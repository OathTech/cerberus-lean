# Arc-18 C1 — THE ONE REGISTRY + the RoundEval decomposition + the stash salvage (record)

Slice C1 of the coherence arc
(`docs/2026-08-25_arc18-coherence-charter.md`, blessed [USER
2026-08-25]). Closes register rows **R3** (engine-to-law rule +
engine-size down-pressure) and **R4** (registry as the law interface)
of the contracts doc (`docs/2026-08-25_reasoning-layer-contracts.md`
§6); executes the C0 register's AppEqAttr adjudication (contracts §7
entry 3). Worker: [AGENT], worktree `cerberus-lean-coherence`, branch
`coherence`, base `10986b89e` (C0). Five commits, each gated
(relsem + speclab capped builds, test_unit 7/7, test_verify 35/35).

## 1. THE ONE REGISTRY (`RelSem/LawRegistry.lean`)

The reasoning layer's single law interface (contracts §3c). Lean-only
imports (laws import the registry, never the reverse; the engine may
not contain semantic knowledge — the three-layer separation).

**Entry schema** (`StepLaw`): `{name, keys (goal-form DiscrTree path
over the conclusion — the LHS when Eq-shaped; metavariable-telescope
wildcards), kind (dispatch lane), variant (discriminator within a
shared goal form), side (side-condition discharge route: rfl | decide
| ground | omega | hyp | fed | wp_ground-class), frontier (fail-closed
tag), trace (the S0 trace-atom schema — arc-19's search consumes this
field), lineage (canon-first sentence), prio (key depth)}`.
Registration is `@[step_law (kind := …) (side := …) (trace := "…")
(lineage := "…") …]` — required fields fail-closed.
UNIQUE-RULE-PER-GOAL-FORM (the RefinedC hint-mode lesson) enforced at
registration (same keys+kind+variant = error) AND consumption
(`queryUnique` ambiguity = error). Query API: `query`/`queryUnique`
(reducible-transparency matching — see §4)/`byKind`/`byName?`/
`allLaws`/`keyHeads`. Instruments: `#step_law_census` (output PINNED
in Audit — population drift is build-fatal) + `#step_law_lint`.

**Population — 46 laws, census-pinned** (`Audit.lean`
`step_law census: 46 laws [advance 4, construct 8, envAlg 3, envMap
3, heapWP 4, loop 2, memBlock 5, memRW 7, perform 5, roundGlue 3,
wpSeq 2]`):

| kind | laws | home |
|---|---|---|
| construct | seu_read_bind, erun_jump_m, ndct_offer1, driver2_done, inject_ptr_arg1, callND_errno, get_ths_eq, driver_update_ts | ConstructLaws.lean |
| advance | advance_tau_misc, advance_runstate_eval, advance_runstate_tau_misc, advance_action_request | Kit/Round.lean |
| perform | perform_create/load/store/seqrmw/kill | Kit/Round.lean |
| roundGlue | dnms_round (variant generic), dnms_round_computed (computed — the C1-salvaged face), dnms_terminal (terminal) | Kit/Round.lean |
| memBlock | mem_alloc/store/load/prefix/kill_block | Kit/Mem.lean |
| memRW | writeBytesTo_{allocations,deadAllocations,funptrmap,lastUsedUnionMembers} (proj*), readBytesFrom_congr_bytemap (congr), readBytesFrom_writeBytesTo_disjoint (frame), _hit (hit) | Kit/Mem.lean (C1 salvage) |
| envMap | fmapAddBy_built (built), fmapLookupBy_addBy_eq (hit), _ne (skip) | Kit/Map.lean |
| envAlg | fmapLookupBy_addBy_mk (base), _apart (skip), _self (hit) | Kit/Env.lean |
| loop | iter_compose (from0), iter_compose_from (fromN) — degenerate keys BY DESIGN (the invariant family heads the conclusion): never goal-form-dispatched, the human names the invariant; entries exist for the census + trace vocabulary | Kit/Loop.lean |
| wpSeq | wpk_seq_active_ecast (ecast), wpk_seq_active_proj (proj) | PerStepIris.lean (re-homed) |
| heapWP | wpk_load/store/alloc/kill (load/store/alloc/kill) | CerbHeapWP.lean |

**The wpk re-homing** (the C0 register's live-wrinkle finding):
`wpk_seq_active_ecast`/`_proj` — the two NON-dormant laws of the
Q1-DELETE file — moved `PerStepLaws.lean` → `PerStepIris.lean`
(statement text byte-identical, same `RelSem.Cerb` names, the Audit
cone pins untouched), registered as the wpSeq lane. ADJUDICATION NOTE:
the brief's "re-home into the registry" is realized as
registered-entries-hosted-in-PerStepIris — the registry is an INDEX
(Lean-only module), not a home for Iris-typed laws; the deletion goal
is met: PerStepLaws.lean now carries ONLY the dormant arc-16 half and
deletes wholesale at C2 (an in-file banner marks it).

**AppEqAttr disposition (C0 register entry 3, adjudicated here):
LIFT-AND-FREEZE.** The DiscrTree mechanism (metavariable-telescope
keys, scoped env extension, specificity order, ambiguity-is-error,
the enumerable `all` table, the lint) is LIFTED into LawRegistry as
its donor; `Tactics/AppEqAttr.lean` and every `@[app_eq]` tag stay
FROZEN IN PLACE (chase-freeze gate unchanged) and delete with the
chase corpus at C5. The proved lemmas under `@[app_eq]` that the one
route consumes are now ALSO `@[step_law]`-registered (Kit/Round,
Kit/Mem) — the survival-by-re-registration the C0 record required.

## 2. The RoundEval decomposition (R3's structural half)

The 3,586-line monolith (arc-17 growth; review F8, the
recurrence-risk locus) split along its natural seams; each module
header carries its ABSTRACTION SENTENCE (what knowledge may live
there); `RoundEval.lean` is the umbrella (public interface unchanged).
Code carried verbatim apart from `private` removed at new module
boundaries.

| module | lines (C1 close) | abstraction |
|---|---|---|
| RoundEval.lean | 87 | umbrella + module map |
| RoundEval/Core.lean | 329 | expr/ground primitives, hooks, budget scoping, **registry dispatch** (queryLaw/qStar/appGoalSkeleton) |
| RoundEval/Hyp.lean | 818 | the hypothesis-threading mode (pack, directed rewriting, provers, hyp_norm_side) |
| RoundEval/Mint.lean | 248 | anchor discipline + kernel emitters (fail-closed addDecl) |
| RoundEval/Classify.lean | 166 | candidate collection + the .all dig (head lists = classifier HEURISTICS, stated boundary) |
| RoundEval/Arith.lean | 681 | verdict engine + bridge lemmas (omega/kernel-decide/foldArith/towers) |
| RoundEval/Lanes.lean | 501 | minter lanes + dispatcher (mintCmpFact?; env/mem/decidable/bool lanes) |
| RoundEval/Rounds.lean | 732 | per-head round lanes + law-chain elaboration + anchoring |
| RoundEval/Assembly.lean | 566 | the derive_rounds command + whole-run artifacts + the piecewise chain |

**The engine-size watch** (`scripts/check_engine_size.sh` +
`scripts/engine_size_baseline.txt`, wired into test_unit.sh):
per-module counts vs a provenance-carrying baseline; WARN-level on
growth per the charter (the R3 register row carries enforcement);
exit-1 only on instrument breakage. Engine total at C1 close: **4,809
lines** (incl. DeriveState 260, WpGround 121, LawRegistry 300);
baseline history in the file (4,519 at decomposition → +189 dispatch
conversion → +101 piecewise assembler, each with its reason;
down-pressure direction recorded DOWN).

## 3. The dispatch conversion (R3/R4's mechanical half)

Every law the evaluator fires is now SELECTED by a registry query on
a goal-form key. Converted joints: tau/runstate/action ADVANCE
(the TSK_Misc/RSK kind checks fold into key matching — unregistered
shapes are registry-miss frontiers; the two runstate branches
collapse into ONE splice since which law fires is the key's choice),
PERFORM (per-request), MEM-BLOCK (per-op; the accessor-name and
field-index tables retired for structure metadata —
`getStructureFields`/`getProjectionFnInfo?`), env hit/skip/built,
memRW proj/congr/frame/hit, chain glue (generic/computed/terminal
variants), scheduler offer + driver-done iteration. Engine keeps only
slot PREPARATION (ground literals, spellings — elaborator handling
per the entry's declared schema). `queryLaw` (frontier on
miss/ambiguity) for the round lanes; `queryLaw?` (soft decline; the
consumer's frontier stays the fail-closed voice) for the minter
lanes.

**Two measured findings, baked into the design:**
1. `DiscrTree.getMatchLoop` KEY-REDUCES EVERY POSITION (star edges
   included) — a query carrying live state/payload ran whnfCore over
   execution spellings (T4 round-18 heartbeat timeout during
   bring-up). Dispatch goals are therefore SKELETONS: typed
   construction from the live pieces supplies the implicit-type-arg
   keys, then every non-discriminating position is a star (fresh
   mvar — keys as wildcard, never reduced; raw `mkAppN` replacement
   because `mkAppM` runs at a fresh MCtx depth and rejects outer
   mvars).
2. Registry queries run `withReducible` (ambient default transparency
   lets the tree's `unfoldDefinition?` delta plain defs).

**Engine-to-law sweep findings (the "fires twice" scan during
decomposition):**
* REGISTERED: the mem read-over-write lane's law population (was a
  hardcoded 4-projection + congr/frame/hit name table — now memRW
  entries + queries); the env lanes' laws (envMap entries); the
  chain/terminal/scheduler/driver law names (roundGlue/construct
  entries).
* RETIRED FOR METADATA (not semantic knowledge): the MemState
  accessor↔law and field-index tables (structure/projection info);
  the per-lane law-applicability head checks (now key matching).
* DOCUMENTED RESIDUE (in-code justification at
  `RoundEval/Arith.lean` boolHeadProp?): the Bool-bridge prop table —
  engine-adjacent bridge lemmas (nat_ble/blt/beq, natLtb-family,
  intLtb-family + dec_eq_isTrue/False) whose relational-Prop
  derivation needs premise-instantiation machinery arc-19's
  side-condition tracing builds anyway. Registered follow-up, priced
  S. Classifier head lists (registryBoolHead/registryDecHead/
  recLikeHead) stay as heuristics — which heads are WORTH TESTING is
  elaborator handling, not law selection (boundary stated in the
  Classify header).
* DEFERRED TO C2 (named in the census comment): the heap-rule MACROS
  (`wp_load` etc.) still name wpk_* laws in syntax — the laws are
  registered (heapWP); macro-side query conversion rides C2's
  restatement of the rules over CerbMemInterp.
* `wp_side` itself carries no name dispatch (it is the discharge
  chain `assumption | wp_ground | rfl` — exactly the registry's
  side-route vocabulary); per-law route data now lives in the
  entries' `side` fields, which is what arc-19's search consumes.

## 4. The stash salvage (the S3 post-park delta, assessed 1/3)

**APPLIED — the MEM FOOTPRINT PACKAGE** (cherry-picked hunks only):
* `Kit/Mem.lean` +126: the SL footprint primitives at bytemap level —
  writeBytesTo projection quartet, the pointwise
  writeFold_get?/writeBytesTo_bytemap_get? ladder, readBytesFrom
  congruence, and the read-over-write FRAME (disjoint) + exact-HIT
  laws (lineage: Burstall/Bornat independent-cell reasoning — the
  equation-calculus face of the heap RA's load-over-store rules).
* `Kit/Round.lean` +31: `dnms_round_computed` — the σ-computable dnms
  face (premises kernel-deferrable as Eq.refl hints; no elaborator
  unification against the scheduler computation).
* RoundEval: collectMintCands mem heads + MemState-proj candidates;
  the mintMemRW lane (+ groundIntLit?/listSpineLen?), wired after the
  env lane. Registered from birth at commit 2 (memRW kind).
  Gated: drive behavior byte-identical (T4 22 rounds same classes;
  T6 51 rounds + terminal).

**RE-DERIVED — the chain-capacity design** (the stash's remaining
~700 lines were debris; only the DESIGN re-lands, in
`RoundEval/Assembly.lean`): THE PIECEWISE CHAIN ASSEMBLER — the
relative (`chain` token) emitter rebuilt from the seed list: chain
ENDPOINTS TRACKED SYNTACTICALLY (the mint loop's own σ-ladder; no
inferType over state terms); ONE PIECE PER ROUND at the Expr level
through `dnms_round_computed` with every premise KERNEL-DEFERRED as
an Eq.refl hint (no stepAt-unification wedge, no monster single
elaboration, no midpoint unification — mkEqTrans joins endpoints
syntactically identical by construction); per-piece budget windows;
SIZE-GATED windowed diagnostics (a failing piece names its round and
endpoint sizes, printing terms only when small). SMOKE:
`T6Probe.lean` `rchain` — a 3-round partial drive with `chain`
emitting `rchain_chainrel` (the ∀-fuel iter_compose feed shape),
green first run. This is the C3 T5-composition substrate.

**STASH DEBRIS — READY TO DROP.** Everything else in stash@{0} (the
mintEnvLookup keyN/ofNatify probing, closeBoolTower privateness
churn, tryOmega trace, the old chain/assembly experiments) is
superseded by the re-derivation or was diagnostic scaffolding. The
orchestrator may `git stash drop stash@{0}` after this slice lands
(this worker did not drop it, per the brief). One salvageable IDEA
from the debris is noted for C3: raw `Expr.lit` numerals are omega
ATOMS — an `ofNatify` respell before omega discharge may be needed
when quoted-AST digests reach apartness goals (do not apply until a
frontier demands it).

## 5. R3/R4 closure statement

* **R4 CLOSED**: law applicability is determined by registry key at
  every RoundEval dispatch joint; unique-rule-per-goal-form enforced
  at registration and consumption; frontier-tag/trace-schema/lineage
  fields machine-readable on all 46 entries; the census is
  build-pinned. Residues (bool-bridge table S; heap-macro query
  conversion at C2) are named above with owners.
* **R3 CLOSED at the C1 bar**: the engine is decomposed into
  contract-headed modules; the engine-to-law rule is enforced
  culturally by the module headers + mechanically by the watched
  metric (check_engine_size in test_unit, provenance-carrying
  baseline, warn-level per charter); the C1 sweep registered or
  retired every found law table except the documented residue.
  The watched-metric row continues through C6's summary.

## 6. Validation + byte-stability attestation

Per commit (exit-checked; transcripts in the worker report):
relsem capped build green — ALL in-build gates (DAEMON absence,
boundary-opaque, statement gate 27, runEffectful no-cone 114 exact,
step_law census 46, axiom sweep with per-commit re-baselines
4712→4746→4830→4885→4890→4898, each provenance-commented in
Audit.lean; every re-baseline is registry/engine DECLS, never a
cone movement); speclab green (statement gate 46 clean);
`./scripts/test_unit.sh` "Total: 7 passed, 0 failed" + all gate
scripts OK (incl. the new engine-size watch); `./scripts/test_verify.sh`
"35 passed, 0 failed".

BYTE-STABILITY: no landed theorem's statement or cone pin moved in
any commit — every `#guard_msgs` cone pin in Audit.lean passed
VERBATIM throughout (the only pin edits are the two REGISTERED
instruments: the sweep COUNT re-baselines above and the new census
pin). The t6/T1-T3 threaded proofs and both evaluator drives
re-elaborate through the new module structure and registry dispatch
unchanged (T4Threaded: 22 rounds, identical class sequence;
T6Probe: 51 rounds + terminal, same artifacts). The sweep
re-baseline of +55 at the decomposition commit is per-module
compiler auxiliaries (match/eq lemmas no longer shared across one
module body), verified boundary-clean by the same sweep.

Driver paths untouched (relsem/scripts only) — the differential
baselines (exec/cn/immaculate/ci-sweep) are unaffected by
construction; test_verify's oracle differentials re-ran green as the
spot check.

## 7. Commits

| commit | content |
|---|---|
| cb6498790 | stash salvage: the mem footprint package |
| 7f966337f | THE ONE REGISTRY + 46-law population + wpk re-homing |
| 56e454621 | the RoundEval decomposition + engine-size watch |
| 174dc2992 | registry dispatch conversion (goal-form skeleton queries) |
| (this)    | the piecewise chain assembler + T6 smoke + this record |

## 8. C2 handoff

* PerStepLaws.lean is now dormant-only (banner in-file): C2 deletes
  it with the peels; re-register the Audit pins/carrier rows in the
  deleting commit (contracts §7 entry 2).
* The heapWP macro-side query conversion rides C2's CerbMemInterp
  restatement (census comment names it).
* The registry is arc-19's substrate as chartered; the trace fields
  are populated on all entries.
* No walls, no parks: all four C1 deliverables landed. The one
  registered follow-up (bool-bridge registration + query, S) is
  arc-19-adjacent, not a C2 blocker.
