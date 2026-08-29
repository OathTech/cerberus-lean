# CN-on-Iris: prototype archaeology + design study

Investigation note, 2026-08-24 ([AGENT] fork, read-only pass; the
prototype repo was inspected via git show/ls-tree only — no checkouts,
bit-identical at exit). Operator brief: re-found CN as a reasoning/hint
language layered on Iris — CN annotations elaborate to Iris-level
artifacts with proof-obligation-shaped HOLES discharged by our
automation; prize = a proof frontend "for free" + the push toward a
real SL layer.

## Part 1 — what the prototype actually did

### Branch map (cerberus-lean-prototype; all refs LOCAL, nothing to download)

- **`origin/cn-types`** — THE CN line: 213 commits, 27 ahead of main's
  merged CN snapshot; tip `350621a` "WIP: uncommitted working-tree
  state at pre-wipe backup" (the pre-wipe state was captured — the
  record is complete). Second-to-tip: "Fix loop invariant SMT bug …
  (103/103)".
- **`origin/salvage/cn-types-deleted-remote-{1..21}`** — pre-rebase
  snapshots of a deleted remote branch; tips match cn-types commits by
  message (different hashes — rebase artifacts). No unique content
  expected; not exhaustively verified.
- **`origin/mdd/core-proof-system`** — a SEPARATE proto-proof-system
  attempt (ProofSystem/HasType + bridge lemmas + Examples incl.
  Loop.lean): typing-judgment-style, hand-rolled bridge to the
  interpreter. Superseded conceptually by arc-16's layers.
- **`origin/foundational-proofs`** ("Preserve foundational proof
  exploration work", atop "PipelineDemo + cn_discharge tactics") — the
  discharge-tactic exploration.
- Others (`memory-model`, `experiment/direct-math-proofs`,
  `miked/verification-capabilities-*`) — adjacent, not CN-central.

**Download request: NONE** — everything referenced resolves locally.
(Only gap would be work that never reached this clone.)

### What was built (evidence)

A **faithful re-implementation of CN's typechecker in Lean**: 14,274
lines under `lean/CerbLean/CN/` at the cn-types tip — Parser (958
lines), Types (Term/Resource/Constraint/ArgumentTypes), TypeChecking
(Spine, Inference, Resolve, Simplify, Monad, Action, Pexpr — CN's
spine-typing/resource-inference engine mirrored file-by-file against
`cn/lib/*.ml` with per-audit citations), inline SMT via cvc5
(SmtLib.lean, 1,634 lines), a semantic model (Semantics/Heap,
Interpretation), and Verification/Obligation. Run to **107/107 tests**
including loop invariants, with a mirror-CN discipline (17
DIVERGES-FROM-CN markers, waves of audit reports:
docs/2026-02-26_CN_AUDIT_REPORT.md etc.).

The **obligation architecture the operator remembers** is real and
good: docs/2026-01-21_CN_PROOF_OBLIGATIONS.md — VC generation separated
from discharge, obligations as independent Props with `toProp`,
post-hoc discharge by SMT/omega/manual ("holes"), foundational
soundness as goal 1.

### Where it bogged down (the key finding)

The checker WORKED; the **soundness layer was planned and never
built**. docs/2026-01-22_CN_SOUNDNESS_PROOF_PLAN.md lists what was
missing, verbatim: (1) a relational execution semantics, (2) a memory
correspondence (SL `HeapFragment` ↔ concrete `MemState`), (3) a
simulation relation between checker context and interpreter state,
(4) the once-proved soundness metatheorem. NONE of these exist in the
final tree (no Soundness.lean / MemCorrespondence.lean / Execution.lean
anywhere on the branch).

Why it exploded: the design deliberately avoided a syntactic SL
("Key Design Decision: No Separation Logic Syntax") and hand-rolled the
semantics instead — `interpResources` does explicit existential
disjoint-sub-heap splitting per resource, and the frame property is a
bespoke theorem (`frame_derived`). That is a miniature hand-rolled
Iris: no proofmode, no resource algebra, no ghost state, no adequacy
pipeline — so every soundness step (framing through execution,
correspondence, simulation) had to be built from scratch, and wasn't.
Secondary trust-model gap: the plan's per-program instantiation used
`native_decide` for "typeCheck = ok" — banned under mainline doctrine.

**The punchline: the four missing pieces are exactly what arc-16
builds for independent reasons.** (1) = S1's per-step language
instance (landed); (2) = S2's CerbMem heap RA / state interpretation
(running); (3)+(4) = the WP adequacy route (landed in shell form,
re-founded in S4). The complexity that killed the prototype is the
part we are already paying for.

## Part 2 — the design against today's stack

### (a) Doctrine fit — RECOMMENDATION: proof-layer authoring surface

CN specs are per-function modular SL contracts. Under the statement
doctrine those live in the PROOF LAYER, and the fit is exact: a CN
contract elaborates to a **function summary** (`∀ args, {pre} WP f(args)
{post}` in the S1 language over S2 resources); CN `inv` elaborates to
the loop invariant the S3/part-2 loop rules consume; CN predicates
become rep predicates. Headline statements STAY harness-shaped: the
harness's WP proof applies the CN-derived summary at f's call site and
discharges through the unchanged adequacy — end-to-end this works with
no statement-doctrine change, and the per-function CN theorem is
additionally the reusable compositional summary the stepper design
wanted. The alternative (CN specs as statement-level SL through the
governed escape hatch) prices in CN elaboration + the Iris assertion
semantics as statement-trust — and CN specs are not runnable, so the
whole differential/fuzz/plant instrument set goes dark for them.
Reserve it for per-instance operator decisions later, if ever.

### (b) Pipeline — RECOMMENDATION: OCaml-side spec-AST export

Two options. (i) Reuse CN's own frontend (deps/cn, BSD-2): have the
OCaml side parse+elaborate CN magic comments and emit a typed spec AST
as JSON alongside cabs-json (the exact Cabs-JSON precedent — parser
stays a thin OCaml boundary; our cerberus parser already lexes magic
comments behind the existing switch, verified in the arc-15 S0 probe).
(ii) Parse magic comments Lean-side — the prototype's 958-line
Parser.lean proves feasibility, but it is a permanent grammar fork of
a moving language. Choose (i): grammar fidelity and upstream tracking
for free; licensing clean.

### (c) Semantic mapping (CN vocabulary → our Iris layer)

| CN | Ours |
|---|---|
| `take x = Owned<τ>(p)` | typed points-to over the S2 heap RA (`p ◁ τ` view above byte `↦`); take-binding = existential in the pre (RefinedC's `◁ₗ` analogue) |
| CN predicates (`IntList`, user predicates) | rep predicates: Iris predicates recursing on a PURE MODEL — the spec-lab models (ListAppend, CnSeed…) already are these models; direct convergence |
| `requires`/`ensures` | pre/post of the per-function summary (proof layer) |
| loop `inv` | the S3/part-2 logical loop invariant (löb / total-WP; `iter_compose` where functional) |
| `cn_function` | pure Lean defs (the arc-15 R5 `lookup_size_shift_cn` precedent — already done once) |
| ghost statements (`extract`/`focus`/`unfold`) | proofmode hints: lemma applications / view shifts at marked program points (Lithium-hint analogue) |
| pure constraints | side conditions → kernel `decide`/omega reflection solvers; SMT at most as a HINT-FINDER (never trusted — no native_decide, per doctrine) |
| **holes** | residual Iris entailments the automation cannot close, surfaced as named goals — the prototype's independent-`Obligation.toProp` shape, landing in IPM context |

**The inversion that avoids the prototype's fate**: do NOT re-port CN's
checker. CN specs *elaborate to Iris assertions*; the CHECKING is our
WP automation. No spine-inference port, no simulation-relation debt, no
mirror-CN maintenance surface — soundness is definitional because the
elaboration IS the semantics we prove against.

### (d) What's missing / staged plan

Prereqs from arc-16: S2 heap RA (running), S3 primitive laws +
wp-tactics. Then:

- **CN-0 (S; can start any time, disjoint surfaces):** spec-AST export
  from deps/cn OCaml + Lean importer + round-trip pretty-print;
  corpus = deps/cn/tests/cn (213 files, already in the cn_coverage
  lane).
- **CN-1 (M; after S2):** the typed-view layer over byte points-to
  (`◁` for scalars/structs/arrays) — S4/spec-lab want this anyway;
  Caesium is the donor.
- **CN-2 (M; after S3):** CN assertion → iProp elaboration + the
  summary statement form + fold/unfold lemmas per predicate.
- **CN-3 (M–L):** automation over it — S3 wp-tactics + brick-wp-shaped
  packaged steps + Lithium-lite goal-directed search consuming
  elaborated pre/posts; holes = surfaced leftover goals.
- **CN-4 (S–M):** payoff validation on the arc-15 comparison
  datapoints + one corpus function end-to-end (buddy-allocator
  on-ramp: the pKVM case study's CN specs are the eventual target).

Earliest sensible start: CN-0 now (parallel stream, no contention);
the rest is a natural arc-17/part-2 companion — it is largely the
SAME work as part-2's typed views + automation, with CN as the surface
syntax.

### (e) Payoff check (the five arc-15 comparison datapoints)

- division/mod (`requires y != 0`; the implicit INT_MIN corner):
  pre → side conditions → `decide`. **Goes through with no work**; the
  INT_MIN gap surfaces as an undischargeable hole — the finding
  becomes a hole, which is the system working.
- swap_pair / memcpy (Owned arrays, element-wise ensures): typed
  points-to + wp_store steps + iFrame + `decide`. **No work** once
  CN-1/S3 exist.
- get_from_arr (ownership-only ensures): trivially discharged;
  our stronger spec remains available as a manual strengthening.
- append (recursive `IntList`, `L3 == append(L1,L2)`): needs the rep
  predicate + fold/unfold hints — CN itself needs the same unfold
  ghosts there, so **parity with CN, not free**; the pure model +
  lemmas already exist in spec-lab.
- lookup_size_shift (`cn_function`): pure mirror + `decide`. **No
  work.**

Net: scalars/arrays genuinely "for free"; recursive structures at
CN-parity (hint-driven) — honest, and matches CN's own UX.

## Risk paragraph (trick filter + lineage, applied to ourselves)

Lineage: **RefinedC's annotation pipeline** (annotations → Iris-level
judgments → Lithium automation) — canonical and worked; we deviate in
(1) surface language (CN, justified: designed-for-C UX, an existing
213-file corpus, the pKVM buddy case study is CN-annotated — our
kernel-target on-ramp speaks CN) and (2) foundation (our fuel opsem
via the unchanged adequacy, vs Caesium). Abstraction sentence: *CN's
resource vocabulary already IS separation logic — elaborating it into
a real SL buys checking from the logic's own machinery, and every
further annotated function reuses the same elaboration + automation.*
Where this could become the next chase, and the guards: (a) re-porting
CN's checker/spine-inference (the prototype's 14K-line path) —
grinding + duplication; the elaborate-don't-check inversion is the
design's load-bearing choice and any drift back is a finding; (b)
SMT-shaped discharge acquiring trust (the prototype planned
`native_decide`) — banned; SMT only as hint-finder; (c) chasing CN
checker-semantics fidelity (DIVERGES-FROM-CN culture) — we bind to CN's
surface MEANING, not its checker; our elaboration is normative for us,
divergences documented at the spec-meaning level only. Timing guard:
nothing here starts before its arc-16 prerequisite exists (CN-0
excepted) — the prototype's lesson is precisely that this frontend
without the Iris substrate is quicksand.

## Which CN pieces we use ([USER 2026-08-24] disposition)

CN decomposes into (1) the C spec language, (2) the recursive-predicate
definition language, (3) the Rocq breakout. Ruling:

1. **Spec language: ADOPT wholesale** as the hint surface (fits
   "extremely well"). Design choice: keep accepted annotations a
   syntactic SUBSET of stock CN where possible (files stay parseable
   by the upstream tool — corpus/differential story, upstream
   relations preserved).
2. **Definition language: DO NOT ADOPT — replace its role**
   ([USER]: "a bit wonky and under-designed"). RefinedC precedent:
   thin annotations, heavy definitions in the prover. CN annotations
   reference predicates BY NAME; canonical definitions live
   Lean-side (the spec-lab pure models + rep predicates already are
   this). Optional CN-side mirrors for dual-tool compatibility;
   Lean is the source of truth, CN's definition semantics never
   inherited.
3. **Rocq breakout: SUBSUMED, not adopted** — we are in the prover;
   holes surface natively as IPM goals. Mine the pKVM case study's
   coq_lemmas (deps/) at CN-3 design time as empirical data on what
   obligations escape automation at kernel scale.

Trust story of the cut: annotations = hints (zero TCB); definitions
= Lean (kernel); holes = goals (kernel). No CN tooling in the
trusted path. CN-0 unaffected (exports all three syntax-faithfully;
this disposition governs what CN-2 consumes).

## Fulminate ([USER 2026-08-24]: the runtime-check relationship)

Fulminate is VENDORED already (deps/cn: doc/README-FULMINATE.md,
bin/instrument.ml, runtime/libcn = its executable-checks runtime).
It compiles CN's ownership model into runtime checks — the CN team's
EXECUTABLE INTERPRETATION of the spec idioms. Relationship to us:

1. **Oracle for SPEC semantics** (complementing cerberus-OCaml as the
   oracle for program semantics): instrumented programs are just C —
   run them through our pipeline + the oracle, and differentially
   compare Fulminate's runtime verdicts against what CN-2's Iris
   elaboration claims the specs mean. Divergence = interpretation bug,
   caught before proof effort. Candidate lane at CN-2/CN-4 time.
2. **Design donor for CN-2's elaborator**: the translation is an
   operational spec of idiom meaning; its runtime ownership table is
   the dynamic shadow of the S2 heap RA.
3. **Plant synergy**: broken target ⇒ Fulminate check fires + theorem
   unprovable + differential red — triple anti-vacuity witnesses.
4. **Boring-specs alignment**: Fulminate's checkable fragment ≈ the
   executable/boring spec class ≈ where our escape hatch is NOT
   needed; the shared boundary is design data.

Fits harnesses-are-programs: both approaches make specs executable C;
harnesses wrap from outside (closed program, observation channels),
Fulminate instruments from inside (injected ownership bookkeeping).
Complementary, not competing.

## The PBT engines (Bennet / Darcy / Lucas — all vendored in deps/cn)

`cn test` ships three input-generation engines (bin/test/{bennet,
darcy,lucas}.ml + lib/testGeneration/): Bennet = randomized
generation from CN preconditions (constraint backtracking, size
splits — the generators-as-parsers lineage); Darcy = symbolic/SMT
input generation from the same specs; Lucas = randomized refinement
over abstract domains generalizing Bennet. Also
lib/testGeneration/specExport.ml — CN's own spec-export surface
(CN-0 design input, relayed to the worker).

Uses for us (banked, not scheduled):
1. **Spec-guided fuzz for the harness lanes**: our stream fuzzing is
   uniform-random; Bennet/Darcy generate precondition-SATISFYING
   inputs — better coverage of guarded domains for the model-∀
   families. SMT here is trust-clean (input SEARCH, not proof).
2. **CN-4 triangulation widens**: generated inputs run under
   Fulminate checks + our harnesses + our proofs' claims.
3. **The big one (future)**: Bennet compiles GENERATORS from CN
   specs — the same compilation targeting C builder code instead of
   OCaml generators would AUTO-DERIVE our harness builders from CN
   annotations (automating what arc-15 hand-wrote per structure).
   Candidate for the CN ladder's later stages; trick-filter clean
   (abstraction: spec-to-generator compilation, per-spec for free).
