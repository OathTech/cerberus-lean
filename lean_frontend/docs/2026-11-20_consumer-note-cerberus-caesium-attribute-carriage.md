# Consumer note for cerberus-caesium: attribute carriage, new Cabs JSON fields, and what now stops (2026-11-20)

From: the `fix/attribute-preservation` worker [AGENT]. Contract D19; record
`2026-11-20_attribute-preservation-record.md`; census `2026-11-20_discarded-constructs-census.md`; witnesses
`scripts/check_attribute_carriage.sh` and `scripts/check_discarded_constructs.sh` (ladder row 1).

## Summary

No Core term changes for a program that used none of the forms below: the change is in the parser, the Cabs tree,
the desugarer's bookkeeping and one elaboration arm. The Ail `sigma` gains a field `carried_attributes`; Core is
unaffected by it (the elaboration does not read it). Statement and function attributes reach Core as before.

## The Cabs JSON changed shape (fail-closed)

A Cabs JSON exported by the new oracle carries these fields, and `CabsImport.lean` refuses a JSON without them (as
it refuses a position without its lexing pair), so an export and an importer from different sides of this landing do
not mix:

- `Specifiers`, `Struct_declaration`, `Type_name`: `specifier_attrs` (an `Attrs` object: the type's attributes);
- `TSpec_enum`, `ADecl`, `PDecl`, `Params`, `PDeclaration_decl`, `PDeclaration_abs_decl`: `attrs`;
- an enumerator is `[id, attrs, value]` (was `[id, value]`);
- a new declaration tag `Declaration_attribute` with `attrs` (`[[a]];` at file scope);
- an attribute argument that is not a plain string literal is `[loc, tokens, []]`: its tokens joined by single
  spaces, no pieces.

Regenerate any stored Cabs JSON at the re-pin. The ten fixtures `tests/fixtures/*/cabs.json` were regenerated.

## What now stops

Declared refusals (one text on both engines; whole texts in the record §4), with what each replaced on pristine
upstream, measured:

| refused form | before |
|---|---|
| an alignment specifier in a compound literal's type name | a silently wrong answer (the object was not aligned) |
| the `_Atomic` QUALIFIER on a parameter of a function definition | a wrong answer when the body inspects the parameter's type (`typeof`, `sizeof`, `&`); **a CORRECT answer otherwise**: `int f(_Atomic int x) { return x + 1; }` ran correctly and is now refused, because the arm cannot see the body. Write `_Atomic(int) x` |
| the `_Atomic` qualifier with a pointer or array declarator at block scope or on a parameter (`_Atomic int *p` in a function) | a wrong type for a pointer; a crash for an array |
| type qualifiers inside the brackets of an array parameter of a function declaration | a wrong function type for `const`; **already a loud stop** for `restrict` and for `volatile` against a pointer definition (a constraint diagnostic that blamed something else) |
| `cerb::with_address` after the name of a block-scope `extern`, or on a declaration that a later one without it follows | the attribute was silently ignored |
| an attribute declaration in a `for`-init clause | **already a loud stop** (an unlocated constraint violation) |

The specifier form `_Atomic(T)`, the plain `_Atomic int x;` object and `int * const a` are unchanged. Diagnosed: an
alignment specifier in a `sizeof`, `_Alignof`, cast or `_Atomic( )` type name (a constraint violation, C17 6.7.5#2,
accepted before); an attribute on a union or enum tag reference (accepted before); qualifiers in a non-outermost
bracket of an array parameter (`int a[2][const 3]`, accepted before). Parser stops: an old-style definition with a
pointer declarator (a misattributed error before), and a declaration list after a prototype (accepted before), both
`found K&R-style declaration (unsupported)`.

## What now answers differently (fixes)

- `for (_Alignas(64) char c = 0; …)`: the object has the requested alignment (it had its type's).
- `_Noreturn int f(void) { return g(); }`: `g()` is evaluated; UB071 follows only if it returns.
- `__builtin_expect(e, c)` is `(long)(e)` (the forced header's macro was `((long)e)`, wrong for `u + 1`).
- `typedef unsigned char byte [[cerb::byte]];` is the `Byte` type, as with the attribute before `typedef`.

## At your next re-pin

Pin the landing commit of `fix/attribute-preservation` on `mdd/cerberus-lean` (the orchestrator's landing note names
it). Rebuild both engines from re-derived generated trees and regenerate stored Cabs JSON. If a program of yours now
stops with one of the refusals above, the text names the rewrite; tell us if a refusal stops something you answered
correctly before, since that is a finding for this repository.
