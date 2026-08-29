# Cerberus

C semantics framework. See upstream: https://github.com/rems-project/cerberus

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
