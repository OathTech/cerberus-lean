# Real C fixtures for incoming-origin tightening

These fixtures exercise a structural reachability policy after conservative
incoming-origin annotation. Every program returns zero and needs no C libc.
They are small enough for exact trace comparison under independently recorded
choice tapes. The files test a proposed producer optimization; they do not
establish a reachability or refinement theorem.

The original OCaml frontend/interpreter was run with `--nolibc --pp=core --exec
--json-batch`. All eight fixtures produced `Defined`, `Specified(0)`, empty
stdout/stderr and no diagnostic stderr. The Core printer shows the dead jumps
described below are still present after lowering; they were not discarded by
the C frontend. Counts in the first two columns concern the emitted `main`
procedure, excluding runtime procedures.

| Fixture | Core saves | Core runs | Measured incoming origins removed by structural tightening |
| --- | ---: | ---: | --- |
| `dead_after_goto.c` | 3 | 4 | 2: dead `goto unused` and the return from `unused` |
| `dead_after_return.c` | 2 | 3 | 2: the goto and return after the initial return |
| `jump_into_branch.c` | 3 | 5 | 2: the returns of 47 and 48; retain entry into `inner` |
| `sequence_suffix.c` | 3 | 5 | 2: the returns of 47 and 48; retain the suffix after `entry` |
| `goto_backedge.c` | 3 | 6 | 2: the returns of 47 and 48; retain the self-backedge |
| `loop_break_continue.c` | 6 | 7 | 3: the two dead gotos and the return from `unused` |
| `constant_if.c` | 2 | 3 | 0: the condition is not a literal Core boolean |
| `fallthrough_labels.c` | 3 | 1 | 0: both ordinary labels already have no incoming jumps |

The actual tightened producer and exact differential campaign confirm these
removal counts. The six positive cases also execute a destination whose set
shrunk, established by post-finalization fault injection. A whole-file count
includes runtime procedures and should not be mistaken for the `main` count in
this table; the current runtime contributes zero jump sites.

## What the original lowering exposes

Generated symbol suffixes and value computations are omitted from these
descriptions; the described `save` and `run` nodes are present in printed Core.

* **Dead suffixes:** `dead_after_goto.c` starts with `run done; run unused`, then
  binds `unused` and `done` using `save`. Both labelled bodies end in `run ret`.
  Procedure entry reaches only `done`; following that target reaches only its
  return jump. `dead_after_return.c` similarly starts with `run ret`, followed
  by the unreachable goto and label body. C return is a jump to a saved return
  continuation, so it supplies the same structural cut as C goto.
* **Label entry:** `jump_into_branch.c` emits `run inner(value)` before the
  conditional. `save inner` appears inside one branch, after a return jump.
  The saved continuation must remain reachable despite the enclosing ordinary
  path being dead. Its `run done(value)` must then discover the final return.
* **Sequencing suffixes:** `sequence_suffix.c` jumps over a return to
  `save entry`. The assignment after the labelled statement and `run done`
  are in its surrounding sequence. Analysis of only the saved node's immediate
  body would miss them; use the machine's collected continuation, including
  reconstructed sequencing contexts.
* **Backedges:** `goto_backedge.c` has two distinct `run body` sites: initial
  entry and the loop backedge. Both remain allowed. The worklist must revisit
  newly discovered targets without looping forever or treating the second
  origin as a duplicate of the first.
* **Compiler-generated loop labels:** `loop_break_continue.c` contains saves
  for the while head, two continuation labels, break, the user label and
  return. Its live jumps target continue, break, the while head and return.
  The unreachable gotos remain explicit immediately after continue/break.
* **No C-level constant folding:** `constant_if.c` computes a loaded integer
  comparison, converts it through a case expression to a boolean, then tests
  that boolean symbol. Its effectful `if` does not directly test `Vfalse`.
  A policy that only recognizes literal Core booleans should keep both arms.
* **Ordinary fallthrough:** `fallthrough_labels.c` enters both saves through
  ordinary sequencing. Empty accepted-origin sets must not block this entry;
  only `run` checks membership.

## Reproduce

Select the existing producer and runtime through `CERBERUS_PRODUCER` and
`CERBERUS_RUNTIME`; do not rebuild or change shared executables while a campaign
is running. From the repository root, inspect one original lowering with:

```bash
"$CERBERUS_PRODUCER" --runtime="$CERBERUS_RUNTIME" --nolibc \
  --pp=core --pp_flags=loc --exec --json-batch \
  tests/corenice/comesfrom-tightening/sequence_suffix.c
```

Run the existing four-process, bidirectional comparison for each fixture using
the selected CoreNice policy build:

```bash
for fixture in tests/corenice/comesfrom-tightening/*.c; do
  python3 scripts/corenice-diff.py "$fixture" \
    --producer "$CERBERUS_PRODUCER" --runtime "$CERBERUS_RUNTIME" \
    --seed 17 --summary-json || exit
done
```

The comparison script bounds each child by memory and wall time. Use the normal
local cap wrapper when running the original producer directly. Repeat with
additional choice seeds; matching a resource stop or frontend refusal is not a
successful comparison. Keep raw Core dumps and traces in temporary storage.
