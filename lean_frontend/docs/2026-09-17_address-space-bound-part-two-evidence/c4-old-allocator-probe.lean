import CerbMem
/-! C4 (pre-merge audit F2, 2026-09-18) — the PRE-FIX allocator body EXECUTED on the exact cursor the
    discriminator reaches. `allocatorOld` below is `CerbMem.allocator` at mainline 4a23d98aa (part one's
    base — the last mainline before remedy 1; `git show 4a23d98aa:lean_frontend/CerbMem.lean`), copied
    VERBATIM by the shell that wrote this file and renamed; `CerbMem.allocator` is this tree's fixed body.
    Both are run over the schedule of tests/address_space/window-char-int7.c — the driver's errno int
    (4, align 4), `char c` (1, align 1), `int a[7]` (28, align 4) — from `initialMemState top` at the
    lane's tops 64 / 32 / 8. Executed via scripts/lean_probe.sh (capped), from lean_frontend/. -/
open CerbMem
set_option autoImplicit false

def allocatorOld (sz align : Int) : memM (StorageInstanceId × Address) :=
  ND fun st =>
    let allocId := st.nextAllocId
    if align == 0 then
      (NDkilled (CerbFail.failStopKill "CerbMem.allocator: alignment 0 has no meaning in the model (impl_mem.ml:1252 quomod raises Division_by_zero — an OCaml-execution artifact, not the referent); operator decision pending, zero-discrepancy Z2 record §10"), st)
    else
      let z := st.lastAddress - sz
      let q := z / align
      let m := z % align
      let z' := z - (if q < 0 then -m else m)
      if z' ≤ 0 then
        (NDkilled (Other (MerrOther "Concrete.allocator: failed (out of memory)")), st)
      else
        (NDactive (allocId, z'),
         { st with nextAllocId := allocId + 1, lastUsed := some allocId, lastAddress := z' })


def stepWith (alloc : Int → Int → memM (StorageInstanceId × Address)) (st : MemState) (sz align : Int) :
    String × Option MemState :=
  match alloc sz align with
  | ND f =>
    match f st with
    | (NDactive (id, a), st') => (s!"ACTIVE id={id} addr={a} cursor'={st'.lastAddress}", some st')
    | (NDkilled (Other (MerrOther msg)), st') => (s!"KILLED[MerrOther {msg}] cursor={st'.lastAddress}", none)
    | (NDkilled _, st') => (s!"KILLED[other kind] cursor={st'.lastAddress}", none)
    | (_, st') => (s!"other outcome cursor={st'.lastAddress}", none)

/-- window-char-int7.c's allocation schedule: (label, size, align). -/
def schedule : List (String × Int × Int) := [("errno int", 4, 4), ("char c", 1, 1), ("int a[7]", 28, 4)]

def runSchedule (label : String) (alloc : Int → Int → memM (StorageInstanceId × Address)) (top : Int) : IO Unit := do
  IO.println s!"== {label}, top = {top}: initialMemState {top}"
  let mut st := initialMemState top
  for (name, sz, al) in schedule do
    let (msg, st') := stepWith alloc st sz al
    IO.println s!"   {name} (size {sz}, align {al}) at cursor {st.lastAddress}: {msg}"
    match st' with
    | some s => st := s
    | none => break

#eval do
  IO.println s!"Lean {Lean.versionString}; Int (-1)%4={(-1:Int)%4} (-1)/4={(-1:Int)/4} (Euclidean, as Zarith ediv_rem)"
  for top in [64, 32, 8] do
    runSchedule "OLD body (4a23d98aa, pre-remedy-1)" allocatorOld top
    runSchedule "FIXED body (this tree, CerbMem.allocator)" allocator top
