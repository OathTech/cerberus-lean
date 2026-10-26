# Park: repaired transport reaches an existing libc Error — 2026-10-22

(This file is the strerror ACCEPTANCE-CRITERION PARK record of the transport repair,
the fourth of the slice's five park events. Header added at the pre-merge review, P3-1.)

Branch `feature/inner-arg-temps`, resumed from park `ebbfa2145`.
**Dispositioned, 2026-10-22:** the registered `strerror` Error is accepted
under complete-observation equality, while retaining its `BOTH_FAIL`
classification. The [completion record](2026-10-22_inner-arg-temps-completion-record.md#transport-park-resolution)
records the ruling and resumed validation. The historical park follows.

## Park disposition

[AGENT 2026-10-22, relayed by the operator] Resume with a fork Core-printer
repair for tray 65. Give `SD_FunArgValue` a parseable numbered spelling,
regenerate the variant dump and quotation pin, and require all 42 switched
libc execution rows to agree before removing the blanket containment.
Normal Core output and its libc pin must remain unchanged. Check every
imported libc dump for body binders that reuse a procedure parameter name.
Compare the seven previously failing/resource-bound rows with Normal at
the same limits. Finish I3/I4 and the full battery; I1b remains deferred.
No diagnostic-text difference may be silently adopted as a baseline.

[AGENT 2026-10-22, relayed by the operator] Use `name_fav<number>` and
reject collisions with bare source names in the printer while constructing
each procedure document. Check both insertion orders. Keep the loader's
parameter-rebinding check independent, accepting its conservative refusal
of shadowing. Do not add general scope analysis. Queue a transport using
unique numbers for every named symbol, or a structured library format,
as separate work because it changes Normal output and metadata joins.

The earlier I2 checks established a faithful quotation of a corrupted
parse. They were not transport evidence. The
[second park](2026-10-21_inner-arg-temps-libc-park.md) preserves that finding;
the earlier recursive-main disposition remains in force.

## Repair and boundaries

`pp_symbol.to_string_pretty` now prints a function-argument value as its
C name plus `_fav` and its numeric symbol ID. `pp_core` scopes a pair of
name sets to each procedure's document construction. Inserting either a
bare `SD_Id`/`SD_ObjectAddress` spelling or an argument spelling checks the
other set; a collision calls `Cerb_debug.error` with the procedure and
name. The scope is restored even on an exception. Other printer entry
points have no such active context. The Lean diagnostic/signature printers
mirror the new spelling.

The loader traverses the parsed procedure body before metadata stitching,
checking patterns, pure expressions, actions and saved-continuation binders
against its formal parameter names. The refusal retains
`R-IAT-LIBC-SYMBOL-LOSS`, names the procedure and binder, and applies in
Normal mode too. The traversal is a frontend speedbump, not a proof that
the text represents the original library. It does not perform scope or
liveness analysis; printed names must distinguish symbols live together
within a procedure. A scoped source program can therefore be conservatively
refused when a printed body binder reuses a Core parameter name.

Five focused parser checks exercise separate value/address names, the
original conflation, a nested Normal-mode case binder, a saved continuation
binder, and independence between procedures. The parser executable passes
297 checks. Existing deprecation/unused warnings in the touched CoreParser
file were removed using the replacement APIs, without suppressions.

## Normal output and pins

Before and after the printer change, each source was printed from the
repository root with the canonical runtime and `--pp=core --pp_core_out=...`.
The 42 `tests/libc_exec/**/*.c` and ten `tests/fixtures/*/source.c` outputs
are byte-identical. These aggregate SHA-256 values hash sorted lines
`<row-name> <file-sha256>\n`, with row names `libc/<relative-C-path>` or
`fixtures/<fixture-directory>`:

| Capture | Before and after SHA-256 |
|---|---|
| 42 libc program Core outputs | `70b185aceb87b9a61d5a4a76cce542f3752fc4629b6430bdd3679b1372edaab5` |
| 10 fixture Core outputs | `974fac545aefe3e012d31c76b617751484c3f34efd662209127f7c3b3186581d` |
| Normal libc dump | `d93b99cd55dae4b23071262a24d235c69489c8e41011554194126ecc81555a0a` |

Both libc dumps regenerate without the collision diagnostic. The variant
dump pin becomes
`56986871ff4cf05959213c5c20936b0914d14bd925b5bf7223cce25be72536ac`.
The longer argument names also change line wrapping. Normal's dump/pin
remain untouched. The three printer files were previously identical to
the upstream base, so the manifest gains three `[files]` and
`[source-content]` rows, with a dated note; no generated-model delta changes.

An intentional C printer plant uses a parameter `x` and a local named
after that parameter's measured argument-value spelling. Under the switch
it stops with exit 125 and `Core printer symbol collision in procedure f:
x_fav444`; the same C source prints successfully in Normal mode. The
positive switched control uses `x_fav0` and succeeds before that mutation.
This is a planted printer collision, not a differential execution finding.

## Candidate validation

The production CLI's blanket containment remains while an explicitly
labelled scratch candidate validates the repaired transport. Its source
differs only by removal of that blanket CLI branch; the loader detector,
all dependencies and native objects are the production candidate's.
It is compiled with the package's complete module setup and linked with
the production response file, substituting only the Main object.
No baseline is accepted from the scratch driver.

Command (repository root after the documented build; scratch driver described
above, not the production executable):

```sh
python3 scripts/inner_arg_temps_lane.py \
  --oracle "$PWD/_build/default/backend/driver/main.exe" \
  --lean "$PWD/.tmp/inner-arg-temps-repair/candidate/cerberus-lean" \
  --out "$PWD/.tmp/inner-arg-temps-repair/candidate-libc" \
  --observe --rows '^libc/'
```

The measured result (103.53 s) is:

```text
SUMMARY: inner_arg_temps rows=42 AGREE=2 AGREE-FIRST=39 BOTH_FAIL=1 failures=0
```

The instrument returned 0 because an observation run can report a
`BOTH_FAIL` without adopting it. That is **not** the transport acceptance
gate: the disposition requires 42 AGREE/AGREE-FIRST rows and all 36 old
DIFF rows to become agreement. That criterion fails. No discrepancy has
been hidden by the zero observation-run status.

The one non-agreement row is `tests/libc_exec/039-strerror-assert.c`.
`runtime/libc/src/string.c:347-351` implements `strerror` with an unconditional
assert. The test's source comment already describes that behavior. On
both engines in both modes, the complete observation is exactly:

```text
Error {msg: "assert() failure"}
```

Each engine exits 1. The new lane correctly calls equal Error/Error
`BOTH_FAIL`, not agreement. Its Normal controls match the switched
observations exactly, including their texts. This behavior is already
registered as `039-strerror-assert MATCH` in
`tests/libc_exec/baseline.txt:38`: the older libc lane's MATCH means equal
complete tokens and includes Errors. The distinction is explicit in the
[2026-09-28 test record](2026-09-28_thin-surface-tests-record.md), libc
breadth and O13, which describe both engines stopping at the assert.
No existing baseline changes. The original transport corruption prevented
this row from reaching the shared Error; the repair exposes it faithfully.
Thus 35 of the former 36 DIFF rows become agreement and the remaining row
becomes this existing failure. All 42 pairs now have equal observations,
but only 41 are agreement under the new lane's definition.

[AGENT 2026-10-22] Park on the falsified all-42-agreement premise, as the
charter requires. Keep the production blanket refusal and the per-dump
binder detector; do not relabel the Error, implement `strerror`, lift
containment, adopt an I3 baseline, or claim completion. The next disposition
must settle whether this registered Normal-mode failure is an accepted
`BOTH_FAIL` row for the transport acceptance criterion.

Focused transport plants also passed: a hand-corrupted body binder in each
of the two dumps is refused by procedure and parameter name; a C local
with the measured argument-value spelling is refused by the switched
printer, while its positive switched and Normal controls print. They run
through `Runner.transport_plants()` and are included in the still-provisional
lane's `--selftest`. The whole selftest awaits its baseline and is not claimed
as validated.

## Outstanding at park

The repaired variant dump is committed with its content pin, but its
quotation pin remains the old value: production quotation is still
contained. B13 consequently remains red by containment. No new release row
or baseline is adopted. The full I3 sweep, complete `--selftest`, Csmith
round, production transport validation/containment lift, quotation round
trips and full close-out battery remain outstanding. Tray 66's requested
main-comment report is drafted from the already measured main witness;
I4 delivery/consumer readiness is not claimed. I1b remains deferred.

## Earlier failure/resource controls

The five minimal rows also fail in Normal mode on both engines, with the
same failure class and payload apart from the already permitted symbol
numbers in Errors. They are the existing `CERB_SKIP` rows in
`scripts/exec_baseline.txt`: 073/074 (unknown exit/abort procedure without
libc), 097 (null-pointer shift TODO), 112/113 (allocator exhaustion).
The first control pass used an overly strict cross-mode full-text equality
for Errors and failed 073/074: the oracle prints Symbol IDs 549/543 in
Normal and 468/462 under the switch. This is the existing failure-class
numbering exception (tray 17), not a new `_fav` text change. The instrument
was corrected to use that same narrow projection for the Normal failure
classification, while retaining separate hashes of **all full tokens** in
each mode. Focused reruns of 073/074 pass; the other three passed the
original strict comparison. There is no second full seven-row pass claim.
No error text is rewritten and a change beyond the numeric Symbol field
still fails the comparison.

Both `p07_list_sum` and `p08_list_reverse` hit the 4G cap (exit 137) on
both engines in both modes, with the same 30-second timeout. Neither is a
switch-only failure or agreement. Their earlier switched RESOURCE rows
are in the second park record. Their Normal corpus registration is
`tests/corpus/p07_list_sum.core.sha256` and
`tests/corpus/p08_list_reverse.core.sha256`, reached by
`scripts/test_verify.sh`'s `CORPUS_HASHED` list. That existing lane checks
Core dumps and explicitly does not execute these large-arena programs;
it is not a pre-existing Normal RESOURCE execution baseline. This focused
measurement supplies that missing Normal classification without changing
any baseline.

## Park checkpoint checks

The final capped build passed (407 jobs). The package-directory parser run
and Tier A's parser executable both report `Done: 297 passed, 0 failed`,
including the libc checks. The production execution and standalone quotation
containment probes each return exit 2 with `R-IAT-LIBC-SYMBOL-LOSS`, empty
stdout and no quotation file. The blanket message now describes the unmet
acceptance criterion rather than claiming the repaired dump still conflates
argument values. The per-dump detector's named refusal is unchanged.

Tier A passed all 19 existing commands, exit 0, after launch load 3.28
at 02:06 UTC. Both driver freshness checks passed before launch. Command:

```sh
CERB_MEM_MAX=32G SKIP_BUILD=1 python3 scripts/release.py --mode fast \
  --out .tmp/inner-arg-temps-repair/tier-a
```

Verbatim conclusion:

```text
PASSED A14.2 (165.7s)
fast: passed; 19/19 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

Summed command time was 1399.0 s. The four execution baselines each report
zero regressions and zero improvements. Normal libc remains 42 MATCH,
multi-TU remains 8 and 7 MATCH, and CN retains 213 exact entries (207 MATCH,
6 UB_MATCH). A9 retains 108 SAME and its five registered DIFF rows. PNVI
retains all 164 exact rows/hashes: 152 AGREE, 3 AGREE-FIRST, 2 BOTH_FAIL,
7 REFUSAL. No existing baseline or generated-model delta moved. The new
printer source-content pins passed the fork-drift check. No proof module
changed; no additional kernel replay is claimed or required by this charter.
The full battery is not run at this park; B13 is still blocked by containment.

Only this gate-result text, a direct blocker reproduction command, and the
LADDER parser-count caption were finalized after the unchanged-source run.
Raw captures, scratch binaries and gate evidence are ephemeral and removed
before the park commit; the source, conclusions, hashes and reproducing
commands remain in git.

The acceptance conflict can be checked without a scratch Lean executable:

```sh
CERB_MEM_MAX=4G ./scripts/capped _build/default/backend/driver/main.exe \
  --runtime=_build/install/default --switches=inner_arg_temps \
  --exec --batch tests/libc_exec/039-strerror-assert.c
```

It returns the Error above, exit 1; removing the switch produces the same
Error. The runtime source and the existing Normal baseline independently
show why this cannot count as a successful execution agreement row.
