# inner_arg_temps close-out — 2026-10-25–26

Branch `feature/inner-arg-temps`, resumed from park commit `dd6fcb3c3`.
Status: **COMPLETE on the feature branch**. The exact diagnostic registration
is implemented and the full battery passed 44/44, including B12 and B13.
This is the worker's slice close-out, not merge, downstream adoption or
release certification.

## B10.1 park disposition

[AGENT 2026-10-23, relayed by the operator] Resume the slice and register
only `immaculate/nolibc/zd-z2fl03-nan-to-int` as `diagnostic-text`, with the
two measured signatures from the park control. The two extra evaluator
frames follow from the authorized I0b backport of upstream `3230aa494`:
`loaded_ivfromfloat` tests `_Bool` before `Ivfromfloat`. The witness's
semantic outcome is identical on both sides: exit 125, empty stdout and
the same existing `Z.Overflow` exception; neither completes execution.
Retain the frame comparison and treat any other changed signature as a
separate finding. Finish the full battery including B12/B13, then close
the slice. Quotation hygiene remains separate work.

Implemented 2026-10-25: one entry in
`scripts/upstream_oracle_differences.json`, leaving all eight existing
entries and `test_upstream_oracle.py` unchanged. The admitted signatures
are:

| Side | Exit | stdout SHA-256 | Projected stderr SHA-256 |
|---|---:|---|---|
| Fork | 125 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` | `0f7a88b72c6adbaacff27c501d8cacafd29e1b8bde570b761334b4f3a78b5637` |
| Pristine | 125 | `e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855` | `a8aed81ebd2694a31719159a618fecf63fe023bc4d22fec1b7e4d661dcd959c3` |

The [park record](2026-10-23_inner-arg-temps-oracle-park.md) preserves the
failed battery and causal control. The new entry cites that control, this
disposition and tray 15. VALIDATION's B10.1 description and tray 15's remedy
paragraph now identify this precise diagnostic consequence. No diagnostic
projection or semantic implementation changes accompany the registration.

## Completion scope

The [I3 record](2026-10-23_inner-arg-temps-closeout-record.md) contains the
matched-mode lane, selftest, classified Csmith round, repaired libc pins,
Normal-output preservation hashes and four quotation/kernel replay checks.
I4's flags, mode limits, recursion correction, observation-set contract,
transport limitations and deferred work are in README, SUPPORTED,
VALIDATION, TODO and the
[consumer note](2026-10-21_consumer-note-cerberus-caesium-inner-arg-temps.md).
Tray 64 reports the dead recursive-main guard, tray 65 the repaired printer
loss, and tray 66 the translation.lem main comment/code mismatch. No report
has been submitted. Normal remains the default; a default change would be
a separate follow-up with consumer agreement.

## Validation

The focused `--only '^immaculate/nolibc/zd-z2fl03-nan-to-int$'` run of
`scripts/test_upstream_oracle.py` exited 0, with the exact registered pair
classified `reviewed_difference`. It used the production binary and
validated independent foundation. Verbatim scope summary:

```text
Independent oracle scope: subset (--only); 1 rows in 2.8s; source unchanged: True
```

This is a one-row check, not full-battery evidence. The register loader
accepted all nine entries; a structural comparison against the park commit
confirmed that only this row was added and all eight earlier entries are
identical. The comparison script has no diff.

The complete battery ran with no overrides and no source edits during
execution, one command at a time under the cap. Each command had the
3600-second tripwire; the whole battery was the gate:

```sh
CERB_MEM_MAX=32G DUNE_CACHE=disabled SKIP_BUILD=1 ./scripts/capped \
  python3 scripts/release.py --mode full --lane-timeout 3600 \
  --out .tmp/inner-arg-temps-final/full
```

Dispatched at 2026-10-25 23:14:41 UTC after `uptime` showed one-minute load
5.83; completed at 2026-10-26 02:04:38 UTC. Exit 0. All 44 selected commands
passed, including all 20 Tier A commands; no interrupted or unrun selected
command, artifact-inventory issue or source movement. Every command group
was cleaned up. Verbatim final summary:

```text
full: passed; 44/44 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

Derived sum of command times: 10195.774 seconds. The longest commands
were B9 at 2931.094 seconds, B7 at 1745.946 seconds and B13 at 1005.487
seconds. No command reached the one-hour tripwire. B9's approximately
49-minute cost is a measurement to retain when reviewing the existing
instrument, not a raised limit or a new timing pin.

### A15: matched-mode lane

The selftest passed and the full population reproduced its baseline.
Verbatim summaries:

```text
SELFTEST OK (control; both stripped-switch stubs; Normal-only main/libc mutations; both dump/mode plants; both binder plants; printer collision; sequence/set controls; five baseline plants; outcome failures)
SUMMARY: inner_arg_temps rows=186 AGREE=137 AGREE-FIRST=41 BOTH_FAIL=6 RESOURCE oracle:KILL=2 failures=0
BASELINE OK (inner_arg_temps: 186 rows; classes and both distinct-observation/status hashes exact)
```

The registered failures/resources retain the I3 classifications and Normal
controls; they are not execution agreement. The I3 Csmith round remains a
failed measurement with six completed comparisons and 26 classified
frontend failures also present in Normal mode. This close-out does not
reclassify that round as green or rerun it under a relaxed comparison.

### B10.1 and B12: pristine oracle

B10.1 passed all 998 rows. Derived counts: 951 semantic agreements,
36 matching failures, 9 reviewed differences and 2 interface agreements;
zero unregistered differences. The only change from the failed park sweep
is that the exact NaN-to-int pair is now a reviewed diagnostic difference.
Both its signatures reproduced the entry. Verbatim scope summary:

```text
Independent oracle scope: tier-b; 998 rows in 209.0s; source unchanged: True
```

B10.2's register/comparison controls passed, retaining the existing frame
comparison. B12 completed all four libxml2 chvalid slices with
`semantic_agreement`, exit 0. Its scope summary is verbatim:

```text
Independent oracle scope: libxml2_chvalid; 4 rows in 509.1s; source unchanged: True
```

B7 and B9 also retain these verbatim conclusions:

```text
Baseline check: 0 regression(s), 0 improvement(s)
observation lane plants: 93/93 passed
```

### B13: both libc quotations and kernel replay

All four standalone/linked round trips passed the independent whole-file
representation, comparator syntax and auxiliary BEq checks. Both modes'
alias-output controls passed, and wrong-directory invocations refused as
expected. The Normal and repaired variant quotation hashes are unchanged
from I3. Both `LibcLiteral` and `LinkedLiteral` passed
`lake env leanchecker` in each mode, all four exits 0.

| Mode / literal | Round trip seconds | Elaboration seconds / peak RSS KB | Kernel replay seconds / peak RSS KB |
|---|---:|---|---|
| Normal / standalone | 253.55 | 239.94 / 14876756 | 2.29 / 827784 |
| Normal / linked | 238.67 | 224.61 / 14886964 | 2.28 / 827408 |
| inner_arg_temps / standalone | 216.50 | 202.90 / 14336040 | 2.38 / 827468 |
| inner_arg_temps / linked | 257.76 | 243.88 / 14344300 | 2.28 / 826904 |

These are observations under the shared-box load, not timing pins.
Each mode printed the first summary below; the final unit summary is the
second line, both verbatim:

```text
Core quote round trip: PASS (whole-file representation, comparator syntax, auxiliary BEq)
Total: 2 passed, 0 failed
```

### Gated identities

The run used `dd6fcb3c3bf329b6561b97ffbfd2830de588d42f` plus the diagnostic
registration and documentation changes. Its pre/post diff SHA-256 was
`6a02b6c1553ec884a826e143e99cc35261537cc3994d9190f48f497607d2d36c`.
Only documentation completion follows the passing run; the register,
comparison, executable source and pins remain as gated.

| Artifact | SHA-256 |
|---|---|
| Difference register, nine rows | `8fe5e8eadc44df7abf76d2351964dee888b4993c62aefd77603a76c5665bacea` |
| A15 baseline | `e9f111965e4a28728eee315e3d60a3ba6fd86df368be6948be0ed48ce51aa51e` |
| Normal libc dump | `d93b99cd55dae4b23071262a24d235c69489c8e41011554194126ecc81555a0a` |
| Switched libc dump | `56986871ff4cf05959213c5c20936b0914d14bd925b5bf7223cce25be72536ac` |
| Normal libc quotation | `c165410918073f7c01762238e12ff4ec6d527141ec06bc81c7c5508d41fd4873` |
| Switched libc quotation | `6f2514217b637cedd4109b7c9698942a63b07e59f126ef257cabcf1fe10db0ca` |
| Fork oracle binary | `d3ad9876372d1070b0050aa6ffef91f9aaf92c51cf51892475daba0eb6432320` |
| Lean driver binary | `36469d84be27947ccfcc8f0be15c7d971627cecbe3f9d8ff2cfd6ba4dbf161a0` |
| LADDER membership | `92572745fc0ec775d972ba690b004998293a4342969513bb81d7043a41b9e6dd` |

The oracle rebuild's binary hash moved, with unchanged source digest
`b2b02eea39caad4158e45356e3fdd2696c37827ad7771f835891adfaf2ecb293`.
The Lean source digest remains
`9522712cf89937fd5d7170960fcd1b68b0e9acfe2cf0e3e9ca2bfd4efabdf14e`.
The pinned independent-oracle foundation manifest remains
`a5e3d0f218c17ef831535ded780f0069f3596d25d1d3b648a33c0732065d44ca`.

I1b remains approved and deferred to the quotation-hygiene slice. No
semantic implementation change was made during this final registration
and close-out. Raw captures are removed after recording these conclusions.
No merge or push.


## Post-rebase (orchestrator, 2026-10-26)

[AGENT 2026-10-26, orchestrator] The branch (tip `c1ec77ddc`, base `e32c16709`,
full battery 44/44 there) was rebased onto mainline `1bb518576` (the
union-initializer refusal, the survey docs and the outcome protocol landed since
the base) by the orchestrator, per the operator's landing instruction. The
slice's own diff changed only at the resolutions in `Main.lean` (the protocol's
envelope structure kept, the switch texts carried in), `scripts/LADDER.md` row 1,
`scripts/check_cabs_json_utf8.sh` and `scripts/check_runtime_resolution.sh`; the
file set is unchanged (pre-rebase tip preserved at
`refs/snapshots/inner-arg-temps-prerebase-20261026` until landing).

Fresh pre-merge review of the rebased tip `b2ae427d6`
(`2026-10-26_inner-arg-temps-premerge-review.md`): NOT MERGEABLE as it stood,
MERGEABLE WITH FIXES — both blocking findings were rebase-integration defects
of the orchestrator's, fixed in the following commit: P1-1 the completed-run
switch report on stderr was an "unrecognized diagnostic" to the landed
`decode_stop`, so every completed Lean run classified INVALID in the stop-aware
lanes (fix: the decoder admits exactly one well-formed report line and retains
it as `switch_report`, with plants); P1-2 the two witness scripts kept the
mainline's merged capture while the slice's assertions read `$ERR` (fix: the
capture is split). Dispositions of the rest: P2-1 this section and the charter's
status line; P2-2 the two libc refusals are REFUSAL envelopes (boundary `cli`,
item `--libc`) so no raw text precedes the report; P2-3 and P2-4 queued in
TODO.md (the `-d5` bare-name census speedbump; the csmith-corpus fuzz row) —
fail-closed transport is NOT claimed; P3-1 header lines added to the misnamed
records; P3-2 the stale "ONE instance" comment corrected. Re-validation: the
orchestrator's full battery on the landed tip is quoted in the landing note.
