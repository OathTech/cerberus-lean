# Professor whole-project assessment — the proof layer vs the BRiCk/RefinedC aim

Date: 2026-08-27. Author: [AGENT] professor-grade assessor (read-only pass;
NO builds run; single write target = this file). Worktree assessed:
`/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-coherence`
(branch arc/segment-ladder @ e59825cc0, plus an uncommitted delta from a
killed worker — dispositioned in §6). Donor baselines read at
`deps/refinedc`, `deps/BRiCk`, `deps/brick-wp`.

MANDATE (operator, verbatim, binding): "Our aim here is to BUILD A
VERIFICATION FRAMEWORK SIMILAR TO BRICK OR REFINEDC. That's the aim. We are
NOT executing code at specific inputs. We are NOT doing enumeration. These
are COMPLETELY FORBIDDEN as proof strategies. Examples should be
quantified / 'all input' properties. This isn't necessarily the final form
of proof we will support. But it's the MINIMUM kind of specification we
care about." And: "From this perspective, we are NOT INTERESTED AT ALL IN
CONCRETE EXECUTION AT SPECIFIC VALUES. If we wanted that, we would just run
the interpreter. Who cares? … We are doing FORMAL VERIFICATION here,
that's the point."

Method note: every load-bearing claim below carries a file:line citation I
or a scoped read-only survey verified against source. Tallies marked
(derived) are my arithmetic over cited counts. Prior evidence consumed:
the proof-style professor pass (notes/2026-08-27_proof-style-professor-
pass.md — its circularity finding is confirmed below against source) and
the reasoning-layer design pass (notes/2026-08-26_reasoning-layer-design-
pass.md).

---

## 0. Executive summary and the sharpest judgment

**The sharpest judgment.** The project has built a genuinely sound,
kernel-certified, Iris-carried **concrete-trace evaluator** and dressed it
in program-logic vocabulary. Measured against the BRiCk/RefinedC standard,
the statement layer is ~20% real (T1–T5 are genuine ∀-input theorems) and
~80% the forbidden pattern (every R6 corpus theorem, T6, T7, and the whole
planned spec-lab "exec-equation campaign" are single-input executions
proved in the kernel). The deeper problem is architectural, not
statistical: the proof substrate **cannot cross a data-dependent branch at
a symbolic value** — there is no case-split rule, no assertion language
over program variables, and the one ghost resource that carries the
machine (`restIs` at a *concrete* `driver_state`,
relsem/RelSem/CerbHeapWalk.lean:219-236) pins the entire control/env state
to a literal. Consequently the quantified theorems that do exist quantify
only over data the execution never branches on (T1–T4) or ride ~3,300
hand-built lines for one loop (T5). `e1_clamp.c` is the emblem: a
4-line function whose natural spec is `∀x, clamp0(x) = max(x,0)`, proved
only at `x = -3` (Corpus/E1.lean:414-417) because the branch on `x` cannot
be taken symbolically. The good news: the trust discipline (trio-exact
cones, fail-closed gates, proof-producing emission) is better than either
donor's, the Iris coupling (GenHeap byte points-to, adequacy) is real, and
the fuel-algebra composition core is sound and small. The framework is
missing its middle: per-construct rules at symbolic operands, an assertion
layer, and a symbolic executor. That is exactly what BRiCk/RefinedC *are*.

**Deliverable headlines.**
- **Kill list (§3):** 26 concrete-input theorems (22 corpus + T6 pair +
  T7 pair), 4 parked concrete reproducer modules, the 16-theorem ambient
  slate + its ~7,900-line chase-era proof machinery, ~5,000 lines of
  per-fixture spine/supply serving concrete runs, 23 unproved spec-lab
  sample/concrete statement defs, and the planned exec-equation campaign
  (the "current binding constraint" of PROOF.md:206-221 is precisely the
  forbidden strategy — cancel it, do not park it).
- **Conversion (§4):** the Seg fuel-algebra, FnSpec, the heap RA, the
  four memory-op WP rules, the memory block laws, the registry, and the
  proof-producing mint chassis convert on named canonical lineage.
  Everything whose only defense is "it made the corpus numbers go up"
  dies.
- **Build plan (§5):** six slices — judgment contract; assertion layer
  (decompose `restIs`); per-construct symbolic rules incl. the branch
  rule; the automation; calls; loops+acceptance — with the concrete-input
  **ban gate** landed first, fail-closed.

---

## 1. The standard being judged against (donor baseline, from source)

What "function verified against a spec" means in the donors:

**RefinedC** (deps/refinedc): the artifact is one Iris entailment
`⊢ typed_function impl_f (type_of_f …)` where `typed_function`
(theories/typing/function.v:59-65) is
`∀ x : A` (ghost parameters) `, □ ∀ (lsa : vec loc …) (lsv : vec loc …),
(args typed ∗ locals uninit ∗ pre) -∗ typed_stmt (Goto f_init) …` —
**arguments enter universally as locations constrained by types**; values
are never enumerated. Statements are verified by a judgment
`typed_stmt … (Q : gmap label stmt)` (typing/programs.v:66-70), loop
invariants are a **load-bearing** `gmap label (iProp Σ)` fed to
`split_blocks` (typing/automation.v:347-378), and the whole thing is
discharged by Lithium instance search. Adequacy yields `not_stuck`
(typing/adequacy.v:40-49).

**BRiCk** (deps/BRiCk): the artifact is `|-- func_ok tu f spec`
(logic/func.v:452-456) = `□ ∀ Q vals, fs_spec vals Q -* wp_func tu f vals
Q`, over an axiomatized per-AST-node WP (`wp_operand`, `wp_lval`,
`wp_init` — logic/wp.v:631-907; one axiom per statement form in
logic/stmt.v) with continuation-indexed postconditions (`Kpred`,
wp.v:124-141) and `wp_while_inv I` (stmt.v:480-489) via Löb. Specs are
`\with …\pre …\post` accumulators (specs/wp_spec_compat.v:50-77) whose
argument binders range over **all** values satisfying the pre.

**brick-wp** (deps/brick-wp): no logic of its own — a 3.5k-line
lemma/Ltac layer over BRiCk (`wp_open_func`, `wp_auto`,
`wp_fptr_of_spec` — theories/WpTactics.v:1353-1391, 2241-2255) proving
`func_ok` artifacts for real examples (persistent-bst Find/Insert with a
plain-`mpred` loop invariant, examples/persistent-bst/coq/Find.v:143-233).

**The yardstick, condensed:** (1) statements universally quantify
arguments/ghost state, with values constrained only by types and pure
pres; (2) the proof walks the **program syntax** by once-proved (or
axiomatized) per-construct rules at **symbolic operands**, branches
producing subgoals; (3) invariants are assertions (predicates), declared
at loop heads/labels, and the declaration is load-bearing; (4) framing is
the ambient mechanism, over *all* state the footprint does not mention —
including locals; (5) per-function marginal cost is a spec + invariants +
an automation run.

---

## 2. The six adjudications

### 2.1 The differential test infrastructure — testing or masquerade?

**Verdict: legitimate model-validation TESTING, on a separate ledger,
and mostly honestly labeled — with two masquerade findings.**

The oracle-differential lanes (test_exec, test_core, cn_coverage, csmith,
libxml2_uri, immaculate, the speclab shell lanes) compare two
implementations' executions; none is presented as proof. test_verify.sh
runs executions only (scripts/test_verify.sh:112-167): fixture
differentials vs the oracle plus "harness point" rows from
tests/verify/expectations.txt checked with **no oracle** against recorded
spec strings — a test of the harness, labeled as such
(test_verify.sh:15-16). The speclab gate exes carry an explicit
"EPISTEMIC LABEL: this is a TEST (untrusted-evaluator)"
(speclab/test/SLUnit/CoreGateTest.lean:20). This discipline is *good* and
survives the purge untouched: differential testing of the semantics is
how a model gets validated, and it is not a proof strategy.

**Masquerade finding 1 — the planned promotion of tests to theorems.**
PROOF.md:206-221 names the "exec-equation campaign — the unconditional
kernel proofs that the compiled harnesses *execute* to their verdicts
(which would upgrade sample-∀ to family-∀ …) — is the current binding
constraint." That campaign IS the forbidden strategy: kernel-proving
concrete executions at pinned inputs (4-point sample sets,
speclab/SpecLab/DivModFiles.lean:162-178). Under the mandate it is not
parked, it is CANCELLED, and PROOF.md's "binding constraint" framing must
be rewritten (§3, K-7).

**Masquerade finding 2 — theorem-adjacent test rows.** The
tests/verify/expectations.txt rows are duplicated inside Lean as
`slatePoints` "on the ASSEMBLED THEOREM OBJECTS"
(relsem/test/Unit/EmitLeanCoreTest.lean:73-74): concrete execution points
run through `CerbND.runND` against the exact terms the theorems quantify.
As a drift *test* this is fine and stays; but its per-killed-fixture rows
exist only to serve killed theorems and go with them.

### 2.2 T4/T5 — the real thing or costume?

**Verdict: the statements are the real thing; the layer they ride is
partially costume, and the prior professor pass's circularity finding is
CONFIRMED against source.**

Statements, verified in source: T5Threaded is
`T5EnvHypThr → ∀ seed, T5SeedApart seed → ∀ n, 0 ≤ n ≤ 100 →
outcomes(sum(n)) = {Specified(n·(n−1)/2)}, no UB` at a **symbolic trip
count** through `Seg.while_inv` (relsem/RelSem/T5.lean:89-102); the loop
induction lives in the once-proved rule; `triF` with `triF_closed` is a
genuine invariant (T5Inv.lean:61-83). T4Threaded is ∀-x with the honest
seed-apartness guard whose necessity is kernel-witnessed by the collision
falsifier (T4Threaded.lean:61-70, 146-151). T1/T2/T3 are ∀-x/∀-xy
(T1Threaded.lean:818-822, T2Threaded.lean:645-651). These meet the
mandate's minimum-spec bar.

The qualifications, all verified: (1) **the quantified theorems never
cross a data-dependent branch at the symbolic value** — id, add,
roundtrip, memb are branch-free in the argument; sum's branch is the loop
guard, absorbed into the invariant family at the cost of ~3,300
per-fixture engine-room lines (T5Walks 439 + T5Inv 983 + T5Spine 738 +
T5Seam 183 + hand spine in T5.lean; derived) plus T4Walks' 800 for T4.
(2) The corpus-tier "invariants" are circular: `at_ k := compOf
(walk-endpoint k)` — "the assertion at visit k is: being the state the
run reaches at visit k" (confirmed at T7.lean:78-90,
Corpus/C3B.lean:660-664; the professor pass's exact finding,
notes/2026-08-27_proof-style-professor-pass.md:437-455). (3) The
invariant map is decorative: `InvMap.while_inv` takes its lookup as
`_hfind` and never uses it (Segment.lean:300-304) — RefinedC's
`Q !! b` is load-bearing (typing/automation.v:118-121); ours is costume.
(4) The donor-correspondence table's only "MIRRORED" structural row
(docs/2026-08-26_arc18-r2-donor-correspondence.md:18, `SegInv`/`InvMap`
vs `typed_block`) is precisely the row the dead `_hfind` and the circular
`at_` falsify. T5 alone proves the costume can become the garment.

### 2.3 The minting engine (RoundEval) — principled symbolic execution?

**Verdict: concrete-execution machinery with an open heap frame — the
degenerate straight-line fragment of symbolic execution. The chassis
converts; the whole-run mode dies.**

What it is: `derive_rounds` walks the interpreter's rounds at an anchor
state whose **heap maps are free binders** (with pointwise footprint
hypotheses and a `fencing` list — Corpus/E1.lean:339-348) but whose
control state, environment, and **data are concrete**; each round is
classified by `whnf` on the actual redex (RoundEval/Rounds.lean:374-506)
and emitted as a kernel-checked equation (the fail-closed emitters,
RoundEval/Mint.lean:129-259). Where the discriminant does not reduce, the
mint STOPS — the parked C9 wall ("pure-eval runstate over the
PEarray_shift payload does not reduce", commit dafd50451), the R6
finding that the engine "mints at concrete file anchors only; the layer
does not reach symbolic-file families"
(docs/2026-08-27_arc18-r6-breadth-campaign.md:200-210). There is no
case-split: grep confirms no PEif/PEcase *rule* exists anywhere in the law
tables (ConstructLaws.lean has 8 harness-protocol laws only; Kit/Eval.lean's
PEif occurrences are redex-position classification, not branching).

Against the canon: RefinedC/Lithium also computes per-program — but over
**symbolic values with typed side conditions**, branches spawning
subgoals. A symbolic executor that can only proceed when every branch
condition evaluates is an interpreter with a frame. The per-round
`∀ fuel` relative chains at 26–204 rounds per trivial program
(E1.lean:340-348; E5's 204) are enumeration of execution steps in
mechanism costume — prong 1 of the trick filter.

What is genuinely principled and survives (named lineage): the
proof-producing, fail-closed emission discipline (ACL2Lean donor contract
— mvar/fvar/sorry checks, kernel recheck at addDecl,
RoundEval/Mint.lean:129-241); the anchor/named-constant discipline (the
S0 giant-terms rule); `kernelVerdict` ground-fact leaves
(Lanes.lean:645-652); and the goal-form registry dispatch
(LawRegistry.lean:1-52). These are exactly the chassis a real symbolic
executor needs.

### 2.4 The segment layer — does it meet the structural standard?

**Verdict: no, not yet — it is a sound trace-composition algebra, not a
program logic. Three of five yardstick criteria fail.**

What is right: `Seg C B s s' := ∃ k ≤ B, ∀ fuel, C (fuel+k) s = C fuel s'`
with `trans`/`iter`/`while_inv`/`Summary.consume` proved once by pure Nat
induction (Segment.lean:77-184, 488-495) — genuine Floyd/Hoare/Dijkstra
lineage, correctly cited, total-correctness budgets a real improvement
over the donors' partial WP. `FnSpec` (Segment.lean:394-409) has the
right RefinedC `A → fn_params` shape including the argument family.

What fails the standard: (1) **pre/posts are concrete `driver_state`s,
not assertions** — the header admits it: "No new assertion DSL"
(Segment.lean:44-47). A triple whose endpoints are states is a transition,
and the prior pass's overclaim finding stands ("the segment judgment is a
triple at the equation calculus" — it is an equation). (2) No branch
rule: `SegPoint` has entry/label/call/terminal (Segment.lean:210-218) —
no join for an `if`; branches exist only where a concrete run resolved
them, or as "multi-exit" compositions at concrete data (X7/X2). (3) No
frame at the judgment level over locals/env — framing exists only for
the two heap maps via open binders; everything else rides `restIs` at a
concrete state (CerbHeapWalk.lean:219-236), so a segment proved in one
calling context is unusable in any other (all addresses are literals:
`xAddr := 281474976710648`, E1.lean:49). (4) The call rule has **zero
worked instances** — parked at the `are_compatible` partial-def wall
(breadth record §4.2). (5) The invariant map is dead (§2.2). The
composition algebra is a KEEP; the layer around it must be rebuilt.

### 2.5 Spec-lab — which parts serve quantified families?

**Verdict: split cleanly.** KEEP (genuinely quantified statement
machinery): the codec library with 16 kernel-checked RoundTrip/Canonical
laws (SpecLab/Codec.lean:51-435), the per-rung pure models and their ~85
lemmas, the five `model_forall_iff_stream_forall` bridges — genuinely ∀
over an abstract predicate (SpecLab/DivMod.lean:292-295) — and the
`fileOfStream_encode` program-term equalities (∀-model). KEEP as *test*
infrastructure: `mkHarness` (four-way string concatenation, no runtime
magic — MkHarness.lean:68-71) and the differential/fuzz/plant shell
lanes. KILL as theorem targets: the 23 unproved `*SampleStatement` /
`*StreamStatement` / `*PlantHealthyClaim` Prop defs — 4-point pinned
sample sets (DivModFiles.lean:162-195 et al.) are enumeration by
construction — and the exec-equation campaign that would prove them
(§2.1). The choice-stream doctrine itself (variation as compiled
constants) is a statement-layer decision the operator ratified for
harness *form*; it is not the problem. The problem is proving executions
of the resulting concrete programs in the kernel instead of quantifying
inputs through a verifier. Family-∀ (quantifying the stream through the
program *term*) should be re-based on the verifier (spec parameterizes
the harness's argument/initial memory, not the file term); the R6 record
already concedes the engine cannot reach symbolic-file families.

### 2.6 The statement-gate taxonomy — the mechanical ban

The existing statement-TCB gate (Audit.lean:563-779) enforces
*vocabulary* (fuel-opsem-only), is fail-closed and negative-tested — a
good mechanism, wrong axis for this mandate: nothing stops a slate
statement from being `∀ seed, run(f, [42]) = v`. The needed gate (build
plan B0/B6, priced there):

1. **Quantified-input obligation.** For every registered slate statement,
   walk the type (the existing transitive walker): after stripping
   `∀ seed` and guard hypotheses, the statement must bind at least one
   universally quantified variable that flows into the harness argument
   list or the initial-memory description. Mechanically: reject any
   `CallHarnessAdequateThr`/`…UBFreeThr` application whose `args`
   expression is closed (no bound fvar) — E1's `[intValue (-3)]` fails,
   T5's `[intValue n]` passes.
2. **FnSpec shape check.** Registered `FnSpec`s with `args := fun _ => …`
   (constant families) are rejected unless carrying an explicit
   per-instance operator-waiver marker (the governed escape hatch,
   mirroring the statement-SL escape-hatch doctrine).
3. **Finite-sample ban.** Reject statements quantifying by membership in
   a closed literal list (`∀ m ∈ sampleSet, …` — the speclab shape),
   same waiver mechanism.
4. **Negative tests in-build** (the wrapper-hole pattern the gate already
   uses): a permanent concrete-args probe the checker must reject.
5. The gate lands FIRST (before the purge) with grandfather waivers that
   are deleted in the purge commit — so drift is build-fatal from day
   one and the waiver list is the visible debt register.

---

## 3. Deliverable 1 — THE KILL LIST

Everything below is either (a) a theorem stated at concrete inputs, or
(b) infrastructure whose purpose is to serve that pattern. Verdict KILL
means: delete now; nothing may rebuild it. Where a C fixture file or a
test row has independent *testing* value it stays on the test ledger —
the kill is of theorems and theorem-serving proof text.

### 3.1 Concrete-input THEOREMS (statements at literal arguments)

| # | Item | Statement (cited) | Lines | Takes down |
|---|------|-------------------|-------|-----------|
| K-1a | `T6Threaded`, `T6Threaded_ubFree` — pick(10) | T6Probe.lean:604-617 | 640 | Audit slate rows, cone pins, one-route row |
| K-1b | `T7Threaded`, `T7Threaded_ubFree` — flip(7) | T7.lean:227-233 | 249 + 758 (T7Walks) | slate rows, pins, one-route rows, proof-size registration |
| K-1c | Corpus batch 1: `E1…E5Threaded` (+twins) — clamp0(-3), abs3(-5), scale(7), is_digit(53), is_mark(42) | Corpus/E1.lean:414-432 …E5.lean:411-414 | 2,184 (derived) | slate +10, stmtAllowed +10, pins +10, one-route +5, lakefile roots |
| K-1d | Corpus batch 2: `C4/C5/C3A/C3BThreaded` (+twins) — hex_val(102), pct_hi(65), acc10(21474836,5), lead_digit(273) | C4.lean:404-407 …C3B.lean:793-798 | 2,152 (derived) | slate +8, stmtAllowed +13, pins (incl. c3b_run_seg), one-route +4 |
| K-1e | Corpus batch 3: `X7/X2Threaded` (+twins) — is_pow2(6), cap10(273) | X7.lean:668-673, X2.lean:667-672 | 1,375 | slate +4, stmtAllowed +10, pins +6, one-route +2 |
| K-1f | Parked concrete reproducers: `Corpus/X3.lean` (call at concrete args), `Corpus/Z1.lean` (20-deep chain), committed `Corpus/C9.lean` | X3.lean:1-12 (park header), Z1.lean:1-8 | 153 + 378 + 243 | not in build (X3/Z1) / lakefile root (C9); EmitLeanCoreTest slate points for x3/z1/z2/c9 |

Subtotal: **26 registered theorems** (22 corpus + 2 T6 + 2 T7; derived
from the Audit slate at Audit.lean:706-752) plus 3 parked modules;
~7,900 lines (derived). The **statements' C fixtures stay** in
tests/verify as differential-test inputs and as future ∀-input acceptance
targets (clamp0 ∀x is build-plan acceptance B5).

Killing these is a *reduction in nothing*: each is subsumed by one run of
the existing interpreter (`test_verify.sh` already executes every one of
these points). The operator's line applies verbatim: if we wanted
clamp0(-3), we would run the interpreter.

### 3.2 Concrete-serving PROOF INFRASTRUCTURE

| # | Item | What it is | Verdict |
|---|------|-----------|---------|
| K-2a | Per-fixture harness-spine supply: the `@[seg_eq]`/`@[seg_fact]`/`@[seg_canon]`/`@[seg_post]` **entries** for killed fixtures (~12/fixture, "pure boilerplate, ~95% template-identical", breadth record §2.2; census: segEq 162, segFact 62, segCanon 18, segPost — Audit census 327) | Registered equations at literal addresses/bytes (`xAddr = 281474976710648`, E1.lean:49) whose only consumer is `seg_auto` proving the killed theorems | KILL entries; attribute mechanism survives (§4 C-6) |
| K-2b | The whole-run concrete-anchor mint mode: `derive_rounds … from (mkRdy …) upto N chain builder` producing 26–204-round whole-program terminal chains per fixture (E1.lean:339-348 and every corpus/T file) | The enumeration engine: per-round kernel equations of one concrete execution | KILL the mode; chassis converts (§4 C-5) |
| K-2c | Per-fixture walk modules serving killed theorems: T7Walks.lean (758) | Minted/hand chains at flip(7)'s trajectory | KILL |
| K-2d | The circular-invariant pattern: `JoinSpellings` twin tables + `at_ k := compOf (endpoint k)` in all concrete fixtures (T7.lean:63-90, C3B.lean:647-664, X7.lean:547-563) | Strongest-postcondition trajectory declared as "THE INVARIANT" | KILL with the fixtures; the *rebuilt* invariant layer must make the declaration load-bearing (B5) |
| K-2e | Gate registrations that exist to serve the pattern: Audit slate rows for K-1 theorems (Audit.lean:706-752), stmtAllowed fixture-data rows (Audit.lean:626-646), per-theorem cone pins (+25 at R6), the 12,404 sweep-count pin (Audit.lean:1695-1698), check_one_route LIVE_MODULES corpus rows (check_one_route.sh:42-98), EmitLeanCoreTest `slatePoints` rows for killed fixtures (EmitLeanCoreTest.lean:75-167) | Fail-closed lists — deleting fixtures without re-registering is build-fatal BY DESIGN | Re-register in the same purge commit (this is churn, not risk; the gate survey enumerates every touch point) |
| K-2f | `.arc17-probe-scratch/` (container) and `.r6-scratch/` (untracked, this worktree): probe logs, old C9 drafts | Dead scratch | DELETE |

### 3.3 The ambient/legacy families (already-adjudicated purge, accelerated)

Ambient T1–T4 statements are ∀-x (T1.lean:59-62) — not concrete-input —
but they are superseded duplicates of the threaded family, carry the
`runEffectful` boundary residual (104 registered carriers,
Audit.lean:1347-1439), and their proofs ride the frozen chase machinery.
The C5 "extended purge" already owns them; this mandate folds that purge
into the kill commit: `T1/T2/T3/T4.lean` (475), `T1AppEq–T4AppEq`
(5,132), `T4Defs.lean` (640), `Tactics/AppWalk.lean` (2,435),
`Tactics/WalkTrace.lean` (371), `SlateWP.lean` (85), `PerStepOwnP.lean`
(428), the arc-7 Iris shell (`IrisState/IrisLang/IrisRules/IrisAdequacy`,
435, superseded by the per-step + heap route; one-route already bans
their import — check_one_route.sh:100), `T1Core/T1File` where their only
consumer was the ambient slate. ~10,000 lines (derived). Takes down: the
runEffectful carrier register (goes to zero — a *win*: the boundary
residual exits every cone), ambient slate rows, `T1_of_threaded`-style
bridges, chase-freeze allowlist entries (a disappeared allowlisted file
is explicitly fine, check_chase_freeze.sh:28-29).

### 3.4 Spec-lab kill items

| # | Item | Verdict |
|---|------|---------|
| K-4a | The 23 sample/concrete statement Prop defs (`*SampleStatement`, `*StreamStatement`, `*PlantHealthyClaim`, `*LeakStatement` at pinned 4-point sets) — DivModFiles.lean:162-195, ByteArrFiles.lean:155-184, ListAppendFiles.lean:199-283, TreeRotFiles.lean:245-333, CnSeedFiles.lean:158-188 | KILL the defs and their SpecLabAudit registrations; they exist solely as targets for the cancelled exec-equation campaign. The `sample_of_family` / `sample_model_iff_stream` bridge theorems die with them. |
| K-4b | **The exec-equation campaign itself** (PROOF.md:206-221 "the current binding constraint") | CANCEL — the plan, not just the artifacts. PROOF.md rewritten: the binding constraint is the verifier (§5), not kernel-proved concrete executions. |
| K-4c | The five generated `*Core.lean` program terms (12.55 MB) | KEEP only those consumed by surviving test lanes/family-∀-via-verifier work; any whose sole consumer was a killed statement def go. (Skeptical default: revisit at purge; they are generated, cheap to regenerate.) |

KEEP explicitly (not kill-list, for the record): Codec.lean and all model
lemmas, the `model_forall_iff_stream_forall` bridges, `mkHarness` + the
differential/fuzz/plant lanes (test ledger), SpecLabAudit's gate
*mechanisms*.

### 3.5 Documentation corrections required by the kill

- PROOF.md §3's corpus paragraph never states that the eleven corpus
  theorems' arguments are fixed literals (docs survey §8: the fact is
  recoverable only from fixture names and the FnSpec texts; PROOF.md:182
  says only "Statements are ∀-seed"). Whatever survives the purge,
  PROOF.md must state quantification per theorem explicitly — this is a
  docs-truth finding independent of the kill.
- The R6 record's headline ("Eleven programs proved … at the cost floor
  — 2 manual steps per theorem") stands as history but must be marked
  superseded: the 2 manual steps bought concrete-input theorems, and the
  ~400-line per-fixture supply modules were the real price.

---

## 4. Deliverable 2 — CONVERSION (skeptical; default was kill)

Each survivor names its canonical lineage, the conversion, and the price.
Anything not listed here and not explicitly kept in §3 dies.

| # | Item | Why principled (lineage) | Conversion | Price |
|---|------|--------------------------|-----------|-------|
| C-1 | `Seg`/`SegDone` + `trans`/`iter`/`while_inv` + `Summary`/`Summary.consume` (Segment.lean:77-184, 480-495) | Floyd cut-points; Hoare sequence/while/procedure rules; Dijkstra/Gries budgets. Pure Nat algebra, proved once, fixture-free | KEEP as the **internal transition algebra** beneath a new assertion-level triple (B1). It is not itself the user judgment — pre/posts-as-states is the flaw, not the algebra | S (exists) |
| C-2 | `FnSpec` + `Verified`/`WpOb`/`dischargeThr` (Segment.lean:394-461) | RefinedC `A → fn_params` (function.v:29-51); the argument family `A` is already the right shape | KEEP; make `A`-families the ONLY registrable form (constant `args` gated, §2.6); extend pre to assertion-level (initial-memory description) alongside pure pre | S |
| C-3 | CerbHeapRA: GenHeap byte points-to + ghost_map alloc table + MemInv (CerbHeapRA.lean:1-190) | HeapLang gen_heap; Caesium heapG shape (the S2 study) | KEEP unchanged. The third component, `restIs` (ghost_var at the whole non-heap machine state), is the **conversion centerpiece**: decompose into (a) a control/program-point token, (b) per-variable env points-to (a second ghost_map over the scope env), (c) supplies as ghost counters — so assertions abstract locals and control the way donors do | L — the load-bearing refactor (B1) |
| C-4 | CerbHeapWP op rules + `wpk_seq_res_det` skeleton (CerbHeapWP.lean:1-60); the footprint-shaped walk-rule FORMS (wpk_seq_rest/read1/argobj/…, CerbHeapWalk.lean) | HeapLang PrimitiveLaws factoring; the framing dividend is real and measured | KEEP the four op rules; CONVERT the walk rules from "lift one per-fixture whole-atom equation" to per-Core-construct rules at symbolic operands (B2). The `∀ bm am` open-map equation form survives as the rules' semantic feed — but proved once per construct, not minted per fixture | M–L |
| C-5 | RoundEval chassis: fail-closed emitters (Mint.lean:129-259), law-chain elaboration + registry dispatch (Rounds.lean), `kernelVerdict` ground leaves, hyp-threading, anchor discipline | ACL2Lean proof-producing checker contract; reflection-at-leaves; S0 named-state rule | CONVERT into the symbolic executor's engine: same emission, but stepping per Core construct with **case-split on irreducible discriminants** (two emitted subgoal branches with path-condition hypotheses) instead of stopping. The whole-run concrete-anchor mode is deleted (K-2b) | L (B2+B3) |
| C-6 | LawRegistry + the `@[seg_*]`/`@[step_law]` attribute machinery (LawRegistry.lean, SegmentFaces.lean:50-110) | RefinedC hint-mode/DiscrTree dispatch; unique-rule-per-goal-form | KEEP; entries repopulated with per-construct laws instead of per-fixture supply | 0 |
| C-7 | Kit/Mem block laws (`mem_load_block`, `mem_store_block`, `readBytesFrom_writeBytesTo_{hit,frame,within}`) | Caesium `heap_mapsto_app`/ghost_state lemmas; RefinedC array element points-to (the uncommitted `within` law cites array.v:9-16 correctly) | KEEP — this is the genuine memory-model lemma layer; grow it (array/struct views) | S per addition |
| C-8 | `verify_fn` + `seg_auto` faces (SegmentFaces.lean) | Lithium / brick-wp `wp_auto` packaging | KEEP the face names and the registry-driven, fail-closed-frontier design; re-target at the B2 rules. The current supply-consumption body is replaced | M (inside B3) |
| C-9 | The adequacy spine: PerStep language instance, `kCallHarnessAdequateThrHeap_of_wp` (CerbHeapWalk.lean:2109), threaded faces (relsemcore/Threaded.lean:107-130) | Iris language-instance + heap_adequacy precedent | KEEP — this is the real Iris coupling and the boring-statement discharge path; unchanged by the purge | 0 |
| C-10 | T5's statement + `triF`/`triF_closed`; T1–T4 threaded statements | The mandate's minimum-spec form, already achieved | KEEP statements byte-stable; proofs re-derived through B1–B5 (deleting T5's 3,300-line engine room and T4Walks' 800 once the new route re-proves them — do NOT delete before) | (inside B5) |
| C-11 | Seed-apartness guards (`T4SeedApart` et al.) + digest pins | Honest (falsifier-witnessed) but a statement-surface wart — 2^60 numerals in headline hypotheses | KEEP short-term; the chartered freshness redesign (modeled supply / ND+filter, CLAUDE.md model-level end state) is the remover. Any new statement machinery must stay supply-passable | M (already chartered, separate) |
| C-12 | Statement-TCB gate + axiom-cone pins + one-route + chase-freeze mechanisms | Fail-closed trust hygiene, better than donor practice | KEEP; EXTEND with the §2.6 concrete-input ban | S |
| C-13 | Speclab codecs/models/bridges; mkHarness + shell lanes | Quantified statement machinery / test ledger | KEEP as-is | 0 |
| C-14 | Kit/Loop `iter_compose*` | Subsumed by `Seg.iter` (same content, weaker form) | DELETE after re-pointing T5's route (leave-one-route rule) | S |
| C-15 | The breadth-campaign *measurement record* (walls, root causes: are_compatible partial def, depth/width cliffs, the every-assignment-draws-a-symbol finding) | Real reconnaissance | KEEP as documentation; these are B2's work orders | 0 |

Explicitly NOT converted (sunk-cost defense only, dies): the per-fixture
spine template ("~95% template-identical" — automating its generation, as
the R6 record proposed, would industrialize the wrong thing); the
`JoinSpellings` twin-spelling normalizer as user-facing vocabulary (an
elaboration artifact that belongs inside the engine if it survives at
all); `T6Probe`'s three retained historical routes; the sample-∀
statement pattern.

---

## 5. Deliverable 3 — the build plan for the real thing

### 5.1 What exists vs the yardstick (merits, not claims)

| Yardstick component | Donor | Here, today | Gap |
|---|---|---|---|
| Universally-quantified fn specs | `typed_function` ∀-ghost ∀-arg-locations | `FnSpec A` exists, right shape; used with `A = Unit`/constants in 26 of 31 slate theorems | Gate + usage, not machinery |
| Per-construct rules, symbolic operands | wp axioms per AST node (BRiCk); Typed* instances (RefinedC) | NONE for Core constructs; 8 harness-protocol laws + 4 mem-op WP rules; everything else minted per fixture at concrete data | **The central gap** |
| Branch rule / case-split | trivial (wp_if; typed_if) | ABSENT — engine stops at irreducible discriminants | **The central gap's sharpest edge** |
| Assertion language over locals | `l ◁ₗ ty`, `p ↦ v` incl. args/locals | Heap bytes/allocs only; locals+control pinned concretely via `restIs` | B1 |
| Loop invariants, load-bearing | gmap label iProp → split_blocks; wp_while_inv I | `Seg.while_inv` sound; map dead; invariants = state trajectories except T5 | B5 |
| Calls | type_call_fnptr / wp_fptr + func_ok | Rule form only; zero instances; blocked on a kernel-opaque partial def | B4 |
| Framing | ambient, all unmentioned state | heap maps only | B1/B2 |
| Adequacy to an unquestionable statement | not_stuck (RefinedC); none (BRiCk) | **Better than donors**: fuel-opsem outcome statements, trio-exact cones, zero axioms in repo | keep |
| Automation | Lithium; wp_auto | seg_auto over per-fixture supply | B3 re-target |
| Trust discipline | Rocq kernel + solver trust (Lithium orchestration) | kernel-only, gate-enforced, negative-tested | keep — genuinely ahead |

### 5.2 The slices (ordered; prices in house S/M/L)

**B0 — The contract + the ban gate (S).** Write the target judgment
contract from the design pass's §2.2 `SegTriple` sketch, upgraded per
§2.4: assertions = program-point token ∗ env points-to ∗ heap footprint ∗
pure facts; `FnSpec` argument telescopes; invariants as predicates.
Acceptance examples fixed now: `∀x, clamp0(x)` (branch), `∀n, sum(n)`
(loop, re-proof), `∀x, memb(x)` (memory), two-function call. Land the
§2.6 concrete-input ban gate with grandfather waivers. Nothing else
starts until the operator ratifies the contract (the design pass is a
discussion doc by its own header — this stays true).

**B1 — The assertion layer (L).** Decompose `restIs`: control token
(program-point = Core label/continuation position), env ghost_map
(`x ↦env v` with symbolic `v`), supplies as ghost counters. Rebuild the
four op rules and adequacy over the decomposed interpretation. This is
the refactor that makes locals frameable and values symbolic. Risk
ceiling: if the interpretation split stalls, the exit ramp is env-as-one-
ghost-var with symbolic value maps (halfway house, still unblocks B2).

**B2 — Per-construct symbolic rules (L, the heart).** For the elaborated
Core vocabulary (measured small: spec-lab vocabulary saturation; R6's
zero-new-engine-laws-for-scalars): pure-expr rules (PEop/PElet/PEctor…),
**PEif/PEcase case-split rules** (two subgoals under path-condition
hypotheses — the missing rule), memory ops through C-4, `save`/`run`
join rules, seq/wseq. Each proved ONCE at ∀-operands with pure side
conditions; the fixture-independent "equation-supply frontier" arc-17
kept deferring, now the main line. Known walls with owners: totalize
`AilTypesAux.are_compatible` (M, priced in the R6 record — B4 blocker);
representation indexing for the write-tower/width cliffs (the
better-abstractions items — they will resurface here and must be solved
at the representation, never by budget).

**B3 — The automation (M–L).** Re-target `seg_auto`: goal-directed
application of B2 rules, branch-splitting, leaf discharge
(omega/decide/kernelVerdict), fail-closed frontiers, trace emission.
Lineage: Lithium's instance search / brick-wp's wp_auto; chassis = C-5.

**B4 — Calls (M).** are_compatible totalization (lem-side fuel or hand
mirror + regen), then the first worked `Summary.consume` instance at
symbolic args; callee FnSpecs consumed persistently (RefinedC
function_ptr precedent).

**B5 — Loops + acceptance (M).** Predicate invariants at labels with a
LOAD-BEARING map (fix `_hfind`); re-prove T5 through the new route;
prove the B0 acceptance slate — including the R6 corpus programs
**restated ∀-input** (clamp0 ∀x, abs3 ∀x, is_digit ∀c, is_pow2 ∀x,
cap10 ∀x, lead_digit ∀x…). The old corpus becomes the acceptance suite
it should have been. Marginal-cost target: spec + invariant + automation
run, ~0 manual lines straight-line (the design pass's §2.4 numbers, now
at quantified statements).

**B6 — The purge (M, churn).** Delete §3 in ONE commit: kill-list
modules, gate re-registrations (the gate survey enumerates every
touch point: Audit slate/stmtAllowed/pins/carriers/sweep-count,
one-route live list, lakefile roots, EmitLeanCoreTest rows,
chase-freeze allowlist), waiver deletions, PROOF.md rewrite (§3.5),
runEffectful carrier register to zero. Re-run the full battery; the
differential ledger is untouched and must stay green.

Ordering: B0 immediately (gate first); B1→B2 sequential; B3 overlaps B2's
tail; B4/B5 after B2; B6 can run any time after B0 (earlier = less to
maintain; the operator may prefer purge-first to stop the sunk-cost
gravity — I recommend purge right after B0, keeping only T1–T5 statements
+ their current proofs as regression anchors until B5 re-proves them).

### 5.3 What survives untouched through all of it

The semantics package and its OCaml-differential ledger; the Iris
adequacy spine; the heap RA; the trust gates; speclab's codec/model
layer; the statement doctrine's boring fuel-opsem faces. The
*statements* T1–T5.

---

## 6. Disposition of the uncommitted delta and scratch

Killed worker's delta (git status at e59825cc0):

- `RelSem/Kit/Mem.lean` (+46): `readBytesFrom_writeBytesTo_within` — a
  general sub-range read-over-write law with correct RefinedC lineage
  citations (array.v element points-to, caesium heap_mapsto_app).
  **KEEP/COMMIT** — this is C-7 class, exactly the kind of law B2 needs.
- `RelSem/RoundEval/Lanes.lean` (+56): the `within` mint arm +
  `listSpineSlice?`. **KEEP with C-5's fate** — engine-lane code; carried
  into the converted engine, deleted only if the mem lane itself is
  rebuilt differently.
- `RelSem/Corpus/C9.lean` (rewritten 413→243) + `RelSem/Corpus/C9T.lean`
  (new, 270, self-described merge-scratch): the array fixture UNPARKED
  and — notably — restated as a **∀-x guarded family**
  (`c9Range x`, `c9Spec x = x+1`, C9T.lean:20-27), the T4 recipe at
  array data. This is the one corpus item already pointed the right way.
  **Disposition: do not land as-is** (it rides the whole-run mint and the
  per-fixture spine, both scheduled for conversion), but **salvage the
  statement** (`arr_rw` ∀-x is a good B5 acceptance row for the array
  vocabulary) and the root-cause note in its header (assignment
  fresh-draws). C9T.lean's own header says it must not be committed.
- `lakefile.toml` (+C9 root): falls with the above.
- `.r6-scratch/` (untracked logs/probes): DELETE (K-2f).

Recommended handling: commit the Kit/Mem law + Lanes arm as a small
clean slice (they stand alone); park C9/C9T changes on a branch tip or
drop them (prune-don't-merge doctrine), recording the ∀-x statement shape
in the B5 acceptance list.

---

## 7. Summary tables

### 7.1 Kill-list summary

| Class | Items | Volume (derived) |
|---|---|---|
| Concrete-input theorems (registered) | 26 theorems: T6 pair, T7 pair, 22 corpus | ~7,900 lines incl. T7Walks |
| Parked concrete reproducers | X3, Z1, C9(committed), C9T | ~1,040 lines |
| Ambient/legacy chase-era slate + machinery | 16 ambient theorems + AppEq/AppWalk/OwnP/arc-7 shell | ~10,000 lines |
| Per-fixture seg supply entries | ~240 registry entries (segEq/segFact/segCanon/segPost for killed fixtures) | inside fixture files |
| Whole-run concrete-anchor mint mode | `derive_rounds … chain builder` usage sites | mode deletion in engine |
| Spec-lab sample/concrete statement defs | 23 Prop defs + bridge theorems + SpecLabAudit rows | ~300 lines + 12.55 MB generated terms (revisit) |
| The exec-equation campaign | PROOF.md:206-221 plan | CANCELLED, not parked |
| Gate re-registrations required | Audit slate/stmtAllowed/pins/carriers/sweep pin; one-route rows; lakefile roots; EmitLeanCoreTest rows | one purge commit |

### 7.2 Conversion table (§4 condensed)

| Item | Lineage | Fate | Price |
|---|---|---|---|
| Seg algebra + composition rules | Floyd/Hoare/Dijkstra | KEEP (internal algebra) | S |
| FnSpec | RefinedC fn_params | KEEP + telescope + gate | S |
| Heap RA (GenHeap/ghost_map) | HeapLang/Caesium | KEEP | 0 |
| `restIs` whole-rest pin | — (the design flaw) | CONVERT: decompose into control token + env points-to + supplies | L |
| Mem-op WP rules + walk-rule forms | HeapLang PrimitiveLaws | KEEP ops; CONVERT walks to per-construct | M–L |
| RoundEval chassis | ACL2Lean proof-producing | CONVERT to symbolic stepper w/ case-split; kill whole-run mode | L |
| LawRegistry + attributes | RefinedC hint dispatch | KEEP | 0 |
| Kit/Mem block laws (+ delta's `within`) | Caesium ghost_state | KEEP, grow | S |
| verify_fn/seg_auto faces | Lithium/wp_auto | KEEP faces, re-target | M |
| Adequacy spine + threaded faces | Iris adequacy | KEEP | 0 |
| T1–T5 statements | the mandate's minimum spec | KEEP byte-stable; re-prove | in B5 |
| Seed guards | falsifier-honest | KEEP until freshness redesign | M (chartered) |
| Statement gate | house | KEEP + concrete-input ban | S |
| Speclab codecs/models/lanes | — | KEEP (statements/tests) | 0 |
| iter_compose | subsumed | DELETE after re-point | S |

### 7.3 Build plan

| Slice | Content | Price |
|---|---|---|
| B0 | Judgment contract + acceptance slate + concrete-input ban gate (first) | S |
| B1 | Assertion layer: decompose restIs; env points-to; symbolic values | L |
| B2 | Per-construct symbolic rules incl. PEif/PEcase case-split; are_compatible totalization feeds B4 | L |
| B3 | Automation: goal-directed rule application + branch split + leaf discharge | M–L |
| B4 | Call rule worked at symbolic args | M |
| B5 | Predicate invariants, load-bearing map; T5 re-proof; corpus restated ∀-input as acceptance | M |
| B6 | The purge, one commit, full re-registration + PROOF.md rewrite | M |

### 7.4 Top risks in executing this

1. **Symbolic reduction through the generated interpreter.** B2's rules
   must hold at ∀-operands over a deep, fuel-indexed, machine-generated
   functional program. Kernel-opaque `partial def`s (are_compatible is
   the known one; the census may find more) and the measured giant-term
   cliffs (depth/width, the write-tower normalization) will resurface as
   rule-proving obstacles. Mitigation: each is a named totalization or
   representation-indexing slice, never a budget bump — and the R6
   reconnaissance already priced the known ones.
2. **Address abstraction vs C's address observability.** Literal
   addresses must become block/offset points-to, but PNVI-visible
   addresses (the pnvi sweep's measured stdout diffs) mean naive
   abstraction is semantically wrong for some programs. The chartered SL
   alloc design-evaluation gate (Caesium as reference) governs this;
   B1 must route through it.
3. **Freshness capture poisons quantified statements.** The T4 falsifier
   is real; until the modeled-supply/ND-filter redesign lands, every
   fresh-drawing program's spec carries 2^60 guards. Acceptable
   short-term wart; becomes intolerable at scale — sequence the
   chartered freshness work before the breadth re-campaign grows.
4. **Purge churn against fail-closed gates.** Dozens of pinned lists and
   counts move together; a partial purge is build-fatal by design. Do it
   as one commit with the re-baseline ledger, exactly as the R6 batches
   did in the growth direction.
5. **Sunk-cost gravity.** 21,000+ per-fixture lines and a green 133-point
   test_verify create pressure to "generalize the template" instead of
   deleting it. The R6 record already proposed automating spine
   generation — that is industrializing the wrong artifact. The ban gate
   (B0) is the structural defense.
6. **B2 is open-ended in principle.** Bounded in practice by the measured
   vocabulary saturation (flat ~12 supply entries/fixture; zero new
   engine laws for scalar programs by batch 1) — but the first symbolic
   branch and the first symbolic loop over the real interpreter are
   unproven territory. The acceptance slate (clamp0 ∀x before anything
   else) forces the hard part first.

---

## Appendix: source inventory consulted

relsem: Segment.lean, SegmentFaces.lean, LawRegistry.lean,
ConstructLaws.lean, RoundEval/{Core,Mint,Rounds,Lanes,Hyp,Arith,
Assembly}.lean, Kit/{Mem,Loop,Eval,Round,Map,Env,AppEq,Audit}.lean,
CerbHeap{RA,WP,Walk,Demo}.lean, PerStep*.lean, T1–T7 files (all),
T5{Walks,Inv,Seam,Spine}.lean, T4{Defs,Walks,Threaded}.lean,
T6Probe.lean, Corpus/* (all 15), Audit.lean, SlateCore/SlateFiles/
SlateWP.lean, Tactics/*, lakefile.toml, test/Unit/EmitLeanCoreTest.lean.
relsemcore: Threaded.lean, Call.lean. speclab: full package (survey).
scripts: all check_*/test_* gates (survey), LADDER.md. Docs: PROOF.md,
arc-18 charter + R1–R6 records, donor-correspondence, the two container
notes. Donors: refinedc typing/{programs,function,adequacy,automation}.v,
caesium/lifting.v; BRiCk logic/{wp,stmt,expr,func,cptr}.v,
specs/{wp_spec_compat,classy,elaborate,functions}.v; brick-wp full
(survey). Uncommitted delta: git diff + C9T.lean + .r6-scratch listing.
