# Arc-13 merge checklist (the renumbering)

Prepared 2026-08-22 at S3 close-out mechanics, BEFORE the 2-agent
adversarial audit (charter S3: audit pair runs after these mechanics;
this file gains the audited-head fact + dispositions pointer at the
audit's close). **MERGE LIVES WITH THE USER — this checklist is
preparation only; the ff-only merge executes on explicit per-merge
sign-off; the pre-merge audit ASK is unconditional.**

## Facts (rev-parsed at checklist time)

- `mdd/cerberus-lean` (mainline): `fc1c8c1476c477ace355db144130b9676db784cf`
  (contains BOTH the arc-11 and arc-12 merges — the charter's
  preconditions; verified: 15 arc-12 commits in its history).
- `arc/renumbering` at checklist time:
  `157221fffe5a5fb07caf2fc95c2e3f4c6f76fe9b` (D2; the S3
  results/checklist commit follows this file; the merge ask states
  the audited head).
- merge-base(mainline, arc/renumbering) = `fc1c8c147` = the mainline
  head → **ff-only is possible today** (`git merge-base
  --is-ancestor` verified: the branch is a strict descendant; no
  rebase needed unless the mainline moves).
- **lem-lean: ZERO changes** (charter success condition 5) —
  `git -C lem-lean status --porcelain` empty; `deps/lem-pinned` @
  `11d4b4c` unmoved; root `lake-manifest.json` zero diff (LemLib rev
  unchanged); relsem package manifest zero diff. **No pin dance
  needed.**
- Arc commits to merge (5 + the S3 close commits):
  `de68a4839` (charter), `41f7684a1` (S0 decision), `53e8c48e3` (D1),
  `0ca08d695` (S1 batch A), `59781c611` (S1/S2 close-out),
  `157221fff` (D2), `dc09c702d` (S3 docs; the audited head),
  `32264b40e` (audit fix a: code/scripts) + the audit-fix records
  commit (batch b, this file's head).

## Whole-arc surface (vs charter; measured `git diff mdd..HEAD --name-only`)

51 files, +45,529/−43,627 [CORRECTED at the S3 audit, B-F6/F8:
measured at the audit-fix final head — the earlier 45/+44,840/−43,610
predated the S3 docs commit and the two audit-fix commits] (dominated
by the libc.core re-pin):
- Oracle OCaml (5): `util/cerb_fresh.ml` (single-supply window
  backstop), `backend/common/{ail_sym_hwm,pipeline}.ml`,
  `backend/driver/main.ml` (grandfather flag + warn modes DELETED),
  `ocaml_frontend/fork_renumber.ml` (NEW — the R-B shims).
- `.lem` (3): declares + comments ONLY (the charter's "only per the
  S0 decision's validated path"); zero body changes; generated-Lean
  diff EMPTY (regenerated + diffed at batch A, the close-out head,
  and the final head).
- relsem `.lean` (10): T1Core/SlateCore re-emitted; 8 proof modules
  script-renumbered (1,510 tokens, zero manual proof edits). ZERO
  Tactics/Kit/Audit/lakefile changes.
- Scripts (6): drift manifest (refreshed, `renumber=arc13`),
  corpus baseline (restored), `test_csmith_corpus.sh`
  (`CSMITH_BASELINE` override), `test_exec.sh` (comment/classifier
  token cleanup), `test_libxml2_uri.sh` (grandfather removal),
  `canonicalize_ids.py` (underscore names + self-test).
- Pinned artifacts: tests/verify ×5, tests/libc/libc.core
  (+ its content-hash pin tests/libc/libc.core.sha256 — audit fix
  B-F5; the old .co.version version-string pin is DELETED),
  uri_baseline.
- Docs: 6 arc-13 files + 7 APPENDED addenda (arc-12 ×5, arc-6 ×1,
  findings README) + `lean_frontend/CLAUDE.md` de-stale.
- FORBIDDEN-SURFACE grep over the diff (`native/`, `CerbMem`,
  `CerbND`, memory model, `test_unit.sh`, `check_proof_size.sh`,
  lakefiles/manifests): zero hits. lem-lean: no branch exists for
  this arc. The **workbench-v2 worktree**
  (`worktrees/cerberus-lean-arc/workbench-v2`) was NEVER touched —
  it must SURVIVE the merge window too (R-S2-1 probe scratch;
  do not prune/clean it during merge operations).

## The gate (all green at 59781c611, re-verified through the S3 head; re-run at the audited head before the ask)

1. `test_unit.sh` (both Lake packages + in-build audits + emit drift
   gates) — PASS.
2. `test_verify.sh` 29/29 (pin-provenance against the NEW pins).
3. `test_core.sh` / `test_parse.sh` ALL.
4. exec lanes at baseline with `cerb_floor=0` everywhere: minimal
   106, ci 242, coverage 199, float 69/69, bytes, multi_tu 2/2,
   debug (reporting; standing baselined mismatch=1 only).
5. `test_libc_exec.sh` 7/7; `test_libxml2_uri.sh` GATE PASS 16/16
   (grandfather-free); `test_libxml2.sh` chvalid 4/4.
6. `check_fork_drift.sh` OK (56-file manifest, 20 pinned hashes,
   merge-base `b9aeedcb4`).
7. Corpus: fresh shard `--check-baseline` spot (0 regressions).
8. Generated-Lean diff EMPTY (regenerate + diff — the standing
   tripwire).

## Merge steps (operator-gated)

1. Present this checklist + the audit dispositions; ASK per-merge.
2. If the mainline moved: rebase, re-gate (full list above), re-ask.
3. `git -C cerberus-lean merge --ff-only <audited arc/renumbering
   head>` (from the PRIMARY checkout, parked on the mainline).
4. No lem/opam/Lake pin actions (zero lem changes this arc).
5. Post-merge certification (primary checkout): `make prelude-src` +
   `dune build backend/driver/main.exe cerberus-lib.install`, then
   (a) `test_verify.sh` 29/29 (pin-provenance on the merged tree),
   (b) ONE three-way spot: `--pp core` of `tests/verify/t1_id.c`
   byte-equal to `deps/cerberus-upstream`'s oracle output
   (the byte-identity certificate survives the merge),
   (c) `SKIP_BUILD=1 test_exec.sh tests/minimal` SUMMARY identical.
   NOTE [updated at the S3 audit fix, B-F5 — the remedy now WORKS
   without a re-pin]: the primary checkout's `_build` still carries
   the OLD-scheme libc.co until its own `dune build cerberus.install`
   re-derives it — run that BEFORE any libc-mode lane on the merged
   primary tree, then `scripts/libc_prep.sh --check`: the regenerated
   dump passes the CONTENT-HASH pin (tests/libc/libc.core.sha256)
   with no version re-pin — the hash is rebuild-independent (the old
   version-string pin would have demanded a spurious --record after
   every rebuild; it is deleted). A hash mismatch after the rebuild
   is a REAL drift signal, fail-closed as designed.
6. `git push` remains a separate operator action.

## The S3 audit (facts + dispositions pointer)

- Audited head: `dc09c702d` (2-agent adversarial audit per the
  charter). Dispositions executed in TWO audit-fix commits atop it
  (batch a: code/scripts — A-F1 narrowing, B-F5 content-hash pin,
  [USER] env-trap tweaks; batch b: records) — the merge ask states
  these as the final head. Full per-finding record: the results doc
  §"The S3 audit".
- Gate re-verified at the audit-fix tree: test_unit rc=0 (both
  packages), test_verify 29/29, exec-minimal at baseline
  (`cerb_floor=0`), test_libc_exec 7/7 vs the content-hash pin,
  `libc_prep.sh --check` OK (plant-tested).

## Lessons (audit-plant hygiene — B-F7; orchestrator promotes to container doctrine at merge)

- Plant recipes MANDATE rebuild-after-revert BEFORE any further
  measurement: a reverted source with a stale planted binary is a
  doctored instrument, and any number it produces is a
  record-integrity hazard.
- Audit pairs sharing a worktree SEQUENCE binary-affecting plants —
  two auditors must never interleave plants that touch the same
  build outputs.

## Post-merge follow-ups (registered, not merge-blocking)

- ~~WalkBench instrument repair~~ CLOSED at the S3 audit fix (A-F2:
  stale root-package RelSem oleans cleaned; green re-run recorded;
  probe recipe fixed in lean_frontend/CLAUDE.md). No T5-resumption
  work item remains for the instrument.
- notes/upstream/07 addendum: DONE by orchestrator (D2); the 07
  filing's upstream ask itself unchanged.
- The 8 restored-TIMEOUT-class corpus rows ([CORRECTED, B-F2] 5
  surviving old + 3 newly-restored TIMEOUT + jitter watch) stay
  under the perf-gap register.
