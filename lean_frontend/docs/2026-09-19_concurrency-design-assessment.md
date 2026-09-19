# Concurrency charter and legacy implementation assessment

**Recommendation: REQUEST CHANGES to the landing charter and the implementation. Keep the SC-first direction and reuse the prototype, but do not land it as the consumer's trusted concurrency model in its present form.** The principal blockers are semantic counterexamples and an unreliable legacy validation lane. They cannot be resolved by rebasing, preserving the existing 30 litmus outcomes, and attempting the proposed proofs for a bounded time.

Reviewed by Codex, 2026-09-19. The [landing charter](2026-09-19_charter-concurrency-landing.md) is at `arc/concurrency-landing`, `38d7d2123ca1dd2a0769c19518b9410c7d4ea1f5`. Its only change over `feature/concurrency`, `086d8762d382eff375c101f5f0c64d3ffe9bccc7`, is the charter itself. The implementation assessed here is therefore the legacy S0–S7 implementation, **not a future rebased L1 candidate**. Mainline at entry was `0457732e1`. Work ran in the isolated `audit/concurrency-design-20260919` worktree; no implementation, charter, baseline, shared installation, or existing branch history was edited. [Evidence and reproduction](2026-09-19_concurrency-design-assessment-evidence/README.md).

## Assessment against the goals

The relevant goals are an executable, kernel-visible C semantics; useful support for cerberus-sl's fault-avoiding reasoning; eventual Linux system-code verification; and an initial strong interleaving model that does not silently commit future work to SC. These are the current user's goals quoted in the charter/scoping note. The present consumer's reference is `cerberus-sl/docs/2026-09-10_master-plan-rev5.md` and its amendments, not the retired refined-cerberus project.

| Goal | Assessment |
|---|---|
| A useful first concurrent executor | **Substantial reusable work.** Explicit model selection, working spawn/join scheduling, scalar SC litmus behavior, integer compare-exchange, startup sequencing, and typed model failures are worthwhile. |
| A trustworthy supported C fragment | **Not met.** The syntactic predicate admits byte-access and memory-copy cases for which the event interpretation is wrong. A documented limitation does not enforce a fragment boundary. |
| Kernel-visible reasoning support | **Good infrastructure, incomplete semantic contract.** Removing dead stubs and proving predicate-tree recursion sufficient are useful. The six sequential identity lemmas establish neither observer agreement nor faithful recording. |
| One consumer model for sequential and concurrent code | **Not ready.** Ordinary, spawn-free byte accesses and `memcpy` already refute the advertised sequential/SC agreement statement. |
| Future model changes | **The selector is a good beginning, not a general memory-model interface.** Immediate reads, concrete memory, action grouping and the recorded state remain coupled to this SC implementation. The charter acknowledges read deferral but overstates the reusable contract and transfer rule. |
| Linux-scale direction | **Appropriate staging, narrow present capability.** Weak orders, LKMM, efficient exploration and a concurrent Iris logic can wait. Accurate access footprints and an honest supported domain cannot be postponed while claiming general SC C behavior. |

There are two distinct bodies of legacy work. The Cambridge axiomatic library and operational-model/Isabelle development provide valuable definitions and prior mathematics. The S0–S7 feature is a new executable adapter/scheduler. Its SC path calls `symUpdatePreEx` and constructs a witness; it does **not** execute the operational model's proved commitment algorithm. The published equivalence proof concerns that other operational model and does not certify this adapter. [Original operational-model artifact](https://www.cl.cam.ac.uk/~pes20/cpp_op/).

The positive evidence is real: a fresh build of both engines and the bridge-test executable succeeded; the bridge's five controls passed; an independent status-aware, full-observation check of the committed litmus targets passed **30/30**. Those results coexist with the failures below.

## Findings that must shape the landing plan

### C1 — P1: the admitted access domain gives both missed races and false failures

Locations: `frontend/model/driver.lem:92–114, 121–125, 237–242, 1047–1102`; `frontend/model/cmm_aux.lem:5–13`; `frontend/concurrency/cmm_csem.lem:1228–1236, 1431–1438`.

`sc_fragment_ok` checks action syntax and memory orders. It does not establish that pointer equality represents all conflicting accesses, or that a load's recorded value equals the value of its selected whole-object write. The concrete memory can perform a byte access, while the concurrency recorder identifies locations solely by pointer value and chooses the most recent write at precisely that pointer.

The following real C probes were run on both freshly built engines:

| Probe | Sequential | SC |
|---|---|---|
| `int x=0x01010101; return ((unsigned char*)&x)[0];` | `Specified(1)` | **`MI_sc_inconsistent well_formed_rf`** |
| `int x=0; ((unsigned char*)&x)[1]=1; return x;` | `Specified(256)` on this target | **`MI_sc_inconsistent well_formed_rf`** |
| Parallel `x=0x01010101` and `r=((unsigned char*)&x)[1]`, with `x=r=0` initially | Spawn refusal | **`{Specified(0), Specified(1)}`; no data race** |

The first two are valid, single-thread accesses through a character type. The third has conflicting accesses to overlapping storage without synchronization. Character access is permitted by C11 6.5p7; the race criterion is 5.1.2.4p25. These are not examples of prohibited type-punning. [C11 committee draft N1570](https://www.open-std.org/jtc1/sc22/wg14/www/docs/n1570.pdf).

The second write updates concrete bytes but does not replace the recorder's last write at the base address. The first read selects a full-width integer write whose recorded value differs from the byte value. At offset one, the race detector does not even relate the accesses. The same-address race control correctly reports UB005, which isolates the missing overlap treatment.

**Required:** repair access footprints and value correspondence, or enforce a conservative, nonvacuous supported domain with typed refusal. It must cover concrete aliasing and access ranges, not merely spelling or memory order. Carry the corresponding invariant in the consumer/theorem hypotheses and prove that admitted executions preserve it. Keep these positive and negative cases in the lane.

The [September 6 supported profile](2026-09-19_concurrency-design-assessment-evidence/2026-09-06_supported-profile.md) already classified overlap as a concurrency blocker (CR-2). The new charter's decision to leave mixed-size accesses to Phase 1 preserves a wrong answer inside its claimed fragment.

### C2 — P1: not every memory effect enters the concurrent execution

Locations: `driver.lem:123–125, 1244–1380`, especially `Memcpy`/`Memcmp` at 1297–1306 and `Realloc` at 1313–1316; `action_request_sc2` at 1104–1197.

`model_check_expr` accepts **every `Ememop`**. The memop handler has no model argument and invokes concrete `memcpy`, `memcmp` and `realloc` without recording their memory accesses. Other paths also require an explicit inventory: initialization supplied to object creation, startup/library effects, and allocation/lifetime operations. A scheduling point around a memop does not provide its missing events.

A spawn-free `memcpy(&x,&y,sizeof x)` with `x=0, y=7`, followed by `return x`, returns **7 sequentially and `well_formed_rf` inconsistency under SC on both engines**. Three concurrent copy probes fail differently across engines: the fork reports `well_formed_rf`, Lean `det_read`. Complete error observations therefore disagree even though a legacy `{ERROR}` projection would equate them. These measurements establish failures of the advertised interface; they do not claim that this review isolated the separate cause of the differing first failed leaf.

**Required:** inventory all memory-changing/reading paths and either give each an appropriate event interpretation or refuse it under the supported model. Restore full engine agreement on the resulting domain. Do not satisfy the twin lane by pinning internal inconsistencies as ordinary fragment refusals. In particular, the corpus should test real C calls, byte views, initialization and aliasing, not only manually constructed Cmm events.

### C3 — P1: L2/L3 contain false statements, not merely expensive proofs

Locations: landing charter L2/L3 (lines 28 and 30), and the no-model-change fence at line 40.

**L3:** adding `sc_fragment_ok` to `epar_free` did not make the statement true. C1's two byte programs and C2's sequential copy pass the entry scans and have no spawn. Yet their verdicts differ between the two models. This is independent of trace-field projection and is not solved by more fuel. A proof cannot close while those programs remain in its quantified domain and the implementation remains fixed.

**L2(i):** a strict total commit order with `sb,asw ⊆ T`, latest-write `rf`, restricted `mo/sc`, empty `lo/tot`, and no data races does not imply all the library's consistency leaves. I executed two abstract counterexamples against the actual generated predicate, plus a positive control:

- One thread, a non-atomic write and read of the **same value**, `T = [write,read]`, empty `sb/asw`, latest-write `rf`: no data races and `well_formed_threads=true`, but **`det_read` and `consistent_non_atomic_rf` fail**.
- The same order with `sb(write,read)`, but different written/read values: no races and well-formed threads, but **`well_formed_rf` fails**.
- Adding the needed sequencing and matching value makes all leaves pass.

These are abstract-construction probes, not claims that both graphs come from valid C. Their purpose is precisely to show the missing hypotheses of L2(i). The driver specification must establish those hypotheses from program execution. At a minimum this includes finite/valid event identities, supported action/location kinds, faithful memory values and footprints, the actual sequencing rules, initialization, and indivisible RMW behavior. Assuming the target leaf itself is not a useful substitute.

**Required charter change:** establish the precise domain and statements first; explicitly authorize the small shared-model repairs or guards they require. State L3 over an explicit observable projection, canonical corresponding initial states, the address-space parameter, and quantified fuel. Include errors, UB, output and incompleteness in the contract. Any weaker statement must have a counterexample-based rationale and a concrete successful instance.

The two-layer proof organization is good. Its current premise list is not sufficient. S2 must distinguish **false statement**, **implementation defect**, and **proof-engineering difficulty**. Committing an abstract theory with the concrete correspondence still owed can be a useful research checkpoint; it is not the promised transfer principle for consumer adoption.

### C4 — P1: the legacy litmus gate can certify incomplete executions

Locations: `scripts/test_litmus.sh:90–150, 155–173, 183–205`; `tests/litmus/sc_reference.py:229–240`.

The legacy lane ignores the fork's exit status. On Lean it enters `if ! run_lean ...` and then reads `$?`, obtaining the negated success status rather than the original failing status. Its `sed` projection discards output fields and collapses all typed Errors into `ERROR`. Reference readers also overwrite duplicate names.

Fresh plants through the actual extracted helpers retained a valid printed `Specified(7)` record while varying process status. **Fork exit 137, Lean exit 137, and both exit 124 all produced `DIFF_FAIL=0 COMPARE_FAIL=0`.** The healthy status-zero control also passed. Prefixing the expectations with a contradictory duplicate SB row still passed the mechanical reference check. These are helper-level plants, explicitly not real C executions killed by the OS.

This is already repaired in substantial part on `arc/validation-foundations-concurrency` (`51b855aec`, `eb926f8d3`, `2460ef33f`, record `86a2aea54`). The new charter relegates checking that branch to its final open-items inventory. It needs to be a prerequisite to the **first** trustworthy L1 gate.

**Required:** port the concurrency-specific repaired lane and reference checks onto the current observation codec; preserve current shared validation infrastructure. Re-test original statuses, stdout/stderr, distinct failure payloads, refusal cardinality, duplicate/orphan/missing/unterminated rows, and incomplete runs. Include a plant at the production driver-to-bridge connection: the existing `SCBridgeTest` calls the checker on hand-built candidates and would remain green if the driver's call to it disappeared.

My independent 30/30 result used current-mainline observation decoding and original exit statuses, rather than this legacy extractor. It confirms the current small targets, not the reliability of their shipped gate.

### C5 — P2: the sequencing approximation is broader than the charter's account

Locations: `core_run_aux.lem:418–458`; `driver.lem:1031–1045, 1149–1166`; legacy S3/S4 records.

The historical CR-3 warning about SeqRMW has not been discharged. SeqRMW tags the whole rebuilt arena/stack. In addition, the final S4 `add_to_sb_ctx` tags **all unsequenced siblings**, including ordinary non-atomic actions. Some comments still describe the earlier context-aware implementation as leaving siblings untouched. The scope of the approximation must therefore be assessed from the final code, not solely from S3's “SeqRMW only” warning.

A fresh trace for `int x=0,y=0; return x++ + y;` records the read of `y` sequenced before the load/store of `x`, although the C operands are unsequenced. The return value is 0 on both engines, and a same-object `x++ + x` control still reports UB035. **This review does not claim those probes demonstrate a newly missed cross-thread race.** They demonstrate that recorded `sb` is a chosen ordering stronger than source sequencing, so an exact-recording theorem and the assertion that this never changes race behavior require justification.

**Required:** prove the ordering transformation preserves the supported semantics, or repair/narrow that part of the domain. Preserve real indeterminate sequencing where the language requires it, and distinguish it from unsequenced non-atomic evaluations. A concurrent publication probe included in the evidence is exploratory; its mixed defined/UB set is not presented as an independently established counterexample.

## Trust-story changes needed in the charter

**A predicate on a recorded graph is not program adequacy.** An under-recorded access or an invented synchronization edge can make `data_races(recorded_graph)=∅` while the program is unsafe. Proving the consistency checker always accepts such graphs does not fix that. The concrete correspondence obligation must cover every relevant effect and the relationship between source/runtime conflicts and graph conflicts. This is why C1/C2 precede the proposed theorem work.

**Define the safety observation for prefixes and racy programs.** The implementation checks races only at the end of `drive`. It can return a mixture of a defined observation and UB005 for different schedules; the existing `datarace+Wna_sc+sc_Rna` target explicitly does so. The library's `behaviour` definition instead classifies the entire program undefined if any consistent execution has a fault (`cmm_csem.lem:668–681`). A per-trace interface can be useful, but a defined member of a mixed set is not a safety certificate. Before claiming fault-avoiding consumer adequacy, specify how all schedules, fuel exhaustion, and a race followed by nontermination are covered. A tail-only test is not a prefix-safety theorem. The original operational-model paper describes the whole-program fault quantification. [Nienhuis et al., OOPSLA 2016](https://www.cl.cam.ac.uk/~pes20/rems/papers/nienhuis-oopsla-2016.pdf).

**Distinguish extension points from established interface laws.** The closed `CM_sequential | CM_sc` selector prevents an ambiguous Boolean flag; it does not supply a parameterized transition interface with laws. `driver_state` fixes `Cmm_op.symState`, action callbacks deliver concrete read values, and the same driver handles concrete effects and observation construction. It is reasonable to retain these for Phase 0. State what is provisional, expose the intended SC step/observation invariants, and keep consumer claims indexed by this instance. “Adequacy against the interface only” needs an actual statement that the current instance satisfies; prose saying what every future instance guarantees is insufficient. No elaborate plugin architecture or weak executor is needed for this landing.

**Correct the model-switch rule.** The converse of the proposed trace-consistency theorem is not, by itself, DRF-SC or proof transport. To transport universal safety/postconditions to a target model, establish target definedness and the appropriate inclusion of target observations in the proved model's observations, under an explicit common program domain. The origin of the race-freedom premise matters; assuming the future target is race-free is different from deriving that from an SC proof.

The relevant literature explicitly restricts the SC result to a sublanguage without low-level atomics and identifies an additional atomic-initialization condition. The repository's `SC_condition` likewise includes `atomic_initialisation_first`; a memory-order scan and the runtime consistency tree alone do not establish this condition. Name and discharge the applicable hypotheses. A future C11 weak instance or LKMM instance requires its own transfer argument; merely calling it DRF-SC does not preserve all existing proofs. [Batty et al., POPL 2012, project and proof materials](https://www.cl.cam.ac.uk/~pes20/cppppc/).

**Keep oracle roles separate.** Fork/Lean agreement checks two implementations of the same source. The Python reference checks a hand transcription. The checker validates a recorded graph. Each is useful; none validates the missing C-to-event correspondence alone. `herd7` is a useful next independent comparison for mapped litmus tests, but does not automatically validate the frontend, concrete-memory adapter, or completeness of that mapping. Keep concurrency as a separate fork-only interface lane, rather than adding fake pristine difference-register rows.

## Revised landing sequence and acceptance

The [September 6 integration proposal](2026-09-19_concurrency-design-assessment-evidence/2026-09-06_concurrency-integration-charter.md) is closer to the needed order: decide the nontrivial domain and provider statement, repair or refuse overlap/SeqRMW, then demonstrate agreement and actual consumption. The September 19 charter contributes useful two-layer proof structure and a broad empirical twin; combine those strengths.

1. **Inventory and reconcile first.** Bring the feature onto the named current mainline, preserving the allocator/address-space, seam and validation changes. Import the concurrency-specific instrument repairs before trusting a lane. Review semantic conflicts individually; “keep mainline's form” is not a semantic resolution rule.
2. **Make the supported SC instance correct.** Resolve C1/C2 and the sequencing obligation. Add honest typed guards where support is deferred. Cover the actual RMW set: the implementation supports integer compare-exchange, while generic `Core.RMW` remains a TODO and `atomic_exchange_explicit` crashes earlier in the tested frontend. Do not advertise all seq_cst RMWs as implemented.
3. **Fix and review the theorem statements.** Establish the execution invariant and concrete correspondence on that domain; prove the observer agreement needed by the consumer. Use representative successful programs. The twin lane should now be diagnostic evidence for these claims, not a way of normalizing counterexamples into acceptable rows.
4. **State the consumer contract and demonstrate it.** Include the supported profile, exact observations, startup/state/fuel hypotheses, instance-specific laws and prefix/whole-program fault interpretation. Compile a small external client against the exported API/theorem. Coordinate the consumer's pin separately; do not silently replace its intended properties with convenient implementation facts.
5. **Gate the reconciled final tree.** Full current Tier A/B, strengthened litmus and plants, SC/sequential twins with exact refusal classifications, current pristine exclusion handling, affected reporting, and fresh source/artifact identities. Audit the final implementation again before merge.

**May remain deferred:** weak-memory read deferral, non-SC orders, fences, LKMM, general concurrent Iris rules, fairness/liveness claims, and state-space reduction. Historical state and all-pairs graph construction have growth costs worth profiling on a modest sequential/concurrent workload before broader adoption; Linux-scale execution performance is not a sensible Phase-0 exit criterion.

**Should not remain “owed” in a consumer-ready landing:** enforced domain correctness, faithful relevant memory effects, reliable validation, and the transfer claim used to justify moving the consumer to `CM_sc`. If the operator instead chooses an explicitly experimental executor landing, label that a different acceptance target and retain the consumer's existing trusted instance. An abstract theorem plus sampled tests is valuable, but does not complete the agreed consumer trust story.

## Verification and limits

| Fresh check | Result |
|---|---|
| Regenerate both targets; forced, cache-disabled OCaml build; capped Lean driver + SC bridge build | Passed, 280 Lean jobs. |
| Status-aware independent check of the committed litmus corpus | 30/30 targets, full engine sets agree. |
| Shipped SC bridge-test executable | 5/5 controls passed. |
| 20 focused C programs, both modes, both engines | 40 paired runs; C1/C2 reproduced. Three concurrent-copy pairs disagree on the inconsistency leaf. Atomic exchange fails in both frontends. |
| Two additional atomic/unsequenced exploratory programs | Both engines report UB035; retained as coverage observations, not used to establish a new blocker. |
| Abstract L2 hypothesis probes | Two counterexamples and one accepting control, evaluated against generated definitions. These are tests, not general proofs. |
| Legacy instrument plants | Healthy control accepted; three incomplete-status variants incorrectly accepted; contradictory duplicate reference incorrectly accepted. |
| Source integrity | Tracked implementation unchanged; audit-only files added. |

This is a design and legacy-code assessment with focused reproductions. I did not rebase the implementation, repair it, repeat the full historical battery, prove the proposed theorems, certify a current-mainline candidate, or certify a concurrent consumer logic. The retained records distinguish actual executions, abstract graph tests, helper plants, and recommendations.
