/-
  RelSem.M1Guard — V3a continuation (2026-08-29): THE m1 GUARD
  ANCHORS (work-order item (i); record
  docs/2026-08-29_v3a-loops-mechC.md §6 row 1).

  m1's two branches compile to the P01-R10 guard shape VERBATIM
  (`if conv_int(v₁) OP conv_int(v₂) then Specified(1) else
  Specified(0)` at the aU/Loc.unknown spellings, v₂ = 0) — so the
  chain layer here is the P02Guard template (P01 R10 value-
  generalized) INSTANTIATED AT m1File: the z-stage pexpr constants
  are file-free and shared (P01's convB/if1pe/le-family imported
  verbatim); only the step/loop lemmas mention the file (the eval
  inlines conv_int from the file's stdlib map).

  THE ANCHORS (registered `@[seg_round]`, the pre-registered
  PERF-2 anchor definition: cut-point reason = BRANCH, stated over
  V1 fragments with quantified data + path-condition hypotheses,
  successor non-ground via the trace): one per guard side. The
  control images ride the m1 walk's own spellings — the UNCHANGED
  arena pieces are PROJECTED from the emitted `m1ar0` (zero
  transcription); the mutated member (the substituted guard redex)
  is the extracted walk spelling (probe
  RelSem/M1WalkProbe.lean, log .v3a-logs/m1fields-arena.live).

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.M1Proof
import RelSem.P01Rounds
import RelSem.P02Guard
import RelSem.SegRoundTac

set_option autoImplicit false
set_option maxHeartbeats 2000000

namespace RelSem.M1

open RelSem RelSem.Cerb RelSem.Kit RelSem.CerbSt RelSem.Seg
  RelSem.Slate
-- spot-audit F3 (2026-08-29): m1File re-homed RelSem.Slate →
-- RelSem.Corpus (statement-side, with the corpus program terms).
open RelSem.Corpus (m1File)
open Lem_Basic_classes (ordCompare)
open RelSem.T1 (T1P RExpr aU intCty xAddr loadedV meLoad errPtr
  xPtrV)
open RelSem.P01 (xObjV le1pe le2pe and12pe if1pe symIsRepr
  symWrapI symConvInt)
open RelSem.P02 (convB)

/-! ## §1 The m1 walk family (the P01Rounds family shape at m1File;
    current_loc = Loc.unknown — the program annots are aU, so the
    first program-node eval resets the harness loc) -/

@[reducible] def m1gTh (arena : RExpr) (f₁ : Fmap sym value) :
    thread_state :=
  { arena := arena,
    stack0 := Stack_empty,
    errno := errPtr,
    current_loc := CerbLocation.Loc.unknown,
    exec_loc := ELoc_normal
      [(sgnM1Sym, CerbLocation.other "RelSem.callND")],
    env := [f₁],
    current_proc_opt := some sgnM1Sym }

@[reducible] def m1gσ (arena : RExpr) (f₁ : Fmap sym value)
    (tS aS eS sS : Nat) (ls : CerbMem.MemState)
    (tr : List trace_event) (n : Nat) : driver_state :=
  { core_file := m1File,
    core_extern := create_extern_symmap m1File,
    core_state0 :=
      { thread_states := [(0, (none, m1gTh arena f₁))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := tS, aid_supply := aS, excluded_supply := eS,
        sym_supply := sS,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW m1File)).labeled },
    layout_state := ls,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := tr,
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := n }

def m1CtlAt (arena : RExpr) (tr : List trace_event) (n : Nat) :
    driver_state :=
  ctlOf (m1gσ arena fmapEmpty 0 0 0 0 CerbMem.initialMemState tr n)

@[reducible] def m1gfam (arena : RExpr) (tr : List trace_event)
    (n : Nat) (p : Pack) : driver_state :=
  m1gσ arena p.f₁ p.tS p.aS p.eS p.sS p.ls tr n

/-- Control inversion at the m1 walk family. -/
@[seg_inv]
theorem m1g_inv {σ : driver_state} {arena : RExpr}
    {tr : List trace_event} {n : Nat}
    (h : ctlOf σ = m1CtlAt arena tr n) :
    ∃ p : Pack, σ = m1gfam arena tr n p := by
  obtain ⟨cf, ce, cs, crs, ls, ccs, fs0, tr', sa, bl, ctr'⟩ := σ
  obtain ⟨ths, io⟩ := cs
  obtain ⟨tS, aS, eS, sS, lab⟩ := crs
  have h' := h
  simp only [m1CtlAt, ctlOf, eraseEnvs, driver_state.mk.injEq,
    core_state.mk.injEq, core_run_state.mk.injEq] at h'
  obtain ⟨hcf, hce, ⟨hths, hio⟩, ⟨-, -, -, -, hlab⟩, -, hccs, hfs,
    htr, hsa, hbl, hctr⟩ := h'
  cases ths with
  | nil => simp at hths
  | cons t rest =>
    obtain ⟨tid, pp, th⟩ := t
    obtain ⟨arena', stack', errno', env', proc', exec', loc'⟩ := th
    simp only [List.map_cons, List.map_nil, List.cons.injEq,
      List.map_eq_nil_iff, Prod.mk.injEq, eraseThreadEnv, m1gTh,
      thread_state.mk.injEq] at hths
    obtain ⟨⟨htid0, hp, harena, hstack, herrno, henv, hproc, hexec,
      hloc⟩, hrest⟩ := hths
    cases env' with
    | nil => simp at henv
    | cons f₁ fr =>
      simp only [List.map_cons, List.map_nil, List.cons.injEq,
        List.map_eq_nil_iff] at henv
      obtain ⟨-, hfr⟩ := henv
      refine ⟨⟨f₁, tS, aS, eS, sS, ls⟩, ?_⟩
      subst hcf hce htid0 hp harena hstack herrno hproc hexec hloc
        hccs hfs htr hsa hbl hctr hio hrest hfr hlab
      rfl

/-! ## §2 The arena at the guard cut points — LITERAL constants with
    kernel-checked provenance pins. The projection spellings
    (`match m1ar0 with …`) are kept as the `…P` twins and tied to the
    literals by `seg_pin_eq` (kernel-recheck at declaration add): the
    anchors' walk-side defeq must run on LITERALS — the elaborator's
    default-transparency unfolding of a file-lookup projection
    expands the whole slate file (measured 32 G OOM at the anchor
    candidates), while the kernel computes the same normal form in
    milliseconds (the extraction probe's own instrument). -/

/-- The Esseq continuation of the body (the second guard + return +
    save — UNTOUCHED through the first block's walk), projection
    form. -/
def m1arRestP : RExpr :=
  match m1ar0 with
  | Expr _ (Esseq _ _ r) => r
  | e => e

def m1pat544P : generic_pattern sym :=
  match m1ar0 with
  | Expr _ (Esseq p _ _) => p
  | _ => Pattern [] (CaseBase (none, BTy_unit))

def m1bnd0 : RExpr :=
  match m1ar0 with
  | Expr _ (Esseq _ b _) => b
  | e => e

def m1patWP : generic_pattern sym :=
  match m1bnd0 with
  | Expr _ (Ebound (Expr _ (Ewseq p _ _))) => p
  | _ => Pattern [] (CaseBase (none, BTy_unit))

def m1outerCaseP : RExpr :=
  match m1bnd0 with
  | Expr _ (Ebound (Expr _ (Ewseq _ _ k))) => k
  | e => e

/-- The a_544 binder pattern (literal; pinned below). -/
def m1pat544 : generic_pattern sym :=
Pattern [Aloc CerbLocation.Loc.unknown]
  (CaseBase (some (Symbol "" 7590096031763635132 (SD_Id "a_544")), BTy_loaded OTy_integer))

/-- The (a_546, a_547) Ewseq pattern (literal; pinned below). -/
def m1patW : generic_pattern sym :=
Pattern [Aloc CerbLocation.Loc.unknown]
  (CaseCtor Ctuple
    [Pattern [Aloc CerbLocation.Loc.unknown]
        (CaseBase (some (Symbol "" 17206061397319244606 (SD_Id "a_546")), BTy_loaded OTy_integer)),
      Pattern [Aloc CerbLocation.Loc.unknown]
        (CaseBase (some (Symbol "" 2905319918966306201 (SD_Id "a_547")), BTy_loaded OTy_integer))])

/-- The outer-case continuation (literal; pinned below). -/
def m1outerCase : RExpr :=
generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
  (Epure
    (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
      (PEcase
        (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
          (PEctor Ctuple
            [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit (PEsym (Symbol "" 17206061397319244606 (SD_Id "a_546"))),
              Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                (PEsym (Symbol "" 2905319918966306201 (SD_Id "a_547")))]))
        [(Pattern [Aloc CerbLocation.Loc.unknown]
              (CaseCtor Ctuple
                [Pattern [Aloc CerbLocation.Loc.unknown]
                    (CaseCtor Cspecified
                      [Pattern [Aloc CerbLocation.Loc.unknown]
                          (CaseBase (some (Symbol "" 17765704775598467422 (SD_Id "a_548")), BTy_object OTy_integer))]),
                  Pattern [Aloc CerbLocation.Loc.unknown]
                    (CaseCtor Cspecified
                      [Pattern [Aloc CerbLocation.Loc.unknown]
                          (CaseBase
                            (some (Symbol "" 16629223912856532319 (SD_Id "a_549")), BTy_object OTy_integer))])]),
            Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
              (PEif
                (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                  (PEop OpEq
                    (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                      (PEcall (Sym (Symbol "" 15837442492999787586 (SD_Id "conv_int")))
                        [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                            (PEval (Vctype (Ctype [] (Basic (Integer (Signed Int_)))))),
                          Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                            (PEsym (Symbol "" 17765704775598467422 (SD_Id "a_548")))]))
                    (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                      (PEcall (Sym (Symbol "" 15837442492999787586 (SD_Id "conv_int")))
                        [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                            (PEval (Vctype (Ctype [] (Basic (Integer (Signed Int_)))))),
                          Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                            (PEsym (Symbol "" 16629223912856532319 (SD_Id "a_549")))]))))
                (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                  (PEctor Cspecified
                    [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                        (PEval
                          (Vobject (OVinteger (CerbMem.IntegerValue.IV CerbMem.Provenance.Prov_none (Int.ofNat 1)))))]))
                (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                  (PEctor Cspecified
                    [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                        (PEval
                          (Vobject
                            (OVinteger (CerbMem.IntegerValue.IV CerbMem.Provenance.Prov_none (Int.ofNat 0)))))])))),
          (Pattern [Aloc CerbLocation.Loc.unknown]
              (CaseBase (none, BTy_tuple [BTy_loaded OTy_integer, BTy_loaded OTy_integer])),
            Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
              (PEctor Cunspecified
                [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                    (PEval (Vctype (Ctype [] (Basic (Integer (Signed Int_))))))]))])))

/-- The Esseq continuation (literal; pinned below). -/
def m1arRest : RExpr :=
generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
  (Esseq
    (Pattern [Aloc CerbLocation.Loc.unknown]
      (CaseBase (some (Symbol "" 14641249357205542421 (SD_Id "a_543")), BTy_boolean)))
    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
      (Ecase (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit (PEsym (Symbol "" 7590096031763635132 (SD_Id "a_544"))))
        [(Pattern [Aloc CerbLocation.Loc.unknown]
              (CaseCtor Cspecified
                [Pattern [Aloc CerbLocation.Loc.unknown]
                    (CaseBase (some (Symbol "" 11067898428807828624 (SD_Id "a_545")), BTy_object OTy_integer))]),
            generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
              (Epure
                (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                  (PEif
                    (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                      (PEnot
                        (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                          (PEop OpEq
                            (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                              (PEsym (Symbol "" 11067898428807828624 (SD_Id "a_545"))))
                            (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                              (PEval
                                (Vobject
                                  (OVinteger
                                    (CerbMem.IntegerValue.IV CerbMem.Provenance.Prov_none (Int.ofNat 1))))))))))
                    (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit (PEval Vtrue))
                    (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit (PEval Vfalse)))))),
          (Pattern [Aloc CerbLocation.Loc.unknown]
              (CaseCtor Cunspecified [Pattern [Aloc CerbLocation.Loc.unknown] (CaseBase (none, BTy_ctype))]),
            generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
              (End
                [generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                    (Epure (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit (PEval Vtrue))),
                  generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                    (Epure (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit (PEval Vfalse)))]))]))
    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
      (Esseq (Pattern [] (CaseBase (none, BTy_unit)))
        (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
          (Eif
            (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit (PEsym (Symbol "" 14641249357205542421 (SD_Id "a_543"))))
            (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
              (Esseq
                (Pattern [Aloc CerbLocation.Loc.unknown]
                  (CaseBase (some (Symbol "" 1862827267035441118 (SD_Id "a_559")), BTy_loaded OTy_integer)))
                (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                  (Ebound
                    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                      (Ewseq
                        (Pattern [Aloc CerbLocation.Loc.unknown]
                          (CaseBase (some (Symbol "" 1656971181475828259 (SD_Id "a_558")), BTy_loaded OTy_integer)))
                        (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                          (Epure
                            (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                              (PEctor Cspecified
                                [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                    (PEval
                                      (Vobject
                                        (OVinteger
                                          (CerbMem.IntegerValue.IV CerbMem.Provenance.Prov_none (Int.ofNat 1)))))]))))
                        (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                          (Epure
                            (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                              (PEcase
                                (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                  (PEsym (Symbol "" 1656971181475828259 (SD_Id "a_558"))))
                                [(Pattern [Aloc CerbLocation.Loc.unknown]
                                      (CaseCtor Cspecified
                                        [Pattern [Aloc CerbLocation.Loc.unknown]
                                            (CaseBase
                                              (some (Symbol "" 16397053867550904782 (SD_Id "a_557")),
                                                BTy_object OTy_integer))]),
                                    Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                      (PEctor Cspecified
                                        [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                            (PEcatch_exceptional_condition (Signed Int_) IOpSub
                                              (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                (PEval
                                                  (Vobject
                                                    (OVinteger
                                                      (CerbMem.IntegerValue.IV CerbMem.Provenance.Prov_none
                                                        (Int.ofNat 0))))))
                                              (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                (PEcall (Sym (Symbol "" 15837442492999787586 (SD_Id "conv_int")))
                                                  [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                      (PEval (Vctype (Ctype [] (Basic (Integer (Signed Int_)))))),
                                                    Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                      (PEsym (Symbol "" 16397053867550904782 (SD_Id "a_557")))])))])),
                                  (Pattern [Aloc CerbLocation.Loc.unknown]
                                      (CaseCtor Cunspecified
                                        [Pattern [Aloc CerbLocation.Loc.unknown] (CaseBase (none, BTy_ctype))]),
                                    Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                      (PEctor Cunspecified
                                        [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                            (PEval (Vctype (Ctype [] (Basic (Integer (Signed Int_))))))]))]))))))))
                (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                  (Esseq (Pattern [] (CaseBase (none, BTy_unit)))
                    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                      (Erun { sb_before := [], dd_before := [], asw_before := [] }
                        (Symbol "" 14329421068334193232 (SD_Id "ret_541"))
                        [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                            (PEcall (Sym (Symbol "" 7499171796590179012 (SD_Id "conv_loaded_int")))
                              [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                  (PEval (Vctype (Ctype [] (Basic (Integer (Signed Int_)))))),
                                Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                  (PEsym (Symbol "" 1862827267035441118 (SD_Id "a_559")))])]))
                    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                      (Epure (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit (PEval Vunit))))))))
            (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
              (Epure (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit (PEval Vunit))))))
        (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
          (Esseq
            (Pattern [Aloc CerbLocation.Loc.unknown]
              (CaseBase (some (Symbol "" 14386475981198921378 (SD_Id "a_560")), BTy_loaded OTy_integer)))
            (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
              (Ebound
                (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                  (Ewseq
                    (Pattern [Aloc CerbLocation.Loc.unknown]
                      (CaseCtor Ctuple
                        [Pattern [Aloc CerbLocation.Loc.unknown]
                            (CaseBase (some (Symbol "" 7457282682047707106 (SD_Id "a_562")), BTy_loaded OTy_integer)),
                          Pattern [Aloc CerbLocation.Loc.unknown]
                            (CaseBase
                              (some (Symbol "" 17306733169765808126 (SD_Id "a_563")), BTy_loaded OTy_integer))]))
                    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                      (Eunseq
                        [generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                            (Ewseq
                              (Pattern [Aloc CerbLocation.Loc.unknown]
                                (CaseCtor Ctuple
                                  [Pattern [Aloc CerbLocation.Loc.unknown]
                                      (CaseBase
                                        (some (Symbol "" 12129931134301626842 (SD_Id "a_568")),
                                          BTy_loaded OTy_integer)),
                                    Pattern [Aloc CerbLocation.Loc.unknown]
                                      (CaseBase
                                        (some (Symbol "" 15836592521936022799 (SD_Id "a_569")),
                                          BTy_loaded OTy_integer))]))
                              (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                (Eunseq
                                  [generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                      (Ewseq
                                        (Pattern [Aloc CerbLocation.Loc.unknown]
                                          (CaseBase
                                            (some (Symbol "" 16496410563140706571 (SD_Id "a_567")),
                                              BTy_object OTy_pointer)))
                                        (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                          (Epure
                                            (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                              (PEsym (Symbol "" 16562859848569467201 (SD_Id "x"))))))
                                        (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                          (Eaction
                                            (Paction polarity.Pos
                                              (Action CerbLocation.Loc.unknown
                                                { sb_before := [], dd_before := [], asw_before := [] }
                                                (Load0
                                                  (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                    (PEval (Vctype (Ctype [] (Basic (Integer (Signed Int_)))))))
                                                  (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                    (PEsym (Symbol "" 16496410563140706571 (SD_Id "a_567"))))
                                                  NA)))))),
                                    generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                      (Epure
                                        (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                          (PEctor Cspecified
                                            [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                (PEval
                                                  (Vobject
                                                    (OVinteger
                                                      (CerbMem.IntegerValue.IV CerbMem.Provenance.Prov_none
                                                        (Int.ofNat 0)))))])))]))
                              (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                (Ecase
                                  (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                    (PEctor Ctuple
                                      [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                          (PEsym (Symbol "" 12129931134301626842 (SD_Id "a_568"))),
                                        Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                          (PEsym (Symbol "" 15836592521936022799 (SD_Id "a_569")))]))
                                  [(Pattern [Aloc CerbLocation.Loc.unknown]
                                        (CaseCtor Ctuple
                                          [Pattern [Aloc CerbLocation.Loc.unknown]
                                              (CaseCtor Cspecified
                                                [Pattern [Aloc CerbLocation.Loc.unknown]
                                                    (CaseBase
                                                      (some (Symbol "" 5991727426051750857 (SD_Id "a_570")),
                                                        BTy_object OTy_integer))]),
                                            Pattern [Aloc CerbLocation.Loc.unknown]
                                              (CaseCtor Cspecified
                                                [Pattern [Aloc CerbLocation.Loc.unknown]
                                                    (CaseBase
                                                      (some (Symbol "" 3766081930734261399 (SD_Id "a_571")),
                                                        BTy_object OTy_integer))])]),
                                      generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                        (Epure
                                          (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                            (PEif
                                              (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                (PEop OpGt
                                                  (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                    (PEcall (Sym (Symbol "" 15837442492999787586 (SD_Id "conv_int")))
                                                      [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                          (PEval (Vctype (Ctype [] (Basic (Integer (Signed Int_)))))),
                                                        Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                          (PEsym (Symbol "" 5991727426051750857 (SD_Id "a_570")))]))
                                                  (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                    (PEcall (Sym (Symbol "" 15837442492999787586 (SD_Id "conv_int")))
                                                      [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                          (PEval (Vctype (Ctype [] (Basic (Integer (Signed Int_)))))),
                                                        Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                          (PEsym (Symbol "" 3766081930734261399 (SD_Id "a_571")))]))))
                                              (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                (PEctor Cspecified
                                                  [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                      (PEval
                                                        (Vobject
                                                          (OVinteger
                                                            (CerbMem.IntegerValue.IV CerbMem.Provenance.Prov_none
                                                              (Int.ofNat 1)))))]))
                                              (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                (PEctor Cspecified
                                                  [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                      (PEval
                                                        (Vobject
                                                          (OVinteger
                                                            (CerbMem.IntegerValue.IV CerbMem.Provenance.Prov_none
                                                              (Int.ofNat 0)))))])))))),
                                    (Pattern [Aloc CerbLocation.Loc.unknown]
                                        (CaseBase (none, BTy_tuple [BTy_loaded OTy_integer, BTy_loaded OTy_integer])),
                                      generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                        (Epure
                                          (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                            (PEctor Cunspecified
                                              [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                  (PEval (Vctype (Ctype [] (Basic (Integer (Signed Int_))))))]))))]))),
                          generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                            (Epure
                              (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                (PEctor Cspecified
                                  [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                      (PEval
                                        (Vobject
                                          (OVinteger
                                            (CerbMem.IntegerValue.IV CerbMem.Provenance.Prov_none
                                              (Int.ofNat 0)))))])))]))
                    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                      (Epure
                        (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                          (PEcase
                            (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                              (PEctor Ctuple
                                [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                    (PEsym (Symbol "" 7457282682047707106 (SD_Id "a_562"))),
                                  Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                    (PEsym (Symbol "" 17306733169765808126 (SD_Id "a_563")))]))
                            [(Pattern [Aloc CerbLocation.Loc.unknown]
                                  (CaseCtor Ctuple
                                    [Pattern [Aloc CerbLocation.Loc.unknown]
                                        (CaseCtor Cspecified
                                          [Pattern [Aloc CerbLocation.Loc.unknown]
                                              (CaseBase
                                                (some (Symbol "" 4998152064567917579 (SD_Id "a_564")),
                                                  BTy_object OTy_integer))]),
                                      Pattern [Aloc CerbLocation.Loc.unknown]
                                        (CaseCtor Cspecified
                                          [Pattern [Aloc CerbLocation.Loc.unknown]
                                              (CaseBase
                                                (some (Symbol "" 15936767184861729128 (SD_Id "a_565")),
                                                  BTy_object OTy_integer))])]),
                                Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                  (PEif
                                    (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                      (PEop OpEq
                                        (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                          (PEcall (Sym (Symbol "" 15837442492999787586 (SD_Id "conv_int")))
                                            [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                (PEval (Vctype (Ctype [] (Basic (Integer (Signed Int_)))))),
                                              Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                (PEsym (Symbol "" 4998152064567917579 (SD_Id "a_564")))]))
                                        (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                          (PEcall (Sym (Symbol "" 15837442492999787586 (SD_Id "conv_int")))
                                            [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                (PEval (Vctype (Ctype [] (Basic (Integer (Signed Int_)))))),
                                              Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                                (PEsym (Symbol "" 15936767184861729128 (SD_Id "a_565")))]))))
                                    (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                      (PEctor Cspecified
                                        [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                            (PEval
                                              (Vobject
                                                (OVinteger
                                                  (CerbMem.IntegerValue.IV CerbMem.Provenance.Prov_none
                                                    (Int.ofNat 1)))))]))
                                    (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                      (PEctor Cspecified
                                        [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                            (PEval
                                              (Vobject
                                                (OVinteger
                                                  (CerbMem.IntegerValue.IV CerbMem.Provenance.Prov_none
                                                    (Int.ofNat 0)))))])))),
                              (Pattern [Aloc CerbLocation.Loc.unknown]
                                  (CaseBase (none, BTy_tuple [BTy_loaded OTy_integer, BTy_loaded OTy_integer])),
                                Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                  (PEctor Cunspecified
                                    [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                        (PEval (Vctype (Ctype [] (Basic (Integer (Signed Int_))))))]))]))))))))
            (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
              (Esseq
                (Pattern [Aloc CerbLocation.Loc.unknown]
                  (CaseBase (some (Symbol "" 16217071427669230452 (SD_Id "a_542")), BTy_boolean)))
                (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                  (Ecase
                    (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                      (PEsym (Symbol "" 14386475981198921378 (SD_Id "a_560"))))
                    [(Pattern [Aloc CerbLocation.Loc.unknown]
                          (CaseCtor Cspecified
                            [Pattern [Aloc CerbLocation.Loc.unknown]
                                (CaseBase
                                  (some (Symbol "" 2433340024454083569 (SD_Id "a_561")), BTy_object OTy_integer))]),
                        generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                          (Epure
                            (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                              (PEif
                                (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                  (PEnot
                                    (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                      (PEop OpEq
                                        (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                          (PEsym (Symbol "" 2433340024454083569 (SD_Id "a_561"))))
                                        (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                          (PEval
                                            (Vobject
                                              (OVinteger
                                                (CerbMem.IntegerValue.IV CerbMem.Provenance.Prov_none
                                                  (Int.ofNat 1))))))))))
                                (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit (PEval Vtrue))
                                (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit (PEval Vfalse)))))),
                      (Pattern [Aloc CerbLocation.Loc.unknown]
                          (CaseCtor Cunspecified
                            [Pattern [Aloc CerbLocation.Loc.unknown] (CaseBase (none, BTy_ctype))]),
                        generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                          (End
                            [generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                (Epure (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit (PEval Vtrue))),
                              generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                (Epure (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit (PEval Vfalse)))]))]))
                (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                  (Esseq (Pattern [] (CaseBase (none, BTy_unit)))
                    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                      (Eif
                        (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                          (PEsym (Symbol "" 16217071427669230452 (SD_Id "a_542"))))
                        (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                          (Esseq
                            (Pattern [Aloc CerbLocation.Loc.unknown]
                              (CaseBase
                                (some (Symbol "" 17489985924624673497 (SD_Id "a_573")), BTy_loaded OTy_integer)))
                            (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                              (Ebound
                                (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                  (Epure
                                    (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                      (PEctor Cspecified
                                        [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                            (PEval
                                              (Vobject
                                                (OVinteger
                                                  (CerbMem.IntegerValue.IV CerbMem.Provenance.Prov_none
                                                    (Int.ofNat 1)))))]))))))
                            (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                              (Esseq (Pattern [] (CaseBase (none, BTy_unit)))
                                (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                  (Erun { sb_before := [], dd_before := [], asw_before := [] }
                                    (Symbol "" 14329421068334193232 (SD_Id "ret_541"))
                                    [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                        (PEcall (Sym (Symbol "" 7499171796590179012 (SD_Id "conv_loaded_int")))
                                          [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                              (PEval (Vctype (Ctype [] (Basic (Integer (Signed Int_)))))),
                                            Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                              (PEsym (Symbol "" 17489985924624673497 (SD_Id "a_573")))])]))
                                (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                  (Epure (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit (PEval Vunit))))))))
                        (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                          (Epure (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit (PEval Vunit))))))
                    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                      (Esseq
                        (Pattern [Aloc CerbLocation.Loc.unknown]
                          (CaseBase (some (Symbol "" 13039610436516453285 (SD_Id "a_574")), BTy_loaded OTy_integer)))
                        (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                          (Ebound
                            (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                              (Epure
                                (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                  (PEctor Cspecified
                                    [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                        (PEval
                                          (Vobject
                                            (OVinteger
                                              (CerbMem.IntegerValue.IV CerbMem.Provenance.Prov_none
                                                (Int.ofNat 0)))))]))))))
                        (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                          (Esseq (Pattern [] (CaseBase (none, BTy_unit)))
                            (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                              (Erun { sb_before := [], dd_before := [], asw_before := [] }
                                (Symbol "" 14329421068334193232 (SD_Id "ret_541"))
                                [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                    (PEcall (Sym (Symbol "" 7499171796590179012 (SD_Id "conv_loaded_int")))
                                      [Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                          (PEval (Vctype (Ctype [] (Basic (Integer (Signed Int_)))))),
                                        Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                          (PEsym (Symbol "" 13039610436516453285 (SD_Id "a_574")))])]))
                            (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                              (Esseq (Pattern [] (CaseBase (none, BTy_unit)))
                                (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                  (Epure (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit (PEval Vunit))))
                                (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                  (Esave (Symbol "" 14329421068334193232 (SD_Id "ret_541"), BTy_loaded OTy_integer)
                                    [(Symbol "" 16264240517835081145 (SD_Id "a_575"), (BTy_loaded OTy_integer, none),
                                        Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                          (PEundef CerbLocation.Loc.unknown UB088_reached_end_of_function))]
                                    (generic_expr.Expr [Aloc CerbLocation.Loc.unknown]
                                      (Epure
                                        (Pexpr [Aloc CerbLocation.Loc.unknown] PUnit.unit
                                          (PEsym (Symbol "" 16264240517835081145 (SD_Id "a_575")))))))))))))))))))))))

seg_pin_eq m1pat544_pin m1pat544 m1pat544P
seg_pin_eq m1patW_pin m1patW m1patWP
seg_pin_eq m1outerCase_pin m1outerCase m1outerCaseP
seg_pin_eq m1arRest_pin m1arRest m1arRestP

/-- The load's positive-action annotation (walk spelling). -/
def m1fpA : List dyn_annotation :=
  [DA_pos [] (CerbMem.Footprint.FP CerbMem.FootprintAccess.R
    xAddr 4)]

/-- The evaluated second unseq member (`pure(Specified(0))` → the
    loaded value; round 7's spelling). -/
def m1spec0V : RExpr := Expr aU (Epure (Pexpr [] () (PEval (loadedV 0))))

/-- The first block's arena at pexpr `pe` in the guard slot (the
    walk's shape from the case-select round onward). -/
def m1arB1 (pe : generic_pexpr Unit sym) : RExpr :=
  Expr aU (Esseq m1pat544
    (Expr aU (Ebound (Expr aU (Ewseq m1patW
      (Expr aU (Eunseq
        [Expr [] (Eannot m1fpA (Expr aU (Epure pe))), m1spec0V]))
      m1outerCase))))
    m1arRest)

/-! ## §3 The guard chain at m1File (the P02Guard template at the
    aU/Loc.unknown spellings; z-stage constants shared with P01) -/

def m1clocC : Option CerbLocation.Loc :=
  some (CerbLocation.other "RelSem.callND")
def m1extC : Fmap sym sym := create_extern_symmap m1File

/-- Compare-verdict arm (aU spelling). -/
def m1gArm (k : Int) : generic_pexpr Unit sym :=
  Pexpr aU () (PEctor Cspecified [Pexpr aU () (PEval (xObjV k))])

/-- One conv_int call operand at value `v` (aU spelling). -/
def m1convA (v : Int) : generic_pexpr Unit sym :=
  Pexpr aU () (PEcall (Sym symConvInt)
    [Pexpr aU () (PEval (Vctype intCty)), Pexpr aU () (PEval (xObjV v))])

/-- The guard-round redex (in-arena spelling; root aU). -/
def m1gz0 (op : binop) (v1 v2 : Int) : generic_pexpr Unit sym :=
  Pexpr aU () (PEif (Pexpr aU () (PEop op (m1convA v1) (m1convA v2)))
    (m1gArm 1) (m1gArm 0))

/-- Post-pull spelling (root re-annotated `[]`). -/
def m1gzA (op : binop) (v1 v2 : Int) : generic_pexpr Unit sym :=
  Pexpr [] () (PEif (Pexpr aU () (PEop op (m1convA v1) (m1convA v2)))
    (m1gArm 1) (m1gArm 0))

/-- After step A: both conv calls inlined (P01's convB, shared). -/
def m1gzB (op : binop) (v1 v2 : Int) : generic_pexpr Unit sym :=
  Pexpr [] () (PEif (Pexpr [] () (PEop op (convB v1) (convB v2)))
    (m1gArm 1) (m1gArm 0))

/-- After step B: bool-ctype test + is_representable inlined. -/
def m1gzC (op : binop) (v1 v2 : Int) : generic_pexpr Unit sym :=
  Pexpr [] () (PEif (Pexpr [] () (PEop op (if1pe v1) (if1pe v2)))
    (m1gArm 1) (m1gArm 0))

/-! ### Steps A/B (value-generic, per-op) -/

theorem m1gsA_gt (v1 v2 : Int)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr m1File.tagDefs 0 CerbLocation.Loc.unknown m1clocC
      m1extC env memo m1File false (m1gzA OpGt v1 v2)
      = Result (Defined (m1gzB OpGt v1 v2)) := rfl

theorem m1gsA_lt (v1 v2 : Int)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr m1File.tagDefs 0 CerbLocation.Loc.unknown m1clocC
      m1extC env memo m1File false (m1gzA OpLt v1 v2)
      = Result (Defined (m1gzB OpLt v1 v2)) := rfl

theorem m1gsB_gt (v1 v2 : Int)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr m1File.tagDefs 0 CerbLocation.Loc.unknown m1clocC
      m1extC env memo m1File false (m1gzB OpGt v1 v2)
      = Result (Defined (m1gzC OpGt v1 v2)) := rfl

theorem m1gsB_lt (v1 v2 : Int)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr m1File.tagDefs 0 CerbLocation.Loc.unknown m1clocC
      m1extC env memo m1File false (m1gzB OpLt v1 v2)
      = Result (Defined (m1gzC OpLt v1 v2)) := rfl

/-! ### The verdict sub-evals (P01's sLe/sAnd/sIf at m1File) -/

theorem m1sLe1 (v : Int) (h1 : -2147483648 ≤ v)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr_lemFuel 999996 m1File.tagDefs 4
      CerbLocation.Loc.unknown m1clocC
      m1extC env memo m1File false (le1pe v)
      = Result (Defined (Pexpr [] () (PEval Vtrue))) := by
  have hd1 : decide ((-2147483648:Int) ≤ v) = true := decide_eq_true h1
  have harm : (if (decide ((-2147483648:Int) ≤ v)) = true
      then Vtrue else Vfalse) = Vtrue := by rw [hd1]; simp
  conv => rhs; rw [← harm]
  rfl

theorem m1sLe2 (v : Int) (h2 : v ≤ 2147483647)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr_lemFuel 999996 m1File.tagDefs 4
      CerbLocation.Loc.unknown m1clocC
      m1extC env memo m1File false (le2pe v)
      = Result (Defined (Pexpr [] () (PEval Vtrue))) := by
  have hd2 : decide (v ≤ (2147483647:Int)) = true := decide_eq_true h2
  have harm : (if (decide (v ≤ (2147483647:Int))) = true
      then Vtrue else Vfalse) = Vtrue := by rw [hd2]; simp
  conv => rhs; rw [← harm]
  rfl

theorem m1sAnd (v : Int) (h1 : -2147483648 ≤ v) (h2 : v ≤ 2147483647)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr_lemFuel 999997 m1File.tagDefs 3
      CerbLocation.Loc.unknown m1clocC
      m1extC env memo m1File false (and12pe v)
      = Result (Defined (Pexpr [] () (PEval Vtrue))) := by
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval Vtrue : generic_pexpr_ Unit sym)) ?hop).trans rfl
  case hop =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined (m1sLe1 v h1 env memo)).trans ?_
    change exception_undef_bind _ _ = _
    refine (eubind_defined (m1sLe2 v h2 env memo)).trans ?_
    rfl

theorem m1sIf (v : Int) (h1 : -2147483648 ≤ v) (h2 : v ≤ 2147483647)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState) :
    step_eval_pexpr_lemFuel 999998 m1File.tagDefs 2
      CerbLocation.Loc.unknown m1clocC
      m1extC env memo m1File false (if1pe v)
      = Result (Defined (Pexpr [] () (PEval (xObjV v)))) := by
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval (xObjV v) : generic_pexpr_ Unit sym)) ?hif).trans rfl
  case hif =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined (m1sAnd v h1 h2 env memo)).trans ?_
    rfl

/-! ### The guard (compare application) per op/side -/

section Guard
variable (v1 v2 : Int)
    (h1 : -2147483648 ≤ v1) (h2 : v1 ≤ 2147483647)
    (h3 : -2147483648 ≤ v2) (h4 : v2 ≤ 2147483647)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState)

include h1 h2 h3 h4

theorem m1GuardGtT (hgt : v2 < v1) :
    step_eval_pexpr_lemFuel 999999 m1File.tagDefs 1
      CerbLocation.Loc.unknown m1clocC m1extC env memo m1File false
      (Pexpr [] () (PEop OpGt (if1pe v1) (if1pe v2)))
      = Result (Defined (Pexpr [] () (PEval Vtrue))) := by
  have hd : decide (v2 < v1) = true := decide_eq_true hgt
  have harm : (if (decide (v2 < v1)) = true
      then Vtrue else Vfalse) = Vtrue := by rw [hd]; simp
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval Vtrue : generic_pexpr_ Unit sym)) ?hop).trans rfl
  case hop =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined (m1sIf v1 h1 h2 env memo)).trans ?_
    change exception_undef_bind _ _ = _
    refine (eubind_defined (m1sIf v2 h3 h4 env memo)).trans ?_
    conv => rhs; rw [show (Result (Defined (PEval Vtrue
      : generic_pexpr_ Unit sym)) : exceptM
        (t0 (generic_pexpr_ Unit sym)) core_run_cause)
      = Result (Defined (PEval (if (decide (v2 < v1)) = true
          then Vtrue else Vfalse))) from by rw [harm]]
    rfl

theorem m1GuardGtF (hle : ¬ v2 < v1) :
    step_eval_pexpr_lemFuel 999999 m1File.tagDefs 1
      CerbLocation.Loc.unknown m1clocC m1extC env memo m1File false
      (Pexpr [] () (PEop OpGt (if1pe v1) (if1pe v2)))
      = Result (Defined (Pexpr [] () (PEval Vfalse))) := by
  have hd : decide (v2 < v1) = false := decide_eq_false hle
  have harm : (if (decide (v2 < v1)) = true
      then Vtrue else Vfalse) = Vfalse := by rw [hd]; simp
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval Vfalse : generic_pexpr_ Unit sym)) ?hop).trans rfl
  case hop =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined (m1sIf v1 h1 h2 env memo)).trans ?_
    change exception_undef_bind _ _ = _
    refine (eubind_defined (m1sIf v2 h3 h4 env memo)).trans ?_
    conv => rhs; rw [show (Result (Defined (PEval Vfalse
      : generic_pexpr_ Unit sym)) : exceptM
        (t0 (generic_pexpr_ Unit sym)) core_run_cause)
      = Result (Defined (PEval (if (decide (v2 < v1)) = true
          then Vtrue else Vfalse))) from by rw [harm]]
    rfl

theorem m1GuardLtT (hlt : v1 < v2) :
    step_eval_pexpr_lemFuel 999999 m1File.tagDefs 1
      CerbLocation.Loc.unknown m1clocC m1extC env memo m1File false
      (Pexpr [] () (PEop OpLt (if1pe v1) (if1pe v2)))
      = Result (Defined (Pexpr [] () (PEval Vtrue))) := by
  have hd : decide (v1 < v2) = true := decide_eq_true hlt
  have harm : (if (decide (v1 < v2)) = true
      then Vtrue else Vfalse) = Vtrue := by rw [hd]; simp
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval Vtrue : generic_pexpr_ Unit sym)) ?hop).trans rfl
  case hop =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined (m1sIf v1 h1 h2 env memo)).trans ?_
    change exception_undef_bind _ _ = _
    refine (eubind_defined (m1sIf v2 h3 h4 env memo)).trans ?_
    conv => rhs; rw [show (Result (Defined (PEval Vtrue
      : generic_pexpr_ Unit sym)) : exceptM
        (t0 (generic_pexpr_ Unit sym)) core_run_cause)
      = Result (Defined (PEval (if (decide (v1 < v2)) = true
          then Vtrue else Vfalse))) from by rw [harm]]
    rfl

theorem m1GuardLtF (hge : ¬ v1 < v2) :
    step_eval_pexpr_lemFuel 999999 m1File.tagDefs 1
      CerbLocation.Loc.unknown m1clocC m1extC env memo m1File false
      (Pexpr [] () (PEop OpLt (if1pe v1) (if1pe v2)))
      = Result (Defined (Pexpr [] () (PEval Vfalse))) := by
  have hd : decide (v1 < v2) = false := decide_eq_false hge
  have harm : (if (decide (v1 < v2)) = true
      then Vtrue else Vfalse) = Vfalse := by rw [hd]; simp
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval Vfalse : generic_pexpr_ Unit sym)) ?hop).trans rfl
  case hop =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined (m1sIf v1 h1 h2 env memo)).trans ?_
    change exception_undef_bind _ _ = _
    refine (eubind_defined (m1sIf v2 h3 h4 env memo)).trans ?_
    conv => rhs; rw [show (Result (Defined (PEval Vfalse
      : generic_pexpr_ Unit sym)) : exceptM
        (t0 (generic_pexpr_ Unit sym)) core_run_cause)
      = Result (Defined (PEval (if (decide (v1 < v2)) = true
          then Vtrue else Vfalse))) from by rw [harm]]
    rfl

end Guard

/-! ### Step C (the whole verdict pexpr) per op/side -/

section StepC
variable (v1 v2 : Int)
    (h1 : -2147483648 ≤ v1) (h2 : v1 ≤ 2147483647)
    (h3 : -2147483648 ≤ v2) (h4 : v2 ≤ 2147483647)
    (env : List (Fmap sym value)) (memo : Option CerbMem.MemState)

include h1 h2 h3 h4

theorem m1sC_gt_T (hgt : v2 < v1) :
    step_eval_pexpr m1File.tagDefs 0 CerbLocation.Loc.unknown m1clocC
      m1extC env memo m1File false (m1gzC OpGt v1 v2)
      = Result (Defined (Pexpr [] () (PEval (loadedV 1)))) := by
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval (loadedV 1) : generic_pexpr_ Unit sym)) ?hif).trans rfl
  case hif =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined
      (m1GuardGtT v1 v2 h1 h2 h3 h4 env memo hgt)).trans ?_
    rfl

theorem m1sC_gt_F (hle : ¬ v2 < v1) :
    step_eval_pexpr m1File.tagDefs 0 CerbLocation.Loc.unknown m1clocC
      m1extC env memo m1File false (m1gzC OpGt v1 v2)
      = Result (Defined (Pexpr [] () (PEval (loadedV 0)))) := by
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval (loadedV 0) : generic_pexpr_ Unit sym)) ?hif).trans rfl
  case hif =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined
      (m1GuardGtF v1 v2 h1 h2 h3 h4 env memo hle)).trans ?_
    rfl

theorem m1sC_lt_T (hlt : v1 < v2) :
    step_eval_pexpr m1File.tagDefs 0 CerbLocation.Loc.unknown m1clocC
      m1extC env memo m1File false (m1gzC OpLt v1 v2)
      = Result (Defined (Pexpr [] () (PEval (loadedV 1)))) := by
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval (loadedV 1) : generic_pexpr_ Unit sym)) ?hif).trans rfl
  case hif =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined
      (m1GuardLtT v1 v2 h1 h2 h3 h4 env memo hlt)).trans ?_
    rfl

theorem m1sC_lt_F (hge : ¬ v1 < v2) :
    step_eval_pexpr m1File.tagDefs 0 CerbLocation.Loc.unknown m1clocC
      m1extC env memo m1File false (m1gzC OpLt v1 v2)
      = Result (Defined (Pexpr [] () (PEval (loadedV 0)))) := by
  change exception_undef_bind _ _ = _
  refine (eubind_defined
    (z := (PEval (loadedV 0) : generic_pexpr_ Unit sym)) ?hif).trans rfl
  case hif =>
    change exception_undef_bind _ _ = _
    refine (eubind_defined
      (m1GuardLtF v1 v2 h1 h2 h3 h4 env memo hge)).trans ?_
    rfl

end StepC

/-! ### The whole-loop faces (aux2 chains at runEU, per op/side) -/

section Loop
variable {A : Type} (v1 v2 : Int)
    (h1 : -2147483648 ≤ v1) (h2 : v1 ≤ 2147483647)
    (h3 : -2147483648 ≤ v2) (h4 : v2 ≤ 2147483647)
    {env : List (Fmap sym value)} {memo : Option CerbMem.MemState}
    {st : A}

include h1 h2 h3 h4

theorem m1cmp_gt_T (hgt : v2 < v1) :
    runEU (eval_pexpr_aux2 m1File.tagDefs CerbLocation.Loc.unknown
      m1clocC m1extC env memo m1File (m1gz0 OpGt v1 v2)) st
      = runEU (Result (Defined (Sum.inr (loadedV 1)))) st := by
  have h : eval_pexpr_aux2 m1File.tagDefs CerbLocation.Loc.unknown
      m1clocC m1extC env memo m1File (m1gz0 OpGt v1 v2)
      = Result (Defined (Sum.inr (loadedV 1))) :=
    (aux2_step 999999 _ _ _ _ _ _ _
        (show pull_constrained 0 (m1gz0 OpGt v1 v2) = m1gzA OpGt v1 v2
          from rfl)
        (by intro a xs h; simp [m1gzA] at h) (m1gsA_gt v1 v2 env memo)
        (by rfl)).trans
    ((aux2_step 999998 _ _ _ _ _ _ _
        (show pull_constrained 0 (m1gzB OpGt v1 v2) = m1gzB OpGt v1 v2
          from rfl)
        (by intro a xs h; simp [m1gzB] at h)
        (show _ = _ from m1gsB_gt v1 v2 env memo) (by rfl)).trans
    (aux2_done 999997 _ _ _ _ _ _ _
        (show pull_constrained 0 (m1gzC OpGt v1 v2) = m1gzC OpGt v1 v2
          from rfl)
        (by intro a xs h; simp [m1gzC] at h)
        (m1sC_gt_T v1 v2 h1 h2 h3 h4 env memo hgt) (by rfl)))
  rw [h]

theorem m1cmp_gt_F (hle : ¬ v2 < v1) :
    runEU (eval_pexpr_aux2 m1File.tagDefs CerbLocation.Loc.unknown
      m1clocC m1extC env memo m1File (m1gz0 OpGt v1 v2)) st
      = runEU (Result (Defined (Sum.inr (loadedV 0)))) st := by
  have h : eval_pexpr_aux2 m1File.tagDefs CerbLocation.Loc.unknown
      m1clocC m1extC env memo m1File (m1gz0 OpGt v1 v2)
      = Result (Defined (Sum.inr (loadedV 0))) :=
    (aux2_step 999999 _ _ _ _ _ _ _
        (show pull_constrained 0 (m1gz0 OpGt v1 v2) = m1gzA OpGt v1 v2
          from rfl)
        (by intro a xs h; simp [m1gzA] at h) (m1gsA_gt v1 v2 env memo)
        (by rfl)).trans
    ((aux2_step 999998 _ _ _ _ _ _ _
        (show pull_constrained 0 (m1gzB OpGt v1 v2) = m1gzB OpGt v1 v2
          from rfl)
        (by intro a xs h; simp [m1gzB] at h)
        (show _ = _ from m1gsB_gt v1 v2 env memo) (by rfl)).trans
    (aux2_done 999997 _ _ _ _ _ _ _
        (show pull_constrained 0 (m1gzC OpGt v1 v2) = m1gzC OpGt v1 v2
          from rfl)
        (by intro a xs h; simp [m1gzC] at h)
        (m1sC_gt_F v1 v2 h1 h2 h3 h4 env memo hle) (by rfl)))
  rw [h]

theorem m1cmp_lt_T (hlt : v1 < v2) :
    runEU (eval_pexpr_aux2 m1File.tagDefs CerbLocation.Loc.unknown
      m1clocC m1extC env memo m1File (m1gz0 OpLt v1 v2)) st
      = runEU (Result (Defined (Sum.inr (loadedV 1)))) st := by
  have h : eval_pexpr_aux2 m1File.tagDefs CerbLocation.Loc.unknown
      m1clocC m1extC env memo m1File (m1gz0 OpLt v1 v2)
      = Result (Defined (Sum.inr (loadedV 1))) :=
    (aux2_step 999999 _ _ _ _ _ _ _
        (show pull_constrained 0 (m1gz0 OpLt v1 v2) = m1gzA OpLt v1 v2
          from rfl)
        (by intro a xs h; simp [m1gzA] at h) (m1gsA_lt v1 v2 env memo)
        (by rfl)).trans
    ((aux2_step 999998 _ _ _ _ _ _ _
        (show pull_constrained 0 (m1gzB OpLt v1 v2) = m1gzB OpLt v1 v2
          from rfl)
        (by intro a xs h; simp [m1gzB] at h)
        (show _ = _ from m1gsB_lt v1 v2 env memo) (by rfl)).trans
    (aux2_done 999997 _ _ _ _ _ _ _
        (show pull_constrained 0 (m1gzC OpLt v1 v2) = m1gzC OpLt v1 v2
          from rfl)
        (by intro a xs h; simp [m1gzC] at h)
        (m1sC_lt_T v1 v2 h1 h2 h3 h4 env memo hlt) (by rfl)))
  rw [h]

theorem m1cmp_lt_F (hge : ¬ v1 < v2) :
    runEU (eval_pexpr_aux2 m1File.tagDefs CerbLocation.Loc.unknown
      m1clocC m1extC env memo m1File (m1gz0 OpLt v1 v2)) st
      = runEU (Result (Defined (Sum.inr (loadedV 0)))) st := by
  have h : eval_pexpr_aux2 m1File.tagDefs CerbLocation.Loc.unknown
      m1clocC m1extC env memo m1File (m1gz0 OpLt v1 v2)
      = Result (Defined (Sum.inr (loadedV 0))) :=
    (aux2_step 999999 _ _ _ _ _ _ _
        (show pull_constrained 0 (m1gz0 OpLt v1 v2) = m1gzA OpLt v1 v2
          from rfl)
        (by intro a xs h; simp [m1gzA] at h) (m1gsA_lt v1 v2 env memo)
        (by rfl)).trans
    ((aux2_step 999998 _ _ _ _ _ _ _
        (show pull_constrained 0 (m1gzB OpLt v1 v2) = m1gzB OpLt v1 v2
          from rfl)
        (by intro a xs h; simp [m1gzB] at h)
        (show _ = _ from m1gsB_lt v1 v2 env memo) (by rfl)).trans
    (aux2_done 999997 _ _ _ _ _ _ _
        (show pull_constrained 0 (m1gzC OpLt v1 v2) = m1gzC OpLt v1 v2
          from rfl)
        (by intro a xs h; simp [m1gzC] at h)
        (m1sC_lt_F v1 v2 h1 h2 h3 h4 env memo hge) (by rfl)))
  rw [h]

end Loop

/-! ## §4 THE GUARD-1 ANCHORS (branch cut point; pre-registered
    anchor definition — path-conditioned, data-quantified, trace-
    carrying successor) -/

/-- GUARD 1 (x < 0), TRUE side. -/
@[seg_round]
theorem m1g1T (x : Int) (h1 : -2147483648 ≤ x)
    (h2 : x ≤ 2147483647) (hlt : x < 0) (p : Pack) :
    app (dnmsRoundM m1File.tagDefs 0)
        (m1gfam (m1arB1 (m1gz0 OpLt x 0)) [meLoad x] 9 p)
      = (NDactive (Sum.inl NOWAKEUP),
         m1gfam (m1arB1 (Pexpr [] () (PEval (loadedV 1))))
           [meLoad x] 10 p) := by
  seg_discover
  refine ((advance_runstate_eval (th' := ?_)
    (rs' := ?_) ?_).trans ?_)
  rotate_left 2
  · seg_peels
    focus
      show runEU (eval_pexpr_aux2 _ _ _ _ _ _ _ _) _ = _
      refine (m1cmp_lt_T x 0 ?_ ?_ ?_ ?_ ?_).trans ?_
      all_goals first | assumption | omega | rfl
    all_goals rfl
  · rfl

/-- GUARD 1 (x < 0), FALSE side. -/
@[seg_round]
theorem m1g1F (x : Int) (h1 : -2147483648 ≤ x)
    (h2 : x ≤ 2147483647) (hge : ¬ x < 0) (p : Pack) :
    app (dnmsRoundM m1File.tagDefs 0)
        (m1gfam (m1arB1 (m1gz0 OpLt x 0)) [meLoad x] 9 p)
      = (NDactive (Sum.inl NOWAKEUP),
         m1gfam (m1arB1 (Pexpr [] () (PEval (loadedV 0))))
           [meLoad x] 10 p) := by
  seg_discover
  refine ((advance_runstate_eval (th' := ?_)
    (rs' := ?_) ?_).trans ?_)
  rotate_left 2
  · seg_peels
    focus
      show runEU (eval_pexpr_aux2 _ _ _ _ _ _ _ _) _ = _
      refine (m1cmp_lt_F x 0 ?_ ?_ ?_ ?_ ?_).trans ?_
      all_goals first | assumption | omega | rfl
    all_goals rfl
  · rfl

/-! ## §5 THE GUARD-2 ANCHORS (second branch; the else-arm reaches
    this block after the first guard falls through — arena pieces by
    PROJECTION off the literal `m1arRest`, ground truth pinned by the
    walk probe's extraction at segCtl_1_48: trace [meLoad x,
    meLoad x], ctr 30, OpGt at (x, 0)) -/

def m1restK1 : RExpr :=
  match m1arRest with
  | Expr _ (Esseq _ _ k) => k
  | e => e

def m1restK2 : RExpr :=
  match m1restK1 with
  | Expr _ (Esseq _ _ k) => k
  | e => e

def m1pat560 : generic_pattern sym :=
  match m1restK2 with
  | Expr _ (Esseq p _ _) => p
  | _ => Pattern [] (CaseBase (none, BTy_unit))

def m1bnd2 : RExpr :=
  match m1restK2 with
  | Expr _ (Esseq _ b _) => b
  | e => e

def m1patW2 : generic_pattern sym :=
  match m1bnd2 with
  | Expr _ (Ebound (Expr _ (Ewseq p _ _))) => p
  | _ => Pattern [] (CaseBase (none, BTy_unit))

def m1outerCase2 : RExpr :=
  match m1bnd2 with
  | Expr _ (Ebound (Expr _ (Ewseq _ _ k))) => k
  | e => e

def m1rest3 : RExpr :=
  match m1restK2 with
  | Expr _ (Esseq _ _ k) => k
  | e => e

/-- The second block's arena at pexpr `pe` in the guard slot. -/
def m1arB2 (pe : generic_pexpr Unit sym) : RExpr :=
  Expr aU (Esseq m1pat560
    (Expr aU (Ebound (Expr aU (Ewseq m1patW2
      (Expr aU (Eunseq
        [Expr [] (Eannot m1fpA (Expr aU (Epure pe))), m1spec0V]))
      m1outerCase2))))
    m1rest3)

/-- GUARD 2 (x > 0), TRUE side. -/
@[seg_round]
theorem m1g2T (x : Int) (h1 : -2147483648 ≤ x)
    (h2 : x ≤ 2147483647) (hgt : 0 < x) (p : Pack) :
    app (dnmsRoundM m1File.tagDefs 0)
        (m1gfam (m1arB2 (m1gz0 OpGt x 0)) [meLoad x, meLoad x] 30 p)
      = (NDactive (Sum.inl NOWAKEUP),
         m1gfam (m1arB2 (Pexpr [] () (PEval (loadedV 1))))
           [meLoad x, meLoad x] 31 p) := by
  seg_discover
  refine ((advance_runstate_eval (th' := ?_)
    (rs' := ?_) ?_).trans ?_)
  rotate_left 2
  · seg_peels
    focus
      show runEU (eval_pexpr_aux2 _ _ _ _ _ _ _ _) _ = _
      refine (m1cmp_gt_T x 0 ?_ ?_ ?_ ?_ ?_).trans ?_
      all_goals first | assumption | omega | rfl
    all_goals rfl
  · rfl

/-- GUARD 2 (x > 0), FALSE side. -/
@[seg_round]
theorem m1g2F (x : Int) (h1 : -2147483648 ≤ x)
    (h2 : x ≤ 2147483647) (hle : ¬ 0 < x) (p : Pack) :
    app (dnmsRoundM m1File.tagDefs 0)
        (m1gfam (m1arB2 (m1gz0 OpGt x 0)) [meLoad x, meLoad x] 30 p)
      = (NDactive (Sum.inl NOWAKEUP),
         m1gfam (m1arB2 (Pexpr [] () (PEval (loadedV 0))))
           [meLoad x, meLoad x] 31 p) := by
  seg_discover
  refine ((advance_runstate_eval (th' := ?_)
    (rs' := ?_) ?_).trans ?_)
  rotate_left 2
  · seg_peels
    focus
      show runEU (eval_pexpr_aux2 _ _ _ _ _ _ _ _) _ = _
      refine (m1cmp_gt_F x 0 ?_ ?_ ?_ ?_ ?_).trans ?_
      all_goals first | assumption | omega | rfl
    all_goals rfl
  · rfl


end RelSem.M1
