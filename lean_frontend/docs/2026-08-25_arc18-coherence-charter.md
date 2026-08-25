# Arc 18 — the coherent reasoning layer (charter DRAFT)

STATUS: BLESSED [USER 2026-08-25]: "(2) agree on Q1-3. Go ahead with the next arc" — Q1 DELETE the dormant peels/wpk laws; Q2 FULL interpretation migration (exit ramp retained); Q3 ONE arc. Original DRAFT header follows.

STATUS-AT-DRAFT: DRAFT — awaiting operator blessing. Commission [USER
2026-08-25, verbatim]: "put together the charter for making the design
coherent. The aim is we have a well-designed reasoning layer, with a
coherent design philosophy and a playbook that future agents can use.
The end state should be (1) all current examples continue to pass,
(2) the design is clear and explainable, (3) we don't foreclose any
future buildout opportunities, and (4) we are in good shape for our
next push into more complex examples."

Inputs: the coherence review (notes/2026-08-25_reasoning-coherence-
review.md — its six seams and six priced moves are this charter's raw
material; its closing judgment "leave exactly one route, registry as
its public interface" is adopted as the spine), the arc-17 records,
the stash assessment (salvage patches 1-2 + ten seeds), and the four
donor examinations below. Plans from the POST-MERGE tree (the arc-17
branch lands first, pending its merge audit). Arc numbering: this arc
takes the "arc 18" slot; the goal-directed-search arc (Lithium parity
floor) becomes arc 19 and INHERITS this arc's registry as its
presumed-existing substrate.

## Donor takeaways (design-philosophy and playbook input, cited)

- **golean** (deps/golean CLAUDE.md + AGENTS.md): coherence is
  maintained by ONE always-loaded operating contract stating the trust
  chain in a single sentence ("the executable interpreter is BOTH the
  differentially validated model and the statement language; the
  Prop-level relation is proof infrastructure, proven equivalent,
  absent from headline statements") plus a one-command validation gate
  (`scripts/ci`) and a merge invariant keeping the proof relation in
  lockstep with the interpreter. ADOPT: the one-sentence trust chain
  as the philosophy's opening; the lockstep-invariant phrasing for our
  evaluator↔laws contract; the "amend when a practice proves its
  worth — keep it lean" header discipline for the playbook.
- **RefinedC** (deps/refinedc theories/{caesium,typing,lithium}):
  three SEPARATE, contracted layers — semantics, typing judgments,
  search engine — where rules are definitions with a canonical
  goal-form head (typed_stmt/typed_if/… in typing/programs.v)
  registered via typeclass instances with Hint Modes (typing/type.v:381,
  403): the goal-form key + mode discipline gives
  unique-rule-per-goal-form BY CONSTRUCTION, and extension points are
  explicit named hooks (typing/automation.v: sidecond_hook,
  normalize_hook). ADOPT: registry entries keyed by goal form with
  applicability determined by the key, not by engine code; named
  extension hooks instead of engine edits; the three-layer separation
  as our module boundary (laws may not know about the engine; the
  engine may not contain semantic knowledge).
- **brick-wp** (deps/brick-wp README + theories/WpTactics.v): a step
  library packaged for reuse — axiom-free core, STRICT genericity
  boundary (imports the framework, never a consumer project), a shop
  window that enumerates the API by proof-step category, pins.env
  recording compatibility evidence honestly, and ND-collapse lemmas
  reducing order-enumeration to one goal per unit. ADOPT: the
  README-by-proof-step-category shape for our PLAYBOOK.md's tactic
  section; the genericity rule for ConstructLaws/Kit (fixture-free is
  already gated — extend to consumer-free imports); the honest
  compatibility register.
- **iris-lean HeapLang** (.lake/packages/iris Iris/Iris/HeapLang/):
  the module SEQUENCE is itself the playbook — Syntax → Semantics →
  Instances → PrimitiveLaws → DerivedLaws → ProofMode → Tactic → Lib.
  Each file is one layer contract; a newcomer reads them in order and
  knows how to extend each. ADOPT: reorganize the surviving route's
  modules to read in that order, and structure PLAYBOOK.md's
  narrative around that sequence.

## 1. The design philosophy (one page)

**The trust chain, one sentence** (golean-style): the fuel opsem —
generated from the same Lem model as the differentially validated
OCaml oracle — is both the semantic model and the statement language;
everything above it is proof infrastructure that discharges through
adequacy and appears in no statement and no cone beyond the three
standard axioms.

**The stack, with each layer's contract to the next:**

1. **Fuel opsem** (generated + seams; the TCB). Contract upward: total
   functions, app-equations, per-step structure via the KExpr
   reification. Gates: purity/totality, lem-sync, fork-drift,
   differential baselines.
2. **The per-step relational layer** (KExpr/KStep, relsemcore +
   PerStep): configurations of the fuel opsem's own state; every step
   arm premised on a generated-code equation (defined, never
   axiomatized). Contract upward: `Language` instance + completeness
   lemma (`ksteps_of_runNDFuel`). LOCKSTEP INVARIANT (golean-style):
   any change to the generated step surface re-proves completeness in
   the same commit.
3. **THE ONE IRIS ROUTE** (adjudicated, this charter):
   - **State interpretation: `CerbMemInterp` (the heap RA)** becomes
     the sole interpretation. Rationale: framing is the charter-named
     scaling abstraction and the arc-19 search requires
     footprint-shaped hypotheses; OwnP goals structurally cannot
     produce them (review seam 2, BLOCKING). OwnP retires with the
     migration (decision D2 below; exit ramp: if migration exceeds M,
     the fallback is the review's role-labeling — OwnP as
     "harness-spine bootstrap, retiring at the libxml2 rung" — but
     the TARGET is one interpretation). Adequacy hands the closed
     harness its initial footprint (`kAdequateHeap_of_wp`, landed
     arc-16 S2) — "whole-state" is just the initial big-sep, the
     HeapLang precedent exactly.
   - **Equation supply: the evaluator** (`derive_state`/
     `derive_rounds`) mints named per-round/per-stage equations by
     applying REGISTERED laws. Contract upward: named equations +
     frontier tags, fail-closed. The evaluator is a THIN LAW-APPLIER:
     any mechanism encoding semantic knowledge that fires twice
     becomes a registered law (the standing engine-to-law rule,
     review move 6); the engine's line count is a watched metric
     under down-pressure like proof length.
   - **Consumption: the wp-tactic layer** (`wp_step`/`wp_pures`/
     `wp_side`→`wp_ground`) walks the harness spine consuming minted
     equations; loops enter through `iter_compose` (equation-level
     invariant families — honestly named: this is Floyd-Hoare at the
     equation calculus, not löb; the Iris-level invariant story
     arrives with contracts/typed views in arc 19+).
   - **Retired by this adjudication** (D1): the arc-7 whole-run route
     (IrisLang/SlateWP — falls with the ambient family), the chase
     corpus (already scheduled), AND the dormant arc-16 half (the
     loop peels + the 15 `wpk_round_*` laws): zero consumers,
     superseded by the evaluator route; prune-don't-merge applies to
     our own refounding too. The cmm arc, when it genuinely needs
     per-round ND granularity, re-derives against the registry —
     with the arc-16 S3 record as its archive. (Operator may override
     to KEEP-with-named-consumer; see Q1.)
4. **Adequacy** (threaded, per-step): lands fuel-opsem-only statements
   at cones exactly {propext, Classical.choice, Quot.sound}.
5. **Statements** (boring, gate-enforced): ONE vocabulary post-arc —
   a semantics-side threaded initial state; primary face
   `HarnessRunsToThr` (whole-program, the harness doctrine's native
   form); `CallHarnessAdequateThr` as the labeled function-call slate
   idiom; UBFree/Outcomes as derived forms; guarded faces (T4's
   apartness) carry their hypotheses visibly with kernel-witnessed
   justifications.

**Design principles carried forward** (distilled from doctrine, not
new): Iris-first/canon-first with lineage sentences; the trick filter;
the three-species grind ban; statements fuel-opsem-only; park ends the
slice; down-pressure on proof length AND on engine size; giant terms
in goals are a representation smell (named constants + law-driven
navigation, never whnf materialization).

## 2. The playbook (deliverable spec)

**Placement**: `lean_frontend/PLAYBOOK.md` (shop-window doctrine:
front-facing, current-state-only, professor-passed), pointer from
README.md; the machinery modules' headers remain the in-tree
contracts (gate-checked where feasible — the review's "shop window
for the proof machinery").

**Contents (recipes, each with a worked in-tree example):**
1. THE STORY — the one-page philosophy above, newcomer-readable.
2. HOW TO ADD A CONSTRUCT LAW — registry entry shape (attribute,
   goal-form key, frontier tag, trace schema, lineage sentence),
   where it lives, the fixture-free + consumer-free gates, how to
   plant-test the registration. Worked example: `erun_jump_m`.
3. HOW TO PROVE A NEW PROGRAM — the t6 pattern end-to-end: pin the
   fixture (oracle dump, drift gate), statement (threaded face),
   `derive_rounds`, the wp walk, cone pin, battery registration.
   Target: an agent following only this recipe reproduces t6-class
   results (the dumb-agent probe, acceptance test 2).
4. HOW TO EXTEND THE TACTIC LAYER — named hooks only (RefinedC-style
   sidecond/normalize extension points); engine edits require the
   engine-to-law justification.
5. HOW TO STATE A NEW THEOREM — statement vocabulary, threaded form,
   guarded-hypothesis pattern, cone pinning, statement-gate
   registration.
6. WHAT THE GATES ENFORCE — the gate census with one line each + the
   plant-test recipe for adding a gate.
7. THE REGISTERS — down-pressure (proof lines), engine size, the
   forward-compatibility checklist (below).

## 3. The slice plan

Sequencing adjudications up front:
- **T5 TIMING (D3): consolidation BEFORE T5 completion.** Rationale:
  (a) the route migration (C2) changes the substrate T5's proof walks
  on — landing T5 first means proving it twice, a prune-thinking
  violation; (b) the identity law is route-independent and is itself
  a LAW — it lands in C3 where it registers properly from birth;
  (c) criterion 1 ("current examples keep passing") is not at risk:
  T5 is honestly PENDING today, so deferral regresses nothing;
  (d) the generalization proof the arc needed (T6) is already landed
  — T5 completes as a client of the consolidated layer, which is a
  better demonstration than completing it on machinery scheduled for
  rework.
- **Registry before migration** (C1 before C2): the migration's
  re-derived walks should land on the final interface once.

**C0 — doc truth + freeze + contracts (S).** The review's move 1
(TODO.md in-flight/next rewritten; PROOF.md §4 presents
evaluator+laws+WP as current, walker as purge-bound legacy;
check_chase_freeze header's @[app_eq] claim fixed); delete the three
untracked Probe scratch files (F9); ratify the extended purge
inventory (below) as a committed list; the registry entry schema
spec'd; the RoundEval decomposition plan written (module cut:
dispatch core / per-head lanes / minting primitives / arith minter /
diagnostics — executed in C1). Serves (2).

**C1 — THE ONE REGISTRY (M).** Attribute-indexed law registry: the
AppEqAttr DiscrTree machinery is the in-house donor (generalized to
a `@[step_law]`-class attribute or a renamed evolution of @[app_eq]);
entries carry {goal-form key, law kind, side-condition class,
frontier tag, trace-atom schema, lineage tag}; unique-rule-per-
goal-form discipline per RefinedC's hint-mode lesson. RoundEval
dispatch and wp_side consult the registry (hardcoded-name dispatch
deleted); ConstructLaws + Kit/{Mem,Env,Round,Map} entries registered;
RoundEval decomposed per the C0 plan (the 3383-line recurrence risk,
F8: after decomposition the engine core is the watched metric).
Serves (2),(4); unblocks arc 19. STASH: salvage patch 1 (the mem
footprint package) applies here, registered from birth; salvage
patch 2 (chain-capacity design) re-derived here with the addDecl
failure diagnosed first; the ten seeds ride this slice's brief.

**C2 — ONE ROUTE (M, exit ramp).** CerbMemInterp becomes the sole
state interpretation: seq/pure step rules restated over it (the
generic lift + the four op rules exist, arc-16 S2), the T1-T3/T6
threaded walks re-derived (15-line scripts; cones must be
byte-stable — acceptance 1's regression gate), OwnP bindings retired
from the live route. The framing demo graduates: at least one
re-derived theorem's proof visibly frames (footprint hypotheses in
the goal). Exit ramp: if the migration exceeds M, stop, land the
role-labeling fallback (documented split until the libxml2 rung),
report. DELETE in this slice (zero consumers, verified): the loop
peels + PerStepLaws + their smokes — unless Q1 rules KEEP. Serves
(2),(4).

**C3 — LAW COMPLETION + T4 + T5 (M).** The `pull_constrained`
identity law FIRST (the mandatory item nothing may substitute for);
remaining memop laws as registry entries; T4-threaded completed
(rounds 22+, SeqRMW branch, terminal + walk + guarded statement
proved — the S4→S2b chain closes; statement added to the statement
gate, review seam 4 residue); T5 completed on the consolidated
substrate (identity law + iter_compose + one body walk; proof-size
T5 row flips PENDING → enforced). Down-pressure numbers recorded for
both against their ambient/chase-era footprints. Serves (1),(4).

**C4 — STATEMENT HOMING + family-∀ (S + M).** The threaded initial
state and faces MOVE (not mirror) semantics-side (relsemcore); the
threaded whole-program face defined; speclab's 46 statements + 15
lemmas re-landed threaded; family-∀ endpoints (R1/R5 → R2 → R3/R4 as
machinery allows); refutation schemas unconditional. After this
slice, runEffectful's carrier set is exactly the ambient family.
Serves (1),(4).

**C5 — THE EXTENDED PURGE (M, one commit).** "Leave exactly one
route": the chase corpus (AppWalk 2435 lines, WalkTrace, the four
AppEq files, T5Prefix/T5Iter walk scaffolding, t5-probe/WalkBench/
E-series), the arc-7 route (IrisLang/IrisState/IrisRules/
IrisAdequacy/SlateWP), the ambient family + its 114-carrier set +
the _of_wpK2 bridges + PerStepSmoke/PerStepTacSmoke, the ambient
statement faces (deleted or inverted to labeled corollaries), the
peels/PerStepLaws if not already gone in C2, and `runEffectful`'s
no-cone gate row driven to an EMPTY carrier set (the axiom survives
only lem-side, consumed by zero theorems). Freeze-gate allowlist
empties; every gate re-registered in the same commit; fresh grumpy
pass over the post-purge tree. Success bar: ONE step-machinery, ONE
interpretation, ONE statement family + labeled derivations; the
coherence review re-run as the audit instrument. Serves (2).

**C6 — PLAYBOOK + acceptance (S-M).** PLAYBOOK.md written against
the post-purge tree (§2 above); professor pass + re-mark; THE
DUMB-AGENT PROBE (acceptance 2, specified below); the forward-
compatibility checklist verified (acceptance 3); down-pressure
register summarized; ROADMAP/container records. Serves (2),(3).

**Out of scope, unchanged**: the libxml2 rung (S6 of the old
numbering) remains the NEXT arc's graduation probe (acceptance 4) —
run under the consolidated layer, its memory reasoning under
CerbMemInterp per the review's seam-2 requirement, producing the
parity-distance table for arc 19 (search). The CN extension track
unchanged, never blocking.

## 4. The four end-state criteria as acceptance tests

1. **All current examples pass**: per-slice regression gate — the
   full battery (unit incl. all censuses/freeze/no-cone, verify
   35/35, exec zero-movement where driver paths are touched, speclab
   lanes, cn baseline) green at every commit, and every LANDED
   theorem's statement + cone byte-stable across the consolidation
   (Audit pins are the instrument; any pin movement is a finding,
   not a rebase).
2. **Clear and explainable**: (a) PLAYBOOK.md passes the grumpy
   professor + re-mark at A− or better; (b) THE DUMB-AGENT PROBE — a
   fresh agent, given ONLY the playbook and the tree (no
   conversation context, no records), must in one session: add one
   small construct law for a named simple shape (registry entry,
   gates green) AND prove one new micro-program (t6-class, oracle-
   pinned, threaded statement, trio cone) via recipe 3. Pass =
   both land on green with zero orchestrator intervention beyond the
   brief; the probe's friction log feeds a playbook revision.
3. **No foreclosure**: a checklist verified and recorded in the C6
   record, one sentence each: cmm schedules (per-step ND structure
   preserved in KStep; choice-stream slot intact), typed views
   (heap-RA byte layer + Caesium donor path unchanged), CN
   elaboration (CN-0 AST + the ladder's prerequisites intact),
   contracts/overrides (summary shapes representable over
   CerbMemInterp; registry supports call-boundary rule kinds),
   elaboration-in-statement probe (pinned-AST route unaffected),
   effect-state end state (seed-threading pattern + ghost-resource
   candidate preserved behind the evaluation gate).
4. **Ready for the next push**: the libxml2 rung's charter can be
   written against the post-arc tree with no prerequisite listed
   except its own content (string/buffer laws, typed views) — the
   C6 record drafts that charter's skeleton as its own final section.

## 5. Doctrine compliance

Every slice brief carries: lineage sentences per mechanism; the
three-species grind guards + the ~1hr tripwire + KILL-banner
exit-checking; park-ends-slice + immediate-interim-reply; iteration-
unit sizing; the down-pressure register row; statements fuel-opsem-
only (gate); no budget bumps (scoping at defaults allowed, recorded).
Merges ff-only on per-merge sign-off; audit ask unconditional;
checkpoints on concrete objects are the operator's.

## Questions for the operator

- **Q1 (peels/PerStepLaws)**: DELETE at C2/C5 with the arc-16 records
  as archive (recommended: zero consumers, prune-don't-merge, cmm
  re-derives against the registry when real), or KEEP with "cmm arc"
  as the named future consumer (cost: carrying a dormant second
  step-machinery through the coherence arc that is supposed to end
  with exactly one)?
- **Q2 (interpretation migration)**: ratify the full OwnP →
  CerbMemInterp migration in C2 (recommended; one interpretation,
  framing becomes real, arc-19 unblocked), or the softer
  role-labeling split until the libxml2 rung forces it (cheaper now,
  carries the dual-route hazard and a second migration later)?
- **Q3 (arc scope)**: run C0-C6 as ONE arc (recommended; the slices
  are tightly coupled and the purge needs C2-C4 complete), or split
  at C3/C4 into two arcs with a mid-point merge?
