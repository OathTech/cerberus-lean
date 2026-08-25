# Arc 17 S1 — the equation-supply frontier (record)

Worker record, 2026-08-24/25. Charter:
`2026-08-24_arc17-automation-framework-charter.md`, slice S1. Branch
`automation-framework` (off `f5cf03a8b`, the S0 close); this slice's
commits: `1c63cbe35` (twin dissolution), `95d30dc49` (call-structure
laws + census instrument), `9ca16ed9d` (acceptance probe + harness
laws + the park), plus the pin/record commit carrying this file.
Lineage (charter-named): decompilation-into-logic (Myreen) —
elaboration's stereotyped Core shapes, one law per shape. [AGENT]
decisions marked; every number is from this session's builds/probes,
re-verified with EXIT-CHECKED runs (see §5.4 — a record-integrity
lesson from this slice's own middle).

## 1. The registry (`RelSem/ConstructLaws.lean`)

ONE registration point for fixture-independent construct laws
(charter S1 task 4). Discipline, stated in the module header and held
throughout: one law per construct shape; hypotheses in engine
discharge order; every docstring carries the SHAPE (generated arm,
file:line), the why-the-next-program-gets-it-free sentence, and its
TRACE-ATOM SCHEMA per the S0 format spec §3.6; NO fixture symbols
ever — `check_proof_size.sh`'s mega-lemma counter now scans
`ConstructLaws.lean` exactly as it scans `Kit/` (plant-tested both
directions: exit 1 with a planted `t2File` mention, exit 0 clean).

The S1 inventory (cones VERBATIM, session probe; all Audit-pinned
build-fatally):

```
'RelSem.Laws.seu_read_bind' depends on axioms: [propext]
'RelSem.Laws.erun_jump_m' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Laws.ndct_offer1' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Laws.driver2_done' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Laws.inject_ptr_arg1' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Laws.callND_errno' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Laws.get_ths_eq' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Laws.driver_update_ts' depends on axioms: [propext, Classical.choice, Quot.sound]
```

plus the non-law registry helper `stepAt` (the step-discovery
composite as a term — the emitter's handle for mechanical round
minting, §5).

| Law | shape (construct) | dissolves |
|---|---|---|
| `seu_read_bind` | run-state read at a with-runstate head | (helper for the next row) |
| `erun_jump_m` | Erun/Esave label jump (goto, loop back-edges, save/run return) | the 3 label-resolution twins (§2) |
| `ndct_offer1` | single-thread scheduler read | 6 per-fixture `ndct_eq*` proof bodies |
| `driver2_done` | driver iteration at a done offer (the mode-split CASED once) | 6 per-fixture `driver2_iter*` bodies |
| `inject_ptr_arg1` | one-scalar-argument caller protocol | the per-fixture injection stage (probe-exercised) |
| `callND_errno` | the harness errno block (fixture-independent verbatim) | the per-fixture errno stage (probe-exercised) |
| `get_ths_eq` / `driver_update_ts` | thread-table read / thread setup | rfl-class stages, named feeding handles |

Output-recast discipline [AGENT]: the stateful laws carry a final
`hout : <computed post-state> = σ'` hypothesis — the caller passes a
NAMED compact state + `rfl`, so walks re-anchor to names at every
stage (the S0 giant-terms discipline made law-compatible). The
threaded fixtures' `driver2_done` call sites consume it.

## 2. Twin dissolution (charter S1 task 1 — the test cases)

The arc-16 S3/S4 label-resolution twins existed because the Erun eval
round's `runSE (state_except_read …)` label lookup pinned the
concrete run state. `erun_jump_m` splits the round exactly there:
resolution enters as `hres` (discharged `simp only [mkDr, hlab]; rfl`
from a `labeled`-projection hypothesis), the jump body as `hk` (the
fixture's ∀-run-state eval lemma). The ambient rounds are now
∀-run-state with `(rs : core_run_state) (hlab : rs.labeled = collect_
labeled_continuations_NEW <file>)`; both the ambient and the threaded
∀-seed ladders instantiate the SAME lemma with `hlab := rfl`.

| Twin (deleted) | lines | replaced by | consumer sites |
|---|---|---|---|
| `RelSem.T1.round6_thr` | ~35 | `T1.round6` ∀-rs via `erun_jump_m` | T1AppEq walker chain (rsR6 literal + rfl), T1Threaded chain (`rsR6_thr seed` + rfl) |
| `RelSem.T2.round13_thr` | ~33 | `T2.round13` ∀-rs | T2AppEq chain (rsAB + rfl), T2Threaded chain (`rsAB_thr seed` + rfl) |
| `RelSem.T3.round21_thr` | ~33 | `T3.round21` ∀-rs | T3AppEq chain (rs5 + rfl), T3Threaded chain (`rs5_thr seed` + rfl) |

Measure: 3 twins deleted for 2 registry lemmas (1 construct law + 1
crossing helper); T1–T3 threaded files now consume ALL committed
rounds as-is (T2: 16/16, T3: 24/24 — the S4 record's "the last
per-fixture round text" is gone). Cone IMPROVEMENT: the generalized
ambient rounds are pinned trio (`round6`/`round13`/`round21` —
`[propext, Classical.choice, Quot.sound]` each, Audit `#guard_msgs`),
where the old ambient statements' concrete rs (rooted in the ambient
initial state) sat above the `runEffectful`-quoting substrate.

The call-structure laws then dissolved the remaining per-fixture
scheduler/driver text: `ndct_eq_thr` / `driver2_iter_thr` in
T1/T2/T3Threaded are now one law application each (the per-fixture
execution-mode `cases` dance lives ONCE, inside `driver2_done`).

T4's Erun rounds (`round13`/`round21`/`round54` in T4AppEq) are
deliberately untouched: T4 is parked at the S4 collision diagnosis;
its rounds pin rs for the env-symbol comparisons too, which is the
S2 env-algebra's business — registered as an S2 input, not forced.

## 3. The construct sweep (charter S1 task 2)

Instrument: `scripts/core_shape_census.sh` (committed, Tier C
reporting; fail-closed on an empty corpus; counting caveats in its
header — `nd(` lookbehind, pure-let by subtraction, if/case conflate
pure and effectful forms). Corpus: the 44 pinned Core dumps
(at census time tests/verify 5 + tests/speclab 39, the drift-gated oracle dumps — audit-1 MINOR-1 correction; post-t6-pin the census reads 45 = 6 + 39).
Verbatim run (2026-08-25):

```
core_shape_census: 44 pinned Core dumps (tests/verify + tests/speclab)
construct                    occurrences   files
---------------------------------------------------
Epure (pure)                       23103      44
Ewseq (let weak)                   11747      44
Esseq (let strong)                  5036      44
Elet (pure let)                     1059       -
Eif/PEif (if)                       5027      44
Ecase/PEcase (case)                 4701      41
Eunseq (unseq)                      4267      44
Ebound (bound)                      2465      44
End (nd)                             642      40
Esave (save)                         746      44
Erun (run)                           695      44
Eccall (ccall)                       202      44
Eproc (pcall)                          0       0
Epar (par)                             0       0
Ewait (wait)                           0       0
action: create                       982      44
action: alloc                          0       0
action: load                        3005      44
action: store                       1987      44
action: kill                        4903      44
action: seq_rmw                      122      34
memop: PtrValidForDeref              690      39
memop: PtrEq                          66      16
memop: PtrNe                          30      15
memop: PtrWellAligned                 23      16
memop: other kinds                     0       0
pexpr: array_shift                   914      39
pexpr: member_shift                  223      17
pexpr: undef                        4293      44
---------------------------------------------------
```

Law-coverage mapping (the interpretation the script deliberately does
not carry):

| census shape | law status |
|---|---|
| tau strips (wseq/sseq/let/case/bound/annot) | COVERED — `Kit.dnms_round` + `advance_tau_misc`; peeled: `wpk_round_tau` |
| pure evals (if/case scrutinees, conv chains) | COVERED at round level — `advance_runstate_eval` (+`wpk_round_eval`); the EVAL PAYLOAD at symbolic data stays per-fixture ∀-rs eval lemmas (registered residual, below) |
| Erun/Esave | COVERED — `erun_jump_m` (NEW, §2) |
| create/load/store/kill | COVERED — Kit `perform_*` + `mem_*_block` (+S3 `wpk_round_*`); the probe exercised alloc+store through them at literals |
| harness caller protocol | COVERED — the 4 NEW harness laws (§1) |
| scheduler/driver iteration | COVERED — `ndct_offer1`/`driver2_done` (NEW) |
| Eccall | COVERED at dispatch (`wpk_pcs_ccall`); callee summaries = parity component 3, out of S1 scope |
| `seq_rmw` (122 occ, 34 files) | REGISTERED GAP — the NEG/RMW transform DRAWS FRESH SYMBOLS (supply-reading): any ∀-seed law needs the S2 seed-apartness + env algebra (the S4 T4 diagnosis, verbatim prediction). S2 input, not forced. |
| memops (809, dominated by PtrValidForDeref) | REGISTERED GAP — no perform/wpk law for `Step_memop_request2` yet; not exercised by any current fixture's exec cone; S–M when a fixture needs it (deref-guard shapes will, on the libxml2 road). |
| `End` nd (642, incl. dead Unspecified branches) | REGISTERED LIMIT — `KStep.seq_nd` atom granularity (S3 §2.3); choice/schedule territory, cmm arc owns. |
| Eproc/Epar/Ewait/alloc | absent from the corpus — no law owed (census-honest zero rows). |

## 4. The acceptance probe (charter S1 task 3): STOPPED at the stop
   clause, with the gap measured

Fixture: `tests/verify/t6_branch.c` — `int pick(int x)` with a local,
a computed branch, subtraction/addition arms; a source shape (expr-
level branch on a computed condition) no prior fixture pins. Pinned
per house practice: oracle `--pp=core` dump byte-pinned + provenance-
gated; 4 expectation rows; emitted into SlateCore (`pickT6Sym`/
`pickT6Decl`, drift-gated) + `t6File` in SlateFiles + 4 concrete
slate points in EmitLeanCoreTest. All differential lanes green:
`test_verify: 35 passed, 0 failed (6 fixtures, 22 harness points)`.

Ground truth (compiled runner, seed 0, verbatim `#eval` output
`[44]`): callND(pick,[10]) runs 44 advancing driver rounds + the
terminal offer, final value Specified(7).

### 4.1 What the zero-fixture-equation proof REACHED (verified)

- THE FULL HARNESS PREFIX: `iintro` + 9 `wp_step`s — the S0-minted
  stage equations (`dG_app`, `kRes`/`kBody`/`kTys` in `expecting`
  mode) + `inject_ptr_arg1`/`get_ths_eq`/`callND_errno`/
  `driver_update_ts` with Kit `mem_alloc_block`/`mem_store_block`
  facts at literal instantiations — elaborated to a goal displaying
  `stateIs (dRdy seed)` with the driver-loop atom exposed
  (goal-display transcript, verbatim head):

  ```
  ∗Hst : stateIs (dRdy seed)
  ⊢ WP (KExpr.seq (driver2 t6File.tagDefs false) fun x =>
        KExpr.seq nd_get fun dr_st' =>
          KExpr.done (Outcome.value (finalize t6File.tagDefs "callND" dr_st')))
      {{ o, ⌜∃ r, o = Outcome.value r ∧ t6Spec r⌝ }}
  ```

  Zero fixture-specific equation lemmas; the per-fixture text is DATA
  (statement, param symbol, address/byte/memory literals, the
  `derive_state` ladder).
- MECHANICAL ROUND SUPPLY, rounds 1–7 (all pure): per-round successor
  states minted by `derive_state_step … from (advance_step … (stepAt
  … (r⟨k-1⟩ seed))) at (r⟨k-1⟩ seed)` — no hand transcription of any
  intermediate arena — and consumed by `Kit.dnms_round` with all-rfl
  side conditions. Through-r7 file: 17.7 s, exit 0, kernel-checked.

### 4.2 The wall (round 8, the first MEMORY round), measured

Round 8 is the store of `t`'s initializer (`Step_action_request2`,
identified by a whnf diagnostic on `stepAt`). Its mechanical mint:

- at `.all`-transparency whnf: the single command allocates past the
  64 G blast-radius cap (capped cgroup kill ~75 s; live-poll: linear
  ~0.8 GB/s from command start). Suspected mechanism: unfolding the
  byte-map's balanced-tree operations degrades DAG sharing (the
  `#print` of an early minted body itself OOMs the pretty-printer);
- at `.default`-transparency whnf: same kill on this round (and on
  lazily-minted predecessors the matcher fast-path stalls on the
  action-request wrap-continuation match nests — the reason `.all`
  was tried);
- an all-projection body design (`(app m σ).2`, no whnf) instead
  crosses the default heartbeat budget by round 5 — exponential
  recompute of the projection cascade, no memoization. NO budget
  bump taken anywhere (heartbeat doctrine: pressure = design input).
- `shareCommon` post-compaction and `addDecl`-vs-`addAndCompile`
  were each tried and measured NOT to change the kill (the emitter
  keeps `addAndCompile` + default-first whnf with `.all` fallback —
  the one durable improvement from the campaign).

VERDICT: the probe FAILS AT THE CHARTER BAR AS STATED, by the
charter's own stop clause — the missing piece is not a construct law
(the round laws exist and fire; the memory-block laws discharge the
same store in the prefix walk at literal instantiations) but
S0-EMITTER-CLASS MACHINERY: a LAW-DRIVEN SUCCESSOR EVALUATOR for
memory rounds — compute the post-state by applying the Kit
`mem_*_block` equations symbolically (building the compact literal
spelling the fixtures write by hand) instead of raw whnf of the
memory model. Canonical lineage: the HeapLang-ProofMode architecture
(compute successor states once in the meta layer) + the donor's
recompute-and-check contract; the fixtures' `allocA_eq`-style simp
recipes are the evaluator's existing equation set. Priced M.
REGISTERED AS AN S2 INPUT (alongside the env algebra it will sit
next to).

Disposition: `RelSem/T6Probe.lean` is committed PARKED OUT OF THE
BUILD (absent from lakefile roots/RelSemAll/Audit, header explains)
at its reproducible frontier — `scripts/capped lake lean` on it is
green in ~18 s and reproduces everything in §4.1; the round-8
reproducer is in-file, commented, with the measurements. Park may
rot silently (not built); re-run before relying on it.

### 4.3 Down-pressure register row (partial, honest)

| item | value |
|---|---|
| prefix WP walk proof body | 11 tactic lines (9 wp_steps + iintro; law/mint feeds only) |
| fixture equation LEMMAS written | 0 |
| fixture DATA written | statement + symbol + 2 addresses + alloc/byte/mem literals + 7-def state ladder (~120 lines) |
| mechanical round mints landed | 7/44 (pure rounds; each ~0.5 s) |
| parked-file elaboration | 17.8 s, exit 0 |
| full-proof line count / time | NOT REACHED (the §4.2 gap) |

### 4.4 Record-integrity note ([AGENT], logged per doctrine)

Mid-session, a series of chain-extension builds was misread as green:
the runs were cgroup memory-kills (exit 143) whose output contained
no error lines, and the exit codes went unchecked behind a grep
pipeline. Interim in-session conclusions ("148-round chain
elaborates", "walk + statements land") were WRONG and are withdrawn;
the parked file and this record contain only claims re-verified with
exit-checked runs (the 44-round ground truth replaced the fictitious
148). Standing lesson applied for the rest of the session: every
build claim carries `echo EXIT=$?`.

## 5. Registry-shape notes (charter S1 task 4; for the parity
   ledger's component 2)

- ALREADY Lithium-fragment-shaped (unique rule per goal form, no
  backtracking): the round layer — goal forms `app (dnms …) σ`,
  `app (new_drive_core_threads …) σ`, `app (driver2_lemFuel …) σ`,
  the callND stage atoms — each has exactly ONE registered rule;
  side conditions are `rfl`/`wp_ground`-class or fed equations BY
  NAME (the S0 atom schemas are embedded per entry).
- NOT yet unique-rule-per-goal-form: (a) the advance layer under
  `dnms_round` — choosing `advance_tau_misc` vs `advance_runstate_
  eval` vs `advance_action_request` requires looking at the
  DISCOVERED step's head constructor (a deterministic discriminator
  an engine can switch on — normal-form-able, but today the caller
  chooses; the probe sidestepped it with hadv-rfl); (b) the memory
  layer — `mem_store_block` vs UB paths is guarded by hypothesis
  polarity, and the success-path-only scope means a failing store has
  NO rule (fail-closed by absence, but an engine needs the explicit
  frontier tag); (c) `hout` recasts assume the caller owns a name
  supply — the engine's state-naming policy (S0 §3.6's registry
  wrapper) will own it.
- The trace-atom schemas are in every docstring; no emission
  implementation this slice (per S0 §3.6 the wrapper lands with the
  engine).

## 6. Timings (this session's build logs, forced rebuilds)

```
✔ Built RelSem.ConstructLaws (665ms–779ms across the slice)
⚠ Built RelSem.T1AppEq (6.6s)   -- walker-era file, unchanged cost class
⚠ Built RelSem.T2AppEq (1.9s–2.1s)
⚠ Built RelSem.T3AppEq (2.7s)
✔ Built RelSem.T1Threaded (1.1s–1.2s)
✔ Built RelSem.T2Threaded (922ms–1.1s)
✔ Built RelSem.T3Threaded (995ms–1.0s)
(parked) RelSem/T6Probe.lean via lake lean: 17.8s, exit 0
```

No budget bumps anywhere (heartbeats/maxRecDepth default throughout;
the probe campaign's budget pressures were answered with design
changes or the park, never raises).

## 7. Validation (verbatim, at the close commit)

```
info: RelSem/Audit.lean:188:0: RelSem DAEMON absence gate: no constant named DAEMON or DAEMON1 exists in the environment; neither is allowlisted
info: RelSem/Audit.lean:559:0: RelSem statement gate: 25 slate statements fuel-opsem-clean (negative tests: t1_wp and the wrapper-hole probe correctly rejected)
Build completed successfully (387 jobs).
Total: 7 passed, 0 failed
check_proof_size: Kit + ConstructLaws files fixture-free OK (8 files)
check_chase_freeze: OK — no chase-surface imports/uses outside the legacy allowlist (8/8 allowlisted files present)
test_verify: 35 passed, 0 failed (6 fixtures, 22 harness points)
```

Sweep re-baselines this slice: 4108 → 4119 (twin dissolution +
call-structure laws, net +11) → 4128 (harness-protocol laws + stepAt;
provenance comments at the pin). Statement gate steady at 25 (the
probe's statements are parked with it; no statement anywhere
changed). Axiom censuses untouched (2 declared-boundary hand-written
axioms); no new sorries; freeze gate 8/8 throughout.

## 8. Registered S2 inputs (consolidated)

1. THE MEMORY-ROUND SUCCESSOR EVALUATOR (§4.2) — law-driven
   post-state computation for the emitter/engine; M. The probe
   resumes from its parked frontier when this lands.
2. `seq_rmw` construct law (§3) — blocked behind seed-apartness +
   env algebra (the S4 T4 diagnosis; supply-reading shape).
3. T4's rs-pinned rounds (§2) — same env-algebra dependency.
4. Memop round laws (§3) — S–M, first needed by deref-guard-bearing
   fixtures (libxml2 road).
5. Standalone-`example` heartbeat crossings of the `hout` recast
   direction (T6Probe park note) — dissolves with input 1's compact
   successor spellings.
