# Core logic paper v3 — third fresh review

REVIEWER: fresh Fable-class agent, no project history, per the
standing fresh-eyes ruling [USER 2026-08-30]. Target:
`notes/2026-08-30_core-logic-paper.md` (v3, §H amendment log).
Method: ALL findings formed from primary sources first — the live
model (`worktrees/cerberus-lean-coherence/lean_frontend/generated/`:
CerbMem.lean read in full, Core_aux.lean, Core_reduction.lean,
Core_run.lean, Driver.lean, Mem_common.lean's UB table, Core.lean
inventory), actual elaborated Core (`tests/verify/*.core`), the donors
(deps/refinedc `theories/typing/programs.v` + `theories/caesium/
ghost_state.v`; deps/BRiCk `logic/wp.v`), the catechism, the frozen
corpus doc, and the CLAUDE.md 08-29/30 rulings. The two prior reviews
were SEALED until §§0–6 below were complete; §7 is the cross-check,
written last. READ-ONLY review; no builds run.

---

## 0. VERDICT

**RATIFY-WITH-AMENDMENTS.** Eight amendments, listed exactly in §0.1.
None is a redesign; two (V3-2, V3-3) are statement-level fixes inside
v3-NEW material that would be false/inconsistent if mechanized as
written; one (V3-1) re-anchors a load-bearing citation to the function
the driver actually calls. The rule content of the figure — including
every v3-changed row I audited — is coherent with the model as
implemented, and the two headline v3 fixes (E14's K.run routing;
the FR-2 sweep's row corrections) are RIGHT: I attacked both
independently and they held. This is now, in my judgment, the right
foundation (sharpest-judgment §8), one amendment pass away from
ratifiable.

### 0.1 The exact amendments

1. **(V3-1) Re-anchor A.2's label environment to the real engine
   path**: `collect_labeled_continuations_NEW` (Core_aux.lean:853)
   → `collect_saves` (:778) / `collect_saves_aux` (:770), which is
   what Driver.lean:436 calls and what the Erun step resolves against
   (`run_st.labeled`, Core_reduction RUN arm). Rescope the FR-6c
   wellformedness caveat to that function's actual perimeter
   (Ebound AND End invisible; Ecase/Eunseq/Epar ARE traversed).
2. **(V3-2) Fix the space-credit realization off-by-one**: define
   ⟦space(n)⟧ as `n ≤ lastAddress − 1` (address 0 is the model's
   OOM sentinel and never usable), or equivalently consume
   `space(sz+al)`. As drafted ("n ≤ current headroom" with the
   natural headroom = lastAddress), `space(sz+al−1)` does NOT
   exclude the OOM kill at the boundary — the §E soundness lemma
   would be false. One line; must be pinned before mechanization.
3. **(V3-3) Resolve the A6-locking / persistent-alloc contradiction**:
   A.0 declares `alloc(ι,a,n,ro)` persistent with the readonly status
   inside it; A6-locking's post "updates alloc(…,ro)". Persistent
   resources cannot be updated. Factor the status out (persistent
   `alloc(ι,a,n)` + a full-fraction writable/status token consumed at
   locking — the Caesium alloc_alive dfrac pattern the paper already
   cites).
4. **(V3-4) Add the panic-class premises the sweep missed**:
   `arrayShiftPtrval` PANICS on null and function pointers
   (CerbMem.lean:1132-1135); `memberShiftPtrval` panics on function
   pointers (:1164). P9/M12 need non-null+non-function operand
   premises; M13 non-function. Extend PR-3's mandate from Merr raise
   sites to panic!/failwithI/fuel sentinels in the helpers the rows
   call.
5. **(V3-5) Citation-precision repair inside the sweep** (§2 table):
   the comment-line and wrong-arm cites (A7 ×3 + atomic-guard row-swap,
   A6 ×2 + missing atomic premise, A5 label transposition, M3-M6);
   state where A6/A7's liveness lives (the ↦-implies-live realization
   invariant vs the model's MerrOutsideLifetime = UB009 path).
6. **(V3-6) Give `wpE^N` a semantic definition and a lineage** (CSL
   resource-bundle confinement is the honest nearest; or declare
   post-exhaustion novelty per the anti-innovation ruling). Its
   derivation is priced but its meaning is currently a promissory
   note.
7. **(V3-7) Scope A7's trap-representation premise to _Bool** (the
   model checks only `Bool0` loads, :1599-1604); blanket form is
   sound but needlessly incomplete.
8. **(V3-8) Ratification mechanics**: v3 is a delta document ("as v2
   except…") whose base lives in git history. Produce the
   consolidated, self-contained figure AT ratification; and add one
   named line to hardest-item 3: allocating LOOPS (the libxml2
   xmlBufferGrow class) put symbolic credit arithmetic into loop
   invariants — the "automation must make it free" claim is currently
   assessed against prologue-create literals only.

---

## 1. Independent findings, ranked

### V3-1 (MAJOR as record-integrity; LOW semantic damage). The label-environment anchor is the wrong function — the third wrong anchor in three reviews.

A.2: "Labels(f) = the labels the engine's procedure-wide collection
returns — built by `Core_aux.collect_labeled_continuations`
(Core_aux.lean:622, called at Driver.lean:436)". Checked against the
tree: Driver.lean:436 reads `initial_core_run_state
(collect_labeled_continuations_NEW file1)`. That function
(Core_aux.lean:853) folds `collect_saves` (:778, worker :770) over
every Proc in the file; the Erun reduction resolves jumps against the
resulting `run_st.labeled` map (Core_reduction, RUN arm; unresolvable
label = loud `failwithI "Erun couldn't resolve label"`). The :622
function exists but its only live consumer is the LEGACY engine
(`Core_run.core_thread_step2`, Core_run.lean:395) — not the model of
record (`step_ctx`/`driver2`).

The two collectors are NOT behaviorally identical: `collect_saves`
traverses **Ecase branches, Eunseq arms, Elet bodies, and Epar**
(into a closed accumulator), where :622 returns `fmapEmpty`. So
Labels(f) as the paper defines it UNDERCOUNTS the engine's labels
(a save inside an expr-level Ecase branch resolves in the engine but
is outside the paper's Labels(f)) and the FR-6c caveat is mis-scoped:
for collect_saves the invisible positions are exactly **Ebound and
End** (both "typing forbids" positions per the source comments, so
the caveat may in fact be vacuous for well-typed Core — worth saying).

What SURVIVES: the two load-bearing semantic claims — the
Esseq/Ewseq wrapping (cont_ℓ = save body wrapped through the
enclosing sequence, so the continuation runs to the procedure's end)
and Ebound-invisibility — hold for BOTH functions; I verified the
wrapping in collect_saves_aux directly. No rule in the figure becomes
unsound. But the paper's "engine-verified" label on this anchor is
false of the artifact cited, and the wellformedness perimeter is
wrong. Cross-check note (§7): the fresh review PRESCRIBED this exact
citation and claimed to have "verified [it] at the right function";
v3 transcribed it. This is the transcribed-without-verification
failure mode recurring for the third time on the same paragraph
(v1: find_labeled_continuation; v2-review: collect_labeled_
continuations; actual: collect_saves), and it recurred because PR-3
sweeps raise sites, not engine WIRING. Amendment: PR-3 (or a PR-4)
must include a wiring check — for every "engine of record" citation,
the call chain from driver2 to the cited symbol.

### V3-2 (MAJOR-adjacent — a false lemma statement in v3-new material). The space-credit amount does not exclude the OOM kill at the boundary.

Model (verified): `allocateObject`/`allocateRegion` compute
`alignedAddr = alignDown(lastAddress − size, align)` and kill
(`NDkilled (Other (MerrOther "out of memory"))`) iff
`alignedAddr == 0` (:1476-1478, :1504-1506). Per-allocation headroom
consumption = `lastAddress − alignedAddr ≤ size + align − 1` — the
paper's slack bound is the correct CONSUMPTION bound. But the credit
must also be a SUFFICIENCY certificate: `alignedAddr ≠ 0` requires
`alignedAddr ≥ align` (it is a multiple of align), i.e.
`lastAddress ≥ size + align`. Holding `space(sz+al−1)` under
⟦space(n)⟧ = "n ≤ lastAddress" permits `lastAddress = sz+al−1`
exactly — where the model kills DESPITE the credit (align=1 witness:
lastAddress = sz ⟹ alignDown(0,1) = 0 ⟹ kill). The draft conflates
the credit's two roles (upper-bound-on-consumption: sz+al−1 suffices;
success-guarantee: needs sz+al).

**The one-line fix**: ⟦space(n)⟧ := `n ≤ lastAddress − 1` (address 0
reserved as the sentinel — which is truthfully what the model does).
Then `space(sz+al−1)` is exactly right on BOTH roles: sufficiency
(`lastAddress − 1 ≥ sz+al−1 ⟺ lastAddress ≥ sz+al` ✓) and
preservation (headroom decrease = lastAddress_old − lastAddress_new ≤
sz+al−1 ✓, so Σ outstanding credits ≤ headroom is invariant). The
2^48-scale ADQ funding means no corpus corollary would ever have hit
the boundary — which is exactly why the lemma statement must be
pinned now, not discovered by a failing mechanization later. Neither
prior reviewer could have caught this: the credit amount and the
realization reading are v3-original design (FR-3 prescribed the
mechanism, not the arithmetic).

Otherwise the credit design checks out against the model: kills do
NOT touch lastAddress (killM verified — linearity is a real model
fact, not an assumption); nothing in the figure mints space; the
frame rule cannot create it; A5's free(NULL) no-op consumes nothing;
M16 realloc consumes fresh credit and returns none (correct — the
model never reclaims); allocation ids are never reused (nextAllocId
monotone, deadAllocations only grows — dead(ι)'s persistence is
licensed exactly as claimed).

### V3-3 (MAJOR-adjacent — internal inconsistency introduced by the v3 sweep). A6-locking's post cannot update a persistent alloc.

A.0: "`alloc(ι, a, n, ro)` (persistent)". B.3 A6 (v3-new sweep
finding, correct about the model — storeM :1652-1659 transitions the
allocation to IsReadOnly with the kind selected from the allocation's
prefix, mirroring impl_mem.ml:1776-1787): "the A6-locking variant's
post updates `alloc(…, ro)`". These cannot both stand: a persistent
assertion once owned is owned forever, so after a locking store the
proof context retains `alloc(ι,a,n,rw)` while the model's state says
read-only — the realization relation cannot be defined. The sweep
finding was transcribed into the row without propagating to the
assertion-language declaration. Fix in §0.1(3). (In-fragment
reachability is narrow — locking stores serve string-literal/const
initialization, and A2 covers creation-time readonly — but the figure
as printed is self-inconsistent, which is a mechanization-blocker.)

### V3-4 (AMEND). The sweep is blind to the panic class on the very rows it declared total.

P9/M12: "total; pure pointer arithmetic; the UB046 premise was
PHANTOM". The phantom deletion is right (MerrArrayShift has no raise
site — verified by grep). But `arrayShiftPtrval` (CerbMem.lean:
1130-1135) **panics on PVnull and PVfunction operands**, and
`memberShiftPtrval` (:1160-1164) panics on PVfunction. B.5/ADQ put
engine fail-stops in the excluded class ("engine-incomplete
branches"), and the paper itself lists memcmp's uninit PANIC as a
premise-generating outcome (M15) — the same discipline demands
non-null/non-function operand premises here. Root cause is method:
the sweep grepped Merr-constructor raise sites; panics in pure
helpers are invisible to it. PR-3's mandate must say "Merr raise
site, panic!, failwithI, or fuel sentinel — or PHANTOM-delete".
(Also worth a line: memberShiftPtrval on NULL with nonzero offset
returns a CONCRETE pointer at addr = offset — the offsetof idiom —
no panic; the row's "total address arithmetic" is true only of that
arm.)

### V3-5 (AMEND). Citation precision inside a sweep that claims completeness.

The v3-changed rows' SEMANTIC content is right everywhere I checked
(§2). But several inline citations land on comment lines or wrong
arms — the string-grep tell:

- A7 "live (DeadPtr :1555)": line 1555 is a COMMENT; the raise is
  :1620. "in-bounds (OutOfBoundPtr :1613, Prov_none :1553)": :1613
  is the Prov_device arm, :1553 a comment; real sites :1627 (bounds)
  and :1609 (Prov_none). "atomic-member guard (:1695)": :1695 is the
  STORE's guard; the load's is :1628-1629. (A7's trap cite :1604 is
  byte-exact — the row is a mix of exact and grep-hit citations.)
- A6 "in-bounds … :1675": the device arm; the bounds raise is :1688.
  A6 omits its atomic-member premise entirely (raise :1692-1695,
  LoadAccess-tagged upstream copy-paste, mirrored).
- A5's premise labels are transposed: Free_out_of_bound (:1537) IS
  the designates-allocation-start check (addr ≠ alloc.base); :1539
  is the was-dynamically-allocated check.
- M3-M6 ":1767" is a comment line; the MerrWIP raises are
  :1776/:1777/:1784/:1791/:1798.
- A6 and A7 carry no liveness premise and no MerrOutsideLifetime
  mention: the model catches access-after-kill via
  `allocations.get? → none → MerrOutsideLifetime` (:1624, :1685) —
  real UB (UB009 in the table). Presumably absorbed by the standard
  SL argument (holding `a ↦` implies the allocation is present —
  A4/A5 consume the points-to). That is the right design; the rows
  must SAY it, because it is a realization-invariant obligation
  (↦ ⟹ allocation live), not a free fact.

A sweep that will be re-run mechanically (PR-3) must verify the cited
line RAISES the named error, not merely mentions it. None of these
changes rule content; all of them corrode the "every premise now
carries its raise-site citation" claim, which is the paper's §H
headline.

### V3-6 (AMEND). wpE^N is the one v3-new device with neither lineage nor semantics.

E10/E12's proviso face — "`wpE^N e ⟨K⟩`: e's wp with its
negative-polarity action rules drawing their resource premises from
the bundle N" — passes the steering test in one respect (polarity is
Core SYNTAX, `Pos/Neg0` in the AST, not engine state) and fails the
paper's own standards in two: (i) as phrased it is a statement about
DERIVATIONS (which rules a proof used), not an iProp — the semantic
version (a wp variant whose Neg-action rule reads its resources from
a designated, threaded bundle) is definable and must be the stated
one; (ii) no lineage is named, and the anti-innovation ruling makes
lineage a review criterion — the honest nearest is CSL's resource
bundles / conditional critical regions (O'Hearn), with the ∗-split
conclusion shape the review prescribed. The derivation is at least
priced (cross-cutting obligations) — this is a definitional
completion, not a redesign.

### V3-7 (minor). Trap-representation premise over-broad.

The model's trap check fires only on `_Bool` loads (:1599-1604; and
the UB table maps only the LoadAccess arm to UB012 — the Store arm
falls to the none-catchall and is never raised). A blanket no-trap
premise on A7 is sound but buys incompleteness for nothing; scope it
to Bool0-typed loads.

### V3-8 (minor/foresight). The credit-bookkeeping "automation must make it free" claim is corpus-shaped.

Verified credible for the corpus: prologue creates have literal
elaborated sizes, the arithmetic is omega-class, ADQ funds 2^48.
Unpriced anywhere: loops that allocate per iteration (libxml2's
buffer-growth idiom — the named graduation target) put SYMBOLIC
credit terms (∝ trip count) into loop invariants and make budget
arithmetic part of invariant inference. Not a corpus blocker; it
belongs as a named sentence in hardest-item 3 so it is discovered in
the ledger, not at the libxml2 rung. Related honesty check that
PASSES: p24's failure arm returning the credit is exactly right for
the choice-driven wrapper (no allocation ⟹ no consumption), and the
"{emp} is not writable" closure of DN-5 is correct by inspection
(:1478 is a real kill on a bounded allocator).

---

## 2. Spot-audit of the claimed raise-site sweep (≥10 rows, model read directly)

| Row (v3 claim) | Verdict against CerbMem/Mem_common |
|---|---|
| A1/A3 OOM kill :1478/:1506; no alignment raise; deterministic monotone allocator | **EXACT** — kills verified at both lines; allocator only computes alignDown (no misalignment error); addresses monotone; killM never restores lastAddress |
| A4/A5 kill arms :1528-1545; free(NULL) unconditional no-op; forbid_nullptr_free dead | **CORRECT** semantically; premise labels transposed (V3-5); switch enum verified dead (CerbGlobal.lean:25, zero consumers); MerrFreeNullPtr never raised |
| A5 Free_out_of_bound → none (killed-not-UB) | **EXACT** — verified in undefinedFromMem_error (Mem_common.lean:392) |
| A6 writable :1690, ill-typed store :1667 non-UB kill checked before pointer match, locking :1650-1660 | **EXACT** on all three; but bounds cite is the device arm (V3-5), atomic premise missing, liveness implicit |
| A7 trap :1604 REAL (UB012); uninit/UB011 PHANTOM | **EXACT** — trap raise verified; MerrReadUninit has NO raise site anywhere in generated/ (grep); uninitialized loads yield MVunspecified silently. Trap is _Bool-only (V3-7) |
| M1/M2 demonic fork :1731 | **EXACT** — eqPtrval msum {provenance-false, addr-eq} at differing provenance (:1753-1755); same-provenance deterministic; MerrPtrComparison never raised |
| M3-M6 non-strict, cross-allocation defined, UB053 phantom, MerrWIP kills | **CORRECT** — addresses compared regardless of provenance (:1774-1797); MerrWIP arms are the only failures; UB053 unreachable; cite :1767 is a comment (V3-5) |
| M8 :1922 / FR-6b combineProv :227-240 | **EXACT** both |
| M10 liveness+alignment, NO bounds; :1886 concreteness kill | **EXACT** — validForDerefPtrval has no isInBounds call |
| M11 void/function MerrOther kills :1851-1858 | **EXACT** |
| M12/M13 unchecked | Phantom-deletion **CORRECT**; totality claim WRONG per the panic sites (V3-4) |
| M14 checked per-byte loop :1945, overlap-UB dropped | **EXACT** (loop :1948-1957; upstream TODO inherited) |
| M15 uninit panic | **EXACT** (:1991, loud panic) |
| M16 :2020/:2022 realloc arms | **EXACT** |
| M21 identity :2172 | **EXACT** (`memReturn pv`, integer discarded) |
| B.5 killed-not-UB class | **VERIFIED**: MerrOther/MerrWIP/ill-typed-store/Free_out_of_bound all land on `none` in the UB map; MerrOutsideLifetime is UB009 (real UB — see V3-5's liveness note) |
| Inventory cites (Core.lean :177/:267/:524/:552/:733/:1032/:1249; Mem_common:570; step_ctx :484; driver2 :384; Ecase-PEconstrained failwithI) | **ALL EXACT** |

Summary: the sweep's semantic content survives a hostile re-audit
essentially intact — a genuinely strong result — but its citation
layer is partly grep-artifact (comment lines, wrong arms) and its
method missed the panic class and the engine-wiring class. "Complete"
is the wrong word for it; "row-correct with a repairable citation
layer and two named blind spots" is the honest grade.

## 3. Soundness attacks

### 3.1 The E14/K.run fix (FR-1) — attacked and HELD

Engine facts verified first: fall-through into `Esave` evaluates the
default pexprs and TAU-steps into the BODY in place with params bound
(Core_reduction one_step0, Esave arm); `Erun` replaces the arena with
the collected continuation (body wrapped through the enclosing
sequence). At the save's position these coincide — the physical
context around the Esave equals the collection-time wrap — so
"fall-through ≡ jump with default args", which is exactly what E14
now asserts. Attack attempts:

- **Nested loops** (the review's counterexample re-run): inner save
  inside outer continuation at index w now demands ∃w′<w at every
  fall-through entry; the trailing run-outer inside the inner
  continuation demands <w′<w — each outer cycle strictly descends;
  `while(1){int i=0; while(i<0)i++;}` is unprovable. Fix effective.
- **Mutual saves** (A↔B jump cycles): each edge demands strict
  decrease; infinite descent kills divergence; bounded mutual passes
  provable with a joint measure. Correct on both sides.
- **Fall-through-then-jump self-loop** (`…; save A: skip` with
  `run A` in the tail): each pass through cont_A demands a strictly
  smaller index; `A: goto A` unprovable. Correct.
- **Completeness (does anything terminating become unprovable?)**:
  sequential loops (W1 then W2 in W1's continuation tail) and
  loop-after-loop-in-continuation shapes discharge with rank/
  lexicographic components ((outer, phase, inner) lex — I worked the
  index assignments; they close). Ret-label fall-through: verified
  from real dumps that ret defaults are `undef(UB088)` (c9_arrw.core
  :160) and main's is `Specified(0)` (:199) — E14 + UB-as-⊥ makes
  fall-off-the-end unprovable exactly when it should be, and main's
  benign. I could not construct a terminating program the three-line
  totality content rejects.
- **Any label entry bypassing Krun?** Enumerated the entry routes:
  Erun (Krun), Esave fall-through (Krun since v3), unresolvable label
  (engine failwithI — ADQ-excluded), save-under-Ebound/End
  (collection-invisible — the wellformedness caveat, rescoped per
  V3-1). No fourth route found.

The donor-conformance claim is verified at source: RefinedC
programs.v:72 `typed_block` judges every block against the Q gmap
(typed_block_rec :1200-1202 is the invariant-family recursion shape);
no privileged fall-through exists there. A.2's binding is now closed
(all three premise lines under ∀ a x̄; I checked every schema
variable). The spec-indexed `I_ℓ : A → W_f → list value → iProp`
states P04's `s = Σ_{k<i} xs[k]` and P08's IntList invariant without
strain.

### 3.2 The space-credit design — attacked; one boundary defect (V3-2), otherwise sound

Forgery/leak attempts: no rule mints space; ∗-splitting a credit RA
is standard; the frame cannot create it; ADQ funding is from the
realizing state's actual headroom; free/kill correctly return
NOTHING (the model reclaims nothing — verified); p24's failure arm
correctly returns the untouched credit; realloc correctly pays fresh.
Alignment slack: consumption ≤ sz+al−1 verified against alignDown
arithmetic (including allocateObject's `size.max 1` and
allocateRegion's unclamped size — malloc(0) consumes only slack,
covered). The single defect is the boundary sufficiency gap (V3-2).
Linearity is the right structure for THIS model and I verified its
premise in the code rather than trusting the paper.

### 3.3 The race-proviso sort

E9a's ∗ as the race obligation is clean and donor-standard; the
two-lemma metatheorem's lemma (a) in the per-location R/W-aware form
is the provable one (the model's `overlapping` is R/W-aware —
:1187-1191 verified, two reads never overlap; `do_race` fires on
DA_neg annotations at the join — verified present in
Core_reduction). E9b′'s demotion to derived is right (its premises
were E9a's with a weaker conclusion). The residual sort problem is
wpE^N (V3-6): borderline-acceptable, honestly priced, definitionally
incomplete.

### 3.4 ADQ's killed-not-UB exclusion vs the frozen rows

Checked against the frozen house shape ("outcome-SET form (all ND
resolutions; no UB)") and rows P01, P04, P13: ADQ's conclusion (every
execution terminates without UB, without non-UB kills, without
engine-incomplete branches; every outcome realizes Q) + machine
totality gives outcome-set EQUALITY with the spec singleton — it
strengthens, never weakens, the frozen meaning. P13's
design-dependent failure clause resolves cleanly: under
credit-funded concrete-model allocation the success-only outcome set
holds (F1 ◐ withdrawn), with the failable-wrapper route (p24)
available as the corpus-2 pattern — no conflict with the frozen H8
scoping. The space credits appear in CONTRACTS only, never in the
frozen statements — statement-TCB discipline preserved.

## 4. Expressiveness — the 15 frozen rows + p24 under v3's judgments

(✓ = writable in v3's judgments AND meaning preserved vs the frozen
spec; credit column = what the credit terms do to the row's contract.)

| Row | v3 machinery | Credit impact | Verdict |
|---|---|---|---|
| P01 clamp | wpPE case-split; call boundary | prologue create credits (literal) | ✓ |
| P02 sat_add | path conditions as pure facts; F15 short-circuit via Core shape | literal | ✓ |
| P03 swap may-alias | E9c-free arg lists; alias case-split at ∗ vs collapsed ↦ | literal | ✓ |
| P04 arr_sum | I_ℓ a w v̄ with a = (xs,n); A7 | literal | ✓ (FR-4 fix is what makes it writable) |
| P05 find_first | contents-dependent measure in W_f; early exit = run to exit label via Krun | literal | ✓ |
| P06 arr_reverse | two-index invariant; A6/A7 | literal | ✓ |
| P07 list_sum | rep predicate (derived layer) over quantified skeleton | literal | ✓ |
| P08 list_reverse | IntList ∗-surgery; the SL classic | literal | ✓ |
| P09 call_contract | E7/E8 consume □contract; frame | callee contract carries its own space(A_f) — the ubiquity cost, automation-owned | ✓ |
| P10 gcd_rec | contract-intro IH at measure μ | per-call create credits × recursion depth — bounded by μ, literal per frame | ✓ |
| P11 gcd_iter | variant in W_f (b decreases) | literal | ✓ |
| P12 pt_midpoint | struct typed views; frame-as-observable | literal | ✓ |
| P13 cell_alloc | A3 + A5 + dead(ι) tombstone as leak-conjunct carrier | space(sizeof(int)+slack) in pre, instantiation-funded; success-only outcomes | ✓ (resolves H8's ◐ cleanly) |
| P14 count_pairs | nested I_ℓ, lexicographic W_f | literal | ✓ (the exact FR-1 shape — exercise early per ledger #5, agreed) |
| P15 scan_classify | ∃-NUL witness invariant; switch = if-dispatch+save/run (no Ecase) | literal | ✓ |
| p24 h_malloc wrapper | choice-driven failure arm | `{space(n′)} … {(NULL ∗ space(n′)) ∨ (r↦… )}` — failure returns credit | ✓ (modulo V3-2's n′ arithmetic pin) |

All 16 writable; no row's meaning drifts. The credit terms are
uniform plumbing except P13/p24, where they are the content — and
there they say exactly what the model does.

## 5. Flex §G — the six axes attacked

- **G1 (partial sibling wpE^∂)**: verified consistent — the
  unconstrained E14 is sound for fuel-inductive safety; credits do
  NOT foreclose the sibling (they are safety-side: partial
  correctness still excludes kills, so space premises appear in both
  siblings unchanged). HOLDS.
- **G3 (PNVI switch, perimeter M1-M9+M21)**: verified against the
  model — the unported SW_strict branches sit exactly at the
  comparison rows (:1717-1719, :1764 region comments), M8/M9/M21's
  PNVI arms are the B.4F set; the re-scope to comparison-heavy
  programs is right. Credits are PNVI-neutral (allocation arithmetic
  identical in both modes). HOLDS.
- **cmm re-entry**: credits are ordinary linear resources —
  thread-splittable; no foreclosure. HOLDS.
- **Contracts-promotion**: credits IMPROVE promotion (budgets are
  explicit in the contract, no ambient headroom assumption). HOLDS.
- **The one unstated flex fact (offered, not a defect)**: the credit
  design hard-codes the model's never-reclaim behavior. If a future
  model reclaims addresses (the model-refinement ledger's
  address-reuse entry), existing credit contracts remain SOUND
  (headroom only grows relative to the invariant — conservative),
  and an Iron-style credit-return at kill is an ADDITIVE upgrade.
  Verified additive, so no verdict changes; §G could carry the line.
- **G5 (substitution exit ramp + shadowing)**: PR-2's shadowing
  concern verified REAL in the tree — `save while_531: unit
  (i: pointer:= i, s: pointer:= s)` (t5_sum.core:8) is exactly the
  param-snapshot-shadows-itself shape. The probe is correctly
  specified. HOLDS.

## 6. Will it work — ledger and probes

The seven-item hardest list is honest and correctly ordered; item 3's
promotion to "on every corpus row's critical path" is right (I
verified the every-prologue-creates claim in spirit via the loop-dump
by-pointer params). Two additions needed: the wpE^N semantic
definition should graduate from cross-cutting to the ledger if it
resists (V3-6), and the allocating-loop credit line (V3-8). The
probes: PR-1 (with rebind) and PR-2 (with shadowing) are the right
two cheap de-riskers for the correspondence family; PR-3 is the right
institution but needs the V3-4/V3-5 mandate extensions (panic class;
raise-not-mention verification) and a PR-4-style wiring check
(V3-1) — the one fidelity-claim class three successive reviews now
show PR-3 cannot reach. Grade tallies are labeled derived and the
per-row grades I audited are defensible (the sweep mostly simplified
rows, as claimed).

## 7. Cross-check against the sealed reviews (written last)

Read after §§0–6 were complete: `2026-08-30_core-logic-paper-review.md`
(v1 review), `2026-08-30_core-logic-v2-fresh-review.md` (fresh
review).

- **§H's v2→v3 dispositions are faithful.** FR-1's exact prescribed
  fix was executed (and independently re-verified sound here, §3.1);
  FR-2's sweep was executed and EXTENDED (A7-uninit/trap, A6-locking,
  A1-align — all three §H-sweep additions verified correct against
  the model here); FR-3's option (a) was chosen and elaborated;
  FR-4/FR-5/FR-7(a-g) all match their prescriptions against v3's
  text. No disposition misrepresents what was done.
- **The recurring failure mode fired again, in the one place PR-3
  cannot see.** The fresh review's §1 states it verified the label
  collection "at the right function" (collect_labeled_continuations
  :622, "called at Driver.lean:436") and FR-6a prescribed moving the
  cite there; §9 even singles out MAJOR-1 as "independently
  re-verified by me at the correct engine function." Driver.lean:436
  calls `collect_labeled_continuations_NEW` → `collect_saves`; the
  :622 function's only live consumer is the legacy Core_run engine.
  v3 transcribed the prescription verbatim, adding the
  "engine-verified" label (V3-1). Three documents, three different
  functions, none of them checked by following the driver's call
  chain. The semantic claims survive by luck of structural similarity
  — but this is precisely the class §9 named ("wrong prescriptions
  faithfully transcribed"), now with the fresh review as the source.
- **Findings here that are genuinely new** (neither prior document
  contains them, and neither could have): V3-2 (the credit
  off-by-one — the arithmetic is v3-original), V3-3 (the
  locking/persistence collision — both halves are v3-new), V3-4
  (the panic blind spot — the fresh review's FR-2 asserted
  arrayShiftPtrval "checks anything"—it checks pointer shape and
  panics), V3-5's specifics, V3-6's lineage gap (the fresh review
  prescribed the ∗-split; the wpE^N face is v3's own elaboration).
- **No regression found**: nothing either prior review verified as
  correct was un-fixed or silently weakened in v3. The v1 review's
  citation-check table and the fresh review's model-facts section
  otherwise held up under my re-derivation (memop 22, expr 19,
  pexpr 29, the Eunseq annotation pipeline, the Ecase-substitution
  wrinkle, main's Specified(0) ret default).

## 8. Sharpest judgment

Is this now the right foundation? **Yes.** The things that had to be
true are now true and I verified them at the model, not at the
paper's word: the judgment economy is small and donor-shaped; the
totality content is three auditable lines and survives adversarial
counterexample construction; the rules track the implemented
semantics row-by-row including its unlovely corners (killed-not-UB,
the ND comparison fork, the locking store, the dead switch); the one
genuinely novel mechanism (space credits) is the classical answer to
a real model fact (a bounded, never-reclaiming allocator) rather than
an invention; and the corpus — the document that defines success —
fits the judgments without strain, credits included. The remaining
defects are all of one size: statements that must be pinned exactly
right before mechanization (an anchor, an inequality, a persistence
split, four premises, one definition). What should worry the
ratification conversation is not the figure but the PROCESS
signature: three consecutive reviews each planted a confident wrong
engine-anchor in the same paragraph, and each survived because
"verified" meant reading the cited function rather than walking the
driver's call chain. PR-3 institutionalized raise-site checking;
institutionalize wiring-checking the same way (V3-1), and this
document is done evolving and ready to be built.
