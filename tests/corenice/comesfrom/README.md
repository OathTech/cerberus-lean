# Incoming-jump fixtures

Run `python3 scripts/corenice-incoming-tests.py` after building the
`corenice-incoming-tests`, `core-diff` and `corenice-diff` executables and the
normal native Cabs producer/runtime. The script accepts `--unit-bin PATH` and
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
removed permission, a fresh disallowed origin, resolved procedure aliases,
ordinary `Esave` entry, an untaken disallowed edge, arity-error precedence and
the check occurring before argument handling. A permitted argument-UB control
demonstrates that the optimized negative argument test would otherwise fail.
Unknown-label controls run in separate processes and require the existing
unresolved-label panic, rather than accepting any failing process.

These focused synthetic tests cover both jump implementations. The normal
driver uses the optimized implementation. Its observation stream does not
count every internal jump; this script therefore does not infer executed-check
counts from source constructs or emitted annotations. Post-finalization
metadata corruption on generated programs and runtime-procedure inventory are
separate integration checks. No equivalence or producer-correctness theorem is
claimed by this suite.
