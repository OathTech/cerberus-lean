# Arc 17 — the automation framework (Iris refounding, part 2)

STATUS: BLESSED [USER 2026-08-24]: "Go ahead and launch the arc." ORIENTATION [USER
2026-08-24, verbatim]: "Our main line is building a scalable proof
automation framework inside Iris for theorem proving use. Ultimately,
we want to be able to verify libxml2 via this framework. CN is a kind
of nice convenience, but the core of this is building a clean,
well-structured automation / tactic library using the powerful
affordances offered by iris-lean and ideas from our inspiration in
other academic work." Standing pressures embedded throughout: DOWN-
PRESSURE ON PROOF LENGTH as automation grows ([USER], at the part-1
merge); the grind ban (structure over kernel volume); canon-first +
reuse discipline + trick filter (lineage sentences per mechanism).

Inputs: part-1's measured prices (S0-S4 records), the S4 "what
remains expensive" analysis (THE EQUATION SUPPLY is the bottleneck,
not the tactic layer), the T4 apartness diagnosis, the ACL2Lean donor
review (notes/2026-08-24_acl2lean-donor-review.md), the whole-project
audit's purge inventory, the arc-15 spec-lab statements awaiting
family-∀.

## The mission in one sentence

Make the per-construct machinery FIXTURE-INDEPENDENT and the
discharge engine STRUCTURED-AND-CHEAP, until a libxml2 function's
theorem costs its loop invariants and contracts — nothing else.

## Slices

- **S0 — the discharge-engine substrate** (ACL2Lean-shaped; lineages
  per the donor review). (a) `derive_state` named-constant emitter
  (the giant-terms fix; donor's derive_world pattern; S). (b)
  `proveByDecide`-style memoized ground-fact discharger wired as the
  wp-tactics' side-condition engine (LIFT, S). (c) The trace/
  certificate format spec for automation results (proof-producing,
  NOT monolithic-derivation reflection — the donor's ratified
  invariant is our constraint; S, spec only this slice).
- **S1 — the equation-supply frontier** (the core slice): per-
  construct, fixture-independent law completion — whole-loop and
  call-structure equations derived from construct shape rather than
  per-fixture chains (the S3 label-resolution twins and the S4
  round13/round21 twins are the test cases: they should DISSOLVE
  into construct laws). Lineage: decompilation-into-logic (Myreen) —
  elaboration's stereotyped shapes → derived rules. Acceptance
  probe: a NEW small fixture (never seen by any law) proved with
  ZERO fixture-specific equations.
- **S2 — T4-threaded via apartness** (the M-priced fix): the
  seed-apartness hypothesis (kernel-computable), the ordered-map
  env-algebra lemma layer (a reusable library — most struct-store
  programs need it), T4 re-proved at the guarded ∀-seed statement,
  trio cone. The guarded form's honesty: the statement carries the
  apartness hypothesis VISIBLY (it is true, and its necessity is
  kernel-witnessed — the S4 counterexample is the justification).
- **S2b — THE BOUNDARY-AXIOM ENDGAME** ([USER 2026-08-24]: "we
  definitely want to resolve the additional axiom uncertainty" —
  this slice CLOSES it, no residual ambiguity). Current state:
  threaded T1–T3 are trio-clean; the ambient family (retiring at
  S5) and the spec-lab statement substrate still wear
  `runEffectful`; `with_tagDefs`/`forceIO` are absent from every
  T1–T4 cone but exist as axioms in the tree (entering only via
  Mini_pipeline/Main compiled paths). Deliverables: (a) the
  spec-lab/harness statement substrate (HarnessRunsTo and the
  drive-quoting layer) moved to the threaded initial state so that
  EVERY statement-layer family in the repo is trio-clean — no
  statement anywhere quotes the ambient effect state; (b) each of
  the three axioms gets a FINAL DISPOSITION, executed: DELETED from
  the tree (its remaining consumers rethreaded — expected for
  `with_tagDefs`/`forceIO`, whose only consumers are driver-path
  code that can take the state explicitly; the digest/tagDefs
  threading priced S–M by the spike) or, where genuinely retained
  for the compiled/differential path (candidate: LemLib
  `runEffectful`, consumed by generated OCaml-parity code),
  re-justified in PROOF.md with a NEW GATE asserting no-cone-entry
  tree-wide (any theorem cone acquiring it is build-fatal, not
  merely unpinned); (c) the hand-written axiom census updated to
  the end state (target: 2 → 0 in this repo; LemLib's residual, if
  kept, carries its own lem-side justification + the no-cone
  gate); (d) PROOF.md §1 rewritten from "scheduled for
  elimination" to the achieved state. Exit condition: a reader of
  PROOF.md can answer "what axioms exist, where, why, and what
  guarantees they never touch a theorem" with zero uncertainty.
- **S3 — T5 BY INVARIANT** (the classics demonstration): the loop
  proved via a logical loop invariant + one body WP discharged by
  the S1 laws + iter_compose/löb — no round-walks. T5's statement
  lands; the proof-size gate's T5 row flips PENDING → enforced.
  This is the direct refutation-by-construction of the chase era.
- **S4 — spec-lab family-∀ endpoints**: the arc-15 sample-∀
  statements upgraded (R1 divmod + R5 swap first — scalar; then R2
  memcpy; R3/R4 as the env-algebra + invariant machinery allows),
  refutation schemas unconditional. Each endpoint re-measures
  proof-length (the down-pressure register).
- **S5 — THE PURGE** (one commit, after S2 lands T4-threaded and the
  ambient chains' consumers are re-founded): delete the chase
  surfaces per the audit inventory (~700K: AppWalk, WalkTrace,
  round-walk idiom, AppEq files, T5 walk scaffolding, instruments);
  freeze-gate allowlist empties; audit pins + proof-size gate
  re-registered; ambient T1-T4 retire in favor of the threaded
  family + labeled bridges dropped or inverted. Fresh grumpy pass
  over the post-purge tree.
- **S6 — THE LIBXML2 RUNG** (the graduation probe, scoped honestly):
  ONE uri.c function (candidate: a small RFC-3986 helper from the
  16/16 gate corpus) taken end-to-end through the framework —
  harness statement (template idiom), WP proof via S1 laws + S3
  invariants, measured cost. NOT "verify libxml2" — the probe that
  prices the ladder and exposes what the framework still lacks
  (expected: string/buffer idioms, the typed-view layer). Its
  report is arc-18's charter seed.

## The parity goal ([USER 2026-08-24]: aim for Lithium/Caesium parity)

The framework's named horizon: **RefinedC-grade automation** — a user
writes ONLY annotations (contracts, loop invariants, type/ownership
assignments); one entry-point invocation discharges the whole
function; failures surface as READABLE STUCK GOALS (the holes), never
tactic errors. Component ledger (distance measured at S6):
1. TYPED LAYER — typed views promoted from parked to load-bearing
   (user-facing goals speak types/rep predicates, not byte ranges);
   Caesium's typing layer is the donor.
2. GOAL-DIRECTED SEARCH — the one major un-chartered artifact (M–L,
   arc-18 centerpiece unless S6 demands it earlier): a single
   verify_fn entry point doing Lithium-style DETERMINISTIC,
   backtracking-free decomposition over the S1 rule registry
   (normal-form goals, unique-rule-per-step, find_in_context;
   the arc-9-era Lithium source review is the design map).
3. CONTRACTS AT CALLS — the override/summary layer (S1 laws + the
   summary library feed it; without it push-button stops at the
   first call).
4. COVERAGE + SIDE CONDITIONS — S1 construct completion + the S0
   decide/omega engines.
S6's libxml2-rung report MUST include the parity-distance table
(which of the four carried the rung's cost, and what a Lithium-grade
run would have cost instead). Arc-18's charter takes parity as its
success bar if the S6 numbers support it. [USER 2026-08-24]: parity
is A FLOOR, NOT A CEILING — "RefinedC isn't the end point, but it's
one of the best things out there. We want to at least meet this
bar." The ledger is a DRIVER for the build-out; exceeding the bar
(the kernel-certified trust story already does on one axis) is the
expectation, not the exception.

## Extension track (explicitly NOT main line; never blocks it)

CN-1+ (typed views are MAIN-LINE citizens wanted by S6 anyway; the
CN-specific elaboration CN-2+ waits), Fulminate lanes, spec-guided
fuzz. Chartered separately when main-line slices create their
prerequisites; no main-line slice may depend on extension work.

## Doctrine compliance

Lineage sentences: named per mechanism above (ACL2Lean architecture
verdict, Myreen decompilation, Floyd-Hoare/löb invariants, proof-
producing emission). Grind ban: every slice iterates small; the S1
acceptance probe is the anti-grind test (zero fixture equations =
nothing to grind). Statements stay fuel-opsem-only (gate-enforced);
the S2 apartness hypothesis is statement-visible, kernel-computable.
No budget bumps. Merges ff-only on per-merge sign-off; audit ask
unconditional; checkpoints on concrete objects are the operator's.

## Success criteria

1. S1's acceptance probe: an unseen fixture proved with zero
   fixture-specific equations.
2. T4-threaded + T5 landed, trio cones (T5 = workbench exit
   criterion finally discharged, by invariant not walk).
3. The purge: chase surfaces gone, gates re-registered, battery
   green, tree professor-clean.
4. The libxml2 rung report: one function's measured end-to-end cost
   + the priced gap list for arc-18.
5. Proof-length register: every slice's numbers, trend downward
   (the standing down-pressure made measurable).
