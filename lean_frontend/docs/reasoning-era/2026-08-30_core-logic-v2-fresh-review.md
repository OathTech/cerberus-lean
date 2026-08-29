# Fresh full review — The Core Program Logic, paper design v2

REVIEWER: independent fresh-eyes pass (commissioned [USER 2026-08-30]:
"check that the logic design is coherent with what Cerberus gives us,
will work, sound, gives us a clean Iris-based logic… we should make
sure we get fresh eyes, this is the core document for the whole
effort."). READ-ONLY review; no builds. All findings below were formed
from primary sources BEFORE reading the prior review
(`notes/2026-08-30_core-logic-paper-review.md`); the cross-check
against that review and the §H amendment log is confined to §9, written
last. Primary sources examined directly: the generated live engine
(`Core_reduction.lean`, `Driver.lean`, `Core_aux.lean`,
`Core_run{,_aux}.lean`), the memory model (`CerbMem.lean`),
`Mem_common.lean`/`Undefined.lean` (UB tables), elaborated dumps
(`tests/corpus/p01_clamp.core`, `p05_find_first_funs.core`), the donors
(`deps/refinedc/theories/{typing/programs.v,typing/function.v,
caesium/lang.v,caesium/ghost_state.v}`,
`deps/BRiCk/…/logic/{wp.v,stmt.v}`), the catechism
(`docs/2026-08-27_design-catechism.md`), and the frozen corpus
(`docs/2026-08-27_target-corpus.md`). Line citations verified at the
worktree `worktrees/cerberus-lean-coherence`.

## 0. Verdict

**RATIFY-WITH-AMENDMENTS.** The architecture is right: the three
judgments cut by Core's own grammar, contracts-primary with a
function-scoped label environment, substitution-everywhere with the
environment as engine, the join-time-race reading of Eunseq under a
∗-rule, UB-as-⊥ over the model's own error table, and a first-class
∀-state adequacy theorem — every one of these I verified against the
executable model and the donors, and every one holds up. The document
is honest about its hard parts and its seams are real. It is the right
foundation.

It is not ratifiable as it stands, for three reasons, each with an
exact fix and none requiring redesign:

1. **The totality discipline has one remaining hole (E14 fall-through
   entry) that re-admits total-wp of divergence** — the same defect
   class v2's own amendment log says was closed. Nested loops already
   trigger it. Exact fix known (route fall-through through K.run).
   §2 FR-1.
2. **The B.4/B.3 model-fidelity discipline (the paper's own B.5 rule)
   was applied at the two rows where v1 was caught, not swept across
   the table.** I found the same defect class — premises/descriptions
   naming behavior the implemented model does not have — at M1/M2
   (which as described is UNSOUND, not merely incomplete), M3–M6, M12,
   M14, P9, A5, M10, M21. §2 FR-2.
3. **The A1–A3 `canAlloc` question (V4) is answerable today by
   inspection, and the answer kills the hopeful branch**: the model has
   a bounded address space and a reachable out-of-memory kill;
   `canAlloc(n, al)`'s stated signature cannot express the actual
   failure condition, and Create appears in the prologue of every
   elaborated call, so this is on the critical path of all 15 corpus
   rows. §2 FR-3.

Everything else is either verified correct (§3) or a figure-hygiene
amendment (§2 FR-4 onward).

## 1. What I verified about the model (the facts the review rests on)

Stated so the findings are checkable; all read directly from the
generated code.

- **Inventory**: pexpr **29** (`generated/Core.lean:733`), expr **19**
  (:1249), actions **15** (:1032), ctors **17** (:524), binops **14**
  (:177), memops **22** including `Copy_alloc_id` and
  `CHERI_intrinsic` (`generated/Mem_common.lean:570`). The paper's
  counts are exact.
- **Engine of record**: `Driver.driver2` (Driver.lean:384) steps
  threads via `Core_reduction.step_ctx` (Core_reduction.lean:484).
  `Core_run` survives only as env/stack helpers and the pexpr
  evaluators. The paper's Core_reduction-of-record claim is correct.
- **Unseq race machinery**: races are detected ONLY at the join —
  `do_race` (Core_reduction.lean:300) is called from exactly one place,
  `one_step_unseq_aux` (:345–349), which fires when all arms are
  irreducible, folding each arm's `dyn_annotation` footprints against
  the accumulated ones. `do_race` honors DA_neg exclusion-id waivers
  and calls `CerbMem.overlapping` (CerbMem.lean:1187–1191), which is
  R/W-aware (two reads never overlap). Race → `UNSEQUENCED_RACE` →
  UB035. The paper's schedule-independent-join reading is exactly
  right.
- **Annotation flow**: footprint annotations survive OUTWARD through
  both `Ewseq` AND `Esseq` ("lets pat = {A}v in E2 --> {A}{v/pat}E2",
  one_step0) — i.e. effects behind internal sequence points inside an
  unseq arm still race against sibling arms, which is correct C11 and
  exactly what E9a's whole-arm ∗-split requires. Annotations die at
  `Ebound` ("bound({A}v) -> v", step_ctx). Negative actions are walked
  to the enclosing bound/sseq by `break_at_bound_and_sseq` (:463) with
  exclusion ids; the named fail-stop holes are real
  (`failwithI "TODO: NO_BOUND (Neg)"`, negative SeqRMW
  `failwithI "TODO(better typing)…"`, both on line 484; also
  `"TODO: NO_BOUND (SeqRMW)"`).
- **Labels**: the live engine resolves `Erun` procedure-wide via
  `run_st.labeled`, a flat `Fmap sym (params × expr)` built by
  `Core_aux.collect_labeled_continuations` (Core_aux.lean:622) at
  driver start (Driver.lean:436). Crucially, its `Esseq` case wraps a
  label found in e1 as `Esseq pat cont e2` — **the label's continuation
  really is the procedure's continuation from the save point through
  the enclosing sequence**, as A.2 asserts. Its `Ebound` case returns
  `fmapEmpty` — labels under a bound are invisible (see FR-6c). Jump =
  replace arena with the continuation + bind label params; fall-through
  `Esave` evaluates the default pexprs and binds them (one_step0).
  Corpus dumps confirm forward jumps
  (`run ret_525 … ; … save ret_525:`), `undef(<<UB088…>>)` defaults on
  ret labels (and `Specified(0)` on main's), and loop labels passing
  unchanging pointers (`save while_641: unit (i: pointer:= i)`,
  `run while_641(i)` — p05).
- **Memory model**: concrete/PVI. `ptrfromint`
  (CerbMem.lean:1897–1909) never fails and passes the integer's
  provenance through; `intfromptr` (:1911–1925) fails only
  MerrIntFromPtr on range and carries the pointer's provenance in the
  IV. `combineProv` (:227–240) is the PVI merge. The allocator
  (`allocateObject`, :1469–1497) grows DOWN from
  `lastAddress = 0xFFFFFFFFFFFF` and **fails with
  `NDkilled (MerrOther "out of memory")` when the aligned address hits
  0** — allocation failure is reachable in the model of record.
  `killM` (:1520–1545): free(NULL) with Dynamic kind is
  **unconditionally** a no-op; `forbid_nullptr_free` exists only as an
  enum in CerbGlobal.lean:25 and is consulted NOWHERE; MerrFreeNullPtr
  is unreachable. `eqPtrval` (:1731) on concrete pointers of
  DIFFERENT provenance is a genuine **ND fork** (msum over
  {provenance-false, address-equality}); lt/gt/le/ge (:1770–1800) are
  the NON-STRICT variants — address comparison regardless of
  provenance, `MerrWIP` (not UB053) on null/function operands;
  `MerrPtrComparison` has no raise site. `arrayShiftPtrval`/
  `memberShiftPtrval` and their eff wrappers are UNCHECKED
  (`MerrArrayShift` has no raise site). `memcpyM` (:1945) is a
  per-byte checked load/store loop with **overlap-UB unimplemented**
  (its own header says so); `memcmpM` panics loudly on an
  uninitialized byte. `copyAllocId` (:2172) is
  `memReturn pv` — **the integer argument is discarded; the pointer is
  returned unchanged**. `validForDerefPtrval` (:1867) checks
  liveness + alignment (no bounds). `diffPtrval` (:1812) genuinely
  raises MerrPtrdiff (M7's premise is real).
- **UB dictionary**: `undefinedFromMem_error` at Mem_common.lean:392
  as cited; note `Free_out_of_bound → none` (an error with no UB
  classification — a killed-not-UB outcome class, relevant to ADQ
  wording, FR-7).
- **Donors**: every load-bearing citation checked and correct —
  `typed_stmt` with `Q : gmap label stmt` (programs.v:68),
  `typed_block` (:72), `typed_val_expr` (:96–97), `typed_function`
  (function.v:59, □-persistent, spec-indexed), `PtrOffsetOp`
  (lang.v:246), `CallFailS`/`AllocFailed`-by-fiat (:471–476, :493),
  `BinOpLCtx/RCtx` fixed order (:588–589), `alloc_alive`
  (ghost_state.v:92); BRiCk `Kpred`/`ReturnType` (wp.v:124–140),
  `nd_seq` (wp.v:290, binary demonic-two-orders), `Mpar`
  (wp.v:496–497, "like the semantics of argument evaluation in C",
  separable resources), `Parameter wp_lval` (wp.v:631), the
  infinite-loop-removal caveat (stmt.v:461–464), `Kloop` + Löb
  (stmt.v:467–495), `Axiom wp_while_unroll` (stmt.v:483).
- **Sequentialise**: Main.lean's only sequentialise references are the
  oracle's pre-sequentialised libc dump; user code runs
  live-unsequenced. The §D mode-of-record pin is describing a real
  fork in the semantics; the pin is genuinely needed.
- **First-match**: `select_case`/`match_pattern` (Core_aux.lean:637)
  is deterministic first-match. P8/E4's discipline matches the model.

## 2. Independent findings, ranked

### FR-1 (MAJOR — unsoundness). E14 fall-through entry breaks the every-cycle-decreases discipline; total-wp of divergence is derivable.

A.2's label obligations demand `∃w′ < w` on every jump from inside a
label continuation (Floyd), and E15 routes jumps through `K.run`, so
jumps are correctly constrained. But E14's premise is
`wpPE defaults {v̄. ∃w, I_ℓ w v̄}` — an **unconstrained** ∃w — and E14
applies at any `Esave` met in sequence, including one met *inside
another label's continuation*. The index is thereby reset upward on
every fall-through, and only jump edges decrease. Counterexample
needing nothing exotic — a nested loop:

```c
while (1) { int i = 0; while (i < 0) i++; }
```

Elaborated, the inner loop's `Esave` sits inside the outer while
label's continuation and is re-entered by fall-through on every outer
iteration. Proof under v2's figure: enter `while_outer` at any w; its
continuation reaches `Esave while_inner`; E14 establishes
`I_inner` at a FRESH arbitrary w′ (pick it huge); the inner loop
terminates by its own variant; the trailing `run while_outer(…)` sits
inside `while_inner`'s continuation (per `collect_labeled_continuations`'
Esseq-wrapping, verified §1), so it needs only an index `< w′` — not
`< w`. Every obligation discharges; the program diverges. The same
schema covers backward `goto` into code containing a later loop. This
is precisely the MAJOR-2a defect class the amendment log records as
closed; the jump edge was fixed, the fall-through edge was not.

**Exact fix**: E14's premise becomes `wpPE defaults {v̄. K.run ℓ v̄}` —
fall-through entry consults the SAME continuation map as jumps. Then
inside a label continuation the fall-through inherits `∃w′ < w`
(every edge in every cycle decreases; sequential/nested loops remain
provable by the already-prescribed lexicographic/rank components of
W_f), and in the entry body it inherits `∃w, I` as now. This is also
strictly MORE donor-conformant: RefinedC has no privileged fall-through
into a block — every block entry goes through the Q map
(programs.v:72); v2's E14 deviated from the very donor shape D3b
claims to adopt. One consequential edit: §G1's "the totality content
lives in exactly two separable premise lines" becomes three (the
E14 routing is totality content too); the partial sibling `wpE^∂` is
exactly where the unconstrained form is sound.

### FR-2 (MAJOR as a class). The B.5 discipline was enforced at M8/M9 and not swept; at least nine rows still carry premises or descriptions the implemented model contradicts.

The paper's own law (§B.5): premises are exactly the conditions under
which the model does not reach the UB table. v2 fixed the two rows v1
was caught on and asserts "Rules below track THAT model." Row-by-row
against CerbMem as implemented:

- **M1/M2 PtrEq/PtrNe — WRONG, and unsound as described.** The paper:
  "provenance-insensitive address comparison at the implemented
  corners." The model (`eqPtrval`, CerbMem.lean:1731): same-provenance
  → deterministic address equality; **different provenance → a real
  ND fork** (`msum` over "using provenance"=false and "ignoring
  provenance"=address-eq). Under the demonic semantics a rule
  concluding deterministic address equality is FALSE at the
  cross-provenance corner (the classic one-past-end == next-base
  comparison: the model can answer false where addresses are equal).
  The sound rule: deterministic under a same-provenance (or
  null/function-shape) premise; demonic over BOTH answers otherwise.
  Note also `MerrPtrComparison` is not the failure mode anywhere here.
- **M3–M6 PtrLt/Gt/Le/Ge — phantom premise + wrong failure mode.**
  The paper: "same-allocation premise (UB053)." The model: the
  non-strict path compares addresses **regardless of provenance**
  (the strict-relationals switch is unported); UB053/MerrPtrComparison
  has no raise site; null or non-concrete operands fail with
  **MerrWIP** (a non-UB kill). Correct rule: concrete-operand
  premises, defined cross-allocation comparison, no UB053. (The
  same-allocation premise is conservative, so this is incompleteness —
  but the rules must exclude the MerrWIP arms, which the stated
  premises don't name.)
- **P9/M12/M13 array/member shift — phantom UB046.** Neither the pure
  `arrayShiftPtrval` nor `effArrayShiftPtrval`/`memberShiftPtrval`
  checks anything; `MerrArrayShift` is never raised. "Checked shift
  (UB046)" (M12) is false of the model; the shift rules should be
  total, with OOB consequences surfacing at the access rules.
- **M14 Memcpy — phantom UB100.** `memcpyM` inherits upstream's
  overlap-UB-unimplemented TODO; disjointness is not a model UB
  condition. (The per-byte checked loads/stores are real, so
  readable/writable premises stand; overlap does not.)
- **M21 Copy_alloc_id — the named read-the-model check is answerable
  now, and the answer contradicts the row's description.**
  `CerbMem.copyAllocId` (:2172) is `memReturn pv`: the integer is
  discarded, the pointer returned unchanged — NOT "ptr at the
  integer's address with the pointer's allocation id" (that is the
  RefinedC/PNVI reading; Caesium's CopyAllocIdS even demands
  `valid_ptr`). Also "live VIP_copy_alloc_id error arms exist" is
  misleading: the constructors exist in `vip_error`'s type; nothing in
  the Lean model raises them. Under the model of record M21 is a
  trivial B-grade identity rule; the interesting rule belongs in
  §B.4F with the rest of the PNVI table.
- **A5 free — phantom switch.** `killM` never consults
  `forbid_nullptr_free` (declared, dead); free(NULL) under Dynamic is
  unconditionally a no-op; MerrFreeNullPtr unreachable. The rule
  should drop the switch-conditioned premise (an oracle-parity note
  may keep the switch's name).
- **M10 — wording.** `validForDerefPtrval` decides by liveness +
  ALIGNMENT; there is no bounds check. "liveness+bounds facts" is a
  misdescription (the landed law presumably matches the code; the
  paper's line doesn't).
- **M15 — under-specified but fixable in one line**: the model PANICS
  on an uninitialized byte (loud fail-stop, not UB); the rule needs an
  initialized-bytes premise to exclude a non-UB kill.

None of these individually is hard to fix, and most err conservative
(phantom premises cost completeness, not soundness — M1/M2 is the
exception). But the batch shows the MAJOR-4 remediation was executed
as a point fix rather than as the row-by-row audit B.5 itself
prescribes. **Amendment: a mechanical sweep — for every premise in
B.3/B.4, cite the raising site in CerbMem/Core_reduction or delete the
premise as phantom; for every row description, transcribe the model's
actual behavior.** This is a half-day's work against a 37-row surface
and it is exactly the pre-mechanization probe the paper is missing
(see §7, PR-3).

### FR-3 (MAJOR — structural, answered question not absorbed). canAlloc: the V4 "theorem-of-the-model" branch is dead, and Create is everywhere.

The paper hopes (A.0, DN-5) that `canAlloc` "is a theorem of the model
(monotone ids over unbounded Int addresses), which would collapse the
credits-vs-robustness question and license {emp} preconditions." By
inspection it is not: addresses are bounded (start 0xFFFFFFFFFFFF,
grow down), and `allocateObject` reaches
`NDkilled (MerrOther "out of memory")` at exhaustion
(CerbMem.lean:1478). Consequences the paper must absorb:

1. `canAlloc(n, al)`'s **signature is wrong**: headroom depends on
   allocation history, not on (size, alignment). As a pure premise in
   a ∀-context contract it is not stateable; it must be either (a) a
   resource (space credits — canonical lineage exists: Iron / Iris
   time-and-space-credit constructions; also note the OOM outcome is a
   kill, not UB, so total adequacy must exclude it explicitly), or (b)
   a model-refinement premise at ADQ instantiation ("this run's total
   allocation is bounded by B < 2^48"), the pattern the paper already
   uses for the freshness window — with per-contract allocation
   budgets threaded as pure facts.
2. **This is not a malloc corner.** Every elaborated call stages its
   by-pointer locals with `create(…)` (p01: main creates the argument
   cell before `ccall`). A1's premise therefore appears in the
   prologue of essentially every function in every corpus row; V4's
   outcome shapes every contract in the system. The paper treats V4 as
   a pending sub-decision; it is a top-five difficulty-ledger item and
   should be listed as such (§E currently omits it).

No redesign implied — option (b) in particular is cheap and fully in
the paper's existing idiom — but the figure cannot be ratified with a
premise family whose sort is unknown-and-actually-undecidable-as-pure.

### FR-4 (MODERATE — figure ill-formed / inexpressive as written). The invariant family is not spec-indexed, and A.2's schema has unbound variables.

A.2 declares `I_ℓ : W_f → list value → iProp`, and the (labels)
premise mentions `Q a x̄` with `a, x̄` bound only inside the separate
(body) premise line. Two problems: (i) as printed, the schema is
ill-formed (free `a, x̄` in (labels)); (ii) substantively, label
invariants MUST be able to mention the spec index — P04's invariant is
`s = Σ_{k<i} xs[k]` over the quantified `xs`; P08's is
`IntList acc (rev visited) ∗ IntList p rest` with `l = visited ++ rest`
the spec index. With `I_ℓ` unindexed, none of the corpus's loop rows
is expressible. Exact fix: quantify `a, x̄` over all three premise
lines and index the family `I_ℓ : A → W_f → list value → iProp`
(equivalently, the label environment lives under the contract's ∀a —
which is where A.2 already says it lives; the type just didn't follow).

### FR-5 (MODERATE — steering-test leak). E9b′'s and E10's race premises have no stated logical form.

E9a's disjointness premise is the ∗ itself — clean. But E9b′ adds "the
pairwise footprint-disjointness premise" and E10 "the race proviso
restricted to the negative-polarity residue of e₁ vs e₂" without
saying what assertion-language object either premise IS. Runtime DA
footprints are engine objects; a premise quantifying over them is
operational narration in the figure — the exact thing the design
axioms exile. Options: state both provisos as resource-splitting
premises (E9b′ becomes a corollary of E9a plus order-wps, at which
point it should be demoted to a derived rule or dropped — with the
disjointness premise it is admittedly "nearly E9a" by the paper's own
text, so it earns its keep only if its premise is expressible); state
E10's proviso as a ∗-split between e₁'s negative-action footprint
resources and e₂'s precondition. Either way the figure should not ship
rules whose premises have no sort.

### FR-6 (MINOR — citation and model-fact corrections).

a. **A.2 cites the wrong resolver**: `Core_aux.find_labeled_continuation`
   (:596–608) has no call site in the live path; the engine's map is
   built by `collect_labeled_continuations` (Core_aux.lean:622, called
   from Driver.lean:436). The semantic claims (procedure-wide, flat,
   continuation-from-save-point) are TRUE — I verified them at the
   right function — but the cite should move.
b. **M9's parenthetical mis-cites**: `ptrfromint` passes the IV's
   provenance directly; `combine_prov` (:227–240, not :662–668 — those
   lines are a byte-fold comment elsewhere) is the arithmetic-merge
   path, not this one.
c. **Labels(f) needs one wellformedness line**: the engine's collection
   returns `fmapEmpty` under `Ebound` — a save inside a bound is
   procedure-invisible. Elaboration keeps saves at statement level, but
   A.2's "Labels(f) = all Esave labels in f's body" should carry the
   caveat (or a premise that no save sits under a bound), else the
   figure and the model disagree on which jumps resolve.
d. **A1's stray phrase**: "Freshness … (monotone ids; alloc-ND
   evaluation)" — there is no allocation-address ND in this model
   (deterministic bump allocator); the parenthetical looks like a
   leftover and contradicts A.4's own "address ND does not occur."

### FR-7 (MINOR — soundness-statement hygiene).

a. **ADQ's conclusion says "terminates without UB"**; the model also
   has killed-not-UB outcomes (MerrOther OOM, MerrWIP arms,
   `Free_out_of_bound → none` in the UB map, memcmp's panic, the
   E10-cluster failwithI holes). The semantic wp meaning ("lands in
   Knorm or jumps covered by Krun") implicitly excludes them, but ADQ's
   prose should say "without UB, error, or engine-incomplete branch" —
   otherwise the no-UB phrasing under-claims what the judgments prove
   and leaves the OOM/kill class formally unaddressed.
b. **E9a's ledger lemma (a) is stated too strongly to be provable**:
   "from 'preconditions separate' to 'runtime DA footprints disjoint'"
   is FALSE under read-sharing — two arms holding `↦{1/2}` on the same
   range both read; footprints overlap addresswise and only
   `overlapping`'s R/W-awareness saves the join. The provable form is
   per-location: each arm's accesses are covered by its fraction, and
   cross-arm overlapping accesses are both reads. The paper's own
   "favorable model fact" two lines later is the proof it knows this;
   the lemma statement should match.
c. **P8's displayed rule is garbled** (the "first match" index i is
   used before it is bound); the clean form is
   `∃i, (∀j<i, ¬match) ∧ match_i ⇓ σ ∧ wpPE (σ body_i) {Q}`.
d. **The engine hole census at E10/E12 is one short**: the live engine
   also fails on `Ecase` of `PEconstrained`
   (`failwithI "TODO: Core_reduction.one_step, Ecase PEconstrained"`),
   which belongs on P4/E4's validation rider.
e. **PR-2 must probe shadowing, not just size**: elaborated label
   params snapshot the very variables they shadow
   (`save while_641: unit (i: pointer := i)` — and the printed .core
   text round-trips through CoreParser, so the two `i`s must be the
   same symbol). "Binder distinctness is a parse-time invariant" must
   not be read as "no shadowing"; the substitution function and the
   correspondence lemmas need to be shadow-correct, and PR-1's
   engine-match check should include a rebinding case.
f. `dead(ι)`'s persistence is unmarked in A.0 (alloc is marked
   persistent; dead should be too — allocation ids are never reused,
   which the paper should note as the model fact licensing it:
   `nextAllocId` is monotone and `deadAllocations` only grows).
g. P27's "not emitted by our elaboration path" is true for C source
   generally, but translation.lem:3106–3126 DOES emit `PEbmc_assume`
   for the `__bmc_assume` builtin; the exclusion should say "programs
   calling __bmc_assume are out of fragment."

## 3. Where the design is right — verified, not presumed

Stating these plainly, since fresh eyes owe positive findings the same
rigor:

1. **The Eunseq story is the paper's best technical content and it is
   CORRECT against the model.** I traced the whole pipeline:
   per-action DA_pos/DA_neg annotation at the request callbacks,
   annotation merge (`{A1}{A2}E → {A1∪A2}E`), outward propagation
   through wseq AND sseq (so whole-arm footprints — including effects
   behind internal sequence points — meet at the join, which is the
   correct C11 unsequenced semantics), the single `do_race` call site
   at the join, R/W-aware `overlapping`, death at `Ebound`. The ∗-rule
   E9a is the right primary rule for exactly this model; the
   MAJOR-3-corrected E9b′ counterexample (`store x 1 ∥ store x 1`) is
   real (DA_pos × DA_pos overlap fires at the join in every schedule);
   E9c matches the annotation mechanics (pure arms carry no
   footprints). The two-lemma pricing of E9a (locality +
   interleaving-invariance) is the honest price, modulo FR-7b's
   restatement.
2. **The function-scoped label environment (MAJOR-1's fix) matches the
   engine exactly**, including the subtle part: label continuations
   extend through enclosing Esseq to the rest of the procedure
   (`collect_labeled_continuations`' Esseq-wrapping), which is what
   makes A.2's `cont_ℓ` + `Knorm := Q` obligations well-posed. The
   corpus dumps' forward-run/save-later shape is real, ubiquitous, and
   correctly forced the contract-level introduction.
3. **Substitution-everywhere is coherent with this engine.** The
   engine itself already substitutes in `Ecase` branches
   (`select_case subst_sym_expr`, with the OCaml's own "TODO: stop
   using subst?") while using env frames elsewhere — the model is
   ALREADY a mixed substitution/env machine, which supports the
   paper's claim that the env is an implementation of substitution
   rather than a semantic commitment. Jump-as-instantiation matches
   the engine's arena-replacement + param-bind. The correspondence
   family is the right price at the right layer, and the exit ramp
   (G5) is genuinely the same machinery.
4. **UB-as-⊥ + the premise dictionary** is the right discipline, and
   where it was actually applied (M7, M8, M9, A4, A6/A7, P16) the rows
   check out against the code. FR-2 is the discipline un-applied, not
   the discipline wrong.
5. **Totality as a primitive-variant discipline is the right
   divergence from the donors** — BRiCk's Kloop/Löb partiality carries
   its own recorded unsoundness-under-optimization caveat
   (stmt.v:461–464, verified), and the Hoare total-recursion rule at
   contract introduction is the classical shape. FR-1 is a hole in
   the execution of this design, not in the design.
6. **The judgment economy passes the steering test** (modulo FR-5):
   three judgments cut by Core's own grammar classes, Kpred labels
   subsuming break/continue/return (verified in dumps:
   break_640/continue_639/ret_638 are ordinary labels), path
   conditions as pure facts, no environment/supply/control sorts, no
   harness residue anywhere in §§A–E, §F genuinely one paragraph and
   genuinely corollary-shaped.
7. **The engine-of-record and mode-of-record analysis is right and
   needed**: Core_reduction is the live engine; the
   live-unseq-vs-presequentialised fork is real (libc text is the
   oracle's sequentialised dump; user code never sequentialises); the
   recommendation (live-unseq of record) matches what the executable
   face actually runs.
8. **The inventory is exact** — all seven censuses re-derived and
   correct, including the v1 undercount fix (22 memops).

## 4. Expressiveness check — the frozen corpus against the figure

Question per row: is the ∀-context contract writable in this figure's
judgments? (Marks: ✓ = writable as-is; ✓* = writable once FR-4's
spec-indexed I_ℓ lands; all rows assume FR-3's canAlloc resolution for
their prologue creates.)

| Row | Needs | Verdict |
|---|---|---|
| P01 clamp | wpPE case-split (P22/P8), ret-label Krun, A1/A6/A7 prologue | ✓ |
| P02 sat_add | P13 ℤ-ops, P16 overflow gate, path conditions | ✓ |
| P03 swap both-arms | two-cell ∗ vs p=q collapse; pure-disjunctive contract | ✓ |
| P04 arr_sum | typed ↦ arrays (derived), loop invariant over spec index | ✓* |
| P05 find_first | contents-dependent trip count; early exit via Krun; minimization invariant | ✓* |
| P06 arr_reverse | two-index invariant, symbolic writes | ✓* |
| P07 list_sum | isList rep predicate (derived layer), π-quantified skeleton as pure ∀ | ✓* |
| P08 list_reverse | lseg/isList, ownership passing in I_ℓ | ✓* |
| P09 call_contract | E7/E8 consumption + frame (the WP's frame property) | ✓ |
| P10 gcd_rec | A.2 recursion with measure μ(a,b)=b at contract intro | ✓ |
| P11 gcd_iter | label variant with W_f=ℕ over heap contents (I may mention heap — stated) | ✓* |
| P12 pt_midpoint | struct ↦ (derived), 3-way disjointness, frame-as-observable via readback | ✓ |
| P13 cell_alloc | A3+A5, dead(ι) tombstone = the leak conjunct's carrier; H8 clause = FR-3's outcome | ✓ (contingent on V4) |
| P14 count_pairs | nested invariants, lexicographic W_f — NOTE: the very shape FR-1's hole sits on; fine after the E14 fix | ✓* |
| P15 scan_classify | ∃-NUL pure pre, byte ↦, switch = P8/E4 first-match | ✓ |

**No row is fundamentally inexpressible**; the two systematic
dependencies are FR-4 (five loop rows) and FR-3 (all rows'
prologues + P13 centrally). The `dead(ι)` tombstone deserves credit:
it is what makes P13's leak conjunct expressible in an affine logic
without an allocation-census ghost.

## 5. Divergence adjudications (innovation only where Cerberus forces it)

| Divergence | Adjudication |
|---|---|
| Totality (D7) vs both donors' partiality | JUSTIFIED — donor's own caveat verified; G1's partial sibling covers kernel forever-loops. Keep. |
| E9a ∗-rule proved vs BRiCk's axiomatized Mpar (D9) | FORCED AND EARNED — BRiCk's whole wp is a Parameter (wp.v:631); we have an executable model with a real join-race check, so the rule must and can be a theorem. The genuinely novel obligation (locality lemma) is correctly named as the hard half. |
| Freshness/alloc as theorem+premise vs fiat ND (D11/D12) | FORCED by having a real allocator — but see FR-3: the model also has real EXHAUSTION, which the fiat donors dodge; the divergence must be carried to its conclusion, not half-way. |
| Function-scoped labels (D3b) | DONOR-CONFORMANT (RefinedC shape verified) — and FR-1's fix makes it MORE so (no privileged fall-through exists in RefinedC either). |
| Substitution-everywhere (D6) | DONOR-CONFORMANT at the right granularity: Core value binders ↔ λ-tradition substitution; C addressable locals are create()'d heap cells (= RefinedC's locals-as-heap). BRiCk's `region ρ` is a name→ptr environment — the honest note is that our label parameters play ρ's role and are substituted instead; defensible under DN-1, worth one sentence of honesty in D6. |
| Recursion at contract intro vs fntbl+Löb | FORCED by totality; classical (Hoare total recursion). Keep. |
| Premise-dictionary UB indexing (D13) | Right, and FR-2 is its enforcement debt, not a design flaw. |
| Concrete/PVI of record, PNVI as FUTURE (D14) | RIGHT CALL — verified the model is PVI with PNVI compiled out; v1's inversion would have been fatal to the memop rows. But see G3 note (§6): the PVI reality touches M1–M6 too, not just M8/M9/M21. |

No unjustified innovation found. The figure's "no equivalent" entries
are honest.

## 6. Flex attacks (§G)

- **G1 (partial sibling)**: REAL, with one correction — the totality
  content is THREE lines once FR-1 lands (the ∃w′<w, the μ, and E14's
  K.run routing); the sibling keeps the unconstrained E14. The
  fuel-inductive safety argument for invariant-without-variant is
  sound. Verdict stands, amended.
- **G2 (cmm)**: seams are real (mo-arguments kept in excluded rows;
  E9a as the sequential shadow of par — BRiCk's own Mpar encoding
  supports this; ADQ model-parameterization stated). The honest caveat
  (per-thread Kpred composition is new design) is the right honesty.
  No foreclosure found.
- **G3 (PNVI switch)**: the "swaps three rows, nothing else knows the
  dialect" claim is FALSE as stated — once M1–M6 are corrected to the
  implemented semantics (FR-2), they are provenance-behavior-laden
  too, and PNVI changes pointer-comparison semantics as well as the
  cast rows. The switch remains ADDITIVE-ish, but the perimeter is
  M1–M9+M21, and the re-proof class includes comparison-heavy
  programs, not only cast-heavy. Verdict: revisable, but re-scope.
- **G4 (promotion)**: correct; ADQ's conclusion schema is exactly the
  statement-TCB shape. No foreclosure.
- **G5 (substitution retreat)**: the exit ramp is genuinely the
  already-required correspondence family — this is the best-designed
  seam in the paper. Add FR-7e (shadowing) to PR-2's checklist.
- **G6 (weak memory)**: no global-interleaving assumption found in any
  Core^seq rule; the NA-premise fencing is real. Fine at this
  altitude.

## 7. Will it work — the ledger, the probes, the metatheorem family

- The five-hardest list is nearly right. Amend to seven: add **the
  canAlloc/space-accounting obligation (FR-3)** and **the
  E14-corrected totality-index plumbing** (the lexicographic W_f
  bookkeeping through label environments is now load-bearing for every
  nested loop; it should be exercised by P14 early).
- The correspondence family's per-construct decomposition
  (let/case/sseq/wseq/params/label-args) matches where the engine
  actually binds (verified: update_env sites at exactly those
  constructs, plus the Ecase-substitution wrinkle which makes one
  lemma FREE); the pricing (one lemma per construct, hot factor named)
  is credible.
- PR-1/PR-2 are the right probes but insufficient: add **PR-3 — the
  mechanical B.3/B.4 raise-site sweep** (for each premise, the
  CerbMem/Core_reduction line that raises the named error, or PHANTOM;
  for each row description, the transcribed behavior). Cheap, and it
  converts FR-2 from a review finding into a table the mechanization
  consumes. My §1 covers more than half of it already.
- The E10/E12 cluster's honesty (directionally confirmed; named
  failwithI holes; mode-of-record pin as a blocking operator decision)
  is the right posture; add FR-7d's hole to the census.
- Nothing graded routine hides a metatheorem that I found, with one
  borderline case: P7/P8's argument-commutation lemma is named in
  cross-cutting obligations — correctly, since pure-argument
  evaluation order inside ctors is where a wrong commutation claim
  would hide.

## 8. Sharpest overall judgment

This document does the one thing the whole effort needs its foundation
to do: it commits to rules that are theorems about THE model — the
live engine and the implemented memory model, not ISO, not the PNVI
papers, not the donors' semantics — and it prices the two genuinely
novel obligations (the unseq locality lemma, the
substitution-correspondence family) instead of hiding them. The
architecture is donor-shaped where the donors are right and diverges
exactly where Cerberus forces it. I tried to break every rule family
against the executable semantics; the design survived everywhere the
paper claimed verified ground, and broke exactly where it had not yet
looked: one un-swept table (FR-2), one un-closed corner of its own
MAJOR-2 fix (FR-1), one deferred decision whose answer was sitting in
the allocator (FR-3). All three fixes are local, exact, and
consistent with the paper's own disciplines — indeed they mostly ARE
the paper's own disciplines, applied one notch harder. Ratify with the
amendments below; do not redesign.

**Amendment list (exact):**
1. E14 premise → `wpPE defaults {v̄. K.run ℓ v̄}`; delete the direct-∃w
   form; note the third totality line in G1. (FR-1)
2. Execute the B.3/B.4 raise-site sweep (PR-3); restate M1/M2 (ND
   fork), M3–M6 (non-strict, MerrWIP premises), P9/M12/M13 (unchecked),
   M14 (drop UB100), M21 (identity rule; PNVI version to §B.4F), A5
   (drop the switch premise), M10 (alignment not bounds), M15
   (initialized-bytes premise). (FR-2)
3. Resolve canAlloc's sort NOW (credits resource or ADQ-level
   allocation-budget premise), reflecting the model's real OOM kill;
   promote to the difficulty ledger; note Create's ubiquity in
   elaborated prologues. (FR-3)
4. Index `I_ℓ` by the spec index and close A.2's binding scope. (FR-4)
5. Give E9b′/E10's race provisos an assertion-language form or demote
   E9b′ to derived. (FR-5)
6. Citation/wellformedness corrections: collect_labeled_continuations,
   combine_prov lines, Ebound label-invisibility caveat, A1 stray
   phrase. (FR-6)
7. Hygiene: ADQ "without UB/error/incomplete-branch"; E9a lemma-(a)
   R/W-aware restatement; P8 rule form; Ecase-PEconstrained hole;
   PR-2 shadowing; dead(ι) persistence + id-non-reuse note;
   P27 __bmc_assume wording. (FR-7)

## 9. Cross-check of the amendment log (§H) against the prior review — WRITTEN LAST

*(This section was written only after §§0–8 were complete, per the
freshness discipline. Prior review:
`notes/2026-08-30_core-logic-paper-review.md`.)*

**Headline: §H is an honest log.** Every disposition it claims I
checked against both the prior review's amendment list and v2's actual
text: MAJOR-1 (label re-homing — independently re-verified by me at
the correct engine function), MAJOR-3 (E9b′/E9c), MAJOR-5 (censuses),
M-a/M-b/M-c/M-f/M-g/M-h/M-i, the §3 minors, and the DN adjudications
are all genuinely executed, not merely logged. The DN-1 execution
(substitution-everywhere with PR-1/PR-2) faithfully implements the
prior review's row-4 caveat (env-cells permissible as engine
representation only, with a measurement). Nothing in §H misrepresents
what was done.

**The failure mode is different from papering-over, and worth naming
for the ratification conversation: v2 transcribed the prior review's
prescriptions faithfully, including three that were themselves wrong
or incomplete, and generalized one claim beyond what was re-audited.**
Independent convergence note: my FR-1/FR-2/FR-3/FR-4 were all formed
before reading the prior review; on reading it, each turns out to sit
exactly where the prior review's text stops:

1. **FR-1 (E14 unsoundness) is an incomplete closure of MAJOR-2's
   class, introduced by combining two amendments.** The prior review's
   amendment 2 fixed the jump edges (`∃w′ < w`) and amendment 8
   prescribed the fall-through defaults premise `wpPE defaults {v̄. I_ℓ v̄}`
   — WITHOUT an index constraint. v2 composed them verbatim
   (`∃w` unconstrained at E14), and the composition re-opens the
   MAJOR-2a hole one edge over. §H's "MAJOR-2 … closed" row is
   overstated: the class is closed on jump edges only. Neither
   document tested the nested-loop/fall-through cycle.
2. **FR-2's A5 instance was INJECTED by the prior review.** Its §3
   minor list instructed "name the `forbid_nullptr_free` switch" on
   the premise that the model consults it; the model does not (the
   switch is a dead enum; killM is unconditional). v2 executed the
   amendment faithfully and thereby acquired a phantom premise. More
   broadly, the prior review audited model fidelity at M8/M9 (its
   MAJOR-4) and did not sweep M1–M6/M12/M14/P9/M10 — and v2's B.4
   preamble then asserts "Rules below track THAT model" for the whole
   table, a claim generalized beyond either document's audit. That
   sentence is the one place I would say v2 papers over an open
   obligation with an assertion.
3. **FR-3's dead branch originates in the prior review's DN-5 note**
   ("if the model's allocator is genuinely infallible over an
   unbounded address space … canAlloc may be a THEOREM"). The
   allocator is bounded and fallibly kills
   (CerbMem.lean:1478); v2 copied the hopeful framing into A.0
   verbatim. Not dishonest — but the V4 question was answerable by
   both documents and answered by neither.
4. **FR-4's unindexed invariant family is the prior review's own
   prescription transcribed exactly** (amendment 2:
   `I : W → list value → iProp` — no spec index). The prior review's
   expressiveness table then marks P04–P08/P11/P14/P15 "AS AMENDED"
   without noticing its amended type cannot state their invariants.
   v2 inherited both the type and the confidence.

**No regressions found**: nothing the prior review verified as correct
was broken by v2's edits; the v1→v2 delta is monotone. The two
reviews' independent agreement is itself evidence: both found the
architecture sound, the citation discipline exemplary, the §B.5
discipline the paper's best idea, and the same E9a/correspondence
obligations the honest hard core. The residual defect set (my FR-1
through FR-7) is small, exactly located, and fixable without touching
the judgment forms — but it is exactly the set that a
transcribe-the-amendments pass structurally could not find, which is
the strongest argument that this fresh-eyes pass was worth
commissioning and that the FR-2 sweep (PR-3) should be executed
against the model rather than against any review, including this one.
