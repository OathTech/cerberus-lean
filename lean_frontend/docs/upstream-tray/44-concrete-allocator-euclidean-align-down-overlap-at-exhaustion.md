# `Concrete.allocator` (and the VIP twin) SUCCEEDS with an overlapping, misaligned object once the address space is exhausted below the request: the align-down step is a truncating-division idiom applied to a Euclidean `quomod`

**Affected:** `memory/concrete/impl_mem.ml:9` (`module Z … let quomod = ediv_rem` — EUCLIDEAN
division, `0 ≤ m < |align|`), `:1247-1262` (`allocator`; the rounding line is `:1253`), `:508`
(`initial_mem_state`: `last_address = Z.of_int 0xFFFFFFFFFFFF; (* TODO: this is a random impl-def
choice *)`). The same idiom, verbatim, in the VIP model: `memory/vip/impl_mem.ml:8` and `:202-211`.
`allocator_with_address` (`:1267`) only checks alignment and does no rounding — unaffected. The
cheri-coq and symbolic models have no such allocator. Checked against `master` @ `b9aeedcb4`: the
cited lines are byte-identical to the merge-base (our fork's only difference in the concrete file is
an unrelated census helper at `:2999-3003`; the VIP file is identical).

## Description

```ocaml
let allocator (sz: Z.t) (align: Z.t) : (storage_instance_id * address) memM =   (* :1247 *)
  get >>= fun st ->
  let alloc_id = st.next_alloc_id in
  begin
    let open Z in
    let z = sub st.last_address sz in
    let (q,m) = quomod z align in
    let z' = sub z (if q < zero then neg m else m) in                            (* :1253 *)
    if z' <= zero then
      fail (MerrOther "Concrete.allocator: failed (out of memory)")
    else
      return z'
  end >>= …
```

`z - (if q < 0 then -m else m)` is the align-down idiom for a TRUNCATING `quomod` (a remainder
carrying the sign of `z`). With the Euclidean `quomod` the remainder is never negative, so the `q < 0`
branch ADDS `m` to a negative `z`:

- normal regime, `z ≥ 0` (the cursor is at or above the request): `q ≥ 0`, `z' = z − m = align·q` —
  the largest multiple of `align` at or below `z`; `z' ≤ 0` is the out-of-memory kill. Correct.
- exhausted regime, `z < 0` (`last_address < sz`): `q ≤ −1` and `z' = z + m = 2z + align·|q|`. For
  `−align/2 < z < 0` this is `2z + align > 0`, so the allocation SUCCEEDS at an address in
  `(0, align)`; the object `[z', z' + sz)` ends at `last_address + z + align > last_address`, i.e. it
  OVERLAPS the most recently allocated live object (whose base is `last_address`), and `z'` is in
  general not `align`-aligned.

## Reproducer

No C program reaches the regime at the default bound: `last_address` starts at `0xFFFFFFFFFFFF`
and only decreases (a kill does not restore it), so the cumulative size of every `create`/`alloc`
in one run would have to exceed about 2^48 bytes. The defect is reproduced by evaluating the
allocator's arithmetic directly, on both engines, 2026-09-16.

The reference's own arithmetic (OCaml 5.4.0, Zarith `ediv_rem`; the body of `:1251-1256` copied
verbatim into a standalone program):

```
ediv_rem (-1) 4 = (-1, 3)
last=3 sz=4 align=4: z=-1 q=-1 m=3 z'=2 -> active, address 2
last=7 sz=8 align=8: z=-1 q=-1 m=7 z'=6 -> active, address 6
last=2 sz=4 align=4: z=-2 q=-1 m=2 z'=0 -> killed (out of memory)
last=8 sz=4 align=4: z=4 q=1 m=0 z'=4 -> active, address 4
```

Our Lean mirror of the same function (`lean_frontend/CerbMem.lean:2093-2107`, Lean 4.32.2; `Int`'s
`/` and `%` are Euclidean, `(-1)/4 = -1`, `(-1)%4 = 3`), evaluated on the ACTUAL `CerbMem.allocator`
by an independent consumer-side probe and on a pure copy of its arithmetic by us — identical:

```
(-1, 3)
(-1, -1, 3, 2, "active, address 2, object [2, 6)")
(-1, -1, 7, 6, "active, address 6, object [6, 14)")
(-2, -1, 2, 0, "killed (out of memory)")
(4, 1, 0, 4, "active, address 4, object [4, 8)")
```

## Observed vs expected

Observed, cursor 3 and a 4-byte object aligned at 4: the allocation SUCCEEDS at address 2; the new
object `[2, 6)` overlaps the live object based at 3, and 2 is not 4-aligned; the cursor moves to 2.
Expected: the out-of-memory kill (`MerrOther "Concrete.allocator: failed (out of memory)"`), as the
`z' ≤ 0` test intends — a fresh object is disjoint from every live object and `align`-aligned, or the
allocation fails.

## Impact

Any run whose cumulative allocation exceeds the address-space bound: at the default bound this is
about 2^48 bytes, so no test program is affected today. The defect matters in two other settings:
(1) any smaller address space — the bound is, in upstream's own words, "a random impl-def choice",
and a model instantiated with a small address space (a tiny target, or a semantics quantified over
the bound) reaches the exhausted regime with ordinary programs and then reports a SUCCESSFUL
allocation that overlaps a live object instead of the kill; (2) any proof about EVERY run of the
model — a `create` rule that hands out a disjoint fresh cell is unsound in exactly this state, so the
defect has to be fixed or assumed away.

## Proposed remedy

Either of the following, in BOTH `memory/concrete/impl_mem.ml` and `memory/vip/impl_mem.ml`:

1. (intent-preserving) Fail when the cursor is below the request BEFORE rounding:
   `if z < zero then fail (MerrOther "… (out of memory)")`; then `z' = z − m` with the Euclidean `m`
   is a plain align-down and the `q < zero` branch is dead and can be deleted.
2. Use the truncating `Z.div_rem` for this `quomod`, which is what the branch was written for (with
   truncation `z < 0` always yields `z' ≤ z < 0` and the kill fires).

## Classification

**TRUE BUG** (model soundness, not an ISO matter): the allocator violates its own invariant — fresh
objects disjoint from live ones and aligned — in a reachable state of the model, and the intended
kill (`z' ≤ 0`) is defeated by a division-convention mismatch between the idiom and the `quomod`
definition four lines into the file. Minor at the default bound (unreachable in practice); real for
small address spaces and for verification over all runs.

## Provenance

Found 2026-09-16 by the AI agent (Claude, Anthropic) executing the cerberus-sl S2 heap slice while
proving that slice's allocation rule, by reading the OCaml reference and evaluating the pinned Lean
mirror (its note: cerberus-sl `docs/2026-09-16_concrete-allocator-division-note.md`); independently
verified the same day by the cerberus-lean orchestrator (Claude, Fable 5.1) on the reference's own
Zarith arithmetic and on the Lean toolchain, and extended to the VIP twin. Drafted by Claude (Fable
5.1) under operator direction; the filed issue carries an AI-provenance note per the tray's policy.
File together with 34 (the same allocator; `align = 0`).

## Fork status (2026-09-16) — fix RULED, scheduled; LANDED (C1, 2026-09-16)

[USER 2026-09-16], verbatim: *"Yes, we should file it, and I think this is in the 'unambiguously
wrong' category where we are allowed to fix ahead of upstream."* The fork will take remedy 1 in both
models and in the Lean mirror (`CerbMem.lean:2093-2107`), with a unit test pinning the four states
above, the fork-drift manifest rows for the two OCaml files, and a `VALIDATION.md` §3 entry as a
fork≠pristine deviation (unobservable at the default bound) — a slice chartered after the
pristine-oracle instrument (WP-O) lands, per the operator's sequencing.

The same message carried the operator's direction on the bound itself, verbatim: *"Btw, I thought
we had moved away from concrete bounds? The semantics should be quantified over such bounds so we
could (in principle) be running on a tiny machine with a tiny amount of memory to allocate, and the
reasoning has to quantify over the bound."* [AGENT] the address-space bound is today a literal in
both engines (`impl_mem.ml:508`; `CerbMem.lean:153` `lastAddress : Address := 0xFFFFFFFFFFFF`),
sheltered until now by the mirror exemption of the no-magic-values rule; with the bound a quantified
parameter (matched mode instantiating it to upstream's value) the exhausted regime is reachable by
ordinary programs, which is why the fix above precedes the parameter.

**LANDED — C1 of `arc/allocator-soundness-address-bound` (2026-09-16; commit hash in the record
`lean_frontend/docs/2026-09-16_allocator-soundness-address-bound-record.md` §C1, which also carries the OCaml diff
= the patch hunk for upstream).** Remedy 1 in `memory/concrete/impl_mem.ml:1252-1263` and
`memory/vip/impl_mem.ml:207-218` (`if z < zero then fail (MerrOther "Concrete.allocator: failed (out of memory)")`
before the rounding; `let (_, m) = quomod z align in let z' = sub z m`; the `q < zero` branch deleted; a two-line
fork comment at each site); the Lean mirror `lean_frontend/CerbMem.lean` `allocator` (line by line, with the new
cites); the GENERAL kernel theorem `CerbMem.allocator_active_sound` + `allocator_below_request_kills`
(`lean_frontend/CerbMemAllocatorProofs.lean`; axioms `propext`/`Classical.choice`/`Quot.sound`); the runtime
witness `lean_frontend/test/Unit/AllocatorSoundnessTest.lean` (`allocator-soundness-test`: the four states above,
post-fix killed / killed / killed / active at 4, the pre-fix values quoted as the negative control); fork-drift
content pins for both files (`scripts/fork_drift_manifest.txt`, header note "allocator-soundness C1");
`lean_frontend/VALIDATION.md` §3 "Fork ≠ pristine" entry — UNOBSERVABLE at upstream's bound, NO register row.
