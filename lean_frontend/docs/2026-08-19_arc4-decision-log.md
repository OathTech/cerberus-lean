# Arc 4 decision log (exec pipeline)

Orchestrator/worker doctrine (first full outing): workers commit their own
slices (green gates only), orchestrator scopes + verifies at batch
boundaries, merge is the user's. Format: **D<n>** — decision / why /
alternatives.

**D1** — Lane: branch `arc/exec-pipeline`, worktree
`worktrees/cerberus-lean-arc/exec-pipeline`. A lem-lean worktree is
created LAZILY only if S1 demands a backend change (the known
self-shadowing shape); the opam lem (574e326) serves regen meanwhile.
Charter + this log are the orchestrator's arc-opening commit.
