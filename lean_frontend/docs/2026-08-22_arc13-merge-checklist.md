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
  `157221fff` (D2), + S3 docs commit(s) + audit fix batch if any.

## Whole-arc surface (vs charter; measured `git diff mdd..HEAD --name-only`)

45 files, +44,840/−43,610 (dominated by the libc.core re-pin):
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
- Pinned artifacts (8): tests/verify ×5, tests/libc/libc.core
  (+.co.version), uri_baseline.
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
   NOTE: the primary checkout's `_build` still carries the OLD-scheme
   libc.co until its own `dune build cerberus.install` re-derives it —
   run that BEFORE any libc-mode lane on the merged primary tree
   (tests/libc/libc.core pin-check will otherwise fail loudly, which
   is the gate working as designed).
6. `git push` remains a separate operator action.

## Post-merge follow-ups (registered, not merge-blocking)

- WalkBench instrument repair (mover: workbench maintenance, T5
  resumption).
- notes/upstream/07 addendum: DONE by orchestrator (D2); the 07
  filing's upstream ask itself unchanged.
- The 8 restored-TIMEOUT-class corpus rows (3 old + 3 newly-restored
  TIMEOUT + jitter watch) stay under the perf-gap register.
