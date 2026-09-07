/-
  FailureReachProbe.lean — the census's declaration-dependency instrument
  (tests/failure-probes/FailureReach.lean, copied verbatim in its FAILURE_REACH /
  FAILURE_RANGE emission) plus ONE extra column family for the reachability
  census (docs/2026-09-07_pure-failure-reachability-census.md Q5):

    FAILURE_CONS <name> <in closure(drive)> <in closure(consumer fine roots)> <in closure(consumer STEP-level roots)>

  where the consumer fine roots are the cerberus-lean constants refined-cerberus's
  current sources reference directly (cerberus-heaplang/CerberusHeapLang/{Step,
  DriverCollapse,Soundness}.lean, read-only grep 2026-09-07; the list is in the
  census record). `entries`, `frontEntries` and `closure` are FuelFormsTool's.
  Read-only instrument: it edits nothing and proves nothing.
-/
import Unit.FuelFormsTool
import CerbND
import CerbCall
import Cabs_to_ail
import GenTyping
import Translation
import Core_linking
import Core_typing
import Mini_pipeline

open Lean

/-- refined-cerberus's directly referenced cerberus-lean constants (grep of the
    three importing files; comments/doc mentions included — over-approximation). -/
def consumerFineRoots : List Name :=
  [`driver2, `step_ctx, `step_action, `step_eval_pexpr, `full_eval_pexpr,
   `eval_pexpr_aux2, `E.eval_pexpr20, `memValueFromValue, `hack,
   `finalize, `to_pure, `process_core_step2, `new_drive_core_threads,
   `drive_nonmemory_steps_aux2, `CerbND.runND, `CerbND.runNDFuel, `liftMem,
   `liftCore_run, `valueFromPexpr, `CerbMem.storeM, `CerbMem.loadM, `CerbMem.killM,
   `CerbMem.allocateObject, `CerbMem.allocateRegion, `CerbMem.opIval,
   `CerbMem.eqPtrval, `CerbMem.ltIval, `CerbMem.leIval, `CerbMem.eqIval,
   `CerbMem.minIval, `CerbMem.maxIval, `CerbMem.sizeofIval, `CerbMem.alignofIval,
   `CerbMem.arrayShiftPtrval]

/-- The STEP-LEVEL subset of the consumer roots: what the consumer's per-step
    theorems (Step.lean / Soundness.lean) are about, without the driver-level
    roots (`drive`, `driver2`, `hack`, `finalize`, `process_core_step2`,
    `new_drive_core_threads`, `drive_nonmemory_steps_aux2`, the runners and lifts). -/
def consumerStepRoots : List Name :=
  [`step_ctx, `step_action, `step_eval_pexpr, `full_eval_pexpr, `eval_pexpr_aux2,
   `E.eval_pexpr20, `memValueFromValue, `to_pure, `valueFromPexpr,
   `CerbMem.storeM, `CerbMem.loadM, `CerbMem.killM, `CerbMem.allocateObject,
   `CerbMem.allocateRegion, `CerbMem.opIval, `CerbMem.eqPtrval, `CerbMem.ltIval,
   `CerbMem.leIval, `CerbMem.eqIval, `CerbMem.minIval, `CerbMem.maxIval,
   `CerbMem.sizeofIval, `CerbMem.alignofIval, `CerbMem.arrayShiftPtrval]

run_cmd do
  let env ← getEnv
  for entry in entries ++ frontEntries ++ consumerFineRoots do
    unless (env.find? entry).isSome do
      throwError "missing public entry {entry}"
  let exec := closure env entries
  let front := closure env frontEntries
  let driveOnly := closure env [`drive]
  let cons := closure env consumerFineRoots
  let consStep := closure env consumerStepRoots
  for (n, ci) in env.constants.toList do
    let some midx := env.getModuleIdxFor? n | continue
    let modName := env.allImportedModuleNames[midx.toNat]!.toString
    if ["Lean", "Init", "Std", "Lake", "LemLib", "Unit"].any (fun pref => modName.startsWith pref) then
      continue
    let kind := match ci with
      | .defnInfo _ => "definition"
      | .opaqueInfo _ => "opaque"
      | _ => "other"
    if kind == "other" then continue
    logInfo m!"FAILURE_REACH\t{n}\t{exec.contains n}\t{front.contains n}"
    logInfo m!"FAILURE_CONS\t{n}\t{driveOnly.contains n}\t{cons.contains n}\t{consStep.contains n}"
    if let some ranges ← findDeclarationRanges? n then
      let r := ranges.range
      logInfo m!"FAILURE_RANGE\t{n}\t{modName}\t{kind}\t{r.pos.line}\t{r.pos.column}\t{r.endPos.line}\t{r.endPos.column}"
