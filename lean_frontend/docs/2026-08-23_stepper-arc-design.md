> Imported 2026-08-23 from the project-container notes/ folder (the
> operator-side working layout) so the repo is self-contained; the
> container copy may accrue operator annotations.

# The stepper arc — design note (compositional exec proofs)

Status: DESIGN BANKED 2026-08-23 from operator discussion ([USER]
rulings tagged); not yet chartered. Sequencing: seal-through-the-chase
→ T5 lands → this arc. Grounding: the arc-15 Linux-scaling memo
(proof register, results doc), the R13 wall record, the harness
statement template note, the parked exec-equation campaigns (R1-R5).

## The problem, in the lab's own numbers

Arc-15 measured ~3 proof-lines/LOC of PURE-MODEL content (spec-adjacent
— CN users write the analogue as annotations) with the EXEC-EQUATION
campaign parked as the binding constraint. The exec walk's growth axis
is measured: Core construct vocabulary saturated at R3; growth is CALL
STRUCTURE (inlining). [USER]: "could we do better than 3/LOC?" — the
answer is that the number that should approach ~0 is proof-per-
straight-line-C, and the mechanism is a certificate-emitting symbolic
stepper.

## Architecture: laws + seals + residuals + overrides

A CN/Lithium-style engine that steps the semantics in a symbolic
domain, discharging straight-line segments automatically; human
content only at loop heads (invariants) and call boundaries
(contracts). NOT a pivot — the designed endpoint of the workbench:

- **Laws** (have): arc-9 law tables + app_walk; arc-11 context-indexed
  laws = proved rewrite rules applied at subterms (SAW's "proved
  rewrites" analogue).
- **Seals** (have; deepen): named intermediates keep every kernel
  obligation shallow. SEAL-THROUGH-THE-CHASE (parked Lane-B design,
  operator go/no-go pending) is the prerequisite: checkpointed seals
  INSIDE kWhnfWithFacts so chase depth never exceeds the kernel's
  recursion guard (the R13 wall: Kernel.whnf "deep recursion detected"
  at 172 Core lines; lab flagships are 1,900-4,300). Trades kernel
  depth for kernel count — the right trade (count parallelizes,
  depth doesn't).
- **Residuals** (have): arc-11 typed residuals = SAW's
  "make-subterm-symbolic" generalization move (seals name without
  forgetting; residuals abstract with obligations — distinct moves,
  both needed; the productive round shape is chase → seal →
  generalize).
- **Overrides** (MISSING — the new capability): per-function proved
  summaries applied at call sites instead of inlining. [USER]: "one
  missing piece here is compositional reasoning (in the SAW sense)."
  Converts proof cost from inlined-tree size to call-graph size.

## The compositionality ruling ([USER-aligned, doctrine-derived)

Compositional reasoning lives STRICTLY IN THE PROOF LAYER. Headline
theorems stay closed-program observations (the statement doctrine
does not bend). A summary — "calls to f from states in class C step
to states described by f_model" — is an ordinary internal lemma,
never statement vocabulary, never TCB. Boring in front, SAW-style
modular structure in the back, glued by transitivity. The parked
exec-equation campaign endpoints (R1 division, R2 memcpy, R5 swap …)
ARE per-function summaries in embryo: the summary library exists
before its consumer.

## Two-stage summary plan (framing is the hard part)

Applying f's summary at a call site needs the caller's remaining
state untouched — the framing problem. Staged:

1. **Whole-state summaries first**: f's effect as a function on the
   entire memory state. No framing machinery; kernel-friendly;
   SUFFICIENT for closed harnesses (the harness owns the whole heap).
   Scales worse; gets overrides working; closes the parked campaigns.
2. **Footprint summaries second**: f touches only its footprint; the
   frame persists. The SL-shaped version — Iris/OwnP points-to over
   the Cerberus memory model. THIS IS P2'S REAL DESTINY: not a
   hand-proof style (graded poorly as one in the lab) but the framing
   engine that makes overrides scale — resolving why P2 kept feeling
   necessary-but-not-yet.

## Trust accounting

SAW trusts its rewriter, override mechanism, and solvers. We do not:
every rewrite application, seal link, and override instantiation
emits a kernel certificate (the proof-scaling philosophy's constant-
factor tax; lab evidence says affordable with good engineering). No
non-kernel proof methods; no budget bumps (in-chase sealing exists
precisely so depth never needs a knob).

## Benchmark and success criteria (falsifiable on day one)

The five parked exec-equation campaigns (R1-R5) are the evaluation
corpus: known statements, pinned fixtures, and a manual-cost baseline
(T5: 79 rounds for a 172-line fixture; R4 flagship ≈ 26× that).
Success = close the parked campaigns at near-zero marginal human
lines; re-measure lines/LOC; upgrade the arc-15 sample-∀ statements
to family-∀ and the conditional refutation schemas to unconditional.
Floor prediction: human lines ∝ loop count + call structure, not LOC
(= CN's floor, reached with kernel certificates instead of trust).

## Design donors (attribute in the engine headers)

Lithium/RefinedC (vendored, deps/refinedc — goal-directed automation,
the litreview brief), SAW (overrides-at-calls, proved-rewrite style,
generalization; [USER] supplied the mapping), golean (walker/audit
patterns, already attributed), CN (the stepping-tool shape being
mirrored certificate-side).

## Open questions for the charter

1. Symbolic-state representation for stage 1 (concrete-map-with-
   symbolic-cells vs whole-state function composition).
2. Override applicability conditions in an ND semantics (runND
   branch structure at call sites; the sequenced-call rule).
3. Where invariant inference stops and the human starts (loop heads:
   iter_compose families exist — how much of the invariant can the
   engine propose?).
4. Certificate-count economics: obligations per sealed step at
   Linux-function scale; parallel checking strategy.
