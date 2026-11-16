# Incoming-jump fixtures

Run `python3 scripts/corenice-incoming-tests.py` after building the
`corenice-incoming-tests`, `corenice-incoming-control`, `core-diff` and
`corenice-diff` executables and the normal native Cabs producer/runtime.
The script accepts `--unit-bin PATH`, `--control-bin PATH` and
forwards ordinary comparator path/resource flags. It requires exact trace
comparison in both recording directions.

Every C fixture has defined behavior and returns zero on its expected result:

| Fixture | Intended source coverage |
| --- | --- |
| `goto_forward_backward.c` | forward/backward jumps and repeated static sites |
| `loops_break_continue.c` | for, while, do, break and continue |
| `switch_fallthrough.c` | case dispatch, fallthrough, default and break |
| `label_normal_entry.c` | normal label entry followed by jumped entries |
| `recursive_goto.c` | recursive calls using the same static jump identities |
| `untaken_edge.c` | syntactically present but unreachable incoming edge |
| `runtime_arithmetic.c` | parsed runtime/implementation arithmetic procedures |
| `choice_order.c` | two genuine function-evaluation orders with checked jumps |

The Lean test executable additionally invokes the real `core_thread_step2` and
`step_ctx` rules, executes their returned state/exception closures and checks
the typed fault fields against the actual synthetic annotated AST. It covers
removed permission, a fresh disallowed origin, resolved procedure aliases and
label queries with the same semantic identity but different descriptions,
ordinary `Esave` entry, an untaken disallowed edge, arity-error precedence and
the check occurring before argument handling. A permitted argument-UB control
demonstrates that the optimized negative argument test would otherwise fail.
Unknown-label controls run in separate processes and require the existing
unresolved-label panic, rather than accepting any failing process.

These focused synthetic tests cover both jump implementations. The normal
driver uses the optimized implementation. The generated-program control clears
all label permissions after finalization to identify the first actual taken
jump, checks its typed payload against the original artifact, then replays the
consumed choice-tape prefix with two precise corruptions: removing only that
permission and changing only that jump's origin to a fresh identity. All three
must fault with matching pre-fault observations, which must be prefixes of the
uncorrupted defined execution. The script counts first-site witnesses, not
every dynamic jump or coverage of every annotated site. Runtime procedures are
inventoried separately; a no-jump arithmetic fixture is reported explicitly.
No equivalence or producer-correctness theorem is claimed by this suite.

For the structural tightening policy, run
`python3 scripts/corenice-incoming-tightening.py` after rebuilding the same
executables with that policy. The default campaign creates 80 candidates from
the eight fixtures in `tests/corenice/comesfrom-tightening` and 72 temporary
bounded variants. Deduplication by source text keeps the first occurrence,
including authored fixtures, and executes 73 unique inputs while reporting the
seven skipped duplicates. Variants change dead-edge multiplicity, sequencing
depth, loop bounds and values; they are not a general C fuzzer. A ninth family uses independent
function calls to exercise both actual evaluation orders. The alternate tape
flips a recorded genuine choice, and the report counts distinct observed tapes.

Every positive case must remove origins and execute a destination whose set
actually shrank. The control executable's `tightened` selection clears only
such destinations, then validates the same precise typed-fault controls.
`constant_if` and ordinary-label-fallthrough controls require zero removals.
JSON summaries count syntactic/permitted/removed origins, affected labels,
maximum permitted set size, empty incoming sets, and executed tightened-target
witnesses. Generated programs and traces are deleted after the run.
