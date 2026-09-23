# Run digest as state (D-S) — delivery record, 2026-09-22

Delivery on `arc/run-digest`. The final frozen-tree verdict is in the committed
[full summary](2026-09-22_run-digest-as-state-evidence/summary.txt) and
[report](2026-09-22_run-digest-as-state-evidence/report.json). This record and all
implementation files were written before that run; only evidence files were
copied after it exited. The post-review documentation corrections below are
explicitly later changes, tracked in
[the review-fix record](2026-09-22_run-digest-review-fixes.md); they do not alter
the original frozen report. Landing was separately authorized after review.

## 0. Decisions, provenance and base

[USER] requested the primed run-digest slice at `32dd36f31`, based on enum head
`e2fc391f21fd659c74f4dfdecdf7cc9fd45a2009`, and subsequently authorized amendments:
“If you find ways to improve the result you deliver wrt overall project goals
(eg. if the plan omits important tasks) you can make these amendments”.

The accepted design and response are committed in-tree:
`2026-09-20_run-digest-as-state-design-note.md` (`ad25962b3`),
`2026-09-20_run-digest-design-response-cerberus-sl.md` (`dd8233295`), and the
charter `2026-09-22_charter-run-digest-as-state.md` (`32dd36f31`).
[AGENT] implements the accepted state-data design, without changing the frontend
minting scheme or the OCaml ambient runtime mint. The address-space top remains
the first explicit entry parameter; digest is second, behind Lean's inserted supply.

During the first frozen battery the enum branch advanced to
`e877725373bd38564bf07aac7a3b8d195de0d35d`. The runner was stopped cleanly and
its incomplete evidence retained; the branch was rebased onto that head without
conflicts. The three charter/design commits became `713145baa`, `90e76668e`,
and `c103b3c37`, respectively. The enum delta adds audit records and corrects two
failure-register classifications; implementation hashes were unchanged. The
final battery starts afresh on this rebased tree. Other worktrees are read-only.
Every heavy step is
preceded by process/load polling; waits and wall times are retained in the evidence.
No machine-global install, baseline change, pin-file change, or push is authorized.

## 1. Changes by file and reasons

| File | Change |
|---|---|
| `frontend/model/symbol.lem` | Only `fresh_given_int`: explicit `digest -> nat -> sym`, body `Symbol d n SD_None`. |
| `frontend/model/core_run_aux.lem` | Read-only `sym_digest` beside `sym_supply`; both constructors receive and seed it. |
| `frontend/model/core_run.lem` | The run's one mint reads `run_st.sym_digest`; its OCaml target rep remains unchanged. |
| `frontend/model/driver.lem` | Both public entries take digest after top; `initial_driver_state_with` unchanged. |
| `frontend/model/mini_pipeline.lem` | Const-expr mini-run receives the desugarer's current `digest ()`; this remains a FRONTEND seed read (S0 §5 Q-C). |
| `frontend/model/translation.lem`, `translation_effect.lem` | Five compiler-forced frontend arity fixes pass `(Symbol.digest ())`, preserving the previous value and draw positions (amendment, §5). |
| `ocaml_frontend/fork_renumber.ml` | Mirror accepts the new argument and seeds `sym_digest = Cerb_fresh.digest ()`; `sym_supply = 0` divergence preserved; `fresh_symbol'` unchanged. |
| `backend/common/driver_ocaml.ml` | Both entries receive `(Cerb_fresh.digest ())`. |
| `backend/web/instance.ml`, `backend/ocaml/runtime/rt_ocaml.ml` | Optional-backend entries receive the same global value, also type-checked in isolation. |
| `lean_frontend/CabsImport.lean` | Importable pure `runDigest`: last program Cabs TU, `""` for an empty Cabs list. Existing module, no new seam or manifest entry (§5). |
| `lean_frontend/Main.lean` | Calls that selector at the driver entry and `CerbCall.driveCall`; frontend `setDigestIO`/`forceIO` unchanged, comments narrowed. |
| `lean_frontend/CerbCall.lean` | Digest forwarded through `driveCall`, `mkCallSite`, `argCreate` to `PrefFunArg`; no ambient read in this engine. |
| `lean_frontend/test/Unit/FuelExemplar.lean` | Quantifies the run and its setup/round lemmas over digest, preserving the universal theorem. |
| `lean_frontend/test/Unit/FreshIntTest.lean` | Existing mint test passes a named 32-hex digest at the new arity. |
| Five `speclab/test/SLUnit/*GateTest.lean` files | Existing entry calls receive a named, nonempty 32-hex test digest. |
| `lean_frontend/test/Unit/RunDigestTest.lean` | T1–T6 and exact guarded axiom censuses; both entries/constructors covered; real fixture parsed at compilation and runtime. |
| `lean_frontend/lakefile.toml`, `scripts/test_unit.sh` | Register `run-digest-test`; 14 unit executables. |
| `scripts/fork_drift_manifest.txt` | Nine source-content and seven generated-diff pins, single-row edits plus one dated note; no refresh. |
| Effect-erasure invariant, `VALIDATION.md`, `CLAUDE.md`, `TODO.md` | Runtime digest boundary retired; frontend boundary remains; combined consumer migration documented. |

No further `.lem` core-run-state literal was found. `FuelFormsTool.lean` names the
entry for environment inspection but does not call it, so it needs no edit.
`handwritten_copy.manifest` remains unchanged (49 existing seam files).
`initial_core_run_state dg xs` still calls `Symbol.fresh_int ()`: on Lean that is
a SUPPLY draw, explicitly threaded by the generator, not an ambient digest read.

The optional backends remain outside `check_fork_drift.sh`'s `SURFACES`; the
manifest's layer-1 set therefore gains no rows. Generated layer 2 remains 29 files.
The five originally chartered generated rows move, plus `translation.ml` and
`translation_effect.ml`. Full old/new pins are in `manifest-pins.txt` in the evidence.

## 2. Kernel acceptance T1–T6

`test/Unit/RunDigestTest.lean` compiles the consumer's two acceptance shapes by
reflexivity: `fresh_given_int d n = Symbol d n SD_None` and
`∀ m, symDigest (fresh_given_int d m) = d`. T3 checks empty and two distinct-unit
orders. T4 uses the already committed
`tests/fixtures/001-return-literal/cabs.json`, whose digest is
`81c0f476cb2abad15583f4fcde44a0ed`; fixture SHA-256:
`c21c4fdf5af34ed459bcb6b6fc6c3d6e9011ebef56ca23a4edbdb9ea0b584112`.
Its digest field is bound to the kernel pin by the actual `CabsImport.parseJson`
at elaboration and again against the on-disk fixture at runtime. The length,
lowercase-hex and nonempty facts are kernel `decide`, not a claim that parsing
was proved. No fixture is added or changed.

T5 checks both driver entries, both core-state constructors, the minted symbol
at the entry supply, and preservation of `sym_digest` by minting. T6 guards the
old-arity type error. Exact axiom outputs and test output are retained below and
in the evidence; no axiom, native proof procedure, or option bump is introduced.

Verbatim output from the fully capped probe and unit executable (also committed
as `kernel-axioms-and-tests.txt`):

```text
'RunDigestTest.mint_eq' does not depend on any axioms
'RunDigestTest.mintDigest' does not depend on any axioms
'RunDigestTest.runDigest_empty' does not depend on any axioms
'RunDigestTest.runDigest_last' does not depend on any axioms
'RunDigestTest.runDigest_reversed' does not depend on any axioms
'RunDigestTest.fixture_shape' depends on axioms: [propext, Classical.choice, Quot.sound]
'RunDigestTest.fixture_entry_digest' does not depend on any axioms
'RunDigestTest.entry_digest' depends on axioms: [propext, Classical.choice, Quot.sound]
'RunDigestTest.given_entry_digest' depends on axioms: [propext, Classical.choice, Quot.sound]
'RunDigestTest.core_given_digest' does not depend on any axioms
'RunDigestTest.core_entry_digest' does not depend on any axioms
'RunDigestTest.entry_mint' depends on axioms: [propext, Classical.choice, Quot.sound]
'RunDigestTest.mint_preserves_digest' does not depend on any axioms
initial_driver_state (_lemSupply_fresh_int : Nat) (address_space_top1 : Int) (digest1 : String)
  (file1 : generic_file Unit core_run_annotation) (fs_state2 : CerbFS.FsState) : driver_state × Nat
initial_driver_state_given (sup : Nat) (address_space_top1 : Int) (digest1 : String)
  (file1 : generic_file Unit core_run_annotation) (fs_state2 : CerbFS.FsState) : driver_state × Nat
initial_core_run_state (_lemSupply_fresh_int : Nat) (dg : String)
  (xs : Fmap sym (labeled_continuations core_run_annotation)) : core_run_state × Nat
initial_core_run_state_given (sup : Nat) (dg : String) (xs : Fmap sym (labeled_continuations core_run_annotation)) :
  core_run_state
fresh_given_int (d : String) (n : Nat) : sym
T1 PASS: fresh_given_int d n = Symbol d n SD_None (rfl)
T2 PASS: forall m, symDigest (fresh_given_int d m) = d (rfl)
T3 PASS: empty, last-unit and reversed-order digest pins (rfl)
T4 PASS: committed cabs-json digest is 32 lowercase hex digits and nonempty (decide); parsed entry agrees
T5 PASS: both entries and constructors seed the digest; run mint uses it and preserves it (rfl)
T6 PASS: old fresh_given_int arity rejected (#guard_msgs)
```

The negative diagnostic is guarded exactly in the test source: an argument of
type `Nat` is rejected where `String` is expected in `fresh_given_int n`. Every
printed theorem above also has an exact `#guard_msgs` axiom-population pin.

## 3. Consumer re-pin note — final migration text for cerberus-sl

Take ONE re-pin after E-A and D-S are audited and landed, also including the
already landed address-space parameter. This note supersedes the digest-deferred
paragraph of the E-A record §9.2 and incorporates its enum migration.

1. Carry `Program.digest : String` as a field seeded from the pipeline's run entry,
   with `progOf F supply digest`. Quote and check that value in all eight captured
   modules alongside `supply` and `tagDefs`. In Lean's Cabs execution pipeline,
   it is the LAST program Cabs TU's digest in frontend order, not necessarily
   the digest of `main`'s symbol. An empty Cabs list selects `""`; metadata and
   libc units do not select it. This rule is specific to that entry. OCaml
   Core text (`.core`) sets its file digest, including after a C input;
   `.co`/`.o` objects preserve the preceding global (empty only if nothing has
   set it). Other entry paths must carry their actual entry digest, never
   infer it from absence of Cabs TUs. Lean's `--parse-core` does not execute
   Core text. [AGENT 2026-09-22: audit D1 correction.]
   The existing nonempty-digest freshness hypothesis remains a per-program fact.
2. Generated entry shapes are now
   `initial_driver_state sup top digest file fs` and
   `initial_driver_state_given sup top digest file fs`.
   `initial_core_run_state_given sup digest xs` seeds both fields; the lifted
   non-`_given` constructor is `initial_core_run_state sup digest xs` and returns
   state plus advanced supply. Every full `core_run_state` literal gains
   `sym_digest`; record updates preserve it. The generated driver's field is
   `core_run_state0` (Lem's collision-renamed projection).
3. `fresh_given_int d n = Symbol d n SD_None := rfl`. The engine's mint is
   `fresh_given_int rs.sym_digest rs.sym_supply`. Add the invariant
   `rs.sym_digest = P.digest` beside the existing supply and label-table clauses;
   it holds at entry by reflexivity and no run step writes the field. Adapt the
   mirror's `HeadStep.neg_rewrite` and digest-sensitive freshness lemmas to this
   term. Delete `MintDigest`, `MintDigestC`, their signature assumptions and
   `Spikes.T11Guard.mintDigest_pin_t11`. The acceptance-shaped equation is
   `∀ m, symDigest (fresh_given_int P.digest m) = P.digest := fun _ => rfl`.
   No exported theorem module is needed. Update the stale digest prose in
   `Lang`, `SymFresh`, and `HeapNeg`.
4. E-A adds `enumDefs : Fmap sym integerType` BEFORE `tagDefs` on every generated
   reader-taking signature: `drive`, `driver2`, `driver_globals`, `finalize`,
   `desugar`, `translate`, and every previously tag-reader-lifted definition.
   Newly reader-taking definitions include `GenTyping.annotate_program`, the
   shared `Implementation` integer-layout/normalisation wrappers,
   `AilTypesAux.are_compatible`/`make_composite`, `Ctype_aux.are_compatible_aux`/
   `match_integer_ctype`, `GenTyping`/`GenTypesAux` consumers,
   `Translation_aux.{ctype_of, qualified_ctype_of, combine_params_args}` and
   `Mem_common.{derive_intrinsic_signature, resolve_arg, try_usual_arithmetic}`.
   Generated binders are authoritative; `Core_typing.*` is not newly lifted
   merely because its file literal gains a field. Driver initialization remains
   supply-lifted only; its new digest is an explicit parameter, not a reader.
5. `Core.file` gains `enumDefs` beside `tagDefs`; linking unions it. The full
   `CertP` literals gain `enumDefs := F.enumDefs` (or an empty map for a file with
   no enums). The run receives `runFile.enumDefs`; elaboration receives the TU's
   `Lem_Map.fromList sigma.enum_definitions` (new AIL sigma field).
6. `CerberusImpl.{sizeof_ity,is_signed_ity,alignof_ity,precision_ity}` still take a
   TYPE ONLY, now required to be resolved. Resolve an enum with
   `CerberusImpl.resolveEnum enumDefs ity`, or normalise with
   `CerberusImpl.normalise_integerType enumDefs tagDefs ity`. Unregistered enums
   fail closed. `CerberusImpl.typeof_enum`, the registration effect and
   `enumRegistryRef` are gone. The generated shared wrappers take readers:
   `sizeof_ity enumDefs tagDefs ity`, etc. `is_signed_ity` resolves ONLY an enum,
   so unsupported-width `Signed (IntN_t 128)` still returns true as OCaml does;
   size/alignment/precision fully normalise. Hand-written `CerbMem` consumers
   likewise take enumDefs first (`allocateObject`, `loadM`, `storeM`,
   `sizeofIval`, `alignofIval`, `offsetofIval`, `maxIval`, `minIval`, `intfromptr`,
   `copyAllocId`, and the measured layout/reconstruction workers). Their
   sufficiency theorems carry the additional binder.
7. The F-1 hotfix already in this base reshapes `reconstructValue_lemFuel`'s
   struct/union arms: check `lookupEntry` before the struct fold, select a union
   member before recursion, and return each failure as the whole result.
   The `_indexed` twin and equivalence theorem match this shape. Adjust proofs
   unfolding these arms (`TreeRotExhibit`/`ListRevExhibit`). For any new
   `reader_seed`, give it a `val` and value pin: the first two arguments seed
   readers in sorted order. Construct reader-sensitive callbacks INSIDE the
   seed's extent, passing their source data rather than a previously lifted
   closure (E-A audit E1). D-S itself adds no reader seed.
8. Frontend `Symbol.fresh*`, the five elaboration callers' ambient digest reads,
   the const-expr mini-run's seed, `CerberusFresh` opaques and their allowlist
   rows remain. `CoreParser.mkSym` still uses `""` for library symbols. OCaml
   run minting remains ambient and equal in value to the entry's digest;
   the Lean runtime mint and `--call` engine use explicit data.

Consumer acceptance after re-pin: `corpus-check` for the eight quotations and all
seven outcomes unchanged, the new invariant theorem trio-only, `check.sh` green,
and the pin recount. `Spikes.T11S.t11_adequacy_concrete_pin` should retain only
`selectAgrees_pin`, or just the standard trio if the separate match-pattern-arity
slice has landed. That slice is not part of D-S; this worker did not edit it.
The inherited [enum/arity audit](2026-09-21_enum-repairs-and-match-pattern-arity-audit.md)
closes the enum E1–E4 repairs, while retaining separate R1/R2 findings for the
arity branch. Landing that branch and removing `SelectAgreesC` remain conditional
on its own repairs and audit; this delivery does not certify them.

## 4. Gates, unchanged boundaries and evidence

Preflight verdicts (wall times, not CPU time): regeneration 43.1 s; OCaml build
8.8 s including libc staging; Lean **every root** `Build completed successfully
(395 jobs).` in 166.5 s; speclab `Build completed successfully (148 jobs).` in
95.6 s. Focused kernel/exemplar/freshness tests passed. The optional entry
expressions are extracted from their actual sources and compiled against only
this checkout's freshly rebuilt interfaces. `web_entry rc=0`,
`runtime_entry rc=0`; no diagnostics on that isolated check. The full web target
needs absent `fpath`/`cohttp-lwt-unix`; the runtime dune stanza is commented out
and its unrelated stale full-file literal predates this slice (E-A §10.2). These
checks establish the changed CALLS' validity, not whole optional-target builds.

The final OCaml review additionally annotates the shim's ignored parameter as
`Digest.t`, to preserve the intended interface type instead of inferring a
polymorphic argument. Rebuild and optional-call checks passed in 7.9 s after
a 60.1 s process wait; the integer-digest negative control was rejected
(`wrong_digest expected rejection rc=2`, `Digest.t = string` expected). Outputs are in
`typed-ocaml.txt`; the full battery re-runs all Tier A rows after this annotation.

Tier A, before that type-only annotation, took **522.6 s**:

```text
fast: passed; 16/16 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

A1: `Total: 14 passed, 0 failed`. A6: `SUMMARY: total=2 match=2 fail=0`; A6b:
`SUMMARY: total=7 match=7 fail=0`; both `ALL PASSED`. Every row's verbatim tail
is committed in `tier-a-tails.txt`; the CN baseline is 213 exact entries, zero
differences/crashes/timeouts. No baseline or expectation is changed.

Pre-rebase boundary gates, verbatim (historical census before enum audit N2):

```text
check_fork_content: OK — 82 source files content/mode-pinned
check_fork_drift: OK — layer 1: 82 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 29 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 38f87d5 = lem -v)
check_failure_reach: instrument built + census taken in 6 s (FAILURE_REACH rows 21273, FAILURE_RANGE rows 11330; counts: {"generated:monadic_ascribed":263,"generated:pure_or_unresolved":1254,"handwritten:pure_or_unresolved":126})
check_failure_reach: OK (238 pure failure sites = the 238 register rows exactly (236 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=169 REACHABLE=50 UNKNOWN=19; every row sealed; tally line consistent)
```

D-S leaves the failure register byte-unchanged from its rebased enum base:
238 rows (236 exec, 2 unresolved), 169 unreachable-by-invariant / 48 reachable /
21 unknown, 0 discardable. The inherited enum N2 correction reclassifies the two
enum-lookup rows as UNKNOWN because the oracle Core lexer has no `enum` token;
it changes no failure sites or position classes. Rebased boundary output is
retained separately in `rebased-boundary-gates.txt`.
The unsafe allowlist's **19 PIN rows**, `OPAQUE_WANT`'s **10 rows**,
`CerberusFresh.lean`, `CoreParser.lean`, and the 49-file handwritten manifest
are byte-unchanged. The Tier A axiom gate also reports zero declarations across
219 generated files and the recursively scanned 400-file C2 surface.

The first frozen run was stopped for the enum rebase after 28/39 commands had
passed, with `source_unchanged: true`; B7 was interrupted while running. It is
INCOMPLETE evidence, not the final verdict. Its report and summary are retained
as `interrupted-pre-rebase-report.json` and `interrupted-pre-rebase-summary.txt`.
The stop/rebase reason and 30/30 implementation/record hash check are recorded
in `rebase-provenance.txt`. The new full run repeats every selected command.

Final frozen-tree command (through the container's `scripts/ce`, with every
Lean subprocess capped by its owning script):

```sh
python3 .tmp/run-digest/coordinate-release.py scripts/release.py --mode full --out .tmp/run-digest/full
```

The runner's `source_unchanged` and `selection_complete` fields must both be
true and all 39 selected commands must pass. The pristine lane must remain
835 semantic agreements / 7 reviewed differences; the other existing classes
and every other lane must remain at baseline. The committed `summary.txt`,
`report.json`, `full-lane-tails.txt` and `final-validation.txt` are the verbatim
verdict/evidence for that final tree. These are gate results; release adoption
and the independent pre-merge audit remain separate exits.

The previous E-A frozen full battery took 5,494 s across its lanes (derived sum;
about 92 minutes), slightly beyond a strict 90-minute timeout. Under the user's
amendment authorization, the final runner has a 100-minute watchdog to permit
that known baseline, with progress checked throughout. The local scheduling
wrapper imports the unchanged runner and waits before each `execute_lane` call;
it changes no command, selection, result, or lane timeout. The watchdog counts
active wall time, excluding these explicitly logged coordination waits. The
wrapper, outer watchdog, `lane-polls.jsonl`, and actual wall time in `steps.jsonl`
are retained in evidence. Initial heavy work waited for the external audit;
subsequent polls waited 40.1 s before regeneration, 20.0 s before isolated OCaml
checks, and 80.1 s before the boundary gates (the latter includes our preceding
speclab job). Other workers sometimes started after a clear poll; this slice's
heavy commands remained sequential. Later waits, if any, are in `steps.jsonl`.

The shared-model validation rule (`VALIDATION.md` §0, LADDER C5) additionally
requires the three-engine report, omitted from the charter's gate list. Under
the user's amendment authorization, `test_upstream_oracle.py --with-lean` runs
on the rebased implementation. Its pristine/fork classification and every
reported Lean difference are checked against the inherited baseline; the Lean
column is reporting evidence, not a newly claimed gate. Outputs are retained in
`three-engine-report.json` and `three-engine-summary.txt`. The preliminary
report had the expected 835/7 pristine counts and the exact 40 historical Lean
difference IDs/classes, but failed source stability because this record and
scheduling evidence were still being finalized. Its summary is retained as
`three-engine-prefreeze-summary.txt`; it is repeated on the final freeze, and
only that repeat supplies the final report. Neither report changes a baseline.

## 5. Errata and amendments

- [AGENT] Added the mandatory three-engine report from `VALIDATION.md` §0 and
  per-lane scheduling polls. The unchanged release runner still owns all lane
  commands, containment, verdicts and source-stability checks. The first full
  attempt polled before the whole battery; the restarted battery polls before
  each lane as the charter requests.
- [AGENT, authorized by USER's amendment instruction] The charter/design's claim
  that `fresh_given_int` has only one generated caller needs “on the RUN PATH”.
  Five frontend calls exist in `translation.lem:3328–3329` and
  `translation_effect.lem:88,93,158`, plus `FreshIntTest.lean:64`. The prepared
  mechanical fix passes the same ambient digest at those frontend sites and a
  named nonempty digest in the test. These files and their two generated pins
  are necessary compiler-forced additions to the original fence.
- [AGENT] `runDigest` lives in existing `CabsImport.lean` instead of `Main.lean`:
  importing Main into a unit executable also imports its global `main`, preventing
  a distinct unit entry. Main and the test now use the SAME transparent selector,
  without a new module, copied-file manifest row, or duplicated implementation.
- [AGENT] Lem rejects `Symbol.digest ()` in `mini_pipeline.lem` with
  `Type error: unbound field name: digest` (the module is open-imported there).
  The unqualified imported `digest ()` generates the intended `Cerb_fresh.digest`
  / `CerberusFresh.digest` call. The first failed generation changed no semantics;
  its diagnostic and successful regeneration are retained.
- [AGENT] The fork mirror needs the new digest binder as well as the field;
  `(_digest : Digest.t)` documents that OCaml uses the ambient value, equal at all
  four callers, while retaining the digest argument's intended OCaml type.
- [AGENT] The actual generated state projection is `core_run_state0`, not the
  charter's `core_run_state`. The entry is supply-lifted only; the historical
  FuelExemplar comment claiming its constructor is fuel-lifted is stale.
- [AGENT] The existing `FuelFormsTool` has no entry application; no edit is needed.
  The optional backends are outside the oracle manifest surfaces; no new layer-1
  row is appropriate. Existing committed JSON suffices for T4.

- [AGENT] The first T4 proof used `String.all`, whose iterator did not reduce
  under kernel `decide`. Using `fixtureDigest.toList.all` states the same
  lowercase-hex check transparently and proves it with the standard trio, without
  changing the parser, raising limits, or using a native proof procedure.

## 6. Evidence

Directory: `2026-09-22_run-digest-as-state-evidence/`. It contains the final
`report.json`/`summary.txt`, T1–T6 and guarded axiom outputs, build/gate tails,
wall-time/process-wait log, exact manifest pins and every Lem/OCaml hunk in
`lem-ocaml.diff`. The latter is the verbatim zero-context source diff for review. Full per-lane
logs remain under `.tmp/run-digest/full` in this worktree. No source file was
edited during the original frozen run. The post-review documentation corrections
are recorded separately and make no new source-stability claim for that report.
