# Validation-foundations landing preparation (2026-09-06)

[AGENT, orchestrator-directed worker], written 2026-09-06/07 in the worktree
`worktrees/cerberus-lean-arc/validation-foundations-land`. Quoted outputs are
verbatim; tallies marked *derived* were computed from the objects named.
This record is the last commit on the candidate and is docs-only; every gate
below ran on the commit named next to it.

## 1. The ruling, verbatim [USER 2026-09-06]

> "Agree on all points, and particularly on cleaning up the evidence
> archives. These should not be git committed, and will not be pushed. I
> don't actually hold strong value in such data which could be recreated,
> so I am fine dropping large files like this. The important thing is that
> runs can be reconstructed. Re ordering of concurrency, I think we should
> stabilize the core semantics before this, so we should revert to our
> previous ordering. Re master plan revisions dropping rulings - yes, this
> should be retained."

## 2. What the candidate is

`arc/validation-foundations-land`, created from the mainline
`mdd/cerberus-lean` = `89f7e6885` (confirmed). It replays the 14 commits of
`mdd/cerberus-lean..arc/validation-foundations` (oldest `8bb4a3433`, newest
`d607409f9`) one by one WITHOUT the evidence blobs, then adds five commits
of landing preparation. No `.lem`, semantics, baseline or pin content
changed other than the one `scripts/common.sh` content pin named in §5.

Source → replayed (each replayed commit keeps the original author, author
date and message, plus the trailer line
`Landing replay: evidence archives/large JSON dropped per [USER 2026-09-06]`;
no commit became empty, none was skipped):

| Source | Replayed | Subject |
|---|---|---|
| `8bb4a3433` | `bbb86a5f8` | docs: assess customer readiness and reproduce litmus exit-status gap |
| `6b609e4ba` | `5342f35ad` | docs: record live csmith shard-two timeout regressions |
| `6f17c8844` | `bdc6baddc` | docs: update customer readiness plan and propose validation charter |
| `e0fc7ad34` | `43b2a75dd` | Validate complete batch observations and execute the documented test ladder |
| `5d2f380de` | `bc2a1a278` | Add independent upstream oracle and complete observation callers; Tier A and G3 pass |
| `5c28b3b24` | `7347d2acb` | Add cold provider proof, failure census and release hardening; Tier A passes |
| `1066d89ee` | `4aa61a95e` | Repair capture composition and failure classification; 13 Tier A gates pass |
| `6d6cfa858` | `a192c1392` | docs: deliver validation foundations with final candidate evidence |
| `b1aa25796` | `f780a9570` | docs: hold validation foundations after fresh pre-merge audit |
| `68de6771c` | `f545cb985` | Repair audited validation failures and census attribution |
| `de9f6d361` | `8be462a89` | Preserve cancellation arriving during validation cleanup |
| `05278ae95` | `5317bc5ac` | Record repaired validation foundations candidate for second review |
| `df40f6aa1` | `297e20a44` | Review repaired validation foundations against semantics-first doctrine |
| `d607409f9` | `741b0231a` | Correct independently reviewed validation documentation |

Landing-preparation commits on top:

| Commit | Content |
|---|---|
| `d3881eac5` | evidence reconstructibility (SHA256SUMS split, README landing notes + recipes, link fixes), `.gitignore` archive rule, `lean_frontend/CLAUDE.md` recipe, LADDER row-10 prerequisite |
| `7d49efdeb` | raw-observation retention rule in `scripts/common.sh` + plants + the one content-pin move |
| `0dae55102` | master plan revision 9, handoff order pointer, response §6 erratum |
| `809189b71` | `test_gcc_capture.sh` success message (follow-up to the retention rule) |
| `6071050f7` | this record (§1–§9) |
| `ded9efef8` | the TERM/NO_COLOR diagnostic-styling repair after the orchestrator's boundary finding (§10) |
| (this update) | §10 appended, docs-only |

## 3. The drop set (derived from the source-branch blobs)

Rule applied per commit: every path under `lean_frontend/docs/` matching
`*.tar.gz` or `*.tar.zst`, and every file under `lean_frontend/docs/` whose
blob in that commit is ≥ 1,048,576 bytes. That is 31 files — 22 archives
(15 of them ≥ 1 MiB) + 9 JSON inventories ≥ 1 MiB — totalling
398,086,194 bytes. (The brief's "24-file drop set" is the ≥ 1 MiB subset:
15 archives + the 9 JSON; the seven sub-MiB archives — 564,305 / 654,066 /
659,838 / 806,150 / 316,706 / 266,601 / 76,653 bytes — fall under the
archive rule and the operator's "should not be git committed", and the
brief itself names the 316,706-byte document-review tarball as dropped.)
`audit-files.json` (1,045,192 bytes, just under 1 MiB) is kept.

| Directory | Files | Bytes |
|---|---|---|
| `validation-foundations-evidence/` | 14 (12 `.tar.gz` + `final-full.json`, `final-reporting.json`, `final-checkpoint-fast.json` … see its `SHA256SUMS.dropped`) | 161,123,767 |
| `validation-foundations-repair-evidence/` | 11 (5 `.tar.zst`, `final-checkpoint.tar.gz`, `development.json`, `full.json`, `interrupted-full.json`, `reporting.json`, `final-checkpoint.json`) | 224,447,237 |
| `validation-foundations-audit-evidence/` | 3 (`audit.tar.gz`, `checkpoint-fast.tar.gz`, `checkpoint-files.json`) | 11,855,230 |
| `validation-foundations-second-review-evidence/` | 2 (`documentation-checkpoint.tar.gz`, `review-checks.tar.gz`) | 343,254 |
| `validation-foundations-document-review-evidence.tar.gz` (top level) | 1 | 316,706 |

Every dropped file's identity line is in its directory's
`SHA256SUMS.dropped` (unchanged lines); the top-level tarball's line is in
`validation-foundations-document-review-evidence.SHA256SUMS.dropped`. Before
the split each line was checked against the source-branch blob: 30/30 `OK`;
the top-level tarball's blob hashes
`9bfc16c70ab4dde6aa49e08c71eff9cd28247f4306d7bedf6bbfdb7f1ff78ed4`, the
value its record quotes. The original bytes exist only on the local,
never-pushed branch `arc/validation-foundations` (head `d607409f9`).

## 4. Replay verification

`git diff --stat arc/validation-foundations 741b0231a` lists exactly the 31
dropped paths and nothing else; its summary line, verbatim:

```
 31 files changed, 1365734 deletions(-)
```

Author / author-date / subject parity of the 14 replayed commits against
their sources: 14/14 `SAME` (derived from `git log --format='%an|%ae|%aI|%s'`
on both ranges). Object accounting (derived; `git rev-list --objects` over
`mdd/cerberus-lean..<head>`, blobs only): `arc/validation-foundations`
introduces 269 blobs / 404,448,468 bytes over the mainline; the replayed
branch introduces 238 blobs / 6,362,274 bytes — a difference of 31 blobs /
398,086,194 bytes, the drop set exactly. `git count-objects -vH` (the
object store is shared by all worktrees, so this is the whole repository):

```
count: 2364
size: 330.55 MiB
in-pack: 121056
packs: 3
size-pack: 215.79 MiB
prune-packable: 0
garbage: 0
size-garbage: 0 bytes
```

## 5. Reconstructibility (the operator's condition)

- Each evidence README carries a dated [AGENT] landing note quoting the
  ruling, the drop rule, the per-directory drop list with sizes, where the
  identities live, and a reconstruction table: the commit to check out
  (source SHA and the byte-identical replayed SHA) and the exact runner
  invocations taken from the records — `python3 scripts/release.py --mode
  full|fast --out <new dir>`, `--mode reporting --lane C1 --lane C4`,
  `build_independent_oracle.py --lem-repo … --cerberus-repo … --out
  .validation-foundations/independent-oracle-v2` + `test_upstream_oracle.py`
  (+ `--plant`), `build_provider_smoke.py --cerberus-rev "$(git rev-parse
  HEAD)" --lem-repo … --out .validation-foundations/provider-cold` +
  `run_failure_probes.py` / `run_failure_census.py --provider-manifest
  .validation-foundations/provider-cold/manifest.json --out …`; environment
  per the records (`scripts/ce` / `source scripts/env.sh`,
  `CERB_MEM_MAX=32G`, `DUNE_CACHE=disabled`). What is not re-derivable by a
  command (the pre-merge audit reviewers' own scripts, which existed only
  inside `audit.tar.gz`; their member list and hashes remain in
  `audit-files.json`) is stated as such.
- `SHA256SUMS` in each directory now lists present files only; the two
  `SHA256SUMS` that list `README.md` were re-hashed after the note was
  added, and the pre-note hashes are recorded in the notes.
- 15 markdown hyperlinks to dropped files across 8 dated records (the
  `d3881eac5` message says 14 — a miscount; 15 is the correct tally: 3 + 3
  + 1 + 1 + 1 + 4 + 1 + 1), plus the READMEs' own rows, now name the file as dropped and point at the retained
  inventory/summary and `SHA256SUMS.dropped`.
- `.gitignore`: `lean_frontend/docs/**/*.tar.gz`, `**/*.tar.zst`,
  `**/*.tar` under a comment; deliberately no `*.json` ignore.
  `git check-ignore -v`: `lean_frontend/docs/x.tar.gz`,
  `…/validation-foundations-evidence/final-full.tar.gz`, `…/a/b/c.tar.zst`,
  `…/a/b.tar` ignored (lines 85/85/86/87); `…/final-full-summary.json` and
  `scripts/x.tar.gz` not ignored.

## 6. Raw-observation retention (assessment finding, `7d49efdeb`)

`scripts/common.sh` created `OBSERVATION_RUN_DIR` under
`.tmp/scripts/observations/` on every harness invocation and never removed it
(the Codex worktree's `.tmp` reached 5.5 GB). Rule, in the existing EXIT-trap
machinery, `register_cleanup` unchanged:

- exit 0 and `CERB_OBSERVATION_DIR` unset → the run directory is removed;
- exit ≠ 0 → kept, and `Raw observation evidence: <dir>` is printed on
  stderr (one place, every lane);
- `CERB_OBSERVATION_DIR` set (the release runner's / plant batteries'
  evidence mode) → always kept.

Fail-safe direction: anything but a clean exit 0 keeps the data; an abnormal
death that skips the trap keeps it too. `test_exec.sh`, `test_multi_tu.sh`
and `test_gcc_capture.sh` success-path messages that name the directory now
say what happens to it. Plants in `scripts/test_capture_prerequisites.py`
(the existing file that exercises real shell entry points on isolated
fixtures): a harness sourcing the copied `common.sh` run three ways, checked
on the real filesystem. Verbatim:

- new `common.sh`: `Ran 1 test in 0.046s` / `OK`; whole file:
  `Ran 3 tests in 0.271s` / `OK`.
- negative form (pre-change `common.sh` swapped in from `HEAD`, then
  restored byte-identical):
  `FAIL: test_observation_run_dir_retention_follows_exit_status_and_evidence_mode (…) (case='success')` /
  `AssertionError: True != False : success: run dir /home/dev/projects/cerberus-lean-proj/.tmp/tmp4w74llt9/.tmp/scripts/observations/harness.9bkS6DICJN exists=True, expected kept=False`;
  `FAIL: … (case='failure')` / `AssertionError: False != True : b''`
  (no evidence line printed); `FAILED (failures=2)` — the evidence-mode
  case passes either way, as it should.

Content pin: `scripts/common.sh` is in `scripts/fork_drift_manifest.txt`
`[source-content]`; refreshed through the gate's `--emit` route
(`check_fork_content.py --emit` over the manifest's `[files]` set), one line:

```
before: 100755 dc3bf76bef5af4b5591f157a336450f9cc6947709df242684513ffb02a1d849e scripts/common.sh
after:  100755 71f184f3eeb16515a828e931e669f39287a5969b9f38e47d97f29b3fc45b290a scripts/common.sh
```

No other pin moved (`git diff --numstat`: `1 1`; the 76 `[source-content]`
lines against the live emit: no difference). A full `--refresh` was NOT used:
it regenerates the manifest header and would have discarded the reviewed
notes there.

## 7. Documents (`0dae55102`)

- `2026-09-05_master-plan.md` → Revision 9, 2026-09-06 [AGENT
  orchestrator-directed]: new §0 "Operator rulings carried verbatim" (the
  [USER 2026-09-05] audit rulings copied verbatim from the response §3, the
  [USER 2026-09-06] ruling above, pointers to the rulings already verbatim
  in §1); §3 "Priority order" replaced by the response §4 order, updated for
  what is done, with the concurrency charter at step 8 as a proposal;
  revision 8's factual sections kept; every "revision 3 superseded the
  response §4" sentence now states that the §3 order IS the response §4
  order, reconfirmed [USER 2026-09-06].
- `2026-09-05_orchestrator-handoff.md`: one dated order-pointer paragraph.
- `2026-09-05_whole-project-audit-response.md` §6 Erratum (2026-09-06): the
  landing `9635592ca` lost the 12 `.log` evidence files to `.gitignore:59`
  `*.log`; facts re-checked in git; process fix: verify evidence checksums
  against `git ls-files`, never `git add` a directory holding gitignored
  evidence without `-f`/renaming.
- `lean_frontend/CLAUDE.md` build recipe: `dune install --prefix
  "$PWD/_build/local-install" cerberus-lib` (worktree-local, never the
  shared `_opam`), matching `scripts/common.sh`. `scripts/LADDER.md` Tier B
  row 10: explicit PREREQUISITE (the prepared independent build; the lane
  fails closed without it).

## 8. Gates on the candidate (env.sh sourced via `scripts/ce`, `CERB_MEM_MAX=48G`)

(a) `./scripts/test_unit.sh` (full, `CERB_FORK_DRIFT_DEV_SKIP` unset), at
`7d49efdeb` on a clean tree — the code of every later commit differs from it
only by the one-line message change in `test_gcc_capture.sh` (`809189b71`),
which the Tier A runner below re-exercised as its A1 lane. Verbatim:

```
=== test_unit.sh at HEAD=7d49efdeb7fdf1660f183fc1527bd47fc45ffda9 start 2026-09-07T00:39:25Z; dirty=0
Total: 6 passed, 0 failed
check_exec_purity: CLEAN (11 modules)
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
check_sorry_token: OK (286 files scanned comment-stripped — generated 207, hand-written+test 44, LemLib 35; 0 sorry tokens)
GCC capture: 4/4 probes passed; raw evidence /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/validation-foundations-land/.tmp/scripts/observations/test_gcc_capture.WdmHcsCMUy
Ran 18 tests in 0.068s / OK          (test_observations.py)
Ran 3 tests in 0.243s / OK           (test_capture_prerequisites.py — incl. the new retention plant)
Ran 16 tests in 3.421s / OK          (test_release.py)
Ran 5 tests in 0.002s / OK           (test_failure_census.py)
Ran 5 tests in 0.239s / OK           (test_upstream_oracle_instrument.py)
check_no_fuel_numerals: OK (293 files scanned comment-stripped; no lemDefaultFuel/driverFuel/ndDefaultFuel, no LemFuel instance, no literal fuel (F1-F6); allowed Main.lean sites seen: 4 of 4 (hand-written + generated copy))
check_lakefile_roots: OK (206 roots = 206 generated modules + the exe root Main; 85 auxiliary modules all built)
check_fuel_forms: forms partition OK (54 MEASURED + 13 ABSORBING + 8 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)
check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)
check_lem_sync: OK (src 977326511c1096013d9b1fa183500ad6487a23ac9c6edc3d3f2ff8bd11e266e0, gen 295e4f8291c9ffd57a4061dd38e8ec273f18d6c1cfe3a0465291f1a4bcff8100)
check_fork_drift: SELFTEST OK (14 plants with declared verdict/message: S1-S10 prerequisite/locale/name controls; S11 copied-content control; S12 inside-listed-file drift; S13/S14 duplicate/missing content pins; unplanted gate green)
check_fork_content: OK — 76 source files content/mode-pinned
check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin f6542f8 = lem -v)
check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)
test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)
=== test_unit.sh exit=0 end 2026-09-07T00:41:24Z; dirty=2
```

(The `dirty=2` at the end is the master-plan/handoff edits made while the
gate ran; no unit gate reads `lean_frontend/docs`. The `Ran N tests / OK`
pairs are joined on one line here for compactness; each is two lines in the
log. The `GCC capture` line names a directory that the retention rule
removed at exit 0 — the reason for `809189b71`.)

(b) `python3 scripts/release.py --mode fast --out .tmp/landing/release-fast`
at `809189b71` on a clean tree (the report directory is under the gitignored
`.tmp/` and is ephemeral — not committed; an earlier start of the same
command at `0dae55102` was interrupted by me with SIGINT after 70 s to land
`809189b71` first and recorded itself as `INCOMPLETE A1 (69.9s)` /
`fast: incomplete; 0/13 selected commands completed successfully.` — the
runner's cancellation path, kept aside as
`.tmp/landing/release-fast.aborted-at-0dae55102/`). Verbatim:

```
=== release.py --mode fast at HEAD=809189b718c52093bf326b4c8f56f3d59225af8f start 2026-09-07T00:44:17Z; dirty=0
Release evidence: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/validation-foundations-land/.tmp/landing/release-fast
RUN A1: ./scripts/test_unit.sh
RUN A2: ./scripts/test_exec.sh --check-baseline
RUN A3: ./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage
RUN A4: ./scripts/test_exec.sh --check-baseline=scripts/exec_debug_baseline.txt tests/debug
RUN A4b: ./scripts/test_exec.sh --check-baseline=scripts/exec_float_baseline.txt tests/float
RUN A4c: ./scripts/test_bytes.sh
RUN A5: ./scripts/test_libc_exec.sh
RUN A6: ./scripts/test_multi_tu.sh
RUN A7: ./scripts/test_parse.sh
RUN A8: ./scripts/test_core.sh
RUN A9: ./scripts/test_elab.sh
RUN A10: ./scripts/test_libxml2_uri.sh
RUN A11: ./scripts/test_cn_coverage.sh --check-baseline
fast: passed; 13/13 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
=== release.py exit=0 end 2026-09-07T00:50:36Z; dirty=0

Per-lane statuses (derived from the report's lane records):
A1    passed  exit=0 119.791
A2    passed  exit=0 29.172
A3    passed  exit=0 51.818
A4    passed  exit=0 22.757
A4b   passed  exit=0 18.308
A4c   passed  exit=0 3.083
A5    passed  exit=0 22.666
A6    passed  exit=0 2.081
A7    passed  exit=0 9.292
A8    passed  exit=0 8.341
A9    passed  exit=0 15.703
A10   passed  exit=0 17.104
A11   passed  exit=0 57.164
total_lane_seconds None
keys ['artifact_issues', 'artifacts_after', 'artifacts_before', 'catalogue', 'environment', 'external_inputs_after', 'external_inputs_before', 'finished_utc', 'lanes', 'membership_sha256', 'mode', 'release_certification', 'schema', 'selected', 'selection_complete', 'source_after', 'source_before', 'source_unchanged', 'started_utc', 'status', 'unrun']

Real-world state after both gate runs: `.tmp/scripts/observations/` in this worktree holds 0 run directories (the standalone test_unit.sh run's green harnesses removed theirs; the release runner's lanes kept theirs under `.tmp/landing/release-fast/<lane>/observations`, its evidence mode).
```

(c) `sha256sum -c SHA256SUMS` in each evidence directory, on the final tree:

```
validation-foundations-evidence: sha256sum -c SHA256SUMS rc=0; 13 OK, 0 not-OK
validation-foundations-repair-evidence: sha256sum -c SHA256SUMS rc=0; 20 OK, 0 not-OK
validation-foundations-audit-evidence: sha256sum -c SHA256SUMS rc=0; 6 OK, 0 not-OK
validation-foundations-second-review-evidence: sha256sum -c SHA256SUMS rc=0; 6 OK, 0 not-OK
```

(d) Link check — every relative markdown link target in `lean_frontend/docs/**/*.md`,
`lean_frontend/*.md`, `scripts/*.md` resolved against the filesystem
(`.tmp/landing/check_links.py`, ephemeral), on the final tree:

```
BROKEN lean_frontend/docs/2026-09-05_whole-project-audit-evidence/README.historical.md:23: strict-ocaml-run.log
BROKEN lean_frontend/docs/2026-09-05_whole-project-audit-evidence/README.historical.md:23: strict-lean-run.log
BROKEN lean_frontend/docs/2026-09-05_whole-project-audit-evidence/README.historical.md:24: strict-native-build.log
BROKEN lean_frontend/docs/2026-09-05_whole-project-audit-evidence/README.historical.md:24: strict-native-run.log
BROKEN lean_frontend/docs/2026-09-05_whole-project-audit-evidence/README.historical.md:26: fuel-decoy-table.log
BROKEN lean_frontend/docs/2026-09-05_whole-project-audit-evidence/README.historical.md:27: fuel-decoy-policy.log
BROKEN lean_frontend/docs/2026-09-05_whole-project-audit-evidence/README.historical.md:34: verdict-extractor-plant.log
BROKEN lean_frontend/docs/2026-09-05_whole-project-audit-evidence/README.historical.md:35: fork-manifest-order.log
BROKEN lean_frontend/docs/2026-09-05_whole-project-audit-evidence/README.historical.md:37: cerberus-unit-tail.log
BROKEN lean_frontend/docs/2026-09-05_whole-project-audit-evidence/README.historical.md:38: lem-nonlean-after-build.log
BROKEN lean_frontend/docs/2026-09-05_whole-project-audit-evidence/README.historical.md:39: lem-comprehensive-summary.log
BROKEN lean_frontend/docs/2026-09-05_whole-project-audit-evidence/README.historical.md:40: cerberus-lanes-summary.log
BROKEN lean_frontend/docs/2026-09-05_whole-project-release-gate-audit.md:113: ../../../lem-lean/lean-lib/LemLib.lean
BROKEN lean_frontend/docs/2026-09-05_whole-project-release-gate-audit.md:336: ../../../lem-lean/doc/lean-backend/2026-09-03_string-representation-design.md
BROKEN lean_frontend/docs/2026-09-06_validation-foundations-landing-prep.md:270: target
BROKEN lean_frontend/docs/2026-09-05_whole-project-audit-evidence/README.historical.md:23: strict-ocaml-run.log
BROKEN lean_frontend/docs/2026-09-05_whole-project-audit-evidence/README.historical.md:23: strict-lean-run.log
BROKEN lean_frontend/docs/2026-09-05_whole-project-audit-evidence/README.historical.md:24: strict-native-build.log
BROKEN lean_frontend/docs/2026-09-05_whole-project-audit-evidence/README.historical.md:24: strict-native-run.log
BROKEN lean_frontend/docs/2026-09-05_whole-project-audit-evidence/README.historical.md:26: fuel-decoy-table.log
BROKEN lean_frontend/docs/2026-09-05_whole-project-audit-evidence/README.historical.md:27: fuel-decoy-policy.log
BROKEN lean_frontend/docs/2026-09-05_whole-project-audit-evidence/README.historical.md:34: verdict-extractor-plant.log
BROKEN lean_frontend/docs/2026-09-05_whole-project-audit-evidence/README.historical.md:35: fork-manifest-order.log
BROKEN lean_frontend/docs/2026-09-05_whole-project-audit-evidence/README.historical.md:37: cerberus-unit-tail.log
BROKEN lean_frontend/docs/2026-09-05_whole-project-audit-evidence/README.historical.md:38: lem-nonlean-after-build.log
BROKEN lean_frontend/docs/2026-09-05_whole-project-audit-evidence/README.historical.md:39: lem-comprehensive-summary.log
BROKEN lean_frontend/docs/2026-09-05_whole-project-audit-evidence/README.historical.md:40: cerberus-lanes-summary.log
BROKEN lean_frontend/docs/2026-09-05_whole-project-release-gate-audit.md:113: ../../../lem-lean/lean-lib/LemLib.lean
BROKEN lean_frontend/docs/2026-09-05_whole-project-release-gate-audit.md:336: ../../../lem-lean/doc/lean-backend/2026-09-03_string-representation-design.md
link check: 300 relative links in 229 files, 14 broken

(Two earlier passes over this record reported 15: the 15th hit was a literal
markdown-link-shaped fragment — a close bracket followed by a parenthesised
word — in this paragraph's own prose, which the checker read as a link; the
wording was changed and the check re-run.)
```

All 14 broken links are pre-existing and unrelated to the drop: 12 are
`2026-09-05_whole-project-audit-evidence/README.historical.md`'s
deliberately preserved links to the 12 lost `.log` files (the §6 erratum
subject; nothing recreated), 2 are container-relative
`../../../lem-lean/...` paths in the release-gate audit that resolve only
from the primary checkout's location. No `.md` links to a dropped path.

## 9. What remains for the orchestrator

1. The full battery on the candidate head (`python3 scripts/release.py
   --mode full`, Tier A+B; B10 needs the prepared independent build, LADDER
   row 10), per the validation gate rule; worker-claimed green is not
   accepted.
2. The delta audit of `scripts/capped`, `scripts/common.sh`,
   `scripts/test_exec.sh` over `mdd/cerberus-lean..HEAD` (the range changes
   all three; this preparation touched `common.sh` only in the cleanup
   block).
3. Per-merge sign-off; ff-only onto `mdd/cerberus-lean` (`89f7e6885` has
   not moved as of this record — recheck).
4. After landing: prune the Codex scratch — the source worktree
   `worktrees/cerberus-lean-arc/validation-foundations/` (its
   `.validation-foundations/` and 5.5 GB `.tmp/`), the five detached
   worktrees registered UNDER it (`provider-cold-dev`, `provider-cold-dev-v2`,
   `provider-cold-final-1066d89`, `premerge-audit-20260906/cold-provider`,
   `audit-repairs-20260906/provider-functional`, all `git worktree list`
   entries), `worktrees/cerberus-upstream-validation-foundations`, and the
   branch `arc/validation-foundations` — the ONLY holder of the dropped
   archive bytes; the operator ruled they will not be pushed, and whether to
   keep the local branch as an archive or delete it is the operator's call.
   `arc/validation-foundations-concurrency` is the portable-commit companion
   for §3 step 8 and stays.
5. The container `CLAUDE.md` build block still says `opam exec --switch=.
   -- dune install cerberus-lib` (outside this repo; same drift as the one
   fixed in `lean_frontend/CLAUDE.md`).
6. The 14 pre-existing broken doc links above (disposition, not repair, is
   the question: the 12 historical ones are correct as they stand).

## 10. Orchestrator boundary finding (2026-09-07): TERM-dependent oracle diagnostics — repaired in `ded9efef8`

**Finding, verbatim** (orchestrator, independent battery on `6071050f7`;
`./scripts/test_immaculate.sh` → rc=1):

```
DEVIATION: zd-z2m01-aligned-alloc-zero-zero expected [MATCH | L=CRASH] got [INVALID | L=CRASH]
DEVIATION: zd-z2m01-aligned-alloc-zero expected [ORACLE_CRASH | L=UB:{ub: "DUMMY(align_alloc)", stderr: "", loc: "<12:28--12:47>"}] got [INVALID | L=UB:{ub: "DUMMY(align_alloc)", stderr: "", loc: "<12:28--12:47>"}]
DEVIATION: g5-decode-multichar expected [MATCH | L=CRASH] got [INVALID | L=CRASH]
```

> "Retained raw evidence (the new retention rule worked):
> `.tmp/scripts/observations/test_immaculate.RNqM2FI3dw/immaculate.CMnrVbDREw/*.oerr`.
> The oracle stderr's first line is `cerberus: internal error, ^[[31muncaught
> exception^[[m:` (ANSI SGR around "uncaught exception"), so `observations.py`'s
> exact `OCAML_ENVELOPE` match fails and the codec reports `OBSERVATION ERROR:
> engine exit 125 outside batch protocol` → INVALID."

Reproduced here: the four cited captures each decode to `OBSERVATION ERROR:
engine exit 125 outside batch protocol` under the pre-repair codec; the
retained run has 13 `.oerr` files with an ESC byte and 12 INVALID rows (the
13th, `zd-z2f04-closedir`, begins with a plain `internal error: can_advance:
…` line and the old codec absorbed the styled envelope behind it into a
CRASH message — same defect, silently). Probe on the lane's own invocation
shape (`opam exec --switch=. -- _build/default/backend/driver/main.exe
--runtime=_build/install/default --exec --batch --mode=exhaustive
tests/immaculate/libc/zd-z2m01-aligned-alloc-zero-zero.c`, both streams to
files), verbatim:

```
TERM=xterm-256color                status=125 escapes=1 first=cerberus: internal error, ^[[31muncaught exception^[[m:
TERM=dumb                          status=125 escapes=0 first=cerberus: internal error, uncaught exception:
NO_COLOR=1 TERM=xterm-256color     status=125 escapes=0 first=cerberus: internal error, uncaught exception:
TERM unset                         status=125 escapes=0 first=cerberus: internal error, uncaught exception:
```

**Root cause (measured):** Cmdliner 2.1.1 (`_opam/lib/cmdliner/META`;
`_opam/lib/cmdliner/cmdliner_base.ml:131-138`, `styler'`: `NO_COLOR`
non-empty → Plain; `TERM=dumb` or unset → Plain; any other `TERM` → Ansi)
styles its diagnostics — the uncaught-exception envelope is printed by
`cmdliner_msg.ml:103-106` with `Fmt.ereason "uncaught exception"` — from the
ENVIRONMENT, independent of isatty. Codex's recorded 32/32 ran in a sandbox
without `TERM`; the orchestrator's battery inherited `TERM=xterm-256color`
from an interactive shell: an environment-dependent gate (F4 class).
`Cerb_colour` (`util/cerb_colour.ml:34-52`) is isatty-based and every
capture redirects both streams, so it was not the culprit; it is pinned in
scope below anyway.

**Repair (`ded9efef8`, one commit):**

1. `scripts/common.sh` exports `NO_COLOR=1` and `TERM=dumb` at the top,
   before any engine/oracle/tool invocation (comment cites this finding).
   Pass-through confirmed by reading the invocation paths:
   `observation_capture` runs `"$@"` in place; `CAPPED_TEST=(env
   CERB_MEM_MAX=… scripts/capped)` and `capped` only source `env.sh` (opam
   switch + git redirects, no TERM); `opam exec` and `timeout` inherit; the
   gcc lane's `setarch -R /usr/bin/env -i bash -c …` applies to the compiled
   PROGRAM only (`test_gcc_oracle.sh:391,402`) and is untouched.
2. `scripts/observations.py`: an ESC byte (0x1b) anywhere in engine stderr
   raises `ProtocolError('styled (ANSI) diagnostics in engine stderr; the
   harness must run engines with NO_COLOR=1 / TERM=dumb')`, checked after
   the kill/timeout classifications and before any grammar match. Nothing
   is stripped or normalized.
3. `scripts/release.py`: the same pin in every lane's environment (the
   Python lanes B9/B10 do not source `common.sh`); ambient `TERM` /
   `NO_COLOR` recorded in the report's `environment` block.
   `scripts/test_upstream_oracle.py` and `scripts/run_failure_probes.py`:
   the same pin on their direct engine invocations (both decode stderr).
4. Plants. `scripts/test_observations.py`
   `test_styled_diagnostics_are_rejected_specifically_never_normalized`:
   the retained `.oerr` bytes (3,173 bytes, 25-line trace) as fixture →
   the specific error under `immaculate` / `litmus` / `batch`, behind a
   plain `internal error:` first line, and for any styled stderr line at
   status 0; the plain form decodes to
   `INTERNAL_ERROR:{msg: "Division_by_zero"}`; styled stdout stays a
   malformed record. Negative form (pre-repair `observations.py` swapped
   in, then restored byte-identical): `AssertionError: "^styled \(ANSI\)
   diagnostics …$" does not match "engine exit 125 outside batch protocol"`
   (×3), `FAILED`. `scripts/test_observation_lanes.py`: immaculate variant
   `ambient-term` (the real lane with `TERM=xterm-256color` and no
   `NO_COLOR` in its ambient environment), expected to accept.
5. Content pin `scripts/common.sh` (`--emit` route, one line):
   `100755 71f184f3eeb16515a828e931e669f39287a5969b9f38e47d97f29b3fc45b290a`
   → `100755 77f5ab3a841446962926185d3db8c0e3853fada26ff7708fdd3b47dcab0c3413`;
   no other pin moved (76 lines = live emit; `--numstat 1 1`).

**Exposure audit of oracle-stderr consumers (step 4):**

| Form (grammar / consumer) | Printer | Styled by | After the pin, under the harness | Probe |
|---|---|---|---|---|
| `cerberus: internal error, uncaught exception:` + exception + trace (`OCAML_ENVELOPE` exact match, `FATAL`; the immaculate/litmus CRASH decode) | Cmdliner (`cmdliner_msg.ml:103-106`) | `TERM` / `NO_COLOR` (environment) | plain | the four-row table above |
| Cmdliner usage/parse errors (`Usage: …`, `cerberus: unknown option …`) — status-consumed only (codec: exit outside 0/1; `test_exec.sh`: CERB_SKIP by status) | Cmdliner (`Fmt.code`/`ereason`/`missing`) | `TERM` / `NO_COLOR` | plain | `main.exe --no-such-option` under `TERM=xterm-256color`: `cerberus: ^[[31munknown^[[m option ^[[01m--no-such-option^[[m` |
| `internal error: <msg>` first line (`ORACLE_INTERNAL`; `FATAL`; `FUEL_RECORD` `internal error: lem: fuel exhausted`) | `Cerb_debug.error` (`util/cerb_debug.ml:23`, `Cerb_colour.ansi_format ~err:true [Red]`) | isatty(stdout) AND isatty(stderr) | plain — every capture redirects both streams | retained `zd-z2f04-closedir.oerr` under the ambient `TERM=xterm-256color`: line 1 `internal error: can_advance: …` has no ESC; the ESC is on line 2, the Cmdliner envelope |
| `unsupported: <msg>`, `warning: …`, `(debug N): …` | `Cerb_debug` (`ansi_format`, `err=false` → isatty(stdout) only) | isatty | plain under captures; not grammar-consumed | source (`util/cerb_debug.ml:44-54`) |
| `CERB_FRESH_FLOOR_VIOLATION …` (`test_exec.sh` CERB_FLOOR substring class) | `prerr_endline` (`util/cerb_fresh.ml:66`, `backend/common/ail_sym_hwm.ml:322`) | never | plain | source (plain `Printf.sprintf` + `prerr_endline`) |
| `Fatal error: exception …` (`FATAL`) | OCaml runtime default handler | never | plain | source |
| `PANIC at …` (`LEAN_PANIC`, `FATAL`, `IMMACULATE_PANICS`) | Lean runtime | never | plain | retained `.lerr` files under the ambient `TERM`: `escapes=0` (g2-memcmp-uninit, g4-bswap64-overflow, g5-decode-multichar, offsetof-union-member) |
| `capped: OOM-KILLED …` (`CAP_OOM`) | `scripts/capped` | never | plain | source |
| verdict lines and `Error {msg: …}` refusals (cn_coverage/verify/ci_sweep/multi_tu/gcc/exec) | engine stdout protocol | n/a | unchanged | — |

Consumers covered: `observations.py` (`observation_tokens` / `compare` in
exec, multi_tu, cn_coverage, verify, ci_sweep, gcc, immaculate, speclab*,
libc_exec, libxml2*, bytes), `test_exec.sh` CERB_FLOOR/CERB_SKIP,
`test_upstream_oracle.py` (codec), `run_failure_probes.py`. Argument: after
the pin every engine invocation runs with `NO_COLOR=1 TERM=dumb` and both
streams redirected, so no consumed form is styled; if one ever is, the
codec's ESC rejection names it instead of mis-classifying. Not pinned:
`build_provider_smoke.py` / `build_independent_oracle.py` (build logs are
hashed, never grammar-decoded; dune's own styling is isatty-gated).

**Gates on `ded9efef8`**, `TERM=xterm-256color` exported and `NO_COLOR`
unset in the shell (the point of the exercise), run while the
orchestrator's own re-verify battery (`/home/dev/projects/cerberus-lean-proj/.tmp/vf-reverify.sh`,
same worktree; in its libxml2 → observation-lanes phase, gcc last) was
still running — the overlap is recorded, not hidden (32 cores; load 13 at
start). Verbatim:

```
=== regate at HEAD=ded9efef8833c95dd21a293830af7f1ab9179d94 start 2026-09-07T01:19:59Z; ambient TERM=xterm-256color NO_COLOR=unset; dirty=0; load=10.32 6.15 3.72; concurrent: orchestrator battery pid 1053920 (/bin/bash ./scripts/test_libxml2.sh)
=== ./scripts/test_unit.sh
Total: 6 passed, 0 failed
Ran 19 tests in 0.064s
check_fork_content: OK — 76 source files content/mode-pinned
check_fork_drift: OK — layer 1: 76 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 22 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin f6542f8 = lem -v)
check_fixture_freeze: OK (16 fixture files match the pinned manifest; name set exact)
test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)
=== test_unit.sh exit=0 2026-09-07T01:22:01Z
=== ./scripts/test_immaculate.sh
  MATCH          g5-decode-multichar   O[CRASH] L[CRASH]
  MATCH          g2-memcmp-uninit      O[CRASH] L[CRASH]
  MATCH          zd-z2f04-closedir     O[CRASH] L[CRASH]
  ORACLE_CRASH   zd-z2m01-aligned-alloc-zero  O[CRASH] L[UB:{ub: "DUMMY(align_alloc)", stderr: "", loc: "<12:28--12:47>"}]
  MATCH          zd-z2m01-aligned-alloc-zero-zero  O[CRASH] L[CRASH]
OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
=== test_immaculate.sh exit=0 2026-09-07T01:23:20Z
=== python3 scripts/test_observation_lanes.py --lane immaculate
PLANT OK   immaculate: control
PLANT OK   immaculate: bytes
PLANT OK   immaculate: lean-exit2
PLANT OK   immaculate: descendant-oom
PLANT OK   immaculate: oracle-exit2
PLANT OK   immaculate: crash-fuel
PLANT OK   immaculate: crash-garbage
PLANT OK   immaculate: crash-other
PLANT OK   immaculate: ambient-term
observation lane plants: 9/9 passed
=== obs-lanes exit=0 2026-09-07T01:42:37Z
=== release.py --mode fast (alone) at HEAD=ded9efef8833c95dd21a293830af7f1ab9179d94 start 2026-09-07T01:42:38Z; ambient TERM=xterm-256color NO_COLOR=unset; dirty=0; load=8.12 12.85 12.35; other dune/lane processes: 0
fast: passed; 13/13 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
=== release.py exit=0 2026-09-07T01:49:26Z; dirty=0; load=8.75 9.17 10.69
report.json environment (ambient, recorded): TERM=xterm-256color NO_COLOR=None; lanes: A1 passed 127.3s, A2 passed 28.5s, A3 passed 55.8s, A4 passed 23.6s, A4b passed 19.6s, A4c passed 3.5s, A5 passed 25.5s, A6 passed 2.3s, A7 passed 10.0s, A8 passed 9.4s, A9 passed 17.6s, A10 passed 19.8s, A11 passed 62.8s
```

Notes. (1) A first `release.py --mode fast` on this head (01:23:20–01:29:31,
while the orchestrator's battery was in its observation-lanes phase in the
same worktree) ended `fast: failed; 10/13 selected commands completed
successfully.`: A5 `test_libc_exec.sh`, A7 `test_parse.sh` and A8
`test_core.sh` each died after 0.13 s in `build_cerberus` with dune's
`Error: Another Dune instance is currently running. Aborting...` — the two
batteries share this worktree's `_build/` and dune's lock (the other
battery's lanes reach dune through the `SKIP_BUILD=1` freshness checks
`tools/check_lem_sync.sh` / `tools/check_driver_fresh.sh` and their build
steps), and `build_cerberus` fails closed there rather than proceeding on a
possibly half-built tree — correct behaviour, not a lane result; their run
directories were kept and their paths printed (the §6 retention rule,
witnessed). That report is kept aside at `.tmp/landing/release-fast-2/`;
`test_parse.sh` alone under the same `TERM` passed (`ALL PASSED`, rc=0); the
standalone rerun above, with no other dune or lane process on the box, is
the gate. (2) The `Ran 19 tests` line is `test_observations.py` inside
`test_unit.sh` (18 + the new styled-diagnostics test). (3) The orchestrator's
own battery on `6071050f7` is superseded by this head; its retained
observation directories under `.tmp/scripts/observations/` (18 at the time
of writing) are theirs to inspect or delete. (4) The earlier record
commits' claim that `common.sh` moved one pin still holds per commit; the
pin has now moved twice on this branch (`dc3bf76b… → 71f184f3…` in
`7d49efdeb`, `71f184f3… → 77f5ab3a…` in `ded9efef8`).

## 11. Orchestrator boundary battery on the final head (2026-09-07)

[AGENT orchestrator]. Independent of the worker's gates: the detached
script `.tmp/vf-reverify.sh` (ephemeral, deleted with this commit) ran the
LADDER Tier A + Tier B battery plus the branch's two new Tier B rows on
`df6b20ee1` in THIS worktree, alone (a first attempt on `6071050f7` was
stopped when the repair worker started re-gating in the same worktree;
its 23 green lanes and the immaculate red that became §10 are superseded).
Environment: an ordinary interactive-derived shell — `TERM=xterm-256color`,
`NO_COLOR` unset, `LANG=en_US.UTF-8` — i.e. the condition under which the
pre-repair codec failed. Cache-disabled rebuild first
(`recorded oracle stamp (bin b896aa287b7f` / `recorded lean stamp (bin 32f8b3427f02`).

Every lane rc=0 (verbatim `=== lane` / `--- rc=` pairs from the log):
    === bash tools/check_driver_fresh.sh --check  rc=0
    === ./scripts/test_unit.sh  rc=0
    === ./scripts/test_exec.sh --check-baseline  rc=0
    === ./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage  rc=0
    === ./scripts/test_exec.sh --check-baseline=scripts/exec_debug_baseline.txt tests/debug  rc=0
    === ./scripts/test_exec.sh --check-baseline=scripts/exec_float_baseline.txt tests/float  rc=0
    === ./scripts/test_bytes.sh  rc=0
    === ./scripts/test_libc_exec.sh  rc=0
    === ./scripts/test_multi_tu.sh  rc=0
    === ./scripts/test_parse.sh  rc=0
    === ./scripts/test_core.sh  rc=0
    === ./scripts/test_elab.sh  rc=0
    === ./scripts/test_libxml2_uri.sh  rc=0
    === ./scripts/test_cn_coverage.sh --check-baseline  rc=0
    === ./scripts/test_parse.sh tests/ci  rc=0
    === ./scripts/test_core.sh tests/ci  rc=0
    === ./scripts/test_verify.sh  rc=0
    === ./scripts/test_immaculate.sh  rc=0
    === ./scripts/test_speclab.sh --selftest  rc=0
    === ./scripts/test_speclab.sh --plant  rc=0
    === ./scripts/test_hang_plant.sh  rc=0
    === ./scripts/test_kill_plant.sh  rc=0
    === ./scripts/test_fuel_plant.sh  rc=0
    === ./scripts/test_libxml2.sh  rc=0
    === python3 scripts/test_observation_lanes.py  rc=0
    === independent oracle build (branch recipe)  rc=0
    === python3 scripts/test_upstream_oracle.py  rc=0
    === python3 scripts/test_upstream_oracle.py --plant  rc=0
    === ./scripts/test_gcc_oracle.sh --check-baseline  rc=0

Verdict lines, verbatim:

```
check_driver_fresh: oracle OK (bin b896aa287b7f3543600c59277c517472093be412fe3ddf8ff689f59567b83bb8, src 46d26f1f7ede22ffb6d3ff563194b8423a297775cef211805388c6c88217efda)
check_driver_fresh: lean OK (bin 32f8b3427f023ad78afc27fd170284cf09c2b331751652ef588d8d0061a62ad6, src 89a31871cc2e83121d7efb009c35aa6c50216b31f6dad88cee4688b0786edf28)
test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)
SUMMARY: total=106 match=85 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=3 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
SUMMARY: total=69 match=69 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
SUMMARY: exec_match=9 neg_pinned=5 fail=0
SUMMARY: match=12 diff=0
ALL MATCH RECORDED BASELINE
SUMMARY: total=2 match=2 fail=0
SUMMARY: total=106 same=103 diff=3 ocaml_fail=0 lean_fail=0
SUMMARY: total=213 match=207 ub_match=6 ub_diff=0 reject_match=0 diff=0 mismatch=0 reject_diff=0 lean_fail=0 lean_crash=0 fuel=0 lean_error=0 lean_timeout=0 oracle_fail=0 oracle_timeout=0 oracle_inconsistent=0
BASELINE OK (213 entries, exact match)
test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)
OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
test_fuel_plant: ALL PLANTS OK (FUEL classification live in exec/gcc/ci_sweep/cn_coverage/measure; negatives not FUEL; the real driver at --fuel 1 reads FUEL and at the default MATCH; --fuel 0/non-numeral/out-of-position/missing refused)
SUMMARY: total=4 match=4 fail=0 (points: 1354, 22 observations each)
observation lane plants: 91/91 passed
Independent oracle: passed; {'semantic_agreement': 709, 'reviewed_difference': 1, 'matching_failure': 11, 'interface_agreement': 2}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/validation-foundations-land/.tmp/upstream-oracle-q9q21hlp/report.json
check_driver_fresh: oracle OK (bin b896aa287b7f3543600c59277c517472093be412fe3ddf8ff689f59567b83bb8, src 46d26f1f7ede22ffb6d3ff563194b8423a297775cef211805388c6c88217efda)
Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-arc/validation-foundations-land/.tmp/upstream-oracle-ik58hik9/report.json
SUMMARY: total=1963 compared=1885 agree=1873 agree_nd=0 triaged=12 disagree=0 o2_agree=190 skip_gcc_compile=1 skip_gcc_stdout=1 skip_lean_crash=9 skip_lean_fail=9 skip_lean_timeout=11 skip_ub=47 triaged_addr=11 triaged_ub=1
Baseline check: 0 regression(s), 0 improvement(s)
```

Derived: zero baseline movement in every baseline lane; gcc second oracle
`agree=1873 disagree=0`, `0 regression(s), 0 improvement(s)`; the pristine
oracle lane `semantic_agreement: 709, reviewed_difference: 1,
matching_failure: 11, interface_agreement: 2` and its plant `plant_rejected: 1`;
observation-lane plants `91/91 passed`; immaculate `OK: lane matches the
committed baseline` under the ambient colour terminal (§10's defect closed).
Not run here: csmith corpus shards, ci_sweep, libxml2 beyond the battery
row — unchanged from the mainline's last runs; the C1/C4 reporting
measurements are the branch's own records.
