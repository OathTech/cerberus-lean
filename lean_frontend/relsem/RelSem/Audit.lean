/-
  RelSem.Audit — arc-7 S1 (2026-08-19): the in-build axiom audit for the
  relational layer, adopted from golean's proofs/Audit.lean pattern
  (deps/golean/proofs/Audit.lean §"Exhaustive axiom sweep" + the curated
  #guard_msgs gates). This file is a MEMBER of the RelSem lib (imported
  from relsem/RelSem.lean), so `lake build RelSem` elaborates it and an
  edit that weakens the epistemic position FAILS THE BUILD rather than
  silently shipping.

  What it checks:

  1. EXHAUSTIVE SWEEP — every constant declared in a module whose name
     root is `RelSem` (module-of-origin via `getModuleIdxFor?`, not
     namespace — golean pre-merge finding F1: a namespace filter lets a
     top-level declaration dodge the sweep), plus every constant of the
     file being elaborated (no module index yet). Each constant's
     TRANSITIVE axioms (`collectAxioms`) must lie inside the declared
     boundary below; `sorryAx` / `ofReduceBool` / `ofReduceNat` (the D14
     non-kernel-method axioms) are never in it.
     SCOPE = THIS FILE'S IMPORT CLOSURE, exactly (arc-11 audit A-F1:
     the T5 chain — T5Fixture/T5Prefix/T5Iter — was package-built but
     NOT imported here, so its constants dodged the sweep; the chain
     is now imported below, the sweep's tail line states the closure
     scope honestly, and the sweep count is #guard_msgs-PINNED so a
     module leaving the closure is a build failure, not a silent
     shrink. Re-baseline the pinned count deliberately, in the same
     commit, with the reason.)

  2. CURATED PINS — `#guard_msgs in #print axioms` on the load-bearing
     proved theorems, asserting their EXACT axiom sets, so growth (a
     new axiom entering `runNDFuel_sound`) is a build failure until this
     file is deliberately re-baselined in the same commit with the
     reason. Since arc-8 S3 every pin is DAEMON-free (deletion note
     below); the T1–T4 cones are exactly `[propext, runEffectful,
     Classical.choice, Quot.sound]`.

  THE DECLARED BOUNDARY (allowlist), with provenance:
  * the classical trio `propext`, `Classical.choice`, `Quot.sound`;
  * `runEffectful` (LemLib.lean) — the arcs-1+2 effect-erasure
    barrier (docs/2026-08-18_effects-totality-design.md). TEMPORAL
    ([USER 2026-08-24]): it survives only because it lives in the
    LemLib runtime (lem-side surgery, out of this repo's scope) and
    is consumed by the generated ambient/compiled paths; the threaded
    theorem family is already free of it, and the ambient family
    retires at the arc-17 purge. Its carrier set is PINNED EXACTLY by
    the no-cone-entry gate below — any NEW theorem cone acquiring it
    is a build failure.

  BOUNDARY AXIOMS DELETED (arc-17 S2b, 2026-08-25 — the [USER
  2026-08-24] temporal-mover execution): `CerbTags.with_tagDefs`
  (axiom since arc-4 S1r) and `CerberusFresh.forceIO` (axiom since
  arc-5 S2) are NO LONGER AXIOMS — each is now an `opaque` with a
  kernel-checked inhabitation witness (`fun _ f => f ()` /
  `fun f => pure (f ())`, the effect-erased meanings), still
  irreducible to every proof, still @[implemented_by]-bound to the
  same native extents (behavior re-verified by the differential
  lanes + FreshIntTest). They can never appear in an axiom cone
  again; the hand-written axiom census (check_theorem_axioms.sh) is
  0, and the BOUNDARY-OPAQUE gate below asserts the axiom-form
  absence fail-closed (either name existing as an axiom, or ever
  being allowlisted, fails the build).

  DAEMON IS DELETED — THE ABSENCE IS ENFORCED (arc-8 S3, 2026-08-20).
  History: `axiom DAEMON : ∀ {α : Type}, α` (lem's undefined-value
  axiom, formerly in LemLib) was, AS DECLARED, a logically INCONSISTENT
  axiom — `(DAEMON : Empty)` proves `False`, kernel-checked (arc-7
  audit-1 F1; the arc-7 results addendum has the verbatim probe). Until
  arc-8, every substrate-quoting cone here carried it (kernel-checked
  only MODULO the unreachable-marker meta-assumption), tracked by an
  entry-vector census. Arc-8 executed the temporal mover
  (lembugs/2026-08-20_daemon-inconsistent-axiom.md): the lem backend
  now derives real bounded Inhabited instances (S1) and emits
  failwithI with `[Inhabited tv]` signature threading (S2), and DAEMON,
  DAEMON1, and legacy `failwith` are DELETED from LemLib (S3). The
  T1–T4 cones are now exactly `[propext, runEffectful,
  Classical.choice, Quot.sound]` — UNCONDITIONAL kernel certificates
  modulo only the declared boundary above.
  FAIL-CLOSED ABSENCE GATE (below, replacing the old census walk): the
  build FAILS if any constant named `DAEMON` or `DAEMON1` exists
  anywhere in THIS MODULE'S elaboration environment — the import
  closure of the audited roots (LemLib, every generated module that
  closure reaches, relsem) — or if either name is ever allowlisted.
  SCOPE HONESTY (arc-8 audit, auditor B F1): generated files OUTSIDE
  this import closure (e.g. Core_indet.lean) are NOT seen by this
  gate; full-tree absence over lean_frontend/generated/ is enforced by
  the name-independent tree-wide axiom census in
  scripts/check_theorem_axioms.sh (allowlist: the two declared
  boundary axioms only; unsafeCast banned outright). Reintroduction
  under any guise is a build failure, not a re-baseline; there is no
  sanctioned path back.

  FINDING CLOSED (arc-7 S2 — was: REGISTERED FINDING, arc-7 S1/D3,
  arc-blocking): `sorryAx` sat in the cone of `initial_driver_state`
  (generated Driver) via
    initial_driver_state → collect_labeled_continuations_NEW
      → instSetTypeGeneric_fun_map_decl → sorryAx
  (the backend's sorried low-priority `SetType (generic_fun_map_decl)`
  instance, demanded — but never applied — by `Lem_Map_extra.fold`'s
  signature). EVICTED by the arc-4 S1a priority-override mechanism: the
  hand-written default-priority instance in CerbFunMapInstances.lean,
  imported into Core_aux via `declare {lean} extra_import` in
  core_aux.lem. `initConfig`'s cone is sorryAx-free; the exception list
  below is EMPTY and stays fail-closed in both directions: any constant
  that picks up sorryAx fails the build, and a re-grown list entry that
  stops carrying sorryAx fails the build until removed deliberately.

  SCOPE ([AGENT:S1S0]): RelSem.* modules only. The proof-test modules
  (Unit.EffectsProofTest, Unit.TotalityProofTest) CANNOT join this
  import closure: each declares a top-level `main` (they are exe roots),
  and importing both fails with "environment already contains 'main'"
  (probed 2026-08-19). Their subject constants stay covered by the
  check_theorem_axioms.sh exemplar probes in the unit-test gate.

  To re-baseline after an INTENDED change: update the pin/exception in
  the same commit, with the reason. Never re-baseline to launder a red.
-/

import Lean
import RelSem.ExecModel
import RelSem.Machine
import RelSem.RunND
import RelSem.Cerberus
import RelSem.Call
import RelSem.FuelHooks
-- (RelSem.IrisCoupling — arc-7 paper-only sketch, 1 marker decl —
-- DELETED at arc-18 R3: zero importers, retirement-register surface;
-- sweep re-pinned 8404 → 8403 in the deleting commit.)
-- arc-7 S4: the iris-lean coupling modules join the sweep + pins.
import RelSem.T1Core
import RelSem.T1File
-- (T1Walks/T2Walks/T3Walks — the hand walk supplies — DELETED at V0
-- 2026-08-27 with the whole walk-engine kill basket; record
-- docs/2026-08-27_v0-statements-and-ban.md.)
-- arc-7 S5a: the slate climb (T2-T4) + the fixture-generic WP bridge.
import RelSem.SlateCore
import RelSem.SlateFiles
-- V0: the prior-vocabulary census instrument (consistency statement
-- layer; gates below) + THE CORPUS STATEMENT SLATE (batch A).
import RelSem.PriorCensus
import RelSem.CorpusCore
import RelSem.CorpusFiles
import RelSem.CorpusStatements
import RelSem.CorpusBCore
import RelSem.CorpusBFiles
import RelSem.CorpusBStatements
-- arc-9 S2: the kit exactness pins join the in-build audit.
import RelSem.Kit.Audit
import RelSem.Kit.EvalStep
-- (arc-11 audit A-F1's T5 chain — T5Fixture → T5Prefix → T5Iter —
-- RETIRED at arc-18 R4: T5-the-theorem is PROVED through the segment
-- layer (RelSem.T5, pinned below at the trio); the ambient-era climb
-- artifacts' capability is subsumed. Their Audit pins are
-- re-registered to the flagship pins in the same commit.)
-- arc-16 S1: the per-step language (the Iris refounding's language
-- layer) joins the sweep closure + pins.
import RelSem.PerStep
import RelSem.PerStepIris
import RelSem.PerStepCall
import RelSem.PerStepObs
import RelSem.PerStepPeel
import RelSem.MemLocal
import RelSem.CerbStateRA
import RelSem.CerbStateWP
import RelSem.CerbStateStep
import RelSem.CerbStateAdequacy
import RelSem.CerbStateDemo
import RelSem.T1Rounds
import RelSem.T1Proof
import RelSem.P01Rounds
import RelSem.P01Proof
import RelSem.T2Rounds
import RelSem.T2Proof
import RelSem.T3Rounds
import RelSem.T3Proof
-- arc-18 C2: the heap-route walk substrate joins the sweep closure +
-- pins (the one-route migration).
-- arc-16 S3: the runner-observation algebra + wp-tactics join the
-- sweep closure + pins. (PerStepPeel + PerStepLaws DELETED at
-- arc-18 C2, Q1 [USER] ruling — pins removed in the same commit.)
import RelSem.PerStepTactics
-- arc-18 C2: the transitional OwnP surface (disentangled from the
-- live route; the OwnP pins below now originate here).
-- arc-17 S0: the discharge-engine substrate (named-state emitter +
-- memoized ground-fact discharger) joins the sweep closure.
import RelSem.DeriveState
import RelSem.WpGround
-- arc-17 S2: the law-driven round evaluator joins the sweep closure.
import RelSem.RoundEval
-- arc-18 C1: THE ONE REGISTRY (the reasoning layer's single law
-- interface; census pinned below).
import RelSem.LawRegistry
-- arc-17 S2: the ordered-map env algebra joins the sweep closure +
-- pins (comparator lawfulness + lookup-through-insert under
-- apartness).
import RelSem.Kit.Env
-- arc-17 S1: the per-construct law registry joins the sweep closure
-- + pins. (RelSem/T6Probe.lean joined the build at S2 when the
-- evaluator completed the probe — audit-1 NOTE-1 comment refresh.)
import RelSem.ConstructLaws
-- arc-16 S4: the threaded effect state (∀-seed statements; the
-- acceptance re-proof) joins the sweep closure + pins.
import RelSem.Threaded
import RelSem.T1Threaded
import RelSem.T2Threaded
import RelSem.T3Threaded
-- arc-17 S2: the completed acceptance probe joins the sweep closure
-- + pins (the ∀-seed t6 theorems through the round evaluator).
-- arc-18 R2: the segment layer (judgment + composition + FnSpec) and
-- its faces (verify_fn/seg_auto + the seg_* registration attributes)
-- join the sweep closure + pins.
import RelSem.Segment
import RelSem.SegmentFaces
-- V0 2026-08-27: T4Threaded/T5 are STATEMENT-ONLY files now
-- (honest-unproved targets, consistency-freshness shape); the
-- T4Walks/T5Walks/T5Inv/T5Seam/T5Spine engine rooms are DELETED
-- (kill basket, record docs/2026-08-27_v0-statements-and-ban.md).
import RelSem.T4Threaded
import RelSem.T5
-- arc-18 R6: the breadth-campaign corpus, batch 1 (EASY tier e1–e5)
-- joins the sweep closure + pins.
-- arc-18 R6: batch 2 (CENSUS tier c4/c5/c3a/c3b) joins the sweep
-- closure + pins.
-- arc-18 R6: batch 3 (edge loop rows x7/x2; the array-lane C9 is
-- PARKED — not imported, see RelSem/Corpus/C9.lean's header).

namespace RelSem.Audit

open Lean

/-- The declared axiom boundary (docstring above records provenance).
    Arc-17 S2b: `CerbTags.with_tagDefs` and `CerberusFresh.forceIO`
    are REMOVED — they are opaques now, not axioms (the boundary-opaque
    gate below enforces that they never come back as axioms). -/
def allowedAxioms : List Name :=
  [``propext, ``Classical.choice, ``Quot.sound, `runEffectful]

-- THE DAEMON ABSENCE GATE (arc-8 S3, durability requirement 3 —
-- replaces the arc-7 S5c DAEMON1 tripwire and the entry-vector census
-- walk). FAIL-CLOSED: the build fails if a constant named `DAEMON` or
-- `DAEMON1` exists anywhere in this module's environment (the import
-- closure of the audited roots: LemLib, the generated modules that
-- closure reaches, relsem), or if either name is allowlisted. Scope
-- honesty (arc-8 audit, auditor B F1): generated files outside the
-- closure are covered by the tree-wide script census in
-- scripts/check_theorem_axioms.sh, not here. The deleted axiom was
-- logically INCONSISTENT (header history); reintroduction is a build
-- failure forever after — never a re-baseline.
open Lean in
#eval show CoreM Unit from do
  let env ← getEnv
  for banned in [`DAEMON, `DAEMON1] do
    if allowedAxioms.contains banned then
      throwError "RelSem audit: {banned} has been ALLOWLISTED — the \
        DAEMON axiom family was DELETED in arc-8 (it was logically \
        inconsistent as declared); there is no sanctioned path back. \
        Revert."
    if (env.find? banned).isSome then
      throwError "RelSem audit: a constant named {banned} EXISTS in \
        the environment — the DAEMON axiom family was DELETED in \
        arc-8 (it was logically inconsistent as declared) and its \
        absence is enforced fail-closed. Remove the declaration; \
        reintroduction is a build failure, never a re-baseline."
  logInfo "RelSem DAEMON absence gate: no constant named DAEMON or \
    DAEMON1 exists in the environment; neither is allowlisted"

-- THE BOUNDARY-OPAQUE GATE (arc-17 S2b — the axiom-endgame
-- enforcement, DAEMON-gate pattern). The two former hand-written
-- boundary axioms were converted to opaques with kernel-checked
-- witnesses; this gate makes the conversion IRREVERSIBLE-BY-DEFAULT:
-- FAIL-CLOSED in all directions — each name must (1) EXIST (a rename
-- must re-point the gate, never silently drop the check), (2) NOT be
-- an axiom (reintroduction under the same name is a build failure,
-- never a re-baseline), (3) BE an opaque (the irreducibility the
-- armor depends on — a plain def would let proofs see the witness),
-- and (4) never be allowlisted in `allowedAxioms`. Plant-tested both
-- directions (transcripts: docs/2026-08-25_arc17-s2b-axiom-endgame.md).
open Lean in
#eval show CoreM Unit from do
  let env ← getEnv
  for n in [`CerbTags.with_tagDefs, `CerberusFresh.forceIO] do
    if allowedAxioms.contains n then
      throwError "RelSem boundary-opaque gate: {n} is ALLOWLISTED as \
        an axiom — it was DELETED as an axiom in arc-17 S2b (it is an \
        opaque with a kernel-checked witness); there is no sanctioned \
        path back. Revert."
    match env.find? n with
    | none =>
      throwError "RelSem boundary-opaque gate: {n} is MISSING from \
        the environment (renamed without re-pointing the gate?)"
    | some ci =>
      if ci matches ConstantInfo.axiomInfo _ then
        throwError "RelSem boundary-opaque gate: {n} exists as an \
          AXIOM — the boundary axioms were deleted in arc-17 S2b \
          (converted to opaques with kernel-checked witnesses); \
          reintroduction is a build failure, never a re-baseline."
      unless ci matches ConstantInfo.opaqueInfo _ do
        throwError "RelSem boundary-opaque gate: {n} is neither an \
          axiom nor an opaque — the effect-erasure armor requires the \
          constant to be IRREDUCIBLE (a plain def would let proofs \
          unfold the witness and relate states across the effect \
          boundary). Restore the opaque form."
  logInfo "RelSem boundary-opaque gate: with_tagDefs/forceIO exist, \
    are opaque (kernel-checked witnesses, not axioms), and are not \
    allowlisted"

/-- Non-theorem constants allowed to carry `sorryAx` IN ADDITION to the
    boundary. EMPTY since the arc-7 S2 eviction (finding-closed note in
    the header); the machinery stays, exact and fail-closed both ways,
    so any future sorryAx entry is a deliberate re-baseline here. -/
def sorryExceptions : List Name := []

/-! ## Curated pins — exact axiom sets of the load-bearing theorems.
    Re-baseline only deliberately, in the same commit, with the reason. -/

/-- info: 'RelSem.runNDFuel_sound' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms RelSem.runNDFuel_sound
/-- info: 'RelSem.runND_sound' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms RelSem.runND_sound
/-- info: 'RelSem.runNDFuel_mono' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms RelSem.runNDFuel_mono
/-- info: 'RelSem.Cerb.runNDActiveSound' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.runNDActiveSound
/-- info: 'RelSem.behaviors_sound' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms RelSem.behaviors_sound
/-- info: 'RelSem.Cerb.seqModel_behavior_sound' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.seqModel_behavior_sound
/-- info: 'RelSem.Cerb.seqModel_adequate_of_reach' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.seqModel_adequate_of_reach
/-- info: 'RelSem.Cerb.pointsToByte_functional' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.pointsToByte_functional
-- V2 (2026-08-28): T1 RE-PROVED through the per-round assertion
-- layer (RelSem/T1Proof.lean) — the registered Cns statement, the
-- cone EXACTLY the classical trio. Pinned exactly; any growth
-- (sorryAx, runEffectful, a boundary leak) is a build failure.
/-- info: 'RelSem.T1.t1_threaded_proved' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T1.t1_threaded_proved
-- V2 (2026-08-28): P01 (clamp0) PROVED — the first symbolic
-- data-dependent branch (the V-plan checkpoint; RelSem/P01Proof.lean)
-- + its UB-freedom face, both at the registered Cns statements.
-- Pinned exactly.
/-- info: 'RelSem.P01.p01_proved' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.P01.p01_proved
/-- info: 'RelSem.P01.p01_ubfree_proved' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.P01.p01_ubfree_proved
-- V2 (2026-08-28): T2 (add) PROVED — the two-argument protocol +
-- the checked add at range hypotheses; and its UB-freedom face.
/-- info: 'RelSem.T2.t2_threaded_proved' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T2.t2_threaded_proved
/-- info: 'RelSem.T2.t2_ubfree_proved' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T2.t2_ubfree_proved
-- V2 (2026-08-28): T3 (roundtrip) PROVED — the memory-WRITING
-- program through the create/store/kill round classes; + UB-freedom.
/-- info: 'RelSem.T3.t3_threaded_proved' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T3.t3_threaded_proved
/-- info: 'RelSem.T3.t3_ubfree_proved' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T3.t3_ubfree_proved
-- Substrate-mentioning theorems: pinned exactly so any growth
-- (sorryAx above all) is a build failure. DAEMON-free since the arc-8
-- S3 deletion (formerly it entered through the quoted generated
-- bodies).
/-- info: 'RelSem.Cerb.step_eval_pexpr_val_erase' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.step_eval_pexpr_val_erase
/-- info: 'RelSem.Cerb.pexprStep_val' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.pexprStep_val
/-- info: 'RelSem.Cerb.driver2_wrapper_defeq' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.driver2_wrapper_defeq
-- arc-7 S3: coverage-by-need micro-lemmas (RelSem/Machine.lean §
-- "Coverage-by-need", RelSem/Cerberus.lean liftMem_step_killed). The
-- generic app-equation layer is near-axiom-free (propext from the simp
-- rewrites); app_pick_singleton quotes `pick` (failwithI + threaded
-- [Inhabited] binders since arc-8 — its cone is now [propext]).
-- Pinned exactly.
/-- info: 'RelSem.step_done_inv' does not depend on any axioms -/
#guard_msgs in #print axioms RelSem.step_done_inv
/-- info: 'RelSem.app_bind_killed' depends on axioms: [propext] -/
#guard_msgs in #print axioms RelSem.app_bind_killed
/-- info: 'RelSem.app_liftND_killed' depends on axioms: [propext] -/
#guard_msgs in #print axioms RelSem.app_liftND_killed
/-- info: 'RelSem.app_pick_singleton' depends on axioms: [propext] -/
#guard_msgs in #print axioms RelSem.app_pick_singleton
/-- info: 'RelSem.Cerb.liftMem_step_active' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.liftMem_step_active
/-- info: 'RelSem.Cerb.liftMem_step_killed' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.liftMem_step_killed
-- arc-7 S3: the symbolic-argument harness (RelSem/Call.lean). Every
-- theorem below MENTIONS the harness computation `callND` (drive-path
-- generated substrate), so runEffectful enters through the quoted
-- bodies (initial_driver_state carries it). Pinned exactly — growth
-- (sorryAx above all) fails the build. `ofStatus_value_inv` is the
-- harness's one pure lemma and is pinned axiom-FREE.
/-- info: 'RelSem.Cerb.ofStatus_value_inv' does not depend on any axioms -/
#guard_msgs in #print axioms RelSem.Cerb.ofStatus_value_inv
-- arc-7 S5c (audit-1 F2): the CerbND-shaped UB-freedom surface.
-- arc-7 S3: the terminal-head outcome-set characterization (the slate-
-- path fuel-erasure instances, RelSem/RunND.lean + the model-level and
-- callConfig faces). The RunND layer is [propext]-grade (boundary
-- theorems); the callConfig corollaries quote the harness
-- substrate (runEffectful). The 30
-- FuelHooks wrapper-defeq theorems are rfl objects covered by the
-- sweep; `nd_bind_wrapper_defeq` is pinned as the exemplar (axiom-free).
/-- info: 'RelSem.runND_active' depends on axioms: [propext] -/
#guard_msgs in #print axioms RelSem.runND_active
/-- info: 'RelSem.runND_killed' depends on axioms: [propext] -/
#guard_msgs in #print axioms RelSem.runND_killed
/-- info: 'RelSem.behaviors_active_iff' depends on axioms: [propext] -/
#guard_msgs in #print axioms RelSem.behaviors_active_iff
/-- info: 'RelSem.behaviors_killed_iff' depends on axioms: [propext] -/
#guard_msgs in #print axioms RelSem.behaviors_killed_iff
/-- info: 'RelSem.Cerb.seqModel_behavior_running_active_iff' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.seqModel_behavior_running_active_iff
/-- info: 'RelSem.Cerb.seqModel_behavior_running_killed_iff' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.seqModel_behavior_running_killed_iff
/-- info: 'RelSem.FuelHooks.nd_bind_wrapper_defeq' does not depend on any axioms -/
#guard_msgs in #print axioms RelSem.FuelHooks.nd_bind_wrapper_defeq
-- arc-7 S4: the iris-lean coupling (RelSem/Iris{Lang,State,Rules,
-- Adequacy}.lean). iris-lean itself contributes NO axioms beyond the
-- classical trio (verified: every pure-coupling theorem below is
-- trio-only); the harness-mentioning theorems (wp_callND, the adequacy
-- chain) quote `callND`/`initial_driver_state` and inherit
-- runEffectful through the substrate. Pinned exactly — growth
-- (sorryAx above all) fails the
-- build. The terminal-head determinism lemmas are axiom-FREE.
/-- info: 'RelSem.step_running_active_inv' does not depend on any axioms -/
#guard_msgs in #print axioms RelSem.step_running_active_inv
/-- info: 'RelSem.step_running_killed_inv' does not depend on any axioms -/
#guard_msgs in #print axioms RelSem.step_running_killed_inv
-- (arc-9 S2 re-baseline, OwnP adoption: `stateIs_agree`/`stateIs_update`
-- are RETIRED — agreement/update now happen inside iris-lean's
-- `ownP_eq`/`ownP_lift_step`; the pins below cover the reworked
-- surface. Design: docs/2026-08-20_arc9-s1-design.md §1.1.)
-- arc-7 S4: T1 through the full WP route (RelSem/T1.lean), conditional
-- on the Layer-2 residual T1AppEq (blocked on the arc-3 F8 generated-
-- partials residue — see the T1.lean header). The program TERM
-- (T1Core/T1File — the emitted parsed AST) is boundary-clean: the AST
-- literals themselves are axiom-FREE; t1File adds only the classical
-- trio through convert_file/fromList. The theorems quote the harness
-- substrate (runEffectful). Pinned.
/-- info: 'RelSem.T1.idT1Decl' does not depend on any axioms -/
#guard_msgs in #print axioms RelSem.T1.idT1Decl
/-- info: 'RelSem.T1.t1File' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T1.t1File

-- (RelSem.T1.roundtrip_arith / RelSem.T2.catch_add_fact — walk-file
-- residents — DELETED at V0 with their files.)

-- The pinned fixture program terms (emitted, drift-gated). Pinned
-- exactly.
/-- info: 'RelSem.Slate.t2File' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Slate.t2File
/-- info: 'RelSem.Slate.t3File' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Slate.t3File
/-- info: 'RelSem.Slate.t4File' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Slate.t4File

-- (The arc-11 A-F1 "T5 FLAGSHIPS" pin block — entry5_walk + the
-- T5Iter env-lookup family at the clean quartet — RETIRED at arc-18
-- R4 with its files: T5-the-theorem is PROVED (RelSem.T5.T5Threaded,
-- pinned in the R4 block below at EXACTLY the classical trio — the
-- quartet's runEffectful is gone with the ambient-era substrate).
-- The env-lookup capability lives on ∀-k in T5Inv's St_lk* family,
-- swept trio-clean.)

/-! ## (RETIRED SECTION — arc-8 S3.) The arc-7 S5c DAEMON entry-vector
    census (a kernel walk pinning `failwith` and
    `instInhabitedAction_request2` as the exactly-two DAEMON
    referencers on the slate cones) lived here while DAEMON existed.
    The axiom family is now DELETED from LemLib and the census is
    superseded by the fail-closed ABSENCE GATE above (no constant
    named DAEMON/DAEMON1 may exist anywhere in this module's import
    closure; full generated-tree absence is the script census's job)
    together with the DAEMON-free curated pins. -/

/-! ## THE STATEMENT-TCB GATE (arc-7 S5a Task 4; REBUILT arc-7 S5c,
    audit-1 F2): a slate theorem's STATEMENT may mention only
    fuel-opsem-level objects. Mechanized: walk the constants of each
    slate theorem's TYPE, TRANSITIVELY unfolding every RelSem-rooted
    Prop-family def (`T?Statement`, `t?Spec`, `intRange`, `T4EnvHyp`,
    `CallHarnessAdequate`, `CallHarnessUBFree`, …) — audit-1 F2 showed
    the previous one-level walk let a Prop-def wrapper hide a
    relational-layer name (`CallUBFree` = `seqModel.UBFree`). FAIL THE
    BUILD if the walk reaches (a) an Iris-rooted constant, (b) a
    banned relational-layer internal, or (c) any RelSem-rooted
    NON-Prop constant outside the small positive allowlist of
    harness-surface/fixture-data names below (fail-closed: new
    statement vocabulary must be allowlisted deliberately, here).
    NEGATIVE-TESTED in-build on `t1_wp` (Iris statement) and on the
    permanent wrapper-hole probe (`wrapperHole_thm`), both of which
    the checker must reject. -/

open Lean in
/-- Names a slate STATEMENT must not mention (the Iris root covers
    WP/IProp/state-interpretation constants; the exact list covers the
    relational layer incl. the seqModel route — audit-1 F2's in-tree
    finding). -/
def stmtBannedExact : List Name :=
  -- (`RelSem.Cerb.stateIs` left this list at the 2026-08-27
  -- kill-list execution: its host IrisState.lean is DELETED and the
  -- gate's existence check is fail-closed on listed names.)
  [`RelSem.Step, `RelSem.Steps, `RelSem.CsSem,
   `RelSem.Cerb.DSteps, `RelSem.Cerb.DStep,
   `RelSem.Cerb.seqModel, `RelSem.ExecModel]

open Lean in
/-- The RelSem-rooted NON-Prop constants a slate statement MAY mention:
    the harness surface (`callND`, `intValue`) and the pinned fixture
    data (program terms, fs states, terminal states). Everything
    RelSem-rooted that is neither here nor a transparently-unfolded
    Prop-family def fails the gate. -/
def stmtAllowed : List Name :=
  -- (2026-08-27 kill-list execution: the ambient drDone rows and the
  -- t6/t7/corpus fixture-data rows left with their statements.
  -- V0 2026-08-27 freshness finalization: the drDone_thr terminal
  -- states left with the Outcomes statements; T5SeedApart +
  -- t4MinStaticSym — the seed-apartness guards — are DELETED (the
  -- consistency quantification replaces them); freshDrawsOf + the
  -- per-fixture prior vocabularies join.)
  [`RelSem.Cerb.callND, `RelSem.Cerb.intValue,
   `RelSem.T1.t1File, `RelSem.T1.t1Fs,
   `RelSem.T2.t2Fs, `RelSem.T3.t3Fs, `RelSem.T4.t4Fs,
   `RelSem.Slate.t2File, `RelSem.Slate.t3File, `RelSem.Slate.t4File,
   -- arc-16 S4: the seed-parametric initial state (fuel-opsem-level:
   -- mirrors the generated def with the seed explicit).
   `RelSem.Cerb.initial_driver_state_threaded,
   `RelSem.Slate.t5File, `RelSem.T5.t5Fs, `RelSem.T5.t5Spec,
   `RelSem.T5.T5EnvHypThr, `RelSem.T5.t5Range,
   -- V0: the consistency statement layer — the draw window (non-Prop
   -- def inside `ConsistentRun`'s transparent unfolding) + the pinned
   -- prior vocabularies (Nat-list literal fixture data, PriorCensus-
   -- gated below).
   `RelSem.Cerb.freshDrawsOf, `RelSem.Cerb.specifiedInt,
   `RelSem.T1.t1Prior, `RelSem.Slate.t2Prior, `RelSem.Slate.t3Prior,
   `RelSem.Slate.t4Prior, `RelSem.Slate.t5Prior,
   -- V0: the corpus batch-A statement vocabulary (program terms,
   -- prior vocabularies, the shared fs, the one non-Prop model fn).
   `RelSem.Corpus.p01File, `RelSem.Corpus.p02File,
   `RelSem.Corpus.p03File, `RelSem.Corpus.p09File,
   `RelSem.Corpus.p10File, `RelSem.Corpus.p11File,
   `RelSem.Corpus.p12File,
   `RelSem.Corpus.p01Prior, `RelSem.Corpus.p02Prior,
   `RelSem.Corpus.p03Prior, `RelSem.Corpus.p09Prior,
   `RelSem.Corpus.p10Prior, `RelSem.Corpus.p11Prior,
   `RelSem.Corpus.p12Prior,
   `RelSem.Corpus.corpusFs, `RelSem.Corpus.satAdd,
   -- V0 batch B: the memory-input rows' family builders + priors
   -- (the whole-program face's statement vocabulary; the builders
   -- are first-order executable file constructors).
   `RelSem.Corpus.p04FileOf, `RelSem.Corpus.p05FileOf,
   `RelSem.Corpus.p06FileOf, `RelSem.Corpus.p14FileOf,
   `RelSem.Corpus.p15FileOf,
   `RelSem.Corpus.p04Prior, `RelSem.Corpus.p05Prior,
   `RelSem.Corpus.p06Prior, `RelSem.Corpus.p14Prior,
   `RelSem.Corpus.p15Prior,
   `RelSem.Corpus.p07FileOf, `RelSem.Corpus.p08FileOf,
   `RelSem.Corpus.p07Prior, `RelSem.Corpus.p08Prior]

open Lean in
/-- Syntactic "ends in Prop" (Prop-family def: `Prop` or a pi chain
    into `Prop`) — the unfolding trigger for the transitive walk. -/
def endsInProp : Expr → Bool
  | .forallE _ _ b _ => endsInProp b
  | .mdata _ b => endsInProp b
  | .sort l => l == .zero
  | _ => false

open Lean in
/-- The banned/dis-allowed names reachable from `n`'s statement through
    the transitive Prop-def unfolding (empty = pass). -/
def stmtViolations (env : Environment) (n : Name) :
    Except String (List Name) := do
  let some ci := env.find? n
    | .error s!"statement gate: {n} not found"
  -- V0 (2026-08-27): the slate is registered as honest-unproved
  -- STATEMENT DEFS (Prop-family defs), not theorems — for a Prop-def
  -- target the walk seeds with the def ITSELF (the loop below then
  -- unfolds it transparently and walks its VALUE); for a theorem it
  -- walks the TYPE as before.
  let mut viol : Array Name := #[]
  let mut seen : NameSet := {}
  let mut queue : Array Name :=
    match ci with
    | .defnInfo dv => if endsInProp dv.type then #[n]
                      else dv.type.getUsedConstants
    | _ => ci.type.getUsedConstants
  while h : queue.size > 0 do
    let c := queue[queue.size - 1]
    queue := queue.pop
    if seen.contains c then continue
    seen := seen.insert c
    if c.getRoot == `Iris || stmtBannedExact.contains c then
      viol := viol.push c
      continue
    if c.getRoot == `RelSem then
      match env.find? c with
      | some (.defnInfo dv) =>
        if endsInProp dv.type then
          -- Prop-family wrapper: transparent — its CONTENT is walked
          queue := queue ++ dv.value.getUsedConstants
        else if !stmtAllowed.contains c then
          viol := viol.push c
      | _ =>
        if !stmtAllowed.contains c then viol := viol.push c
  .ok viol.toList

/-- PERMANENT NEGATIVE-TEST FIXTURE (audit-1 F2, the wrapper hole): a
    Prop-def wrapper hiding a relational-layer name behind two levels
    of indirection. Never a real statement — exists only so the gate's
    transitive walk is itself gate-tested. -/
def wrapperHoleProbe : Prop :=
  ∃ c, RelSem.Cerb.seqModel.UBFree c

/-- The wrapper-hole probe theorem the gate must REJECT. -/
theorem wrapperHole_thm : wrapperHoleProbe → wrapperHoleProbe := id

/-! ## THE CONCRETE-INPUT BAN (V0, 2026-08-27 — the ONE gate the
    forbidden class earned; catechism §III.1/§VII, assessment §2.6).
    An EXTENSION of this statement-TCB gate (same registration, new
    axis, negative-probed — no new gate script, anti-gate-grind):

    every REGISTERED slate statement must bind a universally
    quantified input that FLOWS INTO the harness input position — the
    call args of a call-boundary face, or the file (init encoding) of
    a whole-program face. Mechanically: the statement def's value must
    apply a registered input face DIRECTLY (fail-closed: a statement
    that hides its face behind a wrapper is rejected — apply faces at
    statement top level), and EVERY such application's input-position
    argument must depend on an enclosing ∀-binder (`hasLooseBVars`).
    Constant-args applications are rejected. FINITE-SAMPLE
    quantification is rejected on the `x ∈ [literal, …]` premise
    shape (a `Membership.mem` premise whose container is a
    cons/nil-literal spine). SCOPE HONESTY: these two mechanical
    checks catch the constant-args and ∈-literal-sample classes; other
    finite-sample costumes (disjunction-of-equalities, decidable
    range predicates over tiny bounds) are the catechism's §III.2
    anti-brute-force review obligation, not this walker's — bounds
    are reviewed at statement registration (the corpus §0 discipline).

    WAIVERS: empty at birth. Any entry requires an in-file [USER] tag
    at the waived statement AND a row here naming the operator
    decision — an [AGENT]-added waiver is a record-integrity
    finding. -/

open Lean in
/-- The registered input faces: (face constant, input-position
    argument index). Call faces carry inputs in `args`; whole-program
    faces carry them in the file (the init/model encoding). -/
def inputFaces : List (Name × Nat) :=
  [(`RelSem.Cerb.CallHarnessAdequateCns, 4),
   (`RelSem.Cerb.CallHarnessUBFreeCns, 4),
   (`RelSem.Cerb.HarnessRunsToCns, 1),
   (`RelSem.Cerb.CallHarnessAdequateThr, 4),
   (`RelSem.Cerb.CallHarnessUBFreeThr, 4),
   (`RelSem.Cerb.HarnessRunsToThr, 1)]

open Lean in
/-- Concrete-input waivers (EMPTY at birth; see the section note —
    entries require an in-file [USER] tag). -/
def concreteInputWaivers : List Name := []

open Lean in
/-- Is `e` a cons/nil list-literal spine? (The finite-sample container
    shape.) -/
partial def isListLiteral (e : Expr) : Bool :=
  if e.isAppOfArity ``List.nil 1 then true
  else if e.isAppOfArity ``List.cons 3 then isListLiteral (e.getArg! 2)
  else false

open Lean in
/-- The concrete-input scan: walk the statement value; count face
    applications with a quantified input; collect violations
    (constant-input face applications; ∈-literal-list premises). -/
partial def concreteInputScan (e : Expr)
    (acc : Nat × List String) : Nat × List String := Id.run do
  let mut (found, viols) := acc
  match e with
  | .app .. =>
    let fn := e.getAppFn
    if let .const c _ := fn then
      if let some (_, idx) := inputFaces.find? (fun p => p.1 == c) then
        if e.getAppNumArgs > idx then
          let input := e.getArg! idx
          if input.hasLooseBVars then
            found := found + 1
          else
            viols := viols ++
              [s!"face {c} applied at a CONSTANT input (no quantified \
                variable flows into argument {idx})"]
    for a in e.getAppArgs do
      (found, viols) := concreteInputScan a (found, viols)
    (found, viols) := concreteInputScan e.getAppFn (found, viols)
    return (found, viols)
  | .forallE _ t b _ =>
    -- finite-sample premise check on the domain
    if t.isAppOf ``Membership.mem then
      if (t.getAppArgs.any isListLiteral) then
        viols := viols ++
          ["finite-sample quantification (∈ a literal list) in a \
            premise — a sample set is not a ∀"]
    (found, viols) := concreteInputScan t (found, viols)
    (found, viols) := concreteInputScan b (found, viols)
    return (found, viols)
  | .lam _ t b _ =>
    (found, viols) := concreteInputScan t (found, viols)
    (found, viols) := concreteInputScan b (found, viols)
    return (found, viols)
  | .letE _ t v b _ =>
    (found, viols) := concreteInputScan t (found, viols)
    (found, viols) := concreteInputScan v (found, viols)
    (found, viols) := concreteInputScan b (found, viols)
    return (found, viols)
  | .mdata _ b => return concreteInputScan b (found, viols)
  | .proj _ _ b => return concreteInputScan b (found, viols)
  | _ => return (found, viols)

open Lean in
/-- The concrete-input check of one registered statement def
    (empty list = pass). -/
def concreteInputViolations (env : Environment) (n : Name) :
    Except String (List String) := do
  if concreteInputWaivers.contains n then return []
  let some (.defnInfo dv) := env.find? n
    | .error s!"concrete-input ban: {n} is not a definition"
  let (found, viols) := concreteInputScan dv.value (0, [])
  if found == 0 && viols.isEmpty then
    return ["no registered input-face application with a quantified \
      input found (faces must be applied directly in the statement \
      body, with a ∀-bound input flowing into the input position)"]
  return viols

/-! ### The ban's PERMANENT NEGATIVE-TEST FIXTURES (plants, both
    directions: the checker must REJECT both; the real slate passing
    is the positive direction). Never real statements. -/

/-- Constant-args probe: the emblem of the forbidden class
    (`clamp0(-3)`-style — a pinned literal argument). -/
def constArgsProbe : Prop :=
  RelSem.Cerb.CallHarnessAdequateCns RelSem.T1.t1Prior
    RelSem.T1.t1File.tagDefs RelSem.T1.t1File "id"
    [RelSem.Cerb.intValue 42] RelSem.T1.t1Fs (RelSem.T1.t1Spec 42)

/-- Finite-sample probe: a "family" over a pinned 3-point sample. -/
def finiteSampleProbe : Prop :=
  ∀ x ∈ [(1 : Int), 2, 3],
    RelSem.Cerb.CallHarnessAdequateCns RelSem.T1.t1Prior
      RelSem.T1.t1File.tagDefs RelSem.T1.t1File "id"
      [RelSem.Cerb.intValue x] RelSem.T1.t1Fs (RelSem.T1.t1Spec x)

open Lean in
#eval show CoreM Unit from do
  let env ← getEnv
  -- Fail-closed existence checks on the gate's own lists (a rename must
  -- re-point the gate, never silently drop a check).
  for n in stmtBannedExact ++ stmtAllowed do
    let some _ := env.find? n
      | throwError "RelSem statement gate: listed name {n} is MISSING \
          (renamed without re-pointing the gate?)"
  let slate : List Name :=
    -- 2026-08-27 KILL-LIST EXECUTION: the ambient 16-theorem family
    -- (T1–T4 quadruples), the T6/T7 pairs and the 22 R6 corpus
    -- theorems — all CONCRETE-INPUT or superseded-ambient — are
    -- DELETED (operator-ratified; record
    -- docs/2026-08-27_kill-list-execution.md).
    -- V0 2026-08-27: the slate is re-registered as HONEST-UNPROVED
    -- STATEMENT DEFS in the consistency-freshness house shape (the
    -- theorems and their walk supply are deleted — kill basket,
    -- record docs/2026-08-27_v0-statements-and-ban.md; the
    -- ThreadedOutcomes statements — exact outcome-list pins over
    -- internal terminal states — left with the walk vocabulary).
    [`RelSem.T1.T1ThreadedStatement, `RelSem.T1.T1ThreadedUBFreeStatement,
     `RelSem.T2.T2ThreadedStatement, `RelSem.T2.T2ThreadedUBFreeStatement,
     `RelSem.T3.T3ThreadedStatement, `RelSem.T3.T3ThreadedUBFreeStatement,
     `RelSem.T4.T4ThreadedStatement, `RelSem.T4.T4ThreadedUBFreeStatement,
     `RelSem.T5.T5ThreadedStatement, `RelSem.T5.T5ThreadedUBFreeStatement,
     -- V0: THE CORPUS SLATE, batch A (the frozen corpus's scalar
     -- call-boundary rows P01/P02/P03/P09/P10/P11/P12 — honest-
     -- unproved targets in the consistency-freshness shape; the
     -- memory-input rows P04–P08/P14/P15 and P13 are batch B /
     -- findings, see the V0 record §statements).
     `RelSem.Corpus.P01Statement, `RelSem.Corpus.P01UBFreeStatement,
     `RelSem.Corpus.P02Statement, `RelSem.Corpus.P02UBFreeStatement,
     `RelSem.Corpus.P03Statement, `RelSem.Corpus.P03UBFreeStatement,
     `RelSem.Corpus.P09Statement, `RelSem.Corpus.P09UBFreeStatement,
     `RelSem.Corpus.P10Statement, `RelSem.Corpus.P10UBFreeStatement,
     `RelSem.Corpus.P11Statement, `RelSem.Corpus.P11UBFreeStatement,
     `RelSem.Corpus.P12Statement, `RelSem.Corpus.P12UBFreeStatement,
     -- V0 batch B: the memory-input rows (whole-program face —
     -- HarnessRunsToCns's Active-conjunct already excludes UB, so
     -- one statement per row; P07/P08 [struct arena] and P13
     -- [malloc linkage] are V0-record findings/parks).
     `RelSem.Corpus.P04Statement, `RelSem.Corpus.P05Statement,
     `RelSem.Corpus.P06Statement, `RelSem.Corpus.P14Statement,
     `RelSem.Corpus.P15Statement,
     `RelSem.Corpus.P07Statement, `RelSem.Corpus.P08Statement]
  for n in concreteInputWaivers do
    let some _ := env.find? n
      | throwError "concrete-input ban: waived name {n} is MISSING \
          (renamed without re-pointing the waiver?)"
  for n in slate do
    match stmtViolations env n with
    | .error e => throwError "{e}"
    | .ok [] => pure ()
    | .ok vs =>
      throwError "RelSem statement gate: {n}'s STATEMENT mentions \
        banned constants {vs} — slate statements are fuel-opsem only"
    -- THE CONCRETE-INPUT BAN (V0 axis, same registration)
    match concreteInputViolations env n with
    | .error e => throwError "{e}"
    | .ok [] => pure ()
    | .ok vs =>
      throwError "RelSem statement gate (CONCRETE-INPUT BAN): {n} — \
        {vs} — quantified all-input properties are the MINIMUM \
        specification class (catechism §II/§III.1); fix the \
        statement or obtain an operator waiver ([USER] tag required)"
  -- NEGATIVE TEST 1: an Iris-statement theorem must be rejected.
  -- (2026-08-27 kill-list execution: the historical probe subject
  -- `t1_wp` died with the ambient family; `wpk_load` — the heap-route
  -- WP load rule, an Iris entailment by construction — replaces it.)
  match stmtViolations env `RelSem.CerbSt.wpk_load with
  | .error e => throwError "{e}"
  | .ok [] =>
    throwError "RelSem statement gate NEGATIVE TEST FAILED: wpk_load's \
      Iris statement passed the checker — the gate is not detecting"
  | .ok _ => pure ()
  -- NEGATIVE TEST 2 (permanent, audit-1 F2): the wrapper-hole probe
  -- must be rejected, and specifically by seeing seqModel THROUGH the
  -- Prop-def wrapper.
  match stmtViolations env `RelSem.Audit.wrapperHole_thm with
  | .error e => throwError "{e}"
  | .ok vs =>
    unless vs.contains `RelSem.Cerb.seqModel do
      throwError "RelSem statement gate NEGATIVE TEST FAILED: the \
        wrapper-hole probe did not surface seqModel through the \
        Prop-def wrapper (transitive walk broken?) — got {vs}"
  -- NEGATIVE TESTS 3+4 (V0, the concrete-input ban's plants, both
  -- directions of the forbidden class): the constant-args probe and
  -- the finite-sample probe must BOTH be rejected.
  match concreteInputViolations env `RelSem.Audit.constArgsProbe with
  | .error e => throwError "{e}"
  | .ok [] =>
    throwError "CONCRETE-INPUT BAN NEGATIVE TEST FAILED: the \
      constant-args probe passed the checker — the ban is not \
      detecting"
  | .ok _ => pure ()
  match concreteInputViolations env `RelSem.Audit.finiteSampleProbe with
  | .error e => throwError "{e}"
  | .ok [] =>
    throwError "CONCRETE-INPUT BAN NEGATIVE TEST FAILED: the \
      finite-sample probe passed the checker — the ban is not \
      detecting"
  | .ok _ => pure ()
  logInfo s!"RelSem statement gate: {slate.length} slate statements \
    fuel-opsem-clean + concrete-input-clean (negative tests: wpk_load, \
    the wrapper-hole probe, the constant-args probe and the \
    finite-sample probe all correctly rejected)"

/-! ## THE PRIOR-VOCABULARY PINS (V0): the consistency statements'
    `prior` lists vs the fixture terms' emitted symbol vocabulary —
    exact, both directions, fail-closed (instrument:
    RelSem/PriorCensus.lean; untrusted-evaluator/test-ledger grade,
    TEMPORAL — mover: a total Core-AST symbol census, V2-class). -/

open Lean in
#eval show CoreM Unit from do
  let env ← getEnv
  let pins : List (Name × List Nat × String) :=
    [(`RelSem.T1.t1File, RelSem.T1.t1Prior, "t1Prior"),
     (`RelSem.Slate.t2File, RelSem.Slate.t2Prior, "t2Prior"),
     (`RelSem.Slate.t3File, RelSem.Slate.t3Prior, "t3Prior"),
     (`RelSem.Slate.t4File, RelSem.Slate.t4Prior, "t4Prior"),
     (`RelSem.Slate.t5File, RelSem.Slate.t5Prior, "t5Prior"),
     (`RelSem.Corpus.p01File, RelSem.Corpus.p01Prior, "p01Prior"),
     (`RelSem.Corpus.p02File, RelSem.Corpus.p02Prior, "p02Prior"),
     (`RelSem.Corpus.p03File, RelSem.Corpus.p03Prior, "p03Prior"),
     (`RelSem.Corpus.p09File, RelSem.Corpus.p09Prior, "p09Prior"),
     (`RelSem.Corpus.p10File, RelSem.Corpus.p10Prior, "p10Prior"),
     (`RelSem.Corpus.p11File, RelSem.Corpus.p11Prior, "p11Prior"),
     (`RelSem.Corpus.p12File, RelSem.Corpus.p12Prior, "p12Prior"),
     (`RelSem.Corpus.p04FileOf, RelSem.Corpus.p04Prior, "p04Prior"),
     (`RelSem.Corpus.p05FileOf, RelSem.Corpus.p05Prior, "p05Prior"),
     (`RelSem.Corpus.p06FileOf, RelSem.Corpus.p06Prior, "p06Prior"),
     (`RelSem.Corpus.p14FileOf, RelSem.Corpus.p14Prior, "p14Prior"),
     (`RelSem.Corpus.p15FileOf, RelSem.Corpus.p15Prior, "p15Prior"),
     (`RelSem.Corpus.p07FileOf, RelSem.Corpus.p07Prior, "p07Prior"),
     (`RelSem.Corpus.p08FileOf, RelSem.Corpus.p08Prior, "p08Prior")]
  for (root, pinned, pinName) in pins do
    match RelSem.PriorCensus.checkPin env root pinned pinName with
    | .ok () => pure ()
    | .error e => throwError "{e}"
  logInfo s!"PriorCensus gate: {pins.length} prior-vocabulary pins \
    exact against the emitted fixture terms (both directions)"

-- arc-16 S1: THE PER-STEP LANGUAGE (RelSem/PerStep*.lean — the Iris
-- refounding's language layer; design record
-- docs/2026-08-24_arc16-s1-language-instance.md). The generic layer
-- (KExpr/KStep/completeness) is boundary-clean ([propext, Quot.sound]
-- grade — Quot.sound enters through funext in the fold congruence);
-- the coupling layer is trio-only; the harness-mentioning theorems
-- (callK anchors consume the quoted substrate transparently; the
-- adequacy/smoke chain quotes `callND`/`initial_driver_state`)
-- inherit runEffectful exactly as the arc-7 route's. T1_perStep's
-- cone is IDENTICAL to the committed T1's. Pinned exactly.
/-- info: 'RelSem.ksteps_of_runNDFuel' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms RelSem.ksteps_of_runNDFuel
/-- info: 'RelSem.ksteps_of_runND' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms RelSem.ksteps_of_runND
/-- info: 'RelSem.runNDFuel_bind_fuel_irrel' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms RelSem.runNDFuel_bind_fuel_irrel
/-- info: 'RelSem.runNDFuel_succ_congr' depends on axioms: [propext] -/
#guard_msgs in #print axioms RelSem.runNDFuel_succ_congr
/-- info: 'RelSem.kstep_seq_active_inv' does not depend on any axioms -/
#guard_msgs in #print axioms RelSem.kstep_seq_active_inv
/-- info: 'RelSem.kval_stuck' does not depend on any axioms -/
#guard_msgs in #print axioms RelSem.kval_stuck
/-- info: 'RelSem.Cerb.instLanguageKDrive' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.instLanguageKDrive
/-- info: 'RelSem.Cerb.ksteps_erased' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.ksteps_erased
/-- info: 'RelSem.Cerb.wpk_done' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.wpk_done
/-- info: 'RelSem.Cerb.callFinishK_denote' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.callFinishK_denote
/-- info: 'RelSem.Cerb.callK_denote' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.callK_denote

-- V1 (2026-08-28): THE DECOMPOSED MACHINE-STATE RESOURCE
-- (RelSem/MemLocal + CerbStateRA + CerbStateWP + CerbStateAdequacy +
-- CerbStateDemo; the arc-16 S2 heap RA re-founded at component
-- granularity — env cells / control token / supplies / memory
-- residual; record docs/2026-08-28_v1-assertion-layer.md). Every
-- cone is EXACTLY the classical trio; the rules quantify over
-- programs and the bridges quote only the threaded substrate — no
-- runEffectful anywhere. Pinned exactly.
/-- info: 'RelSem.Cerb.writeBytesTo_eq' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.writeBytesTo_eq
/-- info: 'RelSem.Cerb.readBytesFrom_of_pointwise' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.readBytesFrom_of_pointwise
/-- info: 'RelSem.Cerb.lem_int_beq_eq_true_iff' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.lem_int_beq_eq_true_iff
/-- info: 'RelSem.Cerb.lem_int_beq_eq_false_iff' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.lem_int_beq_eq_false_iff
/-- info: 'RelSem.Cerb.lem_int_contains_eq_false_of_not_mem' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.lem_int_contains_eq_false_of_not_mem
/-- info: 'RelSem.Cerb.MemInv.store' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.MemInv.store
/-- info: 'RelSem.Cerb.MemInv.alloc' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.MemInv.alloc
/-- info: 'RelSem.Cerb.MemInv.kill' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.MemInv.kill
/-- info: 'RelSem.CerbSt.interp_ctl_agree' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.CerbSt.interp_ctl_agree
/-- info: 'RelSem.CerbSt.interp_env_lookup' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.CerbSt.interp_env_lookup
/-- info: 'RelSem.CerbSt.interp_mrest_agree' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.CerbSt.interp_mrest_agree
/-- info: 'RelSem.CerbSt.interp_alloc_lookup' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.CerbSt.interp_alloc_lookup
/-- info: 'RelSem.CerbSt.interp_bytes_lookup' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.CerbSt.interp_bytes_lookup
/-- info: 'RelSem.CerbSt.interp_ctl_move' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.CerbSt.interp_ctl_move
/-- info: 'RelSem.CerbSt.interp_env_write' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.CerbSt.interp_env_write
/-- info: 'RelSem.CerbSt.interp_store_update' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.CerbSt.interp_store_update
/-- info: 'RelSem.CerbSt.interp_alloc_update' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.CerbSt.interp_alloc_update
/-- info: 'RelSem.CerbSt.interp_kill_update' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.CerbSt.interp_kill_update
/-- info: 'RelSem.CerbSt.wpk_seq_res_det' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.CerbSt.wpk_seq_res_det
/-- info: 'RelSem.CerbSt.wpk_load' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.CerbSt.wpk_load
/-- info: 'RelSem.CerbSt.wpk_store' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.CerbSt.wpk_store
/-- info: 'RelSem.CerbSt.wpk_alloc' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.CerbSt.wpk_alloc
/-- info: 'RelSem.CerbSt.wpk_kill' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.CerbSt.wpk_kill
/-- info: 'RelSem.CerbSt.wpk_seq_ctl' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.CerbSt.wpk_seq_ctl
/-- info: 'RelSem.CerbSt.wpk_seq_ctl_env1' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.CerbSt.wpk_seq_ctl_env1
/-- info: 'RelSem.CerbSt.wpk_seq_env_write' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.CerbSt.wpk_seq_env_write
/-- info: 'RelSem.CerbSt.wpk_get_done_ctl' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.CerbSt.wpk_get_done_ctl
/-- info: 'RelSem.CerbSt.cerbSt_adequacy' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.CerbSt.cerbSt_adequacy
/-- info: 'RelSem.CerbSt.kAdequateSt_of_wp' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.CerbSt.kAdequateSt_of_wp
/-- info: 'RelSem.CerbSt.kCallHarnessAdequateThrSt_of_wp' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.CerbSt.kCallHarnessAdequateThrSt_of_wp
/-- info: 'RelSem.CerbSt.kCallHarnessUBFreeThrSt_of_wp' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.CerbSt.kCallHarnessUBFreeThrSt_of_wp
/-- info: 'RelSem.CerbSt.kCallHarnessAdequateCnsSt_of_wp' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.CerbSt.kCallHarnessAdequateCnsSt_of_wp
/-- info: 'RelSem.CerbSt.kCallHarnessUBFreeCnsSt_of_wp' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.CerbSt.kCallHarnessUBFreeCnsSt_of_wp
/-- info: 'RelSem.CerbSt.MemInv_initial' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.CerbSt.MemInv_initial
/-- info: 'RelSem.CerbSt.two_alloc_frame' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.CerbSt.two_alloc_frame
/-- info: 'RelSem.CerbSt.Demo.demo_wp' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.CerbSt.Demo.demo_wp
/-- info: 'RelSem.CerbSt.Demo.demo_adequate' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.CerbSt.Demo.demo_adequate

-- arc-16 S3 (post arc-18 C2 deletions): THE RUNNER ALGEBRA +
-- WP-TACTICS (RelSem/PerStepRunner + PerStepTactics +
-- PerStepTacSmoke; design record
-- docs/2026-08-24_arc16-s3-laws-and-tactics.md). The dormant S3
-- half — PerStepPeel (dnmsK/driver2K/callK2 + runner_eq bridges)
-- and PerStepLaws (the 12 wpk_round_* laws, wpk_ite, wpk_pcs_*,
-- the _of_wpK2 adequacy bridges) — was DELETED at arc-18 C2 per
-- the Q1 [USER] ruling (zero live consumers; the two live seq laws
-- were re-homed into PerStepIris at C1; archive = the arc-16 S3
-- record; the cmm arc re-derives per-round ND granularity against
-- the C1 registry when genuinely needed). Their pins were removed
-- in the deleting commit. The runner algebra is
-- [propext(,Quot.sound)]-grade; the T1 tactic smoke inherits the
-- temporal effect boundary's runEffectful through the quoted
-- harness substrate, IDENTICAL to the committed T1's cone. Pinned
-- exactly.

-- arc-16 S4: THE THREADED EFFECT STATE + THE ACCEPTANCE RE-PROOF
-- (RelSem/Threaded.lean + the T?Threaded fixture family; record
-- docs/2026-08-24_arc16-s4-acceptance.md). The ∀-seed statements are
-- STRONGER than the ambient originals, and their cones are EXACTLY
-- the classical trio — the seed-parametric initial state removes
-- `runEffectful`'s entry point (the [USER 2026-08-24] amendment,
-- executed; the axiom itself remains declared for the compiled/driver
-- path — what tightens here is the THEOREM cones). The ambient-bridge
-- lemmas (and only they) mention the ambient state and wear the
-- boundary axiom DELIBERATELY — the labeled pins below document the
-- impure side. Pinned exactly; growth fails the build.
-- (RelSem.T1.round0_thr — a T1Threaded hand round — DELETED at V0
-- with the walk supply.)
-- arc-17 S1: the label-resolution twins (round6_thr/round13_thr/
-- round21_thr) are DISSOLVED — the ambient eval rounds are ∀-run-
-- state through the construct-law registry (RelSem.ConstructLaws)
-- and are pinned trio here (they no longer mention any concrete run
-- state, so the ambient files' rs ladders can't pull the boundary
-- axiom in).
/-- info: 'RelSem.Laws.seu_read_bind' depends on axioms: [propext] -/
#guard_msgs in #print axioms RelSem.Laws.seu_read_bind
/-- info: 'RelSem.Laws.erun_jump_m' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Laws.erun_jump_m
/-- info: 'RelSem.Laws.ndct_offer1' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Laws.ndct_offer1
/-- info: 'RelSem.Laws.driver2_done' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Laws.driver2_done
/-- info: 'RelSem.Laws.inject_ptr_arg1' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Laws.inject_ptr_arg1
/-- info: 'RelSem.Laws.callND_errno' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Laws.callND_errno
/-- info: 'RelSem.Laws.get_ths_eq' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Laws.get_ths_eq
/-- info: 'RelSem.Laws.driver_update_ts' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Laws.driver_update_ts

-- arc-18 C1: THE ONE REGISTRY census pin (register row R4 — the
-- machine-indexed law interface). The pin makes the registered
-- population EXACT in-build: a law silently dropping out of (or
-- sneaking into) the registry fails the build. Re-baseline
-- deliberately, same commit, with the reason. Population at C1:
-- construct 8 (ConstructLaws) + roundGlue 3 + advance 4 + perform 5
-- (Kit/Round) + memBlock 5 + memRW 7 (Kit/Mem incl. the C1-salvaged
-- read-over-write laws) + envMap 3 (Kit/Map) + envAlg 3 (Kit/Env) +
-- loop 2 (Kit/Loop) + wpSeq 2 (the re-homed live seq laws,
-- PerStepIris) + heapWP 4 (CerbHeapWP — the wp_load/store/alloc/kill
-- rules; macro-side query conversion rides C2's restatement) = 46.
-- Census re-baseline 46 → 47 (arc-18 C2): `inject_ptr_arg2` — the
-- two-scalar-argument caller protocol registers as a construct law
-- (the engine-to-law rule: the two-parameter inject stage recurs, so
-- it is a law, not per-fixture text; born with the T2 migration).
-- Census re-baseline 47 → 55 (arc-18 C2): the heapWalk lane — the
-- eight walk-rule faces the heap-route macros apply
-- (rest/read1/read2/allocStore/allocStore2/scratch1/get/getDone,
-- CerbHeapWalk) register; the registry-backing check in
-- CerbHeapWalk.lean makes a macro-backing law leaving the registry
-- build-fatal (the C1 heap-macro handoff, adjudicated:
-- registry-as-source-of-truth; goal-form-query APPLICATION is
-- arc-19's search). The wpSeq lane's two OwnP faces stay registered
-- while their consumers (T6Probe's walk + the C5-bound smokes)
-- remain on the transitional OwnP surface.
-- Census re-baseline 55 → 57 (arc-18 C3): the evalPull lane — THE
-- PULL_CONSTRAINED IDENTITY LAW's two faces (fuel + wrapper,
-- Kit/Eval.lean): pull_constrained at constraint-free pexprs is the
-- pullSpine rebuild (the arc-17 S3 record §3.4's priced mechanism —
-- "a LAW, not a lane"); the constraint-set dedup wall deletes by
-- construction wherever the walk crosses the symbolic-exc
-- eval boundary.
-- Census re-baseline 57 → 60 (arc-18 C3): the evalArith lane — the
-- conv/catch arithmetic laws (conv_int_signed_range /
-- catch_add_signed_range, Kit/Eval.lean): the T5 body walk's
-- round-35 tower cascade resolved as once-proved laws (identity /
-- guarded sum at in-range operands), consumed by the mintConvArith
-- lane with omega-discharged range premises — plus the envMap
-- empty-lookup base case (fmapLookupBy_empty, Kit/Map.lean: the
-- core_extern wrapper at freshly-drawn symbols under the env fence).
-- 60 → 66 (arc-18 C3b: the memRW READ-OVER-UPDATE completion the
-- three T5 walks measured out — writeBytesTo_lastAddress/
-- writeBytesTo_nextAllocId [the create rounds' supply projections
-- over open-map ladders], tm_get?_insert_eq/tm_get?_insert_skip
-- [post-create allocation-table reads], tm_get?_erase_ne/
-- list_contains_cons_ne [post-kill reads]; all Kit/Mem,
-- fixture-free).
-- 66 → 69 (arc-18 C4: the WHOLE-PROGRAM DRIVE surfaces the divmod
-- walk measured out — mem_store_lock_block [memBlock: the block-scope
-- const-array init store, insert-canonical readonly flip],
-- advance_memop_request + perform_memop_pvfd [advance/perform: the
-- Ememop lane's driver layer + PtrValidForDeref, consumed by the new
-- thin mintMemopRound dispatcher]; probe evidence: 74 divmod-plant
-- drive rounds minted incl. store_lock and memop classes; the walk
-- itself parks at the ground-mode materialization frontier —
-- docs/2026-08-26_arc18-c4-statement-homing.md §4).
-- 69 → 76 (arc-18 R1, the open-memory minting mode: the seven
-- remaining writeBytesTo pass-through projection laws
-- [nextIota/iotaMap/varargs/nextVarargsId/dynamicAddrs/lastUsed/
-- requested] — the T6 open drive's Erun round rebuilds the memory
-- record field-by-field over the folded ladder, so every non-bytemap
-- field needs its registered projection; all Kit/Mem, fixture-free).
-- 76 → 92 (arc-18 R2, the segment layer: loop 2 → 5 [the [F1]
-- variable-round `iter_compose_var`/`_from` + the ∃-round `Seg.iter`,
-- all Kit/Segment, fixture-free] + the T6 fixture's registered
-- EQUATION SUPPLY under the new supply kinds — segEq 9 [the k-stage
-- open equations + driver2_o], segFact 3 [address-arithmetic facts],
-- segCanon 1 [the nd_get representative]; supply entries are
-- per-fixture BY DESIGN, visible per-kind here — the engine-side
-- minting of supply entries is the registered arc-19 frontier).
-- 92 → 105 (arc-18 R2, the t7 slice: heapWalk 8 → 9 [the write1
-- rule — the loop atom's read-write store ladder] + t7's registered
-- equation supply [segEq 9 → 18, segFact 3 → 5, segCanon 1 → 2] —
-- per-fixture supply entries by design, visible per kind).
-- 105 → 106 (arc-18 R4, the scratch2 engine leg: heapWalk 9 → 10 —
-- `wpk_seq_scratch2_ecast`, the two-scratch loop atom at the C3b
-- pointwise final-state interface; once-proved, fixture-free).
-- 106 → 130 (arc-18 R4, the T5 fixture's registered equation supply:
-- segEq 18 → 27 [the t5File k-stage open equations + the scratch2
-- driver atom], segFact 5 → 18 [address arithmetic, the t5Fin
-- pointwise final-state facts, the ρ' scalar pins, geometry],
-- segCanon 2 → 3, segPost 0 → 1 [the closed-form readout] —
-- per-fixture supply entries by design, visible per kind).
-- 130 → 168 (arc-18 R4, T1/T2/T3 re-housed through the layer: their
-- k-stage open equations + driver atoms + canon representatives +
-- address facts join the registry [segEq 27 → 54, segFact 18 → 26,
-- segCanon 3 → 6] — per-fixture supply entries by design).
-- 168 → 191 (arc-18 R5, T4-apartness through the layer: heapWalk
-- 10 → 11 [wpk_seq_scratch1p — the one-scratch multi-layer atom at
-- the scratch2 pointwise interface, once-proved, fixture-free];
-- the t4 fixture's registered equation supply — segEq 54 → 63
-- [the t4File k-stage open equations + the scratch1p driver atom],
-- segFact 26 → 37 [address arithmetic, the t4Fin pointwise
-- final-state facts, the ρ' scalar pins, geometry], segCanon 6 → 7,
-- segPost 1 → 2 [the readout] — per-fixture supply entries by
-- design, visible per kind).
-- 191 → 252 (arc-18 R6 batch 1, the breadth-campaign EASY tier
-- e1–e5: five fixtures' registered equation supply — segEq 63 → 108
-- [per fixture: 8 k-stage open equations + the driver atom; read1
-- atoms for e1/e2/e4/e5, scratch1 for e3], segFact 37 → 48 [the
-- arg/errno address facts ×5 + e3's scratch address fact],
-- segCanon 7 → 12 [one nd_get representative per fixture] — ZERO
-- new engine laws: heapWalk unchanged at 11; the marginal law rate
-- for this batch is entirely per-fixture supply, the arc-19
-- minting-frontier shape).
-- 252 → 302 (arc-18 R6 batch 2, the CENSUS tier c4/c5/c3a/c3b:
-- four fixtures' registered supply — segEq 108 → 144 [k-stage
-- spines + driver atoms: read1 c4, scratch1 c5, read2 c3a (the
-- first argobj2/read2 corpus uses), write1 c3b (the loop)],
-- segFact 48 → 58 [address facts; c3a has three (two args), c5
-- has three (scratch)], segCanon 12 → 16 — ZERO new engine laws
-- again: heapWalk unchanged at 11; the batch consumed five
-- DISTINCT existing atom shapes with no additions).
-- 302 → 327 (arc-18 R6 batch 3: memBlock 6 → 7 — the ONE new
-- engine-lane law of the whole campaign so far, `mem_pvfd_block`
-- (the array lane's PtrValidForDeref at open memory; the fixture
-- itself is PARKED, the law + feeder stay); segEq 144 → 162,
-- segFact 58 → 62, segCanon 16 → 18 — the x7/x2 edge fixtures'
-- per-fixture supply).
-- 327 → 328 (2026-08-27 delta disposition, kill-list execution
-- commit 1: memRW 20 → 21 — `readBytesFrom_writeBytesTo_within`
-- (Kit/Mem), the sub-range read-over-write law salvaged from the
-- killed worker's delta per the assessment §6 (C-7 class, RefinedC
-- array.v / caesium heap_mapsto_app lineage); the rest of the
-- delta (C9 rework, Lanes `within` arm, C9T) was dropped
-- per the disposition record).
-- 328 → 166 (2026-08-27 KILL-LIST EXECUTION: the killed fixtures'
-- per-fixture supply entries left with their files — segEq 162 → 45,
-- segFact 62 → 32, segCanon 18 → 5 [the t1–t5 threaded supply
-- remains, killed-by-registration pending the B-plan re-proof];
-- segPost unchanged 2; the wpSeq lane's two OwnP faces
-- [wpk_seq_active_ecast/_proj] left with PerStepOwnP.lean — the lane
-- empties; ALL engine lanes unchanged: advance 5, construct 9,
-- envAlg 3, envMap 4, evalArith 2, evalPull 2, heapWP 4, heapWalk
-- 11, loop 5, memBlock 7, memRW 21, perform 6, roundGlue 3. Record:
-- docs/2026-08-27_kill-list-execution.md.)
-- 78 → 71 (V1 2026-08-28, THE WHOLE-STATE ROUTE DELETION — record
-- docs/2026-08-28_v1-assertion-layer.md: the heapWP 4 re-registered
-- at the DECOMPOSED interpretation (memory-residual granularity),
-- heapWalk 11 DELETED with CerbHeapWalk (the rest-pinning walk
-- rules — zero consumers post-V0), stateWP 4 born: the ctl/env-cell
-- rules of the assertion layer.)
-- 166 → 78 (V0 2026-08-27, THE KILL BASKET — record
-- docs/2026-08-27_v0-statements-and-ban.md: the t1–t5 threaded
-- per-fixture supply left with its files [segEq 45 → 0, segFact
-- 32 → 0, segCanon 5 → 0, segPost 2 → 0 — the killed-by-registration
-- §3 row, executed at V0 with the walk engine rooms]; loop 5 → 1
-- [the iter_compose family died with Kit/Loop, conversion C-14;
-- `Seg.iter` — the ∃-round survivor — is the lane's one law]. ALL
-- other engine lanes unchanged: advance 5, construct 9, envAlg 3,
-- envMap 4, evalArith 2, evalPull 2, heapWP 4, heapWalk 11,
-- memBlock 7, memRW 21, perform 6, roundGlue 3.)
-- (71 → 82, V2 C2: envMap +2 [lookup-congr + singleton-miss], stateWP
-- +9 [the case-split trio + read-ctl + the ctl-sup pair + the birth
-- trio] — same-commit provenance.)
-- (82 → 87, V2 C2b: evalPull +3 [se_sym_hit + the boolean-guard
-- fusions — Kit/EvalStep, the pure-eval construct laws], stateWP +2
-- [ctl-sup-mem + alloc-store] — same-commit provenance.)
-- (87 → 90, V2 C3: evalPull +2 [se_call + aux2_sym_hit], stateWP +1
-- [read-ctl-dom] — same-commit provenance.)
-- (sweep 3752 → 3769, V2 verify_fn revival: the FnSpec Cns role
-- [VerifiedCns/VerifiedUBCns/WpObCns/dischargeCns/dischargeUBCns] +
-- the Cns statement shapes + p01FnSpec; p01_proved/p01_ubfree_proved
-- re-routed THROUGH verify_fn — same-commit provenance.)
-- (96 → 99, V2 T3: stateWP +3 [ctl-sup-alloc + ctl-sup-store +
-- ctl-sup-kill — the memory-writing round classes]; sweep
-- 3590 → 3752 (the closure gains T3Rounds/T3Proof) — same-commit
-- provenance.)
-- (95 → 96, V2 T2: stateWP +1 [alloc-store2 — the two-argument
-- inject]; sweep 3432 → 3590 (the closure gains T2Rounds/T2Proof) —
-- same-commit provenance.)
-- (92 → 95, V2 P01: evalPull +2 [se_ctor_tuple + se_case_sel],
-- stateWP +1 [ctl-env2]; sweep 3180 → 3432 (the closure gains
-- P01Rounds/P01Proof) — same-commit provenance.)
-- (90 → 92, V2 C3b: Audit's closure gains RelSem.T1Rounds/T1Proof
-- (the T1 per-round engine + proof), pulling PerStepPeel/PerStepObs
-- in — envMap +1, stateWP +1 previously outside the closure —
-- same-commit provenance.)
-- (99 → 107, V2b segment layer: segLink +8 [link_ctl/env1/env2/
-- birth1/birth1_env1/birth2/load + seg_done] — the block-fused
-- link rules over the canonical context (RelSem/SegRun.lean);
-- same-commit provenance.)
/-- info: step_law census: 107 laws [advance 5, construct 9, envAlg 3, envMap 7, evalArith 2, evalPull 9, heapWP 4, loop 1, memBlock 7, memRW 21, perform 6, roundGlue 3, segLink 8, stateWP 22] -/
#guard_msgs in #step_law_census
-- (V0 2026-08-27, THE KILL BASKET — record
-- docs/2026-08-27_v0-statements-and-ban.md: the T1–T5 threaded
-- THEOREMS and their whole-run equation supply — round6/round13/
-- round21, the dnms chains, the app equations, T1/T2/T3Threaded[_ubFree],
-- the ThreadedOutcomes pins, the T5 seam/spine family
-- (T5S.*, t5_run_seg, T5.driver2_o), and the T4 walk family
-- (T4W.t4_run_seg, T4.driver2_o, T4Threaded[_ubFree]) — are DELETED;
-- the statements stand honest-unproved in the consistency-freshness
-- shape, registered in the statement gate above. Their ~40 cone pins
-- retired here in the same commit. `wpk_seq_scratch1p`'s pin — the
-- last walk-engine survivor — retired at V1 2026-08-28 with the
-- whole-state route.)

-- V0: THE CONSISTENCY-FRESHNESS METATHEOREMS (relsemcore
-- RelSem/Threaded.lean §CONSISTENCY) — the anti-vacuity schema
-- (monotone ⇒ distinct; below-the-vocabulary ⇒ non-capturing) and
-- the UB-freedom plumbing. Kernel theorems; cones pinned AT MOST the
-- classical trio (the metatheorem is required ≤ trio by the V0
-- validation criteria).
/-- info: 'RelSem.Cerb.freshDrawsOf_nodup' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.freshDrawsOf_nodup
/-- info: 'RelSem.Cerb.consistentRun_of_supply_le' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.consistentRun_of_supply_le
/-- info: 'RelSem.Cerb.callHarnessUBFreeCns_of_adequateCns' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.callHarnessUBFreeCns_of_adequateCns

-- (arc-18 R2: the hand walk `t6_wpK_thr` is SUBSUMED by the segment
-- route — T6Threaded's pin above covers the whole discharge; the
-- walk lemma is deleted with its plumbing.)

-- arc-17 S2: the ordered-map env algebra — the comparator-lawfulness
-- theorem and the lookup-through-insert payoff lemmas, trio-exact.
/-- info: 'RelSem.Kit.lemCmpToOrd_symEnvCmp_eq_model' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.lemCmpToOrd_symEnvCmp_eq_model
/-- info: 'RelSem.Kit.fmapLookupBy_addBy_mk' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.fmapLookupBy_addBy_mk
/-- info: 'RelSem.Kit.fmapLookupBy_addBy_apart' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.fmapLookupBy_addBy_apart
/-- info: 'RelSem.Kit.symEnvCmp_LT_of_num_lt' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Kit.symEnvCmp_LT_of_num_lt
-- The impure side, LABELED: the ambient bridges mention the ambient
-- state, so they (and only they) wear the boundary axiom — by design.

-- (arc-17 S0 derive_state ladder pins — rsD3_thr_def/rsR6_thr_def/
-- drDone_thr_def, T1Threaded residents — DELETED at V0 with the walk
-- supply; the derive_state EMITTER itself is KEEP chassis.)

/-! ## THE RUNEFFECTFUL NO-CONE-ENTRY GATE (arc-17 S2b)

    `runEffectful` (LemLib) is the SINGLE residual boundary axiom —
    temporal, retiring with the ambient family at the arc-17 purge
    (its deletion is lem-side surgery, out of this repo's scope). This
    gate pins its theorem-carrier set EXACTLY, both directions
    fail-closed:

    * a theorem cone ACQUIRING the axiom (any RelSem-module theorem
      whose transitive cone contains `runEffectful but is not in the
      registered list) FAILS THE BUILD — acquisition is build-fatal,
      never silent, never merely unpinned;
    * a STALE entry (registered but no longer carrying — e.g. after
      the purge re-founds a consumer) FAILS THE BUILD until removed
      deliberately, in the same commit, with the reason.

    Scope: theorems (thmInfo) of RelSem-module origin within this
    file's import closure — the sweep's scope exactly. Compiler-
    generated sub-proofs (`Name.isInternalDetail`: `_proof_*` etc.)
    are excluded from the pin because their parent theorem references
    them, so the parent's cone contains everything theirs does — any
    acquisition surfaces at a registered (or build-failing) named
    theorem; internal names are also unstable across recompiles.
    THE LIST IS EMPTY since the 2026-08-27 kill-list execution (the
    ambient family is deleted); the gate now enforces that NO theorem
    cone in this repository carries the residual boundary axiom.
    Plant-tested both directions (transcripts:
    docs/2026-08-25_arc17-s2b-axiom-endgame.md). -/

open Lean in
/-- The registered `runEffectful` theorem carriers (see the section
    note above). -/
def runEffectfulCarriers : List Name := []
  -- EMPTY since the 2026-08-27 kill-list execution: the ambient
  -- theorem family (the 104 registered carriers — T1–T4 chains, the
  -- callND ambient harness bridges, the labeled ambient bridges) is
  -- DELETED. The gate stays, fail-closed in both directions: any
  -- theorem cone ACQUIRING `runEffectful` is build-fatal — the
  -- residual boundary axiom is now outside EVERY theorem cone in
  -- this repository (record: docs/2026-08-27_kill-list-execution.md).

open Lean in
#eval show CoreM Unit from do
  let env ← getEnv
  -- fail-closed existence check on the registered list itself
  for n in runEffectfulCarriers do
    let some _ := env.find? n
      | throwError "runEffectful no-cone gate: registered carrier {n} \
          is MISSING (renamed without re-pointing the gate?)"
  let mods := env.header.moduleNames
  let isOurs : Array Bool := mods.map (fun m => m.getRoot == `RelSem)
  let names : Array Name := env.constants.fold
    (fun acc n _ => acc.push n) #[]
  let mut got : Array Name := #[]
  for n in names do
    let ours := match env.getModuleIdxFor? n with
      | some idx => isOurs[idx.toNat]!
      | none => true  -- the file being elaborated
    unless ours do continue
    unless env.find? n matches some (.thmInfo _) do continue
    if n.isInternalDetail then continue
    let axs ← collectAxioms n
    if axs.contains `runEffectful then got := got.push n
  let newAcq := got.filter (fun n => !runEffectfulCarriers.contains n)
  let stale := runEffectfulCarriers.filter (fun n => !got.contains n)
  unless newAcq.isEmpty do
    throwError "runEffectful no-cone gate FAILED — theorem cone(s) \
      ACQUIRED the residual boundary axiom (acquisition is build-fatal; \
      re-found the proof through the threaded substrate, or register \
      the carrier here deliberately, same commit, with the \
      reason):\n{newAcq.toList}"
  unless stale.isEmpty do
    throwError "runEffectful no-cone gate: registered carrier(s) no \
      longer carry the axiom (re-founded upstream?) — REMOVE them \
      deliberately, same commit, with the reason:\n{stale}"
  logInfo s!"runEffectful no-cone gate: carrier set exact \
    ({got.size} registered ambient-family theorems; no acquisition, \
    no stale entries)"

/-! ## The exhaustive sweep — LAST in the file by design: a constant
    declared after this point would dodge it (negative-test lesson,
    2026-08-19), so nothing may be declared below, and RelSem.Audit is
    the last import of the lib root. -/

open Lean in
-- The sweep's success line is #guard_msgs-PINNED (arc-11 audit A-F1
-- re-baseline: 3021 → 3348 after the T5 chain joined the closure).
-- The pin makes the COUNT exact in-build: a module silently leaving
-- this file's import closure (the A-F1 hole class) now FAILS the
-- build instead of shrinking the sweep quietly. Re-baseline
-- deliberately, same commit, with the reason. (When green the pin
-- SWALLOWS the info line — absence of the sweep line from a green
-- build log is expected; the DAEMON + statement gates still print.)
-- Re-baselines: 4827 → 4914 (arc-18 C2: THE T2/T3 MIGRATIONS — the
-- T2 and T3 open-memory equation layers (rest ladders, open stage
-- equations, open load/create/store/kill rounds, driver2_o, terminal
-- readouts) + the substrate's two-object and scratch-object rules
-- (interp_alloc_store factored, wpk_seq_alloc_store2, wpk_seq_read2,
-- wpk_seq_scratch1 + ecasts + macros, tm_get?_insert_ne,
-- writeBytesTo_lastAddress/nextAllocId) + the registered
-- inject_ptr_arg2 construct law; all trio-clean; every pre-existing
-- cone pin passed VERBATIM).
-- 4786 → 4827 (arc-18 C2: THE T1 MIGRATION — the T1
-- walk moves to the heap route: the T1 open-memory equation layer
-- (rest ladder, k*_o stage equations, round*_o open rounds,
-- driver2_o, the terminal readout) + wpk_seq_get/_ecast and the walk
-- macros join the closure; all trio-clean; every pre-existing cone
-- pin passed VERBATIM).
-- 4737 → 4786 (arc-18 C2: THE HEAP-ROUTE WALK
-- SUBSTRATE — RelSem/CerbHeapWalk.lean joins the closure (rest-patch
-- algebra, happ adapters, wpk_seq_rest/read1/alloc_store +
-- wpk_get_done_pure + ecast faces, MemInv_alloc_store/MemInv_initial,
-- the CerbHeapS bundle, the threaded heap-route adequacy bridges);
-- +49 declarations, all trio-clean; pins above).
-- 4898 → 4737 (arc-18 C2: THE ENTRY-2 DELETIONS —
-- PerStepPeel.lean + PerStepLaws.lean deleted per the Q1 [USER]
-- ruling (the dormant arc-16 half: peels, wpk_round_* library,
-- wpk_ite/wpk_pcs_*, the _of_wpK2 bridges); −161 declarations, all
-- previously pinned trio/labeled; the carrier pin shrank 114 → 112
-- in the same commit; no cone movement anywhere else).
-- 4890 → 4898 (arc-18 C1: THE PIECEWISE CHAIN
-- ASSEMBLER — the re-derived relative-chain emitter (endpoint-
-- tracked pieces through dnms_round_computed, kernel-deferred
-- premises) + its T6 smoke: rchain1..3 successor defs + _app
-- equations + rchain_chainrel (the ∀-fuel iter_compose feed) join
-- the closure; all boundary-clean).
-- 4885 → 4890 (arc-18 C1: THE DISPATCH CONVERSION —
-- queryLaw/qStar/appGoalSkeleton (Core) + queryLaw? (Lanes) join the
-- engine; RoundEval's hardcoded law-name dispatch now consults the
-- registry by goal-form SKELETON at every joint — tau/runstate/
-- action advance, perform, mem-block, env hit/skip/built, memRW,
-- chain glue, scheduler offer, driver-done; all boundary-clean,
-- drive behavior unchanged: T4 22 rounds same classes, t6 51 rounds
-- terminal).
-- 4830 → 4885 (arc-18 C1: the RoundEval DECOMPOSITION
-- — the monolithic evaluator split into 8 contract-shaped modules
-- (RoundEval/{Core,Hyp,Mint,Arith,Classify,Lanes,Rounds,Assembly});
-- zero code additions — the +55 is per-module compiler auxiliaries
-- (match/eq lemmas no longer shared across one module's body); all
-- boundary-clean, drive behavior unchanged).
-- 4746 → 4830 (arc-18 C1: THE ONE REGISTRY —
-- RelSem.LawRegistry (StepLaw/Registry structures + derived
-- instances, the @[step_law] attribute, query/census/lint machinery)
-- joins the closure; the 42-law population is attribute metadata on
-- EXISTING theorems (census pinned above), so the census pin, not
-- this count, tracks it; the two re-homed wpk seq laws move files
-- name-stably. All boundary-clean).
-- 4712 → 4746 (arc-18 C1: the stash-salvaged MEM
-- FOOTPRINT PACKAGE — Kit/Mem read-over-write laws (writeBytesTo_*
-- projection quartet + writeFold_get?/writeBytesTo_bytemap_get? +
-- readBytesFrom_congr_bytemap + the disjoint-frame/exact-hit
-- read-over-write laws), Kit/Round dnms_round_computed (the
-- σ-computable dnms face), and RoundEval's mem read-over-write
-- minter lane (groundIntLit?/listSpineLen?/mintMemRW); all
-- boundary-clean, drive behavior byte-identical — T4 22 rounds same
-- classes, t6 51 rounds terminal).
-- 3348 → 3356 (arc-15 T5 resumption, R-S2-1 batch:
-- T5Prefix gains eInsMK/eInsBEq — the pinned generated-instance
-- spelling for the env-family inserts — and Tactics/AppWalk gains
-- kDiffTrace (trace-lane kernel diff, R-S2-3) + addRawAuxThm (raw
-- seal fallback with level-mvar closure)). 3356 → 3517 (arc-16 S1:
-- the per-step language modules PerStep/PerStepIris/PerStepCall/
-- PerStepSmoke join the closure — 161 declarations, all
-- boundary-clean; pins above). 3517 → 3692 (arc-16 S2: the CerbMem
-- heap RA modules MemLocal/CerbHeapRA/CerbHeapWP/CerbHeapDemo join
-- the closure — 175 declarations, all trio-clean; pins above).
-- 3692 → 3904 (arc-16 S3: the peel/law/tactic modules
-- PerStepRunner/PerStepPeel/PerStepLaws/PerStepTactics/PerStepTacSmoke
-- join the closure — 212 declarations, all boundary-clean; pins
-- above). 3904 → 3983 (arc-16 S4: the threaded effect-state modules
-- Threaded/T1Threaded join the closure — 79 declarations, all
-- boundary-clean, the threaded theorem family trio-exact; pins
-- 4646 → 4712 (arc-17 S3 cont.: THE BUILDER-WALK ENGINE — the
-- Lem-comparator Bool bridges (natLtb-family ×14), the NonNeg/
-- decide-shape/bool-eq/verdict-transfer bridges, the env-lookup
-- lane's symCmpO bridges, closeBoolTower, position-safe
-- substitution, dual-mode proveHypEq, the relative-chain emitter —
-- plus the re-minted T4 verdict-fact population under the evolved
-- lanes (named facts differ; all boundary-clean; the sweep line
-- remains the trio-cleanliness witness).
-- 4552 → 4646 (arc-17 S3: THE ARITH MINTER — RoundEval's verdict
-- lanes + bridge lemmas (dec_eq_isTrue/False, nat_ble/blt/beq
-- bridges, decide-shape bridges, Int.NonNeg bridges, symCmpO
-- bridges) + the env-lookup lane machinery, and the T4 drive's
-- frontier moves 17 → 22: rT18..rT22 successor defs + _app
-- equations + the minted verdict facts rT_hf*/side facts rT_hfs*
-- (∀-closed over the pack telescope, omega/kernel-backed), all
-- boundary-clean — the sweep line remains the trio-cleanliness
-- witness for the conditional equations).
-- 4439 → 4552 (arc-17 S2b cont.: the evaluator HYPOTHESIS-THREADING
-- MODE lands — RoundEval's engine (HypPack/substitution/
-- kernel-deferred prover/twin) + the T4 drive's frontier moves from
-- round 1 to round 17: rT1..rT17 successor defs + _app equations +
-- the create-round _addr fact, all boundary-clean (the ∀-seed/∀-x
-- conditional equations carry their hypothesis binders, no new
-- axioms — this sweep line is the trio-cleanliness witness).
-- 4438 → 4439 (arc-17 S2b: the runEffectful no-cone-entry gate's
-- registered-carrier list `runEffectfulCarriers` joins this file).
-- 4410 → 4438 (arc-17 S2 cont.: T4Threaded — the guarded statement
-- + apartness defs + evaluator-driven prefix at the measured
-- frontier; the seq_rmw perform law joins via Kit/Round).
-- 4361 → 4410 (arc-17 S2 cont.: Kit/Env — the ordered-map env
-- algebra: comparator model + lawfulness + Fmap lookup layer).
-- 4128 → 4361 (arc-17 S2: RoundEval meta code + the completed t6
-- probe — 51 evaluator-minted round decls + equations + the run
-- artifacts + the ∀-seed theorem family; provenance: the S2 record).
-- above). 3983 → 4050 (arc-16 S4 cont.: T2Threaded/T3Threaded join
-- the closure — 67 declarations, all boundary-clean, theorem cones
-- trio-exact; pins above. T4Threaded deliberately absent: parked at
-- the collision diagnosis). 4050 → 4108 (arc-17 S0: the
-- discharge-engine substrate — DeriveState (named-state emitter) +
-- WpGround (memoized ground-fact discharger) join the closure, and
-- T1Threaded's state ladder is re-emitted through `derive_state`
-- (+3 `_def` rfl lemmas, trio-pinned above); 58 declarations, all
-- boundary-clean). 4108 → 4119 (arc-17 S1: the per-construct law
-- registry ConstructLaws joins the closure (seu_read_bind +
-- erun_jump_m + ndct_offer1 + driver2_done + match/eq auxiliaries);
-- the three label-resolution twins round6_thr/round13_thr/round21_thr
-- are DELETED — their ambient rounds are ∀-run-state and pinned trio
-- above — and the per-fixture scheduler/driver-iteration proof
-- machinery in the threaded files collapses into the two
-- call-structure laws; net +11, all boundary-clean). 4119 → 4128
-- (arc-17 S1 cont.: the harness caller-protocol laws
-- inject_ptr_arg1/callND_errno/get_ths_eq/driver_update_ts + the
-- stepAt registry helper join ConstructLaws — the acceptance
-- probe's law layer; the probe fixture file itself is parked OUT of
-- the build). 4914 → 5090 (arc-18 C3: THE PULL_CONSTRAINED IDENTITY
-- LAW — Kit/Eval's pullSpine mirror + its equation/matcher
-- auxiliaries + notConstrained + pull_helper_id/foldl_inr_of_step +
-- the two law faces; all boundary-clean, no cone movement).
-- 5090 → 5265 (arc-18 C3 cont.: the evalArith laws + their
-- equation/matcher auxiliaries [Kit/Eval], fmapLookupBy_empty
-- [Kit/Map], option_eq_some_getD + the substitution-hardening
-- engine decls [RoundEval]; all boundary-clean, no cone movement).
-- 5265 → 5281 (arc-18 C3b: the T5-continuation routing fixes' engine
-- decls + auxiliaries — LawRegistry.matchByUnify [the fence-robust
-- opt-in query fallback], RoundEval/Hyp resolveProjVal + projNormHop
-- [THE PROJECTION-NORMALIZATION HOP], Rounds.classifyUsedHypNorm
-- [glue-first flag]; meta code only, all boundary-clean, no cone
-- movement — the committed T4/T6 drives re-elaborate byte-identically
-- [builder-gated changes]). 5281 → 5292 (arc-18 C3b cont.: the six
-- memRW read-over-update laws [Kit/Mem] + their auxiliaries +
-- projBaseHead [Classify]; boundary-clean, no cone movement).
-- 6774 → 6784 (arc-18 C4 cont.: the three whole-program-drive laws
-- + their unfold lemmas + selectRoKindK [Kit/Mem, Kit/Round — the
-- census 66→69 entries and their auxiliaries]; boundary-clean, no
-- cone movement).
-- 6772 → 6774 (arc-18 C4: the R6 STATEMENT HOMING — RelSem.Threaded
-- MOVES to the semantics package [relsemcore/RelSem/Threaded.lean;
-- one definition, one home; this package imports it] and gains the
-- two homed whole-program statement-vocabulary defs: `specifiedInt`
-- + `HarnessRunsToThr` [moved/derived from speclab DivModFiles —
-- the spec-lab statement surface now quotes them across the
-- one-way seam]; boundary-clean, no cone movement).
-- 5292 → 6772 (arc-18 C3b cont.: THE T5 EQUATION SUPPLY + FAMILY
-- join the sweep — T5Walks' five builder drives [e 22 / b 79 /
-- bx 44+terminal / bfirst 78 / bxzero 43+terminal: round successors,
-- _app equations, minted facts, chainrel prefixes] + T5Inv [triF,
-- the St family, alignment rfls, component invariants, memStep/
-- envStepF layers]; ALL boundary-clean — the initial wiring tripped
-- the runEffectful no-cone gate [the builders' labeled spelling
-- routed through the AMBIENT initial_core_run_state] and was
-- respelled via initial_core_run_state_threaded 0: the acquisition
-- catch working as designed, record §3 of
-- docs/2026-08-26_arc18-c3b-t5-landing.md).
-- 6784 → 6959 (arc-18 R1, the open-memory minting mode: T6's OPEN
-- drive `ro` [51 round successors + _app equations + minted facts +
-- chainrel prefixes at free maps], the T6 heap-route spine [open
-- k-stage equations + driver2_o + rDone6 ladder], and the seven new
-- Kit/Mem writeBytesTo projection laws; ALL boundary-clean — record
-- docs/2026-08-26_arc18-r1-open-memory.md).
-- 8362 → 8404 (arc-18 R2, the [F3] seam acceptance: RelSem.T5Seam
-- [t5SeamInv + the normalization theorem + the two BPack-hypothesized
-- discharge instances over the T5W twin chains]; ALL boundary-clean).
-- 8404 → 8403 (arc-18 R3, the early purge: RelSem.IrisCoupling
-- deleted — zero importers, its single paper-only marker decl
-- leaves the closure; record docs/2026-08-27_arc18-r3-early-purge.md).
-- 7182 → 8362 (arc-18 R2, the t7 slice: the four T7W walk drives'
-- minted artifacts [e 95 / bEven 72 / bOdd 94 / bx 33+terminal —
-- round successors + _app equations + chainrel prefixes at open
-- maps] + the T7W spine/feeds + RelSem.T7 [the composed invariant
-- proof]; ALL boundary-clean).
-- 6959 → 7182 (arc-18 R2, the segment layer: RelSem.Segment [the
-- ∃-round judgment + composition + FnSpec + spelling normalization]
-- + RelSem.SegmentFaces [verify_fn/seg_auto + the seg_* attributes]
-- + Kit/Loop's variable-round variants + the T6Probe reshape
-- [t6_canon/pickSpec in, t6_wpK_thr/t6_post_o out]; ALL
-- boundary-clean).
-- 8403 → 8654 (arc-18 R4 slice 1: the scratch2 engine leg
-- [MemLocal's ii-ee chain get? lemmas + MemInv.scratch2_pointwise;
-- CerbHeapWalk's wpk_seq_scratch2/_ecast] + the T5Inv ∀-k FAMILY
-- CLOSURE [roundtrip5/recon_i32/i2b_i32, triF bounds, supply/env/
-- byte/allocation families ∀ k, St_rest_indep + the exit endpoints
-- exitAt/exitAt0/stFin] + the SegmentFaces R4 legs [mkBuiltProof
-- env-peel built-chain, verify_fn guarded-family alternatives,
-- argobj2/read2/scratch2 dispatch arms]; ALL boundary-clean).
-- 8654 → 8769 (arc-18 R4 slice 3: RelSem.T5Spine [the t5File
-- harness spine at symbolic n, the ∀-k pack closure `packAt`, the
-- twin exit legs, the composed run + scratch2 driver atom, the
-- fixed final rest + readout] + RelSem.T5 [statement data + the
-- two-line flagships] + the SegmentFaces R4 hardening legs;
-- ALL boundary-clean).
-- 8769 → 8798 (arc-18 R4 slice 4: T1/T2/T3 re-housed — canon
-- representatives + FnSpecs in, the three hand wpK walks + inline
-- readouts DELETED, the shape-indexed verify_fn + keyed matchSegEq
-- in SegmentFaces; ALL boundary-clean).
-- 8469 → 8982 (arc-18 R5, T4-apartness through the layer: the
-- T4Walks two-walk drive's minted rounds/facts + the T4W spine +
-- the scratch1p rule + the re-housed T4Threaded route).
-- 8982 → 10060 (arc-18 R6 batch 1, the breadth-campaign EASY tier:
-- five corpus fixtures — RelSem.Corpus.E1–E5, each the T6Probe
-- open-memory route [spine equations + minted rounds + driver atom
-- + ∀-seed statements + safety twin]; ALL boundary-clean, zero
-- engine changes).
-- 2679 → 2698 (V0 2026-08-27, batch B cont.: the P07/P08 struct-
-- arena builders + statements + priors; boundary-clean).
-- 2590 → 2679 (V0 2026-08-27, THE CORPUS SLATE batch B: CorpusBCore
-- [emitted fn+main terms ×5 + struct node tagdefs] + CorpusBFiles
-- [glob builders, family constructors, priors] + CorpusBStatements
-- [5 P-statement defs + models + wf]; ALL boundary-clean).
-- 2505 → 2590 (V0 2026-08-27, THE CORPUS SLATE batch A: CorpusCore
-- [emitted program terms: 10 fn decls + struct pt + the params trio]
-- + CorpusFiles [assemblies, funinfo, priors] + CorpusStatements
-- [the 14 P-statement defs + models + the two EnvHyp defs] join
-- the closure; ALL
-- boundary-clean).
-- 2490 → 2505 (V0 2026-08-27, THE CONCRETE-INPUT BAN: the ban's
-- checker meta decls + the two permanent negative-test probes
-- [constArgsProbe/finiteSampleProbe] + auxiliaries join this file;
-- boundary-clean).
-- 6024 → 2490 (V0 2026-08-27, THE KILL BASKET — record
-- docs/2026-08-27_v0-statements-and-ban.md: the T1–T5 walk engine
-- rooms [T1Walks/T2Walks/T3Walks/T4Walks/T5Walks/T5Inv/T5Seam/
-- T5Spine — hand rounds, evaluator-minted whole-run chains, seam/
-- spine families], the whole-run mint mode [RoundEval/Assembly.lean]
-- and Kit/Loop leave the closure with the T1–T5 threaded THEOREMS
-- (statements stand honest-unproved, consistency-freshness shape);
-- PriorCensus + the Cns statement layer join — net ~3,534
-- declarations out.)
-- 12410 → 6024 (2026-08-27 KILL-LIST EXECUTION, one commit: the
-- ambient theorem family + AppEq carriers, the arc-7 Iris shell +
-- SlateWP, the transitional OwnP surface + runner/smokes, the chase
-- machinery [AppWalk/WalkTrace/AppEqAttr/Kit-AppEq], T6Probe,
-- T7/T7Walks, the 14-file R6 corpus, and the killed SlateFiles/
-- SlateCore fixture terms leave the closure — ~6,400 declarations;
-- record docs/2026-08-27_kill-list-execution.md.)
-- 12404 → 12410 (2026-08-27 delta disposition, kill-list execution
-- commit 1: `readBytesFrom_writeBytesTo_within` [Kit/Mem] + its
-- compiler auxiliaries — the one salvaged law from the killed
-- worker's delta; boundary-clean).
-- 12383 → 12404 (arc-18 R6 batch 4: the SlateFiles additions for
-- the PARKED lanes — x3Stdlib [the ccall protocol's params trio,
-- emitted from std.core] + the x3/z1/z2 file assemblies; no new
-- theorems, no new laws — the parked reproducers' data only).
-- 11501 → 12383 (arc-18 R6 batch 3: the x7/x2 edge fixtures —
-- multi-exit/break compositions, two walks each — + mem_pvfd_block
-- + the assembled-but-unimported c9 file data; boundary-clean).
-- 10060 → 11501 (arc-18 R6 batch 2, the CENSUS tier: four corpus
-- fixtures — RelSem.Corpus.C4/C5/C3A/C3B; c3b is the first corpus
-- LOOP through the invariant route (three walks + SegInv map +
-- while_inv composition, the T7 recipe); ALL boundary-clean, zero
-- engine changes).
-- 8798 → 8469 (arc-18 R4 slice 5, THE RETIREMENT: the ambient-era
-- T5 chain — T5Fixture/T5Prefix/T5Iter, the arc-9→15 climb's parked
-- capability — DELETED; T5-the-theorem stands proved through the
-- layer at the trio. Carrier set 112 → 104 in the same commit.)
-- 2732 → 2763 (V2 C2: the domain ledger + birth moves, the V2 rule
-- lane [CerbStateStep], the peel modules joining the audit closure.)
-- 2668 → 2732 (V2 C1: the observation algebra [PerStepObs] + the
-- loop peel with anchors and the round-granular bridges
-- [PerStepPeel, CerbStateAdequacy §V2] — the big-step↔small-step
-- simulation infrastructure; same-commit provenance).
/--
info: RelSem audit sweep: 3867 declarations (module-of-origin root RelSem, within RelSem.Audit's import closure — NOT the whole tree), all within the declared axiom boundary (0 recorded sorryAx exceptions)
-/
#guard_msgs in
#eval show CoreM Unit from do
  let env ← getEnv
  -- Fail-closed existence checks on the lists themselves (a rename must
  -- re-point the gate, never silently drop a check).
  for n in allowedAxioms do
    let some _ := env.find? n
      | throwError "RelSem audit: allowlisted axiom {n} is MISSING \
          (renamed without re-pointing the gate?)"
  for n in sorryExceptions do
    let some ci := env.find? n
      | throwError "RelSem audit: sorry-exception {n} is MISSING \
          (renamed without re-pointing the gate?)"
    if ci matches ConstantInfo.thmInfo _ then
      throwError "RelSem audit: sorry-exception {n} is a THEOREM — \
        a proof may never carry sorryAx (exception list is defs-only)"
  -- Target = modules whose name root is RelSem (module-of-origin, not
  -- namespace), plus the file being elaborated (no module index yet).
  let mods := env.header.moduleNames
  let isOurs : Array Bool := mods.map (fun m => m.getRoot == `RelSem)
  let names : Array Name := env.constants.fold (fun acc n _ => acc.push n) #[]
  let mut bad : Array (Name × Name) := #[]
  let mut staleExceptions : List Name := sorryExceptions
  let mut audited := 0
  for n in names do
    let ours := match env.getModuleIdxFor? n with
      | some idx => isOurs[idx.toNat]!
      | none => true
    unless ours do continue
    let axs ← collectAxioms n
    audited := audited + 1
    let isException := sorryExceptions.contains n
    if isException && axs.contains ``sorryAx then
      staleExceptions := staleExceptions.filter (· != n)
    for ax in axs do
      if allowedAxioms.contains ax then continue
      if ax == ``sorryAx && isException then continue
      bad := bad.push (n, ax)
  unless staleExceptions.isEmpty do
    throwError "RelSem audit: sorry-exceptions no longer carry sorryAx \
      (fixed upstream?) — REMOVE them deliberately: {staleExceptions}"
  if bad.isEmpty then
    -- Arc-11 audit A-F1: the old tail ("across RelSem.* modules")
    -- OVERSTATED the scope — the sweep sees exactly this file's
    -- import closure, no more. Say so.
    logInfo s!"RelSem audit sweep: {audited} declarations \
      (module-of-origin root RelSem, within RelSem.Audit's import \
      closure — NOT the whole tree), all within the declared axiom \
      boundary ({sorryExceptions.length} recorded sorryAx exceptions)"
  else
    let lines := bad.qsort (fun a b => a.1.toString < b.1.toString)
      |>.map (fun (n, ax) => s!"  {n} depends on {ax}")
    throwError "RelSem audit sweep FAILED — declarations with axioms \
      outside the declared boundary (a `sorry`, a non-kernel decision \
      procedure, or new \
      postulate?):\n{String.intercalate "\n" lines.toList}"

end RelSem.Audit
