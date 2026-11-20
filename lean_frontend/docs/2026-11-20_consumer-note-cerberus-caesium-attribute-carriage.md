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
- an argument clause made only of plain string literals is the list it was, one argument per comma; ANY other
  clause (a bracket group or a prefixed literal anywhere in it) is ONE argument `[loc, tokens, []]`: all the tokens
  between the clause's parentheses joined by single spaces, a top-level comma included as a token, no pieces.

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
| `cerb::with_address` (with its one argument) after the name of a block-scope `extern`, or on a declaration that a later one without it follows | the attribute was silently ignored and the program ran |
| `#pragma pack`, every form | the line was silently skipped: a wrong layout |
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

## Where a redeclaration's attributes land (measured on both engines)

- **An object with EXTERNAL linkage** declared more than once: every declaration's attributes are on its one entry in
  `sigma.declarations`, earlier declarations first (`[[a]] extern int e; [[b]] int e;` gives `a` then `b`).
- **A file-scope object with INTERNAL linkage redeclared `extern` in a block**: the file-scope declaration's
  attributes are on the entry; the BLOCK declaration's are NOT, they are in `carried_attributes` as
  `(AP_declaration | AP_declarator_id, the object's identifier, …)`
  (`[[a]] static int e; … { [[b]] extern int e; }` gives `object e: a` and `carried declaration e: b`).
- **The same attribute written on two declarations is kept twice**, each with its own location (the header-plus-source
  pattern produces this); nothing is deduplicated, since nothing is given a meaning. A reader that counts or forbids
  repeats must do so itself.
- **Functions**: every declaration's attributes are on the declaration entry; the definition entry has the
  definition's own.
- **Typedef names — an upstream defect you inherit, not a design**: upstream's `register_typedef` reuses an existing
  declaration of the same name with no scope test, so a block-scope typedef that SHADOWS a file-scope one is merged
  with it: `typedef int T [[a]]; int main(void) { [[b]] typedef int T; … }` puts `b` and `a` on ONE entry, though
  the inner `T` is another entity in C (and a shadowing typedef of a different type is rejected as a redefinition).
  Pristine upstream does the same; it is filed (upstream-tray report 98) and unchanged here. A consumer that gives
  typedef attributes a meaning gets the inner typedef's attribute on the outer one.
- `cerb::with_address` on a declaration that a later declaration without it follows is refused at every such site
  (a file-scope redeclaration, a block-scope `extern` of an external or of an internal object, the `_Thread_local`
  form); with any argument count but one it is an ordinary carried attribute.

## `#pragma pack` is refused ([USER 2026-11-20] ruling)

`#pragma pack` in every form — `pack(n)`, `pack()`, `pack(push, …)`, `pack(pop)`, and `_Pragma("pack…")` — stops the
parse on both engines alike (no Cabs JSON is produced): `error: unimplemented keyword '#pragma pack (refused, contract
D19: …)'`. Before, the line was skipped and the struct had the unpacked layout (`sizeof` 8 where the compiled program
has 5). Every other pragma is still skipped silently, as upstream skips it (C17 6.10.6#1), inside an attribute
argument too.

## At your next re-pin

Pin the landing commit of `fix/attribute-preservation` on `mdd/cerberus-lean` (the orchestrator's landing note names
it). Rebuild both engines from re-derived generated trees and regenerate stored Cabs JSON. If a program of yours now
stops with one of the refusals above, the text names the rewrite; tell us if a refusal stops something you answered
correctly before, since that is a finding for this repository.
