/-
  Unit.T4EnvWitnessTest — arc-7 S5c (audit-1 F3): the T4EnvHyp
  FIRST-IN-PROCESS witness probe.

  T4's statement (RelSem/T4.lean) holds under `T4EnvHyp` — three
  process-global extern facts the kernel cannot see through. This exe
  witnesses, in a fresh process that mirrors the harness executable's
  startup order EXACTLY (Main.lean: the floor probe draws first, then
  tags are set, then ONE `initial_driver_state` is constructed and
  run), that the hypothesized values are the values the process
  actually establishes:

    (0) the FIRST process draw is 1048576 — native/fresh_int.c is
        post-increment from CERB_FRESH_BASE = 1<<20 (the F3-corrected
        account: 1048577 is NOT the first draw);
    (1) after `setTagDefsIO t4File.tagDefs`, the live tag global
        yields exactly the pinned `struct S` layout T4's equations
        read (sizeof 8, alignof 4, member offsets a=+0 / b=+4);
    (2) `CerberusFresh.digest () = ""`;
    (3) the SECOND process draw — `initial_driver_state`'s sym-supply
        seed — is 1048577, the value `T4EnvHyp`'s third conjunct pins;
    then t4 is RUN on that exact state: the outcome must be the
    `Active Specified(11)` singleton (T4's spec at x = 11).

  ORDERING IS THE POINT: this test must be the process's first
  fresh-draw activity (its own exe, never merged into another test).
  Wired into scripts/test_verify.sh (fail-closed).
-/

import RelSem.Call
import RelSem.SlateFiles
-- NOTE: deliberately NOT importing the T?AppEq/T4Defs proof modules:
-- their closed initial-state constants (e.g. RelSem.T1.rsD3) are
-- evaluated at MODULE INITIALIZATION and each consumes a fresh draw,
-- which would shift this probe's draw counter. The import closure here
-- mirrors the harness executable's (Main imports RelSem.Call; the
-- fixture data adds no draws).

set_option autoImplicit false

open RelSem.Cerb RelSem.Slate

/-- `struct S`'s C type (as RelSem.T4.structSCty, restated locally to
    keep the proof modules out of the import closure — note above). -/
def structSCty : ctype := Ctype [] (Struct structSSym)

def main : IO UInt32 := do
  let mut failures := 0
  let check (label : String) (ok : Bool) : IO Nat := do
    if ok then
      IO.println s!"ok   {label}"
      pure 0
    else
      IO.println s!"FAIL {label}"
      pure 1

  -- (0) FIRST process draw (mirrors Main.lean's startup floor probe).
  let d1 ← CerberusFresh.freshIntIO ()
  failures := failures + (← check
    s!"first process draw = 1048576 (got {d1}; post-increment from 1<<20)"
    (d1 == 1048576))

  -- (1) Establish the tag global exactly as Main --call does
  --     (Main.lean: resetTagDefsIO + setTagDefsIO), then witness the
  --     pinned struct S layout through the LIVE global — the exact
  --     reads T4's layout equations make.
  let _ ← (CerbTags.resetTagDefsIO () : BaseIO Unit)
  let _ ← (CerbTags.setTagDefsIO t4File.tagDefs : BaseIO Unit)
  failures := failures + (← check
    "tag global: sizeof(struct S) = 8"
    (CerbMem.sizeofCtype structSCty == 8))
  failures := failures + (← check
    "tag global: alignof(struct S) = 4"
    (CerbMem.alignofCtype structSCty == 4))
  let offOf (memb : String) : Option Int :=
    match CerbMem.offsetofIval (CerbTags.tagDefs ()) structSSym
        (Identifier CerbLocation.Loc.unknown memb) with
    | CerbMem.IntegerValue.IV _ n => some n
  failures := failures + (← check
    s!"tag global: struct S member offsets a=+0, b=+4 (got {offOf "a"}, {offOf "b"})"
    (offOf "a" == some 0 && offOf "b" == some 4))

  -- (2) The TU-digest global at its initial (unset) value.
  let dig := CerberusFresh.digest ()
  failures := failures + (← check
    s!"digest () = \"\" (got \"{dig}\")" (dig == ""))

  -- (3) The SECOND process draw: the sym-supply seed of the ONE
  --     driver state this process constructs — T4EnvHyp's third
  --     conjunct, operationally.
  let drSt := initial_driver_state t4File CerbFS.fs_initial_state
  let supply := drSt.core_run_state0.sym_supply
  failures := failures + (← check
    s!"initial_driver_state sym-supply seed = 1048577 (got {supply}; the SECOND process draw)"
    (supply == 1048577))

  -- Run t4 on EXACTLY that state (the theorem's environment): the
  -- production runner's outcome set must be the Active
  -- Specified(11) singleton.
  let outcome :=
    match CerbND.runND (callND t4File.tagDefs t4File "memb"
        [intValue 11]) drSt with
    | [(Active r, _, _)] =>
      match r.dres_core_value with
      | Vloaded (LVspecified (OVinteger (CerbMem.IntegerValue.IV _ n))) =>
        if n == 11 then none else some s!"Specified({n}), expected 11"
      | _ => some "single Active execution, non-integer result value"
    | [(Killed _ _, _, _)] => some "Killed"
    | [] => some "no executions"
    | _ => some "multiple executions"
  failures := failures + (← check
    "t4 memb(11) on the witnessed state = {Active Specified(11)}"
    outcome.isNone)
  match outcome with
  | some msg => IO.println s!"     detail: {msg}"
  | none => pure ()

  if failures == 0 then
    IO.println "T4EnvWitnessTest: ALL PASSED"
    return 0
  else
    IO.println s!"T4EnvWitnessTest: {failures} FAILURE(S)"
    return 1
