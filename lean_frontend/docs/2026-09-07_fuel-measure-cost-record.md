# Fuel measure execution cost — 2026-09-07

[AGENT] Work under the [fenced charter](2026-09-07_codex-charter-fuel-measure-cost.md),
on `arc/fuel-measure-cost` at starting HEAD
`cee6b4639508c543524900bcd763ae04565f1916`. This HEAD adds only the charter
to the target `4d1088004`. No earlier deliverable or active charter job
was present when this work began. **D1 (commit `a1e7cda30`) and D2 are complete. D3–D5 remain pending;
no proven remedy or charter completion is claimed. Measurements span
2026-09-07 and 2026-09-08.**

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

### Clarification pending for D3 acceptance

[AGENT] Reference 419 exposes a conflict between the charter's requirements:
§0 requires every pre-arc 15-second completer to complete again, while D3
requires the shard to print exactly `0 improvement(s)` against a baseline
that records 419 as TIMEOUT. An asynchronous clarification asks whether new
MATCH improvements may be accepted while keeping every baseline file
unchanged, or whether the exact zero-improvement requirement governs. No
answer or exception has been assumed. This does not prevent completing D2;
it must be resolved or reported when assessing D3 acceptance.

## D3–D5 — not started

No proven measure change, HEAD-after measurement, post-remedy 1.10 bar
verdict, or full closing battery is claimed. The completed pre-arc table
is D2 evidence above.

## What has not been done

No semantics, measure, theorem, worker, `_zero` lemma, generated source,
register, baseline, pin, or opam change. The two authorized reference worktrees have been created for D2. No merge or push. The only intended source changes so far are the
new instrument, its NON-GATING reporting-tier documentation, and this record
and its compact evidence. No stop rule has fired.
