# Arc 5 decision log (link & libc)

Orchestrator/worker doctrine; dual-lineage discipline (OCaml = what,
prototype = how). Format: **D<n>** — decision / why / alternatives.

**D1** — Lane: branch `arc/libc-linking`, worktree
`worktrees/cerberus-lean-arc/libc-linking`. Charter blessed via the goal
launch (DRAFT marker removed). No lem-lean worktree unless a backend
need emerges. Native-objects note: this worktree primes native/*.o from
the post-arc-4 primary (current); any native/*.c change requires `make
lean-native-obj` (arc-4 gotcha, now in CLAUDE.md).
