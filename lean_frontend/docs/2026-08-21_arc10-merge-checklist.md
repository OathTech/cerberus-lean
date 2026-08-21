# Arc 10 merge checklist (awaiting operator sign-off — do not merge without it)

TWO-REPO merge this arc (lem changed in S2): the full pin dance
applies. **Every numbered step below is OPERATOR-GATED per doctrine —
the orchestrator prepares and executes only on explicit per-merge
sign-off; the pre-merge audit ASK is unconditional and precedes the
merge ask.** The 2-agent adversarial audit (charter S5, mandatory
scopes a–d) runs and is dispositioned BEFORE any merge ask.

**SERIALIZATION (binding, playbook + charter):** arc 9
(`arc/wp-tactics`, the workbench stream) is still OPEN at checklist
time. Merges serialize: whichever stream closes SECOND rebases on the
moved mainline, re-gates in full, and re-asks. This checklist
therefore states BOTH orders below; the operator picks the order when
the second stream closes. Until a merge is signed off, both mainlines
stay untouched by this stream.

State at checklist time (verified 2026-08-21, S5):

- LEM branch `arc/robustness` @ `11d4b4c` [UPDATED 2026-08-21, audit
  fix-batch: the auditor-A F1 fix — Type-1 sorry emission path made
  fail-closed — landed as `11d4b4c` on top of S2b `a9387fb`; history:
  S2a `98d19fb` → S2b `a9387fb` → audit-fix `11d4b4c`. The commit
  touches `src/` + `tests/comprehensive/` only — **lean-lib/ is
  untouched**], worktree `worktrees/lem-lean-arc/robustness`, clean.
  **Still a linear descendant of the mainline `237867bbf` — ff-only
  applies directly as of now (re-verified at the audit-fix commit).**
- CERB branch `arc/robustness` @ the audit-fix-batch head [UPDATED
  2026-08-21: the S5 close-out head `e4f093ef9` gained the audit
  fix-batch — scripts commit `496a639cf` (shard-gate vanished-file
  direction + the fork-drift gate) + the docs/records commit (labeled
  corrections; carries this checklist update)] (history: S0
  `a0f3706ab` → S1 `3b82fac70` → S2 `442a52334`+`eec935634` → S3/S3b
  `e0d3ad1f7`/`57fe96ab4`/`65f77606c` → S4 `fb36810a8`…`ac509e962` →
  D-log commits → S5 `b4768cabf` + `e4f093ef9` → the fix-batch),
  worktree `worktrees/cerberus-lean-arc/robustness`, clean. **Merge
  base with `mdd/cerberus-lean` (@ `da8378eed`) is `da8378eed`
  (verified at S5) — linear descendant, ff-only applies directly as
  of now.**
- CERB lakefile.toml LemLib pin: rev
  `a9387fbb834d552b3334b499f83076c9ee35dbb5` = the PRE-audit-fix LEM
  head (mid-arc S2 bump, own commit `eec935634`); lake-manifest.json
  inputRev matches. [UPDATED 2026-08-21, audit fix-batch — this
  REPLACES the earlier "no re-pin commit is needed" note:] the LEM
  branch head is now `11d4b4c`, so pin ≠ head again. The audit-fix
  commit leaves `lean-lib/` (the Lake subDir) byte-untouched, so the
  current pin stays SEMANTICALLY valid for builds mid-close; per the
  standing pin dance the lakefile rev is RE-POINTED TO THE MERGED
  `mdd/lean-backend` HEAD at close (step A4/B5: bump rev + offline
  `lake update LemLib` via the deps/gitconfig redirect, own commit,
  gate re-run). The arc-close criterion stays: branch heads = opam
  pin = Lake pin.
- `deps/lem-pinned` is still @ `237867bbf` (mainline; D2 pattern —
  opam pin untouched mid-arc); the opam-installed lem is the 237867bbf
  build. Mid-arc regeneration used the checkout lem (PATH+LEMLIB).
  THE PIN DANCE CLOSES THIS GAP (steps A5–A6 / B6–B7).
- Arc-9's declared lakefile touch-point: the iris rev (arc-9 D1 bumped
  iris-lean to `34390a01339` on ITS branch). Same files
  (lakefile.toml / lake-manifest.json), different entries — the
  expected trivial rebase conflict for whichever stream goes second.
- [ADDED 2026-08-21, audit fix-batch — auditor B F2: the rebase
  surface above was under-enumerated] **Two more shared files** both
  streams touch, for whichever stream goes second:
  (1) `scripts/test_unit.sh` — arc-10 edits the `UNIT_TESTS` array
  (pp-test, S3) AND appends the fork-drift gate (audit fix-batch);
  arc-9 adds its own unit exes to the SAME `UNIT_TESTS` hunk —
  expect a same-hunk conflict; resolution = union of both arrays +
  both gate tails. (2) `lean_frontend/lakefile.toml` beyond the dep
  revs: each stream adds its own `[[lean_exe]]` blocks — union them.
  THE LESSON (D1-ruling-5 class, made standing here): gate scripts
  and the lakefile are SHARED SURFACE — future parallel-stream
  charters must DECLARE intended touches to them up front, like the
  dep-pin touch-points already are.

## Pre-steps (either order)

1. **Pre-merge audit ask (unconditional).** Propose audit scope +
   scale to the operator; disposition findings (fix-or-record) before
   any merge ask. Mandatory scopes per charter S5: (a) mirror-citation
   fidelity (CerbMem finding-11/finding-8 + CerbPP/CerbFloat printer
   mirrors against the cited OCaml file:lines); (b) BEq/comparison
   derivation soundness (derived comparisons vs OCaml poly-compare
   parity — the CerbStepInstances precedent; spot differential
   evidence); (c) baseline honesty (every baseline movement justified:
   0086/mem3-004 finding-11, 0006/0007/0046/mem-006 pp class,
   ptr3-006 finding-8; csmith classifications match the committed
   artifacts; corpus baseline vs the S5 sharded re-verification);
   (d) parallel-stream discipline (zero commits touching
   `lean_frontend/relsem/`, `tests/verify/`, `CerbND.lean`, the iris
   pin — checkable from the diffstat).
2. **Pre-merge state check.** Confirm `mdd/lean-backend` still @
   `237867bbf` and `mdd/cerberus-lean` still @ `da8378eed`. If either
   moved (i.e. arc 9 merged first): take ORDER B below. If both
   unmoved: ORDER A.

## ORDER A — arc 10 merges first (straightforward: both branches are
linear descendants today)

3. **lem-lean merge (operator sign-off required):** on the lem-lean
   primary (parked on `mdd/lean-backend`):
   `git merge --ff-only arc/robustness` → `mdd/lean-backend` =
   `11d4b4c` [UPDATED 2026-08-21: was `a9387fb` before the audit-fix
   commit]. Re-run lem `make` + `tests/comprehensive: make lean` on
   the merged mainline (gate).
4. **CERB Lake pin bump (NEEDED — [UPDATED 2026-08-21, audit
   fix-batch]; supersedes the earlier "no bump needed" wording):**
   set lakefile.toml LemLib rev to the merged head `11d4b4c` and
   `lake update LemLib` (offline via the deps/gitconfig redirect);
   own commit on the CERB branch BEFORE its merge, retiring the
   in-file "re-pin at arc close" comment in the same touch; gate
   re-run after. (lean-lib is byte-identical between `a9387fbb…` and
   `11d4b4c`, so the bump is content-neutral for builds — the commit
   message should say so.)
5. **opam pin re-sync (operator/orchestrator at merge time;
   switch-level, in-session-allowed):**
   `git -C deps/lem-pinned reset --hard 11d4b4c` [UPDATED 2026-08-21:
   was `a9387fbb`] (branch
   `cerberus-pin`, = the merged `mdd/lean-backend`), then from
   `cerberus-lean/`: `opam upgrade --switch=. --no-depexts lem`
   (the arc-8-merge-verified form: `--switch=cerberus-lean` fails —
   LOCAL switch, use the path form; `--no-depexts` because opam's
   system-package detection fails in-sandbox). Verify the installed
   lem regenerates identically (step 6). (deps/lem-pinned is the
   container-level worktree — outside the repo worktrees, explicitly
   NOT an arc-worker action.)
6. **CERB gate re-run at the merge candidate with the OPAM lem now at
   the merged head:** `make lean-prelude-src` must produce a no-diff
   generated/ tree vs the committed one ([UPDATED 2026-08-21] the
   merged head `11d4b4c` differs from the mid-arc checkout lem
   `a9387fb` only in the fail-closed Type-1 error path — diff -rq
   zero-movement over all 195 generated files was verified at the
   audit-fix commit); then the full validation gate: capped
   default-target build (D4 standing rule; CERB_MEM_MAX=40G while the
   arc-9 lane is live), Tier A per scripts/LADDER.md (now incl. float
   4b + bytes 4c), test_verify.sh 29/29, ci check-baseline
   (114/114-agree state), csmith-corpus lane spot shard
   (`--check-baseline --shard 1/6`, BASELINE OK). An arc is closed
   only when branch heads = opam pin = Lake pin.
7. **cerberus-lean merge (operator sign-off required):** on the
   cerberus-lean primary (parked on `mdd/cerberus-lean`):
   `git merge --ff-only arc/robustness`.
8. **Post-merge rebuild on the primary:** `source scripts/env.sh`;
   `make lean-prelude-src`; **`make lean-native-obj`** (standing
   gotcha: stale .o FAIL-STOP via the fresh-counter floor); full
   capped `lake build` (in-build absence gate + statement gate + audit
   sweep green in the log).
9. **Post-merge certification:** Tier A per scripts/LADDER.md +
   test_verify.sh + at least one libxml2 battery slice (full Tier B if
   time permits) + the ci check-baseline + one csmith-corpus shard.
   Expected: byte-identical SUMMARY lines vs the S5 records (zero
   movement); any movement is a soundness finding, never a baseline
   update.
10. **Arc-9 consequence (recorded for the other stream):** arc 9 now
    rebases `arc/wp-tactics` over the moved mainline, resolves the
    expected lakefile/lake-manifest conflict (iris entry from its
    branch + LemLib entry from the mainline), full re-gate, re-ask.

## ORDER B — arc 9 merged first (this stream goes second)

3. **Rebase:** `git rebase mdd/cerberus-lean` on `arc/robustness`
   (CERB). Expected conflicts [enumeration EXTENDED 2026-08-21, audit
   fix-batch — auditor B F2]:
   (a) lakefile.toml / lake-manifest.json dep revs — keep the
   mainline's (arc-9) iris rev AND this branch's LemLib rev (the
   merged `mdd/lean-backend` head per step A4); after resolving,
   `lake update LemLib` offline via the deps/gitconfig redirect if
   the manifest needs regeneration;
   (b) `scripts/test_unit.sh` — SAME-HUNK collision on the
   `UNIT_TESTS` array (arc-10 added pp-test; arc-9 adds its exes)
   plus arc-10's appended fork-drift gate tail — resolve as the
   union of both arrays + both gate tails;
   (c) lakefile.toml `[[lean_exe]]` blocks — each stream adds its
   own; union them.
   Record every resolution in the rebase commit/log. (Lesson, D1-
   ruling-5 class: gate scripts are shared surface — future parallel
   charters declare them; see the state-section note.) If arc 9 also
   moved
   `mdd/lean-backend` (not expected — its lem surface was not
   declared): rebase the LEM branch too and re-verify ff-only
   ancestry; any non-trivial lem conflict = stop and re-scope with the
   operator.
4. **Full re-gate on the rebased branch** (the D4 standing set + Tier
   A + verify + ci + one corpus shard, as in A6/A9 — a rebase is a new
   head, no prior green transfers).
5. **Re-ask.** The audit disposition and the merge ask are both
   renewed at the rebased head (per doctrine: re-gate, re-ask).
6.–9. Then as ORDER A steps 3, 4, 5, 6, 7–9 (lem merge unchanged —
   `11d4b4c` [UPDATED 2026-08-21: was `a9387fb`] is untouched by the
   rebase unless step B3's lem caveat fired; Lake pin bump to the
   merged head per A4; opam pin re-sync; gate; cerb ff-only merge;
   post-merge rebuild + certification).

## Common tail (either order)

11. **Container-doc updates (orchestrator, POST-merge; outside the
    repos):** arcs line (arc 10 merged: finding 11 + pp class +
    finding 8 closed, 1134→0 comparison sorries, csmith campaign 3169
    programs zero Lean defects, F-D fork-regression = TOP next-arc
    candidate); known-issues pin lines (lem-lean pins → `11d4b4c`
    [UPDATED 2026-08-21: was `a9387fb`]; gates line gains
    float/bytes/csmith-corpus lanes + the fork-drift gate + unit 6/6
    + ci at 114/114); queue line (F-D repair slotted; wireguard note
    already addendum'd in S4).
12. **Worktree/branch disposition (operator's call):** the two
    `arc/robustness` worktrees prunable after both merges (ff-only ⇒
    branches fully contained in the mainlines).
13. **Next-network-window reminders (do NOT gate the merge):** refresh
    `deps/mirrors/lem-lean.git` (and the rest); `git push` of both
    merged mainlines is a separate operator-gated action; the F-A/F-B
    upstream-tray filings (tests/csmith_findings/oracle/, un-forked
    repros) go out when the operator chooses.

Validation gate at every step: Tier A per LADDER.md under the D4
standing rule (capped default-target build included; CERB_MEM_MAX=40G
while the arc-9 lane is live). No merge commits, no `git branch -f`,
no pointer surgery; if ff-only is impossible at any point, stop and
re-ask.
