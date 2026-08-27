# V0 — statements, targets, and the ban (slice record)

STATUS: SLICE CLOSED at this record (the record ends the slice).
Provenance: the operator-ratified V0 brief (2026-08-27) under the
infrastructure plan (container `notes/2026-08-27_infrastructure-plan.md`
§3 V0, with the operator amendments: the Q3 freshness finalization —
"guards die now" — and the kill-quick basket) and the BLESSED design
catechism (`docs/2026-08-27_design-catechism.md`, the governing
document; its §VI self-check ran at slice start and at each commit
boundary). [AGENT] worker execution throughout; quoted outputs are
verbatim; derived tallies labeled. THE HONEST-GAPS PRINCIPLE governs
this record: real gaps are stated as real.

## 0. Headline

The statement layer is FINALIZED and the proof ledger is HONESTLY
EMPTY: the ∀-seed + SeedApart guard shape is replaced by
quantification over CONSISTENT EXECUTIONS (the can't-happen-ND
formulation, with the anti-vacuity metatheorem proved once at the
trio); the T1–T5 walk engine rooms, the whole-run mint mode, and
Kit/Loop's iter_compose family are DELETED, retiring T1–T5 to
honest-unproved statements — the repository holds ZERO proved
flagship theorems, ratified and intentional. FOURTEEN of the fifteen
frozen-corpus rows are registered as honest-unproved TARGETS in the
new house shape (P13 is an operator finding, §7.1), all under the new
CONCRETE-INPUT BAN riding the statement-TCB gate (negative-probed
both directions, in-build). The two censuses (exec-cone opaques;
runEffectful call sites) are published with recommendations (§5);
FF-1 is diagnosed and fixed (§6). Full Tier A green at every commit.

## 1. Commits (all on `arc/segment-ladder`; each verified green
      before its claim)

| # | SHA | Content |
|---|---|---|
| 1 | `69a6cec3f` | Freshness finalization + kill basket (a)(b): consistency layer, walk-room/mint-mode/Kit-Loop deletion, T1–T5 → honest-unproved, gate re-registrations |
| 2 | `0ba772a41` | Kill basket (c): speclab family-∀ targets deleted (superseded by the corpus slate) |
| 3 | `cadd3632d` | THE CONCRETE-INPUT BAN (statement-gate axis + permanent plants) |
| 4 | `1caa9891a` | Corpus slate batch A (P01/P02/P03/P09/P10/P11/P12) + fixtures + samples |
| 5 | `b0c26503a` | FF-1 fix (probe recipe + orphan purge) + register edits + charter banner |
| 6 | `1935f3014` | Corpus slate batch B (P04/P05/P06/P07/P08/P14/P15 — parametric families) |
| 7 | (this commit) | PROOF.md truth pass + this record |

## 2. THE FRESHNESS FINALIZATION (deliverable 1 — the Q3 amendment)

New layer in `relsemcore/RelSem/Threaded.lean` §CONSISTENCY
(statement-TCB home, fuel-opsem-only):

- `freshDrawsOf seed st'` — a terminated execution's draw window
  `[seed, st'.core_run_state0.sym_supply)` (the arc-13 state-threaded
  supply makes the window readable off the final state).
- `ConsistentRun prior seed st'` — the draws are NON-CAPTURING:
  pairwise distinct ∧ disjoint from `prior` (the program's static
  symbol-number vocabulary). Assume-not-assert: statements CONSTRAIN
  consistent executions and say nothing about capturing ones — the
  excluded set is named for what it is (the arc-16 S4 P3 falsifier
  class) instead of bounded around with per-program numerals.
- The faces: `CallHarnessAdequateCns` / `CallHarnessUBFreeCns` /
  `HarnessRunsToCns` — ∀ seed, ∀ enumerated outcome, consistency of
  the outcome's own window → Active + spec. QUANTIFICATION HONESTY
  (stated in the docstrings): the executions ranged over are the
  counter refinement's (one per seed); the fully-ND allocator
  formulation stays the chartered cmm-arc form, per the [USER
  2026-08-24] sequencing ruling.
- THE ANTI-VACUITY METATHEOREM, proved once, kernel, cones pinned:
  `freshDrawsOf_nodup` (monotone ⇒ distinct — the counter
  refinement's correctness half; trio) and
  `consistentRun_of_supply_le` (a run whose final supply clears the
  prior vocabulary is consistent; trio). Per-program non-emptiness =
  this schema + a kernel bound check on the program's run, which
  arrives WITH the proofs (V1+); executably, every family is
  witnessed non-vacuous today by the sample lanes (§4.4). HONEST GAP:
  no kernel-checked run witness exists post-kill (no run equations
  survive), so "∃ a consistent terminating execution" is currently
  evidence-backed, not kernel-backed, for each family.
- DELETED with their gate rows: `T4SeedApart`, `t4MinStaticSym`,
  `T5SeedApart` (and the allowlist entries). Env-hyp pins
  (`T4EnvHypThr` tagDefs+digest, `T5EnvHypThr`/`CorpusEnvHyp` digest)
  are UNCHANGED — they pin opaque externs, not seeds.
- `prior` is PINNED FIXTURE DATA (same trust class as the emitted
  program terms — same pinned sources), validated fail-closed by the
  new PriorCensus instrument gate (`relsem/RelSem/PriorCensus.lean` +
  the Audit `#eval` gate): the pinned list must equal the set of
  `sym.Symbol` numeric literals in the fixture term's syntactic value
  closure, exactly, both directions. TEMPORAL REGISTRATION: the
  instrument is untrusted-evaluator grade (test ledger); the mover is
  a total symbol-census function over the Core AST (V2-class — note
  the generated `Core_linking.free_expr` family, §5.1, is a natural
  donor). Plant transcript (verbatim, commit 1):

  ```
  error: RelSem/Audit.lean:612:0: PriorCensus gate: t1Prior is MISSING symbol numbers present in RelSem.T1.t1File's emitted term closure (re-pin deliberately, same commit, with the reason): [362773788461399393]
  ```

- FnSpec (`Segment.lean`) keeps its seed-indexed `guard` field with a
  V0 note: it is dormant proof-layer plumbing (all consumers died
  with the proofs); its restatement to the Cns faces lands with the
  V1/V2 re-target. The `Verified` role still speaks the Thr face —
  a documented, dated wart, not a silent one.

## 3. THE KILL BASKET (deliverable 4; R3/R5 method — fresh import
      scan, re-home-before-delete texts unchanged, same-commit gate
      re-registration, plants)

### 3.1 Deleted (commit 1)

| Class | Items |
|---|---|
| Walk engine rooms (~7,200 lines) | `T1Walks` `T2Walks` `T3Walks` `T4Walks` `T5Walks` `T5Inv` `T5Seam` `T5Spine` |
| The whole-run mint mode (647 lines) | `RoundEval/Assembly.lean` (the `derive_rounds` command + relative-chain assembly + whole-run terminal artifacts — assessment K-2b; the CHASSIS — Core/Hyp/Mint/Arith/Classify/Lanes/Rounds — STAYS per conversion C-5) |
| Kit/Loop (159 lines; conversion C-14) | `iter_compose`/`_from`/`_var`/`_var_from` + `roundSum` (+ `app_fuel_cast`/`fuel_split` — import-scanned, zero remaining consumers). `Seg.iter` (∃-round, Segment.lean, independently proved) is the survivor |
| The T1–T5 PROOFS | `T1Threaded`/`T2Threaded`/`T3Threaded`/`T4Threaded`/`T5Threaded` + `_ubFree` theorems, their in-file equation supplies (k-stage open equations, hand rounds, driver atoms, derive_state ladders), ~40 cone pins (tombstones at each removal site) |
| The ThreadedOutcomes statements | `T?ThreadedOutcomesStatement`+theorems (T1–T3) — exact outcome-LIST pins quoting internal terminal driver states (`drDone_thr`): concrete-trace data in statement costume (catechism §III.7 boundary call, documented in the tombstones; §VI q5 adjudication: the vocabulary they pinned was walk-room state, killed with it) |
| Speclab family-∀ targets (commit 2, basket c) | `DivModI8FamilyStatement`, `SwapFamilyStatement` + audit rows + cone pins — SUPERSEDED by the corpus slate. KEPT: codecs, models, ∀-bridges, `fileOfStream_encode`, mkHarness, both `--gate` lanes |
| Charter banner (commit 5, basket d) | `docs/2026-08-26_arc18-segment-ladder-charter.md` → SUPERSEDED header pointing at disposition + this record + the infra plan |

Statement vocabulary RE-HOMED text-unchanged before deletion:
`t1Fs`/`t1Spec` → T1Threaded; `t2Fs`/`t2Spec` → T2Threaded;
`t3Fs`/`t3Spec` → T3Threaded; `t4Fs` → T4Threaded; `t5Fs` → T5.lean.

### 3.2 The killed-by-registration register

The kill-list execution record's §3 deferral rows (walk rooms, seg*
supply, mint mode, iter_compose) are EXECUTED — early, at V0, per the
operator-ratified basket (their registered triggers were B-plan
re-proofs; the ratified V0 decision retired the proofs instead).
Remaining register content: ONE row — `LemLib.runEffectful` (lem-side;
§5.2 is its census).

### 3.3 The adequacy-smoke disposition (deliverable 4a's exemption
      clause)

NO end-to-end adequacy INSTANCE survives without the killed rooms:
the smallest one (T1) rode the hand-walk supply, which the brief's
kill list names explicitly — so, per the brief's fallback clause, we
SAY SO rather than keep the machinery. What stands as V1's regression
anchors: the wpk-level framing demonstration `two_alloc_frame`
(CerbHeapDemo, KEEP, trio-pinned), the four op rules + walk rules
(CerbHeapWP/CerbHeapWalk), and the GENERIC adequacy bridges
(`kCallHarnessAdequateThrHeap_of_wp` etc.) — all proved, all pinned.
V1's exit criterion (adequacy re-proof over the decomposed
interpretation) restores the end-to-end instance.

## 4. THE STATEMENT SLATE (deliverables 1+2 — 31 registered rows,
      ALL honest-unproved, consistency-freshness shape)

### 4.1 The T-slate (10 rows)

`T?ThreadedStatement` + `T?ThreadedUBFreeStatement` for T1–T5, each
`[EnvHyp →] ∀ inputs, pre → CallHarness{Adequate,UBFree}Cns prior
file fname args fs spec`. Statement texts CHANGED at V0 by design
(the freshness restatement — the old byte-stability regime ended with
the guards; the statement gate re-registered on the DEFS, walker
extended with the Prop-def seeding arm).

### 4.2 The corpus slate, batch A (14 rows — call-boundary)

Per `docs/2026-08-27_target-corpus.md` §2 (headline + UBFree each):
P01 clamp (∀x∈intRange: {Specified (max x 0)}); P02 sat_add (3-case
satAdd model; UB-freedom = the sequenced-&& guards proved); P03 swap
both-alias-arms (∀ a b ∈ intRange, alias ∈ {0,1} structural
disjunction: {Specified 0}); P09 call_contract (H4-closed pre
0≤a,0≤b,a+b≤INT_MAX−2: {Specified ((a+1)+(b+1))}); P10 gcd_rec + P11
gcd_iter (shared `Int.gcd` model at the full-range domain 0<a≤MAX,
0≤b≤MAX); P12 pt_midpoint (|coord|≤INT_MAX/2: {Specified 0},
frame-as-observable). Fixture terms: emitted decls
(`CorpusCore.lean`, drift-gated byte-identical) + assemblies
(`CorpusFiles.lean` — corpus stdlib = T1 closure + the params trio;
funinfo hand-pinned from the dumps' ccall annotations, incl.
void/pointer/const-struct signatures). Env hyps: `CorpusEnvHyp`
(digest pin) on all; `P12EnvHyp` adds the tagDefs pin (struct
layout).

### 4.3 The corpus slate, batch B (7 rows — whole-program families)

`CorpusEnvHyp → ∀ m, wf m → HarnessRunsToCns prior (pXXFileOf m) 0`
(one row per program — the Active conjunct subsumes UB-freedom):
P04 arr_sum (wf: 1≤|xs|≤2^20, elements int-range, EVERY PREFIX SUM
in range — the semantic no-overflow pre); P05 find_first (spliced
expected_idx = `List.findIdx`, the least-hit model); P06 arr_reverse
(expected[] = reverse xs); P14 count_pairs (n≤65536 derived bound;
countPairs model); P15 scan_classify (wf carries the ∃-NUL witness
`0 ∈ s` + uchar range; digitCount model); P07 list_sum / P08
list_reverse (THE SUMMIT: wf carries `List.Perm π (range n)` — the H2
quantified LINK-ORDER skeleton, ~n! shapes, as data inside
choices[]; struct-node arena builders with zeroed OVstruct
elements).

THE FAMILY MECHANISM (`CorpusBFiles.lean`; mkHarness lineage at the
Core-AST level): fixed code emitted from pinned `*_funs.core`
extractions (aggregates+fun-map sections; extraction
provenance-checked byte-identically per test_verify run); spliced
globals built parametrically over the dumps' create/store(_lock)/pure
glob spine with ALREADY-EVALUATED loaded values — the DOCUMENTED
initializer simplification (drops the unseq/conv_loaded_int
evaluation ceremony; semantically equal at wf-range values; validated
behaviorally at every sample, §4.4). The emitter grew SeqRMW / PtrEq
/ PVnull arms (loud-growth contract — each was a hard error first).

### 4.4 The samples (the family→sample pattern, both twins)

- `EmitLeanCoreTest`: 21 call-boundary points executed on the
  ASSEMBLED batch-A theorem objects + 7 whole-program DRIVES through
  the batch-B family builders at the corpus .c sample splices — all
  `Specified(0)`/spec-exact (verbatim tail, final run):

  ```
  ok   drive p15 'a7.9' = Specified(0)
  ok   drive p07 heads[4,-1,7] pi[1,2,0] = Specified(0)
  ok   drive p08 heads[1,2,3] pi[2,0,1] = Specified(0)
  EmitLeanCoreTest: ALL PASSED
  ```

  (The drive runner accepts agreeing outcome SETS — exhaustive mode
  enumerates unsequenced-evaluation orders. COST NOTE: the exe now
  runs ~47 s — the two 2^20-struct arenas dominate; priced here, on
  the Tier A budget deliberately.)
- `test_verify` corpus lane: 14 fixture provenance checks (8
  byte-identical dumps incl. p14; 6 content-hash pins for the
  16–94 MB arena dumps — the libc.core B-F5 pattern) + 7
  funs-extraction provenance rows + 7 main-mode oracle-vs-lean
  differentials + 21 harness rows vs pure-spec values.

## 5. THE CENSUSES (deliverable 5; read-only instruments)

### 5.1 Kernel-opaque constants in the Core evaluator's cone

Method: meta transitive-closure walk from
{`RelSem.Cerb.callND`, `drive`, `driver2`, `Core_eval2`}, collecting
`opaqueInfo` constants (partial defs compile to opaques). 36 total;
the 20 project rows (Float/String/Init internals excluded):

| Class | Constants | Disposition |
|---|---|---|
| THE totalization order (component E) | `are_compatible` [AilTypesAux] | The known one — V4's lem-side fuel totalization (plan Q5); blocks the call rule |
| Monadic folds | `foldlM` [State], (`stExcept_foldlM`/`foldrM0` [State_exception] are in-tree but did not appear in this cone) | fuel-totalize with E, same move |
| printf/scanf machinery | `printf_aux`, `store_chars_in_array` [Formatted]; `many`, `many1`, `string0` [Monadic_parsing] | reachable via the formatted-IO path; NO corpus row exercises printf — totalize opportunistically or park behind a documented boundary when V2 hits them |
| Call plumbing | `mk_stdcall_aux` [Translation_aux], `get_with_address` [Cerb_attributes] | small; ride the E slice |
| Derived-instance stragglers | `instBEqCore_base_type.beq` [Core], `_private.CerbMem.beqMemValueSafe` [CerbMem] | instance-method opacity; the lem-backend derived-BEq lane / hand-written CerbMem partial — S-priced each |
| Extern opaques (the DECLARED boundary — not totalization targets) | `CerbTags.tagDefs`, `CerberusFresh.digest`, `CerbDebug.get_level`, `CerbGlobal.current_execution_mode`, `CerbGlobal.using_concurrency`, `CerberusImpl.typeof_enum` | env-hyp/pin class (two already appear in statements as pins) |
| Loud-failure opaques | `failwithI`, `fuelExhaustedWith` [LemLib] | fail-stop by design |
| Float boundary | `floatSpec` + `Float.*` [Init] | the permanent kernel/compiler boundary |

RECOMMENDATION: V4's E-slice work order = `are_compatible` + the
monadic folds + call plumbing (one lem-side fuel pass); the printf
family is the surprise budget V2 should EXPECT to hit only if a rule
crosses formatted IO (no corpus row does). BONUS FIND for the prior
census's mover: `Core_linking.free_pexpr`/`free_expr`/
`symbols_in_pattern` — GENERATED symbol collectors (partial; fuel
totalization gives the kernel-grade census function almost for free).

### 5.2 `runEffectful` call sites (carrier set already 0, gate-pinned)

Genuine generated call sites: NINE. `Symbol.lean` ×7 (the ambient
fresh-symbol makers — `fresh`, `fresh_pretty`, description variants)
+ `Translation_effect.lean` ×1 (elaboration marker draw) +
`Core_run_aux.lean` ×1 (`initial_core_run_state`'s supply seed — the
one that ever mattered for statements; already bypassed by the
threaded twin). All other textual hits are comments/docstrings/gate
strings. CLASSIFICATION: 8 sites are LOAD-BEARING EXECUTABLE
PLUMBING of the C→Core elaboration pipeline (parse/desugar/elaborate
— ambient supply by design; OCaml-parity face); 1
(`initial_core_run_state`) is DELETABLE-BY-SMALL-LEM-SLICE via the
proven effect-spike route (seed the initial state; zero lem-backend
changes were needed for the spike's statement side).
RECOMMENDATION: take the small slice for `initial_core_run_state`
in the next lem arc (it retires the last theorem-adjacent site);
the elaboration sites retire together with the same arc's
supply-state threading — nothing in V1–V5 is blocked on either
(theorem cones already carrier-free, gate-enforced at 0).

## 6. FF-1 — the probe recipe (deliverable 6)

DIAGNOSIS (measured, repro'd both directions): `lake lean FILE` pins
only the file's DIRECT imports in the module setup it passes to
lean; transitive modules resolve via LEAN_PATH — and Lean's module
search COMMITS PER ROOT COMPONENT (`RelSem/`) to the first path
entry carrying that directory, no per-file fallback. With the
`RelSem` prefix split across two packages (root `RelSemCore`:
Call/Machine/RunND/ExecModel/Cerberus/Threaded vs the relsem proof
package), whichever tree wins the commit loses the other's modules
("object file … does not exist"). Flipping LEAN_PATH order flips
which side fails — the layout cannot be served by path search at
all. `lake setup-file` computes the COMPLETE per-module artifact map
(both trees, correct).

FIX: `scripts/lean_probe.sh` — `lake setup-file` + `lean --setup`,
memory-capped, run from the owning package dir. Both charter repro
files (`RelSem/SegmentFaces.lean`, `RelSem/RoundEval/Rounds.lean`)
elaborate green through it. ORPHAN PURGE executed: the arc-11-era
artifacts stranded in the ROOT `.lake` (RelSem/{Audit, FuelHooks,
Kit/* incl. a stale copy of the now-deleted Kit/Loop, SlateCore,
SlateFiles, T1Core, T1File}, lib + ir trees) are deleted — the
stale-shadow hazard is gone; the six RelSemCore modules remain
root-side by design. `lean_frontend/CLAUDE.md`'s probe section
rewritten (neither `lake lean` nor `lake env lean` is correct for
this layout; `lake build RelSem.<Mod>` remains right for lib
members).

## 7. FINDINGS for the operator (stop-and-report items)

1. **P13 (cell_alloc) — statement NOT registered** (the fifteenth
   row). Its designated function calls `malloc`/`free`; under
   `--nolibc` these elaborate to bodiless extern procs
   (`malloc_proxy` ccall) — a statement over the unlinked file term
   would be UNPROVABLE-AS-FALSE-SHAPED (stuck ccall), and the honest
   alternative quantifies the LIBC-LINKED file, which today has no
   statement-grade term (libc.core is 89,609 lines; emission or
   parse-at-statement-level are both new machinery). OPTIONS, priced:
   (a) linked-file term via a CoreParser-at-statement-level route
   (M; grows the statement TCB by the parser); (b) resolve at V5's
   alloc-ND design evaluation, which the corpus itself (H8) makes
   P13's outcome-set depend on anyway — the malloc MODELING decision
   may change what file the statement should quantify (RECOMMENDED:
   register P13 at V5's open, with the design decision); (c) a
   Core-intrinsic malloc modeling (bigger, semantics-side).
2. **P06/P08 wf carries `1 ≤ |xs|`** beyond the frozen §2 text: the
   empty instance needs an empty `expected[]` C array
   (inexpressible pre-C23; the mkHarness nonempty note; the bound is
   explicit in the corpus's own P04 row). Flagged per the frozen-
   corpus rule — operator may bless the bound or direct a re-freeze.
3. **The batch-B initializer simplification** (§4.3) is a documented
   term-level divergence from the oracle's elaborated initializer
   expressions (evaluation ceremony dropped, values pre-evaluated);
   semantically equal on wf domains, behaviorally validated at every
   sample. It is fixture-data-grade trust (as all emitted terms),
   named here for the audit trail.
4. **No kernel anti-vacuity WITNESS per family yet** (§2): the
   metatheorem is proved once; per-family non-emptiness is
   executable-evidence-backed until V1+ proofs land run bounds.
5. **EmitLeanCoreTest runtime** grew to ~47 s (the 2^20 struct
   arenas). Acceptable on the current Tier A budget; flagged for the
   ladder if it compounds.

## 8. Gate movements (same-commit provenance at every pin)

| Surface | Old → New |
|---|---|
| Statement gate slate | 13 theorem rows → **31 statement DEFS** (10 T-slate + 14 batch A + 7 batch B); walker gains the Prop-def seeding arm |
| THE CONCRETE-INPUT BAN (new axis, same gate) | — → live: quantified-input-flow obligation (per-face input positions), constant-args + ∈-literal-sample rejection, waiver list EMPTY ([USER]-tag required); permanent probes `constArgsProbe`/`finiteSampleProbe` must be rejected on every build; transient plant verified (registering the constant-args probe fails the build with the ban message — commit 3) |
| `stmtAllowed` | 24 → 46 rows (guards out; consistency vocabulary + corpus files/priors/models in) |
| PriorCensus gate | — → 19 pins exact (T1–T5 + 14 corpus), plant-tested |
| step_law census | 166 → 78 (seg* supply lanes emptied with the walk rooms; loop 5 → 1 — `Seg.iter` the survivor; ALL other engine lanes unchanged) |
| Audit sweep | 6024 → 2490 (kill) → 2505 (ban) → 2590 (batch A) → 2679 → 2698 (batch B) |
| runEffectful carriers | 0 → 0 (gate stands, fail-closed) |
| one-route live modules | 45 → 36 |
| engine size | 6964 → 6318 (Assembly deleted — the watch's first shrink) |
| relsem lakefile roots | 51 → 42 → 48 (kill; corpus modules) |
| check_speclab statements | 13 → 11 (family-∀ targets out) |
| test_verify | 63 → 105 → 112 checks (corpus lane: provenance + funs-extraction + main-mode + harness rows) |
| Corpus freeze gate | untouched — `target-corpus freeze OK (16 files match the pinned manifest)` at every run |

## 9. Validation (verbatim, final tree)

In-build gates (relsem `lake build`, green, 376 jobs):

```
info: RelSem/Audit.lean:710:0: RelSem statement gate: 31 slate statements fuel-opsem-clean + concrete-input-clean (negative tests: wpk_load, the wrapper-hole probe, the constant-args probe and the finite-sample probe all correctly rejected)
info: RelSem/Audit.lean:824:0: PriorCensus gate: 19 prior-vocabulary pins exact against the emitted fixture terms (both directions)
info: RelSem/Audit.lean:1253:0: runEffectful no-cone gate: carrier set exact (0 registered ambient-family theorems; no acquisition, no stale entries)
```

The consistency metatheorem cones, `#guard_msgs`-pinned in-build:
`freshDrawsOf_nodup`, `consistentRun_of_supply_le`,
`callHarnessUBFreeCns_of_adequateCns` — each exactly
`[propext, Classical.choice, Quot.sound]` (the V0 criterion; the
first and third entered at the trio via the List/omega lemma stock).

Full Tier A at the closing tree — every command exit-checked, ALL 16
lanes exit 0 (`TIERA_OVERALL_FAIL=0`); one line per lane, verbatim:

```
[0] ./scripts/test_exec.sh --check-baseline :: BASELINE OK
[0] ./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage :: BASELINE OK
[0] ./scripts/test_exec.sh --check-baseline=scripts/exec_debug_baseline.txt tests/debug :: BASELINE OK
[0] ./scripts/test_exec.sh --check-baseline=scripts/exec_float_baseline.txt tests/float :: BASELINE OK
[0] ./scripts/test_bytes.sh :: ALL AT COMMITTED EXPECTEDS
[0] ./scripts/test_libc_exec.sh :: ALL MATCH RECORDED BASELINE
[0] ./scripts/test_multi_tu.sh :: ALL PASSED
[0] ./scripts/test_parse.sh :: ALL PASSED
[0] ./scripts/test_core.sh :: ALL PASSED
[0] ./scripts/test_elab.sh :: SUMMARY: total=106 same=103 diff=3 ocaml_fail=0 lean_fail=0
[0] ./scripts/test_libxml2_uri.sh :: GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)
[0] ./scripts/test_cn_coverage.sh --check-baseline :: BASELINE OK (213 entries, exact match)
[0] ./scripts/test_immaculate.sh :: OK: lane matches the committed post-S1 baseline (mostly MATCH; the intended non-MATCH rows: g5-decode-question ORACLE_CRASH/L=63 and g5-escape-roundtrip DIFF/L=127 are oracle-wrong — upstream-tray #10/#11 — and g6 is TRIPWIRE).
[0] ./scripts/test_verify.sh :: test_verify: 112 passed, 0 failed (22 fixtures, 18 harness points, 14 corpus fixtures, 21 corpus points)
[0] ./scripts/test_speclab_divmod.sh --gate :: test_speclab_divmod: PASS (--gate)
[0] ./scripts/test_speclab_seed.sh --gate :: test_speclab_seed: PASS (--gate)
TIERA_OVERALL_FAIL=0
```

`test_unit.sh` at the same tree: exit 0, `Total: 6 passed, 0 failed`
(+ all gate scripts OK: exec purity/totality, theorem-axiom cones,
lem-sync, fork-drift, proof-size + corpus freeze, one-route, engine
size). speclab build:
`speclab statement-TCB gate: 11 statements clean; wrapper-hole
negative test detecting`.

## 10. The clause-(d) acceptance instrument (pre-registered, per the
      plan's V0 rider)

The per-row table every later slice fills in — the measurement exists
before any proof does. Columns: manual lines · invariant count ·
automation-frontier count · professor-readable (Y/N). Rows: P01–P15
(P13 pending §7.1) + the five T-slate anchors. All rows today:
UNPROVED (no entries) — the first entry is V2's P01, by mandate
reported to the operator with proof text verbatim.

## 11. Catechism §VI self-check at close

1. ∀-statements served: all 31 registered rows are ∀-input targets.
2. Amortization: the family builders + consistency layer + ban are
   once-built infrastructure; nothing per-instance was added.
3. Lineage: mkHarness template (families), can't-happen-ND
   (freshness — the [USER] model-level ruling), B-F5 content-hash
   pins, the ACL2Lean-C-5 chassis boundary for the kill.
4. Professor test: statements are boring fuel-opsem text; the ban's
   scope-honesty is documented where mechanical checks end.
5. Enumeration/concrete residue: the ban is live + negative-probed;
   the killed Outcomes statements were the last concrete-trace pins.
6. Failure mode: P13 and the wf bounds are REPORTED findings, not
   silent adjustments; the record is the stop.
7. Trust surface: statements layer-1 only; one gate axis added (the
   earned one); prior lists are declared TEMPORAL with a named mover;
   no new axioms, carriers still zero.
