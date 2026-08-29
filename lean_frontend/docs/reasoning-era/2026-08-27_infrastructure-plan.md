# The infrastructure plan — proving the frozen target corpus

STATUS: FOR OPERATOR DISCUSSION (restart plan step 5). Not a charter;
nothing here executes before the operator blesses it. Prices are
estimates for discussion, calibrated against this project's measured
history (M slices have run optimistic twice; L is where estimates go
to die — treated accordingly in §3's checkpoint design).

Planned against, in order of authority:
1. The design catechism (BLESSED, normative):
   docs/2026-08-27_design-catechism.md — the layer stack, the
   canonical property, the forbidden/valuable lists, the escalation
   ladder, anti-gate-grind.
2. THE FROZEN CORPUS (docs/2026-08-27_target-corpus.md + corpus/):
   the fifteen theorems ARE the acceptance criteria; §4's per-row
   binding-gap table is this plan's requirements list; the review's
   freeze clause (d) binds acceptance to marginal-cost/legibility —
   a grind pass cannot count.
3. The whole-project assessment (conversion table + B0–B6, both
   UNRATIFIED inputs — adjudicated into this plan in §4, with deltas
   stated).
4. The kill-list execution record — the actual post-purge state this
   plan builds FROM (the assessment's B6 is largely already executed;
   what remains of it is the killed-by-registration deferral set,
   scheduled here as per-slice retirement riders).

---

## 0. Executive summary

The corpus needs exactly the "missing middle" the assessment named,
organized as eight components (§1) built in seven slices (§3). The
two load-bearing L-slices come first — the assertion layer (V1) and
the case-splitting per-construct rules (V2) — because every corpus
row is blocked on at least one of them and four rows are blocked on
nothing else. The first theorem to fall is P01 (clamp ∀x): the
emblem program, deliberately scheduled as the plan's first
high-information checkpoint — the first data-dependent branch ever
crossed at a symbolic value in this project. The summit rows (P08
list_reverse, P13 cell_alloc) land last, on the full stack.

Price envelope (honest): 2×S–M + 4×M/M–L + 2×L ≈ the proof-layer
effort of arcs 16–18 combined. The envelope is dominated by V1+V2;
everything after them is M-grade construction on a load-bearing
foundation. Checkpoints are designed so the operator sees the two
riskiest results (V1's adequacy re-proof; V2's P01) as mandatory
reports, success included, before the M-grade tail spends anything.

Trust story: unchanged in every particular (§5). Statements at layer
1, cones exactly the trio, kernel-certified throughout; ONE gate
extension (the concrete-input ban, riding the existing statement-TCB
gate — the single gate the forbidden class earned, per
anti-gate-grind); `are_compatible` totalized in the model, the
operator's "total in the proper way".

---

## 1. Component architecture (the missing middle, on the blessed stack)

The stack (catechism §I): executable semantics ⇧ relational ⇧ Iris ⇩
target. Everything below lives in the Iris layer except A (statement
layer, anchored at layer 1) and E's totalization (layer-1 model
work). Per component: donor lineage · what existing KEEP/CONVERT
machinery it reuses · price · corpus rows it unblocks.

**A. The corpus statement layer + the ban gate (S–M).**
Oracle-pinned fixtures for P01–P15 (tests/verify pattern; the .c
files are frozen — pin `.core` dumps, expectations rows on the TEST
ledger), the fifteen canonical-property statements in Lean (house
guarded threaded shape; wf predicates with the §0 type-derived
bounds; mkHarness splices for the memory-input rows), registered
honest-UNPROVED with kernel-checked 2-witness anti-vacuity per
program (freeze obligation §6c; P07/P08's witnesses carry two
DISTINCT permutations). Plus the concrete-input ban: the
quantified-input obligation (reject any registered
CallHarnessAdequateThr application with closed args and no
quantified initial-memory binder), the constant-FnSpec check, and
the finite-sample ban — implemented as an EXTENSION of the existing
in-build statement-TCB gate (same walker, new axis, negative-probed),
not a new gate script. Anti-gate-grind compliant: this is the one
gate the forbidden class earned; the purge already emptied the
would-be waiver list, so it lands clean.
Lineage: the C4 honest-unproved-target pattern; the gate design =
assessment §2.6. Reuses: statement gate walker, mkHarness, codecs.
Unblocks: nothing provable — it defines every target and makes the
forbidden class build-fatal from day one.

**B. The assertion layer (L — the load-bearing refactor).**
Decompose `restIs` (today: one ghost pin of the whole non-heap
machine at a concrete state — the single design flaw that makes
locals unframeable and values concrete): (i) a control token
(program-point = Core label/continuation position), (ii) env
points-to — a second ghost_map, `x ↦env v` with SYMBOLIC v, (iii)
supplies as ghost counters. Rebuild the four memory-op WP rules and
the adequacy discharge over the decomposed interpretation. The
two-faces rule (S2 doctrine) is the design constraint: the
interpretation stays a concrete authoritative map INSIDE adequacy
plumbing; proof-level assertions abstract over it — the
decomposition must not leak concreteness back into proofs, and must
not break the adequacy seam. Exit ramp (assessment's, preserved):
env-as-one-ghost-var over a symbolic value map — a halfway house
that still unblocks V2.
Lineage: RefinedC locals-as-locations (`l ◁ₗ ty`), HeapLang
gen_heap, Caesium heapG. Reuses: CerbHeapRA (unchanged), the
adequacy spine (C-9), the per-step language instance.
Unblocks: prerequisite for every row; with C, rows P01–P03.

**C. Per-construct symbolic rules + the case-splitting stepper (L —
the heart).** Two halves, one slice:
(i) Rules: for the elaborated Core vocabulary (measured small —
spec-lab saturation; R6's zero-new-engine-laws-for-scalars), one
once-proved rule per construct at ∀-operands with pure side
conditions: PEop/PElet/PEctor…, **PEif/PEcase case-split** (subgoal
per branch under a path-condition hypothesis — the absent rule, the
assessment's sharpest edge), memory ops through the rebuilt op
rules, save/run join rules, seq/wseq. Divergence from BRiCk noted
with rationale: theirs are axioms per AST node; ours are THEOREMS
against the generated semantics — more work, strictly stronger.
(ii) Engine: the RoundEval chassis (fail-closed proof-producing
emission, registry dispatch, kernelVerdict leaves — ACL2Lean
lineage, all KEEP) re-targeted from whole-run concrete-anchor
minting to goal-directed per-construct stepping that EMITS SUBGOALS
at irreducible discriminants instead of stopping. The whole-run
mint mode dies when its last KEEP consumer re-proves (rider, §3).
Escalation ladder (operator ruling): every rule is a named theorem,
hand-applicable; thin working-tactic faces per construct; auto on
top.
Lineage: BRiCk wp.v per-node rules; RefinedC Typed* instances;
symbolic execution canon (path conditions). Reuses: LawRegistry +
attribute machinery (C-6, keep), Kit/Mem block laws (C-7), the
R4-measured keyed-DiscrTree dispatch + per-probe budget isolation.
Unblocks: P01, P02 (with B); P03's alias case structure; the branch
halves of P05/P13/P15.

**D. Predicate invariants + the variant rule (M–L).** Invariants as
ASSERTIONS at loop labels with a load-bearing map (fix the dead
`_hfind`; RefinedC's `Q !! b` is the mirror), discharged through the
KEEP Seg composition algebra (C-1 — internal, beneath the
assertion-level judgment); entry/preserve/exit obligations derived
from the map. THE VARIANT RULE: well-founded measure ⇒ ∃-trip-count
(deriving `Seg.while_inv`'s n from a decreasing measure — Dijkstra
bound functions / total-correctness Hoare while; the documented gap
P11 forces). Retirement riders: `iter_compose` (conversion C-14) and
the T5 engine rooms die at T5's re-proof here.
Lineage: Floyd/Hoare/Dijkstra; RefinedC split_blocks; BRiCk
wp_while_inv. Reuses: Seg algebra, T5's triF as the worked example.
Unblocks: P11; T5 re-proof; with F: P04–P06, P14, P15.

**E. Calls: totalization + contract consumption + recursion (M + M).**
(i) Totalize `AilTypesAux.are_compatible` IN THE MODEL — lem-side
fuel totalization (recommended over a target_rep hand mirror: stays
in the generated semantics, no hand-written seam growth, OCaml
target untouched — the operator's "total in the proper way";
no-internal-trust-gaps standard move; prelude regen + lem-sync gate
re-derivation). Independent of B/C/D — can run EARLY in parallel
(semantics-side, different surface).
(ii) FnSpec consumption at symbolic args (Summary.consume exists,
zero instances — first worked instances land here), callee specs
persistent (RefinedC function_ptr precedent); recursion as
contract-with-measure (the callee's own FnSpec as induction
hypothesis at the decreasing measure — P10; well-founded induction
over D's measure machinery; BRiCk's Löb is the partial-correctness
analogue, ours is the total form).
Unblocks: P09, P10.

**F. Memory views: arrays, structs, and the array-lane engine gap
(M–L).** Element points-to over arrays with carve-out/recombine (the
salvaged `within` law's family — RefinedC array.v, Caesium
heap_mapsto_app); struct field views (P12, T4's re-proof); symbolic
index reasoning (i-th element under `i < n` path conditions); and
closing the R6b-parked engine wall (PEarray_shift evaluation at
symbolic anchors — the reproducer's round-35 wall, now solved as a
per-construct rule in C's style rather than a mint patch).
Unblocks: P04, P05, P06, P12, P14, P15 (with D); T4 re-proof.

**G. Heap structures + ownership (M–L + the operator-gated design
decision).** Rep predicates as recursive assertion definitions with
fold/unfold laws (`IntList p l` — Reynolds/O'Hearn; RefinedC's
type-based lists are the machine-checked precedent) over the
π-quantified skeletons; malloc/free ownership birth/death (GenHeap
alloc is in the RA already), the leak conjunct (speclab's
HarnessFinalAllocs vocabulary, KEEP); and THE ALLOC-ND DESIGN
EVALUATION (chartered, operator-gated, Caesium as reference) which
resolves P13's design-dependent failure clause (◐ → live or
withdrawn) — scheduled as V5's opening operator conversation.
Unblocks: P07, P08, P13 — the summit.

**H. The automation layer (M–L, continuous).** Goal-directed rule
application over the registry (Lithium lineage; the arc-19
pre-commitment honored — the design starts from Lithium's
architecture), branch-split management, leaf discharge
(omega/decide/kernelVerdict), fail-closed frontiers with
machine-readable traces; verify_fn/seg_auto face names kept,
re-targeted. Built INCREMENTALLY alongside C–G (each slice's rows
must discharge at clause-(d) cost, so automation grows with the
rules, not after them). Escalation ladder open at every level.
Unblocks: nothing alone; it is what makes every row's proof cost
"spec + invariants + automation run".

Cross-cutting (not a component, a standing wart with a chartered
remover): every corpus statement carries the guarded-seed shape
(every C assignment draws a fresh symbol — R6's finding); the
freshness redesign (modeled supply / ND+filter, chartered) is NOT in
this plan's scope; §7 Q3 asks the operator to confirm tolerance
until after the corpus.

---

## 2. Corpus row × component dependency (the requirements matrix)

| Row | Needs | First provable after |
|---|---|---|
| P01 clamp | B + C | **V2 — the first checkpoint theorem** |
| P02 sat_add | B + C (+arith leaves) | V2 |
| P03 swap both-arms | B + C (two-cell views exist) | V2 |
| P12 pt_midpoint | B + C + F(structs) | V3b |
| P11 gcd_iter | B + C + D(variant) | V3a |
| T5 re-proof (KEEP anchor) | B + C + D | V3a (retires T5 rooms) |
| P04/P06 arr loops | B + C + D + F | V3b |
| P05 find_first | B + C + D + F (contents-dependent count) | V3b |
| P14 count_pairs | B + C + D + F (nested) | V3b |
| P15 scan_classify | B + C + D + F (+switch = PEcase) | V3b |
| T4 re-proof (KEEP anchor) | B + C + F(struct member) | V3b (retires T4Walks; mint mode dies — last consumer) |
| P09 call_contract | B + C + E | V4 |
| P10 gcd_rec | B + C + D(measure) + E | V4 |
| P07 list_sum | B + C + D + F + G(rep) | V5 |
| P08 list_reverse | above + G in full | V5 |
| P13 cell_alloc | B + C + G(ownership + design decision) | V5 |

---

## 3. The slice sequence

Every slice: commits on green Tier A; parks with prices; the
catechism binds every worker (its STOP rule in every brief);
retirement riders execute the killed-by-registration triggers.

**V0 — statements, targets, and the ban (S–M).** Component A in
full. Rider: a totalization CENSUS of the Core-eval path (grep +
classify every `partial def` reachable from Core_eval — cheap
reconnaissance; are_compatible is the known one, the census bounds
the surprise budget for V2/V4). Also pre-register the clause-(d)
acceptance instrument: the per-row table (manual lines / invariant
count / automation-frontier count / professor-readable) that every
later slice fills in — the measurement exists before any proof does.
EXIT: 15 statements registered honest-UNPROVED + anti-vacuity
witnesses; ban gate live + negative-probed; fixtures oracle-pinned;
census published. No proofs claimed.

**V1 — the assertion layer (L).** Component B. EXIT (measured, not
vibes): adequacy re-proved over the decomposed interpretation;
the four op rules rebuilt; a nontrivial FRAMING demonstration at
symbolic env values (a two-variable program where one local is
framed across an update of the other — the thing `restIs` cannot
express today); T1–T3 statements still green via their old proofs
(untouched — their re-proof waits for V2's rules). MANDATORY
OPERATOR REPORT at close, success included: this is risk #2's
moment. Park rule: if the decomposition stalls against adequacy,
the exit ramp (env-as-one-ghost-var) is taken EXPLICITLY with the
delta priced, not silently.

**V2 — case-split + the first rules (L — the heart).** Component C;
H starts. EXIT = CORPUS ROWS: **P01 PROVED** (the first symbolic
branch — the plan's defining checkpoint), P02, P03; T1–T3 re-proved
through the new route (retirement rider: T1–T3Walks + their seg*
supply die; first tranche of the killed-by-registration register
clears). Every proof at clause-(d) cost, recorded in the V0 table.
MANDATORY OPERATOR REPORT at P01, success included — with the proof
text verbatim (the professor exhibit of the new era).

**V3a — scalar loops + the variant rule (M).** Component D. EXIT:
P11 proved; T5 RE-PROVED through predicate invariants (the
load-bearing map replacing the walk spine — retirement rider: T5
engine rooms ~3,300 lines + iter_compose die, conversion C-14
executed). T5's statement byte-stable throughout (gate-enforced).

**V3b — memory views (M–L).** Component F. EXIT: P04, P05, P06,
P12, P14, P15 proved; T4 re-proved (riders: T4Walks dies; THE
WHOLE-RUN MINT MODE dies — its last KEEP consumer is gone; the
killed-by-registration register EMPTIES except runEffectful's
lem-side item). At this point 9/15 corpus rows + all five KEEP
anchors ride the new stack exclusively.

**V4 — calls + recursion (M; totalization M runs early/parallel).**
Component E. The totalization lands semantics-side (lem-sync +
fork-drift gates re-derive; zero-movement differential required —
the model's OCaml-parity face is untouched by a Lean-target-only
fuel form; if the lem change is target-neutral it must be proven
zero-movement on the oracle ledger). EXIT: P09, P10 proved.

**V5 — heap structures + ownership (L-ish: M–L + the design
conversation).** Component G. OPENS with the operator-gated
alloc-ND design evaluation (Caesium reference; resolves P13's ◐).
EXIT: P07, P08, P13 proved — 15/15. The corpus is passed exactly
when this slice closes at clause-(d) costs.

**V6 — close-out (S–M).** The independent professor pass over the
fifteen proof texts (clause-(d) verification — a grind pass cannot
count, so the pass is the acceptance instrument); docs truth pass
(PROOF.md states the fifteen, per-theorem quantification explicit);
registers verified empty; the final audit ask + merge ask per
doctrine. Rider: the libxml2 rung is NOT in this plan (freeze
clause (f): passing 15/15 is necessary-not-sufficient; the
graduation test is the next plan's opening).

Sequencing notes: V1→V2 strictly serial (V2 needs B). E(i)
totalization may start any time after V0 (disjoint surface,
semantics-side; the two-repo pin dance rules apply if lem-side).
V3a/V3b may interleave batches after V2. H grows inside every slice.
The two L-slices carry the plan's risk; the checkpoint design puts
both of their verdicts in front of the operator before the M-tail
commits effort.

---

## 4. Adjudication of the assessment's inputs (deltas stated)

The conversion table: ADOPTED as written (C-1…C-15), with three
deltas. (1) C-14 (iter_compose) executes at V3a, not "after
re-point" in the abstract. (2) C-5's conversion is split across
V2 (stepper + case-split) and H (automation) rather than one
monolith. (3) C-11 (seed guards) is explicitly OUT of scope with an
operator question (§7 Q3) rather than an in-plan M.

The B-plan: B0→V0 (unchanged in intent; the contract half is now
the BLESSED catechism, so V0 is thinner than B0); B1→V1; B2→V2+F's
rule-style (the array lane joins the per-construct family rather
than being a separate vocabulary patch); B3→H (continuous, not a
slice — automation that arrives after the rules would let V2–V5
accrete manual proofs that violate clause (d)); B4→V4; B5→V3a/V3b/V5
(split by corpus tier; "corpus restated ∀-input" is superseded — the
FROZEN corpus is stronger than the B5 acceptance list and replaces
it); B6→ALREADY EXECUTED (the kill-list slice) except the
killed-by-registration riders, which this plan schedules at V2/V3a/
V3b. The assessment's "purge right after B0" recommendation was
overtaken by events — the operator ordered the purge first, and it
is done.

---

## 5. The trust story (unchanged — the catechism's §V/§VII applied)

- Statements: layer 1 only, fuel-opsem faces, byte-stable for the
  five KEEP anchors, canonical-property shape for the fifteen new
  targets. No statement mentions Iris, assertions, or the engine.
- Cones: exactly {propext, Classical.choice, Quot.sound} for every
  theorem, build-pinned. The purge already achieved carrier-zero;
  nothing in this plan may re-acquire a carrier (gate stands).
- Kernel-certified throughout: the stepper emits ordinary kernel
  terms (ACL2Lean contract); case-split subgoals are ordinary
  goals; no solver trust anywhere (the deliberate divergence from
  Lithium's trust model, carried in the correspondence table).
- Gates: ONE extension (concrete-input ban, riding the existing
  statement gate) — the single trust-property gate the mandate
  earned. No other new gates; discipline points ride the catechism
  and structurally-forcing design per anti-gate-grind.
- `are_compatible`: totalized in the model (fuel), zero-movement
  proven on the differential ledger, lem-sync/fork-drift gates
  re-derived — the no-internal-trust-gaps standard move, nothing
  hand-written grows.

## 6. Risks (ranked)

1. **Symbolic reduction through the generated interpreter** (V2's
   substance): kernel-opaque partial defs beyond are_compatible
   (V0's census bounds this), and the measured giant-term cliffs
   (write-tower depth, width caps) resurfacing as rule-proving
   obstacles. Mitigation: each is a named totalization or
   representation-indexing slice — better abstractions, never
   budgets (the ruling); the R6 reconnaissance already priced the
   known ones.
2. **The restIs decomposition vs adequacy** (V1): the two-faces
   seam is load-bearing; a leak of concreteness into proofs or a
   broken adequacy discharge stalls the whole stack. Mitigation:
   the explicit exit ramp; the mandatory V1 report; T1–T3 kept on
   their old proofs as regression anchors until V2.
3. **Address abstraction vs PNVI observability** (V3b/V5): block/
   offset points-to is semantically wrong for address-observing
   programs (measured: the pnvi sweep). The corpus avoids
   address-printing, but P07/P08's arena and P13's malloc touch the
   seam; the chartered alloc design evaluation (Caesium reference)
   governs — scheduled, not improvised.
4. **The three-loop const-embedding price** (V3b): every
   memory-input row crosses decode/compute/readback loops. The
   decode and readback loops are the SAME mkHarness template shape
   across all programs — their invariants are proved ONCE as
   harness-protocol lemmas (amortized; catechism §IV.1), or the
   slice drowns in triplicate loop proofs.
5. **L-slice estimate risk**: both L's front-loaded; checkpoints
   before the tail spends; parks are honest and priced.

## 7. Operator questions (with recommendations)

- **Q1 — Ratify the conversion table** as adjudicated here (§4
  deltas included)? The disposition record's §2 is TO-BE-RATIFIED;
  this plan consumes it.
- **Q2 — The alloc-ND design evaluation**: confirm scheduling as
  V5's opening conversation (recommended — nothing earlier needs
  it; P13's core clause is design-independent), vs pulling it
  earlier.
- **Q3 — Seed-guard tolerance**: every corpus statement carries the
  guarded-seed shape with 2^60-scale apartness numerals. Recommend:
  tolerate through V5 (the honest wart), sequence the chartered
  freshness redesign AFTER the corpus passes; the alternative
  (redesign first) front-loads an M–L before any corpus row falls.
- **Q4 — Checkpoint cadence**: mandatory reports at V1-close and
  P01 (recommended); per-slice close reports otherwise. More or
  fewer?
- **Q5 — Totalization route**: lem-side fuel (recommended: model-
  proper, no hand-written seam, OCaml target untouched) vs
  target_rep hand mirror. If lem-side: the two-repo pin dance
  applies; zero-movement differential required.
- **Q6 — V0 statement scope**: all fifteen statements registered up
  front (recommended: the targets and the ban exist from day one;
  the C4 honest-unproved pattern is house style) vs
  statements-per-slice.

## 8. What this plan does NOT do

No corpus edits (frozen; the hash gate enforces). No statement-layer
changes beyond ADDING the fifteen registered targets in the house
shape. No typed-view/refinement-type layer (reach-not-clone; breadth
data may reopen post-corpus). No CN import, no symbolic-file family
machinery (the call-boundary + splice routes cover the corpus), no
weak-memory work (quarantined per the pKVM spike), no libxml2 rung
(the NEXT plan's opening, per freeze clause (f)), no freshness
redesign (Q3), no speculative machinery of any kind: a component
that no corpus row forces does not get built — the corpus is the
scope fence.

## 9. Catechism §VI self-check (applied to this plan)

1. ∀-statements served: the fifteen frozen rows + five KEEP anchors
   — every slice's exit is named theorems. 2. Amortization: every
   component is proved-once machinery; the only per-program cost at
   V5's end is spec + invariants + automation (clause d). 3.
   Lineage: named per component (§1). 4. Professor test: the
   acceptance instrument (V0-pre-registered, V6-verified). 5. No
   enumeration/concrete residue: case-split subgoals are structural;
   the ban gate is live from V0; bounds are the corpus's
   anti-brute-force set. 6. Failure mode: parks with prices,
   stop-events at the two L-slices, the exit ramp explicit. 7.
   Trust surface: unchanged (§5); the one gate extension is the
   earned one.
