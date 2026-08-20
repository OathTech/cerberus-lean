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
     non-kernel-method axioms) are never in it. (Header line "DAEMON
     entering `runNDT_sound`" reads `runNDFuel_sound` since the arc-7 S2
     totalize-CerbND transfer.)

  2. CURATED PINS — `#guard_msgs in #print axioms` on the load-bearing
     proved theorems, asserting their EXACT axiom sets, so growth (e.g.
     DAEMON entering `runNDT_sound`) is a build failure until this file
     is deliberately re-baselined in the same commit with the reason.

  THE DECLARED BOUNDARY (allowlist), with provenance:
  * the classical trio `propext`, `Classical.choice`, `Quot.sound`;
  * `DAEMON` (LemLib.lean:26) — lem's Inhabited-fallback axiom for
    generated instances;
  * `runEffectful` (LemLib.lean:52) — the arcs-1+2 effect-erasure
    barrier (docs/2026-08-18_effects-totality-design.md);
  * `CerbTags.with_tagDefs` (CerbTags.lean:70) and
    `CerberusFresh.forceIO` (CerberusFresh.lean:113) — the two
    hand-written declared-boundary axioms (check_theorem_axioms.sh
    census).
  Deliberately NOT allowed: `DAEMON1` (LemLib.lean:27) — it has never
  appeared in a RelSem cone; if it ever does, that is a fresh decision,
  not a drift.

  DAEMON DISPOSITION ([AGENT:S1S0], 2026-08-19, decided on probe
  evidence): DAEMON DOES appear in RelSem cones — e.g.
  `pexprStep_val` / `step_eval_pexpr_val_erase` / `driver2_wrapper_defeq`
  carry it. This is NOT a generated-instance leak into proof REASONING:
  `collectAxioms` walks the VALUES of every constant a statement
  mentions, so any theorem about the real generated substrate
  (`step_eval_pexpr`, `driver2`, `drive` — each of whose compiled bodies
  contains lem's DAEMON Inhabited fallback) inherits DAEMON through the
  substrate, exactly the arc-3 D9 allowance for driver2's cone. No
  relsem/ source names DAEMON (the hand-written axiom census and the D14
  grep cover relsem/), so the only entry vector is the generated code.
  The layer-boundary theorems that do NOT mention the fuel'd substrate
  (`runNDFuel_sound`, `runND_sound`, `runNDFuel_mono`, `behaviors_sound`,
  `seqModel_behavior_sound`, `seqModel_adequate_of_reach`,
  `pointsToByte_functional`) are DAEMON-FREE and pinned exactly below —
  the curated pins are what keep "DAEMON allowed in principle" from
  becoming "DAEMON everywhere".

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
import RelSem.IrisCoupling

namespace RelSem.Audit

open Lean

/-- The declared axiom boundary (docstring above records provenance). -/
def allowedAxioms : List Name :=
  [``propext, ``Classical.choice, ``Quot.sound,
   `DAEMON, `runEffectful, `CerbTags.with_tagDefs, `CerberusFresh.forceIO]

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
-- Substrate-mentioning theorems: DAEMON enters through the generated
-- bodies they quote (disposition in the header), pinned exactly so any
-- FURTHER growth (sorryAx above all) is a build failure.
/-- info: 'RelSem.Cerb.step_eval_pexpr_val_erase' depends on axioms: [DAEMON, propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.step_eval_pexpr_val_erase
/-- info: 'RelSem.Cerb.pexprStep_val' depends on axioms: [DAEMON, propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.pexprStep_val
/-- info: 'RelSem.Cerb.driver2_wrapper_defeq' depends on axioms: [DAEMON, propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.driver2_wrapper_defeq
-- arc-7 S3: coverage-by-need micro-lemmas (RelSem/Machine.lean §
-- "Coverage-by-need", RelSem/Cerberus.lean liftMem_step_killed). The
-- generic app-equation layer is near-axiom-free (propext from the simp
-- rewrites); app_pick_singleton quotes `pick` (whose compiled body
-- carries lem's failwith fallback) so DAEMON enters through the
-- substrate, exactly the standing disposition. Pinned exactly.
/-- info: 'RelSem.step_done_inv' does not depend on any axioms -/
#guard_msgs in #print axioms RelSem.step_done_inv
/-- info: 'RelSem.app_bind_killed' depends on axioms: [propext] -/
#guard_msgs in #print axioms RelSem.app_bind_killed
/-- info: 'RelSem.app_liftND_killed' depends on axioms: [propext] -/
#guard_msgs in #print axioms RelSem.app_liftND_killed
/-- info: 'RelSem.app_pick_singleton' depends on axioms: [DAEMON, propext] -/
#guard_msgs in #print axioms RelSem.app_pick_singleton
/-- info: 'RelSem.Cerb.liftMem_step_active' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.liftMem_step_active
/-- info: 'RelSem.Cerb.liftMem_step_killed' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.liftMem_step_killed
-- arc-7 S3: the symbolic-argument harness (RelSem/Call.lean). Every
-- theorem below MENTIONS the harness computation `callND` (drive-path
-- generated substrate), so DAEMON and runEffectful enter through the
-- quoted bodies exactly as for the D3-disposed substrate theorems
-- above (initial_driver_state carries runEffectful; the driver code
-- carries DAEMON). Pinned exactly — growth (sorryAx above all) fails
-- the build. `ofStatus_value_inv` is the harness's one pure lemma and
-- is pinned axiom-FREE.
/-- info: 'RelSem.Cerb.callReaches' depends on axioms: [DAEMON, propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.callReaches
/-- info: 'RelSem.Cerb.callOutcomes_sound' depends on axioms: [DAEMON, propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.callOutcomes_sound
/-- info: 'RelSem.Cerb.callAdequate_of_reach' depends on axioms: [DAEMON, propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms RelSem.Cerb.callAdequate_of_reach
/-- info: 'RelSem.Cerb.ofStatus_value_inv' does not depend on any axioms -/
#guard_msgs in #print axioms RelSem.Cerb.ofStatus_value_inv
/--
info: 'RelSem.Cerb.callHarnessAdequate_of_adequate' depends on axioms: [DAEMON,
 propext,
 runEffectful,
 Classical.choice,
 Quot.sound]
-/
#guard_msgs in #print axioms RelSem.Cerb.callHarnessAdequate_of_adequate

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
