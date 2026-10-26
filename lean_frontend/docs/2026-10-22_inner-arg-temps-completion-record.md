# Park: exhaustive cross-mode observation multiplicity

(This file is the MULTIPLICITY PARK record, despite its file name; the I3 completion
record is `2026-10-23_inner-arg-temps-closeout-record.md` and the close-out is
`2026-10-25_inner-arg-temps-closeout-record.md`. Header added at the pre-merge review, P3-1.)

2026-10-22, branch `feature/inner-arg-temps`, resumed from `9c391406c`.
Status: **Dispositioned, 2026-10-23**. Cross-mode observation multiplicity
is admissible; the oracle sanity comparison now uses distinct complete
observation sets. The historical park follows. Current validation is in
the [completion record](2026-10-23_inner-arg-temps-closeout-record.md).

## Transport park resolution

[AGENT 2026-10-22, relayed by the operator] Resume the slice and accept the
registered `strerror` failure. Transport acceptance compares each libc
row's complete observation across both engines and both modes. The
unconditional assert in `runtime/libc/src/string.c:347-351` gives the same
Error four ways. Its Normal registration is `039-strerror-assert MATCH`
in `tests/libc_exec/baseline.txt:38`, whose MATCH denotes equal complete
tokens, including Errors. Retain `BOTH_FAIL` in the new lane, with that
citation; it does not count as execution agreement. Remove the blanket
containment for the repaired transport, retaining the per-dump binder
refusal. Finish I3/I4 and the full battery. I1b remains deferred. Launch
Tier A/Tier B only below load 6 and keep heavy jobs sequential.

The [repair record](2026-10-22_inner-arg-temps-transport-record.md) preserves
the original finding, Normal byte-identical captures, implemented printer
and loader checks, corrected dump pin, and the park's green Tier A.
I2's original green was a faithful quotation of a corrupted parse, not
transport evidence. The production lane now explicitly runs all 42 libc
rows in both modes on both engines; it compares complete tokens even for
039. The positive selftest includes 039, and a Normal-only libc mutation
must fail the four-way check. No previous baseline changes are authorized.

## Work and results

For the production validation below the blanket CLI refusal was removed;
`R-IAT-LIBC-SYMBOL-LOSS` remained at
libc loading for any dump with a procedure body binder reusing a formal
parameter name. Other refusals (`--call`, mixed switch sets, dump/mode
mismatch) remained. The failing acceptance check below restores the blanket
containment pending disposition; the quotation pin is unchanged.

## Production rebuild

After `make lean-prelude-src`, the capped `lake build CerberusLean
cerberus-lean` passed (404 jobs). Both freshness checks passed. The rebuilt
Main module introduced no warning; Lake replayed existing warnings from
unchanged generated/dependency and handwritten modules. No warning was
suppressed by this change.

| Identity | SHA-256 |
|---|---|
| Oracle binary | `40715bbce7efa58706459c8258f9fe3cf88d696f766dc5b83d97d63837bd91ab` |
| Oracle source set | `b2b02eea39caad4158e45356e3fdd2696c37827ad7771f835891adfaf2ecb293` |
| Lean binary | `36469d84be27947ccfcc8f0be15c7d971627cecbe3f9d8ff2cfd6ba4dbf161a0` |
| Lean source set | `9522712cf89937fd5d7170960fcd1b68b0e9acfe2cf0e3e9ca2bfd4efabdf14e` |

The proposed ladder entry parsed as 20 Tier A commands and 44 Tier A+B
commands. It is withdrawn at park because no baseline can be adopted. The
existing ladder remains 19/43. Membership comes from LADDER.md, so no
duplicate hard-coded release.py catalogue is needed. The per-command
tripwire remains 3600 seconds.

## Failure and resource registrations

The five minimal failures cite `scripts/exec_baseline.txt:75`, `:76`,
`:99`, `:114` and `:115`: 073/074 (unknown exit/abort without libc),
097 (null-pointer shift TODO), and 112/113 (allocator exhaustion).
The lane compares their failure class with Normal, retains separate hashes
of the full tokens, and never counts them as execution agreement. The
numeric Symbol-ID exception for 073/074 is unchanged from the transport
record; no `_fav` diagnostic-text difference is admitted.

`p07_list_sum` and `p08_list_reverse` have existing Core-dump registrations
in `tests/corpus/*.core.sha256`, selected by `scripts/test_verify.sh:197`.
That older lane does not execute these large-arena programs; it is not an
existing Normal RESOURCE baseline. The new lane explicitly measures both
engines in Normal and switched mode at the same 4G/30s bounds. Resource
outcomes are recorded separately from agreement. No old registration moves.

## New acceptance finding and park

The full production sweep launched at 04:30 UTC with load 5.73. Both
engines were fresh; no driver override was used. It completed all 186
rows and returned 1 (about 515 seconds from first capture to final result).
The baseline writer correctly wrote no baseline.
The run's final summary was:

```text
SUMMARY: inner_arg_temps rows=186 AGREE=136 AGREE-FIRST=41 BOTH_FAIL=6 RESOURCE oracle:KILL=2 failures=1
inner_arg_temps: FAIL — failed rows: ['libc/exhaustive/001-unseq-order-libc']
```

The failing row is `tests/libc_exec/exhaustive/001-unseq-order-libc.c`.
It evaluates two unsequenced calls to `set`, then formats/prints the result
through libc. Both engines exit 0 and agree on their **complete ordered
sequences within each mode**. Those sequences differ across modes:

| Mode, both engines | Complete observations | Multiplicity of each distinct result | Full-token hash (lane) |
|---|---:|---|---|
| inner_arg_temps | 4 | Specified(32), stdout `3-2\n`: 2; Specified(31), stdout `3-1\n`: 2 | `a7b62efae56a` |
| Normal | 80 | Specified(32), stdout `3-2\n`: 40; Specified(31), stdout `3-1\n`: 40 | `4a8b908ce912` |

Stderr is empty and blocked is false in every verdict. The distinct
outcome sets coincide, but the required complete observations do not.
No deduplication, sorting, first-result substitution or weaker projection
is applied. This observation establishes an acceptance-premise conflict,
not a demonstrated printer-loss defect: the repaired engine pair agrees
exactly under each convention. The other exhaustive row, `002-errno-basic`,
has five observations four ways, hash `fd8117003e27`.

All 40 top-level libc inputs pass the four-way complete-token comparison:
39 execution agreements and the accepted `039-strerror-assert` BOTH_FAIL.
Including exhaustive/002, 41 of the 42 libc rows pass the revised cross-mode
criterion. All 42 matched-mode switched engine pairs agree on their complete
observations. The three main witnesses pass four ways, and both upstream
backport witnesses match their expected output. The two resource rows are
KILL on both engines in both modes, not timeouts. Load rose above 20 during
libc validation; the failing exhaustive row is a completed exit-0 sequence
difference, not a resource result.

[AGENT 2026-10-22] Park on the falsified complete cross-mode sequence premise,
as the charter requires. Restore switched-libc containment, retain the
per-dump detector, adopt no baseline or release row, and leave the comparator
unchanged. A disposition must settle whether this exhaustive multiplicity
difference is admissible and specify its comparison contract before I3 can
continue. No Normal-mode or other existing baseline changes.

Reproduce after the documented build, using the production driver with
only the blanket containment removed (the state measured above):

```sh
CERB_MEM_MAX=32G SKIP_BUILD=1 ./scripts/capped \
  python3 scripts/inner_arg_temps_lane.py \
  --oracle "$PWD/_build/default/backend/driver/main.exe" \
  --lean "$PWD/lean_frontend/.lake/build/bin/cerberus-lean" \
  --out "$PWD/.tmp/inner-arg-temps-completion/population" --record-baseline
```

The cross-mode discrepancy itself can be reproduced on the contained
checkout using the oracle alone; these two complete stdout streams have
80 and 4 verdicts respectively:

```sh
CERB_MEM_MAX=4G ./scripts/capped _build/default/backend/driver/main.exe \
  --runtime=_build/install/default --exec --batch --mode=exhaustive \
  tests/libc_exec/exhaustive/001-unseq-order-libc.c
CERB_MEM_MAX=4G ./scripts/capped _build/default/backend/driver/main.exe \
  --runtime=_build/install/default --exec --batch --mode=exhaustive \
  --switches=inner_arg_temps \
  tests/libc_exec/exhaustive/001-unseq-order-libc.c
```

A focused reproduction uses a fresh output directory and
`--observe --rows '^libc/exhaustive/'` instead of `--record-baseline`.
The committed contained driver will refuse switched libc; do not mistake
that containment for an execution reproduction.

## Outstanding

No new baseline exists. The full selftest, Csmith measurement, repaired
variant quotation pin/replay, I3 release registration and I4 close-out/full
battery remain uncompleted. B13 remains blocked by containment. I1b stays
deferred to quotation hygiene. The row-039 disposition is accepted and
unchanged; this park is a separate complete-sequence multiplicity finding.

## Park checkpoint validation

The final contained production rebuild passed (404 jobs), and both
freshness checks passed. Final Lean binary SHA-256:
`92d66851af7bf65cfd0920ac58cc494cfbc471825075a12d112644600ab2deb9`;
source-set SHA-256:
`a75ba8ec91cf01caab5dac37c940cab91b7c02ce2fc5eeea6ec5d2cac2265cc1`.
The oracle identity above is unchanged. Execution and standalone quotation
probes return exit 2 with the new multiplicity-specific containment text,
empty stdout and no quotation file. The first two probe invocations hit
earlier CLI guards (missing LEAN_ABORT_ON_PANIC, then misplaced --batch);
the corrected invocations use the canonical argument order and the panic
setting and check the intended refusal. No failure is counted as a pass.

The existing Tier A checkpoint passed all 19 commands, exit 0, launched
at 04:47 UTC with load 5.33 and completed at 05:10 UTC. Summed command
time: 1406.8 seconds. Source and external input identities stayed unchanged;
the runner reports no artifact issues. Its unit row passed all 20
executables, including 297 parser checks. No existing baseline moved.
Command (repository root, after the fresh contained build):

```sh
CERB_MEM_MAX=32G DUNE_CACHE=disabled SKIP_BUILD=1 ./scripts/capped \
  python3 scripts/release.py --mode fast \
  --out .tmp/inner-arg-temps-completion/tier-a
```

Verbatim conclusion:

```text
PASSED A14.2 (166.0s)
fast: passed; 19/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

This certifies the existing Tier A membership only. The new lane's
production acceptance test failed; its baseline and release registration
remain unadopted. No full-battery or completed-delivery claim is made.
Raw captures, build logs and release reports are ephemeral and removed
after recording these conclusions and reproduction commands.
