# Arc 9 charter: WP tactic library + complex-reasoning slate ("the workbench")

Date: 2026-08-20. Mode: long-cycle autonomous under the orchestrator/
worker doctrine. BLESSED by operator via launch, 2026-08-20 ("Great,
let's launch this"). Fully offline. Branch
pair: `arc/wp-tactics` (cerberus-lean; lem-lean expected UNTOUCHED —
any lem change triggers the full pin dance).

## Objective

[USER 2026-08-20, shape directive] Build the proof machinery
deliberately instead of discovering its absence mid-grind: (1) a
REVIEW of iris-lean, deps/brick-wp, and deps/golean; (2) a careful
PLAN for a reasonable tactic set; (3) prove SEVERAL examples with
loops / other constructs requiring complex reasoning (T5 is the
anchor, not the whole point); (4) ITERATIVE improvement of the
tactics against those examples. The whole point: lifting ideas
cleanly, avoiding dumb grind, designing the library nicely, and
ESPECIALLY reusing iris-lean infra where it is already available.

Exit criterion with teeth: T5 (bounded loop) plus a graded slate of
further complex examples proved through the library with SHORT proofs
— where "short" is a measurable bar set in S1, and a proof that blows
the bar is a missing-rule finding, never something to push through.

## Standing constraints (inherited, load-bearing here)

- Statements stay interpreter-only (statement-TCB gate unchanged);
  Iris and every new tactic are PROOF MACHINERY — nothing enters the
  theorem statements or the TCB.
- Cones stay exactly [propext, runEffectful, Classical.choice,
  Quot.sound] (arc-8 absence gates enforcing). New WP rules are
  PROVED against the existing adequacy chain — no axiomatized rules,
  no sorry, no non-kernel proof methods (D14 ban).
- Heartbeat doctrine: an elaborator-budget bump is a defect with a
  register entry and a remover. If a tactic needs one, the tactic is
  wrong.
- golean anti-pattern (operator, arc-7): no long boring hacking
  campaigns where there's a rule to find. Enforced structurally this
  arc via the proof-size bar + the S3 stop-extract-redo loop.

## Slices

**S0 — the three-way review (no code).** One worker, three maps, one
gap matrix:
(a) IRIS-LEAN — TWO revisions: the pinned Lake dep (79dab154a) AND
the freshly updated deps/iris-lean head ([USER 2026-08-20] "I also
updated iris-lean … they're new" — 5 commits past our pin: wp_rec
eval-context fix #657, OwnP #653, ProgramLogic loose ends #666,
big_sepM2 #582, 100% base_logic #656 — all on-topic for this arc).
Catalog what iris-lean ALREADY SHIPS at each rev — proof-mode
tactics (intro/split/frame/etc.), WP infrastructure, invariant/
fixpoint machinery (Löb, `wp` unfolding lemmas, any while/fixpoint
combinator support), ghost-state libraries beyond what arc-7 used —
and what of it our IrisRules/IrisAdequacy currently duplicates by
hand. Produce a PIN-BUMP RECOMMENDATION with the delta priced (the
bump is offline-executable: deps/gitconfig resolves the Lake dep to
the local checkout; method prior art: golean's own upstream
delta-scan recon, deps/golean commit 276c0bde + W3.2 records).
REUSE-FIRST is the arc's prime directive: every capability we need
that iris-lean has is consumed, not reimplemented — deviations need
recorded justification.
(b) BRICK-WP (deps/brick-wp, Rocq — DESIGN donor, not code): the
tactic taxonomy and layering — representation/ownership conversion,
locals/fields/reads/assignments, expression helpers, function-proof
setup, direct-call composition, statement walkers + lightweight
automation (wp_step / wp_auto / wp_walk), the spec-to-wp_fptr
bridges. Catalog with file:line cites; for each, note the
Cerberus-Core analog (our MExpr/DriveConfig shapes) and whether the
idea transfers.
(c) GOLEAN (deps/golean, freshly updated [USER 2026-08-20] — now
mid-W3.2 "re-envelope" arc): its proof-library structure and lessons
— what tactic/lemma layers it built, where it ground instead (their
records/audits say), the Audit.lean pattern extensions, proof-size
discipline if any; PLUS the fresh W3.2 material: their iris-lean
upstream delta-scan recon (the S0(a) method donor) and the recorded
operator rulings on when/how their iris pin moves — the sibling
project is solving our exact pin-bump question, lift the reasoning.
Output: survey doc + a GAP MATRIX — needed capability × source
(already-in-iris-lean / brick-wp-design-lift / golean-pattern /
build-new), committed. No tactics written in S0.

**S1 — the plan (design doc, a real one).** From the matrix: the
tactic set with NAMES and CONTRACTS (what goal shape in, what out),
the library layering (iris-lean primitives → Cerberus step/eval layer
→ walkers/automation), file structure under relsem/, the loop story
(invariant rule proved from the existing app-equation layer + Löb or
iris-lean's fixpoint machinery — decided by the S0 findings), the
PROOF-SIZE BAR (concrete: e.g. max N tactic lines per slate proof,
measured in the audit), and the graded example slate (S3) with a
fixture recipe per example. Committed and flagged to the operator in
the arc record; the arc proceeds autonomously unless a tripwire
fires (the operator may of course redirect at any checkpoint).

**S2 — first wave: minimal tactics + T5.** Build ONLY what T5 needs
per the plan (the loop-invariant rule + the basic walker/step
tactics). T5 stated over the pinned t5_sum fixture (statement style
identical to T1-T4: ∀-quantified, interpreter-only, CallHarness
form), proved through the new machinery. T5's proof is the first
measurement against the size bar.

**S3 — the graded slate + the improvement loop.** Several further
examples chosen in S1 for DISTINCT reasoning demands — candidates:
nested/sequential loops, loop over a struct/array (memory + invariant
interplay), early exit (break/return from loop), two-function call
composition (the brick-wp call-bridge idea), and as a stretch one
real-code cameo (a chvalid predicate). Per example: C fixture +
pinned Core + differential expectations (test_verify pattern) +
theorem + proof. THE LOOP RULE OF THE ARC: when a proof exceeds the
bar or grinds, STOP — extract the missing rule/tactic, add it to the
library with contract + test, REDO the proof short. Tactic changes
re-run the whole slate (regression = the improvement is wrong).

**S4 — consolidation + close-out.** Library docs (every tactic:
contract, example, provenance tag — iris-lean-reused /
brick-wp-lifted / golean-pattern / novel); proof-size audit tallies
per slate proof (verbatim); results doc, decision log, 2-agent
adversarial audit — mandatory scopes: (a) REUSE HONESTY: did we
reimplement anything iris-lean already had (each build-new matrix
entry re-justified); (b) attribution fidelity (brick-wp/golean cites
against the cited code); (c) grind honesty: proof-size tallies real,
no bar-gaming (e.g. mega-lemmas hiding steps); (d) soundness: every
new rule's proof traces to the adequacy chain, cones re-pinned clean,
statement gate untouched. Fix-or-record; merge checklist. Stop. Do
not merge.

## Success conditions (machine-checkable)

1. T5 proved: ∀-quantified, interpreter-only, cone exactly [propext,
   runEffectful, Classical.choice, Quot.sound]; fixture differential
   green in test_verify.
2. ≥3 further slate examples (incl. at least one nested/compound loop
   and one call-composition case) proved likewise, each within the S1
   proof-size bar (tallies verbatim in the results doc).
3. The gap matrix exists and every build-new entry carries a recorded
   why-not-iris-lean justification (audit-verified).
4. Library documented per S4; tactic regression suite green (the full
   slate re-proves on every library change; wired into the arc's gate
   runs).
5. Zero lem changes (else full pin dance); standing gates green at
   every commit; differential surface zero movement; statement-TCB
   gate and arc-8 absence gates untouched-green.
6. Records complete; branch gate-green; merge checklist ready;
   mainlines untouched.

## Risks / pre-declared calls

- IRIS-LEAN MATURITY GAPS / PIN BUMP: the pinned rev may lack pieces
  the new head has (ProgramLogic #666 and wp_rec #657 look directly
  relevant). S0 prices the bump; if recommended, it lands as its OWN
  early commit (lakefile rev + lake update + full re-gate incl. the
  arc-7 adequacy/T1-T4 stack re-elaborating clean) BEFORE tactic work
  builds on either rev — never mid-arc under proof churn. Local
  additions to our tree remain the fallback (clearly marked
  candidate-upstream). Never fork-and-diverge silently. NOTE for the
  operator items list: deps/mirrors still lacks an iris-lean.git
  mirror (network window item, pre-existing).
- LOOP-RULE SOUNDNESS is the delicate center: it must be proved from
  the existing Machine/RunND semantics, not assumed. If the app-
  equation layer resists a clean invariant rule, that is a DESIGN
  finding for the record (and possibly a Machine.lean refactor
  decision), not a grind-through.
- Example ratholes: per-example park clause — a slate entry that
  resists after the stop-extract-redo loop is parked with pricing;
  the arc does not stall on one example.
- Stack ceiling (register): slate loop bounds chosen well under
  ~1.5k iterations; the ceiling itself stays a register item (NOT
  this arc's scope).
- Proof-size bar gaming: audit scope (c) exists precisely for this.

## Autonomy protocol

As arcs 4-8: workers commit (green gates only, one coherent commit
per slice, verbatim outputs), orchestrator scopes and independently
verifies at every boundary, decision log with [USER]/[AGENT]
provenance, capped builds only, merge lives with the operator
(unconditional audit ask). S0/S1 want a Fable-grade worker (survey +
design quality is the arc); S2/S3 Fable for tactic/rule work;
mechanical fixture batches may use Opus. EMERGENCY EXIT always
permitted, nature declared. Tripwires: loop rule unprovable without
axioms; iris-lean reuse impossible without a pin bump (flag, don't
bump unilaterally); any gate keepable-green only by weakening;
machine-global state.
