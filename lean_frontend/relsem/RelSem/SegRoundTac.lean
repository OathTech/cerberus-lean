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
import RelSem.CStep

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
    (h1 : -2147483648 ≤ v := by first | assumption | omega)
    (h2 : v ≤ 2147483647 := by first | assumption | omega) :
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

/- (The generic `runEU_aux2_sym` / `runEU_aux2_ctor2` /
   `hnc_of_notConstrained` / `runEU_aux2_step_then` eval crossings
   MOVED to RelSem/CStep.lean at V3a — they are construct-package
   citizens (mechanism C), consumed both by the round tactics below
   (names unchanged) and by the stepper's mint path.) -/

/-- `intLoad_facts` at an ARBITRARY location (V3a: the mint path's
    load rounds carry the round's own loc; `mem_load_block` is
    loc-generic, so the block is too). -/
theorem intLoad_facts_loc (loc : CerbLocation.Loc) (v : Int)
    (addr : Int) (aid : Int)
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
    (h1 : -2147483648 ≤ v := by first | assumption | omega)
    (h2 : v ≤ 2147483647 := by first | assumption | omega) :
    app (CerbMem.loadM loc T1.intCty
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
  exact Kit.mem_load_block (loc := loc)
    (um := none) (hinv.contains_dead_false hget) hget hbounds hty
    (readBytesFrom_of_pointwise rfl hbytes) hrecon rfl

/-! ## The pinned step-discovery (PERF-1 mechanism A, 2026-08-28)

    PERF-0 measured the round tactics' dominant cost INSIDE the
    old first step (refine of `dnmsRoundM_adv` at a bare `rfl`
    discovery premise): elaborator-side whnf of the
    step-discovery `find_can_advance (dnmsDiscover …)` against
    composite arenas (69 s Meta.whnf on r28's state), re-derived per
    unification. The kernel evaluator runs the SAME computation in
    8 ms (probe E). `seg_discover` therefore computes the discovery
    ONCE with `Lean.Kernel.whnf` and pins it as an explicit
    rfl-hinted equation (classical: sharing / explicit equations —
    the plan's L2, in-tree precedent `advance_action_unfold`'s
    "rw with the pinned equation keeps the check linear" note;
    kernel-leaf computation per the ACL2Lean-pattern ruling — the
    certifying artifact is an ordinary `rfl` the kernel re-verifies
    at declaration add, no ofReduce*, fail-closed). The advance
    chain then unifies against the CONCRETE step term, never against
    a re-derivation. Committed choice: `some step` commits to the
    advancing atom; `none` is a loud redirect to `seg_round_term`;
    a kernel failure is a loud stop. -/

section Discover
open Lean Elab Meta Tactic

initialize registerTraceClass `RelSem.segPeels

/-- Hinted refl: `Eq.refl lhs` cast to `lhs = rhs` (the SegStepper
    `mkRflHint` device — the kernel checks the defeq at declaration
    add; a mismatch is a loud kernel error, never a silent pass). -/
private def discRflHint (ty : Expr) : MetaM Expr := do
  let some (_, lhs, _) := ty.eq?
    | throwError "seg_discover: rfl hint on a non-equation:{indentExpr ty}"
  mkExpectedTypeHint (← mkEqRefl lhs) ty

elab "seg_discover" : tactic => do
  let g ← getMainGoal
  g.withContext do
    let ci ← getConstInfo ``RelSem.Cerb.dnmsRoundM_adv
    let (args, _, concl) ← forallMetaTelescope ci.type
    unless ← isDefEq concl (← g.getType) do
      throwError "seg_discover: goal is not an advancing round \
        equation:{indentExpr (← g.getType)}"
    let hfindM := args[args.size - 2]!
    let hadvM := args[args.size - 1]!
    let hfindTy ← instantiateMVars (← hfindM.mvarId!.getType)
    let some (_, discE, rhsE) := hfindTy.eq?
      | throwError "seg_discover: hfind premise is not an equation"
    -- the kernel-computed discovery (8 ms where Meta.whnf is 69 s)
    let env ← getEnv
    let lctx ← getLCtx
    let stepO ← match Lean.Kernel.whnf env lctx discE with
      | .ok e => pure e
      | .error _ => throwError "seg_discover: kernel whnf FAILED on \
          the discovery:{indentExpr discE}"
    unless stepO.isAppOfArity ``Option.some 2 do
      throwError "seg_discover: discovery result is not an advancing \
        step (head: {stepO.getAppFn}) — terminal offer round? use \
        seg_round_term"
    -- expose the step's constructor (the advance laws dispatch on it)
    let stepInner ← match Lean.Kernel.whnf env lctx stepO.appArg! with
      | .ok e => pure e
      | .error _ => throwError "seg_discover: kernel whnf FAILED on \
          the step body"
    let stepOW := mkApp stepO.appFn! stepInner
    unless ← isDefEq rhsE stepOW do
      throwError "seg_discover: could not pin the discovered step:\
        {indentExpr stepOW}"
    let hfindTy ← instantiateMVars (← hfindM.mvarId!.getType)
    hfindM.mvarId!.assign (← discRflHint hfindTy)
    g.assign (← instantiateMVars (mkAppN
      (mkConst ci.name (ci.levelParams.map .param)) args))
    replaceMainGoal [(← instantiateMVars hadvM).mvarId!]

/-- ADAPTIVE COMMITTED PEEL (PERF-1): peel the discovered step's
    monadic wrappers down to the `eval_pexpr20` entry, dispatching
    each step by the GOAL HEAD alone (Lithium's lazymatch discipline
    — committed choice by syntax, no candidate iteration, no
    speculative defeq): `stExceptUndef_bind` → one stub peel;
    `full_eval_pexpr` → expose its bind (one cheap `show`);
    `E.eval_pexpr20` / `runEU` → stop (the class leaf takes over).
    The peel DEPTH is position-dependent (Eunseq members enter
    through `full_eval_pexpr'` directly; sseq-context evals through
    the `eval_pexpr1` bind) — this replaces the fixed three-peel
    scaffolds that mis-keyed the shallow forms. Leaves the leaf goal
    FIRST; the residual wrapper equations close by `rfl` after it
    (`all_goals rfl` in the class macros). -/
elab "seg_peels" : tactic => do
  let rec go (fuel : Nat) : TacticM Unit := do
    match fuel with
    | 0 => throwError "seg_peels: peel depth bound exceeded"
    | fuel+1 =>
      let g ← getMainGoal
      let ty ← instantiateMVars (← g.getType)
      let some (_, lhs, _) := ty.eq?
        | throwError "seg_peels: goal is not an equation:{indentExpr ty}"
      let lhsW ← Meta.whnfCore lhs
      let fn := lhsW.getAppFn
      trace[RelSem.segPeels] "iter (fuel {fuel}): head {fn}"
      if fn.isConstOf ``runEU then
        pure ()   -- the leaf's floor
      else if fn.isConstOf ``E.eval_pexpr20 then
        -- normalize the entry to its `runEU (eval_pexpr_aux2 …)`
        -- spelling (deterministic change — the leaf `show`s are
        -- reducible-only and cannot unfold eval_pexpr20)
        let mut cur := lhsW
        let mut steps := 0
        while !(cur.getAppFn.isConstOf ``runEU) && steps < 8 do
          let some nxt ← Meta.unfoldDefinition? cur
            | throwError "seg_peels: eval_pexpr20 unfolding stuck at \
                {cur.getAppFn}"
          cur ← Meta.whnfCore nxt
          steps := steps + 1
        unless cur.getAppFn.isConstOf ``runEU do
          throwError "seg_peels: eval_pexpr20 did not reach runEU \
            (reached {cur.getAppFn})"
        let some (_, _, rhs) := ty.eq? | unreachable!
        let g' ← g.change (← Meta.mkEq cur rhs)
        replaceMainGoal [g']
      else if fn.isConstOf ``full_eval_pexpr then
        -- expose full_eval's bind EXPLICITLY (the unifier's delta of
        -- `full_eval_pexpr` against a bind pattern is unreliable —
        -- measured PERF-1 build finding; a deterministic `change` at
        -- the unfolded spelling replaces the speculative defeq)
        let mut cur := lhsW
        let mut steps := 0
        while !(cur.getAppFn.isConstOf ``stExceptUndef_bind)
            && steps < 8 do
          let some nxt ← Meta.unfoldDefinition? cur
            | throwError "seg_peels: full_eval unfolding stuck at \
                {cur.getAppFn}"
          cur ← Meta.whnfCore nxt
          steps := steps + 1
        unless cur.getAppFn.isConstOf ``stExceptUndef_bind do
          throwError "seg_peels: full_eval did not expose its bind \
            (reached {cur.getAppFn})"
        let some (_, _, rhs) := ty.eq? | unreachable!
        let g' ← g.change (← Meta.mkEq cur rhs)
        replaceMainGoal [g']
        go fuel
      else if fn.isConstOf ``stExceptUndef_bind then
        evalTactic (← `(tactic|
          (refine (RelSem.Kit.stub_defined (z := ?_) (st' := ?_)
            ?_).trans ?_
           rotate_left 2)))
        go fuel
      else
        throwError "seg_peels: unkeyed goal head {fn} — a new chain \
          shape needs its committed key (never iterate):{indentExpr lhsW}"
  go 12

end Discover

/-! ## The round tactics -/

/-- The eumapM element chain (closed args by rfl, sym args by the
    hit law at the round's cell facts). -/
syntax "seg_eumapM" : tactic
macro_rules
  | `(tactic| seg_eumapM) =>
    `(tactic| first
        | exact eumapM_nil
        | (refine eumapM_cons (b := ?_) (bs := ?_) ?_ ?_
           rotate_left 2
           · first
             | rfl
             | (refine se_sym_hit (v := ?_) ?_ ?_
                rotate_left 1
                · rfl
                · assumption)
           · seg_eumapM))

/-- The scrutinee/operand sub-eval solver: closed by rfl, a sym cell
    hit, or a Ctuple of sym cells. -/
syntax "seg_se_scrut" : tactic
macro_rules
  | `(tactic| seg_se_scrut) =>
    `(tactic| first
        | rfl
        | (refine se_sym_hit (v := ?_) ?_ ?_
           rotate_left 1
           · rfl
           · assumption)
        | (refine se_ctor_tuple (pes' := ?_) (cvals := ?_) ?_ ?_
           rotate_left 2
           · seg_eumapM
           · rfl))

/-- The per-shape single-step solver (the `hstep` of the skeleton):
    closed steps by rfl; the case with cell-fed scrutinee + arm
    select; the call with cell-fed args. -/
syntax "seg_se_step" : tactic
macro_rules
  | `(tactic| seg_se_step) =>
    `(tactic| first
        | rfl
        | (refine se_case_sel (pa := ?_) (pb := ()) (cval := ?_)
            (a2 := ?_) (b2 := ?_) (pe2 := ?_) ?_ ?_
           rotate_left 5
           · seg_se_scrut
           · rfl)
        | (refine se_call (pes' := ?_) (cvals := ?_) (peA := ?_)
            (pe_' := ?_) (a2 := ?_) (pe'' := ?_) ?_ ?_ ?_ ?_
           rotate_left 6
           · seg_eumapM
           · rfl
           · rfl
           · rfl))

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
        | (show runEU (eval_pexpr_aux2 _ _ _ _ _ _ _ _) _ = _
           refine (RelSem.Seg.runEU_aux2_step_then (peP := ?_)
             (pe' := ?_) (z := ?_) ?_ ?_ ?_ ?_).trans ?_
           rotate_left 3
           · rfl
           · seg_se_step
           · rfl
           · rfl
           · first | assumption | rfl)
        | (show stExceptUndef_bind _ _ _ = _
           refine (stub_defined (z := ?_) (st' := ?_) ?_).trans ?_
           rotate_left 2
           · seg_stub_chain
           · seg_stub_chain))

/-- TAU rounds (all `TAU[…]`/`RS_TAU[…]` classes incl. the pattern
    binds — the env write is in the successor spelling). -/
macro "seg_round_tau" : tactic =>
  `(tactic| (seg_discover
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
  `(tactic| (seg_discover
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
  `(tactic| (seg_discover
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
