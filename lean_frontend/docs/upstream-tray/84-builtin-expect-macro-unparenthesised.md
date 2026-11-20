# `__builtin_expect(EXP, C)` expands to `((long)EXP)`: the cast binds to the first operand of the argument

**Affected:** `runtime/libc/include/builtins.h:14` @ `c3ff8c53f`, the header every run force-includes (`backend/driver/main.ml:51`): `#define __builtin_expect(EXP, C) ((long)EXP)`.

## Description

GCC's `__builtin_expect(exp, c)` has the value of `exp` converted to `long`. With the parameter unparenthesised, an argument with a top-level binary operator is cast in its first operand only.

## Reproducers

Unsigned wrap:

```c
int main(void) { unsigned u = 4294967295u; return __builtin_expect(u + 1, 0) != 0; }
```

Upstream: `Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}`. gcc: 0.

Comparison:

```c
int main(void) { double d = 0.75; return __builtin_expect(d < 0.5, 0); }
```

Upstream: `Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}`. gcc: 0.

(Measured 2026-11-20 with `cerberus --exec --batch` (`--nolibc` unless a reproducer includes a library header) on the un-forked upstream binary and runtime @ `c3ff8c53f`; gcc 13 `-std=gnu2x`. Found by the discarded-constructs census, `../2026-11-20_discarded-constructs-census.md`, row §2.4 X1; fork record `../2026-11-20_attribute-preservation-record.md`.)

## Fork status

FIXED (commit `ed7925183`): the parameter is parenthesised; the libc dump does not move. `<stdatomic.h>`'s `atomic_init(obj,value) (*obj = value)` and `posix/sys/ioctl.h`'s `_IOC(inout,group,num,len)` (`inout` and `len` bare) have the same slip and are unchanged; neither header is force-included.

## Patch

`#define __builtin_expect(EXP, C) ((long)(EXP))`
