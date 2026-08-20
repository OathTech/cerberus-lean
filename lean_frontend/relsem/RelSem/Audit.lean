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
    barrier (docs/2026-08-18_effects-totality-design.md);
  * `CerbTags.with_tagDefs` (CerbTags.lean:70) and
    `CerberusFresh.forceIO` (CerberusFresh.lean:113) — the two
    hand-written declared-boundary axioms (check_theorem_axioms.sh
    census).

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
import RelSem.T4Defs
import RelSem.T4AppEq
import RelSem.T4

namespace RelSem.Audit

open Lean

/-- The declared axiom boundary (docstring above records provenance). -/
def allowedAxioms : List Name :=
  [``propext, ``Classical.choice, ``Quot.sound,
   `runEffectful, `CerbTags.with_tagDefs, `CerberusFresh.forceIO]

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
   `RelSem.Slate.t2File, `RelSem.Slate.t3File, `RelSem.Slate.t4File]

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
     `RelSem.T4.T4Outcomes]
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

/-! ## The exhaustive sweep — LAST in the file by design: a constant
    declared after this point would dodge it (negative-test lesson,
    2026-08-19), so nothing may be declared below, and RelSem.Audit is
    the last import of the lib root. -/

open Lean in
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
    IO.println s!"RelSem audit sweep: {audited} declarations across \
      RelSem.* modules, all within the declared axiom boundary \
      ({sorryExceptions.length} recorded sorryAx exceptions)"
  else
    let lines := bad.qsort (fun a b => a.1.toString < b.1.toString)
      |>.map (fun (n, ax) => s!"  {n} depends on {ax}")
    throwError "RelSem audit sweep FAILED — declarations with axioms \
      outside the declared boundary (a `sorry`, a non-kernel decision \
      procedure, or new \
      postulate?):\n{String.intercalate "\n" lines.toList}"

end RelSem.Audit
