# Arc 1: effects + totality — charter (2026-08-18)

Status: DRAFT for user blessing. First arc under the branch-and-merge
protocol (adopted from golean, `deps/golean/CLAUDE.md` §merge-protocol;
adapted for the two-repo layout below). Governing document:
`../../..​/ROADMAP.md` (container level) — this arc is the remaining half of
Phase 0 plus the Phase-1 totality audit, merged into one design arc because
they shape the same generated-code skeleton.

## End state (the goals, in the user's framing)

Top-level project goals: (1) run and differentially test C programs through
the semantics; (2) eventually formally verify C programs building on the
semantics, with iris-lean as proof machinery, final theorems over the
operational semantics, Iris outside the TCB. Long-term: match the OCaml
backend, but built in Lean so we can reason about the result.

This arc delivers the **design and a working exemplar** of the mechanism
that makes goal (2) reachable without compromising goal (1): how the lem
Lean backend renders

- **ambient effects** (fresh counters, debug output, tagDefs state — what
  OCaml gets from mutable refs) as *honest, pure* Lean on the proof path,
  with the current unsafe-extern scaffold demoted to execution-only or
  retired; and
- **general recursion** (driver loop, Core reduction) as *fuel-threaded
  total* definitions on the proof path, replacing reasoning-opaque
  `partial def`.

Pattern source: golean's fuel opsem → relational layer → adequacy stack
(`deps/golean/docs/2026-07-18_totality-fuel-decision.md`,
`2026-07-21_eval-totalization-correspondence.md` and the arc notes around
them) — read before slice 1, compare deliberately, record divergences.

## What this arc is and is not

IS: a design note with a user ruling; a vertical exemplar through the real
lem backend proving the design compiles, runs, and states; a scale plan
with honest cost estimates for the full conversion.

IS NOT: the full conversion of all ~160 effectful call sites or every
recursive function (that is the next arc, sized by this one's findings);
any pipeline-stage work (desugar/typecheck/translate — separate arcs); any
`.lem` model restructuring (objective 3: declares only, always); any
upstream submission.

## Slices

1. **Inventory + design note.** Census of the effectful call sites (which
   lem constants, which generated defs, which are inside instance methods —
   the known attribute gap) and of `partial def` emission (which generated
   functions, which are on the execution path). Design options laid out
   with tradeoffs, at minimum: (a) lifting into the model's existing
   monads where call sites already sit in one; (b) a dedicated effect
   monad/state carrier threaded by the backend (Lean-output-only lifting);
   (c) fuel: backend-generated fuel threading (`declare`-controlled?) vs
   hand-written fuel wrappers at the target_rep boundary; (d) how effects
   and fuel COMPOSE in one def; (e) what the ND/driver layer needs (the
   fuel opsem must expose Core's nondeterminism as outcome sets/oracle —
   goal-2 requirement). Includes the TCB statement: exactly what remains
   axiomatic/unsafe on each path, and the execution↔proof-path
   correspondence obligation.
   → **USER CHECKPOINT: design ruling** (the mechanism, the monad shape,
   the fuel story, what the next arc converts first).
2. **Vertical exemplar** (ruled design, implemented in lem behind
   declares): one effectful val (`fresh_int`) and one small recursive
   function family rendered via the new mechanism end-to-end — lem
   comprehensive tests extended (`tests/comprehensive/test_target_reps.lem`
   pattern), cerberus regenerated, `fresh-int-test` green **via the pure
   path**, existing suites at baseline, and one toy statement proved over
   the exemplar's fuel-threaded output (the reasoning smoke test — this is
   what the scaffold cannot do).
   → **USER CHECKPOINT: exemplar sign-off** (is this the shape to scale).
3. **Scale plan + close.** What full conversion costs (sites, expected lem
   changes, risks — instance methods, mutual recursion, the ND layer);
   ROADMAP.md updated; next arc chartered; arc-end audit ask; merge
   protocol.

## Two-repo mechanics (the pin dance)

Work spans lem-lean and cerberus-lean. Rules:

- Branch pair, same name: `arc/effects-totality` off `mdd/lean-backend`
  (lem-lean) and off `mdd/cerberus-lean` (cerberus-lean). Worktrees via
  `scripts/new-worktree.sh <repo> arc/effects-totality`.
- cerberus-lean's arc branch may point its Lake manifest + the
  `deps/lem-pinned` checkout at lem-lean arc-branch commits DURING the arc
  (the insteadOf redirect makes arc commits fetchable immediately).
- **Merge order at arc end:** lem-lean merges first (ff-only into
  `mdd/lean-backend`), then cerberus-lean's pins are moved to the *merged*
  lem commit on the cerberus arc branch, gate re-run, then cerberus-lean
  merges (ff-only into `mdd/cerberus-lean`). Branch heads = opam pin =
  Lake pin at close, or the arc is not closed.
- `git push` is separate, operator-gated, needs a networked window anyway.

## The validation gate (this project's `scripts/ci` equivalent)

Green before any checkpoint claim, any audit, any merge:

1. lem-lean: `make` + `tests/comprehensive: make lean` (35 generate +
   compile, all green).
2. cerberus-lean: `make lean-build` (regenerate + natives + lake build),
   `./scripts/test_unit.sh` (2/2), `./scripts/test_parse.sh` (ALL),
   `./scripts/test_core.sh` (baseline: 104/105, `078-float-special` is the
   known red — any OTHER red is a regression).
3. No new `sorry`/axioms outside the declared boundary list; the arc's
   design note carries the axiom census.

A green build is not evidence of correctness (golean doctrine, inherited):
the decisive signals are the differential baselines and, for this arc, the
exemplar's proved statement.

## Front-loaded (blessed with this charter) vs checkpointed

- FD-1 — objective 3 binds: `.lem` model changes are declares only.
- FD-2 — the pure mechanism is the destination; the scaffold survives at
  most as an execution-mode alternative, never the proof path. If the
  design finds the scaffold should be retired entirely, that is in-lane.
- FD-3 — homes: design notes in `lean_frontend/docs/` (this dir), lem-side
  design/doc in lem-lean `doc/notes/` (the effectful note's precedent);
  decisions in files, not chat (golean rule, inherited).
- FD-4 — golean is the pattern library, not gospel: divergences from its
  fuel/adequacy choices are fine but must be recorded with reasons.
- CHECKPOINTED: the mechanism itself (slice-1 ruling); the exemplar shape
  (slice-2 sign-off); anything touching the ND/driver design beyond
  requirements-gathering (flag it, don't decide it).

## Must-park

Full-scale conversion; pipeline stages; `078-float-special`; the two
execution-path sorries (unless the exemplar's recursive family naturally
IS one of them — bring that back as a proposal, not a fait accompli);
toolchain bumps (CSE behavior is toolchain-sensitive — pin 4.29.0 for the
whole arc); iris-lean/mathlib builds; upstreaming; any machine-global or
opam-config change (operator-gated, standing rule).

## Pre-merge audit (the ask is unconditional)

Before merge, propose scope + scale to the user and get sign-off; the user
may waive or trim, the ask is never skipped (golean protocol §3, adopted
verbatim). Primary dimension for THIS arc: **semantics/TCB honesty of the
effects+fuel design** — does the pure path mean what it claims (no hidden
unsafe reachable from proof-facing terms), is the execution↔proof
correspondence stated honestly, is the axiom census complete, and do the
compiler-hazard mitigations (extraction/CSE — the class that already bit
us three ways) hold on the exemplar under adversarial reading. Secondary:
claim strength of the design note vs what the exemplar demonstrates.

## Exit criterion

The design ruling is recorded; the exemplar is merged green through both
repos under the pin discipline; the scale plan and next-arc charter exist;
ROADMAP.md reflects reality. Deferral of the scale-up with an honest
record is success; an unproved design ruling is not.
