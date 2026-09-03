# `dynamic_addrs` tracks dynamic allocations by address and is never cleaned: a zero-size `alloc` at the base of a live object makes `free` of that object pass the dynamic check

**Affected:** `memory/concrete/impl_mem.ml` — `dynamic_addrs` field :497
(initial `[]` :517); `is_dynamic` :661-663 (`List.mem addr
st.dynamic_addrs`); `allocate_region` :1420-1435 (record :1429 with
`size= size_n`, no lower bound; `dynamic_addrs= addr :: st.dynamic_addrs`
:1433 — the list's ONLY writer); `kill` :1464-1550 (dynamic arms check
`is_dynamic addr` first, :1492-1499 / :1518-1525, then `is_dead`
:1527-1532, then the base match :1534-1549; neither arm touches
`dynamic_addrs`); `allocator` :1247-1265 (cursor `last_address` moves by
`sz`, so `sz = 0` leaves it in place). Checked against `master` @
`b9aeedcb4`: our copy of impl_mem.ml is byte-identical through :2998
(the only fork delta is a 5-line addition at :2999-3003, after every
cited line). `runtime/libcore/std.core:350-358` (`malloc_proxy`:
`alloc(IvMaxAlignment, size)`) and `parsers/core/core_parser.mly:1536-1537`
are byte-identical to master.

## Description

The dynamic check in `kill`/`free` is "is this ADDRESS the base of some
dynamic allocation that ever existed", not "is this ALLOCATION dynamic":

```
let is_dynamic addr : bool memM =
  get >>= fun st ->
  return (List.mem addr st.dynamic_addrs)                       (* :661-663 *)
...
let alloc = {prefix= Symbol.PrefMalloc; base= addr; size= size_n; ty= None; ...} in
update (fun st ->
  { st with
      allocations= IntMap.add alloc_id alloc st.allocations;
      dynamic_addrs= addr :: st.dynamic_addrs })                 (* :1429-1434 *)
```

Two properties of the model combine with it. (1) `allocate_region`
admits `size_n = 0`, and `allocator` :1247-1265 computes the new base as
`last_address - size` aligned down — with size 0 and an alignment that
divides `last_address`, the new base IS `last_address`, the base of the
most recently allocated object (the cursor is never bumped past a live
object). (2) `kill` never removes anything from `dynamic_addrs`, so the
list accumulates the bases of dead regions and duplicates.

Hence: `create` an object `x` at base `B`; `alloc(a, 0)` with `a | B`
mints a zero-size dynamic region at `B` and pushes `B`; `free(x)` —
a dynamic kill of the CREATED object — now passes `is_dynamic B`, passes
`is_dead`, matches `addr = alloc.base`, and succeeds. The automatic
object is deallocated with no UB report. C11 §7.22.3.3p2 makes this
undefined behaviour, and Cerberus's own verdict for it,
`UB179a_non_matching_allocation_free` (`frontend/model/mem_common.lem:
279-280`, "does not match any existing dynamic allocation"), does not
fire.

## Reproducer (Core; upstream binary @ b9aeedcb4)

`tests/noodle-probes/dynamic-addrs/core_bug.core` in our tree:

```
proc main (): eff loaded integer :=
  let strong x_ptr: pointer = create(16, 'signed int') in
  store('signed int', x_ptr, Specified(1)) ;
  let strong q: pointer = alloc(8, 0) in
  free(x_ptr) ;
  pure(Specified(0))
```

```
$ cerberus --nolibc --exec --batch --mode=exhaustive core_bug.core
Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
```

Control (`core_control.core`: the same program without the `alloc` line):

```
Undefined {ub: "UB179a_non_matching_allocation_free", stderr: "", loc: "<5:3--5:14>"}
```

Consequences, same binary (verbatim, 2026-09-03):

- `core_use_after_free.core` — `load('signed int', x_ptr)` after the
  accepted free: `Undefined {ub: "UB010_pointer_to_dead_object", ...}`
  (the automatic object really is gone).
- `core_bug_then_kill.core` — the accepted free followed by the object's
  own scope-exit `kill('signed int', x_ptr)` (what every C block exit
  does): `cerberus: internal error, uncaught exception:
  Failure("Concrete: FREE was called on a dead allocation")`, exit 125
  (impl_mem.ml:1532's `failwith`, reached only through this path).
- `core_dup.core` — two `alloc(8, 0)` at `B`, `free` both, then
  `free(x_ptr)`: `Specified(0)` (duplicates in the list; each region has
  its own id, so `core_dup_dead.core`'s double free of ONE region is
  still caught: `UB179b_dead_allocation_free`).

All of the above are identical on our fork's oracle (built from
`72164481a`). The runner and the full verbatim log:
`tests/noodle-probes/dynamic-addrs/{run_dynaddr.sh,results.log}`.

### Reachability from C (why the reproducer is Core, not C)

The natural C shape does NOT reach the defect on any engine:

```c
#include <stdlib.h>
int main(void) { void *q; _Alignas(16) int x = 1; q = malloc(0); free(&x); return 0; }
$ cerberus --nolibc --exec --batch --mode=exhaustive da_bug.c
Undefined {ub: "UB179a_non_matching_allocation_free", stderr: "", loc: "<12:3--12:11>"}
```

because the Ail→Core translation creates a temporary object for every
argument of a call to a `[ailname]` proxy (`frontend/model/translation.lem:
4435`, `pcreate ... PrefFunArg` per parameter), so between the caller's
last object and `malloc_proxy`'s `alloc` there is always the `size_t`
argument temporary — `malloc(0)` lands on the base of its own (killed on
return) temporary, never on a nameable live object. Measured:
`da_offset.c` returns `&x - (uintptr_t)malloc(0)` = `Specified(8)`
(= one 8-byte temporary). The gap is therefore reachable from Core
programs, from tools that generate Core directly, and from any future
zero-argument allocation path; it is not reachable from C through the
standard allocation functions today. (Native glibc rejects the C shape:
`free(&x)` aborts with `munmap_chunk(): invalid pointer`.)

## Observed vs expected

- Observed: `free` of a `create`d object succeeds when a zero-size
  dynamic region was minted at its base; the later scope-exit kill then
  hits an internal `failwith`.
- Expected: `UB179a_non_matching_allocation_free` at the `free`, as in
  the control.

## Impact

A soundness gap in the memory model's UB detection: a program that is UB
under §7.22.3.3p2 is ACCEPTED (and a UB program later crashes the tool
instead of yielding a verdict). Verification consumers building on the
concrete model cannot take "`free` succeeded ⟹ the argument was a
dynamic allocation" from the engine; refined-cerberus (the consumer
that found this by proof, `docs/DECISIONS.md` K0 N-1 / K1) has to
carry the dynamic-ness in its own ghost state and couples only the
direction the engine preserves. Practical exposure from C is nil today
(previous section), which is also why no differential corpus ever hit it.

## Proposed remedy

Track dynamic allocations by IDENTITY, not by address. Allocation ids
(`next_alloc_id`, :1251) are never reused, so the information survives
death, and `is_dynamic` becomes exact:

```
(* mem_state *)  dynamic_ids: storage_instance_id list;   (* was dynamic_addrs: address list *)
(* allocate_region *)  dynamic_ids= alloc_id :: st.dynamic_ids
(* kill, Prov_some arm *)
  is_dynamic alloc_id >>= function                        (* List.mem alloc_id st.dynamic_ids *)
    | false -> fail ~loc (MerrUndefinedFree Free_non_matching)
    | true -> return ()
```

with the existing `is_dead` / base-match checks unchanged after it; the
`Prov_symbolic` arm (:1490-1499) resolves the iota first and then applies
the same id check; `realloc` (:2675) likewise. Two alternatives were
assessed and are NOT recommended as stated:

- *Erase the address in `kill`'s dynamic arm.* Not behaviour-preserving:
  `kill` checks `is_dynamic` BEFORE `is_dead` (:1518 before :1527), so
  after erasure a double `free` reports `UB179a` instead of today's
  `UB179b_dead_allocation_free`, and `realloc` of a freed pointer
  (:2675 before :2679) reports `UB179c` instead of `UB179d` — verdict
  codes that downstream test suites pin. It also cannot distinguish two
  live zero-size regions at one address (erasing one occurrence is
  correct only if duplicates are counted).
- *A per-allocation `is_dynamic` flag on the record.* Correct while the
  allocation is live, but `kill` removes the record from `allocations`
  (:1542), so the dead-allocation arms (`UB179b`/`UB179d`, which today
  read the address list) lose the information; it needs the id list or
  a retained record anyway.

Behaviour of the id-based remedy on every existing program: identical
whenever the freed pointer's address is the base of its own dynamic
allocation (the only way `is_dynamic addr` is true today, absent the
collision), including all dead-allocation verdicts; the two programs
that change are the collision itself (now `UB179a`, the fix) and the
doubly-UB "free of an INTERIOR pointer into an already-freed dynamic
block", which moves from `UB179a` to `UB179b` (both UB; the id check
passes, `is_dead` then fires). `size_n = 0` regions may stay admitted
(C11 §7.22.3p1 leaves `malloc(0)` implementation-defined and the model
returns non-null: `da_malloc0_nonnull.c` → `Specified(1)` on all
engines); with identity tracking their base coincidence is harmless.

## Classification

**TRUE BUG** (memory-model soundness gap; low practical exposure from C
today). The intended semantics is unambiguous from the error's own name
and the ISO text; the address-keyed list is an implementation shortcut
whose two failure modes (never cleaned, zero-size coincidence) the
comment-free code does not acknowledge.

## Provenance

Reported to us by the refined-cerberus verification effort
(`refined-cerberus/docs/2026-09-03_upstream-note-dynamic-addrs.md`,
reasoned from the code while proving a memory well-formedness
invariant; not executed there). Reproduced 2026-09-03 on the un-forked
upstream binary + runtime @ `b9aeedcb4` and on our fork's oracle; our
Lean port (`lean_frontend/CerbMem.lean` `allocateRegion` :1873-1891,
`killM` :1895-1920) mirrors the address-keyed list and reproduces the
accepted free through a libc-body-injection instrument
(`tests/noodle-probes/dynamic-addrs/inj_bug_bexit.c` + `inject_rand.core`
→ `Specified(0)`; control → `UB179a`). Record:
`lean_frontend/docs/2026-09-03_dynamic-addrs-investigation.md`. Bug
localisation, minimisation and this draft by Claude (Fable 5.1) under
operator direction; per the tray's provenance policy the filed issue
carries an AI-provenance note.
