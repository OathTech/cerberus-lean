# Arc 4 merge checklist (awaiting operator sign-off — do not merge without it)

State at close: single arc branch `arc/exec-pipeline` (cerberus-lean
only — ZERO lem-lean changes this arc: pins remain `574e326` = opam =
Lake = lem-lean mainline; NO pin dance required). Tree clean, all gates
green, both audits run with all findings fixed-or-recorded (D13/D14).

Merge (ff-only, exactly):
1. cerberus-lean primary (parked on `mdd/cerberus-lean`):
   `git merge --ff-only arc/exec-pipeline`.
2. Post-merge: rebuild primary (regen + lake build), run the FULL gate
   set incl. the new sync gate and `test_exec.sh --check-baseline`;
   update container CLAUDE.md (gates line: + exec differential;
   playbook arcs line: arc 4 merged; known-issues corpus numbers) and
   ROADMAP (Phase 2 execute ✅-differential; Phase 3 milestone status).
3. Prune the arc worktree; primary certified on the merged tip.

Validation gate at every step: lake build 356/356; test_unit.sh 4/4 +
sync OK + purity CLEAN + axiom cones OK (incl. driver2 sorryAx-free) +
totality CLEAN; test_parse ALL; test_core 105/106 (known 078 red);
test_exec 103/106 with --check-baseline rc 0; test_elab 103/106 SAME.

The merge ask is unconditional (playbook); the audit is done, the
decision is the operator's.
