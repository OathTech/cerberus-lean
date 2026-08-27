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
   It is **temporal, not permanent**: its remaining consumers are the
   ambient theorem family (which retires at the arc-18 C5 purge in
   favor of the threaded family) and compiled driver code; its
   deletion is lem-side surgery, registered for a lem arc. Two gates
   bound it meanwhile: (a) the **no-cone-entry gate**
   (`relsem/RelSem/Audit.lean`) pins the exact set of theorems whose
   cones carry it (114 registered ambient-family theorems) — any NEW
   theorem cone acquiring it is build-fatal, and a stale entry is
   build-fatal until deliberately removed; (b) the per-theorem
   `#guard_msgs` cone pins. The **threaded flagship theorems**
   (`T1Threaded`–`T3Threaded`, `T6Threaded` and their UB-freedom
   companions) have cones of **exactly the classical trio**
   `[propext, Classical.choice, Quot.sound]` — no effect axiom
   anywhere; the ambient originals wear
   `[propext, runEffectful, Classical.choice, Quot.sound]`, exactly
   and pinned. What remains to reach trio-everywhere: the spec-lab
   statement substrate still quotes the ambient initial state
   (registered for the family-∀ slice, which re-lands those
   statements anyway), and the ambient family retires at the purge.
   All assertions are in-build and plant-tested (deliberately broken
   to confirm they fire — transcripts in
   `docs/2026-08-25_arc17-s2b-axiom-endgame.md`).

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

**Unconditional kernel theorems about compiled C programs.** The
foundational slate T1–T4 (scalar arithmetic through struct member
write/read): ∀-quantified, interpreter-only statements about pinned
compiled Core programs, proved via the iris-lean weakest-precondition
route and discharged through an in-repo adequacy theorem into
statements that mention only the fuel semantics. Cones exactly as §1
(the ambient quartet, pinned). Since the Iris refounding (arc-16/17),
a **threaded** family re-proves T1–T3 (and a fifth fixture, T6) at
**∀-fresh-supply-seed statements** — strictly stronger than the
ambient originals — with cones of **exactly the classical trio**. A
sixth fixture, **T7** (`t7_flip.c`, a branch-in-loop: data-dependent
arms alternating across iterations), is proved at a guarded ∀-seed
statement through the arc-18 **segment layer** (one declared loop
invariant, `verify_fn` + `seg_auto`; `relsem/RelSem/T7.lean`), same
trio-exact cone. **T5** (`t5_sum.c`, the bounded
sum loop) is PROVED at the chartered **∀-n input-family** statement
(0 ≤ n ≤ 100 ⇒ outcomes = {Specified(n·(n−1)/2)}, no UB) through the
segment layer at the SYMBOLIC trip count — one declared loop
invariant, body obligations from the ∀-k pack closure, the driver
atom through the once-proved two-scratch rule, a two-line proof
(`relsem/RelSem/T5.lean`, arc-18 R4), trio-exact cone. **T4**
(`t4_struct_member.c`, the struct-member exit-criterion target) is
PROVED at its guarded ∀-seed threaded statement (arc-18 R5): the
unrestricted ∀-seed statement is FALSE (the arc-16 S4 hash-collision
falsifier), so the statement carries the kernel-computable
**seed-apartness guard** `T4SeedApart`; under it the whole 56-round
run — including the NEG-store transform's two fresh draws at the
OPEN seed — is evaluator-minted equation supply, and the theorem is
`verify_fn membSpec; seg_auto` (`relsem/RelSem/T4Threaded.lean`),
trio-exact cone. The full threaded slate T1–T7 is now proved through
the segment layer. The ambient T1–T4 theorems stand until the purge
(the ambient-era T5 prefix chain retired at R4 — subsumed by the
proved theorem).

**Kernel-checked statement layers for real C functions** (the spec
lab: division/modulo, `memcpy`, array access, linked-list append,
tree rotation, and two CN-suite functions): the pure models and their
lemmas, the model↔stream bridges, finite *sample*-∀ statements over
explicitly pinned instance sets (the quantification is labeled — a
finite set, not the family), leak-observable statements, and
*conditional* plant-refutation schemas — all kernel-checked, with
cones pinned in-build.

**Differential evidence at scale** (evidence, not theorems): every
harness instance and every corpus lane agrees between the Lean
pipeline and the OCaml oracle — including ~2,000 executions across
the spec-lab families and a 2,186-file sweep of the upstream CI
corpora with zero semantic mismatches. See
`docs/2026-08-22_ci-sweep-results.md` and the `*-results.md` records.

**Not yet proved (parked, priced, in the records):** the
**exec-equation campaign** — the unconditional kernel proofs that the
compiled harnesses *execute* to their verdicts (which would upgrade
sample-∀ to family-∀ and make the refutation schemas unconditional) —
is the current binding constraint. Its machinery is the arc-17
automation framework (the law-driven round evaluator with its
hypothesis-threading mode, the construct-law layer, and the
invariant-based loop treatment — charter:
`docs/2026-08-24_arc17-automation-framework-charter.md`), being
consolidated to a single route by the arc-18 coherence arc
(`docs/2026-08-25_arc18-coherence-charter.md`; family-∀ endpoints
land at its C4 slice); the chase-era walk/sealing route it
supersedes is frozen pending the arc-18 C5 purge
(`docs/2026-08-24_chase-era-postmortem.md`).
Length/shape-parametric ∀ (beyond fixed shapes) is staged behind the
same machinery. Do not read any claim in this file as covering these.

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
actually takes (the flagships `T1Threaded`–`T3Threaded`, `T6Threaded`
all run on it) is: **the evaluator mints equations; the WP layer
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

**Frozen legacy, purge-bound.** The chase-era workbench — the
`@[app_eq]` law table with its symbolic walker (`app_walk`),
per-stage certificate emission, and trace/replay — still exists
in-tree feeding the *ambient* (pre-threading) theorem family, but it
is frozen by a build gate (`scripts/check_chase_freeze.sh`: any new
dependence on it is build-fatal) and scheduled for deletion at the
arc-18 C5 purge together with the ambient family it serves. New
proof work goes through the evaluator/WP route above, never the
walker. Consolidation plan and the retirement inventory:
`docs/2026-08-25_arc18-coherence-charter.md`,
`docs/2026-08-25_reasoning-layer-contracts.md`; post-mortem of the
superseded route: `docs/2026-08-24_chase-era-postmortem.md`.

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
