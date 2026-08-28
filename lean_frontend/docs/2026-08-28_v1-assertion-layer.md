# V1 — the assertion layer (slice record)

STATUS: SLICE CLOSED at this record (the record ends the slice).
Provenance: the operator-blessed infrastructure plan (container
`notes/2026-08-27_infrastructure-plan.md` §3 V1 / component B §1.B,
risk 2), executed under the BLESSED design catechism
(`docs/2026-08-27_design-catechism.md`; §VI self-check ran at slice
start and at each commit boundary), with the mid-slice operator
directive (2026-08-28, relayed): study RefinedC/Caesium's soundness
layer, mirror with attribution, and make the Cerberus-vs-Caesium
DELTA visible as the project's novel content (§4 below). [AGENT]
worker execution; quoted outputs verbatim; derived tallies labeled.

## 0. Headline

The `restIs` whole-state interpretation is DELETED and replaced by a
DECOMPOSED machine-state resource: Iris now owns the machine's
components separately — per-cell env ownership (`envIs x dq v` with
SYMBOLIC v), an exclusive control token, a supply-counter cell, a
memory-residual cell, and the unchanged byte/allocation ghost maps.
Adequacy is re-proved over the decomposition (generic bridges to the
V0 Thr AND Cns statement faces, cones exactly the classical trio,
pinned in-build), and the slice's acceptance exhibit is kernel-checked
end-to-end: a real Core fragment run by the real generated machine in
which ONE local's assertion at a SYMBOLIC value SURVIVES BY THE FRAME
RULE across a step that rebinds a DIFFERENT local — the thing the old
route could not express — discharged through adequacy to a layer-1
outcome-set statement quantified over ALL values. Full Tier A green;
statement layer untouched (the V0 slate is byte-stable; only
proof-layer files changed).

## 1. Commits (branch `arc/segment-ladder`; each verified green before
      its claim)

| # | SHA | Content |
|---|---|---|
| 1 | `d19d50ca3` | CerbStateRA — the decomposed resource (beside the old route; exit-ramp discipline) |
| 2 | `a4e61f662` | CerbStateWP — the lifting skeleton + op rules at residual granularity + the ctl/env rules |
| 3 | `403324089` | CerbStateAdequacy — bundle, general adequacy, Thr + Cns bridges |
| 4 | `25311393e` | EnvWf (the Caesium `heap_state_invariant` move) threaded through RA/WP/adequacy |
| 5 | `f6a1de8f5` | The demo engine room — real-machine round equations at an ABSTRACT env frame (the F-trick) |
| 6 | `b3477655b` | THE EXHIBIT — `demo_wp` + `demo_adequate` |
| 7 | `27c0b0c4c` | `two_alloc_frame` (KEEP anchor) migrated |
| 8 | `1a700888c` | THE DELETE — the whole-state route gone; gates re-registered same-commit |
| 9 | (this commit) | Slice record + docs truth pass |

## 2. The component inventory (RelSem/CerbStateRA.lean; lineage per
      mechanism, mirror citations per the operator directive)

| Component | Resource | Lineage / mirror |
|---|---|---|
| BYTES | GenHeap at `Address(Int) ↦ AbsByte` (`a ↦{dq} b`, `pointsToBytes` big-op) | unchanged from arc-16 S2; HeapLang gen_heap; Caesium `heap_ctx` (ghost_state.v:180) |
| ALLOCS | ghost_map `AllocId ↦ Allocation` (`allocIs`) | unchanged; Caesium `alloc_meta`+`alloc_alive` merged (S2 deviation D1; ghost_state.v:22-31, freeable :167-174) |
| ENV | ghost_map `symNum(Int) ↦ (sym × value)`: `envIs x dq v`, v SYMBOLIC | gmap-authoritative locals view; NO Caesium counterpart (their locals are heap allocations) — see §4; the auth is tied to the physical env by LOOKUP-LEVEL COHERENCE (§3) |
| CTL | ghost_var halves at `ctlOf σ` (`ctlIs`) — arena/stack/labels/trace/fs/…; env frames SPINE-preserved content-erased, supplies zeroed, layout dropped | the exclusive control token (standard control-in-Iris; ghost_var halves idiom); the old rest cell, shrunk |
| SUPPLY | ghost_var halves at the four fresh counters (`supIs`) | ghost counters (mono-counter RA refinement deferred, documented); aligns with V0's `ConsistentRun` window |
| MEMREST | ghost_var halves at `memRestOf σ` (`mrestIs`) — funptrmap, lastAddress, nextAllocId, deadAllocations, … | Caesium keeps its fn table as an auth component (`fntbl_ctx`, ghost_state.v:186); ours stays one exclusive cell (promotion to per-entry maps is V2+ material) |

The interpretation (`CerbStInterp`): the six authoritative pieces ∗
`⌜MemInv⌝ ∗ ⌜EnvWf⌝` — pure physical invariants INSIDE the
interpretation, the exact Caesium `state_ctx` shape
(`⌜heap_state_invariant st⌝ ∗ heap_ctx … ∗ alloc_meta_ctx … ∗
alloc_alive_ctx …`, deps/refinedc/theories/caesium/ghost_state.v:
189-199). Two-faces rule unchanged: the interpretation appears only
in the IrisGS instance and adequacy plumbing; proofs hold footprints.

Rules (RelSem/CerbStateWP.lean, all registered `@[step_law]`,
registry-backing check in-build):
* the four memory-op rules (`wpk_load/store/alloc/kill`) rebuilt at
  MEMORY-RESIDUAL granularity — a heap op no longer pins control,
  env, or supplies (they frame); lane `heapWP 4`;
* NEW lane `stateWP 4`: `wpk_seq_ctl` (control-token step; every env
  cell frames), `wpk_seq_ctl_env1` (step characterized by ONE owned
  cell at a symbolic value), `wpk_seq_env_write` (rebind of the owned
  cell; all other cells preserved by NUMBER-APARTNESS and framed),
  `wpk_get_done_ctl` (terminal readout at the token).

Adequacy (RelSem/CerbStateAdequacy.lean): the `CerbStS` bundle (12
slots); `cerbSt_adequacy` generalized to ANY MemInv+EnvWf initial
state with a CHOSEN coherent tracked-env footprint (env cells are
BORN here or at the write rule); the production-runner face; the
threaded harness bridges (`kCallHarnessAdequateThrSt_of_wp` +
UB-freedom — conclusions byte-identical to the retired heap-route
bridges) and THE CNS BRIDGES (`kCallHarnessAdequateCnsSt_of_wp` +
UB-freedom) discharging the V0 consistency statement faces from a
∀-seed WP obligation. All cones exactly
{propext, Classical.choice, Quot.sound}, `#guard_msgs`-pinned.

## 3. THE COHERENCE DESIGN (the slice's design finding)

A projection-based per-cell env auth — gen_heap's exact-image
pattern, Caesium's `to_heapUR := fmap to_heap_cellR`
(ghost_state.v:39-49) — is UNPROVABLE over LemLib's `Fmap`: the type
carries CAPTURED COMPARATOR CLOSURES and no representation invariant,
so no faithful cell-level projection exists for arbitrary values (an
adversarial captured comparator changes lookup behavior invisibly to
any projection). Resolution (canonical: the
logical-view-of-physical-state simulation move):

* the interpretation holds an EXISTENTIALLY quantified auth map `e`
  tied to the physical env by lookups only —
  `EnvCoh σ e := ∀ n c, get? e n = some c → symNum c.1 = n ∧
  envLookup σ c.1 = some c.2` (`envLookup` = the interpreter's own
  `lookup_env` at the head thread);
* a fragment yields exactly the pure fact step derivations consume;
  updates re-establish coherence POINTWISE from number-apartness —
  the Kit/Env + Kit/Map lookup-through-insert suite (arc-17 S2)
  became load-bearing exactly as priced;
* `EnvWf` (every head-thread frame empty or `FmapBuilt` at the
  canonical `symCmpO`) rides the interpretation as a pure conjunct —
  the Caesium `heap_state_invariant` move — making the hit/skip laws
  applicable at UNKNOWN frames.

Soundness note: coherence is one-directional (tracked ⇒ physical);
untracked cells are unconstrained, and rules can only conclude what
fragments grant — fail-closed by construction.

## 4. THE CERBERUS DELTA (operator-directed; what Caesium never had
      to do — the retrofitting-locality content)

| Caesium (deps/refinedc/theories/caesium) | Cerberus (this slice) |
|---|---|
| State is stdpp `gmap`s; auth images are exact `fmap` projections (ghost_state.v:39-49); no map well-formedness needed | LemLib `Fmap` carries captured comparator closures + dual trees with no invariant → coherence-relation auth (§3) + the `EnvWf` built-ness interpretation invariant |
| C locals are HEAP allocations (function frames map vars to locations at call setup) — locality for locals is free once the heap has it | Cerberus Core keeps a REAL ENVIRONMENT (a scope-stack of value bindings, `List (Fmap sym value)`, inside `thread_state`) — per-cell locality had to be BUILT: the env ghost map, the coherence seam, the spine-preserving ctl erasure |
| Small-step relation over records; lifting lemmas case on one constructor (lifting.v, heap.v) | The EXECUTABLE fused interpreter: one `app` runs whole deterministic monadic chains; step characterization = inversion at the control token (list/record eta) + Kit crossing lemmas (`stub_defined`/`liftCore_run_defined`/`aux2_done`) + THE F-TRICK at the stuck env lookup (the one-step evaluator is DEFEQ to its abstraction at the lookup position; the fragment fact rewrites it closed — CerbStateDemo `symEvalF`/`step_eval_symx`) |
| Fresh allocation ids from the operational step; `alloc_meta` persistent | The fresh-symbol SUPPLY as its own component (the V0 consistency layer reads its window); mid-run tracking-birth of env cells needs negative domain information — deferred (§6.1) |

The compiled-matcher instance seam (the R-S2-1 lesson, recurring):
generated code elaborates `fmapAddBy`'s `[BEq]` through the
`MapKeyType`-derived instance, instance SYNTHESIS picks another —
non-defeq. V1's wrappers (`addBy_eq'`/`addBy_ne'`, demo file) fix the
generated spelling once; the V2 rule layer should own this pattern.

## 5. THE EXHIBIT (the plan's V1 exit criterion 2)

`RelSem/CerbStateDemo.lean` — a real Core fragment
`wseq y := (pure w) ; pure (sym x)` over `t1File`, run by the real
generated machine (each WP step = one unrolled
`drive_nonmemory_steps` round; the readout = the driver's own
`finalize`):

* `demo_wp` : `ctlIs ∗ envIs x 1 vx ∗ envIs y 1 w0 ⊢ WP demoK
  {{ o, ∃ r, o = value r ∧ r.dres_core_value = vx }}` — step 1 (the
  y-rebind) applies `wpk_seq_env_write` consuming ONLY the token and
  y's fragment; x's fragment is NEVER MENTIONED and survives by the
  FRAME RULE; step 2 reads x at its symbolic value
  (`wpk_seq_ctl_env1`); vx is a bound VARIABLE throughout.
* `demo_adequate` (layer-1): ∀ vx w0 w and ∀ supplies, every outcome
  the production runner enumerates for the fragment is a value whose
  core value is EXACTLY vx. Cone exactly the trio (pinned).

Honesty labels: the fragment is a hand-assembled `KExpr` over
generated atoms (documented; a corpus row falls at V2+ per the plan);
the arena is hand-built Core syntax, not a pinned .core dump; the
demo's engine derivations (ctl inversion, round equations, the eval
chain) are per-instance — the V2 per-construct rules systematize
exactly them.

## 6. Honest gaps and deferrals (each with a mover)

1. **Tracking-birth of unowned env cells** (ghost insert mid-run):
   needs negative domain information the footprint cannot supply;
   V1 births cells at adequacy (the chosen footprint) or via the
   write rule. Mover: V2's rule layer (supply-freshness route
   sketched in the RA header).
2. **Multi-thread env coherence**: `EnvCoh`/`EnvWf` speak the head
   thread (the singleton-pool discipline all harness states satisfy).
   Mover: the cmm arc.
3. **`FnSpec.Verified` still speaks the Thr faces** (V0's documented
   wart, unchanged); `verify_fn` retargeted to the new bundle but its
   statement-shape classifier is tuned to pre-V0 shapes — dormant.
   Mover: V2's discharge re-target (plan component H).
4. **`seg_auto` and the auto-fed walk macros DELETED** (their applier
   set was exactly the retired walk rules). The face returns at V2
   over the per-construct rules (plan component H). `seg_env_lookup`,
   `seg_side`, the registration attrs, and the pure Seg algebra KEEP.
5. **The supply cell is a ghost_var**, not a mono-counter RA — the
   refinement (and the alloc-ND design conversation) stays chartered
   where the plan put it.
6. **`extWriteSeq`/`bytes_update_seq_ghost`** (the arc-18 R2 loop
   write-ladder ghost move) died with the old route un-ported — zero
   consumers; V3a re-derives at need.

## 7. Gate movements (same-commit provenance at every pin)

| Surface | Old → New |
|---|---|
| One state interpretation | `CerbMemInterp`/`restIs` → `CerbStInterp` (decomposed); one-route gate live list re-pointed, banned tokens + `CerbHeapGS`/`CerbHeapGpreS`/`CerbMemInterp`/`restIs`/`CerbHeapS` |
| step_law census | 78 → 71 (heapWalk 11 deleted; heapWP 4 re-registered at residual granularity; stateWP 4 born) |
| Audit sweep | 2698 → 2668 |
| Cone pins | old-route S2/C2 blocks → the V1 block (interp moves, 8 rules, adequacy + Thr/Cns bridges, `two_alloc_frame`, `demo_wp`, `demo_adequate`) — all exactly the trio |
| Statement gate | UNTOUCHED (31 statements byte-stable); negative probe re-pointed to `CerbSt.wpk_load`, verified still rejecting |
| Registry-backing check | re-homed CerbHeapWalk → CerbStateWP (8 macro-backing laws) |
| Engine size | SegmentFaces 1176 → 656 (§3/§5 deleted; annotated re-baseline); engine total 6318 → 5798 |
| Hygiene | two stray tracked `.lean_probe.*.json` scratch files (pre-V1) removed |

## 8. Validation (verbatim, closing tree)

In-build (relsem `lake build`, 376 jobs, green):

```
info: RelSem/Audit.lean:710:0: RelSem statement gate: 31 slate statements fuel-opsem-clean + concrete-input-clean (negative tests: wpk_load, the wrapper-hole probe, the constant-args probe and the finite-sample probe all correctly rejected)
info: RelSem/CerbStateWP.lean:680:0: CerbStateWP registry-backing check:     8 macro-backing laws registered
info: RelSem/Audit.lean:1169:15: step_law census: 71 laws [advance 5, construct 9, envAlg 3, envMap 4, evalArith 2, evalPull 2, heapWP 4, loop 1, memBlock 7, memRW 21, perform 6, roundGlue 3, stateWP 4]
info: RelSem/Audit.lean:1259:0: runEffectful no-cone gate: carrier set exact (0 registered ambient-family theorems; no acquisition, no stale entries)
```

`test_unit.sh`: exit 0, `Total: 6 passed, 0 failed` + all gate
scripts OK (exec purity/totality, theorem-axiom cones, lem-sync,
fork-drift, proof-size + corpus freeze, one-route, engine size).

Tier A (16 lanes, serial; one line per lane, verbatim):

```
[0] exec_main :: BASELINE OK
[0] exec_cov :: BASELINE OK
[0] exec_debug :: BASELINE OK
[0] exec_float :: BASELINE OK
[0] bytes :: ALL AT COMMITTED EXPECTEDS
[0] libc_exec :: ALL MATCH RECORDED BASELINE
[0] multi_tu :: ALL PASSED
[0] parse :: ALL PASSED
[0] core :: ALL PASSED
[0] elab :: SUMMARY: total=106 same=103 diff=3 ocaml_fail=0 lean_fail=0
[0] uri :: GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)
[0] cn_coverage :: BASELINE OK (213 entries, exact match)
[0] immaculate :: OK: lane matches the committed post-S1 baseline (mostly MATCH; the intended non-MATCH rows: g5-decode-question ORACLE_CRASH/L=63 and g5-escape-roundtrip DIFF/L=127 are oracle-wrong — upstream-tray #10/#11 — and g6 is TRIPWIRE).
[0] verify :: test_verify: 112 passed, 0 failed (22 fixtures, 18 harness points, 14 corpus fixtures, 21 corpus points)
[0] speclab_divmod :: test_speclab_divmod: PASS (--gate)
[0] speclab_seed :: test_speclab_seed: PASS (--gate)
TIERA_OVERALL_FAIL=0
```

## 9. Catechism §VI self-check at close

1. ∀-statements served: every corpus row needs local framing (the
   plan's dependency matrix — component B is on every line); the
   exhibit itself is ∀ vx (and supplies).
2. Amortization: proved-once interpretation + 8 registered rules;
   the demo's per-instance engine work is exactly what V2's
   per-construct rules amortize — named as such, not hidden.
3. Lineage: named per component (§2), mirrors cited file:line per
   the operator directive; the delta over the donors is §4, visible.
4. Professor test: the exhibit reads as the frame rule doing its
   canonical job (own two locals, update one, the other persists);
   the engine room is labeled engine room.
5. No enumeration/concrete residue: the ban gate stands untouched;
   the exhibit quantifies its values; nothing samples.
6. Failure mode: the walls hit (Fmap projection, matcher instances,
   fuel-literal matchers) are DOCUMENTED design findings with movers,
   not pushed-past parks.
7. Trust surface: statements untouched, cones exactly the trio
   everywhere (pinned), one interpretation route (gate-enforced), no
   new axioms, carriers still zero.
