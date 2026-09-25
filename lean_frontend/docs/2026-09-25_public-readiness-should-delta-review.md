# Public-readiness SHOULD block — independent delta review (cerberus-lean)

[AGENT — independent delta review, third pass, Claude Fable subagent, 2026-09-25]

**Range reviewed:** `c13a105..57ed81ca7` on `cleanup/public-readiness-should-20260925`
(verbatim `git log --oneline c13a105..57ed81ca7`):

```text
57ed81ca7 S1-S5/S7-S8/M8-M9: reconcile public docs and record verified follow-up
4e875defb S6/S9/S10/version: enforce portable gates and re-pin verified Lem once
```

`57ed81ca7` touches only documentation (`README.md`, `lean_frontend/{CLAUDE,README,SUPPORTED,TODO,VALIDATION}.md`,
`docs/upstream-tray/INDEX.md`, `scripts/LADDER.md`, NEW
`docs/2026-09-25_public-readiness-followup.md`), so `4e875defb` is the
implementation head the records cite. Context: the MUST heads LANDED
([USER 2026-09-25] "Go ahead with merge as planned"); mainline
`mdd/cerberus-lean` = `27c7ff717` = `c13a105` + `3dd6d1f71` (landing note,
+27 lines to `docs/2026-09-24_public-readiness-closure.md`) + `d048e2651`/`27c7ff717`
(orchestrator note, docs-only). Claims under test: the remediator's
`docs/2026-09-25_public-readiness-followup.md` (read first; claims are claims).

**What I did / did not do:** read-only measurement from the audit worktree
(`git show/diff/grep/ls-tree`, Python tallies); no `lake/dune/make/opam/lem`;
the SHOULD worktree was not entered. Every gate verdict quoted from the
record is the remediator's claim; the orchestrator gates that worktree
separately. Tallies I computed are labelled **derived**. Grades: P1 blocks
merge; P2 fix before merge; P3 after; N note.

---

## Findings, most severe first

### A1 — ANNOUNCEMENT BLOCKER CANDIDATE (operator; not a code finding) — external issue creation appears restricted

The follow-up record, "M9 and announcement exits": the anonymous GitHub
issue pages for both `OathTech/lem-lean` and `OathTech/cerberus-lean`
"show “Issue creation is restricted in this repository”; the operator was
asked to check external issue creation while signed in." Every public page
in this range routes fork defects to
`https://github.com/OathTech/cerberus-lean/issues` (`lean_frontend/README.md:115`,
`SUPPORTED.md:61-62`). If external users cannot open issues, the advertised
reporting route is dead on announcement day. Operator action: verify from a
signed-out or non-member account (or change the repository setting) BEFORE
announcing; this review cannot check it offline.

### G1 — P3 — `check_fork_drift.sh` keeps one container instruction in the very script S10 cleaned

`scripts/check_fork_drift.sh:255` (at `57ed81ca7`):
`fail "--refresh needs lem on PATH to record [meta] lem-pin (source scripts/env.sh)"`.
Verified by the whole-tree grep (section 3). Fix: `(run under opam exec --switch=. --)`.

### G2 — P3 — F11 residue: `lean_frontend/DESIGN.md:3` still cites `abe505d3d` as the implementation checked

Every other front page moved to `4e875defb0cce250e841723c1be7ecb7c2240150`
(`README.md:8,19`, `lean_frontend/README.md:3`, `VALIDATION.md:3`,
`SUPPORTED.md:3`, `CLAUDE.md:4,316`, `TODO.md:9`); `DESIGN.md` was not in the
range. One-line fix.

### G3 — P3 — the record's executed build dropped the README's `--prefix`, without labelling the deviation

`followup` "Executed build and gate commands", `cold-build.sh` line 3:
`opam exec --switch=. -- dune install cerberus-lib` (no `--prefix`); the
MUST rounds' `cold-build.sh` had `--prefix "$PWD/_build/local-install"`.
The PUBLIC recipe is intact: `lean_frontend/README.md:98`
`opam exec --switch=. -- dune install --prefix "$PWD/_build/local-install" cerberus-lib`
(also `CLAUDE.md` "Install worktree-locally, including when _opam is a
shared symlink"). Harmless in the remediator's physically copied `_opam`,
but the README line as published was not the line measured this round, and
the record's "Commands below are the executed commands, including local
validation adaptations" does not name this one. Fix: a sentence in the
record, or re-run the one command with `--prefix` (cheap; `common.sh:211`
performs the same install during lanes anyway).

### G4 — P3 (deferred residuals, all outside the public path) — 31 non-record container-coupling hits remain

Whole-tree grep at `57ed81ca7` for `/home/dev|scripts/ce|scripts/env.sh|cerberus-lean-proj`,
excluding `lean_frontend/docs/` (dated records/evidence: tens of thousands of
recorded absolute paths, e.g. 23,446 in `2026-09-22_run-digest-as-state-evidence/`,
all data), `tests/ci_sweep/results/*.tsv` (750 recorded result rows) and
`tests/parity-probes/sweep-2026-08-30/` (dated sweep rows) — 31 hits, classified:

| Hit(s) | Class |
|---|---|
| `scripts/check_fork_drift.sh:255` | diagnostic message in a row-1 gate → **G1** |
| `scripts/measure_csmith_cpu.py:4,168` (`raise ValueError("source the container scripts/env.sh first")` after a `GIT_CONFIG_GLOBAL` test at `:167`); `tests/mem-scale-probes/measure.sh:85` (`[[ -n "${GIT_CONFIG_GLOBAL:-}" ]] \|\| … exit 2`) | **hard requirements** in Tier-C / probe instruments, not reachable from README/LADDER Tier A |
| `scripts/ensure_independent_oracle.py:18`; `scripts/test_{fuel,hang,kill}_plant.sh:26/22/28`; `tests/mem-scale-probes/run_all.sh:8`, `measure.sh:43`; `tests/noodle-probes/**`, `tests/parity-probes/**`, `tests/z2-probes/run_z2.sh:15`, `tests/failure-probes/reach/README.md:11`; `lean_frontend/speclab/README.md:74` | usage comments / probe READMEs (`scripts/ce …` invocations); `run_noodle.sh:58,67`, `run_dynaddr.sh:69`, `run_z2.sh:56`, `run_all.sh:45` filter a `cerberus-lean-proj env:` banner line from outputs (harmless) |
| `lean_frontend/CLAUDE.md:314` | negative statement ("No parent `scripts/env.sh` …") — fine |
| `Makefile:327-341` (`rebuild-lem` comment: "container worktree deps/lem-pinned", "container CLAUDE.md") | grep-invisible to the pattern; maintainer target, comment still container-coupled |

`scripts/ci_lean.sh:12-14` (the one public-reachable hard requirement I
flagged in the MUST review, F4) is GONE and the file is `100755` (verified:
`git ls-tree` `100644 → 100755`, diff `−4`). `scripts/LADDER.md:68` row 10
now provisions the pristine oracle with `opam exec --switch=. -- python3
scripts/ensure_independent_oracle.py --lem-repo … --cerberus-repo "$PWD"`
(no `scripts/ce`). Public front pages: zero hits. **F4 closed for the public
path; the table above is the SHOULD-after residue.**

### G5 — N (operator decision) — the ISO-fix register's "filed upstream" criterion is unmet for all four register rows

`VALIDATION.md:240-245` (new): "several entries below have prepared
reports, not filed issues … Filing remains an operator action, so the
presence of a register row does not establish every policy condition."
Cross-checked against the new INDEX status table: the register's tray
reports 10, 11, 13 and 40 are all **Draft**; the only **Filed** report is 01
(`Cerberus #1009`, not a register row). The [USER 2026-09-03]-ratified
licence (criteria (i)–(vii)) includes upstream filing. Honest disclosure,
correctly done (S4); the substance — file the four, or re-adjudicate the
criterion — is the operator's.

### G6 — N — provenance tag missing on the new manifest NOTE group

`scripts/fork_drift_manifest.txt:1-7` (the "follow-up single re-pin" and
"S10/version" NOTE lines) carry dates and the base commit but no `[AGENT]`
tag; the closure group at `:8` has one. One-token fix.

### G7 — N — `tools/gen_version.ml` on the fork-drift SURFACE: right layer, with one consequence

It is an upstream file the oracle build consumes (`ocaml_frontend/dune:17`
`(run ocaml -I +unix unix.cma %{dep:../tools/gen_version.ml})`), now
fork-modified; layer 1 requires every fork-vs-upstream difference on a
surface to be manifested and layer 3 pins its bytes — the manifest's stated
scope includes "build/runtime helpers". Correct placement. Consequence: an
upstream change to `tools/gen_version.ml` will now surface at layer 1 and
force a reviewed manifest update — intended.

### G8 — N — S9 mode parsing detail (correct, noting the semantics)

`ENFORCE="${ENFORCE-1}"` (not `:-`): unset → `1` (enforce); an EMPTY value is
kept and rejected by the `case` (`exit 2`, "ENFORCE must be 0 or 1") — plant
"empty mode" covers it. The `SCANNER FAILED … exit 1` path (`:143-147`)
precedes the mode branch, so it fails under `ENFORCE=0` too, as the header
claims; no plant exercises scanner-failure-under-report-only (the
enforce-mode plant does).

---

## (1) S9 — totality gate enforces by default

`scripts/check_exec_totality.sh` diff (`+16/−x`): header now "default /
ENFORCE=1 — exit 1 …; ENFORCE=0 — explicitly labelled report-only mode;
scanner errors still fail"; code `:37-43`:

```bash
ENFORCE="${ENFORCE-1}"
case "$ENFORCE" in
  1) ;;
  0) echo "check_exec_totality: REPORT ONLY (ENFORCE=0; findings do not fail this invocation)" ;;
  *) echo "check_exec_totality: FAIL — ENFORCE must be 0 or 1" >&2; exit 2 ;;
esac
[[ -f "$ALLOW" ]] || { echo "check_exec_totality: FAIL — missing allowlist $ALLOW" >&2; exit 1; }
```

and the trailer `echo "check_exec_totality: REPORT ONLY (ENFORCE=0)"; exit 0`
replaces "reporting mode (sweep in progress)". Invalid mode → 2, missing
allowlist → 1, findings/stale rows → 1 in enforce mode. ✓

`scripts/test_exec_totality.py` (NEW, 57 lines): builds a scratch tree
(`scripts/`, `lean_frontend/generated/*.lean` copied, `lean_frontend/CerbND.lean`,
the allowlist) and runs **the production script bytes** (`shutil.copyfile(root/"scripts/check_exec_totality.sh", gate)`;
`subprocess.run(["bash", str(gate)] …, timeout=30)`) — not a
re-implementation. Plants (each asserts rc AND message, else
`AssertionError`): baseline control `CLEAN`; planted `partial def
readinessPlant` → rc 1 `PARTIAL Core_eval.readinessPlant` (default
enforces); `ENFORCE=0` → rc 0 `REPORT ONLY` (report-only really tolerates);
`ENFORCE=true` → 2; `ENFORCE=` → 2; stale allowlist row → 1 `STALE allowlist
entry`; allowlist deleted → 1 `missing allowlist`; `Core_eval.lean` deleted
→ 1 `MISSING`; PATH-shimmed `python3` exiting 2 → 1 `SCANNER FAILED`;
restored control `CLEAN`. **8 plants + 2 controls, as claimed; fail-closed
(an uncaught assertion is a non-zero exit); the scratch tree needs a
populated `generated/`, which row 1 has.** Wiring: `scripts/test_unit.sh:272-280`
runs `bash …/test_version.sh` then `python3 …/test_exec_totality.py` then
`ENFORCE=1 "$TOTALITY_SH"` — each failing with its own message. ✓

## (2) S6 — `check_lakefile_roots.sh`

Diff: `set -uo pipefail` + `export LC_ALL=C` at the top (so parsing,
`sort` and `comm` share the C locale regardless of the caller — the
"baseline green under en_US.utf8" claim holds by construction); `roots_of`
failure → "cannot parse/sort roots"; `[[ -d "$gen" ]]` check; the old
`ls "$gen"/*.lean 2>/dev/null | …` replaced by `find … -printf | sed | sort || { …; return 1; }`
(a `2>/dev/null` REMOVED); both `comm` calls `|| { echo "… comm comparison failed"; return 1; }`
(exit status of `$(…)` is `comm`'s, so `||` fires). Plant 4: a PATH-shimmed
`comm` exiting 2 must yield "comm comparison failed" and rc≠0; selftest
line now "4 plants red, baseline green". ✓ Record's claim (verbatim):
`check_lakefile_roots: SELFTEST OK (4 plants red, baseline green)` under
`LC_ALL=en_US.utf8`.

## (3) S10 — portability

`check_fork_drift.sh`: `resolve_upstream_tree` is now
`printf '%s\n' "${CERB_UPSTREAM_TREE:-}"` (both relative candidates and the
`/home/dev/…` fallback deleted); missing-ref help now
`git remote add upstream https://github.com/rems-project/cerberus.git` /
`git fetch upstream master:refs/remotes/upstream/master`; layer-2 message
"set CERB_UPSTREAM_TREE; see lean_frontend/VALIDATION.md provisioning
instructions"; `tools/gen_version.ml` added to `SURFACES`. The fail paths
are untouched (missing ref/tree/manifest → FAIL; `CERB_FORK_DRIFT_DEV_SKIP=1`
remains the only, loud, opt-in) — no new skip. Residual: **G1**.
`ci_lean.sh`: `GIT_CONFIG_GLOBAL` block deleted, mode `100755`. ✓
`tools/check_{driver_fresh,handwritten_sync,lem_sync}.sh`: help text →
"From the repository root, with the README local opam switch: opam exec
--switch=. -- …" (their three content pins move in the manifest, as the
NOTE says). VALIDATION.md gains "Provisioning the fork-drift oracle"
(`:1090-1124`): public clone of `rems-project/cerberus`, `checkout --detach
$(sed -n 's/^merge-base=//p' scripts/fork_drift_manifest.txt)`,
`opam exec --switch="$fork_root" -- make -C "$upstream_source" prelude-src`
(the pristine tree built with the FORK lem — the layer-2 contract), then
`export CERB_UPSTREAM_TREE=…`. The record reports validating exactly this
recipe from a scratch clone and pointing row 1 at it: layer 2 "30 differing
generated files, all hash-pinned" — i.e. the freshly derived pristine tree
reproduces the manifest hashes. Whole-tree grep classification: **G4**.

## (4) Version identity

`tools/gen_version.ml` (`+3/−2`): `git describe --dirty --always` →
`git describe --long --dirty --always` (`--long` forces
`<tag>-<n>-g<hash>` even at an exact tag, so the hash is always present;
`--always` keeps the bare hash when no tag is reachable); the date now
`git show --no-patch --format="%ci" HEAD` (was: resolve the describe output
as a rev). Rule as stated. Consumed only by `ocaml_frontend/dune:17`
(the oracle's `version.ml`); `lakefile.toml` `[[lean_exe]]` count 17 → 17 —
**no new Lean CLI**. `scripts/test_version.sh` (NEW): isolated scratch repo
with `GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_COUNT=0`,
fixed author/committer, runs the production generator via
`ocaml -I +unix unix.cma "$root/tools/gen_version.ml"`; asserts
`git-<short>` (untagged), `git-release-test-0-g<short>` (exact annotated
tag), `…-dirty`, `git-release-test-1-g<short>` (post-tag), and `unknown` when
`.git` is moved away (archive fallback) — `set -euo pipefail`, so any
mismatch or missing `ocaml` fails closed. Wired into row 1
(`test_unit.sh:272`). SURFACE placement: **G7**. Record's claim, verbatim:
`test_version: OK (untagged, exact annotated tag, dirty tag, post-tag, archive fallback)`.

## (5) The re-pin to `67ec5de70e02e280bb348a4ba826696b76116732`

All five sites (verbatim `git grep`): `lakefile.toml:70`,
`lake-manifest.json:8,11`, `speclab/lake-manifest.json:15,18`,
`tests/mem-scale-probes/micro/lake-manifest.json:15,18`,
`fork_drift_manifest.txt:416` `lem-pin=67ec5de70e02e280bb348a4ba826696b76116732`
(full 40-hex). `6b20bfd` survives only in history NOTE lines and `TODO.md:548`
(a dated statement). Sorted-set diff of the manifest `c13a105..57ed81ca7`
(derived): the `lem-pin` line; NEW `[files]` row `tools/gen_version.ml`;
NEW `[source-content]` row `100644 792b3cf7… tools/gen_version.ml`; the three
tool hashes (`check_driver_fresh` `e46f9aac→50ad2019`, `check_handwritten_sync`
`e2d0b6b7→98b24dd3`, `check_lem_sync` `9a07e1a9→e05d28dd`); eight NOTE
comment lines. `[files]` 84 → 85, `[source-content]` 84 → 85,
`[expected-*]` unchanged (10 cosmetic / 20 semantic). Header retained → no
`--refresh`. ✓ README `--prefix`: present (`:98`) — **G3** is about the
record's measurement, not the recipe. lem-lean `6b20bfd..67ec5de` =
`003c188` (M8 notices), `fd048db` (`src/lean_backend.ml` +24/−x,
`lean-lib/LemLib.lean` 2 lines — `never_extract` on the fuel-exhausted
wrapper, per the record — tests, `scripts/capped`, `opam`), `67ec5de`
(docs); `git describe --always 67ec5de` → `67ec5de` (7 chars; the F1
prefix rule admits it, and the record's own run shows `lem -v 67ec5de7`).
LemLib changed, so the Lean runtime dependency changed even though the
record reports generated trees byte-identical (`gen f4893e95…` for Lean,
`b79e328e…` for OCaml — the same stamps as the closure run) — orchestrator
to re-derive.

## (6) Documentation

**`lean_frontend/CLAUDE.md` (−147/+x):** removed — the container build
block (Lake deps "resolved offline via deps/gitconfig redirects", bare
`make lean-prelude-src`, `lake build cerberus-lean` exe-only, `opam exec --
dune …` without `--switch=.`, the long `dune install`/`cerberus.install`
caveat prose, `make rebuild-lem` via `deps/lem-pinned`); replaced by the
README-consistent sequence (`opam exec --switch=. -- make prelude-src
lean-prelude-src`, `dune build … cerberus-lib.install`, `dune install
--prefix "$PWD/_build/local-install" cerberus-lib`, `dune build cerberus.install`,
capped `make lean-native-obj`, `lake build CerberusLean cerberus-lean`,
speclab). "Unit tests (fast, hermetic, no OCaml)" → "Unit executables and
row-1 gates … also builds/checks the OCaml oracle and needs the explicit
fork-drift prerequisites" (true: row 1 runs `check_fork_drift`);
`core-parser-test — 292 checks` (matches `Done: 292 passed` in the
orchestrator's earlier logs); the `St` all-state claim qualified (S5);
Status: SC prototype/feature branches "parked", `sorry` reps "refused by
the backend, including in the excluded CMM surface". Every remaining
command is `opam exec --switch=. --`-prefixed or Lake-under-`capped`; I
found no instruction that the new scripts would fail. Header cites
`4e875defb`/`67ec5de` ✓.

**`SUPPORTED.md`:** header → `4e875defb` + `67ec5de` with follow-up/
remediation/closure links; NEW "Reproduce the supported demonstration":
"default **sequential**, concrete-memory LP64 pipeline", "row 1
(`test_unit.sh`) plus minimal, coverage, debug, float, bytes and libc lanes",
projections named, exclusions ≠ agreement, issue link with required
inputs, "only entries labelled Filed have recorded submission evidence".
**F5 CLOSED.** **F11:** closed everywhere except `DESIGN.md:3` (**G2**);
the right commit is `4e875defb` (implementation head; `57ed81ca7` docs-only).

**`TODO.md`:** header reconciled at `4e875defb`/`67ec5de`; the master plan
labelled historical; `[USER 2026-09-24] "FYI, I have concluded the
concurrency branch prototype has failed, and I'm working on a remediation.
But that dependency should be considered dead for now."` quoted (operator
chat; consistent with the orchestrator's brief); "Delivered program data:
run digest and enum map" section (D-S/E-A delivered; cerberus-sl adoption
instructions retained); the `sorry` target_rep items → CLOSED (two entries
folded into one); the effect-axiom item → CLOSED with the digest/enum
seams stated correctly; the three `ctype_aux` PENDING rows → "left the
register on 2026-09-10; the current register is empty" (true: 0 rows);
`refined-cerberus` → `cerberus-sl` in four current-facing lines, with the
2026-09-16 retirement. `item 7` mentions remain the charter/consumer
cross-references (`:76`, `:368`) — the run-digest/enum work is the
"Delivered" section, not an open item. ✓

**`docs/upstream-tray/INDEX.md`:** per-report table, derived tally by
script: **49 status rows = 48 Draft + 1 Filed** (01 → `Cerberus #1009`,
2026-08-19), 0 Sent, 0 Closed; report files by `git ls-tree -r` excluding
INDEX/README: **49** (45 top-level + `lean4/01,02` + `lem/01` + `ocaml/01`) —
the table is complete. Issue 1010 noted as outside the count. ✓ (**G5**
for the register consequence.)

**`scripts/LADDER.md`:** orientation paragraph (smoke / row 1 + six / all
Tier A / A+B), CI entry `opam exec --switch=. -- ./scripts/ci_lean.sh`,
"No custom global Git configuration is required", row 10's provisioning
without `scripts/ce` / `new-worktree.sh`. ✓ **`VALIDATION.md`:** "filed
upstream" → "recorded in the upstream tray … distinguished" (S4), ISO-fix
register policy paragraph (**G5**), concurrency wording ("parked", ruling
in TODO), provisioning section (§3). **`README.md`:** badges labelled
upstream-only (S3), implementation cite `4e875defb`. **`lean_frontend/README.md`:**
M8 licensing paragraph (LemLib not "BSD-only"; NOTICE/LICENSE links at the
pinned Lem), "Validation levels and prerequisites" (S8: exact seven
commands for row 1 + six lanes; `release.py --list`; `ci_lean.sh --mode
fast/full`; reporting mode), `capped` prose now also documents the 64G
default and `CERB_JOB_CGROUP` (verified present in `scripts/capped:103,134`
at `c13a105`; `capped` unchanged in range), `--version` hash-at-tag
statement matching `--long`, `bash scripts/test_version.sh`.

**Dated records:** `git diff --name-status c13a105 57ed81ca7 -- lean_frontend/docs/`
→ only `A …/2026-09-25_public-readiness-followup.md` and `M …/upstream-tray/INDEX.md`
(a living index, not a dated record). No pre-2026-09-25 record edited. ✓
`[USER 2026-09-25]` quote present: `followup.md:3`. ✓

## (7) M9 — see A1

The record's web observations (both repos public, landing on the `mdd`
branches) and the restricted-issues banner are the operator's to act on;
anonymous Git transport, empty-cache install and tag checks remain
UNVERIFIED-OFFLINE (the record's proxy failures, rc 128), correctly labelled.

## (8) Policy

New gates: `test_exec_totality.py` (plants + controls, fail-closed,
exercises the production script) and `test_version.sh` (`set -euo pipefail`,
isolated repo, fail-closed); both wired into row 1; no new `lean_exe`
(17 → 17), no `.lean/.lem/.c` change, the only `.ml` change is
`tools/gen_version.ml` (build identity, not model). `2>/dev/null` added in
`scripts/ tools/ Makefile`: **0** (one removed). Baselines/registers: only
`fork_drift_manifest.txt`. Provenance: the follow-up record is tagged
`[AGENT] Prepared by OpenAI Codex under operator direction` with the
`[USER 2026-09-25]` charter quote; manifest NOTE group untagged (**G6**).
Mode changes: `ci_lean.sh 100644 → 100755` (a real defect fixed — the record
reports the `Permission denied` rc 126 honestly and keeps it); the two new
test files are `100644`, invoked via `bash`/`python3` — fine.

## (9) Merge readiness

`git merge-base --is-ancestor c13a105 57ed81ca7` → yes.
`git merge-base --is-ancestor 27c7ff717 57ed81ca7` → **NO**; merge-base with
mainline is `c13a1054…`. **A rebase onto `27c7ff717` is required before the
ff merge.** The two mainline-only commits touch
`docs/2026-09-24_public-readiness-closure.md` (append) and the orchestrator
note — neither file is in this range — so the rebase should be
conflict-free; re-gate after it. The pin-moving set (`lakefile.toml`, three
manifests, `lem-pin=`, README pin) implies another shared-switch /
`deps/lem-pinned` re-pin to `67ec5de` at landing (in-tree `lem -v` will be
`Lem 67ec5de`; admitted by the F1 prefix rule). Order: lem-lean `67ec5de`
lands first (ff), re-pin, rebase this branch, re-gate (row 1 incl. the two
new tests + the eleven lanes the record ran), ff merge on explicit
per-merge sign-off.

## VERDICT

[AGENT] The SHOULD range delivers what its record claims and nothing
outside it: the totality gate enforces by default with a plant battery
that drives the production script; the roots gate is locale-fixed and
propagates `comm` failures; the fork-drift gate has no container path and
a public provisioning recipe that the record shows reproducing the pinned
hashes; `ci_lean.sh` is executable and free of the Git-config sentinel;
version output is hash-bearing at exact annotated tags with an isolated
test; the single re-pin is consistent at all five sites with a single-row
manifest edit; the public docs now say what the scripts do (F4 public path,
F5, and F11 except `DESIGN.md:3` are closed). **No P1 or P2.** P3: G1
(`check_fork_drift.sh:255` message), G2 (`DESIGN.md:3`), G3 (record's
`--prefix` deviation), G4 (instrument/probe residuals for a later pass).
For the operator, not the code: **A1** — verify that outsiders can open
issues before announcing — and G5 (four ISO-fix register rows rest on
Draft reports). Merge after rebase onto `27c7ff717` and the orchestrator's
re-gate; merge authority rests with the operator.
