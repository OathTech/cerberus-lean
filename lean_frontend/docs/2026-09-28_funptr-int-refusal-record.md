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
needs a representation change. These two channels remain a served difference, registered as
named deviation N1 (`VALIDATION.md` §2b, new class (e); [USER 2026-09-28] "yes, re the decision,
agree with (1). Named deviations are okay in cases we can't easily resolve the mismatch."), with
witnesses `zd-funptr-bytes-deviation` and `zd-funptr-printf-deviation` and upstream-tray draft 46.

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

## Addendum (later on 2026-09-28): the refusal is withdrawn, the integer channel joins N1

The thin-surface edge-case tests (`docs/2026-09-28_thin-surface-tests-record.md` §3 D2) found that the refusal made
every `atexit` call refuse in libc mode. The runtime libc stores each handler as an integer and converts it back to
call it (`runtime/libc/src/stdlib.c:194-199`); the number is never observed, and both engines served the round trip
correctly before the refusal (served-surface probe `p2_exit_atexit`, `Specified(7)`, `"main\nbye\n"` on both). The
blast-radius measurement above missed it because no lane program called `atexit`, which is exactly the thin coverage
the test-depth map later measured.

Decision [USER 2026-09-28] "agree on atexit as you propose": revert the refusal and register the integer channel under
named deviation N1 with the bytes and `%p`. `CerbMem.intfromptr` is back to the OCaml mirror with the N1 marker;
`zd-funptr-int-direct` and `zd-funptr-int-voidptr` are pinned `DIFF | L=VAL:{Specified(47)}` (oracle 530);
`ptr3-001` is back to `MATCH`; libc_exec rows `040-atexit-order` and `041-atexit-return` pin the served round trip.
