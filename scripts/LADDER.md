# The test ladder (arc-6 S4; decision [AGENT:S4], see the arc-6 decision log)

Three documented tiers. "The fast ladder" and "the slow ladder" below are
the normative meanings of those phrases in charters, decision logs, and
merge checklists from arc 6 on. Every command runs from the repo root;
every gating command must exit 0.

`python3 scripts/release.py --mode fast` executes Tier A; `--mode full`
executes Tier A+B. `--list` prints the command IDs parsed directly from the
tables below. A `--lane ID` selection is explicitly a subset, never a full
tier certification. The CI entry is `bash scripts/ci_lean.sh` (full by
default), after loading the project-scoped opam/Lean/Git environment.

The runner retains raw logs, source/build identities and a versioned report
under `.tmp/release/` (or a fresh `--out` directory). Missing commands,
timeouts, changed source and ambient binary/freshness overrides prevent a
green certification. A completed tier and a customer-ready release are
separate claims; unrun reporting/adoption/audit obligations remain visible.
Reporting requires explicit `--mode reporting --lane ID` selections and
writes proposed scoreboard/baseline artifacts into the report directory.
Follow current ownership: the legacy csmith run is excluded from this
charter's dispatch. No automatic reporting campaign follows a full run.

## Tier A — fast ladder (every commit / worker boundary claim)

Order is the conventional run order; all are fail-closed gates.

| # | Command | Bar |
|---|---------|-----|
| 1 | `./scripts/test_unit.sh` | 7/7 exes (incl. 280 parser tests + pp-test + `fuel-exemplar-test` + C-TF1's `monadic-failstop-test`) + sync gate + axiom censuses/cones (incl. the boundary-opaque population pin + the FUEL contract-lemma cones) + `check_sorry_token.sh` (comment-stripped `sorry`-token census, 0) + `test_fuel_classifier.sh` (FUEL classifier selftest) + exec-purity/totality + lem-sync + fork-drift gate (`check_fork_drift.sh` — oracle-surface manifest + hash-pinned generated-OCaml deltas) + fixture-freeze (`check_fixture_freeze.sh` — the corpus/ hash manifest) + native stream-capture probes (stable signal, binary stderr, and genuine stderr nondeterminism) + the renumber-instrument plant battery (`test_renumber_plants.sh` RIDES this row: it is invoked by test_unit.sh, not run separately) + the failure-reach register gate (`check_failure_reach.sh --selftest` + gate, 2026-09-08 — also Tier B row 11) |
| 2 | `./scripts/test_exec.sh --check-baseline` | tests/minimal vs `scripts/exec_baseline.txt`, rc 0 |
| 3 | `./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage` | rc 0 (recorded DIFFs unchanged) |
| 4 | `./scripts/test_exec.sh --check-baseline=scripts/exec_debug_baseline.txt tests/debug` | rc 0 |
| 4b | `./scripts/test_exec.sh --check-baseline=scripts/exec_float_baseline.txt tests/float` | rc 0 (69/69 MATCH baseline, arc-10 S3b; oracle-indicting caveat in the baseline header) |
| 4c | `./scripts/test_bytes.sh` | rc 0 — 9/9 exec files at the COMMITTED `.exec` expecteds (oracle-independent reference) + 5/5 front-end-reject pins (arc-10 S3b; script header has the leg semantics) |
| 5 | `./scripts/test_libc_exec.sh` | all MATCH recorded baseline (`tests/libc_exec/baseline.txt`) |
| 6 | `./scripts/test_multi_tu.sh` | all corpus entries pass |
| 7 | `./scripts/test_parse.sh` | tests/minimal 100% (FUEL arc budget commit, 2026-09-03: Lean side runs `--pp-core` — front end, NO execution — under a fail-noisy per-file timeout; the 10^6 fuel ceiling had been this lane's implicit bound. Nonzero Lean exits are classified REJECTED (printed verdict) / INTERNAL_ERROR_EXPECTED (failwithI on `*.error.c`, oracle-mirrored) / LEAN_FAILURE (fatal) — never `ok`) |
| 8 | `./scripts/test_core.sh` | tests/minimal 100% (078 is GREEN since arc-6 S1 — any red is a regression) |
| 9 | `./scripts/test_elab.sh` | recorded same/diff state, rc 0 |
| 10 | `./scripts/test_libxml2_uri.sh` | **GATING since arc-6 S4** (charter success condition 1): 16/16 byte-identical LEAN_LIBC vs ORACLE_LIBC + pinned per-lane expectations + baseline drift check (`tests/libxml2/uri_baseline.txt`), fail-closed both directions |
| 11 | `./scripts/test_cn_coverage.sh --check-baseline` | CN-corpus coverage lane (arc/cn-coverage, 2026-08-22): 213/213 `deps/cn/tests/cn` files compared vs the oracle (S5f verdict-sequence semantics + REJECT lane, multi-TU drivers, fail-closed manifest bijection) at the exact-match `tests/cn_coverage/baseline.txt` (fail-closed both directions). **Tier A rationale:** measured wall time ~27 s warm (sequential, small programs) — cheaper than the exec-baseline suites that dominate this tier; its sensitivity surface (exec semantics, multi-TU linking, libc proxies) is per-commit surface, and the corpus is external real-world-shaped code |

Measured wall time (arc-6 S4, warm builds): ~4-5 min for the full tier
on the reference machine (the exec baseline suites dominate; the uri
gate itself is ~1 min once both binaries are built). Cold builds add
whatever dune+lake need.

## Tier B — slow ladder (slice boundaries, close-out certification, pre-merge)

Everything in Tier A, plus the rows below. `scripts/release.py --mode full`
executes this membership; `test_unit.sh` also bundles the codec and runner's
small hermetic plants. The tables are the executable membership authority.

| # | Command | Bar |
|---|---------|-----|
| 1 | `./scripts/test_libxml2.sh` | full chvalid battery, 4 slices × (1354-point set), byte-equal verdicts both sides + oracle == `tests/libxml2/chvalid_baseline.txt`; ~8 min |
| 2 | `./scripts/test_parse.sh tests/ci` | 100% (`--pp-core` + per-file timeout since the FUEL arc budget commit — see Tier A row 7) |
| 3 | `./scripts/test_core.sh tests/ci` | at recorded state (all parse) |
| 4 | `./scripts/test_verify.sh` | fixture differentials (tests/verify + corpus/): pin provenance + main-mode + call-point oracle-differentials, 0 failed |
| 5 | `./scripts/test_immaculate.sh` | at baseline |
| 6 | `./scripts/test_speclab.sh --selftest` + `--plant`; `./scripts/test_speclab_{divmod,bytearr,list,tree,seed}.sh --gate` | all PASS (harness-family differential lanes; sweep/fuzz modes are reporting-tier extras) |
| 7 | `./scripts/test_gcc_oracle.sh --check-baseline` | **GATE since 2026-09-02 [USER 2026-09-02]** (born reporting-tier 2026-08-30; design `lean_frontend/docs/2026-08-30_gcc-second-oracle-design.md`): the gcc SECOND-oracle lane over tests/minimal + debug + float + immaculate/nolibc + the staged csmith tier, rc 0 vs the 1,963-row skip ledger `scripts/gcc_oracle_baseline.txt` + the fail-closed triage ledger `scripts/gcc_oracle_triage.txt`. Asymmetric by audited design (VALIDATION.md §2): any DISAGREE or regression is fatal; improvements print loudly at rc 0 and are re-recorded in a dedicated instrument commit. ~24 min wall (csmith tier incl.) — Tier B, never Tier A. Load caveat: the TIMEOUT-class rows are wall-clock sensitive (TIMEOUT_SECS=30; the slowest csmith rows hand-time at ~17 s on a quiet box, and a busy box — load ≈12 at the 2026-09-02 audit — pushed one over) — a REGRESSION whose only movement is into SKIP_LEAN_TIMEOUT is re-run on a quiet box before it is read as red; no code change. |
| 8 | `./scripts/test_hang_plant.sh`; `./scripts/test_kill_plant.sh`; `./scripts/test_fuel_plant.sh`; `./scripts/test_failstop_plant.sh` | plant batteries for the harness failure CLASSIFICATIONS (mem-scale S0/S2; FUEL arc 2026-09-03): a sleeping Lean-driver stub must read HANG and a busy-looping one TIMEOUT in test_exec.sh + test_ci_sweep.sh; a 5 GiB-resident stub must read each capped harness's own KILL class (exit 137 + capped's OOM-KILLED witness); a stub printing the fuel-exhaustion kill / panic must read FUEL (`FUEL` / `SKIP_LEAN_FUEL` / `LEAN_FUEL` / measure.sh `FUEL(kill|panic)`) in every classifying lane and a genuine `Error {msg: "assert() failure"}` stub must NOT. C-TF1 plants require validated `ModelFailure` captures to retain the crash classes and ordinary Error text to remain outside them. Loud plant banner on every run; rc 0 |
| 9 | `python3 scripts/test_observation_lanes.py` | Real entry-point plants for exec, multi-TU, CN, CI, GCC, verify, bytes, libc-exec, URI, immaculate and all six spec-lab scripts: positive controls, same-value byte differences, original failure statuses, CN refusal text and genuine native exit 137; descendant-OOM witnesses at successful exits, UB_DIFF denominator/default/new-baseline rejection, and immaculate fuel/garbage/unreviewed-panic rejection. Explicit reference projections are retained. Measured 18.3 minutes in the repaired 90-case run at `de9f6d361`, dominated by repeated real verify/immaculate pipelines; Tier B because this repeats full pipelines under controlled mutations. |
| 10 | `python3 scripts/test_upstream_oracle.py` + `--plant` | Pristine source `b9aeedcb4` built with upstream Lem `3802cb0`, compared with fork OCaml: applicable Tier A C inputs plus representative CLI/library interfaces, full raw records, reviewed diagnostic differences and a real unexpected-verdict plant. Requires a checked independent build manifest (`CERB_INDEPENDENT_MANIFEST`); missing provenance fails. About two minutes warm plus roughly one minute for the separate cold-build recipe. **PREREQUISITE (not built by the lane or by `release.py`):** the prepared independent build — `scripts/ce python3 scripts/build_independent_oracle.py --lem-repo <lem-lean checkout> --cerberus-repo <cerberus-lean checkout> --out .validation-foundations/independent-oracle-v2` (~50 s–1 min; the output directory must be new) — whose `manifest.json` the lane reads from that default path or from `CERB_INDEPENDENT_MANIFEST`. Without a valid built manifest the lane FAILS CLOSED (no build, no skip, no vacuous pass); recipe and review: `lean_frontend/docs/2026-09-06_independent-oracle-and-fork-pins.md`. |
| 11 | `./scripts/check_failure_reach.sh --selftest`; `./scripts/check_failure_reach.sh` | **The failure-reach register gate** (fuel-pending close-out 2026-09-08, option C of the pure-failure reachability census `lean_frontend/docs/2026-09-07_pure-failure-reachability-census.md`; the TRIPWIRE the parked twin design `…/2026-09-07_pure-failure-correspondence-design.md` names): rebuilds the one-module declaration-dependency instrument `tests/failure-probes/FailureReach.lean` as a fresh scratch Lake package (~6 s, ~1.8 GB, capped), takes the census (`scripts/failure_census.py`) and requires every PURE failure site of the exec dependency closure (231) + every pure site with an unresolved owner (2) to equal a row of `scripts/failure_reach_register.txt` — same position class (the census's classifier `scripts/failure_position.py`), reviewed reach class (166 UNREACHABLE-BY-INVARIANT / 48 REACHABLE / 17 UNKNOWN + the 2 unresolved as UNKNOWN), sealed rows, both directions; a NEW site, a stale row, a moved position class, a DISCARDABLE generated let-binding (the F1 shape — today 0) or an unsealed class edit is RED naming the rows. `--selftest` plants five cases on scratch copies. Also runs inside `test_unit.sh` (Tier A row 1) since its cost is unit-scale; listed here as its own certification row per the close-out brief. rc 0 |

**Battery placement decision [AGENT:S4]:** `test_libxml2.sh` was
out-of-ladder in arc 5 (~35 min, 28 slices). After the arc-6 S3
consolidation (~8 min, 4 slices) it JOINS the ladder — but in Tier B,
not Tier A: 8 minutes would roughly double the per-commit gate, and the
battery's sensitivity surface (exec semantics, memory model, map
representations, the lem pin) is exactly the slice-boundary surface.
Any change touching those seams should run Tier B even mid-slice.
Debug aid: a single slice (`./scripts/test_libxml2.sh
chvalid_battery_00`, ~2.5 min) is a useful smoke between full runs but
is NOT a certification substitute.

## Tier C — reporting instruments (committed numbers, NOT gates)

These produce committed scoreboards; their numbers move only by a
deliberate re-record with justification in a commit/doc. They do not
block a merge by themselves.

| Command | Artifact |
|---------|----------|
| `./scripts/test_exec.sh --write-baseline=scripts/exec_ci_baseline.txt tests/ci` | tests/ci exec differential scoreboard (arc-6 S4 rider; see `lean_frontend/docs/2026-08-19_arc6-s4-ci-scoreboard.md`). NOTE: default-mode exit is nonzero while known mismatches exist — the artifact is the baseline file, not the exit code. A CHECK against this baseline (`--check-baseline=scripts/exec_ci_baseline.txt tests/ci`) may be used as a no-regression probe, but tier-C status means running it is optional, not part of certification. |
| `./scripts/fuzz_csmith.sh` | csmith differential fuzzing (csmith + creduce installed locally since arc-10; lane portfolio + deterministic seed ranges: `lean_frontend/docs/2026-08-20_arc10-s4-csmith-campaign.md`) |
| `./scripts/test_csmith_corpus.sh --check-baseline` | 1669-file in-tree csmith corpus lane vs `scripts/exec_csmith_corpus_baseline.txt` (arc-10 S4; classified baseline). At `928aa1e76` the baseline has NO MISMATCH/DIFF/UB_DIFF row: 1161 MATCH, 499 `CERB_SKIP` (oracle-side, Lean not reached) and 9 `TIMEOUT` (derived tallies from the file; the 2026-08-22 header narrates the arc-13 re-baseline and is the per-row history). Under the zero-discrepancy rule (VALIDATION.md §1) the TIMEOUT rows are class-(b) pending per-row completion evidence, never agreement. Full pass ~2.7 h: run `--shard K/6` sharded (shard-aware fail-closed baseline check, arc-10 S5). Reporting-tier: full pass at close-out/pre-merge boundaries, spot shard otherwise. Load caveat (fuel-measure-cost landing, 2026-09-08): the TIMEOUT rows are wall-clock sensitive at `TIMEOUT_SECS=15`; a TIMEOUT row observed completing NEAR the budget (`sia_csmith_169.c`, 14.94 s wall on a quiet box) is NOT re-recorded MATCH — a MATCH pin that times out under load is a FATAL regression while a TIMEOUT pin that completes is a non-fatal reported improvement — so a TIMEOUT → MATCH re-record needs a clear margin under the budget, repeated on a quiet box, with the `uptime` load recorded |
| `./scripts/test_ci_sweep.sh --all-suites` | full-upstream-CI-sweep scoreboard (ci-sweep stream, 2026-08-22): differential sweep of the big heterogeneous corpora under tests/ (gcc-torture breakdown classes, ci, tcc, suite, pnvi, hacl-star, freebsd, examples) with checkpointed per-corpus TSVs committed under `tests/ci_sweep/results/` (15 TSVs). Enforces NO baseline, exits 0 unless the harness itself breaks; the committed TSVs move only by a deliberate re-record (TODO.md registers the pending one) |
| `python3 scripts/measure_csmith_cpu.py --output .tmp/csmith-cpu.tsv` | **NON-GATING** per-input/per-engine `input, engine, exit, wall_s, cpu_s, maxrss_kb, status` TSV, plus `.meta.txt` with identities, timeout, uptime load and verbatim lane verdicts. Runs the existing corpus lane with `--check-baseline`, retaining its GNU time records at cleanup; staging, engine arguments and classifications are the lane's own. Requires fresh built binaries (`SKIP_BUILD=1`); all runs under `scripts/capped`, `CERB_MEM_MAX=48G`, default 15 s per engine. `--timeout N`, `--shard K/M`, `--max N` pass through (`--max 470` selects small_arrays); `--repo DIR` uses that checkout's oracle, Lean and lane. Every input has two rows; an unexecuted Lean side has `NA` resources and exit, and both rows carry the joint lane status. CPU is user+system with GNU time's 0.01 s precision. Export integrity is checked against saved and printed lane statuses; exit 0 certifies export, not baseline agreement. `--selftest` checks known rusage and real CPU/skip/timeout stubs; `--collect RUN_DIR --output NEW.tsv` exports an already completed run. Outputs must be new; no baseline writes. |

### Instruments (neither gates nor scoreboards)

Runnable artifacts kept so that recorded claims stay reproducible. They
have no baseline, no tier, no wiring; running one produces evidence for
a record, never a pass/fail for the tree.

| Path | What |
|------|------|
| `tests/parity-probes/` | the parity-detective lane (2026-08-30): `run_probe.sh` single-file differential runner + `probes/*.c` beyond-testset probes + the `sweep-2026-08-30/` TSVs; every claim of `lean_frontend/docs/2026-08-30_parity-detective-report.md` has a runnable artifact here |
| `tests/mem-scale-probes/` | the memory-scale arc's probe corpus (`gen_probes.sh`, `measure.sh`, `run_all.sh`, `summarize.py`, `probes/`, `results/`) and `micro/` — a THIRD Lake package (`memscale-micro`, own `lakefile.toml` + `lake-manifest.json`, requires CerberusLean by path, shares the workspace package store) timing CerbMem byte-path primitives in isolation. Measurement only; the third manifest is registered in TODO.md's package-set-pin item |
| `tests/csmith_findings/` | the arc-10 S4 csmith campaign's committed reproducer artifacts (all ORACLE-side findings) with regeneration recipes; index in its README |

## Conventions

* Baseline updates are instrument changes: never silent, always a
  dedicated commit with justification (house rule since arc 4).
* Per-invocation resource caps on libxml2-sized inputs: per-test
  `scripts/capped` with `CERB_MEM_MAX=4G` (cgroup RSS) + timeout —
  [USER 2026-09-02] ("Q2 agree"), SUPERSEDING the arc-5 operator
  directive `ulimit -v 4000000`. Why: `ulimit -v` limits VIRTUAL
  address space, and Lean's virtual footprint is ~2–3.6× its RSS, so
  the old cap killed Lean at ~1.7 GB RSS while the oracle ran to
  3.1 GB (record: `lean_frontend/docs/2026-09-01_mem-scale-profile.md`
  §2; ruling: `docs/2026-09-01_mem-scale-design.md` §0/Q2). MIGRATED
  (mem-scale S2, 2026-09-02): all 22 `ulimit -v` sites — 20 code sites
  + 2 header comments, derived tally — in the seven
  harnesses (`test_ci_sweep`, `test_libc_exec`, `test_libxml2`,
  `test_libxml2_uri`, `test_immaculate`, `test_gcc_oracle`,
  `tests/parity-probes/run_probe.sh`) now run each test under
  `scripts/common.sh`'s `CAPPED_TEST` (`scripts/capped`,
  `CERB_TEST_MEM_MAX`, default 4G); a cap breach has capped's positive
  OOM witness (the cgroup's `memory.events oom_kill` counter), even when
  a surviving parent exits 0 or 1. It is never agreement; GCC explicitly
  accounts for its native-side exclusion. A bare 137 remains subject to
  each protocol's status rules and is not itself an OOM witness. Plant:
  `scripts/test_kill_plant.sh`.
  Baselines re-derived in the dedicated instrument commit recorded in
  `lean_frontend/docs/2026-09-02_mem-scale-record.md` §S2.
* Close-out certification = Tier B green + Tier C artifacts current +
  the arc's charter-specific bars (see the arc merge checklist).
