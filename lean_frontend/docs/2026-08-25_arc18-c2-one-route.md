# Arc-18 C2 — THE ONE-ROUTE MIGRATION (record)

Slice C2 of the coherence arc
(`docs/2026-08-25_arc18-coherence-charter.md`, blessed [USER
2026-08-25]: Q1 DELETE the dormant peels/wpk laws, Q2 FULL
CerbMemInterp migration with exit ramp). Closes register row **R2**
(single-interpretation discipline) of the contracts doc
(`docs/2026-08-25_reasoning-layer-contracts.md` §6) and executes
retirement-register **entry 2** (§7). Worker: [AGENT], worktree
`cerberus-lean-coherence`, branch `coherence`, base `63f76ed4a` (C1).
Every commit gated (relsem + speclab capped builds with all in-build
gates, `test_unit.sh` 7/7 + gate scripts, `test_verify.sh` 35/35);
driver paths untouched throughout (relsem/scripts/docs only), so the
differential baselines are unaffected by construction — test_verify's
oracle differentials re-ran green at every commit as the spot check.

## 1. Migration verdict

**LANDED — CerbMemInterp is the live route's sole state
interpretation.** The T1/T2/T3 threaded families (headline +
UB-freedom + outcome-set theorems and their WP walks) are re-derived
over the heap RA; the OwnP interpretation survives only on a
transitional surface consumed by C5-bound legacy (arc-7 shell,
ambient family, smokes) and ONE labeled walk exemption (T6, §6 — the
measured obstacle is the equation-supply engine, not the adequacy
plumbing; the charter's exit ramp was NOT taken for the migration
itself). Statement texts and cones byte-stable throughout (§7).

## 2. The disentanglement (the C0 entry-1 live wrinkle, resolved)

The C2 preparatory surgery (commit `adfa9d6a8`): all OwnP surface
moved NAME-STABLY out of the live route into transitional
`RelSem/PerStepOwnP.lean` (C5-bound, header-labeled):

* from `IrisState.lean` — the interpretation itself
  (`CerbGpreS`/`CerbGS`/`stateIs`/`CerbS`); `IrisState.lean` is now a
  shell importing PerStepOwnP, so the arc-7 route resolves the same
  names with zero text edits;
* from `PerStepIris.lean` — the OwnP lifting + seq rules + adequacy
  bridge; `PerStepIris.lean` is now the INTERPRETATION-FREE language
  core (Language instance, inversions, erasure, `DriveVal` — moved in
  from the arc-7 `IrisLang.lean`, which now imports the live core:
  the dependence direction is shell → live only) with an
  interpretation-GENERIC `wpk_done`;
* from `PerStepCall.lean` / `Threaded.lean` — the OwnP adequacy
  bridges (ambient + threaded);
* from `PerStepTactics.lean` — the OwnP step macros + `wpk_ite_conj`;
  the tactic module keeps the interpretation-generic pieces
  (`wp_expose`/`wp_done`/`wp_side`) + the heap op-rule macros.

Sweep count unchanged at the disentanglement commit (pure moves).

## 3. The migration design (why the walks changed shape)

Under a footprint interpretation there is DELIBERATELY no resource
that pins the whole physical state — that is the entire point of
framing — so a whole-state `app` equation at one closed σ is
unusable above the adequacy plumbing. The migration therefore moves
the walks' equation supply to **OPEN-MEMORY form**: per-stage
equations `∀ bm am, app m (setMaps ρ bm am) = (NDactive v, …)` — the
two heap maps FREE VARIABLES at the rest decomposition, memory reads
entering as pointwise footprint facts (exactly what
`allocIs`/`pointsToBytes` fragments certify), memory writes as
`writeList` chains over the open maps.

**Measured feasibility (the C2 probes, run before any build)**: the
generated code never forces the heap maps except through the memory
lens — pure driver rounds and harness stages close by the IDENTICAL
`rfl` proofs at fully open `MemState`; load rounds route through
`Kit.mem_load_block` + pointwise facts. This is why the migration
cost stayed at M: the open-memory re-derivation is mostly the same
text with the maps generalized.

**The substrate** (`RelSem/CerbHeapWalk.lean`, all instances of the
S2 lifting skeleton `wpk_seq_res_det`; lineage HeapLang
PrimitiveLaws — one rule per footprint shape, the frame implicit):

| rule (ecast face registered, kind `heapWalk`) | footprint shape |
|---|---|
| `wpk_seq_rest` | rest-only step; EVERY heap fragment frames |
| `wpk_seq_read1` / `read2` | one/two-object read at any fraction; rest may move; everything else frames |
| `wpk_seq_alloc_store` / `alloc_store2` | object creation: mints `allocIs` + `pointsToBytes` by the frame-preserving updates, freshness from `MemInv` (never from the fixture) — the SL can't-happen pattern |
| `wpk_seq_scratch1` | a scratch object's WHOLE LIFETIME (create/store/load/kill) inside one atom: the fragment is minted by the insert and consumed by the delete (net unobservable); dead bytes out as D2 dead capital |
| `wpk_seq_get` / `wpk_get_done_pure` | mid-walk/terminal state reads: continuations consume the state only through rest projections, so successors/postconditions are uniform over the rest fiber |

plus the rest-patch algebra (`setMaps`/`patchRest`/`restOf`
decomposition — structure-eta `rfl`s), the factored ghost move
`interp_alloc_store`, `MemInv_alloc_store`/`MemInv_initial`, the
`CerbHeapS` closed functor bundle (HeapLangS template, indices 4-8 =
GenHeap bytes / alloc ghost map / rest cell), and the heap-route
threaded adequacy bridges `kCallHarnessAdequateThrHeap_of_wp` /
`kCallHarnessUBFreeThrHeap_of_wp` — the initial physical maps are
empty, so the client's entire initial capital is the REST HALF (the
`heap_adequacy` precedent at an empty initial heap). Walk macros
(`wp_rest`/`wp_get`/`wp_read1`/`wp_read2`/`wp_argobj`/`wp_argobj2`/
`wp_scratch1`/`wp_fin`) keep the walks at 11-13 lines.

**New construct law** (engine-to-law rule): `inject_ptr_arg2`
(ConstructLaws) — the two-scalar-argument caller protocol recurs, so
it is a registered law, not per-fixture text (census 46 → 47; the
T2 fixture consumed it at birth).

## 4. The framing dividend, DEMONSTRATED IN LANDED THEOREMS

Not a demo file — the landed flagship walks:

* **T1** (`t1_wpK_thr`, feeding `T1Threaded`): the driver-loop step
  (`driver2_o` → `wpk_seq_read1`) consumes exactly {rest half,
  `allocIs 0 allocXW`, `pointsToBytes xAddr (argBytes x)`} — the
  ERRNO object's fragments `HalE`/`HptE` ride the frame across the
  entire loop; the loop's characterization never mentions them.
* **T2**: the loop reads BOTH argument footprints (`wpk_seq_read2`);
  the errno fragments frame.
* **T3**: the loop consumes the argument footprint and runs the
  scratch local's create/store/load/kill INTERNALLY
  (`wpk_seq_scratch1`); the errno fragments frame, and the scratch
  allocation is unobservable outside the step (its `allocIs` is
  minted and consumed inside the rule — "double allocation is
  unconstructible" closing over itself); the dead bytes surface as
  `HptS` (D2 dead capital, unusable without a live `allocIs`).

## 5. The deletions (Q1; retirement-register entry 2, EXECUTED)

Commit `068fe11c5`. Deleted-not-lost: last commit carrying the files
is `63f76ed4a`.

| deleted surface | notes |
|---|---|
| `RelSem/PerStepPeel.lean` (784 lines: `dnmsK`/`driver2K`/`callK2` + `*_runner_eq`) | zero live consumers; the cmm arc re-derives per-round ND granularity against the C1 registry when genuinely needed |
| `RelSem/PerStepLaws.lean` (747 lines: 12 `wpk_round_*`, `wpk_ite`, `wpk_pcs_*`, the `_of_wpK2` adequacy bridges) | the two live seq laws were already re-homed at C1; `PerStepTactics` re-pointed its import |

Same-commit gate re-registrations: Audit pins for every deleted
surface removed; `runEffectful` carrier pin 114 → 112 (the two
`_of_wpK2` bridges); sweep re-baseline 4898 → 4737 (−161
declarations, provenance comment); lakefile roots pruned.
`PerStepRunner.lean` (generic runner-observation algebra) RETAINED —
now zero-consumer, flagged for the C5 sweep's adjudication.
`PerStepSmoke`/`PerStepTacSmoke` are register entry 4 (C5), not C2:
kept; TacSmoke's peel-wall section re-headered as a history note.

## 6. The T6 exemption (labeled, with the named mover)

`T6Probe.lean` is the ONE walk still on the transitional OwnP
surface. The obstacle is MEASURED and is in the equation-supply
engine, not the walk or the adequacy plumbing: T6's driver run is
minted by `derive_rounds` (51 rounds), and the evaluator's side-fact
discharge is GROUND-EVAL against closed maps
(`RoundEval/Rounds.lean` `evalGroundA`: allocation lookups, pointer
destructuring, byte reads whnf'd to literals) — at open maps those
reads are stuck terms. Hand-writing 51 open rounds would be exactly
the banned third grind species (manual where the automation is the
deliverable). NAMED MOVER: the **RoundEval open-memory minting
mode** — states carried as `setMaps` decompositions, map reads
resolved through the registered read-over-write laws (the memRW
lane: `tm_get?_insert_ne`, `writeList_get?_in/notin`,
`readBytesFrom_*`) or fed from the T4 `assuming` hypothesis pack;
natural home C3 (beside the T4 hypothesis-threading completion) or
arc-19's side-condition tracing, which owns the same machinery.
Migration recipe once the mode exists: the T1 pattern verbatim. The
exemption is carried IN the R2 gate (one labeled line) and in
T6Probe's header; T4Threaded binds no interpretation (no walk yet —
parked at C3's round-23 wall) and needs no exemption.

## 7. R2 closure + byte-stability attestation

**R2 CLOSED**: `scripts/check_one_route.sh` (wired into
`test_unit.sh`, fail-closed): (a) the 34 live-route modules carry no
OwnP/arc-7 import and no OwnP binding token outside comments
(comment-stripped scan); (b) no `.lean` file in the proof packages
binds both `[CerbGS]` and `[CerbHeapGS]` (the S2 §2.5 coexistence
hazard; `PerStepTacSmoke` labeled: its two smokes bind one route
each, in separate theorems, C5-bound); (c) OwnP binders anywhere are
confined to the retirement-register surfaces + the labeled T6
exemption — a NEW OwnP-binding file fails the build. PLANT-TESTED
both directions (transcripts in the worker report, all verbatim):
plant 1 (live module imports PerStepOwnP) FAILED the gate at the
planted line; plant 2 (non-comment `stateIs` use in Kit/Loop) FAILED;
plant 3 (a fresh both-binding file) FAILED; clean tree OK. The
contracts doc's R2 row is updated to CLOSED (rides this slice).

**BYTE-STABILITY**: no landed theorem's statement text changed —
`T1ThreadedStatement`/`T2ThreadedStatement`/`T3ThreadedStatement`,
the `T*Threaded`/`T*Threaded_ubFree`/`T*ThreadedOutcomes` theorems,
the ambient slate, and every speclab statement are verbatim
(statements are fuel-opsem-only and never mention the
interpretation — the migration is invisible at the statement layer,
which is the point of adequacy). Every pre-existing `#guard_msgs`
cone pin in `Audit.lean` passed VERBATIM at every commit — the
threaded families remain EXACTLY {propext, Classical.choice,
Quot.sound} on the heap route. The only pin edits are the four
REGISTERED instruments, each with a provenance comment in the same
commit: sweep 4898→4737→4786→4827→4914 (deletions / substrate / T1 /
T2+T3), census 46→47→55 (inject_ptr_arg2; the heapWalk lane), carrier
114→112 (the deleted `_of_wpK2` bridges). The statement gate held at
27 slate statements and speclab's at 46 clean throughout.

## 8. The C1 heap-macro handoff (adjudicated)

The C1 census note deferred "macro-side query conversion" to C2.
Delivered as REGISTRY-AS-SOURCE-OF-TRUTH: all twelve macro-backing
laws (the 8 heapWalk faces + the 4 heapWP op rules) are registered
entries, unique per (kind, variant), and `CerbHeapWalk.lean` carries
a build-fatal REGISTRY-BACKING CHECK (`byName?` per law) — a law
silently leaving the registry breaks the build. The macro SYNTAX
remains thin named appliers ([AGENT] adjudication, recorded per the
C1 precedent: goal-form-query APPLICATION — an applier that selects
the rule by DiscrTree match on the WP goal — is arc-19's search
machinery; building a private one here would duplicate it).

## 9. Commits

| commit | content |
|---|---|
| 068fe11c5 | the entry-2 deletions (peels + dormant law library) + same-commit re-registrations |
| adfa9d6a8 | the disentanglement — PerStepOwnP; live route arc-7-free; DriveVal to the live core |
| cc1ba80f1 | the heap-route walk substrate (rules + bridges + CerbHeapS + MemInv lemmas) |
| 2268000a5 | T1 migrated; framing dividend landed; wpk_seq_get + walk macros |
| 8f51214e2 | T2 + T3 migrated; two-object + scratch-object rules; inject_ptr_arg2 (census 47) |
| (this) | heapWalk registration (census 55) + registry-backing check + the R2 gate + plants + contracts-doc closure + T6 label + this record |

## 10. Walls, parks, C3 handoff

* T6's migration PARKED at the measured evaluator obstacle (§6) —
  the open-memory minting mode is the C3/arc-19 work item; until it
  lands, the OwnP transitional surface (PerStepOwnP + the IrisState
  shell + the wpSeq registry pair) must survive C5's arc-7 deletion
  wave EXACTLY as far as T6's consumption (the C5 executor should
  re-check the R2 gate's allowlist against the tree at purge time).
* T4Threaded (C3): when its walk lands, it should be born on the
  heap route (the T3 scratch pattern likely covers memb's
  struct-member stores once the evaluator mints open equations — or
  its rounds get hand-derived open twins like T1-T3 if the count
  stays small).
* The `wpSeq` OwnP registry pair (`wpk_seq_active_ecast/_proj`)
  retires when T6 migrates (census re-baseline then).
* Down-pressure note: the walks stayed 11-13 macro lines; the
  per-fixture open-equation layers are ~1.5x their closed
  predecessors (the open twins coexist with the closed chains the
  Outcomes corollaries still consume — C5 may reclaim the closed
  rounds where only the open ones are consumed).
