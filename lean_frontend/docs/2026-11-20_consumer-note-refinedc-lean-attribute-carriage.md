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
as ONE argument whose string is the clause's TOKENS joined by single spaces (`( "s" )`, `L"s"`) and whose piece list
is EMPTY; a clause with a group or a prefixed literal anywhere in it is one such argument, whole
(`rc::x(("a") "b", "c")` arrives as the single argument `( "a" ) "b" , "c"`).
A plain string argument always has at least one piece; treat an empty piece list as "not a string literal". The
tokens are those the C parser read, so they are the tokens AFTER macro expansion, without comments or layout: a
group written over several lines or through a macro arrives on one line, expanded.

Redeclarations: an object with external linkage declared more than once keeps the attributes of every declaration,
earlier first (`[[rc::global("…")]] extern int e;` in a header and `int e;` in the source file: the attribute used to
be lost, on your pin too; it is now on `e`'s entry in `sigma.declarations`). The exact landing place in each case,
and the typedef case that is NOT right, are in the section below.

Not accepted by the parser, loudly: an attribute declaration directly after a label (`case 0: [[fallthrough]];`),
an attribute after an EMPTY parameter list of a definition (`int f() [[a]] { … }`), and arguments that are not
strings, commas or bracket groups of strings.

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
| the attribute `cerb::with_address`, anywhere, with any arguments (a parse stop: `error: unimplemented keyword '[[cerb::with_address]] (refused, contract D19: …)'`) | **a crash** (upstream's `TODO: cerb::with_address() is yet implemented`) for the one-argument form on a file-scope object or a block-scope `extern`; everywhere else the attribute was silently ignored and **the program ran**: those uses now stop too, a declared change of verdict |
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
- `cerb::with_address` never reaches you: the parser refuses an attribute of that name wherever it is written and
  whatever its arguments (it is an unimplemented upstream extension; upstream-tray report 99). Another namespace's
  `with_address`, and the bare name, are ordinary carried attributes.
  BOUNDARY, if you ever give the Lean engine a Cabs JSON of your own: The refusal is made by the C parser, so it covers C sources. A Cabs JSON that this parser did not produce (written by hand, or by another producer) can still carry the attribute to the Lean engine: there the one-argument form on an object that is allocated ends in the existing loud `UPSTREAM_CRASH` stop, attributed to upstream's file and lines (`memory/concrete/impl_mem.ml`), and the other forms are ignored as upstream ignores them. Closing that on the Lean import is optional and not done (TODO.md).
- A KNOWN HAZARD of carriage without meaning: an attribute that another compiler gives a layout meaning to is
  carried like any other and changes nothing here. `struct [[gnu::packed]] S { char c; int i; }` has the UNPACKED
  size and offsets (`sizeof` 8 where gcc gives 5), the same wrong layout that `#pragma pack` is refused for. The
  front end does not refuse it: reject the attributes you cannot honour.

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
