# Proof-performance plan — how RefinedC scales, where our cost lives, and the fix at the Iris level

STATUS: OPERATOR-SIGNED; adversarial review verdict SOUND-WITH-AMENDMENTS
(`notes/2026-08-28_proof-performance-plan-review.md`). Amendments A1–A11
are BINDING and are folded into this text in place [AGENT 2026-08-28,
PERF-0+1 worker, step 0 of the executing brief]; the amendment log at
the end of this document records each fold. Original text drafted for
operator discussion → adversarial review → sign-off. Commissioned [USER 2026-08-28] under
two binding rulings, quoted because they govern every proposal below:

> "Optimizations which couple to the representation structure without
> insight are absolutely totally and completely forbidden."
> "Making up your own terms ('seal engine') is also forbidden."

Every mechanism in this document carries its classical name and a
legitimacy statement (what abstraction it exploits, why it is
semantics-preserving, why the next program gets it for free). Sources:
deps/refinedc primary sources (file:line cited), the V2b pause record
(`lean_frontend/docs/2026-08-28_v2b-pause-record.md` — measurements
quoted from there are provisional until its commit), and static
reading of the branch. No builds were run (the V2b worker had not yet
parked); profiling is slice PERF-0.

---

## 1. How RefinedC scales — the principles, classically named

Read: `deps/refinedc/theories/lithium/{syntax,interpreter,base,
solvers}.v`, `theories/caesium/`.

**L1. Proof search as deterministic interpretation of a reified goal
language** (classical: LCF-style interpreter over a goal grammar;
committed-choice / syntax-directed rule selection). Lithium's goals
are always in a small fixed grammar (`li.exhale/inhale/all/exist/
case_if/find_in_context/subsume/…`, syntax.v:10-70). The interpreter
`lazymatch`es on the head constructor and commits to exactly one step
(interpreter.v throughout). **Backtracking lives in leaf
side-condition solvers over pure, small goals** (solvers.v:47) —
and [A3] in ONE main-walk place: `liFindHyp` (interpreter.v:537-569)
iterates context candidates with `first [ … ]` (also at
interpreter.v:273, 372-390, 465, 540, 564, 572). What makes that
candidate iteration survivable is that each attempt is CHEAP: they
unify "using the opaqueness hints of typeclass_instances" precisely
because "directly doing exact: eq_refl sometimes takes 30 seconds to
fail" (interpreter.v:543-549, verbatim — the donors' own r127). So
the donors' real defense against speculative-unification cost is
opacity-bounded cheap failure (mechanism D) at least as much as
committed choice (mechanism A). Unification against large terms is
never attempted speculatively: the goal's *syntax* selects the rule
before any expensive defeq is tried.
→ Our confirmation this principle is load-bearing: the pause record's
r12 (backtracking 4-variant `first`: non-terminating at 12M
heartbeats; deterministic single-variant: ~50 s) and the r127 root
cause (a wrong-shape lemma "grinding toward failure" — 64M/21 min —
where the right-shape lemma checks in seconds). Our worst measured
pathologies are precisely violations of L1.

**L2. Explicit sharing in the goal (let-abstraction / A-normal
form).** Lithium threads `LET_ID`-bound abbreviations through goals
and unfolds them only when the goal is small (liUnfoldLetGoal,
interpreter.v:18-38 with the comment "not too bad for performance
since the goal is small at this point"). Classical: sharing/CSE at
the goal level; unfolding deferred to where it is cheap.

**L3. Abstraction barriers via opacity — an interface, not a dial.**
`Global Opaque Z.shiftl Z.shiftr` (base.v:40); `Typeclasses Opaque`
on Caesium's arithmetic/bitfield vocabulary (caesium/bitfield.v:290,
449; int_type.v:41). The model: these symbols are never unfolded by
unification; ALL reasoning about them goes through proved lemmas.
This is the classical module-abstraction principle (sealed
interface). It is legitimate exactly when the lemma interface is
COMPLETE — proofs never need the unfolding. (Contrast with the
forbidden class: steering *when/in what order* unfolding happens
while still depending on it — see §4.)

**L4. Elaboration-effort control per step.** `notypeclasses refine`
everywhere; specialized `tac_fast_apply` variants for measurable
1-2% wins (interpreter.v:183); pruned zify hooks after a measured
200% slowdown (base.v:52). Classical: nothing exotic — they simply
never pay instance search or conversion they did not choose to pay.

**L5. Work-sharing across branches.** Case analysis is sequenced so
hypothesis normalization happens once, not per branch
(interpreter.v:1119: "we don't need to do normalization and
simplification of hypotheses that we introduce twice").

**L6. Continuous measurement.** A benchmarks/ directory and a public
regression dashboard (coq-speed.mpi-sws.org, linked from
interpreter.v:183). Performance is a tracked metric with history,
not an anecdote.

**C1. The Caesium goal-shape principle — why their goals are small.**
Caesium's operational semantics is an *inductively defined small-step
relation* over a compact state. A step is characterized by its
CONSTRUCTOR: "this statement steps thus" is an inversion of an
inductive, costing nothing to establish. The machine state never
appears as a concrete term in a proof goal — it lives behind the Iris
interpretation; goals mention points-to fragments only. **Our WP
layer (post-V1) already has this shape** — `envIs/ctlIs` fragments,
authoritative interpretation. The giant terms live one layer DOWN: in
the round-equation supply, because our semantics is a *definitional
interpreter* (a function), and characterizing one step = evaluating
that function at a concrete state. That asymmetry — inductive
relation vs. interpreter function — is the single deepest difference
between their cost model and ours, and §3's main proposal addresses
it at the level the operator mandated.

---

## 2. Where our cost actually lives — top three cost centers

Grounded in the pause record's measurements and the branch's files
(P02RoundsA statements reference NAMED arena constants `p02ar1…` —
so raw statement text is already shared; the cost is *unification-
time normalization*, not source-text elaboration).

**CC1 — Speculative unification against large terms (tactic-time).**
The r127 disaster: the checked-ADD tactic applied a call-form arm
lemma that could NEVER unify against the primitive `PEconv_int`
form; discovering the failure required deep whnf of arena-sized
terms, repeatedly, toward inevitable failure (16M → 64M → stopped).
The r12 backtracker: 4 candidate variants tried in sequence against
an arena-sized goal = non-terminating at 12M, where the single
correct variant is ~50 s. **This is the worst-case-severity
pathology [A2: "dominant" split — CC1 owns the worst case; the
AGGREGATE wall time is CC2's, 52+ min of chunk builds being mostly
green rounds at ~9 s/round] and it is
a proof-search discipline failure (L1 violation), not a term-size
wall.** Evidence: `p02add_evalR` — the same content as one
correctly-shaped lemma — type-checks in seconds.

**CC2 — Per-round ground evaluation via elaborator whnf, at the
wrong granularity.** Each round lemma's proof is "evaluate the
interpreter one step at this state" by rfl-class normalization:
~9 s/round average (chunk A: 88 rounds ≈ 13 min), 16M-heartbeat
budgets on 26 rounds. [A2 correction] The multiplier is CHAIN SHAPE
(extra refine-unifications), NOT arena size: the pause record's own
control experiment — r28/r29 (composite-arena) time out at 2M while
r128/r129 at the SAME arena size pass at 2M ("the cost driver is
the CHAIN SHAPE (extra refine-unifications), not arena size alone",
pause record §3 verbatim). Chain-shape cost is CC1-adjacent
(unification volume, not ground-evaluation volume); mechanism B is
expected to absorb it by eliminating per-round refine setup
entirely — that attribution is assigned to B explicitly. The
evaluation itself is legitimate computation; the cost problem is
that 349 obligations × (setup + normalization of overlapping state
data) pays the fixed costs 349 times. [A2] One measured failure
sits OUTSIDE this taxonomy: r257 (case-at-cell timeout, "possibly
conv-conditioned") is UNCLASSIFIED and carries a PERF-0/1 triage
obligation; until it is placed, the "top three cost centers"
coverage claim has a declared hole. The pause record again
supplies the counterfactual: whole-loop fused lemmas over the same
rounds check in seconds. Granularity, not evaluation, is the lever.

**CC3 — Per-program supply as such.** P02 (10 lines of C) required
generating, elaborating, and kernel-checking 349 program-specific
facts before its proof could start. Even at perfect per-fact cost
this is O(rounds × paths) per program — the supply's *existence* at
round granularity is the scaling ceiling (uri.c functions would be
thousands of facts). The donors have no analogue of this layer at
all (C1): their per-program content is the program's syntax walk.

Not cost centers (checked): statement-text size (named constants
already; generator hash-consing did its job); kernel checking of
CORRECT terms (fast throughout); Lake overhead (minor).

---

## 3. The fix at the Iris level — mechanisms, classically named

Ordered by depth. A/B are completion-grade (P02); C is the real fix
the operator's "AT THE IRIS LEVEL" constraint names; D/E/F are
supporting infrastructure.

**A. Committed-choice dispatch, completed everywhere** (classical:
syntax-directed / committed-choice proof search; donor: Lithium L1).
The generator already emits per-variant deterministic dispatch (op +
verdict read off the round's redex diff); the stepper already
pre-pins family slots first-order. Finish the discipline: no `first`
over candidates anywhere a discriminating syntactic key exists; the
round tactics select their leaf by the same diff-reading the
generator does. [A4] The spec ENUMERATES the dispatch key inventory
down to the ARM-FORM level r127 needed: op × verdict × arm form
(primitive `PEconv_int` vs call-form conv) — the r127 class fails
one level BELOW the op/verdict keys the generator reads from the
redex diff, so the key set must discriminate there. Legitimacy: rule
selection by syntax is
semantics-neutral — it changes which proof is *attempted*, never
what is proved. Effect [A4 precision]: A+D JOINTLY kill CC1 — A
alone kills the r12 class (backtracker → committed single variant,
measured ~50 s); for the r127 class committed choice helps only if
the key inventory discriminates at the failing level, and a wrong
single commitment still grinds slowly unless D makes wrong-shape
failure cheap. Price: S (the generator half is done; tactic side
mechanical). Does NOT fix: per-round evaluation cost (CC2).

**B. Fusion of straight-line obligations** (classical [A9]: derived-
rule composition at Floyd-style cut points — Floyd 1967 cut points +
the Hoare 1969 sequence rule applied at generation time, the lineage
already carried verbatim in SegRun.lean; "staging" dropped as the
headline name per review A9; the donors' obligation unit —
their automation has the kernel check per-function terms whose
straight-line segments are single derivations, never per-instruction
lemmas). Make BLOCK-granular fused facts the generated supply's
default unit — one lemma per straight-line run between cut points,
proved by one composed evaluation (the intermediate states computed
once inside a single normalization, not re-established per round);
per-round facts remain only where a cut point needs an anchor.
Legitimacy: `SegStep.trans` (the Hoare sequence rule) already
composes these soundly; fusing the *supply* is applying the same
once-proved composition at generation time; semantics-preserving by
the existing composition theorem. Empirical warrant: p02add_evalR /
p02conv_chainR (whole-loop facts) check in seconds vs 16M+ for their
split forms. Effect: CC2 shrinks by roughly the block factor (P02:
349 → ~40-60 facts; the SLOW register should empty). Price: M
(generator emits fused statements + the fused-fact tactic face; the
frontier rounds' proved whole-loop lemmas are exactly this shape
already). Does NOT fix: the per-program supply's existence (CC3).

**C. THE IRIS-LEVEL FIX: a per-construct step-characterization
package — the derived small-step presentation of the definitional
interpreter** (classical, precisely named per [A7]: the derived
relational presentation (introduction/inversion lemmas) of a clocked
definitional interpreter — functional big-step lineage
(Owens–Myreen–Kumar–Tan, ESOP 2016); Iris-native precedent, named
per reuse-discipline point 4: HeapLang's `PureExec`-class
per-construct step characterization, proved once and consumed by
`wp_pure`-style tactics; donor: this is exactly what makes Caesium
goals small —
C1 — obtained for our semantics as THEOREMS instead of by fiat).
Today, per-program round equations exist because the WP rules'
premises demand "this round is this step" at near-concrete states.
Replace that demand: prove, once per Core construct, a
characterization lemma quantified over the V1 fragments — "when the
control token is at an `Eif` whose discriminant reads cell x, and
`envIs x v` holds, the round steps thus" — i.e., the step relation
our rules consume becomes a package of ∀-fragment lemmas (the
inductive-relation view of the interpreter, derived and proved
sound, never trusted). Per-program content then shrinks to the
program's own syntax walk (which constructs appear where — small,
computed once by the stepper from the pinned Core term) plus block
anchors where genuinely needed (guard verdicts at path conditions).
Legitimacy: these are ordinary theorems about the interpreter,
strictly MORE symbolic than the round equations they replace
(catechism §VI: more ∀, less ground); every program gets every
construct lemma for free — the definition of amortization. This is
also, note, what assessment component C ("per-construct symbolic
rules") always specified; the per-program round supply was V2's
interim scaffold, and this retires it. Effect: kills CC3 (supply
becomes O(blocks) anchors), further shrinks CC2 (evaluation happens
inside once-proved construct lemmas). Price: M-L — [A6 reworded] it
is assessment-Component-C completion (whole-project-assessment-
disposition §B2, "per-construct symbolic rules … the heart",
chartered at V2 and left incomplete by the V2/V2b interim round
supply); the committed record has V3a = Component D (scalar loops +
variant rule, `notes/2026-08-27_infrastructure-plan.md:271`), so C
FRONTS V3a rather than being an already-promoted V3a item — not new
scope either way. [A10 exit ramp] On probe no-go, B-granularity
fused supply remains the default and V3a proceeds on it: the fold
must not couple V3a's fate to C's probe — a no-go is a park with a
price, never a blocked arc. Risk: the fused-interpreter step characterization at
fully symbolic fragments is exactly where V1/V2 paid their walls
(the F-technique, instance-generic legs); the construct lemmas
inherit those solved patterns but at one more level of generality —
the honest unknown, to be probed on 2-3 constructs before committing
the package (PERF-2's first exit).

**D. Opacity as completed interfaces** (classical: abstraction
barriers / sealed modules; donor: L3, Caesium's `Typeclasses
Opaque`). Where a symbol's lemma interface is COMPLETE (the arena
constants once B/C land; interpreter internals the construct
package fully characterizes), mark it irreducible so unification
cannot fall into normalizing it. Governing rule, per the operator's
ruling: opacity is legitimate ONLY with the completeness property —
if any proof needs the unfolding, that is an interface gap to close
with a lemma, never a transparency toggle. (This is the disciplined
opposite of unfold-order steering — §4.) [A8] Two enforcement
notes: (i) the loud failure invites the quiet local fix — a worker
flipping transparency back locally (`attribute [local …]`-class
reversal) is exactly the forbidden toggle; the reversal is made
MECHANICALLY DETECTABLE (a greppable ban on re-transparency of
sealed names in proof files + a sealed-name registry, implemented as
at most one grep line riding an existing gate script per the
operator's light-enforcement calibration). (ii) Lean's
`irreducible` binds the ELABORATOR, not the kernel — kernel defeq
ignores it; loudness holds where it matters (elaboration), but
kernel-side normalization of sealed symbols reached by other routes
is a perf residue to measure in PERF-0/3, not a soundness gap; D is
not a kernel-level barrier. Effect: converts CC1-class
accidents into immediate loud failures instead of silent grinding.
Price: S, after B/C. Risk: none if the completeness rule is
enforced; the build itself enforces it (a needed-unfold fails loudly).

**E. Parallel builds via the module DAG** (classical: build-level
parallelism; no proof content). The chunk modules are already
independent; a single Lake invocation over the DAG with a measured
2×48G memory envelope. Price: S (ONE supervised experiment,
operator-authorized in the PERF-0+1 executing brief — the
authorization cite A6 asked for). [A11] Memory reconciliation with
the capped-64G default and the [USER 2026-08-26] box-OOM rulings:
explicit CERB_MEM_MAX=48G per job (2×48G = 96G total exposure — a
box total-memory check precedes the run), supervised, run ONCE,
staggered against all other heavy lanes, reported either way.
Bounded by memory until B/C shrink per-job
footprints.

**F. A timing lane** (donor: L6, coq-speed). A Tier-C reporting
instrument: per-module wall/heartbeat numbers pinned per commit, so
regressions are data. Price: S. (Also the home for PERF-0's
baseline.)

Explicitly REJECTED at proposal time (the forbidden class):
unfold-order steering in any form; transparency toggles without the
completeness property; budget raises (standing ban); any
`ofReduce*`/native path (banned); caching against the
certification-integrity rules; weakened lemma statements ("checking
less"). Deferred pending a measured probe and separate discussion:
`Decidable`-reflection evaluation of ground steps (kernel `decide`
is sanctioned by the ACL2Lean-pattern rulings, but its win over
whnf at our term shapes is unmeasured — a PERF-0 datum, not a plan
item).

## 4. The seal-era machinery, classified (the mandated case study)

Hypothesis verified with one amendment. In classical terms the seal
era was three things entangled:
1. **Sharing / let-abstraction** (naming intermediate states) —
   legitimate, classical, semantics-preserving; survives today as
   named constants and is extended honestly by §3.B/D.
2. **A groping toward staging/obligation granularity** ("keep every
   kernel obligation shallow") — the legitimate insight it almost
   had; §3.B is that insight done properly (compose by a proved
   rule, choose the obligation unit deliberately).
3. **Unfolding-order steering inside kernel whnf** (checkpointing
   the kernel's evaluation to dodge its recursion guard) — the
   illegitimate core: not memoization (nothing reused), not
   abstraction (no interface — proofs still depended on unfolding
   happening, just in a controlled order), but coupling to the
   evaluator's operational behavior with no model of it. This is
   the exact referent of the operator's prong-2/forbidden clause,
   and its tell was already documented at the time: "learning the
   abstraction by collision."
The discipline this classification yields: every performance
mechanism must be one of the named classical moves (sharing,
staging, committed choice, abstraction barriers, parallelism,
measurement) — and anything whose effect one can only explain by
narrating evaluator behavior is rejected on sight.

## 5. Slice plan (measurable exits; metrics = chunk-minutes,
heartbeat budgets, worker tokens/hour)

- **PERF-0 — baseline** (S; first action after the V2b park
  completes): profile ≤8 representative declarations (fast round,
  SLOW round, composite-arena round, an r127-class decl with the
  wrong vs the right lemma, one fused whole-loop lemma, one
  chunk); [A2] TRIAGE r257 — place it in the CC taxonomy or name a
  new cost center; land the F timing lane with those numbers
  pinned. Exit:
  cost attribution (elaborator vs kernel vs instance) is data.
- **PERF-1 — completion grade: A + B on P02** (M): committed-choice
  everywhere (key inventory down to arm form, per A4); fused supply
  as default; rewire the 6 frontier rounds
  through the already-proved whole-loop lemmas; P02 proves; B/C/D
  chunks land or are replaced by fused equivalents. Exits: P02 at
  the frozen statement (trio cones); [A5] the ≤ ~5 min exit is
  defined as the COLD, serial, capped (48G) rebuild wall time of
  the FULL P02 supply closure — Rounds base + all chunks +
  P02Guard — measured in the F timing lane under pinned
  conditions (never warm-cache, never with cost shifted into
  unmeasured modules); SLOW register ≤ 5 named entries, each with a
  named remover; no 64M
  anywhere; per the honest-gaps rule the proof-size registration
  decision for P01/P02 files is made with the new numbers. [A11]
  Caller-protocol boilerplate (~150-175 lines/program, "the honest
  next fusion target" — slice record §2) is SCOPED OUT of PERF-1
  (proof-text mass, not build time) but explicitly on the table for
  the PERF-1 proof-size registration decision and any throughput
  reading. [A11] The generator (gen_p02.py, currently a container-
  level instrument) is COMMITTED/VERSIONED before fused supply
  becomes the default path — deterministic regeneration is an audit
  requirement.
- **PERF-2 — the Iris-level fix: C, probed then landed** (M-L;
  fronts V3a): probe the construct-characterization shape on 2-3
  constructs (pure-eval, `Elet` bind, `Eif`) — measured go/no-go
  (exit ramp per A10: no-go ⇒ B-granularity supply stays default,
  V3a proceeds on it) —
  then the package for the current vocabulary; stepper consumes
  construct lemmas + syntax walk; T1/P01/P02 supplies regenerate at
  anchor granularity. Exits, tightened per [A1]/[A5]:
  - ANCHOR is DEFINED: a generated fact is an anchor iff it cites a
    cut-point reason drawn from the program's SYNTAX (branch /
    loop-head / call / terminal), is stated over V1 fragments with
    quantified data values, and contains no ground successor state.
    Ground-state supply facts are per-round facts whatever they are
    named; the B0 concrete-input statement check applies to supply
    files as the mechanical backstop.
  - Structural anchor bound, fixed IN ADVANCE of regeneration:
    #anchors ≤ k·(#branches + #loops + #calls + 1) with k = 2.
  - The NEW scalar program is PRE-REGISTERED before the construct
    package lands (the t6 never-seen-program precedent, arc-17) and
    includes at least one construct outside the probe set; it
    requires ZERO generated per-round facts (anchors only, counted
    against the bound).
  - Supply build for a P02-class program ≤ ~1 min; [A5] the
    tokens/hour exit is DEMOTED to a Tier-C reported indicator in
    the F lane (labeled derived, orchestrator-attributed;
    confounded by the probe-workflow switch) and REPLACED as exit
    by the build-latency criterion: no build on the proof-slice
    critical path exceeds ~5 min.
- **PERF-3 — D + E** (S): opacity with the completeness rule over
  the now-complete interfaces; the parallel-build experiment,
  measured. Exit: timing lane shows the deltas; any needed-unfold
  failure = an interface gap ticket.
- Then **V3a resumes** (loops), repriced DOWN: its supply burden
  becomes anchors + the construct package it now rides on.

## 6. Operator questions

1. **Granularity default**: approve block-fused facts as the
   generated supply's default unit (per-round only at cut-point
   anchors)? [Recommend yes — empirically warranted in-house.]
2. **PERF-2 as V3a's front**: it substantially IS the promoted V3a
   item + assessment-C completion — approve folding rather than a
   separate arc? [Recommend yes.]
3. **Opacity discipline**: approve with the completeness rule
   (needed-unfold = interface gap, never a toggle)? [Recommend yes;
   it is the donors' standing practice.]
4. **The `Decidable`-reflection probe**: run as a PERF-0 measured
   experiment (kernel decide is within the sanctioned pattern), or
   defer entirely? [Recommend: measure in PERF-0, discuss only if
   the numbers argue for it.]
5. **Timing lane**: approve as a Tier-C instrument? [Recommend yes.]

## 7. Amendment log ([AGENT 2026-08-28] — review A1–A11 folded in place)

Review: `notes/2026-08-28_proof-performance-plan-review.md`, verdict
SOUND-WITH-AMENDMENTS; each amendment below is BINDING and marked
`[An]` at its fold site in the text above.

- A1 → §5 PERF-2 exits: anchor definition (syntax-cited cut-point
  reason, fragment-quantified, no ground successor; B0 gate over
  supply files), structural bound #anchors ≤ 2·(#branches+#loops+
  #calls+1), pre-registered new program with an out-of-probe-set
  construct.
- A2 → §2: CC2 multiplier corrected to chain shape (r28/r29 vs
  r128/r129 control), chain-shape cost assigned to B; r257 added as
  unclassified with a PERF-0/1 triage obligation; "dominant" split
  worst-case (CC1) vs aggregate (CC2). Also §5 PERF-0 (triage item).
- A3 → §1 L1: `liFindHyp` candidate iteration acknowledged
  (interpreter.v:537-569); opacity-cheap failure cited as donor
  evidence for D (interpreter.v:543-549).
- A4 → §3.A: A+D jointly kill CC1; key inventory enumerated down to
  arm form (op × verdict × primitive-vs-call conv form).
- A5 → §5 PERF-1/2 exits: ≤5-min = cold/serial/capped full P02
  supply-closure rebuild in the F lane; SLOW register ≤ 5 named
  entries with removers; tokens/hour demoted to Tier-C indicator,
  replaced by the critical-path build-latency criterion.
- A6 → §3.C: "already-promoted V3a item #1" reworded (committed
  record: V3a = Component D; per-construct rules = assessment
  Component C); E's operator authorization cited (the PERF-0+1
  executing brief).
- A7 → §3.C: precise classical name (derived relational presentation
  of a clocked definitional interpreter, Owens–Myreen–Kumar–Tan
  ESOP 2016) + the Iris-native PureExec precedent named.
- A8 → §3.D: mechanically detectable re-transparency ban (one grep
  line on an existing gate + sealed-name registry, light-enforcement
  calibration); `irreducible` binds elaborator not kernel — perf
  residue to measure, not a soundness gap.
- A9 → §3.B: "staging" dropped as headline name; Floyd cut points +
  Hoare sequence rule at generation time is the classical anchor.
- A10 → §3.C + §5 PERF-2: exit ramp stated — probe no-go ⇒
  B-granularity supply remains default, V3a proceeds on it.
- A11 → §3.E + §5 PERF-1: 2×48G reconciled with the box-OOM rulings
  (explicit CERB_MEM_MAX, total-memory check, supervised, once,
  staggered); caller-protocol fusion scoped out of PERF-1 with the
  record cite but on the table for the proof-size registration
  decision; the generator committed/versioned before fused supply
  becomes the default path.

Catechism §VI self-check on this plan: every mechanism serves the
∀-statements (C makes rules MORE quantified); costs amortize (per
construct, not per program); lineages named throughout (Lithium,
Caesium, Hoare composition, functional-big-step correspondence,
module abstraction); nothing enumerates; nothing couples to
evaluator behavior without a model; failure modes are loud by
design (D's completeness rule, A's no-backtracking).
