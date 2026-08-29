# Target-corpus review — adversarial professor pass (restart plan step 3)

Date: 2026-08-27. Author: [AGENT] adversarial reviewer (fresh eyes; did
not author the corpus). READ-ONLY pass, no builds; single write target =
this file. Instruments: the design catechism
(notes/2026-08-27_design-catechism.md §II canonical property, §III
forbidden list), the whole-project assessment
(notes/2026-08-27_professor-whole-project-assessment.md, esp. §2.6, §5),
donor exemplars read at deps/refinedc/examples/ and deps/cn/tests/cn/.
Corpus under review: notes/2026-08-27_target-corpus-draft.md +
notes/corpus-draft/p01..p14*.c.

Operator ruling received mid-review, binding here (relayed verbatim in
part): "we don't want to end up in 'gate grind' — mechanical gates can
just pile up. Let's just get the corpus figured out." Consequences
applied throughout: fixes below prefer statement/precondition changes
and structurally-forcing example design; inline documentation notes
where structure cannot force; NO new per-concern mechanical gates are
proposed (the chartered concrete-input ban gate, assessment §2.6/B0, is
the one load-bearing trust gate and it is already planned — nothing
here adds to it). Author's Q3 is SETTLED by this ruling (§7).

---

## 0. Verdict

**Corpus verdict: REVISE-THEN-FREEZE.** The corpus is aimed at exactly
the right thing — every program is small, every theorem is a genuine
∀-statement in the canonical shape, no theorem pins an input literal,
and the family matrix is (mostly) honest. Where it is right it is
plainly right: P01, P02, P11 are excellent forcing programs; the
outcome-SET statement form is stronger than the catechism's minimum;
the "0 of 14 provable today" table (draft §4) is the corpus doing its
job. But the review found one theorem that is FALSE as stated (P13),
one with a UB hole in its precondition (P09), one whose sample
instance is wrong (P05 — evidence the samples were never executed),
one program whose entire claimed family is dishonest-passable by
13-point enumeration (P10 — a finite-sample theorem in ∀-costume),
and a corpus-wide dishonest-pass channel (CAP=8 makes bounded
unrolling and concrete-skeleton enumeration cheap for P04–P08, P14 —
precisely catechism §III.2's "unrolling-as-verification"). All are
fixable by statement/precondition/design changes. The complete
revision list is §8; with it applied, freeze.

**The mandate's four questions, answered up front:**
- *Small but challenging?* Yes — after revision. 14 functions ≤ 12
  LOC, each currently unprovable, each at donor exemplar level (§5).
- *Actually defined to exercise the required reasoning?* Mostly. The
  scalar rungs (P01/P02/P11) genuinely force their families. The
  memory rungs as drafted allow forbidden-strategy passes that the
  revisions close (§2).
- *If we pass, are we on our way to a verifier?* Yes, with two honest
  caveats (§6): the corpus is the donors' tutorial/paper-example tier,
  not their showcase tier (that is correct for a MINIMUM corpus; the
  libxml2 rung remains the graduation test), and the corpus defines
  WHAT to prove — the marginal-cost/legibility bar (catechism §IV.1–2)
  must ride the freeze text or a 5,000-line manual pass of all 14
  would be a pyrrhic "pass".
- *Hints of concrete-input garbage?* In the theorems: none (§3 —
  verified per program). In one program's DOMAIN: yes — P10's
  0 ≤ n ≤ 12 is a 13-point input space, i.e., a finite-sample theorem
  wearing a ∀ (§2.3). One sample-instance bug (P05) shows the
  oracle-sample leg needs an execution check at freeze.

---

## 1. Method

Per program I attacked on the mandate's five axes: (1) dishonest pass —
can the theorem be proved WITHOUT the family it claims to force;
(2) concrete-input residue per catechism §II's one-sentence test;
(3) claimed-family forcing vs mere presence; (4) calibration against
deps/refinedc/examples (reverse.c, talk_demo_alloc.c, wrapping_add.c,
binary_search.c, paper_example_2_*.c read in source) and
deps/cn/tests/cn (swap_pair.c, append.c, arrow_access.c read; 512-file
listing surveyed); (5) statement-form fidelity to the canonical
property and the draft's §2 house shape. I hand-simulated every
`main()` sample instance (all 14) and checked every arithmetic guard
for UB at domain boundaries. Findings labeled H-n (headline) and per
program.

---

## 2. The dishonest-pass holes (headline findings)

### H1 — CAP=8 enables bounded unrolling across the array/list rungs
(P04, P05, P06, P07, P08, P14)

All six memory-loop programs bound the quantified length by CAP=8
(p04_arr_sum.c:11 `#define CAP 8`, and identically in p05–p08, p14).
A prover can case-split on n ∈ {1..8} (8 meta-cases), after which every
loop has a CONCRETE trip count and the whole body unrolls into
straight-line code over symbolic contents — sums, scans, reversals,
even P14's nested loops (≤ 28 inner-body instances) close with NO loop
invariant at all. P05's early exit adds a hit-index split (≤ 44 cases
total). This is verbatim catechism §III.2 ("Unrolling-as-verification;
… cost proportional to the number of … rounds enumerated rather than
to program structure") — the strategy is forbidden, but at CAP=8 it is
CHEAP, and the substrate's existing whole-run machinery is exactly
shaped to do it. A corpus whose flagship loop rungs can be passed by
the very pattern the restart exists to kill is not freeze-ready.

**Fix (statement change, no gate): raise CAP to 100** in all six
programs (the T5 precedent: n ≤ 100, T5.lean per assessment §2.2).
Stack cost is trivial (int buf[100] = 400 B; P07/P08 arena[100] =
1.6 KB). At n ≤ 100 unrolling is 100-case grind — blatantly §III.2,
caught by the standing grind tripwire and proof-size bar with no new
machinery. Adjust P04's element bound so the sum bound still holds
(|xs[i]| ≤ 2^20, n ≤ 100 → |sum| ≤ 100·2^20 < 2^27 — fine as-is).
The invariant proof at CAP=100 costs exactly what it costs at CAP=8 —
that asymmetry is the point.

### H2 — The list programs' heap SHAPE is concrete by construction
(P07, P08)

The arena prologue (p07_list_sum.c:20-23, p08_list_reverse.c:18-21)
links arena[i] → arena[i+1] in fixed order. Given n, the entire heap
skeleton — which address links to which — is DETERMINED; only payloads
are symbolic. So after the H1-style split on n, the "rep predicate"
rungs collapse to per-node points-to at known addresses: the
`IntList p l` predicate and P08's celebrated two-partial-lists
invariant (draft §2, P08: "THE canonical SL proof") are entirely
avoidable. Contrast RefinedC's reverse.c: the list arrives as an
argument with unknown structure, so the rep predicate is forced. The
corpus's summit, as drafted, can be dishonest-passed at concrete
skeletons.

**Fix (structurally forcing, no gate): quantify the arena LINK ORDER.**
Extend the encoding with a permutation: choices[] = ⟨n, π(0..n−1),
payloads⟩, prologue links arena[π(i)].tail = &arena[π(i+1)] (still
~4 lines); wf m includes "π is a permutation of 0..n−1". Now the
skeleton is quantified data — per-n splitting faces ~n! shapes, and
the only structure-cost-proportional route is a genuine
address-abstract rep predicate. This converts F11 from PRESENT to
FORCED for both programs, with H1's CAP raise as belt-and-braces.
(Fallback if the permutation codec is judged too heavy at freeze:
CAP=100 alone + an inline note on both files that skeleton enumeration
is not a legitimate technique — weaker, per the operator's
note-where-structure-can't-force rule. I recommend the permutation:
it is a small statement-level change that makes the summit
dodge-proof.)

### H3 — P10 fact_rec is a finite-sample theorem in ∀-costume

`∀ n, 0 ≤ n ≤ 12: result = n!` (draft §2 P10; p10_fact_rec.c) has a
**13-point input domain**. `interval_cases n` + 13 concrete kernel
runs proves it with no contract, no induction hypothesis, no measure —
the exact R6-era pattern at 13 points instead of 1. This is the
catechism §III.1/§III.2 boundary case: the statement passes the §II
one-sentence test syntactically, but "the ∀ ranges over a finite
pinned sample" describes it exactly — the pin is the overflow bound,
not a literal list, and no version of fact-over-int escapes it (12! is
the last fit). The chartered ban gate (assessment §2.6) would NOT
catch it: n is a bound variable flowing into args; the gate's
finite-sample clause checks literal-list membership, not interval
width. Note the operator's mid-review ruling leans on P10 as the
structural anti-inlining backstop for P09 — as drafted, P10 cannot
carry that weight: a 13-point domain is enumerable, and even honest
per-case reasoning may simply inline/unroll the ≤ 12-deep call tree
concretely.

On the operator's specific question (fact → fib?): **fib does not fix
this.** fib(n) in int forces n ≤ 46 — a 47-point domain, same disease,
smaller dose. (Closed-form collapse — the operator's stated worry — is
NOT the danger for either: neither fact nor fib has a usable closed
form; enumeration is the danger.) The structural fix is recursion over
a NON-enumerable domain. Two candidates:

- **Recursive gcd** (recommended): `int gcd_rec(int a, int b) { if
  (b == 0) return a; return gcd_rec(b, a % b); }`, same spec and
  bounds as P11 (0 < a ≤ B, 0 ≤ b ≤ B, B ≥ 2^16 → ≥ 2^32-point
  domain). Forces F6 exactly: the recursive call is consumed via the
  contract with measure b decreasing; call-tree unrolling at symbolic
  values is infeasible (data-dependent depth, symbolic mod-towers);
  domain enumeration infeasible. Elegant twin with P11 — the same
  mathematical function verified by loop-variant and by
  recursion-measure, the two faces of well-foundedness. Loses fact's
  intermediate-product overflow chain, but F12 remains richly covered
  (P02, P04, P12).
- Recursive list_sum (alternative): F6 over the P07 encoding, contract
  as structural-induction hypothesis; keeps F6 attached to heap data.
  Slightly more machinery-coupled (rides F11).

If the operator prefers to keep a factorial/fib flavor for its F12
content, it can stay ONLY as an oracle-lane extra, not as the F6
forcer, with an inline note that interval enumeration is not a
legitimate technique — but per the ruling's own preference order
(structure over notes), replace it.

### H4 — Two theorems false/UB-holed as stated (precondition bugs)

- **P13 cell_alloc**: "∀ v ∈ intRange: outcomes ⊆ {Specified (v+1),
  Specified SENTINEL}" (draft §2 P13). At v = INT_MAX, `*p + 1`
  (p13_cell_alloc.c:19) is signed-overflow UB — the no-UB conjunct
  fails and the theorem as stated is FALSE. Fix: pre v ≤ INT_MAX − 1
  (or post = saturating model — don't; the pre is the boring fix).
  (Checked: no SENTINEL/v+1 collision — v+1 = INT_MIN needs
  v = INT_MIN − 1, out of range. SENTINEL itself is fine, §4.)
- **P09 call_contract**: "∀ a b < BOUND: outcomes = {Specified
  (a+1+b+1)}" with the header saying only "in range, < BOUND"
  (p09_call_contract.c:8-9). No LOWER bound: at a = b = INT_MIN,
  `return x + y` (line 16) is signed-overflow UB — theorem false.
  Fix: pre 0 ≤ a, b < BOUND (or |a|,|b| < BOUND). While here: BOUND =
  10^6 is a third program-relevant constant the draft's "two justified
  constants" claim (§3 last bullet) does not account for — see H7.

These two are exactly the class of bug the corpus wants the VERIFIER
to catch; the corpus's own statements must not contain them at freeze.

### H5 — P05's spliced sample instance is wrong (record-integrity)

p05_find_first.c:11-12: choices = {4, 7, 1, 9, 3, 0,0,0,0, 9} → n=4,
buf = [7,1,9,3], x = choices[9] = 9. First hit is index **2**
(buf[2] = 9), but expected_idx = **3**. The compiled sample returns 1
(mismatch), not 0. Every other program's sample checks out under hand
simulation (I verified all 14). Harmless to the theorem (the sample is
oracle-ledger only) but it is direct evidence the samples were not
executed before drafting — freeze must include one differential run of
all 14 samples (an execution of existing test machinery, not a new
gate). Fix: expected_idx = 2.

### H6 — P03's "may-alias case-split" (F9) is over-claimed

The theorem's ∀ alias ∈ {0,1} is legitimately a 2-point STRUCTURAL
selector (the alias configuration space is inherently binary — this is
not finite-sample residue). But the meta-split on alias resolves
pointer identity BEFORE swap runs: in each arm the prover faces
concretely-equal or concretely-distinct pointers, never an UNRESOLVED
may-alias at a symbolic pointer (the memmove-class reasoning the
family name suggests). What P03 actually forces — both the two-cell
disjoint case and the p=q collapse case discharged from ONE theorem —
is valuable and donor-comparable (CN's swap_pair.c is strictly
easier: fixed two-slot array, no aliasing at all). Fix (matrix
honesty + note, per the ruling): relabel F9's P03 cell as "both alias
arms in one theorem"; add the P09-style inline note on swap that it is
to be proved once against a spec covering both arms (spec-level
disjunction or a p=q-conditional post), inlining-per-arm noted as not
the intent. Unresolved-symbolic-alias reasoning remains a real family
for real C — adjudicated DEFERRABLE (§6): it will be forced naturally
by the first memmove-shaped libxml2 target, and no ≤ 12-LOC harness
with a closed init forces it without contrivance.

### H7 — Constants undercount + unpinned bounds (statement hygiene)

Draft §3 claims exactly two justified constants (CAP=8, SENTINEL). The
sources carry more program-relevant constants: P09's BOUND = 10^6
(arbitrary — any bound below INT_MAX works; justify or widen), P10's
12 (H3 — the domain pin), P11's B (named in the theorem, never
pinned), P04's 2^20 element bound (fine, but list it), P12's "fields
in range" (never pinned; must bound |ax+bx| ≤ INT_MAX — e.g.
|coord| ≤ 2^30 − 1). None trivializes its postcondition — no
precondition smuggling found anywhere in the corpus (checked per
program; P02 is the exemplar: NO pre at all beyond intRange, guards
proved not assumed). Fix: freeze pins every constant with a one-line
justification and pins B ≥ 2^16.

### H8 — P13 pre-decides the standing alloc-ND design-evaluation gate

The draft keeps malloc-failure ND in the outcome set "so allocation ND
is exercised honestly" (p13 header, draft §2 P13). But CLAUDE.md's
standing [USER 2026-08-24] ruling puts allocation-failure
nondeterminism explicitly UNDER the SL-alloc design-evaluation gate
("allocation FAILURE nondeterminism (malloc null)" among the
subtleties to EVALUATE before executing, Caesium as reference). If the
evaluated model makes malloc infallible, P13's SENTINEL branch is dead
in every execution — its F1 (null-check branch) claim becomes VACUOUS
and the two-outcome set collapses. The corpus freeze must not decide
that design by side effect. Fix (statement scoping): freeze P13's
core content unconditionally — ownership birth/death + the leak
conjunct + result v+1 on the success outcome — and mark the failure
outcome clause DESIGN-DEPENDENT: two-outcome set if the evaluated
model is failable, {Specified (v+1)} with the null branch noted
statically dead (and P13's F1 cell removed from the matrix) if not.
Also "⊆" vs the house "=": ⊆ is the right connective only while the
ND question is open; resolve to "=" with the design. Q4's malloc
question: §7.

### H9 — wf/encoding under-specification (degeneration risk)

The mandate asks where "the const-embedding splice could degenerate to
a pinned array without the theorem noticing." The theorems quantify
`∀ m, wf m → exec(mkHarness(encode m, encode(modelFn m))) ⇓ 0` (draft
preamble) — genuine ∀ over program-relevant data, PROVIDED wf and
encode are what the prose sketches. But no program's wf predicate or
codec is pinned in the draft (bounds live in comments). If wf is
accidentally strong (e.g. encode partial off the sample, or a wf
conjunct that fixes n), the ∀ collapses silently and no reader of the
theorem statement notices. Fix (statement content, standing doctrine —
not a new gate): at freeze, each memory-input program pins its wf
definition and carries the plant-test-doctrine anti-vacuity witness —
kernel-checked inhabitation by ≥ 2 wf-instances with DIFFERENT
modelFn values (arc-15's plant discipline applied to the domain).
Companion note for the freeze text: the const-embedding form means
each memory program's proof crosses THREE loops (decode prologue,
computation, comparator readback), not one — same families, but the
per-program price should be stated honestly.

---

## 3. Concrete-input residue audit (catechism §II applied per theorem)

Every theorem passes the one-sentence test: P01 "for all int x…", P02
"for all int a,b…", P03 "for all a,b and both alias arms…", P04–P08,
P14 "for all wf memory inputs m…", P09/P10/P11/P12 "for all in-bounds
scalars…", P13 "for all v…". No theorem mentions a literal argument;
the choices[]/expected[] literals are marked SPLICED and the draft's
discipline (theorem quantifies the splice; main() = oracle sample
only) is correctly and consistently stated in all 14 file headers.
The two residue findings are H3 (P10's domain IS a finite sample —
the one true "concrete-input garbage" hint in the corpus) and H9 (the
degeneration risk if wf/codecs aren't pinned). The scalar-rung
call-boundary route (T4/T5 mechanism) is clean. The samples themselves
are honestly labeled everywhere ("oracle differential sample only —
NOT the theorem", p01:12) — this labeling discipline is exactly
catechism §V and should be kept verbatim at freeze.

---

## 4. Statement-form fidelity

- **House shape**: all 14 fit the draft-§2 preamble form (EnvHyp →
  ∀ seed apart → ∀ init/args, pre → outcome-set). The outcome-SET
  equality is STRONGER than the catechism §II implication form
  (totality over ND resolutions + termination + no-UB) — correctly
  claimed, and it is what makes P11's termination demand real (§5).
- **Postconditions genuinely functional**: yes in all 14 — max, the
  3-case satAdd, per-arm swap results, sum, least-index, reverse (both
  representations), (a+1)+(b+1), n!/gcd, midpoint-with-frame, v+1,
  pair-count. The memory programs compress the post into the
  comparator (Specified 0 vs mismatch-index) per the Form-1 readback
  doctrine — fine, and the mismatch-index granularity is a nice touch.
- **Hidden bonus worth naming (P02)**: the guards are UB-safe ONLY via
  `&&` short-circuit (at a ≤ 0, `2147483647 - a` would itself overflow
  for a = INT_MIN, p02:9 — unevaluated by short-circuit; symmetrically
  line 10). The theorem therefore also forces correct sequenced-&&
  reasoning at symbolic operands — a real C family (F1-adjacent) the
  matrix doesn't even claim. Keep exactly as written; add the
  sequencing observation to P02's header so the forcing is on record.
- **Frame-as-observable (P12, P03, P09)**: putting the frame IN the
  checked postcondition (p12:17 return 9 on input mutation) is honest
  and statement-doctrine-clean — better than trusting const. Good.
- **The two named constants**: CAP as a CONCEPT is legitimate (donor
  capacity pres exist throughout CN/RefinedC), its VALUE 8 is the H1
  smell — raise to 100. SENTINEL is legitimate (a fixed error code is
  spec content, like errno; collision-checked in H4). The undercount
  of the other constants is H7.

---

## 5. Calibration vs the donors (small-but-challenging)

Read against deps/refinedc/examples and deps/cn/tests/cn:

- P03 vs CN swap_pair.c: ours is HARDER (CN's has no aliasing and a
  trusted main). P12 vs CN arrow_access.c: comparable-to-harder (frame
  as checked observable). P07/P08 vs CN append.c and RefinedC
  reverse.c: same class — the IntList predicate + pointer surgery is
  precisely CN's append/RefinedC's reverse content. P13 vs RefinedC
  talk_demo_alloc.c: comparable (theirs is arena-alloc typing; ours
  adds the leak conjunct — a house strength). P02 vs RefinedC
  wrapping_add.c: comparable side-condition content, ours totally
  UB-focused. P14, P05, P06: standard tutorial-tier loop exemplars.
- Nothing approaches RefinedC's binary_search.c (function pointers,
  sortedness ghosts, per-loop constraint lists) or btree.c/queue.c.
  That is CORRECT for a minimum corpus — but say it plainly at
  freeze: passing 14/14 lands us at RefinedC's paper-examples tier,
  necessary-not-sufficient for the aim; the libxml2 rung is the
  graduation test, and the corpus should not be advertised as donor
  parity.
- One place we are HARDER than donors, deliberately: P11's
  termination. RefinedC and BRiCk are partial-correctness logics;
  neither example set proves gcd terminates. Our outcome-set form is
  total by construction, so the well-founded variant is genuinely
  forced (any route to a fuel bound — even "b decreases so ≤ B trips"
  — IS the measure argument; the Fibonacci trip bound is harder than
  the variant, so there is no cheap dodge). This exceeds-donors item
  is priced (the while_inv gap, draft §4) and is NOT gratuitous — it
  falls out of the house adequacy form. Keep.
- Research-grade smuggling check: only P13's alloc-failure ND
  qualified (H8) — and it is a scoping fix, not a rejection. Nothing
  else in the corpus is research-grade; every family has 20+ years of
  canon (catechism §IV.3 satisfied by construction).

---

## 6. Coverage honesty — forced vs present, and the missing families

**Forced (theorem unprovable without the family), after revisions:**
F1 (P01/P02 — symbolic branch, no dodge exists), F2a (P04/P06 at
CAP=100), F2b (P05 — contents-dependent trip count; the hit-index
enumeration dies with H1), F2c (P11 — genuinely forced, see §5), F3
(P14), F4 (P05), F5 (P09 with the inline note + H3's recursive
backstop), F6 (P10 replacement), F7/F8 (all array rungs), F9-frame
(P09/P12 — the frame is checked in the post, unfakeable), F10 (P07/
P08/P12), F11 (P07/P08 with H2's permutation), F12 (P02/P04/P09/P10 or
successor/P11/P13 — with H4's fixes these side conditions are real),
F13 (P01/P02/P05/P13), F14 (all memory rungs). F9-may-alias: present,
not fully forced (H6) — accepted with relabel.

**Missing families, adjudicated (my judgment as charged):**

MUST be in the minimum corpus (one program covers all three):
- **Strings/NUL-termination**: THE libxml2/uri.c idiom. P05 does not
  substitute — its loop bound is an explicit n parameter; the
  NUL-convention loop's safety depends on a NUL-EXISTS-within-bounds
  precondition, a genuinely different invariant discipline (deref
  safety from a ∃-witness, not an index bound). For a corpus whose
  graduation target is uri.c, this is a gap.
- **Integer conversions / char widening**: absent entirely (unsigned
  char ↔ int comparisons are every parser's bread). No current row
  forces a conversion rule.
- **switch**: same FAMILY as F1 (n-way split) but a different
  elaborated-Core SHAPE; libxml2 is switch-heavy. Cheap to cover.

**Fix: ADD P15** (≤ 12 LOC): a NUL-terminated unsigned-char buffer
scan-and-classify — e.g. count chars of a class determined by a small
switch, ∀ wf buffers (NUL within CAP=100, contents symbolic). One
program closes all three gaps; theorem: ∀ s wf: result = the model
count. This keeps "tiny" honest (15 rows, every one forcing).

Legitimately DEFERRED (agree with draft Q2, with additions — record
these in the freeze text so deferral is a decision, not an omission):
function pointers (RefinedC binary_search class; note libxml2's SAX
layer will eventually force it — pick fn-ptr-free rungs like uri.c
first); concurrency (chartered, cmm/pKVM lanes); unresolved-symbolic
may-alias (H6 — first memmove-shaped target forces it); unsigned
wraparound arithmetic (defined-overflow ring — real for pKVM/WireGuard
hashes, no new logic machinery, natural at those targets); mutable
globals / static state across calls (pKVM lane; note the const-
embedding harnesses already force global READS); break/continue (early
exit VOCABULARY variant — F4's return-from-loop covers the family;
optionally recast P05's exit as break at freeze for a free vocabulary
row); goto (libxml2 error paths — defer to the libxml2 rung
explicitly).

---

## 7. The author's four operator questions — recommendations

- **Q1 (size 14, "tiny"?)**: Recommend **15** — the 14 as revised plus
  P15 (§6). Still tiny (≈ 290 lines total); with H3's replacement no
  row is filler and every family column has a forcing row. Below 14
  would reopen gaps; above ~16 starts buying breadth the libxml2
  ladder buys better.
- **Q2 (defer fn-ptrs + concurrency)**: **Confirm both deferrals**,
  and enlarge the recorded deferral list per §6 so each absence is an
  adjudicated decision.
- **Q3 (P09 anti-inlining)**: **Settled by the operator mid-review**:
  no mechanical gate; inline note on P09 that inlining bump is not a
  legitimate technique for this theorem, with recursion as the
  structural backstop. My contribution to the settled form: the
  backstop only works if P10's successor has a non-enumerable domain
  (H3) — as drafted, P10 (and a fib swap) can itself be enumerated/
  depth-unrolled, so the backstop must be the recursive-gcd (or
  recursive-list) replacement. With that, the P09 note + backstop is
  adequate: the B4 call rule is what gets built regardless, and a
  dishonest P09 pass would leave P10's successor unprovable — the
  structure enforces what the note requests.
- **Q4 (P13 malloc vs create/kill)**: **Keep malloc.** Real-C
  fidelity is the corpus's reason to exist; the libc lane is standing
  (cerberus.install/libc.co gates); a create/kill primitive would
  dodge exactly the libc/ownership reality pKVM needs. But apply H8:
  the freeze must not pre-decide malloc-failure ND — scope the
  failure clause as design-dependent pending the chartered SL-alloc
  design evaluation.

---

## 8. Per-program verdicts and the complete revision list

| # | Verdict | Required revision (exact) |
|---|---|---|
| P01 clamp | **ACCEPT** | none — the emblem, correctly stated |
| P02 sat_add | **ACCEPT** | record the short-circuit forcing in the header (§4); pin the 3-case model in Lean at freeze |
| P03 swap | **REVISE** | matrix: relabel F9 cell "both alias arms" (H6); inline note: swap proved once against a both-arms spec; alias selector recorded as structural 2-point domain |
| P04 arr_sum | **REVISE** | CAP 8 → 100 (H1); pin wf + 2-witness anti-vacuity (H9) |
| P05 find_first | **REVISE** | expected_idx 3 → 2 (H5); CAP → 100; optional break-form (§6); wf pin |
| P06 arr_reverse | **REVISE** | CAP → 100; wf pin |
| P07 list_sum | **REVISE** | CAP → 100; quantified link-order permutation in the encoding (H2); wf pin |
| P08 list_reverse | **REVISE** | same as P07 — the summit must be dodge-proof (H2) |
| P09 call_contract | **REVISE** | pre gains lower bound: 0 ≤ a,b < BOUND (H4 — theorem false without it); inline anti-inlining note (Q3 settled form); justify or widen BOUND (H7) |
| P10 fact_rec | **REPLACE** | 13-point domain = finite-sample theorem (H3). Replace with recursive gcd (recommended; P11's twin) or recursive list_sum; fib is NOT a fix (47 points). fact may remain an oracle-lane sample only |
| P11 gcd_iter | **ACCEPT** | pin B ≥ 2^16 (H7) |
| P12 pt_midpoint | **ACCEPT** | pin the field bound (e.g. \|coord\| ≤ 2^30 − 1) (H7) |
| P13 cell_alloc | **REVISE** | pre v ≤ INT_MAX − 1 (H4 — theorem false without it); failure-outcome clause marked design-dependent per the standing alloc-ND gate, F1 cell conditional (H8) |
| P14 count_pairs | **REVISE** | CAP → 100 (H1) |
| P15 (new) | **ADD** | NUL-terminated unsigned-char scan + switch classifier: strings + conversions + switch in one ≤ 12-LOC row (§6) |

Corpus-level freeze-text additions (statement content, not new gates):
(a) all samples executed differentially once before freeze (H5's
lesson); (b) every constant listed with a one-line justification (H7);
(c) each memory program's wf pinned with the ≥ 2-witness anti-vacuity
obligation (H9); (d) the acceptance bar per program includes the
catechism §IV.1–2 marginal-cost/legibility standard (spec + invariants
+ automation; professor-readable) so a grind pass cannot count as a
pass; (e) the §6 deferral list recorded as decisions.

**Corpus verdict: REVISE-THEN-FREEZE** — with the table above applied,
this corpus does what the mandate demands: small, currently
unprovable, genuinely forcing, and free of concrete-input residue. The
strongest thing I can say for it, having attacked it: after revision I
could not construct a forbidden-strategy pass for any row.

---
---

# APPENDIX — DELTA RE-REVIEW of corpus v2 (same day)

Scope per orchestrator: verify each finding's claimed disposition
against the actual v2 text; re-run the dishonest-pass instrument on
the CHANGED programs (P07/P08-π, P09, P10-rsum, P15); check all
bounds against the operator's anti-brute-force ruling (draft §0);
verdict. Read-only, no builds. All 15 sample instances hand-simulated
by me against their spliced data (I cannot execute the claimed 15/15
oracle run — it is a specific, falsifiable record and freeze
obligation (a) re-runs it; my hand simulation agrees 15/15).

## A1. Disposition verification (finding by finding, against v2 text)

| Finding | Claimed | Verified? |
|---|---|---|
| H1 unrolling | Superseded by anti-brute-force ruling | **YES, stronger than my fix.** ARENA = 2^20 (p04–p08, p15), 65536 type-derived (p14), full ranges elsewhere. Unrolling/skeleton splits now inconceivable-scale. |
| H2 π-skeleton | Applied P07/P08 | **YES, genuine** — see A2. |
| H3 P10 | fact → rsum, n ≤ 65535 type-derived | **Applied; adjudicated in A3 — I recommend the gcd swap.** |
| H4 P13 | v ≤ INT_MAX−1 | **YES** (p13 header + §0; derivation correct). |
| H4 P09 | 0 ≤ a,b ∧ a+b ≤ INT_MAX−2 | **YES, and arithmetic checked**: x=a+1, y=b+1, x+y=a+b+2 ≤ INT_MAX all in range; bump's contract 0 ≤ v ≤ INT_MAX−1 covers both sites; ~2^61 pairs. The v2 pre closes BOTH the underflow hole I found and the overflow side. |
| H5 sample | expected_idx 2; all 15 executed | **YES** (p05:12); my hand simulation of all 15 samples (incl. the new π-encoded P07/P08 and P15's do-while prologue) gets Specified(0) in every case. P07: list arena[1](4)→arena[2](−1)→arena[0](7), sum 10 ✓. P08: skeleton π=[2,0,1], reverse [3,2,1] ✓. P15: digits before NUL in {a,7,.,9} = 2 ✓. |
| H6 P03 | relabel + both-arms-spec note | **YES** (p03 header + matrix footnote + deferral recorded). |
| H7 constants | §0 inventory | **YES** — every constant now listed with a derivation; P09's arbitrary BOUND eliminated entirely (better than my fix). One characterization nit: A4-n3. |
| H8 P13 scoping | core unconditional / failure clause design-dependent | **YES, and the core is still strong** — see A2. |
| H9 wf pins | carried as freeze obligation §6c | **YES**, with one needed strengthening: A4-n2. |
| §4 P02 bonus | recorded, family F15 | **YES** (p02 header verbatim-faithful to my finding). |
| §6 P15 | added | **YES, well-built** — see A2. |

## A2. Dishonest-pass re-run on the changed programs

**P07/P08 with π — is the link-order quantification real, and is π
itself degenerable?** Real: choices = [n; π(0..n−1); heads], prologue
links arena[π(i)].tail = &arena[π(i+1)] (p07:26-29, p08:24-27) — the
list-order address sequence IS quantified data. Degeneration attack:
(a) case-split on (n, π) to recover concrete skeletons → Σ n!
cases, dead at any n past ~10 — enumeration inconceivable; (b) avoid
the rep predicate by reasoning at base+π(i)·sizeof(node) offsets →
those are SYMBOLIC, data-dependent addresses whose pairwise
disjointness must be derived from π's injectivity — that reasoning IS
the address-abstract ownership family; there is no concrete-address
route left. F11 is now FORCED for both. Verdict stands: the summit is
dodge-proof. Two honest residuals, neither blocking: (i) wf's "π is a
permutation" conjunct is load-bearing — if it admitted repeats the
prologue builds overlapping nodes and the theorems are false; this
lands under the H9 freeze pin and needs the A4-n2 witness
strengthening; (ii) all nodes live inside ONE arena object (offsets,
not separate allocations) — a provenance-fidelity delta vs RefinedC's
malloc'd reverse.c; acceptable (P13 owns per-allocation ownership;
const-embedding forces the arena), record one line so P08 is never
cited as covering per-node allocation ownership (A4-n4).

**P09 (new pre)**: correct (table above). Inlining remains possible by
design — Q3 settled by operator; the note is in-file and the backstop
condition is adjudicated in A3. No new holes.

**P13 (H8 scoping) — is the unconditional core still strong?** Yes.
The core clause (success outcome = v+1, ownership birth at malloc /
death at free, leak conjunct on EVERY path, p13:7-10) forces the F11
alloc machinery regardless of how the design evaluation resolves
malloc failability: even the success-path proof must gain and consume
the malloc points-to, and the leak conjunct is path-unconditional. The
design-dependent clause defers exactly the one thing the standing gate
owns (the outcome-set shape / F1 liveness, matrix ◐), and ⊆→= resolves
with it. Correctly scoped; no smuggling remains.

**P15 as landed**: the loop guard is `s[i] != 0` with deref safety
flowing only from wf's ∃-NUL witness — the invariant must carry "no
NUL among s[0..i)" to justify the next deref, which is precisely the
claimed discipline and is not dodgeable (contents-dependent trip
count at 2^20 scale, no enumeration; no closed form). Switch at the
widened unsigned char forces the n-way shape. Sample correct.
Unclaimed bonuses: the do-while prologue and the side-effecting
`choices[i++]` condition add two more real-C vocabulary shapes for
free. ACCEPT as landed.

## A3. The rsum-vs-gcd adjudication (definite recommendation)

The author's honest remark is accurate on both counts: rsum's
postcondition n(n+1)/2 IS its closed form, and 65535 is the type
maximum for this function shape (derivation p10:6-9, checked
correct). My analysis:

- The closed form is NOT the problem. Any proof of ∀n ≤ 65535:
  rsum(n) ⇓ n(n+1)/2 must relate rsum(n)'s execution to rsum(n−1)'s
  at symbolic n — that relation IS contract-consumption-as-induction
  (F6); the closed form only simplifies the per-step algebra, not the
  structure. There is no non-inductive route short of enumeration.
- The domain IS the problem, under the operator's own §0 test
  ("if enumeration is even conceivable as a strategy, the bound is
  too small"). 65536 points × depth-n concrete runs is months of
  banned grind — not practically enumerable — but it is the ONLY
  domain in the corpus where the question even has to be argued
  (everything else is ≥ ~2^31). rsum sits in exactly the gray zone
  the ruling was written to eliminate.
- The P09 backstop role needs the strongest available program: rsum's
  data-dependent depth does defeat inline-unrolling, but gcd_rec
  defeats it AND has a ≥ 2^32-point domain AND a data-dependent
  measure (b' = a mod b < b, no closed-form depth), closing every
  channel at once.

**RECOMMENDATION (definite): swap P10 to recursive gcd at freeze.**
`int gcd_rec(int a, int b) { if (b == 0) return a; return gcd_rec(b,
a % b); }`, spec and full-range bounds identical to P11 — the
loop-variant/recursion-measure TWIN, sharing P11's model function at
zero extra spec cost. rsum is not wrong — if the operator keeps it,
the in-file honest remark suffices and I would not fight it — but
under the anti-brute-force ruling's own absolute phrasing, gcd_rec is
the choice with nothing to argue. rsum's one real virtue (T5-familiar
model isolating the new call machinery) survives the swap: it can be
B4's first worked warm-up instance without being a frozen target.

## A4. Bounds sweep (anti-brute-force ruling, corpus-wide) + nits

Every bound checked against §0's test: P01/P02/P03/P11 full range
(P11's % hazards: b=0 guarded, INT_MIN/−1 excluded by sign pres —
clean); P04–P08/P15 at 2^20 with full-range contents (P04's SEMANTIC
prefix-sum pre is the elegant form — no convenience constant exists
at all); P09 ~2^61 derived; P12 INT_MAX/2 derived (checked: forced by
a->x + b->x); P13 INT_MAX−1 derived; P14's 65536 derivation checked
correct (65536·65535/2 ≤ INT_MAX < 65537·65536/2) and its enumerable
n-dimension is harmless — contents stay full-range symbolic, so
splitting on n yields no concrete instances, only 2^31-body-instance
unroll targets: inconceivable. **The only gray-zone bound in the
corpus is P10's 65535 (A3).** Remaining nits, all one-line text
fixes at freeze:

- **n1 (stale v1 text)**: draft §3 still says P09 is "flagged for the
  reviewer to adjudicate an enforcement mechanism (see open question
  Q3)" — Q3 is settled; §3 also still says "the 14 rows" (twice) —
  now 15. Docs-truth fix before freeze.
- **n2 (π witnesses)**: strengthen §6c for P07/P08 — the ≥2-witness
  anti-vacuity obligation must include two DISTINCT permutations π
  (not merely distinct payloads), so the skeleton quantification is
  witnessed non-degenerate.
- **n3 (ARENA characterization)**: §0/p04 call ARENA "not a
  theorem-relevant constant", but |xs| ≤ 2^20 IS the wf bound in the
  theorem (draft §2 P04). Harmless (non-enumerable either way) —
  state it honestly as the wf capacity bound at the wf pin.
- **n4 (provenance note)**: one line on P07/P08 that the quantified
  skeleton lives within a single arena object (offset-level, not
  per-node allocations); per-allocation ownership is P13's row.

## A5. Delta verdict

**READY-TO-FREEZE**, conditional on exactly: (1) the P10 decision at
sign-off — my definite recommendation is the recursive-gcd swap (A3),
with rsum acceptable-if-preferred given its in-file honest remark;
(2) the four one-line text fixes n1–n4. No structural revisions
remain: every v1 finding is genuinely dispositioned in the v2 text
(none by claim alone — H1 by a stronger ruling than my fix, H5 by
execution, H2 by a design change I verified forces what it promises),
and the changed programs survive the dishonest-pass instrument. The
v2 corpus, with the P10 adjudication and nits applied, is the frozen
target I would defend.
