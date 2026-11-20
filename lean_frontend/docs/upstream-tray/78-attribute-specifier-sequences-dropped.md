# C23 attribute specifier sequences are accepted and dropped at 33 sites (19 in the parser, 14 in the desugarer)

**Affected:** `parsers/c/c_parser.mly` @ `c3ff8c53f`: the productions at :859, :861, :863, :865, :942, :966, :1039, :1043, :1056, :1058, :1082, :1103, :1121, :1122, :1166, :1194, :1197, :1219, :1220 write `ioption(attribute_specifier_sequence)` without naming the value; `balanced_token` (:1790-1793) returns `[]` for a nested group; `:852-855` builds a dummy declaration of an identifier `test` for `[[a]];` (its own `TODO: this is a dummy declaration`). `frontend/model/cabs_to_ail.lem`: `desugar_declaration_base` gives the leading attributes to typedefs, functions and external objects only (:3974, :3985, :4011; not :4013); the declarator-id attributes are bound to `_` for parameters (:2522), function definitions (:5121), block-scope declarators (`desugar_init_declarator_BROKEN`), for-init declarators (:4312), and not registered for typedefs (:3051, :3974) or file-scope function declarators (:5265-5268, a level-0 debug `WARNING: ... erasing some attributes!`); `:5208-5221` prints `TODO(attributes ignored)` for `struct [[a]] S;`; `:2070` lacks the check `:2051-2053` makes for a struct. `frontend/model/cabs_to_ail_effect.lem`: `register_external_object_declaration` (:2353-2412) stores the last declaration's attributes over the earlier ones, where `register_function_declaration` (:2264-2288) and `register_typedef` (:955) combine; and the block-scope `extern` redeclaration of a file-scope object with internal linkage replaces the file-scope entry with one that has no attributes.

## Description

C23 6.7.12.1 (clause numbers are those of draft N3096) says what an attribute appertains to at each placement. None of the dropped ones reaches Ail, so a tool that reads attributes from Ail (RefinedC's `rc::` annotations, CN-style contracts) silently gets nothing: a postcondition written after a function's parameter list, after its name, on a parameter, or on a local is not there. An attribute on an earlier declaration of an object is lost when a later declaration follows (`[[a]] extern int e; int e;`, the shape of an annotated global declared in a header). Three further effects: `cerb::byte`, which `register_typedef` reads, applies before a typedef declaration and not after the typedef's name, though both placements appertain to the name (a question as much as a report: was the after-name placement meant to be inert?); `[[fallthrough]];`, the standard's own attribute declaration, is rejected as a constraint violation at an unknown location; `union [[a]] U g;` is accepted where the same struct form is rejected.

## Reproducers

After the parameter list (the placement of `unsequenced`/`reproducible`):

```c
int f(int x) [[m::mk("s")]] { return x; } int main(void) { return f(0); }
```

Upstream: `--pp=ail --ast=ail` shows no `m::mk`. gcc: accepts.

`cerb::byte` after the typedef's name:

```c
typedef unsigned char byte [[cerb::byte]]; int main(void) { return _Generic((byte)0, unsigned char: 1, default: 0); }
```

Upstream: Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"} (with the attribute before `typedef`: Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}). gcc: accepts.

The attribute declaration:

```c
int main(void) { int x = 0; switch (x) { case 0: x = 1; [[fallthrough]]; case 1: x = x + 1; } return x - 2; }
```

Upstream: `unknown location  error: constraint violation: at least one type specifier should be given in the declaration`. gcc: 0.

A nested argument group:

```c
[[m::mk(("inner"))]] int g; int main(void) { return 0; }
```

Upstream: the Ail dump shows `m::mk()`. gcc: accepts.

(Measured 2026-11-20 with `cerberus --exec --batch` (`--nolibc` unless a reproducer includes a library header) on the un-forked upstream binary and runtime @ `c3ff8c53f`; gcc 13 `-std=gnu2x`. Found by the discarded-constructs census, `../2026-11-20_discarded-constructs-census.md`, row §1 (A1-A57, S5, S6); fork record `../2026-11-20_attribute-preservation-record.md`.)

## Fork status

Every attribute the grammar accepts is carried: to the Ail slot of the entity it appertains to where one exists (a function, an object with linkage, a typedef name, a tag definition, a member, a statement), otherwise to a new `sigma` field `carried_attributes` of triples (placement, declared identifier, attributes). `[[a]];` is a declaration form (an attributed null statement in a block). An object declared more than once keeps the attributes of every declaration. Nested argument groups and prefixed string literals are carried as their tokens joined by single spaces. The union and enum tag-reference forms stop as the struct form does. No attribute is given a meaning. 229 witness programs, `scripts/check_attribute_carriage.sh`.

## Patch

The fork's change is commit `3b7c0568e` (branch `fix/attribute-preservation`): `frontend/model/cabs.lem` (the slots), `annot.lem` (`attribute_placement`), `ail/ailSyntax.lem` (`carried_attributes`), `cabs_to_ail.lem`, `cabs_to_ail_effect.lem` (`carry_attributes`), `parsers/c/c_parser.mly` and `lexer_feedback.ml` (every production keeps its value; menhir's conflict counts are unchanged). The smallest part that removes the wrong answer is one line at each typedef registration: `E.register_typedef ident (Annot.combine_attributes attrs ident_attrs, qs, ty)`.
