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
been accepted.

## Observed vs expected

Observed: a misspelt switch silently runs the default (PVI) model; `PNVI,PNVI_ae_udi` silently runs
plain PNVI (the first of the class wins), not PNVI-ae-udi. The only trace is a stderr line that a
batch harness capturing stdout never sees. Expected: a command-line error (cmdliner's usual exit
124) for an unknown name and for two names of one class.

## Impact

Any experiment comparing memory models through `--switches` can report results for the wrong model
without failing: the verdicts above differ between the intended and the actual model. `--iso`
followed by `--switches` is handled better (a warning that `--iso` overrides, `main.ml`), which
shows the intent to be explicit.

## Proposed remedy

Make `Switches.set` return an error (or raise `Invalid_argument`) for an unknown name and for a
second name of one `pred` class, and have `main.ml` turn it into a command-line error.

## Classification

TRUE BUG (robustness, fail-open option parsing). Not a semantic question.

## Provenance

Measured in the cerberus-lean PNVI design pass (`lean_frontend/docs/2026-10-04_pnvi-ae-udi-design.md`
§C.5) and re-run for this draft on 2026-10-07 (PNVI arc S4, `docs/2026-10-07_pnvi-s4-lane-record.md`).
Fork status: cerberus-lean REFUSES both cases at its CLI (refusals R-PNVI-12 unknown name,
R-PNVI-11 override; `scripts/check_cli_refusals.sh`). Duplicate search: none done (no network at
drafting); repeat before filing.
