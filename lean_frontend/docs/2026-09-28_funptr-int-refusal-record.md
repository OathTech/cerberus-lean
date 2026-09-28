# Function-pointer-to-integer refusal (served-surface audit P1-1) — record

Date: 2026-09-28. Branch: `arc/contract-enforcement`. Author: the orchestrator [AGENT].
Decision: [USER 2026-09-28] "P1-1 - let's measure, then refuse if the blast radius isn't too big."

## Finding (from `docs/2026-09-28_served-surface-audit.md` §P1-1, re-measured)

Converting a function pointer to an integer serves the function symbol's number
(`impl_mem.ml:2487-2488`, mirrored at `CerbMem.intfromptr`). That number comes from the
fresh-symbol supply. The oracle's Core parser draws one number for every `std.core` symbol
before the user TU (`core_parser.mly:184,220`); `CoreParser.lean` mints hashes instead. So the
engines serve different integers where the oracle answers: a fifth outcome under the contract.

Re-measured by the orchestrator on `835c230b1` (the auditor's figures reproduced, nolibc,
oracle `--exec --batch --nolibc`, Lean `--batch --first`):

| probe | oracle | Lean |
|---|---|---|
| `(intptr_t)&f & 0xfff` | `Specified(530)` | `Specified(47)` |
| low two bytes of a stored `int (*)(void)` | `Specified(502)` | `Specified(19)` |
| `printf("%p", (void*)fp)` | `(@empty, 0x283)` | `(@empty, 0xa0)` |

## Change

`CerbMem.intfromptr` refuses both routes to the number, through `failStopMem` /
`CerbFail.failStopKill` (a monadic fail-stop, so no failure-reach register row):

- a `PVfunction` pointer value (the direct cast, including `(unsigned long)(void*)f`);
- a `PVconcrete` address that the funptrmap records as a function pointer (the number read
  back from a stored `void*`; the same test as `caseFunsymOpt`).

The `PVconcrete` arm is otherwise unchanged, split out as `intfromptrConcrete`. The divergence
from the OCaml is documented in-code as deliberate.

## Not refused: the byte and `%p` channels

A stored function pointer is the number's bytes (`impl_mem.ml:1168-1185`, mirrored). Every stored
function pointer (tables, callbacks, `void*` round trips) goes through that representation,
so refusing at the store would refuse all of them. `%p` prints a `void*` read back from those
bytes through the pure printer, which has no memory state. A precise refusal of either channel
needs a representation change. These two channels remain a served difference; their disposition
(register as a deviation, or a representation change) is an OPEN operator decision.

## Blast radius (measured)

Tier A lanes on the change (immaculate, minimal, multi-TU, tray, address space, libc_exec, bytes,
float, debug, coverage): one row moved, `tests/coverage/ptr3/ptr3-001-funcptr-to-int.libc.c`
(MATCH only because it tested `x != 0`). It is renamed `*.unsupported.c` per the lane convention
and re-pinned UNSUPPORTED. Tier B corpora: measured by the full ladder at the enforcement claim point.

## Witnesses

- `tests/immaculate/nolibc/zd-funptr-int-direct.c`, `zd-funptr-int-voidptr.c`: pinned refusals,
  `DIFF | L=CRASH`.
- `tests/immaculate/nolibc/zd-funptr-call-control.c`: stored, round-tripped, compared and called
  function pointers stay served, `MATCH` `Specified(312)`.
