# The `_Atomic` QUALIFIER form (C11 §6.7.3) is dropped or misplaced by the desugarer in two declaration positions: block-scope declarations with an initializer, and function parameters

**Classification:** TRUE BUG (two independent desugar paths; both observable
as a spurious constraint violation on well-formed C11).

**Affected (upstream `master` @ `b9aeedcb4`; our copy of
`frontend/model/cabs_to_ail.lem` is byte-identical at every cited line):**

- `desugar_declaration_base` :3540-3553 (self-labelled `"BROKEN:
  desugar_declaration_base"` :3542): `translate_type_qualifiers` computes
  `isAtomic` :3549, but the init-declarator is desugared and the object
  REGISTERED by `desugar_init_declarator_BROKEN` :3551 (:2571, self-labelled
  `"TODO ==> USING desugar_init_declarator_BROKEN"`) with the UN-wrapped
  `_ty`; `mk_ctype_atomic` is applied afterwards to a local `cty` :3553 that
  the registered object type never sees. Reached from :3744 (the
  block-scope declaration path).
- `desugar_parameter_declaration` :2124/:2168 and the abstract-declarator
  arm :2183/:2189: `mk_ctype_atomic` is applied to the DECLARATOR's result
  type (`ty`, after the pointer/array declarators have been applied)
  instead of to the base type before them — `_Atomic int *p` becomes
  `_Atomic(signed int*) p` (an atomic pointer to int) rather than a pointer
  to atomic int; :2166 additionally registers the parameter with the
  un-wrapped `ty`.

The other declaration paths are right: `desugar_init_declarator` (:2619,
`wrap_atomic` at :2626/:2658 BEFORE registration) serves file-scope
declarations with or without initializer and block-scope declarations
WITHOUT an initializer; the specifier form `_Atomic(T)` and the `atomic_int`
typedefs go through `desugar_type_specifiers` and are unaffected.

## Reproducers (upstream binary @ b9aeedcb4, `--nolibc --exec --batch`; our port prints the identical text, as it is generated from the same `.lem`)

Works (four shapes), verbatim `Defined {value: "Specified(1)", …}`:

```c
_Atomic int x;             // file scope, no initializer
_Atomic int x = 0;         // file scope, initializer
static _Atomic int x;      // file scope, static
int main(void){ _Atomic int x; atomic_store_explicit(&x,1,memory_order_seq_cst); … }   // block scope, NO initializer
```

Fails, block scope WITH initializer:

```c
#include <stdatomic.h>
int main(void){ _Atomic int x = 0; atomic_store_explicit(&x,1,memory_order_seq_cst); return atomic_load_explicit(&x,memory_order_seq_cst); }
```
```
c_local_init.c:2:36: error: constraint violation: address argument to atomic operation must be a pointer to _Atomic type ('signed int' invalid)
```
`--pp=ail` of `int main(void){ _Atomic int x = 0; return 0; }` shows the
declared type with the qualifier gone: `signed int x = 0;`.

Fails, parameter:

```c
#include <stdatomic.h>
int f(_Atomic int *p){ atomic_store_explicit(p,1,memory_order_seq_cst); return atomic_load_explicit(p,memory_order_seq_cst); }
_Atomic(int) x; int main(void){ return f(&x); }
```
```
d_param.c:2:24: error: constraint violation: address argument to atomic operation must be a pointer to _Atomic type ('signed int' invalid)
```
`--pp=ail` of `int f(_Atomic int *p){ return 0; }` shows the misplaced
qualifier: `signed int f(_Atomic(signed int*) p)`.

## Why it matters

C11 §6.7.3p1 lists `_Atomic` among the type qualifiers; §6.7.2.4 is the
specifier form. Real code (and the C11 standard's own examples) uses the
qualifier form freely; `atomic_int x = 0;` inside a function — the most
common way to declare an atomic — expands to the specifier form via
`<stdatomic.h>` and so escapes, which is why the bug is easy to miss.

## Proposed remedy

1. Block scope with initializer: route `desugar_declaration_base` through
   `desugar_init_declarator attrs isAtomic …` (the non-BROKEN function,
   which wraps before registering), or have `desugar_init_declarator_BROKEN`
   take `isAtomic` and wrap `_ty` before `register_*`; drop the
   after-the-fact `cty` wrap at :3553.
2. Parameters: apply `mk_ctype_atomic` to `base_ty` BEFORE `mk_qs_ctype`
   builds the declarator type (:2124-2130, :2183-2189), and register the
   wrapped type at :2166.

Provenance: found 2026-09-04 while building an SC-concurrency litmus
corpus (the corpus was respelled to the specifier form); shapes isolated
2026-09-05 with the six-probe sweep above. [AGENT]-drafted; filing is the
operator's call.
