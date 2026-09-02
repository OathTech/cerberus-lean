# The test ladder (arc-6 S4; decision [AGENT:S4], see the arc-6 decision log)

Three documented tiers. "The fast ladder" and "the slow ladder" below are
the normative meanings of those phrases in charters, decision logs, and
merge checklists from arc 6 on. Every command runs from the repo root;
every gating command must exit 0.

## Tier A — fast ladder (every commit / worker boundary claim)

Order is the conventional run order; all are fail-closed gates.

| # | Command | Bar |
|---|---------|-----|
| 1 | `./scripts/test_unit.sh` | 5/5 exes (incl. 280 parser tests + pp-test) + sync gate + axiom censuses/cones + exec-purity/totality + lem-sync + fork-drift gate (`check_fork_drift.sh` — oracle-surface manifest + hash-pinned generated-OCaml deltas) + fixture-freeze (`check_fixture_freeze.sh` — the corpus/ hash manifest) |
| 2 | `./scripts/test_exec.sh --check-baseline` | tests/minimal vs `scripts/exec_baseline.txt`, rc 0 |
| 3 | `./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage` | rc 0 (recorded DIFFs unchanged) |
| 4 | `./scripts/test_exec.sh --check-baseline=scripts/exec_debug_baseline.txt tests/debug` | rc 0 |
| 4b | `./scripts/test_exec.sh --check-baseline=scripts/exec_float_baseline.txt tests/float` | rc 0 (69/69 MATCH baseline, arc-10 S3b; oracle-indicting caveat in the baseline header) |
| 4c | `./scripts/test_bytes.sh` | rc 0 — 9/9 exec files at the COMMITTED `.exec` expecteds (oracle-independent reference) + 5/5 front-end-reject pins (arc-10 S3b; script header has the leg semantics) |
| 5 | `./scripts/test_libc_exec.sh` | all MATCH recorded baseline (`tests/libc_exec/baseline.txt`) |
| 6 | `./scripts/test_multi_tu.sh` | all corpus entries pass |
| 7 | `./scripts/test_parse.sh` | tests/minimal 100% |
| 8 | `./scripts/test_core.sh` | tests/minimal 100% (078 is GREEN since arc-6 S1 — any red is a regression) |
| 9 | `./scripts/test_elab.sh` | recorded same/diff state, rc 0 |
| 10 | `./scripts/test_libxml2_uri.sh` | **GATING since arc-6 S4** (charter success condition 1): 16/16 byte-identical LEAN_LIBC vs ORACLE_LIBC + pinned per-lane expectations + baseline drift check (`tests/libxml2/uri_baseline.txt`), fail-closed both directions |
| 11 | `./scripts/test_cn_coverage.sh --check-baseline` | CN-corpus coverage lane (arc/cn-coverage, 2026-08-22): 213/213 `deps/cn/tests/cn` files compared vs the oracle (S5f verdict-sequence semantics + REJECT lane, multi-TU drivers, fail-closed manifest bijection) at the exact-match `tests/cn_coverage/baseline.txt` (fail-closed both directions). **Tier A rationale:** measured wall time ~27 s warm (sequential, small programs) — cheaper than the exec-baseline suites that dominate this tier; its sensitivity surface (exec semantics, multi-TU linking, libc proxies) is per-commit surface, and the corpus is external real-world-shaped code |

Measured wall time (arc-6 S4, warm builds): ~4-5 min for the full tier
on the reference machine (the exec baseline suites dominate; the uri
gate itself is ~1 min once both binaries are built). Cold builds add
whatever dune+lake need.

## Tier B — slow ladder (slice boundaries, close-out certification, pre-merge)

Everything in Tier A, plus:

| # | Command | Bar |
|---|---------|-----|
| 1 | `./scripts/test_libxml2.sh` | full chvalid battery, 4 slices × (1354-point set), byte-equal verdicts both sides + oracle == `tests/libxml2/chvalid_baseline.txt`; ~8 min |
| 2 | `./scripts/test_parse.sh tests/ci` | 100% |
| 3 | `./scripts/test_core.sh tests/ci` | at recorded state (all parse) |
| 4 | `./scripts/test_verify.sh` | fixture differentials (tests/verify + corpus/): pin provenance + main-mode + call-point oracle-differentials, 0 failed |
| 5 | `./scripts/test_immaculate.sh` | at baseline |
| 6 | `./scripts/test_speclab.sh --selftest` + `--plant`; `./scripts/test_speclab_{divmod,bytearr,list,tree,seed}.sh --gate` | all PASS (harness-family differential lanes; sweep/fuzz modes are reporting-tier extras) |

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
| `./scripts/test_csmith_corpus.sh --check-baseline` | 1669-file in-tree csmith corpus lane vs `scripts/exec_csmith_corpus_baseline.txt` (arc-10 S4; classified baseline — 15 DIFF are the F-D fork-oracle class, see baseline header). Full pass ~2.7 h: run `--shard K/6` sharded (shard-aware fail-closed baseline check, arc-10 S5). Reporting-tier: full pass at close-out/pre-merge boundaries, spot shard otherwise |

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
  `CERB_TEST_MEM_MAX`, default 4G); a cap breach is exit 137 + capped's
  OOM-KILLED witness banner (the cgroup's `memory.events oom_kill`
  counter) and every harness classifies it as its own KILL class (never
  agreement, never a skip; a bare 137 keeps its crash class); plant:
  `scripts/test_kill_plant.sh`.
  Baselines re-derived in the dedicated instrument commit recorded in
  `lean_frontend/docs/2026-09-02_mem-scale-record.md` §S2.
* Close-out certification = Tier B green + Tier C artifacts current +
  the arc's charter-specific bars (see the arc merge checklist).
