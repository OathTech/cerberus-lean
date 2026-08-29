# Corpus-2 (the hunted tail) + the shakeout campaign — DRAFT v2

STATUS: DRAFT v2 — the step-3 adversarial review's revisions APPLIED
(verdict REVISE-THEN-FREEZE, all 8 ACCEPT, revisions textual:
notes/2026-08-29_corpus2-review.md; delta table in §8) + one
POST-REVIEW addition, p24 (awaiting the reviewer's DELTA PASS, §3a).
Pipeline: author → review → operator freeze sign-off; NOTHING enters
a repository before that — additions to the frozen corpus require
[USER] sign-off by the freeze rules regardless. Mandate [USER
2026-08-29, verbatim]: "a next step here is building a further corpus
intended to exercise these features. Go hunting, basically. We should
also exercise the existing features across some more small examples,
try to shake out bugs."

**CONTRACTS-PRIMACY acceptance framing** [USER 2026-08-29, postdating
the v1 draft — acceptance wording only; the .c texts and the frozen
harness-statement shapes do not change]: each corpus-2 row's
DELIVERABLE is the **∀-context contract** — the FnSpec over quantified
ambient state (arbitrary consistent supply position, arbitrary frame
heap, arbitrary call depth: "no privileged boot context; main is a
function that might get called after a long execution period") — with
the frozen harness theorem as its **derived corollary**. The corollary
remains the frozen acceptance text; the contract is what the build
must produce, and a row is not passed by a proof that only reaches the
corollary without the contract.

Draft C sources: `notes/corpus2-draft/p16..p23.c` (8 reviewed
programs + `p24` post-review draft; every function ≤ ~12 LOC, all
scalar-input → the call-boundary route throughout: NO splices needed
except p24's marked failure-choice slot). All samples ORACLE-EXECUTED
at draft time and independently RE-RUN by the reviewer: 8/8
`Specified(0)` (+ p24 at draft, §6) — the corpus-1 H5 lesson applied
by execution, not claim. Corpus-1 discipline applies in full
(catechism; canonical-property theorems; §0 anti-brute-force bounds;
structurally-forcing designs; per-program dishonest-pass analysis —
now in-file for all rows per review C6; license attribution).

---

# PART 1 — CORPUS-2: THE HUNT

## 1. Target list, provenance, and the priority adjudication

Sources: the capability roadmap's coverage table (its `post-corpus
(flagged)` rows), the corpus-1 Q2 deferral list (recorded as
decisions), and the uri.c census — whose §9 closed-universe note is
the decisive priority instrument: **uri.c contains 90 goto sites but
ZERO unions, function pointers, switch statements, recursion, floats,
varargs, or dynamic structures.** So "what uri.c demands" and "what
the kernel targets demand" split the tail differently, and the hunt
adjudicates each feature honestly:

| Feature (table row) | Demanded by | Class | Program |
|---|---|---|---|
| goto / general labels (E3, rank-9 census idiom) | **uri.c: 90 sites** | **MINIMUM-2** | p16 |
| ptr↔int casts (PNVI) | **kernel (pKVM addr arithmetic)**; RefinedC intptr.c class; not uri.c | **MINIMUM-2** | p17 |
| unsigned wraparound ring | **kernel (pKVM/WireGuard hash targets** — corpus-1 Q2's own note); not uri.c | **MINIMUM-2** | p18 |
| mutable globals/statics across calls | **kernel (pKVM lane**, Q2 note); uri.c's cleanup-flag field is the read-only cousin | **MINIMUM-2** | p19 |
| switch with fallthrough | kernel style (uri.c has NO switch) | EXPLORATORY | p20 |
| unions (non-punning) | kernel, moderate (uri.c none) | EXPLORATORY | p21 |
| function pointers / indirect call | libxml2 SAX layer + kernel ops tables (uri.c none) | EXPLORATORY | p22 |
| true Eunseq / proof-side ND | nothing near-term; the first ND proof row, cmm-adjacent | EXPLORATORY | p23 |
| floats | **nothing** (uri.c none; pKVM-hyp avoids FP) | **EXCLUDED** — recommend no program; the tests/float differential lane validates the semantics; proof-side floats wait for a demanding target |
| varargs / snprintf | uri.c's 2 snprintf sites only | **EXCLUDED** — realistic route is snprintf-as-contracted-primitive at the capstone, not a varargs proof theory now |
| unresolved SYMBOLIC may-alias | first memmove-shaped target (corpus-1 deferral) | **EXCLUDED here** — needs V5+ machinery; stays the recorded deferral it already is |
| symbolic fn-ptr ARGUMENT with contract assumption (RefinedC binary_search class) | libxml2 SAX layer / kernel ops tables | **EXCLUDED here** (review C3 addition) — unreachable in the scalar-harness style (a fn-ptr cannot enter the call boundary); recorded deferral with named trigger; p22 is near-maximal within corpus rules |
| failable allocation (malloc null) | P13's design-dependent clause, resolved by the malloc-null ruling | **p24 DRAFT** (post-review; delta pass pending) |
| concurrency (par/wait/RMW) | — | **DEFERRED BY RULING** (cmm; untouched) |

Census-driven idioms that are COMPOSITIONS of covered/planned
vocabulary — by-reference cursors (P4), backtracking (E4),
realloc/grow (A3 = libc over alloc+memcpy+free), strdup family,
free-then-assign (S1) — are deliberately NOT corpus-2 construct rows:
they are capstone-campaign material (program-level rehearsal over
vocabulary the V3b–V5 tiers land), listed here so the review can
check the boundary was drawn honestly.

## 2. New reasoning families forced (extends the corpus-1 matrix)

G1 general-join labels (a label with MULTIPLE predecessors —
loop back-edges never produced this; per review C1, the VOCABULARY is
forced, join-once composition exercised-not-forced at 2 predecessors)
· G2 provenance-carrying ptr↔int casts · G3 defined-wraparound (the
UB machinery must NOT over-fire) · G4 global/static footprint IN
CONTRACTS · G5 switch-provenance dispatch ladder + fall-through at
elaborated labels — G1 at the switch construct (review C2: the switch
elaborates to if-dispatch + save/run labels; NO Ecase node exists;
distinct as an elaboration-provenance rehearsal, not as new Core
vocabulary) · G6 union member discipline (read-what-you-wrote per
path) · G7 per-arm contract selection at a pointer-valued callee
(devirtualization-by-case-split is the intended proof — review C3) ·
G8 proof-side nondeterminism (outcome-set singleton across ALL
interleavings).

| # | program | G1 | G2 | G3 | G4 | G5 | G6 | G7 | G8 | + corpus-1 families |
|---|---|---|---|---|---|---|---|---|---|---|
| p16 | goto_ladder | ● | | | | | | | | F1, F13 |
| p17 | ptr_roundtrip | | ● | | | | | | | F7 |
| p18 | wrap_mix | | | ● | | | | | | F12-dual |
| p19 | static_tick | | | | ● | | | | | F5 |
| p20 | switch_fall | ● | | | | ● | | | | F1 |
| p21 | union_pick | | | ◐ | | | ● | | | F1, F10-adjacent |
| p22 | fnptr_apply | | | | | | | ● | | F1, F5 |
| p23 | unseq_pair | | | | | | | | ● | F12 |

Every G-family has a row; G1/G2/G3/G4/G6/G7/G8 are forcing in the
strict sense; G5's distinct content is the elaboration provenance and
the behaviorally-forcing fallthrough (a disjoint-arms prover derives
2→1 against the spec's 2→2), stated at that honest strength per
review C2. (p21's G3 ◐: the else-arm's unsigned reinterpretation
exercises the ring conversion.) p24 (draft) adds the failable-alloc
disjunction-contract family — see §3a.

## 3. The programs (theorem · bounds · dishonest-pass)

House theorem shape as corpus-1 §2 (canonical property, outcome-SET,
consistency-freshness faces, call-boundary quantification). Bounds
per the anti-brute-force ruling — full inventory:

- **p16 goto_ladder** (fresh; uri.c E3 shape). ∀ a b, a,b ≤ INT_MAX/2
  (derived: success-path sum), lower full: outcomes = {Specified
  (a<0 → −1; b<0 → −1 [after cleanup]; else a+b)}. Review C1 honest
  form (in-file): forces the general-label/fall-through VOCABULARY
  (Erun to a non-loop parameterized label; fall-through entry into a
  save block — Core-verified two-in-edge topology, no tail
  duplication); join-ONCE composition is exercised, not forced, at 2
  predecessors — per-path stepping of the 2-statement label body is
  structure-proportional and legitimate; the amortization forcing is
  uri.c's ~40-in-edge `done`, for which this is the miniature.
- **p17 ptr_roundtrip** (RefinedC examples/intptr.c lineage, BSD;
  text fresh). ∀ v full int range: outcomes = {Specified v}. The
  theorem never mentions an address — it forces the PNVI cast-memop
  vocabulary (IntFromPtr/PtrFromInt/PtrValidForDeref, Core-verified
  on the only path; ∀-seed quantification blocks any
  concrete-address route), not address observability. Review C4
  honesty (in-file): this is the EASY face of PNVI — the recovery is
  unambiguous by construction (exactly one live exposed allocation);
  multiple exposed candidates, one-past pointers, dead-allocation
  recovery, and udi disambiguation all stay deferred. LP64 noted
  (unsigned long = 8 bytes, no truncation).
- **p18 wrap_mix** (fresh; Knuth constant). ∀ a b full uint range:
  outcomes = {Specified (mixModel a b)}, mixModel = the same
  mul/xor/shl/add over Nat mod 2³². Dishonest-pass: nothing to
  unroll (straight-line); the content is that FOUR wrapping ops
  discharge with NO UB side condition firing — an over-fire shakeout
  of the guard machinery as much as a capability row. Review C5
  width note (in-file): the row is 32-bit; WireGuard's siphash is
  u64 — the law class is expected width-generic (mod-2^w, w a
  parameter) so the kernel justification carries; a u64 row is
  flagged for table maintenance (§4), not drafted.
- **p19 static_tick** (fresh). ∀ x ≤ INT_MAX−2 (derived): outcomes =
  {Specified 1}. Forces: the callee contract must carry the static
  cell (`calls ↦ c` pre / `calls ↦ c+1` post) and the caller
  composes it TWICE — globals-in-contracts, V4-dependent.
  Dishonest-pass: inlining both calls is the settled P09 situation —
  the in-file note now exists (review C6 closed); the result being
  x-independent is the point (the SPEC forces reasoning about the
  counter's thread, not the argument). Review C5 sliver, named: the
  elaboration emits a real `glob calls` section, so the harness
  protocol needs glob-INIT stepping + globals in EnvHyp before
  contracts mention them — priced S on top of V4 (§4).
- **p20 switch_fall** (fresh). ∀ c full range: outcomes = {Specified
  (2→2, 1→1, 0→5, else −1)}. Review C2 factual relabel (in-file):
  the switch elaborates to an if-dispatch ladder + per-case save/run
  labels + a break label — NO Ecase node exists; the row's content
  is the switch-provenance elaboration shape (G1 at the switch
  construct) and the behaviorally-forcing fallthrough (a
  disjoint-arms prover derives 2→1 against the spec's 2→2).
  Distinguishable from P15's disjoint-arm switch by the shared-body
  spec values. (The roadmap table's "switch → PEcase/Ecase chains"
  line flagged as inaccurate for this shape — table maintenance.)
- **p21 union_pick** (RefinedC simple_union.c lineage, BSD; text
  fresh). ∀ tag x full range: outcomes = {Specified (tag≠0 → x;
  else (x mod 2³²) >> 1)} — the int conversion in range by
  derivation (quotient < 2³¹, inline). Vocabulary precision
  (review): the UNION MEMBER vocabulary — memberof/member_shift at
  union type + union-typed create/store/kill (incl. the whole-union
  Unspecified-store init, Core-verified) — not the PEunion ctor.
  Per-path read-what-you-wrote — no punning UB; punning rows stay
  deferred.
- **p22 fnptr_apply** (RefinedC cmp-pointer class, BSD; text fresh).
  ∀ sel full, x ∈ [INT_MIN/2, INT_MAX/2] (derived to cover both
  callees): outcomes = {Specified (sel≠0 → x+1; else x+x)}. Review
  C3 honest framing (in-file): the intended proof IS
  devirtualization-per-arm — after the case-split each arm's callee
  is a concrete Cfunction value consuming its own contract; in Core
  every call is already ccall-of-a-Cfunction-value, so the
  "indirect" rule largely rides V4's direct form. What the row
  genuinely buys: fn-ptr values through a store/load roundtrip (an
  fn-ptr-typed CELL — new memRW content), the `cfunction()` memop,
  per-arm FnSpec selection. The genuinely-new class it does NOT
  touch — a fn-ptr arriving as a QUANTIFIED ARGUMENT with a contract
  assumption — is added to the recorded deferral list (§1) with its
  SAX/ops-table trigger.
- **p23 unseq_pair** (fresh). ∀ x, |x| ≤ (INT_MAX−6)/4 = 536870910
  (derived): outcomes = {Specified (4x+6)}, no UB. The two inner
  assignments are unsequenced but target DISTINCT objects (defined;
  C11) — the theorem's outcome-SET must be proved a singleton over
  ALL runner interleavings: the first proof-side ND row. Honest
  price flag: this needs a genuinely new rule class (ND-branch
  proof rules over End/Eunseq); it is in the draft to make the gap
  concrete, not because it is near.

## 3a. p24 h_malloc_cell — POST-REVIEW DRAFT (delta pass pending)

Added after the step-3 review per the operator's malloc-null /
F1-rescope ruling [USER 2026-08-29]: P13's failable sibling, with
allocation FAILURE entering as CHOICE-STREAM DATA (const-embedding —
no semantic ND added; `fail_choice` is a marked spliced slot, the
corpus's only splice). Design: an `h_malloc` wrapper whose contract
is the classic failable-malloc DISJUNCTION — `{emp} h_malloc(n)
{r. (r = NULL ∧ fail-choice) ∨ (r ↦ n uninit bytes)}` (VST/CN malloc
contract lineage) — consumed by `cell` under a case-split on the
disjunction, BOTH ARMS LIVE as quantified data (P13's
design-dependent F1 cell realized unconditionally here). Theorem
(corollary form): ∀ v ≤ INT_MAX−1 (derived), ∀ c ∈ {0,1} (structural,
the P03-alias pattern): outcomes = {Specified (c=1 → SENTINEL; else
v+1)}, no UB, no leak on either arm. Contracts-primacy applies as
everywhere: the deliverable is the contract pair; the harness theorem
is the corollary. Depends on V5 + the alloc-ND evaluation's P13
decision (this row is that decision's failable face made
choice-determined). Oracle sample (libc mode): `Specified(0)` at
draft. AWAITING the reviewer's delta pass before any freeze scope
includes it.

## 4. Coverage delta (against the roadmap's table)

If frozen and proved, corpus-2 closes the table's post-corpus flagged
rows: `goto (general)` (p16), `casts (ptr↔int)` (p17 — the easy PNVI
face, per its in-file note), unsigned-ring arithmetic (p18, a new
Level-2 row the table folded into "covered class" — split out
honestly), globals/statics (p19, a Level-2 row the table did not
list — flagged for the table's maintenance), `switch` richness (p20 —
whose table line "switch → PEcase/Ecase chains" is itself inaccurate:
the elaboration is if-dispatch + labels; table maintenance), union
MEMBER vocabulary (p21 — memberof/member_shift + union-typed
create/store, not the PEunion ctor), `function pointers` (p22 — the
value/store-load/cfunction face; the quantified-argument class
recorded deferred), `End/Eunseq proof-side` (p23), failable
allocation (p24, draft). Remaining open tail after corpus-2: floats,
varargs, symbolic may-alias, symbolic-fn-ptr-argument (all excluded
with rationale + named triggers, §1) and concurrency (ruling).
**Scope of the claim (review C7): at the TABLE'S row granularity, no
construct row is then unowned — but the table itself has holes, and
three are flagged here for its maintenance: BITFIELDS (uri.c has
none, census §9, but kernel code uses them pervasively — the same
kernel-priority logic that promoted p18/p19 will apply at the kernel
rung), 64-BIT ring arithmetic (p18's width note), and ENUMS (cheap,
elaborate to ints).** No new program is demanded by the flags
(corpus-as-scope-fence stands); the flags keep the boundary honest.

Build-tier attachment (when each row becomes provable — for the
roadmap's threading, not new machinery beyond what's listed): p16,
p20 → the landed save/run + REBIND vocabulary plus fall-through-entry
and forward-run segLink content (EARLY: attachable right after the
bridge/polish slices — cheapest new capability per row in the draft;
review C9: this is a claim about the engine that the first attachment
will test, priced as such); p18 → unsigned eval-law widening (S,
width-generic per the in-file note); p17 → cast memop vocabulary
(new, S-M, PNVI-careful, easy-face only); p21 → union member views
(V3b-adjacent; note the whole-union Unspecified-store init touches
memRW at union type — slightly more than field views); p19, p22 → V4
+ globals-in-contracts (S on top of V4) + the glob-INIT protocol
sliver (S — named per review C5); p23 → ND-branch rules (its own
small design item, cmm-adjacent; unseq-split + same-outcome join is
the minimal form); p24 (draft) → V5 + the alloc-ND design decision.

## 5. Self-audit (the corpus-1 four questions)

Small but challenging: every function ≤ ~12 LOC; each isolates one
tail construct with a genuinely forcing spec. Actually exercises the
claimed families: the G-matrix rows are checked per-program in §3's
dishonest-pass notes (sharpest: p16's two-predecessor label, p22's
data-dependent contract dispatch, p23's all-orders singleton). On the
way to a verifier: corpus-2 + corpus-1 = every C feature row owned,
excluded-with-rationale, or ruled-deferred (§4). Concrete-input
residue: none — all theorems ∀ over full/derived ranges (§3 bounds;
no literal-pinned inputs; main() bodies are oracle samples on the
test ledger). Enumeration inconceivable in every domain (smallest:
p23's ~2³⁰).

## 6. Oracle sample results

`--exec --batch` via the house oracle recipe: p16–p23 ALL
`Defined {value: "Specified(0)"}` at draft time — including p17's
PNVI cast roundtrip (defined under the default provenance model, as
designed) and p23's unsequenced pair — and independently RE-RUN by
the step-3 reviewer (8/8 reproduced, `--nolibc`). p24 (post-review
draft): `Specified(0)` at draft, libc mode (malloc). The freeze-time
re-run of the full set (incl. p24 if admitted) remains a freeze
obligation (corpus-1 §6a pattern; the reviewer's re-run stands as
review evidence, not as the freeze run).

## 7. Open questions for the operator (at freeze)

1. **Freeze scope**: freeze MINIMUM-2 (p16–p19) now with
   EXPLORATORY (p20–p23) as a labeled annex frozen together, or
   freeze all 8 as one corpus-2? (Recommend: all 8, one review, one
   freeze — the annex split adds process without changing content;
   the tier attachment in §4 already sequences the work.)
2. **The exclusions** (floats, varargs, symbolic may-alias):
   confirm as recorded decisions (recommend yes — no target demands
   them; each has a named future trigger).
3. **p23's price honesty**: keep it in corpus-2 (defining the
   ND-rule gap as a frozen target) or move it to the cmm arc's
   corpus (recommend: keep — it is sequential C, defined behavior,
   and the smallest possible statement of proof-side ND; the cmm arc
   inherits it as its warm-up either way).
4. Numbering/freeze mechanics: p16–p23 (+ p24 if its delta pass
   admits it) extend the corpus-1 manifest (same hash-gate, same
   README terms) on sign-off, with the corpus-1 freeze obligations
   applied (freeze-time sample re-run; the C6 sample labels landed
   before hashing) and the MINIMUM-2/EXPLORATORY class labels
   CARRIED IN THE MANIFEST — noting (review C8) that MINIMUM-2 means
   "minimum for the TARGET SLATE (uri.c OR kernel)", a broader
   criterion than corpus-1's uri.c-graduation MINIMUM; the manifest
   labels keep that visible.

Review recommendations on Q1–Q4 (for the operator's decision, §5 of
the review): Q1 all-8-one-freeze — reviewer AGREES; Q2 confirm all
three exclusions (+ the C3 fn-ptr-argument addition) — reviewer
AGREES; Q3 keep p23 — reviewer AGREES, strengthened by the Core
verification; Q4 — reviewer agrees with the mechanics above.

---

# PART 2 — THE SHAKEOUT CAMPAIGN (existing features, more examples)

Purpose [USER]: "exercise the existing features across some more
small examples, try to shake out bugs." NOT new capability — edge
COMBINATIONS of covered vocabulary, each expected CHEAP (the m1 cost
class). Findings are engine/design bugs to fix, never proofs to
grind. The campaign DOUBLES as the polish basket's (B2) acceptance
measurement: post-basket, these programs must land near-free — their
recorded per-program costs ARE the basket's metric.

## Programs (14; s01–s12 loop-free, s13–s14 post-bridge)

| id | program | edge combination exercised |
|---|---|---|
| s01 | nested3 | 3-deep nested branches at symbolic (x,y) — path-condition stacking |
| s02 | branch_store | arms store DIFFERENT values to one local; join; reload — memory joins branch arms |
| s03 | tmp_swap | swap two locals via temp; spec = swapped difference — rebind/store chains |
| s04 | med3 | median of three — comparison-ladder combinatorics |
| s05 | abs_diff | \|a−b\| with derived two-sided overflow pre — guard ladders both polarities |
| s06 | neg_edge | guarded negation (x = INT_MIN branch-handled) — UB side condition discharged FROM the guard |
| s07 | dead_store | write-after-write same cell before load — store composition |
| s08 | interleave | two locals updated alternately ×3 — deep sequencing/rebind chains |
| s09 | via_ptr | p=&x; *p=v; read x — pointer-to-local aliasing. **FRONTIER PROBE label (review)**: the store's target address is a LOADED pointer value — the row most likely to touch un-landed vocabulary; an over-budget result here is the EXPECTED finding, not a campaign failure |
| s10 | cond_write | arms write DIFFERENT cells; both read after join — per-arm footprints reconciled at the join (the sharpest frame shake; frontier-probe pairing with s09) |
| s11 | same_cond_twice | two sequential ifs on one predicate — 2 INFEASIBLE paths; contradiction pruning (the arm must close by absurdity, cheaply) |
| s12 | guard3 | 3-deep && chain — short-circuit nesting depth |
| s13 | loop_edge (post-bridge) | while with trip count 0/1 boundary at symbolic n — empty-loop composition |
| s14 | two_accs (post-bridge) | loop with two accumulators — multi-cell invariant |

All statements quantified (∀ inputs, full/derived ranges — the
concrete-input ban gate applies to them like every slate row); all
sources fresh-written trivial C.

## Campaign rules

1. **Budget ([F5] form, review-corrected)**: per program, **spec +
   invariant declarations + ≤6 manual steps** — invariants are
   legitimate human content per the catechism and sit OUTSIDE the
   step budget (s13/s14 each carry theirs); registered facts ≤6 (the
   m1 class); user text at the m1 shape (verify_fn + case structure
   + arithmetic). Over-budget ⇒ PARK as a design/engine finding.
2. **Halt**: two consecutive over-budget programs HALT the campaign
   for an engine investigation (the [F5] mechanism).
3. **Findings discipline**: an expensive or failing shakeout program
   is a BUG REPORT (engine/design), filed and fixed — never ground
   past (species-3).
4. **B2 acceptance — the falsifiable form (review-corrected)**: the
   measurement is a pinned BEFORE/AFTER PAIR. BEFORE = the campaign's
   first run in the A2→A3 gap (rule 6), recording per program:
   manual steps, registered facts, guard-template lines, coda
   transcription steps, wall-clock. AFTER = the re-run once the
   polish basket (B2) lands. The basket's acceptance = the DELTA on
   exactly the components B2 claims — guard-template lines → ~0
   (the minter), coda transcription steps → ~0 (the fusion) — PLUS a
   stated absolute post-basket budget: every s-row within rule 1's
   budget with zero per-program guard-template text. Without both
   runs recorded, the "doubles as acceptance" claim is unfalsifiable
   and must not be made.
5. Batches ≤5, Tier A green per batch, one commit per batch, brief
   interim per batch (the R6-era protocol).
6. **Sequencing**: thread A post-bridge (the roadmap's A2→A3 gap or
   right after A3); note for the orchestrator: s01–s12 are loop-free
   and MAY interleave earlier if a thread-A gap opens.
7. **ONE campaign registry (review; the coherence rule — leave one
   route)**: this Part-2 list is the covered-vocabulary shakeout
   registry and SUPERSEDES the pre-restart R6 census-plan's
   EASY/EDGE territory for that purpose. The R6 census-plan's
   CENSUS-tier programs (c1–c14, the uri.c idiom set in the
   pre-registered census doc) are NOT shakeout — they need V3b+
   vocabulary and remain the capstone-campaign material, attached to
   their tiers, governed by the pre-registered census. Exactly one
   registry per purpose; both recorded here.

---

## 8. Delta summary — step-3 review findings × disposition (v2)

| Finding | Disposition |
|---|---|
| C1 p16 join-once overclaim ("P09-class") | APPLIED — in-file + §2/§3 honest rewrite: vocabulary forced; join-once exercised-not-forced at 2 predecessors; uri.c's ~40-in-edge `done` named as the real forcing; "P09-class" dropped (it dodges no contract). The optional acc-dependent-continuation strengthening NOT taken (the reviewer's own analysis: cannot force join-once at n=2 — the note is the fix) |
| C2 p20 "Ecase" factually wrong | APPLIED — relabel everywhere (in-file, §2 G5, §3, §4): if-dispatch ladder + save/run labels, zero Ecase (reviewer-verified); G5 = switch-provenance G1; behaviorally-forcing fallthrough stated; roadmap-table line flagged inaccurate (maintenance) |
| C3 p22 devirtualization honesty | APPLIED — in-file + §3: devirtualization-per-arm IS the intended proof; "constant-folding impossible" overclaim removed; genuine buys enumerated (fn-ptr cell, cfunction memop, per-arm FnSpec); symbolic-fn-ptr-ARGUMENT class ADDED to §1's recorded deferrals with SAX/ops-table trigger |
| C4 p17 easy-face of PNVI | APPLIED — in-file + §3: recovery unambiguous by construction; multiple-exposed/one-past/dead-recovery/udi all named deferred; LP64 word added |
| C5 p18 width / p19 glob sliver | APPLIED — p18 width-generic law-class note (u64 flagged for table maintenance); p19 glob-INIT protocol sliver named and priced S-on-V4 (in-file + §4) |
| C6 in-file discipline regressions | APPLIED — sample labels ("oracle differential sample only — NOT the theorem") on all 8 files + p24; p19's claimed anti-inlining note now exists; p20/p21/p23 dishonest-pass lines added in-file |
| C7 table-granularity + silent holes | APPLIED — §4 claim scoped to the table's row granularity; bitfields/u64-ring/enums flagged for table maintenance; no new program (scope-fence) |
| C8 MINIMUM-2 criterion broadening | APPLIED — §7 mechanics: manifest labels carry MINIMUM-2 = "minimum for the TARGET SLATE (uri.c OR kernel)" visibly |
| C9 pricing slivers | APPLIED — §4 tier attachment: p16/p20 EARLY claim marked engine-testable; p21 union-typed-store note; p19 glob sliver; p23 minimal-form note |
| Part-2 count | APPLIED — 14 |
| Part-2 budget rule [F5] form | APPLIED — invariants outside the step budget; registered-facts ≤6 retained |
| Part-2 B2 acceptance unfalsifiable | APPLIED — pinned before/after pair with named per-program quantities and the absolute post-basket budget; claim forbidden without both runs |
| Part-2 s09 | APPLIED — FRONTIER PROBE label (loaded-pointer store target), paired with s10 |
| Part-2 R6-plan relation | APPLIED — rule 7: one registry per purpose; shakeout supersedes R6 EASY/EDGE for covered-vocabulary shaking; R6 CENSUS tier remains the capstone material at its tiers |
| [coordinator] contracts-primacy ruling | APPLIED — header framing block: deliverable = ∀-context contract, harness theorem = derived corollary ("no privileged boot context"); .c texts and statement shapes unchanged; p24 carries the framing in-file |
| [coordinator] F1-rescope / malloc-null | APPLIED — p24 h_malloc_cell DRAFTED (§3a; failure as choice-stream data, both arms live, null ∨ points-to disjunction contract, VST/CN lineage; oracle-green libc mode); marked delta-pass-pending, outside the reviewed 8 |
