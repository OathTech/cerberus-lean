# The `_Atomic` qualifier is dropped from a parameter's object and applied to the whole declared type at block scope and in parameters

**Affected:** `frontend/model/cabs_to_ail.lem` @ `c3ff8c53f`: `desugar_parameter_declaration` registers the body's object with `ty` (:2565) and returns `mk_ctype_atomic ty` (:2566-2568, :2588); `desugar_declaration_base` wraps the type AFTER the declarator (:3966, `mk_ctype_atomic _ty`), where the file-scope arm and members use `wrap_atomic` (:3037, :3069, :3129), which descends through pointers. `cabs_to_ail_aux.lem:173-186` (`wrap_atomic`) wraps an array type whole.

## Description

In `_Atomic int *p` the qualifier belongs to the specified type: `p` is a pointer to atomic int (C17 6.7.2.4, 6.7.3). At block scope and for a parameter the declared type becomes an atomic pointer to int; for a parameter of a definition the object the body sees has no `_Atomic` at all.

## Reproducers

The parameter's object:

```c
int f(_Atomic int x) { typeof(x) y = 0; return _Generic(&y, _Atomic int *: 0, int *: 1, default: 2); } int main(void) { return f(0); }
```

Upstream: `Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}`. gcc: 0.

A block-scope pointer:

```c
int main(void) { _Atomic int *p = 0; return _Generic(p, _Atomic int *: 1, default: 0); }
```

Upstream: Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"} (the file-scope form: Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}). gcc: 1.

A block-scope array:

```c
int main(void) { _Atomic int a[3]; a[0] = 0; return a[0]; }
```

Upstream: `internal error: Ctyp.mk_ctype_atomic: called on an invalid inner type`. gcc: 0.

A file-scope array:

```c
_Atomic int a[3]; int main(void) { a[1] = 2; return sizeof a + a[1]; }
```

Upstream: `error: constraint violation: invalid use of _Atomic`. gcc: 14.

(Measured 2026-11-20 with `cerberus --exec --batch` (`--nolibc` unless a reproducer includes a library header) on the un-forked upstream binary and runtime @ `c3ff8c53f`; gcc 13 `-std=gnu2x`. Found by the discarded-constructs census, `../2026-11-20_discarded-constructs-census.md`, row §2.1 W12; §2.2 M1; §2.3 C3, C4; fork record `../2026-11-20_attribute-preservation-record.md`.)

## Fork status

Declared REFUSALS, as narrow as the arms allow: the `_Atomic` qualifier on a parameter of a function definition, and in the specifiers of a block-scope or parameter declaration whose declarator is not a plain identifier. The specifier form `_Atomic(T)`, the plain `_Atomic int x;` object and the file-scope pointer are unchanged and answer as gcc does. The file-scope array rejection is unchanged. Not repaired: the placement is upstream's to fix (use `wrap_atomic` at both sites and register the parameter's object with the atomic type).
