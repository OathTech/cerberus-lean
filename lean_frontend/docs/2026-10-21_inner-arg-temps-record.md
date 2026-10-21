# The inner_arg_temps elaboration mode

Worktree branch: `feature/inner-arg-temps`. Starting implementation:
`e32c16709`; dispatch charter: `a8b20cbb6`.

Status: **PARKED after I2**, 2026-10-21. The recursive-main refusal premise
failed in the first I3 probes. See the [park record](2026-10-21_inner-arg-temps-park.md)
for the counterexample, active source path and reproduction commands.
The later rulings authorize the separate
[I0b backport](2026-10-21_inner-arg-temps-i0b-record.md), now validated by
complete Tier A and both-mode libc quotation checks, and defer approved
I1b work to quotation hygiene. They do not resolve that park condition.

## I0 — upstream PR 1020

[AGENT 2026-10-21, relayed by the operator] Adopt upstream
`f10329b44287ab79ed5017ff68431d5c5953ebd7` before enabling the Lean
driver's mode. The fork retains the defect; upstream's witness demonstrates
it. At this checkpoint, the separate floating-to-`_Bool` backport and I1b
awaited operator rulings; the later charter amendment resolves those items.

The shared `translation.lem` change is upstream's unmodified hunk. It factors
the Normal convention's argument conversion into a helper and uses that
helper for both conventions. Pointer arguments already converted to `_Bool`
are no longer sent through `loaded_ivfromfloat` under `inner_arg_temps`.
Both engines are generated from the same source. The upstream C witness,
expected output and test-list entry are adopted.

Before the patch, the freshly built fork oracle produced the following
outputs with
`_build/default/backend/driver/main.exe --runtime=_build/install/default --exec --batch tests/ci/0344-ptr-to-_Bool-param.c`,
adding `--switches=inner_arg_temps` for the second run. Timing trailers omitted.

Normal, exit 0:

```text
Defined {value: "Specified(0)", stdout: "0 0 1 1 1 9 1 0\n", stderr: "", blocked: "false"}
```

`inner_arg_temps`, exit 1:

```text
Error {msg: "ill-formed program: `PEctor: one of the operands was ill-typed ==> Civfromfloat('_Bool', 1) <====> ['_Bool'; 1]'"}
```

Fork-drift pins (single rows plus a dated NOTE):

- `frontend/model/translation.lem` content:
  `e99043b7e282fdaff5b2df2fa25ef5f5b116a8fe23796eacb617908cf7fa5a75`.
- `translation.ml` label-normalized generated delta against pristine upstream:
  `32d184cce426a27eb4efbd43a29816ca3a2f516b03fbf5452f5afc251dce328d`.

The regenerated fork oracle returns the upstream expected output in both
Normal and `inner_arg_temps` modes (exit 0 in each). The Normal libc dump
retains its content pin:
`d93b99cd55dae4b23071262a24d235c69489c8e41011554194126ecc81555a0a`.

The CI scoreboard gains only the adopted witness. Its exhaustive nolibc
run is `CERB_SKIP`: the oracle reaches the lane's 30-second CPU timeout.
This is not differential agreement. The single-file invocation of
`scripts/test_exec.sh tests/ci/0344-ptr-to-_Bool-param.c` failed (exit 1):

```text
[1/1] CERB_SKIP 0344-ptr-to-_Bool-param (Cerberus timeout: TIMEOUT(cpu 30.11s of 30.13s wall; timeout 30s))
SUMMARY: total=1 match=0 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=1 cerb_floor=0 cerb_inconsistent=0
FAILED: zero comparisons happened (all files skipped) — vacuous run
```

The eight call arguments in the upstream witness introduce many evaluation
orders. Its libc single-trace check is separate from this exhaustive
scoreboard entry. No existing scoreboard row changes.

The Normal Lean libc run (`--batch --first --runtime=_build/install/default
--libc tests/libc/libc.core`, with the twelve metadata TUs from
`scripts/libc_prep.sh --jsons` and the witness's exported Cabs JSON) also
returns the exact upstream expected line, exit 0. The switched Lean run
remains for I1/I2, which enable that driver configuration and its libc dump.

Focused checks:

```text
Build completed successfully (402 jobs).
check_fork_content: OK — 88 source files content/mode-pinned
check_fork_drift: OK — layer 1: 88 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 30 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 2d3a492758cb23dc4e417f2961983d25b36ce130 matches lem -v lean-backend-v0.1.0-alpha.1-65-g2d3a492 (hex prefix))
libc_prep: OK (content hash verified: pin + regenerated dump == d93b99cd55dae4b23071262a24d235c69489c8e41011554194126ecc81555a0a, 4188542 bytes)
```

Existing compiler warnings are visible in the builds. The generated-code
warning class is already tracked in `TODO.md` as a lem-backend follow-up;
the initial build also replayed handwritten deprecation/unused warnings.
No warning suppression or dependency change is introduced by I0.

Tier A: `CERB_MEM_MAX=32G python3 scripts/release.py --mode fast` completed
with exit 0. The launch was delayed until the measured one-minute load was
below 6 (4.68 at 01:54:01 UTC). Verbatim runner conclusion:

```text
PASSED A14.2 (180.6s)
fast: passed; 19/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

The minimal, coverage, debug and float baseline checks each report
`0 regression(s), 0 improvement(s)`. The Normal libc lane reports
`SUMMARY: match=42 diff=0` and `ALL MATCH RECORDED BASELINE`; URI is unchanged
at 16/16 and CN at 213 entries. A9 remains at its recorded
`SUMMARY: total=113 same=108 diff=5 ocaml_fail=0 lean_fail=0` (the same five
signature differences documented in the PNVI S4 record). The PNVI lane's
baseline check passes. No existing baseline row moved.

I0 is green at its required checkpoint boundary. This is Tier A evidence,
not the slice's full close-out battery. No proof module was edited, so the
charter does not require a separate kernel replay for I0.

## I1 — switch acceptance, configuration and reports

[AGENT 2026-10-21] Put the two pure configuration selectors in
`CerbDriverConfig.lean`, used by the production driver and its kernel pins.
The runtime existence check and actual std load use the same filename
selector (`pipeline.ml:34`); `frontendTU` uses the calling-convention selector
(`pipeline.ml:271`). The reader parameter is unchanged.

`judgeSwitches` accepts exactly `inner_arg_temps` as a second non-default
whole set, in both CLI spellings. Mixed sets, duplicates and unknown names
remain refusals. `--call` under this switch is refused with exit 2 before
reading input: `CerbCall`'s injected call site is Normal-only.

[AGENT 2026-10-21] Report the complete set on stderr after execution returns.
This preserves the strict batch stdout grammar and leaves an aborting
panic's diagnostic envelope intact. Quotation commands remain silent and
write the same fixed-prefix report as a Lean comment after the import:

```text
cerberus-lean switches: []
cerberus-lean switches: [PNVI_ae_udi]
cerberus-lean switches: [inner_arg_temps]
-- cerberus-lean switches: [inner_arg_temps]
```

Only the last line above is a quotation-header example. No run report is
printed when a process aborts or is refused before execution. The API
`CerbQuote.moduleSource` takes the complete switch list explicitly; it does
not infer provenance from a calling convention that cannot distinguish
Normal from PNVI.

`OpaqueFailureTest` pins the positive `has_switch` result and the production
calling-convention/std selectors at the default and inner sets by `rfl`,
plus a Normal-convention PNVI control and the report strings. These are
test-executable pins; no proof module was changed.

The codec plant verifies unchanged full tokens for Defined, Undefined,
Error and multi-execution records with each report on stderr, and rejects
the report on stdout. The existing positive controls in
`test_observation_lanes.py` now plant that stderr report at each lane entry
point; their full run belongs to the close-out battery. Focused exec plants:

```text
observation lane plants: 9/9 passed
```

Two CLI speedbumps previously merged stdout and stderr before comparing
verdicts. Their captures are now separate: they compare exactly the same
stdout bytes and check the switch diagnostic independently. The served
library-location divergence pin remains unchanged; I1b is still pending.

Focused validation: the capped build passed (536 jobs), the kernel-pin
executable passed, CLI refusal/acceptance witnesses and all 23 runtime
witnesses passed, the observation codec passed all 26 tests, and the
default fixture quotation completed its independent whole-file round trip.
Direct default, PNVI and inner quotations are silent and carry their exact
header. Exec purity and fork drift pass. The OCaml build was also run with
`DUNE_CACHE=disabled` and `--force` after adding the Lean library root.
The touched Main file's existing unused bindings and deprecated string
spellings were cleaned up without suppressions; it now builds without its
previous warnings.

The Normal libc quotation pin becomes
`992646e25801b13b66ea9bfa915dda1f788a72a19b5951904d36f88a9a83b279`.
Removing exactly the new header line reproduces its previous SHA-256,
`30bdb3f5db037b5a63a3deaa24cba27f289bd7841770d1e1ebff43699dcbfe06`:
the literal body is byte-identical. This is the requested header addition,
not a semantic or verdict baseline change.

The first I1 Tier A attempt failed A1 and A7. The UTF-8 Cabs check merged
stderr into its exact stdout comparison; the batch-diagnostic check required
empty stderr after a libc-parser failure. Inspection found the same merged
capture in the assembly-refusal check. These instruments now keep verdict
stdout separate and check the fixed report on stderr. No verdict projection,
expected semantic token or baseline row is changed. The source was corrected
while the already-red runner completed its remaining lanes, so that attempt
cannot certify an unchanged candidate.

Focused reruns of the affected checks passed, including their original plants:

```text
check_cabs_json_utf8: selftest plant 'uncaught' caught: 9 failing witness(es)
check_cabs_json_utf8: selftest plant 'refuse-all' caught: 9 failing witness(es)
check_asm_refusal: selftest plant 'erase' caught: 18 failing witness(es) (= expected 18)
check_asm_refusal: selftest plant 'lean-erase' caught: 10 failing witness(es) (= expected 10; incl. the required witnesses)
check_asm_refusal: selftest plant 'refuse-all' caught: 16 failing witness(es) (= expected 16; incl. the required witnesses)
batch diagnostic producers: 8/8 passed
```

The final complete I1 Tier A result follows the attempt diagnostics below.

The failed attempt finished with exit 1:

```text
fast: failed; 17/19 selected commands completed successfully.
Source unchanged: False. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

Its differential lanes reported unchanged baselines: minimal 113, coverage
279, debug 90, floats 93, libc 42, CN 213 and PNVI 164. A9 retained the same
five already-recorded signature differences. These observations diagnose the
report-channel integration; they do not turn the failed attempt into a pass.

The second attempt passed the repaired UTF-8 and assembly checks but failed
A1's final translation-fuel check: four successful controls still required an
empty stderr file. Their verdicts were unchanged, and the low-fuel cases all
aborted with the expected fuel classification. The controls now require the
exact default switch report on stderr. A search of the remaining shell and
Python stderr assertions found no further empty-stderr requirement on a
completed `cerberus-lean` run. The focused invocation
`SKIP_BUILD=1 CERB_MEM_MAX=32G bash scripts/test_translation_fuel.sh` passed:

```text
translation-fuel: PASS (two dead-code witnesses, constant-expression refusal in batch and pp-core, five successful controls)
```

The second attempt finished with exit 1, with A1 its only failed row and all
differential baselines unchanged. Its source changed when that last assertion
was repaired, so it is not checkpoint certification:

```text
fast: failed; 18/19 selected commands completed successfully.
Source unchanged: False. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

The third attempt passed all 19 commands but was incomplete. An independent
`csmith --version` prerequisite probe unexpectedly wrote `platform.info` in
the repository root (the Csmith 2.3.0 file contained integer and pointer
sizes). The runner detected that new untracked artifact. Its before/after
tracked diff hashes were identical, as was `CerbDriverConfig.lean`, the only
pre-existing untracked source. The generated artifact was removed.
[AGENT 2026-10-21] Run Csmith invocations in disposable scratch directories
to contain its startup artifacts. The complete tier was rerun without
intervening probes.

```text
fast: incomplete; 19/19 selected commands completed successfully.
Source unchanged: False. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

Final I1 checkpoint: `DUNE_CACHE=disabled CERB_MEM_MAX=32G python3
scripts/release.py --mode fast` exited 0:

```text
PASSED A14.2 (182.3s)
fast: passed; 19/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

Minimal, coverage, debug and float baselines each report zero regressions and
zero improvements. Normal libc retains all 42 rows; multi-TU retains 8 and
7 rows; CN retains all 213; PNVI retains all 164 classes and hashes. A9 remains
at 108 SAME / 5 DIFF, the previously recorded five signature differences.
No existing baseline moved. This is the green I1 boundary; variant-libc
pairing and the new differential lane are the next checkpoints.

## I2 — paired libc inputs and quotations

`libc_prep.sh --record` records both convention variants; `--check` verifies
both committed texts against their content hashes and regenerated oracle
dumps, then verifies the actual lane-loaded staged objects against their
build-tree counterparts. `--jsons` performs the same checks and exports one
shared set of twelve parse-only Cabs TUs. The metadata export convention is
unchanged. The staged objects are in package `cerberus`, as selected by
`backend/driver/main.ml:54-77`; the std variants are in `cerberus-lib`.

Content pins:

- Normal dump, unchanged: `d93b99cd55dae4b23071262a24d235c69489c8e41011554194126ecc81555a0a`
  (4,188,542 bytes).
- `libc_inner_arg_temps.core`: `564da8b27b56fb56e70ebc1a71a2c686beb0c63be01ed5f5216b2bd4867a2240`
  (4,038,187 bytes).
- Normal quotation, unchanged from I1:
  `992646e25801b13b66ea9bfa915dda1f788a72a19b5951904d36f88a9a83b279`.
- Switched quotation (`core-quote-libc-inner-arg-temps.sha256`):
  `ab7cb26e7e38987d871e956d1db05d66f06f58311ca0b776407c81eb47d4bee0`.

[AGENT 2026-10-21] Recover the dump's lost convention from all fixed
procedure parameters before the stitch: raw `pointer` for Normal and
`loaded T` for Inner_arg, matching `translation.lem:4335-4340`. Definitions
may have the model's final variadic carrier `[(ctype,pointer)]`, shared by
both modes (`translation.lem:4476-4491`); it is not a fixed parameter.
Declarations have only fixed parameters. A dump without any fixed procedure
parameter is refused because its convention cannot be established. The
comparison uses the linked metadata's actual `calling_convention0`; it
cannot overwrite that tag onto bodies from the other mode. This supplies
the missing input distinction checked by the oracle's
`IncompatibleCallingConvention` at `core_linking.lem:286-287`.

Both mismatched pairs were tested against the built driver: Normal dump
with the switch, and variant dump without it. In `--batch` and
`--quote-libc`, each exits 2, names `IncompatibleCallingConvention` on
stderr, emits no verdict stdout and writes no quotation. Both matched pairs
run fixture 001 to exactly `Specified(42)`. The switched upstream pointer
conversion witness now runs on both engines in libc single-trace mode:

```text
Defined {value: "Specified(0)", stdout: "0 0 1 1 1 9 1 0\n", stderr: "", blocked: "false"}
```

The quotation test now accepts `--switches=inner_arg_temps`, checks the exact
header, rebuilds its expected value under that explicit switch set and loads
the matching std and libc inputs. Tier B row 13 runs Normal and Inner_arg
standalone and linked quotations, with distinct pins. The release inventory
also requires the two staged variant artifacts.

Focused command: `CERB_MEM_MAX=32G ./scripts/capped scripts/test_unit.sh
--core-quote-libc`, exit 0. Both modes passed standalone and fixture-001-linked
whole-file comparison, comparator-term checks, constructor census, exact
header, canonical alias determinism and wrong-cwd refusal. Both standalone
hashes matched their pins. All four literal environments passed
`lake env leanchecker` (exit 0). No proof module changed.

| Mode / literal | Elaboration wall seconds | Peak RSS, KB | Replay seconds |
|---|---:|---:|---:|
| Normal / standalone | 132.40 | 14,882,132 | 1.91 |
| Normal / linked | 147.37 | 14,887,076 | 1.97 |
| Inner_arg / standalone | 172.24 | 14,260,564 | 1.91 |
| Inner_arg / linked | 136.95 | 14,268,888 | 1.83 |

The four quote/elaborate/compare round trips total 621.50 seconds; replay
and invocation controls are additional. These are cost measurements, not
limits. The two censuses each found 56 floating literals, zero NaNs, zero
memory values and zero absolute position paths.

```text
Core quote round trip: PASS (whole-file representation, comparator syntax, auxiliary BEq)
✓ core-quote-test PASSED
Core quote round trip: PASS (whole-file representation, comparator syntax, auxiliary BEq)
✓ core-quote-test (inner_arg_temps) PASSED
Total: 2 passed, 0 failed
```

The dump-level float census also found the same multiset of 24 literals in
both variants. N3 remains: the switched dump contains the existing lossy
`1.84467440737e+19` at line 59507. No float literal was added or changed.

I2 checkpoint: `DUNE_CACHE=disabled CERB_MEM_MAX=32G python3
scripts/release.py --mode fast`, exit 0:

```text
PASSED A14.2 (171.7s)
fast: passed; 19/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

The four exec baselines each report zero regressions and zero improvements.
Normal libc remains 42 MATCH; multi-TU remains 8 and 7 MATCH; CN remains
207 MATCH plus 6 UB_MATCH. A9 remains 108 SAME / 5 known DIFF. PNVI retains
all 164 rows, classes and hashes (152 AGREE, 3 AGREE-FIRST, 2 BOTH_FAIL,
7 REFUSAL). No existing baseline moved. This is the green I2 boundary.

## I3 — stopped at the premise check

The new main-with-arguments witness returns `Specified(0)` on both engines
in both modes with `--args "ab cd"`. The switched oracle's Core has
`proc main (argc: loaded integer, argv: loaded pointer)`, confirming that
the mode applies to main despite the translation comment.

The bounded recursive-main witness instead returns `Specified(7)` on both
engines in both modes. It does not reach the charter's expected refusal.
The active reduction path bypasses the cited guard. No lane, refusal
baseline, selftest or fuzzing round was added; I4 and the close-out battery
were not started. I1b and `3230aa494` remain pending. The park record gives
the evidence and the scope decision needed before resumption.
