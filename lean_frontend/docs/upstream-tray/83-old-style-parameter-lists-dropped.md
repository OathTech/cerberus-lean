# Old-style identifier lists and declaration lists are dropped without a diagnostic in three shapes

**Affected:** `parsers/c/lexer_feedback.ml` @ `c3ff8c53f`: `pointer_decl`, `declarator_decl` and `array_decl` (:92-110) overwrite the declarator's `sort`, so `create_function_definition` takes its catch-all (:166-167) and drops both lists; `fun_ids_decl` (:117-120) keeps the identifiers in `sort` only and `cabs_of_declarator` (:83-86) ignores it.

## Description

An old-style definition whose declarator is a pointer is valid C17 (6.9.1); it is rejected with a diagnostic that blames the body. A declaration list after a prototype is accepted and discarded (gcc rejects it). An identifier list in a declarator that is not a definition is a constraint violation (6.7.6.3#3) and is accepted; nested in a parameter it crashes.

## Reproducers

Pointer declarator:

```c
int g; int *f(a) int a; { g = a; return &g; } int main(void) { return *f(1); }
```

Upstream: `error: use of undeclared identifier 'a'`. gcc: 1.

Declaration list after a prototype:

```c
int f(void) int x; { return 0; } int main(void) { return f(); }
```

Upstream: `Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}`. gcc: rejects.

Identifier list in a declaration:

```c
int f(a, b); int main(void) { return 0; }
```

Upstream: `Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}`. gcc: 0 (warns).

Nested:

```c
void g(int h(x)); int main(void) { return 0; }
```

Upstream: `internal error: AilTypesAux.adjust ==> FunctionNoParams`. gcc: 0.

(Measured 2026-11-20 with `cerberus --exec --batch` (`--nolibc` unless a reproducer includes a library header) on the un-forked upstream binary and runtime @ `c3ff8c53f`; gcc 13 `-std=gnu2x`. Found by the discarded-constructs census, `../2026-11-20_discarded-constructs-census.md`, row §2.1 W4, W5, W6; §2.3 C5; fork record `../2026-11-20_attribute-preservation-record.md`.)

## Fork status

The first two shapes stop with upstream's own `found K&R-style declaration (unsupported)` (commit `4b260827c`: a `knr_ids` field survives the wrappers, and any declaration list on a non-old-style definition raises `KnR_declaration`). The last two are unchanged.
