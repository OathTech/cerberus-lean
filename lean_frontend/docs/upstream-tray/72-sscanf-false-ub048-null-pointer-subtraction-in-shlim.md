# `sscanf` with any non-empty format is reported as `UB048_disjoint_array_pointers_subtraction`: the shipped library's `__shlim` subtracts the string FILE's null read pointer from its buffer

**Affected:** `runtime/libc/src/stdio.c` @ `c3ff8c53f`: `:726-734` (`vsscanf` builds a `FILE` on the stack with
`.read`, `.buf = (void *)s` and `.cookie = (void *)s`; every other member, `rpos` included, is zero-initialised) and
`:113-122` (`__shlim`, `:116` `f->shcnt = f->buf - f->rpos;`, reached from `vfscanf` through the macro `fshlim(f, 0)`,
`runtime/libc/src/vfscanf.c:79` and `internal.h:43`, before the first read). The shipped C library, so the OCaml backend and our Lean port agree.

## Description

`vsscanf` (and through it `sscanf`) scans a string by wrapping it in a `FILE` whose buffer pointer is the string and
whose read pointer has not been set yet; the first thing `vfscanf` does with that `FILE` is `__shlim`, which computes
`f->buf - f->rpos` — the string's address minus a null pointer. The memory model evaluates that subtraction as what it
is in ISO C (C17 6.5.6#9: both operands shall point into the same array object) and stops with UB048, attributed to
`stdio.c:116`. The program that called `sscanf` is conforming; the undefined subtraction is inside the library's own
text (the idiom is musl's, where it is harmless on the targets musl supports).

## Reproducer

```c
#include <stdio.h>
int main(void) { int v = 0; int r = sscanf("12", "%d", &v); printf("%d %d\n", r, v); return 0; }
```

```
$ cerberus --exec --batch sscanf_d.c
Undefined {ub: "UB048_disjoint_array_pointers_subtraction", stderr: "", loc: "<116:23--116:30>"}
```

(exit 1; verbatim, 2026-11-10, un-forked upstream binary + runtime @ `c3ff8c53f`, shipped libc. The location is
`runtime/libc/src/stdio.c:116`.) A string conversion fails the same way:

```c
#include <stdio.h>
int main(void) { char b[8]; int r = sscanf("hi there", "%7s", b); printf("%d %s\n", r, b); return 0; }
```

```
Undefined {ub: "UB048_disjoint_array_pointers_subtraction", stderr: "", loc: "<116:23--116:30>"}
```

```
$ gcc -std=c11 -w -O0 sscanf_d.c && ./a.out
1 12
$ gcc -std=c11 -w -O0 sscanf_s.c && ./a.out
1 hi
```

(gcc 13.3.0 / glibc; verbatim 2026-11-10.)

## Observed vs expected

- Observed: an undefined-behaviour verdict for a conforming program, before any character is scanned.
- Expected: C17 7.21.6.7#2-#3 (`sscanf` is `fscanf` reading from the string): `1 12` and `1 hi`.

## Impact

`sscanf` is unusable for any format that makes `vfscanf` read: a conversion (`%d`, `%7s` above) or a literal
character (`sscanf("x", "x")`: the same UB048 line on un-forked upstream, 2026-11-10) ends the execution with a UB
verdict that points into the library. Only the empty format returns (`sscanf("x", "")`:
`Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}`, gcc exit status 0). Programs that parse with `sscanf` (configuration readers, test drivers) cannot be run in libc mode.

## Proposed remedy (prose; no patch is attached)

Give the string `FILE` a read pointer before `__shlim` sees it: initialise `.rpos` and `.rend` to the string in
`vsscanf` (so that `f->buf - f->rpos` is a subtraction within one object and is 0), or make `__shlim` not subtract
when `f->rpos` is null.

## Fork status (2026-11-10)

Unchanged: the fork's oracle and the Lean port print the same verdict (the Lean port without the library location).
The fork has not changed this behaviour.

## Classification

**TRUE BUG** (a false undefined-behaviour verdict on conforming input, in the shipped library).

## Provenance

Found on 2026-11-04 while probing the formatted-input functions with small programs compared against gcc; the
mechanism was located on 2026-11-10 by reading `stdio.c` at `c3ff8c53f` from the verdict's location. Re-run on un-forked upstream at `c3ff8c53f`, on this fork's two engines and on gcc on 2026-11-10. Analysis and this
draft by Claude (Fable 5.2), an AI agent, under the direction of a human operator; the filed issue carries an
AI-provenance note per the tray's policy.
