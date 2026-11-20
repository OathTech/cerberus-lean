# Consumer note for refinedc-lean: every attribute placement now reaches Ail (2026-11-20)

From: the `fix/attribute-preservation` worker [AGENT]. Answers the "discarded contracts" item of your
`docs/PUBLIC-ALPHA.md` and your probe `scripts/probes/discarded-contracts.py`. Contract D19; record
`2026-11-20_attribute-preservation-record.md` (§3 has your ten programs); census
`2026-11-20_discarded-constructs-census.md`; witness `scripts/check_attribute_carriage.sh` (ladder row 1).

## What changed for you

All ten placements of your probe now arrive in Ail, on both engines, and none is refused by the front end:

| placement | where the attribute is |
|---|---|
| function declaration; after the function name | the function's attributes in `sigma.declarations` and `sigma.function_definitions` (the after-name placement JOINS the leading ones: C23 6.7.12.1 has both appertain to the function) |
| return statement | the statement's `attrs` (unchanged) |
| after the parameter list | `sigma.carried_attributes`: `(AP_function, some sample, attrs)` |
| after the return type | `(AP_specifiers, some sample, attrs)` |
| on a parameter; after a parameter name | `(AP_parameter, some x, attrs)`; `(AP_declarator_id, some x, attrs)` |
| after a local's type; after its name; before its declaration | `(AP_specifiers, some y, …)`; `(AP_declarator_id, some y, …)`; `(AP_declaration, some y, …)` |

`sigma.carried_attributes : list (Annot.attribute_placement * maybe Symbol.identifier * Annot.attributes)` is new. It
holds every attribute that appertains to something Ail has no attribute slot for (block-scope objects, parameters,
enumerators, enum specifiers, tag declarations, the type placements, type names, a file-scope `[[a]];`). The identifier
is the declared entity's, with its source location (it equals the location in the entity's `bindings` entry);
`Nothing` means no entity (a type name, an abstract declarator). The front end gives none of these a meaning.

**What you need to do.** Your translator reads the function, statement, tag and member slots. To close your item it
must also read `carried_attributes`: an `rc::` attribute there is one you do not interpret today, so refuse it (your
`class: annotation` refusal) or give it a meaning. Note the after-function-name placement: it is now in the
function's own attributes, so `int sample [[rc::ensures("{False}")]] (int x)` is a function-level `ensures` to your
existing code path. `[[a]];` in a block is an attributed `AilSskip` statement in its position.

Attribute arguments: `rc::x(("s"))` and `rc::x(L"s")` used to arrive as `rc::x()` and `rc::x("s")`; they now arrive
as ONE argument whose string is the source text (`("s")`, `L"s"`) and whose piece list is EMPTY. A plain string
argument always has at least one piece; treat an empty piece list as "not a string literal".

## The Cabs JSON changed shape (fail-closed)

A Cabs JSON exported by the new oracle carries these fields, and `CabsImport.lean` refuses a JSON without them (as
it refuses a position without its lexing pair), so an export and an importer from different sides of this landing do
not mix:

- `Specifiers`, `Struct_declaration`, `Type_name`: `specifier_attrs` (an `Attrs` object: the type's attributes);
- `TSpec_enum`, `ADecl`, `PDecl`, `Params`, `PDeclaration_decl`, `PDeclaration_abs_decl`: `attrs`;
- an enumerator is `[id, attrs, value]` (was `[id, value]`);
- a new declaration tag `Declaration_attribute` with `attrs` (`[[a]];` at file scope);
- an attribute argument that is not a plain string literal is `[loc, source text, []]`: no pieces.

Regenerate any stored Cabs JSON at the re-pin. The ten fixtures `tests/fixtures/*/cabs.json` were regenerated.

## What now stops

Declared refusals (one text on both engines; whole texts in the record §4): an alignment specifier in a compound
literal's type name; the `_Atomic` QUALIFIER on a parameter of a function definition; the `_Atomic` qualifier in the
specifiers of a block-scope or parameter declaration whose declarator is not a plain identifier (`_Atomic int *p`
inside a function); type qualifiers inside the brackets of an array parameter of a function declaration
(`int f(int a[const 1]);`); `cerb::with_address` after the name of a block-scope `extern`; an attribute declaration
in a `for`-init clause. Each replaced a silently wrong answer or a crash. The specifier form `_Atomic(T)`, the plain
`_Atomic int x;` object and `int * const a` are unchanged. Diagnosed: an alignment specifier in a `sizeof`,
`_Alignof`, cast or `_Atomic( )` type name (a constraint violation, C17 6.7.5#2); an attribute on a union or enum tag
reference. Parser stops: an old-style definition with a pointer declarator, and a declaration list after a prototype
(`found K&R-style declaration (unsupported)`).

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
