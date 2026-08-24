# Arc 16 S4 — the acceptance test: T1–T4 at the threaded ∀-seed state (record)

Worker record, 2026-08-24. Charter:
`2026-08-24_arc16-iris-refounding-charter.md`, slice S4 with the
[USER] amendment (the effect-state elimination folds in; recipe = the
parked spike branch `effect-spike @ 7f4100a5c`). Branch
`iris-refounding` (off `158080b88`, the S3 close); this slice's
commits: `ebce2b3ab` (threaded layer + T1), `354770966` (T2 + T3 +
the T4 park), plus this record. [AGENT] decisions are marked;
measurement numbers and transcripts are verbatim from this session's
builds/probes.

## 1. The threaded layer (`RelSem/Threaded.lean`, 204 lines)

- `initial_core_run_state_threaded` / `initial_driver_state_threaded`
  — the generated initial states mirrored field-for-field with the
  fresh-symbol supply seed EXPLICIT (the temporal-boundary mover,
  statement side; spike statement shapes reused).
- The threaded harness faces `CallHarnessAdequateThr` /
  `CallHarnessUBFreeThr` — the committed conclusion forms
  (relsemcore `RelSem/Call.lean:322/369`) word for word at the
  seed-parametric initial state. ∀-seed statements over them are
  STRONGER than the ambient originals.
- The adequacy bridges `kCallHarnessAdequateThr_of_wp` /
  `kCallHarnessUBFreeThr_of_wp` — the S1 statement-facing discharge
  (`kAdequate_of_wp` is already σ-generic) re-derived at the threaded
  state. Cones: EXACTLY the classical trio — with the ambient state
  out of the statement, `runEffectful` has no entry point.
- The LABELED impure side: `initial_driver_state_eq_threaded_ambient`
  (`rfl` — the ambient state IS the threaded one at the ambient
  draw), `callHarnessAdequate_of_thr` (∀-seed ⇒ ambient; "nothing
  lost"). These mention the ambient state and wear `runEffectful` BY
  DESIGN; pinned labeled in Audit.lean.

## 2. Per-fixture outcomes

### T1 — LANDED (`RelSem/T1Threaded.lean`, 583 lines)

Route: threaded run states (`rsD3_thr`/`rsR6_thr`/`drDone_thr`) →
per-stage `app` equations at NAMED threaded states (the S3 cheap
regime) → walker-free driver-round chain → `driver2_iter_thr` →
the S1–S3 WP walk over `callK` → the Threaded adequacy bridges.
Statements landed: `T1Threaded : T1ThreadedStatement` (the
`CallHarnessAdequateThr` face), `T1Threaded_ubFree`,
`T1ThreadedOutcomes` (the outcome-set singleton), + the labeled
sanity bridge `T1_of_threaded : T1Statement`.

What had to be built vs reused:

- The spike's recorded open-state hazard held EXACTLY: the five
  resolution stages, the thread read, and the thread-setup update all
  close by `rfl` at the open state; the two MEMORY stages (argument
  injection, errno) must route through the kit
  (`app_liftND_active` + memory-level equations at CLOSED memory
  states — memory is seed-free on the T1 path). The spike's
  seed-free memory equations (`allocArg_eq`/`storeArg_eq` + side
  facts) were ported as-is (~90 lines).
- THE WALKER-FREE ROUNDS ([AGENT] design, replacing the spike's
  frozen-machinery chain): T1's seven mechanical rounds — whose arc-7
  hand lemmas were deleted when the arc-9 walker absorbed them — are
  RESTORED as ∀-run-state round lemmas in the committed T3AppEq
  hand-chain style (`round0_thr`…`round8_thr`, 2–3 proof lines each,
  intermediate arenas transcribed from the kernel's own reduction via
  the goal display; every transcription guess verified by `rfl` on
  the first build pass). The committed ∀-rs `round3` (the load) is
  consumed AS-IS; `round6_thr` (the conv eval; the one ambient round
  that pins the run state for label resolution) is the spike's
  28-line recipe at the threaded state. The chain is a 9-line
  term-mode composition.
  PURGE-RELEVANT NOTE for part 2: these restored lemmas + the same
  composition discharge the AMBIENT `dnms_chain` too (the ambient
  state is the threaded one at the ambient draw, definitionally) —
  T1AppEq's dependence on the frozen walker can be dissolved with
  them, shrinking the purge's blocker list.
- The WP walk `t1_wpK_thr`: 15 tactic lines (11 `wp_step`s feeding
  named-state equations + `iintro`/`wp_done`/`ipureintro`/`exact`).
  PROBE-VERIFIED VARIANT (session scratch, deleted): the S3
  `wp_pures` self-computing tactic also works at the OPEN state — an
  11-line script (`wp_pures` swallows the rfl-able stages; 4 fed
  equations: injection, errno, thread setup, the loop). [AGENT] The
  committed proofs stay in the fully-fed named-state style
  (deterministic, measured ~1 s/fixture); the probe pins that the
  tactic layer is not the bottleneck at open states.

### T2 — LANDED (`RelSem/T2Threaded.lean`, 374 lines)

The recipe pays off: of T2AppEq's sixteen driver rounds, FIFTEEN are
∀-run-state committed lemmas consumed AS-IS at the threaded run-state
ladder (`rsD3_thr`/`rsB_thr`/`rsAB_thr`); only `round13` (the Erun
eval round — label resolution pins the run state) is twinned
(28-line fixed recipe, rs-generic `fullEval_conv_eq` reused). Prefix
memory stages through the kit (T2AppEq's alloc/store equations
reused, seed-free). Same statement family + WP walk (15 lines).

### T3 — LANDED (`RelSem/T3Threaded.lean`, 371 lines)

Of T3AppEq's twenty-four rounds, TWENTY-THREE consumed AS-IS
(create/store/load/kill memory rounds included — they are ∀-rs with
the aid bump generic); only `round21` (conv chain #2 + save jump)
twinned. The 24-round chain is a term-mode composition over the
five-draw run-state ladder (`rs1_thr`…`rs5_thr`). Same statement
family + WP walk (15 lines).

### T4 — STOPPED, PARKED WITH DIAGNOSIS (charter stop clause exercised)

The charter's expectation ("T4's `fresh = 1048577` conjunct
DISSOLVES under ∀-seed") is CORRECTED by measurement. T4's exec path
READS the supply: the NEG-store transform draws two symbols
(`Symbol (digest()) seed SD_None`, supply increments 1 and 2), which
then (a) are INSERTED into comparison-keyed env maps
(`update_env patAnon1/2` → `fmapAddBy symbol_compare` at
T4Defs `e21`/`e38`) and (b) are LOOKED UP (`PEsym anon1/anon2`) in
later rounds. `symbol_compare` (generated Symbol.lean) is
digest-compare then Nat-compare on the drawn number. Session probes
(scratch, deleted; verbatim):

- P1 (ambient control) — GREEN by `rfl`:
  `symbol_compare anon1 symA529 = LemOrdering.LT` (the pinned seed
  1048577 kernel-computes; this is how the ambient rounds close).
- P2 (the wall) — RED, error verbatim:
  ```
  error: Type mismatch
    rfl
  has type
    ?m.3 = ?m.3
  but is expected to have type
    symbol_compare (anon1_thr seed) symA529 = LemOrdering.LT
  ```
  At an OPEN seed the comparison the env insert/lookup forces is
  kernel-stuck; every round from the `e21` bind on (≈35 of T4's 56
  rounds carry `e21`-derived envs) loses its `rfl` route — the
  treatment SPREADS, which is the brief's park trigger.
- P3 (the collision falsifier) — GREEN by `rfl`:
  `symbolEquality (anon1_thr 1680278659536745755) symA529 = true`
  and `symbol_compare (anon1_thr 1680278659536745755) symA529 =
  LemOrdering.EQ` — at seed = symA529's hash number the freshly
  drawn symbol IS the static `a_529` to the semantics
  (`symbolEquality` ignores the description), so the env insert
  CAPTURES the static binding. **The unrestricted ∀-seed T4
  statement is FALSE**, not merely hard (epistemic status, audit-1 note: the COLLISION is kernel-witnessed by P3; the falseness conclusion additionally rests on the capture argument over the e21 arena — argued, not end-to-end-run-witnessed; the park-and-relax response is correct under either reading): no machinery improvement
  can prove it.

THE PRICE FOR PART 2 (the contained fix, estimated M):

1. Statement: the fresh conjunct RELAXES (not dissolves) to a
   seed-apartness hypothesis — e.g. `seed + 1 < hmin` with `hmin`
   the minimum static hash number in t4File's symbol table
   (kernel-computable; the ambient draw 1048577 satisfies it), or a
   per-key ≠/order conjunction. Decidable, boring, ∀-seed-under-
   hypothesis remains strictly stronger than the ambient pin.
2. Machinery: an env-algebra lemma layer — `fmapAddBy`/lookup on
   comparison-keyed maps under symbolic-order hypotheses (canonical
   ordered-map reasoning; one-time, reusable for every future
   supply-reading program).
3. Labor: the ≈35 `e21`/`e38`-dependent rounds re-derived
   lemma-driven (their `rfl`s force the stuck comparisons); each
   mechanical, none free. This is deliberately NOT done here: it is
   bulk re-derivation the part-2 machinery (or a run-state-generic
   round treatment) should structure first.

The ambient T4 (T4EnvHyp route, `= 1048577` pin) stands unchanged;
`T4Threaded` is deliberately absent from the statement gate's slate
list (noted in-gate).

## 3. The measurement (charter verdict data)

| Fixture | ambient AppEq footprint (lines) | threaded NEW text (lines) | of which twins of rs-pinning objects | committed rounds REUSED | WP proof body | first elaboration |
|---|---|---|---|---|---|---|
| T1 | 862 (T1AppEq; chain walker-driven) | 583 | ~490 (incl. the 7 RESTORED mechanical rounds + spike memory block) | 2/9 (round3; round6 recipe) | 15 lines (11 probe-verified) | 1.1 s |
| T2 | 1381 (T2AppEq) | 374 | ~120 (round13 twin + prefix/kit + ladder) | 15/16 | 15 lines | 975 ms |
| T3 | 1277 (T3AppEq) | 371 | ~110 (round21 twin + prefix/kit + ladder) | 23/24 | 15 lines | 955 ms |
| T4 | 2234 (T4AppEq+Defs) | 0 (parked) | — | — | — | — |
| shared | — | 204 (Threaded.lean, one-time) | — | — | — | 749 ms |

Reading the table honestly: the RE-PROOF (the WP walk through the
S1 language + S3 tactics + threaded adequacy) is 15 lines per
fixture — the charter's tens-of-lines bar, met. The supporting
threaded text is 371–583 lines/fixture, dominated by ∀-seed twins of
exactly the objects whose statements pin the ambient state; where
the ambient file's rounds were already frame-parametric (T2: 15/16,
T3: 23/24) the twin cost collapses to ONE eval round + prefix +
composition. T1 paid extra to RESTORE what the walker had absorbed
(a one-time repayment of chase-era debt that also unblocks part of
the purge). Elaboration: ~1 s/fixture — no budget pressure anywhere
(default heartbeats/recursion throughout; zero bumps).

## 4. Cones (VERBATIM, session probes; the trio-cone family Audit-pinned build-fatally — dnms_chain twins covered transitively via the pinned app-eq cones)

```
'RelSem.Cerb.kCallHarnessAdequateThr_of_wp' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.Cerb.kCallHarnessUBFreeThr_of_wp' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.T1.round0_thr' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.T1.round6_thr' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.T1.dnms_chain_thr' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.T1.driver2_iter_thr' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.T1.t1_app_eq_thr' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.T1.t1_wpK_thr' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.T1.T1Threaded' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.T1.T1Threaded_ubFree' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.T1.T1ThreadedOutcomes' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.T2.round13_thr' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.T2.dnms_chain_thr' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.T2.t2_app_eq_thr' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.T2.t2_wpK_thr' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.T2.T2Threaded' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.T2.T2Threaded_ubFree' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.T2.T2ThreadedOutcomes' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.T3.round21_thr' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.T3.dnms_chain_thr' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.T3.t3_app_eq_thr' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.T3.t3_wpK_thr' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.T3.T3Threaded' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.T3.T3Threaded_ubFree' depends on axioms: [propext, Classical.choice, Quot.sound]
'RelSem.T3.T3ThreadedOutcomes' depends on axioms: [propext, Classical.choice, Quot.sound]
```

The labeled impure side (mentions the ambient state, BY DESIGN):

```
'RelSem.Cerb.initial_driver_state_eq_threaded_ambient' depends on axioms: [propext,
 runEffectful,
 Classical.choice,
 Quot.sound]
'RelSem.Cerb.callHarnessAdequate_of_thr' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound]
'RelSem.T1.T1_of_threaded' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound]
'RelSem.T2.T2_of_threaded' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound]
'RelSem.T3.T3_of_threaded' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound]
(sixth member, audit-1 count correction: 'RelSem.Cerb.initial_core_run_state_eq_threaded_ambient' also wears the quartet — in-file labeled, unpinned, impure by statement text)
```

## 5. The tagDefs/forceIO seam (brief task 3)

Verified across every threaded cone above: `CerbTags.with_tagDefs`
and `CerberusFresh.forceIO` appear in NONE of them — nor in the
ambient T1–T4 cones (Audit pins: `[propext, runEffectful,
Classical.choice, Quot.sound]` exactly). The spike's survey stands:
those two boundary axioms enter only via Mini_pipeline's const-expr
driver and Main's per-TU loop — compiled-path surfaces outside every
theorem cone. There is therefore NOTHING TO THREAD at theorem level
in this slice; the axioms remain on the declared boundary (TEMPORAL,
compiled path) with the census unchanged. The T4EnvHyp
tagDefs/digest conjuncts are hypothesis-pins on opaque externs, not
axiom carriers — a future threaded T4 keeps them as hypotheses
(their elimination is a different mover: modeling the tag table and
digest inside the machine state, cmm-arc-adjacent, unpriced here).

## 6. Gate tightening (rides the slice commits)

- Audit.lean: 28 new `#guard_msgs` cone pins (trio-exact for the
  threaded family; quartet LABELED for the ambient bridges).
- Statement gate: the threaded family joins the slate list (16 → 25
  statements checked fuel-opsem-clean); statement vocabulary
  allowlist grows by exactly `initial_driver_state_threaded` +
  the three per-fixture `drDone_thr` terminal states.
- Sweep re-baselined 3904 → 3983 → 4050 (Threaded/T1Threaded then
  T2/T3Threaded; provenance comments at the pin).
- The axiom CENSUS is untouched (the boundary axioms still exist for
  the compiled/driver path — what tightened is the theorem-cone
  assertions), per the brief.

## 7. What remains expensive (the honest paragraph for part 2)

The per-fixture WP walk is cheap (15 lines, ~1 s) and the tactic
layer works at open states (`wp_pures` probe) — the EXPENSIVE thing
is the EQUATION SUPPLY the walk feeds on. Three specific costs
remain: (1) whole-loop equations (`driver2_iter`-class) still come
from AppEq-style round chains — the S3 law library's per-round WP
rules attach to the PEELED expressions, whose tactics-alone use is
parked at the S3 compute-forward wall, so per-fixture round chains
(re-derived at the threaded state when they pin it) remain the fuel;
T5-class loops cannot get a whole-run equation at all, which is
exactly part 2's T5-by-invariant work. (2) The label-resolution eval
rounds pin the concrete run state and force a per-fixture twin
(~30 lines each; T2/T3's ONLY twins) — factoring the labeled-
continuation lookup from the aid-supply ladder would make them ∀-rs
and kill the last per-fixture round text. (3) Supply-READING
programs (T4-class) need the env-algebra layer under seed-apartness
hypotheses (§2/T4) before any ∀-seed statement is even true —
ordered-map reasoning, canonical, M-sized, and a prerequisite for
threading any program whose compiled form contains the NEG-store
transform (i.e. most struct-store programs). Honest summary: the
Iris machinery discharges statements cheaply once per-step equations
exist; making the EQUATIONS fixture-independent is the remaining
scaling frontier, and it is part 2's charter (peel-route stepping at
named states, per-construct laws over the arena vocabulary,
T5-by-invariant).

## 8. The S4 verdict against the charter bar

- Statements: threaded conclusion forms are the committed faces at
  the seed-parametric state, ∀-seed in front — STRONGER than the
  ambient originals, which are re-derived as corollaries (the
  labeled bridges). Statement-TCB preserved (gate-checked, 25
  clean).
- Cones: T1–T3 threaded families EXACTLY
  `[propext, Classical.choice, Quot.sound]` — the charter's success
  criterion, met; `runEffectful` eliminated from every threaded
  theorem. T4: the criterion is UNREACHABLE AS STATED (the ∀-seed
  statement is false — kernel-witnessed collision falsifier); parked
  with a priced, contained fix. Per the charter's own stop clause,
  this diagnosis is a successful S4 outcome for that fixture.
- Cheapness: WP re-proof bodies 15 lines/fixture at ~1 s; supporting
  threaded text 371–583 lines/fixture with 70–96% round reuse where
  the ambient files were frame-parametric. The machinery was not
  fought anywhere T1–T3; T4's wall is semantic, not mechanical.
- VERDICT: S4 PASSES on T1–T3 with the effect-state elimination
  folded in; T4 exercises the stop clause with a
  charter-expectation CORRECTION (fresh conjunct relaxes, not
  dissolves) and a part-2 price. No budget bumps, no new axioms, no
  sorries, no chase-surface use (freeze gate 8/8 throughout).

## 9. Validation (verbatim, at `354770966` + this record's commit)

```
RelSem statement gate: 25 slate statements fuel-opsem-clean (negative tests: t1_wp and the wrapper-hole probe correctly rejected)
RelSem audit sweep: 4050 declarations (module-of-origin root RelSem, within RelSem.Audit's import closure — NOT the whole tree), all within the declared axiom boundary (0 recorded sorryAx exceptions)
RelSem DAEMON absence gate: no constant named DAEMON or DAEMON1 exists in the environment; neither is allowlisted
Total: 7 passed, 0 failed
check_chase_freeze: OK — no chase-surface imports/uses outside the legacy allowlist (8/8 allowlisted files present)
test_verify: 29 passed, 0 failed (5 fixtures, 18 harness points)
```

Probe scratch (`ProbeS4Cones*.lean`, `ProbeT4Seed.lean`,
`ProbeWpPures.lean`) deleted before commit; this record preserves
the content. No edits to any ambient statement, committed theorem,
or existing proof file — pre-existing files touched only by additive
registration (lakefile roots, RelSemAll imports, Audit imports +
pins + statement-gate rows + sweep re-baselines).
