# Arc 18 C4 — STATEMENT HOMING + SPECLAB THREADING + family-∀ (record)

Worker record, 2026-08-26. Charter:
`2026-08-25_arc18-coherence-charter.md` slice C4; contracts doc
`2026-08-25_reasoning-layer-contracts.md` (register row R6 closes
here; retirement register entry 4's speclab rows execute here).
Branch `coherence`; this slice's commits: `963b4b52d` (homing +
threading) and `761e1aaaf` (family-∀ targets + the drive-law yield +
this record).
[AGENT] decisions marked; quoted outputs verbatim from exit-checked
runs.

## 1. R6 — THE STATEMENT HOMING (CLOSED)

`RelSem.Threaded` MOVED (never mirrored) from the proof package
(`relsem/RelSem/Threaded.lean`, born arc-16 S4) to the SEMANTICS
side: `relsemcore/RelSem/Threaded.lean`, a new root of the root
package's exec-facing `RelSemCore` lib. One definition site; the
proof package imports it; module name, namespace (`RelSem.Cerb`),
every declaration name, and every moved statement TEXT byte-stable.

- Moved: `initial_core_run_state_threaded`,
  `initial_driver_state_threaded`, `CallHarnessAdequateThr`,
  `CallHarnessUBFreeThr`, `callHarnessUBFreeThr_of_adequateThr`, and
  the three LABELED ambient-bridge lemmas (still on the no-cone
  gate's 112-name carrier pin — the gate scans by module root, so the
  move is scan-neutral; verified by the gate's exact-count green).
- NEW, homed beside the call faces (contracts §5 target vocabulary):
  `HarnessRunsToThr` — THE WHOLE-PROGRAM PRIMARY FACE (the speclab
  `HarnessRunsTo` shape at the threaded initial state; the audit-1
  MINOR-1 deliberate-divergence label carried) — and `specifiedInt`
  (moved from speclab DivModFiles; one home).
- Mechanical footprint: root lakefile RelSemCore roots +
  `RelSem.Threaded`; relsem lakefile root removed; stale
  `relsem/.lake` Threaded artifacts deleted (the arc-11 stale-shadow
  hazard); `scripts/check_one_route.sh` live-module list re-pointed;
  `relsem/RelSem/CerbHeapWalk.lean` gains the explicit
  `import RelSem.PerStepCall` the old proof-side module re-exported.
- Audit sweep re-baselined 6772 → 6774 (the two homed defs;
  provenance comment at the pin).

## 2. SPECLAB SUBSTRATE THREADING (the S2b-registered cascade;
      THE PRIZE delivered)

All 46 (now 50, §3) gated statements + the 15 SpecLabProofs lemmas
re-landed at the threaded initial state:

- `HarnessRunsTo` (ambient) is REPLACED by the homed
  `HarnessRunsToThr` (not aliased — an alias would re-import the
  ambient cone). `HarnessFinalAllocs` threaded in place (seed
  parameter; quotes `initial_driver_state_threaded`).
- SEED QUANTIFICATION [AGENT, fail-closed]: every speclab statement
  takes the seed as an explicit PARAMETER and does NOT ∀-quantify it.
  Rationale: unrestricted ∀-seed claims are kernel-witnessed FALSE
  for some program shapes (the arc-16 S4 T4 hash-collision capture),
  and the speclab healthy faces are executable-validated, not
  kernel-proved — enshrining unproved ∀-seed claims would be the
  exact dishonesty the T4 diagnosis warns about. ∀-seed enters only
  in the family-∀ TARGET shapes (§3), where a future proof must earn
  it (or weaken to a guarded face per the T4-apartness pattern). The
  ambient originals are the images at the ambient draw
  (`initial_driver_state_eq_threaded_ambient`).
- The refutation schemas are re-derived seed-parametric and are now
  STRONGER as refutations (the plant's healthy claim refuted at every
  seed for which a run fact is exhibited, no ∀-seed detour).
- THE PRIZE (arc-17 S2b §6's endgame): every speclab statement and
  lemma cone is a TRIO SUBSET — `runEffectful` appears in NO speclab
  cone. All SpecLabAudit + SpecLabProofs pins re-captured verbatim
  (36 pins dropped the axiom; the ambient quartet is gone from the
  package). Repo-wide, `runEffectful`'s carrier set is now exactly
  the ambient relsem family (112 registered names, C5-bound).
- Gate registrations (same commits): SpecLabAudit's in-build TCB walk
  gains the exact-name allowlist `slAllowedSemanticsSide` (4 homed
  names, walked through — defense in depth; negative probe retained);
  `scripts/check_speclab_statements.sh` gains the two-line-form
  carve-out (`import RelSem.Threaded` + the canonical `open
  RelSem.Cerb (…)` line, byte-exact; everything else RelSem-shaped
  still fails). Operator provenance: the blessed arc-18 charter C4.
- The SLUnit gate exes are untouched (they run the compiled ambient
  pipeline against oracle-pinned verdicts; the statements' seedwise
  claims relate to them through the ambient-draw bridge).

## 3. family-∀ (R1/R5): TARGET SHAPES LANDED; the proof campaign
      PARKED at a measured engine frontier

Landed:

- `DivModI8FamilyStatement` (∀ seed, ∀ m, WfI8 m → …verdict 0) and
  `SwapFamilyStatement` (∀ seed, ∀ u64-pair — the R5 model is
  Wf-free) — the registered TARGET shapes, gated + pinned (trio),
  each with a kernel-checked family→sample link
  (`sample_of_family`, `swap_sample_of_family`: the validated finite
  faces are the targets' images — the anti-vacuity tie between
  target and evidence). Statement gate 46 → 50.
- HONESTY LABEL (in-file): both family statements are UNPROVED
  targets; the sample statements remain the executable-validated
  faces.

Proof machinery landed (the walk campaign's yield — all registry
content, engine-to-law compliant; law census 66 → 69):

- `Kit.mem_store_lock_block` (memBlock): the block-scope CONST-array
  initialization store (`storeM … true`) — plain store's byte write +
  the allocation readonly flip, RHS in INSERT-CANONICAL form (an
  autoParam `hallocs` equates the store body's whole-map `.map` with
  the single `insert`; ground states discharge it by kernel rfl —
  keeps the anchored allocations ladder navigable instead of
  accreting `.map` layers, a measured whnf cliff).
- `Kit.advance_memop_request` + `Kit.perform_memop_pvfd`
  (advance/perform): the Ememop surface's driver layer +
  PtrValidForDeref (state-preserving validity read; unfold lemmas in
  the advance_action_unfold discipline).
- THE MEMOP ENGINE LANE: `mintMemopRound`
  (`RoundEval/Rounds.lean`) + the `Step_memop_request2` dispatch
  branch (`Assembly.lean`) — a THIN registry dispatcher (advance +
  perform selected by goal form; hypotheses discharge through the
  standard side triple; an unregistered memop shape is a
  registry-miss frontier, never an engine branch). Query lesson
  recorded in-code: the memop ctor passes CONCRETE (its `sym` type
  argument is a pattern KEY; starring it kills the DiscrTree match).

Probe evidence (scratch probe, deleted per F9 hygiene; measurements
verbatim from the session): the divmod PLANT file's whole-program
drive walk — prefix via `derive_state_step` (driver_globals) + the
`callND_errno` law REUSED VERBATIM (the drive's errno block is
byte-identical to callND's) + a hand ready-state — minted
**74 rounds mechanically at open seed** (classes: tau/runstate/
create/store/store_lock/load/memop; the memop round at 160 ms), on a
program family whose Core is 1262 lines with FOUR law surfaces the
slate never exercised (the arc-15 S1 park list). Three of the four
fell this slice: the drive prefix (recipe above), store_lock, Ememop.

**THE MEASURED FRONTIER — round 75, the ground-mode materialization
envelope.** The load at round 75 dies in `evalGroundA "loaded bytes"`:
at a ~20-layer `writeBytesTo` ladder the bytemap projection is a
single whnf unit that forces every layer (200k-heartbeat cliff; the
identical cliff the arc-17 S2b MATERIALIZED-MEMORY TWIN solved for
hyp-mode drives — T4's depth was 7). Extending the twin to ground
drives was attempted and REVERTED in-session (park-don't-improvise):
the delta pass hit a SUBSTITUTION MISS at the second store_lock round
(the predecessor-memory spelling absent from the anchored successor —
full-ladder rematerialization, same cliff), and doing it right needs
the hyp machinery's defeq-substitution routes generalized — real
engine work, not a patch. No budget bumps anywhere.

REGISTERED REMAINDER (priced):

1. THE GROUND-MODE TWIN (M) — memMat init + delta maintenance for
   ground drives with substitution-robust deltas (the hyp-mode
   defeqSubst routes generalized); unlocks the divmod plant's
   full walk → whole-run drive equation → the UNCONDITIONAL
   refutation schemas (via `runND_active`-style bridges) and the
   ground half of family-∀. Natural home: C5-adjacent engine work or
   arc-19 (the search arc inherits the registry this lane extends).
2. Family-∀ PROOFS for R1/R5 (M–L after item 1) — open-m hypothesis
   packs + the arith minter over the division arithmetic (the same
   subsystem as T4's parked round-22 frontier); the walk recipe is
   now on file (this record + the probe transcript).
3. R2/R3/R4 family-∀ — REGISTERED with the T5-corrected-map
   dependency (loop/recursion machinery; charter C3b park), NOT
   attempted, per the brief.
4. The whole-program face's `finalize`/verdict bridge
   (`harnessRunsToThr_of_app_active`, S) — statement-side plumbing to
   land with the first whole-run equation; deliberately NOT landed
   ahead of its consumer.

## 4. Validation (verbatim, exit-checked)

At the homing+threading commit (`963b4b52d`):

```
Build completed successfully (368 jobs).   [root]
Build completed successfully (402 jobs).   [relsem]
Build completed successfully (147 jobs).   [speclab]
Total: 7 passed, 0 failed                  [test_unit]
test_verify: 35 passed, 0 failed (6 fixtures, 22 harness points)
test_speclab_divmod: PASS (--gate)
test_speclab_bytearr: PASS (--gate)
test_speclab_list: PASS (--gate)
test_speclab_tree: PASS (--gate)
test_speclab_seed: PASS (--gate)
```

Gate lines (verbatim, same battery):

```
info: RelSem/Audit.lean:1151:0: runEffectful no-cone gate: carrier set exact (112 registered ambient-family theorems; no acquisition, no stale entries)
info: SpecLabAudit.lean:132:0: speclab statement-TCB gate: 46 statements clean; wrapper-hole negative test detecting
check_one_route: OK — one state interpretation on the live route (34 modules OwnP-free; coexistence hazard clear; OwnP binders confined to the retirement register + the labeled T6 exemption)
check_speclab_statements: OK — 23 speclab statement file(s) clean (Iris/RelSem/native_decide/bv_decide/sorry ban)
```

At the family-∀/laws commit: speclab TCB gate line moves to
`50 statements clean`; relsem census pin `69 laws [advance 5, …,
memBlock 6, …, perform 6, …]`; full battery re-run green (tallies in
the commit message).

Re-baselines with provenance: audit sweep 6772 → 6774 (§1) → 6784
(the §3 laws + auxiliaries); step_law census 66 → 69 (§3);
statement gate 46 → 50 (§3). T1–T3/T6
threaded pins, T5 walk pins, cn_coverage and exec baselines: ZERO
movement (untouched, battery-verified).

## 5. Contracts/register effects

- R6: CLOSED (contracts doc row updated in-place).
- Retirement register entry 4: the speclab ambient substrate rows are
  EXECUTED (re-landed threaded); the ambient faces
  `CallHarnessAdequate`/`CallHarnessUBFree` + the ambient relsem
  family remain C5's inventory, unchanged.
- After this slice, `runEffectful`'s theorem-carrier set is exactly
  the ambient relsem family — the charter's C4 exit line, delivered.
