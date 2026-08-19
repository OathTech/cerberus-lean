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

**D2** — S0 findings accepted: the "silent" rc=1 was a stderr-lost
`INTERNAL PANIC: executed 'sorry'` from the generated BEq core_step2
fallback, fired by driver2's blocked-thread filter — NOT
easy_update_mem_value_aux (return-42 has no memory ops). Frontier map
(105 files) drove S1 scoping. Worker fixed nothing (semantics fixes out
of S0 scope) — correct restraint.

**D3** — S1a deviation APPROVED post-hoc: skip_instances is unusable for
core_step2 (suppresses the real Inhabited that Core_reduction's own
failwithI sites need; probed, ~8 synthesis failures, import-cycle
unfixable). Priority-override instead: hand instances at default priority
beat the (priority := low) sorry fallbacks; extra_import lives in
driver.lem (sole legal host in the import closure). Verified at boundary:
model diff = declares + comments only; OCaml token-neutral; gates green;
return-42 → Active 42. Caveat recorded in-file: new equality use sites on
core_step2 outside Driver.lean would silently get the fallback — audit
scope item.

**D4** — Ordering call: S2 (differential harness port) BEFORE further
crash-fixing. With 62 Active / 26 Killed, the bottleneck is
CLASSIFICATION (which results are right?), not crashes; the harness
turns the frontier into a mismatch list and S3 batches work that list.
The remaining crash classes (15 ACTION_ILLTYPED, 2 SeqRMW) become S3
batch items ranked by differential impact. Also noted: the execution
path uses the CONCRETE memory model (CerbMem) — easy_update (defacto)
is likely OFF the runtime path (which is why 62 programs store happily);
its elimination matters for driver2's KERNEL CONE (success condition 2)
and gets a dedicated later worker.
