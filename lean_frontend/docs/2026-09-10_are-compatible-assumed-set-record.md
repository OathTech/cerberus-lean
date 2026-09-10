# `are_compatible_aux` assumed-compatible accumulator — stopped before D1

[AGENT 2026-09-10] **STOP: the untouched Tier A baseline fails in the
Driver auxiliary-proof axiom gate, outside this charter's file fence.**
No implementation change was made. D1–D5 are not delivered.

Charter: [2026-09-10_codex-charter-are-compatible-assumed-set.md](2026-09-10_codex-charter-are-compatible-assumed-set.md).
Worktree: `/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/are-compatible-assumed-set`.
Branch: `arc/are-compatible-assumed-set`.
Starting head: `b80415165f402fea462a7f58f2f56a59ccadc0ac`, clean;
its parent is `86daea264`.

The charter was read in full before other work, followed by its §5 reading
list. All commands used the designated worktree and sourced
`/home/dev/projects/cerberus-lean-proj/scripts/env.sh`. The baseline used
`CERB_MEM_MAX=48G`, `DUNE_CACHE=disabled`, the existing capped Lean/Lake
invocations, and one heavy job at a time. No primary-checkout build, edit,
or commit, no Lem/dependency edit, and no merge, push, or rebase occurred.

## Baseline attempt and the stop rule

Before any implementation or documentation edit, the command was:

```sh
source /home/dev/projects/cerberus-lean-proj/scripts/env.sh
export CERB_MEM_MAX=48G DUNE_CACHE=disabled
python3 scripts/release.py --mode fast --lane-timeout 3300 \
  --out .tmp/are-compatible-assumed-set/baseline-fast
```

The run started at `20260910T050806.235120Z`. A1's seven executable tests
passed, but its axiom gate failed. These are distinct results: the complete
unit command exited 1. A2 and A3 completed while the failure was being
inspected; A4 had started when the owned runner was stopped with SIGTERM.
The runner caught that signal and cleaned its active command containment.
The exact argv and worktree cwd were checked before signaling PID 2190724.
No other process was targeted.

Charter §3 requires a stop when:

> a gate is red for a reason outside the fence

The implicated `scripts/check_theorem_axioms.sh`, Driver auxiliary module,
and Driver proof module are outside the allowed compatibility-source
surface. This is not D1's explicitly permitted changed-ctype fork-drift
failure: `ctype_aux.lem` was still untouched. No gate bypass or artifact
repair was attempted after the stop. The charter's stop disposition takes
precedence over continuing the remaining baseline commands or starting the
pristine-oracle build.

Verbatim lane/gate output, with `===` headers and `rc=` lines transcribed
from the runner's command receipts:

```text
=== A1 ./scripts/test_unit.sh
rc=1 status=failed
Total: 7 passed, 0 failed
.axiom-probe-fuel.lean:27:14: error(lean.unknownIdentifier): Unknown constant `hack_measure_sufficient`
.axiom-probe-fuel.lean:28:14: error(lean.unknownIdentifier): Unknown constant `Driver_lemMeasureProofs.hack_measure_sufficient`
check_theorem_axioms: FAIL — FUEL arc leg: probe for 'hack_measure_sufficient' did not run cleanly (matched 0 lines; fail-closed)
test_unit: axiom-cone gate FAILED
=== A2 ./scripts/test_exec.sh --check-baseline
rc=0 status=passed
Baseline check: 0 regression(s), 0 improvement(s)
=== A3 ./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage
rc=0 status=passed
Baseline check: 0 regression(s), 0 improvement(s)
=== A4 ./scripts/test_exec.sh --check-baseline=scripts/exec_debug_baseline.txt tests/debug
rc=-9 status=incomplete
```

The runner's final summary is verbatim:

```text
fast: incomplete; 2/13 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

`Complete tier selection` describes the selected catalogue, not successful
completion. The runner process exited 1. Its report finished at
`2026-09-10T05:10:01.551583+00:00`, records `interrupted_signal = 15`,
`status = incomplete`, `source_unchanged = true`, and `artifact_issues = []`.
Source identities are clean and equal before/after, and external-input
inventories compare equal. Every recorded command has
`containment_cleaned = true`; all four recorded cgroups were absent when
checked. All eight stdout/stderr hashes match their raw captures.

| Lane | Recorded seconds | Status | Exit |
|---|---:|---|---:|
| A1 | 21.064 | failed | 1 |
| A2 | 28.670 | passed | 0 |
| A3 | 51.806 | passed | 0 |
| A4 | 12.503 | incomplete, deliberately stopped | -9 |

No baseline file changed. The two completed differential baseline lanes
report zero movement; nothing is claimed for the interrupted or unrun
lanes. No one-hour tripwire fired.

## Read-only diagnosis: source and primed artifacts disagree

Both theorem declarations exist in this worktree's source:

- `lean_frontend/Driver_lemMeasureProofs.lean:75` defines the hand-written
  `hack_measure_sufficient` theorem in `Driver_lemMeasureProofs`.
- `lean_frontend/generated/Driver_auxiliary.lean:6` imports that module,
  and `:40` defines the generated `hack_measure_sufficient` obligation.
- `frontend/model/driver.lem:1927` still declares the measured `hack`.
- `scripts/check_theorem_axioms.sh:859` asks for both constants; its probe
  explicitly imports `Driver_auxiliary` at `:890` and runs via
  `scripts/capped lake env lean` at `:896`.

The existing compiled artifacts differ from that source state:

| Worktree-relative path | Observed state |
|---|---|
| `lean_frontend/generated/Driver_auxiliary.lean` | 2151 bytes; SHA-256 `d8779db6754d348c745753a2925890606e9ba53e1cd4c6e1d616d8d032a39681` |
| `lean_frontend/.lake/build/lib/lean/Driver_auxiliary.olean` | 1816 bytes; SHA-256 `79e9d8918bb814d338b0c23e20ff0c93bb5cd89b23eece1934af1ff2d6628a95` |
| `lean_frontend/.lake/build/lib/lean/Driver_auxiliary.trace` | Its input/import list omits `Driver_lemMeasureProofs`; it records the earlier primary-checkout build paths copied into this worktree. |
| `lean_frontend/generated/Driver_lemMeasureProofs.lean` | 4683 bytes; SHA-256 `a04c35f36c60db99e04b9c9cfac7f947c8247969eab3bc10996cdac0487754a8` |
| `lean_frontend/.lake/build/lib/lean/Driver_lemMeasureProofs.olean` | Missing |
| `lean_frontend/.lake/build/lib/lean/Driver_lemMeasureProofs.trace` | Missing |

[AGENT inference] The evidence points to stale/incomplete primed auxiliary
proof artifacts, not absent theorem source. The copied trace's import set
does not match the current generated module. The exact priming/build
mechanism that produced this state was not established, and no repaired
baseline is claimed. Reading a copied trace containing primary-checkout
paths did not execute or read files at those paths.

## Evidence and orchestrator handoff

The [evidence directory](2026-09-10_are-compatible-assumed-set-evidence/)
contains plain-text A1 stdout/stderr, the runner console, extracted verdicts,
a compact receipt with artifact hashes and command statuses, and the copied
Driver auxiliary trace. It totals 31,547 bytes (derived filesystem tally),
below the charter's 1 MB limit. Full raw lane captures and the schema-2
runner report remain in `.tmp/are-compatible-assumed-set/baseline-fast/`.
Full report SHA-256:
`25657329f42480910b6a63c8758c511604952641f4c3b58320ad6953c5d8af1a`.
The compact committed receipt is an explicit projection of that report,
not a replacement full report or a green certification.

Outstanding work, in order, if the orchestrator resumes the charter:

1. Establish fresh auxiliary proof artifacts in this worktree and a clean
   untouched baseline. The full default Lake build under the specified
   48 GiB cap is a candidate repair to assess; it was not tried here.
   Rerun the full Tier A and the separately requested direct unit command.
2. Build the pristine oracle using charter §1's exact command. It was not
   attempted; `.validation-foundations/independent-oracle-v2/manifest.json`
   remains absent.
3. Execute D1–D5 in charter order. No accumulator edit, regeneration,
   measure/proof, reproducer run, CPU experiment, fork refresh, new corpus
   row, tray update, or full Tier B run has been performed. The `.lem` diff
   is empty. There are no D1–D5 commits to review.

Questions for the orchestrator, recorded rather than asked interactively:

- Why did priming provide an old Driver auxiliary object and omit the
  Driver proof object although both source declarations are present?
  Which build/priming check should establish the corrected baseline before
  this charter is resumed?
- D1 acceptance (c) requests three paths in `git diff --stat`, but
  `git ls-files frontend/model/ctype_aux.lem ocaml_frontend/generated/ctype_aux.ml lean_frontend/generated/Ctype_aux.lean`
  lists only `frontend/model/ctype_aux.lem` here; both generated trees are
  untracked build outputs. Should D1 record the generated-file deltas and
  hashes separately while committing only tracked source? Nothing was
  force-added and no ignore rule was changed.

This commit contains only the stop record and its evidence. The branch is
stopped for orchestrator review under §3; no merge, push, or rebase.
