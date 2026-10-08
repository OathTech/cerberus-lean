# B9 (`python3 scripts/test_observation_lanes.py`): profile and options

Date 2026-10-08. Worktree `worktrees/cerberus-lean-lane/pnvi-symbolic-rows` at `4e2b3ce19`
(mainline `c4284b08f` + one PNVI docs/lane commit). I changed no code or lane. The worktree's
git status was clean before and after the run.

Labels: **MEASURED** means a number read from this run's evidence or from a micro-measurement
whose log sits next to this note. **[AGENT]** means my judgement or an estimate derived from
those numbers.

## 1. What B9 runs (read from source, MEASURED by count)

- B9 is a single Python driver. It runs a **93-plant battery strictly in series**: one
  `subprocess.run` per plant, with no parallelism.
- A plant is one complete run of a real lane entry point (`scripts/test_<lane>.sh …`). Both
  engines are replaced by a Python stub through `CERB_{ORACLE,LEAN}_BIN_OVERRIDE`.
- 16 sub-lanes, plants per sub-lane: exec 9, multi_tu 5, cn_coverage 7, ci_sweep 5, gcc_oracle 5,
  verify 6, bytes 5, libc_exec 5, libxml2_uri 5, **immaculate 11**, and 5 each for speclab,
  speclab_divmod, speclab_bytearr, speclab_list, speclab_tree and speclab_seed.
- **Subsets.** The new-style lanes use tiny explicit subsets: exec gets one fixture, cn_coverage
  gets `--only <row>`, ci_sweep and gcc_oracle get `--max 1`, and multi_tu gets a 2-file tree. The
  legacy lanes take no subset flag. **verify, libc_exec, libxml2_uri, bytes, immaculate and
  speclab run their FULL real corpus in every plant.** They set `PLANT_REAL_EXEC=1`: the stub runs
  the real engine and then changes the bytes or status afterwards.
- **Identical work.** Inside one sub-lane, every plant re-runs the same real engine invocations on
  the same inputs. Only the stub's change after the run differs. The control plants also repeat
  ladder rows A5 (libc_exec), B4 (verify) and B5 (immaculate), but through the stub.
- **Caps.**
  - Each engine call runs under `scripts/capped` at `CERB_TEST_MEM_MAX` (4G default) plus
    `timeout ${TIMEOUT_SECS}` (verify uses `timeout 30`).
  - B9 itself has no timeout. `release.py` applies `--lane-timeout`, default 3600 s.
- **Rebuilds.**
  - The plant env sets `SKIP_BUILD=1`. Six lanes ignore it: multi_tu, verify, bytes, libc_exec,
    libxml2_uri and immaculate. Each of their plants calls `build_cerberus` (dune) and
    `build_lean` (`capped lake build CerberusLean cerberus-lean`, a 399-job replay) and records
    driver-freshness stamps. That is 37 no-op builds per B9 run. They cost about 2–5 s each
    (MEASURED: the "pre" column for immaculate is 1.7–5.3 s).
  - The speclab lanes run `capped lake build speclab-test` and the `*-core-test` targets on every
    plant.
  - immaculate runs `libc_prep.sh --jsons` (which regenerates the 12 libc TU jsons) and two
    `lake env lean --run` probes on every plant. The probes are cheap: the "tail" column is
    1.3–3.0 s.

## 2. The run (MEASURED, verbatim)

Invocation: `scripts/ce /usr/bin/time -v python3 scripts/release.py --mode full --lane B9 --out .tmp/b9-profile/release`.
This is the same runner and environment pin (`NO_COLOR`, `TERM`, `CERB_OBSERVATION_DIR`,
`--out plants`) as the full ladder.

```
START 2026-10-08T08:30:50+00:00
 08:30:50 up 31 days, 17:06,  ? user,  load average: 13.34, 14.37, 18.95
32
END 2026-10-08T09:21:33+00:00 rc=0
 09:21:33 up 31 days, 17:57,  ? user,  load average: 17.90, 28.24, 25.79
PASSED B9 (3033.7s)
observation lane plants: 93/93 passed
	User time (seconds): 2354.20
	System time (seconds): 464.37
	Percent of CPU this job got: 92%
	Elapsed (wall clock) time (h:mm:ss or m:ss): 50:35.71
```

**Confounds.** Both inflate the wall-clock time. MEASURED unless marked:

1. **B9 was not the only heavy job on the box.** From about 08:45 a cerberus-sl Lean build was
   running (`.../cerberus-sl/.tmp/worktrees/s9-ns-closure`, about 25 `lean` processes).
   1-minute load over 219 samples taken every 30 s: min 14.0, median 21.5, peak 56.3. Memory
   PSI avg300 was some=6.1% / full=3.9%.
   - Effect on per-call cost, compared against isolated replays (§3): the immaculate Lean step
     cost about 0.37 s for a nolibc row and about 2.85 s for a libc row during the run. Isolated
     replays cost 0.09 s and 1.3 s.
   - [AGENT] Contention therefore inflated the engine-bound plants by about 1.5–3×.
2. **One-off cold build.** `speclab.control` took 268.5 s because the worktree's speclab package
   was stale. Its own `lake build speclab-test` compiled 294 jobs, for example
   `SpecLab.TreeRotCore (148s)`. In a full ladder, B6 builds this before B9 runs.
   - [AGENT] The steady-state equivalent of this run is about 3033.7 − 268.5 + 5 ≈ **2770 s
     under this contention**. That is consistent with the recent ladder figures of 2109–2752 s.

### Per-sub-lane totals (MEASURED; a plant's wall time runs from the birth of its case dir to its `stdout` write; the gaps between plants sum to 0.0 s)

```
== per-sub-lane totals (s)   [plants: 93; sum 3033.4; first-start->last-end 3033.4; inter-plant gaps 0.0]
  1647.9   54.3%  11 plants   149.8/plant  immaculate
   626.7   20.7%   5 plants   125.3/plant  libc_exec
   328.6   10.8%   6 plants    54.8/plant  verify
   271.7    9.0%   5 plants    54.3/plant  speclab        (268.5 of it = speclab.control's one-off cold lake build)
    65.9    2.2%   5 plants    13.2/plant  libxml2_uri
    18.7    0.6%   5 plants     3.7/plant  bytes
    18.0    0.6%   5 plants     3.6/plant  multi_tu
    12.8    0.4%   5 plants     2.6/plant  speclab_tree
     9.4    0.3%   5 plants     1.9/plant  speclab_list
     8.9    0.3%   5 plants     1.8/plant  speclab_seed
     8.2    0.3%   5 plants     1.6/plant  speclab_bytearr
     6.4    0.2%   5 plants     1.3/plant  speclab_divmod
     3.7    0.1%   9 plants     0.4/plant  exec
     3.6    0.1%   7 plants     0.5/plant  cn_coverage
     1.8    0.1%   5 plants     0.4/plant  ci_sweep
     1.1    0.0%   5 plants     0.2/plant  gcc_oracle
```

### Per-plant wall time, plants over 5 s (MEASURED, in serial order; the other 62 plants sum to 64.5 s)

```
     9.6  multi_tu.control
    56.9  verify.control
    54.1  verify.bytes
    55.2  verify.lean-exit2
    56.4  verify.descendant-oom
    53.5  verify.oracle-exit2
    52.4  verify.call-verdict-then-timeout
   114.3  libc_exec.control
   125.2  libc_exec.bytes
   115.4  libc_exec.lean-exit2
   108.1  libc_exec.descendant-oom
   163.6  libc_exec.oracle-exit2
    23.0  libxml2_uri.control
    23.0  libxml2_uri.bytes
     8.4  libxml2_uri.lean-exit2
     7.9  libxml2_uri.descendant-oom
   183.2  immaculate.control
   125.4  immaculate.bytes
   134.0  immaculate.lean-exit2
   140.7  immaculate.descendant-oom
   184.4  immaculate.oracle-exit2
   121.8  immaculate.crash-fuel
   157.7  immaculate.crash-garbage
   122.7  immaculate.crash-other
   172.2  immaculate.crash-model
   182.7  immaculate.crash-model-suffix
   123.2  immaculate.ambient-term
   268.5  speclab.control
     5.1  speclab_bytearr.control
     5.8  speclab_list.control
     8.7  speclab_tree.control
     5.3  speclab_seed.control
```

## 3. Breakdown

**Where the time goes in an immaculate plant** (MEASURED from the mtimes of the raw captures in
`immaculate.control`, 102 rows):

```
immaculate.control nolibc/argv 68 cases; cabs-json 7.6s (0.112/case), lean pipeline (json->.l) 8.0s (0.118/case), .l->.l.status 17.3s (0.254/case), codec x2 8.8s (0.129/case), oracle(+capped+opam) 5.8s (0.085/case)
immaculate.control libc 34 cases; cabs-json 6.1s (0.180/case), lean pipeline (json->.l) 47.4s (1.393/case), .l->.l.status 49.5s (1.455/case), codec x2 8.0s (0.236/case), oracle(+capped+opam) 18.8s (0.554/case)
```

- **The 34 libc-mode rows are about 71% of an immaculate plant** (about 130 of 183 s), although
  they are a third of the rows.
- I could not cleanly attribute the `.l -> .l.status` gap from timestamps. An isolated replay of
  the exact harness step (capped + timeout + stub + the first write in `verdict`) gives a gap of
  0.016–0.037 s (`micro-harness-step.txt`). [AGENT] The in-run gap is a stall under contention,
  not a cost built into the harness.

**The libc environment load is a fixed cost paid on every libc-mode Lean call** (MEASURED, isolated,
`micro-libc-fixed-cost.txt`):

```
trivial program, nolibc args: 33 ms/run
trivial program, libc args: 1274 ms/run
libc.core bytes 4188542
libc-tu json bytes 32299250
```

- Every libc-mode Lean call parses about 4 MB of Core and 32 MB of JSON before it executes
  anything.
- The capped + timeout + stub wrapper adds only about 0.02–0.09 s per call
  (`micro-libc-lean.txt`: direct 1.40–1.49 s against wrapped 1.45–1.51 s).
- MEASURED call count: B9 makes about 34×11 (immaculate) + 43×5 (libc_exec rows) + 5 (libxml2)
  ≈ **594 libc-mode Lean calls**.
- [AGENT] At about 1.24 s of fixed load each, that is **about 740 s of uncontended engine time,
  about 35–40% of uncontended B9, spent re-loading the same libc environment.**

**Engine time against harness overhead** ([AGENT], derived from the immaculate breakdown and the
isolated replays):

- Engine work (oracle exec + cabs-json + Lean, including the libc load) is about 60–70% of the
  heavy plants.
- Harness work is the rest:
  - two `python3 observations.py tokens` codec calls per row, about 0.12–0.24 s per row;
  - `opam exec` around each oracle call, about 25 ms (MEASURED `opam exec -- true`);
  - capped setup and teardown, about 30 ms;
  - the stub's Python start-up;
  - the per-plant no-op dune and lake builds.

**Serialisation.** All 93 plants run in series, but they are independent processes. Each one
writes to its own case dir and raw-observation dir. Two exceptions share state:

- The gcc_oracle plants rewrite the shared `outdir/gcc/zero.c`.
- The six lanes that ignore `SKIP_BUILD` run concurrent-unsafe `dune` and `lake` builds and
  write stamps into the shared tree.

The longest single plant is about 185 s (immaculate.oracle-exit2) when the cold speclab build is
excluded.

**Identical re-runs** (MEASURED by reading source and argvs). Every legacy-lane plant re-runs
byte-identical real engine work: 11× for immaculate (102 rows × 3 calls), 5× for libc_exec,
6× for verify, and 5× each for libxml2_uri, bytes and speclab. Of all the plants, only
`immaculate.ambient-term` deliberately changes the engine environment (`TERM`).

**When the cost grew** (MEASURED from git):

- `scripts/test_observation_lanes.py` has not changed since `a4d5214e5` (2026-09-08).
- LADDER records "18.3 minutes … at `de9f6d361`" (2026-09-06, 90 plants).
- Since then the corpora under the full-corpus plants grew:
  - immaculate `.c` files: 59 → 102. libc 27 → 34 and nolibc 29 → 65. Rows were added on
    09-15, 09-17, 09-20, 09-21, 09-28 (14), 09-29, 09-30 and 10-03.
  - `tests/libc_exec`: 12 → 43 rows.
- Each added row is paid once per plant: 11× and 5×.
- [AGENT] Corpus growth multiplied by the plant fan-out accounts for the move from about 18 to
  about 35–46 minutes. The driver itself did not change.

## 4. Options

Ranked by expected gain × low trust impact. None of them changes what any plant asserts.

**1. Plant-level task parallelism (a bounded worker pool).** Recommended. [AGENT]
- **What.** Run independent plants concurrently, with j about 4–8 workers. Print the results and
  write `report.json` in the fixed catalogue order, so the output stays deterministic.
- **Preconditions** (the data races that exist today):
  - Build once, up front: one `build_cerberus`/`build_lean` plus a freshness check of the real
    binaries (`REAL_ORACLE`/`REAL_LEAN`), then make the six lanes honour `SKIP_BUILD`.
    Caution: under an override, common.sh skips the freshness check for the overridden side. The
    per-plant `build_lean` is currently what keeps `REAL_LEAN` fresh, so the up-front check must
    replace it explicitly.
  - Give each gcc plant its own fixture directory.
  - Serialise or pre-run the speclab `lake build`s.
- **Expected gain.** Wall time ≈ max(sum/j, longest plant ≈ 185 s). That is about 2770/8 ≈ 350 s
  at j=8 and about 700 s at j=4 under similar contention. [AGENT] estimate.
- **Memory.** Bounded at j × 4G (`CERB_TEST_MEM_MAX`), so 32G at j=8, which fits the 32–48G box
  discipline.
- **Trust impact.** Low. Each plant keeps the same argv, environment, stub and acceptance
  predicate. The new risk is concurrency in the harness, which plant-tests and fixed-order
  reporting would contain.
- **Cost.** Shares CPU with other agents. Total CPU work is unchanged.

**2. Memoise identical real-engine runs within one B9 invocation (record/replay at the stub).** [AGENT]
- **What.** The stub already sits between the harness and the real engine. The first plant of
  each lane records (stdout, stderr, rc) under a key: full argv, cwd, the SHA-256 of every input
  file named in argv, and the environment variables that affect the engines (`TERM`, `NO_COLOR`,
  `LEAN_ABORT_ON_PANIC`, `CERB_INSTALL_PREFIX`, fuel/runtime). Later plants replay it before
  applying their own change.
- **Scope.** The cache lives in the plant outdir only and is never persisted across runs. Any
  miss falls through to a real run.
- **Expected gain** [AGENT]. It removes (n−1)/n of the engine share in the legacy lanes:
  - immaculate: about 10/11 × 65% × 1648 ≈ 970 s;
  - libc_exec: about 4/5 × 70% × 627 ≈ 350 s;
  - verify: about 5/6 × most of 329 s ≈ 200 s.
  - In total about 45–50% of B9 wall time **and CPU**. That matters on a shared box, and it
    combines with option 1.
- **Trust impact.** Low to moderate.
  - The plants are already non-evidence about semantics: the banner says so and the stub
    mediates every call.
  - The risk is an incomplete key. `ambient-term` must bypass replay, because its whole point is
    that ambient `TERM` must not reach the engines. The descendant-OOM and timeout kinds must
    still run their change on top of the replayed stream.
  - Needs its own plant: a mutated input file or environment must miss the cache.

**3. Tiering/sharding of the B9 row.** [AGENT]
- **(a) Sharding.** Expand the row into `B9.<lane>` through the LADDER brace syntax that
  `release.py` already supports (`--lane {exec,…}`).
  - Gain: no wall-time gain by itself. It gives per-sub-lane timing and failure locality in
    every ladder report, and it gives `release.py` units it could later dispatch in parallel.
  - Trust impact: none.
- **(b) Change-triggered tiering.** Run the legacy-lane plants only when a harness file changes
  (`common.sh`, `observations.{sh,py}`, `capped`, `test_<lane>.sh`).
  - Gain: large.
  - Trust impact: moderate. It changes *when* this evidence is collected, and the trigger set has
    to be conservative. [AGENT] I do not recommend it as the first move.

**4. A plant-subset corpus for the legacy lanes (sampling).** [AGENT]
- **What.** Give immaculate, libc_exec, verify and libxml2 an explicit `--only` subset in plant
  mode, as cn_coverage, ci_sweep, gcc and exec already have. Choose at least one row per section
  (nolibc, argv, libc, exhaustive, the in-Lean probes) and per verdict class (VAL, UB, ERR with
  embedded quotes, CRASH, KILL).
- **Expected gain.** The largest: B9 would probably take about 5–8 minutes.
- **Trust impact.** Moderate.
  - Each lane needs new code for subset-aware baseline comparison. That code touches the
    fail-closed baseline comparison of the real rows.
  - Rows outside the subset no longer cross the stub path in B9. They are still run for real by
    A5/B4/B5.
  - It weakens per-row coverage of the harness, which the brief forbids unless the row selection
    is argued complete. So it ranks last.

**Outside B9's scope, worth recording.** The fixed libc-load cost of about 1.24 s per libc-mode
Lean call (§3) is paid on every libc row in every lane (A5, B5, B7 and others as well as B9).
Memoising the parsed libc environment inside the engine (a serialised or compacted environment,
or several programs per process) would speed up the whole ladder. It is a change to the product
loader, though, with a higher trust impact. It needs its own design pass. [AGENT]

## 5. Recommendation [AGENT]

Do **option 1 (plant-level parallelism)**, with its preconditions:

- one up-front build and freshness check of `REAL_ORACLE`/`REAL_LEAN`;
- `SKIP_BUILD` honoured in the six lanes;
- a private gcc fixture per plant;
- deterministic reporting.

It keeps every plant's assertion byte-for-byte the same, and it should bring B9 from about
35–46 minutes down to about 6–12 minutes. Sharding (option 3a) is a cheap companion for
per-lane accounting.

If B9's CPU cost on the shared box remains a concern, option 2 (memoising identical runs within
one invocation) is the next step. Option 4 is not recommended without an argued
coverage-preserving row selection.

## Evidence files (in this directory)

- `release.console` — the runner's console output and the `/usr/bin/time -v` output.
- `load.log`, `loadsamples.log` — `uptime` at start and end, `nproc`, and `/proc/loadavg` every 30 s.
- `analysis.txt` — per-plant and per-lane totals and the immaculate breakdowns, derived from
  timestamps.
- `B9-stdout.txt` — the verbatim output of B9.
- `micro-libc-lean.txt`, `micro-harness-step.txt`, `micro-libc-fixed-cost.txt` — the isolated
  micro-measurements.
- The full raw evidence (1.7G) is in
  `worktrees/cerberus-lean-lane/pnvi-symbolic-rows/.tmp/b9-profile/release/`. It is ephemeral
  and can be deleted.
