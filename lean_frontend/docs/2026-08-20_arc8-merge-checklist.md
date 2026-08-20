# Arc 8 merge checklist (awaiting operator sign-off — do not merge without it)

TWO-REPO merge this arc (lem-heavy): the full pin dance applies.
**Every numbered step below is OPERATOR-GATED per doctrine — the
orchestrator prepares and executes only on explicit per-merge sign-off;
the pre-merge audit ASK is unconditional and precedes the merge ask.**
The 2-agent adversarial audit (charter S4) runs and is dispositioned
BEFORE any merge ask.

State at checklist time (verified 2026-08-20, S4):

- LEM branch `arc/daemon-elim` @ `47a6b24` (S0 `5724c1d` → S1 `446e799`
  → S2 `0549d36` → S3 `9d220e4` → S4 docs-only `47a6b24`, design-note
  close-out pointer; doc/notes change only — lean-lib is BYTE-IDENTICAL
  between `9d220e4` and `47a6b24`), worktree
  `worktrees/lem-lean-arc/daemon-elim`, clean. **Linear descendant of
  the mainline: `git merge-base bd7e2eb 9d220e4` =
  `bd7e2ebeaf5d24bc643c59cdac7b31549afd2f2f` and
  `git merge-base --is-ancestor bd7e2eb 9d220e4` succeeds (verified at
  S4, pre-docs-commit; `47a6b24` extends `9d220e4` linearly) —
  `mdd/lean-backend` @ `bd7e2eb` has not moved, so ff-only applies
  directly.**
- CERB branch `arc/daemon-elim` @ `fc7c5b0eb` + the S4 docs commit,
  worktree `worktrees/cerberus-lean-arc/daemon-elim`. Merge base with
  `mdd/cerberus-lean` @ `0b21eb749` is `0b21eb749` (verified) — linear
  descendant, ff-only applies directly.
- CERB lakefile.toml LemLib pin: rev `9d220e49ee1a91356d8034f12b6a9896e1ba7819`
  (= LEM branch head), with an in-file mid-arc comment;
  lake-manifest.json inputRev matches. `deps/lem-pinned` is still at
  `bd7e2eb` (D2: opam pin untouched mid-arc); the opam-installed lem is
  the bd7e2eb build — regeneration during the arc used the checkout lem
  (PATH+LEMLIB). THE PIN DANCE BELOW CLOSES THIS GAP.

Order (ff-only, exactly; lem-lean FIRST):

1. **Pre-merge audit ask (unconditional).** Propose audit scope + scale
   to the operator; disposition findings (fix-or-record) before any
   merge ask. Mandatory scopes per charter S4: (a) derivation
   soundness — no derived default observable in any differential;
   (b) threading completeness vs the S0 census + D6 errata;
   (c) absence-gate fail-closure (negative-tested: plant an axiom,
   watch the build die); (d) April-parallel check — no opaque-fallback
   regression anywhere.
2. **Pre-merge state check.** Confirm `mdd/lean-backend` still @
   `bd7e2eb` and `mdd/cerberus-lean` still @ `0b21eb749`; if either
   moved: rebase the arc branch(es), re-run the full gate, re-ask
   (playbook — merges serialize).
3. **lem-lean merge (operator sign-off required):** on the lem-lean
   primary (parked on `mdd/lean-backend`):
   `git merge --ff-only arc/daemon-elim`
   → `mdd/lean-backend` = `47a6b24`. Re-run lem `make` +
   `tests/comprehensive: make lean` on the merged mainline (gate).
4. **CERB lakefile re-pin (charter: re-pin to the MERGED lem
   commit).** Current pinned rev is `9d220e49ee1a…` (the S3 deletion
   commit); the merged head is `47a6b24` (docs-only on top of it,
   lean-lib byte-identical). Doctrine ("arc closed only when branch
   heads = opam pin = Lake pin") calls for bumping lakefile.toml rev +
   `lake update LemLib` to `47a6b24` (offline via the deps/gitconfig
   redirect; content-neutral for the build) and updating the in-file
   mid-arc comment — as a CERB-branch commit before its merge, gate
   re-run after. FALLBACK (operator's call, recorded if taken): keep
   rev `9d220e49` with a comment noting the head delta is docs-only —
   this leaves Lake pin ≠ branch head and is a deviation from the
   close criterion.
5. **opam pin re-sync (operator/orchestrator at merge time; switch-
   level, in-session-allowed):**
   `git -C deps/lem-pinned reset --hard 47a6b24` (branch
   `cerberus-pin`, = the merged `mdd/lean-backend`) then
   `opam upgrade --switch=cerberus-lean lem`.
   Verify `lem -v` reports the new build. (deps/lem-pinned is the
   container-level worktree — this step is outside the repo worktrees
   and therefore explicitly NOT done by arc workers; it is the
   operator/orchestrator's merge-time action.)
6. **CERB gate re-run at the merge candidate** with the OPAM lem now at
   the merged head (backend code = the `0549d36` S2 state; S3/S4
   touched lean-lib/docs only): `make lean-prelude-src` must be a
   no-op diff vs the
   checkout-lem tree (same backend commit — verify with `git status` on
   generated/ checksums / a clean rebuild), then the full validation
   gate (Tier A per scripts/LADDER.md + test_verify 29/29). An arc is
   closed only when branch heads = opam pin = Lake pin.
7. **cerberus-lean merge (operator sign-off required):** on the
   cerberus-lean primary (parked on `mdd/cerberus-lean`):
   `git merge --ff-only arc/daemon-elim`.
8. **Post-merge rebuild on the primary:** `source scripts/env.sh`;
   `make lean-prelude-src` (opam lem is now the merged head — the primary
   regenerates the DAEMON-free tree); **`make lean-native-obj`**
   (standing gotcha: stale .o FAIL-STOP via the fresh-counter floor);
   full capped `lake build` (in-build absence gate + statement gate +
   audit sweep must be green in the log).
9. **Post-merge certification** (all lake/lean through scripts/capped):
   Tier A per scripts/LADDER.md + `./scripts/test_verify.sh` (29/29) +
   at least one libxml2 battery slice (full Tier B if time permits) +
   the tests/ci reporting sweep. Expected: byte-identical SUMMARY
   lines vs the S3/S4 records (zero movement); any movement is a
   soundness finding, never a baseline update.
10. **Container-doc updates (orchestrator, POST-merge; container
    CLAUDE.md is outside the repos):** arcs line (arc 8 merged; DAEMON
    HONESTY paragraph → resolved wording; boundary-list prose: DAEMON
    TEMPORAL entry removed, absence gates noted; "presumptive arc-8
    spine" queue line replaced); ROADMAP equivalent updates; known-
    issues pin line (lem-lean pins now the merged `arc/daemon-elim`
    head, gates updated).
11. **Worktree/branch disposition (operator's call):** the two
    `arc/daemon-elim` worktrees can be pruned after both merges; the
    branches are fully contained in the mainlines (ff-only).
12. **Next-network-window reminders (do NOT gate the merge):** refresh
    `deps/mirrors/lem-lean.git` (and the rest); `git push` of both
    merged mainlines is a separate operator-gated action.

Validation gate at every step: Tier A per LADDER.md; steps 6/8/9 are
the full certifications. No merge commits, no `git branch -f`, no
pointer surgery; if ff-only is impossible at any point, stop and
re-ask.
