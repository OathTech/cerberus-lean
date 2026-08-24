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
2. **The declared boundary axioms** — exactly three:
   - `LemLib.runEffectful` (in `lem-lean/lean-lib/LemLib.lean`) — the
     effect-erasure boundary for `BaseIO` externs (fresh counters,
     debug output);
   - `CerbTags.with_tagDefs` (`CerbTags.lean`) — tag-definition
     state installation;
   - `CerberusFresh.forceIO` (`CerberusFresh.lean`) — fresh
     symbol/digest generation.
   These three are **scheduled for elimination, not accepted as
   permanent**: the effect state they hide (the fresh-symbol supply,
   the tag-definition table) is planned to move *inside* the modeled
   machine state — Lean-side only; the OCaml implementation keeps its
   ambient counter for upstream fidelity — after which theorem cones
   shrink to exactly the three standard Lean axioms
   (`propext`, `Classical.choice`, `Quot.sound`) and the native
   counter survives only as the compiled binary's implementation of
   the modeled supply. Until then, every cone wears them visibly
   (below), and no design may make that migration harder.
   Build gates pin this set: the axiom census over this repository
   (hand-written and generated code) is asserted to be exactly
   `with_tagDefs` + `forceIO` — `runEffectful` lives in the LemLib
   runtime library — and each theorem's **transitive axiom cone** is
   asserted exactly: the flagship theorems' cones are
   `[propext, runEffectful, Classical.choice, Quot.sound]` — the
   classical trio plus the effect boundary, nothing else. The
   assertions are in-build (`relsem/RelSem/Audit.lean` plus
   `scripts/check_theorem_axioms.sh`) and plant-tested (deliberately
   broken to confirm they fire — DESIGN.md §5).
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
statements that mention only the fuel semantics. Cones exactly as §1.

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
is the current binding constraint; it waits on the symbolic-walk
machinery (T5 and the in-chase sealing work, both in flight — see
`docs/2026-08-22_arc15-t5-resumption-record.md` and the stepper
design note `docs/2026-08-23_stepper-arc-design.md`).
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
ordinary kernel-checked declaration.

- **The workbench** (`relsem/`): a law table (`@[app_eq]`) of proved
  rewrite equations; a symbolic walker (`app_walk`) that discharges
  execution steps by emitting per-stage certificates — each an
  ordinary kernel-checked declaration; sealing (naming big
  intermediate terms) to keep every kernel obligation shallow;
  structured trace IR with **checked replay** (recorded proof runs
  replay ~15× faster with identical checking, and refuse loudly on
  any fingerprint mismatch).
- **iris-lean coupling**: separation-logic machinery (weakest
  preconditions, framing, invariants) used freely in proofs and
  discharged through the adequacy theorem — Iris never appears in a
  statement.
- **Pure transport**: most of a specification's intellectual content
  lives as ordinary lemmas about the pure model (cheap, parallel,
  standard Lean), connected to execution once per structure family.

The direction of travel is the **Iris refounding**: instantiating the
proof machinery this section describes as a proper Iris language
instance with a points-to heap over the memory model, per-construct
WP laws, and logical loop invariants — after which the walker-based
discharge described above is scheduled for retirement (re-proof
first, statements and axiom cones unchanged). The plan and its
post-mortem of the superseded route:
`docs/2026-08-24_arc16-iris-refounding-charter.md` and
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
