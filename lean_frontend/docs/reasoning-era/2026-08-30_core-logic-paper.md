# The Core Program Logic — paper design (v3)

STATUS: PAPER DESIGN v3 (conceptual; deliberately not mechanized).
v1 commissioned [USER 2026-08-29]; v2 = v1 review's amendments + the
DN-1 substitution ruling; **v3 = the fresh full review's amendments**
(`notes/2026-08-30_core-logic-v2-fresh-review.md`, verdict
RATIFY-WITH-AMENDMENTS, FR-1..FR-7 + PR-3), applied per the operator
ruling [USER 2026-08-30] with the fresh review CORRECTING the v1 review
where they conflict (three transcribed-wrong prescriptions; §H meta-
note). Amendment log: §H.

Scope rulings (standing): granularity = BRiCk's (per AST node); no
mechanization sequencing; whole of Core except concurrency. Design
axioms: contracts primary, ∀-ambient-context; no privileged states;
rules at the most general true level; model-refinement conditions as
explicit premises or ADQ-instantiation obligations, never ambient; no
interpreter machinery in the figure; harnesses only in §F. Classical
names throughout.

Inventory (review-re-derived, exact): pexpr 29 (`generated/
Core.lean:733`), expr 19 (:1249), actions 15 (:1032), ctors 17 (:524),
binops 14 (:177), patterns (:552), polarity (:267); memops 22
(`generated/Mem_common.lean:570`). **Model of record**: the live engine
`Core_reduction.step_ctx` (Core_reduction.lean:484; driven by
`Driver.driver2`, Driver.lean:384) over the **concrete/PVI memory
model** (`CerbMem.lean`). Every rule premise in §§B.3-B.4 now carries
its raise-site citation or was deleted as phantom (FR-2/PR-3); the two
reviews' verified line facts are used throughout.

---

## A. The judgment forms

### A.0 The assertion language

Iris propositions over **heap and allocation resources plus pure facts
only**; binding is substitution (§A.1); the interpreter's environment,
supply, and control token are engine internals (§D).

| Assertion | Reading | Classical name / donor |
|---|---|---|
| `a ↦{q} bs` | byte-range points-to | gen_heap; Caesium `heap_mapsto`; BRiCk `_at` |
| `alloc(ι, a, n, ro)` (persistent) · `alive(ι)` (full fraction to kill) · `dead(ι)` (**persistent** — FR-7f: allocation ids are never reused; `nextAllocId` monotone, `deadAllocations` only grows) | allocation meta / liveness / tombstone | Caesium `alloc_alive` (ghost_state.v:92); CompCert blocks |
| **`space(n)`** | **allocation headroom: ownership of n bytes of the model's remaining (linear, never-reclaimed) address range** — FR-3, design below | Hofmann-lineage heap-space credits; Iris time/space-credit constructions; Iron-style resource accounting |
| `⌜φ⌝` · `□ contract(f, Φ)` | pure facts; persistent contracts | standard |
| `valist(ℓ, vs)` | varargs cursor (M17-M20) | VST va-list, in spirit |

Derived layer: typed points-to, representation predicates.

**The space-credit design (FR-3 — replaces v2's `canAlloc`, whose
"theorem-of-the-model" branch is dead).** The model's allocator is
bounded and history-dependent: `allocateObject`/`allocateRegion` grow
DOWN from `lastAddress = 0xFFFFFFFFFFFF` and reach
`NDkilled (MerrOther "out of memory")` when the aligned address hits 0
(CerbMem.lean:1478, :1506). A pure `canAlloc(n, al)` premise is
therefore not stateable in a ∀-context contract (headroom depends on
history). The mechanism, with classical lineage: **`space(n)` is a
linear resource** — the model's address space is consumed monotonically
(kills do NOT reclaim addresses), which is exactly credit structure.
A1-A3 consume `space(sz + al − 1)` (the bump-with-alignment worst-case
slack); nothing ever mints `space` back. The realization relation ⟦·⟧
interprets `space(n)` as "n ≤ current headroom" (soundness lemma in
§E); **ADQ instantiation funds the initial supply from the realizing
state's actual headroom** — for corpus corollaries the 2^48-scale
headroom makes the budget arithmetic trivial (and anti-brute-force-
compliant). Contracts that allocate carry `space(A_f)` in their
precondition — explicit, compositional, automatable (elaborated sizes
are literals; the arithmetic is omega-class). Because **every
elaborated call stages by-pointer locals with `create`** (verified:
p01's main creates the argument cell before `ccall`), essentially every
contract carries a small credit term — a per-contract bookkeeping cost
the automation must own (§E, hardest-list item 3). Consequences:
**P13** gains `space(sizeof(int)+slack)` in its precondition
(instantiation-funded in the harness corollary); **p24**'s failable
wrapper becomes `{space(n′)} h_malloc(n) {r. (r = NULL ∗ space(n′)) ∨
(r ↦ unspec(n) ∗ alive ∗ alloc)}` — the choice-driven failure arm
returns the credit; the drafted `{emp}` precondition is not writable
(DN-5's hopeful branch closed by inspection).

**Other explicit premise families:** provenance/concreteness premises
at the memop rules (stated against the implemented PVI model, §B.4);
freshness/window obligations live at ADQ instantiation only.

### A.1 Substitution-everywhere; the three judgments

(Unchanged from v2 except as noted.) Binding is by substitution at
every level; `match(p, v) ⇓ σ` yields substitutions; no environment
cells, no births, no binder fractions; label jumps are instantiation.
The engine's mixed substitution/env implementation (it already
substitutes in Ecase branches — `select_case subst_sym_expr`) supports
the reading; the environment≈substitution correspondence is the §D
metatheorem family. Judgments: `wpPE e {v. Q}` (pure; UB-as-⊥;
demonic constrained-ND), `wpE e ⟨Knorm; Krun⟩` (effectful; total,
demonic; Krun : label → list value → iProp), `wpA α ⟨K⟩` (actions).
Donor mapping unchanged (D2/D3).

### A.2 Contracts, the label environment, recursion (FR-4, FR-6a/c)

For procedure `f`: `Labels(f)` = the labels the engine's
procedure-wide collection returns — built by
`Core_aux.collect_labeled_continuations` (Core_aux.lean:622, called at
Driver.lean:436), whose `Esseq` case wraps a label's continuation
through the enclosing sequence (so `cont_ℓ` = the procedure's
continuation from the save point — engine-verified). **Wellformedness
caveat (FR-6c): the collection returns `fmapEmpty` under `Ebound` — a
save beneath a bound is procedure-invisible.** Elaboration keeps saves
at statement level; the figure carries the premise *no label of
Labels(f) sits under an Ebound* (else figure and model would disagree
on which jumps resolve).

Each ℓ ∈ Labels(f) carries a **spec-indexed invariant family**
(FR-4 — v2's unindexed type could not state any corpus loop invariant,
e.g. P04's `s = Σ_{k<i} xs[k]` over the quantified xs):

`I_ℓ : A → W_f → list value → iProp`   (A = the spec-index type;
one well-founded (W_f, <) per function)

**Contract introduction** (recursion homed here; all three premise
lines under the same `∀ a x̄` — FR-4's binding fix):

```
Family F = {f₁…fₖ}, spec indices A, ONE well-founded measure μ over
indexed calls:

for each f ∈ F with spec (P, Q) and invariants I:
 (IH)     □ ∀ g ∈ F, ∀ b, μ(g,b) < μ(f,a) → contract(g, b)
 (body)   ∀ a x̄, P a x̄ ⊢ wpE (body_f[x̄]) ⟨Knorm := Q a x̄ ;
                                Krun := λℓ v̄. ∃w, I_ℓ a w v̄⟩
 (labels) ∀ a x̄ (with P a x̄'s pure content available), ∀ ℓ, w, v̄,
            I_ℓ a w v̄ ⊢ wpE (cont_ℓ[params_ℓ := v̄])
              ⟨Knorm := Q a x̄ ;
               Krun := λℓ' v̄'. ∃w' < w, I_{ℓ'} a w' v̄'⟩
conclusion: □ contract(f, (P,Q)) for every f ∈ F
```

Floyd every-cycle-decreases: from inside any label continuation at
index w, EVERY label entry — by jump **or by fall-through (FR-1)** —
demands an index < w; from the entry body, some index. Forward jumps
and nested loops are provable via rank/lexicographic components of W_f.
E7/E8 consume contracts only.

### A.3 Control and totality (FR-1 applied)

**E14 (fall-through save entry) routes through `K.run`** — the v2 form
`wpPE defaults {v̄. ∃w, I_ℓ w v̄}` is DELETED as unsound (the fresh
review's nested-loop counterexample: an inner `Esave` met inside an
outer label's continuation reset the index upward on every outer
iteration, deriving total-wp of `while(1){int i=0; while(i<0)i++;}`).
With fall-through consulting the same map as jumps, every edge of every
cycle decreases; re-verified against that counterexample: the inner
save's entry inside the outer continuation at w now demands
`∃w′ < w, I_inner a w′ v̄`, and the trailing `run while_outer` inside
the inner continuation at w′ demands an index < w′ < w — each outer
cycle strictly descends, so the divergent program is unprovable, while
terminating nested loops discharge via lexicographic W_f. This is also
MORE donor-conformant: RefinedC has no privileged fall-through — every
block entry goes through the Q map (programs.v:72). Totality content
of the figure = **three** separable elements (G1 amended): the
`∃w′ < w` in (labels), the measure μ, and E14's K.run routing.

Path conditions as pure facts (unchanged). The bare/unconstrained
label rule exists only in the partial sibling `wpE^∂` (§G1).

### A.4 Nondeterminism

Demonic everywhere. Eunseq portfolio: E9a primary; E9b′ **demoted to a
derived rule** (FR-5: with the disjointness premise it is E9a's
premises with a weaker conclusion); E9c the free ≤1-effectful case.
Pointer equality at mixed provenance is a genuine model ND fork —
M1/M2 are demonic there (FR-2).

---

## B. The rule figure

(Only rows changed from v2 are annotated; unchanged rows carry over.)

### B.1 Pure expressions (29)

**P1-P7, P10-P28** as v2, except:

**P8 · PEcase** — clean first-match form (FR-7c):
```
wpPE e {v. ∃i, (∀ j < i, ⌜¬match(altⱼ.p, v)⌝)
           ∧ match(altᵢ.p, v) ⇓ σ ∧ wpPE (σ altᵢ.body) {Q}}
```
(deterministic first-match; matches `select_case`/`match_pattern`,
Core_aux.lean:637). Non-exhaustive = ⊥. Validation rider (FR-7d): the
live engine fail-stops on `Ecase` of `PEconstrained`
(`failwithI "TODO: … Ecase PEconstrained"`) — on P4/E4's census. **B**

**P9 · PEarray_shift** — **total; the UB046 premise was PHANTOM**
(FR-2): neither `arrayShiftPtrval` nor the eff wrappers check bounds;
`MerrArrayShift` has no raise site. Pure pointer arithmetic; OOB
consequences surface at the access rules (A6/A7). *(§B.4F holds the
checked PNVI-style variant.)* **B**

**P27 · PEbmc_assume** — exclusion re-worded (FR-7g): the elaborator
DOES emit it for the `__bmc_assume` builtin (translation.lem:3106-
3126); the exclusion is "programs calling __bmc_assume are out of
fragment", not "never emitted".

### B.2 Effectful expressions (19)

**E1-E8, E11, E13, E15-E19** as v2 (E7/E8 consume-only), except the
E9/E10/E12/E14 block:

**E9 · Eunseq** (FR-5 re-portfolio; model facts per the fresh review's
§1 — annotations flow outward through wseq AND sseq, die at Ebound,
join-only `do_race` at `one_step_unseq_aux`, R/W-aware `overlapping`):

*E9a — primary (unchanged statement):* the ∗-rule; the separating
conjunction is the race-freedom obligation. Ledger: the two-lemma
metatheorem with lemma (a) in its **provable, per-location R/W-aware
form** (FR-7b): each arm's accesses are covered by its fractional
resources, and cross-arm address-overlapping accesses are both reads —
NOT "footprints disjoint" (false under legitimate `↦{1/2}`
read-sharing; the model's R/W-aware `overlapping`,
CerbMem.lean:1187-1191, is what makes the weaker form suffice). **D**

*E9b′ — DERIVED (demoted, FR-5):* under E9a's ∗-premises, the demonic
conjunction of the n! sequential orders also concludes the unseq wp —
a corollary recorded for automation (order-wise stepping is sometimes
mechanically cheaper); it earns no independent premise language. **—**

*E9c — the free case:* all but ≤1 subexpression pure (pure arms are
`wpPE`-provable — an assertion-language condition; no footprint objects
named): no race possible, orders collapse. Covers most elaborated
argument lists. **A/B**

*E9×Eccall:* as v2 (calls indivisible; `is_unseq_with_ccall`), riding
the E10 validation flag. **C**

**E10 · Ewseq** — the race proviso now has an **assertion-language
form** (FR-5): define the annotated judgment face `wpE^N e ⟨K⟩` ("e's
wp with its negative-polarity action rules drawing their resource
premises from the bundle N" — a derived notion: the Neg-action rows'
premises are confined to N; N is an ordinary iProp). Rule:
```
N ∗ P₂    N ⊢-confined wpE^N e₁ ⟨Knorm := λv. match ⇓ σ ∧ …⟩
P₂ ⊢ (σ-continuation) wpE e₂ ⟨K⟩
────────────────────────────────
N ∗ P₂ ⊢ wpE (Ewseq p e₁ e₂) ⟨K⟩
```
— the ∗-split between e₁'s negative-action footprint resources and
e₂'s precondition; no engine objects in the premise. Validation rider
unchanged (directionally confirmed; `break_at_bound_and_sseq`;
fail-stop holes: `NO_BOUND (Neg)`, negative SeqRMW, `NO_BOUND
(SeqRMW)`, + Ecase-PEconstrained on the census). **C/D**

**E12 · Ebound** — as v2, with the proviso in the same `wpE^N` form
(the enclosed Neg-residue's N discharged at the boundary; annotations
die at Ebound — engine-verified). **B/C**

**E14 · Esave** — **fall-through routes through the label map**
(FR-1):
```
wpPE defaults {v̄. K.run ℓ v̄}
──────────────────────────────
wpE (Esave ℓ params body) ⟨K⟩
```
Inside a label continuation this demands `∃w′ < w` (decrease); in the
entry body, `∃w` (initial). Defaults are pexprs (ret labels carry
`undef(UB088)` — ⊥ does the work; main's ret default is
`Specified(0)`, engine-verified). **C** (redesigned rule; the landed
Seg machinery is its explicit-index special case).

### B.3 Memory actions (8 in-fragment rows; raise-site-swept — FR-2/
PR-3; citations to CerbMem.lean)

**A1 · Create** — premises: `space(sz + al − 1)` (FR-3; the OOM kill
at :1478 is what the credit excludes). **The v2 `alignOK` UB-premise
was PHANTOM** (no alignment raise site — the allocator merely computes
the aligned address; slack is priced in the credit). Post: fresh ι
(deterministic monotone allocator — the v2 "alloc-ND" stray phrase
deleted, FR-6d), `alive(ι) ∗ alloc(ι,a,|τ|,rw) ∗ a ↦ unspec(|τ|)`.
**B**

**A2 · CreateReadOnly** — as A1 + initializer + read-only meta. **B/C**

**A3 · Alloc0** — as A1 (dynamic-eligible); OOM kill :1506; `space`
consumed; failure-coverage via the wrapper pattern at application.
**B**

**A4 · Kill (Static0)** — full-fraction `alive(ι)` + points-to →
`dead(ι)`. Raise sites real: MerrUndefinedFree arms :1528-1545. **A/B**

**A5 · Kill (Dynamic0)** — free: premises = designates-allocation-start
(Free_non_matching :1528,:1534,:1539,:1545), live (Free_dead_allocation
:1532), in-bounds (Free_out_of_bound :1537 — NOTE: maps to `none` in
the UB table, a **killed-not-UB** outcome; the premise excludes a
kill). free(NULL) = **unconditional no-op** — the v2
`forbid_nullptr_free` switch premise is DELETED as phantom (FR-2: the
switch is a dead enum, CerbGlobal.lean:25, consulted nowhere;
MerrFreeNullPtr unreachable; oracle-parity note retains the name).
**B**

**A6 · Store0** — premises all raise-site-real: in-bounds (MerrAccess
StoreAccess OutOfBoundPtr :1675), writable (MerrWriteOnReadOnly :1690),
type-fit (**a killed-not-UB guard**: ill-typed store = MerrOther
non-UB kill, :1667, checked before the pointer-kind match), concrete
provenance (Prov_symbolic MerrOther kill :1678), full-fraction `↦`.
**Sweep finding beyond the review's list: the `locking` flag has real
semantics** — a locking store transitions the allocation to read-only
(:1650-1660, mirroring impl_mem.ml:1776-1787; string-literal/const
initialization): the A6-locking variant's post updates `alloc(…, ro)`.
**A** (base) / **B** (locking variant)

**A7 · Load0** — premises raise-site-real: live (DeadPtr :1555),
in-bounds (OutOfBoundPtr :1613, Prov_none :1553), concrete
(Prov_symbolic kill :1616), **no-trap-representation (MerrTrap-
Representation LoadAccess :1604 — REAL and previously missing)**;
atomic-member guard (:1695). **Sweep finding: the v2 uninit/UB011
premise was PHANTOM — `MerrReadUninit` has NO raise site in the
implemented model**; uninitialized loads yield `LVunspecified` without
UB. **A/B**

**A8 · SeqRMW** — fused load-substitute-store (unchanged); rides A6/A7
premises; the Neg-polarity fail-stop hole is on the E10 census. **B**

### B.4 Memory operations (22; swept — FR-2; model of record =
concrete/PVI as implemented)

**Preamble, scoped honestly (FR-2/coordinator):** the rows below track
the implemented model **at the rows audited by the two reviews and the
§H sweep** (raise-site citations inline); **PR-3 — the mechanical
raise-site sweep — is a standing pre-mechanization check** that
re-verifies the full table against `CerbMem`/`Core_reduction` before
any memop rule is mechanized (the fresh review's §1 supplies more than
half the table). The PNVI-grade rules live in §B.4F.

**M1/M2 · PtrEq/PtrNe** — **corrected (FR-2; v2's description was
unsound):** same-provenance (or null/function-shape) operands →
deterministic address equality; concrete operands of **different
provenance → a genuine demonic ND fork** (`eqPtrval` :1731: msum over
{provenance-answer false, address-equality}) — the rule concludes
`∀ b ∈ {false, addr-eq}, Q b` at that corner (the classic
one-past-end == next-base comparison can answer false at equal
addresses). No MerrPtrComparison anywhere. **B/C**

**M3-M6 · PtrLt/Gt/Le/Ge** — **corrected (FR-2):** the model runs the
NON-STRICT variants — address comparison **regardless of provenance**
(cross-allocation comparison is defined); the v2 same-allocation/UB053
premise was PHANTOM (no raise site). Real premises: concrete, non-null,
non-function operands (the MerrWIP arms :1767 — **killed-not-UB**).
**B**

**M7 · Ptrdiff** — real (MerrPtrdiff raised, :1814; same-allocation
precondition per :1807). Unchanged. **B**

**M8 · IntFromPtr** — representability premise (MerrIntFromPtr :1922);
provenance carried in the IV. (FR-6b: the provenance is passed
directly; `combineProv` :227-240 is the arithmetic-merge path, not
this one.) **B**

**M9 · PtrFromInt** — never fails; integer's provenance passes
through; usability at use sites. Scope line: PVI certifies less than
PNVI-ae-udi. **B/C**

**M10 · PtrValidForDeref** — decided by **liveness + alignment** (no
bounds check — `validForDerefPtrval` :1867; v2's "bounds" was a
misdescription, FR-2); concreteness premise (:1886 kill). **A/B**

**M11 · PtrWellAligned** — sweep addition: premises exclude the
void/function-operand **MerrOther kills** (:1851-1858); otherwise
total. **B**

**M12/M13 · PtrArrayShift/PtrMemberShift** — **UNCHECKED in the model**
(FR-2: no MerrArrayShift raise site; "checked shift" deleted): total
address arithmetic; consequences at access rules. **B**

**M14 · Memcpy** — per-byte checked load/store loop (:1945) — the
readable/writable/per-byte premises are A6/A7's, REAL; **the UB100
overlap premise is dropped** (overlap-UB unimplemented — the model's
own header; FR-2). If upstream implements it, the premise returns
(model-mode note). **B/C**

**M15 · Memcmp** — sweep/FR-2: **initialized-bytes premise added**
(the model PANICS loudly on an uninitialized byte — a non-UB
fail-stop, :1977 region). **C**

**M16 · Realloc** — real arms cited: MerrUndefinedRealloc
Free_non_matching :2020, Free_dead_allocation :2022 (per
impl_mem.ml:540-546 mapping); compound contract over A3+copy+A5.
**C/D**

**M17-M20 · Va_\*** — `valist` resource; premises exclude the MerrWIP
validity arms (:2123 et al. — killed-not-UB). **C**

**M21 · Copy_alloc_id** — **corrected (FR-2): the implemented memop is
the identity on its pointer argument** (`copyAllocId` :2172 =
`memReturn pv`; the integer is discarded; the VIP error constructors
exist in the type but nothing raises them). Rule: trivial
identity. The RefinedC/PNVI provenance-transfer reading moves to
§B.4F (M21F). **B**

**M22 · CHERI_intrinsic** — EXCLUDED (CHERI boundary). 

#### B.4F · FUTURE table (PNVI-ae-udi mode; rules about a future model)

M8F (exposure effect), M9F (exposed-live recovery, MerrPtrFromInt
becomes reachable), M21F (genuine allocation-id transfer, VIP arms
live), **and — G3 re-scope (fresh review) — the comparison rows**: under
PNVI the pointer-relation semantics changes too (strict relationals,
provenance-sensitive equality), so the switch's perimeter is
**M1-M9 + M21**, and the re-proof class includes comparison-heavy
programs, not only cast-heavy. Gated on the chartered model-mode
switch.

### B.5 The UB catalog — unchanged discipline, one addition

Premises = the conditions under which the model reaches neither the UB
table NOR a **killed-not-UB outcome** (the class the sweep surfaced:
MerrOther OOM, MerrWIP arms, Free_out_of_bound→none, ill-typed-store,
memcmp's uninit panic, the engine's failwithI holes). Both classes are
⊥ for `wpE`; ADQ's wording says so (FR-7a).

---

## C. The equivalence dictionary — deltas from v2

D6 gains the honesty sentence (fresh review §5): BRiCk's `region ρ` is
a name→ptr environment — our label parameters play ρ's role and are
substituted instead; defensible under DN-1, now said. D14 unchanged
(concrete/PVI of record — the fresh review verified this call as
"RIGHT CALL"). D9/D10 updated: E9b′ derived, not independent. D11/D12
updated: allocation exhaustion is REAL in our model (space credits) —
the fiat donors dodge both freshness AND exhaustion; the divergence is
now carried to its conclusion (the review's own phrase). Everything
else stands as v2.

---

## D. The soundness architecture — deltas from v2

Engine of record and the correspondence family unchanged (the fresh
review verified both, including the Ecase-substitution wrinkle that
makes one correspondence lemma free). The Eunseq **mode-of-record pin**
stands as an open operator decision (live-unseq recommended; the fork
is real — user code live-unseq, pinned libc pre-sequentialised).

**ADQ (FR-7a wording):**
```
ADQ: if {P} f {Q} is derivable in the figure, then semantically:
  ∀ s, v̄,  ⟦P v̄⟧ s →
    every execution of f(v̄) from s terminates WITHOUT UB, WITHOUT
    non-UB error kills, and WITHOUT engine-incomplete branches, and
    for every outcome o the resulting model state realizes Q v̄ o.
```
The killed-not-UB class (OOM, MerrWIP, Free_out_of_bound, panics,
failwithI holes) is excluded explicitly — the space-credit premise is
what excludes the OOM kill; the concreteness/validity premises exclude
the MerrWIP/kill arms; the engine-hole census (E10/P4) bounds the
incomplete branches. All engine-side obligations (realization,
freshness window, initial `space` funding) discharge here, uniformly.

---

## E. The ledger

Derived tallies (89 rows; per-row grades authoritative): **A/A-B ≈ 22 ·
B ≈ 26 · C ≈ 19 · C/D-D ≈ 7 · excluded 14 · aux 1.** The FR-2 sweep
mostly SIMPLIFIED rows (phantom premises deleted: P9, M3-M6, M12/M13,
M14, A5, A1-align; M21 collapsed to identity); it hardened M1/M2
(demonic fork) and M15/A7 (real premises added).

**The seven hardest (fresh review's amendment: five → seven):**

1. **E9a's two-lemma metatheorem** — (a) per-location R/W-aware
   coverage (FR-7b's provable form; Yang–O'Hearn locality made
   fraction-aware), (b) interleaving-invariance vs the join-race
   scheduler. **D**
2. **The environment≈substitution correspondence family** — M-L at the
   hot factor; gated by PR-1/PR-2 (below). **D-adjacent**
3. **Space accounting (FR-3)** — the credit-soundness lemma
   (`space(n)` ⊑ actual headroom through the monotone bump allocator,
   alignment slack included) + per-contract credit bookkeeping on
   every prologue `create`; automation must make the arithmetic free.
   **C/D, on every corpus row's critical path**
4. **The E10/E12 polarity cluster** — assertion-form provisos
   (`wpE^N`), validation riders, the named failwithI holes
   (+ Ecase-PEconstrained), the mode-of-record pin. **C/D**
5. **Totality-index plumbing** — lexicographic/rank W_f through
   function-scoped label environments under FR-1's all-edges-decrease
   discipline; **exercise early on P14** (nested loops — the exact
   shape FR-1's hole sat on). **C**
6. **Realloc/Memcpy compound contracts.** **C/D**
7. **Total recursion at contract introduction** (mutual measure
   plumbing; P10 acceptance). **C**

**Pre-mechanization probes (now three, all named):**
- **PR-1** — label-args-as-instantiation vs the engine on a corpus
  loop dump, **including a rebinding case** (FR-7e).
- **PR-2** — substitution feasibility over the generated AST:
  term-size measurement on large bodies **plus shadow-correctness**
  (FR-7e: elaborated label params snapshot the variables they shadow —
  `save while_641: (i := i)`; the subst function and correspondence
  lemmas must be shadow-correct).
- **PR-3** *(new — FR-2 institutionalized)* — the mechanical raise-site
  sweep: for every B.3/B.4 premise, the CerbMem/Core_reduction line
  that raises the named error, or PHANTOM-delete; for every row
  description, the transcribed behavior. Standing check before any
  memop/action rule is mechanized; the fresh review's §1 + this
  version's §H sweep already cover the majority.

Cross-cutting obligations: P7/P8 argument-commutation; E9c derivation;
the B.4F model-mode charter (operator); the `wpE^N` face's derivation.

---

## F. Application — unchanged (one paragraph, corollary-shaped).

---

## G. FLEX — deltas from v2

**G1**: totality content = **three** separable elements (∃w′<w, μ,
E14's K.run routing — FR-1); the partial sibling `wpE^∂` keeps the
unconstrained E14 and remains sound there (fuel-inductive safety).
**G3**: re-scoped (fresh review): the PNVI switch's perimeter is
M1-M9+M21 (comparison semantics change too); re-proof class =
cast-heavy AND comparison-heavy programs; still additive, wider.
**G5**: PR-2 now carries the shadowing check (FR-7e). G2/G4/G6
unchanged (review-verified: no foreclosure found).

---

## H. Amendment log

### v1 → v2 (per the first review; retained)

| Finding | Disposition |
|---|---|
| MAJOR-1..5, M-a..M-i, §3 minors, DN adjudications, flex addendum | As logged in v2 (see git history of this file); the fresh review's §9 verified every entry as genuinely executed, no regressions. |

### v2 → v3 (per the fresh review; [USER 2026-08-30]: the fresh review
corrects the v1 review where they conflict)

| Finding | Disposition in v3 |
|---|---|
| FR-1 ★ (E14 re-admits divergence via fall-through) | E14 premise → `wpPE defaults {v̄. K.run ℓ v̄}`; ∃w-form deleted; re-verified against the nested-loop counterexample (each outer cycle now strictly descends); G1 = three totality lines; noted MORE RefinedC-conformant (no privileged fall-through, programs.v:72) |
| FR-2 ★ (B.5 discipline un-swept; 9+ rows) | Full B.3/B.4 raise-site sweep executed with inline citations: M1/M2 → demonic ND fork (the unsound corner fixed); M3-M6 → non-strict/cross-allocation-defined, UB053 phantom deleted, MerrWIP kill premises added; P9/M12/M13 → total (UB046 phantom); M14 → UB100 dropped (unimplemented); M15 → initialized-bytes premise; M21 → identity rule (PNVI reading to B.4F); A5 → switch premise deleted (dead enum); M10 → alignment-not-bounds; M11 → void/function kill premises; preamble scoped to audited rows; **PR-3 added as the standing check** |
| FR-2 sweep, beyond the reviewer's list (§H sweep, raise-site greps) | **A7: uninit/UB011 premise PHANTOM (no MerrReadUninit raise site) — deleted; trap-representation premise REAL (:1604) — added**; **A6: locking flag has real read-only-transition semantics (:1650-1660) — post updated; ill-typed store = killed-not-UB guard (:1667)**; **A1: alignment-UB premise phantom — absorbed into credit slack**; M16's two real realloc arms cited; Va_* MerrWIP validity premises; the killed-not-UB CLASS named in B.5/ADQ |
| FR-3 ★ (canAlloc's sort undecidable-as-pure; bounded allocator) | **Space credits chosen** (`space(n)`, linear — matches the never-reclaimed address space; Hofmann/Iron/Iris-credits lineage); A1-A3 consume `sz+al−1`; ⟦space⟧ ⊑ headroom soundness lemma; ADQ-instantiation funding; P13 pre += space; p24 `{emp}` closed → credit-carrying with failure-arm credit return; DN-5's theorem branch recorded DEAD (:1478); promoted to hardest-list #3 with the every-prologue-creates ubiquity note |
| FR-4 (unindexed I_ℓ; unbound schema variables) | `I_ℓ : A → W_f → list value → iProp`; all three premise lines under ∀ a x̄; corpus loop invariants now stateable |
| FR-5 (race provisos have no sort) | E10/E12 provisos as `wpE^N` ∗-splits (assertion-language); E9b′ demoted to derived |
| FR-6 (citations/wellformedness) | collect_labeled_continuations (:622) cited, find_labeled_continuation dropped; combineProv :227-240 corrected; Labels(f) Ebound-invisibility premise added; A1's "alloc-ND" stray deleted |
| FR-7 (hygiene) | ADQ "without UB, non-UB error kills, or engine-incomplete branches"; E9a lemma (a) per-location R/W-aware; P8 form fixed; Ecase-PEconstrained on the census; PR-2 + shadowing, PR-1 + rebind case; dead(ι) persistent + id-non-reuse fact; P27 __bmc_assume wording |
| Meta (review §9) | Recorded: v2 faithfully transcribed three wrong v1-review prescriptions (the A5 switch injection, the unindexed I type, the unconstrained defaults premise) and one over-general claim (the B.4 preamble); v3 treats the fresh review as correcting; PR-3 exists so future fidelity claims are checked against the MODEL, not against any review |
