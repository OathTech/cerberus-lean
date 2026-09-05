# Concurrency Phase 0 — consumer note for refined-cerberus (charter §8; 2026-09-05)

To the refined-cerberus orchestrator, with the cumulative change manifest
(`2026-09-05_concurrency-phase0-change-manifest.md`). [AGENT, concurrency
branch]; the operator relays. Nothing here designs your logic (charter
§8.3, "we do not design their logic"); it states the semantics-side facts
and what changed since your S1 review response.

## 1. What you asked for, and where it stands

| Your ask (response §) | Status |
|---|---|
| Q1 explicit selector argument, one token per statement | DONE (S1): `drive fmapEmpty false` → `drive fmapEmpty CM_sequential`; no bool anywhere |
| Q2 distinguished error constructors | DONE (S1/S3): `DErr_model_refused (model_refusal)`, `DErr_model_inconsistent (model_inconsistency)`, payload-carrying, with generated renderers |
| Q3 `sc_fragment_ok` total and `rfl`-evaluable; `epar_free` alongside | DONE (S1): mutual structural scan over the file; pinned by `rfl` examples in the exemplar |
| Q4 labelling: SC-instance results carry `sc_fragment_ok file = true` | Your side; the predicate and the refusal set are as agreed |
| Q4 the `Epar`-free agreement lemma | **NOT DISCHARGED** — §3 below |
| Q5 staged re-pin; the S1 manifest lists the kill arms by file:line; generated textual diffs | DONE: S1 manifest §3 (arms), per-slice generated diffs S1/S3/S4/S5 |
| §7 the single-thread loop's shape (last component first, first advanceable) preserved | PRESERVED at every slice; the only change near it is `can_advance`'s selector-and-runnable-count condition (S1 manifest §4) |

## 2. The four §8 points, as landed

1. **Signature.** One token per statement; the S1 manifest is the
   announced change; your re-pin is your forced-semantics-change slice.
2. **Scheduler degeneracy.** Your register's reading stays TRUE under
   `CM_sequential` (and under `CM_sc` with ONE runnable thread — the S2
   design made scheduling points conditional on ≥ 2 runnable threads
   exactly so that your inner-loop lemmas keep their meaning). It is
   FALSE under `CM_sc` once a `par` runs: the outer loop then turns one
   round per memory action.
3. **Commitment risk.** The SC instance is labelled everywhere; DESIGN.md
   §4 records the value-at-issue boundary (mover Phase 1) so no reader
   takes `CM_sc`'s shape for the general one; your memory-value coupling
   behind an interface (your §5) is the matching move.
4. **Timing.** This note goes out with the cumulative manifest at the
   S6 "mergeable" record; merge is the operator's.

## 3. The agreement lemma: precise status

Your response asked (§5): for `Epar`-free files, `runND (drive tds
CM_sequential file args) st = runND (drive tds CM_sc file args) st`, "or
the weaker 'same outcome list up to the trace field' if the scheduler
rounds leave a footprint in the state". Our acceptance record took it as
a Phase-0 obligation with an S5 proof. It is not proved. What is true:

- The S2 design holds: with one runnable thread `can_advance` takes the
  sequential branch, so the STEP SEQUENCE is the same — the invariant
  part of the accepted proof shape.
- S3 changed the footprint: under `CM_sc` every action also (a) updates
  the recorded candidate execution in the driver state and (b) annotates
  the arena/stack with sb/asw edges, and the trace end (c) evaluates
  `data_races` and the SC consistency tree. So the literal state equality
  is FALSE, and the true statement is your weaker form: the VERDICT
  LISTS agree. Its content beyond the invariant is that for a single
  thread (c) is silent — `data_races` is empty (no cross-thread pair) and
  the recorded execution with rf = the last write satisfies the tree
  (a single-thread SC-consistency theorem over cmm_csem's tree).
- The remaining proof is therefore not the "no bisimulation" invariant
  alone; it needs that consistency theorem. We have NOT started it. The
  operator decides between an S5b slice before merge and handing it to
  you as owed with this statement. Whichever, the semantics-side facts
  you need for the invariant part are already theorems: the six
  SequentialIdentity lemmas (S5 manifest §2).

## 4. What the S3/S4 mechanics mean for `Round.lean`

`Step_action_request2` carries polarity and the action's annotation (two
extra binders in your classification match); `step_ctx` takes the model;
`action_request2` has one more constructor (`CompareExchangeRequest2`,
S4). Under `CM_sequential` none of them changes a round's classification
(`frag_round_complete`, `ShippedRefusal`): the new kill arms are the two
S1 manifest §3 rows, and the S3/S4 arms are `CM_sc`-only or perform-then-
return (the compare_exchange request under `CM_sequential` performs and
records nothing).

## 5. Provenance

[AGENT, concurrency branch] 2026-09-05. Your response quoted from
`2026-09-04_concurrency-S1-interface-review-response.md` Part A
(verbatim relay). Nothing merged, nothing pushed; the operator gates both.
