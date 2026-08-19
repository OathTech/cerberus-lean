# Arc 6 merge checklist (awaiting operator sign-off — do not merge without it)

TWO-REPO merge this arc (lem-lean library change). State at close: both
arc branches gate-green; pins aligned (lem `bd7e2eb` = Lake manifest =
deps/lem-pinned = opam); certified from pins.

Order (ff-only, exactly):
1. lem-lean primary (parked on `mdd/lean-backend`):
   `git merge --ff-only arc/libc-load` (2 commits: Fmap representation,
   LemLibLegacy freeze-guard; ff preserves ids so `bd7e2eb` stays valid
   everywhere — no commit re-pin needed).
2. cerberus-lean arc worktree or post-merge: flip lakefile.toml rev
   `arc/libc-load` → `mdd/lean-backend` (same commit), `lake update
   LemLib` (manifest hash unchanged), commit; re-run Tier A + uri gate.
3. cerberus-lean primary: `git merge --ff-only arc/libc-load`.
4. Post-merge primary certification: `make lean-prelude-src` (opam lem
   is already the arc lem — safe), `make lean-native-obj` if native/*
   changed (it did NOT this arc — no md5-class additions; still cheap
   to run), full lake build, then Tier B slow ladder per
   scripts/LADDER.md + `test_exec.sh tests/ci` reporting sweep.
5. Container docs: CLAUDE.md (arcs line: arc 6 merged; gates line: uri
   GATING + D14 ban + disjoint counters; known-issues: 078 is GREEN —
   remove the known-red language, test_core baseline is now 100%;
   ladder reference) and ROADMAP (Phase-2/3 status: libc+varargs+perf
   done, ci scoreboard, arc-7 = Layer-2).
6. Prune both arc worktrees + the spike worktree remains (spike/relsem
   is arc-7 input, NOT merged — it merges with arc 7).

Validation gate at every step: Tier A per LADDER.md + uri 16/16; Tier B
at final certification. The merge ask is unconditional; audits done,
decision is the operator's.
