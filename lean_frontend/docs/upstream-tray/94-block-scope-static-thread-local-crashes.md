# A block-scope `static _Thread_local` object crashes or has no definition

**Affected:** `frontend/model/cabs_to_ail.lem` @ `c3ff8c53f`: :4039 `error "TODO: desugar_declaration_base, Thread duration"` (with an initializer); :4054-4056 registers no definition (without one).

## Description

C17 6.7.1#3 permits `_Thread_local` with `static` at block scope.

## Reproducers

```c
int main(void) { static _Thread_local int y = 3; return y; }
```

Upstream: `internal error: TODO: desugar_declaration_base, Thread duration` (without the initializer: `Error {msg: "unresolved symbol: x at other_location(Driver.drive)"}`). gcc: 3.

(Measured 2026-11-20 with `cerberus --exec --batch` (`--nolibc` unless a reproducer includes a library header) on the un-forked upstream binary and runtime @ `c3ff8c53f`; gcc 13 `-std=gnu2x`. Found by the discarded-constructs census, `../2026-11-20_discarded-constructs-census.md`, row §2.3 C1, C2; fork record `../2026-11-20_attribute-preservation-record.md`.)

## Fork status

Unchanged in the fork: the program is valid C and the fork stops on it exactly as upstream does (nothing is refused or repaired).
