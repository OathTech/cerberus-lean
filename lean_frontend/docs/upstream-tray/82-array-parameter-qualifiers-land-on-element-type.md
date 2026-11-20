# Type qualifiers inside the brackets of an array parameter qualify the element type; in a function definition the form is rejected

**Affected:** `frontend/model/cabs_to_ail.lem` @ `c3ff8c53f`, `desugar_array_declarator`, the `Scope_prototype` arm (:2257-2260) with `AilTypesAux.adjust` (`ail/ailTypesAux.lem:1280-1287`); the commented-out code at :2245-2256 has the pointer placement. The parameters of a function DEFINITION are not in prototype scope and take the `ArrayDeclarationQsAndStaticOutsideFunctionProto` arm (:2262-2266).

## Description

C17 6.7.6.3#7: a parameter `int a[const 1]` is adjusted to `int * const a`; the qualifiers in the brackets qualify the pointer. Cerberus types it `const int *a`. C17 6.7.6.2#1 permits the qualifiers and `static` in any parameter declaration with an array type, definitions included.

## Reproducers

Declaration:

```c
int f(int a[const 1]); int main(void) { return _Generic(f, int (*)(int * const): 1, int (*)(const int *): 2, default: 0); }
```

Upstream: `Defined {value: "Specified(2)", stdout: "", stderr: "", blocked: "false"}`. gcc: 1.

Definition:

```c
void f(int a[const 1]); void f(int a[const 1]) { a[0] = 1; } int main(void) { int x[1]; f(x); return x[0]; }
```

Upstream: `error: constraint violation: type qualifiers or 'static' used in array declarator outside of function prototype`. gcc: 1.

(Measured 2026-11-20 with `cerberus --nolibc --exec --batch` on the un-forked upstream binary and runtime @ `c3ff8c53f`; gcc 13 `-std=gnu2x`. Found by the discarded-constructs census, `../2026-11-20_discarded-constructs-census.md`, row §2.2 M2; §2.3 G8, G9; fork record `../2026-11-20_attribute-preservation-record.md`.)

## Fork status

Declared REFUSAL of qualifiers in the brackets of an array parameter of a function declaration (the wrong answer). The definition's rejection and the `static` refusal (`feature not yet supported: array parameter with the static keyword`) are unchanged.
