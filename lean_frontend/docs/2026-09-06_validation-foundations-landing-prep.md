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
| (this record) | docs-only |

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
