# inner_arg_temps: Normal diagnostic difference — 2026-10-23

Branch `feature/inner-arg-temps`, tested commit
`a74922afef98e88dcba903f3953c65f9a31d82c0`. **PARKED; close-out failed.**

[AGENT 2026-10-23] Park under the charter's rule for baseline movement
outside the new lane. Full-battery B10.1 found one unregistered Normal
diagnostic difference. Preserve the comparison and register unchanged;
await disposition before further branch work. This record diagnoses the
difference, not a new accepted exception.

## Finding and relevance

Row `immaculate/nolibc/zd-z2fl03-nan-to-int`, from
`tests/immaculate/nolibc/zd-z2fl03-nan-to-int.c`, computes NaN and converts
it to `int`. Both pristine and fork OCaml engines, in Normal mode with
`--exec --batch --nolibc`, exit 125 with empty stdout and uncaught
`Z.Overflow`. Neither produces a completed semantic observation.
The fork backtrace contains two additional `Core_eval.step_eval_pexpr`
frames (one is its anonymous function).

`scripts/test_upstream_oracle.py:204` removes the elapsed-time trailer and
normalizes positions in OCaml frames and exception headers. It retains
function/file names and frame order/count. Consequently this pair is
`difference`, not `matching_failure`. Treating it as agreement would
change the existing contract. The new lane's cross-mode set comparison
does not apply to this independent, Normal-only oracle comparison.

The cause is I0b (`08fb2d156`), the approved backport of upstream
`3230aa494`. In `runtime/libcore/std.core:81`, `loaded_ivfromfloat` now
tests for `_Bool` before evaluating `Ivfromfloat`. On a non-Bool target,
the same failing conversion therefore executes inside an extra conditional.
This explains the additional evaluator frames. A controlled substitution
confirmed the cause: with the same production fork binary, replacing only
`std.core` in an isolated runtime copy with its pre-I0b contents restores
the pristine diagnostic signature exactly. The production runtime was
untouched. Verbatim control results:

```text
current exit 125 stdout bytes 0 projected stderr SHA256 0f7a88b72c6adbaacff27c501d8cacafd29e1b8bde570b761334b4f3a78b5637
pre-i0b-std exit 125 stdout bytes 0 projected stderr SHA256 a8aed81ebd2694a31719159a618fecf63fe023bc4d22fec1b7e4d661dcd959c3
CONTROL CONFIRMED: changing only std.core restores the pristine diagnostic signature.
```

The NaN-to-integer failure predates this slice. The non-finite conversion
TODO remains in `std.core:80`, and the final remedy paragraph of
[tray 15](upstream-tray/15-bool-float-conversion-truncation.md) already
distinguishes wider-integer conversion from its fixed `_Bool` case.
No new program result or new upstream defect is established here. The
verification consequence is a diagnostic change absent from the register,
now causally identified; no semantic repair is attempted.

## Full-battery result

Reproduction command, after the documented build and with the independent
oracle provisioned:

```sh
CERB_MEM_MAX=32G DUNE_CACHE=disabled SKIP_BUILD=1 ./scripts/capped \
  python3 scripts/release.py --mode full --lane-timeout 3600 \
  --out .tmp/inner-arg-temps-closeout/full
```

Run started at 06:37:15 UTC and ended at 08:41:51 UTC on 2026-10-23.
The load average was below 6 at dispatch. B10.1 failed after 998 rows;
its scope summary is verbatim:

```text
Independent oracle scope: tier-b; 998 rows in 188.4s; source unchanged: True
```

Derived from its report: 951 semantic agreements, 36 matching failures,
8 reviewed differences, 2 interface agreements and this one difference.
After identifying the failed row, the worker stopped the owned release
runner by PID. Its interrupt handler stopped the active B12 command.
All dispatched command groups were cleaned up. B13 was not dispatched.
The runner exited 1; its final summary is verbatim:

```text
full: incomplete; 41/44 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

Thus the full battery is a failed close-out gate, despite 41 successful
commands. B10.1 failed, B12 is incomplete, and B13 remains unrun in this
battery. No per-command 3600-second tripwire fired. Derived command time
totals 7474.218 seconds; the longest command was B9 at 2299.846 seconds.
There were no artifact-inventory issues or source changes during the run.

The full run's A15 population and baseline summaries are verbatim:

```text
SUMMARY: inner_arg_temps rows=186 AGREE=137 AGREE-FIRST=41 BOTH_FAIL=6 RESOURCE oracle:KILL=2 failures=0
BASELINE OK (inner_arg_temps: 186 rows; classes and both distinct-observation/status hashes exact)
```

B7's baseline check and B9's instrument checks also passed, respectively:

```text
Baseline check: 0 regression(s), 0 improvement(s)
observation lane plants: 93/93 passed
```

The [I3 record](2026-10-23_inner-arg-temps-closeout-record.md) retains the
earlier Tier A 20/20 result, focused B13's four round trips and four kernel
replays, and the failed 32-seed measurement with all 26 frontend failures
classified. Those results do not substitute for a passing full battery.

## Identities and focused reproduction

| Artifact | SHA-256 |
|---|---|
| Fork binary used by the full run and control | `904eeb5152d03cf4ee2dc500aad210e87c698b4b755a9d1504bdbc2d5c1c581f` |
| Independent-oracle foundation manifest | `a5e3d0f218c17ef831535ded780f0069f3596d25d1d3b648a33c0732065d44ca` |
| Unchanged difference register | `c6bd45748011352ac8810cbb43d9446fff5a2de27962e50a1818a968166c8f98` |

The routine full-run rebuild changes the binary hash from the earlier
focused/Tier A captures; the oracle source digest remains
`b2b02eea39caad4158e45356e3fdd2696c37827ad7771f835891adfaf2ecb293`.
The Lean binary/source identities remain those in the I3 record.

The following reproduces only the finding, not the full gate:

```sh
CERB_MEM_MAX=32G ./scripts/capped python3 scripts/test_upstream_oracle.py \
  --only '^immaculate/nolibc/zd-z2fl03-nan-to-int$' \
  --out .tmp/iat-nan-diagnostic
```

For the causal control, copy the staged runtime tree (following symlinks)
to a fresh scratch prefix containing `lib/cerberus-lib/runtime`. Run the
production fork binary twice with `--runtime=<scratch-prefix> --exec
--batch --nolibc tests/immaculate/nolibc/zd-z2fl03-nan-to-int.c`, each
under `CERB_MEM_MAX=4G ./scripts/capped`. Use the current `std.core` first,
then replace only the scratch `runtime/libcore/std.core` with
`git show 08fb2d156^:runtime/libcore/std.core`. A copied Dune file may be
read-only; recreate that scratch file before writing. Apply
`project_diagnostics` from `scripts/test_upstream_oracle.py` to each stderr
and hash the resulting bytes. Expected statuses and hashes are above.

## Disposition needed

A narrowly scoped `diagnostic-text` register entry could account for this
specific pair of signatures and cite the approved I0b backport, while
retaining the exact frame comparison elsewhere. That is a proposed
disposition, not an adopted baseline. No register row, diagnostic
projection, semantic code or existing baseline changes in this park.
The repaired transport stays enabled with its per-dump refusals; this
finding does not invalidate its matched-mode execution evidence.

I4 close-out, a passing full battery and the quotation-hygiene follow-up
remain unfinished. Raw captures and the isolated control runtime are
ephemeral and are removed after recording these conclusions. No push.
