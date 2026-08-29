# The reasoning-layer design pass (whole-project)

STATUS: **DISCUSSION DOCUMENT — NOT A CHARTER.** Commissioned per the
operator's sequencing ruling [USER 2026-08-26]: "make sure to do a
'whole project design pass' before imposing this reasoning layer, then
discuss it with me before signoff. We want to (1) avoid baroque
machinery hanging around if it's not needed, and (2) think carefully
about the reasoning layer vs. eg. Brick / refinedC / CN." Nothing here
executes without that conversation. Prices are estimates for
discussion, not commitments.

Ground truth surveyed: worktree `worktrees/cerberus-lean-coherence`,
branch `coherence` @ `cfeb7af5e` (post C4, boundary verified green);
donors `deps/BRiCk` (cloned 2026-08-26, ideas-only), `deps/refinedc`,
`deps/cn`, `deps/brick-wp`, `deps/golean`. Prior inputs: the
reasoning-layer contracts (`lean_frontend/docs/
2026-08-25_reasoning-layer-contracts.md`, NORMATIVE), the coherence
review (`notes/2026-08-25_reasoning-coherence-review.md`), the Hoare
ruling + proof-style professor test [USER 2026-08-26].

The operator's two suspicions, restated as the pass's questions:

1. **Baroqueness**: is any of the machinery we built load-bearing only
   for the way we currently *phrase* proofs, rather than for the
   proofs themselves?
2. **The reasoning layer**: when a human verifies `sum(n)` they say
   "invariant: s = k(k-1)/2 at the loop head; three straight-line
   segments preserve it." Our T5 artifacts say "79-round builder walk
   with a 27-hypothesis pack." What judgment makes the machine
   argument *coincide* with the human one — and what did
   BRiCk/RefinedC/CN already learn about that question?

**Headline of the whole pass** (details below): the audit finds
essentially no *new* baroque machinery — the C5 retirement register
already schedules the right deletions — but it finds the USER SURFACE
inverted: engine idioms (walks, rounds, minted state names,
`derive_rounds` in fixture files) sit in user position, and the
legitimately-human content (T5's invariant) is spelled in engine
vocabulary. The fix is not more machinery; it is ONE missing judgment
— a segment triple at Core's join points — derived once from pieces
that all already exist. The donors converge on exactly this shape.

---

## Part 1 — The baroqueness audit (delete-or-justify)

Method: every proof-layer mechanism on the branch, judged on (a) does
the segment layer subsume it, (b) engine-room vs user-facing, (c) is
its complexity load-bearing today (the walls it was built against —
do they still exist post-identity-law, post-registry?).

Verdict key: **ENGINE** = keep, hidden behind the judgment;
**SUBSUMED** = delete/demote when the segment layer lands; **BAROQUE**
= delete at C5 regardless; **USER-SIMPLIFY** = the content is right,
the face must change.

| Mechanism (file, size) | Verdict | Grounds |
|---|---|---|
| Law registry `@[step_law]` (`LawRegistry.lean`, 342 ln; 66 sites across Kit/ConstructLaws/CerbHeapWP/Walk) | **ENGINE** | The one law interface (R3/R4 closed); the segment layer dispatches through it; arc-19 searches over it. DiscrTree keys + unique-rule-per-goal-form are RefinedC's hint-mode lesson, lineage named in-file. |
| Round evaluator, decomposed (`RoundEval/` 9 modules, ~5,000 ln) | **ENGINE, demoted** | Becomes the *segment discharger*, invoked by the layer, never written in fixture files. Complexity is load-bearing: every lane maps to a measured wall (S1 §4.2 OOM → anchors; the substitution drip → named side facts). Engine-size watch continues (R3 row). |
| — ground mode (`evalGroundA`) | ENGINE | Closed-state discharge; stays for harness prologues. |
| — hypothesis-threading mode (`Hyp.lean`, 1,033 ln) | **ENGINE, load-bearing for the layer** | Conditional rewriting made mechanical — this is precisely how an *invariant-parameterized* segment discharges (the invariant's equalities/bounds enter as the pack). Without it the segment layer only handles ground segments. |
| — builder mode + builder-gated unify fallback (C3b) | ENGINE, watch | Exists for loop-head-parameterized states; the invariant segment needs it. If the open-memory minting mode (below) generalizes it away, fold in. |
| — arith minter (`Arith.lean`, 722 ln) | ENGINE | Decision procedures at the leaves (omega + kernel decide) — the ACL2Lean donor contract; canonical. |
| — fence fallbacks, glue rounds, anchor discipline | ENGINE detail | Each anchored to a measured cliff (whnf budget, fvar leak); documented in-module. Not user-visible post-layer. |
| `DeriveState.lean` (260 ln) | **ENGINE** | The giant-terms fix (ACL2Lean `derive_world` lift). Segment endpoints stay named constants — the layer depends on it. |
| `WpGround.lean` (memoized decide) | **ENGINE** | Side-condition leaves; donor-verbatim; canonical. |
| wpk tactic layer (`PerStepTactics.lean`) | **ENGINE, demoted** | `wp_step`/`wp_pures` remain the substrate the segment rule is *proved from once*. User proofs stop calling them per atom. The brick-wp factoring (lemmas + thin macros) is preserved — one level down. |
| CerbMemInterp + heap rules (`CerbHeapRA/WP/Walk`, ~2,700 ln) | **ENGINE (the survivor)** | The one interpretation (Q2 FULL, R2 closed). The segment rule instantiates `wpk_seq_*`; framing across segments is the frame rule doing its job. Non-negotiable keeper. |
| Chain assembler + `iter_compose` (`Assembly.lean`, `Kit/Loop`) | **ENGINE — it IS the segment composition** | A `*_chainrel` (∀-fuel relative block equation) is operationally exactly what "triple over a segment" means at the equation calculus. The layer renames and packages it; nothing new to build here. |
| The five T5 walks (`T5Walks.lean`: e 22, bfirst 78, b 79, bx 44, bxzero — ~266 rounds) | **SUBSUMED as user artifacts; content survives** | The C3b decomposition *empirically discovered the segment structure*: e/bfirst/b/bx/bxzero are precisely entry→head, head→head, head→exit — segments to join points. The equation supply survives engine-side; the hand-assembled walk files shrink to spec + invariant. This is the strongest internal evidence the segment layer is the right abstraction: the walls forced us into its shape before we named it. |
| T5 invariant family (`T5Inv.lean`, 335 ln: `triF`, `St p k`, alignment rfls) | **USER-SIMPLIFY** | `triF`/`triF_closed` (s = k(k-1)/2) is the legitimately-human content and reads well. `St p k` spelled via builder packs + 27-hypothesis alignment is engine leakage into the one artifact a professor must read. Target: invariant = footprint assertion at the loop label; `St`/alignment derived by the engine. |
| Per-fixture walk bodies (T1/T2/T3Threaded wp scripts; T6's 11-`wp_step` script) | **SUBSUMED** | Today's user-facing proof is a state-name plumbing script (`wp_step (dG_app seed) Hst …`). Correct, short — but its vocabulary is minted names, not program structure. Replaced by per-segment `seg_auto`. |
| `derive_rounds` in fixture files | **SUBSUMED as user syntax** | Becomes engine-internal (the layer calls it per segment). A fixture file should contain: fixture data, spec, invariants. Nothing else. |
| C4 family-∀ target apparatus (R1/R5 target statements, honest-unproved) | KEEP (statements) | Targets stay; the segment layer is their likely prover (ground-mode-twin item M dissolves if the open-memory mode lands for segments anyway). |
| Chase corpus (AppWalk 2,435 ln, AppEq files ~5,100 ln, T5Prefix/Iter/Fixture, ambient family, OwnP shells, `PerStepRunner`) | **BAROQUE — already scheduled** | Retirement register entries 1–4; C5 executes. This pass re-confirms: no segment-layer design below needs any of it. No stay of execution. |
| T6's OwnP exemption (`check_one_route.sh` labeled exemption) | dissolves | The segment layer *requires* the open-memory minting mode (named mover in the C2 record) — landing it clears the last exemption as a side effect. |
| Kit law library (`Kit/{Eval,Map,Mem,Env,Round,Loop}`, ~2,600 ln) | **ENGINE** | The registered law supply. `pull_constrained` identity law + read-over-write laws are what deleted the round-44 wall — load-bearing, canonical (rewrite systems). |
| Speclab statement/harness substrate (46 threaded statements, codecs, mkHarness) | UNTOUCHED | Statement layer; the boring front. This pass changes nothing in front of adequacy. |

**Audit summary.** (1) Machinery: nothing new to delete beyond the
standing C5 register; the engine's complexity is wall-anchored and
documented, kept under the existing size watch. (2) The genuine
finding is a *misplaced interface*: we built a good engine and then
let users (ourselves, and soon the breadth campaign's agents) talk to
it in engine language. Every SUBSUMED row above is the same defect
seen from a different file. (3) One mechanism is genuinely missing —
the judgment itself — and it is derivable from existing parts
(chainrel + iter_compose + CerbHeapWalk rules + adequacy), not new
capability.

---

## Part 2 — The comparative reasoning-layer design

### 2.1 What the donors actually do

**BRiCk** (`deps/BRiCk/rocq-skylabs-brick/theories/lang/cpp/logic/` —
ideas-only, license unread for code reuse). The middle layer the
operator pointed at is concrete: an axiomatic wp indexed by **source
AST node and value category** (`wp_lval`, `wp_operand`, `wp_init` in
`wp.v`; one rule per statement form in `stmt.v`), with
continuation-passing postconditions (`Kpred` carrying
Normal/Break/Continue/Return — control flow as continuations). Loops:
`wp_while_inv I : (I ⊢ while_unroll … (Kloop (▷I) Q)) → I ⊢ wp (Swhile …) Q`
(`stmt.v:487`) — *the invariant rule is stated at the source loop
node*. What makes it legible before automation: every rule is
readable as an operational Hoare rule for a C++ construct; a proof
walks the source. Cost visible in `deps/brick-wp/examples/
persistent-bst/coq/Dtor.v`: even with brick-wp's packaged steps, a
5-field destructor is ~60 tactic lines of `wp_walk`/`wp_offset`/
`iDestruct` — legible but verbose; the automation layer above (their
`wp_auto`) is what compresses.

**RefinedC** (`deps/refinedc/theories/typing/programs.v`). The user
judgment is a *typing* judgment: `typed_val_expr e T := ∀ Φ, (∀ v ty,
v ◁ᵥ ty -∗ T v ty -∗ Φ v) -∗ WP e {{Φ}}` — a WP wrapper where
pre/posts are refinement types. The structural point for us:
`typed_stmt … (Q : gmap label stmt)` and
`typed_block (P : iProp) (b : label) …` — Caesium compiles C control
flow to **labeled blocks with gotos**, and invariants attach to
**block labels**. Lithium then runs goal-directed search over typing
rules. What types buy: canonical goal forms (automation never
guesses), compositional annotations humans can write. What they cost:
a large subsumption/simplification apparatus, and the annotation
language itself — infrastructure whose consumer is a human developer.

**CN** (`deps/cn`). Resource-annotated triples in source (requires/
ensures/loop invariants), discharged by symbolic execution with SMT
leaves. The judgment IS the triple; legibility comes from annotations
living next to the C. Trusts its solver stack — the part we do not
copy (everything of ours lands kernel-checked).

**brick-wp / golean** (`deps/brick-wp`, `deps/golean`). Not judgment
designs but *discipline* donors, both already absorbed: every
recurring proof step a lemma with thin tactic faces (our wpk layer);
two-layer walker/audit separation (our engine/gate split).

**Convergence.** Three independent projects answer "where does human
content live?" identically: **pre/post at function boundaries,
invariants at control-flow join points, everything between discharged
mechanically.** RefinedC's join points are Caesium's labels; BRiCk's
are source loop nodes (via Kpred); CN's are loop annotations. Our
Core already has the RefinedC shape natively: loops elaborate to
`save`/`run` labeled continuations (T5's `run while_531` back-edge),
so **join points = Core labels**, no source-AST reconstruction
required. And per canon-first: this is not a donor fashion, it is
Floyd 1967 — assertions attached to cut points of the control-flow
graph, verification conditions on the straight-line paths between
them. The donors are three implementations of Floyd's cut-point
method; ours will be the fourth.

### 2.2 The chosen judgment (proposal)

**A separation-logic segment triple at Core join points**, proof-layer
only (statements stay boring; discharge through the existing threaded
adequacy; cones stay the trio).

```
SegTriple (tags) (P : SegAssn) (start : SegPoint) (Q : SegAssn) : Prop
```

- `SegPoint`: entry, a Core label (`save`d continuation), a call
  boundary, or the terminal.
- `SegAssn`: footprint assertion — points-to fragments + allocation
  fragments + pure facts over binder values (the CerbMemInterp
  vocabulary that already exists; `restIs` carries the non-memory
  driver components).
- Meaning (internally): from any state satisfying `P` at `start`, the
  driver's run reaches the next join point in some finite round count
  with state satisfying `Q` — packaged as the ∀-fuel relative chain
  equation (`*_chainrel`) under framing. **The segment rule** —
  SegTriples compose; a loop whose head-invariant is preserved by its
  body segment and exited by its guard-false segment yields a
  SegTriple for the whole loop (via `iter_compose`) — is proved ONCE.
  Lineage, named: Floyd cut points; Hoare composition + while rules;
  Iris wp-seq/wp_while_inv; RefinedC typed_block.

**Why triples and not RefinedC-style types** (the operator's "think
carefully vs Brick/refinedC/CN"): refinement types are a *compression
of triples* whose payoff is (a) guiding proof search and (b) giving
humans a compact annotation language. (b) is de-scoped by
reach-not-clone — our author is an agent writing Lean directly. (a)
we get differently: the registry's goal-form keys + frontier tags
already give the search canonical shapes (arc-19's substrate). And
types cost the subsumption engine — the single biggest machinery item
in RefinedC. Decision: triples now; a typed view later *if* breadth
data shows assertion shapes stereotyping hard enough that a type
layer pays for itself (it would sit above SegTriple unchanged — no
foreclosure). **Why not BRiCk's wp-over-source**: it needs the C AST
as the proof's index; we verify at Core. The source-structure
reconstruction idea survives as *presentation*: segment names and
docstrings state the source construct ("the while body", "the else
arm") — the spec-lab vocabulary-saturation data says Core shapes are
stereotyped enough to name mechanically.

**The engine-room contract** (one sentence per direction): the layer
may assume the engine can mint, for any straight-line segment and any
hypothesis pack drawn from `P`, the open-memory chainrel for that
segment or a tagged frontier; the engine may assume it is only ever
asked for straight-line segments between declared join points.
`seg_auto` = derive_rounds (open-memory mode, pack from the
invariant) → chainrel → segment-rule instance. Missing today and
REQUIRED: the **open-memory minting mode** (map reads through the
registered memRW lane instead of ground eval) — already the named
mover on T6's exemption; landing it is the layer's one engine
prerequisite.

### 2.3 The professor exhibit — T6 as it would read

Today (`T6Probe.lean`): fixture data, two law-instantiation lemmas
(`t6_inject`/`t6_errno`, ~25 lines each of Kit hypotheses),
`derive_rounds r …`, then an 11-line `wp_step` script over minted
state names, then the adequacy wrap. Correct, trio-clean — and
unreadable without knowing dG/dInj/dErr/r_fin.

After (target; names illustrative):

```lean
/-- pick(10) = 7, no UB.  tests/verify/t6_branch.c -/
def pickSpec : FnSpec where
  args := [intValue 10]
  pre  := emp                      -- closed harness: adequacy grants the initial footprint
  post := fun r => r = specified 7

theorem T6Threaded : T6ThreadedStatement := by
  verify_fn t6File "pick" pickSpec
  -- one segment: entry ─▸ return  (a branch, both arms straight-line)
  seg_auto
```

And T5 (the loop; the invariant is the *only* human line):

```lean
/-- sum-to-n via the while loop: result = n(n-1)/2. -/
theorem T5Threaded : T5ThreadedStatement := by
  verify_fn t5File "sum" t5Spec
  invariant while_531 fun k =>
    s_cell ↦ intBytes (k * (k-1) / 2) ∗ i_cell ↦ intBytes k ∗ ⌜k ≤ n⌝
  seg_auto   -- entry ─▸ loop head      (establishes I at k = 0)
  seg_auto   -- loop head ─▸ loop head  (guard true: body preserves I)
  seg_auto   -- loop head ─▸ return     (guard false: I ∧ ¬guard ⊢ post)
```

The professor test, applied: the proof states an invariant at a
named source loop and three segment obligations — the exact shape of
the blackboard argument. Every `seg_auto` is engine work (the 78/79/
44-round walks, minted and kernel-checked, visible in the trace
format if summoned); none of it is in the reader's way. Structural
coincidence is the acceptance criterion, and this is what it looks
like.

Honesty notes on the exhibit: (i) `intBytes`/footprint spelling is
real — the invariant is an SL assertion, which is *proof-layer*
content (boring-front unaffected; see open question Q2); (ii) today's
T5 pack has 27 hypotheses — the claim is that all but the invariant's
~3 conjuncts are frame/plumbing the segment rule internalizes;
partial risk that a few surface as side conditions (measured answer
comes from the first landing); (iii) `verify_fn`/`invariant`/
`seg_auto` are thin faces over existing pieces, not a new engine.

### 2.4 Costs (estimates for discussion)

- **The layer itself**: SegTriple + segment rule + the three faces —
  proved from chainrel/iter_compose/CerbHeapWalk/adequacy. M (single
  worker slice, iterable; no new trust surface, all kernel-checked).
- **Open-memory minting mode**: the one engine prerequisite; M
  (design named in the C2 record; memRW lane exists, the mode routes
  reads through it).
- **Breadth campaign, per program**: harness (existing speclab
  machinery) + spec + invariants only. Straight-line/branching: ~0
  manual proof lines. One loop: 1 invariant. New Core vocabulary:
  new registered laws at the measured spec-lab rate (saturated at R3
  in arc-15 — expected low marginal cost; each new law is
  proved-once-fires-everywhere, the automation dividend).
- **Arc-19 over segments**: search decomposes per segment — invariant
  synthesis at labels (candidate: from the engine's own round trace,
  the Floyd-style forward-propagation candidates) + frontier-tag
  filling. The registry's trace atoms were designed for this
  consumer.

Trick-filter self-check: the abstraction exploited is stated in one
sentence — Core's compiled control flow already carries its join
points as labels, so Floyd cut-point decomposition applies without
source reconstruction — and the next example gets it for free
(any Core program has labels). No representation steering; the engine
is unchanged underneath.

---

## Part 3 — Integration with the standing plan (PROPOSAL, awaiting
the conversation)

Sequencing logic: T5-the-theorem should land ONCE, through the layer
(the C3c enumerated mechanics priced re-proving walk compositions by
hand; the adjudicated landing-first-is-proving-twice reasoning
applies to the layer itself now).

- **S-A — the segment layer over existing theorems** (M): SegTriple +
  segment rule + faces; open-memory minting mode; re-house T1/T2/T3/
  T6 as spec + `seg_auto` (statements and cones byte-stable — this is
  a proof-body refactor). Clears the T6 OwnP exemption. Acceptance:
  the professor reads T6 and T1 cold; proof-size gate numbers drop.
- **S-B — T5 through the layer** (M): invariant at `while_531`
  (T5Inv's `triF` reborn in footprint form); subsumes most of C3c's
  map (env-lookup peels/pack families become engine work; assess the
  scratch2 Iris rule — likely dissolves into the segment rule;
  statement + gate-row flip as chartered). R5 progress via the same
  route for T4's builder leg (unchanged env-algebra content).
- **S-C — the breadth campaign** (M, batched 5 at a time, box-aware):
  ~20 small programs; acceptance = structural coincidence + the
  proof-style professor pass on a sample; measures marginal
  cost/program and feeds the law frontier. Family-∀ targets (C4's
  R1/R5 statements) attempted here where the layer reaches them.
- **C5 — extended purge, inventory unchanged + Part 1 deltas**: the
  register entries as written, plus the SUBSUMED rows (per-fixture
  walk scripts, fixture-file `derive_rounds`, T5Walks-as-user-prose —
  content re-homed engine-side first). Freeze allowlist empties as
  chartered.
- **C6 — playbook teaches the segment style**: the dumb-agent probe
  writes a spec + invariant, never a walk. (If C6 taught today's
  idiom it would be obsolete at birth — sequencing C6 after S-A is
  the point.)

Nothing here forecloses: cmm (segments per thread; choice streams as
schedules unchanged), the repo split (the layer lives proof-side of
the seam), CN extension track (CN annotations map 1:1 onto
SegTriples — the natural import target), typed views (layer above,
later), libxml2 rung (uri.c's functions are exactly
segments+few-loops shaped).

---

## Open questions for the operator

1. **Ratify the judgment choice**: SL segment triples at Core labels
   (Floyd/RefinedC-shaped), types-later-maybe — vs. investing in a
   refinement-type layer now?
2. **Invariants are SL assertions in the proof layer.** Statements
   stay boring (unchanged, gate-enforced); the escape-hatch doctrine
   governs *statement*-level SL only. Confirm this reading — loop
   invariants in footprint form are ordinary proof content, no
   operator gate per instance.
3. **Sequencing**: S-A → S-B → S-C → C5 → C6 as above (T5 lands
   through the layer, C3c's remaining map absorbed) — or finish C3c
   first as chartered? Recommendation: through the layer; the C3b
   walks survive as its equation supply either way.
4. **Vocabulary flip now**: rename walk→segment across docs/module
   docs at S-A (cheap; the professor reads names first). Any
   attachment to the "walk" terminology?
5. **Call boundaries**: the design reserves SegPoints at calls for
   per-function summaries (SAW-override lineage, two-stage plan from
   the stepper note's surviving idea). Defer until the first
   multi-function target, or include a single worked summary in S-C?
6. **Breadth corpus**: draw the ~20 programs from `deps/cn/tests/cn`
   clean-room (extension-track synergy) or fresh minimal C (main-line
   purity)? Recommendation: mixed, majority fresh.
7. **Presentation investment**: segment names carry source-construct
   labels from day one (mechanical from Core shapes) — sufficient for
   the professor, or is a fuller Core→C structure map (the old
   reconstruction idea) wanted this arc? Recommendation: names only;
   reconstruction stays parked.
