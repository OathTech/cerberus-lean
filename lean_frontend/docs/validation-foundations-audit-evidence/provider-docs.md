# Fresh pre-merge review: provider, failure census and core documents

2026-09-06 [AGENT]. Reviewer: fresh provider/docs audit worker. Review subject:
`6d6cfa858109a42561878db3d939024c5756ad4f`, base
`89f7e688530c6910884518811d645e4e892e4507`, in the owned
`arc/validation-foundations` worktree. The source remained unchanged. All
review outputs are confined to this directory. No build, Lean/Lake invocation,
shared pin mutation, customer inspection, legacy-run inspection, tracked edit,
commit, merge or external message was performed by this reviewer.

## Result

Three P2 findings remain open: incorrect G6 declaration attribution, a false
byte-printer diagnosis/remedy in TODO, and unreconciled current overview claims.
No P0/P1 finding was identified in this assigned surface. The G6 mapping and
G7 reconciliation claims should be corrected before treating those acceptance
items as complete. These are findings in the delivered instruments/documents;
the explicitly declared semantic debt is not being relabeled as a new merge
blocker.

The provider completion theorem is nonvacuous, uses the actual shipped entry,
and is described with appropriate limits. The archived provider/probe evidence
is internally consistent by the checks below. Fresh cold-build execution is
owned by the coordinator and is not claimed by this report.

## F-PD1 — P2: validate compiler-range containment before assigning census dependencies

**Code:** `scripts/failure_census.py:57-58`, `:86-87`, `:165-177`.
**Affected claim:** `lean_frontend/docs/2026-09-06_failure-census-and-correspondence.md:44-52,68-71`.

The lexical header regex does not recognize anonymous instance headers such
as `instance (priority := low) : BEq (...) where`. Consequently a failure in
such an instance can inherit the preceding named definition. If that earlier
name exists in the dependency log, lines 165-166 accept it without checking
whether its compiler declaration range contains the occurrence. The range
fallback is only used when no name was found. This can assign another
declaration's execution-dependency bit to the site.

Two concrete examples in the committed census:

| Source occurrence | Recorded declaration | Actual containing declaration | Execution dependency |
|---|---|---|---|
| `generated/Cmm_csem.lean:440:14` | `aid_of`, range 356:0–357:317 | `instBEqPre_execution`, range 439:0–440:165 | recorded true; actual false |
| `generated/Core_reduction.lean:331:14` | `combine_dyn_annotations`, range 307:0–308:14 | `instBEqOne_step`, range 330:0–331:160 | recorded true; actual false |

The compiler evidence is in the archived `reach.log`: lines 16462-16463 and
18886-18887 for the first case; lines 8183-8184 and 29612-29613 for the second.
The source occurrence and enclosing-instance syntax independently confirm
the range interpretation.

**Reproduction:** from the subject root, after the selected archived evidence
has been copied into this audit directory:

```sh
python3 .validation-foundations/premerge-audit-20260906/provider-docs/audit_census_ranges.py
```

It exits 1 and produces `range-mapping-reproduction.json`. The script first
checks every census source hash against the current files and the reach-log
hash against the archived census. Separately rerunning the shipped lexical
census on these files and this archived log produced JSON identical to the
committed census (`census-local.json`). Existing lexical tests pass 3/3, but
do not exercise this declaration-assignment bug.

**Derived impact:**

- 140 occurrences are assigned to a declaration whose range does not contain
  them. All are anonymous comparison-instance failures in seven modules.
- All 140 have an unambiguous containing compiler range. Thirty execution
  flags change true to false: ten `Cmm_csem` and twenty `Core_reduction`
  occurrences. No frontend flag changes.
- Generated pure sites in the execution closure change from 156 to 126;
  combined pure execution sites change from 261 to 231; all execution sites
  change from 335 to 305. The 1,644 total occurrences, 263 generated monadic
  ascriptions, and 67 generated plus seven handwritten monadic execution
  occurrences do not change.
- The smallest-range method additionally refines one valid enclosing name,
  `CerbMem.memcmpM`, to its nested `getBytes` declaration. Its dependency bits
  are unchanged; it is not counted among the 140 incorrect ranges.

This is an attribution/count defect, not evidence that any newly discovered
failure is C-reachable. The existing report already correctly distinguishes
dependency closure from branch reachability. Nevertheless, a source-obligation
register must identify the actual declaration before it can guide repairs.

**Remedy:** require the selected compiler range to contain every source
occurrence, even when a lexical/private name exists; use the unambiguous
smallest enclosing range for anonymous declarations and preserve unresolved
cases explicitly. Add a plant with a named execution-dependent function
followed by an unused anonymous failing instance. Regenerate the census,
comparison record and affected counts on the identified source. Keep the old
measurement dated rather than editing its raw evidence to look original.

## F-PD2 — P2: remove the disproved non-ASCII printer diagnosis and unsafe blanket remedy

**Claim:** `lean_frontend/TODO.md:149-162` says every non-ASCII byte in captured
stdout/stderr diverges, says no corpus row prints non-ASCII, and recommends
changing `batchEscape` to escape the String's UTF-8 bytes.

**Counterevidence:** `Main.lean:343-364`, the actual producer trace in
`docs/2026-09-05_observation-contract.md:116-126`, and the existing fixtures
`tests/immaculate/libc/zd-z2p01-stdout_escape.c:8` and
`zd-z2p01-stderr_escape.c:8` establish why that diagnosis is wrong for modeled
IO. The IO String carries one model byte per Char. The fixtures already print
bytes C3 A9 and FF, respectively.

The final B5 archive retains equal Lean/OCaml records and status 0 for each
side. The stdout record contains `\195\169`; the stderr record contains
`\255`. All eight selected record/status files were checked against their
`final-full.json` hashes. Their exact bytes and paths are retained in
`byte-overview-counterevidence.json` and `archived/.tmp/.../B5/...`.

**Impact:** the current TODO gives a future maintainer an incorrect repair
instruction: iterating UTF-8 bytes over this byte-carrier String would encode
C3 A9 twice, recreating the corruption already described in Main's historical
comment. It also contradicts the charter's completed producer-tracing work.
The generic Lem String/Unicode defects remain real and explicitly separate;
this finding does not claim all producers of `batchEscape` are correct.

**Remedy:** replace the blanket diagnosis with the traced producer-specific
boundary, retain the existing positive byte fixtures, and state the remaining
unproved or bad producers separately. Do not apply a blanket UTF-8 conversion
to modeled IO.

## F-PD3 — P2: reconcile current overview claims with the delivered runner and reporting

**Citations:**

- `lean_frontend/VALIDATION.md:613` says no ladder/battery runner script
  exists and assigns only procedural enforcement to Tier A/B. The current
  `scripts/LADDER.md:8-13` gives `release.py` and `ci_lean.sh`; the latter
  invokes the runner at line 17. The VALIDATION introduction itself describes
  the delivered runner and 32/32 pass.
- `VALIDATION.md:625-626` still says the value-only copies are pending.
  Section 0 and the current observation contract instead say those callers
  were migrated. The §4 parenthesis at lines 337-338 is stale for the same
  reason. GCC's intentionally weaker native projection must remain distinct
  from whether its Lean observation is fully captured.
- `lean_frontend/README.md:122-124` headlines the 2,186-file CI sweep with
  “zero mismatches among the 1,316 comparable,” without marking that total
  historical. Current C4 has 1,205 MATCH + 154 UB_MATCH = 1,359 agreements,
  one UB-location difference, three filesystem refusals, two Lean timeouts,
  and 821 oracle-side non-comparisons. Those counts are explicit in
  `docs/2026-09-06_ci-reporting-results.md:23-34` and the updated VALIDATION
  lane table.

**Impact:** readers following the current core overviews receive conflicting
answers about the enforcement mechanism, migrated observations, and measured
CI agreement. The README's general “zero mismatches” wording also hides the
now-observed UB-location difference from its headline presentation, even
though the detailed record correctly preserves it. G7 expressly requires
reconciliation of current overview/TODO claims.

**Remedy:** update the current prose around the delivered runner and comparison
matrix, and either replace the old CI count with the final classified result
or explicitly date and label it historical. Keep outcome agreement, baseline
stability and reporting completion separate as the new delivery/profile do.

## Provider proof and clean-recipe review

Read `build_provider_smoke.py` in full, the provider record/adoption manifest,
the final provider manifest and command evidence, `ProviderSmoke.lean`, and
the relevant shipped `FuelExemplar`/`LemLibPmapLaws` definitions and statements.

- `ProviderSmoke.completed` at lines 14-20 proves existence and singleton
  completion at every ambient fuel `k+2`, plus the actual Core value 42.
  It cannot be discharged by empty exploration or an always-failing runner.
  `FuelExemplar.run:136-139` calls generated `drive`, actual `CerbND.runND`,
  and `initial_driver_state` with the explicit fixed file and FS state.
- `round_done:458`, `drive_after_setup:425`, and `runND_active:231` connect
  the concrete completed round to the shipped pipeline. `finalize_done:352`
  requires singleton-thread/value-arena hypotheses; the fixture proof
  discharges them. The provider record correctly avoids generalizing those
  hypotheses to arbitrary terminal states.
- `remember_result:24-27` uses actual `Pmap.add`/`find?`, `Pmap.WF`, and the
  delivered comparator laws for Nat. There is no replacement map/semantics.
  Both archived client axiom lists contain exactly `propext`,
  `Classical.choice`, and `Quot.sound`.
- The clean recipe starts detached source worktrees and a fresh dependency
  clone, rejects omitted generation/wrong pins, uses owned compiler/runtime
  installation and capped Lean commands, and builds all three packages plus
  the external client and standalone Lem targets. Its assumptions about
  installed OCaml/Lean tools and reused immutable Git sources are stated.
- All three adoption-manifest package hashes and toolchain strings match
  the subject. The tested functional revision is `1066d89ee...`; the diff
  from it to `6d6cfa858...` contains documentation/evidence only.

The fixture/test-library dependence and absence of customer adoption are
explicitly disclosed. Neither is a new defect in this bounded smoke client.

## Failure proposal, profile, plan and next charter

The current proposal preserves strict reference success soundness, sufficient
fuel and all-larger-fuel success completeness, both deliberate-failure
directions, and a success-conditioned relation to the old value definitions.
It requires positive controls and handles erased callback/operand failures
before dead-result elimination. The six `rfl` equations in `FailureMain.lean`
are counterexamples to unrestricted failure correspondence, not claims that
failure is represented faithfully. Required-failure and positive execution
controls are present in both languages. The pinned reference evaluation-order
and OCaml compiler/runtime boundaries are stated separately.

For the final design discussion, make failure-side fuel quantifiers equally
explicit: lines 219-221 state sufficient/all-larger fuel for success, while
222-224 say only that finite reference failure is reproduced. State the
eventual stable-failure requirement and the contract for unsupported guards
before implementing the larger transform. This is a design clarification,
not a claim that an implemented theorem has failed.

The full master plan, profile and next charter maintain the provider's
observer-agreement obligation, require nontrivial successful instances, and
explicitly reject always-refusing domains or agreement-as-hypothesis.
Mixed-size overlap, SeqRMW, full integration, strict failure, byte/state/fuel
debt, customer adoption and unavailable C2/C3 remain openly named. The
concurrency charter is a proposal, not implicit authorization to land it.
The profile's core distinctions are sound apart from relying on the G6
attribution evidence addressed by F-PD1. Remaining historical material is
clearly identified as historical where inspected.

## Evidence checks and coverage limits

`evidence-checks.json`, `range-mapping-reproduction.json`,
`byte-overview-counterevidence.json`, and `check-commands.json` retain derived
checks. The selected raw evidence is copied under `archived/` with its
original relative paths.

- Final provider/failure archive: exactly 150 inventory members; every
  per-member hash agrees with the committed inventory.
- Provider manifest, probe report and census hashes agree with the final
  summary links; every provider/probe command stdout/stderr hash agrees with
  its archived bytes.
- All 207 generated Lean and 86 generated OCaml file hashes in the cold
  manifest agree with the current subject tree.
- Shipped lexical census rerun equals the archived census byte-for-data;
  existing three lexical tests pass; the new independent range audit fails
  as expected on F-PD1.
- No missing local file target was found among Markdown links in the twelve
  current documents listed below. This does not certify every historical
  document or remote URL.

Full documents read: README, DESIGN, VALIDATION, TODO, master plan revision 5,
validation-foundations charter, execution record, delivery record, supported
profile, failure-census/correspondence, provider-smoke, proposed concurrency
integration charter. Supporting reads include the observation contract,
capture-composition repair, CI reporting record, current evidence index,
corrected historical inventory README, provider manifests, census/probe
scripts and fixtures, and relevant theorem dependencies. Container/repository
CLAUDE working instructions were read.

No source-level proof was independently recompiled by this reviewer, no
strictness executable was independently rerun, and no independent execution
closure was re-elaborated. The range audit instead uses hash-matched sources
and the committed completed compiler log, so those original compiler results
remain its external input. Fresh cold/probe/census execution is coordinator
work. No customer state was inferred beyond committed provider manifests.
No assessment of general ISO C conformance or runtime/logical equality is
claimed.
