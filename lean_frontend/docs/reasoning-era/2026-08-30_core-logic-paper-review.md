# Hostile PL-professor review — the Core program logic paper design

TARGET: `notes/2026-08-30_core-logic-paper.md` (87-row figure, 3
judgments + Kpred + contract judgment + ∀-state ADQ).
REVIEWER MODE: adversarial PL-expert audit (Iris / SL / RefinedC /
BRiCk / C-semantics metatheory), commissioned pre-ratification.
METHOD: read-only; every soundness claim tested against the ACTUAL
executable model (`generated/Core_reduction.lean`, `Core_run.lean`,
`CerbMem.lean`, `Core_sequentialise.lean`, `Core_aux.lean`, the
generated AST, the pinned corpus `.core` dumps); every donor citation
opened in `deps/refinedc` and `deps/BRiCk`; rubrics = the catechism,
the 2026-08-29 logic-first/contracts-primacy/harness rulings, the
frozen corpus, the rip-out inventory's KEEP layer. Includes the
operator-mandated DIVERGENCE AUDIT (§6) as a first-class deliverable
[USER 2026-08-29: "The default should be do what they do… innovate
only when necessary… is this a real cerberus constraint, or a BS
constraint that comes from some previous mis-design choice"].

---

## 0. VERDICT

**RATIFY-WITH-AMENDMENTS.** The architecture is right and the paper
is honest where it matters most: the three-judgment cut is the donor
method correctly applied to Core's own grammar; UB-as-⊥ with the
model's UB table as the premise dictionary (§B.5) is the paper's best
idea and is exactly RefinedC's move made reference-model-honest; the
∀-state ADQ and the one-paragraph §F execute the operator's rulings
faithfully — there is **no harness residue in the judgments**; the
soundness positioning (§D: our rules proved, BRiCk's axiomatized) is
factually verified (`Parameter wp_lval`, wp.v:631; `Axiom
wp_while_unroll`, stmt.v:483); and the citation hygiene is the best I
have audited in this project — every load-bearing donor cite checked
out exact, including the Mpar NOTE verbatim.

But the figure contains **five MAJOR defects** — two unsound rules,
one rule that cannot express any elaborated C loop (blocking 8 of 15
frozen corpus rows), one cluster written against a semantics the
model does not implement, and one inventory undercount. All five are
amendable within the existing architecture; none requires redesign of
the judgment forms, Kpred, the contract judgment, or ADQ. The
divergence audit (§6) additionally finds two bin-3 items (env-cell
sort, fresh-premises-in-rules) where the paper elevates OUR
interpreter machinery to logic-level status while correctly exiling
the identical `ctl` case — the amendment is to apply the paper's own
argument uniformly.

Amendment list: §7. No REDESIGN verdict on any component.

---

## 1. MAJOR FINDINGS (ranked)

### MAJOR-1 · E14/E15 label scoping is wrong for every elaborated C function

E14 extends `Krun` at ℓ **inside the save's body only**. The model
and the elaborated code do not work that way:

- Every elaborated procedure ends
  `… ; run ret_631(conv…) ; … ; save ret_631: … in pure(a_681)` —
  the `run` is **sequenced BEFORE its `save`** (verified:
  `tests/corpus/p04_arr_sum_funs.core:160-163`; same shape in every
  corpus dump). Break labels are sequenced siblings too
  (`save break_633 … in pure(Unit) ; <rest>` at :150).
- The model resolves `Erun ℓ` by **searching the whole procedure**
  for the labeled continuation
  (`Core_aux.find_labeled_continuation`, generated/Core_aux.lean:596-
  608): labels are procedure-scoped, and a save's "body" is really
  the continuation of the procedure from the save point.

Under E14 as written, the jump at :160 occurs where `K.run` has no
`ret_631` entry — **the figure cannot type a single elaborated C
function**. RefinedC has the correct structure and the paper even
cites it: `typed_stmt`'s `Q : gmap label stmt` is **function-scoped**
(programs.v:68), with `typed_block` (programs.v:72) as the per-label
obligation. The divergence audit's default answer applies with full
force: the paper silently replaced the donor's function-scoped label
environment with a novel block-scoped one, and the novelty is wrong.
**Amendment**: label environment = all saves of the procedure,
introduced at the contract judgment (A.2); per-label rule = "I_ℓ ⊢ wp
of the continuation-from-the-save-point under the full label map";
E15 unchanged. This also settles the "nested save shadowing" question
trivially (post-elaboration symbols are unique; the map is flat).

### MAJOR-2 · E14's totality story is unsound, and its variant cannot express any real loop

Two independent defects:

(a) **The base rule without the variant proves total wp for divergent
programs.** Counterexample: `body = Erun ℓ []`, `I_ℓ := True`.
Premise 1 holds by E15 (`K.run ℓ [] = I_ℓ [] = True`); premise 2
holds; conclusion `wpE (Esave ℓ [] (Erun ℓ)) ⟨K⟩` — but this program
loops forever and `wpE` means every execution terminates. In a total
logic the label-introduction rule **cannot exist without the
well-founded premise**; "derived total loop rule" is backwards — the
variant is a mandatory premise of the primitive rule, not an optional
strengthening. (BRiCk can state Kloop bare only because its wp is
partial and the ▷/Löb carries the cost — the paper knows this,
D4/D7, and then states a rule that forgets its own divergence.)

(b) **The variant is indexed on the wrong thing.** `V : list value →
W` over the label's *argument values* — but elaborated loop labels
pass **the unchanging pointers to the loop state**
(`save while_634: unit (i: pointer := i, s: pointer := s)`,
p04 dump:9; identical in every loop dump). `v̄' = v̄` on every
back-edge, so `V(v̄') < V(v̄)` is unsatisfiable for any V: **the rule
as written can prove termination of NO elaborated while/for loop.**
The decreasing quantity lives in memory. Classical fix (Dijkstra/
Floyd, correctly named by the paper, incorrectly transcribed): the
label invariant is a family `I : W → list value → iProp` over a
well-founded W (a logical/ghost index free to mention heap contents
via the assertion), back-edge obligation `∃ w' < w, I w' v̄'`.

Impact: blocks the ∀-context contracts of **P04, P05, P06, P07, P08,
P11, P14, P15** (every loop row of the frozen corpus). One amendment
fixes all eight.

### MAJOR-3 · E9b (the orders-rule) is UNSOUND against the model

The paper claims E9b is "sound … no metatheorem needed". False. The
model's unsequenced-race detection is **schedule-independent**: each
completed subexpression of a live `Eunseq` carries its accumulated
footprint annotations (`Eannot fps (value)`), and at the join
`one_step_unseq_aux` runs `do_race` over ALL pairs
(Core_reduction.lean, `do_race` at ~:19253: DA_neg/DA_pos ×
`CerbMem.overlapping`, exclusion-id suppression), firing
`UNSEQUENCED_RACE → UB035_unsequenced_race` **regardless of the
interleaving taken**. Counterexample to E9b: `e₁ = store x 1`,
`e₂ = store x 1`. Both sequential orders are UB-free and provable by
E11; `Eunseq [e₁,e₂]` races at the join → UB → `wpE` is false. E9b's
premises hold, its conclusion fails. (Also independently unsound
ignoring the race check: the model interleaves at redex granularity,
so fine interleavings — lost updates — are not covered by the n!
coarse orders; only race-freedom collapses them.)

BRiCk's `nd_seq` (wp.v:290) is sound **for BRiCk's semantics**, which
has no join-time race UB at that combinator. Core's does. The
co-design-dodge sneer at Caesium in D9 cuts both ways: E9b quietly
assumed the donor's semantics while running on ours.

**Amendment**: E9b gains the pairwise footprint-disjointness premise
(at which point it is nearly E9a and its "cheap fallback" value
shrinks to the genuinely cheap case: all-but-one subexpression pure —
no footprints, no race possible — which IS worth a dedicated derived
rule, and covers most elaborated argument lists). DN-2's
recommendation must be re-decided on the corrected menu (§5).

Positive result from the same investigation, recorded for E9a's
benefit: the model's `overlapping` is R/W-aware (two reads never
conflict — CerbMem.lean:1186-1191, mirroring impl_mem.ml:527-532),
so fractional read-sharing under ∗ is compatible with the race
check. E9a's shape survives contact with the model.

### MAJOR-4 · The provenance rules (M8/M9, B.4 preamble, D14) are written against a semantics the model does not implement

§B.4: "Provenance premises are stated against the model's PNVI
instantiation." The model has **no PNVI instantiation**. Verified in
`CerbMem.lean` (the layer-1 memory model of record):

- ":511-515 — OCaml consults it ONLY under `is_PNVI()`, which this
  pipeline never enables (no SW_PNVI …)"
- ":651 — Not ported: taint tracking (PNVI) and is_zap"
- `ptrfromint` (:1897-1909, mirroring impl_mem.ml:2126-2173):
  "Skips the PNVI allocation-finding — concrete model uses PVI" —
  wraps the integer, **carries the integer value's own provenance**
  (IV values carry provenance; PVI `combine_prov` at reconstruction,
  :662-668), **never fails**: no exposed-allocation lookup, no
  MerrPtrFromInt, no UB_CERB001 is reachable from it.
- `intfromptr` (:1911-1925): representability check only
  (MerrIntFromPtr ✓ = M8's premise) — **no exposure effect exists**.

So: M9's premise family ("integer corresponds to an address within
some exposed, live allocation; MerrPtrFromInt/UB_CERB001 excluded")
names conditions **under which the model does nothing and UB entries
the model cannot reach** — a direct violation of the paper's own
§B.5 discipline ("a rule's premises are exactly the conditions under
which the model does not reach the UB table") and of its own §E.2
warning ("the rules must track the model, not an idealization" — the
paper wrote the warning and then committed the offense). M8's
"provenance becomes exposed(ι)" is ghost state mirroring nothing.
D14's "ours is the reference semantics" is an overclaim: the
executable, differentially-validated layer 1 runs the concrete
model in PVI mode.

**Amendment** (either branch acceptable; the choice is an operator
decision, not the paper's to make silently): (i) restate M8/M9
against the concrete model as implemented (M8 = representability +
provenance-carry into the IV; M9 = PVI provenance-carry, no UB
premise — and then the honest note that layer-1 currently certifies
LESS than PNVI-ae-udi would, with the PNVI mode switch as a
registered model-mode mover), or (ii) charter enabling PNVI-ae-udi in
layer 1 FIRST and keep the rules — in which case they are rules about
a future model and must be flagged exactly as E10 is. The D grade was
assigned for the right rows but the wrong reason: the hazard is not
"the model's bookkeeping is intricate", it is that there is currently
no model bookkeeping to track.

### MAJOR-5 · The memop inventory is 22, not 20 — two constructors unaccounted

`generated/Mem_common.lean` memop export (:560):
`… Va_end Copy_alloc_id CHERI_intrinsic` — **22 constructors**. The
paper claims "20 constructors; Mem_common.lean:514-560" and rules
M1-M20 cover exactly the first 20. `CHERI_intrinsic` would ride the
existing CHERI boundary (like CivNULLcap) but is never named.
`Copy_alloc_id` is **not CHERI**: it is the RefinedC-inspired
provenance-transfer memop (the AST comment says "RefinedC"; the
mem_error type has live `VIP_copy_alloc_id` arms), squarely inside
the whole-of-Core ruling and squarely in M8/M9's provenance
territory. Given that the commission is "every feature except
concurrency" and the document advertises exact enumeration, an
undercounted table is a completeness failure of precisely the class
the paper found in its own predecessors. **Amendment**: M21
Copy_alloc_id (rule or explicit disposition), M22 CHERI_intrinsic
(named CHERI-boundary exclusion); fix the census and the §E grade
counts.

---

## 2. MEDIUM FINDINGS

- **M-a · Recursion is mis-homed.** The IH-at-smaller-measure lives
  only in E8 (Eproc). But recursive C functions call through
  **Eccall** (gcd_rec included), whose E7 rule consumes a bare
  `□ contract` with no measure mechanism — as written, P10 is not
  provable through the C-call vector the elaborator actually emits.
  Both donors home recursion at the function-DEFINITION rule
  (RefinedC: `typed_function` under a fntbl containing the
  function's own spec, discharged by Löb; our total analogue is the
  classical Hoare total-recursion rule at contract INTRODUCTION,
  A.2, with the well-founded measure on the spec index). Move it
  there; E7/E8 just consume contracts. State the mutual-recursion
  form (one measure over the indexed family) — currently absent.
- **M-b · P8/E4's rule text is wrong as written.** "∃ alt,
  match(alt.p, v) ⇓ Θ ∧ … " plus "demonic over the first matching
  alternative" is self-contradictory: ordered match is
  DETERMINISTIC, and the ∃-form lets the prover choose a later
  branch and ignore the one the model takes (unsound reading).
  Rewrite: the first matching alternative, with
  earlier-patterns-fail facts entering as path conditions;
  non-exhaustiveness = ⊥ premise (that part is right).
- **M-c · E14's fall-through premise treats label defaults as
  values.** Defaults are PEXPRS and the elaborator uses that:
  `save ret_631: … (a_681 := undef(<<UB088_…>>))` — the
  reached-end-of-function UB IS the default. `I_ℓ(defaults)` as
  stated is unsatisfiable for every ret label, i.e. no function
  body is provable. The premise must be `wpPE defaults {v̄. I_ℓ v̄}`
  and demanded only where fall-through entry is the path taken
  (which the MAJOR-1 restructuring gives naturally: the save-point
  obligation in sequence position is exactly the fall-through).
- **M-d · `fresh(x)` in `births` and `supply(σ)` in the figure are
  interpreter narration** (catechism steering test). The T4
  hash-collision episode proves the WINDOW machinery is real — at
  the ADEQUACY layer, where ADQ §D indeed discharges it ("fresh by
  the route-A window arithmetic … at instantiation"). Carrying
  `fresh(x) ⇛` per binder in E4/E5 additionally drags a per-birth
  supply obligation through every rule for a property (binder
  distinctness) that is STATIC after elaboration (the parser
  fail-stops on symbol-hash collision — CoreParser tripwire). The
  paper makes exactly the right argument to exile `ctl` from the
  logic and then fails to apply it to `fresh`/`supply`. Purge both
  from the rule figure; they live in the realization relation and
  the instantiation lemma. (Divergence audit bin 3, §6.)
- **M-e · The substitution-everywhere option is missing from DN-1's
  menu.** See §6, divergence row 4 — the flagship bin-3 candidate.
  DN-1's stated alternative (env cells everywhere) is the only
  alternative considered; the donor-default direction (binding by
  substitution at BOTH levels, HeapLang lineage, no env sort at
  all) is not on the menu, and it would delete assertion sort D6,
  the fractions on immutable bindings, and the births machinery.
- **M-f · Eannot is misclassified.** E18 "dynamic annotations carry
  no semantics for this fragment" is false for the live engine:
  `Eannot fps v` is the CARRIER of the race-check footprints
  (dyn_annotation lists) that E9's own soundness story consumes.
  It is model-internal load-bearing, same class as Eexcluded —
  reclassify (source-facing transparency is fine; the soundness
  case analysis is not "A"-grade trivial).
- **M-g · Unsequenced function calls unaddressed.** The model
  special-cases memop/action requests occurring unsequenced with a
  ccall (`is_unseq_with_ccall`, threaded through every
  Step_*_request2). C's indeterminate sequencing (calls don't
  interleave) is a different regime from unsequenced actions; E9
  says nothing about Eunseq containing Eccall. Needs a stated rule
  or a stated exclusion.
- **M-h · The E10/E12 validation flag — partially settled by this
  review, with corrections.** The paper reading (Neg-polarity
  residue unsequenced across wseq, discharged at bounds) is
  DIRECTIONALLY CONFIRMED: `break_at_bound_and_sseq` walks Neg
  actions out through wseq contexts to the enclosing
  Ebound/Esseq; exclusion ids implement the sequenced-with set.
  But: (i) the live engine is **Core_reduction**, not Core_run —
  the paper's flag cites "Core_run's race bookkeeping"; Core_run's
  core_thread_step2 is a legacy engine (fails on Eexcluded, warns
  "TODO negatives", ignores polarity entirely) and the Driver calls
  `Core_reduction.step_ctx`; (ii) the implementation has fail-stop
  holes the characterization lemmas will hit (`failwithI "TODO:
  NO_BOUND (Neg)"`; `failwithI` on negative SeqRMW); (iii) a
  mode-of-record question the paper must pin: `Core_sequentialise`
  rewrites `Ewseq/Esseq pat (Eunseq es) e2` into fixed left-to-right
  chains and the pinned libc text is the oracle's SEQUENTIALISED
  dump, while the Lean pipeline never calls `sequentialise_file` on
  user code — so user programs run live-unseq and library code runs
  pre-sequentialised. Which semantics is layer-1-of-record for
  Eunseq must be stated in §D (it changes what E9a/E9b are theorems
  ABOUT).
- **M-i · E9a's named metatheorem is only half the obligation.**
  §E.1 names interleaving-invariance (commutation). To use it you
  must first get from "preconditions separate" to "runtime DA
  footprints disjoint" — the **locality/footprint-confinement
  property of the semantic wp** (Yang/O'Hearn locality; the reason
  BRiCk can only AXIOMATIZE Mpar). For a wp defined over the
  monolithic interpreter state this is the genuinely hard half, and
  the ledger doesn't name it. The D grade stands; the risk text
  needs the second lemma.

## 3. MINOR FINDINGS

- B.3 header "the 6 non-atomic rows" vs 7 constructors / 8 rows
  (A1-A8). Grade-count arithmetic in §E totals 85 for an "87-row"
  figure (and the true memop count makes it 87 — fix together with
  MAJOR-5).
- ADQ statement: "∃ s', ⟦Q v̄ o⟧ s' for the resulting state s'"
  double-binds s' (should be: the resulting state satisfies ⟦Q⟧);
  "⊨ … is derivable" mixes semantic and syntactic turnstiles.
- A.2 binds parameters by substitution (`body_f x̄`) while E5/E4
  mint env cells — one binding story per §A.0's sorts, please
  (resolves itself under M-e either way).
- A4/A5: Kill needs `alive` at full fraction (unstated); A5 cites
  MerrFreeNullPtr as an excluded premise AND makes free(NULL) a
  defined no-op — both true only relative to the
  `forbid_nullptr_free` switch state; name the switch.
- E19's Eexcluded note is accurate, but in the LEGACY engine it is
  a failwithI, in the live engine it is real — say which.
- P29 parenthetical ("P29 = P12 counted once") is confusing;
  coverage of the 29 pexpr exports is in fact complete (verified
  name-by-name).

## 4. CITATION-CHECK RESULTS (attack 2)

Every load-bearing cite verified against the checked-out donors:

| Cite | Claim | Verdict |
|---|---|---|
| Caesium lang.v:588-589 | BinOpLCtx/BinOpRCtx fixed left-to-right | **EXACT** (RCtx requires v1 : val ⇒ left first) |
| Caesium lang.v:246 / :240 | PtrOffsetOp / eval_bin_op machine ints | **EXACT** |
| Caesium lang.v:470 / :476 | Call step / AllocFailed by fiat | **EXACT** (heap Alloc's AllocFailed also at :490-494) |
| RefinedC programs.v:68/:72/:96/:117 | typed_stmt (Q : gmap label stmt) / typed_block / typed_val_expr / typed_call | **EXACT, all four** |
| RefinedC function.v:59 | typed_function, fp : A → fn_params | **EXACT** |
| RefinedC ghost_state.v:92-162 | alloc_alive / alloc_global | **VERIFIED** (alloc_alive_def at :92) |
| RefinedC typing/intptr.v | exists, milder provenance | **VERIFIED** |
| BRiCk wp.v:124-139 | Kpred over ReturnType (5 ctors) | **EXACT** |
| BRiCk wp.v:485-497 | Mpar + NOTE "like the semantics of argument evaluation in C" | **EXACT & VERBATIM** (nb: the similar :305 NOTE on nd_seqs says "C++" — the paper quoted the right one) |
| BRiCk wp.v:290-292 | nd_seq | **EXACT** |
| BRiCk wp.v:606-624 | five value categories | **VERIFIED** (comment block; names per the C++ draft) |
| BRiCk wp.v:631 | `Parameter wp_lval` (axiomatized wp) | **EXACT** — and `Axiom wp_while_unroll` (stmt.v:483) confirms "rules as Axiom" |
| BRiCk stmt.v:467-508 / :484 | Kloop/wp_while_inv; ▷/Löb | **EXACT** (▷ at :484, iLöb at :492, "proved using Löb induction" :458). Bonus for D7: stmt.v:459-464 documents these partial rules as UNSOUND under infinite-loop-removal compilation — a genuine argument FOR the totality divergence the paper doesn't use |

Generated-AST cites: pexpr export :733 (29 ✓ name-by-name), expr
:1249 (19 ✓), actions (15 ✓), ctors :524 (17 ✓), binop (14 ✓),
polarity :267 ✓, SeqRMW Bool comment ✓, Esave params+defaults ✓,
undefinedFromMem_error :392 ✓ (all quoted UB codes present:
UB011/024/046/048/053/100, UB_CERB001/005, MerrUndefinedRealloc).
**One factual error: the memop count (MAJOR-5).** Otherwise this is
exemplary citation discipline and should be said so plainly.

## 5. DESIGN-QUESTION ADJUDICATIONS (attack 6)

- **DN-1 (pure binding): REJECT AS POSED.** Not because the
  recommendation is indefensible but because the menu omits the
  donor-default third option — substitution at BOTH levels (§6 row
  4, M-e). Re-pose with three options; if env cells survive, the
  justification must be an engineering measurement (term-size under
  substitution in large Core bodies is a legitimate concern worth
  measuring), not "Core's scope-stack is real" — the scope-stack is
  the interpreter's, and interpreter structure is what the
  soundness proof absorbs, per the paper's own ctl precedent.
- **DN-2 (ship both E9a/E9b): AMEND THEN ACCEPT.** E9b as stated is
  unsound (MAJOR-3). The corrected menu: E9a (primary, two-lemma
  metatheorem per M-i); E9b′ = orders + disjointness premise
  (sound, little cheaper than E9a); E9c = the genuinely free
  special case (≤1 effectful subexpression — no footprints, no
  race, orders collapse), which covers most elaborated argument
  lists and should be its own derived rule.
- **DN-3 (PEconstrained demonic): ACCEPT.** Matches the model
  (Step_constrained explores every constraint arm) and the
  outcome-set semantics; consistent with End/E13. The
  fixed-implementation note is correctly framed as a would-be
  ledger entry.
- **DN-4 (varargs in-figure with valist resource): ACCEPT.** VST
  lineage properly named; tail priority sensible; whole-of-Core
  ruling satisfied.
- **DN-5 (canAlloc carried): ACCEPT**, with one addition: if the
  model's allocator is genuinely infallible over an unbounded
  address space (Int addresses, monotone ids), then `canAlloc` may
  be a THEOREM of the model, not merely a dischargeable premise —
  determine this at V4, because it collapses the credits-vs-
  robustness decision for the p24 wrapper (whose drafted
  `{emp}`-precondition contract is only writable if canAlloc is
  free or the failure arm absorbs it).
- **DN-6 (fragment name/boundary): ACCEPT** after MAJOR-5's two
  dispositions land. The exclusion boundary is otherwise clean: no
  Core^seq rule secretly depends on Epar/Ewait/atomic rows
  (checked); NA restriction matches what the elaborator emits for
  non-atomic C; PEbmc_assume exclusion is sound (elaboration-path
  claim, plausible and testable).

## 6. THE DIVERGENCE AUDIT (operator addendum, 2026-08-29)

Every point where the paper differs from RefinedC (RC) or BRiCk
(BR), binned: **(1) unnecessary invention → adopt donor**,
**(2) real Cerberus constraint**, **(3) inherited pseudo-constraint
from our own machinery**.

| # | Divergence | Donor way | Bin | Adjudication |
|---|---|---|---|---|
| 1 | Three judgments by effect (wpPE/wpE/wpA) | BR: 5 value-category wps; RC: typed_val_expr/typed_stmt | **2** | Not a real divergence: judgment-per-syntactic-class IS the donor method; Core's grammar (pexpr/expr/action are three generated inductives) forces the classes. Forcing fact is about Core. KEEP. |
| 2 | Kpred over {norm} ⊎ labels | BR: ReturnType; RC: gmap label stmt | **2** | Real: elaboration compiles break/continue/return to save/run (verified in dumps: while_/break_/continue_/ret_ labels). KEEP. |
| 2b | **Label-introduction scoping: per-save-body** | RC: function-scoped label map | **1** | **UNNECESSARY INVENTION, AND WRONG** (MAJOR-1). The model is procedure-scoped (find_labeled_continuation); forward run-to-save is universal. ADOPT RC's shape. Amendment required. |
| 3 | Total correctness (termination in wp) | Both partial (▷/Löb) | ratified | Operator-ratified; consequences audited: (i) label rule must carry the variant primitively (MAJOR-2a); (ii) variant must be logically indexed (MAJOR-2b); (iii) recursion needs explicit measures + mutual form at contract intro (M-a); (iv) no Löb shortcut for recursion — accept the measure plumbing; (v) supporting argument available from BR's own soundness caveat (stmt.v:459-464). |
| 4 | **Env-cell sort `x ⇒ᵉ{q} v`** | None in either donor; λ-tradition/HeapLang: substitution | **3** | The claimed forcing fact ("Core's binder environment is real") is about the INTERPRETER (`th_st.env`), not about Core's meaning: Core binders are immutable, so binding-by-substitution is available (the model itself substitutes in places; `mk_value_pe` exists; DN-1 already adopts substitution at the pure level). The env is V1-decomposition/landed-ghost-map inheritance (CerbStateRA `env_pre : GhostMapG …`). Revisitable: price = redo E4/E5/E15 births layer + the landed env-cell machinery; gain = delete a novel sort, the fractions on immutable bindings (which exist only to share cells across unseq — free under substitution), and one coherence apparatus. The mechanization MAY still choose env-cells for term-size engineering — but then the paper must say that, with a measurement, not claim semantic necessity. **Do not ratify D6 as "the retrofit's novel sort" until DN-1 is re-posed (M-e).** |
| 5 | **`fresh(x)` premises inside `births`** | Both donors: fiat/none | **3** | Forcing fact = OUR hash-interned symbol supply + the route-A window (T4's collision episode) — machinery, not Core. Static distinctness is a parse-time invariant (fail-stop tripwire). Keep at ADQ instantiation (where §D already puts it); purge from the rules (M-d). |
| 6 | `supply(σ)` assertion sort | none | **3** | Same as 5; the paper's own ctl argument applies verbatim. Out of the figure, into the realization relation. |
| 7 | `canAlloc` premise vs AllocFailed-by-fiat | RC: ND failure by fiat (lang.v:476) | **2** | Real: model-refinement-ledger honesty + the no-ambient-assumption axiom (both operator-ratified). KEEP; check theorem-status at V4 (DN-5). |
| 8 | Allocation freshness as theorem | Both: fiat ND freshness | **2** | Real strength of the deterministic model (monotone ids). KEEP; praised. |
| 9 | UB-as-⊥, total, premise dictionary from the model's UB table | RC: UB untypeable; BR: UNSUPPORTED/False | **2** | Same discipline, better indexed. The paper's best section. KEEP. |
| 10 | Demonic ND everywhere | Consistent with both | — | No divergence. |
| 11 | E9a ∗-rule for Eunseq | BR Mpar (exact analogue, verified) | **2** | Real: ISO unsequenced-race fidelity, and the model really implements the race check (Core_reduction do_race). KEEP with the two-lemma metatheorem (M-i). RC genuinely dodged (verified, lang.v:588-589). |
| 12 | E9b orders-rule sans race premise | BR nd_seq | **1** | Adopted the donor combinator without the donor's semantics — unsound here (MAJOR-3). Fix the premise; then it's bin 2. |
| 13 | M8/M9 PNVI exposure rules | RC: milder intptr; BR: none | **3-adjacent** | The claimed constraint ("the model's PNVI instantiation") is not currently a fact of the model (MAJOR-4): the rules follow the PNVI ideal, not layer 1. Either track the model (concrete/PVI) or charter the model-mode change first. |
| 14 | Mathematical ℤ arithmetic + explicit UB gates (P13-P16) | RC/BR: machine ints inline | **2** | Real and verified (binop table is width-free; the elaborator emits catch_exceptional_condition). One caveat: model integer VALUES carry provenance (PVI) — "mathematical" is true of the arithmetic, not of the value sort; matters only at M9's doorstep. KEEP. |
| 15 | Contract judgment shape | RC typed_function/fn_params mirrored | **2** | Donor-faithful. KEEP. |
| 16 | Recursion via measure at E8 | RC: fntbl+Löb at function level | **1** | The measure is forced by totality (ratified), but the HOME is a divergence from both donors and wrong (M-a): move to contract introduction. |
| 17 | valist resource | VST lineage (named) | **2** | KEEP. |
| 18 | match/births auxiliaries | — | **2** | Patterns are Core-real. (births' fresh component → row 5.) |
| 19 | PEconstrained demonic row | No donor equivalent | **2** | Cerberus-real construct. KEEP. |
| 20 | alloc/alive/dead meta sort | Caesium ghost_state mirrored | **2** | Donor-faithful. KEEP. |

**Three-bin summary**: bin 1 (adopt donor, amend): 2b label scoping,
12 E9b premise, 16 recursion home. Bin 3 (our-machinery
pseudo-constraints, the operator's most-wanted class): 4 env sort,
5 fresh-in-rules, 6 supply sort, 13 (PNVI-idealization variant of
the disease). Bin 2 (real, keep): everything else — and the bin-2
set is large, which is the honest headline: **most of this design is
correctly donor-shaped or genuinely Cerberus-forced; the invented
remainder is small, identifiable, and in every case the donor
default or the paper's own ctl-argument gives the fix.**

## 7. EXPRESSIVENESS CHECK — frozen corpus vs the figure (attack 5b)

"AS AMENDED" = after the MAJOR-1/2 label+variant amendments and M-a.

| Row | Expressible as ∀-context contract? | Judgments used | Blocker in the CURRENT text |
|---|---|---|---|
| P01 clamp | YES | A.2 + wpPE (P22/P16) | — |
| P02 sat_add | YES | A.2 + P16/P22 (+F15 via E11 chains) | — |
| P03 swap may-alias | YES | A.2 + A6/A7; disjunctive (p=q-conditional) pre/post in iProp | — |
| P04 arr_sum | AS AMENDED | E14 inv + A7 + derived typed views | MAJOR-2b (variant), MAJOR-1 (labels) |
| P05 find_first | AS AMENDED | E14 inv + Krun early exit (E15) | same |
| P06 arr_reverse | AS AMENDED | E14 + A6/A7 | same |
| P07 list_sum | AS AMENDED | E14 + derived rep predicates (isList — derived layer, correctly placed) | same |
| P08 list_reverse | AS AMENDED | E14 + lseg/isList + A6/A7 | same |
| P09 call_contract | YES | E7 contract consumption + frame | — (E7's compat premise fine) |
| P10 gcd_rec | AS AMENDED | contract-intro recursion + E7 | M-a (recursion absent at E7, mis-homed at E8) |
| P11 gcd_iter | AS AMENDED | E14 variant | MAJOR-2b is fatal as written (variant over unchanging pointer args) |
| P12 pt_midpoint | YES | A6/A7 + P10/M13 struct offsets + frame-as-observable | — |
| P13 cell_alloc | YES | A3/A5 + leak conjunct as ownership post | — |
| P14 count_pairs | AS AMENDED | nested E14 invariants | MAJOR-1/2 |
| P15 scan_classify | AS AMENDED | E14 (∃-NUL witness invariant) + P14 conversions | MAJOR-1/2 |
| p24 h_malloc_cell | YES (caveat) | A3 + E7 + disjunctive post | drafted `{emp}` pre vs canAlloc premise — resolves at V4/DN-5 |

Bottom line: the JUDGMENT FORMS express everything (no row needs a
new judgment, sort, or harness notion — strong evidence the A-section
design is right); the current E14 text blocks 8 of 15 rows plus P10's
route, all through the two label/variant amendments.

## 8. GRADE/LEDGER HONESTY (attack 4)

Sampled 12 rows against the rip-out inventory's KEEP layer and the
tree at `arc/segment-ladder`:
- **Confirmed honest A/landed claims**: P1 (env GhostMap real,
  CerbStateRA:326-347), P3, P16 (checked-add chains — P02 proved),
  P22 (by_cases idiom), E1, E4/E11 (births + SegStep composition,
  CerbStateStep/Segment.lean), A6/A7 (MemLocal/Kit laws), M10, E15's
  rebind (landed), ADQ B (cerbSt_adequacy general face exists,
  inventory §1).
- **Overclaimed**: E14 "B — the composition is landed": the landed
  thing is `Seg.while_inv` in EXPLICIT-n form (Segment.lean:182) —
  the corpus doc itself records the variant gap, and with MAJOR-1/2
  the honest grade is C/D until the redesigned rule lands. E9b "B —
  sound fallback": unsound as stated (MAJOR-3). E18 "A": see M-f.
- **Ledger's five-hardest list**: correctly identifies the hard
  rows; E9a's risk statement is missing its harder half (M-i);
  M8/M9's risk is misdiagnosed (MAJOR-4); E10's flag is genuine and
  this review partially discharges it (M-h). No routine-graded row
  found hiding a metatheorem beyond these.

## 9. HARNESS RESIDUE / OPERATIONAL NARRATION (attack 3)

**Verdict: clean where it was commissioned to be clean.** No
judgment, premise, or rule references harnesses, choice streams,
splices, init states, or statement shapes; §F is genuinely one
derived paragraph; ADQ is ∀-state with instantiation-as-use — the
2026-08-29 rulings are executed faithfully and this deserves plain
praise. The residue that DOES exist is interpreter-narration, not
harness-narration: `fresh`/`supply` (M-d) and, arguably, the env-cell
sort (M-e) — all three flagged in the divergence audit as bin 3. The
`ctl` exclusion shows the paper knows the principle; apply it
uniformly and the section is immaculate.

## 10. WHERE THE DESIGN IS RIGHT (owed explicitly)

- The **§B.5 premise-dictionary discipline** — premises indexed by
  the model's own UB table so that no-UB is the conjunction of the
  figure, not a side claim — is the paper's central technical idea
  and it is correct, donor-grounded, and better-indexed than either
  donor. It also *generates* MAJOR-4 as its own enforcement: the one
  place the paper violated it is the one place the rules went wrong.
- The **three-judgment cut** and the recognition that Core
  pre-compiled C++'s value categories away is exactly right, and
  the BRiCk-granularity ruling is honored.
- **Kpred over {norm} ⊎ labels** is the right postcondition
  structure (only its introduction rule's scoping is wrong).
- The **∗-rule as showpiece with the orders-rule as insurance** is
  the right portfolio (after MAJOR-3's premise fix), and D9's
  reading of the donor landscape (Mpar the close donor, Caesium the
  dodge) is verified accurate.
- The **soundness architecture** (§D) makes the strongest trust
  claim of the three systems and states it accurately.
- **Citation hygiene** is exemplary (§4).

## 11. AMENDMENT LIST (exact; ratification-blocking = ★)

1. ★ E14/E15: function-scoped label environment (RefinedC shape);
   save-point = continuation obligation; introduction at A.2.
2. ★ E14: variant folded into the primitive rule; invariant family
   `I : W → list value → iProp`, W well-founded, back-edge
   `∃ w' < w`; drop the unsound bare form.
3. ★ E9b: add pairwise footprint-disjointness premise; add the
   free ≤1-effectful-subexpression derived rule; re-decide DN-2.
4. ★ M8/M9/B.4/D14: restate against the concrete-PVI model as
   implemented OR charter the PNVI mode switch first; strike "ours
   is the reference semantics" until layer 1 runs PNVI.
5. ★ Memops: 22 not 20; M21 Copy_alloc_id disposition, M22
   CHERI_intrinsic exclusion; fix censuses.
6. Recursion to contract introduction (A.2); mutual-recursion form;
   E7 consumes only.
7. P8/E4: first-match determinism + earlier-mismatch path facts.
8. E14 defaults premise via wpPE, conditioned on fall-through.
9. Purge `fresh`/`supply` from the rule figure (keep at ADQ);
   re-pose DN-1 with substitution-everywhere on the menu.
10. E10/E12 flag updated per M-h (engine = Core_reduction;
    failwithI holes named; the Eunseq mode-of-record pinned in §D).
11. E18 reclassified (annotation carrier is model-internal
    load-bearing); E9×Eccall regime stated (M-g).
12. E9a risk text gains the locality/confinement lemma (M-i);
    minor items of §3.

With 1-5 landed and 6-12 accepted as listed changes, this reviewer
would sign the figure as a credible pre-mechanization design of
record — the architecture already is one.
