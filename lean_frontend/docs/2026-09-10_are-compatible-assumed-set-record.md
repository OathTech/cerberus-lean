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


## Resumption at `f7e631dca` — second stop during D1

[AGENT 2026-09-10] **Current disposition: STOP during D1 acceptance (a).
The accumulator is implemented and both engines build, but the prescribed
reproducer now fails in `Core_eval.PEmemberof` instead of returning
`Specified(7)`. This is outside the charter's file fence. D1 is not accepted;
D2–D5 have not started.** The original stop section above is preserved as
history; charter §6 resolved both of its questions.

Resumption started from `f7e631dcae6cbfc2ba34e7ac68fc8c16c925736b`, clean,
on the same branch and worktree. The amended charter, including §6, was
read before resuming. The earlier §5 reading was retained and the source,
build helpers, reproducer, and relevant gate details were rechecked.
No merge, push, or rebase occurred. No files in the primary checkout,
`lem-lean`, or `deps/` were changed or built. The two repository arguments
to the pristine build were read-only git-archive sources, exactly as §1
requires; all its compilation and installation occurred under this
worktree's owned `.validation-foundations/independent-oracle-v2/`.

### Untouched resumed baseline — green

Before the first source edit, both requested commands completed:

```sh
source /home/dev/projects/cerberus-lean-proj/scripts/env.sh
export CERB_MEM_MAX=48G DUNE_CACHE=disabled
python3 scripts/release.py --mode fast --lane-timeout 3300 \
  --out .tmp/are-compatible-assumed-set/resumed-baseline-fast
./scripts/test_unit.sh
```

The direct unit command was wrapped with `/usr/bin/time -p` and
`timeout --kill-after=10s 3300s`. Lake/Lean calls used `scripts/capped`
with `CERB_MEM_MAX=48G`; only one heavy job ran at a time.

The release runner exited 0. Verbatim runner summary:

```text
fast: passed; 13/13 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

The runner's final certification sentence concerns separate
reporting/adoption/audit obligations; its selected Tier A status is
`passed`, 13/13. Start: `20260910T052355.815474Z`; finish:
`2026-09-10T05:30:45.970362+00:00`. Source identities were equal and clean
before/after, external-input inventories were equal, `artifact_issues`
was empty, and every command reported containment cleaned. All 26 saved
stdout/stderr hashes were verified against the report. Full report SHA-256:
`409a90414c1860843d2ff514453a1075db8a4ad9ba5e2b6eb6b3471c26cfc4f8`.

Verbatim verdict lines below; `===` and `rc/status/elapsed` labels are
transcribed from the runner receipts, not invented lane output:

```text
=== A1 ./scripts/test_unit.sh
rc=0 status=passed elapsed=146.839s
Total: 7 passed, 0 failed
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
check_fuel_forms: forms partition OK (57 MEASURED + 13 ABSORBING + 5 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)
check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin f6542f8 = lem -v)
=== A2 ./scripts/test_exec.sh --check-baseline
rc=0 status=passed elapsed=29.269s
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
=== A3 ./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage
rc=0 status=passed elapsed=51.939s
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
=== A4 ./scripts/test_exec.sh --check-baseline=scripts/exec_debug_baseline.txt tests/debug
rc=0 status=passed elapsed=22.905s
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
=== A4b ./scripts/test_exec.sh --check-baseline=scripts/exec_float_baseline.txt tests/float
rc=0 status=passed elapsed=18.459s
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
=== A4c ./scripts/test_bytes.sh
rc=0 status=passed elapsed=3.233s
=== A5 ./scripts/test_libc_exec.sh
rc=0 status=passed elapsed=23.513s
=== A6 ./scripts/test_multi_tu.sh
rc=0 status=passed elapsed=2.332s
=== A7 ./scripts/test_parse.sh
rc=0 status=passed elapsed=9.895s
Total:          106
=== A8 ./scripts/test_core.sh
rc=0 status=passed elapsed=8.442s
Total:          106
=== A9 ./scripts/test_elab.sh
rc=0 status=passed elapsed=15.904s
=== A10 ./scripts/test_libxml2_uri.sh
rc=0 status=passed elapsed=17.309s
=== A11 ./scripts/test_cn_coverage.sh --check-baseline
rc=0 status=passed elapsed=58.83s
BASELINE OK (213 entries, exact match)
```

The separate unit invocation also passed. Its final resource/exit receipt
is verbatim:

```text
Total: 7 passed, 0 failed
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
check_fuel_forms: forms partition OK (57 MEASURED + 13 ABSORBING + 5 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)
check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin f6542f8 = lem -v)
real 145.20
user 104.35
sys 49.39
rc=0
```

After the unit receipt, the login shell printed
`/usr/bin/bash: line 3: /home/dev/.bash_logout: Permission denied`.
This was after `rc=0`, not a test failure. The nono sandbox skill was read;
`nono why --path /home/dev/.bash_logout --op read` reported `DENIED`,
`filesystem_deny`, with an explicit `/home/dev/.bash_logout` deny rule.
Later commands used non-login shells and still sourced the required
project environment. No sandbox configuration or hook was edited, and no
cgroup access failed. Access to this hook is unnecessary for the charter.
The skill's one-off restart grant / persistent profile-draft-and-promote
routes remain operator options if that separate hook ever needs access;
neither was needed or attempted here.

### Pristine prerequisite — built and identified

The prescribed command was run once, before the D1 edit, with the same
outer timing/3300-second tripwire wrapper:

```sh
/home/dev/projects/cerberus-lean-proj/scripts/ce python3 scripts/build_independent_oracle.py \
  --lem-repo /home/dev/projects/cerberus-lean-proj/lem-lean \
  --cerberus-repo /home/dev/projects/cerberus-lean-proj/cerberus-lean \
  --out .validation-foundations/independent-oracle-v2
```

Verbatim build output:

```text
cerberus-lean-proj env: switch=/home/dev/projects/cerberus-lean-proj/cerberus-lean/_opam, git redirects active
lem-compiler: passed (6.842s)
lem-libraries: passed (1.264s)
lem-runtime-build: passed (4.302s)
lem-runtime-install: passed (0.154s)
cerberus-generation: passed (19.91s)
cerberus-build: passed (9.572s)
Independent upstream oracle: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/are-compatible-assumed-set/.validation-foundations/independent-oracle-v2/manifest.json
real 43.94
user 59.33
sys 14.33
rc=0
```

The manifest status is `built`. Upstream Cerberus source is
`b9aeedcb4dd438763b0eef7f95ac19e93875d7de`; upstream Lem source is
`3802cb04b53d5f1096a464e51ecbfb2a750a7ccd`. Manifest SHA-256:
`3e7234cbece79960ebf6872a0e8b4cb802ed40865e550490431cccbfa25cf611`.
Oracle binary SHA-256:
`e21f6cf392cd180cab290ac2101ffd5b35d67581c68b1636479a65f52b6ea985`.
The manifest's `artifacts.oracle.path` and `artifacts.runtime.root` were
used directly for the reproducer. Its complete build report remains at
`.validation-foundations/independent-oracle-v2/manifest.json`; the evidence
contains a labeled compact projection with source and command receipts.

### D1 implementation and builds — partial work preserved

The environment is now `(tagDefs1, tagDefs2, assumed)`, with a list of tag
pairs, initialized to `[]` at the public entry. The local recursive helper
accepts the path list explicitly. Array, return-type, pointer, and atomic
comparisons pass the current list. The parameter siblings pass the whole
current environment unchanged. In both cross-TU tag arms, membership is
tested after the name test and before lookups. Both struct member sites
(ordinary and flexible array) and the union member site cons the current
pair. Siblings do not return or share additions. The three existing fuel
declarations are unchanged; no measure declaration or proof was added.

Before adding this record/evidence, `git diff --stat` was exactly:

```text
 frontend/model/ctype_aux.lem | 35 +++++++++++++++++++----------------
 1 file changed, 19 insertions(+), 16 deletions(-)
```

Both generated trees were changed only by their Make targets. Comparing
309 captured hashes (generated Lean/OCaml files and script baseline/pin
inputs) found exactly two changed generated files: `Ctype_aux.lean` and
`ctype_aux.ml`. No captured script baseline, hypothesis register, or fork
manifest changed. These hashes are retained in `d1-before-sha256.json`.
The generated files remain ignored build outputs; nothing was force-added.

Build order, each completed before the next started:

1. `opam exec --switch=. -- make prelude-src`.
2. `source scripts/common.sh; build_cerberus` (worktree-local build/install
   and oracle freshness recording).
3. `make lean-prelude-src`.
4. From `lean_frontend/`, `../scripts/capped lake build CerberusLean cerberus-lean`.
5. `tools/check_driver_fresh.sh --record-lean`, then `--check`.

The four build commands had independent 3300-second outer timeouts; none
approached the one-hour tripwire. Verbatim exit/resource tails:

```text
=== d1-prelude.log
real 19.84
user 19.53
sys 0.31
rc=0
=== d1-oracle-build.log
real 7.59
user 20.09
sys 4.54
rc=0
=== d1-lean-prelude.log
real 19.55
user 19.23
sys 0.34
rc=0
=== d1-lean-build.log
Build completed successfully (388 jobs).
real 41.18
user 123.60
sys 7.85
rc=0
```

Verbatim freshness evidence:

```text
check_driver_fresh: recorded lean stamp (bin cb15a4e21b883d2a36d304e709638b25c23118055bcfdbd2b008aaf4fd2b09cf, src 818c0bdc23fec568b581a610a01d6a1e5a75b04e5e893800ab88d06cedd0aaba)
check_driver_fresh: oracle OK (bin 36f2fce36439c08c261fb34b6b8f79582fa23be6e4ac9b61f759b39e7fa6984e, src 5d57b951d111dc372af3625e6f81c72554be129eefc22db1b5fb57d71715926e)
check_driver_fresh: lean OK (bin cb15a4e21b883d2a36d304e709638b25c23118055bcfdbd2b008aaf4fd2b09cf, src 818c0bdc23fec568b581a610a01d6a1e5a75b04e5e893800ab88d06cedd0aaba)
```

[AGENT] The intended compatibility argument is local to this block:
once equal qualifiers and equal cross-TU tag names have passed, a
successful table hop's member-comparison subtree is fixed by the two
unchanged tables and the tag pair. Its member qualifiers come from the
definitions, not the outer qualifiers. On an original evaluation that
returns a Boolean, a repeated successful pair on an active recursion path
would restart the same subtree indefinitely. Thus no such pair recurs on
an originally returning path; the added membership branch never fires
there, and all original tests/results and their order remain the same.
The existing error branches are retained; this is not a claim that every
malformed input returns a Boolean instead of raising an error.

For termination, each recursive descent into looked-up members adds a
previously absent pair. The two finite tables supply only finitely many
tag pairs, and recursion between those hops descends through finite type
syntax and parameter lists. Because additions are path-local, sibling
checks cannot incorrectly discharge one another. This is the D1 design
argument, not a completed kernel sufficiency proof: that proof and the
measure belong to D2, which has not started. Nor does termination of this
block establish successful execution of the whole C reproducer: the next
section records the newly exposed failure.

### D1 acceptance (a) — failure outside the fence

The original failure-probe files were used unchanged and in the prescribed
`node_a.c`, `node_b.c` order. Each source was converted with the fork
oracle's `--cabs-json` into ignored scratch JSON before the Lean run;
both bridge commands exited 0. Lean used `LEAN_ABORT_ON_PANIC=1` and no
fuel override. All engine runs used `timeout --kill-after=5s 60s`.
Exact engine commands, raw stdout/stderr, and measured exit/elapsed lines:

```text
=== fork-oracle
$ timeout --kill-after=5s 60s /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/are-compatible-assumed-set/_build/default/backend/driver/main.exe --runtime=/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/are-compatible-assumed-set/_build/install/default --nolibc --exec --batch --mode=exhaustive /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/are-compatible-assumed-set/tests/failure-probes/cross_tu_node/node_a.c /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/are-compatible-assumed-set/tests/failure-probes/cross_tu_node/node_b.c
[stdout]
Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(531, SD_Id("node")) vs Symbol(502, SD_Id("node"))'"}
[stderr]
Time spent: 0.024507 seconds
rc=1 elapsed=0.036015s
```

```text
=== lean
$ timeout --kill-after=5s 60s /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/are-compatible-assumed-set/lean_frontend/.lake/build/bin/cerberus-lean --batch /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/are-compatible-assumed-set/.tmp/are-compatible-assumed-set/d1-reproducer/node_a.json /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/are-compatible-assumed-set/.tmp/are-compatible-assumed-set/d1-reproducer/node_b.json
[stdout]
Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(48, SD_Id("node")) vs Symbol(19, SD_Id("node"))'"}
[stderr — empty]
rc=1 elapsed=0.031220s
```

```text
=== pristine-oracle
$ timeout --kill-after=5s 60s /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/are-compatible-assumed-set/.validation-foundations/independent-oracle-v2/cerberus/_build/default/backend/driver/main.exe --runtime=/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/are-compatible-assumed-set/.validation-foundations/independent-oracle-v2/cerberus/_build/install/default --nolibc --exec --batch --mode=exhaustive /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/are-compatible-assumed-set/tests/failure-probes/cross_tu_node/node_a.c /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/are-compatible-assumed-set/tests/failure-probes/cross_tu_node/node_b.c
[stdout — empty]
[stderr — empty]
rc=124 elapsed=60.073402s
```

The fork run failed the scratch harness's explicit expected-verdict
assertion. Its saved log includes that Python `AssertionError`; this is
the acceptance assertion reacting to the engine's `rc=1`, not an engine
Python crash. The remaining bridge/Lean/pristine runs were completed only
as bounded diagnosis of this failure. They did not run concurrently with
any build or lane.

[AGENT] The original non-termination is no longer the observed fork/Lean
outcome on this reproducer. Both now complete unsuccessfully with
`PEmemberof(struct) ==> mismatched tags`. Their messages have different
internal symbol numbers and are quoted separately; this is **not** a
MATCH verdict and is **not** `Specified(7)`. The pristine oracle remains
non-completing at the specified 60-second bound (`rc=124`, empty output).

Read-only localization:

- `frontend/model/core_aux.lem:198-205`: the struct-valued store invokes
  `Ctype_aux.are_compatible`; a successful comparison returns a memory
  struct value under the destination tag.
- `frontend/model/core_eval.lem:941-952`: after evaluating the operand of
  `PEmemberof`, the `Vobject (OVstruct tag_sym' xs)` arm requires exact tag
  equality. Its `tag_sym <> tag_sym'` branch emits the exact observed
  `Illformed_program` message at line 946, before member lookup.
- The prescribed `node_b.c` ends in `return ident(n).v;`: it directly
  selects a member of a struct returned across the TU boundary.

[AGENT inference] The accumulator lets execution reach a separate
cross-TU struct-result/member-selection problem. The exact semantic
remedy—such as where a returned aggregate should be converted to its
caller's type, or whether this operation should compare compatible
struct types—has not been established. Changing the compatibility
predicate alone cannot repair the direct exact-tag check while preserving
this charter's prescribed algorithm. `core_eval.lem` and the return/value
conversion machinery are outside the allowed surface. Neither was edited,
and neither reproducer nor expected verdict was weakened to manufacture
acceptance.

Charter §3's operative stop rule is:

> a gate is red for a reason outside the fence

D1 acceptance (a) is that red gate. Accordingly no post-edit Tier A/direct
unit pass was started, no D2 work was begun, and no later deliverable was
attempted. The green results above are explicitly the untouched baseline,
not validation of the edited tree. D1 acceptance (b) is unrun; acceptance
(c)'s source/generated accounting is recorded here, but D1 as a whole
remains incomplete. The changed source/semantic fork pins have not been
refreshed; D4's authorized refresh was not reached. No existing baseline
file or corpus row was re-recorded, and no post-edit baseline agreement is
claimed. No one-hour tripwire fired.

### D1 source and generated diffs

The `.lem` diff is verbatim:

```diff
diff --git a/frontend/model/ctype_aux.lem b/frontend/model/ctype_aux.lem
index 4bfddfb5c..6aa05c28c 100644
--- a/frontend/model/ctype_aux.lem
+++ b/frontend/model/ctype_aux.lem
@@ -84,9 +84,9 @@ declare ocaml target_rep function reset_tagDefs = `Tags.reset_tagDefs`
 
 
 
-val     are_compatible_aux: (map Symbol.sym (Loc.t * tag_definition) * map Symbol.sym (Loc.t * tag_definition)) -> (qualifiers * ctype) -> (qualifiers * ctype) -> bool
-let rec are_compatible_aux ((tagDefs1, tagDefs2) as env) (qs1, Ctype _ ty1) (qs2, Ctype _ ty2) =
-  let are_compatible_aux qs_ty1 qs_ty2 = are_compatible_aux (tagDefs1, tagDefs2) qs_ty1 qs_ty2 in
+val     are_compatible_aux: (map Symbol.sym (Loc.t * tag_definition) * map Symbol.sym (Loc.t * tag_definition) * list (Symbol.sym * Symbol.sym)) -> (qualifiers * ctype) -> (qualifiers * ctype) -> bool
+let rec are_compatible_aux ((tagDefs1, tagDefs2, assumed) as env) (qs1, Ctype _ ty1) (qs2, Ctype _ ty2) =
+  let are_compatible_aux assumed qs_ty1 qs_ty2 = are_compatible_aux (tagDefs1, tagDefs2, assumed) qs_ty1 qs_ty2 in
   (* qualifiers need to be equal (see §6.7.3#10) *)
   qs1 = qs2 && match (ty1, ty2) with
     | (Void, Void) ->
@@ -95,7 +95,7 @@ let rec are_compatible_aux ((tagDefs1, tagDefs2) as env) (qs1, Ctype _ ty1) (qs2
         AilTypesAux.are_compatible (qs1, Ctype [] (Basic bty1)) (qs2, Ctype [] (Basic bty2))
     | (Array elem_ty1 n1_opt, Array elem_ty2 n2_opt) ->
         (* STD §6.7.6.2#6 *)
-           are_compatible_aux (no_qualifiers, elem_ty1) (no_qualifiers, elem_ty2)
+           are_compatible_aux assumed (no_qualifiers, elem_ty1) (no_qualifiers, elem_ty2)
         && match (n1_opt, n1_opt) with
              | (Just n1, Just n2) -> n1 = n2
              | (Just _ , Nothing) -> true
@@ -105,12 +105,12 @@ let rec are_compatible_aux ((tagDefs1, tagDefs2) as env) (qs1, Ctype _ ty1) (qs2
     | (Function (ret_qs1, ret_ty1) params1 isVariadic1, Function (ret_qs2, ret_ty2) params2 isVariadic2) ->
         (* STD §6.7.6.3#15 *)
         (* TODO: when the two types do not both have a param list *)
-           are_compatible_aux (ret_qs1, ret_ty1) (ret_qs2, ret_ty2)
+           are_compatible_aux assumed (ret_qs1, ret_ty1) (ret_qs2, ret_ty2)
         && are_compatible_params env params1 params2
         && isVariadic1 = isVariadic2
     | (Pointer ref_qs1 ref_ty1, Pointer ref_qs2 ref_ty2) ->
         (* STD §6.7.6.1#2 *)
-        are_compatible_aux (ref_qs1, ref_ty1) (ref_qs2, ref_ty2)
+        are_compatible_aux assumed (ref_qs1, ref_ty1) (ref_qs2, ref_ty2)
     | (Struct tag1, Struct tag2) ->
         (* STD §6.2.7#1 *)
         (* TODO: being conservative here (aka STD compliant) *)
@@ -125,6 +125,7 @@ let rec are_compatible_aux ((tagDefs1, tagDefs2) as env) (qs1, Ctype _ ty1) (qs2
                   error "Ctype_aux.are_compatible_aux: failed to destruct a struct tag"
             end in
           if tag_str1 = tag_str2 then
+            if List.elem (tag1, tag2) assumed then true else
             match (Map.lookup tag1 tagDefs1, Map.lookup tag2 tagDefs2) with
               | (Nothing, Nothing) ->
                   true
@@ -137,13 +138,13 @@ let rec are_compatible_aux ((tagDefs1, tagDefs2) as env) (qs1, Ctype _ ty1) (qs2
                     false
                   else
                     List.all (fun ((ident1, (_, _(*TODO alignment*), qs1, ty1)), (ident2, (_, _(*TODO alignment*), qs2, ty2))) ->
-                      ident1 = ident2 && are_compatible_aux (qs1, ty1) (qs2, ty2)
+                      ident1 = ident2 && are_compatible_aux ((tag1, tag2) :: assumed) (qs1, ty1) (qs2, ty2)
                     ) (List.zip xs1 xs2) &&
                     match (flexible_opt1, flexible_opt2) with
                       | (Nothing, Nothing) ->
                           true
                       | (Just (FlexibleArrayMember _ ident1 qs1 ty1), Just (FlexibleArrayMember _ ident2 qs2 ty2)) ->
-                          ident1 = ident2 && are_compatible_aux (qs1, ty1) (qs2, ty2)
+                          ident1 = ident2 && are_compatible_aux ((tag1, tag2) :: assumed) (qs1, ty1) (qs2, ty2)
                       | _ ->
                           false
                     end
@@ -167,6 +168,7 @@ let rec are_compatible_aux ((tagDefs1, tagDefs2) as env) (qs1, Ctype _ ty1) (qs2
                   error "Ctype_aux.are_compatible_aux: failed to destruct a union tags"
             end in
           if tag_str1 = tag_str2 then
+            if List.elem (tag1, tag2) assumed then true else
             match (Map.lookup tag1 tagDefs1, Map.lookup tag2 tagDefs2) with
               | (Nothing, Nothing) ->
                   true
@@ -179,7 +181,7 @@ let rec are_compatible_aux ((tagDefs1, tagDefs2) as env) (qs1, Ctype _ ty1) (qs2
                     false
                   else
                     List.all (fun ((ident1, (_, _(*TODO alignment*), qs1, ty1)), (ident2, (_, _(*TODO alignment*), qs2, ty2))) ->
-                      ident1 = ident2 && are_compatible_aux (qs1, ty1) (qs2, ty2)
+                      ident1 = ident2 && are_compatible_aux ((tag1, tag2) :: assumed) (qs1, ty1) (qs2, ty2)
                     ) (List.zip xs1 xs2)
               | _ ->
                   error "Ctype_aux.are_compatible_aux: failed to lookup a union definition"
@@ -187,7 +189,7 @@ let rec are_compatible_aux ((tagDefs1, tagDefs2) as env) (qs1, Ctype _ ty1) (qs2
           else
             false
     | (Atomic atom_ty1, Atomic atom_ty2) ->
-        are_compatible_aux (no_qualifiers, atom_ty1) (no_qualifiers, atom_ty2)
+        are_compatible_aux assumed (no_qualifiers, atom_ty1) (no_qualifiers, atom_ty2)
     | _ ->
         (* TODO: we can't see Enum types here and there is some impl-def stuff *)
         false
@@ -220,7 +222,7 @@ let are_compatible qs_ty1 qs_ty2 =
     end
   ) (tagDefs ()) Map.empty in *)
   let tagDefs = tagDefs () in
-  are_compatible_aux (tagDefs, tagDefs) qs_ty1 qs_ty2
+  are_compatible_aux (tagDefs, tagDefs, []) qs_ty1 qs_ty2
 
 (*
 val tags_are_compatible: Symbol.sym -> Symbol.sym -> bool
@@ -275,11 +277,12 @@ let match_integer_ctype (Ctype _ ty_) =
 
 (* === Totality declares (arc 3 sweep, 2026-08-18): Lean-target only.
    are_compatible_aux / are_compatible_params_aux / are_compatible_params
-   form a genuinely cyclic mutual family whose recursion goes through
-   tagDefs map lookups (member types fetched from the environment), not
-   subterms -> fuel all three (all-or-none for mutual blocks). Return
-   type is bool: the witness only discharges typing; honesty lives in
-   the fuelExhausted runtime panic. === *)
+   form a mutual family bounded by the finite set of tag pairs in the
+   two tagDefs maps and structural descent between map lookups. The
+   path-local assumed-compatible list prevents repeated tag-pair hops.
+   Fuel all three (all-or-none for mutual blocks); the bool witnesses
+   only discharge typing, with fuelExhausted preserving the runtime
+   panic until the sufficiency measures are supplied. === *)
 declare {lean} fuel val are_compatible_aux = `fuelExhausted false`
 declare {lean} fuel val are_compatible_params_aux = `fuelExhausted (fun _ => false)`
 declare {lean} fuel val are_compatible_params = `fuelExhausted false`
```

Generated OCaml unified before/after diff (before snapshot taken prior to
any source edit):

```diff
--- before/ocaml_frontend/generated/ctype_aux.ml
+++ after/ocaml_frontend/generated/ctype_aux.ml
@@ -72,9 +72,9 @@
 
 
 
-(*val     are_compatible_aux: (map Symbol.sym (Loc.t * tag_definition) * map Symbol.sym (Loc.t * tag_definition)) -> (qualifiers * ctype) -> (qualifiers * ctype) -> bool*)
-let rec are_compatible_aux (((tagDefs1, tagDefs2) as env1)) (qs1, Ctype( _, ty1)) (qs2, Ctype( _, ty2)):bool=
-   (let are_compatible_aux1 qs_ty1 qs_ty2=  (are_compatible_aux (tagDefs1, tagDefs2) qs_ty1 qs_ty2) in qualifiersEqual
+(*val     are_compatible_aux: (map Symbol.sym (Loc.t * tag_definition) * map Symbol.sym (Loc.t * tag_definition) * list (Symbol.sym * Symbol.sym)) -> (qualifiers * ctype) -> (qualifiers * ctype) -> bool*)
+let rec are_compatible_aux (((tagDefs1, tagDefs2, assumed) as env1)) (qs1, Ctype( _, ty1)) (qs2, Ctype( _, ty2)):bool=
+   (let are_compatible_aux1 assumed qs_ty1 qs_ty2=  (are_compatible_aux (tagDefs1, tagDefs2, assumed) qs_ty1 qs_ty2) in qualifiersEqual
   (* qualifiers need to be equal (see Â§6.7.3#10) *)
   qs1 qs2 && (match (ty1, ty2) with
     | (Void, Void) ->
@@ -83,7 +83,7 @@
         AilTypesAux.are_compatible (qs1, Ctype( [], (Basic bty1))) (qs2, Ctype( [], (Basic bty2)))
     | (Array( elem_ty1, n1_opt), Array( elem_ty2, n2_opt)) ->
         (* STD Â§6.7.6.2#6 *)
-           are_compatible_aux1 (no_qualifiers, elem_ty1) (no_qualifiers, elem_ty2)
+           are_compatible_aux1 assumed (no_qualifiers, elem_ty1) (no_qualifiers, elem_ty2)
         && (match (n1_opt, n1_opt) with
              | (Some n1, Some n2) -> Nat_big_num.equal n1 n2
              | (Some _ , None) -> true
@@ -93,12 +93,12 @@
     | (Function( (ret_qs1, ret_ty1), params1, isVariadic1), Function( (ret_qs2, ret_ty2), params2, isVariadic2)) ->
         (* STD Â§6.7.6.3#15 *)
         (* TODO: when the two types do not both have a param list *)
-           are_compatible_aux1 (ret_qs1, ret_ty1) (ret_qs2, ret_ty2)
+           are_compatible_aux1 assumed (ret_qs1, ret_ty1) (ret_qs2, ret_ty2)
         && (are_compatible_params0 env1 params1 params2
         && (isVariadic1 = isVariadic2))
     | (Pointer( ref_qs1, ref_ty1), Pointer( ref_qs2, ref_ty2)) ->
         (* STD Â§6.7.6.1#2 *)
-        are_compatible_aux1 (ref_qs1, ref_ty1) (ref_qs2, ref_ty2)
+        are_compatible_aux1 assumed (ref_qs1, ref_ty1) (ref_qs2, ref_ty2)
     | (Struct tag1, Struct tag2) ->
         (* STD Â§6.2.7#1 *)
         (* TODO: being conservative here (aka STD compliant) *)
@@ -124,6 +124,10 @@
                   Cerb_debug.error "Ctype_aux.are_compatible_aux: failed to destruct a struct tag"
             )) in
           if tag_str1 = tag_str2 then
+            if Lem_list.elem 
+  (instance_Basic_classes_Eq_tup2_dict
+     Symbol.instance_Basic_classes_Eq_Symbol_sym_dict
+     Symbol.instance_Basic_classes_Eq_Symbol_sym_dict) (tag1, tag2) assumed then true else
             (match (Pmap.lookup tag1 tagDefs1, Pmap.lookup tag2 tagDefs2) with
               | (None, None) ->
                   true
@@ -136,13 +140,13 @@
                     false
                   else
                     List.for_all (fun ((ident1, (_, _(*TODO alignment*), qs1, ty1)), (ident2, (_, _(*TODO alignment*), qs2, ty2))) -> Symbol.idEqual
-                      ident1 ident2 && are_compatible_aux1 (qs1, ty1) (qs2, ty2)
+                      ident1 ident2 && are_compatible_aux1 ((tag1, tag2) :: assumed) (qs1, ty1) (qs2, ty2)
                     ) (Lem_list.list_combine xs1 xs2) &&
                     (match (flexible_opt1, flexible_opt2) with
                       | (None, None) ->
                           true
                       | (Some (FlexibleArrayMember( _, ident1, qs1, ty1)), Some (FlexibleArrayMember( _, ident2, qs2, ty2))) -> Symbol.idEqual
-                          ident1 ident2 && are_compatible_aux1 (qs1, ty1) (qs2, ty2)
+                          ident1 ident2 && are_compatible_aux1 ((tag1, tag2) :: assumed) (qs1, ty1) (qs2, ty2)
                       | _ ->
                           false
                     )
@@ -177,6 +181,10 @@
                   Cerb_debug.error "Ctype_aux.are_compatible_aux: failed to destruct a union tags"
             )) in
           if tag_str1 = tag_str2 then
+            if Lem_list.elem 
+  (instance_Basic_classes_Eq_tup2_dict
+     Symbol.instance_Basic_classes_Eq_Symbol_sym_dict
+     Symbol.instance_Basic_classes_Eq_Symbol_sym_dict) (tag1, tag2) assumed then true else
             (match (Pmap.lookup tag1 tagDefs1, Pmap.lookup tag2 tagDefs2) with
               | (None, None) ->
                   true
@@ -189,7 +197,7 @@
                     false
                   else
                     List.for_all (fun ((ident1, (_, _(*TODO alignment*), qs1, ty1)), (ident2, (_, _(*TODO alignment*), qs2, ty2))) -> Symbol.idEqual
-                      ident1 ident2 && are_compatible_aux1 (qs1, ty1) (qs2, ty2)
+                      ident1 ident2 && are_compatible_aux1 ((tag1, tag2) :: assumed) (qs1, ty1) (qs2, ty2)
                     ) (Lem_list.list_combine xs1 xs2)
               | _ ->
                   Cerb_debug.error "Ctype_aux.are_compatible_aux: failed to lookup a union definition"
@@ -197,7 +205,7 @@
           else
             false
     | (Atomic atom_ty1, Atomic atom_ty2) ->
-        are_compatible_aux1 (no_qualifiers, atom_ty1) (no_qualifiers, atom_ty2)
+        are_compatible_aux1 assumed (no_qualifiers, atom_ty1) (no_qualifiers, atom_ty2)
     | _ ->
         (* TODO: we can't see Enum types here and there is some impl-def stuff *)
         false
@@ -230,7 +238,7 @@
           error "Ctype_aux.are_compatible"
     end
   ) (tagDefs ()) Map.empty in *)let tagDefs1 = (Tags.tagDefs ()) in
-  are_compatible_aux (tagDefs1, tagDefs1) qs_ty1 qs_ty2)
+  are_compatible_aux (tagDefs1, tagDefs1, []) qs_ty1 qs_ty2)
 
 (*
 val tags_are_compatible: Symbol.sym -> Symbol.sym -> bool
```

Generated `ocaml_frontend/generated/ctype_aux.ml` SHA-256 after regeneration:
`1f10d7093365ec467ca4b5d5f421a1643a31600291cb40713fa8795d5cab1d76`.

Generated Lean unified before/after diff:

```diff
--- before/lean_frontend/generated/Ctype_aux.lean
+++ after/lean_frontend/generated/Ctype_aux.lean
@@ -88,29 +88,29 @@
 /- removed value specification -/
 
 mutual
- def  are_compatible_params_aux0_lemFuel (lemFuel : Nat)  (env1 : (Fmap (sym) ((CerbLocation.Loc ×tag_definition)) ×Fmap (sym) ((CerbLocation.Loc ×tag_definition)))) (acc : Bool)  : (List ((qualifiers ×ctype ×Bool)) ×List ((qualifiers ×ctype ×Bool))) → Bool := match lemFuel with
+ def  are_compatible_params_aux0_lemFuel (lemFuel : Nat)  (env1 : (Fmap (sym) ((CerbLocation.Loc ×tag_definition)) ×Fmap (sym) ((CerbLocation.Loc ×tag_definition)) ×List ((sym ×sym)))) (acc : Bool)  : (List ((qualifiers ×ctype ×Bool)) ×List ((qualifiers ×ctype ×Bool))) → Bool := match lemFuel with
   | 0 => (fuelExhausted (fun _ => false))
   | Nat.succ lemFuel => (match env1, acc with |  env1,  acc => ( fun (x : (List ((qualifiers ×ctype ×Bool)) ×List ((qualifiers ×ctype ×Bool)))) =>  match x with  |  ([],  []) =>        acc |  (((qs1,  ty1,  _)  ::  params1), ( (qs2,  ty2,  _)  ::  params2)) => (are_compatible_params_aux0_lemFuel lemFuel)  env1  (         /-  STD (Â§6.7.6.3#15) the unqualified versions of the parameters types are compared  -/         acc  && (are_compatible_aux_lemFuel lemFuel)  env1  (no_qualifiers, ty1)  (no_qualifiers, ty2)       )  (params1, params2) |  _ =>        /-  the list of params must have the same length to be compatible  -/       false ) )
-def  are_compatible_params0_lemFuel (lemFuel : Nat)  (env1 : (Fmap (sym) ((CerbLocation.Loc ×tag_definition)) ×Fmap (sym) ((CerbLocation.Loc ×tag_definition)))) (params1 : List ((qualifiers ×ctype ×Bool))) (params2 : List ((qualifiers ×ctype ×Bool)))  : Bool := match lemFuel with
+def  are_compatible_params0_lemFuel (lemFuel : Nat)  (env1 : (Fmap (sym) ((CerbLocation.Loc ×tag_definition)) ×Fmap (sym) ((CerbLocation.Loc ×tag_definition)) ×List ((sym ×sym)))) (params1 : List ((qualifiers ×ctype ×Bool))) (params2 : List ((qualifiers ×ctype ×Bool)))  : Bool := match lemFuel with
   | 0 => (fuelExhausted false)
   | Nat.succ lemFuel => (match env1, params1, params2 with |  env1,  params1,  params2 => (are_compatible_params_aux0_lemFuel lemFuel)  env1  true  (params1, params2) )
-def  are_compatible_aux_lemFuel (lemFuel : Nat)  (p : (Fmap (sym) ((CerbLocation.Loc ×tag_definition)) ×Fmap (sym) ((CerbLocation.Loc ×tag_definition)))) (p0 : (qualifiers ×ctype)) (p1 : (qualifiers ×ctype))  : Bool := match lemFuel with
+def  are_compatible_aux_lemFuel (lemFuel : Nat)  (p : (Fmap (sym) ((CerbLocation.Loc ×tag_definition)) ×Fmap (sym) ((CerbLocation.Loc ×tag_definition)) ×List ((sym ×sym)))) (p0 : (qualifiers ×ctype)) (p1 : (qualifiers ×ctype))  : Bool := match lemFuel with
   | 0 => (fuelExhausted false)
-  | Nat.succ lemFuel => (match p, p0, p1 with |   env1@((tagDefs1,  tagDefs2)),  (qs1,  Ctype  _  ty1),  (qs2,  Ctype  _  ty2) => ( let  are_compatible_aux1  := (fun (qs_ty1 : (qualifiers ×ctype)) (qs_ty2 : (qualifiers ×ctype)) => (are_compatible_aux_lemFuel lemFuel)  (tagDefs1, tagDefs2)  qs_ty1  qs_ty2);  qualifiersEqual    /-  qualifiers need to be equal (see Â§6.7.3#10)  -/   qs1  qs2  && ( match ty1,  ty2 with  | Void0,  Void0 =>          true | Basic  bty1,  Basic  bty2 =>          are_compatible  (qs1, Ctype  []  (Basic  bty1))  (qs2, Ctype  []  (Basic  bty2)) | Array0  elem_ty1  n1_opt,  Array0  elem_ty2  n2_opt =>          /-  STD Â§6.7.6.2#6  -/            are_compatible_aux1  (no_qualifiers, elem_ty1)  (no_qualifiers, elem_ty2)          && ( match n1_opt,  n1_opt with  | some  n1,  some  n2 =>  n1  ==  n2 | some  _,  none =>  true | none,  some  _ =>  true | none,  none =>  true            ) | Function  (ret_qs1,  ret_ty1)  params1  isVariadic1,  Function  (ret_qs2,  ret_ty2)  params2  isVariadic2 =>          /-  STD Â§6.7.6.3#15  -/         /-  TODO: when the two types do not both have a param list  -/            are_compatible_aux1  (ret_qs1, ret_ty1)  (ret_qs2, ret_ty2)          &&  ((are_compatible_params0_lemFuel lemFuel)  env1  params1  params2          &&  (isVariadic1  ==  isVariadic2)) | Pointer  ref_qs1  ref_ty1,  Pointer  ref_qs2  ref_ty2 =>          /-  STD Â§6.7.6.1#2  -/         are_compatible_aux1  (ref_qs1, ref_ty1)  (ref_qs2, ref_ty2) | Struct  tag1,  Struct  tag2 => (         /-  STD Â§6.2.7#1  -/         /-  TODO: being conservative here (aka STD compliant)  -/         if  from_same_translation_unit  tag1  tag2 then  match tag1,  tag2 with  | Symbol  d1  n1  sd1,  Symbol  d2  n2  sd2 => (         if  (CerberusFresh.digest_compare  d1  d2  == ( 0 :  Int))  &&  (n1  ==  n2) then            if  natGteb  (0) (  5)  &&  (sd1  !=  sd2) then              match  CerbDebug.print_debug_pure (  5)  []  (fun (u : Unit) =>  match u with |  () =>                 String.append "[Symbol.symbolEqual] suspicious equality ==> "                 (String.append (show_symbol_description  sd1)   (String.append " <-> "  (show_symbol_description  sd2))) ) with |   () =>              true             else              true          else            false)             else            match              match tag1,  tag2 with  | Symbol  _  _ ( SD_Id  tag_str1),  Symbol  _  _ ( SD_Id  tag_str2) =>                    (tag_str1, tag_str2) | _, _ => (failwithI  "Ctype_aux.are_compatible_aux: failed to destruct a struct tag" : (String ×String))              with |   (tag_str1,  tag_str2) => (           if  tag_str1  ==  tag_str2 then              match (fmapLookupBy  (fun (sym1 : sym) (sym2 : sym)=> ordCompare  sym1  sym2)  tag1  tagDefs1),  (fmapLookupBy  (fun (sym1 : sym) (sym2 : sym)=> ordCompare  sym1  sym2)  tag2  tagDefs2) with  | none,  none =>                    true | some  _,  none =>                    true | none,  some  _ =>                    true | some  (_,  StructDef  xs1  flexible_opt1),  some  (_,  StructDef  xs2  flexible_opt2) => (                   if  not  ((List.length  xs1)  ==  (List.length  xs2)) then                      false                    else                      List.all  (lemListZip  xs1  xs2)  (fun (p : (((identifier ×((attributes ×Option (alignment) ×qualifiers ×ctype)))) ×((identifier ×((attributes ×Option (alignment) ×qualifiers ×ctype)))))) =>  match p with |  ((ident1,  (_,  _/- TODO alignment -/,  qs1,  ty1)),  (ident2,  (_,  _/- TODO alignment -/,  qs2,  ty2))) =>  idEqual                        ident1  ident2  &&  are_compatible_aux1  (qs1, ty1)  (qs2, ty2)                      )  && (                     match flexible_opt1,  flexible_opt2 with  | none,  none =>                            true | some ( FlexibleArrayMember  _  ident1  qs1  ty1),  some ( FlexibleArrayMember  _  ident2  qs2  ty2) =>  idEqual                            ident1  ident2  &&  are_compatible_aux1  (qs1, ty1)  (qs2, ty2) | _, _ =>                            false                     )) | _, _ => (failwithI  "Ctype_aux.are_compatible_aux: failed to lookup a struct definition" : Bool)                         else              false) ) | Union0  tag1,  Union0  tag2 => (         /-  STD Â§6.2.7#1  -/         /-  TODO: being conservative here (aka STD compliant)  -/         if  from_same_translation_unit  tag1  tag2 then  match tag1,  tag2 with  | Symbol  d1  n1  sd1,  Symbol  d2  n2  sd2 => (         if  (CerberusFresh.digest_compare  d1  d2  == ( 0 :  Int))  &&  (n1  ==  n2) then            if  natGteb  (0) (  5)  &&  (sd1  !=  sd2) then              match  CerbDebug.print_debug_pure (  5)  []  (fun (u : Unit) =>  match u with |  () =>                 String.append "[Symbol.symbolEqual] suspicious equality ==> "                 (String.append (show_symbol_description  sd1)   (String.append " <-> "  (show_symbol_description  sd2))) ) with |   () =>              true             else              true          else            false)             else            match              match tag1,  tag2 with  | Symbol  _  _ ( SD_Id  tag_str1),  Symbol  _  _ ( SD_Id  tag_str2) =>                    (tag_str1, tag_str2) | _, _ => (failwithI  "Ctype_aux.are_compatible_aux: failed to destruct a union tags" : (String ×String))              with |   (tag_str1,  tag_str2) => (           if  tag_str1  ==  tag_str2 then              match (fmapLookupBy  (fun (sym1 : sym) (sym2 : sym)=> ordCompare  sym1  sym2)  tag1  tagDefs1),  (fmapLookupBy  (fun (sym1 : sym) (sym2 : sym)=> ordCompare  sym1  sym2)  tag2  tagDefs2) with  | none,  none =>                    true | some  _,  none =>                    true | none,  some  _ =>                    true | some  (_,  UnionDef  xs1),  some  (_,  UnionDef  xs2) => (                   if  not  ((List.length  xs1)  ==  (List.length  xs2)) then                      false                    else                      List.all  (lemListZip  xs1  xs2)  (fun (p : (((identifier ×((attributes ×Option (alignment) ×qualifiers ×ctype)))) ×((identifier ×((attributes ×Option (alignment) ×qualifiers ×ctype)))))) =>  match p with |  ((ident1,  (_,  _/- TODO alignment -/,  qs1,  ty1)),  (ident2,  (_,  _/- TODO alignment -/,  qs2,  ty2))) =>  idEqual                        ident1  ident2  &&  are_compatible_aux1  (qs1, ty1)  (qs2, ty2)                      )) | _, _ => (failwithI  "Ctype_aux.are_compatible_aux: failed to lookup a union definition" : Bool)                         else              false) ) | Atomic  atom_ty1,  Atomic  atom_ty2 =>          are_compatible_aux1  (no_qualifiers, atom_ty1)  (no_qualifiers, atom_ty2) | _, _ =>          /-  TODO: we can't see Enum types here and there is some impl-def stuff  -/         false   )) )
+  | Nat.succ lemFuel => (match p, p0, p1 with |   env1@((tagDefs1,  tagDefs2,  assumed)),  (qs1,  Ctype  _  ty1),  (qs2,  Ctype  _  ty2) => ( let  are_compatible_aux1  := (fun (assumed : List ((sym ×sym))) (qs_ty1 : (qualifiers ×ctype)) (qs_ty2 : (qualifiers ×ctype)) => (are_compatible_aux_lemFuel lemFuel)  (tagDefs1, tagDefs2, assumed)  qs_ty1  qs_ty2);  qualifiersEqual    /-  qualifiers need to be equal (see Â§6.7.3#10)  -/   qs1  qs2  && ( match ty1,  ty2 with  | Void0,  Void0 =>          true | Basic  bty1,  Basic  bty2 =>          are_compatible  (qs1, Ctype  []  (Basic  bty1))  (qs2, Ctype  []  (Basic  bty2)) | Array0  elem_ty1  n1_opt,  Array0  elem_ty2  n2_opt =>          /-  STD Â§6.7.6.2#6  -/            are_compatible_aux1  assumed  (no_qualifiers, elem_ty1)  (no_qualifiers, elem_ty2)          && ( match n1_opt,  n1_opt with  | some  n1,  some  n2 =>  n1  ==  n2 | some  _,  none =>  true | none,  some  _ =>  true | none,  none =>  true            ) | Function  (ret_qs1,  ret_ty1)  params1  isVariadic1,  Function  (ret_qs2,  ret_ty2)  params2  isVariadic2 =>          /-  STD Â§6.7.6.3#15  -/         /-  TODO: when the two types do not both have a param list  -/            are_compatible_aux1  assumed  (ret_qs1, ret_ty1)  (ret_qs2, ret_ty2)          &&  ((are_compatible_params0_lemFuel lemFuel)  env1  params1  params2          &&  (isVariadic1  ==  isVariadic2)) | Pointer  ref_qs1  ref_ty1,  Pointer  ref_qs2  ref_ty2 =>          /-  STD Â§6.7.6.1#2  -/         are_compatible_aux1  assumed  (ref_qs1, ref_ty1)  (ref_qs2, ref_ty2) | Struct  tag1,  Struct  tag2 => (         /-  STD Â§6.2.7#1  -/         /-  TODO: being conservative here (aka STD compliant)  -/         if  from_same_translation_unit  tag1  tag2 then  match tag1,  tag2 with  | Symbol  d1  n1  sd1,  Symbol  d2  n2  sd2 => (         if  (CerberusFresh.digest_compare  d1  d2  == ( 0 :  Int))  &&  (n1  ==  n2) then            if  natGteb  (0) (  5)  &&  (sd1  !=  sd2) then              match  CerbDebug.print_debug_pure (  5)  []  (fun (u : Unit) =>  match u with |  () =>                 String.append "[Symbol.symbolEqual] suspicious equality ==> "                 (String.append (show_symbol_description  sd1)   (String.append " <-> "  (show_symbol_description  sd2))) ) with |   () =>              true             else              true          else            false)             else            match              match tag1,  tag2 with  | Symbol  _  _ ( SD_Id  tag_str1),  Symbol  _  _ ( SD_Id  tag_str2) =>                    (tag_str1, tag_str2) | _, _ => (failwithI  "Ctype_aux.are_compatible_aux: failed to destruct a struct tag" : (String ×String))              with |   (tag_str1,  tag_str2) => (           if  tag_str1  ==  tag_str2 then              if  Lem_List.elem  (tag1, tag2)  assumed then  true  else              match (fmapLookupBy  (fun (sym1 : sym) (sym2 : sym)=> ordCompare  sym1  sym2)  tag1  tagDefs1),  (fmapLookupBy  (fun (sym1 : sym) (sym2 : sym)=> ordCompare  sym1  sym2)  tag2  tagDefs2) with  | none,  none =>                    true | some  _,  none =>                    true | none,  some  _ =>                    true | some  (_,  StructDef  xs1  flexible_opt1),  some  (_,  StructDef  xs2  flexible_opt2) => (                   if  not  ((List.length  xs1)  ==  (List.length  xs2)) then                      false                    else                      List.all  (lemListZip  xs1  xs2)  (fun (p : (((identifier ×((attributes ×Option (alignment) ×qualifiers ×ctype)))) ×((identifier ×((attributes ×Option (alignment) ×qualifiers ×ctype)))))) =>  match p with |  ((ident1,  (_,  _/- TODO alignment -/,  qs1,  ty1)),  (ident2,  (_,  _/- TODO alignment -/,  qs2,  ty2))) =>  idEqual                        ident1  ident2  &&  are_compatible_aux1  ((tag1, tag2)  ::  assumed)  (qs1, ty1)  (qs2, ty2)                      )  && (                     match flexible_opt1,  flexible_opt2 with  | none,  none =>                            true | some ( FlexibleArrayMember  _  ident1  qs1  ty1),  some ( FlexibleArrayMember  _  ident2  qs2  ty2) =>  idEqual                            ident1  ident2  &&  are_compatible_aux1  ((tag1, tag2)  ::  assumed)  (qs1, ty1)  (qs2, ty2) | _, _ =>                            false                     )) | _, _ => (failwithI  "Ctype_aux.are_compatible_aux: failed to lookup a struct definition" : Bool)                         else              false) ) | Union0  tag1,  Union0  tag2 => (         /-  STD Â§6.2.7#1  -/         /-  TODO: being conservative here (aka STD compliant)  -/         if  from_same_translation_unit  tag1  tag2 then  match tag1,  tag2 with  | Symbol  d1  n1  sd1,  Symbol  d2  n2  sd2 => (         if  (CerberusFresh.digest_compare  d1  d2  == ( 0 :  Int))  &&  (n1  ==  n2) then            if  natGteb  (0) (  5)  &&  (sd1  !=  sd2) then              match  CerbDebug.print_debug_pure (  5)  []  (fun (u : Unit) =>  match u with |  () =>                 String.append "[Symbol.symbolEqual] suspicious equality ==> "                 (String.append (show_symbol_description  sd1)   (String.append " <-> "  (show_symbol_description  sd2))) ) with |   () =>              true             else              true          else            false)             else            match              match tag1,  tag2 with  | Symbol  _  _ ( SD_Id  tag_str1),  Symbol  _  _ ( SD_Id  tag_str2) =>                    (tag_str1, tag_str2) | _, _ => (failwithI  "Ctype_aux.are_compatible_aux: failed to destruct a union tags" : (String ×String))              with |   (tag_str1,  tag_str2) => (           if  tag_str1  ==  tag_str2 then              if  Lem_List.elem  (tag1, tag2)  assumed then  true  else              match (fmapLookupBy  (fun (sym1 : sym) (sym2 : sym)=> ordCompare  sym1  sym2)  tag1  tagDefs1),  (fmapLookupBy  (fun (sym1 : sym) (sym2 : sym)=> ordCompare  sym1  sym2)  tag2  tagDefs2) with  | none,  none =>                    true | some  _,  none =>                    true | none,  some  _ =>                    true | some  (_,  UnionDef  xs1),  some  (_,  UnionDef  xs2) => (                   if  not  ((List.length  xs1)  ==  (List.length  xs2)) then                      false                    else                      List.all  (lemListZip  xs1  xs2)  (fun (p : (((identifier ×((attributes ×Option (alignment) ×qualifiers ×ctype)))) ×((identifier ×((attributes ×Option (alignment) ×qualifiers ×ctype)))))) =>  match p with |  ((ident1,  (_,  _/- TODO alignment -/,  qs1,  ty1)),  (ident2,  (_,  _/- TODO alignment -/,  qs2,  ty2))) =>  idEqual                        ident1  ident2  &&  are_compatible_aux1  ((tag1, tag2)  ::  assumed)  (qs1, ty1)  (qs2, ty2)                      )) | _, _ => (failwithI  "Ctype_aux.are_compatible_aux: failed to lookup a union definition" : Bool)                         else              false) ) | Atomic  atom_ty1,  Atomic  atom_ty2 =>          are_compatible_aux1  assumed  (no_qualifiers, atom_ty1)  (no_qualifiers, atom_ty2) | _, _ =>          /-  TODO: we can't see Enum types here and there is some impl-def stuff  -/         false   )) )
 end
 
-def are_compatible_params_aux0 [LemFuel] : (Fmap (sym) ((CerbLocation.Loc ×tag_definition)) ×Fmap (sym) ((CerbLocation.Loc ×tag_definition))) → Bool → (List ((qualifiers ×ctype ×Bool)) ×List ((qualifiers ×ctype ×Bool))) → Bool := are_compatible_params_aux0_lemFuel LemFuel.fuel
-theorem are_compatible_params_aux0_lemFuel_zero (env1 : (Fmap (sym) ((CerbLocation.Loc ×tag_definition)) ×Fmap (sym) ((CerbLocation.Loc ×tag_definition)))) (acc : Bool) :
+def are_compatible_params_aux0 [LemFuel] : (Fmap (sym) ((CerbLocation.Loc ×tag_definition)) ×Fmap (sym) ((CerbLocation.Loc ×tag_definition)) ×List ((sym ×sym))) → Bool → (List ((qualifiers ×ctype ×Bool)) ×List ((qualifiers ×ctype ×Bool))) → Bool := are_compatible_params_aux0_lemFuel LemFuel.fuel
+theorem are_compatible_params_aux0_lemFuel_zero (env1 : (Fmap (sym) ((CerbLocation.Loc ×tag_definition)) ×Fmap (sym) ((CerbLocation.Loc ×tag_definition)) ×List ((sym ×sym)))) (acc : Bool) :
     (are_compatible_params_aux0_lemFuel 0 env1 acc : (List ((qualifiers ×ctype ×Bool)) ×List ((qualifiers ×ctype ×Bool))) → Bool) = (fuelExhausted (fun _ => false)) := rfl
 
 
-def are_compatible_params0 [LemFuel] : (Fmap (sym) ((CerbLocation.Loc ×tag_definition)) ×Fmap (sym) ((CerbLocation.Loc ×tag_definition))) → List ((qualifiers ×ctype ×Bool)) → List ((qualifiers ×ctype ×Bool)) → Bool := are_compatible_params0_lemFuel LemFuel.fuel
-theorem are_compatible_params0_lemFuel_zero (env1 : (Fmap (sym) ((CerbLocation.Loc ×tag_definition)) ×Fmap (sym) ((CerbLocation.Loc ×tag_definition)))) (params1 : List ((qualifiers ×ctype ×Bool))) (params2 : List ((qualifiers ×ctype ×Bool))) :
+def are_compatible_params0 [LemFuel] : (Fmap (sym) ((CerbLocation.Loc ×tag_definition)) ×Fmap (sym) ((CerbLocation.Loc ×tag_definition)) ×List ((sym ×sym))) → List ((qualifiers ×ctype ×Bool)) → List ((qualifiers ×ctype ×Bool)) → Bool := are_compatible_params0_lemFuel LemFuel.fuel
+theorem are_compatible_params0_lemFuel_zero (env1 : (Fmap (sym) ((CerbLocation.Loc ×tag_definition)) ×Fmap (sym) ((CerbLocation.Loc ×tag_definition)) ×List ((sym ×sym)))) (params1 : List ((qualifiers ×ctype ×Bool))) (params2 : List ((qualifiers ×ctype ×Bool))) :
     are_compatible_params0_lemFuel 0 env1 params1 params2 = (fuelExhausted false) := rfl
 
 
-def are_compatible_aux [LemFuel] : (Fmap (sym) ((CerbLocation.Loc ×tag_definition)) ×Fmap (sym) ((CerbLocation.Loc ×tag_definition))) → (qualifiers ×ctype) → (qualifiers ×ctype) → Bool := are_compatible_aux_lemFuel LemFuel.fuel
-theorem are_compatible_aux_lemFuel_zero (p : (Fmap (sym) ((CerbLocation.Loc ×tag_definition)) ×Fmap (sym) ((CerbLocation.Loc ×tag_definition)))) (p0 : (qualifiers ×ctype)) (p1 : (qualifiers ×ctype)) :
+def are_compatible_aux [LemFuel] : (Fmap (sym) ((CerbLocation.Loc ×tag_definition)) ×Fmap (sym) ((CerbLocation.Loc ×tag_definition)) ×List ((sym ×sym))) → (qualifiers ×ctype) → (qualifiers ×ctype) → Bool := are_compatible_aux_lemFuel LemFuel.fuel
+theorem are_compatible_aux_lemFuel_zero (p : (Fmap (sym) ((CerbLocation.Loc ×tag_definition)) ×Fmap (sym) ((CerbLocation.Loc ×tag_definition)) ×List ((sym ×sym)))) (p0 : (qualifiers ×ctype)) (p1 : (qualifiers ×ctype)) :
     are_compatible_aux_lemFuel 0 p p0 p1 = (fuelExhausted false) := rfl
 
 
@@ -125,7 +125,7 @@
     end
   ) (tagDefs ()) Map.empty in  -/
   let  tagDefs1  :=_lemReader_tagDefs; 
-  are_compatible_aux  (tagDefs1, tagDefs1)  qs_ty1  qs_ty2
+  are_compatible_aux  (tagDefs1, tagDefs1, [])  qs_ty1  qs_ty2
 
 /- 
 val tags_are_compatible: Symbol.sym -> Symbol.sym -> bool
```

Generated `lean_frontend/generated/Ctype_aux.lean` SHA-256 after regeneration:
`c0a9791576ecb645167b67e0f4f390e090de1ecd0c2b1d36fb9445c58a2e01b8`.
The generated `_zero` declarations naturally carry the wider environment;
their statements/bodies were not edited by hand and the source fuel
sentinels are unchanged.

### Second handoff — unresolved question and exact remaining work

Question for the orchestrator (recorded, not asked interactively):

- What is the intended shared-semantics remedy for selecting a member of
  the cross-TU returned struct in `ident(n).v`, given the direct exact-tag
  guard at `core_eval.lem:945-946`? Should the charter gain a preceding
  return/aggregate-conversion or member-selection slice and corresponding
  file-fence/acceptance changes, or should this independent blocker be
  repaired before this branch resumes? The expected `Specified(7)` has
  not been withdrawn or replaced here.

Remaining work is D1 acceptance and its decision, then D2 → D5 in order.
This stop commit preserves the partial D1 accumulator implementation with
its source/generated diffs and successful build receipts; it is not an
accepted D1 or a merge candidate. There is no measure/proof module,
partition change, CPU timing experiment, manifest refresh, tray corpus,
LADDER row, TODO/count update, or Tier B result from this resumption.
The fuel partition quoted above is the old baseline's `57 + 13 + 5 + 6`;
`60 + 13 + 2 + 6` has not been achieved.

The evidence directory preserves the earlier stop files and adds full raw
stdout/stderr for all 13 resumed-baseline lanes, the separate unit log,
all D1 build logs, freshness output, engine outputs/command receipts,
input hashes, and compact labeled release/pristine receipts. Its derived
filesystem total is **704,493 bytes**, below the 1 MB limit. Full inventory
reports, bridge JSON, and working captures remain in the ignored output
directories named above. Before commit, status is checked against the
fence and the generated/baseline hashes are rechecked. The branch stops
here for orchestrator review: no merge, push, or rebase.

Final formatting check: `git diff --check -- frontend/model/ctype_aux.lem`
passes. The whole-record check reports trailing spaces inside the required
verbatim unified diffs (including their blank context-line prefixes and
generated trailing spaces). Those evidence bytes are intentionally preserved,
not reformatted. This is not an implementation whitespace defect.


## Orchestrator take-over (2026-09-10) — the slice finished by the orchestrator [AGENT]

[USER 2026-09-10] ("I think it's better if you finish this up yourself given the level of
uncertainty involved. Can you pick this up?") — the orchestrator (Claude) took the slice
over at Codex's second stop (`a91804f9e`) and executed D1's acceptance, D2, D3, D4 and
D5 in this worktree. Codex's stop records above stand as written; nothing in them is
edited. Every verdict line below is verbatim from the named log.

### D1 — accepted as specified; the acceptance criterion (a) REVISED

Codex's uncommitted `frontend/model/ctype_aux.lem` edit (the stop record's diff) is
exactly the charter's accumulator: `env = (tagDefs1, tagDefs2, assumed)`, a LIST of tag
pairs, membership tested after the name test and before the lookups in both cross-TU
arms, the pair consed only into the member comparisons (incl. the flexible array
member), every other call passing the current list, the entry passing `[]`. Accepted
without change and committed by the orchestrator in `bbc60d6ef` together with D2/D4.

**Acceptance (b), zero baseline movement, holds.** Tier A on Codex's D1 source (its
oracle and Lean rebuilt, driver-fresh), `python3 scripts/release.py --mode fast --out
.tmp/acas-tierA-d1`:

```
FAILED A1 (148.2s)
PASSED A2 (32.5s)
PASSED A3 (54.0s)
PASSED A4 (23.0s)
PASSED A4b (18.4s)
PASSED A4c (3.1s)
PASSED A5 (23.1s)
PASSED A6 (2.3s)
PASSED A7 (10.0s)
PASSED A8 (8.4s)
PASSED A9 (16.4s)
PASSED A10 (16.7s)
PASSED A11 (58.3s)
fast: failed; 12/13 selected commands completed successfully.
```

The single red is the one the charter licensed for D1 — `test_unit.sh`'s fork-drift
gate on the changed `ctype_aux.lem` (cleared in D4); every other gate inside A1 passed:

```
Total: 7 passed, 0 failed
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
    check_fuel_forms: forms partition OK (57 MEASURED + 13 ABSORBING + 5 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)
check_fuel_forms: forms partition OK (57 MEASURED + 13 ABSORBING + 5 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)
      check_fork_content: FAIL — source-content drift inside reviewed file(s):
      check_fork_drift: FAIL — source-content check failed
  PLANT OK   [S12 content change inside already-listed fresh supply] rc=1 -> check_fork_content: FAIL — source-content drift inside reviewed file(s):
  PLANT OK   [S13 duplicate source-content pin] rc=1 -> check_fork_content: FAIL — duplicate [source-content] entry: util/cerb_fresh.ml
  PLANT OK   [S14 missing source-content pin] rc=1 -> check_fork_content: FAIL — source-content path set differs from live source delta: unpinned=['util/cerb_fresh.ml']; stale=[]
test_unit: fork-drift gate SELFTEST FAILED
```

**Acceptance (a) is revised, not met as written.** The charter expected `Specified(7)`
on the fork oracle and on Lean. With the non-termination gone, both engines reach the
NEXT cross-TU strictness in the shared model, `core_eval.lem:945-946`'s exact-tag guard
in `PEmemberof(struct)`: the `struct node` value returned from TU 1 (tagged by TU 1's
`node`) is member-selected under TU 2's `node` and rejected as ill-formed. Both fork
engines agree on the failure up to symbol numbering (class (a) of the zero-discrepancy
rule: message text); the pristine upstream oracle still does not terminate. This is a
distinct upstream limitation, outside this slice's fence, filed as upstream-tray draft
38 (`docs/upstream-tray/38-pememberof-cross-tu-struct-value-tag-identity.md`); draft 37
gained a "Fork status" section pointing at it. Verbatim re-run on the FINAL binaries of
this slice (commit `bbc60d6ef`; the pristine oracle is the one Codex built in this
worktree, `b9aeedcb4` + lem `3802cb0`):

```
=== fork-oracle: cerberus --nolibc --exec --batch --mode=exhaustive node_a.c node_b.c
Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(531, SD_Id("node")) vs Symbol(502, SD_Id("node"))'"}
Time spent: 0.024473 seconds
rc=1 elapsed=.037669325s
=== lean: cerberus-lean --batch node_a.json node_b.json (cabs-json via the fork oracle)
Error {msg: "ill-formed program: `PEmemberof(struct) ==> mismatched tags: Symbol(48, SD_Id("node")) vs Symbol(19, SD_Id("node"))'"}
rc=1 elapsed=.033639341s
=== pristine upstream oracle (b9aeedcb4 + lem 3802cb0): same flags
rc=124 elapsed=60.105290299s
=== single-TU control (fork oracle / lean)
Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
Time spent: 0.023435 seconds
rc=0
Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
rc=0
```

The revised D1 acceptance: (a′) the reproducer terminates on both fork engines with the
same failure class, the single-TU control is `Specified(7)` on both, upstream still
`rc=124`; (b) zero baseline movement; (c) the tracked diff is `ctype_aux.lem` alone
(Codex's record carries the generated deltas' hashes; the OCaml `ctype_aux.ml` delta is
the fork-drift `[expected-semantic]` pin moved in D4).

**Correctness argument (why results on previously-terminating inputs are unchanged).**
A cross-TU hop node is determined by the two tables and the two tags once the
qualifier and name tests have passed; its member subtree does not read the outer
qualifiers. If the same pair recurred on a path of the ORIGINAL recursion tree, that
subtree would repeat and the original would not terminate. So on every input the
original terminates on, no pair recurs on any path, the new `List.elem` test never
fires, and both functions compute the same tree, test for test. Termination: every hop
adds a pair the path does not yet carry, drawn from the tags occurring in the tables'
member types (a finite set), and between hops the recursion descends finite syntax —
the measure of D2 makes this a kernel-checked bound.

### D2 — the hypothesis-free measure and its proofs

Declares added to `ctype_aux.lem` beside the three `fuel` declares (the
`ailTypesAux.lem:1337-1350` pattern) and `declare {lean} extra_import
`CerbCtypeMeasure``:

```
declare {lean} fuel_measure val are_compatible_aux = `CerbCtypeMeasure.auxBound p p0 p1`
declare {lean} fuel_measure val are_compatible_params_aux = `CerbCtypeMeasure.paramsAuxBound env1 lemTail`
declare {lean} fuel_measure val are_compatible_params = `CerbCtypeMeasure.paramsBound env1 params1 params2`
```

lem hoisted `are_compatible_params_aux`'s `function` scrutinee as `lemTail` (as at C3)
and emitted the three obligations into `generated/Ctype_aux_auxiliary.lean`
(`are_compatible_aux_measure_sufficient`, `are_compatible_params_aux0_measure_sufficient`,
`are_compatible_params0_measure_sufficient`).

**The measure** (`lean_frontend/CerbCtypeMeasure.lean`, structural `def`s only; no
`partial`/`opaque`/`implemented_by`/macros), for `are_compatible_aux (t1,t2,A) (qs1,ty1) (qs2,ty2)`:

```
auxGeneral = count * weight + lemSize ty1 + lemSize ty2 + 1
count      = hops t1 t2 A + missing (tagsIn ty1) (occ t1) + missing (tagsIn ty2) (occ t2)
hops       = #{ (a,b) ∈ occ t1 × occ t2 : (a,b) not `Lem_List.elem` A }
occ t      = every struct/union tag occurring in a member type of t
missing l o = #{ a ∈ l : a not `Lem_List.elem` o }
weight     = valsSize t1 + valsSize t2 + 1        (Σ member-type sizes of each table)
auxBound   = if both types are Struct/Struct (or Union/Union) tags of the SAME translation
             unit then 1 else auxGeneral         (the cheap path: no table traversal)
```

with `paramsAuxBound` the same over `tagsInParams` and `lemSize_aux1` of the two lists
and `paramsBound = paramsAuxBound + 1`. Why it bounds the block's depth: a structural
step keeps `count` from growing (the child's tags are a sublist of the parent's) and
shrinks both sizes; a hop into member types (u1,u2) with `(s1,s2) :: A` makes the
children's `missing` 0 (their tags occur in the tables) and EITHER both s1,s2 occur in
the tables — the pair `≈ (s1,s2)` of `occ × occ` flips from unassumed to assumed and
`hops` drops — OR one does not and the parent's `missing` was ≥ 1; either way `count`
drops by ≥ 1 while the member sizes are ≤ `valsSize`, so `count'·w + sizes' + 1 ≤
(count−1)·w + w = count·w < parent`. No property of the tables' comparators is used: a
successful `fmapLookupBy` only says the value is one of the tree's nodes
(`find?_some_bounds`, by induction on the `Pmap`). Symbol membership is the block's own
`Lem_List.elem` at the model's `Eq0 sym` instance (digest and number; the description
is ignored), shown to be an equivalence (`symEq_iff`, via `digest_compare_eq_zero_iff`
and the `Eq0 Nat` instance's `defaultCompare`).

**The proofs** (`lean_frontend/Ctype_aux_lemMeasureProofs.lean`): the C3 template — one
joint stability statement for the three members by induction on a bound, each worker
unfolded one step, every recursive call rewritten by a `key` whose side condition is a
decrease lemma (`lt_array`, `lt_pointer`, `lt_atomic`, `lt_function_ret`,
`lt_function_params`, `lt_params_head`, `lt_params_tail`, `lt_params`,
`auxGeneral_lt_of_hop`); the two hop arms descend under the member traversal with
`all_congr`, which supplies the member's membership (`member_bounds`,
`union_member_bounds`, `flex_bounds`). The name test's two shapes (two `SD_Id` tags, or
the `failwithI` pair) are handled by one script since `split` substitutes the tags.
Kernel-only tactics; no option bumps; hypothesis-free (no `assuming`, no
`fuel_hypotheses.txt` row).

**Consequential edits outside the charter's fence, all forced by the measure:**
`lean_frontend/Core_aux_lemMeasureProofs.lean` — `memValueFromValue`'s two theorems
drop their `[LemFuel]` binder (its callee `Ctype_aux.are_compatible` is no longer
ambient, so lem's regenerated obligation has none; the library build failed with
`failed to synthesize LemFuel` until this); `lean_frontend/test/Unit/TotalityProofTest.lean`
Part 1 regenerated with `scripts/gen_fuel_parametricity.py --emit` (19 → 16 ambient
wrappers: the three pins of this block are gone, nothing else moved);
`lean_frontend/lakefile.toml` roots + `handwritten_copy.manifest` gain
`CerbCtypeMeasure` and `Ctype_aux_lemMeasureProofs` (every `generated/` module must be a
root — `check_lakefile_roots.sh`; the charter's §1 said otherwise and is corrected in
place); `scripts/fuel_forms_pending.txt` loses its three `deep-ref` rows (header note
rewritten; 2 parser rows remain); `lean_frontend/VALIDATION.md` §7 table 57→60 MEASURED,
PENDING 5→2.

Verbatim (the proofs+obligations build, the library build, the freshness check, the
fuel-forms gate):

```
Build completed successfully (67 jobs).
Build completed successfully (249 jobs).
check_driver_fresh: oracle OK (bin 6f06e19c653c3c7f80ab538419b6fe558d1cdb23ecc3fd3abf8027780bd7a253, src 2e7aa0096a729a5a9852c40206f12630792e93f87f8682ddee898289d14d7d17)
check_driver_fresh: lean OK (bin aa8bf3e46f68f4e56282c492fa2b1fc13e3ec1e79da33ae77c088e1003f7db91, src 0e46cc1261eeb5ea83e22fe81c0cf82e5285c29a7c28df6d93c014ab1ea41b51)
check_fuel_forms: forms partition OK (60 MEASURED + 13 ABSORBING + 2 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)
check_fuel_forms: OK (81 fuel'd workers: 60 MEASURED (obligation of the contract's shape incl. argument correspondence against the wrapper's body; every obligation + proof cone ⊆ the standard three; 10 of them under a hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions), 13 ABSORBING = kill at zero (the _zero lemma is the worker at literal 0 on its own binders = the monad's absorbing element, cone ⊆ the standard three; propagation NOT proved — lem TODO 13), 2 reachable-AMBIENT = the 2 rows of fuel_forms_pending.txt exactly, 6 ambient unreachable from the drive cone)
```

### D4 — the fork delta manifested; the tray; what was NOT done and why

**Fork-drift.** `./scripts/check_fork_drift.sh --refresh` was tried first and REVERTED:
the wholesale refresh strips the manifest's documented header (181 lines) and reorders
rows — exactly what the manifest's own notes warn about. The two pins were moved by
single-row edits with a header note, as every previous landing did: `[source-content]
frontend/model/ctype_aux.lem 9c81b03e… → 5a657d68…` and `[expected-semantic]
ctype_aux.ml 8882e41d… → afcc21e3…`. Unlike the earlier Lean-only pin moves this one is
a GENUINE shared-model change to the oracle's generated OCaml. The charter's D4.1 text
("--refresh; exactly two hunks") was wrong about the mechanism; corrected here.

```
check_fork_content: OK — 76 source files content/mode-pinned
check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin f6542f8 = lem -v)
```

**The tray-pinned multi-TU corpus (charter D4.2) is NOT added.** Trial: with the
reproducer under a `tests/multi_tu_tray/cross_tu_node/` corpus, `./scripts/test_multi_tu.sh
tests/multi_tu_tray` reports `[1] MISMATCH cross_tu_node` — the lane compares the two
engines' `ERR` payloads byte for byte and the agreed failure differs in symbol numbering
(`Symbol(531…) vs Symbol(502…)` on the oracle, `Symbol(48…) vs Symbol(19…)` on Lean).
Pinning it green would require changing the lane's observation contract (projecting
symbol numbers out of failure text), which is a decision about class (a) evidence the
slice must not take. Decision [AGENT]: the reproducer stays in
`tests/failure-probes/cross_tu_node/`; its differential behaviour is the verbatim
three-engine run above (record-level evidence); the gate-enforced property of this slice
is the termination itself (the three MEASURED obligations, checked by the fuel-forms
gate on every unit run). No LADDER row 6b. **Question for the operator:** should the
multi-TU lane (and the exec lanes, which never see an agreed `ERR`) project symbol
numbers out of failure text so class-(a) agreements can be pinned as MATCH? If yes, the
reproducer becomes a Tier A row in that slice.

**Tray and TODO.** Draft 37 gained "Fork status (2026-09-10)" (the patch is the
D1 `.lem` diff minus the Lean-only declares; fresh three-engine run); NEW draft 38
(`PEmemberof` exact-tag identity on a struct value that crossed the TU boundary; remedy:
consult `Ctype_aux.are_compatible` at member selection, as `memValueFromValue` already
does on store); `INDEX.md` rows 37 (fork status) and 38. `TODO.md`: the C2
compatibility-trio bullet and F-C4-1 RESOLVED with the residual (draft 38) named.
`lean_frontend/CLAUDE.md` states no counts; unchanged.

### Tier A on the finished D2/D4 state (before D3/D5)

`python3 scripts/release.py --mode fast --out .tmp/acas-tierA-d2` at the tree committed as
`bbc60d6ef` (the fuel-forms partition and the moved pins included):

```
PASSED A1 (150.5s)
PASSED A2 (26.7s)
PASSED A3 (51.4s)
PASSED A4 (22.7s)
PASSED A4b (18.4s)
PASSED A4c (3.1s)
PASSED A5 (21.9s)
PASSED A6 (2.2s)
PASSED A7 (9.8s)
PASSED A8 (8.4s)
PASSED A9 (15.8s)
PASSED A10 (16.6s)
PASSED A11 (58.2s)
fast: incomplete; 13/13 selected commands completed successfully.
```

("`fast: incomplete`" is the runner's standing label for Tier A alone — certification
needs Tier B, run in D5.)


### D3 — the measure's cost, measured (csmith small_arrays, both engines, 15 s budget)

`scripts/measure_csmith_cpu.py --max 470 --timeout 15`, AFTER = this worktree at
`bbc60d6ef`, BEFORE = the primary checkout at mainline `86daea264` (read-only; its
binaries are the pre-change ones), run back to back on an otherwise idle box (load ≈ 1):

```
=== after (this worktree, HEAD bbc60d6ef) 2026-09-10T07:50:50Z
after rc=0
SUMMARY: total=470 match=207 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=3 hang=0 cerb_skip=260 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
CPU export OK: 470 inputs, 940 engine rows; lane exit=0; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/are-compatible-assumed-set/lean_frontend/docs/2
=== before (primary checkout 86daea264, read-only) 2026-09-10T08:59:31Z
before rc=0
SUMMARY: total=470 match=207 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=3 hang=0 cerb_skip=260 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
CPU export OK: 470 inputs, 940 engine rows; lane exit=0; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/are-compatible-assumed-set/lean_frontend/docs/2
=== D3 DONE 2026-09-10T10:08:09Z
```

Both runs classify every row exactly as the committed baseline does (the 260 `CERB_SKIP`
rows are the baseline's oracle timeouts, the 3 `TIMEOUT` rows the baseline's Lean
timeouts; zero movement). Derivation (`derive-d3-ratios.py`, output `cpu-ratios.tsv`):

```
compared (lean MATCH on both): 207 rows; excluded: 263; status movements: 0
aggregate lean CPU before=83.75 s after=84.44 s ratio=1.008239
rows over the 1.10 bar: 45
  … 45 rows listed in cpu-ratios.tsv (over_1_10 = YES); every one is a 0.01–0.04 s difference on a row of 0.05–0.23 s
excluded (status before -> after):
  Counter({('CERB_SKIP', 'CERB_SKIP'): 260, ('TIMEOUT', 'TIMEOUT'): 3})
```

The **aggregate Lean CPU over the 207 comparable rows moved by +0.8 %** (83.75 s → 84.44 s).
The 45 per-row "exceedances" are the instrument's 0.01 s quantum on rows of 0.05–0.23 s
(a single tick on a 0.05 s row is a ratio of 1.20). As the previous slice did, they were
REPEATED rather than argued away (`repeat-d3-exceptions.py`, each input re-staged as the
lane stages it, pre/after alternated, `cpu-repeats.tsv`):

```
sa_csmith_132.c	pre=0.0500	after=0.0600	ratio=1.200000	YES
sa_csmith_212.c	pre=0.0500	after=0.0600	ratio=1.200000	YES
sa_csmith_44.c	pre=0.0850	after=0.0950	ratio=1.117647	YES
sa_csmith_51.c	pre=0.0550	after=0.0650	ratio=1.181818	YES
repeated 45 inputs x 2; still over 1.10 by means: 4 ['sa_csmith_132.c', 'sa_csmith_212.c', 'sa_csmith_44.c', 'sa_csmith_51.c']
```

The four that remained over the bar by the means of 2 repeats were repeated 10 times
each (`cpu-repeats-residual-x10.tsv`):

```
sa_csmith_132.c	pre=0.0540	after=0.0530	ratio=0.981481	NO
sa_csmith_212.c	pre=0.0570	after=0.0590	ratio=1.035088	NO
sa_csmith_44.c	pre=0.0930	after=0.0890	ratio=0.956989	NO
sa_csmith_51.c	pre=0.0610	after=0.0600	ratio=0.983607	NO
repeated 4 inputs x 10; still over 1.10 by means: 0 []
```

**D3 verdict: the bar holds.** Every row that completes on both sides is ≤ 1.10 by the
mean of repeated measurements; no row moved MATCH → TIMEOUT; the aggregate cost of the
measure is +0.8 % on this set. The cheap same-TU path does what it was designed to do:
single-TU programs never evaluate `auxGeneral`. Cross-TU programs pay the general bound
(a table traversal per cross-TU struct store); the multi-TU corpora are small and moved
nowhere.

### D5 — the full battery

`.tmp/acas-d5.sh` (orchestrator harness: `LC_ALL=C NO_COLOR=1 TERM=dumb`,
`CERB_MEM_MAX=48G`; each lane's last lines tailed, rc printed): the freshness check, the
unit lane and the four `test_exec.sh` baseline lanes directly, then `python3
scripts/release.py --mode full --out .tmp/acas-tierAB` (Tier A + Tier B, 35 commands).
Verbatim:

```
=== bash tools/check_driver_fresh.sh --check  --- rc=0
=== ./scripts/test_unit.sh  --- rc=0
=== ./scripts/test_exec.sh --check-baseline  --- rc=0
=== ./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage  --- rc=0
=== ./scripts/test_exec.sh --check-baseline=scripts/exec_debug_baseline.txt tests/debug  --- rc=0
=== ./scripts/test_exec.sh --check-baseline=scripts/exec_float_baseline.txt tests/float  --- rc=0
=== python3 scripts/release.py --mode full --out .tmp/acas-tierAB  --- rc=0
```

```
full: passed; 35/35 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

Per-command status from the runner's schema-2 `report.json` (`lanes`), verbatim fields:

```
A1: passed (exit 0, 110.865 s)
A2: passed (exit 0, 26.468 s)
A3: passed (exit 0, 50.955 s)
A4: passed (exit 0, 22.462 s)
A4b: passed (exit 0, 18.104 s)
A4c: passed (exit 0, 3.032 s)
A5: passed (exit 0, 21.71 s)
A6: passed (exit 0, 2.131 s)
A7: passed (exit 0, 9.643 s)
A8: passed (exit 0, 8.442 s)
A9: passed (exit 0, 15.653 s)
A10: passed (exit 0, 16.453 s)
A11: passed (exit 0, 57.466 s)
B1: passed (exit 0, 631.509 s)
B2: passed (exit 0, 22.873 s)
B3: passed (exit 0, 14.9 s)
B4: passed (exit 0, 44.307 s)
B5: passed (exit 0, 61.697 s)
B6.1: passed (exit 0, 164.151 s)
B6.2: passed (exit 0, 2.231 s)
B6.3: passed (exit 0, 9.093 s)
B6.4: passed (exit 0, 8.39 s)
B6.5: passed (exit 0, 8.891 s)
B6.6: passed (exit 0, 9.542 s)
B6.7: passed (exit 0, 8.34 s)
B7: passed (exit 0, 1293.364 s)
B8.1: passed (exit 0, 13.417 s)
B8.2: passed (exit 0, 212.696 s)
B8.3: passed (exit 0, 6.287 s)
B8.4: passed (exit 0, 15.555 s)
B9: passed (exit 0, 1232.219 s)
B10.1: passed (exit 0, 62.136 s)
B10.2: passed (exit 0, 1.279 s)
B11.1: passed (exit 0, 14.801 s)
B11.2: passed (exit 0, 6.638 s)
```

Verbatim verdict lines from the lanes' stdout:

```
Baseline check: 0 regression(s), 0 improvement(s)
SUMMARY: total=1963 compared=1885 agree=1873 agree_nd=0 triaged=12 disagree=0 o2_agree=190 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=9 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=47 triag
Total: 7 passed, 0 failed
check_failure_reach: OK (233 pure failure sites = the 233 register rows exactly (231 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position cla
check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f
check_fuel_forms: forms partition OK (60 MEASURED + 13 ABSORBING + 2 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)
observation lane plants: 93/93 passed
test_fuel_plant: ALL PLANTS OK (FUEL classification live in exec/gcc/ci_sweep/cn_coverage/measure; negatives not FUEL; the real driver at --fuel 1 reads FUEL and at the default MATCH; --fuel 0/non-num
test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)
```

pristine-oracle lane report status: passed; rows: 723

### State at hand-over, and what the operator decides

- **Branch** `arc/are-compatible-assumed-set`: Codex's two stop records (`3f9ade56d`,
  `a91804f9e`), the orchestrator's `bbc60d6ef` (D1+D2+D4 source/proofs/registers/pins/
  tray) and the commit carrying this record + the D3 evidence. Base = mainline
  `86daea264`; fast-forwardable. lem-lean untouched (`f6542f8`).
- **The property delivered:** `Ctype_aux.are_compatible_aux` and its two siblings are
  total (the lem body change) and MEASURED without a hypothesis; the fuel-forms
  register of pending workers is `many`/`many1` only; the fork's OCaml oracle changes
  identically; the deviation from upstream is manifested (two pins) and filed as tray
  drafts 37 (patch) + 38 (the next limitation).
- **Not done, deliberately:** the tray-pinned multi-TU corpus (D4.2) — see D4 for why;
  the operator question about projecting symbol numbers out of `ERR` text stands.
- **Charter corrections** (all applied in place or recorded above): §1 "not lakefile
  roots" (wrong — every generated module is a root); D1 acceptance (a) `Specified(7)`
  (an unobserved outcome asserted; the next limitation intervened); D4.1 `--refresh`
  (strips the header; single-row edits are the practice); D4.2's lane assumption (the
  multi-TU lane compares failure text byte for byte).
- **Consequential edits outside the fence:** `Core_aux_lemMeasureProofs.lean` (dead
  `[LemFuel]` binder), `test/Unit/TotalityProofTest.lean` (regenerated pins) — both
  forced by the measured wrappers and both gate-checked.
- **Merge:** ff-only into `mdd/cerberus-lean` on the operator's per-merge sign-off after
  the unconditional pre-merge audit ask (the orchestrator proposes scope in the
  hand-over message). No push.
