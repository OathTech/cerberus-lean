# Question: a function pointer's integer value is the symbol's fresh-counter number

**Affected (for orientation):** `memory/concrete/impl_mem.ml:2487-2488` (`intfromptr` on
`PVfunction` returns the symbol number), `:1203-1220` (a stored function pointer's bytes are
that number), `:1047` (read-back); `parsers/core/core_parser.mly:184` and `:220` (one
`Cerb_fresh.int()` per `std.core` symbol and label, drawn before the user TU). Checked against
the fork's oracle at `mdd/cerberus-lean` 2026-09-28; not re-checked against upstream `master`.

**Status note:** observed through our Lean port, which numbers symbols differently. We have not
observed a problem in unmodified upstream Cerberus; this is a design question about what the
number means.

## What happens

In the concrete memory model the integer value of a function pointer is the function's symbol
number. That number comes from the process-global fresh counter, so it depends on how many
symbols were drawn before the user's function: roughly 490 for the current `std.core`, plus
the implementation file, plus desugaring order. With `--nolibc --exec --batch`:

```c
#include <stdint.h>
int f(void) { return 1; }
int main(void) { intptr_t x = (intptr_t)&f; return (int)(x & 0xfff); }
```

gives `Specified(530)`. Adding one builtin to `std.core`, or reordering its declarations, moves
the value, although the program's meaning has not changed. The same number is visible through
the bytes of a stored function pointer and through `printf("%p", (void*)fp)` (`0x283` for a
similar program).

## Question

Is the numeric value of a function pointer meant to be observable? Options we can see: treat
the cast and the byte view as unspecified (the model would then fork or refuse), or draw
function addresses from a dedicated, program-ordered supply so the value depends only on the
program. Our port serves the same number and registers the integer, byte and `%p` channels as
a named deviation (`VALIDATION.md` §2b, N1); refusing the integer cast was tried and withdrawn,
because the runtime libc's `atexit` round-trips handlers through `uintptr_t`.
