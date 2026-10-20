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
on draft 56's witness), the memory model's copy now REFUSES before any byte moves, when both
pointers are concrete in the SAME allocation and the byte ranges `[a1, a1+n)` and `[a2, a2+n)`
intersect with `n > 0` (`memcpy(p, p, n)` included; `n = 0` never overlaps; different allocations
never overlap; `realloc`'s own copy is new ← old, two allocations, unaffected). The ranges are the
C-level objects, not clipped to the allocation: a copy that is both overlapping and out of bounds
is refused rather than reported as the loop's out-of-bound UB.

The text (one string on both engines; the numbers are the allocation id, the two bases, the two
ends and `n`, identical on both engines because the allocators mirror each other):

```text
Concrete.memcpy: refused - memcpy on overlapping objects (allocation 1: destination [281474976710640, 281474976710644) and source [281474976710641, 281474976710645), n = 4); C17 7.24.2.1#2 undefined behaviour; upstream copies byte-wise under impl_mem.ml memcpy 'TODO: if ptrval1 and ptrval2 overlap ==> UB' (b9aeedcb4 :2636) - the fork refuses rather than decides (item G1, 2026-10-20)
```

On the wire: the oracle dies on the uncaught exception —
`cerberus: internal error, uncaught exception:` / `Failure("<text>")` + an OCaml backtrace, exit
125; the Lean engine aborts under `LEAN_ABORT_ON_PANIC=1` with
`PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: <text>` on stderr, exit 134 (`--batch`
prints nothing else). Lean site: `CerbMem.memcpyOverlap` / `CerbMem.memcpyOverlapRefusal` /
`CerbMem.memcpyM` (`lean_frontend/CerbMem.lean`); oracle site: `impl_mem.ml` `memcpy`.

**Your harness's own overlap refusal becomes redundant at the next re-pin**: the engines refuse
the overlap themselves, with the text above, before the copy. If the hook keeps running it will
simply never be reached by an overlapping copy that the engine would have served. Non-overlapping
copies are unchanged (see the witness script's controls: adjacent halves, two objects, length 0,
realloc, out-of-bounds UB).

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

## If you unfold `CerbMem.allocator` in proofs

`CerbMem.allocator` gains one arm, between the `align == 0` arm and the remainder:
`else if alignmentRefused align then (NDkilled (CerbFail.failStopKill (failwithI …)), st)`. The
arm is a KILL in the kernel (its `failwithI` is the kill's message, a `String`), so
`CerbMem.allocator_active_sound` keeps its hypothesis-free statement and `allocator_below_request_kills`
is unchanged. A proof that unfolds `allocator` on a literal alignment (your `Adequacy.lean`
`ndRun (CerbMem.allocator 4 4) …` and `… (allocator (sizeof signed_int) 4) …` lemmas) meets the
new `if`; `CerbMem.alignmentRefused 4` reduces to `false` by `decide`, by `rfl`, or inside `simp`
with `CerbMem.alignmentRefused` in the simp set (our own `test/Unit/FuelExemplar.lean`
`allocator_errno` needed exactly `simp [h1, CerbMem.alignmentRefused]` in place of `simp [h1]`).
The predicate is `align != 0 && !(align > 0 && (align.toNat &&& (align.toNat - 1)) == 0)` (the
oracle's `Z.logand align (Z.pred align) = 0` on `align > 0`; this toolchain has no `Int.land`).

## Later

The outcome-protocol design pass (response note, "the common thread") will move both texts into
its envelope; the texts above are the pre-envelope form, matched as substrings by the witness
script's `*_HEAD`/`*_TAIL` constants.
