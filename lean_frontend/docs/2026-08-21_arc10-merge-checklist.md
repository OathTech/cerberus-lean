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

- LEM branch `arc/robustness` @ `a9387fb` (S2a `98d19fb` → S2b
  `a9387fb`; untouched since S2 — no lem close-out commit was needed,
  the S2 record lives in the commit messages + the CERB results doc),
  worktree `worktrees/lem-lean-arc/robustness`, clean. **Linear
  descendant of the mainline: `git merge-base --is-ancestor`
  `mdd/lean-backend` (@ `237867bbf`) → `a9387fb` succeeds (verified at
  S5) — ff-only applies directly as of now.**
- CERB branch `arc/robustness` @ the S5 close-out head (S0 `a0f3706ab`
  → S1 `3b82fac70` → S2 `442a52334`+`eec935634` → S3/S3b
  `e0d3ad1f7`/`57fe96ab4`/`65f77606c` → S4 `fb36810a8`…`ac509e962` →
  D-log commits → S5 `b4768cabf` + the close-out docs commit),
  worktree `worktrees/cerberus-lean-arc/robustness`, clean. **Merge
  base with `mdd/cerberus-lean` (@ `da8378eed`) is `da8378eed`
  (verified at S5) — linear descendant, ff-only applies directly as
  of now.**
- CERB lakefile.toml LemLib pin: rev
  `a9387fbb834d552b3334b499f83076c9ee35dbb5` **= the LEM branch head**
  (mid-arc S2 bump, own commit `eec935634`); lake-manifest.json
  inputRev matches. Because no lem commit followed S2b, the Lake pin
  ALREADY equals what the merged `mdd/lean-backend` head will be — no
  re-pin commit is needed at merge, only the in-file comment's
  "re-pin at arc close" wording is retired (comment-only edit, step
  A4/B5).
- `deps/lem-pinned` is still @ `237867bbf` (mainline; D2 pattern —
  opam pin untouched mid-arc); the opam-installed lem is the 237867bbf
  build. Mid-arc regeneration used the checkout lem (PATH+LEMLIB).
  THE PIN DANCE CLOSES THIS GAP (steps A5–A6 / B6–B7).
- Arc-9's declared lakefile touch-point: the iris rev (arc-9 D1 bumped
  iris-lean to `34390a01339` on ITS branch). Same files
  (lakefile.toml / lake-manifest.json), different entries — the
  expected trivial rebase conflict for whichever stream goes second.

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
   `a9387fb`. Re-run lem `make` + `tests/comprehensive: make lean` on
   the merged mainline (gate).
4. **CERB Lake pin check (no bump needed):** lakefile rev `a9387fbb…`
   already = the merged head. Retire the in-file "re-pin at arc close"
   comment wording (comment-only, part of a CERB-branch commit before
   its merge, gate re-run after) OR record the comment as-is
   (operator's call; content-neutral either way — the REV is already
   aligned, so the arc-close criterion "branch heads = Lake pin"
   holds).
5. **opam pin re-sync (operator/orchestrator at merge time;
   switch-level, in-session-allowed):**
   `git -C deps/lem-pinned reset --hard a9387fbb` (branch
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
   generated/ tree vs the committed one (same backend commit as the
   checkout lem used all arc); then the full validation gate: capped
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
   (CERB). Expected conflict: lakefile.toml / lake-manifest.json —
   keep the mainline's (arc-9) iris rev AND this branch's LemLib rev
   `a9387fbb…`; after resolving, `lake update LemLib` offline via the
   deps/gitconfig redirect if the manifest needs regeneration. Record
   the resolution in the rebase commit/log. If arc 9 also moved
   `mdd/lean-backend` (not expected — its lem surface was not
   declared): rebase the LEM branch too and re-verify ff-only
   ancestry; any non-trivial lem conflict = stop and re-scope with the
   operator.
4. **Full re-gate on the rebased branch** (the D4 standing set + Tier
   A + verify + ci + one corpus shard, as in A6/A9 — a rebase is a new
   head, no prior green transfers).
5. **Re-ask.** The audit disposition and the merge ask are both
   renewed at the rebased head (per doctrine: re-gate, re-ask).
6.–9. Then as ORDER A steps 3, 5, 6, 7–9 (lem merge unchanged —
   `a9387fb` is untouched by the rebase unless step B3's lem caveat
   fired; opam pin re-sync; gate; cerb ff-only merge; post-merge
   rebuild + certification).

## Common tail (either order)

11. **Container-doc updates (orchestrator, POST-merge; outside the
    repos):** arcs line (arc 10 merged: finding 11 + pp class +
    finding 8 closed, 1134→0 comparison sorries, csmith campaign 3169
    programs zero Lean defects, F-D fork-regression = TOP next-arc
    candidate); known-issues pin lines (lem-lean pins → `a9387fb`;
    gates line gains float/bytes/csmith-corpus lanes + unit 6/6 + ci
    at 114/114); queue line (F-D repair slotted; wireguard note
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
