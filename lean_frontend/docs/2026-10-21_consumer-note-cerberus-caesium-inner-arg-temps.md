# inner_arg_temps consumer note — updated 2026-10-23

Current delivery status: **parked, not closed out**. I3 passed Tier A at
`a74922afe`. The full battery found a Normal-mode backtrace change from
the floating-to-`_Bool` backport: an existing NaN-to-integer failure gains
two evaluator frames. The independent-oracle comparison correctly reports
that difference. See the [park record](2026-10-23_inner-arg-temps-oracle-park.md);
the comparison rules and existing baselines remain unchanged.

Use `--switches=inner_arg_temps` as the whole switch set. The driver selects
`std_inner_arg_temps.core` and callee-allocated argument temporaries,
including for main. Execution and quotation use
`tests/libc/libc_inner_arg_temps.core` and the twelve shared parse-only
metadata TUs from `scripts/libc_prep.sh --jsons OUTDIR`. `--call` under the
switch, mixed switch sets and `--iso` remain refused. The default stays
Normal. The [completion record](2026-10-23_inner-arg-temps-closeout-record.md)
tracks validation; this note does not claim downstream testing.

Completed runs report `cerberus-lean switches: [inner_arg_temps]` on stderr;
quotations carry `-- cerberus-lean switches: [inner_arg_temps]`. Normal
reports `[]`. These reports change no compared verdict token. The repaired
variant dump SHA-256 is
`56986871ff4cf05959213c5c20936b0914d14bd925b5bf7223cce25be72536ac`.
The repaired quotation SHA-256 is
`6f2514217b637cedd4109b7c9698942a63b07e59f126ef257cabcf1fe10db0ca`;
replay results are tracked in the completion record.

Correction to the earlier cross-mode guidance: exact complete observation
sequences are required between engines within a mode. Across conventions,
the oracle-only sanity check compares SETS of distinct complete observations
(value, stdout, stderr, blocked), ignoring order and multiplicity. Normal's
caller creates/stores an object per argument in unsequenced steps, adding
exhaustive interleavings; inner_arg_temps allocates in the callee after the
call. `libc/exhaustive/001-unseq-order-libc` has two distinct outcomes with
80 Normal observations and 4 switched observations, engines agreeing within
each mode. These counts are informational, not pinned. A distinct-outcome
difference remains a finding. The completion record attributes the corrected
premise to the orchestrator's 2026-10-23 disposition.

The printer distinguishes loaded parameter values from object addresses
and rejects spelling collisions. The loader independently rejects body
binders that rebind parameter names in every dump, including Normal and
quotation, with `R-IAT-LIBC-SYMBOL-LOSS`. Dump/mode mismatch also refuses.
Legal block-local shadowing can be over-refused; these checks are regression
speedbumps, not a proof of general text-transport soundness. Normal Core
output is unchanged. I2's original green was a faithful quotation of a
corrupted parse, not transport evidence. See
[VALIDATION](../VALIDATION.md#core-text-parameter-identity-speedbumps-inner_arg_temps-repair).

Correction to the earlier recursive-main guidance: upstream's guard is
dead on the active driver path. Eccall reduction invokes Core_run.call_proc
directly, so recursion into main executes. Bounded witnesses with and
without argc/argv pass on both engines in both modes: 42 and 7 respectively,
also their GCC results. No recursive-main refusal is introduced. The
argument witness checks nested callee allocation and preservation of the
outer frame. This does not claim arbitrary recursive programs terminate.

Tier A row 15 runs the matched-mode lane and selftest. The registered
strerror assert is BOTH_FAIL (Normal baseline row 039 calls equal complete
Error tokens MATCH); it never counts as execution agreement. Fuzzing uses
exact switched-engine sequences and the same oracle cross-mode set rule.
The 32-seed Csmith measurement completed six comparisons and reported 26
frontend failures, all also present in Normal mode; the record classifies
every failed seed. It is not an all-green fuzz campaign.
Tray [64](upstream-tray/64-recursive-main-guard-bypassed.md) reports the dead
guard, [65](upstream-tray/65-inner-arg-temps-core-symbol-loss.md) the transport
loss and fork remedy, and [66](upstream-tray/66-main-inner-arg-temps-comment.md)
the translation.lem:4331 main-exclusion comment. None has been submitted.
Quotation hygiene (I1b) remains approved and deferred to its follow-up slice.
