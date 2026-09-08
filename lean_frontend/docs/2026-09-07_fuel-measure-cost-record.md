# Fuel measure execution cost — 2026-09-07

[AGENT] Work under the [fenced charter](2026-09-07_codex-charter-fuel-measure-cost.md),
on `arc/fuel-measure-cost` at starting HEAD
`cee6b4639508c543524900bcd763ae04565f1916`. This HEAD adds only the charter
to the target `4d1088004`. No earlier deliverable or active charter job
was present when this work began. D1–D3 are complete. D3's code is `6ce040f06`; its dedicated instrument
and authorized baseline commit is `5f14f0702`. D4 is complete as a report
of remaining exceptions in `cacc42bbb`, with Tier A green. **Execution
stopped at D5's missing independent-oracle prerequisite under the charter
stop rule.** The full CPU bar and D5 full-battery certification are not claimed. Measurements span
2026-09-07 and 2026-09-08.

## Property and boundaries

The charter's property, verbatim:

> The Lean semantics at HEAD must cost no more than 10 % more CPU per program than it did before the fuel-parameter arc, and every csmith corpus row that completed under the lane's 15-second budget before the arc must complete under it again — with every sufficiency theorem still kernel-checked and zero baseline movement.

[AGENT] Commands source `/home/dev/projects/cerberus-lean-proj/scripts/env.sh`.
Lean/Lake and the timing lane run under `scripts/capped` with
`CERB_MEM_MAX=48G`. The cap preflight printed
`cap smoke: memory.max=51539607552`, exit 0. Our builds and lanes are
serialized. The initial box load was:

```text
19:54:07 up 1 day,  4:29,  ? user,  load average: 18.63, 28.03, 18.68
```

This is context, not the timing table's load: each timing export's metadata
records its own start/end `uptime`. Verdict-deciding ratios must be repeated.
The initial login shell's logout-file read hit a nono OS sandbox boundary
(`/home/dev/.bash_logout`); subsequent shells are nonlogin. The cap and
build succeeded; no sandbox grants or global settings were changed.

## D1 — instrument and HEAD measurement (complete)

`scripts/measure_csmith_cpu.py` executes the existing
`scripts/test_csmith_corpus.sh --check-baseline` with `SKIP_BUILD=1`.
It reuses the lane's staging, prefixes, header substitution, oracle flags,
cabs-json bridge, Lean invocation, and classification. A shell-local `rm`
function copies only the lane's `.time` records and `status.txt` at cleanup,
then performs the original removal. No existing harness source is edited.
This retention hook is restricted to the target checkout's `exec-test.*`
scratch directories; it is not active outside this instrument's subprocesses.

Each input exports an oracle row and a Lean row. Both carry the lane's
joint status; an unexecuted Lean side carries `NA` exit/resources. CPU is
GNU time user+system seconds (0.01 s precision), including the waited-for
timeout/engine descendants. An exit-124 measurement is censored, not a
completed-program CPU cost. The collector checks every saved status against
the corresponding printed lane row, checks consecutive indices and complete
summaries, and rejects missing/extra timing records. Export success is not a
baseline success: the actual baseline verdict and lane exit are retained.

The primed binaries lacked freshness stamps. The normal `build_cerberus`
and `build_lean` helpers built and stamped both successfully, with a 55-minute
outer tripwire (not reached). [Build output](2026-09-07_fuel-measure-cost-evidence/head-build.txt)
records Lean `Build completed successfully (273 jobs).` and these binary hashes:

| Engine | SHA-256 after build |
|---|---|
| Oracle | `a7ceeb66f4297d5210f3f417fa82b5dc238a303a10f134d494acc737e2f186c6` |
| Lean | `32f8b3427f023ad78afc27fd170284cf09c2b331751652ef588d8d0061a62ad6` |

The instrument's first selftest caught its own incorrect assumptions about
zero-padded input names and the colon after MATCH filenames. Both were fixed
inside the new script. The successful selftest exercised known exact rusage,
a real 0.20-CPU-second stub, an oracle refusal, a CPU-bound timeout, and
missing/malformed time-record refusals. [Verbatim output](2026-09-07_fuel-measure-cost-evidence/instrument-selftest.txt):

```text
CPU instrument SELFTEST OK: exact rusage, real CPU stub, MATCH/CERB_SKIP/TIMEOUT, missing/malformed records refused
```

Tier A ran through `python3 scripts/release.py --mode fast` with
`DUNE_CACHE=disabled` and the 48 GiB cap, before the corpus timing run.
[Runner output](2026-09-07_fuel-measure-cost-evidence/d1-fast.txt) and
[direct lane verdict lines](2026-09-07_fuel-measure-cost-evidence/d1-fast-verdicts.txt)
are retained. Verbatim:

```text
fast: passed; 13/13 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

The included direct `./scripts/test_unit.sh` run passed before any semantic
source edit; it is the charter's required pre-D3 snapshot. This is Tier A
evidence only, not D5's full battery.

The final reporting-table placement adds the instrument as `C5`, preserving
the existing `C4` CI sweep ID. The initial placement before that row would
have shifted its ID; this documentation-only correction followed the fast
pass. A [catalogue comparison](2026-09-07_fuel-measure-cost-evidence/d1-ladder-membership.txt)
using the release runner's own parser verifies that every existing ID,
command and tier is unchanged from HEAD, including the complete Tier A and
Tier B command sets. No timed command or semantic source changed.

The completed whole-corpus command was:

```sh
python3 scripts/measure_csmith_cpu.py --output lean_frontend/docs/2026-09-07_fuel-measure-cost-evidence/head-before-15.tsv
```

Its timeout is 15 s per engine. The raw run directory is
`.tmp/fuel-measure-cost/cpu-fp9njwkc`. The original process finished at
`2026-09-07T22:36:57Z`, export exit 0, after starting at `20:15:07Z`.
The whole-corpus measurement is the charter's pre-justified long differential
pass. [The complete TSV](2026-09-07_fuel-measure-cost-evidence/head-before-15.tsv)
has 1,669 inputs and 3,338 engine rows. Its
[metadata](2026-09-07_fuel-measure-cost-evidence/head-before-15.meta.txt)
records unchanged identities across the timing run, including the measured
oracle SHA-256 `7b8ddb10ecddfa6c9d61eac5632ffa7cb195febcf40e2e9325481bc59ae6ffb3`
(after the Tier A builds) and the same Lean SHA-256 shown above.

[Acceptance checks](2026-09-07_fuel-measure-cost-evidence/d1-acceptance.txt)
verify that every TSV status equals both the retained lane status and its
printed classification, every committed baseline input appears exactly once
per engine, and the only baseline changes are the two known timeouts.
Derived tally: **1,159 MATCH, 499 CERB_SKIP, 11 TIMEOUT**. All nine baseline
TIMEOUT inputs remain TIMEOUT; no other input changes status. The underlying
lane's exit 1 is the expected D1 observation, not a green baseline verdict.
The instrument's integrity acceptance, selftest, and Tier A gates are green.
Evidence occupies 175,389 bytes at this D1 acceptance point, below the
charter's 1 MB total limit. Verbatim lane verdicts:

```text
SUMMARY: total=1669 match=1159 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=11 hang=0 cerb_skip=499 cerb_floor=0 cerb_inconsistent=0
REGRESSION: sa_csmith_369.c baseline=MATCH current=TIMEOUT
REGRESSION: sa_csmith_371.c baseline=MATCH current=TIMEOUT
Baseline check: 2 regression(s), 0 improvement(s)
FAILED: regressions vs baseline
```

Timing-table load, verbatim from the export metadata:

```text
start_uptime=20:15:07 up 1 day,  4:50,  ? user,  load average: 10.84, 7.30, 9.70
end_uptime=22:36:57 up 1 day,  7:12,  ? user,  load average: 5.59, 5.32, 6.25
```

The live pass reproduced both known regressions, verbatim:

```text
[303/1669] TIMEOUT sa_csmith_369 (Lean TIMEOUT(cpu 15.00s of 15.00s wall; timeout 15s))
[306/1669] TIMEOUT sa_csmith_371 (Lean TIMEOUT(cpu 14.99s of 15.00s wall; timeout 15s))
```

[AGENT] These observations are CPU-bound at the lane's limit. At the
312-input observation point they were the only baseline changes (derived
comparison of completed printed statuses with the committed baseline).
This is partial-run evidence, not D1 acceptance. The load read immediately
after that observation was:

```text
 21:00:34 up 1 day,  5:36,  ? user,  load average: 32.11, 9.90, 5.36
```

The separate [live instrument check](2026-09-07_fuel-measure-cost-evidence/d1-live-instrument-check.txt)
verified byte equality of all 1,669 staged inputs and both headers against
the lane's recipe, the exact sorted input list, and real timing-record
parsing on the first 36 completed inputs. The completed export subsequently
passed the full acceptance checks above.

## D2 — attribution (complete)

### Sampling method and limits

`perf record -e cpu-clock:u -F 99 -g` could not open any events: this host's
`perf_event_paranoid=4` blocks performance monitoring. The
[verbatim refusal](2026-09-07_fuel-measure-cost-evidence/perf-preflight.txt)
is retained. No host settings were changed. An unrelated optional `file`
probe hit nono's `/etc/magic` read boundary (`nono why`: `path_not_granted`);
it still identified the executable as ELF. That read was unnecessary.

D2(a)'s permitted equivalent is a local
[CPU-timer stack sampler](2026-09-07_fuel-measure-cost-evidence/cpu-stack-sampler.c),
compiled to an ignored shared library and loaded with `LD_PRELOAD` only for
these profiling runs. It samples the existing, unchanged Lean binary using
`ITIMER_PROF`/`SIGPROF`, records the interrupted instruction pointer and up to
96 stack frames, and resolves them against that exact binary's `nm` table.
The [analyzer](2026-09-07_fuel-measure-cost-evidence/analyze-cpu-stacks.py)
counts self samples at the interrupted PC, inclusive symbols once per stack,
and the union of measure frames once per sample. Library/runtime work under
a visible measure frame belongs to that measure's inclusive share.

The [fixture](2026-09-07_fuel-measure-cost-evidence/fixture.c) has two known
0.7-CPU-second phases. Initially the compiler folded its identical functions
together; compiling the fixture with `-fno-ipa-icf` kept them distinguishable.
The successful [selftest](2026-09-07_fuel-measure-cost-evidence/sampler-selftest.txt)
resolved both interrupted PCs and caller stacks, with 69/139 and 70/139
inclusive samples in the respective phases. Verbatim:

```text
CPU stack sampler SELFTEST OK: interrupted PCs and inclusive stacks resolve both known CPU phases, each 30%-70% of samples
```

The profiler prewarms `backtrace`, which is not guaranteed async-signal-safe
by POSIX. Each real run was externally bounded at 90 seconds under the
48 GiB cap and completed with exit 0. Stacks frequently reached the 96-frame
limit because of deep driver continuations; inclusive results describe
visible frames, not an exhaustive call graph. Optimized-away frames and
inline-only arithmetic can be missed. The measure union is a sampling
estimate, not exact accounting, and an unsampled environment operation is
not proof of zero cost. Ordinary ratio measurements will not load this
library. No profiling time is used as `cpu_head` in a pre-arc ratio.

### Observed CPU shares

The two inputs use their actual D1 captured cabs-json from HEAD's own oracle
(rows 303 and 306), not a regenerated or cross-version bridge. All four runs
have exactly the same full Defined-line sets as the captured oracle
([verdict checks](2026-09-07_fuel-measure-cost-evidence/profile-verdicts.txt)).
The first runs use a 10,000-microsecond CPU timer; repeats use 17,000
microseconds to check sensitivity to the sampling interval.

Derived shares below come from the complete self/inclusive top-symbol
reports. Environment, expression, and ctype groups can overlap; measure
union and rest partition the samples. “Rest” means no visible measure frame.

| Input / run | Samples | Environment bounds | Expression sizes | Ctype sizes | Measure union | Rest |
|---|---:|---:|---:|---:|---:|---:|
| [369 initial](2026-09-07_fuel-measure-cost-evidence/sa_csmith_369.profile.txt) | 3021 | 0.00% | 46.67% | 0.00% | 46.67% | 53.33% |
| [369 repeat](2026-09-07_fuel-measure-cost-evidence/sa_csmith_369-repeat.profile.txt) | 2342 | 0.00% | 44.96% | 0.04% | 45.00% | 55.00% |
| [371 initial](2026-09-07_fuel-measure-cost-evidence/sa_csmith_371.profile.txt) | 2042 | 0.05% | 39.37% | 0.00% | 39.42% | 60.58% |
| [371 repeat](2026-09-07_fuel-measure-cost-evidence/sa_csmith_371-repeat.profile.txt) | 1761 | 0.17% | 39.24% | 0.11% | 39.47% | 60.53% |

The top initial self symbol on both inputs is
`lp_CerberusLean_generic__expr___00lemSize___redArg`: 38.60% on 369,
32.32% on 371. Its recursive `aux2` contributes another 5.36% / 3.82% self
samples. The reports list the other measure symbols individually and the
remaining top CPU symbols, including reference-count destruction,
allocation/freeing, function application, substitution, and evaluation.

[AGENT] The observed mechanism is eager recomputation of a structural size:
`get_ctx` evaluates `generic_expr.lemSize g + 1` before searching for the
next reducible expression. That size traverses the arena, including branches
that the context search does not visit on that step, and the driver repeats
it for successive steps. These executable measure computations remain after
proof erasure. On these inputs this is the largest measured hotspot. The
whole-environment layout bounds are not a substantial sampled contributor,
so the proposed `refsOf` guard for those bounds would not address this
hotspot. The completed ordinary reference repetitions below support the attribution:
HEAD adds roughly as much CPU as the observed expression-size work costs.
**[AGENT] MEASURES ARE the dominant cause of these two regressions**,
specifically eager expression sizing in `get_ctx`. This is a measured
attribution judgment, not proof of an exact additive cost decomposition or
of a future remedy meeting the 1.10 bar.

Host load for this table, verbatim from the four `.meta.txt` files (initial
369, initial 371, repeat 369, repeat 371; start then end):

```text
 22:44:07 up 1 day,  7:19,  ? user,  load average: 16.23, 7.42, 6.42
 22:44:38 up 1 day,  7:20,  ? user,  load average: 18.55, 8.86, 6.94
 22:45:19 up 1 day,  7:21,  ? user,  load average: 20.98, 10.81, 7.68
 22:45:40 up 1 day,  7:21,  ? user,  load average: 21.37, 11.53, 7.98
 22:46:31 up 1 day,  7:22,  ? user,  load average: 23.28, 13.64, 8.91
 22:47:16 up 1 day,  7:23,  ? user,  load average: 55.61, 23.66, 12.53
 22:47:18 up 1 day,  7:23,  ? user,  load average: 55.61, 23.66, 12.53
 22:47:52 up 1 day,  7:23,  ? user,  load average: 71.73, 31.30, 15.50
```

The busy and changing box increased repeat runtimes; those runtimes are not
performance-ratio evidence. The repeated sampling shares remain consistent
about the hotspot.

### Pre-arc reference build (complete)

The charter's exact `scripts/new-worktree.sh` commands created
`worktrees/cerberus-lean-ref/1b57bcf26` and `worktrees/lem-lean-ref/3c88f0d`.
The pinned Lem tool built once with `make`, under the 48 GiB cap and a
55-minute tripwire, successfully in about 66 seconds. It reports
`Lem 3c88f0d`; executable SHA-256:
`75efb04e017d5272ec0ddcbe9203cdb0258ba2c48044edad05a1b51efa17bf74`.

The first reference generation invocation (before any oracle or Lean
compilation) exposed a missing local library-path setting:

```text
File "frontend/model/global.lem", line 1, character 1 to line 1, character 22
  Unknown dependency: could not find module 'Pervasives' in directories 'frontend/model', './library'
make: *** [Makefile:223: ocaml_frontend/generated/utils.ml] Error 1
```

[AGENT] This is a scoped reference-tool invocation issue, not an
outside-fence compatibility failure. The tool's `README.md:85`,
`doc/manual/invocation.md:45`, and `src/main.ml:73` explicitly document
`LEMLIB`. Generation resumes with `LEMLIB` pointing to this same reference
worktree's `library/`, alongside its directory prepended to `PATH`. No
reference tool rebuild, source adjustment, installed-library change, pin,
or opam modification was needed. Both primed generated trees were cleaned
using the reference Makefile's own targets before generation; the reference
build uses a worktree-local `dune install --prefix` rather than the old
helper's shared-switch install. The configured build completed successfully
at `2026-09-07T22:56:11Z`, after starting at `22:52:38Z`, with a clean
reference worktree. The [build recipe](2026-09-07_fuel-measure-cost-evidence/build-reference.sh),
[creation output](2026-09-07_fuel-measure-cost-evidence/reference-create.txt),
[Lem build verdict](2026-09-07_fuel-measure-cost-evidence/d2-lem-build-verdicts.txt),
[initial path failure](2026-09-07_fuel-measure-cost-evidence/reference-library-path-failure.txt),
and [reference build verdicts](2026-09-07_fuel-measure-cost-evidence/d2-reference-configured-build-verdicts.txt)
are retained. Verbatim:

```text
Build completed successfully (271 jobs).
REFERENCE CONFIGURED BUILD EXIT: 0
```

| Reference engine | SHA-256 |
|---|---|
| Oracle | `5773df76681e44f4ff117957617acae97fcf0622630b92c8804821dc6f185e2c` |
| Lean | `99912f86b9e98dfb415af071138058e0f004b26e760c5a99941475e055332d83` |

### Ordinary CPU comparisons (complete)

Repeated HEAD measurements at 90 seconds, using the unchanged
`tests/mem-scale-probes/measure.sh` on the lane's actual staged files and
HEAD's own oracle bridge, completed successfully:
[TSV](2026-09-07_fuel-measure-cost-evidence/head-known-before-90.tsv),
[identities and every timing run's uptime](2026-09-07_fuel-measure-cost-evidence/head-known-before-90.meta.txt).
Lean CPU seconds were 21.18 / 21.37 on 369 and 16.14 / 16.16 on 371.
These ordinary runs do not load the profiling library. They replace the
censored 15-second observations only in completed-program CPU comparisons;
they do not satisfy the 15-second completion requirement.

The corresponding reference repetitions also completed with the same
verdicts: [TSV](2026-09-07_fuel-measure-cost-evidence/pre-known-before-90.tsv),
[metadata](2026-09-07_fuel-measure-cost-evidence/pre-known-before-90.meta.txt).
They used the byte-identical D1 staged C files, parsed afresh by the
reference's own oracle and consumed by its own Lean binary. Derived paired
ratios ([TSV](2026-09-07_fuel-measure-cost-evidence/known-before-ratios.tsv)):

| Input | Repeat | CPU pre (s) | CPU HEAD (s) | HEAD / pre |
|---|---:|---:|---:|---:|
| sa_csmith_369.c | 1 | 10.87 | 21.18 | 1.948482 |
| sa_csmith_369.c | 2 | 10.62 | 21.37 | 2.012241 |
| sa_csmith_371.c | 1 | 8.95 | 16.14 | 1.803352 |
| sa_csmith_371.c | 2 | 9.07 | 16.16 | 1.781698 |
| sa_csmith_419.c | 1 | 14.42 | 23.98 | 1.662968 |
| sa_csmith_419.c | 2 | 14.59 | 24.58 | 1.684716 |

The property is already false at untouched HEAD on these three
rows; this is not a post-remedy verdict. Each decision row has two ordinary
measurements on each binary. Timing-table load, verbatim (HEAD start, four
run starts, end; then pre-arc in the same order):

```text
 22:57:39 up 1 day,  7:33,  ? user,  load average: 2.17, 18.55, 20.50
 22:57:39 up 1 day,  7:33,  ? user,  load average: 2.17, 18.55, 20.50
 22:58:05 up 1 day,  7:33,  ? user,  load average: 2.18, 17.24, 20.01
 22:58:25 up 1 day,  7:34,  ? user,  load average: 2.19, 16.27, 19.63
 22:58:51 up 1 day,  7:34,  ? user,  load average: 2.13, 14.90, 19.07
 22:59:11 up 1 day,  7:35,  ? user,  load average: 2.25, 14.10, 18.72
 23:00:06 up 1 day,  7:35,  ? user,  load average: 1.24, 11.83, 17.68
 23:00:06 up 1 day,  7:35,  ? user,  load average: 1.24, 11.83, 17.68
 23:00:21 up 1 day,  7:36,  ? user,  load average: 1.41, 11.35, 17.42
 23:00:34 up 1 day,  7:36,  ? user,  load average: 1.42, 11.02, 17.25
 23:00:49 up 1 day,  7:36,  ? user,  load average: 1.33, 10.53, 16.99
 23:01:02 up 1 day,  7:36,  ? user,  load average: 1.41, 10.10, 16.75
```

The reference corpus measurement uses two separate D1-instrument runs,
shards `1/6` and
`2/6`, each with a 55-minute outer tripwire. Their disjoint union is exactly
all 470 small_arrays inputs plus shard 2's list: 558 inputs, with no repeat
of the 191 overlapping small_arrays/shard-2 inputs. The
[selection check](2026-09-07_fuel-measure-cost-evidence/reference-subset.txt)
uses the actual D1 sorted staging list and the unchanged lane shard formula.
This avoids combining the two reference slices into a pass approaching an
hour. Corpus sources, the staging script, and the committed corpus baseline
are byte-unchanged between pre-arc and HEAD. The
[resolved-pin check](2026-09-07_fuel-measure-cost-evidence/reference-pin-check.txt)
also verifies the actual LemLib checkout equals the manifest's `3c88f0d`
revision, and the reference checkout and engine identities remain unchanged.

Shard 1 completed in 39 minutes 16 seconds, below its 55-minute tripwire:
[TSV](2026-09-07_fuel-measure-cost-evidence/pre-before-15-shard1.tsv),
[metadata](2026-09-07_fuel-measure-cost-evidence/pre-before-15-shard1.meta.txt).
Saved-export checks independently confirm the exact selected input set,
two engine rows per input, and every status equal to the committed baseline.
Verbatim:

```text
SUMMARY: total=279 match=127 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=1 hang=0 cerb_skip=151 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
```

Timing-table load, verbatim:

```text
start_uptime=23:01:52 up 1 day,  7:37,  ? user,  load average: 1.28, 8.72, 15.93
end_uptime=23:41:08 up 1 day,  8:17,  ? user,  load average: 56.89, 29.38, 14.10
```

Shard 2 completed in 32 minutes 35 seconds:
[TSV](2026-09-07_fuel-measure-cost-evidence/pre-before-15-shard2.tsv),
[metadata](2026-09-07_fuel-measure-cost-evidence/pre-before-15-shard2.meta.txt).
Both `369` and `371` read MATCH at the lane's 15-second timeout. The sole
baseline difference is **`sa_csmith_419.c`: TIMEOUT → MATCH**. This is a
reference observation; no baseline file was rewritten. Verbatim:

```text
SUMMARY: total=279 match=160 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=2 hang=0 cerb_skip=117 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 1 improvement(s)
```

Timing-table load, verbatim:

```text
start_uptime=23:41:38 up 1 day,  8:17,  ? user,  load average: 43.53, 29.09, 14.51
end_uptime=00:14:13 up 1 day,  8:50,  ? user,  load average: 4.68, 4.15, 4.74
```

Because 419 completed on the reference but was censored at HEAD's 15-second
limit, it received the same ordinary two-repeat treatment as 369 and 371:
[HEAD timings](2026-09-07_fuel-measure-cost-evidence/head-419-before-90.tsv),
[HEAD metadata](2026-09-07_fuel-measure-cost-evidence/head-419-before-90.meta.txt),
[reference timings](2026-09-07_fuel-measure-cost-evidence/pre-419-before-90.tsv),
[reference metadata](2026-09-07_fuel-measure-cost-evidence/pre-419-before-90.meta.txt).
Those repetitions supply the two 419 rows in the paired table above. Their
load readings, verbatim (HEAD start, two run starts, end; then reference):

```text
 00:15:33 up 1 day,  8:51,  ? user,  load average: 2.76, 3.71, 4.54
 00:15:33 up 1 day,  8:51,  ? user,  load average: 2.76, 3.71, 4.54
 00:16:03 up 1 day,  8:51,  ? user,  load average: 2.44, 3.55, 4.46
 00:16:33 up 1 day,  8:52,  ? user,  load average: 2.99, 3.55, 4.43
 00:16:33 up 1 day,  8:52,  ? user,  load average: 2.99, 3.55, 4.43
 00:16:33 up 1 day,  8:52,  ? user,  load average: 2.99, 3.55, 4.43
 00:16:54 up 1 day,  8:52,  ? user,  load average: 2.71, 3.45, 4.38
 00:17:15 up 1 day,  8:53,  ? user,  load average: 3.06, 3.49, 4.37
```

All 12 ordinary oracle/Lean pairs for the three inputs have identical
**full Defined-line multisets**, not only equal return values
([checks](2026-09-07_fuel-measure-cost-evidence/ordinary-verdicts.txt)). The
reference corpus TSV uses its own historical lane's classification code,
whose identity is recorded in each export; that historical lane predates
HEAD's full Defined-line classifier. Its verdict is not a substitute for
HEAD's current trust gates.

The complete [per-input Lean CPU ratio table](2026-09-07_fuel-measure-cost-evidence/before-prearc-ratios.tsv)
has all **287 inputs completing on both binaries**, including raised-budget
completion evidence for the three HEAD-censored inputs. For those three,
`cpu_pre` and `cpu_head` are the means of the two ordinary repetitions on
each binary; every other row uses the 15-second lane observations. The
`cpu_source` column makes this distinction explicit, and both original
15-second statuses remain visible. No profiling time enters a ratio.

The other **271 inputs** are explicitly listed in the
[exclusion table](2026-09-07_fuel-measure-cost-evidence/before-prearc-excluded.tsv):
268 oracle-side skips and three inputs still censored on the reference.
They are not zero-CPU samples or completed-program comparisons. The
[derivation script](2026-09-07_fuel-measure-cost-evidence/derive-before-ratios.py)
checks unique input/engine keys, exact union coverage, all raised-run exits
and verdicts, and complete partitioning of the required 558 inputs.
[Its output](2026-09-07_fuel-measure-cost-evidence/d2-comparison-check.txt), verbatim:

```text
D2 comparison integrity OK: 558 required inputs = 287 completed-CPU ratios + 271 explicitly excluded inputs.
Derived pre-arc joint-status tally: {'MATCH': 287, 'CERB_SKIP': 268, 'TIMEOUT': 3}
Derived ratio tally: above_1.10=73; at_or_below_1.10=214
Derived ratio min=0.400000 median=1.000000 max=3.234694
Only the three censored HEAD inputs use raised-budget repeats; all remaining ratios are single lane observations.
No D4/post-remedy verdict: short-duration ratios have 0.01-second quantization, and deciding ratios must be repeated.
```

The table's load provenance is the D1 HEAD metadata, both reference shard
metadata files, and the ordinary-repeat metadata quoted above. The changing
box load and 0.01-second quantization limit interpretation of the individual
short-run ratios. The repeated decision rows support D2's attribution;
the full table is before-remedy evidence, not D4 acceptance.

D2 acceptance is complete: both reference builds passed, both selected
lanes exited 0 with no regressions, sample and ordinary-run checks passed,
and all required inputs are accounted for. D1's Tier A semantic gates remain
the applicable unchanged-HEAD snapshot; D2 changed only this record and its
measurement artifacts. No D3 semantic edit has occurred.

### D3 acceptance clarification — resolved by the operator

[USER 2026-09-08]: “"0 regression(s)" is the gate; the exact
"0 improvement(s)" wording is withdrawn.” The operator directs that
improvements be reported, and that every baseline TIMEOUT row which becomes
MATCH at 15 seconds on HEAD-after be re-recorded in a **dedicated instrument
commit separate from the code change**. Its message must list each such row
with the measured HEAD-after `cpu_s` and its verbatim MATCH verdict line.
No other baseline row may change. The operator reiterates that
`sa_csmith_369` and `sa_csmith_371` must read MATCH and directs D3 to proceed.

This explicit ruling resolves the pending asynchronous question and
supersedes the charter's exact zero-improvement criterion and blanket
baseline immutability only for those evidenced improvements in that separate
commit. D1/D2 measurements and their baseline identities remain historical
evidence. No baseline edit has yet occurred.

## D3 — narrower context-search measure (complete)

D2 committed as `30384f4a797e55f670f9ace4337befd58aa0f57c`. Before the
first D3 semantic edit, D1's Tier A `test_unit.sh` snapshot was already green
and the unchanged Lean binary still had SHA-256
`32f8b3427f023ad78afc27fd170284cf09c2b331751652ef588d8d0061a62ad6`.
The [selected unit verdicts](2026-09-07_fuel-measure-cost-evidence/d3-untouched-unit-verdicts.txt)
retain that required untouched snapshot.

[AGENT] The candidate measure is the depth of possible calls in the
`get_ctx`/`get_ctx_unseq_aux` mutual block. A state is an expression or an
operand list. Sequence nodes visit only their left operand; bounds and
annotations visit their child; an unsequenced node visits its list; a
nonempty list visits its head and tail. Every other state has no children.
Irreducibility tests and the nested-annotation stop case are conservatively
ignored. The bound is one plus the
maximum child bound, so each possible worker call strictly decreases it.
It avoids sizing pure-expression payloads and sequence continuations.

The first generic prototype, `CerbTagsWf.branchBound`, implemented that recursion with
`WellFounded.fix`. The structural rank is used only by erased termination
proofs. This generic helper lives in the permitted measure module because
Core already imports that module through CerbMem, precluding a Core import
in the opposite direction. The raw generated measure and the named proof
measure share this same recursive definition; their call matches agree by
`rfl` and their termination proofs by proof irrelevance. The prototype's
[joint stability cone](2026-09-07_fuel-measure-cost-evidence/d3-prototype-axioms.txt)
is within `[propext, Classical.choice, Quot.sound]`.

The initial inline-lambda declaration was rejected by Lem's existing
`FM-free` validator ([verbatim rejection](2026-09-07_fuel-measure-cost-evidence/d3-inline-measure-generation-rejection.txt)).
The permitted module now supplies the named Lean term macro
`CerbTagsWf.getCtxMeasure`, expanding to the same ordinary measure term
where Core's AST types are available. Lem accepts the qualified name;
there is no new Lem vocabulary, dependency change, or proof-trust extension.
`make prelude-src lean-prelude-src` completed with that declaration.

Only the two permitted `.lem` measure expressions changed. The surrounding
historical C3 comment is preserved by the measure-expression-only fence;
its whole-list-derived-size description refers to the previous measure.
Only the permitted content-pin row in `fork_drift_manifest.txt` changed:

- Before: `dd12a55bc776acb588a33b811d175ad66ffb190cec4ec39b8b61179f01059cd1`
- After: `b80d535a24bb993a5bf6715979bb0cd2d6b0f65e40116149bbfbebc39e7da695`

The first root build required fixing hygiene in the new macro: its AST type
identifiers are intentionally resolved at the expansion site, and its list
membership proof explicitly substitutes the child. A focused macro probe
then passed. The next root build passed all generated obligations, and the
[measure audit](2026-09-07_fuel-measure-cost-MeasureAudit.lean) printed the
permitted cones for all eight relevant sufficiency theorems and both
old/new equivalences.

The first Tier A attempt exposed a compatibility requirement in the
unchanged consumer exemplar: `FuelExemplar.round_done` at line 465 uses
`rfl` to reduce the value context. The general well-founded bound did not
reduce definitionally there. This is a consequence of the new measure,
addressed inside the allowed measure module: `branchBoundEntry` returns
its single frame directly when the possible-call list is empty, and is
proved equal to `branchBound` for every state. The unchanged worker then
reduces on `mk_value_e v` by `rfl`, as a focused probe verifies. No test
statement, worker, or proof-budget option changed.

The interrupted first Tier A run is not acceptance evidence: A1 failed;
A2–A5 (including A4b/c) passed before cancellation during A6. Its source
aggregate also changed because compact evidence was written during the
run; the replacement run will freeze every tracked/untracked source file
until completion. The first attempt's raw report and diagnostic are kept
under `.tmp/fuel-measure-cost/`. No outside-fence gate failure is claimed;
the measure-induced definitional issue is being repaired within the fence.

The second Tier A attempt held source identity unchanged and passed all
six unit executables, axiom checks, and the no-fuel-numerals gate. The
fuel-forms selftest then rejected the two new wrappers in its unplanted
comparison: separate macro pattern matches elaborate into distinct private
matcher definitions, which are not unfolded at the gate's deliberately
restricted `.reducible` transparency. A Meta probe confirmed `.reducible`
comparison false and ordinary kernel definitional equality true. The run
was cancelled after that failure; its report is retained as
`.tmp/fuel-measure-cost/d3-fast-leaf/` and is not a pass.

The measure macro now uses explicit `Sum.casesOn`, `generic_expr.casesOn`,
`generic_expr_.casesOn`, and `List.casesOn` to inspect the same constructors.
No private pattern matcher is introduced into the executable measure term.
The proof's named next-call function uses the same eliminators. The
[focused probe](2026-09-07_fuel-measure-cost-evidence/d3-cases-prototype.txt)
checks joint stability, definitional leaf reduction, and equality of separate
macro expansions at the gate's existing `.reducible` transparency. No gate
source, comparison rule, obligation shape, or option was changed.

The existing size-based stability lemma is retained. Two additional
pointwise equivalence theorems compare the previous measure's worker with
the new wrapper through a common sufficient fuel. The six environment-bound
wrappers and their sufficiency obligations remain unchanged: D2 did not
attribute the known regressions to those bounds.

The regenerated fork-drift gate passed, verbatim:

```text
check_fork_content: OK — 76 source files content/mode-pinned
check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin f6542f8 = lem -v)
```

The first passing candidate root build (including `fuel-exemplar-test`) passed
381 jobs. The [actual audit cones](2026-09-07_fuel-measure-cost-evidence/d3-measure-axioms.txt)
all stay within the permitted three. The [direct fuel-forms gate](2026-09-07_fuel-measure-cost-evidence/d3-fuel-forms.txt)
passes with the unchanged census, verbatim:

```text
check_fuel_forms: forms partition OK (54 MEASURED + 13 ABSORBING + 8 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)
check_fuel_forms: OK (81 fuel'd workers: 54 MEASURED (obligation of the contract's shape incl. argument correspondence against the wrapper's body; every obligation + proof cone ⊆ the standard three; 7 of them under a hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions), 13 ABSORBING = kill at zero (the _zero lemma is the worker at literal 0 on its own binders = the monad's absorbing element, cone ⊆ the standard three; propagation NOT proved — lem TODO 13), 8 reachable-AMBIENT = the 8 rows of fuel_forms_pending.txt exactly, 6 ambient unreachable from the drive cone)
```

The [generated-C excerpt](2026-09-07_fuel-measure-cost-evidence/d3-compiled-bound.txt)
shows that the recursive helper takes only `next` and the current state;
its rank is never evaluated. The leaf entry returns the derived single
frame directly. The complete replacement Tier A run passed ([verbatim runner verdicts](2026-09-07_fuel-measure-cost-evidence/d3-fast-verdicts.txt),
[required gate lines](2026-09-07_fuel-measure-cost-evidence/d3-required-gate-verdicts.txt)):

```text
fast: passed; 13/13 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

At this first-candidate checkpoint, runtime timing and the required
15-second passes were still pending. Its Tier A pass was not a D5
full-battery claim; the subsequent measurements and selected implementation
are recorded below.

### First passing candidate: ordinary repeats and remaining cost

The explicit-eliminator candidate (Lean SHA-256
`be1da899f7ad722dad3cf89ab7164eaf50162a024f2e452746ac2ae7d8c3cb2e`)
is retained as a [source patch](2026-09-07_fuel-measure-cost-evidence/candidate1-measures.patch)
against D2. Its root build and Tier A passed above. Two ordinary 90-second
repetitions per input, using the actual D1 staged C files and each binary's
own oracle bridge, all completed with equal full Defined-line multisets:
[candidate TSV](2026-09-07_fuel-measure-cost-evidence/candidate1-after-90.tsv),
[metadata](2026-09-07_fuel-measure-cost-evidence/candidate1-after-90.meta.txt),
[verdicts](2026-09-07_fuel-measure-cost-evidence/candidate1-after-90.verdicts.txt),
and a fresh check on the unchanged pre-arc binary
[TSV](2026-09-07_fuel-measure-cost-evidence/current-pre-90.tsv),
[metadata](2026-09-07_fuel-measure-cost-evidence/current-pre-90.meta.txt),
[verdicts](2026-09-07_fuel-measure-cost-evidence/current-pre-90.verdicts.txt).

| Input | Candidate CPU repeats (s) | Current pre-arc CPU repeats (s) | Derived ratio of means |
|---|---|---|---:|
| sa_csmith_369.c | 13.51 / 13.28 | 10.97 / 11.26 | 1.2051 |
| sa_csmith_371.c | 11.66 / 11.17 | 9.18 / 9.33 | 1.2334 |
| sa_csmith_419.c | 18.83 / 18.32 | 15.49 / 15.16 | 1.2121 |

These are candidate measurements, not D3's 15-second lane verdicts or D4
acceptance. The pre-arc repetitions are somewhat slower than D2's earlier
ones; 419's original pre-arc 15-second MATCH remains evidenced by D2.
Timing-table load, verbatim (candidate then current pre-arc):

```text
01:33:00 up 1 day, 10:08,  ? user,  load average: 2.07, 3.43, 6.34
01:33:00 up 1 day, 10:08,  ? user,  load average: 2.07, 3.43, 6.34
01:33:18 up 1 day, 10:09,  ? user,  load average: 2.91, 3.52, 6.31
01:33:18 up 1 day, 10:09,  ? user,  load average: 2.91, 3.52, 6.31
01:33:34 up 1 day, 10:09,  ? user,  load average: 4.40, 3.82, 6.36
01:33:34 up 1 day, 10:09,  ? user,  load average: 4.40, 3.82, 6.36
01:34:00 up 1 day, 10:09,  ? user,  load average: 5.62, 4.16, 6.40
01:34:00 up 1 day, 10:09,  ? user,  load average: 5.62, 4.16, 6.40
01:34:18 up 1 day, 10:10,  ? user,  load average: 5.37, 4.20, 6.37
01:34:18 up 1 day, 10:10,  ? user,  load average: 5.37, 4.20, 6.37
01:34:33 up 1 day, 10:10,  ? user,  load average: 5.13, 4.20, 6.33
01:34:33 up 1 day, 10:10,  ? user,  load average: 5.13, 4.20, 6.33
01:34:57 up 1 day, 10:10,  ? user,  load average: 4.75, 4.19, 6.27
01:34:58 up 1 day, 10:10,  ? user,  load average: 4.75, 4.19, 6.27
01:37:13 up 1 day, 10:13,  ? user,  load average: 4.77, 4.28, 6.01
01:37:13 up 1 day, 10:13,  ? user,  load average: 4.77, 4.28, 6.01
01:37:28 up 1 day, 10:13,  ? user,  load average: 4.37, 4.22, 5.96
01:37:28 up 1 day, 10:13,  ? user,  load average: 4.37, 4.22, 5.96
01:37:41 up 1 day, 10:13,  ? user,  load average: 4.31, 4.21, 5.94
01:37:41 up 1 day, 10:13,  ? user,  load average: 4.31, 4.21, 5.94
01:38:03 up 1 day, 10:13,  ? user,  load average: 4.62, 4.29, 5.92
01:38:03 up 1 day, 10:13,  ? user,  load average: 4.62, 4.29, 5.92
01:38:19 up 1 day, 10:14,  ? user,  load average: 4.55, 4.29, 5.89
01:38:19 up 1 day, 10:14,  ? user,  load average: 4.55, 4.29, 5.89
01:38:32 up 1 day, 10:14,  ? user,  load average: 4.43, 4.28, 5.86
01:38:32 up 1 day, 10:14,  ? user,  load average: 4.43, 4.28, 5.86
01:38:54 up 1 day, 10:14,  ? user,  load average: 4.38, 4.28, 5.83
01:38:54 up 1 day, 10:14,  ? user,  load average: 4.38, 4.28, 5.83
```

The [369 profile](2026-09-07_fuel-measure-cost-evidence/candidate1-sa_csmith_369.profile.txt)
and [371 profile](2026-09-07_fuel-measure-cost-evidence/candidate1-sa_csmith_371.profile.txt)
use the same checked CPU-stack sampler, on each candidate run's own captured
bridge, at a 10,000-microsecond CPU interval. Both exit 0 and agree with the
ordinary oracle's full Defined multiset. Their metadata retains commands,
identities and start/end uptime. The [after-profile classifier](2026-09-07_fuel-measure-cost-evidence/analyze-after-cpu-stacks.py)
separates the new generic context bound from the tag-environment group;
the D2 analyzer remains unchanged.

Derived inclusive shares: the new context bound occupies 10.85% (148/1364
samples) on 369 and 10.48% (120/1145) on 371. Other expression measures
occupy 3.15% / 2.53%; environment bounds 0.07% / 0.09%; all measure work
14.08% / 13.10%. As before, stack truncation and inlining limit attribution;
profiled CPU is never used in a ratio.

[AGENT] The candidate removed the dominant full-arena traversal, but its
new bound still incurs measurable traversal, allocation and higher-order
call costs. Before accepting that remaining cost, the next candidate adds
`@[inline]` only to `branchBound` and `branchBoundEntry`, exposing the known
visitor to the compiler's existing well-founded-recursion specialization.
The numeric bound, term expansion, and proof statements are unchanged.
The inlined candidate built successfully, but ordinary repeats showed no
clear benefit: Lean CPU 369 14.26 / 13.09 s, 371 11.56 / 11.11 s,
419 18.06 / 18.89 s. All six full Defined-line multisets agreed with
the oracle; identities remained unchanged. See [timings](2026-09-07_fuel-measure-cost-evidence/candidate2-inline-90.tsv),
[commands and load](2026-09-07_fuel-measure-cost-evidence/candidate2-inline-90.meta.txt),
and [verdicts](2026-09-07_fuel-measure-cost-evidence/candidate2-inline-90.verdicts.txt).
Generated C still constructed child lists and used the fold's temporary array.

### Direct computation of the context bound

[AGENT] The next candidate fuses the possible-child traversal and maximum
calculation. `callBound` supplies structurally smaller recursive results to
an explicit AST step; that step returns one frame plus the child's bound,
or one plus the maximum of head and tail for an operand list. Its `sizeOf`
rank occurs only in termination proofs. `callBoundEntry` unrolls one step
to preserve definitional reduction on value leaves. The executable measure
allocates no possible-child list; `getCtxNext` remains only a proof specification.
The [prototype](2026-09-07_fuel-measure-cost-evidence/d3-fused-prototype.txt)
passed the joint worker stability proof, value-leaf definitional reduction,
and equality of separate macro expansions at `.reducible` transparency.
The integrated build, measurements and final D3 acceptance follow below.

The integrated direct-bound candidate built all 381 jobs, including
`fuel-exemplar-test` ([build](2026-09-07_fuel-measure-cost-evidence/d3-fused-build.txt)).
The [actual sufficiency audit](2026-09-07_fuel-measure-cost-evidence/d3-fused-axioms.txt)
checks both generated wrappers against the named bound by `rfl`, checks
value-context reduction, and prints all eight obligations plus both old/new
result equivalences. Every cone is contained in the standard three.
The [direct fuel-forms gate](2026-09-07_fuel-measure-cost-evidence/d3-fused-fuel-forms.txt)
passes with 81/54/13/8/6 and seven hypothesis-carrying rows. The old
size-based joint stability lemma is byte-identical to D2. Only source
`.lem` lines 1527/1528 differ; the authorized content pin remains
`b80d535a24bb993a5bf6715979bb0cd2d6b0f65e40116149bbfbebc39e7da695`.

The executable SHA-256 is
`359cf998c422ba3abb1598b57a94187a69071a9f3c59ef8ec365aa13296c42bb`.
[Ordinary repeats](2026-09-07_fuel-measure-cost-evidence/candidate3-fused-90.tsv),
[commands, load and identities](2026-09-07_fuel-measure-cost-evidence/candidate3-fused-90.meta.txt),
and [full Defined multiset verdicts](2026-09-07_fuel-measure-cost-evidence/candidate3-fused-90.verdicts.txt):

| Input | Direct-bound CPU repeats (s) | Current pre-arc repeats (s) | Derived ratio of means |
|---|---|---|---:|
| sa_csmith_369.c | 11.70 / 12.19 | 10.97 / 11.26 | 1.0747 |
| sa_csmith_371.c | 9.97 / 10.08 | 9.18 / 9.33 | 1.0832 |
| sa_csmith_419.c | 15.85 / 15.83 | 15.49 / 15.16 | 1.0336 |

These are 90-second ordinary measurements, not 15-second lane verdicts.
All six oracle/Lean pairs completed with identical full Defined-line
multisets. They establish a cheaper implementation than candidate 1,
subject to the recorded changing box load; D4 must still check every
required per-program ratio and repeat deciding rows.

The [369 profile](2026-09-07_fuel-measure-cost-evidence/candidate3-sa_csmith_369.profile.txt)
and [371 profile](2026-09-07_fuel-measure-cost-evidence/candidate3-sa_csmith_371.profile.txt)
use the checked sampler and each run's own bridge; both complete and
agree with the oracle's full Defined multiset. Derived inclusive shares:
context-bound recursion 1.99% (24/1204 samples) / 1.81% (18/994),
all measures 4.32% / 4.63%, remaining work 95.68% / 95.37%.
The [classifier](2026-09-07_fuel-measure-cost-evidence/analyze-fused-cpu-stacks.py)
recognizes the compiler's specialized well-founded context-bound symbol.
The [generated C](2026-09-07_fuel-measure-cost-evidence/d3-fused-compiled-bound.txt)
shows 278 lines for that recursion, no rank traversal, child-list fold,
array or indirect call. Seven constructor-allocation sites construct or
reuse the Sum state. Root-step work inlined into the wrapper cannot be
separated by this sampler; optimized frames and the 96-frame stack limit
still constrain attribution. Profiled CPU is never used for a ratio.

[AGENT] This is the selected D3 implementation. The complete final Tier A
run passed with source identity unchanged ([runner verdicts](2026-09-07_fuel-measure-cost-evidence/d3-fused-fast-verdicts.txt),
[required gate lines](2026-09-07_fuel-measure-cost-evidence/d3-fused-required-gate-verdicts.txt)):

```text
fast: passed; 13/13 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

### D3 acceptance and the separate instrument commit

The selected source was committed as `6ce040f0614f762e729633a955bcb002dce693ba` only after all
D3 gates were green. The two timing passes measured that same uncommitted
D3 source while Git HEAD was still D2 (`30384f4a7`); their original
metadata is preserved, including unchanged source/engine identities.
No rebuild occurred between the full corpus and the shard check.
The standalone [audit](2026-09-07_fuel-measure-cost-MeasureAudit.lean)
belongs to the code commit. These timing records and the permitted baseline
edit belong to the following, dedicated instrument commit.

- Full HEAD-after: [3,338 engine rows](2026-09-07_fuel-measure-cost-evidence/head-after-15.tsv)
  for all 1,669 inputs; [metadata](2026-09-07_fuel-measure-cost-evidence/head-after-15.meta.txt).
- Required `test_csmith_corpus.sh --check-baseline --shard 2/6`:
  [558 engine rows](2026-09-07_fuel-measure-cost-evidence/head-after-15-shard2.tsv)
  for all 279 selected inputs; [metadata](2026-09-07_fuel-measure-cost-evidence/head-after-15-shard2.meta.txt).
  D1's unchanged, non-gating cleanup-retention instrument invokes the
  unmodified shard command and retains its rusage; it does not alter the gate.

Both run at `TIMEOUT_SECS=15`, `SKIP_BUILD=1`, under the 48 GiB cap.
The whole-corpus pass uses the charter's explicit long-run exception;
the shard is additionally bounded by the 3,300-second outer timeout.
Every exported status was checked against the lane's displayed classification
and retained status file; neither timing run changed its input, script,
baseline or binary identities. Timing-table load and timestamps, verbatim:

```text
Full corpus
start_utc=2026-09-08T02:14:28Z
start_uptime=02:14:28 up 1 day, 10:50,  ? user,  load average: 6.55, 5.51, 5.68
end_utc=2026-09-08T04:34:32Z
end_uptime=04:34:32 up 1 day, 13:10,  ? user,  load average: 1.90, 1.89, 1.49
Shard 2/6
start_utc=2026-09-08T04:34:59Z
start_uptime=04:34:59 up 1 day, 13:10,  ? user,  load average: 1.38, 1.77, 1.46
end_utc=2026-09-08T05:08:01Z
end_uptime=05:08:01 up 1 day, 13:43,  ? user,  load average: 6.96, 6.69, 4.55
```

[Gate verdicts](2026-09-07_fuel-measure-cost-evidence/d3-csmith-verdicts.txt),
verbatim (full corpus, then shard 2/6):

```text
SUMMARY: total=1669 match=1162 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=8 hang=0 cerb_skip=499 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 1 improvement(s)
SUMMARY: total=279 match=159 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=3 hang=0 cerb_skip=117 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
```

Derived status comparison against D1: exactly three TIMEOUT → MATCH rows;
all other 1,666 statuses are identical. No row worsened. The two required
rows were already MATCH in the baseline and are **not** re-recorded there.
Measured Lean CPU, from the ordinary 15-second lane rusage:

| Input | Full HEAD-after cpu_s / status | Shard 2/6 cpu_s / status | Baseline action |
|---|---|---|---|
| sa_csmith_369.c | 12.07 / MATCH | 11.48 / MATCH | remains MATCH, unchanged |
| sa_csmith_371.c | 10.06 / MATCH | 9.64 / MATCH | remains MATCH, unchanged |
| sia_csmith_169.c | 14.93 / MATCH | outside the shard | TIMEOUT → MATCH |

The **only** baseline edit is `sia_csmith_169.c TIMEOUT` →
`sia_csmith_169.c MATCH`. Its full-run wall time was 14.94 s and exit 0.
The dedicated instrument commit message contains each of the three restored
rows above, its measured full HEAD-after `cpu_s`, and its **entire verbatim
MATCH verdict line**, as the operator directed. Those long lines are kept
in that commit message rather than duplicated in this compact evidence tree.
Verbatim unit output, generated-C excerpts and the saved candidate patch retain
their original trailing spaces; the authored-file whitespace check excludes
only those four captures. No source whitespace or repository gate is changed.
The baseline SHA-256 changes from
`f809543d2f7859b6cb09b354274f974db8d548edff0aa40db7a3ed5a647eef10` to
`c284806aeff14fa983964329c59e9d8f761728f5361d4d39c3e99c626e76954b`.
A byte comparison confirms that single data-line replacement and no other
baseline changes; the updated baseline equals all 1,669 full-run statuses.

`sa_csmith_419.c` remains TIMEOUT in both HEAD-after 15-second passes,
and its baseline row is unchanged. Its earlier pre-arc MATCH and the
90-second ordinary completions remain part of D4's CPU/budget assessment;
D3 acceptance does not claim that the full charter property is already met.
At this D3 checkpoint, D4 and the D5 full battery remained pending. No merge or push.

## D4 — per-program bar and remaining budget failure (report complete)

[AGENT] D3 was committed as code `6ce040f06` and dedicated instrument
`5f14f0702b326fae43d2b5968d0e57b1f03b815e`. D4 changes evidence only.
The [complete comparison](2026-09-07_fuel-measure-cost-evidence/after-prearc-ratios.tsv)
contains every one of D2's 287 completing programs in the small_arrays +
shard-2/6 union. It retains the original pre-arc/HEAD-after comparisons,
then two new ordinary CPU measurements per revision and their ratio of means.
The [271 explicit exclusions](2026-09-07_fuel-measure-cost-evidence/after-prearc-excluded.tsv)
are 268 pre-arc oracle skips and three pre-arc timeouts; none supplies a
completed-CPU ratio. Together these tables cover all 558 selected inputs.
The original ratio for `419` uses its two completed candidate-3 90-second
runs, never its censored 15-second CPU. Every row and exception is retained.

The [repeat driver](2026-09-07_fuel-measure-cost-evidence/repeat-prearc-comparison.py)
runs each revision's unchanged `measure.sh`, using that revision's own
oracle/cabs bridge on identical retained lane-staged C and headers. It
alternates revision order within each pair and makes two passes over all
287 programs. Timeout is 90 seconds; execution is serial under the 48 GiB
cap. This is a completed-cost experiment, not a replacement 15-second lane.
Each of the 1,148 oracle/Lean pairs has equal **full** Defined/Undefined-line
multisets, also equal across revisions and repeats. Source, binaries, pins,
baselines, scripts and input hashes remained unchanged. The compact
[metadata](2026-09-07_fuel-measure-cost-evidence/after-prearc-repeat.meta.json)
pins the raw 2,296-engine-row TSV and full input/verdict inventories.
Raw output remains under `.tmp/fuel-measure-cost/d4-repeats`.

Verbatim timing-table boundaries (UTC dates and loads in the metadata):

```text
05:15:41 up 1 day, 13:51,  ? user,  load average: 3.53, 4.48, 4.33
05:24:40 up 1 day, 14:00,  ? user,  load average: 2.63, 3.14, 3.76
05:33:31 up 1 day, 14:09,  ? user,  load average: 4.18, 2.96, 3.30
```

[Repeat verdict](2026-09-07_fuel-measure-cost-evidence/d4-repeat-verdicts.txt), verbatim:

```text
D4 repeats complete: 287 inputs, two repeats per revision, 1148 oracle/Lean pairs; all full observation multisets agree; all identities unchanged.
D4 table integrity OK: 287 complete ratios, 271 explicit exclusions, 558 unique selected inputs; exact Decimal threshold; no censored CPU used.
```

[AGENT] Derived tallies: the initial measurements taken hours apart show
80/287 ratios above 1.10; the paired two-pass experiment shows **1/287**.
Its median ratio is 0.945946. Threshold decisions use exact decimal CPU
sums, not rounded printed ratios. Every initial excess is identifiable in
the complete table, including the short runs sensitive to the instrument's
0.01-second precision and changing machine load. The fresh paired table is
the controlled comparison; the earlier observations have not been deleted.

| Input | pre CPU runs (s) | HEAD-after CPU runs (s) | ratio of means | HEAD-after 15-second lane |
|---|---|---|---|---|
| sa_csmith_369.c | 11.06, 10.66 | 11.95, 11.40 | 1.075046 | MATCH in both full and shard runs |
| sa_csmith_371.c | 9.10, 8.86 | 9.77, 9.50 | 1.072940 | MATCH in both full and shard runs |
| sa_csmith_419.c | 14.45, 14.55 | 15.54, 15.70 | 1.077241 | TIMEOUT in both runs |
| sia_csmith_078.c | 0.84, 0.85 | 0.89, 1.32 | 1.307692 | MATCH |

**The sole repeated-ratio exception is `sia_csmith_078.c`.** Before further
measurement, a fixed four additional ordinary pairs were selected, with
alternating order; this was not repeat-until-pass. The
[follow-up observations](2026-09-07_fuel-measure-cost-evidence/d4-exception-repeats.tsv)
and [metadata](2026-09-07_fuel-measure-cost-evidence/d4-exception-repeats.meta.json)
retain all engine rows, identities, UTC and loads. Pre CPU is
0.83/0.82/0.83/0.83; after CPU is 0.87/0.86/0.88/0.87. Their ratio of means
is **1.051360**. Pooling **all six** ordinary runs per revision, including
1.32, gives pre mean 0.833333 and after mean 0.948333: **1.138000**, still
above the bar. All observations agree. [AGENT attribution] the large excess
is localized to one unreproduced CPU excursion, consistent with timing
variation on a shared machine; its exact external cause is not established.
It is not evidence that a persistent 30.8% measure overhead was removed.
The initial and pooled exceptions remain reported, and an unconditional
all-program ≤1.10 claim is **not** made.

**The separate 15-second budget exception is `sa_csmith_419.c`.** It was
MATCH pre-arc and remains TIMEOUT in both D3 lane runs. Its fresh completed
mean is 15.62 seconds versus 14.50 pre-arc; both new ordinary completions
exceed 15 seconds. Its baseline row remains unchanged TIMEOUT. Reaching
15 from that mean requires a derived **3.97%** reduction in HEAD-after CPU;
a CPU estimate does not itself certify the wall-time lane limit.

D4 profiles both exceptions twice per revision with the checked D2 CPU
sampler and the exact binary symbol table. Each uses its own ordinary
oracle bridge and compares the full oracle/Lean observation multiset.
All exit 0 and preserve input/binary identities. Sampling is separate from
the ordinary timing tables. Verbatim per-profile top symbols, inclusive
shares, interval, depth-limit hits, commands, hashes and loads are retained
in the `d4-profile-*` and `d4-profile-078-*` evidence files.

| HEAD-after input / repeat | samples | context measure | environment measures | other generic-expression measures | all-measure union | rest |
|---|---:|---:|---:|---:|---:|---:|
| 419 / 1 | 1523 | 2.36% | 0.13% | 3.02% | 5.52% | 94.48% |
| 419 / 2 | 1522 | 1.91% | 0.20% | 2.23% | 4.34% | 95.66% |
| 078 / 1 | 887 | 1.92% | 0.00% | 1.69% | 3.61% | 96.39% |
| 078 / 2 | 879 | 1.25% | 0.11% | 2.73% | 4.10% | 95.90% |

[AGENT attribution] D3 removed the dominant full-expression-size traversal.
The remaining profile is mostly allocation/reference-count work, monadic
continuations, expression substitution/evaluation and context application,
on both revisions. For example `419` after repeat 1 has self samples
`mi_free` 9.13%, `lean_dec_ref_cold` 6.89%, `mi_free_size` 3.55% and
`lean_apply_1` 3.41%; its pre-arc profile has the same leading runtime work.
The remaining `generic_pexpr.lemSize` evaluations belong to other measured
wrappers, whose declare lines are outside the two-line model fence.
The six allowed environment measures contribute at most 0.20% on these
profiles, so the proposed `refsOf` guard is not a supported remedy for the
remaining budget miss. No environment wrapper is changed.

The allowed context plus environment measures occupy only about 2.1–2.5%
of `419`'s observed CPU, less than the 3.97% reduction needed at its fresh
mean even if all their visible cost could be removed. This is a sampling
assessment, **not an impossibility theorem**: inlining and 96-frame
truncation limit attribution, and conservative context bounds may still
have refinements. There is no measured, proved remedy inside this fence
that establishes the remaining budget requirement. Further work would
need an operator-selected broader measure scope, a Lem fuel-scheme change,
or a representation change reducing repeated allocation/traversal; a
broader revision bisect could isolate other intervening costs. None is
implemented. For `078`, the profiles do not reproduce the anomalous excess;
a quieter, higher-precision experiment is the appropriate next instrument,
not a speculative semantic optimization.

D4 is therefore a **report of the remaining exceptions**, not certification
of the charter's whole property. Its acceptance checks are complete;
the Tier A checkpoint and D5 status are recorded below.

D4's complete Tier A checkpoint passed all 13 commands with source identity
unchanged. It includes `test_unit.sh`, all four direct execution baselines,
the theorem/fuel/fork gates and their plants. [Runner verdicts](2026-09-07_fuel-measure-cost-evidence/d4-fast-verdicts.txt)
and [lane/gate lines](2026-09-07_fuel-measure-cost-evidence/d4-fast-lane-verdicts.txt)
are quoted verbatim in the evidence. The full fuel census remains
81/54/13/8/6, seven under hypotheses; fork layer 2 remains exactly 22.
The profile script for `078` has a documentation-only correction to identify
it as the ratio exception; its executed sampler command is unchanged.

```text
fast: passed; 13/13 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

D4's report acceptance and checkpoint are green; the reported performance
exceptions remain open. D5's full battery has not been certified.

## D5 — outside-fence prerequisite failure; recorded stop

[AGENT] D4 is committed as `cacc42bbb01cee8cf5e5175f38a12f7cb94e9cd8`.
Before D5's long battery, the required B10.1 lane was selected through the
unchanged release runner to check the independent-oracle prerequisite.
`CERB_INDEPENDENT_MANIFEST` is unset and the documented default manifest is
absent. The required B10.1 command was actually executed, not counted as a
skip or pass. It failed before any oracle comparison. The runner completed
and cleaned its process scope; no heavy job remains from this charter.

Command (after sourcing the project environment):

```sh
CERB_MEM_MAX=48G DUNE_CACHE=disabled ./scripts/capped python3 scripts/release.py --mode full --lane B10.1 --lane-timeout 3300 --out .tmp/fuel-measure-cost/d5-prerequisite
```

[Runner output](2026-09-07_fuel-measure-cost-evidence/d5-prerequisite-verdicts.txt)
and [lane diagnostic](2026-09-07_fuel-measure-cost-evidence/d5-prerequisite-stderr.txt), verbatim:

```text
Release evidence: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/fuel-measure-cost/.tmp/fuel-measure-cost/d5-prerequisite
RUN B10.1: python3 scripts/test_upstream_oracle.py
FAILED B10.1 (0.1s)
full: failed; 0/1 selected commands completed successfully.
Source unchanged: True. Complete tier selection: False.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
INDEPENDENT ORACLE INCOMPLETE: [Errno 2] No such file or directory: '/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/fuel-measure-cost/.validation-foundations/independent-oracle-v2/manifest.json'
```

Both lane and runner exit 1. The
[compact report](2026-09-07_fuel-measure-cost-evidence/d5-prerequisite.meta.json)
pins the complete raw report and retains the actual selected command,
UTC boundaries, statuses, elapsed time, output hashes and containment result.
`--lane B10.1` is explicitly a prerequisite subset: **the full Tier A+B
selection was not run or certified at D5**. No later lane or separate D5
unit/baseline pass was dispatched after this failure. D4's actual full
Tier A run (including `test_unit.sh` and all four direct `test_exec.sh`
baseline lanes) remains green evidence for the same semantic source;
it is not relabeled as D5's complete battery.

The charter's stop rule, verbatim:

> Stop and report (record + commit, no merge) when: D5 is done; or D2 concludes the measures are not the dominant cause; or a required gate is red for a reason outside the fence; or the reference build fails as in D2(b).

[AGENT] This is the required-gate/outside-fence case. `scripts/LADDER.md`
B10 requires a separately prepared pristine Cerberus `b9aeedcb4` / upstream
Lem `3802cb0` build; the lane and runner do not build it. The documented
`build_independent_oracle.py` recipe creates both archived source/build
trees under `.validation-foundations/independent-oracle-v2`. The charter
restricts reference Lem builds to `worktrees/lem-lean-ref/*` worktrees and
reference Cerberus builds to `worktrees/cerberus-lean-ref/*`; it does not
provide this independent manifest. No existing valid manifest was found
at the documented paths in this worktree, the primary or registered
worktrees. I did not run that archive-build recipe outside the reference
layout, alter the gate, synthesize provenance, change pins/opam or broaden
the charter to establish another build recipe. Preparing a checked
independent manifest under an authorized layout is the prerequisite for
a subsequent full-battery run. This stop record does not grant that scope.

Before the prerequisite check, the allowed documentation was updated:
`TODO.md` resolves the two restored csmith rows and eager-context traversal,
retains the measured D4 exceptions and re-scopes the unimplemented
environment guard; `VALIDATION.md` §7 describes the changed context measure
and unchanged census/hypotheses. D1 already added the non-gating instrument
to `LADDER.md`. The [side-by-side theorem statements](2026-09-07_fuel-measure-cost-evidence/theorem-statements.md)
show all eight declarations before and after: six are byte-identical and
two differ only in μ. The D3 kernel audit proves their sufficiency and
checks the permitted cones; this textual comparison does not replace it.

[Final integrity checks](2026-09-07_fuel-measure-cost-evidence/d5-stop-checks.txt)
confirm that the only baseline byte change over the entire charter is the
operator-authorized `sia_csmith_169.c` improvement in its dedicated
instrument commit; 369/371 remain MATCH, and every other baseline row is
unchanged. The dedicated message retains the measured CPU values and full
MATCH lines exactly. The six environment wrappers/proofs, hypothesis
register and Lake pins are unchanged. The stop-record commit contains
only the fenced documentation and compact evidence. It is the explicitly
required failure record, not a claim of a green D5 gate.

## What has not been done

No worker, `_zero` lemma, generated-file hand edit, register, pin,
opam, or non-measure `.lem` change. No baseline change except the explicitly
authorized, separately recorded `sia_csmith_169.c` improvement. The two authorized reference worktrees
remain available. No merge or push. The outside-fence required-gate stop
rule fired at D5 B10.1; no subsequent build, lane, or scope expansion was performed.
