# `strncmp` compares the differing characters as plain `char`, not as `unsigned char`

**Affected:** `runtime/libc/src/string.c` @ `c3ff8c53f`, :85-90

```c
int strncmp(const char *s1, const char *s2, size_t n)
{
  while ((*s1 && *s1 == *s2) && --n > 0)
    s1++, s2++;
  return (*s1 - *s2);
}
```

`strcmp`, eight lines above (:73-78), returns `(*(unsigned char*)s1 - *(unsigned char*)s2)`.

## Description

C17 7.24.4#1: the sign of a nonzero value returned by the comparison functions is determined by the sign of the
difference between the values of the first pair of characters that differ, "both interpreted as `unsigned char`".
`strncmp` subtracts plain `char` values, so with signed plain `char` a byte above `\x7f` compares below every byte
up to `\x7f`. Report 30 is about the same function with a zero length; this is a different defect in its last line.

## Reproducer

```c
#include <string.h>
int main(void) {
  return (strncmp("\x80", "\x7f", 1) > 0 ? 1 : 0) + (strcmp("\x80", "\x7f") > 0 ? 2 : 0)
       + (memcmp("\x80", "\x7f", 1) > 0 ? 4 : 0);
}
```

Upstream: `Defined {value: "Specified(6)", stdout: "", stderr: "", blocked: "false"}`: `strcmp` and `memcmp` answer
as the standard requires, `strncmp` does not. gcc 13: 7.

(Measured 2026-11-22 with `cerberus --exec --batch` on the un-forked upstream binary and runtime @ `c3ff8c53f`.)

## Suggested fix

```c
  return (*(unsigned char*)s1 - *(unsigned char*)s2);
```

## Fork status

Unchanged in the fork under the default implementation profile (the oracle answers 6). Under the fork's `hafnium`
profile (plain `char` unsigned, contract D20) the fork's pre-merge review of 2026-11-22 measured the comparison
true, the standard's answer.
