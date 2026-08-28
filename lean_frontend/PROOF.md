# PROOF — verification capabilities and trust story

This document states what can be proved about C programs with
cerberus-lean, what has actually been proved so far, and exactly what
you must trust. Precision matters here: claims below distinguish
**kernel theorems** (checked by the Lean kernel), **differential
evidence** (both implementations agree on executions), and **in-flight
work** (pointers to current records, no numbers that rot).

## 1. The trust story

A theorem about a C program here is an ordinary Lean theorem whose
statement mentions only the **fuel-based operational semantics** (the
executable model itself) and the program. To believe such a theorem
you must trust:

1. **The Lean kernel** (and, for the semantics' meaning, the model —
   which is executable and differentially validated, see DESIGN.md §5).
2. **The axiom story — the achieved end state (arc-17 S2b).** This
   repository declares **zero axioms**. The gates enforce it: the
   hand-written axiom census and the generated-tree census
   (`scripts/check_theorem_axioms.sh`) both assert an **empty**
   allowlist, fail-closed.

   *What happened to the old boundary axioms.* Two hand-written
   axioms used to exist and are **deleted** (arc-17 S2b, executing
   the operator's temporal-mover ruling):
   - `CerbTags.with_tagDefs` (`CerbTags.lean`) — tag-definition
     state installation — and
   - `CerberusFresh.forceIO` (`CerberusFresh.lean`) — the IO-position
     evaluation barrier for fresh symbol/digest reads —

   are now `opaque` constants with **kernel-checked inhabitation
   witnesses** (`fun _ f => f ()` and `fun f => pure (f ())` — their
   effect-erased meanings). Nothing is postulated: the kernel checks
   the witnesses; the constants stay irreducible to every proof
   (opaque), so no proof can exploit them; and the compiled behavior
   is unchanged (`@[implemented_by]` still binds the native C
   extents — re-verified by the differential lanes and the unit
   tests that found the original effect-erasure bugs). Because
   opaques are not axioms, these constants **can never appear in any
   axiom cone**. An in-build **boundary-opaque gate**
   (`relsem/RelSem/Audit.lean`) makes the conversion irreversible by
   default: either name existing as an axiom, being a transparent
   def, or being allowlisted fails the build (plant-tested both
   directions).

   *The one residual axiom, outside this repo.*
   `LemLib.runEffectful` (in `lem-lean/lean-lib/LemLib.lean`, a
   dependency) — the arcs-1+2 effect-erasure barrier for `BaseIO`
   externs, consumed by the generated ambient/compiled driver paths.
   It is **temporal, not permanent**: since the 2026-08-27 kill-list
   execution its consumers are compiled driver code ONLY — the
   ambient theorem family that carried it is **deleted**, and the
   **no-cone-entry gate** (`relsem/RelSem/Audit.lean`) now pins the
   carrier set at **zero**: `runEffectful` is outside every theorem
   cone in this repository, and any theorem cone acquiring it is
   build-fatal. Every theorem in the repository — the law library,
   the Iris layer, the consistency metatheorems (the V0 state: the
   flagship slate itself is honest-UNPROVED, see §3) — has a cone of
   **exactly the classical trio**
   `[propext, Classical.choice, Quot.sound]` (or a subset),
   per-theorem `#guard_msgs`-pinned. The axiom's deletion proper is
   lem-side surgery, registered for a lem arc. All assertions are
   in-build and plant-tested (transcripts in
   `docs/2026-08-25_arc17-s2b-axiom-endgame.md`; the zeroing:
   `docs/2026-08-27_kill-list-execution.md`).

   *Where the runtime trust actually lives:* the `@[implemented_by]`
   / `@[extern]` boundary (native counters, the tag table, MD5) —
   compiled-side implementation state, out of every cone by
   construction, mirrored against the OCaml originals and pinned by
   the differential gates. That boundary is permanent (native C
   externs are a declared immovable object); the AXIOMS are gone.
3. **Nothing evaluator-shaped.** Non-kernel proof methods are banned
   outright and gate-enforced: no `native_decide`, no `bv_decide`,
   nothing whose proof carries `Lean.ofReduceBool`/`ofReduceNat`.
   `#guard`-style checks are used as *tests* and never described as
   kernel-checked. Elaborator budget increases (`maxHeartbeats` etc.)
   are treated as defects; the proof machinery is required to keep
   every obligation an ordinary shallow kernel check instead.

Statements are additionally protected by a **statement-TCB gate**: a
theorem *statement* may use only executable, first-order vocabulary
(the semantics, program syntax, computable functions, inductive data).
Iris/relational vocabulary in a statement fails the build. Proofs, by
contrast, may use anything (§4).

## 2. The statement style: harnesses are programs

Specifications are **runnable C programs**. To specify a function
`f`, we generate a *harness*: a closed C program that builds `f`'s
input in memory, calls it, converts the result back into observables
(exit code, output), and returns a verdict. All variation enters as a
**compiled constant byte array** (the "choice stream"): a pure Lean
function `mkHarness : Stream → CProgram` splices the array into a
fixed template, so quantifying over streams quantifies over a family
of concrete programs — each one runnable, fuzzable, and differentially
testable against the OCaml oracle. There is no symbolic input, no
conjured memory state, and no runtime randomness anywhere.

The statement shape (full ratified design:
`docs/2026-08-22_harness-statement-template.md`; worked
example: `docs/2026-08-23_arc15-s4-r4-tree-worked-example.md`):

- a **pure model** of the data structure (a first-order inductive
  type) with computable `encode`/`decode` to the byte stream, related
  by kernel round-trip and canonicity lemmas;
- a **model-∀ headline**: for all model values, every enumerated
  outcome of running the harness is the expected verdict — e.g. for
  the tree-rotation example, `∀ m` in the quantified set,
  `HarnessRunsTo (rotateFileOf m) 0`, where verdict `0` means the
  post-state tree read back byte-for-byte equals the pure
  `rotateAt tree path`;
- **readback via observables**: the statement never mentions memory —
  the program serializes the post-state and compares against a
  compiled-in expected array, returning `0` or `1 + i` (the first
  divergence index); a leak conjunct asserts the final allocation
  count as a scalar observable;
- **plant tests, mandatory**: every spec family ships deliberately
  broken targets that must go red at the predicted index in both
  implementations, plus kernel "refutation schema" lemmas that turn a
  measured bad verdict into a formal refutation of the healthy claim.
  Vacuous specs are structurally loud.

Separation-logic vocabulary in *statements* is a governed escape
hatch: it requires a written-up, priced, per-instance operator
decision, and the statement-TCB gate makes drift build-fatal.

## 3. What is proved today — exactly

THE OPERATOR MANDATE (2026-08-27, binding): theorems here are
**quantified, ∀-input statements**. Concrete execution at specific
values is not a proof deliverable — "if we wanted that, we would just
run the interpreter." The 2026-08-27 kill-list execution
(`docs/2026-08-27_kill-list-execution.md`) deleted every registered
concrete-input theorem (the former T6/T7 pairs and the 22-theorem R6
corpus slate) together with the superseded ambient family; there is
deliberately NO concrete-theorem inventory to report.

**THE STATEMENT SLATE IS HONEST-UNPROVED (V0, 2026-08-27 — record
`docs/2026-08-27_v0-statements-and-ban.md`).** The repository holds
ZERO proved flagship theorems — ratified and intentional: the former
T1–T5 threaded proofs rode the whole-run walk/mint machinery
(assessment class K-2b — per-round kernel equations of concrete
executions wearing quantified statements), and the operator-ratified
V0 kill basket deleted the machinery AND the proofs together. What
stands is the REGISTERED TARGET SLATE, every row honest-unproved and
statement-gate-registered (fuel-opsem-only + the concrete-input ban;
31 rows):

- **T1–T5** (`tests/verify/t1..t5`): the five KEEP anchors, restated
  at V0 in the CONSISTENCY-FRESHNESS house shape — quantification
  over consistent executions (non-capturing draw windows against the
  pinned prior vocabulary; `relsemcore/RelSem/Threaded.lean`
  §CONSISTENCY) replaces the ∀-seed + SeedApart-guard shape. Headline
  + UB-freedom statement defs per fixture
  (`relsem/RelSem/T?Threaded.lean`, `T5.lean`).
- **The frozen target corpus, 14 of 15 rows**
  (`docs/2026-08-27_target-corpus.md`; `relsem/RelSem/Corpus*.lean`):
  P01/P02/P03/P09/P10/P11/P12 at the call-boundary face (headline +
  UB-freedom each), P04/P05/P06/P07/P08/P14/P15 at the whole-program
  family face (`∀ m, wf m → HarnessRunsToCns prior (fileOf m) 0` —
  the parametric splice families). P13 (cell_alloc) is an OPEN
  OPERATOR FINDING (malloc linkage at the statement layer; V0 record
  §findings). ZERO of these are provable today — the corpus defines
  the V1–V5 build.

PROVED and standing (kernel theorems, cones pinned): the
consistency layer's ANTI-VACUITY METATHEOREM
(`freshDrawsOf_nodup` — monotone ⇒ distinct;
`consistentRun_of_supply_le` — below-the-vocabulary ⇒ consistent;
exactly the classical trio); the V1 DECOMPOSED assertion layer
(`CerbStateRA`/`CerbStateWP`/`CerbStateAdequacy`: per-cell env
ownership at symbolic values, control token, supply and
memory-residual cells, the four memory-op rules at residual
granularity, adequacy bridges to BOTH the Thr and Cns statement
faces) with its framing anchors (`two_alloc_frame`, and the
end-to-end symbolic-env exhibit `demo_wp`/`demo_adequate` — a real
Core fragment where one local's symbolic assertion survives a
different local's rebind by the frame rule, discharged through
adequacy; record `docs/2026-08-28_v1-assertion-layer.md`); the
segment algebra (`Seg.iter`/`while_inv`/`Summary.consume`), the
runNDFuel soundness layer, and the spec-lab model/codec lemma
stock. The V0 no-instance gap is closed at the DEMO grade by
`demo_adequate` (an end-to-end adequacy instance over a real
fragment); the harness-program instances return with V2's rules.

**Kernel-checked statement layers for real C functions** (the spec
lab: division/modulo, `memcpy`, array access, linked-list append,
tree rotation, and two CN-suite functions): the pure models and
their ~85 lemmas, the 16 codec round-trip/canonicity laws, the
`model_forall_iff_stream_forall` bridges (genuinely ∀ over the model
domain), the `fileOfStream_encode` program-term equalities, and the
family-∀ TARGET statements (∀-seed, full model domain — registered
targets, honestly labeled UNPROVED). The former finite sample-∀ /
concrete statement defs and their planned proof are **deleted and
cancelled** respectively (see below).

**Differential evidence at scale** (evidence, not theorems): every
harness instance and every corpus lane agrees between the Lean
pipeline and the OCaml oracle — including ~2,000 executions across
the spec-lab families and a 2,186-file sweep of the upstream CI
corpora with zero semantic mismatches. See
`docs/2026-08-22_ci-sweep-results.md` and the `*-results.md`
records. Differential testing validates the MODEL; it is not, and is
never presented as, a proof strategy.

**CANCELLED (not parked): the exec-equation campaign.** The former
plan to kernel-prove that compiled harnesses *execute* to their
verdicts at pinned concrete inputs — described in earlier versions
of this section as "the current binding constraint" — was exactly
the forbidden proof strategy under the operator mandate and is
CANCELLED, not deferred (disposition:
`docs/2026-08-27_whole-project-assessment-disposition.md` §1). The
binding constraint is the VERIFIER — per-construct symbolic rules,
the assertion layer, the case-splitting executor (the assessment's
B0–B6 build plan). Family-∀ spec-lab endpoints re-base on that
verifier. Do not read any claim in this file as covering these.

### Where the C is, and what ties a theorem to it

Every verified program's C source is committed next to its pins: the
foundational fixtures under `../tests/verify/` (e.g.
`t4_struct_member.c`), the spec-lab harness instances under
`../tests/speclab/` (e.g. `rotate_a.c`, a closed runnable program).
The theorems' formal subject, however, is the **elaborated (Core)
form** of the program — a pinned Lean term — and the chain from the
`.c` file to that term has three links with different status:

1. **Theorem term ↔ pinned Core dump**: byte-checked in-build (the
   drift gates re-parse the committed `.core` dump and compare
   against the term the theorem actually mentions).
2. **Pinned dump ↔ the C file**: mechanically re-derived, not proved
   — the verification lanes re-run the oracle's elaboration
   (`--pp=core`) on the `.c` and demand byte-identity with the pin.
   So *which program* is precise and reproducible; that the Core term
   is the *meaning* of the C rests on trusting the elaboration
   pipeline.
3. **The elaboration pipeline itself**: cross-checked, with a caveat
   worth stating plainly. Both elaborators (OCaml and Lean) are
   generated from the *same Lem model*, so their agreement rules out
   implementation/backend bugs but not model-level elaboration bugs.
   The independent evidence against those is the differential corpus
   record — our execution verdicts match what compiled C actually
   does on thousands of gcc-torture/csmith programs — plus upstream
   Cerberus's own validation history. The C *parser* (text → AST)
   stays a thin OCaml front end and is a permanent, declared trust
   boundary.

A registered design option would shrink link 2/3: since desugaring
and elaboration are total generated Lean, a statement can in
principle start from the pinned parsed AST and include elaboration
inside the kernel-checked claim, leaving only the parse outside (see
TODO.md).

## 4. The proof machinery (aggressive, but outside the TCB)

"Boring executable specs in the front, Iris party in the back": proof
*construction* is unrestricted, so long as every step lands as an
ordinary kernel-checked declaration. The route a landed theorem
would take is: **per-construct rules + the WP
layer; adequacy lands the fuel-opsem statement** (V0 NOTE: the
former whole-run mint route — evaluator-minted per-round equations
consumed by walks — is DELETED with its theorems; the RoundEval
CHASSIS below awaits the V2 re-target to a case-splitting symbolic
stepper). The layer
contracts are stated normatively in
`docs/2026-08-25_reasoning-layer-contracts.md`; in brief:

- **The per-step language layer** (`relsem/RelSem/PerStep.lean`,
  `PerStepIris.lean`): a reified per-step language (`KExpr`/`KStep`)
  over the fuel semantics' own driver state, with an iris-lean
  `Language` instance and a completeness theorem
  (`ksteps_of_runNDFuel`) tying it to the executable runner — every
  step arm is *defined* from generated-code equations, never
  axiomatized.
- **The discharge chassis** (`relsem/RelSem/DeriveState.lean`,
  `RoundEval.lean` — V0 state: the whole-run `derive_rounds` mint
  mode is DELETED; what remains is the KEEP chassis per the ratified
  conversion table C-5): fail-closed proof-producing emitters,
  registry-dispatched law chains over the proved construct laws
  (`ConstructLaws.lean`, the `Kit/` lemma kits), kernelVerdict
  ground leaves — the meta layer only shapes claims; the kernel
  re-checks everything at declaration time. The V2 slice re-targets
  it to goal-directed per-construct stepping with case-split at
  irreducible discriminants.
- **The wp-tactic layer** (`PerStepTactics.lean`, `WpGround.lean`):
  `wp_step`/`wp_pures` walk the harness spine consuming the minted
  equations; `wp_side`/`wp_ground` discharge ground side conditions.
  Loops enter through the ∃-round `Seg.iter` (the V0 kill retired
  the fixed-round `iter_compose` family with Kit/Loop, conversion
  C-14; the Iris-level invariant story arrives with the V3a
  predicate-invariant slice).
- **The segment layer** (arc-18 R2; `relsem/RelSem/Segment.lean`,
  `SegmentFaces.lean`): Floyd cut points at Core labels — an ∃-round
  budgeted segment judgment (`Seg`) over the minted chain equations,
  composition/while rules proved once, invariants declared as a map
  from labels with obligations *derived* (RefinedC `typed_block`
  lineage), loop-head spelling normalization engine-side, and
  function contracts (`FnSpec`) with thin faces: user proofs are
  `verify_fn <spec>; seg_auto` plus one invariant declaration per
  loop (donor table:
  `docs/2026-08-26_arc18-r2-donor-correspondence.md`).
- **iris-lean coupling**: separation-logic machinery (weakest
  preconditions, framing, invariants) used freely in proofs and
  discharged through the adequacy theorem — Iris never appears in a
  statement. The decomposed machine-state RA
  (`CerbStateRA`/`CerbStateWP`, V1 2026-08-28: byte points-to +
  per-cell env ownership + control/supply/residual tokens) is the
  SOLE state interpretation (one-route gate-enforced; the arc-16
  whole-state heap RA is deleted).
- **Pure transport**: most of a specification's intellectual content
  lives as ordinary lemmas about the pure model (cheap, parallel,
  standard Lean), connected to execution once per structure family.

**The chase era is DELETED.** The chase-era workbench — the
`@[app_eq]` law table, the symbolic walker (`app_walk`) with
trace/replay, the arc-7 Iris shell, the transitional OwnP
interpretation, and the ambient theorem family they served — was
deleted at the 2026-08-27 kill-list execution (the C5 purge,
absorbed and executed; record
`docs/2026-08-27_kill-list-execution.md`). The chase-freeze gate
retired with its subject (its allowlist emptied); the one-route gate
now bans ANY OwnP-binding file, with an empty retirement register.
Post-mortem of the superseded route:
`docs/2026-08-24_chase-era-postmortem.md`.

## 5. How to check any claim in this file

- Rebuild the proof packages and watch the gates:
  `cd relsem && ../../scripts/capped lake build` (axiom sweeps,
  statement-TCB, absence gates are in-build);
  `cd ../speclab && ../../scripts/capped lake build`.
- Re-elicit a theorem's axioms: `#print axioms <name>` — compare
  against the `#guard_msgs` pins in `relsem/RelSem/Audit.lean` and
  `speclab/SpecLabAudit.lean`.
- Run the differential lanes: `scripts/test_verify.sh`, the
  `scripts/test_speclab_*.sh` family (`--gate` and `--plant`), and
  the corpus lanes per `scripts/LADDER.md`.
