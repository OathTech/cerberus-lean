# Arc 6 decision log (libc & speed)

DECISION PROVENANCE (operator directive, goal launch 2026-08-19): every
decision is tagged **[USER]** (made or explicitly directed by the
operator, with the directing message paraphrased) or **[AGENT]** (made
autonomously by the orchestrator or a worker, resolved by project
principles). Mistagging an agent decision as user-decided is a critical
failure. Worker-made calls are tagged [AGENT:worker-slice].

**D1 [USER]** — Arc scope and charter blessed via goal launch; the
prototype-libc prior-art study in S0(a) is an explicit operator
directive ("we already support libc-loading in the prototype — look at
that closely"), as is the GoLean verification framing recorded in the
charter's S3-adjacent note (operator correction, 2026-08-19).

**D2 [AGENT]** — Lane: branch `arc/libc-load`, worktree
`worktrees/cerberus-lean-arc/libc-load`; charter DRAFT marker removed on
launch. No lem-lean worktree unless a backend need emerges (none
expected; any lem change triggers the full pin dance per charter).
