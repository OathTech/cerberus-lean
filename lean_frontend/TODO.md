# TODO — semantics roadmap and backlog

Grouped by horizon. One line per item; depth lives in the pointed-at
records. (Verification-layer work is out of scope for this branch —
the semantics is the product here; a verification layer consumes it
downstream.)

The current work order is the [master plan](docs/2026-09-05_master-plan.md).
The validation-foundations [delivery record](docs/2026-09-06_validation-foundations-delivery.md)
closes its G1–G7 implementation/evidence goals. The next proposed arc is
[scoped SC integration](docs/2026-09-06_concurrency-integration-charter.md);
its adoption and landing require discussion. The current
[failure census](docs/2026-09-06_failure-census-and-correspondence.md)
supersedes older sampled counts. The legacy csmith run remains independently
owned and hands off; this roadmap does not authorize operating it.

## Queued larger work

- **Concurrency (cmm) instantiation** — concurrency is currently
  stubbed on mainline. The owned prototype has S0–S7 SC support and a
  repaired litmus instrument; integration still requires mixed-size/SeqRMW
  repairs or enforced restrictions, the provider agreement theorem, current
  mainline rebase/compatibility gates, audit and an explicit landing discussion.
- **A-road polish basket** — backend/semantics cleanups (pure-render
  emission split, remaining audit L-slice gaps, ott finish);
  itemized with prices in
  `docs/2026-08-31_semantics-forward-assessment.md` (the F-axes);
  deliberately parked behind the substantive track.

## Fuel-parameter arc — C2 follow-ups (record `docs/2026-09-04_fuel-parameter-C2-record.md` §9)

- ~~**Point-free `function` tails (6 PENDING rows; lem-lean TODO 17)**~~ —
  RESOLVED at C3 (2026-09-05, `docs/2026-09-05_fuel-parameter-C3-record.md`):
  lem d4ba548 hoists the scrutinee as `lemTail`; the six declares + proofs
  landed (`AilTypesAux_lemMeasureProofs`, `Core_reduction_lemMeasureProofs`),
  register 21 → 15. Residual: none of the six (the mutual blocks' measures are
  the derived sizes of the whole walked structure, proved sufficient).
- **Compatibility trio (three pending workers)** — the C4 layout measures
  discharged the six CerbMem layout/reconstruction rows under explicit
  `CerbTagsWf.Acyclic` hypotheses. `are_compatible_aux` and its two siblings
  follow deep pointer/function references; legal recursive-pointer cross-TU
  input is a reference nontermination case. By-value acyclicity is insufficient.
  Close-out D3 (2026-09-08): re-assessed, no honest hypothesis; the upstream-tray
  draft 37 (`docs/upstream-tray/37-…nontermination.md`) is WRITTEN with the
  reproducer `tests/failure-probes/cross_tu_node/` (both oracles rc=124 at 60 s,
  Lean stack overflow rc=134, single-TU control `Specified(7)`); MOVER: upstream's
  fix (an assumed-compatible set), or a lem body change (not Lean-only — C4 record
  §8 item 2(c), operator decision).
- ~~**`to_pure`/`to_pures`**~~ and ~~**`hack`**~~ — RESOLVED at the fuel-pending
  close-out (2026-09-08, `docs/2026-09-08_fuel-pending-closeout-record.md`, option C
  of the reachability census): MEASURED under the arena SHAPE hypothesis
  (`CerbCoreShape.IsValuePexpr` / `IsPureExpr` / `AllPureExprs`; one hop at
  `finalize`/`driver_globals` by `prepare_exit`, driver.lem:1309-1316 — the census's
  Q4 cite corrected in the record §2.1). The hypotheses are cited invariants, not
  theorems: a theorem about `drive`'s final state discharges them from
  `prepare_exit`'s definition (consumer-side; not done). Register 8 → 5.
- **`many`/`many1`** — PENDING with the precise blocker (close-out D2,
  `scripts/fuel_forms_pending.txt`): the recursion argument is the parser INPUT,
  bound inside the `ParserM` lambda (monadic_parsing.lem:38-40, :52-56, :100-103),
  never a head parameter; no parameter-level measure exists without a lem body
  change. MOVER: a lem-lean backend hoist through a single-constructor wrapper
  (the `lemTail` hoist applies to `function` bodies only). S–M (lem-lean).
- **Fuel-forms instrument repair** — P0 checked the exact worker/argument
  correspondence and zero-case shapes; its decoy plants now reject. Keep
  general propagation and completion proofs distinct from this instrument.
- **Fuel propagation/monotonicity for the 13 zero-case rows (Lem TODO 13)** —
  `arc/nd-fuel-stability` supplies completed-observation stability for the
  three CerbND runners and `nd_bind`/`liftND`/`liftAction`, with fixed operands
  and independently quantified worker/observer budgets (record
  `docs/2026-09-08_nd-fuel-stability-record.md`; full A+B green,
  adversarial audit PASS with its documentation finding resolved,
  external review pending; audit
  `docs/2026-09-09_nd-fuel-stability-adversarial-audit.md`).
  The other seven rows retain their obligations: `eval_pexpr_aux2`,
  `eval_pexpr_aux_broken` (outside the drive cone), `full_eval_pexpr`,
  `print_eval_conv_aux`, `drive_nonmemory_steps_aux2`, `driver2`, and
  `load_character_array_aux`. Increasing ambient fuel captured in callees
  needs separate composition proofs. The fuel-forms classifier still means
  kill-at-zero only; it does not certify stability or general propagation.
- **The defacto memory model is unreachable from `drive` (F-C2-4)** — 12
  fuel'd rows (9 measured) are dead code for the exec pipeline; decide
  whether they leave the exec-cone module lists (D-C2-7). S.

## Pure-failure correspondence — PARKED design, its tripwire (2026-09-08)

- **The F1 twin design is PARKED** (`docs/2026-09-07_pure-failure-correspondence-design.md`;
  the census `docs/2026-09-07_pure-failure-reachability-census.md` found 0
  DISCARDABLE among the 231 pure exec-closure sites; [USER 2026-09-07] chose option C).
  Its TRIPWIRE is the failure-reach register gate (`scripts/check_failure_reach.sh`,
  `scripts/failure_reach_register.txt`; test_unit.sh + LADDER Tier B row 11): flip
  conditions = a DISCARDABLE site that is REACHABLE (the gate's DISCARDABLE verdict on
  a generated dead let-binding, or the lem probe suite
  `tests/failure-probes/discarded_failures.lem`), a REACHABLE step-level site where the
  oracle SUCCEEDS (today 0 — the 36 one-sided rows are all `CerbFS`), growth of the
  well-typed-UB-free reachable set beyond 4, or an operator ruling for the logical
  property. The 17 UNKNOWN rows of the register (cross-TU compatibility ×4,
  sequential-fragment progress ×8, memory well-formedness ×4, one Eunseq shape) move
  only by a witness or an invariant, through `--emit`/`--reseal` in a commit. S per row.

## Risk-map baseline audit follow-ups (record `docs/2026-09-07_risk-map-baseline.md`, 2026-09-07)

All six surfaces MOVED-WITH-RULING, no MOVED-UNRULED. Documentary and
hygiene items the audit confirmed (each re-verified by the orchestrator):

- **R3 has no `-- ISO-fix register R3` code marker in `CerbMem.lean`** (audit
  §4; VALIDATION §2 already acknowledges it) — the existing C-Z4 item "R3
  marker + register/marker bijection gate" closes it; no new task.
- **`scripts/fuel_hypotheses.txt:43-46` and `CerbTagsWf.lean:19-40` state
  "Acyclic holds for every program the frontend ACCEPTS CORRECTLY" as a
  guarantee** (audit §3) — it is a CONJECTURE about the frontend with a known
  counterexample (F-A2), not a theorem; restate both as "conjectured frontend
  invariant; consumers discharge `Acyclic` at their entry (refined-cerberus
  does, FUEL.md)". Docs/comment only.
- **`CerbGlobal.lean:17` header comment "every read already returned these
  values"** is overbroad (audit §3; erratum in the cerbglobal record):
  `backend_name` moved `"cerberus-lean"` → `"Driver"` (mirror of `main.ml:124`).
  Fix the comment; state the non-Cn/non-Bmc argument as the execution-
  equivalence reason. Hand-written seam comment → rides the next seam slice.
- **Stale counts in comments/tables** (audit §5): `lean_frontend/test/Unit/TotalityProofTest.lean:21`
  "(64 at C1; 22 at C4)" is fine as history but the caller comment the
  audit read should say the CURRENT ambient pin count (22);
  `scripts/unsafebaseio_allowlist.txt:41` "66 -> 37 PIN" describes a later
  checkpoint (the tooling-inclusive count is 38: B 61 − 29 + 5 + 1, audit §4);
  `scripts/LADDER.md` Tier B row 9 cites a 90-case timing where the lane
  now reports `91/91`. Comment/table fixes; ride the next instrument slice.
- **`2026-09-06_csmith-sweep-post-p0.md` "12 TIMEOUT rows"** → 9 data rows
  (erratum appended to that record).
- Open obligations the audit lists as residual, all already carried: fuel
  monotonicity/propagation (lem TODO 13), native/logical correspondence
  (`beqMemValueSafe`, digest; F7), the pure-failure correspondence design
  (master plan step 2), C-P1 timing, consumer proof-check at the current
  pin (their step 6). Repeat risk map = master plan step 7.

## Fuel-parameter arc — C3 follow-ups (record `docs/2026-09-05_fuel-parameter-C3-record.md` §7–§8)

- **Eager `get_ctx` measure cost — resolved in the fuel-measure-cost worktree;
  remaining performance bar re-scoped.** The operator's standing price is
  "a price we pay, so long as it's truly <10% cpu … changing the trust
  surface is a high bar" [USER 2026-09-05]. The full 1,669-row before/after
  CPU instrument and pre-arc comparison are recorded in
  [the fuel-measure-cost record](docs/2026-09-07_fuel-measure-cost-record.md).
  Code `6ce040f06` replaces the full arena-size traversal with a proved
  conservative context-call bound; the obligation shape and trust cone stay.
  Landed 2026-09-08 (orchestrator review F1) as the NAMED structural
  definition `CerbCoreMeasure.getCtxBound` in the seam
  `lean_frontend/CerbCoreMeasure.lean`; the Lean `macro` D3 used to pass lem's
  FM-free validator is deleted and `CerbTagsWf.lean` is back to its mainline
  text (record, "Landing improvements").
  On 369/371, visible measure cost falls from about 45%/39% to 4.3%/4.6%;
  paired total CPU overhead versus pre-arc is 7.50%/7.29%.
  D4's 287-row paired table has one ratio exception, `sia_csmith_078.c`:
  +30.77% initially, +13.80% with all six runs retained, +5.14% in the fixed
  four follow-ups. The CPU spike is unreproduced; its exact cause is unresolved.
  `sa_csmith_419.c` remains TIMEOUT at 15 seconds (completed mean 15.62 s,
  pre-arc 14.50 s). The all-program property is not certified. Broader measure
  scope, a Lem fuel-scheme change, representation work or a revision bisect
  remain operator decisions; none is implemented here.

## Fuel-parameter arc — C4 follow-ups (record `docs/2026-09-05_fuel-parameter-C4-record.md` §7–§8)

- **The dead `[LemFuel]` binders of the layout oracle's callers (work-list
  item 2, second half).** The five layout wrappers, `reconstructValue` and
  `memValueToBytes` are fuel-free since C4, but the ~20 `CerbMem` functions
  that took `[LemFuel]` only to reach them (`sizeofIval`, `alignofIval`,
  `offsetofIval`, `loadM`, `storeM`, `arrayShiftPtrval`, … — `grep -c
  '\[LemFuel\]' lean_frontend/CerbMem.lean` = 23) still carry the binder,
  and mem.lem's `declare {lean} fuel_consumer val` rows (allocate_object,
  load, store, ne_ptrval, …) make their generated callers carry it too.
  Removing them is a Lean-only cascade (the declares are Lean-target lines;
  OCaml byte-identical by construction) that touches many generated heads —
  its own slice, with the generated-tree diff enumerated in a manifest for
  refined-cerberus. Until then the binders are dead (nothing reads the
  ambient fuel below them). S.
- **F-C4-1 — `Ctype_aux.are_compatible_aux` recurses through pointers and
  function types (STD §6.2.7#1 structural compatibility): a cross-TU pair of
  same-named self-referential structs (`struct node { struct node *next; }`
  in each translation unit, reached via `memValueFromValue` on a struct
  value crossing TUs) makes BOTH oracles recurse forever (rc=124 at 60 s)
  and the Lean driver fail loudly by NATIVE STACK OVERFLOW (rc=134, ~3 s —
  the recursion is not tail-recursive; the fuel is never reached; C4 audit
  §5.1/F-A7).** The three ctype_aux rows stay PENDING (no frontend-guaranteed
  hypothesis bounds them; by-value acyclicity does not). Reproduced by the
  pre-merge audit (its `node_a.c`/`node_b.c`); the upstream-tray draft is
  WRITTEN (close-out D3, 2026-09-08: draft 37 + `tests/failure-probes/
  cross_tu_node/`; TRUE BUG: the standard's rule needs an "assumed compatible"
  set for recursive types). Operator decision (filing; a lem body change).
- **F-A2 (C4 audit) — frontend GAP, upstream TRUE-BUG tray candidate:**
  `_Alignas(type)` on a CHARACTER-typed member bypasses the completeness
  check (`ailTypesAux.lem:1291-1292` `Just LT` → `cabs_to_ail.lem:2882-2883`
  stores `AlignType al_ty` unexamined), so `struct A { _Alignas(struct A) char
  c; }` (ISO §6.5.3.4#1 constraint violation; gcc rejects) is ACCEPTED; its
  table has a by-value self-edge, `CerbTagsWf.Acyclic` is false, both oracles
  hang, Lean gives the loud `CerbMem.memberAlign: fuel exhausted`. The
  hypothesis is honest and the register header says "for programs the
  frontend accepts correctly"; the tray draft is owed by the Z4 code half. S
  (draft) / operator decision (a frontend fix is a shared-semantics change).
- **Stack overflow vs fuel (C4 audit F-A7), for the mem-scale/stack-ceiling
  backlog:** deep NON-tail recursion in a fuel'd worker dies on the 8 MB
  native stack (rc=134 `Stack overflow detected. Aborting.`) long before the
  default fuel is consumed — the fuel is not the operative bound there; the
  harness reads it as a crash-class death, not FUEL. Cross-reference the
  mem-scale S0 survey's `STACK_OVERFLOW` item. M.
- **F-A8 (C4 audit NOTE):** `cerberus-lean --batch --fuel N a.json b.json`
  (two JSON inputs) is refused as `unknown flag` while the single-input form
  accepts `--fuel <N>` (`Main.lean` parses `--fuel` only on the single-input
  path); either the multi-TU form takes `--fuel` or the refusal says why. S.
- **A decidable acyclicity check as a load-time Tier C instrument.**
  `CerbTagsWf.Acyclic` is an existential over ranks (the natural hypothesis
  for the consumer); a bounded traversal computing ranks (or "definition
  order is a rank" on `fmapElements`, if the spine order is definition order
  — it is key order today) would let the differential lanes assert the
  invariant on every loaded program, with a theorem `check = true → Acyclic`.
  S–M.
- **Two csmith corpus rows MATCH→TIMEOUT — RESOLVED at 15 seconds in
  `arc/fuel-measure-cost`, code `6ce040f06`, instrument `5f14f0702`; landed
  2026-09-08 (`arc/fuel-measure-cost-land`).**
  `sa_csmith_369.c` and `sa_csmith_371.c` both read MATCH in the full
  HEAD-after lane (CPU 12.07 / 10.06 s) and the separate shard-2/6 check
  (11.48 / 9.64 s). Their baseline rows remain unchanged MATCH. The full
  lane reports `0 regression(s), 1 improvement(s)`: `sia_csmith_169.c`
  completed at 14.93 s CPU / 14.94 s wall against the 15 s budget. D3's
  dedicated instrument commit re-recorded it TIMEOUT → MATCH; the landing
  REVERTED that row (orchestrator review F2): no margin — a MATCH pin that
  times out under load is a FATAL regression, a TIMEOUT pin that completes is
  a non-fatal reported improvement — so it stays TIMEOUT, class-(b) pending,
  with the completion evidence in the record (LADDER load caveat). No other
  baseline row moved. The nine baseline TIMEOUT rows are still pending
  completions, including `sa_csmith_419.c`, which completed pre-arc and
  remains the measured budget exception.
- **Environment-measure eager cost — measured, remedy deferred.**
  `CerbTagsWf.envBound ambient ty` still traverses the tag environment on
  layout/reconstruction calls. The full-corpus instrument and D2/D3/D4
  profiles are in the same record: environment measures contribute at most
  0.25% on the final 369/371 profiles and 0.20% on the residual 419/078
  profiles. They do not explain the known regressions or provide a measured
  remedy for 419's remaining 15-second miss. All six wrappers and hypotheses
  are unchanged. The `refsOf ty = []` guarded bound remains a future
  candidate requiring a kernel-checked sufficiency proof and workload
  evidence; it is not implemented or claimed proved here. The measured
  subset does not establish an environment-cost bound for every program.

## Small items (independent; can ride along with any fix batch)

- **C-TF1 landed (2026-09-08, `docs/2026-09-08_monadic-failstop-record.md`) — follow-ups.**
  (a) Two escapers now exist: `CerbFail.escapeMessage` (per UTF-8 BYTE — the
  correct `String.escaped` mirror) and `Main.batchEscape` (per CODEPOINT — the
  registered P0 finding below). Unify on the per-byte one; a probe with a
  non-ASCII byte in program stdout is the tripwire. (b) Reasoning-artifact
  lens: `CerbFuel.fuelExhaustedLoc` and `CerbFail.modelFailStopLoc` are
  `opaque`s (boundary census 16); consumers cannot prove them different from
  any location. A transparent `def` (`Loc.other "…"`, kernel-decidable
  against every program location) would remove two boundary rows and let
  theorems case on the kill kind — operator decision (deviates from the C1
  Option-C precedent). (c) The immaculate pin label `L=CRASH` now also covers
  the typed fail-stop (exit 1) — rename to `L=FAILSTOP` in a re-record with
  justification if the coarse label becomes misleading.


- **Byte representation and printer producer contracts (M)** — corrected
  2026-09-06 after audit VF-07. `Main.batchEscape` handles the execution IO
  path's byte-carrier Chars: `driver_fs_step.update_stdout/update_stderr`
  append `String.ofList out_chars`, with one model byte per Char. Existing
  `tests/immaculate` libc fixtures already print bytes C3 A9 and FF and agree with
  OCaml's `String.escaped`. Converting these carriers to UTF-8 would corrupt
  that behavior (FF would become C3 BF). Keep those byte-preserving pins.
  Other producers passed to `batchEscape`, such as frontend parse errors,
  need separate analysis; the generic Lem String/Char representation debt
  and two Lem String XFAILs remain open. Trace each producer, specify its
  byte/text relation, then add missing boundary cases. No blanket printer
  conversion is justified. See the
  [observation contract](docs/2026-09-05_observation-contract.md#mainbatchescape-producer-trace)
  and [audit repair record](docs/2026-09-06_validation-foundations-audit-repairs.md).

- **Driver-freshness stamp: the oracle `bin` hash is not source-
  determined, and the switch's lem libraries are an uncovered link
  input (S)** — registered 2026-09-05 (pre-merge audit
  `docs/2026-09-05_cerbglobal-defs-audit-premerge.md` F3/§2.5; slice
  record `docs/2026-09-05_cerbglobal-defs-record.md` §5.3).
  (a) `ocaml_frontend/dune:12-18`'s `version.ml` rule (`(deps
  (universe))`, `tools/gen_version.ml` `git describe --dirty --always`
  + commit date) is linked into `main.exe` via `Version.version`
  (`backend/driver/main.ml:558`, `backend/common/pipeline.ml:659`), so
  the stamped `bin` hash moves with HEAD and the dirty flag at an
  unchanged `src` hash (three hashes at one `src` during the CerbGlobal
  slice) — a permanent reproducibility nuisance: either exclude
  `Version` from the oracle link (the string is printed by `--version`,
  never consumed) or document it in `tools/check_driver_fresh.sh`'s
  header. (b) The oracle links the switch-installed `lem`, `lem_num`,
  `lem_zarith` (`ocaml_frontend/dune:10`, transitively from
  `backend/driver/dune`); a lem RUNTIME change would relink the oracle
  at an unchanged `src` and could change behaviour invisibly to the
  stamp — today governed only by the pin invariant (branch heads = opam
  pin = Lake pin). Cheap extra leg: record `git -C deps/lem-pinned
  rev-parse HEAD` in the oracle stamp and compare on `--check`; at
  minimum name `lem*` explicitly in the header's non-goals. Neither
  blocked the CerbGlobal merge.

- **core_linking.lem's dangling `set_fold` declare (S)** — registered
  2026-09-03 (pin-bump record §8): `frontend/model/core_linking.lem:61-63`
  declares an UNUSED `val set_fold` with an OCaml rep `Pset.fold` and a
  Lean rep `CerbUtils.set_fold`; the Lean def was deleted at the 3c88f0d
  pin bump (dead, and its "sets are sorted lists" premise false). Remove
  the three lines in a slice allowed to touch the `.lem` (expected OCaml
  rendering delta: none — a target_rep'd val emits no definition — but
  the lem-sync source hash moves and the fork-drift review must re-run).
- **Lem-side record errata to carry to lem-lean (S, operator/orchestrator)**
  — from the 3c88f0d pin bump (record §7/§8): `doc/lean-backend/
  2026-09-03_parity-fix-record.md` §5's `CerbMem.lean:1352` "returns 0
  where the oracle RAISES" claim is false (impl_mem.ml:2479-2480 has the
  same zero guard); "CerbMem.lean (22) now render through lemNatDiv/…"
  is inaccurate (hand-written, not re-rendered); the impact list missed
  the transitive `Std.Data.TreeMap` import and proof-term dependence on
  `List.foldr` reduction (`test/Unit/FuelExemplar.lean`); `Utils.default0`
  did not revert to `default`.
- Step-runner execution ceiling — SURFACING NOTE (pin bump 3c88f0d,
  2026-09-03, record §5.4): `d_loop_1000000.c` lean-first now parks in
  the Lean runtime's stack-overflow handler (exit 124, `HANG(cpu 36.66s
  of 600.08s wall)`) instead of `Stack overflow detected. Aborting.`
  (exit 134) — reproduced 2+2 against the old-pin binary; same ceiling,
  same (b) class, different failure surfacing (the handler deadlock
  VALIDATION.md documents for the >7 M aggregates). `e_memcpy_1000000`
  still aborts (134, `STACK_OVERFLOW;`). The rest of this item is as
  measured at the FUEL arc:
  the PROCESS-STACK ceiling is BINDING
  AGAIN (measured 2026-09-03, FUEL arc record §6): at the coupled driver
  family's budget `CerbFuel.driverFuel` = 10^8 (the FUEL arc's budget
  commit; since the fuel-parameter arc C1 that budget is the `--fuel`
  default `Main.lean` `defaultFuel`, the same value), `tests/mem-scale-probes/probes/d_loop_1000000.c` and
  `e_memcpy_1000000.c` die with `Stack overflow detected. Aborting.`
  (exit 134, after 44.6 s / 99.8 s) while `d_loop_100000`/
  `e_memcpy_100000` complete with the oracle's values — onset between
  10^5 and 10^6 loop iterations for loop shapes. The 2026-08-30 re-
  characterisation ("the old process-stack overflow no longer
  reproduces; the binding ceiling is the fuel budget") described the
  10^6-fuel regime, where fuel exhaustion (~1.7e4 plain loop iterations
  / ~6e4 C-recursion depth) masked the stack. Harness reading: LEAN_CRASH
  (exit ≥ 128, `(no PANIC line captured)`), measure.sh note
  `STACK_OVERFLOW;` — fatal, never agreement, never FUEL. NEVER a stack-
  size knob (registered-defect shape); the structural fix is the
  stack-ceiling design's route: `docs/2026-08-31_stack-ceiling-design.md`;
  history: `docs/2026-08-19_arc6-s0-survey.md`. Fuel exhaustion itself
  is a TYPED outcome since the FUEL arc (`CerbND.fuelExhaustedKill`, the
  harness FUEL class; `docs/2026-09-02_fuel-arc-design.md`).
- Front-end `mkListN` ceiling (FUEL arc record §5, 2026-09-03): a zero-
  initialised local aggregate of 10^6 elements
  (`tests/mem-scale-probes/probes/b_zero_local_1000000.c`, and
  `_10000000`) dies in the FRONT END — `mkListN_aux_lemFuel` (called from
  `constructValue_aux` ← `wip_desugar_initializer`, symbolised from the
  panic backtrace) exhausts the fuel — `lemDefaultFuel` = 10^6 at the
  time; the ambient `--fuel` (default 10^8) since the fuel-parameter arc
  C1 — building the
  n-element list — as a pure-return-worker PANIC (exit 134, harness
  `FUEL(panic)`), unchanged by the driver-family budget (it is outside
  the coupled six; Q4). Evidence for a per-declaration budget declare on
  `mkListN_aux` (an operand-bounded measure: n elements) — a ruling item,
  not applied.
- **`finalize`/`hack` boundary** — the existing fixture lemma reduces
  finalization under singleton-thread/value-arena hypotheses. Since the
  fuel-pending close-out (2026-09-08) the value-arena hypothesis is NAMED
  (`CerbCoreShape.IsValuePexpr`/`IsPureExpr`) and its invariant CITED
  (`prepare_exit`, driver.lem:1309-1316, the only exit of `driver2`); `hack`,
  `to_pure`, `to_pures` are fuel-free under it. Still open: PROVE the hypothesis
  for `drive`'s final state (a theorem from `prepare_exit`'s definition; the
  singleton-thread part likewise), or implement the reviewed strict
  failure/completion design. No blanket "cheap closure" or unconditional fuel
  independence is established.

- Comment-only `.lem` cleanup (fuel-parameter C1, pre-merge audit N3):
  `frontend/model/defacto_memory.lem:2678`, `formatted.lem:327`,
  `monadic_parsing.lem:113` still name the deleted `lemDefaultFuel` in
  COMMENTS. Left deliberately: lem copies comments into the generated
  OCaml text, so fixing them moves `ocaml_frontend/generated` and breaks
  the C1 byte-identity invariant. Do it at the next `.lem`-touching
  upstream-facing change (or as a comment-only delta with the lem-sync
  stamp re-recorded, by operator ruling).
- Cross-block fuel threading in the lem backend (FUEL arc follow-up,
  design note §1.6 route iii): a caller's fuel passed into callee
  workers across `let rec` blocks (today the L1 mechanism threads fuel
  through self/block-member calls only — lean_backend.ml:2852-2863,
  :4088-4097 — which is why `drive_lemFuel` was a hand-written mirror
  until the fuel-parameter arc C1 made the generated `drive [LemFuel]`
  the fuel-parametric pipeline itself; the mirror is deleted).
  Motivation: the coupled-family analysis (stack-ceiling design
  :139-146). Class 0 (Lean emission only) but it changes every budget
  and consumer side condition in the call graph → next-lem-arc
  candidate, own design pass.
- Backend `sorry` target_rep refusal (FUEL arc rider, design note §5):
  lean_backend.ml:4044-4050 still renders a `target_rep … = \`sorry\``
  as `(sorry : <type>)` while the file header (:84) claims the
  sorry-emission paths are gone. Delete the special case and fail
  closed ("Lean backend: target_rep `sorry` refused"). Class 0, next
  lem arc (two-repo pin dance). FINDING recorded with it (arc record):
  frontend/concurrency/cmm_csem.lem carries 23 further `declare lean
  target_rep function … = \`sorry\`` declares (observable_filter,
  behaviour, …, overlap_behaviour) that are UNREFERENCED in the Lean
  build today (zero `sorry` tokens in the generated tree — gate
  `check_sorry_token.sh`); a refusing backend must either see them
  unreferenced or they must get real reps/`skip` before the pin moves.
- KNOWN HANG — FRONT-END stack-depth ceiling with a SILENT overflow
  (found 2026-09-01, arc/mem-scale P0; re-scoped R1 2026-09-02;
  profile `docs/2026-09-01_mem-scale-profile.md` §6.2-6.3): the Lean
  driver neither completes nor fails on a zero-initialised static
  aggregate of more than ~7-8 million ELEMENTS
  (`tests/mem-scale-probes/probes/a_zero_global_10000000.c`;
  `char g[8000000]` hangs, `char g[7000000]` and `int g[2500000]`
  complete; `--pp-core` ALONE hangs, so it is the front end, not
  CerbMem). strace: the working thread takes SIGSEGV SEGV_ACCERR
  (stack guard page of the runtime thread's 1 GiB stack) and then
  blocks forever in `futex(FUTEX_WAIT_PRIVATE)` inside the handler —
  no "Stack overflow detected. Aborting." Prime candidate:
  `cabs_to_ail_aux.lem:124` N-element ConstantArray →
  `ail/genTyping.lem:484` `E.mapM` → `ail/errorMonad.lem:86-92`
  non-tail `ailErr_mapM` (`generated/ErrorMonad.lean:121`, partial
  def; same shape `state_exception.lem:79` foldrM, `Undefined.lean:
  1390` sequence0). Oracle contrast: `OCAMLRUNPARAM=l=200000` fails
  LOUDLY in 0.03 s (exit 125). Three items: (a) fix = .lem
  accumulate-and-reverse (tray) or lem-backend tail rendering — a
  TWO-REPO slice; no equality theorem possible (partial def), gate =
  completion + battery; (b) Lean upstream bug report (signal-handler
  deadlock after guard-page SIGSEGV) with the strace excerpt; (c)
  interim LOUDNESS: HANG classification (exit 124 with CPU/wall <
  0.1) — DONE in S0 (2026-09-02): `scripts/common.sh classify_exit124`
  shared by `scripts/test_exec.sh` (status `HANG`, fatal) and
  `scripts/test_ci_sweep.sh` (`LEAN_HANG`/`CERB_HANG`); plant
  `scripts/test_hang_plant.sh` (sleep→HANG, busy→TIMEOUT, both lanes);
  the 10 M probe reads `HANG(cpu 3.29s of 400.12s wall)` in
  test_exec.sh; no committed row changed class. Item (b) drafted:
  `docs/upstream-tray/lean4/01-stack-overflow-handler-deadlock.md`.
  Never a stack-size knob (charter C9, `docs/2026-09-01_mem-scale-design.md`).
  RULED [AGENT 2026-09-02, orchestrator, operator-informed] (Q5): fix
  at source in the cerberus `.lem` (accumulate-and-reverse mapM; NOT a
  lem-backend change unless the completion gate shows the tail call
  is not realised — charter §6.0/§6.3); plant-tested completion gate
  = a_zero_global_10000000 Lean --first completes with the oracle's
  verdict, asserted as status, never timing.
  OUTCOME (mem-scale S1', 2026-09-02; record
  `docs/2026-09-02_mem-scale-record.md` §S1'): the `.lem`
  accumulate-and-reverse rewrite was built and measured — it moved the
  onset (8 M elements now COMPLETE with the oracle's verdict; 10 M
  still hang) — and then REVERTED per [USER 2026-09-02] ("revert S1'
  I think - poor roi for a change to the trust surface"). Mechanism
  located first-hand: our emitted C is tail-shaped (`jmp lean_apply_*`),
  but the Lean 4.32.2 RUNTIME's `lean_apply_1/2` enter the closure by
  indirect CALL on 22 of 24 arity paths, so every per-element closure
  application in a function-typed monad's run loop costs one
  `lean_apply_*` frame (~110 B/element; 1 GiB thread stack ⇒ ~8 M
  elements). STANDING CEILING, now LOUD (S0 HANG class); registered in
  VALIDATION.md §5. FALLBACK CANDIDATE for the next lem arc (class 0,
  Lean-emission-only, needs its own ruling): a lem-backend RUN-LOOP
  rendering of the monadic list combinators (`mapM`/`sequence`/`foldrM`)
  for function-typed monads — interpret the list inside the `run`
  function directly, no per-element closure application — so the
  OCaml text is untouched and the Lean side stops paying the runtime
  frame. Companion (runtime-side, upstream): make `lean_apply_*`'s
  exact-arity paths tail calls — noted in
  `docs/upstream-tray/lean4/01-stack-overflow-handler-deadlock.md`.
  Upstream-facing source fix drafted regardless: tray draft 18.
- ~~Harness memory limits use `ulimit -v`~~ — DONE (mem-scale S2,
  2026-09-02: `e02d4105a` migration of all 20 code sites + 2 header
  comments to per-test `scripts/capped` at `CERB_TEST_MEM_MAX=4G`;
  `e866357c6` OOM-witness classification; `de574fbc8` baseline
  instrument; record `docs/2026-09-02_mem-scale-record.md` §S2). The
  original item, for the record: `ulimit -v` (virtual address space) in
  SEVEN harnesses: `scripts/test_ci_sweep.sh:222,252,258`,
  `scripts/test_libc_exec.sh:82,90,97`, `tests/parity-probes/
  run_probe.sh:43,51,56`, `scripts/test_gcc_oracle.sh:361,368`,
  `scripts/test_libxml2.sh:141,159,191,201`, `scripts/
  test_libxml2_uri.sh:104,174`, `scripts/test_immaculate.sh:116,123,
  131` — and `scripts/LADDER.md:73` makes it normative (operator
  directive, arc 5). Lean's virtual footprint is ~2-3.6x its RSS, so
  a 4 GB `-v` kills Lean at ~1.7 GB RSS while the oracle runs to
  3.1 GB — the detective's two "OOM" rows were this artefact (profile
  §2); the libxml2 lanes are biased against Lean today. RULED [USER
  2026-09-02] ("Q2 agree"): superseded by per-test `scripts/capped`
  with `CERB_MEM_MAX=4G`; LADDER.md:73 text updated; migration of the
  seven harnesses + dedicated baseline-instrument commit = mem-scale
  S2 (charter §6.4); then re-run the class-(b) rows.
- **Tier-C CI re-record — measured 2026-09-06**: all 2,186 rows across
  15 suites were remeasured on repaired functional candidate `de9f6d361`.
  [Current results and the separate original history](docs/2026-09-06_ci-reporting-results.md)
  retain 1,359 agreements, one libc UB-location defect, three filesystem
  refusals and three Lean timeouts. The sole movement from `1066d89ee` is
  `pr63209.c`: CERB_TIMEOUT to LEAN_TIMEOUT at the unchanged 15-second budget.
  Fresh TSVs and both runs' raw records are retained in the evidence archives;
  the original 56 historical movements and default scoreboards remain unchanged.
  Remaining work
  is the registered semantic/completion obligations and remeasurement after
  relevant changes, not another run of this completed candidate measurement.
- **CerbFS real-fs mover + served-pattern probe family (S)** —
  registered 2026-09-02. `CerbFS` is a declared MODEL boundary
  (VALIDATION.md §5: in-memory filesystem; fail-closed since trust-
  basket item (b), `docs/2026-08-31_trust-basket.md` §2/§7 F1) whose
  served-subset POSITIVE coverage is thin (trust-basket §7 F3: zero
  corpus files exercise the served patterns). Two items: (i) a small
  served-pattern probe family (read, rewind-reread, read-only reopen)
  under `tests/parity-probes/` with recorded verdicts — S; (ii) the
  boundary's mover — either real-fs backing behind the same seam or an
  explicit refusal of every unserved op — S-M; the boundary stays
  declared until then.
- **Clean Lake packaging (M)** — forward-assessment F4.1
  (`docs/2026-08-31_semantics-forward-assessment.md`): a stable,
  documented exec-facing module surface, consumer-facing lakefile
  targets that do not drag the test exes, version tags, a one-page API
  doc. Customer #1 is `refined-cerberus` (pins this repo by path today).
  Registered here 2026-09-02 so the item has a home in the backlog.
- **Regeneration recipe: wipe the generated dir first (S)** — registered
  2026-09-02. `make lean-prelude-src` / `make prelude-src` regenerate
  INTO the existing `lean_frontend/generated/` / `ocaml_frontend/
  generated/` without clearing them; a file left behind by a removed
  `.lem` module lingers (the recipe hand-`rm -f`s the two known names
  from C1, `Core_unstruct*.lean`) and — because the lem-sync stamp is
  recorded over whatever the directory holds after the recipe — would be
  STAMPED as legitimate output (fail-open shape). Wanted: wipe-then-
  regenerate (hand-written copies re-copied by the same recipe), so the
  stamp covers exactly the recipe's output. Companion: Lake's
  `.lake/build` keeps orphaned artifacts too (the 2026-09-02 prune record found
  pre-split ones) — a clean-build leg at boundaries.
- **lem-side: refuse a target_rep spelled `sorry`** — lives in lem-lean's
  register (`lem-lean/doc/lean-backend/TODO.md` item 2, S): the backend
  still special-cases a user-written `sorry` rep; the one live consumer
  use is `frontend/concurrency/cmm_csem.lem` `observable_filter`
  (registered temporal boundary, mover = the concurrency arc above).
  Cross-referenced here 2026-09-02; discharged in the next lem arc.
- Speclab leak checks' oracle-differential leg: wire the new oracle
  `--batch-alloc-census` line (landed 2026-09-01,
  `docs/2026-09-01_s-basket.md`) into the speclab lanes.
- Upstream-tray candidate (found 2026-09-01, S-basket item 1): the
  sizeof/alignof Union arms read the Tags GLOBAL (impl_mem.ml:173,
  :255) while the rest of the layout family threads ~tagDefs —
  elaboration-time offsetof over a union-containing struct crashes
  upstream (probed, exit 125); pinned as a crash pair
  (tests/immaculate/nolibc/offsetof-union-member.c). NO TRAY DRAFT
  YET (stated explicitly 2026-09-02): drafting is S — repro from the
  pinned pair + the impl_mem.ml cites — mover: the next tray-drafting
  pass (`docs/upstream-tray/INDEX.md` filing checklist).

(2026-09-01: the pr44468 offsetof panic, the CoreParser `enum TAG`
arm, the `--args` flag, the allocation-census line, the DivMod
canonicity consolidation, the printf/Monadic_parsing totalization
tail, and the Lean-side lem-sync freshness stamp all closed in the
S-basket slice — `docs/2026-09-01_s-basket.md`.)

## Needs maintainer action or network access

- **Upstream filing tray** — drafted bug reports and prepared PR
  branches from the differential campaigns (several oracle-wrong
  findings pinned Lean-right), maintained operator-side and filed as
  network windows allow.
- ~~**Kill the residual effect axiom**~~ — DONE (effect-retirement
  arc, 2026-09-01 C2): `runEffectful` is deleted from LemLib, the
  fresh-symbol supply is threaded explicitly (single stream), the
  digest read is a kernel-checked opaque, and zero `axiom`
  declarations exist anywhere (this repo + LemLib, recursively,
  gate-enforced). Remaining temporal seam with a named mover (Q4
  ruling, machine-pinned in `scripts/unsafebaseio_allowlist.txt`):
  CerberusImpl's enum registry (mover: the arc's reader/supply
  machinery, follow-up slice). The CerbGlobal config/switch refs LEFT
  the allowlist 2026-09-05 (plain `def`s of the default configuration —
  reasoning-artifact audit A step 1, `docs/2026-09-05_cerbglobal-defs-
  record.md`); A step 2 (the configuration as a reader-lifted parameter
  like `tagDefs`; `using_concurrency`'s half is `feature/concurrency`'s)
  is a queued, chartered slice.
- **Pin the Lake dependency SET** (C2 audit follow-up, registered
  2026-09-01): no gate asserts the lake-manifest package set, so a
  future `require` would join the built surface outside every census
  (the C2 ratchet scans the LemLib copy because it KNOWS about it);
  relatedly, `.lake/packages` can carry stale non-manifest package
  dirs (worktree-priming leftovers) that a path-glob gate could
  mistake for consumed code. Wanted: a leg that reads
  `lake-manifest.json` (ALL THREE packages — `lean_frontend/`,
  `lean_frontend/speclab/`, and the measurement package
  `tests/mem-scale-probes/micro/`, added 2026-09-02 to this item: it
  requires CerberusLean by path and shares the workspace package
  store), asserts the package set is exactly the reviewed list, and
  fails on non-manifest directories in the shared packagesDir.
- **Raw-string awareness for the census stripper** (C2 delta-audit
  note, registered 2026-09-01): the shared comment/string stripper in
  `check_theorem_axioms.sh` does not know Lean raw string literals
  (`r#"..."#`) — a banned token inside one would be treated as code
  (over-trip, safe) but a `"` inside one could desync the string
  lexer. Zero raw strings exist on the scanned surface today
  (grep-verified at registration). Wanted: stripper hardening, or a
  cheap raw-string ban probe (`r#"` fails until the stripper learns
  the form).

- **Whole-project trust-surface risk map** [USER 2026-09-05: "A good thing
  to schedule at the end of this would be a whole-project risk map which
  says whether there has been movement wrt the trust surface. We're doing
  a lot of surgery, all reasonable, but we'll want to make sure we aren't
  disturbing the core cerberus correctness properties."] — an
  INDEPENDENT pass (fresh auditor) after Z4 and the fuel close-out, BEFORE
  the fresh-noodler exit test; baseline = the 2026-08-31 semantics-first
  split. Surfaces: the oracle (`.lem` changes = Lean-only declares only;
  OCaml generated tree byte-identical at every merge; fork-drift
  manifest); execution behaviour (the battery re-run from scratch on the
  final head, every movement one of the ruled ones); the definitions
  consumers reason about (fuel parameter, measured wrappers, absorbing
  payloads, deleted wrappers — each claimed zero-execution-effect: evidence
  vs argument); the trust base (axiom census 0, kernel-only ban, opaque
  boundary rows moved and why, ISO-fix register still 3, exception
  classes unchanged); the gates (added/changed/weakened, plant evidence);
  the consumer surface (what refined-cerberus depends on, what became
  provisional). Output per surface: moved/unmoved · evidence · residual
  risk · named mover. Price M.
