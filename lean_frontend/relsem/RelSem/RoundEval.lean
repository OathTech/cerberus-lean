/-
  RelSem.RoundEval — arc-17 S2 (2026-08-25): THE LAW-DRIVEN ROUND
  EVALUATOR (the S1-registered input #1; charter S2 deliverable 1).

  WHAT THIS FIXES (measured, S1 record §4.2): minting a MEMORY round's
  successor by raw meta `whnf` allocates past the 64 G blast-radius cap
  — unfolding the byte-map's balanced-tree operations degrades DAG
  sharing. The fix is never materializing what the laws can navigate:
  memory-round successors are computed by applying the Kit
  `mem_*_block` / `perform_*` / `advance_action_request` equations
  SYMBOLICALLY — the law chain is elaborated against the round
  equation with the successor as a metavariable, so the successor
  STATE is assembled from the laws' computed-RHS shapes
  (`writeBytesTo`-form memory, named-state field references), and the
  equation is proved by the law-composition term whose leaves are
  small kernel-checked `rfl` ground facts. The kernel recomputes and
  checks everything at `addDecl` (the S0 donor contract); the meta
  layer's whnf/reduce results are never trusted, they only shape the
  recorded claim.

  *Lineage (canon-first, charter-named)*: HeapLang-ProofMode symbolic
  stepping — successor states are computed once in the meta layer and
  goals ride state NAMES (arc-16 S3 §7; the S0 `derive_state` emitter
  is the naming substrate); the per-shape dispatch consumes the
  arc-17 S1 construct-law registry and the arc-9 Kit memory blocks —
  law-application at the meta level, one registered rule per
  discovered head (the Lithium-fragment discipline, S1 record §5).

  GROUND-LITERAL DISCIPLINE (the probe-A lesson, this slice): free
  unification assigns UNREDUCED whnf leftovers to law arguments
  (giant projection cascades in alloc bases, lazy byte lists), which
  poisons every later round's side facts. So every scalar the
  successor spelling carries — addresses, allocation ids, byte lists,
  loaded values, supply counters — is ground-evaluated to a LITERAL
  at the meta level and supplied to the law explicitly; the
  elaborator then CHECKS raw-vs-literal defeq (small) instead of
  assigning raw. Residual open terms in a ground position are a
  TAGGED frontier (fail-closed — that is the env-algebra/apartness
  boundary, not a silent skip).

  THE WHOLE-RUN MINT MODE IS DELETED (V0, 2026-08-27, kill basket —
  record docs/2026-08-27_v0-statements-and-ban.md): the
  `derive_rounds` command (RoundEval/Assembly.lean — binder/pack
  setup, the round loop, relative-chain assembly, the whole-run
  terminal artifacts) was the enumeration engine's entry point
  (assessment K-2b: per-round kernel equations of one concrete
  execution) and its last KEEP consumers (the T1–T5 threaded proofs)
  are retired to honest-unproved statements. What remains below is
  exactly the CHASSIS the conversion table keeps (C-5: fail-closed
  proof-producing emitters, law-chain elaboration + registry
  dispatch, kernelVerdict ground leaves, hypothesis threading,
  anchor/ground-literal discipline) — the V2 symbolic stepper
  re-targets it to goal-directed per-construct stepping with
  case-split at irreducible discriminants.

  House rules: no sorry, no axioms; meta code only — every emitted
  object is an ordinary kernel-checked declaration. Frontier errors
  carry the S0 `frontierTag`.
-/

-- ARC-18 C1 DECOMPOSITION (2026-08-25): the monolithic evaluator
-- (3,586 lines — the charter-named recurrence risk, review F8) is
-- SPLIT into contract-shaped modules, each with an abstraction-
-- sentence header; this file is the UMBRELLA (public interface
-- unchanged — `import RelSem.RoundEval` keeps working):
--
--   RoundEval/Core.lean     expr/ground primitives + hooks
--   RoundEval/Hyp.lean      the hypothesis-threading mode
--   RoundEval/Mint.lean     anchor discipline + kernel emitters
--   RoundEval/Arith.lean    verdict engine + bridge lemmas
--   RoundEval/Classify.lean candidate collection + the .all dig
--   RoundEval/Lanes.lean    minter lanes + dispatcher
--   RoundEval/Rounds.lean   per-head round lanes + law chains
--   (RoundEval/Assembly.lean — the derive_rounds command + whole-run
--    assembly — DELETED at V0 2026-08-27 with the mint mode)
--
-- The engine's line count is a WATCHED METRIC under down-pressure
-- (scripts/check_engine_size.sh + scripts/engine_size_baseline.txt;
-- the R3 register row): any semantic knowledge appearing twice in
-- engine code becomes a registered law (RelSem/LawRegistry.lean).

import RelSem.RoundEval.Core
import RelSem.RoundEval.Hyp
import RelSem.RoundEval.Mint
import RelSem.RoundEval.Arith
import RelSem.RoundEval.Classify
import RelSem.RoundEval.Lanes
import RelSem.RoundEval.Rounds
