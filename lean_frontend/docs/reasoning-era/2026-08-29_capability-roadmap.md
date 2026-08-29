# Capability roadmap — donors, construct coverage, and the path to 15/15

STATUS: PLANNING DOCUMENT for operator discussion (not a charter;
nothing here executes without the conversation). Commissioned
[USER 2026-08-29]: (1) assess where we are vs the goal of matching
BRiCk/RefinedC in capabilities and general reasoning strategy (not
design nits); (1b, operator addendum) the dual-level CONSTRUCT
COVERAGE TABLE; (2) per-limitation build-outs toward a legitimate
functional program logic; (3) a roadmap with parallel threads.

Ground truth: branch `arc/segment-ladder` @ 6aaed9152 (post-V3a2 park
+ hygiene commit). Evidence sources cited throughout: Audit.lean pins
(the proved set and the 31-row slate are read from the gate file, not
from memory), the V-slice records (V0…V3a2), the cargo-cult spot
audit (notes/2026-08-29_cargo-cult-spot-audit.md), the perf plan +
review, the frozen corpus (lean_frontend/corpus/), and the donors'
own example corpora (deps/refinedc/examples/, deps/BRiCk,
deps/brick-wp).

---

## 0. The scoreboard (verified against Audit.lean pins)

PROVED, cone exactly {propext, Classical.choice, Quot.sound},
`#guard_msgs`-pinned in-build (Audit.lean:337–371):

| Theorem | What it is |
|---|---|
| `T1.t1_threaded_proved` | flagship: id through the full caller protocol |
| `T2.t2_threaded_proved` + UB twin | checked add (overflow side conditions) |
| `T3.t3_threaded_proved` + UB twin | create/store/kill memory roundtrip |
| `P01.p01_proved` + UB twin | **corpus row 1**: ∀x clamp = max(x,0) — the emblem |
| `P02.p02_proved` + UB twin | **corpus row 2**: ∀a,b saturating add (4 paths, sequenced-&&) |
| `M1.m1_proved` | the PERF-2 exit specimen (pre-registered, 5 ≤ 6 anchors) |

HONEST-UNPROVED statements (slate-registered, Audit.lean:784–809):
T4/T5 (statement-only since V0; both blocked on the consistency
bridge), P03/P09–P12 (batch A), P04–P08/P14/P15 (batch B).
Unregistered: P13 (V0 finding — malloc linkage, waits on V5's
alloc-ND gate) and M1Statement (spot-audit F3 — its file term is
homed proof-side; registering it trips the statement-TCB gate, which
is the gate being right; fix = re-home, polish basket).

**Corpus: 2/15 proved + the exit specimen; 4 flagship theorems; every
cone the classical trio; zero axioms; zero budget registrations.**

---

## 1. Capability assessment vs BRiCk / RefinedC

Method: the donors' capability is evidenced by what their example
corpora actually verify (RefinedC examples/: binary_search, btree,
queue, quick_sort, mpool, mutable_map, malloc1, lock/latch/spinlock,
intptr, wrapping_add, talk_demo_alloc, VerifyThis2021; BRiCk: C++
object model, ctors/dtors, templates-adjacent metatheory, concurrency
logic; brick-wp: persistent-bst). "General reasoning strategy" means
their shared shape: **human content only at contracts + loop
invariants; everything between discharged by goal-directed automation
over per-construct rules; framing ambient.**

| Axis | Donors (evidence) | Us (evidence) |
|---|---|---|
| Scalar/branch programs | trivial for both (paper examples) | **PROVED** (P01, P02, m1) — same proof shape: spec, case-split, arithmetic |
| Reasoning strategy: contracts+invariants only, auto between | Lithium / wp_auto | **MATCHED IN SHAPE** at the proved rows (`verify_fn`; `seg_run_c`; `by_cases`; `seg_done`); anchors are our per-branch human content — F1 says fuse them into a minter (donors have no per-program guard cost) |
| Loops + invariants | binary_search, quick_sort | **PARKED at the consistency bridge** (machinery landed: Seg.iter/first_exit, guard anchors, all mint classes; T5 walk mints 34/34 prologue + complete F-arm) |
| Termination (total correctness) | NOT a donor capability (partial WP) | variant rule core landed (`first_exit`); P11 parked on the same bridge. We exceed the donors on this axis by house choice |
| Early exit / multi-exit | yes | **MACHINERY LANDED** (V2 zero-interior-iteration compositions; the m1/x-era pattern) — no current corpus row pending on it |
| Calls with contracts | every multi-function example | **MISSING at internal calls** (V4): caller protocol exists for the harness's top call; Eccall frames + FnSpec consumption at real call sites unbuilt; `are_compatible` partial-def gates minting (V0 census) |
| Recursion | btree, quick_sort | **MISSING** (V4, P10 gcd_rec) — contract-as-induction-hypothesis; same frame machinery as calls |
| Arrays at symbolic index | binary_search, mpool | **PARKED** (R6b-era wall: `PEarray_shift` pure-eval at open anchors; 2 of 3 walls fixed then) → V3b; rows P04–P06, P14 |
| Structs | container_of, btree | **MISSING** (`PEmember_shift`/`PEstruct` vocabulary) → V3b; row P12 |
| Pointer aliasing | pointers.c | **MOSTLY HAVE** (case-split + mem rules; P03's may-alias arms are branch content); P03 parked only on its internal ccall (V4) |
| Linked structures / rep predicates | btree, queue, brick-wp bst | **MISSING** (V5): lseg-class predicates over the π-quantified arenas; rows P07/P08 |
| malloc/free ownership | malloc1, mpool, talk_demo_alloc | **MISSING** (V5): Alloc0/Kill-dynamic actions + ownership birth/death + the operator-gated alloc-ND design evaluation; row P13 |
| Strings / NUL scan | (weak in RefinedC examples; uri.c-class is OUR target) | **MISSING** (P15/P05 tier, rides V3b) — our bridgehead axis toward libxml2 |
| Integer side conditions (overflow/UB) | wrapping_add, tests.c | **PROVED** (P02/T2 — the guard/conv ladders); F1: needs the once-proved minter |
| ptr↔int casts | intptr.c (RefinedC has it) | post-corpus (PNVI territory; honest gap, uri.c census decides) |
| Concurrency | RefinedC: spinlock/lock; BRiCk: yes | **DEFERRED BY RULING** (cmm arc; weak-memory logic = its own future program) |
| Trust | typed rules trusted / axiomatized wp | **EXCEEDS DONORS**: every rule a kernel theorem over the independent executable semantics (professor-audit confirmed; 3 kernel-backstop saves this week) |

Summary judgment: at the rows we have proved, the reasoning strategy
is the donors' (confirmed by the substance audit's proof-reading
test). The distance is **coverage, not strategy**: four vocabulary
tiers (bridge-gated loops, arrays/structs/strings, calls, heap
ownership) separate us from their example-corpus reach — plus our
per-program guard/coda/protocol costs that the F1/F2 fusion items
retire.

---

## 1b. THE CONSTRUCT COVERAGE TABLE (the roadmap's backbone)

### Level 1 — Core-construct rule census

Mechanical basis: the registry census (Audit.lean:1267 — 501 laws:
`construct 12, segLink 15, segBlock 18, stateWP 24, memRW 21,
memBlock 7, evalPull 9, evalArith 2, envMap 7, envAlg 3, advance 5,
perform 6, loop 1, famInv 8, roundGlue 3, roundEq 356` — the last
being per-program supply scheduled to shrink as mechanism C widens),
the CStep package (`cstep_tau/eval/rs_tau` + the V3a2 call/case
leaves), and the link/mint classes (SegRun.lean:602–1525:
`link_ctl/_env1/_env2/_rebind1/_rebind2/_birth1/_birth1_env1/_birth2/
_load/_ctl_sup/_ctl_sup_draw/_store/_create/_kill`).

**Pure expressions (`generic_pexpr_`, generated/Core.lean:683–715):**

| Construct | Status | Evidence / owner |
|---|---|---|
| PEsym | **HAVE** | env lookup: envMap laws + seg_env_lookup + coherence reads (link_ctl_env1/2) |
| PEval | **HAVE** | trivial eval class |
| PElet | **HAVE** | bind/birth classes (link_birth*, rebind for re-binds) |
| PEif | **HAVE** | the by_cases path-condition idiom (V2) |
| PEcase | **PARTIAL** | `se_case_sel` + case-split for the exercised pattern shapes (bool/specified/tuple); general nested patterns as-encountered |
| PEctor | **PARTIAL** | tuple/specified ctors (se_ctor_tuple, ctor2 leaves); array/list/ivXXX ctors → V3b as encountered |
| PEop (binops) | **HAVE** | evalArith + the guard/compare ladders (P01 R10 chain, value-generic since V3a2) |
| conv/catch (integer conversions) | **HAVE, template-stamped** | T2/P02/m1 ladders; the r127 primitive-vs-call-form lesson; **F1 minter owed** |
| PEnot | **HAVE** (eval class) | |
| PEis_scalar/integer/signed/unsigned, PEconstrained, PEimpl | **PARTIAL** | eval-class, as-encountered; no corpus row pends on them |
| PEundef / PEerror | **HAVE** | UB outcome classification (the UB-twin machinery) |
| PEcall (pure stdlib defs) | **PARTIAL** | V3a2 step-then leaves (m1's conv_loaded_int); `params_length/_aux/_nth` emitted (x3Stdlib); **blocked in general by `are_compatible` partial def → V4-lem** |
| PEmemop (pure memops: compat/ptr rel) | **PARTIAL** | `mem_pvfd_block` (R6b); `are_compatible` = the V0-census totalization item (V4-lem); ptr-diff/rel as encountered (V3b/V5) |
| PEarray_shift | **MISSING (the named wall)** | R6b park: pure-eval at open anchors — **V3b item 1**; rows P04–P06/P14/P15 |
| PEmember_shift | **MISSING** | struct offsets — **V3b item 2**; rows P12, P07/P08 |
| PEstruct / PEunion / memberof | **MISSING** | PEstruct → V3b (P12); PEunion → post-corpus (nothing owns; uri.c census decides) |

**Effects (`generic_expr_`, generated/Core.lean:1205–1243):**

| Construct | Status | Evidence / owner |
|---|---|---|
| Epure | **HAVE** | eval rounds/cstep_eval |
| Esseq / Ewseq | **HAVE** | ctl/bind round classes + the pattern-bind births; (T5's wseq-at-draw is the bridge's *statement* wall, not a missing rule) |
| Eunseq | **PARTIAL — honest flag** | the elaborated sequenced shapes are covered (P02's &&); TRUE unsequenced interleavings are resolved by the runner's order semantics-side; proof-side interleaving rules: nothing owns — post-corpus, cmm-adjacent |
| Eif / Ecase / Elet | **HAVE** | as pexpr counterparts at expr level |
| Eaction Create / Store0 / Load0 / Kill(static) | **HAVE** (V3a2) | link_create/store/load/kill + minters; HeapLang-lineage round rules (V2 T3) |
| Eaction Alloc0 (malloc) / Kill(dynamic) (free) | **MISSING** | **V5**; row P13 (+ its statement registration) |
| Eaction CreateReadOnly | MISSING (as-encountered) | no row pends |
| Eaction SeqRMW/RMW0/CAS/Fences/Linux* | **DEFERRED BY RULING** | cmm arc (concurrency) |
| Ememop (PtrValidForDeref, …) | **PARTIAL** | pvfd law exists; remaining memops V3b/V5 as rows force them |
| Eccall / Eproc (internal calls) | **MISSING (frames)** | caller protocol covers the harness top call only; bodyK re-entry/call-return frames = **V4**; rows P03/P09/P10 |
| Esave / Erun | **HAVE** | label rounds + the REBIND class (V3a2) + loop layer (Seg.iter/first_exit) |
| Ebound | transparent | runner-level; no dedicated rule needed to date (as-encountered) |
| End (nondet choice) | **MISSING proof-side** | corpus deterministic; exhaustive runner owns it semantics-side; proof-side ND rules post-corpus (cmm formulation) |
| Epar / Ewait | **DEFERRED BY RULING** | cmm |
| Eannot / Eexcluded | transparent / as-encountered | |

### Level 2 — C features → Core vocabulary → status today

| C feature | Elaborates into | Status / closing item |
|---|---|---|
| int types + arithmetic + overflow UB | PEop + conv/catch ladders + Store/Load | **COVERED** (P01/P02/T2) |
| `&&`/`||` short-circuit | nested PEif/wseq | **COVERED** (P02 — falls out of case-split, verified) |
| if / else | Eif/PEif | **COVERED** |
| switch | PEcase/Ecase chains | machinery partial → **P15 (V3b tier)** |
| while / for / do-while | Esave/Erun + guard | rules landed; theorems gated on **the consistency bridge** → then assembly (T5/P11/P14) |
| goto (general) | Esave/Erun general labels | post-corpus (uri.c census decides; loop-shaped labels covered) |
| locals, assignment | Create/Store/Load/Kill + binds | **COVERED** (T3 + prologues) |
| arrays, indexing, ptr arithmetic | PEarray_shift + computed-offset Load/Store | **V3b** (the R6b wall) → P04–P06, P14 |
| structs (field access) | PEmember_shift/PEstruct | **V3b** → P12 (arena structs → V5 P07/P08) |
| unions | PEunion | post-corpus — nothing owns (flagged) |
| pointer aliasing | ptr-eq memops + case-split | mostly covered; P03 blocked by its call, not aliasing |
| function calls + recursion | Eccall/Eproc | **V4** (+ lem totalization) → P03/P09/P10 |
| function pointers | PEcfunction/cfunction memops | post-corpus (flagged) |
| malloc / free | Alloc0 / Kill-dynamic | **V5** → P13 |
| strings (NUL discipline) | uchar arrays + scan loops | **V3b string tier** → P15/P05; the uri.c bridgehead |
| casts (scalar) | conv ladders | covered class |
| casts (ptr↔int) | PNVI memops | post-corpus — honest gap (RefinedC's intptr.c has this; uri.c census decides urgency) |
| floats | float ops | post-corpus — nothing owns (no corpus row; flagged) |
| varargs | — | post-corpus (flagged) |
| concurrency (threads/atomics) | Epar/Ewait/RMW/fences | **deferred by ruling** (cmm arc; weak-memory logic its own program) |

Classification legend used above: corpus-covered / bridge-gated /
V3b / V4 / V5 / post-corpus (uri.c-census-driven backlog) /
deferred-by-ruling. Every roadmap item in §3 cites the rows it
closes.

---

## 2. Per-limitation build-outs

Price calibration, stated honestly: measured slice history says our
M-estimates run hot ~1.5–2× (V2's P02 exit slid a slice; V3a's T5
remainder re-priced M-L mid-flight; the V3a2 wall consumed the rest).
Prices below are POST-calibration (i.e., already inflated); "slice"
= one worker session at the current cadence incl. orchestrator
verification.

**B1 — The consistency bridge (route A)** — the T5/P11/T4 unblock.
What: a proof-layer guarded family (the seed-indexed `FnSpec.guard`
slot, reserved at V0 for exactly this) + ONE new adequacy theorem
transporting guarded-Thr to the frozen Cns face, via window-apartness
`[seed, seed+B)` with the guarded walk strengthened to conclude
`final sym_supply = seed + B` (consistent ⇒ clean path ⇒ exactly B
draws). Classical name: **refinement of nondeterministic freshness by
a bounded-counter implementation** — the operator's own August
can't-happen-ND design; the anti-vacuity metatheorem pattern already
proved at V0. Lineage: assume-guarantee conditioning; the arc-16
spike. Retires the long-standing T4-apartness M-item. Price: **M
(calibrated 1–1.5 slices)**. Closes: T5, P11, T4 (+T4 UB) — 2 corpus
rows + 2 flagship statements. Table rows: the while/for row's gate.

**B2 — The polish basket (professor F1/F2/F3 + monolith)** — the
before-any-fourth-program condition. What: (i) the guard/branch
MINTER (file-generic conv/compare characterization — `conv_int` is
the same stdlib body in every file; kills the ~700-line per-program
guard template; classical name: lemma-schema instantiation /
universe-closure of the ladder family); (ii) seg_done coda auto-fill
+ caller-protocol fusion (the stepper already computes the 14
coordinates it makes humans transcribe; staging, same as block
supply); (iii) M1Statement re-homing statement-side + registration
(the F3 gate lesson); (iv) SegStepper 8-module decomposition (named
in the audit note; reviewability, not behavior). Price: **M
(calibrated 1 slice)**. Closes: no rows directly; conditions all of
V3b/V4/V5; F1 also retires the anchors' per-program cost that keeps
proof files above the 250-line registration bar.

**B3 — Arrays, structs, strings (V3b)** — the widest vocabulary
tier. What: `PEarray_shift` evaluation at open anchors (the R6b
wall's third leg — the construct-lemma treatment now exists to host
it properly), element points-to views with carve-out/recombine
(classical: iterated separating conjunction over arrays — the
standard Iris `array` module shape, gen_heap lineage),
`PEmember_shift`/struct field views (RefinedC struct fields
lineage), the switch/`Ecase` chains and uchar widening for the
string tier. Price: **L (calibrated 2–3 slices; the biggest
remaining block)**. Closes rows: P04, P05, P06, P12, P14, P15 — six
rows, the uri.c bridgehead. Table rows: arrays/indexing, structs,
switch, strings.

**B4 — Calls (V4)** — two half-independent legs. Proof-side: call
frames (Eccall/Eproc entry/return as ctl-token discipline over
bodyK re-entry — the V3a2 record's named round class), FnSpec
consumption at call sites (the Hoare procedure rule + frame — landed
in form at R2, needs its first real instance), recursion as
contract-with-measure (P10's gcd_rec, sharing P11's variant). Price:
**M (calibrated 1–1.5 slices)**. Lem-side (THREAD B, parallel):
`are_compatible` (+ the V0-census fold family) totalized in the
model — lem-side fuel per the operator's "total in the proper way"
ruling + prelude regen + zero-movement differential verification.
Price: **M (1 slice, different toolchain — parallelizable from day
1)**. Closes rows: P03, P09, P10. Table rows: calls/recursion,
PEcall/PEmemop-compat.

**B5 — The heap summit (V5)**. What: rep predicates over the
π-quantified arenas (`isList`/`lseg` — Reynolds/O'Hearn, brick-wp
bst and RefinedC btree as donors), ownership birth/death for
Alloc0/Kill-dynamic (gen_heap alloc/dealloc lineage), the leak
conjunct's proof face, P13's statement registration (the V0
finding), and — FIRST, as the operator gated it — the **alloc-ND
design evaluation vs Caesium** (the standing August ruling: evaluate
the SL-allocation story against address observability/PNVI, alloc
failure, finite space, id reuse before executing). Price: evaluation
S (read-only + discussion) + **L (calibrated 2–3 slices)**. Closes
rows: P07, P08, P13 → **15/15**. Table rows: malloc/free, linked
structures, arena structs.

**B6 — Standing small items** (thread B / D fillers): the
`runEffectful` lem deletion (V0 census: 1 site deletable now, 8 ride
the supply-threading — S, lem-side); PERF-3 opacity+parallelism
(optional, only if the timing lane shows regression — S); the
partial-safety statement form for forever-loops (FUTURE — flag only,
needed at kernel targets, expressible over the same runner as a
∀-fuel prefix claim; nothing in the corpus needs it); the V6
endgame: full professor pass at 15/15, docs/PROOF.md truth pass,
playbook for the segment idiom, the audit + merge asks (M).

Superseded-plans note: the 2026-08-27 infrastructure plan remains
the governing frame but three parts are overtaken and should be read
via this document: V3a was reshaped by the PERF fold (executed);
component H is being delivered continuously (stepper + fusion), not
as a slice; B6/purge was absorbed by V0's kill basket. V3b/V4/V5
below are this document's re-derivations.

---

## 3. The roadmap

### Threads

- **THREAD A (the heavy Lean lane — serial on the box, one worker):**
  A1 bridge (B1) → A2 T5+P11+T4 assembly (S–M each with the bridge +
  landed anchors) → A3 polish basket (B2; MUST precede the fourth
  program's guard stamping) → A4 arrays/structs/strings (B3) → A5
  calls proof-side (B4a; requires THREAD B's totalization MERGED) →
  A6 heap summit (B5, after the alloc-ND conversation) → A7 V6
  endgame.
- **THREAD B (lem/OCaml toolchain — genuinely parallel, different
  build system, starts NOW):** B4b `are_compatible`+fold totalization
  (gates A5, so it must land before thread A reaches V4 — ~3 slices
  of headroom) → runEffectful lem-slice → the pin dance at its merge
  point.
- **THREAD C (read-only/design — parallel always):** the alloc-ND
  design evaluation document (due before A6 opens; the operator
  conversation is its exit), the uri.c post-corpus census refresh
  (the deferred-tail backlog: unions/fn-ptrs/goto/floats/ptr-int
  casts/varargs — priced when the capstone planning starts), V6
  professor-pass prep.
- **THREAD D (docs/hygiene riders):** PROOF.md currency at each
  A-close; the mid-point professor sample (see Q3).

### Dependency graph

```
B1 bridge ──→ A2 {T5, P11, T4} ──→ A3 polish ──→ A4 {P04,P05,P06,P12,P14,P15}
                                        │                │
THREAD B totalization ──────────────────┼────────→ A5 {P03,P09,P10}
                                        │                │
THREAD C alloc-ND evaluation ──→ (operator gate) ──→ A6 {P07,P08,P13} → 15/15
                                                             │
                                                     A7 V6: professor pass,
                                                     docs, audit + merge asks
```

Critical path: **B1 → A2 → A3 → A4 → A5 → A6 → A7** (thread B and C
items sit off-path if started promptly; B4b has ~3 slices of slack).

### Calibrated envelope

7 heavy slices on the critical path (1 + 1 + 1 + 2.5 + 1.5 + 2.5 +
1, calibrated) ≈ **9–12 worker-days at the measured cadence**, with
thread B (~2 slices) and thread C (documents) absorbed in parallel.
Historical honesty: every envelope this project has stated has been
optimistic before calibration and roughly right after it; the two
L-blocks (B3, B5) carry the residual risk, and both have named walls
rather than unknown unknowns.

### Catechism §VI self-check (applied to this plan)

Every build-out serves ∀-statements over the frozen corpus (Q1);
costs amortize — each tier is once-proved vocabulary + the F1/F2
fusions exist precisely to kill the remaining per-program costs (Q2);
every mechanism carries its classical name and donor lineage in §2
(Q3); the proved rows already pass the professor's reading test and
B2 exists to close the gap at the boundaries (Q4); no enumeration —
the corpus's anti-brute-force bounds stand, and the roadmap's only
generated artifacts (round supply) are scheduled to shrink under
mechanism C (Q5); the bridge wall was reported, not pushed (Q6); no
trust-surface change anywhere — statements frozen, cones trio,
`are_compatible` totalization is a model change verified by
zero-movement differential, the one legitimate trust-adjacent move,
done "in the proper way" per the ruling (Q7).

---

## 4. Operator questions (recommendations attached)

1. **Confirm route A for the consistency bridge** (recommended; the
   park record's route B — observation-extended transport — is
   deeper adequacy surgery for the same theorem and both the worker
   and orchestrator lean reject).
2. **Alloc-ND design evaluation timing**: thread C starts the
   document now, the operator conversation happens at A6-open
   (recommended — it gates only P07/P08/P13 and nothing earlier);
   alternative: have the conversation early if you want the heap
   design influencing B3's element-view shapes.
3. **Professor cadence**: recommended a cheap SAMPLE pass after A4
   (arrays tier — the next genuinely new proof idiom) with the FULL
   V6 pass at 15/15; alternative: single pass at the end.
4. **Confirm the B2-before-fourth-program condition as binding** on
   thread A's order (recommended; it is the professor's F1/F2
   amortization condition and the down-pressure ruling applied).
5. **P13 statement registration at A6-open** (standing V0 finding —
   recommended timing unchanged).
6. **The post-corpus tail** (unions, function pointers, general
   goto, floats, ptr↔int casts, varargs, true-unseq/End proof rules):
   confirm these stay uri.c-census-driven backlog — priced at
   capstone planning, not built speculatively (recommended;
   corpus-as-scope-fence).
7. **Thread B start**: authorize the lem-side totalization worker to
   start immediately in parallel (recommended — it is the only item
   with a hard downstream gate and it is toolchain-independent).
