# The test ladder (arc-6 S4; decision [AGENT:S4], see the arc-6 decision log)

Three documented tiers. "The fast ladder" and "the slow ladder" below are
the normative meanings of those phrases in charters, decision logs, and
merge checklists from arc 6 on. Every command runs from the repo root;
every gating command must exit 0.

## Tier A — fast ladder (every commit / worker boundary claim)

Order is the conventional run order; all are fail-closed gates.

| # | Command | Bar |
|---|---------|-----|
| 1 | `./scripts/test_unit.sh` | 4/4 exes (incl. 280 parser tests) + sync gate + census + exec-purity/totality + theorem-axiom cones |
| 2 | `./scripts/test_exec.sh --check-baseline` | tests/minimal vs `scripts/exec_baseline.txt`, rc 0 |
| 3 | `./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage` | rc 0 (recorded DIFFs unchanged) |
| 4 | `./scripts/test_exec.sh --check-baseline=scripts/exec_debug_baseline.txt tests/debug` | rc 0 |
| 5 | `./scripts/test_libc_exec.sh` | all MATCH recorded baseline (`tests/libc_exec/baseline.txt`) |
| 6 | `./scripts/test_multi_tu.sh` | all corpus entries pass |
| 7 | `./scripts/test_parse.sh` | tests/minimal 100% |
| 8 | `./scripts/test_core.sh` | tests/minimal 100% (078 is GREEN since arc-6 S1 — any red is a regression) |
| 9 | `./scripts/test_elab.sh` | recorded same/diff state, rc 0 |
| 10 | `./scripts/test_libxml2_uri.sh` | **GATING since arc-6 S4** (charter success condition 1): 16/16 byte-identical LEAN_LIBC vs ORACLE_LIBC + pinned per-lane expectations + baseline drift check (`tests/libxml2/uri_baseline.txt`), fail-closed both directions |

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
| `./scripts/fuzz_csmith.sh` | csmith fuzzing (network/upstream-gated, see script header) |

## Conventions

* Baseline updates are instrument changes: never silent, always a
  dedicated commit with justification (house rule since arc 4).
* Per-invocation resource caps on libxml2-sized inputs: `ulimit -v
  4000000` + timeout (operator directive, arc 5) — the harnesses apply
  these themselves.
* Close-out certification = Tier B green + Tier C artifacts current +
  the arc's charter-specific bars (see the arc merge checklist).
