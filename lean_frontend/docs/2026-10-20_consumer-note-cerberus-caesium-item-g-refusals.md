# Consumer note for cerberus-caesium: the item-G refusals (2026-10-20)

From: the `fix/item-g-refusals` worker [AGENT]. Occasion: your note 2's items G1 and G2
(2026-10-17; our response note `docs/2026-10-17_consumer-note-cerberus-caesium-response-note-2.md`
left them open; upstream-tray drafts 56 and 57 report them). [USER 2026-10-20] ruled that where
upstream Cerberus left a case deliberately to a TODO, the fork either leaves it as-is or REFUSES
LOUDLY — the run dies with a declared unsupported outcome — and never invents a verdict (no UB
verdict, no error verdict) in its place, nor answers silently wrong. Both cases are now refusals, in
BOTH engines, with byte-identical texts. Contract entry D10; witnesses
`scripts/check_item_g_refusals.sh` (ladder row 1); record `docs/2026-10-20_item-g-refusals-record.md`.

Status: on branch `fix/item-g-refusals`, Tier A green. Two gated lane rows were literally these
cases (`tests/coverage/mem4/mem4-020-memcpy-overlap.c`, `tests/libc_exec/009-aligned-alloc-3.c`),
deliberate controls of the superseded stance; [USER 2026-10-20] ruled them retired, the witness
script carrying their purpose. The behaviour below is what the next re-pin that includes the
branch carries.

## G1 — `memcpy` on overlapping objects

Where upstream's `memory/concrete/impl_mem.ml` `memcpy` carries `(* TODO: if ptrval1 and ptrval2
overlap ==> UB *)` (b9aeedcb4 :2636) and copies byte-wise (so both engines answered `Specified(7)`
on draft 56's witness), the memory model's copy now REFUSES before any byte moves, when the byte
ranges `[a1, a1+n)` and `[a2, a2+n)` intersect with `n > 0` and either (a) both pointers are
concrete in the SAME allocation (`Prov_some`; region text `allocation ID`) or (b) both are
device-memory pointers (`Prov_device`, which an integer cast into the model's fixed
`device_ranges` `[0x40000000, 0x40000004)` / `[0xABC, 0xAC0)` yields; region text `device
memory` — the pre-merge audit found both engines answering `Specified(5)`/`Specified(111)` on
`(char*)0xABC` / `(char*)0x40000000` overlaps before this arm). The remaining pointer shapes
cannot complete a copy: a `Prov_none` concrete pointer fails at the first byte
(`UB_CERB002a_out_of_bound_load`), a `Prov_symbolic` argument dies in the pure
`array_shift_ptrval` (R-PNVI-06, draft 53), `PVnull`/`PVfunction` fail in `load` — with ONE named
residual that both engines still serve: an allocation/device pair, reachable only when an
allocation lies inside a device range, i.e. under the fork-only `--address-space-top` (outside
CONTRACT §2's promise; `memcpy(a + 4, (char*)0xABC, 2)` with `a` at 0xAB8 under top 2756 answers
`Specified(56)` on both). It is not refused because `memcpy` never consults the allocation's
bounds, so an allocation inside device memory cannot be told from an out-of-bounds run into it
(the same reason case (a) requires the same allocation: a source range running out of one object
into its neighbour is the loop's out-of-bound UB, not an overlap). `memcpy(p, p, n)` is included;
`n = 0` never overlaps; `realloc`'s own copy is new ← old, two allocations, unaffected. The ranges
are the C-level objects, not clipped to the allocation, and the refusal fires at application,
BEFORE ANY ACCESS CHECK: a copy that is also out of bounds, or whose object is dead (`free`d), is
refused rather than reported as that UB — a use-after-free verdict is not reported on an
overlapping copy.

The text (one string on both engines; the region, the two bases, the two ends and `n` are
identical on both engines because the allocators mirror each other):

```text
Concrete.memcpy: refused - memcpy on overlapping objects (allocation 1: destination [281474976710640, 281474976710644) and source [281474976710641, 281474976710645), n = 4); C17 7.24.2.1#2 undefined behaviour; upstream copies byte-wise under impl_mem.ml memcpy 'TODO: if ptrval1 and ptrval2 overlap ==> UB' (b9aeedcb4 :2636) - the fork refuses rather than decides (item G1, 2026-10-20)
```

On the wire: the oracle dies on the uncaught exception —
`cerberus: internal error, uncaught exception:` / `Failure("<text>")` + an OCaml backtrace, exit
125; the Lean engine aborts under `LEAN_ABORT_ON_PANIC=1` with
`PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: <text>` on stderr, exit 134 (`--batch`
prints nothing else). Lean site: `CerbMem.memcpyOverlap` / `CerbMem.memcpyOverlapRefusal` /
`CerbMem.memcpyM` (`lean_frontend/CerbMem.lean`); oracle site: `impl_mem.ml` `memcpy`.

**Your harness's own overlap refusal becomes redundant at the next re-pin** under the default
address-space top: every overlapping copy the engines can complete there is refused by the
engines themselves, with the text above, before the copy (cases (a) and (b); the other shapes
fail or die before any byte moves). The one copy the engines still serve is the named residual
above, under a non-default `--address-space-top` only. If the hook keeps running it will simply
never be reached by an overlapping copy that the engine would have served. Non-overlapping copies
are unchanged (see the witness script's controls: adjacent halves, two objects, length 0,
realloc, out-of-bounds UB, device memory).

## G2 — an allocation with an invalid alignment

Where upstream's `runtime/libcore/std.core:385` `aligned_alloc_proxy` checks only
`size rem_t align = 0` and the allocator's `quomod` (b9aeedcb4 :1253) rounds the cursor down to a
multiple of ANY alignment (so `aligned_alloc(3, 9)` allocated at "alignment 3"), the ALLOCATOR of
both memory models now refuses an alignment that is not a positive power of two. The check sits in
the allocator (`impl_mem.ml` `allocator`, Lean `CerbMem.allocator`), not in the shared `std.core`
(Core text can only express verdict-shaped errors), after the allocator's out-of-memory kill and
before the remainder — so an invalid alignment with a size above the cursor still kills
out-of-memory first, as before. It does not fire for any alignment the runtime or the lanes use:
measured over every exec-type lane, the alignments reaching the allocator are 1, 2, 4, 8 and 16
(plus 3 on the one row that is draft 57's case). `_Alignas(3)` never reaches the allocator (a
front-end constraint violation, §6.7.5#3). Neither a null return (C17) nor a UB verdict (C11) is
invented.

Alignment ZERO is out of scope and UNCHANGED: `aligned_alloc(0, n)` still dies on the pre-existing
`Division_by_zero` at `std.core:385`'s `rem_t` (draft 34; Lean: `CerbMem.integerRem_t:
Division_by_zero (…)`), before the allocator.

The text:

```text
Concrete.allocator: refused - allocation with an invalid alignment 3 (not a positive power of two; size 9); C17 7.22.3.1#2-3 requires aligned_alloc to fail by returning a null pointer (C11: undefined behaviour); upstream allocates under runtime/libcore/std.core:385 aligned_alloc_proxy, whose only check is 'size rem_t align = 0', and impl_mem.ml allocator's quomod (b9aeedcb4 :1253) - the fork refuses rather than decides (item G2, 2026-10-20)
```

Same wire shape as G1 (oracle `Failure`, exit 125; Lean abort, exit 134).

## If you unfold `CerbMem.allocator` in proofs (cerberus-sl: this breaks a theorem)

`CerbMem.allocator` gains one arm, between the `align == 0` arm and the remainder:
`else if alignmentRefused align then (NDkilled (CerbFail.failStopKill (failwithI …)), st)`. The
arm is a KILL in the kernel (its `failwithI` is the kill's message, a `String`), so
`CerbMem.allocator_active_sound` keeps its hypothesis-free statement and `allocator_below_request_kills`
is unchanged.

**A general statement over `allocator` becomes FALSE at the re-pin.** cerberus-sl's
`CerberusIris/HeapModelAlloc.lean:59`

```lean
theorem allocator_cases (sz align : Int) (st : MemState) (hne : align ≠ 0) :
    (∃ id a st', ndRun (CerbMem.allocator sz align) st = (.NDactive (id, a), st')) ∨
    ndRun (CerbMem.allocator sz align) st = (.NDkilled oomKill, st)
```

no longer holds: for a refused alignment (e.g. `align = 3`, `sz` small) the result is the new kill
`(.NDkilled (CerbFail.failStopKill (failwithI …)), st)`, neither disjunct. It needs either the
hypothesis `CerbMem.alignmentRefused align = false` or a third disjunct for that kill; the
`allocatorSound`/`allocator_cases` chain its header describes and `Adequacy.lean:336` depend on
it (the pre-merge audit's P3-1 finding).

The literal-alignment unfoldings are merely harder: `Adequacy.lean:339` (`errno_room_iff`) and
`HeapModelAlloc.lean:45` (`allocator_active_shape`), both `simp only [ndRun, CerbMem.allocator]
at h` + `split`, meet the new `if` and gain an arm; `CerbMem.alignmentRefused 4` reduces to
`false` by `decide`, by `rfl`, or inside `simp` with `CerbMem.alignmentRefused` in the simp set
(our own `test/Unit/FuelExemplar.lean` `allocator_errno` needed exactly
`simp [h1, CerbMem.alignmentRefused]` in place of `simp [h1]`).
The predicate is `align != 0 && !(align > 0 && (align.toNat &&& (align.toNat - 1)) == 0)` (the
oracle's `Z.logand align (Z.pred align) = 0` on `align > 0`; this toolchain has no `Int.land`).

## Later

The outcome-protocol design pass (response note, "the common thread") will move both texts into
its envelope; the texts above are the pre-envelope form, matched as substrings by the witness
script's `*_HEAD`/`*_TAIL` constants.


Update [AGENT 2026-10-26] (quotation hygiene Q3, `docs/2026-10-26_quotation-hygiene-record.md`):
the migration below has happened. The Lean engine's two refusals are now outcome-protocol
REFUSAL envelopes on the panic channel (exit 134 unchanged): boundary `memory`, item
`Concrete.memcpy` / `Concrete.allocator`, `detail` = `Refused: ` + the exact text quoted
above, `mover` upstream's decision on the TODO, `upstream` the TODO citation
(`impl_mem.ml:2636` / `:1253` at `b9aeedcb4`), `see` `CONTRACT.md D10; docs/2026-10-20_item-g-refusals-record.md`.
`decode_stop` returns them as `Refusal` objects; match on `boundary == 'memory'` and the
item, never on the text. The oracle's `Failure` texts and exit 125 are unchanged, as are the
kernel faces of both leaves (your `allocator_cases` note below still applies unchanged).
The design-v2 amendment is §10 of `docs/2026-10-20_outcome-protocol-design-v2.md`
(proposed by the worker; ratified at landing).

Integration clarification [AGENT 2026-10-21] (superseded by the update above): the outcome-protocol first delivery
keeps these incoming texts envelope-less. Its generic decoder reports their
validated panic frames as legacy, origin unattributed; the refusal semantics
remain as documented above. The
[protocol migration map](2026-10-20_outcome-protocol-register-migration.tsv)
names the follow-up under structural-outcome WP2. Earlier expectations of
immediate envelope migration in this note are superseded by that explicit gap.
