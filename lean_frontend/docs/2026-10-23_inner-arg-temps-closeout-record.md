# inner_arg_temps completion — 2026-10-23

Branch `feature/inner-arg-temps`, resumed from `5662ee63e`.
Status: **I3/I4 complete on the feature branch**. The
[2026-10-25 close-out record](2026-10-25_inner-arg-temps-closeout-record.md)
records the exact diagnostic registration and the 44/44 full-battery pass
completed on 2026-10-26.
I3 is committed at `a74922afef98e88dcba903f3953c65f9a31d82c0`
after Tier A passed. The full battery failed B10.1 on a Normal diagnostic
change and was stopped; see the [park record](2026-10-23_inner-arg-temps-oracle-park.md).
That first full run did not establish close-out.

## Multiplicity park disposition

[AGENT 2026-10-23, relayed by the operator] Resume with the corrected
cross-mode contract. Within each mode, compare the two engines' complete
ordered observation sequences exactly; this remains the trust surface.
Across modes, compare only the oracle's sets of distinct complete
observations, retaining value, stdout, stderr and blocked. This sanity
instrument ignores order and multiplicity. A distinct-outcome difference
is a finding to refuse and report; multiplicity alone is admissible.
The orchestrator acknowledges the earlier sequence premise as its third
charter error. Lift blanket containment for the repaired transport, retain
the per-dump detector, adopt the lane baseline/release entry and complete
I3/I4 and the full battery. I1b remains deferred; no push is authorized.

Normal calls create and store an object for each argument in the caller.
Those unsequenced steps multiply exhaustive interleavings. Under
inner_arg_temps the callee allocates after the call, reducing paths while
preserving behaviours. In this tree, translation.lem:934–960 constructs
the caller create/store fragments, while :4426–4447 adds the switched
callee prelude. The measured witness is
`tests/libc_exec/exhaustive/001-unseq-order-libc.c`: two distinct complete
outcomes, 80 observations in Normal and 4 under the switch, exact engine
agreement within each mode. These counts are informational, not pins;
unrelated elaboration changes can alter enumeration. The
[park record](2026-10-22_inner-arg-temps-completion-record.md) preserves the
original failed premise and measurements.

[AGENT 2026-10-23] Baseline observation hashes use sorted distinct complete
tokens so they do not implicitly pin path counts. This projection is used
only for cross-revision baseline identity and the oracle cross-mode sanity
check. Engine comparisons keep the full ordered sequences at run time.
Failure/resource classes and their Normal controls retain their prior
classification contract; they never become execution agreement.

## Implementation and scope

The blanket switched-libc refusal is removed. The printer's per-procedure
collision refusal and the loader's parameter-rebinding detector remain,
including for Normal dumps and quotation. The loader's accepted conservative
over-refusal and transport assumptions are documented in VALIDATION.

The lane runs all 42 libc inputs on both engines in both modes. Each pair
must have exactly equal complete sequences, including the registered
strerror Error (BOTH_FAIL, citing `tests/libc_exec/baseline.txt:38`). Cross-mode
sets are checked on the oracle only. The three main witnesses keep their
expected results, with both engine pairs and the oracle set comparison.
Their GCC results remain 7 without arguments and 42 with argc/argv;
upstream's guard is dead on the active driver path, so recursive main
executes. Tray 64 reports that guard and tray 66 the translation.lem:4331
main-exclusion comment; neither changes the model or has been submitted.

Selftest controls cover per-mode order/multiplicity changes, oracle-set
changes to each complete observation field, allowed cross-mode duplication
and reordering, each stripped switch, Normal-only Lean main/libc mutations,
both dump/mode pairings, both binder plants, printer collision, baseline
corruptions and invalid outcome pairs. Fuzzing uses the same oracle set
rule and exact switched-engine sequence comparison.

I2's original green was a faithful quotation of a corrupted parse, not
transport evidence. The repaired dump and the quotation validation below
are separate evidence. The Normal output hashes and printer manifest
re-pins remain as recorded in the
[transport record](2026-10-22_inner-arg-temps-transport-record.md).

## Validation results

Completed measurements are below. The Tier A checkpoint is green. The
44-command full battery did not pass: B10.1 failed, B12 was interrupted and
B13 was not dispatched. Its summaries and diagnosis are in the park record.

### Production population

The full 186-row run completed in 373.92 seconds, exit 0, using fresh
production binaries and no overrides. The baseline is
`tests/inner_arg_temps/baseline.json`. Exact conclusion:

```text
SUMMARY: inner_arg_temps rows=186 AGREE=137 AGREE-FIRST=41 BOTH_FAIL=6 RESOURCE oracle:KILL=2 failures=0
```

All 42 libc rows have exact per-mode engine sequences and equal oracle
cross-mode sets: 41 execution-agreement rows and one registered strerror
BOTH_FAIL. Exhaustive 001 retains the informational 80/4 counts and two
distinct outcomes; exhaustive 002 has five observations and one distinct
outcome in each mode. The main witnesses return 0/7/42 as specified, and
both upstream backport witnesses match their committed expected output.

The five non-libc BOTH_FAIL rows cite the existing Normal CERB_SKIP entries
in `scripts/exec_baseline.txt:75`, `:76`, `:99`, `:114`, `:115` (073/074,
097, 112/113). The Symbol-number exception is confined to classifying
Errors, with complete failure-token hashes retained. Both list corpus
programs p07/p08 hit the 4G cap on both engines in both modes; no switch-only
failure is admitted. Their older Normal registrations in
`tests/corpus/*.core.sha256` are dump checks, not resource execution claims,
as the transport record explains. No previous baseline changes.

Reproduce from the repository root after the documented build:

```sh
CERB_MEM_MAX=32G SKIP_BUILD=1 ./scripts/capped \
  python3 scripts/inner_arg_temps_lane.py \
  --oracle "$PWD/_build/default/backend/driver/main.exe" \
  --lean "$PWD/lean_frontend/.lake/build/bin/cerberus-lean" \
  --out "$PWD/.tmp/inner-arg-temps-closeout/population" --record-baseline
```

Baseline SHA-256: `e9f111965e4a28728eee315e3d60a3ba6fd86df368be6948be0ed48ce51aa51e`.
The normal use is `scripts/test_inner_arg_temps.sh --gate`; recording the
baseline is a deliberate adoption operation, not part of that gate.

### Lane selftest

`inner_arg_temps_lane.py --selftest` with the same fresh engine paths and a
fresh `--out .tmp/inner-arg-temps-closeout/selftest` passed, exit 0. Its
positive control includes the registered strerror Error. Verbatim summary:

```text
SELFTEST OK (control; both stripped-switch stubs; Normal-only main/libc mutations; both dump/mode plants; both binder plants; printer collision; sequence/set controls; five baseline plants; outcome failures)
```

The sequence controls separately change order with fixed multiplicity and
multiplicity with unchanged distinct outcomes; both fail the per-mode
comparison. The cross-mode control accepts both changes, while individual
value/stdout/stderr/blocked mutations fail. These are instrument plants,
not new semantic discrepancies.

### Csmith measurement (failed round, findings classified)

Csmith 2.3.0 (`30dccd7`), 32 seeds 2026102101–2026102132, using the same
profile as `scripts/fuzz_csmith.sh`: `--no-argc --no-bitfields --max-funcs 3
--max-block-depth 3 --max-block-size 4 --max-expr-complexity 3`. The generated
programs use the repository's `csmith_cerberus.h` and `safe_math.h`, with
`CSMITH_MINIMAL`; the header returns the checksum low byte from main.
Each switched engine runs a single trace; the oracle also
runs Normal. Bounds are 30 seconds and 4G per invocation. Captures span
53.24 seconds from first generation command to results write, below the
one-hour tripwire. Reproduce with the population command above, replacing
`--record-baseline` with `--fuzz 32 --seed-start 2026102100` and using a fresh
`--out` directory. Exact summary, process exit 1:

```text
SUMMARY: inner_arg_temps rows=32 AGREE-FIRST=6 failures=26
```

The six completed seeds are 2026102119, 2026102124, 2026102128,
2026102130, 2026102131 and 2026102132. All have exact switched-engine
complete sequences and equal oracle cross-mode sets (one observation in
each mode). This is six single-trace comparisons, not 32 execution
agreements or an exhaustive campaign.

All 26 failures occur before execution. Every failing seed has the same
oracle exit status and principal diagnostic in Normal and switched mode;
wall-time lines differ and invalid-AIL backtraces can include extra switched
allocation frames. These diagnostic comparisons classify findings only;
they are not the complete-observation comparison used for agreement.
The failed rows remain failures; no baseline or decoder is relaxed.
Seed suffixes below are appended to `20261021`:

| Suffixes | Count | Finding and disposition |
|---|---:|---|
| 01, 05, 10, 12, 14, 15, 16, 17, 18, 20, 22, 23, 25, 26, 27, 29 | 16 | Both modes of the oracle crash (125), and Lean under the switch panics, with `Translation called on Ail program with an invalid node`. This is the existing nested-initializer failure in [tray 08](upstream-tray/08-desugar-nested-init-internal-error.md). Union debug diagnostics on some rows additionally make the oracle capture INVALID to the strict observation codec. Neither crash nor INVALID is execution agreement. |
| 03, 08, 09 | 3 | Oracle rejects a static address initializer as non-constant (exit 1); Lean reports a desugaring Error at the same initializer. The expressions combine array subscripting and member selection (`&g_24[5][7].f0.f3`, `&g_119[2][2][1].f2`, `&g_98[8].f0`), the existing class in [tray 09](upstream-tray/09-address-constant-member-rejected.md). |
| 02 | 1 | Oracle rejects assignment from `unsigned short*` to `signed short*` (exit 1); Lean reports a typechecking Error at that assignment. Generator input hits the frontend's incompatible-pointer constraint; no execution observation is available. |
| 04, 06, 07, 11, 13, 21 | 6 | Oracle rejects pointer comparisons with incompatible operand types (exit 1); Lean reports typechecking Errors at the same expressions. Operand pairs include signed/unsigned pointees and differing nested pointer qualifiers. These are frontend constraint rejections, not a switched-mode regression or evidence of semantic disagreement. |

For the ten diagnostic-rejection rows the oracle emits a human diagnostic
without a completed batch observation, while Lean emits a structured Error.
The lane deliberately reports INVALID instead of inventing an equal token.
The pre-existing crash and address-constant findings already have tray drafts;
the pointer diagnostics do not establish a new upstream defect. There is no
observed distinct-outcome set discrepancy and no switch-only frontend failure
in this round. No new finding is silently admitted into the lane baseline.

### Pins and production build

The repaired variant quotation pin changes from
`920c9638e4fb6d78744b740795eff25ea715814d6f1ca3dfa4c4b6a8432429b3`
to `6f2514217b637cedd4109b7c9698942a63b07e59f126ef257cabcf1fe10db0ca`.
The new literal preserves the distinct parameter-value and object symbols
from the repaired text dump. This is the authorized transport repair, not
an unexplained baseline movement. The variant dump was already re-pinned
with the printer repair; the Normal dump and Normal quotation pins do not
move. Normal output preservation was measured before/after the repair:

| Artifact | SHA-256 |
|---|---|
| Normal libc dump | `d93b99cd55dae4b23071262a24d235c69489c8e41011554194126ecc81555a0a` |
| Repaired inner_arg_temps libc dump | `56986871ff4cf05959213c5c20936b0914d14bd925b5bf7223cce25be72536ac` |
| Aggregate of 42 Normal libc-exec Core outputs | `70b185aceb87b9a61d5a4a76cce542f3752fc4629b6430bdd3679b1372edaab5` |
| Aggregate of ten Normal fixture Core outputs | `974fac545aefe3e012d31c76b617751484c3f34efd662209127f7c3b3186581d` |

The aggregate format is sorted `<row-name> <file-sha>\n`; the transport
record gives the capture commands. The three printer source-content
manifest rows and their dated notes are committed with that repair.
No differential text baseline has moved.

After `make lean-prelude-src` and a capped `lake build CerberusLean
cerberus-lean`, the production freshness check reports:

```text
check_driver_fresh: oracle OK (bin 5f2bd315c543fb3990cae35578fd07de094b67d2257ee5f9594fa770abf07b3e, src b2b02eea39caad4158e45356e3fdd2696c37827ad7771f835891adfaf2ecb293)
check_driver_fresh: lean OK (bin 36469d84be27947ccfcc8f0be15c7d971627cecbe3f9d8ff2cfd6ba4dbf161a0, src 9522712cf89937fd5d7170960fcd1b68b0e9acfe2cf0e3e9ca2bfd4efabdf14e)
```

Build and all test commands use the project cap. The build replays existing
generated-code warnings; no new warning is suppressed in this slice.
`release.py` discovers A15 directly from LADDER, giving 20 Tier A and 44
full commands without a duplicate catalogue in Python. Each release command
has its existing 3600-second tripwire; the whole selected battery is the
gate, even when the sum of its commands exceeds an hour.

### B13: repaired quotation validated

`CERB_MEM_MAX=32G DUNE_CACHE=disabled SKIP_BUILD=1 ./scripts/capped
./scripts/test_unit.sh --core-quote-libc` exited 0. All four standalone/linked
round trips passed the independent representation comparison, comparator
syntax and auxiliary BEq checks. Both canonical-directory controls passed;
both wrong-directory cases refused without output. Normal's literal pin
remains `c165410918073f7c01762238e12ff4ec6d527141ec06bc81c7c5508d41fd4873`;
the switched literal matches the repaired pin above.

| Mode / literal | Round trip seconds | Elaboration seconds / peak RSS KB | Kernel replay seconds / peak RSS KB |
|---|---:|---|---|
| Normal / standalone | 178.17 | 169.62 / 14876348 | 1.82 / 825516 |
| Normal / linked | 138.55 | 130.73 / 14888540 | 1.86 / 825532 |
| inner_arg_temps / standalone | 126.74 | 119.77 / 14342064 | 1.79 / 825784 |
| inner_arg_temps / linked | 133.58 | 126.14 / 14348864 | 1.84 / 825536 |

All four `lake env leanchecker` invocations exit 0. Total round-trip time
is 577.04 seconds; this remains a Tier B cost observation, not a time pin.
The two mode summaries are identical; the final unit summary is:

```text
Core quote round trip: PASS (whole-file representation, comparator syntax, auxiliary BEq)
Total: 2 passed, 0 failed
```

Together with the matched-mode libc execution lane, this validates the
repaired path. Literal self-consistency alone would repeat I2's mistake.

### I3 checkpoint: Tier A

From the repository root:

```sh
CERB_MEM_MAX=32G DUNE_CACHE=disabled SKIP_BUILD=1 ./scripts/capped \
  python3 scripts/release.py --mode fast \
  --out .tmp/inner-arg-temps-closeout/tier-a
```

Exit 0; all 20 commands pass, including A15's selftest and full population.
No artifact issues, incomplete selection or source movement. No baseline
outside the new lane changes. Verbatim runner summary:

```text
fast: passed; 20/20 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

The A15 population summary and baseline result are:

```text
SUMMARY: inner_arg_temps rows=186 AGREE=137 AGREE-FIRST=41 BOTH_FAIL=6 RESOURCE oracle:KILL=2 failures=0
BASELINE OK (inner_arg_temps: 186 rows; classes and both distinct-observation/status hashes exact)
```

The routine A1 oracle rebuild records binary SHA-256
`8f175716ae1d4701645b704b75d11cc417c897d33e0c3064f469b5f67f7518e9`,
with the same source digest shown above; the Lean binary/source digests are
unchanged. Both pre/post artifact inventories were accepted by the release
runner. The focused B13 measurement used the earlier binary recorded above.
The subsequent full battery failed as described in the park record;
this Tier A result and focused B13 result do not establish close-out.
