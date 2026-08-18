# Arc 3 charter: totalize the execution slice ("totality sweep")

Date: 2026-08-18. Mode: **long-cycle autonomous** — the agent orchestrates,
makes judgement calls, logs them, and does not pause for feedback except for
the emergency exit defined below. Merge to mainline requires explicit user
sign-off and is NOT part of this arc's execution.

## Objective

Every definition in the execution slice — the 11 generated modules named in
`scripts/check_exec_purity.sh` (`Core_run Core_reduction Core_eval Driver
Core_run_aux Core_aux Defacto_memory Defacto_memory_aux Ctype_aux
Nondeterminism Mem_aux`) — is a total `def` (structural, well-founded, or
fuel-worker + wrapper), with a small justified allowlist of exceptions,
enforced by a new fail-closed gate. This completes layer 1 of the golean
strategy (fuel-based opsem you can state kernel theorems over) for the whole
slice, not just the arc-2 exemplars.

Approximate starting census (S0 re-derives exactly): ~41 `partial def`s in
the slice — ~16 standalone, ~25 inside `mutual` blocks, ~16 reader-lifted
(including the eval/driver spine: `step_eval_pexpr`, `full_eval_pexpr`,
`driver2`).

## Known blockers (clear these before the sweep, not during)

- **B1 — fuel×reader is fail-closed in the lem backend.** The spine defs are
  reader-lifted, so this ban blocks the highest-value targets. Design sketch
  (validated on paper, must be probe-proven): the fuel binder is already
  emitted first, so the worker becomes `f_lemFuel (lemFuel) (_lemReader…)
  (pats)`; the point-free wrapper `f := f_lemFuel lemDefaultFuel` then has
  the reader-prefixed type, the pre-pass already treats the wrapper's cref
  as lifted, and call sites inject the reader into the wrapper as usual. The
  fix is: build the wrapper's ascribed type by prepending the reader binder
  types when the def is lifted, and delete the raise. Probe first in
  `lem-lean/tests/comprehensive/`.
- **B2 — fuel×mutual is fail-closed.** ~25 slice partials are mutual. First
  try termination declares on all members of each mutual family (supported
  today); only families that are genuinely non-structural AND non-WF need
  fuel. If S0 shows few such families, PARK them on the allowlist rather
  than extending lem; if the spine itself needs it, extend lem (shared fuel
  parameter across the mutual block, one wrapper per member) — decision-log
  the call either way.
- **B3 — WF-derivation compile time.** `termination_argument = automatic` on
  large generated matches may make Lean's equation compiler grind. Per-def
  mitigation: if a single def's elaboration exceeds ~5 min, revert that
  declare, classify it fuel-or-park, record it. Never let one def stall a
  batch.

## Slices

**S0 — census & classification (derisk).** Commit a counting script (the
gate in reporting mode). For each partial def in the slice, classify:
`structural` / `wf` / `fuel` / `fuel×reader (B1)` / `fuel×mutual (B2)` /
`park`, with the recursion's driver noted. Probe B1 (and B2 if needed) as
minimal .lem tests in lem-lean BEFORE touching backend code. Output: a
classification table in the design doc + go/no-go on each lem extension.

**S1 — lem extensions (only what S0 demands).** Branch
`arc/totality-sweep` in lem-lean. B1 per the sketch; B2 only if S0 says so.
Every mechanism: comprehensive-test sections (positive + at least one
fail-closed negative), guards for still-unsupported combos (e.g.
fuel×reader_seed), both-artifact gate (lem test suite + cerberus regen +
full build) before the sweep may consume it. Declares must FOLLOW their
binding (recurring footgun).

**S2 — the sweep (orchestrated batches).** Branch `arc/totality-sweep` in
cerberus-lean, worktrees via `scripts/new-worktree.sh`. Batch by module;
each batch is delegated to a worker agent with this recipe and evaluated by
the orchestrator re-running gates (never accept agent-claimed green):
1. Add `declare {lean} termination_argument <f> = automatic` after the def
   (all members for mutual families); regen (`make lean-prelude-src`), build.
2. If the checker rejects: switch to a fuel declare with an **honest
   sentinel** — use the type's own error channel where one exists (ndM
   kill/fail, driver error constructors), else a panic helper in the
   module's extern namespace (pattern: `CerbMem.zerosFuelExhausted`).
   Backtick lexer excludes `"`, so sentinels are helper calls, not literals.
3. If B3 bites: revert, park, record.
4. Model `.lem` edits are **declares only** — no restructuring of cerberus
   definitions (project principle #3). OCaml artifact must stay green
   (declares are no-ops for the ocaml target; verify per batch).
Each batch = one commit, all gates green at that commit.

**S3 — gate + theorems.** `scripts/check_exec_totality.sh`: enforcing in
`test_unit.sh`, fail-closed, absolute paths resolved before any cd (learned
lesson), allowlist read from a committed file with a one-line justification
per entry. Theorems in `test/Unit/EffectsProofTest.lean` (or a sibling):
≥1 wrapper-defeq theorem per newly-fuel'd def, ≥6 new symbolic-execution
theorems over newly-total defs targeting the eval spine (e.g.
`step_eval_pexpr` on literal pexprs), all under the existing axiom bar
(DAEMON-clean cones, sorryAx always fatal), wired into the unit gate.

**S4 — close-out.** Design-doc section (final disposition table), decision
log complete, 2-agent audit (adversarial: gate soundness, sentinel honesty,
OCaml-artifact neutrality, lem guard coverage), fix-or-record every finding,
pin dance to arc tips (Lake manifest + `deps/lem-pinned` + in-switch opam
reinstall), merge-readiness checklist written. **Stop. Do not merge.**

## Success conditions (all machine-checkable)

1. `./scripts/test_unit.sh` green INCLUDING the new enforcing
   `check_exec_totality.sh`: zero `partial def` in the 11 slice modules
   outside the allowlist.
2. Allowlist ≤ 5 defs (target); hard cap 10 — reaching the cap is a replan
   trigger, not a threshold to grow past silently. Every entry justified.
3. At every commit: `lake build` full-green (module count monotone),
   `check_exec_purity` CLEAN, axiom gate OK, `test_parse.sh` ALL,
   `test_core.sh` ≥ 104/105; OCaml prelude+driver build and cerberus test
   scripts unchanged-green.
4. lem-lean: comprehensive tests cover every new mechanism incl. negative
   probes; no still-unsupported combination fails open.
5. New theorems per S3 counts, kernel-checked in the unit gate.
6. Records: `docs/2026-08-18_arc3-decision-log.md` (every judgement call:
   what, why, alternatives), design-doc appendix, audit dispositions.
7. End state: both arc branches gate-green with pins synced to arc tips;
   mainlines untouched; merge checklist ready for user sign-off.

## Autonomy protocol

Judgement calls (sentinel choices, park-vs-extend, batch order, probe
design) are the agent's — decide by project principles (OCaml parity,
declares-only, honest sentinels, fail-closed gates, no global state), log in
the decision log, keep going. Do not stop to solicit feedback.

**EMERGENCY EXIT:** the agent may declare an emergency early exit, stating
its nature; it is always permitted without question. Reserve it for true
stuckness (resource-blocked, mis-specified/unsat requirements, spinning
with minimal progress) or dire threat to project success — not routine
decisions. Concrete tripwires for this arc: allowlist hard cap reached;
B1/B2 probe reveals the mechanism is unsound (not merely laborious); any
gate that can only be kept green by weakening it.

Machine-global state remains untouchable under all circumstances; a
needed-global-change situation is an emergency exit, never an action.
