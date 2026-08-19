/-
  RelSem.IrisCoupling — spike/relsem (2026-08-19). PAPER-ONLY.

  This file intentionally contains NO Iris code and NO Iris imports.
  iris-lean is pinned at Lean 4.32.2 (deps/iris-lean/Iris/lean-toolchain);
  this repo is on 4.29.0. The coupling below is the intended Layer-3
  instantiation, written field-by-field against the iris-lean interface
  as catalogued in docs/2026-08-19_relsem-spike.md §1b, to be realized in
  a separate 4.32.x proof package (golean's `proofs/` split is the model,
  deps/golean/docs/architecture.md:41-93).

  ---------------------------------------------------------------------
  TARGET INTERFACE (iris-lean, Iris/ProgramLogic/Language.lean):

    class ToVal (Expr) (Val : outParam _) where            -- Language.lean:34-48
      toVal : Expr → Option Val
      ofVal : Val → Expr
      coe_of_toVal_eq_some : toVal e = some v → ofVal v = e
      toVal_coe (v) : toVal (ofVal v) = some v

    class PrimStep (Expr) (State Obs : outParam _) where   -- Language.lean:67-69
      primStep : Expr × State → Obs → Expr × State × List Expr → Prop

    class Language (Expr) (State Obs Val : outParam _)     -- Language.lean:109-115
        extends PrimStep Expr State (List Obs), ToVal Expr Val where
      val_stuck : (e, σ) -<obs>-> (e', σ', eₜ) → toVal e = none

  MODEL-PARAMETRIC ENTRY (continuation, 2026-08-19): the coupling now
  consumes the abstract interface `M : RelSem.ExecModel`
  (RelSem/ExecModel.lean) rather than driver-shaped types directly —
  `Expr × State` decompose `M.Config`, `primStep` wraps `M.Step`, and the
  adequacy exit lands in `M.Adequate`/`M.UBFree` via `M.behavior`. The
  concrete instantiation below is `M := RelSem.Cerb.seqModel` (THE
  sequential instance); a concurrency instance swaps behavior extraction
  + state interpretation, not the statement forms.

  INTENDED INSTANTIATION (the ND-machine language, sequential — the
  driver's thread interleaving is already reified INSIDE the ndM tree by
  the generated scheduler, so the Iris thread-pool stays singleton, like
  golean's sequential instance, deps/golean/proofs/GoLeanProofs/Lang.lean):

    Expr  := RelSem.Cerb.DriveExpr        (MExpr driver_result step_kind
                                           driver_error mem_iv_constraint
                                           driver_state)
    Val   := RelSem.Outcome driver_result driver_error
    State := driver_state
    Obs   := Empty  (v0; later: step_kind labels from NDnd/NDstep nodes,
                     giving trace-indexed specs for free — the labels are
                     already in the Step premises)

    instance : ToVal DriveExpr (Outcome driver_result driver_error) where
      toVal := RelSem.toVal          -- proved: RelSem.toVal_ofVal,
      ofVal := RelSem.ofVal          --         RelSem.ofVal_toVal
      coe_of_toVal_eq_some := RelSem.ofVal_toVal
      toVal_coe := RelSem.toVal_ofVal

    inductive CerbPrimStep :
        DriveExpr × driver_state → List Empty →
        DriveExpr × driver_state × List DriveExpr → Prop where
      | step : RelSem.Cerb.DStep ⟨e, σ⟩ ⟨e', σ'⟩ →
               CerbPrimStep (e, σ) [] (e', σ', [])   -- no forks, ever

    instance : PrimStep DriveExpr driver_state (List Empty) where
      primStep := CerbPrimStep

    instance : Language DriveExpr driver_state Empty
        (Outcome driver_result driver_error) where
      val_stuck h := by cases h with | step s => exact RelSem.val_stuck s
      -- proved at 4.29 already: RelSem.Machine.val_stuck

  STATE INTERPRETATION (Iris/ProgramLogic/WeakestPre.lean:35-42 StateInterp,
  :44-61 IrisGS_gen; gen_heap from Iris/BI/Lib/GenHeap.lean):

    stateInterp σ _ _ _ :=
      genHeapInterp (H := CerbHeapF) (heapToMap σ.layout_state)
        ∗ ⌜purity/wf side-facts about the non-heap driver_state fields⌝

    where heapToMap : CerbMem.MemState → ExtTreeMap Int AbsByte is the
    finite-map denotation of the leftmost-wins bytemap — the 4.29 shadow
    is RelSem.Cerb.heapOf, with the golean faithfulness-bridge shape
    (get? (heapToMap st) a = heapOf st a; cf. deps/golean/proofs/
    GoLeanProofs/HeapBridge.lean:63 Bridge A / :83 Bridge B).
    pointsTo (GenHeap.lean:82-83) then gives `a ↦{dq} b` over addresses
    Int and values AbsByte; allocation-granular assertions (footprints,
    isReadonly, lifetime — RelSem.Cerb.OwnsAlloc) layer above as derived
    predicates or a second ghost map keyed by allocation id.

  ADEQUACY PIPE (Iris/ProgramLogic/Adequacy.lean:300 wp_adequacy →
  :236 adequate; golean's exit shape SurfaceExit.lean:96 goSpec_of_wp),
  now THROUGH the model interface:

    WP (initConfig …).expr {{ o, ⌜∃ r, o = .value r ∧ spec r⌝ }}
      ⇒ adequate .NotStuck … (wp_adequacy, over primStep = M.Step)
      ⇒ ∀ relational trace to a value: spec holds  (adequate_result)
      ⇒ seqModel.Adequate (initConfig …) spec
        = RelSem.Cerb.HarnessAdequateM …
        (via seqModel_adequate_of_reach — PROVED at 4.29: behaviors are
         Steps-reachable, so per-trace facts cover all behaviors)
      ⇒ RelSem.Cerb.HarnessAdequate …  (CerbND-shaped headline; this last
        arrow is CLOSED since arc-7 S2: the runner is totalized, runND =
        runNDFuel ndDefaultFuel by rfl, and RunNDActiveSound is proved —
        `runNDActiveSound`)

  the middle statement being model-parametric (quantifies M.behavior,
  never enumerator output — survey §7.7 discipline), the final statement
  fuel-opsem-only (runND over drive), with the reference function `spec`
  (e.g. the pure URI parser for the libxml2 xmlParseURISafe harness)
  appearing in the statement as specification — never as proof method.

  STUCKNESS HONESTY (mirrors go_adequacy's scope note,
  deps/golean/proofs/GoLeanProofs/Adequacy.lean:63-82): `done (.killed r)`
  outcomes are values here (Outcome.killed), NOT stuck configurations —
  UB/kill verdicts are therefore visible in postconditions and can be
  EXCLUDED by the spec (HarnessAdequate forces `out = Active r`), which
  is stronger and more honest than encoding UB as stuckness.
-/

namespace RelSem
namespace IrisCoupling

/-- Paper-only marker so the module is non-empty and buildable. The real
    coupling lives in a future 4.32.x proof package; see the header. -/
def paperOnly : Unit := ()

end IrisCoupling
end RelSem
