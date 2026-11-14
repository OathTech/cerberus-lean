# CoreB source mutation controls

`scripts/coreb-mutations.py` builds actual variants of the B lowering,
evaluator, driver and observer. It uses the ordinary `coreb-diff.py`
comparison, then checks that each failure reached its intended observation.
A failed build, timeout, unprovisioned dependency or unexpected model error is
a failed campaign, never a detected semantic mutation. Every nonpanic variant
must be detected by exact comparison in both record/replay directions using
fresh tapes. The four semantic/observer mutations must remain mismatches under
`--comparison stutter`. The actual singleton-step insertion is instead required
to pass the stutter comparator in both directions. The panic variant must remain
incomplete in both profiles; it cannot finish recording, so its reverse direction
is explicitly inapplicable.

Run it from a provisioned, committed candidate with the same pinned Lem and
opam environment used for the normal build. For an ordinary local switch:

```bash
opam exec --switch=. -- python3 scripts/coreb-mutations.py
```

The script inherits the caller's opam environment. When the warm LemLib
checkout contains an already-built `bin/lem`, its private copied compiler and
library take precedence over the switch's `PATH`/`LEMLIB`; otherwise the supplied
pinned compiler environment is retained. It does not install dependencies or
alter a switch. `--source-checkout PATH` selects
a different clean, provisioned candidate; `--runtime PREFIX` and `--producer
PATH` select its existing runtime and Cabs producer. `--mutant NAME` can be
repeated to select a subset. `--build-memory 12G` and `--build-timeout 600`
bound each build; the differential runner separately bounds child time,
memory and output, including the extra Cabs producer and paired-artifact check.
Successful build/generation stderr and warning-bearing stdout are surfaced
with explicit truncation notices if needed. Budget concurrent jobs before
starting a campaign.

| Variant | Actual changed source | Witness and required detection |
|---|---|---|
| `translation` | Owned `translation.lem`: the ordinary integer constant branch maps only 42 to 43. | `return 42` produces two defined, different results. The complete paired artifact comparison must also reject the change. |
| `arithmetic` | Owned `core_eval.lem`: `IOpAdd` invokes `IntSub`. | Loaded locals compute `z = x + y`, followed by `return 0`. Both executions must remain defined with equal terminal outcomes and differing real store events. |
| `choice-order` | Owned `driver.lem`: reverse the steps passed to the real `new_drive_core_threads` choice. | Existing `order3.c` must reach duplicate alternative descriptors and produce different defined results under branch-zero recording/replay. |
| `observer` | B observer: omit the actual accumulated driver trace delta. | An access fixture must retain the same defined terminal outcome while losing driver events. |
| `singleton` | B entrypoint: wrap the real action in an actual `NDstep` with one continuation. No Nice AST feature is claimed. | `order3.c` must retain exactly the same defined outcome, driver effects and branch choices with one extra visited ND node. Exact comparison rejects it; stutter comparison passes both directions. |
| `panic` | B entrypoint: invoke a native panic immediately before completion emission. | The comparator must report incomplete execution; a separate bounded native recording must abort with SIGABRT, retain the injected panic marker and omit completion. This checks the full bounded stderr independently of the comparator's diagnostic tail. A generic process failure does not satisfy the control. |

Before each variant, its unmutated witness must pass the normal four-run
comparison as defined. Each variant uses a separate disposable detached Git
worktree at the candidate revision. The script copies its warm `.lake`,
generated sources and native object; it creates no cache symlinks or hardlinks.
The B-only patch is committed inside that disposable checkout before building.
Lem-source variants run the existing B generator without its unchanged-baseline
check, then build the B executable. The original Core binary, normal B binary,
runtime and Cabs producer are read-only inputs. Their normal executable hashes
are checked again at exit. Named disposable worktrees and copied caches are
removed on success or failure. The script does not push or change normal
branches.

Reports contain the candidate revision and the observed detection class; raw
traces and copied caches are ephemeral. The fast controls for patch admission,
status classification, witness conditions and independent cache copies run with:

```bash
python3 -m unittest discover -s tests/coreb -p test_mutations.py
```

Source identity and successful negative controls establish instrument
sensitivity on these witnesses. They do not prove semantic equivalence or
completeness of the observation projection. In particular, the paired artifact
comparison retains its documented producer-provenance assumption for map
comparator closures.
