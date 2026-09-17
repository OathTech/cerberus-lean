import CerbMem
/-! AUDITOR negative control (b): the runtime witness's four cases and EXPECTED outcomes
    (test/Unit/AllocatorSoundnessTest.lean, verbatim) evaluated on the compiled `CerbMem.allocator`
    of the PRE-FIX body (generated/CerbMem.lean == 6d9ba82f1), through the same observer shape as
    `CerbMem.allocatorStep`. The witness must FAIL here for it to be a witness. -/
open CerbMem
inductive Outcome where | active (id a cursor : Int) | outOfMemory (cursor : Int) | other
  deriving BEq, Repr
def observe (last sz align : Int) : Outcome :=
  let st : MemState := { lastAddress := last }
  match (match allocator sz align with | ND f => f st) with
  | (NDactive (id, a), st') => .active id a st'.lastAddress
  | (NDkilled (Other (MerrOther "Concrete.allocator: failed (out of memory)")), st') => .outOfMemory st'.lastAddress
  | _ => .other
def cases : List (String × Int × Int × Int × Outcome) := [
  ("cursor 3, request (4, 4)", 3, 4, 4, .outOfMemory 3),
  ("cursor 7, request (8, 8)", 7, 8, 8, .outOfMemory 7),
  ("cursor 2, request (4, 4)", 2, 4, 4, .outOfMemory 2),
  ("cursor 8, request (4, 4)", 8, 4, 4, .active 0 4 4) ]
#eval do
  let mut failed := 0
  for (n, l, s, a, e) in cases do
    let got := observe l s a
    IO.println s!"{if got == e then "PASS" else "FAIL"} {n}: got {repr got}, expected {repr e}"
    if got != e then failed := failed + 1
  IO.println s!"OLD BODY: {failed} of 4 cases FAIL the witness's expectations (3 expected: the two defect states + the third's... see output)"
