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
   build-fatal. Every theorem in the repository — the threaded slate
   `T1Threaded`–`T5Threaded` with UB-freedom companions, the walk
   supplies, the law library — has a cone of **exactly the classical
   trio** `[propext, Classical.choice, Quot.sound]` (or a subset),
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

**The quantified threaded slate, T1–T5** — kernel theorems about
pinned compiled Core programs, stated at the fuel semantics only,
∀-quantified over the fresh-supply seed AND the C-level inputs, cones
exactly the classical trio:

- **T1** (`t1_id.c`): ∀ seed, ∀ x in int range — outcomes of
  `id(x)` = {Specified(x)}, no UB (`relsem/RelSem/T1Threaded.lean`).
- **T2** (`t2_add.c`): ∀ seed, ∀ x y with x, y, x+y in range —
  outcomes of `add(x,y)` = {Specified(x+y)}, no UB (the forced
  no-signed-overflow precondition, spec-discovery documented).
- **T3** (`t3_roundtrip.c`): ∀ seed, ∀ x in range — roundtrip
  through a volatile write/read returns x.
- **T4** (`t4_struct_member.c`): ∀ seed under the kernel-computable
  seed-apartness guard `T4SeedApart` (the unrestricted ∀-seed
  statement is FALSE — the arc-16 S4 hash-collision falsifier, kept
  as the guard's justification), ∀ x in range — struct member
  write/read returns x (`relsem/RelSem/T4Threaded.lean`).
- **T5** (`t5_sum.c`, the bounded sum loop): ∀ seed (guarded), ∀ n
  with 0 ≤ n ≤ 100 — outcomes = {Specified(n·(n−1)/2)}, no UB, at
  the SYMBOLIC trip count through the segment layer's once-proved
  while rule with one declared invariant (`relsem/RelSem/T5.lean`).

Each theorem's proof is `verify_fn <spec>; seg_auto` over its
engine-room walk supply (T1Walks/…/T5Spine — trio-clean equation
supply registered per fixture; the supply-vs-proof ratio is the
registered automation frontier). The known honest limitation,
recorded in the whole-project assessment
(`docs/2026-08-27_professor-whole-project-assessment.md`): these
statements do not yet cross a data-dependent branch at a symbolic
value — the branch/case-split rule, the assertion layer over locals,
and the symbolic executor are the build plan's subject (§B0–B6 of
the assessment; awaiting ratification).

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
actually takes (the whole threaded slate `T1Threaded`–`T5Threaded`
runs on it) is: **the evaluator mints equations; the WP layer
consumes them; adequacy lands the fuel-opsem statement.** The layer
contracts are stated normatively in
`docs/2026-08-25_reasoning-layer-contracts.md`; in brief:

- **The per-step language layer** (`relsem/RelSem/PerStep.lean`,
  `PerStepIris.lean`): a reified per-step language (`KExpr`/`KStep`)
  over the fuel semantics' own driver state, with an iris-lean
  `Language` instance and a completeness theorem
  (`ksteps_of_runNDFuel`) tying it to the executable runner — every
  step arm is *defined* from generated-code equations, never
  axiomatized.
- **The equation supply** (`relsem/RelSem/DeriveState.lean`,
  `RoundEval.lean`): the law-driven round evaluator mints *named*
  states and per-round `app` equations by applying proved construct
  laws (`ConstructLaws.lean`, the `Kit/` lemma kits) — the meta layer
  only shapes the claim; the kernel re-checks everything at
  declaration time. Anything it cannot mint is a *tagged frontier*,
  fail-closed, never a silent skip.
- **The wp-tactic layer** (`PerStepTactics.lean`, `WpGround.lean`):
  `wp_step`/`wp_pures` walk the harness spine consuming the minted
  equations; `wp_side`/`wp_ground` discharge ground side conditions.
  Loops enter through `iter_compose` (`Kit/Loop.lean`) — an
  invariant-style composed-block equation at the equation calculus
  (Floyd–Hoare-shaped; the Iris-level invariant story arrives with
  contracts/typed views in a later arc).
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
  statement. The memory-model heap RA (`CerbHeapRA`/`CerbHeapWP`:
  byte points-to over the concrete memory model, framing) is landed
  and becomes the sole state interpretation in the arc-18 migration.
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
