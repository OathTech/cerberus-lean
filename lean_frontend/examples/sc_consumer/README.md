# External SC operational consumer

This separate Lake package imports the provider by path and uses its initialized
whole-C API. The input is a linked Core file from the ordinary C pipeline, with
its actual origin evidence, filesystem, fresh supply and address-space bound.

`CerbSCOperational.start` returns the program and remaining fresh supply.
`sc_program_node` exposes the next actual ND node and its post-state, including
every offered alternative, label, constraint and suspension. Select an offered
continuation with `sc_program_resume postState continuation`. It retains global
initialization, main, finalization and saved service work. Do not reconstruct
paused execution from the driver state alone.

`CerbSCOperational.terminal` recognizes only the outer result or kill. Blocking
is the result's `dres_blocked` flag; kills retain the original UB, typed model or
port refusal, other operational fault, or distinguished fuel-exhaustion cause.
All carry the actual final/failure-time state and its retained findings. An
empty choice list is visible in the raw node and is not a completed program.
Internal `SC_halted` is not this API's terminal result.

Semantic fuel is captured at initialization and never renewed at resume.
`outcomes budget program` is the existing bounded ND runner; `budget` counts
exploration depth. The CLI uses the same number for both bounds. The example's
kernel statements connect initialized execution to that driver, preserve an
assertion about a reported fault, retain a selected continuation, and expose
budget exhaustion. No sufficiently-large-fuel or whole-program safety claim is
made. Larger C probes need not be exhaustively explored.

From this directory, with the project environment loaded:

```sh
../../../scripts/capped lake build
```

The toolchain and dependency revision match the provider. This example neither
builds nor modifies the customer repository. Remaining interpretation and
runtime obligations stay visible; see the SC charter for completion status.
