# Capture composition and native diagnostic separation

2026-09-06 [AGENT], within validation-foundations G1/G4. The first complete
Tier A+B attempt ran all 32 commands with unchanged source and external
inputs: 28 passed and four failed. All 67 observation plants passed together;
the independent oracle passed its 723 rows and its unexpected-difference
plant. The four failures were instrument integration defects, not new
Cerberus/Lean value disagreements. No semantic baseline is being relaxed.

## Findings and repairs

1. **Reused capture prefixes.** The release runner supplied one observation
   directory per ladder command. A command such as the hang or fuel battery
   invokes the same child harness repeatedly. Both child runs wrote `1.oracle`
   in that shared directory, so the second hit the deliberate overwrite guard
   and returned 125 before reaching its planted Lean process. This broke the
   hang/fuel batteries and the kill battery's repeated CI leg. `common.sh` now
   treats the configured directory as a parent and creates a unique child
   directory per harness invocation. The overwrite guard remains unchanged.
   Native-observation plants find their captures recursively in this layout.
2. **Launcher stderr mistaken for program stderr.** Both native executions
   of `zd-d5-device-range-load.c` returned 139 with empty program output.
   `capped` emitted a signal diagnostic containing a different process ID
   each time. Comparing those diagnostics classified the known triaged native
   fault as nondeterminism and then correctly failed the stale-triage gate.
   Native program stderr now travels through inherited FD 8, duplicated onto
   stderr and closed before the native exec. Launcher diagnostics stay in the
   original capture stderr. Both streams, statuses, command and descriptor
   bindings are retained; determinism compares program bytes, and the OOM
   check still reads the actual launcher witness. No PID-normalizing filter
   is applied to either stream. The fixed argv/environment/exec path remains
   the native lane's existing recipe.
3. **Kill classification after decoding.** The new libxml2 and URI decoder
   calls rejected exit 137 before the existing cap/signal checks could name
   it. Those status checks now run first. They still fail the lane, while
   retaining the intended OOM/SIGKILL attribution. Completed observations
   remain subject to the full decoder before any semantic comparison.

4. **Fuel text mistaken for exhaustion.** After directory isolation repaired
   the classification batteries, their literal-output control exposed the
   codec's substring search for `lem: fuel exhausted`. The codec now rejects
   complete typed-failure or diagnostic records. The same words inside
   escaped C stdout/stderr or an unrelated error message remain data. New
   codec probes cover those bytes and actual fuel records, including the
   litmus internal-failure policy, which must never admit exhaustion.

[The native regression probes](../../scripts/test_gcc_capture.sh) call the
actual `gcc_run` function on the device fault, stable binary stderr including
NUL/high bytes, and genuinely varying program stderr. All three pass in the
repaired development check: the first is consistently 139, the second keeps
its exact bytes, and the third remains nondeterministic. These probes now
ride the unit gate. The standalone prototype also retained its differing
launcher PID lines and separate native stderr as direct causal evidence.

Only the existing `scripts/common.sh` whole-file source-content pin changes
in the fork manifest: `58268e689bdc64de06896fd38c3025329fb2b2968c8b37405253f20afb68b163`
to `7823608431ba78206105e1ed0be614fe7ec9fa4717576f6c4d88226c30fb4e08`. The reviewed delta is the unique evidence-directory
allocation above; the source path set and all 22 generated-delta pins remain
unchanged. No reference-model or runtime semantic repair is included.

## Evidence and validation state

[The first full-run archive](validation-foundations-evidence/first-full-candidate.tar.gz)
contains the complete failed report, raw observations, exact pre-repair
source patch and native diagnostic prototype. Its checksum is in the
evidence directory's `SHA256SUMS`. It must not be substituted for a green
final-candidate run. The first run's GCC lane completed 1,963 rows with
1,873 agreements, 11 triaged rows and zero value disagreements; the native
diagnostic false positive caused the one regression/stale-triage failure.

Two prose counts were corrected against executable evidence: the full
ladder expands to 32 commands (13 + 19), and the GCC ledger has 1,963 rows.
The initial dispatch note inherited the stale 1,953 ledger count and
hand-counted 33 commands. The runner selected every documented command;
these were prose errors, not omitted executions. The finite measurement
ceilings and per-row limits did not change. All 67 observation plants took
about 750 seconds in this run; that is a measurement, not a runtime promise.

The complete repaired ladder remains required before final acceptance. The
legacy csmith campaign, customer checkout, shared pins and mainline branches
remain untouched.

The focused rerun passed hang and kill classification with unchanged source.
Fuel passed its actual exhaustion, summary, assertion and real-driver cases,
but its literal-output control revealed finding 4 above. That failed subset
report is retained at `.tmp/release-capture-repair-classification`; its result
is not a full-tier certification. The expanded codec now passes 13 methods.

The final focused fuel rerun passes, with source unchanged and the complete
literal-output control restored. The actual GCC nolibc subset passes on
29 inputs, including the device row at `TRIAGED_UB`; the eight targeted
GCC/URI observation plants and 14 fork plants pass. These are focused
evidence, not a replacement for the final complete ladder.

[The repair-development archive](validation-foundations-evidence/capture-repairs-development.tar.gz)
retains both focused classification reports, the failed literal-output
reproducer, native stream probes, repaired GCC subset raw captures, eight
observation plants and the fork-plant log. It complements the first failed
full-run archive; all original failures remain visible.

The repaired primary candidate subsequently passed all 13 Tier A commands
with source unchanged. The [fast-run archive](validation-foundations-evidence/capture-repair-fast.tar.gz)
retains all reports, raw observations and the tested source patch;
[its source manifest](validation-foundations-evidence/capture-repair-fast-source.json)
pins every changed script. Only evidence and result documentation follow
that run in this checkpoint. Full Tier A+B and affected reporting still
need their own final-candidate reports.

The matching private concurrency follow-up is committed at
`eb926f8d37187490c34a74bd4ffe74c80acdc77b`, with a clean worktree. All 14
Tier A commands, 30 litmus cases, 26 plants and the original four-case probe
pass. Its manifest pins the byte-identical codec/tests and the shared
capture-directory repair. No concurrency semantics changed.

## Final candidate confirmation

The repairs were committed as `1066d89ee`. Its complete Tier A+B run passes
32/32, including the actual GCC gate, all hang/kill/fuel checks and 67 plants;
C1/C4 and the cold provider recipes also complete. See the
[delivery record](2026-09-06_validation-foundations-delivery.md) for exact
reports, remaining findings and source/artifact identities. The failed and
focused development runs above remain historical evidence, not the final gate.
