# Post-mortem: the chase era (2026-08-20 → 2026-08-24)

Written at the pivot to the Iris refounding (charter:
`2026-08-24_arc16-iris-refounding-charter.md`). This records what was
attempted, why it failed, what the failure taught, and what the
episode cost and bought. [USER]: "this has been pretty interesting as
an experiment" — this document is that experiment's lab notebook
conclusion.

## What was attempted

The proof route for theorems about compiled C programs was, from the
first theorems onward: obtain a **whole-execution equation** for the
pinned program (`app (callND …) init = (NDactive r, st')`), lift it
through an Iris adequacy shell as a single atomic step over
whole-state ownership, and discharge the statement. The equation
itself was produced by increasingly sophisticated machinery — the
"chase": a law table of proved rewrite equations, a walker
(`app_walk`) that discharged execution steps by kernel-normalization
with per-stage certificates, sealing (naming big intermediates),
trace/replay (~15× on re-runs), context-indexed fact queries, and
finally (on the parked branch `arc/t5-seal`) checkpointed seals
*inside* the kernel-normalization chase plus propositional-iota
equation lemmas to steer the kernel's unfolding.

## How it failed

Three layers, from proximate to root:

1. **Proximate (measured, arc/t5-seal record §3):** the kernel wall at
   the T5 loop-body walk's round 13 was never *depth* (real depth
   ~150, well within limits) but the kernel's **lazy-delta unfolding
   order**, which re-dives into the whole evaluation regardless of
   statement shape — falsifying the seal design's core assumption.
   Behind it: an unbounded ladder of monadic-eval "navigation shapes,"
   each unlocked at ~30 minutes, with no convergence argument.

2. **Structural (the whole-project audit's sharpest finding):** the
   Iris layer performed **no verification work**. Our Iris consumption
   was four import lines (Language + OwnP) out of a 281-module
   iris-lean that already contained the full proof mode, fractional
   points-to heaps, total-WP adequacy, and a complete worked language
   instantiation (HeapLang: syntax → semantics → primitive laws →
   wp-tactics → verified programs). The chase existed to compensate
   for the missing instantiation: with no per-step language structure
   and no resource-level state, every program needed a monolithic
   whole-run equation, and the walker was the machine for grinding
   those out. Cost per program: a full new walk — instance
   enumeration in mechanism costume.

3. **Root (process):** no canon-first check at charter time. The
   effort went into representation-level combat (steering a kernel
   heuristic we neither controlled nor modeled — we learned its
   behavior by collision, 18 instrumented iterations) instead of the
   field's tools for exactly this problem: language instances,
   separation/framing, invariants, symbolic execution over understood
   abstractions.

## What it cost

Arcs 9 and 11's engine investment plus the seal branch (~10 hours of
worker time at the end); ~700K of chase-era proof text and machinery
now scheduled for retirement (walker, trace/replay, round-walk idiom,
the four AppEq round-chain files, T5 walk scaffolding, instruments);
one falsified design note (superseded); T5 still unlanded after three
attempts on the walk route.

## What it bought

- **The falsification data**: precise measurements of kernel checking
  behavior (lazy-delta preference, refusal costs, the depth
  non-problem) that no design document would have predicted — and
  that justify the pivot beyond argument.
- **The law library** (the semantics' equational theory) and
  `iter_compose` — genuinely reusable; they feed the new
  architecture's primitive-law layer.
- **T1–T4 themselves**: the theorems are unconditional kernel facts
  with pinned cones; the pivot re-proves them cheaper but never
  un-proves them. All differential/spec-lab infrastructure was
  untouched by the failure.
- **Three doctrines**, now standing with enforcement: canon-first
  proof scaling (charters name each mechanism's lineage), the trick
  filter (a good trick states what abstraction it exploits and why
  the next example is free; grinding and blind representation-
  steering fail regardless of polish), and prune-don't-merge
  (invalidated work parks on a branch; mainline carries only what's
  in use).
- The clarified project identity [USER 2026-08-24]: **an Iris-based
  program verifier for C** — Iris first, with the lit review as the
  map.

## Disposition

`arc/t5-seal` remains a parked legacy branch, unmerged, holding the
seal engine, its measurements, and the promoted ladder — the
cautionary record. The mainline chase surfaces retire on the schedule
in the charter (strictly after T1–T4 are re-proved through the Iris
machinery; the purge is one commit with gate re-registrations). The
stepper design note (`2026-08-23_stepper-arc-design.md`) is
SUPERSEDED by the charter — its laws/residuals content survives; its
seals section carried the falsified assumption.

## The lesson in one line

We built an increasingly clever engine for producing the artifact
(whole-run equations) that a properly instantiated program logic
makes unnecessary — the experiment was worth running once, and only
once.
