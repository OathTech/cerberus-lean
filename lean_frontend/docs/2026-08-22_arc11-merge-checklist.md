# Arc-11 merge checklist (workbench v2)

Prepared 2026-08-22 at S5 close-out, BEFORE the audit pair. **MERGE
LIVES WITH THE USER — this checklist is preparation only; the ff-only
merge executes on explicit per-merge sign-off, presented JOINTLY with
arc-12's outstanding merge ask (D4).** The 2-agent adversarial audit
(charter S5 scopes a–d) runs after this file; the merge ask states
the final audited head.

## Facts (rev-parsed at checklist time)

- `mdd/cerberus-lean` (mainline):
  `a8da194b21eaaac3607238d09a1db8c6d66a5415` (unchanged since the
  arc-9 merge — both live arcs base here).
- `arc/workbench-v2` at checklist time:
  `796862c6f7011d63e648eead97a93c8a49dd727d` (the S5 results/de-stale
  commit; this checklist's commit + any audit-fix commits advance the
  head — the merge ask states the audited head).
- merge-base(mainline, arc/workbench-v2) = `a8da194b2` = the mainline
  head → **ff-only is possible today** (strict descendant; no merge
  commits in the branch — first-parent linear).
- `arc/honest-oracle` (arc 12): `f07bcef6d` — audited, its merge ask
  outstanding; same base `a8da194b2`.
- **lem-lean: ZERO changes** (verified): no lem-lean branch exists
  for this arc (`git branch -a` in lem-lean lists only historical arc
  branches); root `lean_frontend/lake-manifest.json` has a ZERO diff
  vs mainline — LemLib rev `11d4b4c3…` = `deps/lem-pinned` HEAD; the
  new `relsem/lake-manifest.json` pins the SAME dependency revs
  (shared `packagesDir`). No pin dance needed.

## Serialization with arc 12 (JOINT ask; RE-MEASURED at current heads — both branches moved since arc-12's S4 measurement)

Measured at `796862c6f` (arc-11) × `f07bcef6d` (arc-12):

- File-level intersection
  (`git diff mdd..branch --name-only`, `comm -12`): exactly ONE file
  — `lean_frontend/CLAUDE.md`. (Arc-11's S5 edits touch the
  proof-layer/gate/pipeline paragraphs; arc-12's touch the scripts
  table + its own pipeline bullet — different regions. Arc-11's new
  doc files cannot enter arc-12's file set.)
- Cross-merge dry run: `git merge-tree --write-tree 796862c6f
  f07bcef6d` → exit 0, tree `df274d49…`, ZERO conflicted files
  (auto-merges cleanly). Re-run this measurement mechanically at the
  final audited heads before the ask (docs-only audit-fix commits
  keep the name-set stable; any CLAUDE.md-touching fix re-measures).

Both merge orders enumerated (whichever merges second REBASES onto
the moved mainline, RE-GATES on its own bars, RE-ASKS — ff-only,
exactly; no merge commits, no pointer surgery):

- **Order A (arc 11 first):** mainline ff-forwards to the audited
  arc-11 head; arc-12 rebases onto it (expected conflict-free per
  the dry run), re-runs ITS full gate (its checklist §"Pre-merge
  gate"), re-asks, mainline ff-forwards to the rebased arc-12 head.
- **Order B (arc 12 first):** mainline ff-forwards to the audited
  arc-12 head; arc-11 rebases (same single-file, conflict-free
  expectation), re-gates on the arc-11 bar below — note the arc-11
  in-build gates then rerun against the floored oracle-side scripts,
  which arc-11 never touches (disjoint surfaces: arc-11 = relsem/
  proof/declared scripts; arc-12 = oracle OCaml/exec scripts/
  baselines) — and re-asks.

## Pre-merge gate for THIS branch (all green at the S5 head; re-run in full after any rebase)

The arc-11 bar (S4 two-package structure — BOTH builds required):

1. capped ROOT plain `lake build` (from `lean_frontend/`) — green,
   driver linked.
2. capped RELSEM package plain `lake build` (from
   `lean_frontend/relsem/`) — green WITH the three audit-gate info
   lines (DAEMON absence, statement gate 16, axiom sweep 3021/0).
3. `./scripts/test_unit.sh` — exit 0 (builds both packages
   fail-closed; 7 unit tests; all check_* gates incl. the
   proof-size gate with its honestly-PENDING T5 row and the
   app_walk_preview ban).
4. `./scripts/test_verify.sh` — 29/29 (5 fixtures + 18 harness
   points + pin-provenance + t4-env-witness at the relsem-package
   path).
5. `./scripts/test_exec.sh tests/minimal` — zero movement
   (match=85 ub_match=18 mismatch=0, 3 oracle-side skips).
6. `./scripts/test_parse.sh` ALL, `./scripts/test_core.sh` 106/106.

## Post-merge certification (on the merged mainline, whichever order)

- BOTH packages build from a clean mainline checkout (root + relsem
  capped plain builds; the relsem manifest resolves offline via the
  shared packagesDir + deps/gitconfig redirects).
- The full lane battery (Tier A per LADDER.md): test_unit,
  test_verify, test_parse, test_core, exec-minimal + coverage +
  debug + float baselines, test_bytes, test_multi_tu,
  test_libc_exec, test_libxml2_uri (after the arc-12 merge these run
  against the floored oracle — its D2 exemption/grandfather modes
  apply); Tier B at the operator's discretion (test_libxml2, csmith
  corpus `--check-baseline` vs the arc-12 re-baseline).
- `make lean-prelude-src` → zero generated-Lean diff (arc-11 touches
  no .lem and no generated code).
- Worktree note: the untracked T5 probe scratch (results doc §9)
  lives ONLY in the workbench-v2 worktree — preserve the worktree
  (or copy `lean_frontend/scratch/` + the six untracked
  `relsem/RelSem/ProbeT5*.lean`) until the R-S2-1 resumption; a
  merge does not carry untracked files.

## The renumbering arc — preconditions

The operator-ordered RENUMBERING arc (arc-12's
`2026-08-21_arc12-renumbering-case.md`; D4 there = parked for
immediate execution) has BOTH merges as preconditions: THIS merge
plus arc-12's. Arc-11 was closed with renumbering compatibility as a
deciding factor (D3/D4): the T5 resumption's first move R-S2-1 is
engine-side and FIXTURE-INDEPENDENT (survives the fixture re-pin by
design), and checked replay's fingerprint refusal makes any stale
trace re-use after the re-pin loud, never silent.

## Audit hand-off (mandatory scopes per charter S5; runs after this file)

(a) trace/replay trust boundary — preview provably cannot close
CI-accepted theorems (goal-assign reachability under
`preview := true`); replay terms are ordinary kernel declarations;
(b) reuse honesty — context-query vs iris-lean, Yolo ZERO-CODE
boundary (paper-only evidence, S0); (c) grind/bar honesty — the T5
gate row NEVER flipped (verify the PENDING line), tallies recompute,
no unregistered heartbeat bumps; (d) package-rehearsal soundness —
gates re-homed, still fail-closed, plant-tested; the D4-flagged
plain-build deviation (proof gates ride the relsem package's plain
build) assessed. Fix-or-record; findings amend the results doc.

## Forbidden-surface confirmation (for the audit)

Whole-arc diff `mdd/cerberus-lean..arc/workbench-v2` at checklist
time = 34 files (32 pre-S5 + results doc + this file): all inside
the DECLARED write surface (relsem/** incl. the new package files,
relsemcore/** git-mvs, relsem/test/Unit git-mvs, docs, .gitignore
+1 line, lakefile.toml, CLAUDE.md, and the three declared scripts —
check_proof_size.sh, test_unit.sh, test_verify.sh (path-only, S4
re-homing)). Precise grep over the diff for
`^(frontend/|util/|backend/|tests/)`, `\.lem$`, `baseline`,
`fork_drift`, `csmith`, `CerbMem`, `CerbND`: ZERO hits. Zero exec
baselines touched, zero oracle OCaml, zero lem (see Facts).
