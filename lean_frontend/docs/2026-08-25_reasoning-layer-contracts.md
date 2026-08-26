# The reasoning-layer contracts (arc-18 C0)

STATUS: NORMATIVE. This document states each layer's contract with
the layer above it — what the lower layer GUARANTEES, what the upper
layer may ASSUME, and the gate that enforces it. It is the arc-18
charter's philosophy section made binding
(`docs/2026-08-25_arc18-coherence-charter.md`, operator-blessed
2026-08-25: Q1 DELETE the dormant peels/wpk laws, Q2 FULL
CerbMemInterp migration with exit ramp, Q3 one arc); future arc-18
slices cite this document, and changes to it are charter-level
changes. Where a contract is today enforced only by convention, it
appears in the REGISTER (§6) with the C-slice that closes it. §7 is
the retirement register: the written inventory the C5 extended purge
executes from. Sources: the charter; the design-coherence review
(container-side note, 2026-08-25 — its grep findings are restated
here where load-bearing and were re-verified against this tree,
branch `coherence` @ `f776804e3`, on 2026-08-25 [AGENT]).

**The trust chain, one sentence**: the fuel opsem — generated from
the same Lem model as the differentially validated OCaml oracle — is
both the semantic model and the statement language; everything above
it is proof infrastructure that discharges through adequacy and
appears in no statement and no cone beyond the three standard axioms
(`propext`, `Classical.choice`, `Quot.sound`).

Paths below are relative to `lean_frontend/`.

## 1. Layer 1: the fuel opsem (the TCB)

The generated model (`generated/`, from `.lem` via the lem Lean
backend) + the hand-written seams (CerbMem, CerbDecode, …) + the
fuel-totalized ND runner (`CerbND.lean`).

- **GUARANTEES (upward)**: every function on the execution path is
  total (fuel-indexed, loud panic at exhaustion) and pure (no hidden
  IO on the exec slice); generated definitions carry their
  definitional app-equations (the raw material every proof layer
  consumes); the built tree corresponds byte-for-byte to the model
  sources and to the reviewed fork surface; execution verdicts agree
  with the OCaml oracle across the differential corpora.
- **THE UPPER LAYER MAY ASSUME**: `runNDFuel`-family verdicts ARE the
  semantics referenced in statements; `driver_state` is the
  configuration type; unfolding a generated definition is sound
  (definitional) and never crosses an axiom.
- **GATES (all existing)**: `scripts/check_exec_purity.sh`,
  `scripts/check_exec_totality.sh`, the lem-sync content-hash gate,
  the hand-written↔generated sync gate, `scripts/check_fork_drift.sh`
  (all in `scripts/test_unit.sh`); the differential lanes + pinned
  baselines (`scripts/LADDER.md` tiers; a green build is not
  evidence — the baselines are the signal); the mirror-OCaml
  discipline for seams (audit-checked citations, not a build gate).

## 2. Layer 2: the KExpr per-step layer (the lockstep invariant)

`relsem/RelSem/PerStep.lean` (+ `PerStepIris.lean` for the Language
instance): configurations of the fuel opsem's own state; a reified
step relation (`KExpr`/`KStep`) whose every arm is premised on a
generated-code equation — *defined from* the semantics, never
axiomatized beside it.

- **GUARANTEES (upward)**: an iris-lean `Language` instance at the
  driver instantiation; the completeness theorem
  `ksteps_of_runNDFuel` (`PerStep.lean:431`) — every fueled run
  decomposes into ksteps — with cone `[propext, Quot.sound]` (pinned,
  `Audit.lean:700`).
- **THE UPPER LAYER MAY ASSUME**: WP reasoning over `KExpr` is
  reasoning about the executable semantics; no step exists in the
  relational layer that the runner cannot take, and none is missing
  (completeness).
- **GATES**: soundness drift is build-fatal by construction (the step
  arms and the completeness proof elaborate against the generated
  definitions — a generated-surface change that breaks the
  correspondence breaks the build); the cone pin. **CONVENTION-ONLY
  residue**: the lockstep *coverage* obligation — any change to the
  generated step surface re-proves completeness in the same commit,
  and new step forms must be added to `KStep`, not worked around —
  is a stated invariant with no dedicated gate (→ R1).

## 3. Layer 3: THE ONE ROUTE (adjudicated by the charter)

Three sub-contracts. This is the layer the coherence arc
consolidates; current-state vs target is stated honestly per
sub-contract.

### 3a. State interpretation: `CerbMemInterp` (target; Q2 FULL)

- **TARGET**: the heap RA (`CerbHeapRA.lean:187 CerbMemInterp`,
  GenHeap byte points-to + allocation ghost map + rest cell,
  `CerbHeapWP.lean` op rules, own adequacy `kAdequateHeap_of_wp`) is
  the SOLE state interpretation; proof-level assertions abstract over
  unmodified heap (footprint points-to + framing, never flat
  whole-heap enumerations).
- **LANDED (C2, 2026-08-25)**: `CerbMemInterp` IS the live route's
  sole interpretation. The T1/T2/T3 threaded walks are re-derived
  over it (equation supply in OPEN-MEMORY form — `∀ bm am` at the
  rest decomposition, memory reads as pointwise footprint facts; the
  walk substrate is `CerbHeapWalk.lean`); statement texts and cones
  byte-stable throughout. The disentanglement moved the OwnP
  interpretation out of the live route into the transitional
  `PerStepOwnP.lean` (C5-bound; the arc-7 shell + ambient family +
  smokes consume it through the `IrisState.lean` shell). FRAMING IS
  DEMONSTRATED IN LANDED THEOREMS: T1/T2's driver-loop step consumes
  only the argument objects' footprints (the errno fragments ride
  the frame across the whole loop); T3's loop runs a scratch object's
  entire lifetime inside one rule (`wpk_seq_scratch1` — the fragment
  minted and consumed internally, dead bytes out as D2 capital).
  LABELED EXEMPTION with named mover: `T6Probe.lean` stays on the
  transitional surface — its equation supply is EVALUATOR-MINTED and
  `derive_rounds`' side-fact discharge is ground-eval against closed
  maps; mover = the RoundEval OPEN-MEMORY MINTING MODE (map reads
  through the registered read-over-write laws / the `assuming` pack),
  C3/arc-19 territory. Gate: `scripts/check_one_route.sh` (→ R2,
  CLOSED).

### 3b. Equation supply: the evaluator mints

`DeriveState.lean` (named-state emitter) + `RoundEval.lean` (the
law-driven round evaluator).

- **GUARANTEES (upward)**: named per-round/per-stage `app` equations
  and named states, minted by applying REGISTERED laws
  (`ConstructLaws.lean`, the `Kit/{Round,Mem,Env,Map,Loop}` kits);
  every minted declaration is kernel-checked at `addDecl` — the meta
  layer shapes claims, never certifies them; anything unmintable is a
  TAGGED FRONTIER, fail-closed, never a silent skip.
- **THE UPPER LAYER MAY ASSUME**: minted equations are ordinary
  theorems consumable by name; frontier tags enumerate exactly what
  is missing.
- **STANDING RULE (the engine-to-law rule, charter §1)**: the
  evaluator is a THIN LAW-APPLIER — any mechanism encoding semantic
  knowledge that fires twice becomes a registered law; the engine's
  line count is a watched metric under down-pressure
  (`RoundEval.lean` is 3383 lines today — the decomposition executes
  in C1). Convention-only today (→ R3).

### 3c. Consumption: the wp-tactic layer, registry as the interface

`PerStepTactics.lean` (`wp_step`/`wp_pures`/`wp_seq`/`wp_done`) +
`WpGround.lean` (`wp_side`→`wp_ground`); loops enter through
`iter_compose` (`Kit/Loop.lean`) — invariant-family composition at
the equation calculus (Floyd–Hoare-shaped, honestly named: not löb).

- **GUARANTEES (downward/upward)**: the tactic layer consumes minted
  equations and registered laws ONLY — no semantic knowledge lives in
  tactic code; extension happens at named hooks, not engine edits.
- **TODAY**: there is no queryable registry — RoundEval dispatch and
  `wp_side` consume `Kit.*`/`Laws.*` lemmas by hardcoded name; the
  only mechanically indexed vocabulary (`@[app_eq]`, DiscrTree) is
  consumed solely by the frozen walker; `ConstructLaws.lean` has
  registry discipline (shape docstrings, trace schemas, fixture-free
  gate) but no machine-readable index; unique-rule-per-goal-form is
  unenforced (→ R4).
- **TARGET**: the C1 attribute-indexed registry (AppEqAttr DiscrTree
  machinery as in-house donor; entries carry goal-form key, law kind,
  side-condition class, frontier tag, trace-atom schema, lineage
  tag); dispatch consults the registry; arc 19 searches over it.

## 4. Layer 4: threaded adequacy

`PerStepIris.lean:252 kAdequate_of_wp` (OwnP form; retires with the
C2 migration) and the heap-RA adequacy (`kAdequateHeap_of_wp`,
arc-16 S2 — the survivor).

- **GUARANTEES (upward)**: a WP proof at the initial state yields a
  statement mentioning ONLY the fuel opsem and the program, with cone
  exactly the classical trio; adequacy hands the closed harness its
  initial footprint (the initial big-sep — the HeapLang precedent).
- **THE STATEMENT LAYER MAY ASSUME**: no Iris vocabulary, no
  relational vocabulary, and no effect axiom survives into any
  threaded statement or cone.
- **GATES (all existing, in-build)**: the theorem-axiom cone pins
  (`#guard_msgs` in `relsem/RelSem/Audit.lean` +
  `scripts/check_theorem_axioms.sh` incl. the ofReduce* ban); the
  `runEffectful` no-cone-entry gate (exact 114-name ambient carrier
  pin, both directions); the boundary-opaque gate
  (with_tagDefs/forceIO stay opaques, never axioms); the DAEMON
  absence gate.

## 5. Layer 5: the statement vocabulary

Boring, executable, fuel-opsem-only statements (the harness
doctrine): faces today are the ambient call faces
(`relsemcore/RelSem/Call.lean:322 CallHarnessAdequate`, `:369
CallHarnessUBFree`), their threaded twins
(`relsem/RelSem/Threaded.lean:82/95`), the spec lab's whole-program
`HarnessRunsTo` (`speclab/SpecLab/DivModFiles.lean:144`, defined once,
shared), per-fixture wrappers, and T4's guarded `T4SeedApart` face.

- **GUARANTEES**: statements use only executable first-order
  vocabulary; guarded faces carry their hypotheses visibly with
  kernel-witnessed justifications; SL-in-statements stays a governed,
  per-instance operator decision.
- **GATES (existing)**: the statement-TCB gate (`Audit.lean` slate
  list, negative-tested in-build), `scripts/check_speclab_statements.sh`,
  `scripts/check_proof_size.sh` (mega-lemma counter + the
  40-manual-step floor).
- **TARGET VOCABULARY (post C4/C5, one sentence)**: a semantics-side
  threaded initial state + two faces — `HarnessRunsToThr`
  (whole-program, primary) and `CallHarnessAdequateThr` (the labeled
  function-call slate idiom) — with UBFree/Outcomes as derived forms
  and ambient faces deleted or inverted to labeled corollaries.
- **CONVENTION-ONLY residue**: ~~the Thr faces live in the PROOF
  package although they are statement vocabulary — the one-way
  semantics→verification seam therefore blocks speclab from using
  them~~ (R6 CLOSED at C4: the faces are semantics-side, speclab
  quotes them — the 46 statements + 15 lemmas are threaded and
  trio-clean); `T4ThreadedStatement` is landed but absent from the
  statement gate's slate list (→ R5).

## 6. REGISTER: contracts enforced only by convention (work items)

Each row is a real contract with no gate today; the named slice
closes it (per the blessed charter's slice plan).

| # | Convention-only contract | Closed by |
|---|---|---|
| R1 | Lockstep COVERAGE: generated-step-surface changes re-prove `ksteps_of_runNDFuel` in the same commit; new step forms extend `KStep`, never bypass it | C6 (playbook merge-invariant; gate feasibility assessed at C5 re-registration) |
| R2 | Single-interpretation discipline: no file binds both `CerbGS` and `CerbHeapGS` (the S2 coexistence hazard) | **CLOSED at C2** — `scripts/check_one_route.sh` (in `test_unit.sh`, fail-closed, plant-tested both directions): live-route modules OwnP-free (imports + comment-stripped tokens), no both-binding file anywhere, OwnP binders confined to the retirement register + the labeled T6 exemption (mover: RoundEval open-memory minting). Record: `docs/2026-08-25_arc18-c2-one-route.md` |
| R3 | Engine-to-law rule + engine-size down-pressure: RoundEval stays a thin law-applier; semantic mechanism firing twice becomes a registered law | C1 (decomposition + registry dispatch); watched-metric row maintained from C1, summarized C6 |
| R4 | Registry as the law interface: law applicability determined by registry key, not hardcoded dispatch; unique-rule-per-goal-form; frontier-tag/trace-schema fields machine-readable | C1 |
| R5 | Statement-gate completeness: every landed statement face is on the slate list (`T4ThreadedStatement` currently absent, annotated as parked) | C3 attempted, REMAINS OPEN (the T4 theorem did not complete: the anon-env fence-over-materialized route re-measured failing under the C3 engine; the adjudicated route is the T5 builder architecture — `docs/2026-08-25_arc18-c3-theorems.md` §4). Closes when the T4 theorem lands |
| R6 | Statement-face homing: threaded faces defined semantics-side (MOVE, not mirror — the mirror doctrine forbids a duplicated initial-state def) | **CLOSED at C4** (2026-08-26) — `RelSem.Threaded` MOVED to `relsemcore/RelSem/Threaded.lean` (root package, RelSemCore lib; module name and every declaration name stable; the proof package imports it); the whole-program primary face `HarnessRunsToThr` + `specifiedInt` homed beside the call faces; speclab statements quote them across the one-way seam under exact-name gate allowlists (SpecLabAudit `slAllowedSemanticsSide` + the check_speclab_statements.sh two-line-form carve-out). Record: `docs/2026-08-26_arc18-c4-statement-homing.md` |

## 7. RETIREMENT REGISTER (the C-series freeze addendum)

The written inventory the C5 extended purge executes from — no
rediscovery at purge time. NO deletions happen in C0; this register
only. Dependents were verified by grep on this tree (2026-08-25,
`coherence` @ `f776804e3`) [AGENT]; line references cited where a
dependency is load-bearing. Q1 [USER]: the dormant peels/wpk laws are
DELETE, not keep.

### Entry 1 — the arc-7 whole-run route → retires at C5

Surfaces: `relsem/RelSem/IrisLang.lean`, `IrisState.lean`,
`IrisRules.lean`, `IrisAdequacy.lean`, `SlateWP.lean`.

Dependents today: ambient `T1.lean:31` (imports IrisAdequacy),
`T2.lean:25`/`T3.lean:19`/`T4.lean:51` (import SlateWP) — the ambient
family falls with it at C5; `RelSemAll.lean`, `Audit.lean` imports +
pins. **LIVE wrinkle RESOLVED at C2 (2026-08-25)**: the OwnP surface
(interpretation defs + lifting + seq rules + adequacy bridges + OwnP
step macros) moved name-stably into the transitional
`PerStepOwnP.lean`; `IrisState.lean` is now a shell importing it (the
arc-7 route resolves the same names through the shell), `DriveVal`
moved to the live language core, and NO live module imports the
shell (gate: `scripts/check_one_route.sh`). C5 deletes
`PerStepOwnP.lean` + the shell with the ambient family.

### Entry 2 — the dormant arc-16 half (Q1: DELETE) → **EXECUTED at C2
    (2026-08-25, commit 068fe11c5)**: PerStepPeel.lean +
    PerStepLaws.lean deleted wholesale; pins/carrier rows/lakefile
    re-registered in the deleting commit (carrier 114 → 112, sweep
    −161); PerStepRunner retained (generic runner algebra,
    zero-consumer — flagged for C5's sweep). Original entry follows.

Surfaces: `relsem/RelSem/PerStepPeel.lean` (the `dnmsK`/`driver2K`/
`callK2` loop peels) + the 12 `wpk_round_*` laws and the
`kCallHarnessAdequate_of_wpK2` bridge (`PerStepLaws.lean:719`) in
`PerStepLaws.lean`.

Dependents today: `RelSemAll.lean:44-45`, `Audit.lean:165-166` +
pins, `PerStepTacSmoke.lean` (itself entry-4 debt). **LIVE wrinkle**:
`PerStepTactics.lean:37` (the live tactic layer) imports
`PerStepLaws` and its `wp_seq` macros consume `wpk_seq_active_proj`
(`PerStepLaws.lean:99`) and `wpk_seq_active_ecast`
(`PerStepLaws.lean:84`) — those two seq laws are NOT dormant and must
be re-homed (natural home: `PerStepIris.lean` beside `wpk_done`)
before the file is deleted. Gate consequence: `wpk_round_*` names and
`kCallHarnessAdequate_of_wpK2` sit on Audit pin lists / the 114-name
carrier pin — re-registered in the deleting commit. Archive: the
arc-16 S3 record; the cmm arc re-derives per-round ND granularity
against the C1 registry when genuinely needed.

### Entry 3 — the chase corpus → retires at C5 (AppEqAttr ruled at C1)

Surfaces: `relsem/RelSem/Tactics/AppWalk.lean` (2435 lines),
`Tactics/WalkTrace.lean`, `Tactics/AppEqAttr.lean`, the round-chain
lemma files `T1AppEq.lean`/`T2AppEq.lean`/`T3AppEq.lean`/
`T4AppEq.lean`, the T5 walk scaffolding `T5Prefix.lean`/
`T5Iter.lean`/`T5Fixture.lean`, `bench/WalkBench.lean`,
`test/Unit/AppWalkTest.lean`, the `t5-probe` exe
(`test/Unit/T5ProbeMain.lean`).

Dependents today: the ambient T1–T4 + `T4Defs.lean` import the AppEq
lemma files (fall together at C5); `PerStepSmoke.lean:31` imports
T1AppEq (entry-4 debt); the freeze gate's 8-file allowlist
(`scripts/check_chase_freeze.sh`) IS this entry's enforcement
boundary and empties at C5 (the gate then retires or is repurposed).
**LIVE wrinkles**: (a) `T4Threaded.lean:33` — a live threaded
flagship — imports `T1AppEq` for proved equation lemmas; C3 (T4
completion on the consolidated substrate) must leave its equation
diet entirely evaluator/registry-minted before C5 deletes the file.
(b) `Tactics/AppEqAttr.lean`: the DiscrTree attribute machinery is
the C1 registry's in-house donor — C1 rules evolve-vs-delete; the
proved lemmas under `@[app_eq]` survive only by re-registration in
the C1 registry (the attribute index has no non-walker consumer:
`appEqMatches` appears only in `AppWalk.lean`, verified).

### Entry 4 — the ambient family + its bridges and faces → C4/C5

Surfaces: the ambient theorem family — the exact 114-name
`runEffectfulCarriers` pin (`Audit.lean:1035`) — plus
`PerStepSmoke.lean`, `PerStepTacSmoke.lean`, the `_of_wpK2` bridges
(entry 2), and the ambient statement faces: `CallHarnessAdequate`
(`relsemcore/RelSem/Call.lean:322`), `CallHarnessUBFree` (`:369`) —
deleted or inverted to labeled corollaries at C5 — and speclab's
ambient substrate (`HarnessRunsTo`,
`speclab/SpecLab/DivModFiles.lean:144`, + 46 statements and 15
lemmas), re-landed THREADED at C4 (after the R6 homing).

Gate consequences at C5 (same commit as the deletions): the
no-cone-entry gate's carrier set driven to EMPTY (`runEffectful`
survives only lem-side, consumed by zero theorems); the statement
gate's slate list re-registered; the proof-size gate's slate file
list re-registered; the freeze allowlist empties.

### Non-retirements, for the record

`CerbHeapRA.lean`/`CerbHeapWP.lean` (the heap RA) is the SURVIVING
interpretation — C2 makes it load-bearing; `CerbHeapDemo.lean`'s
framing demo graduates into (or is replaced by) a real framing
theorem at C2. `PerStep.lean`/`PerStepIris.lean` (minus the OwnP
binding surface), `PerStepTactics.lean`, `WpGround.lean`,
`DeriveState.lean`, `RoundEval.lean` (decomposed at C1),
`ConstructLaws.lean`, and the `Kit/` modules are the one route and
stay.

## 8. Success bar (restating the charter, for slice audits)

Post-C5: ONE step-machinery (KExpr per-step + evaluator supply), ONE
state interpretation (`CerbMemInterp`), ONE statement family
(threaded, semantics-side) + labeled derivations; the coherence
review re-run as the audit instrument; every gate re-registration
lands in the deleting commit, never after.
