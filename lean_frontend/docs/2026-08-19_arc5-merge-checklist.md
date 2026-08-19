# Arc 5 merge checklist (awaiting operator sign-off — do not merge without it)

State at close: single arc branch `arc/libc-linking` (cerberus-lean only
— ZERO lem-lean and ZERO frontend/model/*.lem changes this arc:
audit-verified; pins remain `574e326` everywhere, NO pin dance). Tree
clean, all gates green, 2 adversarial audits (zero blockers), every
finding fixed-or-recorded (D6-D7).

Merge (ff-only, exactly):
1. cerberus-lean primary (parked on `mdd/cerberus-lean`):
   `git merge --ff-only arc/libc-linking`.
2. Post-merge primary certification: `make lean-prelude-src`;
   **`make lean-native-obj` (MANDATORY — this arc added native/md5.c and
   the force-thunk extern; stale .o fail-stops per the arc-4 floor
   assertion)**; full `lake build`; then the ladder: test_unit 4/4
   (sync + purity + axiom census 2 + cones + totality), test_exec
   --check-baseline rc 0 (103/106), coverage/debug baselines rc 0,
   test_multi_tu 2/2, test_parse ALL, test_core (078 known red only),
   test_elab reporting, plus ≥2 test_libxml2.sh slices MATCH (full 28
   ~35 min, optional at merge).
3. Update container CLAUDE.md (arcs line: arc 5 merged; gates line:
   multi-TU + libxml2 gates; known-issues: axiom census, libxml2
   numbers) and ROADMAP (Phase-2/3 status; libxml2 first-contact result;
   arc-6 pricing).
4. Prune the arc worktree; primary certified on the merged tip.

The merge ask is unconditional (playbook); audits done, decision is the
operator's.
