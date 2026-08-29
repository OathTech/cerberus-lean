# Arc-18 amended charter — the segment ladder (long-cycle)

STATUS: DRAFT codifying the RATIFIED decision slate ([USER 2026-08-26],
this session). Supersedes the arc-18 remainder (C3c–C6) with a single
long-cycle ladder run to completion. Working copy: container notes/;
commits to lean_frontend/docs/ on the arc branch after the interim
merge. Inputs: the reasoning-layer design pass
(notes/2026-08-26_reasoning-layer-design-pass.md), the arc-18 charter
(docs/2026-08-25_arc18-coherence-charter.md), the reasoning-layer
contracts (NORMATIVE), the C0–C4 records. AUDITED 2026-08-26:
Fable-class pragmatics audit verdict SOUND-WITH-AMENDMENTS; all nine
amendments (F1–F9) are folded into the text below and tagged [F#].

## Mandate and provenance

- [USER 2026-08-26] Hoare ruling: machine reasoning ≅ human argument;
  segments to join points; walks are engine room. Proof-style
  professor test is the acceptance standard.
- [USER 2026-08-26] Right-thing-now ruling: "if we're confident, we
  should move towards the right thing" — narrow slices only where
  confidence is genuinely low (the two flagged unknowns below).
- [USER 2026-08-26] Single long-cycle charter, decisions front-loaded,
  push for completion.
- [USER 2026-08-26] MIRROR-DONOR DISCIPLINE: "match / mirror BRiCk /
  refinedC in places it makes sense. Not gratuitously be different."
  Extension of mirror-OCaml doctrine to the proof layer; enforcement
  via the donor-correspondence table (deliverable, audited).
- [USER 2026-08-26] Decision slate ratified: (1) interim merge C0–C4
  first; (2) T4-apartness in; (3) capstone in — and the corpus makes
  "the final exam trivial" (idiom-census ramp, >20 examples as
  needed); (4) professor pass keeps us honest; (5) compositional
  capability is REQUIRED and takes the STANDARD form (SL function
  contracts + frame rule, mirroring typed_function/wp_call — the SAW
  whole-state staging is retired as a stale pre-Iris design); (6)
  dumb-agent probe at the hard bar.
- [USER 2026-08-26] Corpus difficulty bias: "bias our 'tiny C'
  examples to cases that make reasoning hard. loops, compositional
  reasoning, memory etc. Easy cases should be easy, hard cases test
  the edges."

## Design (front-loaded, mirror-donor)

- **Judgment**: RefinedC-shaped block judgment at Core labels —
  invariants declared as a MAP from labels to footprint assertions
  (their `typed_block`/`gmap label` shape); per-segment obligations
  DERIVED from the map, not hand-composed. Defined as a WP wrapper
  (their `typed_val_expr` shape) over the existing wpk/chainrel
  substrate. Lineage: Floyd cut points; Hoare logic; RefinedC
  typed_block; BRiCk wp rules. [F1] The judgment is ∃-ROUND from day
  one ("reaches the next join point in SOME finite round count"):
  the current `iter_compose` (Kit/Loop.lean) is fixed-round-count
  (uniform k per iteration) and cannot state a loop whose body
  branches; R2 builds the existential/variable-round composition
  variant (pure Nat induction; the arc-9 `_var` work-order item,
  never built) as in-scope, not an R6 surprise.
- **Exits**: BRiCk Kpred idea (Normal/Break/Continue/Return as
  continuation-indexed postcondition) adopted where Core's
  save/run shapes need it; no bespoke exit story.
- **Contracts**: ONE FnSpec form, two roles — the spec a function is
  proved against (verify_fn) IS the object a caller consumes at a
  call site. Call rule = Hoare procedure rule + frame rule
  (RefinedC fn_spec / BRiCk wp_call mirror; SAW overrides cited as
  the lineage that dissolves into this, kernel-checked). [F9] FnSpec
  is GREENFIELD (zero occurrences in the tree today) — an explicit
  R2 build item, not an existing form. PENDING-[USER] forward-design
  constraint (proposed, awaiting nod): FnSpec designed
  PROMOTION-READY — nothing in its form may assume it stays
  proof-layer-only, so a later operator decision to admit API
  contracts at statement level is a promotion, not a rework.
- **Assertions**: existing CerbMemInterp footprint vocabulary; no new
  assertion DSL. Loop invariants in footprint form are ORDINARY
  proof-layer content (no per-instance gate; the SL escape hatch
  governs statements only — statements unchanged, gate-enforced).
- **Deliberate divergences** (in the correspondence table, with
  rationale): kernel certificates instead of solver/automation trust;
  no refinement-type/subsumption layer now (reach-not-clone; breadth
  stereotyping data may reopen — a typed view would sit ABOVE the
  judgment, no foreclosure); no human annotation front-end; Core
  labels not source AST as the index; [F7] TOTAL correctness
  (fuel-bounded, termination-inclusive) where the donors' WP is
  partial — the load-bearing reason fuel algebra exists; rationale =
  our adequacy discharge to executable runs.
- **Naming/layout**: one-rule-per-construct files in the BRiCk
  stmt/expr style; community-predictable rule names; walk→segment
  rename rides the layer commit. BRiCk is IDEAS-ONLY (license);
  RefinedC (BSD) may be structurally mirrored with attribution.
- **Arc-19 pre-commitment**: goal-directed search design starts from
  Lithium's architecture; divergence only with written rationale.

## The ladder

- **R0 — interim merge** (in flight): pre-merge audit of C0–C4
  (standard scope, dispatched); on MERGE-SAFE, ff-only merge per
  [USER] sign-off ("land these first"); MAJOR findings stop and
  report. Long cycle then branches from mainline.
- **R1 — open-memory minting mode** (M; DERISK — unknown #1): the one
  missing engine capability (reads through the registered memRW lane
  instead of ground eval). Own iterable slice; clears T6's OwnP
  exemption as a side effect. A wall beyond price = stop-event.
- **R2 — the segment layer, full** (M): judgment (∃-round, [F1]) +
  invariant map + call SegPoints in the type from day one; the
  variable-round composition variant [F1]; FnSpec built [F9];
  segment rule proved once; faces (verify_fn / invariant /
  seg_auto); rename; correspondence table v1. [F3] The engine
  contract includes JOIN-POINT SPELLING NORMALIZATION: C3b's
  measured two-spelling loop-head seam (fall-in spelling vs stored
  continuation spelling — why five walks, not three) is discharged
  ENGINE-SIDE against the one declared invariant; twin-builder
  vocabulary never reaches the user; T5's twins are the acceptance
  case. Smoke: T6 AND one branch-in-loop program (the fixed-round
  breaker) [F1] — neither a stopping milestone. [F6] R2 close =
  mandatory no-wait interim report to operator, success included.
- **R3 — early purge** (S — deflated by [F2]): scope is defined by
  IMPORT SCAN, not by register category — only zero-importer
  register entries delete here, with gate/test re-registration in
  the same commit. The AppEq/AppWalk family is LIVE until R4/R5/R7
  (T1AppEq imported by T4Threaded + the ambient family; AppWalk by
  T1AppEq/T5Prefix/AppWalkTest; PerStepRunner by Audit.lean — the
  in-build gate) and retires at R7 as the register originally
  scheduled. Ambient family NOT here (waits on R5).
- **R4 — T5 through the layer + T1/T2/T3 re-housed** (M-L,
  repriced by [F4]: absorbs the C3b corrected map whose own pricing
  holds `wpk_seq_scratch2` at M — the named known-M sub-item — plus
  six S/S-M items; the enumeration has run optimistic twice):
  invariant at while_531 in footprint form; statements/cones
  byte-stable (proof-body refactor). MEASURES unknown #2, [F8] as a
  CLASSIFICATION not a binary: pack survivors sorted
  frame-internalized / pure-supply / other — supply arithmetic
  (symc bounds, apartness) is NOT frame content and is EXPECTED to
  survive as pure side conditions (the queued ghost-supply design
  question, not a layer failure); the stop-event triggers on
  unexplained "other" survivors, not on expected supply conjuncts.
  T5 statement gate row flips to gating. [F6] R4 close = mandatory
  no-wait interim report with the measurement, success included.
- **R5 — T4-apartness** (M): threaded T4 via the layer's builder leg
  (env-algebra content unchanged); unblocks ambient retirement.
- **R6 — breadth campaign** (M-L, batched ≤5, box-aware serial):
  - Corpus, three tiers: EASY (straight-line/branch; must be
    trivially green — measures the cost floor, ~0 manual lines);
    CENSUS (uri.c idiom census drives a ramp — string-scanning
    loops, char-class checks, pointer arithmetic, early returns,
    small helpers; grow past 20 programs until census coverage);
    EDGE (difficulty-biased: nested loops, loop-carried pointer
    arithmetic, break/continue/early-return, helper-in-loop, aliasing
    /disjointness frame stress, interleaved writes, arithmetic
    invariants). Edge failures are DESIGN FINDINGS, not proofs to
    grind. [F9] The uri.c idiom census is COMMITTED AS AN ARTIFACT
    BEFORE corpus construction — R9's "trivial by construction"
    claim is checked against the pre-registered list, never graded
    end-of-arc by the same hands that built the corpus.
  - [F5] PER-PROGRAM BUDGET (the anti-grind tripwire the campaign
    otherwise lacks): manual proof lines = spec + invariants + ε;
    an over-budget program is PARKED as a design finding, never
    ground past; TWO CONSECUTIVE over-budget programs HALT the
    campaign for a layer-gap investigation (proof-grind species 3
    is the failure mode this guards — 30 workaround-proofs around a
    layer gap before the professor sample is ever drawn).
  - PENDING-[USER] hooks (proposed 2026-08-26, awaiting nod):
    SAFETY-ONLY LANE (same programs, trivial postcondition —
    UB-freedom cost measured for free; the containment product
    tier) and SIZE LADDER (a few deliberately oversized straight-
    line/wide-context programs whose only purpose is to measure
    where the iris-lean substrate bends, before the capstone).
  - Mixed sources: majority fresh minimal C; minority clean-room from
    deps/cn/tests/cn shapes (Yolo rule respected).
  - Call-rule worked examples land here (two-function programs,
    standard contract rule).
  - R1/R5 family-∀ targets attempted where the layer reaches them
    (non-blocking, park-with-price).
  - Professor pass on a 5-program sample + T5 (proof-style standard);
    report to operator at arc end. Failure = stop-event.
- **R7 — C5 remainder** (S): ambient family retirement (post-R5);
  SUBSUMED walk artifacts deleted after equation supply re-homed
  engine-side; freeze allowlist empties.
- **R8 — C6 playbook** (S-M): teaches segment style only. Acceptance
  = HARD BAR: fresh agent, playbook only, no arc context, writes
  spec + invariant for a never-seen program, reaches green without
  engine vocabulary.
- **R9 — capstone (stretch, non-blocking)**: one uri.c function
  through the layer. By R6's census design this should be near
  trivial; a park here is a priced finding for arc-19, not a
  failure.

## Stop-events (the only interrupts; all else runs through)

1. R4's pack measurement shows unexplained "other" survivors ([F8]
   classification; expected pure-supply conjuncts do NOT trigger).
2. R1 blows its price.
3. Anything touching the statement layer or declared boundary list.
4. Professor-pass failure on the sample.
5. [F5] Breadth campaign halt: two consecutive over-budget programs.
6. Standing doctrine: park-ends-slice, grind tripwire (~1hr), OOM
   discipline (48G, serial, prompt commits), no push without
   per-push authorization. Final merge gets its own unconditional
   audit ask regardless of R0's.

SUCCESS-PATH CHECKPOINTS [F6] (reports, not stops — the cycle never
runs silently end-to-end): mandatory no-wait interim reports to the
operator at R2 close and R4 close, success included.

## Acceptance (arc close)

- T1–T6 all proved through the segment layer; statements/cones
  byte-stable to pre-arc texts; trio cones.
- The correspondence table complete and audited; every divergence
  from BRiCk/RefinedC carries rationale.
- Easy-tier cost floor ≈ 0 manual lines; census coverage of uri.c
  idioms; edge-tier findings dispositioned (fixed or priced).
- Professor pass on the sample; dumb-agent probe green at the hard
  bar.
- Purge complete (ambient family gone, walk artifacts gone,
  chase-freeze allowlist empty); gates re-registered.
- Pre-merge audit ask + per-merge sign-off, as ever.
