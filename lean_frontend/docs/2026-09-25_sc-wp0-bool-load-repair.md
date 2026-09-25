# Trapping `_Bool` loads retain the completed read state

[AGENT] This is the independent sequential repair requested by the agent's
SC plan re-review RR2; RR2 is review advice, not a user ruling.
Base: `e9f9d049ffaaf005c392495b0f6418d21f4df29f` on `mdd/cerberus-lean`.
The governing master plan is `SC-CONCURRENCY.md` on `arc/sc-concurrency`,
commit `533fab987`. No donor runtime code was copied for this repair.

[USER] The approved direction is a coherent, correct SC semantics MVP without
Iris integration, with useful foundation pieces independently validated and
landed; the user then directed "proceed with WP0". The master plan and
`lean_frontend/docs/2026-09-25_sc-semantics-mvp-scope.md` at `533fab987`
record that scope. [AGENT] Keeping this sequential correction separate from
the passive-observer slice implements that direction; the user did not
prescribe this particular repair or its fixtures.

OCaml's actual `Concrete.load` fetches/reconstructs the bytes, updates
`last_used`, and then rejects a trapping `_Bool` representation. Lean used
the outer failure helper, which returned the pre-read state. It now returns
the updated `lastUsed` on precisely this failure path. Successful loads and
pointer-validation failures are unchanged. [AGENT] This is a sequential correction,
not part of the later observer-erasure baseline.

[AGENT] The Lean regression calls `loadM` on allocation 7 at address 100, size 1,
with incoming `lastUsed = some 99`. Byte 2 and an unspecified byte both
return the original trap reason with `lastUsed = some 7`; bytes 0 and 1
succeed; a null pointer fails without updating `lastUsed`.

The native probe calls the public production primitives, allocating its
objects through `allocate_object` (the native state representation is
abstract). Its equivalent witness uses allocations 0/1 at 65535/65534,
touches allocation 1, then reads allocation 0. It asserts the exact trap
constructor, value on successful reads, and `last_used` from the existing
state serializer. These are equivalent primitive conditions, not identical
whole-memory fixtures. The subsequent paired observation diagnostic uses
identical allocation/setup sequences on both engines.

Before repair, both Lean trap-state checks fail at caller-selected fuel 2
and 17, while the other checks pass. Native passes all five controls. After
repair, all Lean checks pass. Raw transcripts and source/artifact hashes are
in [sc-wp0-evidence](sc-wp0-evidence/bool-repair-evidence.json).

Reproduce with the workspace environment wrapper:

```
dune build --root . backend/memory_probe/memory_probe.exe
_build/default/backend/memory_probe/memory_probe.exe
scripts/test_unit.sh monadic-failstop-test
```

Validation: `python3 scripts/release.py --mode fast` passed all 16 selected
commands, source unchanged, at `.tmp/release/20260925T025751.740473Z`.
Full slice-boundary certification and independent audit remain required
before a mainline landing. No merge or push is included in this change.
