# Research brief: Iris-line proof rules & automation — what the workbench should import

For the external research agent (2026-08-21). Deliverable: a survey doc
dropped in `cerberus-lean/lean_frontend/docs/` (dated filename), papers
themselves in a gitignored subfolder alongside (the weak-memory-survey
precedent). Iterate to v2 on operator feedback as before.

## Context (what you're advising)

cerberus-lean proves ∀-quantified, interpreter-only theorems about
compiled C programs: a fuel-based operational semantics (generated from
the Cerberus Lem model) is the TCB; iris-lean (the Lean 4 Iris port,
pinned at upstream head) is PROOF MACHINERY coupled via a relational
layer; an in-repo adequacy theorem discharges Iris out of every final
statement. Current state: T1–T4 (straight-line/struct programs) proved;
T5 (first loop) in flight on a purpose-built "workbench": a lemma-kit
layer (computed-RHS "round" lemmas over interpreter steps), a
law-table-driven walker tactic (DiscrTree-indexed, goal-guarded,
kernel-whnf-backed discovery), a pure loop-composition rule
(`iter_compose`, invariant = closed-form state family), and a per-stage
kernel-certificate emitter (decomposing round proofs into many small
kernel obligations to stay under kernel recursion limits).

Design doctrine you must respect in recommendations: statements/TCB are
pristine (no statement-side cleverness, no axiomatized rules, no
compiler-trusted evaluation like native_decide — everything lands as
ordinary kernel-checked obligations); the proof MACHINERY may be
aggressively engineered ("clever tricks that make the proof scale for
kernel-certified steps"). Measured baseline for actionability: the
pre-workbench cost was 5,966 hand proof lines for four loop-free
theorems; the workbench's calibration re-proved a 700-line segment in
5 tactic lines. THE BAR FOR EVERY RECOMMENDATION: "would this have
shortened T5, or will it shorten the next slate (nested loops, arrays,
early exit, call composition, then real libxml2/allocator code)?"

## Core reading list (then sweep beyond it)

1. **RefinedC + Lithium** (Sammler et al., PLDI 2021; repo is being
   vendored at deps/refinedc) — PRIORITY. We care less about the
   refinement-type front-end than about Lithium's automation
   architecture: deterministic, backtracking-free goal decomposition;
   typing-rules-as-automation-friendly-lemmas; how it decides
   rule applicability; its performance discipline. Compare point-by-
   point against our walker design (law table + goal-guarded dispatch
   + laws-only/semantic-obligation split) and say what we're missing.
   Also: Caesium (their C semantics) as a statement-shape contrast.
2. **Islaris** (ISA verification over authoritative Isla traces) — the
   closest architectural relative (Iris over an authoritative
   executable semantics, adequacy discharging Iris). Their rule set
   and automation for walking authoritative steps; what transfers.
3. **Simuliris** — simulation reasoning in Iris; relevant to our
   queued executable-vs-axiomatic concurrency-model equivalence.
4. **Melocoton / DimSum** — multi-language & component composition;
   relevant to call composition and multi-TU linking theorems.
5. **The Iris core line's recent additions** — later credits,
   transfinite Iris, any recent WP-infrastructure papers; verdict per
   item on whether our fuel discipline subsumes it or we should want
   it (iris-lean may not port all of it — flag gaps worth upstreaming
   or reimplementing).
6. **Sweep**: last ~3 years of Iris-adjacent work at POPL/PLDI/ICFP/
   OOPSLA/CAV/ITP (incl. RustBelt-lineage automation, VST-vs-Iris
   automation comparisons, CN's separation-logic automation since
   it's Cerberus-native, BRiCk/brick-wp's published material if any —
   we already mined the brick-wp repo's tactic taxonomy, so cite
   deltas only).

## Questions per paper (the deliverable's table)

- Which PROOF RULES does it contribute that our layer lacks (loop/
  invariant forms, call/frame/composition rules, ghost-state
  patterns)? Stated how (automation-friendly shape)?
- What AUTOMATION ARCHITECTURE does it use (goal decomposition
  strategy, rule indexing, backtracking policy, certificate size
  management, kernel-vs-elaborator budget choices)? What would we
  import into the walker/emitter, concretely?
- Any STATEMENT-SHAPE lessons (how they keep the trusted statement
  clean while automating the proof)?
- PORTABILITY: Rocq-idiom dependence? Needs iris-lean features that
  exist / are missing at our pin (head 34390a0133)?
- One-line verdict: IMPORT-DESIGN / IMPORT-RULE / IRRELEVANT-TO-US /
  ALREADY-HAVE (with what we have it as).

## Deliverable

Survey doc as above: per-paper table + a synthesized "workbench v2
import slate" (ranked, priced S/M/L, each item tied to the
would-it-shorten-T5 bar), + a gaps-in-iris-lean list (candidate
upstream contributions). Mark clearly which claims come from reading
code vs papers vs abstracts.
