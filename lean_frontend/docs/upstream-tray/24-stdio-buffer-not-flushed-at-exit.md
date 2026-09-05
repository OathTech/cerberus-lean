# Output held in a `FILE` buffer is never flushed at program termination: `fputs("out", stdout); return 0;` prints nothing (also with `exit(0)`; and `puts` after `putchar` loses its text)

**Affected:** `frontend/model/driver.lem:1303-1311` (`prepare_exit`) and
`:1328-1333` (`Step_done2 cval` — the return from `main` kills all
threads and records the value; the C library's `exit` is never entered);
`runtime/libc/src/stdlib.c:223-227` (`exit`: `__funcs_on_exit(); _Exit(code);`
— no stream flush); `runtime/libc/src/stdio.c:513-540` (`fflush`, correct
when called), `:787` (`fputs`), `:813-818` (`puts` = `fputs` +
`putc_unlocked('\n')`); `runtime/libcore/std.core:289` (`printf_proxy`,
which writes to the driver's stdout record directly, bypassing the `FILE`
buffer) and `:346-348` (`exit_proxy` → `<builtin_exit>`). Checked against
`master` @ `b9aeedcb4`: the libc C sources and `std.core` are
byte-identical; `driver.lem` differs from master only by Lean-target
`declare` lines outside the cited regions (master's line numbers).

## Description

Three related effects, one root: nothing on either termination path
flushes the C library's `FILE` buffers.

1. **Return from `main`.** The driver's `Step_done2` (driver.lem:1328-1333)
   calls `prepare_exit`, which empties the thread's stack and places the
   return value as the program's result. The libc `exit` is not called, so
   §5.1.2.2.3 ("return from the initial call to `main` is equivalent to
   calling `exit` with the value returned") is not implemented and no
   `fflush` happens. Data written through the buffer (`fputs`, `fputc`,
   `fwrite`, `putc`, `puts` — anything not newline-terminated on the
   line-buffered stdout) is lost.
2. **`exit()`.** The shipped libc's `exit` (stdlib.c:223-227) runs the
   `atexit` list and then `_Exit` → `__builtin_exit` → the Core builtin.
   musl, which this libc derives from, calls `__stdio_exit` here; the
   Cerberus copy does not, so §7.22.4.4#4 ("all open streams with unwritten
   buffered data are flushed") is not implemented either.
3. **Ordering against the `printf` proxy.** `printf`/`vprintf` are Core
   proxies (`std.core:289`) writing straight into the driver's stdout
   record, while `fputs`/`puts`/`fputc` go through the `FILE` buffer, so
   interleavings differ from a real libc even when the buffer IS flushed
   later. A further loss — `putchar('\n'); puts("xy");` prints only `"\n"`
   — we could not localise beyond "the second buffered write after a
   newline-triggered flush is dropped"; it is reported as an observation.

## Reproducers

`tests/noodle-probes/lib/lib_stdio_unflushed_lost.c`:

```c
#include <stdio.h>
int main(void) { fputs("out", stdout); return 0; }
```

`tests/noodle-probes/lib/lib_stdio_exit_unflushed_lost.c`:

```c
#include <stdio.h>
#include <stdlib.h>
int main(void) { fputs("out", stdout); printf(" %d\n", 5); exit(0); }
```

`tests/noodle-probes/lib/lib_stdio_puts_after_putchar.c`:

```c
#include <stdio.h>
int main(void) { putchar('\n'); puts("xy"); return 0; }
```

```
$ cerberus --exec --batch --mode=exhaustive lib_stdio_unflushed_lost.c
Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
$ cerberus --exec --batch --mode=exhaustive lib_stdio_exit_unflushed_lost.c
Defined {value: "Specified(0)", stdout: " 5\n", stderr: "", blocked: "false"}
$ cerberus --exec --batch --mode=exhaustive lib_stdio_puts_after_putchar.c
Defined {value: "Specified(0)", stdout: "\n", stderr: "", blocked: "false"}
```

(verbatim, 2026-09-05, un-forked upstream binary + runtime @ `b9aeedcb4`,
shipped libc; the fork's oracle at `928aa1e76` and our Lean port print
the identical lines.)

```
$ gcc -std=c11 -O0 lib_stdio_unflushed_lost.c && ./a.out        # prints: out
$ gcc -std=c11 -O0 lib_stdio_exit_unflushed_lost.c && ./a.out   # prints: out 5
$ gcc -std=c11 -O0 lib_stdio_puts_after_putchar.c && ./a.out    # prints: \nxy\n
```

(gcc 13.3.0, verbatim stdout `out`, `out 5\n`, `\nxy\n`; 2026-09-05.)
Controls that DO work on Cerberus: newline-terminated `fputs("out\n")`,
an explicit `fflush(stdout)`, `puts` alone
(`lib/lib_stdio_fflush_control.c`, all engines `"outz"`).

## Observed vs expected

- Observed: buffered stdout content is dropped at `return` from `main`
  and at `exit()`; `printf` output is reordered before earlier buffered
  writes; `puts` after `putchar('\n')` loses its text.
- Expected (§5.1.2.2.3, §7.22.4.4#4, §7.21.3): `out`, `out 5`, `\nxy\n`.

## Impact

Any program whose last output is not newline-terminated, or that mixes
`printf` with `fputs`/`fwrite`, produces a different `stdout:` field from
a real implementation — the differential test corpora compare stdout, so
this hides on both engines of a Cerberus-vs-Cerberus comparison and
surfaces only against a native referee. It also silently weakens every
stdout-based test: unflushed output is simply absent, not wrong.

## Proposed remedy

- Make return-from-`main` go through the library's `exit` when the libc
  is linked (call `exit(ret)` from the driver's `Step_done2` path, or emit
  the call in the `main` wrapper), so §5.1.2.2.3 holds by construction
  and `atexit` handlers run too (see the companion report on `atexit`).
- In the shipped libc's `exit` (stdlib.c:223-227) flush all streams
  before `_Exit` (musl: `__stdio_exit()`; equivalently `fflush(NULL)`
  using the existing stdio.c:513-522 loop).
- Route the `printf` family through the same `FILE` buffer as the rest of
  stdio (or flush `stdout` before a proxy write) so ordering matches.
- The `puts`-after-`putchar` loss needs a look at the write-buffer state
  after a newline-triggered flush (`__stdout_write`/`do_putc` in
  stdio.c); we have a reproducer but no localisation.

## Classification

**TRUE BUG.** Standard-mandated behaviour (flush at termination) is
missing on both termination paths; the affected functions are the
shipped libc's own, not a documented gap.

## Provenance

Found by the 2026-09-03 semantic-discrepancy probe campaign over our Lean
port (record `lean_frontend/docs/2026-09-03_noodle-cerberus-lean.md`,
finding L3); both engines agree (shared libc + shared driver), gcc
differs. Re-verified 2026-09-05 on the un-forked upstream binary +
runtime @ `b9aeedcb4`, the fork's oracle and the Lean port (lines above
verbatim). Localisation and this draft by Claude (Fable 5.1) under
operator direction; the filed issue carries an AI-provenance note per the
tray's policy.
