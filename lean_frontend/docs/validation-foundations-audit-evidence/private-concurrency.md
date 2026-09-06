# Fresh private G2 observation audit

2026-09-06, independent reviewer `audit_observations`. Frozen subject
`validation-foundations-concurrency` at
`eb926f8d37187490c34a74bd4ffe74c80acdc77b`, feature base
`086d8762d382eff375c101f5f0c64d3ffe9bccc7`.

The status repair works on the supplied plants, and the source-preservation
claims checked below hold. The shared descendant-OOM defect remains a P1
blocker for the claimed instrument. Three additional P2 boundary defects
remain in the private lane. Two are inherited reference/refusal weaknesses,
and the third is an incomplete repair of inherited failure-message parsing.
None is evidence of a changed concurrent C semantics.

All writing occurred in this audit directory in the primary worktree. The
private worktree remained clean. No engine, Lean/lake/make/dune, heavy corpus,
legacy campaign, refined-cerberus, merge, or external communication was run.

## P1 shared finding: positive descendant-OOM witness is ignored

Primary report `../REPORT.md`, O3, applies unchanged here:
`scripts/observations.py:139,165` does not reject the second positive witness
from `scripts/capped:76-78`, `capped: OOM event recorded in cgroup ...` when
the direct command exits 0 or 1. A matching Defined/status-0 pair remains
completed agreement despite the cap reporting a killed descendant.

`snapshot.json` verifies both codec and capped byte-identical to the audited
primary. The coordinator's actual shipped-wrapper confirmation is retained
in `../../descendant-oom/`, setup `../../reproduce_descendant_oom.py`; our
independent production-function reproduction is in the parent observation
directory. This is wrapper/codec evidence, without claiming the 30 C cases
can launch the planted descendant. Reject all positive cap witnesses before
any batch or litmus policy exception, irrespective of direct command status.

## G2-1 — P2: InternalError loses continuation bytes and admits a second fatal diagnostic

Locations: `scripts/observations.py:33-35,148-164`;
consumer `scripts/test_litmus.sh:95-96,145`.

The litmus policy recognizes one single-line internal-error regex over
combined stdout/stderr, stores only its first line as the message, and
checks unrecognized remainder only on stdout. It returns before the common
fatal-diagnostic guard. Thus these stderr/status pairs compare equal:

```
oracle, status 125: internal error: reason
                   left payload continuation
Lean, status 134:   PANIC at LemLib.failwithIImpl LemLib.lean:10:3: reason
                   right payload continuation
```

The extracted production `run_all` and `compare_to` report
`DIFF_FAIL=0 COMPARE_FAIL=0` against the controlled
`{INTERNAL_ERROR(reason)}` reference. A second independent probe appends
`Fatal error: exception Failure("second fault")` only to the Lean stderr;
it also passes. Changing the recognized first-line message is correctly a
DIFF, so this is selective loss rather than a broken test harness.

Evidence: `internal-different-continuation.*`, `internal-extra-fatal.*`, and
the corresponding subdirectories containing exact capture triplets.
`internal-different-first-control.*` rejects; `internal-control.*` passes.

Impact: complete failure-message agreement is not established. Deliberately
different stack traces may need normalization, but arbitrary continuation
bytes and a second fatal diagnostic are not thereby proved irrelevant. The
current committed 30 target/baseline rows contain no INTERNAL_ERROR target,
so a transition of an existing row to this token still fails the reference
comparison. Do not claim this probe makes today's fixed 30-row lane green
after such a transition. It demonstrates a false engine-agreement claim and
unsafe support for the explicitly permitted internal-failure reference case.

Correction: define and parse the exact failure/diagnostic boundary, retain
the entire message, reject additional fatal records, and allow only known
diagnostic envelopes. If multiline payload cannot be distinguished from
trace metadata under this printer, reject ambiguity or document and enforce
an explicit narrower unsupported case. Add both continuation and second-
fatal probes to the shipped suite. The full decoder exists only in the
repair, although the old sed extractor already had first-line loss.

## G2-2 — P2: duplicate reference rows silently overwrite earlier contradictory rows

Locations: `scripts/test_litmus.sh:119-126,181-209`;
`tests/litmus/sc_reference.py:229-240` (unchanged from feature base).

Both readers assign into maps without rejecting an existing key. Given a
healthy Specified(0) engine pair and this reference:

```
probe.c SC {Specified(99)}
probe.c SC {Specified(0)}
```

the actual helper reports a MATCH and zero failures. Keeping only the first
row, or reversing the two rows, correctly fails. The mechanical derivation
gate has the same defect: prefixing the committed expectations with
`SB+sc_sc+sc_sc.c SC {Specified(99)}` still yields status 0 and
`sc_reference: all 19 SC rows agree with the derivation`. Replacing that
row's unique target with 99 correctly fails.

Evidence: `duplicate-overwrite.*`, `duplicate-reverse-control.*`,
`bad-row-control.*`, `reference-duplicate.*`,
`reference-bad-only-control.*`; the two planted expectations files are
retained verbatim. The complete original expectations file is the positive
control. The combined derivation and lane readers therefore do not repair
each other's omission.

Impact: a malformed reference with two different assertions for one program
can be certified as all rows passing, dependent on order, despite the
declared bijection. Today's committed expectations and baseline each have
30 unique rows and exactly match the 30 C filenames; there is no currently
committed duplicate or missing-row corruption. This is an inherited open
instrument defect, not an introduced data regression.

Correction: reject duplicate names at insertion in both readers (regardless
of whether their values happen to agree), with file/line diagnostics. Add
contradictory and identical duplicates, reversed order, missing/orphan row,
and a valid reordered reference as durable plants.

## G2-3 — P2: an unrelated second Error satisfies REFUSE and the sequential-refusal leg

Locations: `scripts/test_litmus.sh:143-144,169-171,192-194`;
reference contract `tests/litmus/expectations.txt:10-11`.

The codec correctly keeps both complete Error records below, and the
engines' complete sets agree. The reference projection collapses both to
one ERROR token while the refusal guard examines only the first message:

```
EXECUTION 0:
Error {msg: "model refused: thread spawn is unavailable"}
EXECUTION 1:
Error {msg: "unrelated evaluator failure"}
```

Both status values are 0, which is the codec's correct multi-execution
status convention. The production `run_all`, `seq_leg` and `compare_to`
report matching REFUSE, matching sequential spawn refusal, and
`DIFF_FAIL=0 COMPARE_FAIL=0 SEQ_FAIL=0`. An identical singleton refusal at
status 1 passes as expected; putting the unrelated error first fails both
guards.

Evidence: `refusal-plus-unrelated-error.*`, `refusal-control.*`,
`unrelated-error-first-control.*`, plus exact stdout/stderr/status in their
subdirectories. This is **two distinct errors**, not repeated identical
executions that the lane intentionally treats as a set.

Impact: a common engine regression adding a different failure path can pass
the seven NONSC REFUSE references and the sequential-refusal requirement.
The reference file explicitly requires exactly one Error line matching the
refusal pattern. Even if that is relaxed to duplicate-insensitive sets,
accepting an additional distinct, non-refusal Error is not justified. This
weakness predates the status repair; complete engine-to-engine comparison
does not supply the missing independent refusal check.

Correction: apply the refusal predicate to the decoded verdict collection.
Enforce the declared singleton requirement or explicitly require a singleton
distinct Error set, and validate its entire message against the intended
refusal. Add a valid refusal followed by a distinct unrelated Error, reversed
order, and singleton controls to both regular and sequential plants.

## Scope verification and checks performed

`check_snapshot.py` and `snapshot-commands.json` retain exact read-only git
commands; `snapshot.json` records results:

- HEAD and full feature base match the delivery record; private git status
  is empty. The 18 changed paths contain no shared semantics, handwritten
  Lean semantics, C litmus source, reference set, or reference enumerator.
- All 72 fork-manifest source paths, 12 semantic generated-diff hashes and
  11 cosmetic generated-diff hashes are the same multisets as the base, with
  no duplicates. The compiler metadata/order repair has not replaced the
  feature-specific source or hash surface.
- Key preserved whole-file hashes include `frontend/concurrency/cmm_csem.lem`,
  `frontend/model/driver.lem`, `lean_frontend/Main.lean`,
  `lean_frontend/Cmm_csem_lemMeasureProofs.lean` and
  `scripts/fuel_forms_pending.txt`. The original apply_tree/List.all bodies
  at cmm_csem lines 560-564 and 3254-3259 and the S7 initialization edges at
  driver lines 2107 onward and 2404 onward remain in place.
- All 12 effective source pins from candidate.json plus the follow-up
  manifest match frozen HEAD. Shared codec, shell interface, tests and capped
  match the primary bytes. The private fork-drift implementation is older
  than the primary, as documented; reviewed the full private implementation.
- Current references each have 30 unique rows exactly covering the corpus.
  The unmodified Python SC derivation check passes all 19 transcriptions.
  This is a check of the stated finite reference, not a proof of its C-to-IR
  hand transcription or general concurrent-model completeness.
- Supplied private hermetic observation plants pass **26/26**;
  `shipped-plants/report.json` retains per-case raw captures and commands.
  Original CR-1 probe passes its healthy control and rejects **4/4** abnormal
  status pairs; `original-status-probe.stdout` records the result.
- `bash -n` passes the five changed shell files. SHA256SUMS validates both
  shipped archives and candidate manifests. Exact commands/statuses are in
  `checks.json`; checksum verification does not re-run the archived ladder.

Executed from the frozen primary (outputs redirected within this directory):

```
PYTHONDONTWRITEBYTECODE=1 python3 .validation-foundations/premerge-audit-20260906/observations/private/reproduce.py
PYTHONDONTWRITEBYTECODE=1 python3 .validation-foundations/premerge-audit-20260906/observations/private/check_snapshot.py
```

The supplied plant suite was run from the private root with
`PYTHONDONTWRITEBYTECODE=1`, `CERB_OBSERVATION_DIR` set to this directory, and
`python3 scripts/test_litmus_observations.py --out <this-directory>/shipped-plants`.
The original status probe used `TMPDIR=<this-directory>/tmp` so temporary
artifacts stayed within the authorized audit output. `reproduce.py` extracts
the frozen lane helpers verbatim, replaces only engine runners with saved
fixtures, and retains the composed `helpers.sh`. Per-probe exact commands,
stdout/stderr/status, source hashes, and aggregate `reproduce.log` accompany
this report. These are light helper-level plants, not full actual-entry or
real C engine executions.

## Reviewed sources and unresolved limits

Read full private test_litmus.sh, test_litmus_observations.py,
observations.py/sh, common.sh, check_fork_drift.sh, fork_drift_manifest.txt,
sc_reference.py, expectations.txt, before_baseline.txt, original status probe,
private delivery report and both source-pin manifests. Reviewed the
test_unit.sh fork-drift wiring changes; the shared byte-identical codec test
file was fully reviewed/tested in the primary audit. Read applicable container,
root and lean_frontend CLAUDE.md instructions. Reviewed targeted S7/apply_tree
semantic excerpts and verified whole-tree change scope; no independent
general semantic proof is claimed.

The delivery properly limits G2 to repairing the older private instrument
and keeps concurrency integration, mixed-size overlap, SeqRMW sequencing,
provider agreement, current-mainline compatibility, and the feature's older
fuel classification open. No fresh full ladder or source-generation run was
performed by this reviewer; coordinator owns heavy scheduling.

The shared codec's printed Error-state and whole-framed-suffix-loss limits
remain inherited protocol boundaries. The coarse reference set deliberately
omits UB locations and output fields, but live engine-to-engine comparisons
retain those fields; that is not itself a finding. Diagnostic trace
normalization needs an explicit boundary as described in G2-1.

Minor documentation issue: observations.py:5 refers to
`lean_frontend/docs/2026-09-05_observation-contract.md`, which is absent in
this private checkout. The private delivery describes the projection but
does not supply that normative schema document. Ship or link an available
version if this private instrument is meant to be independently reviewable.
