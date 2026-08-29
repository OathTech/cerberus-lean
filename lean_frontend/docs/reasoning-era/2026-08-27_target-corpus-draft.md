# The target corpus — DRAFT v2 (restart steps 1+2, revised per the step-3 review)

STATUS: DRAFT for the step-3 aggressive review. Nothing here is canon;
nothing enters a repository before step 3 passes and the operator's
step-4 freeze sign-off. Mandate [USER 2026-08-27]: harnesses at
arbitrary input memory (const-embedding); theorems that "clearly
unambiguously and with no doubt whatsoever require exercising *all* of
the complexities a program logic is designed to handle"; a tiny corpus
requiring all reasoning families real C needs. Anti-concrete
discipline absolute (canonical-property ruling, same day).

Draft C sources: `notes/corpus-draft/p01..p15*.c` (15 frozen-candidate
rows + 1 clearly-marked ALTERNATE file, 387 lines TOTAL incl. comment
headers; every function ≤ ~12 LOC). In each
memory-input file the `choices[]`/`expected[]` arrays are marked
SPLICED: they are mkHarness template slots — one representative
instance is shown so the file compiles and runs as an oracle
differential sample; the THEOREM quantifies over the splice (arc-15
template: `∀ m, wf m → exec(mkHarness(encode m, encode(modelFn m)))
⇓ Specified 0`). Scalar-input programs use the call-boundary route
(canonical-property ruling: args at the call, prologue stores —
already the proved T4/T5 mechanism).

## 0. Constants and bounds — THE ANTI-BRUTE-FORCE RULING

[USER 2026-08-27, verbatim, amending the earlier capacity approach]:
"we don't need to cap at all, just make it some insanely large number
that fits in the type. In general, the code can be small but we
SHOULD NOT pick values that could be brute forced."

Applied corpus-wide: every precondition bound is the LARGEST value
the type admits; where overflow-safety genuinely forces a tighter
bound, it is DERIVED from the type limit and the derivation is
documented inline in the .c header. The test applied to every
constant: could a prover enumerate this domain? If enumeration is
even conceivable as a strategy, the bound is too small. Bound
inventory (all derivations inline in the files):
- P01/P02/P03/P11: FULL type range (no smaller constant exists in the
  theorem; P03's alias∈{0,1} is case STRUCTURE, not a data domain —
  the data a,b are full-range).
- P04–P08 arena capacity ARENA = 2^20 (object-model scale; the
  mkHarness splice emits exact-size arrays per m). Stated honestly
  (review n3): |xs| ≤ 2^20 IS the wf capacity bound appearing in each
  theorem's precondition — non-enumerable either way, but it is
  theorem content, pinned at the wf pin, not mere plumbing.
  Element/head values full range
  under SEMANTIC no-overflow pres (prefix sums in range — carried by
  the invariant, non-enumerable).
- P09: 0 ≤ a, 0 ≤ b, a+b ≤ INT_MAX−2 (derived: the v+1 hazards AND
  the x+y overflow/UNDERFLOW pair — the lower bounds are H4's fix,
  closing the underflow hole my upper-only first amendment missed;
  ~2^61 valid pairs).
- P10 (gcd_rec, RECOMMENDED): FULL type range, as P11 — 0 < a ≤
  INT_MAX, 0 ≤ b ≤ INT_MAX (≥ 2^32 points, no closed-form depth).
  [P10-ALT rsum: n ≤ 65535 derived — largest n with n(n+1)/2 ≤
  INT_MAX; the review's one gray-zone bound, retained only in the
  alternate file with its honest remark.]
- P12: |coords| ≤ INT_MAX/2 = 1073741823 (derived: the a->x + b->x
  hazard; (2^31)^4-scale domain).
- P13: v ≤ INT_MAX−1 (derived: v+1); SENTINEL = INT_MIN is a fixed
  SPEC code, not a domain bound.
- P14: n ≤ 65536, derived: the count c ≤ n(n−1)/2 must fit int.
- P15: NUL position < 2^20 (arena scale); bytes full uchar range.
The ruling retro-applies to all wf/codec bound pins: codec `wf`
predicates use these same type-derived bounds, never convenience
constants.

## 1. The reasoning-family matrix

Families (operator list + the assessment's missing middle):
F1 symbolic branch/case-split · F2 loop invariants — (a) closed-form
trip count in quantified data, (b) trip count a function of quantified
MEMORY CONTENTS, (c) termination by well-founded measure · F3 nested
loops · F4 early exit from loops · F5 calls/returns with contracts
(spec USED, not inlined) · F6 recursion (callee contract = induction
hypothesis) · F7 pointer deref + arithmetic · F8 arrays at SYMBOLIC
indices · F9 aliasing + frame (may-alias case-split; untouched state
framed) · F10 struct fields · F11 heap structures / rep predicates /
ownership (incl. alloc-free + leak conjunct) · F12 integer arithmetic
with UB side conditions (overflow, %0) · F13 multiple return paths ·
F14 memory as input AND output (postcondition on final memory via
readback).

| # | program | F1 | F2 | F3 | F4 | F5 | F6 | F7 | F8 | F9 | F10 | F11 | F12 | F13 | F14 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| P01 | clamp | ● | | | | | | | | | | | | ● | |
| P02 | sat_add | ● | | | | | | | | | | | ● | ● | |
| P03 | swap (may-alias) | ● | | | | | | ● | | ● | | | | | ● |
| P04 | arr_sum | | ●a | | | | | ● | ● | | | | ● | | ● |
| P05 | find_first | ● | ●b | | ● | | | ● | ● | | | | | ● | ● |
| P06 | arr_reverse | | ●a | | | | | ● | ● | | | | | | ● |
| P07 | list_sum | | ●a | | | | | ● | | | ● | ● | ● | | ● |
| P08 | list_reverse | | ●a | | | | | ● | | | ● | ● | | | ● |
| P09 | call_contract | | | | | ● | | ● | | ● | | | | | |
| P10 | gcd_rec | ● | | | | ● | ● | | | | | | ● | | |
| P11 | gcd_iter | ● | ●c | | | | | | | | | | ● | | |
| P12 | pt_midpoint | | | | | | | ● | | ● | ● | | ● | | ● |
| P13 | cell_alloc | ◐ | | | | | | ● | | | | ● | | ● | ● |
| P14 | count_pairs | ● | ●a | ● | | | | ● | ● | | | | ● | | ● |
| P15 | scan_classify | ● | ●b | | | | | ● | ● | | | | | | ● |

Every family column has ≥1 ●; every row is a ≤ ~12-LOC function.
Marks/footnotes (review): P03's F9 = "both alias arms in one theorem"
(H6 relabel — unresolved symbolic may-alias is a recorded deferral);
P13's F1 is ◐ DESIGN-DEPENDENT (H8 — live iff the evaluated alloc
model is failable); F15 (sequenced-&&/short-circuit at symbolic
operands) is FORCED by P02 (review §4 bonus find, recorded in its
header); P15 additionally closes three named sub-families in one row:
NUL-termination discipline (deref safety from an ∃-NUL witness, not
an index bound), unsigned-char→int conversions, and the switch
n-way-split Core shape.

## 2. The programs (source attribution · theorem · Lean sketch)

Theorem house shape throughout (canonical property + threaded
statements): `EnvHyp → ∀ seed, SeedApart seed → ∀ ⟨quantified init/
args⟩, pre → CallHarnessAdequateThr seed tagDefs file "harness"
⟨args⟩ fs (spec ⟨init/args⟩)` — outcome-SET form (all ND resolutions;
no UB), which strengthens `⇝ result ⟹ result = some(final) ∧ post`.

**P01 clamp** (fresh; the emblem). ∀ x ∈ intRange:
outcomes = {Specified (max x 0)}. Lean:
`∀ x, intRange x → …Adequate… "clamp0" [intValue x] (fun r => r = specified (max x 0))`.
Forces: case-split at symbolic x — unprovable today by the
assessment's central finding; deliberately the corpus's FIRST rung.

**P02 sat_add** (fresh). ∀ a b ∈ intRange: outcomes =
{Specified (satAdd a b)} where satAdd is the 3-case pure model; no UB
— the guards' correctness (no signed overflow on any path) is proved,
not assumed. Forces: UB side-condition reasoning at symbolic operands.

**P03 swap, both alias arms** (derived shape: deps/cn/tests/cn/
swap_pair.c, BSD-2). ∀ a b ∈ intRange, ∀ alias ∈ {0,1} (structural
2-point case vocabulary, not a data domain): outcomes = {Specified 0}
per (a,b,alias) — the DISJOINT arm needs two-cell separation; the
ALIASED arm the p=q points-to collapse; swap is specified ONCE with a
both-arms (p=q-conditional) post and the inline note records that
per-arm inlining is not the intent (H6). Unresolved SYMBOLIC
may-alias is a recorded deferral (first memmove-shaped target).

**P04 arr_sum** (derived shape: CN array tests, BSD-2). ∀ xs, 1 ≤ |xs|
≤ 2^20, prefix sums in int range (semantic pre, §0): outcomes = {Specified 0} (harness compares
against spliced expected = sum xs; mismatch → 1). Forces: loop
invariant `s = Σ_{k<i} xs[k]` over quantified contents + n; symbolic
array indexing; overflow bound carried through the invariant.

**P05 find_first** (fresh; uri.c scan idiom). ∀ xs (|xs| ≤ 2^20), x
full range:
outcomes = {Specified 0} with expected_idx = LEAST i. xs[i]=x else n
(sample corrected per H5: [7,1,9,3] with x=9 hits index 2; all 15
samples now ORACLE-EXECUTED, every one Specified(0) — §7).
Forces: trip count a function of quantified CONTENTS; early exit;
minimization invariant ("no hit below i") — the sharpest loop rung.

**P06 arr_reverse** (fresh, classic). ∀ xs (|xs| ≤ 2^20): final
array =
reverse xs, readback mismatch-index. Forces: two-index invariant over
a partially transformed array; symbolic writes.

**P07 list_sum** (derived int_list shape: deps/cn/tests/cn/append.c,
BSD-2). ∀ l (|l| ≤ 2^20, prefix sums in range — §0), ∀ π permutation
of 0..n−1 (H2): outcomes = {Specified 0}. The prologue builds the
heap list from the spliced encoding VIA π — arena[π(i)].tail =
&arena[π(i+1)] — so the SKELETON is quantified data (~n! shapes;
concrete-skeleton enumeration dies) and the rep predicate
(`IntList p l`) is FORCED, not merely present.

**P08 list_reverse** (the Reynolds/O'Hearn classic; RefinedC ships it
as examples/reverse.c, BSD; text fresh). ∀ l (|l| ≤ 2^20), ∀ π
permutation (H2, as P07 — the summit must be dodge-proof): final heap
holds reverse l (readback walk). Forces: THE canonical SL proof —
invariant `IntList acc (rev visited) ∗ IntList p rest`, pointer
surgery, ownership passing between two partial lists, at a QUANTIFIED
skeleton. The corpus's summit together with P13.

**P09 call_contract** (fresh). ∀ a b with 0 ≤ a, 0 ≤ b,
a+b ≤ INT_MAX−2 (derived §0; the lower bounds close the x+y
UNDERFLOW hole — H4's finding, which my first amendment's upper-only
pre had left open; ~2^61 pairs): outcomes = {Specified (a+1+b+1)}.
bump's FnSpec `{p ↦ v ∗ 0 ≤ v ≤ INT_MAX−1} bump(p) {p ↦ v+1}` must
be CONSUMED at both call sites with the sibling cell FRAMED.
Q3 SETTLED [USER, via review]: NO mechanical gate — the in-file note
records that inlining is not a legitimate technique, with P10's
recursion (data-dependent call depth, non-enumerable domain) as the
structural backstop.

**P10 gcd_rec** (fresh, Euclid; the reviewer's DEFINITE
recommendation, A3 — the loop-variant/recursion-measure TWIN of P11,
sharing its model function). ∀ a b, 0 < a ≤ INT_MAX, 0 ≤ b ≤ INT_MAX
(full type range): outcomes = {Specified gcd(a,b)}. Forces: the
recursive call consumed via its own contract at the DATA-DEPENDENT
measure (b' = a mod b < b — no closed-form depth; neither domain
enumeration nor call-tree unrolling conceivable), the % side
conditions from the branch structure, and the P09 anti-inlining
backstop at full strength. FREEZE SIGN-OFF QUESTION (the one P10
decision, operator decides once): confirm gcd_rec (recommended) or
revert to the ALTERNATE rsum (p10alt_rsum_rec.c, retained with its
honest gray-zone remark; its T5-familiar model remains B4's natural
first warm-up instance either way).

**P11 gcd_iter** (fresh, Euclid). ∀ a b, 0 < a ≤ INT_MAX,
0 ≤ b ≤ INT_MAX (full type range, §0):
outcomes = {Specified (gcd a b)}. Forces: termination by well-founded
VARIANT (b strictly decreases; no closed-form trip count — the
documented gap in Seg.while_inv's explicit-n form), plus the %-UB
side condition discharged from the loop guard.

**P12 pt_midpoint** (derived arrow-access shape: CN, BSD-2). ∀ ax ay
bx by, |each| ≤ INT_MAX/2 (derived, §0): outcomes = {Specified 0}, where the harness
returns 9 if either INPUT struct changed (the frame is IN the
postcondition, observably) and 1 on a wrong midpoint. Forces: struct
field points-to; three-pointer disjointness; frame as a checked
observable.

**P13 cell_alloc** (fresh; RefinedC talk_demo_alloc shape, BSD).
∀ v ≤ INT_MAX−1 (derived, §0). CORE (unconditional): success outcome
= Specified (v+1); ownership birth at malloc / death at free; the
leak conjunct on every path. DESIGN-DEPENDENT clause (H8 — this
corpus does NOT pre-decide the standing SL-alloc design-evaluation
gate): if the evaluated model makes malloc failable, outcomes =
{Specified (v+1), Specified SENTINEL} and the null branch is live
(F1); if infallible, outcomes = {Specified (v+1)} and F1 is
withdrawn (matrix ◐). ⊆ resolves to = with that design decision.

**P14 count_pairs** (fresh). ∀ xs (|xs| ≤ 65536, derived §0):
outcomes =
{Specified #{(i,j) | i<j, xs[i]=xs[j]}}. Forces: nested invariants
(inner indexed by outer state), two symbolic indices, quadratic
count expressed as a pure model function.


**P15 scan_classify** (fresh; uri.c idiom — review §6 addition). ∀ s
with wf s = ∃ k < 2^20, s[k] = 0 (the NUL-witness precondition; bytes
full unsigned-char range): outcomes = {Specified (count of digit-class
bytes before the first NUL)}. Forces, in one ≤12-LOC row: the
NUL-termination loop discipline (deref safety from the ∃-NUL witness,
not an index bound — a different invariant discipline from P05),
unsigned-char→int widening at the switch scrutinee, and the switch
n-way Core shape.

## 3. Self-audit (step-3's four questions, per program — honest)

- Small but challenging? P01–P03, P09, P12: small and each isolates
  exactly one hard capability (case-split; UB arithmetic; alias
  case-split; contract consumption; frame-as-observable) — trivial
  for RefinedC, ALL currently unprovable here, which is the point.
  P04–P08, P11, P13, P14: small text, genuinely hard content
  (invariants over quantified data, rep predicates, measures,
  ownership). Nothing exceeds ~12 LOC of function body.
- Actually exercises the claimed families? The matrix row per
  program names them; the sharpest checks: P05's trip count depends
  on memory CONTENTS (not just a length parameter), P03 forces both
  alias arms of one theorem, P09's anti-inlining is handled per the
  SETTLED Q3 (operator ruling: in-file note, no mechanical gate) with
  P10 gcd_rec as the structural backstop.
- On the way to a verifier? The 15 rows are the uri.c/pKVM idiom
  set minus concurrency (locks are chartered separately) and minus
  function pointers (deferred, Q2). Passing all 15 at these
  statements = per-construct symbolic rules + assertion layer +
  case-split + call rule + rep predicates + measures exist and
  compose — which IS the assessment's B-plan acceptance, restated as
  theorems.
- Concrete-input residue? (Samples now oracle-executed, 15/15
  Specified(0) — the H5 class is closed by execution, not by claim.)
  The `main()` bodies and spliced literals
  are oracle-differential samples ONLY (model-validation ledger) and
  representative splice instances; NO theorem pins an input literal.
  Every bound obeys the §0 anti-brute-force ruling: full type range
  or a type-derived limit with its derivation inline; the ARENA
  constants are sample plumbing (the splice emits exact-size arrays),
  and P13's SENTINEL is a fixed error code in the spec function, not
  a domain bound. No enumerable domain exists in any theorem.

## 4. What today's substrate can/cannot do (per the assessment — the
corpus is NOT trimmed to this; it defines the build)

| program | provable today? | binding gap |
|---|---|---|
| P01, P02 | NO | case-split at symbolic data (B2's heart) |
| P03 | NO | assertion layer + alias case-split |
| P04–P06, P14 | NO | symbolic array indexing + assertion-layer invariants (B1/B2; array lane) |
| P05 | NO | + contents-dependent trip count (∃-round helps; invariant form needed) |
| P07, P08 | NO | rep predicates over heap structures (B1/B5) |
| P09, P10 | NO | call rule (blocked on are_compatible totalization) + contract consumption (B4) |
| P11 | NO | variant-based termination (documented while_inv gap) |
| P12 | NO | struct field assertions + frame-as-observable (B1) |
| P13 | NO | ownership/alloc-free + leak conjunct machinery + alloc-ND (design-eval gate) |

| P15 | NO | NUL-witness invariant discipline + conversions + switch shape (B2) |

Zero of FIFTEEN provable today. That is the corpus doing its job.

## 5. Open questions — status after the step-3 review

- Q1 SIZE: **15 programs** (387 total lines with headers incl. the
  alternate file) — the review's
  recommendation (14 revised + P15), adopted. Every family column has a
  forcing row; no filler.
- Q2 DEFERRED FAMILIES — CONFIRMED, list ENLARGED per review §6 and
  recorded AS DECISIONS: function pointers (RefinedC binary_search
  class; libxml2's SAX layer will force it eventually — uri.c-first
  avoids it); concurrency (chartered cmm/pKVM lanes); unresolved
  SYMBOLIC may-alias (first memmove-shaped target); unsigned
  wraparound arithmetic (defined-overflow ring — natural at
  pKVM/WireGuard hash targets); mutable globals / static state across
  calls (pKVM lane; const-embedding harnesses already force global
  READS); break/continue (F4 vocabulary variant — return-from-loop
  covers the family; optional recast of P05 at freeze); goto (libxml2
  error paths, deferred to that rung explicitly).
- Q3 P09 ENFORCEMENT — **SETTLED by operator ruling** (no-gate-grind):
  NO mechanical gate; the in-file note (inlining is not a legitimate
  technique) + P10's recursion as structural backstop (its
  non-enumerable domain is what makes the backstop real — the review's
  H3 condition, satisfied at full strength by gcd_rec).
- Q4 P13 ALLOC — keep malloc (review concurs: real-C fidelity, libc
  lane standing), WITH the H8 scoping: the failure-outcome clause is
  design-dependent pending the chartered SL-alloc evaluation.

## 6. Freeze-text obligations (from review §8, carried to step 4)

(a) all samples oracle-executed before freeze — DONE for v2 (§7);
(b) every constant listed with a one-line justification — §0;
(c) each memory program's wf pinned + the ≥2-witness anti-vacuity
obligation (plant-test doctrine applied to the domain: kernel-checked
inhabitation by two wf-instances with DIFFERENT modelFn values; for
P07/P08 the two witnesses must additionally carry two DISTINCT
PERMUTATIONS π — review n2 — so the skeleton quantification is
witnessed non-degenerate, not payload-only) —
carried as a freeze deliverable per program (H9), with the honesty
note that each const-embedding proof crosses THREE loops (decode,
compute, readback);
(d) the acceptance bar per program = the marginal-cost/legibility
standard (spec + invariants + automation; professor-readable) so a
grind pass cannot count as a pass;
(e) the §5-Q2 deferral list recorded as decisions;
(f) the corpus is the donors' paper-example tier by design — passing
15/15 is necessary-not-sufficient; the libxml2 rung remains the
graduation test (review §5 calibration, stated plainly).

## 7. Delta summary — step-3 review findings × disposition (v2)

| Finding | Disposition |
|---|---|
| H1 CAP=8 unrolling channel | SUPERSEDED-BY-RULING (anti-brute-force): bounds now type-derived/2^20-scale — strictly stronger than the review's CAP=100 fix; unrolling dies harder |
| H2 concrete heap skeleton (P07/P08) | APPLIED: quantified link-order permutation in the encoding + wf; rep predicates now FORCED (files + §2 updated) |
| H3 P10 finite-sample domain | RESOLVED in two moves: (v2) factorial→recursive sum killed the 13-point domain; (polish, per re-review A3) the RECOMMENDED row is now gcd_rec (full range, ≥2^32 points, data-dependent measure, no closed form) with rsum retained as the clearly-marked ALTERNATE (p10alt_rsum_rec.c) carrying its honest gray-zone remark. The one freeze sign-off decision: gcd_rec (recommended) vs rsum |
| H4 P13 false at INT_MAX | ALREADY-SATISFIED-BY-AMENDMENT (v ≤ INT_MAX−1, derived §0) |
| H4 P09 underflow hole | APPLIED (beyond my first amendment, which fixed only the overflow side): pre now 0 ≤ a,b ∧ a+b ≤ INT_MAX−2 |
| H5 P05 wrong sample | APPLIED: expected_idx 3→2; ALL 15 samples oracle-executed (--exec --batch; P13 via libc mode), 15/15 Specified(0) |
| H6 P03 F9 over-claim | APPLIED: relabeled "both alias arms in one theorem" (matrix + section + in-file note); unresolved symbolic may-alias recorded as deferral |
| H7 constants undercount | ALREADY-SATISFIED-BY-AMENDMENT (§0 inventory) + APPLIED: P09's arbitrary BOUND eliminated (type-derived pre); P11/P12 pins in §0 |
| H8 P13 pre-decides alloc-ND gate | APPLIED: core clause unconditional; failure clause DESIGN-DEPENDENT; F1 cell ◐; ⊆→= resolution deferred to the design decision |
| H9 wf/codec degeneration risk | APPLIED as freeze obligation (§6c): wf pinned per program + 2-witness anti-vacuity, bounds per the anti-brute-force retro-application; three-loop price note carried |
| §4 P02 short-circuit bonus | APPLIED: recorded in P02's header + matrix family F15 |
| §6 missing families | APPLIED: P15 added (NUL + conversions + switch in one row); deferral list enlarged and recorded (Q2) |
| §7 Q1/Q2/Q3/Q4 | APPLIED as settled/updated in §5 |
| §8 freeze-text additions (a)-(e) | CARRIED into §6 as step-4 obligations; (a) already executed for v2 |
| A-n1 stale v1 text (§3 Q3-open, "14 rows") | APPLIED — §3 rewritten (Q3 settled wording, 15 rows) |
| A-n2 π-witness strengthening | APPLIED — §6c: P07/P08's two anti-vacuity witnesses must carry two DISTINCT permutations |
| A-n3 ARENA honesty | APPLIED — §0 states |xs| ≤ 2^20 as the wf capacity bound (theorem content), not "plumbing" |
| A-n4 single-arena provenance | APPLIED — in-file notes on P07/P08 (offset-level skeleton; per-allocation ownership is P13's row) |
| A3 P10 candidate | AUTHORED — p10_gcd_rec.c as P10 (RECOMMENDED), oracle-run Specified(0); rsum demoted to ALTERNATE, still oracle-green; sign-off question stated in §2 P10 |
