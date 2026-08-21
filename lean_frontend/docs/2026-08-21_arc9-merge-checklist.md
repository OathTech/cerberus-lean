# Arc 9 merge checklist (awaiting operator sign-off — do not merge without it)

ONE-REPO merge this arc: **zero lem-lean commits** (verified: no
`arc/wp-tactics` branch exists in lem-lean; the arc touched cerberus
only). No pin dance is needed — the arc-10 close already put lem-lean
`mdd/lean-backend` = opam pin (`deps/lem-pinned`) = the CERB Lake pin
at `11d4b4c` (re-verified at S4: `lem -v` → `Lem 11d4b4c`; lakefile
LemLib rev `11d4b4c3cd91aa251fb7c049050d12fc4f325d70`).

**Every numbered step below is OPERATOR-GATED per doctrine — the
orchestrator prepares and executes only on explicit per-merge
sign-off; the pre-merge audit ASK is unconditional and precedes the
merge ask.** The 2-agent adversarial audit (charter S4 scopes a-d:
reuse honesty, attribution fidelity, grind honesty, soundness) runs
and is dispositioned BEFORE any merge ask.

State at checklist time (verified 2026-08-21, S4; rev-parse facts):

- CERB branch `arc/wp-tactics` REBASED onto the arc-10 merge:
  `git merge-base arc/wp-tactics mdd/cerberus-lean` =
  `56a994469e9428e26a4e2368eed9f1d69fcd1338` =
  `git rev-parse mdd/cerberus-lean` — a linear descendant;
  **ff-only applies directly.** (Old pre-rebase head `30e2ead02`;
  the old→new commit map is in the results doc §6.)
- Rebase conflict surface was exactly the arc-10 checklist's ORDER-A
  step-10 enumeration; resolutions recorded in the results doc §6 and
  the `ad1460f59` commit message (the single post-rebase integration
  fix: mem_alloc_block tracks finding-11, statement unchanged).
- Worktree `worktrees/cerberus-lean-arc/wp-tactics`, clean except
  deliberately untracked next-session scratch
  (`scratch/`, `relsem/RelSem/ProbeT5S3*.lean` — see results §2).
- lakefile.toml dep revs at the branch head: LemLib `11d4b4c3cd…`
  (= merged mainline, unchanged by this arc) and iris
  `34390a0133986385c62bf59a6eb01938945b48ec` (the arc-9 D1 bump —
  **the mainline GAINS the iris head pin at this merge**; the Lake
  manifest matches; resolved offline via the deps/gitconfig
  redirect to the local deps/iris-lean checkout).
- Full battery at the branch head: results doc §3 S4 block (build 609
  jobs + statement gate + audit sweep; unit 7/7 + all gates incl.
  fork-drift and proof-size; verify 29/29; minimal/coverage/debug/
  float/bytes/libc/multi_tu/parse/core/elab/uri/ci all rc 0 at their
  baselines — zero movement; csmith spot shard: see S4 report).

## Steps

1. **Pre-merge audit ask (unconditional).** Propose scope + scale to
   the operator; disposition findings (fix-or-record) before any merge
   ask. Charter-mandated scopes: (a) REUSE HONESTY (every gap-matrix
   BUILD-NEW entry re-justified against iris-lean @ 34390a0133);
   (b) attribution fidelity (brick-wp/golean/iris cites against the
   cited code); (c) grind honesty (proof-size tallies real, no
   mega-lemma bar-gaming; the T5-pending gate line is honest);
   (d) soundness (new rules trace to the adequacy chain, cones
   re-pinned clean, statement gate untouched). Suggested extra scope
   for this close: the S4 rebase itself (conflict resolutions vs the
   enumeration; the ad1460f59 integration fix's statement-unchanged
   claim).
2. **Pre-merge state check.** Confirm `mdd/cerberus-lean` still @
   `56a994469` and `mdd/lean-backend` still @ `11d4b4c`. If the CERB
   mainline moved again: rebase again, full re-gate, re-ask (the
   serialization rule; no green transfers across a rebase).
3. **cerberus-lean merge (operator sign-off required):** on the
   cerberus-lean primary (parked on `mdd/cerberus-lean`):
   `git merge --ff-only arc/wp-tactics`. No lem-lean merge, no Lake
   pin bump, no opam pin move (zero lem changes this arc).
4. **Post-merge rebuild on the primary:** `source scripts/env.sh`;
   `make lean-prelude-src` (also refreshes ocaml_frontend/generated —
   NOTE from S4: a stale pre-arc-10 generated OCaml tree trips the
   fork-drift gate by design; regeneration clears it);
   **`make lean-native-obj`** (standing gotcha: stale .o FAIL-STOP);
   full capped `lake build` (in-build absence gate + statement gate +
   Kit/Audit pins + audit sweep green in the log; CERB_MEM_MAX=40G
   standing while this lane is live).
5. **Post-merge certification:** Tier A per scripts/LADDER.md
   (test_unit now 7/7 incl. app-walk-test; proof-size gate in the
   tail) + test_verify.sh 29/29 + ci
   `--check-baseline=scripts/exec_ci_baseline.txt` + one
   csmith-corpus shard (`--check-baseline --shard 1/6`); at least one
   libxml2 battery slice (full Tier B if time permits). Expected:
   byte-identical SUMMARY lines vs the results doc §3 S4 block (zero
   movement); any movement is a soundness finding, never a baseline
   update.
6. **Container-doc updates (orchestrator, POST-merge; outside the
   repo):** arcs line (arc 9 merged: the workbench — OwnP adoption,
   54-pin kit surface, walker v1-v3 + per-stage certificate emitter,
   axiom-free iter_compose, 700→5 calibration, proof-size gate; T5
   parked at evidence grade 44/79 with named resumption; v2 charter
   queued with T5 as exit criterion 1 + the survey slate);
   known-issues gates line gains app-walk-test + the proof-size gate
   and the iris pin note (iris-lean now pinned at head `34390a0133…`);
   also note: the primary checkout's UNTRACKED copy of
   `2026-08-21_iris-rules-automation-survey.md` should be removed
   (`rm`) — it is now committed on this branch.
7. **Worktree/branch disposition (operator's call):** the
   `worktrees/cerberus-lean-arc/wp-tactics` worktree carries the
   UNTRACKED T5 probe scratch (`scratch/`, `ProbeT5S3*.lean`) —
   next-session material for v2; recommend KEEPING the worktree
   parked until the v2 charter decides, not pruning at merge.
8. **Next-network-window reminders (do NOT gate the merge):**
   deps/mirrors still lacks an iris-lean.git mirror (pre-existing S0
   note); `git push` of the merged mainline is a separate
   operator-gated action.

Validation gate at every step: Tier A per LADDER.md under the D4-arc-7
standing rule (capped default-target build included; CERB_MEM_MAX=40G
while this lane is live). No merge commits, no `git branch -f`, no
pointer surgery; if ff-only is impossible at any point, stop and
re-ask.
