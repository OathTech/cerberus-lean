/-
  RelSem.SegRoundTac — V2b (2026-08-28): THE ROUND-PROVING TACTICS —
  the per-class discharge for registered round-equation SUPPLY
  statements. With these, a fixture's easy-class round equations are
  STATEMENTS ONLY (`:= by seg_round_tau` / `seg_round_eval` /
  `seg_round_load`): the proof text that V2's production line
  template-stamped per round (the O(rounds × paths) mass) is replaced
  by three once-written tactic macros driving the SAME named laws the
  hand proofs drive (dnmsRoundM_adv, the Kit advance laws, the stub/
  aux2 eval chains, the perform/load blocks — escalation ladder
  intact; the hard rounds — multi-step eval chains with arithmetic
  side conditions — remain hand-written on the same laws).

  Lineage: the proof-producing round classes of Kit/Round.lean
  (arc-9/arc-17), searched bounded-first (brick-wp `wp_auto`
  discipline: try the registered chain shapes, fail loudly).

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.Kit.Eval
import RelSem.Kit.EvalStep
import RelSem.Kit.Round
import RelSem.Kit.Mem
import RelSem.PerStepPeel
import RelSem.T1Rounds

set_option autoImplicit false

namespace RelSem.Seg

open RelSem RelSem.Cerb RelSem.Kit

/-! ## Generic int-cell load facts (T1's `loadX_eq_facts` promoted:
    any 4-byte signed-int object, any address/allocation). -/

/-- The load equation at footprint facts for an int cell holding the
    serialized bytes of `v` (state unchanged; the byte roundtrip
    recombines to exactly `v`). -/
theorem intLoad_facts (v : Int) (addr : Int) (aid : Int)
    (alc : CerbMem.Allocation) (ls : CerbMem.MemState)
    (hget : ls.allocations.get? aid = some alc := by assumption)
    (hbytes : ∀ i : Nat, (hi : i < (T1.xBytes v).length) →
      ls.bytemap.get? (addr + (i : Int)) = some (T1.xBytes v)[i]
      := by assumption)
    (hbase : alc.base = addr := by rfl) (hsz : alc.size = 4 := by rfl)
    (hty : CerbMem.isAtomicMemberAccess alc T1.intCty addr = false
      := by rfl)
    (hlum : ls.lastUsedUnionMembers = []
      := by first | assumption | rfl)
    (hfpm : ls.funptrmap = [] := by first | assumption | rfl)
    (hinv : MemInv ls := by assumption)
    (h1 : -2147483648 ≤ v := by assumption)
    (h2 : v ≤ 2147483647 := by assumption) :
    app (CerbMem.loadM CerbLocation.Loc.unknown T1.intCty
        (.PV (.Prov_some aid) (.PVconcrete none addr))) ls
      = (NDactive (CerbMem.Footprint.FP .R addr 4,
          CerbMem.MemValue.MVinteger (Signed Int_) (.IV .Prov_none v)),
         ls) := by
  have hrecon : CerbMem.reconstructValue ls.lastUsedUnionMembers
      ls.funptrmap addr T1.intCty (T1.xBytes v)
      = CerbMem.MemValue.MVinteger (Signed Int_) (.IV .Prov_none v) := by
    rw [hlum, hfpm]
    show CerbMem.reconstructValue_lemFuel (999999 + 1) [] [] addr
      (Ctype [] (Basic (Integer (Signed Int_)))) (T1.xBytes v) = _
    rw [CerbMem.reconstructValue_lemFuel]
    simp only [CerberusImpl.is_signed_ity]
    rw [show T1.xBytes v
        = [T1.mkByte v 0, T1.mkByte v 1, T1.mkByte v 2, T1.mkByte v 3]
        from rfl,
      T1.roundtrip_arith v h1 h2]
    simp [CerbMem.provFromIntegerBytes, CerbMem.combineProv, T1.mkByte]
  have hbounds : CerbMem.isInBounds alc addr
      (CerbMem.sizeofCtype T1.intCty) = true := by
    rw [show CerbMem.sizeofCtype T1.intCty = 4 from rfl]
    unfold CerbMem.isInBounds
    rw [hbase, hsz]
    simp
  exact Kit.mem_load_block (loc := CerbLocation.Loc.unknown)
    (um := none) (hinv.contains_dead_false hget) hget hbounds hty
    (readBytesFrom_of_pointwise rfl hbytes) hrecon rfl

/-- The `runEU`-level face of the one-hit sym read (stated so a
    `refine` UNIFIES the annotations/env/state before the side
    premises elaborate). -/
theorem runEU_aux2_sym {A : Type}
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {loc : CerbLocation.Loc} {cloc : Option CerbLocation.Loc}
    {ext : Fmap sym sym} {env : List (Fmap sym value)}
    {memo : Option CerbMem.MemState}
    {file1 : file core_run_annotation}
    {a a' : List annot} {z : sym} {v : value} {st : A}
    (hpull : pull_constrained 0 (Pexpr a () (PEsym z))
      = Pexpr a' () (PEsym z))
    (hext : fmapLookupBy
      (fun (s1 s2 : sym) => Lem_Basic_classes.ordCompare s1 s2) z ext
      = none)
    (hlk : lookup_env z env = some v) :
    runEU (eval_pexpr_aux2 tagDefs loc cloc ext env memo file1
        (Pexpr a () (PEsym z))) st
      = runEU (Result (Defined (Sum.inr v))) st := by
  rw [aux2_sym_hit hpull hext hlk]

/-- The `runEU` face of the two-cell Ctuple scrutinee eval (the
    Ecase-pack round class; P01's `p01ctor2_eval` promoted generic). -/
theorem runEU_aux2_ctor2 {A : Type}
    {tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)}
    {loc : CerbLocation.Loc} {cloc : Option CerbLocation.Loc}
    {ext : Fmap sym sym} {env : List (Fmap sym value)}
    {memo : Option CerbMem.MemState}
    {file1 : file core_run_annotation}
    {a a₁ a₂ : List annot} {x₁ x₂ : sym} {v₁ v₂ : value} {st : A}
    (hpull : pull_constrained 0 (Pexpr a () (PEctor Ctuple
        [Pexpr a₁ () (PEsym x₁), Pexpr a₂ () (PEsym x₂)]))
      = Pexpr [] () (PEctor Ctuple
        [Pexpr a₁ () (PEsym x₁), Pexpr a₂ () (PEsym x₂)]))
    (hext₁ : fmapLookupBy
      (fun (s1 s2 : sym) => Lem_Basic_classes.ordCompare s1 s2) x₁ ext
      = none)
    (hext₂ : fmapLookupBy
      (fun (s1 s2 : sym) => Lem_Basic_classes.ordCompare s1 s2) x₂ ext
      = none)
    (hlk₁ : lookup_env x₁ env = some v₁)
    (hlk₂ : lookup_env x₂ env = some v₂) :
    runEU (eval_pexpr_aux2 tagDefs loc cloc ext env memo file1
        (Pexpr a () (PEctor Ctuple
          [Pexpr a₁ () (PEsym x₁), Pexpr a₂ () (PEsym x₂)]))) st
      = runEU (Result (Defined (Sum.inr (Vtuple [v₁, v₂])))) st := by
  have h : eval_pexpr_aux2 tagDefs loc cloc ext env memo file1
      (Pexpr a () (PEctor Ctuple
        [Pexpr a₁ () (PEsym x₁), Pexpr a₂ () (PEsym x₂)]))
      = Result (Defined (Sum.inr (Vtuple [v₁, v₂]))) :=
    aux2_done 999999 _ _ _ _ _ _ _ hpull
      (by intro a' xs h; simp at h)
      (se_ctor_tuple
        (pes' := [Pexpr [] () (PEval v₁), Pexpr [] () (PEval v₂)])
        (cvals := [v₁, v₂])
        (eumapM_cons (se_sym_hit (fuel := 999998) hext₁ hlk₁)
          (eumapM_cons (se_sym_hit (fuel := 999998) hext₂ hlk₂)
            eumapM_nil)) rfl)
      (by rfl)
  rw [h]

/-! ## The round tactics -/

/-- The eval sub-chain: peel `stExceptUndef_bind` stubs (values forced
    by unification), close leaves by `rfl` or the one-hit `aux2` sym
    read (the cell fact from the round statement's hypotheses). -/
syntax "seg_stub_chain" : tactic
macro_rules
  | `(tactic| seg_stub_chain) =>
    `(tactic| first
        | rfl
        | (show runEU (eval_pexpr_aux2 _ _ _ _ _ _ _
              (Pexpr _ () (PEsym _))) _ = _
           refine (RelSem.Seg.runEU_aux2_sym (a' := []) (v := ?_)
             ?_ ?_ ?_).trans ?_
           rotate_left 1
           all_goals first | assumption | rfl)
        | (show runEU (eval_pexpr_aux2 _ _ _ _ _ _ _
              (Pexpr _ () (PEctor Ctuple
                [Pexpr _ () (PEsym _), Pexpr _ () (PEsym _)]))) _ = _
           refine (RelSem.Seg.runEU_aux2_ctor2 (v₁ := ?_) (v₂ := ?_)
             ?_ ?_ ?_ ?_ ?_).trans ?_
           rotate_left 2
           all_goals first | assumption | rfl)
        | (show stExceptUndef_bind _ _ _ = _
           refine (stub_defined (z := ?_) (st' := ?_) ?_).trans ?_
           rotate_left 2
           · seg_stub_chain
           · seg_stub_chain))

/-- TAU rounds (all `TAU[…]`/`RS_TAU[…]` classes incl. the pattern
    binds — the env write is in the successor spelling). -/
macro "seg_round_tau" : tactic =>
  `(tactic| (refine dnmsRoundM_adv rfl ?_
             first
               | exact (advance_tau_misc).trans rfl
               | (refine ((advance_runstate_tau_misc (th' := ?_)
                    (rs' := ?_) ?_).trans ?_)
                  rotate_left 2
                  · seg_stub_chain
                  · rfl)))

/-- EVAL rounds (`RS_EVAL[Epure]` sym reads / closed evals,
    `RS_EVAL[eval operands of Load]`, `RS_EVAL[Erun]`-simple): the
    runstate-eval advance with the stub chain. -/
macro "seg_round_eval" : tactic =>
  `(tactic| (refine dnmsRoundM_adv rfl ?_
             refine ((advance_runstate_eval (th' := ?_)
               (rs' := ?_) ?_).trans ?_)
             rotate_left 2
             · seg_stub_chain
             · rfl))

/-- LOAD rounds (`ACTION[LoadRequest]`): the action-request draw +
    the perform block at the int-load facts. The round statement's
    hypotheses feed `intLoad_facts` (get?/bytes/lum/fpm/MemInv/range —
    all by `assumption`, the residual spellings by `rfl`). -/
macro "seg_round_load" : tactic =>
  `(tactic| (refine dnmsRoundM_adv rfl ?_
             apply (app_bind_active ?hreq).trans
             case hreq =>
               refine (app_bind_active rfl).trans ?_
               rw [perform_unfold]
               refine (app_bind_active aid_draw).trans ?_
               rw [ars_load_unfold]
               refine (app_bind_active (app_liftMem_active rfl
                 (intLoad_facts _ _ _ _ _))).trans ?_
               refine (app_bind_active (app_liftMem_active rfl
                 mem_prefix_block)).trans ?_
               exact app_nd_update _ _
             rfl))

/-- TERMINAL rounds (the done-offer `Sum.inr` step). -/
macro "seg_round_term" : tactic =>
  `(tactic| (refine (dnmsRoundM_inr rfl).trans ?_
             rfl))

/-- The one-face round tactic (dispatch by trial — the classes are
    mutually exclusive; failures are cheap and the final failure is
    the ordinary loud one). -/
macro "seg_round_tac" : tactic =>
  `(tactic| first
      | seg_round_term
      | seg_round_tau
      | seg_round_eval
      | seg_round_load)

end RelSem.Seg
