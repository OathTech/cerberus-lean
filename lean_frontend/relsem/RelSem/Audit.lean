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
import RelSem.IrisCoupling
-- arc-7 S4: the iris-lean coupling modules join the sweep + pins.
import RelSem.IrisLang
import RelSem.IrisState
import RelSem.IrisRules
import RelSem.IrisAdequacy
import RelSem.T1Core
import RelSem.T1File
import RelSem.T1
-- arc-7 S5a: the slate climb (T2-T4) + the fixture-generic WP bridge.
import RelSem.SlateCore
import RelSem.SlateFiles
import RelSem.SlateWP
import RelSem.T2AppEq
import RelSem.T2
import RelSem.T3AppEq
import RelSem.T3
-- arc-9 S2: the kit exactness pins join the in-build audit.
import RelSem.Kit.Audit
import RelSem.T4Defs
import RelSem.T4AppEq
import RelSem.T4
-- arc-11 audit A-F1: the T5 chain (T5Fixture → T5Prefix → T5Iter)
-- joins the sweep closure + pins. It was in the package build but
-- OUTSIDE this file's import closure — the sweep/gate hole the
-- arc-11 adversarial audit found.
import RelSem.T5Iter
-- arc-16 S1: the per-step language (the Iris refounding's language
-- layer) joins the sweep closure + pins.
import RelSem.PerStep
import RelSem.PerStepIris
import RelSem.PerStepCall
import RelSem.PerStepSmoke
import RelSem.MemLocal
import RelSem.CerbHeapRA
import RelSem.CerbHeapWP
import RelSem.CerbHeapDemo
-- arc-16 S3: the loop peels + law library + wp-tactics join the
-- sweep closure + pins.
import RelSem.PerStepRunner
import RelSem.PerStepPeel
import RelSem.PerStepLaws
import RelSem.PerStepTactics
import RelSem.PerStepTacSmoke
-- arc-17 S0: the discharge-engine substrate (named-state emitter +
-- memoized ground-fact discharger) joins the sweep closure.
import RelSem.DeriveState
import RelSem.WpGround
-- arc-17 S2: the law-driven round evaluator joins the sweep closure.
import RelSem.RoundEval
-- arc-17 S2: the ordered-map env algebra joins the sweep closure +
-- pins (comparator lawfulness + lookup-through-insert under
-- apartness).
import RelSem.Kit.Env
-- arc-17 S1: the per-construct law registry joins the sweep closure
-- + pins. (The acceptance probe, RelSem/T6Probe.lean, is parked OUT
-- of the build at its measured frontier — see the S1 record.)
import RelSem.ConstructLaws
-- arc-16 S4: the threaded effect state (∀-seed statements; the
-- acceptance re-proof) joins the sweep closure + pins.
import RelSem.Threaded
import RelSem.T1Threaded
import RelSem.T2Threaded
import RelSem.T3Threaded
-- arc-17 S2: the completed acceptance probe joins the sweep closure
-- + pins (the ∀-seed t6 theorems through the round evaluator).
import RelSem.T6Probe
import RelSem.T4Threaded

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
/-- info: 'RelSem.Cerb.callReaches' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.callReaches
/-- info: 'RelSem.Cerb.callOutcomes_sound' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.callOutcomes_sound
/-- info: 'RelSem.Cerb.callAdequate_of_reach' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.callAdequate_of_reach
/-- info: 'RelSem.Cerb.ofStatus_value_inv' does not depend on any axioms -/
#guard_msgs in #print axioms RelSem.Cerb.ofStatus_value_inv
/-- info: 'RelSem.Cerb.callHarnessAdequate_of_adequate' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.callHarnessAdequate_of_adequate
-- arc-7 S5c (audit-1 F2): the CerbND-shaped UB-freedom surface.
/-- info: 'RelSem.Cerb.callHarnessUBFree_of_ubFree' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.callHarnessUBFree_of_ubFree
/-- info: 'RelSem.Cerb.callHarnessUBFree_of_app_active' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.callHarnessUBFree_of_app_active
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
/-- info: 'RelSem.Cerb.callAdequate_of_app_active' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.callAdequate_of_app_active
/-- info: 'RelSem.Cerb.callUBFree_of_app_active' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.callUBFree_of_app_active
/-- info: 'RelSem.Cerb.callHarnessAdequate_of_app_active' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.callHarnessAdequate_of_app_active
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
/-- info: 'RelSem.Cerb.instLanguageDrive' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.instLanguageDrive
/-- info: 'RelSem.Cerb.steps_erased' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.steps_erased
-- (arc-9 S2 re-baseline, OwnP adoption: `stateIs_agree`/`stateIs_update`
-- are RETIRED — agreement/update now happen inside iris-lean's
-- `ownP_eq`/`ownP_lift_step`; the pins below cover the reworked
-- surface. Design: docs/2026-08-20_arc9-s1-design.md §1.1.)
/-- info: 'RelSem.Cerb.instCerbGpreS_CerbS' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.instCerbGpreS_CerbS
/-- info: 'RelSem.Cerb.wp_app_active' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.wp_app_active
/-- info: 'RelSem.Cerb.wp_app_killed' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.wp_app_killed
/-- info: 'RelSem.Cerb.wp_done' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.wp_done
/-- info: 'RelSem.Cerb.wp_callND' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.wp_callND
/-- info: 'RelSem.Cerb.callAdequate_of_wp' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.callAdequate_of_wp
/-- info: 'RelSem.Cerb.callHarnessAdequate_of_wp' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.callHarnessAdequate_of_wp
/-- info: 'RelSem.Cerb.callUBFree_of_wp' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.callUBFree_of_wp
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
/-- info: 'RelSem.T1.t1_wp' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T1.t1_wp
/-- info: 'RelSem.T1.t1_of_app_eq' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T1.t1_of_app_eq
/-- info: 'RelSem.T1.t1_of_app_eq_direct' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T1.t1_of_app_eq_direct
/-- info: 'RelSem.T1.t1_ubFree_of_app_eq' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T1.t1_ubFree_of_app_eq

-- Arc-7 S5a: THE F8 SWEEP LANDED — T1AppEq is a theorem and T1 is
-- UNCONDITIONAL. The app-equation chain (RelSem/T1AppEq.lean) quotes
-- the harness substrate (runEffectful);
-- the byte-roundtrip arithmetic is [propext, Quot.sound].
-- Pinned exactly; sorryAx-free by the sweep.
/-- info: 'RelSem.T1.roundtrip_arith' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T1.roundtrip_arith
/-- info: 'RelSem.T1.t1_app_eq' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T1.t1_app_eq
/-- info: 'RelSem.T1.t1AppEq_holds' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T1.t1AppEq_holds
/-- info: 'RelSem.T1.T1' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T1.T1
/-- info: 'RelSem.T1.T1_direct' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T1.T1_direct
/-- info: 'RelSem.T1.T1_ubFree' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T1.T1_ubFree
/-- info: 'RelSem.T1.T1Outcomes' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T1.T1Outcomes


-- Arc-7 S5a: THE SLATE CLIMB — T2 (add, the forced no-signed-overflow
-- precondition), T3 (roundtrip), T4 (struct member — the exit
-- criterion; under the harness-environment hypotheses T4EnvHyp, the
-- three census-boundary globals surfaced). All through the
-- fixture-generic WP bridge (RelSem/SlateWP.lean). Pinned exactly.
/-- info: 'RelSem.Cerb.wp_of_app_active' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.wp_of_app_active
/-- info: 'RelSem.Cerb.callHarnessAdequate_of_app_eq_wp' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.callHarnessAdequate_of_app_eq_wp
/-- info: 'RelSem.Cerb.callUBFree_of_app_eq_wp' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.callUBFree_of_app_eq_wp
/-- info: 'RelSem.Slate.t2File' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Slate.t2File
/-- info: 'RelSem.Slate.t3File' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Slate.t3File
/-- info: 'RelSem.Slate.t4File' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Slate.t4File
/-- info: 'RelSem.T2.catch_add_fact' depends on axioms: [propext] -/
#guard_msgs in #print axioms RelSem.T2.catch_add_fact
/-- info: 'RelSem.T2.t2_app_eq' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T2.t2_app_eq
/-- info: 'RelSem.T2.T2' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T2.T2
/-- info: 'RelSem.T2.T2_direct' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T2.T2_direct
/-- info: 'RelSem.T2.T2_ubFree' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T2.T2_ubFree
/-- info: 'RelSem.T2.T2Outcomes' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T2.T2Outcomes
/-- info: 'RelSem.T3.t3_app_eq' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T3.t3_app_eq
/-- info: 'RelSem.T3.T3' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T3.T3
/-- info: 'RelSem.T3.T3_direct' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T3.T3_direct
/-- info: 'RelSem.T3.T3_ubFree' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T3.T3_ubFree
/-- info: 'RelSem.T3.T3Outcomes' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T3.T3Outcomes
/-- info: 'RelSem.T4.t4_app_eq' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T4.t4_app_eq
/-- info: 'RelSem.T4.T4' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T4.T4
/-- info: 'RelSem.T4.T4_direct' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T4.T4_direct
/-- info: 'RelSem.T4.T4_ubFree' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T4.T4_ubFree
/-- info: 'RelSem.T4.T4Outcomes' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T4.T4Outcomes

-- Arc-11 (audit A-F1 disposition): THE T5 FLAGSHIPS — the committed
-- in-build theorems of the parked T5 climb (T5 itself is NOT proved;
-- these are the entry walk + the T5Iter env-lookup family). Each
-- sits at the clean quartet: they quote the harness/driver substrate
-- (runEffectful enters through the quoted generated bodies), and the
-- walker's per-round certificates are ordinary kernel-checked
-- declarations adding nothing. Pinned exactly — growth (sorryAx
-- above all) fails the build.
/-- info: 'RelSem.T5.entry5_walk' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T5.entry5_walk
/-- info: 'RelSem.T5.envL_built' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T5.envL_built
/-- info: 'RelSem.T5.envL_lookup_n' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T5.envL_lookup_n
/-- info: 'RelSem.T5.envL_lookup_i' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T5.envL_lookup_i
/-- info: 'RelSem.T5.envL_lookup_s' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T5.envL_lookup_s

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
  [`RelSem.Step, `RelSem.Steps, `RelSem.CsSem,
   `RelSem.Cerb.DSteps, `RelSem.Cerb.DStep, `RelSem.Cerb.stateIs,
   `RelSem.Cerb.seqModel, `RelSem.ExecModel]

open Lean in
/-- The RelSem-rooted NON-Prop constants a slate statement MAY mention:
    the harness surface (`callND`, `intValue`) and the pinned fixture
    data (program terms, fs states, terminal states). Everything
    RelSem-rooted that is neither here nor a transparently-unfolded
    Prop-family def fails the gate. -/
def stmtAllowed : List Name :=
  [`RelSem.Cerb.callND, `RelSem.Cerb.intValue,
   `RelSem.T1.t1File, `RelSem.T1.t1Fs, `RelSem.T1.drDone,
   `RelSem.T2.t2Fs, `RelSem.T2.drDone,
   `RelSem.T3.t3Fs, `RelSem.T3.drDone,
   `RelSem.T4.t4Fs, `RelSem.T4.drDone,
   `RelSem.Slate.t2File, `RelSem.Slate.t3File, `RelSem.Slate.t4File,
   -- arc-16 S4: the threaded statement vocabulary — the
   -- seed-parametric initial state (fuel-opsem-level: mirrors the
   -- generated def with the seed explicit) + the per-fixture threaded
   -- terminal states.
   `RelSem.Cerb.initial_driver_state_threaded,
   `RelSem.T1.drDone_thr, `RelSem.T2.drDone_thr, `RelSem.T3.drDone_thr,
   -- arc-17 S2: the completed acceptance probe's fixture data (the
   -- pinned program term + its fs state — same class as the t1-t4
   -- rows above).
   `RelSem.Slate.t6File, `RelSem.T6.t6Fs]

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
  let mut viol : Array Name := #[]
  let mut seen : NameSet := {}
  let mut queue : Array Name := ci.type.getUsedConstants
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
    [`RelSem.T1.T1, `RelSem.T1.T1_direct, `RelSem.T1.T1_ubFree,
     `RelSem.T1.T1Outcomes,
     `RelSem.T2.T2, `RelSem.T2.T2_direct, `RelSem.T2.T2_ubFree,
     `RelSem.T2.T2Outcomes,
     `RelSem.T3.T3, `RelSem.T3.T3_direct, `RelSem.T3.T3_ubFree,
     `RelSem.T3.T3Outcomes,
     `RelSem.T4.T4, `RelSem.T4.T4_direct, `RelSem.T4.T4_ubFree,
     `RelSem.T4.T4Outcomes,
     -- arc-16 S4: the threaded (∀-seed) family joins the gate
     -- (T4Threaded absent by design: parked at the collision
     -- diagnosis — see the S4 pin block note).
     `RelSem.T1.T1Threaded, `RelSem.T1.T1Threaded_ubFree,
     `RelSem.T1.T1ThreadedOutcomes,
     `RelSem.T2.T2Threaded, `RelSem.T2.T2Threaded_ubFree,
     `RelSem.T2.T2ThreadedOutcomes,
     `RelSem.T3.T3Threaded, `RelSem.T3.T3Threaded_ubFree,
     `RelSem.T3.T3ThreadedOutcomes,
     -- arc-17 S2: the completed acceptance probe's ∀-seed family
     -- (outcome-set companion deliberately absent: priced, not owed
     -- — the S2 record registers it).
     `RelSem.T6.T6Threaded, `RelSem.T6.T6Threaded_ubFree]
  for n in slate do
    match stmtViolations env n with
    | .error e => throwError "{e}"
    | .ok [] => pure ()
    | .ok vs =>
      throwError "RelSem statement gate: {n}'s STATEMENT mentions \
        banned constants {vs} — slate statements are fuel-opsem only"
  -- NEGATIVE TEST 1: an Iris-statement theorem must be rejected.
  match stmtViolations env `RelSem.T1.t1_wp with
  | .error e => throwError "{e}"
  | .ok [] =>
    throwError "RelSem statement gate NEGATIVE TEST FAILED: t1_wp's \
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
  logInfo s!"RelSem statement gate: {slate.length} slate statements \
    fuel-opsem-clean (negative tests: t1_wp and the wrapper-hole probe \
    correctly rejected)"

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
/-- info: 'RelSem.Cerb.ownP_lift_det_step_no_fork' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.ownP_lift_det_step_no_fork
/-- info: 'RelSem.Cerb.wpk_seq_active' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.wpk_seq_active
/-- info: 'RelSem.Cerb.wpk_seq_killed' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.wpk_seq_killed
/-- info: 'RelSem.Cerb.wpk_done' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.wpk_done
/-- info: 'RelSem.Cerb.kAdequate_of_wp' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.kAdequate_of_wp
/-- info: 'RelSem.Cerb.callFinishK_denote' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.callFinishK_denote
/-- info: 'RelSem.Cerb.callK_denote' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.callK_denote
/-- info: 'RelSem.Cerb.kCallHarnessAdequate_of_wp' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.kCallHarnessAdequate_of_wp
/-- info: 'RelSem.Cerb.kCallHarnessUBFree_of_wp' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.kCallHarnessUBFree_of_wp
/-- info: 'RelSem.T1.t1_wpK' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T1.t1_wpK
/-- info: 'RelSem.T1.T1_perStep' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T1.T1_perStep
/-- info: 'RelSem.T1.T1_ubFree_perStep' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T1.T1_ubFree_perStep

-- arc-16 S2: THE CERBMEM HEAP RA (RelSem/MemLocal + CerbHeapRA +
-- CerbHeapWP + CerbHeapDemo; design record
-- docs/2026-08-24_arc16-s2-cerbmem-heap-ra.md). Every cone is
-- EXACTLY the classical trio (the physical layer picks up
-- Classical.choice/Quot.sound through the Std map lemmas + omega);
-- the rules quantify over programs, so no harness substrate (and no
-- runEffectful) enters any cone. Pinned exactly.
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
/-- info: 'RelSem.Cerb.interp_rest_agree' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.interp_rest_agree
/-- info: 'RelSem.Cerb.interp_alloc_lookup' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.interp_alloc_lookup
/-- info: 'RelSem.Cerb.interp_bytes_lookup' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.interp_bytes_lookup
/-- info: 'RelSem.Cerb.interp_store_update' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.interp_store_update
/-- info: 'RelSem.Cerb.interp_alloc_update' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.interp_alloc_update
/-- info: 'RelSem.Cerb.interp_kill_update' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.interp_kill_update
/-- info: 'RelSem.Cerb.wpk_seq_res_det' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.wpk_seq_res_det
/-- info: 'RelSem.Cerb.wpk_load' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.wpk_load
/-- info: 'RelSem.Cerb.wpk_store' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.wpk_store
/-- info: 'RelSem.Cerb.wpk_alloc' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.wpk_alloc
/-- info: 'RelSem.Cerb.wpk_kill' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.wpk_kill
/-- info: 'RelSem.Cerb.cerbHeap_adequacy' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.cerbHeap_adequacy
/-- info: 'RelSem.Cerb.kAdequateHeap_of_wp' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.kAdequateHeap_of_wp
/-- info: 'RelSem.Cerb.two_alloc_frame' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.two_alloc_frame

-- arc-16 S3: THE LOOP PEELS + LAW LIBRARY + WP-TACTICS
-- (RelSem/PerStepRunner + PerStepPeel + PerStepLaws + PerStepTactics
-- + PerStepTacSmoke; design record
-- docs/2026-08-24_arc16-s3-laws-and-tactics.md). The runner algebra
-- is [propext(,Quot.sound)]-grade; the peels and the law library are
-- exactly the classical trio; the statement-facing adequacy wrappers
-- and the T1 tactic smoke inherit the temporal effect boundary's
-- runEffectful through the quoted harness substrate, IDENTICAL to
-- the committed T1's cone. Pinned exactly.
/-- info: 'RelSem.runNDFuel_bind_congr' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms RelSem.runNDFuel_bind_congr
/-- info: 'RelSem.runNDFuel_bind_assoc' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms RelSem.runNDFuel_bind_assoc
/-- info: 'RelSem.runNDFuel_bind_active' depends on axioms: [propext] -/
#guard_msgs in #print axioms RelSem.runNDFuel_bind_active
/-- info: 'RelSem.Cerb.dnmsK_runner_eq' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.dnmsK_runner_eq
/-- info: 'RelSem.Cerb.driver2K_runner_eq' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.driver2K_runner_eq
/-- info: 'RelSem.Cerb.callK2_runner_eq' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.callK2_runner_eq
/-- info: 'RelSem.Cerb.wpk_seq_active_ecast' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.wpk_seq_active_ecast
/-- info: 'RelSem.Cerb.wpk_seq_active_proj' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.wpk_seq_active_proj
/-- info: 'RelSem.Cerb.wpk_ite' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.wpk_ite
/-- info: 'RelSem.Cerb.wpk_ite_conj' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.wpk_ite_conj
/-- info: 'RelSem.Cerb.wpk_round_accum' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.wpk_round_accum
/-- info: 'RelSem.Cerb.wpk_round_advance' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.wpk_round_advance
/-- info: 'RelSem.Cerb.wpk_round_tau' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.wpk_round_tau
/-- info: 'RelSem.Cerb.wpk_round_eval' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.wpk_round_eval
/-- info: 'RelSem.Cerb.wpk_round_rsk_tau' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.wpk_round_rsk_tau
/-- info: 'RelSem.Cerb.wpk_round_tau_ret' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.wpk_round_tau_ret
/-- info: 'RelSem.Cerb.wpk_round_rsk_ret' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.wpk_round_rsk_ret
/-- info: 'RelSem.Cerb.wpk_round_load' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.wpk_round_load
/-- info: 'RelSem.Cerb.wpk_round_store' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.wpk_round_store
/-- info: 'RelSem.Cerb.wpk_round_create' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.wpk_round_create
/-- info: 'RelSem.Cerb.wpk_round_kill' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.wpk_round_kill
/-- info: 'RelSem.Cerb.wpk_pcs_done' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.wpk_pcs_done
/-- info: 'RelSem.Cerb.wpk_pcs_ccall' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.wpk_pcs_ccall
/-- info: 'RelSem.Cerb.kCallHarnessAdequate_of_wpK2' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.kCallHarnessAdequate_of_wpK2
/-- info: 'RelSem.Cerb.kCallHarnessUBFree_of_wpK2' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.kCallHarnessUBFree_of_wpK2
/-- info: 'RelSem.T1.t1_wpK_tac' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T1.t1_wpK_tac
/-- info: 'RelSem.T1.T1_perStep_tac' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T1.T1_perStep_tac
/-- info: 'RelSem.T1.two_alloc_frame_tac' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T1.two_alloc_frame_tac

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
/-- info: 'RelSem.Cerb.kCallHarnessAdequateThr_of_wp' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.kCallHarnessAdequateThr_of_wp
/-- info: 'RelSem.Cerb.kCallHarnessUBFreeThr_of_wp' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.kCallHarnessUBFreeThr_of_wp
/-- info: 'RelSem.T1.round0_thr' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T1.round0_thr
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
/-- info: 'RelSem.T1.round6' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T1.round6
/-- info: 'RelSem.T2.round13' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T2.round13
/-- info: 'RelSem.T3.round21' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T3.round21
/-- info: 'RelSem.T1.dnms_chain_thr' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T1.dnms_chain_thr
/-- info: 'RelSem.T1.driver2_iter_thr' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T1.driver2_iter_thr
/-- info: 'RelSem.T1.t1_app_eq_thr' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T1.t1_app_eq_thr
/-- info: 'RelSem.T1.t1_wpK_thr' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T1.t1_wpK_thr
/-- info: 'RelSem.T1.T1Threaded' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T1.T1Threaded
/-- info: 'RelSem.T1.T1Threaded_ubFree' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T1.T1Threaded_ubFree
/-- info: 'RelSem.T1.T1ThreadedOutcomes' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T1.T1ThreadedOutcomes
-- T2/T3 at the threaded state (same recipe; T2AppEq/T3AppEq's ∀-rs
-- round lemmas consumed AS-IS — since arc-17 S1 that is ALL of them;
-- no twins remain). T4 is PARKED at a kernel-witnessed diagnosis (the record
-- §T4): its exec path READS the supply (the NEG-store transform's two
-- draws), the drawn symbols enter comparison-keyed env maps, and at a
-- COLLIDING seed the fresh symbol captures a static one — the
-- unrestricted ∀-seed T4 statement is FALSE; the fresh conjunct
-- relaxes to a seed-apartness hypothesis, priced for part 2. The
-- ambient T4 (T4EnvHyp route) stands unchanged.
/-- info: 'RelSem.T2.t2_app_eq_thr' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T2.t2_app_eq_thr
/-- info: 'RelSem.T2.t2_wpK_thr' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T2.t2_wpK_thr
/-- info: 'RelSem.T2.T2Threaded' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T2.T2Threaded
/-- info: 'RelSem.T2.T2Threaded_ubFree' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T2.T2Threaded_ubFree
/-- info: 'RelSem.T2.T2ThreadedOutcomes' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T2.T2ThreadedOutcomes
/-- info: 'RelSem.T3.t3_app_eq_thr' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T3.t3_app_eq_thr
/-- info: 'RelSem.T3.t3_wpK_thr' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T3.t3_wpK_thr
/-- info: 'RelSem.T3.T3Threaded' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T3.T3Threaded
/-- info: 'RelSem.T3.T3Threaded_ubFree' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T3.T3Threaded_ubFree
/-- info: 'RelSem.T3.T3ThreadedOutcomes' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T3.T3ThreadedOutcomes

-- arc-17 S2: the completed acceptance probe — the t6 ∀-seed family
-- and the evaluator-emitted whole-run equations, trio-exact.
/-- info: 'RelSem.T6.T6Threaded' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T6.T6Threaded
/-- info: 'RelSem.T6.T6Threaded_ubFree' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T6.T6Threaded_ubFree
/-- info: 'RelSem.T6.t6_wpK_thr' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T6.t6_wpK_thr
/-- info: 'RelSem.T6.r_chain' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T6.r_chain
/-- info: 'RelSem.T6.r_driver' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T6.r_driver

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
/--
info: 'RelSem.Cerb.initial_driver_state_eq_threaded_ambient' depends on axioms: [propext,
 runEffectful,
 Classical.choice,
 Quot.sound]
-/
#guard_msgs in #print axioms RelSem.Cerb.initial_driver_state_eq_threaded_ambient
/-- info: 'RelSem.Cerb.callHarnessAdequate_of_thr' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.callHarnessAdequate_of_thr
/-- info: 'RelSem.T1.T1_of_threaded' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T1.T1_of_threaded
/-- info: 'RelSem.T2.T2_of_threaded' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T2.T2_of_threaded
/-- info: 'RelSem.T3.T3_of_threaded' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T3.T3_of_threaded

-- arc-17 S0: the `derive_state`-emitted equation lemmas of the
-- T1Threaded state ladder (the named-state emitter's first committed
-- clients). Kernel-checked `rfl` objects; pinned trio-exact so a
-- change in the emitter's proof shape (or the states' vocabulary)
-- surfaces build-fatally.
/-- info: 'RelSem.T1.rsD3_thr_def' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T1.rsD3_thr_def
/-- info: 'RelSem.T1.rsR6_thr_def' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T1.rsR6_thr_def
/-- info: 'RelSem.T1.drDone_thr_def' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.T1.drDone_thr_def

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
    The registered set below is the AMBIENT family (T1–T5 chains +
    the callND harness layer + the labeled ambient bridges) — the
    quartet-cone theorems the arc-16 S4 pins already LABEL as the
    impure side. The threaded family carries none of it. EXPECTED
    END STATE: the purge (charter S5) empties most of this list.
    Plant-tested both directions (transcripts:
    docs/2026-08-25_arc17-s2b-axiom-endgame.md). -/

open Lean in
/-- The registered `runEffectful` theorem carriers (see the section
    note above; 114 names, all ambient-family). -/
def runEffectfulCarriers : List Name :=
  [`RelSem.Cerb.callAdequate_of_app_active,
   `RelSem.Cerb.callAdequate_of_reach, `RelSem.Cerb.callAdequate_of_wp,
   `RelSem.Cerb.callHarnessAdequate_of_adequate,
   `RelSem.Cerb.callHarnessAdequate_of_app_active,
   `RelSem.Cerb.callHarnessAdequate_of_app_eq_wp,
   `RelSem.Cerb.callHarnessAdequate_of_thr,
   `RelSem.Cerb.callHarnessAdequate_of_wp,
   `RelSem.Cerb.callHarnessUBFree_of_app_active,
   `RelSem.Cerb.callHarnessUBFree_of_callHarnessAdequate,
   `RelSem.Cerb.callHarnessUBFree_of_ubFree,
   `RelSem.Cerb.callOutcomes_sound, `RelSem.Cerb.callReaches,
   `RelSem.Cerb.callUBFree_of_app_active,
   `RelSem.Cerb.callUBFree_of_app_eq_wp,
   `RelSem.Cerb.callUBFree_of_value_adequate,
   `RelSem.Cerb.callUBFree_of_wp,
   `RelSem.Cerb.initial_core_run_state_eq_threaded_ambient,
   `RelSem.Cerb.initial_driver_state_eq_threaded_ambient,
   `RelSem.Cerb.kCallHarnessAdequate_of_wp,
   `RelSem.Cerb.kCallHarnessAdequate_of_wpK2,
   `RelSem.Cerb.kCallHarnessUBFree_of_wp,
   `RelSem.Cerb.kCallHarnessUBFree_of_wpK2, `RelSem.Cerb.wp_callND,
   `RelSem.Cerb.wp_callND_killed, `RelSem.Cerb.wp_of_app_active,
   `RelSem.T1.dnms_chain, `RelSem.T1.driver2_iter,
   `RelSem.T1.k1_globals, `RelSem.T1.k3_resolve, `RelSem.T1.k4_body,
   `RelSem.T1.k5_ptys, `RelSem.T1.k6_inject, `RelSem.T1.k7_ths,
   `RelSem.T1.k8_errno, `RelSem.T1.k9_update, `RelSem.T1.ndct_eq,
   `RelSem.T1.prefix_a, `RelSem.T1.prefix_b, `RelSem.T1.prefix_walk,
   `RelSem.T1.T1, `RelSem.T1.t1_app_eq, `RelSem.T1.t1AppEq_holds,
   `RelSem.T1.T1_direct, `RelSem.T1.t1_of_app_eq,
   `RelSem.T1.t1_of_app_eq_direct, `RelSem.T1.T1_of_threaded,
   `RelSem.T1.T1Outcomes, `RelSem.T1.T1_perStep,
   `RelSem.T1.T1_perStep_tac, `RelSem.T1.t1_result_eq,
   `RelSem.T1.T1_ubFree, `RelSem.T1.t1_ubFree_of_app_eq,
   `RelSem.T1.T1_ubFree_perStep, `RelSem.T1.t1_wp, `RelSem.T1.t1_wpK,
   `RelSem.T1.t1_wpK_tac, `RelSem.T2.dnms_chain,
   `RelSem.T2.driver2_iter, `RelSem.T2.ndct_eq, `RelSem.T2.prefix_a,
   `RelSem.T2.prefix_a0, `RelSem.T2.prefix_a1, `RelSem.T2.prefix_b,
   `RelSem.T2.prefix_walk, `RelSem.T2.T2, `RelSem.T2.t2_app_eq,
   `RelSem.T2.T2_direct, `RelSem.T2.T2_of_threaded,
   `RelSem.T2.T2Outcomes, `RelSem.T2.t2_result_eq,
   `RelSem.T2.T2_ubFree, `RelSem.T3.dnms_chain,
   `RelSem.T3.driver2_iter, `RelSem.T3.ndct_eq, `RelSem.T3.prefix_a0,
   `RelSem.T3.prefix_a1, `RelSem.T3.prefix_b, `RelSem.T3.prefix_walk,
   `RelSem.T3.T3, `RelSem.T3.t3_app_eq, `RelSem.T3.T3_direct,
   `RelSem.T3.T3_of_threaded, `RelSem.T3.T3Outcomes,
   `RelSem.T3.t3_result_eq, `RelSem.T3.T3_ubFree,
   `RelSem.T4.anon1_stuck_eq, `RelSem.T4.anon2_stuck_eq,
   `RelSem.T4.arena16_stuck, `RelSem.T4.arena33_stuck,
   `RelSem.T4.dnms_chain, `RelSem.T4.driver2_iter, `RelSem.T4.ndct_eq,
   `RelSem.T4.prefix_a0, `RelSem.T4.prefix_a1, `RelSem.T4.prefix_b,
   `RelSem.T4.prefix_walk, `RelSem.T4.round15, `RelSem.T4.round32,
   `RelSem.T4.round54, `RelSem.T4.T4, `RelSem.T4.t4_app_eq,
   `RelSem.T4.T4_direct, `RelSem.T4.T4Outcomes,
   `RelSem.T4.t4_result_eq, `RelSem.T4.T4_ubFree,
   `RelSem.T5.entry5_walk, `RelSem.T5.envL_built,
   `RelSem.T5.envL_lookup_i, `RelSem.T5.envL_lookup_n,
   `RelSem.T5.envL_lookup_s, `RelSem.T5.prefix5_a,
   `RelSem.T5.prefix5_b, `RelSem.T5.prefix5_walk]

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
-- Re-baselines: 3348 → 3356 (arc-15 T5 resumption, R-S2-1 batch:
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
-- the build).
/--
info: RelSem audit sweep: 4646 declarations (module-of-origin root RelSem, within RelSem.Audit's import closure — NOT the whole tree), all within the declared axiom boundary (0 recorded sorryAx exceptions)
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
