# Breakpoint execution fixtures

Run the focused suite after building `core-diff`, `corenice-diff` and
`corenice-resume`:

```bash
python3 scripts/corenice-breakpoints.py
```

`--root PATH` selects a different provisioned owned checkout's comparator and
binaries. Explicit producer/runtime/binary and resource-limit options are also
available. `--case NAME` runs a named subset and reports only that subset.

Each source/choice-policy run first compares original Core against ordinary
automatic Nice under exact observations, then against resumable Nice with all,
none, every-second and one actually reached site's pauses. Each comparison uses
four fresh processes and records/replays choices in both directions. The suite
checks actual pause descriptors against the all-policy encounters, including
source provenance, driver-step progress and cumulative budget. A selected-site
run is inapplicable when execution reaches no site. Coverage counts refer to
the independently recorded Nice lane, not inferred annotation inventory.

| New fixture | Required behavior |
| --- | --- |
| `two_cuts.c` | Return 3 through exactly two joins; enumerate all four host-pause subsets. |
| `composition.c` | Return 6; statement, condition and repeated loop-body joins. The in-memory midpoint demonstration is a separate test. |
| `do_loop.c` | Return 0; repeated body-to-condition joins and pointer updates. |
| `abrupt_return.c` | Return 7 without reaching a join after the early return. |
| `goto_skip.c` | Return 0 without reaching joins skipped by the jump. |
| `sibling_calls.c` | Return 0, update distinct pointed-to objects, and emit both `LR` and `RL` under genuine choices. Prefix `0` and prefix `1,1,1` witness the orders; argument-evaluation choices precede the call-order choice. |
| `ub_before_cut.c` | Division UB before the first marked statement completes; zero pauses. |
| `ub_after_cut.c` | Complete the first store, reach its join, then report division UB. |

The suite also reuses existing saved-label suffix/branch entry, break/continue,
recursive-goto, output-before-UB and minimal factorial/for/goto inputs. Assertions
about loop roles concern normalized AIL boundaries; a C `continue` may become a
jump to an introduced label before normal AIL-body completion.

The reused `tests/z2-probes/nd/order3.c` fixture additionally enumerates all six
complete genuine-choice tapes and all 16 subsets of its four cuts. Its six
distinct return values check that the supplied prefixes really reach all call
orders; each full recorded tape must have exactly the expected arities 3 then 2.
This is a finite exhaustive cross-product for that fixture, not a claim that
larger input families exhaust their nondeterminism or pause schedules.

Unexpected modeled errors, unexpected `NiceFault`, timeouts, observer failures
and budget exhaustion fail the suite. This is bounded execution evidence, not
full C coverage or a simulation theorem. Mutation controls, full campaigns and
midpoint state assertions run separately.
