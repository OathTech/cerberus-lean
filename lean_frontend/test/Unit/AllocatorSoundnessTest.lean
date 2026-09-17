import CerbMemAllocatorProofs

/-! # AllocatorSoundnessTest — the RUNTIME witness of upstream-tray draft 44

The four states of the draft evaluated on the ACTUAL `CerbMem.allocator` (remedy 1
landed 2026-09-16; charter `docs/2026-09-16_charter-allocator-soundness-address-bound.md`
§2 C1(d)). A runtime TEST — an exit code — not a proof: the GENERAL statement is
`CerbMem.allocator_active_sound` (CerbMemAllocatorProofs.lean), imported here so
every run of this exe compiles the kernel theorem too.

NEGATIVE CONTROL — the PRE-FIX values, verbatim from the probe of the mirror as built
at the charter head 6d9ba82f1 (evidence: `docs/2026-09-16_allocator-soundness-address-
bound-evidence/c1-prefix-negative-control.txt`; the reference's own Zarith arithmetic
gives the same four answers, draft 44 "Reproducer"):
  "last=3 sz=4 align=4: active, id=0 address=2 cursor'=2"
  "last=7 sz=8 align=8: active, id=0 address=6 cursor'=6"
  "last=2 sz=4 align=4: killed (Concrete.allocator: failed (out of memory)) cursor'=2"
  "last=8 sz=4 align=4: active, id=0 address=4 cursor'=4"
The first two are the defect (an address in (0, align) overlapping the live object at
the cursor, misaligned); the fourth is the normal regime and must be unchanged.
EXPECTED after the fix: killed / killed / killed / active at 4 with cursor 4. -/

namespace AllocatorSoundnessTest
open CerbMem

inductive Outcome where
  | active (id a cursor : Int)
  | outOfMemory (cursor : Int)
  | other
  deriving BEq, Repr

def observe (last sz align : Int) : Outcome :=
  let st : MemState := { lastAddress := last }
  match allocatorStep sz align st with
  | (NDactive (id, a), st') => .active id a st'.lastAddress
  | (NDkilled (Other (MerrOther "Concrete.allocator: failed (out of memory)")), st') =>
      .outOfMemory st'.lastAddress
  | _ => .other

structure Case where
  name : String
  last : Int
  sz : Int
  align : Int
  expected : Outcome
  preFix : String   -- the negative control, quoted from the pre-fix probe

def cases : List Case := [
  { name := "cursor 3, request (4, 4)", last := 3, sz := 4, align := 4,
    expected := .outOfMemory 3, preFix := "active, address 2 (the defect)" },
  { name := "cursor 7, request (8, 8)", last := 7, sz := 8, align := 8,
    expected := .outOfMemory 7, preFix := "active, address 6 (the defect)" },
  { name := "cursor 2, request (4, 4)", last := 2, sz := 4, align := 4,
    expected := .outOfMemory 2, preFix := "killed (out of memory)" },
  { name := "cursor 8, request (4, 4)", last := 8, sz := 4, align := 4,
    expected := .active 0 4 4, preFix := "active, address 4 (the normal regime)" } ]

end AllocatorSoundnessTest

def main : IO UInt32 := do
  IO.println "allocator-soundness-test: the four draft-44 states on the ACTUAL CerbMem.allocator (remedy 1)"
  let mut failed := false
  for c in AllocatorSoundnessTest.cases do
    let got := AllocatorSoundnessTest.observe c.last c.sz c.align
    let ok := got == c.expected
    IO.println s!"{if ok then "PASS" else "FAIL"} {c.name}: got {repr got}, expected {repr c.expected}; pre-fix: {c.preFix}"
    failed := failed || !ok
  if failed then
    IO.eprintln "allocator-soundness-test: FAILED (a draft-44 state does not match remedy 1's expected outcome)"
    return 1
  IO.println "allocator-soundness-test: OK (4/4 states; kernel theorem CerbMem.allocator_active_sound compiled)"
  return 0
