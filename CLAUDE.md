# Cerberus

C semantics framework. See upstream: https://github.com/rems-project/cerberus

## Soundness and landing

Soundness is the key value of this project: other projects build verification
results on this semantics. Nothing lands on `mdd/cerberus-lean` unless the
full battery of [`scripts/LADDER.md`](scripts/LADDER.md) (Tier A + Tier B)
has been run on the exact commit and is green. Skipping or shortening it must
never happen without the user's explicit, direct request for that landing
([USER 2026-11-24]).

The working practices of this repository (the landing rule in full, the
trust story, how work is branched, recorded and reviewed, and what the
ladder needs on the machine) are in
[`lean_frontend/CLAUDE.md`](lean_frontend/CLAUDE.md). **Read that whole file
before doing any work here**, including setup, migration and documentation
work. Until 2026-11-23 these practices lived in a workspace-level file
outside the repository; they are now there.

## SC concurrency work

Start with [SC-CONCURRENCY.md](SC-CONCURRENCY.md), the governing master plan
for scope, current status, acceptance and incremental mainline landings. Read
the relevant technical-design section before each slice and update the plan
when a decision or accepted slice changes its state. Prototype handoffs and
older concurrency charters are historical inputs, not current instructions.

## Branch roles

- `mdd/cerberus-lean` — the mainline of this fork; all work lands here
  via ff-only merges on operator sign-off.
- `master` — upstream-tracking only (rems-project/cerberus); NEVER
  commit to it.
- Work happens on arc/feature branches in worktrees; parked branches
  (`arc/segment-ladder` + tag `park/reasoning-era-20260831`,
  `arc/t5-seal`) are preserved records, never merged.

## Lean frontend

The Lean 4 port of the semantics — the product of this branch — lives
in `lean_frontend/`. See [`lean_frontend/CLAUDE.md`](lean_frontend/CLAUDE.md)
for build instructions, architecture, and development guide;
[`lean_frontend/VALIDATION.md`](lean_frontend/VALIDATION.md) for the
differential-validation trust story.
