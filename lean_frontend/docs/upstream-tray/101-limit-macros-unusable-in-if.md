# The `<limits.h>` macros cannot be used in `#if`: they expand to identifiers the preprocessor evaluates as 0

**Affected:** `runtime/libc/include/limits.h` @ `c3ff8c53f`, e.g. :5-9

```
#define SCHAR_MIN  __cerbvar_SCHAR_MIN
#define SCHAR_MAX  __cerbvar_SCHAR_MAX
#define UCHAR_MAX  __cerbvar_UCHAR_MAX
#define CHAR_MIN   __cerbvar_CHAR_MIN
#define CHAR_MAX   __cerbvar_CHAR_MAX
```

The `__cerbvar_*` names are resolved by the front end after preprocessing (`frontend/model/builtins.lem`).

## Description

C17 5.2.4.2.1#1 requires the `<limits.h>` values to be "constant expressions suitable for use in `#if` preprocessing
directives". Here each macro expands to an identifier, and an identifier that is not a macro is 0 in a `#if`
expression (6.10.1#4). A program that tests a limit in `#if` therefore takes the branch for the value 0, silently,
and the same expression outside `#if` has the real value.

## Reproducer

```c
#include <limits.h>
int main(void) {
  int r = 0;
#if CHAR_MIN < 0
  r += 1;
#endif
#if CHAR_MAX == 127
  r += 2;
#endif
#if INT_MAX > 32767
  r += 4;
#endif
#if UCHAR_MAX == 255
  r += 8;
#endif
  return r;
}
```

Upstream: `Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}`. gcc 13: 15.

(Measured 2026-11-22 with `cerberus --nolibc --exec --batch` on the un-forked upstream binary and runtime @
`c3ff8c53f`.)

## Fork status

Unchanged in the fork: both engines answer 0. The fork's `tests/impl_profile/preprocessor_if.c` pins a program of
this kind with gcc's answer beside it as a declared difference (fork contract D20: the preprocessor is the host's
and does not read the implementation profile).
