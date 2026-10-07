# `--switches`: an unknown or a conflicting switch name is ignored with a stderr note and the run proceeds, so a typo silently runs a different memory model

**Affected:** `ocaml_frontend/switches.ml` `set` (upstream `b9aeedcb4` `:133-142`): an unknown name
prints `failed to parse switch '…' --> ignoring.` (`:141`); a second name of a class already in the
list (the `pred` classes `:104-132`: the three PNVI variants, the two pointer-arithmetic modes, the
two revocation modes) prints `switch '…' would override a previous switch --> ignoring.` (`:139`).
In both cases the switch is dropped, the run continues, and the exit status is the program's.

## Reproducer

```c
#include <stdint.h>
int x = 7;
int main(void) {
  uintptr_t i = (uintptr_t)&x, j = 0;
  for (int k = 0; k < 64; k++)
    if (i & ((uintptr_t)1 << k)) j |= (uintptr_t)1 << k;
  return *(int *)j;
}
```

Run on the cerberus-lean fork's oracle at merge-base `b9aeedcb4` (`switches.ml` is unchanged
there), `--runtime=… --nolibc --exec --batch`, 2026-10-07 (stdout and stderr merged, the
`Time spent` line removed):

```
== (no --switches)
Undefined {ub: "UB043_indirection_invalid_value", stderr: "", loc: "<7:10--7:19>"}
== --switches=PNVI_ae_udi
Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
== --switches=PNVI_ae_udl
failed to parse switch 'PNVI_ae_udl' --> ignoring.
Undefined {ub: "UB043_indirection_invalid_value", stderr: "", loc: "<7:10--7:19>"}
== --switches=PNVI,PNVI_ae_udi
switch 'PNVI_ae_udi' would override a previous switch --> ignoring.
Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}
```

The typo run exits 1 (the program's UB) and the conflicting run exits 0, as if the options had
been accepted. This program cannot tell plain PNVI from PNVI-ae-udi (it prints `Specified(7)` under
both), so it shows only that the conflicting run proceeds. The next run shows WHICH model it gets.

### Which model the conflicting run executes

Upstream's own litmus test `tests/pnvi_testsuite/provenance_roundtrip_via_intptr_t_onepast.c` (a
one-past pointer cast to `intptr_t` and back, then stepped back into `x`) separates the two models:
plain PNVI finds no allocation at the one-past address, PNVI-ae-udi does (`find_overlaping`'s
`allow_one_past`). Run on PRISTINE upstream `b9aeedcb4` (its built driver, `--runtime=…`, libc
mode, `--exec --batch --mode=exhaustive`), 2026-10-07 (stdout and stderr merged, the `Time spent`
line removed; `exit` is the driver's status):

```
== 
Defined {value: "Specified(0)", stdout: "*q=11\n", stderr: "", blocked: "false"}
exit 0
== --switches=PNVI
Undefined {ub: "UB046_array_pointer_outside", stderr: "", loc: "<9:5--9:8>"}
exit 1
== --switches=PNVI_ae_udi
Defined {value: "Specified(0)", stdout: "*q=11\n", stderr: "", blocked: "false"}
exit 0
== --switches=PNVI,PNVI_ae_udi
switch 'PNVI_ae_udi' would override a previous switch --> ignoring.
Undefined {ub: "UB046_array_pointer_outside", stderr: "", loc: "<9:5--9:8>"}
exit 1
```

`PNVI,PNVI_ae_udi` gives plain PNVI's verdict (UB046), not PNVI-ae-udi's (`Defined`).

## Observed vs expected

Observed: a misspelt switch silently runs the default (PVI) model; `PNVI,PNVI_ae_udi` silently runs
plain PNVI (the first of the class wins, `switches.ml:136-139`; measured by the one-past run above),
not PNVI-ae-udi. The only trace is a stderr line that a
batch harness capturing stdout never sees. Expected: a command-line error (cmdliner's usual exit
124) for an unknown name and for two names of one class.

## Impact

Any experiment comparing memory models through `--switches` can report results for the wrong model
without failing: in the one-past run above the intended model (PNVI-ae-udi) answers `Defined` and
the model actually run (plain PNVI) answers UB046; in the typo run the intended PNVI-ae-udi answers
`Specified(7)` and the PVI run answers UB043. `--iso`
followed by `--switches` is handled better (a warning that `--iso` overrides, `main.ml`), which
shows the intent to be explicit.

## Proposed remedy

Make `Switches.set` return an error (or raise `Invalid_argument`) for an unknown name and for a
second name of one `pred` class, and have `main.ml` turn it into a command-line error.

## Classification

TRUE BUG (robustness, fail-open option parsing). Not a semantic question.

## Provenance

Measured in the cerberus-lean PNVI design pass (`lean_frontend/docs/2026-10-04_pnvi-ae-udi-design.md`
§C.5) and re-run for this draft on 2026-10-07 (the first reproducer on the fork's oracle, whose
`switches.ml` equals upstream's; the one-past run on pristine upstream `b9aeedcb4`, `deps/cerberus-upstream`) (PNVI arc S4, `docs/2026-10-07_pnvi-s4-lane-record.md`).
Fork status: cerberus-lean REFUSES both cases at its CLI (refusals R-PNVI-12 unknown name,
R-PNVI-11 override; `scripts/check_cli_refusals.sh`). Duplicate search: none done (no network at
drafting); repeat before filing.
