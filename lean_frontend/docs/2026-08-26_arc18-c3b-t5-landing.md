# Arc-18 C3b — the T5 continuation: walks complete, family landed, T5 re-parked at a corrected map (record)

Continuation slice of C3 (`docs/2026-08-25_arc18-c3-theorems.md` —
its §3.5 enumeration was this slice's entire scope). Worker: [AGENT],
worktree `cerberus-lean-coherence`, branch `coherence`, base
`df4910340` (the C3 record). Every commit gated (relsem + speclab
capped builds with all in-build gates, `test_unit.sh` 7/7,
`test_verify.sh` 35/35, every pre-existing cone pin byte-stable;
driver paths untouched throughout). One box-level session restart
(stream watchdog, not for cause) recovered per the resumption
discipline — the T5Walks build re-verified fresh, exit-checked,
before its commit. Quoted outputs are verbatim.

## HEADLINE VERDICTS (honest)

**T5 the theorem is NOT LANDED** (the proof-size gate's T5 row
REMAINS PENDING: `check_proof_size: T5.lean — not present yet
(registered, pending)`). What IS landed, each fully gated:

1. **§3.5 item 2 CLOSED** — the round-56 routing item fell (three
   named engine mechanisms, §1) and the body walk runs THROUGH the
   loop-closing Erun: **79 rounds + `b_chainrel`**, every round an
   evaluator mint.
2. **§3.5 item 3 CLOSED at the walk layer** — the exit walk reaches
   the thread's terminal: **44 rounds + terminal `bx_chainrel`**
   (guard-false through the kills and the post-kill s-load; two new
   registered read-over-update laws, §2).
3. **The entry walk at OPEN MAPS** — 22 rounds + `e_chainrel` from a
   ready builder with the two heap maps FREE (the ∀ bm am form the
   CerbMemInterp walk rules consume) — the C2 §6 open-memory-minting
   direction, demonstrated on the hardest fixture.
4. **THE TWO-SPELLING LOOP-HEAD SEAM (new, measured)** — falling
   INTO `save while_531` leaves iteration 1's loop head at a
   DIFFERENT SPELLING from the stored continuation every later
   iteration jumps to (outer-annotation hoist + partial forcing —
   propositionally distinct states; kernel-adjudicated by alignment
   rfl failures + a defeq-verified structural diff). Iteration 1 and
   the n = 0 exit get TWIN WALKS from their own builder (`mkLH1`,
   arena = the entry walk's own endpoint arena, projected — never
   transcribed): **bfirst 78 rounds** (the entry spelling runs one
   round shorter) and **bxzero 43 rounds + terminal**. FIVE walks
   total, all committed in `RelSem/T5Walks.lean`.
5. **§3.5 item 4 LANDED AT THE FAMILY LAYER** (`RelSem/T5Inv.lean` —
   the human-content exhibit): `triF` + kernel-checked closed form;
   the state family `St p k` (k-th loop head, every component a
   projection of the previous member — the family IS the walk's own
   step, indexed); THE ALIGNMENT RFLS (every member definitionally a
   loop-head builder state at its own components — the chainrel
   instantiation feed); component invariants ∀ k (allocation table,
   dead list, supply arithmetic); `memStep` defeq-pinned to the
   walk's own ladder (with the pack's `hfpm`/`hlum` respell baked
   in — a measured spelling fact) + the SL read-over-step laws;
   `envStepF` + the 27-layer built-chain through the
   generated-instance bridge (the R-S2-1 lesson, term-mode).

**T4 UNTOUCHED-PARKED** (per the brief's ordering: T5 did not land,
so the T4 budget clause never opened). R5 remains OPEN; the C0
register's T4Threaded/T1AppEq import item remains for C5's executor.

## 1. The engine work (commits `5208fc6a2`, `cb06265fb`, `6e4735096`)

Each mechanism named, measured, and consumed through the registry
(R4 — no law names in engine code):

| mechanism | the measured defect it removes |
|---|---|
| THE PROJECTION-NORMALIZATION HOP (`Hyp.resolveProjVal`/`projNormHop`, last-resort in `proveHypEqBld`, once per chain) | builder side-condition goals quote structure projections of folded successor spellings (`(b55 …).layout_state.deadAllocations`) the pack's base-binder facts can't scan — the C3 §3.4 item; round 56's `hdead` was a kernel-uncomputable deferred refl |
| FENCE-ROBUST REGISTRY FALLBACK (`LawRegistry.matchByUnify`, OPT-IN, engine passes builder-mode only) | the drive's attribute fence perturbs DiscrTree KEY COMPUTATION (fenced accessor keys const where the tree stored proj-reduced keys; `List.contains` keys const where the tree stored `List.elem`) — registered laws MISSED during exactly the drives that need them (measured rounds 59/37) |
| rangeProofs foldArith (Lanes) | a raw `Int.ofNat` operand from a whnf'd spelling atomizes under omega (the round-59 i-increment catch); side facts stated folded, use-site kernel-deferred cast |
| GLUE-FIRST for hyp-classified BUILDER rounds (+ `classifyUsedHypNorm`) | the direct face's stepAt unification re-runs a pack-dependent discovery packless — round 68 ABORTED on an uncatchable logged 200k-whnf timeout; builder-gated so the committed T4/T6 drives re-elaborate byte-identically |
| dig guards (`projBaseHead` spine check + nested-fenced refusal) | digging `Nat.div`/`.proj` redexes over operands containing the fenced ladder exposed WF internals one layer per dig into a maxRecDepth wall (entry create-i) |
| create-lane `haddr` witness via `hyp_norm_side` fallback | the elaborator's `rfl` projection witness is fence-blocked at builder ladders |
| terminal-chain rhs elaborated against the lhs pair type; builder-mode skip of whole-run artifacts (fence-restore hygiene); emitThm mvar diagnostics | phantom-param mvars in the terminal chainrel; whole-run rfl premises cannot re-run pack-dependent discoveries at a builder σ0 |

## 2. Registered laws (census 60 → 66, memRW 7 → 13; all Kit/Mem, fixture-free)

`writeBytesTo_lastAddress` / `writeBytesTo_nextAllocId` (create
rounds' supply projections over open-map ladders, rfl-side);
`tm_get?_insert_eq` / `tm_get?_insert_skip` (post-create allocation
reads); `tm_get?_erase_ne` / `list_contains_cons_ne` (post-kill
reads). Lane consumption in `mintMemRW` — registry-query appliers.
The walks measured these out one frontier at a time; each fell to
the same law-shaped treatment (the C3 §1 pattern, continued).

## 3. The corrected T5 completion map (what remains — priced honestly)

The §3.5 enumeration was OPTIMISTIC in two measured ways: (a) the
"entry alignment" clause concealed the two-spelling loop-head seam
(five walks, not three — now closed); (b) the composition ladder
under item 5 is larger than its one-line pricing. Remaining, in
order, on the now-committed substrate:

1. **Env-lookup peels ∀ k** (S-M): `envStepF_lkN/lkS/lkI` through
   the 27-layer chain — hit/skip via the registered Kit/Map laws at
   the generated instance (`envBeq` bridge, landed), static keys by
   decide, the two fresh-symbol layers by `symc`-bound apartness
   (`lemCmpToOrd_symEnvCmp_ne_eq_of_num_ne` + `St_symc`); term-mode
   like `envStepF_built` (landed exemplar).
2. **The remaining pack-fact family lemmas** (S-M): `St_rd*` ∀ k
   (base at the e22 ladder via pointwise bm facts +
   `readBytesFrom_of_pointwise`; step = the landed `memStep_rd*`),
   the `recon_i32`/`i2b` general roundtrip lemmas (clone the T1AppEq
   recipe WITHOUT importing the C5-retirement file), supply bounds.
3. **hbody + iter_compose** (S, mechanical once 1-2 land): the
   chainrel instantiated at `St p k` via the landed alignment rfls;
   `iter_compose_from (j := 1)` + the first-iteration and exit
   pieces composed by trans.
4. **Fuel algebra + ndct/driver2** (S): `fuel_split`/`app_fuel_cast`
   at total = 22 + 78 + 79·(N−1) + 46 (N ≥ 1) or 22 + 45 (N = 0),
   bounded by n ≤ 100; then `ndct_offer1` + `driver2_done` — the
   T1Threaded recipe verbatim.
5. **The harness spine at open maps** (S-M): k-stage open equations
   for t5File (inject_ptr_arg1/callND_errno at open maps — the
   T1 k6_o/k8_o recipe verbatim) + the mkRdy/setMaps alignment rfl.
6. **`wpk_seq_scratch2`** (M — the largest single remainder): the
   driver atom reading n's footprint with BOTH s and i scratch
   lifetimes inside (the T3 scratch pattern doubled). Design note:
   the final bytemap is an n-fold ladder, so the rule's byte-ghost
   hypotheses must be POINTWISE (the `writeList_get?_in/notin`
   vocabulary) rather than scratch1's syntactic `allocStoreBytes`
   shape; allocations stay syntactic
   (`((am.insert 2 alS).insert 3 alI).erase 3 |>.erase 2`); MemInv
   via the landed `.store`/`.kill` preservation lemmas.
7. **Statement + adequacy + gates** (S): the guarded ∀-seed
   statement (`T5EnvHypThr` digest guard + a `T5SeedApart`-class
   symc bound + 0 ≤ n ≤ 100), `kCallHarnessAdequateThrHeap_of_wp`,
   `RelSem/T5.lean` at the ≤250-line/≤40-step bar (family +
   statement + composition; mechanical peels stay in T5Inv/T5Walks),
   statement-gate slate + cone pins + the proof-size T5 row flip.

Registered operational note: `T5Walks.lean` re-runs its five drives
when the engine changes (~15 min; lake-cached otherwise) — the
walk-emission caching question is priced with the arc-19 tooling.

GATE CATCH, for the record (the no-cone gate's first catch at the
walk layer): wiring the walks under the audit sweep tripped the
`runEffectful` no-cone gate — the builders' `labeled` spelling (and
`whileBody`'s lookup) routed through the AMBIENT
`initial_core_run_state`, whose body reads the effectful supply, so
every walk equation's cone acquired the residual boundary axiom.
Respelled via `initial_core_run_state_threaded 0` (the `.labeled`
field is seed-independent); the walks re-derived identically and the
cones came back boundary-clean. Exactly the acquisition-is-build-
fatal design working as intended — and a live demonstration of the
forward-design constraint (keep new machinery supply-passable).

## 4. Validation (verbatim; every run exit-checked, strictly serial)

```
Build completed successfully (401 jobs).          [relsem]
Build completed successfully (143 jobs).          [speclab]
Total: 7 passed, 0 failed                          [test_unit]
test_verify: 35 passed, 0 failed (6 fixtures, 22 harness points)
info: … step_law census: 66 laws [advance 4, construct 9, envAlg 3, envMap 4, evalArith 2, evalPull 2, heapWP 4, heapWalk 8, loop 2, memBlock 5, memRW 13, perform 5, roundGlue 3, wpSeq 2]
derive_rounds RelSem.T5W.e: 22 advancing rounds minted
derive_rounds RelSem.T5W.b: 79 advancing rounds minted
derive_rounds RelSem.T5W.bx: relative chain RelSem.T5W.bx_chainrel emitted (44 rounds, terminal=true)
derive_rounds RelSem.T5W.bfirst: 78 advancing rounds minted
derive_rounds RelSem.T5W.bxzero: relative chain RelSem.T5W.bxzero_chainrel emitted (43 rounds, terminal=true)
```

(The audit-sweep count moves with the walk emissions joining the
sweep in the landing commit — provenance comment at the pin.)

## 5. Commits and the park

| commit | content |
|---|---|
| `5208fc6a2` | THE ROUND-56 ROUTING ITEM FALLS — projection hop + fence-robust fallback + glue-first; body walk to the Erun (79 + chainrel) |
| `cb06265fb` | ALL THREE T5 WALKS GREEN — entry at open maps, exit to terminal; the memRW read-over-update completion (census 66) |
| `6e4735096` | queryLaw's builder-gated fallback (Core.lean, belongs with cb06265fb) |
| `3f329fd0c` | T5Walks COMMITTED (three walks) |
| (landing) | the twin walks (bfirst/bxzero) + `T5Inv` (the invariant family) + audit wiring + this record |

**PARK** [AGENT, per the calibrated stop discipline]: the brief's
budget-suspicion clause fired — the §3.5 enumeration grew twin walks
and a 27-layer env-peel layer beyond its pricing, and the remaining
ladder (§3 above) is multi-day scope with one M-sized Iris rule.
Committing the walks + family green and re-parking with this
corrected map is the honest outcome; pushing the composition through
this session would be the seal-era pattern. The hard UNCERTAINTY of
T5 — whether the walks and the family close over the builder pack —
is now retired: everything that remains is enumerable mechanics on
committed substrate. Probes preserved at container
`.c3b-probe-scratch/`; session logs at container `.c3b-logs/`.

Down-pressure note: zero hand-derived per-round equations anywhere —
all 266 rounds across the five walks are evaluator mints; the walls
fell to six REGISTERED laws and seven named engine disciplines; the
family's manual content is the invariant itself plus one-line
projection rfls (the per-construct law supply carrying the rest).
