# The harness statement template (choice-stream mechanism resolved)

Status: design RATIFIED in discussion 2026-08-22 ([USER] rulings tagged);
S0 of the warm-up arc instantiates it. Supersedes the "S0 open subtlety"
(concrete choice primitive) in the container CLAUDE.md doctrine block —
resolved: no runtime primitive is needed for data.
REVISED 2026-08-23 [arc-15 S5]: the arc-15 spec lab instantiated the
template on five rungs (scalars → byte arrays → linked list → tree
rotation → the CN-seed pair); this revision folds in the confirmed
verdicts, the normative amendments from the S4 reference instance's
errata, and the worked example. Rung records + twin registers:
cerberus-lean `lean_frontend/docs/2026-08-2{2,3}_arc15-*.md`.

## The template

For a target C function `f` and a structure family with pure Lean model
`M` (first-order inductive), pure `encode : M → Stream` /
`decode : Stream → M`, and pure behavioral spec `modelFn : M → M'`:

1. **Headline theorem (model-∀):**
   `∀ m : M, wf m → cerberus_exec (mkHarness (encode m)) ⇓ Some (encodeResult (modelFn m))`
   — plus the leak conjunct (final allocation map empty after teardown).
2. **Stream lemma underneath:** the same statement ∀ streams, related by
   kernel lemma `decode ∘ encode = id`. Streams are TRANSPORT/REPLAY
   vocabulary, not statement vocabulary. [USER]: model-∀ as headline —
   inductive data models are not "fancy"; the fiat rule is properly
   "everything in a statement must be EXECUTABLE" (computable pure
   functions + first-order data in; propositions/SL/noncomputable out).
   CODECS SHIP BOTH LAWS [arc-15 S5, confirming S1-E2]: the
   model-∀ ↔ stream-∀ bridge with the OPERATIONAL stream-validity
   form (what a fuzzer actually checks) needs `decode ∘ encode = id`
   AND the `Canonical` law (`encode ∘ decode = id` on consumed
   prefixes — every accepted wire image is canonical). Both are
   idiom-library contracts from day one (`Codec.RoundTrip` +
   `Codec.Canonical`, kernel instances u8/u16/u32/u64/arrays);
   writing only the round trip pushes ~90 lines of canonicity into
   every consumer. Measured across five rungs: the bridge proof
   shape survives codec composition (two-list sequences, recursive
   self-delimiting tree codes) unchanged.
3. **Readback via observation channels, not boolean verdicts** — [USER
   2026-08-22]: `ret` is a computed machine value; the exec outcome
   cannot carry unbounded structures, and trying to assert "the tree in
   memory at exit" would drag separation logic into the statement. The
   invariant instead: THE STATEMENT NEVER MENTIONS MEMORY — the program
   converts memory to observables; we assert only about observables.
   Two SL-free forms:
   - **Form 1 (DEFAULT): compiled-in expected array + generic
     comparator.** mkHarness splices TWO literals — `choices[]` and
     `expected[] = encode(modelFn(decode choices))` (computed pure-side
     at statement-construction time). The C post-phase walks the
     post-state with a generic PER-CODEC comparator (idiom-library
     code, audited once, reused) returning `0` on agreement, `1+i` for
     first divergence at position i. Statement:
     `∀ m, exec(mkHarness(encode m, encode(modelFn m))) ⇓ Specified 0`.
     nolibc-clean, tiny outcomes; mismatch-index return + shared
     comparator + plant tests defeat boolean-vacuity.
   - **Form 2 (variant): stdout serialization.** The outcome's `stdout`
     is an unbounded observable already differentially compared; the
     harness prints the encoding, statement asserts
     `outcome.stdout = encodeResult(modelFn m)`. Costs libc mode; buys
     a human-readable witness per differential log.
   - **Digest readback REJECTED for statements**: hash equality does not
     imply structure equality — the statement would be weaker than the
     proof, and the statement is the product.
   - CONFIRMED VERDICTS [arc-15 S5]: Form 1 is the DEFAULT at every
     rung tried (scalar/array/list/tree/pair — spec register S1-E1,
     S3-E1, S4 record §d); Form 2 is kept as the DIAGNOSTIC/WITNESS
     variant (its human-readable stdout witness earns its keep at
     structure sizes; its costs are unchanged: libc mode + the
     line-buffering discipline — the serialization must END IN A
     NEWLINE, and the newline is part of the statement, or the
     observable is empty on both pipelines [S1-E1 measured]); the
     boolean verdict is legitimate only where the property is
     genuinely boolean and is strictly dominated wherever an index
     exists (a wrong-position-blind comparator bug passes a boolean
     plant and fails a mismatch-index plant). Diagnostic ranking:
     Form 2 > Form 1 > boolean; statement default: Form 1.
   - READBACK-EQUALITY IN FRONT, DECOMPOSITION IN BACK [arc-15 S5,
     from S4-E1]: where a property decomposes as "the locus changed
     per the operation + the frame is untouched" (rotation, and every
     mutating-structure target), the STATEMENT stays the full
     readback equality (one wire vocabulary, one mismatch-index
     space, no locus/path vocabulary, fuzz-runnable); the
     locus/frame decomposition is proved ONCE PER MODEL in the pure
     layer (kernel lemmas, e.g. `rotateAt_as_replace` +
     `rotateAt_frame`) — it adds no statement strength (derivable)
     and is exactly the framing shape the proof layer (Iris side)
     will consume. Never promote it to a statement.
   - The leak conjunct is kept but framed as an outcome-level observable
     (leaked-allocation count = 0): a single scalar fact about the final
     state, no contents/shape vocabulary. Anything needing points-to
     vocabulary in a statement = the governed escape hatch.
     LIVE since arc-15 R3 with a measured driver baseline (the exec
     outcome's final allocation map; the errno object = baseline 1,
     re-checked per run as a startup-footprint drift gate).
     AMENDMENT — THE LEAK CONJUNCT IS A FAILURE-CLASS SEPARATOR FOR
     PLANTS [arc-15 S5, from S4 errata]: plant suites should include
     BOTH a broken-but-leak-free target and a broken-and-leaking
     target where the shape admits them (R4: wrong-child-swap =
     content break at baseline; dropped-subtree = structural break at
     baseline+1, the orphan counted by a pure size lemma). A
     verdict-only family cannot tell the classes apart — the pair
     DEMONSTRATES the conjunct's value instead of asserting it, and
     the leaked count's pure prediction (|orphaned| from the model)
     is part of the plant's predicted signature. Known open leg: the
     oracle's batch surface prints no allocation census, so the leak
     observable is Lean-side measured / pure-predicted /
     logic-refutable but not yet oracle-differential (priced S,
     fork-side, registered).
   Boolean verdicts remain acceptable only for genuinely boolean
   properties.
4. **Plant test per template** (spec-adequacy analogue of the gate
   plant-test practice): deliberately break the target function, confirm
   the differential run goes red and the theorem becomes unprovable.
   Vacuous specs must be LOUD — we can't notice vacuity at scale by
   reading.

## The choice-stream mechanism ([USER 2026-08-22]: ratified)

**Mechanism A — compiled const array (ADOPTED):** `mkHarness : Stream →
CProgram` splices `static const unsigned char choices[] = {...};` into a
fixed C template; the builder is ordinary C reading `choices[i++]`. The
harness is a PROGRAM FAMILY indexed by the stream; choice is resolved
BEFORE the program exists — no runtime randomness, no semantics-level
injection, zero magic in any single execution. Each instance is a
closed, deterministic, concrete program: oracle-runnable bit-for-bit,
fuzzable by sampling streams, replay = the source text itself. Every
resolved program is literally a test case; the theorem says the infinite
family passes. Finiteness solved: self-delimiting codes give unbounded
sizes across the family, each instance finite.

- **The single trust point:** `mkHarness` (faithful source splice; pure,
  tiny, auditable). Both pipelines consume the SAME rendered text, so
  there is no reasoned-about/ran gap.
- **Proof economics:** instances differ only in one array initializer →
  ONE parametric lemma over the template with the array contents held
  symbolic (a vector of unknowns through the builder-loop invariant) =
  T5's symbolic-n iter_compose technology. This is what the codec
  sketch's "symbolic-memory injection channel" cashes out to.
  AMENDMENT — PER-SHAPE PARAMETRIC LEMMA SCOPING [arc-15 S5, from S4
  errata]: the "one parametric lemma" holds PER FIXED SHAPE — the
  emitted Core varies only in literals when the model's SHAPE
  (lengths, arities, tree structure, path depth) is fixed, so the
  digit-run-zip parametric term (arc-15's statement-level
  realization: e.g. `rotateMainParamDecl b0..b23`, 256^24 instances,
  zero marginal statement cost) delivers the fixed-shape family-∀
  as the exec campaign's endpoint. Crossing a shape axis changes the
  AST in ARITY (initializer widths, loop trip counts, callee
  recursion depth, walk position), and each such axis is its own
  symbolic-lemma wall (T5 symbolic-n + symbolic-arity initializers
  + recursion depth + path position — priced and registered, not
  free). Statements must LABEL which they quantify: explicit sample
  set / fixed-shape family / shape-parametric.
- **rand() is REJECTED** as a choice provider (ties specs to a libc PRNG,
  destroys per-instance determinism/replay/differential).
- **THE SEQUENCED-CALL RULE (mechanism-A determinism)** [arc-15 S5,
  from S4 errata; MEASURED]: in harness C, a call result always
  lands in a plain local before any member/deref store — never
  `*link = f(*link);` or `t->left = build(...)`. The assignment's
  LHS lvalue walk is UNSEQUENCED with the RHS call, and the oracle's
  exhaustive mode enumerates the interleavings: measured 3
  executions per site, compounding per site (a 6-node R4 instance
  blew a 120 s timeout; the landed-local form runs in 0.07 s).
  Member stores with simple-load RHS (`t->left = l->right`) are fine
  — the TARGET C stays untouched; the rule binds the HARNESS only.
  Harness C dialect choices are differential-budget choices, not
  style.
- **THE PARENT-LINK WRITE-BACK PATTERN (mutating targets)** [arc-15
  S5, from S4 errata]: when the target returns a replacement for the
  substructure it was handed (rotation returning the new subtree
  root), the harness walks a PARENT LINK (`struct node **link`),
  calls the target on `*link`, and stores the result back through
  the link (as a landed local, per the rule above) — exactly what a
  real caller does. This makes path selection STATEMENT DATA (the
  path rides the choice stream; further paths are pinned verbatim
  instances) rather than harness configuration, and keeps the
  pointer-argument rule intact (the interior pointer originates from
  the program's own build; pointer values never in the stream).

**Mechanism B — argv input channel (S0 PROBE):** one fixed program,
`∀ inputs` via `main(argc, argv)` — the purest headline if oracle/Lean
argv parity certifies. Probe it at S0; strict upgrade of A's headline if
green; A loses nothing if not. stdin is OUT (drags in CerbFS, the
largest untouched seam).

**Mechanism C — semantics ND primitives (BANNED for data, reserved):**
`__any_bounded_int` etc. stay banned for data generation (2^64-branch
exhaustive collapse kills the differential story; the primitive is a
DUMMY stub today). ND remains the semantics' OWN: allocator now, cmm
schedules later (streams resolve *scheduling* there — forward design
unchanged).

## Design lineage ([USER 2026-08-22])

The mechanism is the "generators as parsers of randomness" perspective
from the PBT literature (Goldstein & Pierce's free-generator framing;
industrially, Hypothesis's byte-stream IR) — `decode : Stream → M` IS a
free generator, `encode` its printer, `decode ∘ encode = id` the
round-trip law, and the builder-correctness lemma the kernel-verified
analogue of generator soundness. [USER]: CN's own run-time generator
(Bennett) takes the same perspective — so our choice-stream harnesses
share a substrate with CN's test generation, strengthening the
warm-up slate's CN-vs-us comparison beyond the modular-contracts vs
closed-program-observation distinction (in principle, stream corpora
are comparable across the tools). Practical transfer worth exploiting:
Hypothesis-style SHRINKING — since each harness is a pure function of
its stream, counterexample minimization in the fuzz lane = shrink the
byte stream, yielding minimal counterexample PROGRAMS for free.

Not "defining memory in Lean is hard" (the model IS in Lean). The
decisive reasons: (a) REACHABILITY — conjured states may be ones no
execution produces; theorems over them are silently vacuous; builders
guarantee reachability by construction; (b) THE ORACLE — cerberus-OCaml
cannot start from an injected state; injection forfeits differential
testing; (c) REPRESENTATION ROT — statements pinned to memory-model
internals break under PNVI/cmm evolution; harness statements survive.
These also mark when injection returns: never for data contents.

## Containment note (north-star tension, resolved in-paradigm)

"Builder-reachable states" under-quantifies for containment (attacker
states aren't built by legitimate code) — BUT a byte-blaster builder
(copy the stream verbatim into an allocation) reaches EVERY possible
content of a buffer; what it cannot reach is exotic metadata
(provenance corners, cross-allocation aliasing). For the attacker model
that matters (attacker controls bytes, not allocator bookkeeping),
byte-level builders suffice. The metadata residue is escape-hatch /
future-injection territory — scope it consciously per the governed
escape hatch, never drift.

## Pointer-valued arguments

Never passed in: choices select a PATH; the harness walks its own built
structure and hands `f` the interior pointer it arrives at. All pointer
values originate from the program's own allocations.

## The worked example (tree rotation — arc-15 R4, the reference instance)

Full write-up: cerberus-lean
`lean_frontend/docs/2026-08-23_arc15-s4-r4-tree-worked-example.md`
(target, model, codec, full harness listing, plants, the S4-E1
statement-style lesson). Every template element appears once, in its
intended place. The statement shape, inlined [arc-15 S5]:

* Model: `Tree` (leaf/node, i32 vals) × `Path` (`List Bool`);
  `rotateAt = applyAt rotateRight` — TOTAL, identity off-shape,
  mirroring the C; `Wf` bounds REALIZATION only (≤ 31 nodes, path ≤
  8; off-shape paths are live instances).
* Codec: pre-order presence bits (`0 | 1 val:i32le tree tree`) ++
  path count + step bytes; fuel-indexed decoder; RoundTrip +
  Canonical kernel lemmas (the free-generator reading: `decode` IS
  the tree generator).
* Harness phases: scan (validate before any allocation; malformed =
  254, total on every splice) → build (recursive, heap) → parent-
  link path walk → the call on the interior pointer, result stored
  back through the link → serialize the post-state tree (cap-guarded:
  the 253 arm doubles as cycle protection) → free (teardown) →
  Form 1 comparator (0 / 1+i / length arm 255).
* Statements: `HarnessRunsTo (rotateFileOf m) 0` ∀ m in the labeled
  sample set (finite-explicit), the stream face via the kernel
  bridge, the pointer-selection path family, `BuildOnlyStatement`
  (builder correctness as a runnable program: `expected = choices`),
  and the leak family (healthy at driver baseline; the drop plant at
  baseline+1, its orphan count a pure lemma). Parametric term
  `rotateMainParamDecl b0..b23` = the fixed-shape family-∀ endpoint.
* Plants: wrong-child-swap (content break, leak-free) +
  dropped-subtree (structural break, leaking) — the two-observable
  separation; blind spots documented AND demonstrated green.

## S0 obligations

1. Read golean's structure-parameterization approach (attributed
   precedent for mechanism A). [DONE arc-15 S0 — adopt/differ table
   in the S0 record + speclab/README.md attribution.]
2. Probe argv parity both pipelines (mechanism B go/no-go). [DONE
   arc-15 S0 — byte-identical at the comparable point; mechanism B =
   GO pending one small Lean driver `--args` flag, parked priced S.]
3. Write `mkHarness` + the symbolic-initializer lemma for the
   tree-rotation reference instance; CN warm-ups then instantiate the
   template with progressively richer structures (scalars → arrays →
   lists → tree) toward buddy-allocator shapes. [mkHarness + the
   ladder: DONE arc-15 S0-S5 (R1 divmod, R2 memcpy/getarr, R3
   IntList_append, R4 rotation, R5 swap_pair/lookup — statement-level
   parametric terms landed per fixed shape); the symbolic-initializer
   LEMMA (proved family-∀) = the exec-equation campaign, parked
   priced L after T5.]
