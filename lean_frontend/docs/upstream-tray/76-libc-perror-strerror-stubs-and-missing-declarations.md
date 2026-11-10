# Shipped library gaps on conforming programs: `strerror`/`perror` are `assert(0)` stubs; `<wchar.h>`, `<uchar.h>` and `<float.h>` lack required declarations; `<math.h>` functions are declared but not linked

**Affected** (all @ `c3ff8c53f`): `runtime/libc/src/string.c:347-352` (`strerror`: `assert(0 && "not supported");`),
`runtime/libc/src/stdio.c:937-940` (`perror` calls `strerror(errno)`); `runtime/libc/include/wchar.h` (no `WCHAR_MIN`/
`WCHAR_MAX`, no `wcslen`), `runtime/libc/include/uchar.h` (an include guard with nothing inside),
`runtime/libc/include/float.h` (no `FLT_EPSILON`/`DBL_EPSILON`); `runtime/libc/include/math.h:151`, `:196` (`sqrt`,
`fmod` declared) with `runtime/libc/src/math.c` built by `runtime/libc/dune` into a separate `libm.co` that a default
libc-mode run does not link. The shipped library and headers: the OCaml backend and our Lean port agree.

This is one report for a family of missing library features, listed so that each has a reproducer; none is a wrong
value. Each program below is conforming C17 for a hosted implementation.

## Reproducers (un-forked upstream binary + runtime @ `c3ff8c53f`, shipped libc, 2026-11-10; gcc 13.3.0 `-std=c11 -w -O0`)

1. `strerror` and `perror` (C17 7.24.6.2, 7.21.10.4) stop the program with an assertion failure:

```c
#include <stdio.h>
#include <string.h>
int main(void) { puts(strerror(0)); return 0; }
```
```
$ cerberus --exec --batch strerror_0.c
Error {msg: "assert() failure"}
```
```c
#include <stdio.h>
#include <errno.h>
int main(void) { errno = 0; perror("x"); return 0; }
```
```
$ cerberus --exec --batch perror_x.c
Error {msg: "assert() failure"}
```

(both exit 1.) gcc: the first prints `Success` and exits 0; the second exits 0 with `x: Success` on stderr.

2. `<wchar.h>` does not declare `wcslen` (7.29.4.6.1) or define `WCHAR_MAX`/`WCHAR_MIN` (7.29.1#4):

```c
#include <wchar.h>
int main(void) { return (int)wcslen(L"abc"); }
```
```
$ cerberus --exec --batch wcslen_abc.c
wcslen_abc.c:2:30: error: use of undeclared identifier 'wcslen'
```
```c
#include <wchar.h>
int main(void) { return WCHAR_MAX > 0; }
```
```
$ cerberus --nolibc --exec --batch wcharmax_wchar.c
wcharmax_wchar.c:2:25: error: use of undeclared identifier 'WCHAR_MAX'
```

(both exit 1.) gcc exits 3 and 1. (`<stdint.h>` does define `WCHAR_MAX`; its value is report 62's subject.)

3. `<uchar.h>` (7.28) declares nothing, so `char16_t` is not a type name and the declaration is a syntax error:

```c
#include <uchar.h>
int main(void) { char16_t c = 1; return c; }
```
```
$ cerberus --exec --batch uchar_h.c
uchar_h.c:2:27: error: unexpected token after 'char16_t' and before 'c'
```

(exit 1.) gcc exits 1 (the value of `c`).

4. `<float.h>` has no `FLT_EPSILON` or `DBL_EPSILON` (5.2.4.2.2#13):

```c
#include <float.h>
int main(void) { return FLT_EPSILON > 0; }
```
```
$ cerberus --nolibc --exec --batch flt_epsilon.c
flt_epsilon.c:2:25: error: use of undeclared identifier 'FLT_EPSILON'
```
```c
#include <float.h>
int main(void) { return DBL_EPSILON > 0; }
```
```
dbl_epsilon.c:2:25: error: use of undeclared identifier 'DBL_EPSILON'
```

(both exit 1.) gcc exits 1 for both.

5. `<math.h>` functions are declared, and a call is accepted and then fails at run time as an unknown procedure
   (7.12.7.5 `sqrt`, 7.12.10.1 `fmod`):

```c
#include <math.h>
int main(void) { return (int)sqrt(16.0); }
```
```
$ cerberus --exec --batch fl_sqrt.c
Error {msg: "ill-formed program: `calling an unknown procedure: Symbol(531, SD_Id("sqrt"))'"}
```
```c
#include <math.h>
int main(void) { return (int)fmod(7.5, 2.0) ; }
```
```
Error {msg: "ill-formed program: `calling an unknown procedure: Symbol(622, SD_Id("fmod"))'"}
```

(both exit 1.) gcc (`-lm`) exits 4 and 1.

## Observed vs expected

- Observed: an assertion failure, a compile-time rejection, or a link-time-style run error, as shown per item.
- Expected: the library facilities C17 clause 7 requires of a hosted implementation, or a statement of the supported
  library subset that these stops can be read against.

## Impact

Loud in every case (no program gets a wrong answer). `perror`/`strerror` matter most in practice: any error path that
reports through them ends the run with `assert() failure` instead of the program's own exit path.

## Proposed remedy (prose; no patch is attached)

`strerror` returning a fixed message per `errno` value (musl's table, or a single generic string) makes `perror` work;
the header gaps are declarations; for `<math.h>`, link the built `libm.co` in libc mode or diagnose the call at link
time with the header's name.

## Fork status (2026-11-10)

Unchanged in both engines (identical lines; the Lean port's `unknown procedure` line carries a different symbol
number, report 17's subject). Reported, not fixed. Not ISO C and therefore not listed above, also absent: `strnlen`
(POSIX) and the GNU builtins `__builtin_abs`, `__builtin_popcount`, `__builtin_clz`, `__builtin_clzll`,
`__builtin_add_overflow`, `__builtin_mul_overflow`, `__builtin_alloca`, `__builtin_memcpy`, `__builtin_strlen` (each
`use of undeclared identifier` on pristine today).

## Classification

**INTENDED GAP** for the stubs (`strerror`'s own text says "not supported") and the empty headers; reported because
the stops are not documented as a supported-subset statement.

## Provenance

Collected by the fork's true-bug audit of 2026-11-04 (sibling findings 20 and 21) while probing reports 24, 32 and 62.
Re-run on pristine upstream at `c3ff8c53f`, both fork engines and gcc on 2026-11-10. This draft by Claude (Fable 5.2)
under operator direction; the filed issue carries an AI-provenance note per the tray's policy.
