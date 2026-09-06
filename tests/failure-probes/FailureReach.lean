import Unit.FuelFormsTool
import CerbND
import CerbCall
import Cabs_to_ail
import GenTyping
import Translation
import Core_linking
import Core_typing
import Mini_pipeline

open Lean in
run_cmd do
  let env ← getEnv
  for entry in entries ++ frontEntries do
    unless (env.find? entry).isSome do
      throwError "missing public entry {entry}"
  let exec := closure env entries
  let front := closure env frontEntries
  -- Opaque/partial frontend declarations must remain visible in the census.
  -- Their kernel dependency closure is not a compiled call graph.
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
    if let some ranges ← findDeclarationRanges? n then
      let r := ranges.range
      logInfo m!"FAILURE_RANGE\t{n}\t{modName}\t{kind}\t{r.pos.line}\t{r.pos.column}\t{r.endPos.line}\t{r.endPos.column}"
