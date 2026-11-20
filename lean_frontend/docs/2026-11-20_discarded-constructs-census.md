# Census: constructs the front end accepts and then discards (2026-11-20)

Worker [AGENT], slice `fix/attribute-preservation` (charter
`2026-11-20_worker-charter-attribute-preservation.md`, milestone M0). Documents only: no code changed at this commit.

## 0. What was measured, and how

- Tree: the charter commit `f0d2dae20` on base `dd0f52fe6` (both engines rebuilt from re-derived generated trees);
  pristine upstream `c3ff8c53f` (`deps/cerberus-upstream`); gcc 13.
- Each row was first established by READING (`parsers/c/c_parser.mly`, `parsers/c/c_lexer.mll`,
  `parsers/c/lexer_feedback.ml`, `frontend/model/cabs_to_ail.lem`, `cabs_to_ail_effect.lem`, `cabs_to_ail_aux.lem`,
  `desugaring_init.lem`, `ail/genTyping.lem`, `ail/ailTypesAux.lem`, `translation.lem`, `backend/lean_export/cabs_json.ml`,
  `lean_frontend/CabsImport.lean`) and then CONFIRMED by a one-file probe run through: the fork's OCaml engine
  (`--cabs-json`; `--pp=ail --ast=ail`; `--exec --batch --nolibc`), the Lean engine (`cerberus-lean --batch` on the
  exported JSON, `LEAN_ABORT_ON_PANIC=1`), pristine (`--pp=ail --ast=ail`; `--exec --batch --nolibc`) and
  `gcc -std=c2x` (attributes) or `-std=gnu2x` (the wider table). Two read-only search agents produced candidate lists for
  the wider category; every candidate in the tables below was re-probed by the worker, and a candidate that did not
  reproduce is not listed.
- The probes are the one-line programs quoted in the rows. In the attribute table `A` stands for `[[m::mk("s")]]` and
  "cabs / ail" is the number of occurrences of the marker in the fork's Cabs JSON and Ail dump; pristine's Ail count
  equalled the fork's in every row, and the Lean engine's execution verdict equalled the OCaml engine's in every row
  (the Lean engine has no Ail printer: its only dumps are `--pp-core` and the run verdict). The probe corpus is committed
  with the witness at M3; until then the rows are the record.
- Classes. **CARRIED**: the construct reaches Ail. **GIVEN-MEANING**: it changes what the model does.
  **REFUSED**: the run stops with a diagnostic (marked *misattributed* where the text blames something else, and
  *valid C* where the standard permits the form). **DISCARDED-SILENTLY**: accepted, absent downstream, no diagnostic
  on the default path. Outside the charter's four: **PARSE-ERROR** (the grammar does not accept the form: loud),
  **MISAPPLIED** (kept, but attached at the wrong level, silently) and **CRASH** (an internal error or uncaught
  exception: loud, not attributed).

## 1. Attributes

### 1.1 What exists downstream of the parser

- Cabs slots (`frontend/model/cabs.lem`): `Declaration_base` (:159), `TSpec_struct`/`TSpec_union` (:197-198),
  `Struct_declaration` (:210), `DDecl_identifier` (:242), `CabsStatement` (:330), `FunDef` (:358), and the magic-comment
  slot of `CabsEcall` (:58). No slot on: the specifier lists, `TSpec_enum`, enumerators, pointer/array/function
  declarator parts, parameter declarations, abstract declarators, type names.
- An attribute is `Annot.attribute = <| attr_ns; attr_id; attr_args: list (Loc.t * string * list (Loc.t * string)) |>`
  (`annot.lem:10-14`): arguments are string literals only.
- Ail slots (`ail/ailSyntax.lem`): `sigma.declarations` (functions and objects with linkage, :281), function
  definitions (:287), tag definitions (:293) and their members (`Ctype` member lists), statements (:236-241),
  `typedef_attributes` (:323), `loop_attributes` (:324), `Aattrs` annotations on expressions (`annot.lem:73`). No slot
  on: block-scope objects and parameters (`bindings`), enumerators, enum tags, a tag that is declared and never
  defined, a type occurrence.
- Ail typing keeps what the desugarer delivers (`genTyping.lem:2289` statements, `:2340-2354` function definitions,
  `:2403-2404` the two maps). The Core elaboration copies statement attributes onto the Core expression as an `Aattrs`
  annotation (`translation.lem:3852`, `core_aux.lem:2250-2257`) and declaration attributes into the function-info map
  (`translation.lem:4544`, `:4576`); the Core text printer shows neither.
- The Cabs JSON export writes every Cabs slot (`cabs_json.ml:195,295,396,402,425,495,612-629,636,661`) and
  `CabsImport.lean` reads each (`:345,464,468,490,562,646-670,702,777,786`): nothing is lost at the JSON boundary; what
  the parser's action drops never reaches it.
- Attributes the MODEL gives meaning to: `cerb::byte` on a typedef (`cabs_to_ail_effect.lem:919-930`, the typedef
  becomes the `Byte` type), `cerb::with_address` on an object declaration (`translation.lem:4462`; at run time upstream's
  `Failure("TODO: cerb::with_address() is yet implemented")`, a crash), `cerb::hidden` (printing), `cerb::magic` (CN).
  No standard attribute is given meaning.
- What prints: the OCaml engine's `--pp=ail --ast=ail` shows an `Attributes` node under declarations, function
  definitions, tag definitions, members and statements, and `AilTypedefAttributes`; attribute locations are not printed.

### 1.2 The grammar's 37 use sites, by production

`grep -c attribute_specifier parsers/c/c_parser.mly` counts 41 lines: 37 productions that USE
`attribute_specifier_sequence` (listed below by line) and the four lines of its own two rules (:1615-1623).
"appertains" is C23 6.7.12.1 and the grammar clause of the form.

| # | site | probe (in `int main(void) { return 0; }` unless shown) | appertains to | parser action | desugarer | cabs / ail | class |
|---|------|-------|---------------|---------------|-----------|-----------|-------|
| A1 | :846 declaration, leading; file-scope object | `A int g;` | each declared entity | kept (`Declaration_base`) | `:5296` into the declaration | 1 / 1 | CARRIED |
| A2 | :846; file-scope function declaration | `A int f(void);` | the function | kept | `:5276` | 1 / 1 | CARRIED |
| A3 | :846; block-scope automatic object | `{ A int y = 0; return y; }` | the object | kept | `desugar_declaration_base` gives `attrs` only to typedefs, functions and external objects (`:3974,:3985,:4011`); `:4013` has no slot | 1 / 0 | DISCARDED-SILENTLY |
| A4 | :846; block-scope static object | `{ A static int y = 0; … }` | the object | kept | as A3 | 1 / 0 | DISCARDED-SILENTLY |
| A5 | :846; block-scope `extern` object, block-scope function | `{ A extern int g; … }`, `{ A int f(void); … }` | the entity | kept | `:4011`, `:3985` | 1 / 1 | CARRIED |
| A6 | :846; `for`-init declaration | `for (A int i = 0; i < 1; i++) ;` | the object | kept | `:4301` passes `attrs` on, used for typedefs only; `:4339` no slot | 1 / 0 | DISCARDED-SILENTLY |
| A7 | :846; no declarator (the C23 grammar requires one after a leading sequence) | `A struct S { int m; };` | (not a C23 form; gcc accepts) | kept | not used when the declarator list is empty | 1 / 0 | DISCARDED-SILENTLY |
| A8 | :849 declaration, leading; typedef (file and block) | `A typedef int T;` | the typedef name | kept | `:3051`, `:3974` into `typedef_attributes` | 1 / 1 | CARRIED (GIVEN-MEANING for `cerb::byte`) |
| A9 | :852 attribute declaration, file and block scope | `A;`, `{ A; … }`, `[[fallthrough]];` | implementation-defined (6.7.12.1); `fallthrough` is the standard's own use | builds a dummy declaration of an identifier `test` with EMPTY specifiers and drops the attributes (`:853-855`, upstream's TODO) | `desugar_type_specifiers []` | 0 / 0; `unknown location error: constraint violation: at least one type specifier should be given in the declaration` | REFUSED (*valid C*, *misattributed*, no location) |
| A10 | :859 after a storage-class specifier | `static A int g;` | the type, when last in the sequence; gcc rejects mid-sequence | dropped (`ioption(…)` unnamed) | — | 0 / 0 | DISCARDED-SILENTLY |
| A11 | :861 after a type qualifier | `const A int g = 0;` | as A10 | dropped | — | 0 / 0 | DISCARDED-SILENTLY |
| A12 | :863 after a function specifier | `inline A int f(void) { return 0; }` | as A10 | dropped | — | 0 / 0 | DISCARDED-SILENTLY |
| A13 | :865 after an alignment specifier | `_Alignas(8) A int g;` | as A10 | dropped | — | 0 / 0 | DISCARDED-SILENTLY |
| A14 | :942 after a keyword type specifier (`int`, `unsigned`, …): object, return type, parameter, typedef | `int A g;`, `int A f(void) {…}`, `int f(int A x)`, `typedef int A T;`, `unsigned A int g;` | the type (6.7.3.1) | dropped | — | 0 / 0 | DISCARDED-SILENTLY |
| A15 | :966 after `void`, `_Bool`, a struct/union/enum specifier, a typedef name, `_Atomic(T)`, `typeof(…)` | `void A f(void) {}`, `struct S {int m;} A g;`, `T A g;`, `enum E {EA} A g;`, `_Atomic(int) A g;`, `typeof(h) A g;` | the type | dropped | — | 0 / 0 | DISCARDED-SILENTLY |
| A16 | :972 struct/union specifier with a member list | `struct A S { int m; };`, `union A U {…};`, `struct A { int m; } g;` | the type | kept (`TSpec_struct`/`TSpec_union`) | `:2086-2090` into the tag definition | 1 / 1 | CARRIED |
| A17 | :976 struct tag reference in a declaration | `struct S { int m; }; struct A S g;` | constraint violation (6.7.2.3; gcc rejects) | kept | `:2051-2053` `E.fail … Desugar_TODO "Attribute constraint violation ==> N2335 6.7.2.1#6 and 6.7.2.3#4"` | 1 / 0, `error: TODO: Attribute constraint violation …` | REFUSED |
| A18 | :976 union tag reference in a declaration | `union U { int m; }; union A U g;` | constraint violation (gcc rejects) | kept | `:2070` has no check | 1 / 0, `Specified(0)` | DISCARDED-SILENTLY |
| A19 | :976 forward declaration, file scope | `struct A S;`, `union A U;` | the type (permitted by C23) | kept | `:5208-5232`: struct prints `(debug 0): TODO(attributes ignored) -- TSpec_struct 3 => S` on the OCaml engine's stderr (a no-op in Lean); union nothing; a later definition does not receive it | 1 / 0 | DISCARDED-SILENTLY |
| A20 | :976 forward declaration, block scope | `{ struct A S; struct S { int m; }; … }` | the type (permitted) | kept | reaches `:2051-2053` | `error: TODO: Attribute constraint violation …` | REFUSED (*valid C*) |
| A21 | :979 empty struct (GNU) | `struct A S { };` | — | kept | `UB061_no_named_members` whatever the attribute | 1 / 0 | REFUSED |
| A22 | :1003 member declaration, leading | `struct S { A int m; };` (also a flexible array member, two declarators, a union member) | each member | kept (`Struct_declaration`) | `:3129` | 1 / 1 | CARRIED |
| A23 | :1003 leading, on a bit-field | `struct S { A int m : 3; };` | the member | kept | `feature not yet supported: bit-fields` | 1 / 0 | REFUSED |
| A24 | :942/:966 inside a specifier-qualifier list (:1014-1019): member | `struct S { int A m; };` | the type | dropped | — | 0 / 0 | DISCARDED-SILENTLY |
| A25 | :942/:966 inside a specifier-qualifier list: type name | `sizeof(int A)`, `(int A) 0`, `(int A){0}`, `_Alignof(int A)`, `_Generic(0, int A: 0, default: 1)`, `_Atomic(int A) g;`, `_Alignas(int A) int g;`, `va_arg(ap, int A)`, `offsetof(struct S A, m)`, `typeof(int A) g;` | the type | dropped | — | 0 / 0 | DISCARDED-SILENTLY |
| A26 | :1082 after a qualifier in a specifier-qualifier list | `struct S { const A int m; };` | as A10 | dropped | — | 0 / 0 | DISCARDED-SILENTLY |
| A27 | :1103 after an alignment specifier in a specifier-qualifier list | `struct S { _Alignas(8) A int m; };` | as A10 | dropped | — | 0 / 0 | DISCARDED-SILENTLY |
| A28 | :1039 enum specifier with an enumerator list | `enum A E { EA };`, `enum A { EA };` | the enumerated type | dropped (unnamed; `TSpec_enum` has no slot) | — | 0 / 0 | DISCARDED-SILENTLY |
| A29 | :1043 enum tag reference | `enum E { EA }; enum A E g;` | constraint violation (gcc rejects) | dropped | — | 0 / 0, `Specified(0)` | DISCARDED-SILENTLY |
| A30 | :1056 enumerator | `enum E { EA A, EB };` | the enumerator | dropped | — | 0 / 0 | DISCARDED-SILENTLY |
| A31 | :1058 enumerator with a value | `enum E { EA A = 1, EB };` | the enumerator | dropped | — | 0 / 0 | DISCARDED-SILENTLY |
| A32 | :1117 after the declarator-id; file-scope object (also with an initializer, `static`, `extern`, an array suffix, parentheses) | `int g A;` | the declared entity | kept (`DDecl_identifier`) | `:5296` `combine_attributes attrs ident_attrs` | 1 / 1 | CARRIED |
| A33 | :1117; file-scope function declaration | `int f A (void);` | the function | kept | `:5265-5268` prints `(debug 0): WARNING: desugaring of a function initdecl is erasing some attributes!` on the OCaml engine's stderr (a no-op in Lean) and registers `attrs` only | 1 / 0 | DISCARDED-SILENTLY |
| A34 | :1117; function definition | `int f A (void) { return 0; }` | the function | kept | `:5121` binds `(_, fun_ident)` | 1 / 0 | DISCARDED-SILENTLY |
| A35 | :1117; block-scope object (automatic, static, `extern`), block-scope function | `{ int y A = 0; … }` | the entity | kept | `desugar_init_declarator_BROKEN` (`:3003-3025`) returns no attributes | 1 / 0 | DISCARDED-SILENTLY |
| A36 | :1117; parameter (definition and prototype) | `int f(int x A) { return x; }` | the parameter | kept | `:2522` binds `(_, ident)` | 1 / 0 | DISCARDED-SILENTLY |
| A37 | :1117; typedef (file and block) | `typedef int T A;` | the typedef name | kept | `:3051`, `:3974` register `attrs` only | 1 / 0; with `cerb::byte` the program's answer changes (§1.5) | DISCARDED-SILENTLY |
| A38 | :1117; `for`-init declarator | `for (int i A = 0; …) ;` | the object | kept | `:4312` binds `_` | 1 / 0 | DISCARDED-SILENTLY |
| A39 | :1117; member | `struct S { int m A; };` | the member | kept | `:3129` | 1 / 1 | CARRIED |
| A40 | :1117; bit-field member | `struct S { int m A : 3; };` | the member | kept | `feature not yet supported: bit-fields` | 1 / 0 | REFUSED |
| A41 | :1121 after an array declarator (object, parameter, member) | `int g[3] A;` | the array type | dropped | — | 0 / 0 | DISCARDED-SILENTLY |
| A42 | :1122 after a function declarator (declaration, definition, function pointer, typedef) | `int f(void) A;`, `int f(void) A { return 0; }` | the function type (the placement of `unsequenced`/`reproducible`) | dropped | — | 0 / 0 | DISCARDED-SILENTLY |
| A43 | :1166 after `*` | `int * A g;`, `int * A const g = 0;`, `sizeof(int * A)` | the pointer type | dropped | — | 0 / 0 | DISCARDED-SILENTLY |
| A44 | :1194 parameter declaration, leading, named | `int f(A int x) { return x; }` | the parameter | dropped | — | 0 / 0 | DISCARDED-SILENTLY |
| A45 | :1197 parameter declaration, leading, abstract | `int f(A int);`, `int f(A void) {…}` | the parameter | dropped | — | 0 / 0 | DISCARDED-SILENTLY |
| A46 | :1219 after an abstract array declarator | `sizeof(int [3] A)`, `int f(int [3] A);` | the array type | dropped | — | 0 / 0 | DISCARDED-SILENTLY |
| A47 | :1220 after an abstract function declarator | `sizeof(int (*)(void) A)`, `int f(int (void) A);` | the function type | dropped | — | 0 / 0 | DISCARDED-SILENTLY |
| A48 | :1301 compound statement | `A { }` | the statement | kept (`inject_attr`) | `:4128` statement attributes | 1 / 1 | CARRIED |
| A49 | :1305 selection statement | `A if (1) ;`, `A switch (0) { default: ; }` | the statement | kept | `:4128` | 1 / 1 | CARRIED |
| A50 | :1306 iteration statement | `A while (0) ;`, `A do ; while (0);`, `A for (;0;) ;`, `A for (int i = 0; …) ;` | the statement | kept | `:4128` and `loop_attributes` (`:4241,:4273,:4304,:4403`); for the declaration form the attribute lands on the block that wraps the declaration and the loop (upstream's TODO `:4388`) | 1 / 1 | CARRIED |
| A51 | :1307 jump statement | `A goto l;`, `A continue;`, `A break;`, `A return 0;`, `A return;` | the statement | kept | `:4128` | 1 / 1 | CARRIED |
| A52 | :1315 label | `A l: return 0;` | the label | kept | `:4128` on the `AilSlabel` statement | 1 / 1 | CARRIED |
| A53 | :1320 case range (GNU) | `A case 0 ... 1:` | the label | kept | `:4128` | 1 / 1 | CARRIED |
| A54 | :1326 `case` | `A case 0:` | the label | kept | `:4128` | 1 / 1 | CARRIED |
| A55 | :1332 `default` | `A default:` | the label | kept | `:4128` | 1 / 1 | CARRIED |
| A56 | :1388 expression statement | `A x = 0;` | the statement | kept | `:4128` | 1 / 1 | CARRIED |
| A57 | :1583 function definition, leading | `A int f(void) { return 0; }` | the function | kept (`FunDef`) | `:5163` and `:5189` (declaration and definition) | 1 / 2 | CARRIED |

| A58 | (added 2026-11-20 on the pre-merge review's F2; not a grammar site) an object with linkage declared more than once | `A extern int e; int e;`, `A int e; A2 int e;`, `int e A = 1; int e;` | each declaration's attributes appertain to the object | kept | `register_external_object_declaration` (`cabs_to_ail_effect.lem:2353-2412`) stores the LAST declaration's attributes over the earlier ones (the function and typedef registrations combine) | 1 / 0 for the earlier declaration's | DISCARDED-SILENTLY |
| A59 | (added with A58, found by the re-audit the review asked for) a file-scope object with internal linkage redeclared `extern` in a block | `A static int e; int main(void) { extern int e; return e; }` | the object | kept | the block-scope redeclaration is registered as an internal object under the same symbol and replaces the file-scope entry, with `Annot.no_attributes`, in the union that builds `sigma.declarations` (`cabs_to_ail_effect.lem`, "Adding internals object with static or thread storage duration") | 1 / 0 | DISCARDED-SILENTLY |

(A9's site :852 is where `attribute_declaration` (:1611) is used; the two are one row. Clause numbers for C23 in this
document and in the code are those of ONE draft, N3096, where attributes are 6.7.12 and tags 6.7.2.3; they were not
checked against a copy of the standard on this box.)

**The first version of this table missed A58 and A59** (it was built from the grammar's use sites and the desugarer's
arms; these two are in the registration functions of the effect module). The pre-merge review found A58; the re-audit
of every `register_*`/`update_*` path that followed found A59 and nothing else: function declarations and typedef
redefinitions combine (`:2264-2288`, `:955`), a tag definition after a forward declaration keeps its own attributes
(the forward declaration's are row A19), an enum cannot be redeclared, a prototype and its definition each carry their
own parameter attributes, `update_external_object_type` keeps the entry's.

### 1.3 The attribute's own syntax (:1615-1797)

| # | form | probe | observed | class |
|---|------|-------|----------|-------|
| S1 | a list in one specifier | `[[m::mk("s"), m::mk2("t")]] int g;` | both in Cabs and Ail, in source order | CARRIED |
| S2 | repeated specifiers | `[[m::mk("s")]] [[m::mk2("t")]] int g;` | both, in source order | CARRIED |
| S3 | `ns::name`, a bare name, a keyword as a name (:1641-1734) | `[[m::mk]]`, `[[mk("s")]]`, `[[m::const("s")]]` | kept | CARRIED |
| S4 | string arguments, comma-separated and concatenated | `m::mk("s", "t")`, `m::mk("s" "t")` | kept, with the pieces and their locations | CARRIED |
| S5 | an encoding prefix on an argument string | `m::mk(L"s")` | arrives as `"s"`: `located_string_literal` (:1782-1786) drops the prefix | DISCARDED-SILENTLY |
| S6 | a nested balanced-token group in the arguments (:1790-1793 return `[]`) | `m::mk(("inner"))`, `m::mk(["inner"])`, `m::mk({"inner"})`, `m::mk("s" ("inner"))` | arrives as `m::mk()`, `m::mk()`, `m::mk()`, `m::mk("s")` | DISCARDED-SILENTLY |
| S7 | an argument token that is not a string or a bracket | `m::mk(1)`, `m::mk(inner)`, `m::mk("s", ("inner"), "t")` | `error: unexpected token after '(' …` | PARSE-ERROR |
| S8 | an empty argument clause, an empty list, an empty list element (all C23) | `m::mk()`, `[[]]`, `[[m::mk("s"),]]` | `error: unexpected token …` | PARSE-ERROR |
| S10 | (added on the review) an attribute declaration directly after a label (C23 permits it) | `case 0: [[fallthrough]]; case 1: …`, `lbl: [[a]];` | `error: unexpected token after ']' and before ';'` (only the form after another statement or at the start of a block is accepted) | PARSE-ERROR |
| S11 | (added on the review) an attribute after an EMPTY parameter list of a definition | `int f() [[a]] { return 0; }` | `error: unexpected token after ')' and before '[['` | PARSE-ERROR |
| S9 | GNU `__attribute__((…))` in any position | `__attribute__((unused)) int g;` | the lexer has no such keyword: `error: unexpected token after '__attribute__' …` | PARSE-ERROR |

### 1.4 The standard attributes

None is given a meaning; each is carried exactly where its placement is carried (§1.2) and lost where it is not.

| # | attribute | probe | observed | class |
|---|-----------|-------|----------|-------|
| T1 | `deprecated`, `deprecated("…")`, `__deprecated__`, `maybe_unused`, `nodiscard` at carried placements | `[[deprecated]] int g;`, `[[nodiscard]] int f(void) {…}` | in Cabs and Ail (block-scope `[[maybe_unused]] int y` is row A3) | CARRIED |
| T2 | `noreturn`, `_Noreturn` | `[[noreturn]] void f(void) { } int main(void) { f(); return 0; }` | carried; `Specified(0)` where the keyword `_Noreturn` gives `UB071_noreturn`: the undefined behaviour of 6.7.12.6 is not detected (an invalid program accepted) | CARRIED |
| T3 | `unsequenced`, `reproducible` (their standard placement is after the function declarator) | `int f(int x) [[unsequenced]] { return x; }` | row A42 | DISCARDED-SILENTLY |
| T4 | `fallthrough` | `case 0: x = 1; [[fallthrough]]; case 1: …` | row A9 | REFUSED (*valid C*, *misattributed*) |
| T5 | an attribute another compiler gives meaning to | `struct [[gnu::packed]] S { char c; int i; };` then `sizeof(struct S) == 5` | carried; no meaning (answers 0; gcc 1). Ignoring an unrecognised attribute is the standard's rule (6.7.12.1) | CARRIED |

### 1.5 The loss that changes a program's answer (reported to the orchestrator before this commit)

`[[cerb::byte]] typedef unsigned char byte; int main(void) { return _Generic((byte)0, unsigned char: 1, default: 0); }`
answers `Specified(0)`; with the attribute after the name, `typedef unsigned char byte [[cerb::byte]];` (row A37), it
answers `Specified(1)`, on the fork's OCaml engine, the Lean engine and pristine. The block-scope pair behaves the
same, and `byte y = 1;` is a constraint violation at the first placement and accepted at the second. Both placements
appertain to the typedef name. `cerb::with_address` has no working semantics to be wrong against: where it is kept
(leading, or after the name of a file-scope object) the run crashes with upstream's TODO; where it is dropped (after the
type; on a block-scope static object) the run proceeds unannotated.

### 1.6 Counts (derived from the tables above)

§1.2, 59 rows (57 in the first version; A58 and A59 added on the review): CARRIED 18 (A1, A2, A5, A8, A16, A22, A32,
A39, A48-A57), REFUSED 6 (A9, A17, A20, A21, A23, A40), DISCARDED-SILENTLY 35 (33 in the first version): in the parser
21 (A10-A15, A24-A31, A41-A47), in the desugarer 14 (A3, A4, A6, A7, A18, A19, A33-A38, A58, A59). §1.3, 11 rows:
CARRIED 4, DISCARDED-SILENTLY 2, PARSE-ERROR 5 (S7-S11). §1.4, 5 rows: CARRIED 3, DISCARDED-SILENTLY 1,
REFUSED 1 (T3 and T4 restate A42 and A9). Of the 37 use sites, 19 productions drop the value in their action (:859, :861, :863, :865, :942, :966, :1039,
:1043, :1056, :1058, :1082, :1103, :1121, :1122, :1166, :1194, :1197, :1219, :1220); they make 21 rows because :942 and
:966 are reached again through the specifier-qualifier list (A24, A25).

The consumer's ten programs (`[[rc::ensures("{False}")]]`, the count of `ensures` in the fork's Cabs JSON / Ail dump;
pristine's Ail identical): function declaration 1 / 2 (A57), return statement 1 / 1 (A51), after the parameter list
0 / 0 (A42), after the function name 1 / 0 (A34), after the return type 0 / 0 (A14), after a parameter name 1 / 0
(A36), on a parameter 0 / 0 (A44), after a local's type 0 / 0 (A14), after a local's name 1 / 0 (A35), before a local
declaration 1 / 0 (A3). gcc 13 `-std=c2x` accepts all ten.

## 2. The wider category

Verdict columns are `--exec --batch --nolibc` unless a row says libc; "all three" = the fork's OCaml engine, the Lean
engine and pristine. `gcc` is the exit status of the compiled program, or `rejects`.

### 2.1 Discarded silently

| # | construct | locus | probe | observed (all three) / gcc | what a program can observe | class |
|---|-----------|-------|-------|------------------------------|-----------------------------|-------|
| W1 | `#pragma` lines (and `_Pragma`, which the preprocessor turns into one) | `c_lexer.mll:497-498`: the rest of the line is skipped | `#pragma pack(1)` / `struct S { char c; int i; }; int main(void) { return sizeof(struct S); }` | `Specified(8)` / 5 | layout under `pack`; nothing for an unknown pragma, `STDC FP_CONTRACT`, `omp`. An unrecognised pragma is ignored by the standard's rule (C17 6.10.6#1) | DISCARDED-SILENTLY |
| W2 | the flags of a line marker (`# 1 "f.h" 1 3`) | `c_lexer.mll:487-496` | any `#include` | — | nothing (locations only) | DISCARDED-SILENTLY |
| W3 | the second operand of `__builtin_expect` | `runtime/libc/include/builtins.h:14`, a macro in the header every run force-includes | `int i = 0; (void)__builtin_expect(1, i++); return i;` | `Specified(0)` / 0 | nothing (gcc does not evaluate the hint either). The macro's own defect is row X1 | DISCARDED-SILENTLY |
| W4 | the identifier list of a function declarator that is not a definition | `lexer_feedback.ml:117-120`, `cabs_of_declarator` (:83-86) | `int f(a, b);` | `Specified(0)` / 0 | a constraint violation (C17 6.7.6.3#3) is accepted; the nested form `void g(int h(x));` is row C5 | DISCARDED-SILENTLY |
| W5 | the identifier list AND the declaration list of an old-style definition whose declarator is a pointer, array or parenthesised form | `lexer_feedback.ml:92-110` overwrite the declarator's sort, so `create_function_definition` takes its catch-all (:166-167) | `int g; int *f(a) int a; { g = a; return &g; } int main(void) { return *f(1); }` | `error: use of undeclared identifier 'a'` / 1 | a valid C17 program is rejected with a text that blames the body (the plain form `int f(a, b) int a; int b; {…}` gets the attributed `found K&R-style declaration (unsupported)`) | DISCARDED-SILENTLY |
| W6 | a declaration list after a prototype-style definition | `c_parser.mly:1591`, `lexer_feedback.ml:166-167` | `int f(void) int x; { return 0; } int main(void) { return f(); }` | `Specified(0)` / rejects | a form gcc rejects is accepted (the C17 function-definition syntax derives a declaration list after any declarator; the review could not name the constraint and neither can the worker) | DISCARDED-SILENTLY |
| W7 | an alignment specifier in a type name | `cabs_to_ail.lem:3320-3321` (upstream: `TODO: align_specs is ignored here`) | `char pad = 0; char *p = &(_Alignas(64) char){0}; char pad2 = 0; char *q = &(_Alignas(64) char){0}; return ((unsigned long)p % 64 != 0) + ((unsigned long)q % 64 != 0) + pad + pad2;` | `Specified(2)` / 0 | **a valid program's answer** (C17 6.7.5#2 permits the specifier in a compound literal's type name); in `sizeof`, `_Alignof`, a cast and `_Atomic( )` it is a constraint violation that is accepted (`_Alignof(_Alignas(16) int)` answers 4; gcc rejects) | DISCARDED-SILENTLY |
| W8 | an alignment specifier on a `for`-init declaration | `cabs_to_ail.lem:4301` (a boolean only), `:4339-4351` register `Nothing` | `char pad = 0; for (_Alignas(64) char c = 0; ; ) return ((unsigned long)&c % 64) != 0; return pad;` | `Specified(1)` / 0 | **a valid program's answer** (the block-scope, file-scope and member forms are honoured: `Specified(0)`) | DISCARDED-SILENTLY |
| W9 | an alignment specifier or an initializer on a block-scope typedef | `cabs_to_ail.lem:3972-3975` | `typedef int T = 3; T x = 0; return x;`, `typedef _Alignas(8) char U;` | `Specified(0)` / rejects | constraint violations accepted (the file-scope forms are diagnosed: `:3048`, `:3064`) | DISCARDED-SILENTLY |
| W10 | a function specifier on something that is not a function | `function_specifiers` is read only at `:3989,:5167,:5280` | `_Noreturn int x;`, `inline int x;`, `int f(inline int p)`, `typedef inline int T;` | `Specified(0)` / 0 (gcc warns) | a constraint violation (C17 6.7.4#2) accepted; `inline int main(void)` (6.7.4#4) likewise | DISCARDED-SILENTLY |
| W11 | a declaration that declares nothing | `:5245-5255` (file), `:4156-4162` (block) | `int;`, `static int;`, `{ const long; }`, `typedef int;` | `Specified(0)` / 0 (gcc warns) | a constraint violation (C17 6.7#2) accepted | DISCARDED-SILENTLY |
| W12 | `_Atomic` on a parameter, for the object the body sees | `cabs_to_ail.lem:2565` registers `ty` where `:2566-2568` returns `mk_ctype_atomic ty` | `int f(_Atomic int x) { typeof(x) y = 0; return _Generic(&y, _Atomic int *: 0, int *: 1, default: 2); } int main(void) { return f(0); }` | `Specified(1)` / 0 | **a valid program's answer** | DISCARDED-SILENTLY |
| W13 | parameter qualifiers and `register`, when the function has an earlier declaration | `ail/ailTypesAux.lem:949-952` (the composite parameter is `(no_qualifiers, ty, false)`) | `void f(const int x); void f(const int x) { x = 1; } int main(void) { f(1); return 0; }` | `Specified(0)` / rejects | a constraint violation accepted (without the earlier declaration: `expression is not assignable`); likewise `&y` of a `register` parameter | DISCARDED-SILENTLY |
| W14 | the qualifiers of a function type declared through a typedef, at block scope | `cabs_to_ail.lem:3978-3997` | `typedef int F(void); int main(void) { const F g; return 0; }` | `Specified(0)` / 0 | `UB066_qualified_function_specification` missed (the file-scope form reports it) | DISCARDED-SILENTLY |
| W15 | the encoding prefix of a string literal that initializes a character array | `cabs_to_ail.lem:3828` | `char s[] = L"ab"; int main(void) { return sizeof s; }` | `Specified(3)` / rejects | a constraint violation (C17 6.7.9#14) accepted | DISCARDED-SILENTLY |
| W16 | excess initializers and out-of-range array designators | `desugaring_init.lem:353-355`, `:501-505` | `int a[2] = {1, 2, 3};`, `int b[2] = {[5] = 1};`, `struct S s = {1, 2};` (one member) | `Specified(…)` as if absent / gcc warns, rejects the designator | a constraint violation (C17 6.7.9#2) accepted; the excess expression is not evaluated | DISCARDED-SILENTLY |
| W17 | the operand of `return` in a `_Noreturn` function | `translation.lem:4102-4103` emits the undefined behaviour before translating the operand | (libc) `int g(void) { exit(3); return 0; } _Noreturn int f(void) { return g(); } int main(void) { f(); return 0; }` | `Undefined {ub: "UB071_noreturn"}` (fork and pristine) / 3 | **a valid program's answer**: C17 6.7.4#8 makes it undefined only if the function returns to its caller | DISCARDED-SILENTLY |
| W18 | `const` on a compound literal, a parameter and a struct member, at run time | `translation.lem:2973-2977`, `:934-975`, `:4303`/`:4508` | `const int *p = &(const int){1}; *(int *)p = 2; return *p;` | `Specified(2)` / 2 | `UB064_modifying_const` missed (the plain local form reports it): an invalid program accepted | DISCARDED-SILENTLY |
| W19 | the return type's qualifiers in a function redeclaration | `cabs_to_ail_aux.lem:195` compares `ret_qs1` with itself | `int f(void); const int f(void) { return 0; }` | `Specified(0)` / 0 | nothing in C17 (6.7.6.3#5: the return type is the unqualified version) | DISCARDED-SILENTLY |
| W20 | a top-level magic comment that is not a CN declaration | `cabs_to_ail.lem:5357-5358`; the stored list is never read | `/*@ … @*/` | — | nothing (a comment) | DISCARDED-SILENTLY |

### 2.2 Misapplied (kept, attached at the wrong level, silently)

| # | construct | locus | probe | observed (all three) / gcc | class |
|---|-----------|-------|-------|------------------------------|-------|
| M1 | `_Atomic` as a specifier of a block-scope or parameter declaration whose declarator derives a pointer | `cabs_to_ail.lem:3966`, `:2567`, `:2588` wrap the type AFTER the declarator (file scope and members use `wrap_atomic`, `:3037`, `:3129`) | `int main(void) { _Atomic int *p = 0; return _Generic(p, _Atomic int *: 1, default: 0); }` | `Specified(0)` / 1 (the file-scope form answers 1) | MISAPPLIED (**a valid program's answer**) |
| M2 | type qualifiers inside the brackets of an array parameter of a function declaration | `cabs_to_ail.lem:2257-2260` with `ailTypesAux.lem:1280-1287`; upstream's commented code at `:2245-2256` has the other placement | `int f(int a[const 1]); int main(void) { return _Generic(f, int (*)(int * const): 1, int (*)(const int *): 2, default: 0); }` | `Specified(2)` / 1 | MISAPPLIED (**a valid program's answer**) |

### 2.3 The charter's named candidates that are NOT discarded, and the loud rows

| # | construct | probe | observed (all three) / gcc | class |
|---|-----------|-------|------------------------------|-------|
| G1 | `register` | `register int x = 0; int *p = &x;`; `register int a[2] = {0, 0}; return a[0];` | `constraint violation: address of lvalue declared with register storage-class specifier`; `UB022_register_array_decay` | GIVEN-MEANING |
| G2 | `restrict` | `int f(int * restrict p, int * restrict q) { *p = 1; *q = 2; return *p; }` called with one object; `int restrict x;` | `Specified(2)` / 2; `constraint violation: restrict requires a pointer` | CARRIED (in the type; the aliasing rule of 6.7.3.1 is not modelled, which C17 6.7.3#8 allows for a conforming program) |
| G3 | `volatile` | `volatile int g; int main(void) { g = 1; return g; }` | `Specified(1)` | CARRIED (no semantics beyond the qualifier) |
| G4 | `inline` on a function | `inline int f(void) { return 1; } int main(void) { return f(); }` | `Specified(1)` / link error | CARRIED (`Decl_function`'s flag; the constraints of 6.7.4#3 and the missing external definition are not checked) |
| G5 | `_Noreturn` on a function | `_Noreturn void f(void) { } int main(void) { f(); return 0; }` | `UB071_noreturn` | GIVEN-MEANING |
| G6 | `_Alignas` on a file-scope, block-scope (automatic, static) or member object, both forms | `char pad = 0; _Alignas(64) char a = 0; … ((unsigned long)&a % 64 != 0)`; `struct S { char c; _Alignas(16) char d; }` | `Specified(0)`; `sizeof` 32 / 32; a weaker alignment, a typedef, a parameter, a function: constraint violations | GIVEN-MEANING |
| G7 | bit-fields | `struct S { unsigned a : 3; };` | `feature not yet supported: bit-fields` | REFUSED |
| G8 | `static` in an array parameter, function declaration | `int f(int a[static 4]);` | `feature not yet supported: array parameter with the static keyword` | REFUSED |
| G9 | `static` or qualifiers in an array parameter of a function DEFINITION | `int f(int a[static 4]) { return a[0]; }`, `int f(int a[const 2]) {…}` | `constraint violation: type qualifiers or 'static' used in array declarator outside of function prototype` / gcc accepts | REFUSED (*valid C*, *misattributed*) |
| G10 | old-style definition, plain declarator | `int f(a, b) int a; int b; { return a + b; }` | `found K&R-style declaration (unsupported)` | REFUSED |
| G11 | `asm` statements and labels | `__asm__("nop");`, `int g __asm__("other");` | the D9 refusals (pristine: `Specified`) | REFUSED |
| G12 | designators | `int a[3] = { [2] = 5 };`, `{ .b = 5 }`, `{ .a[1] = 5, .b = 2 }`, a repeated designator | gcc's values | GIVEN-MEANING |
| G13 | `_Atomic`, specifier and qualifier, on a file-scope object or a pointer | `_Atomic int g;`, `_Atomic(int) g;`, `int * _Atomic p = &x;`; member access of an atomic struct | gcc's values; `UB042_access_atomic_structUnion_member` | GIVEN-MEANING |
| G14 | `_Thread_local` at file scope and block-scope `extern` | `_Thread_local int g = 3; int main(void) { return g; }` | `Specified(3)` | CARRIED (the duration reaches `Decl_object`; `translation.lem:4449` ignores it, unobservable in a single thread) |
| G15 | `typeof` | `typeof(x) y = x;`, `typeof(i++) y = 1; return i;`, `typeof` of a `const` object | gcc's values; the qualifier is kept (`expression is not assignable`) | GIVEN-MEANING |
| G16 | `auto`, block-scope `extern`, `_Static_assert` (file, block, member), statement expressions, extra semicolons | — | gcc's values; a failed assertion is a constraint violation; an extra semicolon gets `warning: found an extra semicolon …` on stderr | GIVEN-MEANING |
| C1 | block-scope `static _Thread_local` with an initializer | `static _Thread_local int y = 3;` | `internal error: TODO: desugar_declaration_base, Thread duration` / 3 | CRASH |
| C2 | block-scope `static _Thread_local` without an initializer (`cabs_to_ail.lem:4054-4056` registers no definition) | `static _Thread_local int x; return x;` | `Error {msg: "unresolved symbol: x at other_location(Driver.drive)"}` / 0 | REFUSED (*valid C*, *misattributed*) |
| C3 | `_Atomic` array or parameter pointer at block scope | `_Atomic int a[3];` in a function; `int f(_Atomic int *p) {…}` | `internal error: Ctyp.mk_ctype_atomic: called on an invalid inner type`; `internal error: can_advance: Step_error2 …` | CRASH |
| C4 | `_Atomic` array at file scope or as a member (`cabs_to_ail_aux.lem:173-186` wraps the array) | `_Atomic int a[3];`, `struct S { _Atomic int m[2]; };` | `constraint violation: invalid use of _Atomic`, `invalid operands to binary expression` / gcc accepts | REFUSED (*valid C*, *misattributed*) |
| C5 | an identifier list in a nested function declarator | `void g(int h(x));` | `internal error: AilTypesAux.adjust ==> FunctionNoParams` | CRASH |
| C6 | a composite array type on redeclaration (`cabs_to_ail_effect.lem:2381-2384`, upstream's `TODO: what about ty' ??`) | `int a[3]; extern int a[]; int main(void) { return sizeof a; }` | `constraint violation: invalid application of 'sizeof' to an incomplete type` / 12 | REFUSED (*valid C*, *misattributed*) |
| C7 | a `for`-init array of unknown size (`cabs_to_ail.lem:4345` binds the type before the initializer completes it) | `for (int a[] = {1, 2, 3}; ; ) return sizeof a + a[2];` | an uncaught exception (the Lean engine: `UPSTREAM_CRASH … sizeofIncompleteArray`) / 15 | CRASH |
| C8 | a `#pragma` on the last line of the file, or after other tokens on a line | `int main(void) { return 0; }` / `#pragma foo` (no final newline after cpp) | `error: unexpected end of file` | REFUSED (*valid C*, *misattributed*) |
| C9 | the GNU `?:` | `int x = 3; return x ?: 4;` | `unsupported: … TODO: elaboration of ?: operator` | CRASH (known; the roadmap's crash list) |
| P1 | forms the grammar does not accept | `enum E : unsigned char {…}`, `__extension__`, `__inline__`, `__restrict`, `__const`, `__typeof__`, `__alignof__`, `__int128`, `typeof_unqual`, `constexpr`, `bool`/`nullptr` as keywords, `_Static_assert(1)`, `{}`, a storage class in a compound literal, range and `name:` designators, `goto *p`, top-level `asm`, `_Alignof` of an expression | `error: unexpected token …` or an undeclared identifier | PARSE-ERROR |

Not in the declared configuration, read and not probed: bit-field widths under `--ignore_bitfields` (a debug flag,
`cabs_to_ail.lem:3141-3151`), `&&label` under `--permissive` (`translation.lem:3329-3331`; refused by default, measured),
`printf` erased under `__bmc_cerb__` (`runtime/libc/include/stdio.h:73-75`, the web back end only), `_Thread_local`
shared between cppmem threads (`translation.lem:4449`).

### 2.4 Adjacent finding (not a discard)

| # | defect | probe | observed (all three) / gcc |
|---|--------|-------|------------------------------|
| X1 | `runtime/libc/include/builtins.h:14` `#define __builtin_expect(EXP, C) ((long)EXP)`: the parameter is not parenthesised, so the cast binds to the first operand of the argument | `unsigned u = 4294967295u; return __builtin_expect(u + 1, 0) != 0;` | `Specified(1)` / 0 (**a valid program's answer**) |

### 2.5 Counts (derived)

§2.1: DISCARDED-SILENTLY 20 (W1-W20). By what a program can observe: a valid program's answer changes in 4 (W7 for
the compound literal, W8, W12, W17); a valid program is rejected with a misattributed text in 1 (W5); an invalid
program is accepted in 10 (W4, W6, W9, W10, W11, W13, W14, W15, W16, W18; W7's other contexts too); nothing is
observable in 5 (W1 for an unrecognised pragma — `pack` is the exception a layout depends on —, W2, W3, W19, W20).
§2.2: MISAPPLIED 2. §2.3, 26 rows: GIVEN-MEANING 7 (G1, G5, G6, G12, G13, G15, G16), CARRIED 4 (G2, G3, G4, G14),
REFUSED 9 (G7-G11, C2, C4, C6, C8), CRASH 5 (C1, C3, C5, C7, C9), PARSE-ERROR 1 (P1). §2.4: 1 adjacent defect (X1).

**W1 after the operator's ruling ([USER 2026-11-20]): `#pragma pack` is REFUSED**, in every form (`pack(n)`, `pack()`,
`pack(push, …)`, `pack(pop)`, `_Pragma("pack…")`), by a declared stop in the lexer, on both engines alike (the parse
stops; no Cabs JSON). The row therefore splits: `#pragma pack` moves from DISCARDED-SILENTLY to REFUSED; every other
pragma stays DISCARDED-SILENTLY as upstream's judgement under C17 6.10.6#1 (tray 85), including a pragma line inside
an attribute argument (`m::mk((` / `#pragma foo` / `"a"))` arrives as `( "a" )`; the second look's F5). Measured before
the refusal, over every corpus the lanes walk and the shipped libc (`grep -rlE '#\s*pragma\s+pack|_Pragma'` over
`tests/`, `lean_frontend/corpus`, `runtime/`, `deps/cn/tests`, libxml2 and the pKVM case study): `#pragma pack` occurs in
four gcc-torture programs, each present twice (`execute/` and `breakdown/`): `20131127-1.c`, `pr58570.c`,
`pr79737-1.c`, `pr79737-2.c`. Three are already `CERB_REJECT` rows of the non-gating sweep scoreboard (bit-fields,
asm); one, `tests/gcc-torture/breakdown/success/20131127-1.c`, is `MATCH VAL:Specified(0)` there and becomes a stop at
the next sweep (`tests/ci_sweep/results/torture_success.tsv:318`; a scoreboard with no baseline). The other `_Pragma`
uses (`tests/hacl-star/include/kremlin/internal/target.h`, libxml2's `python/libxml_wrap.h`) are `GCC diagnostic` and
`diag_suppress` pragmas, unaffected. None in the libc, the CN tests or the pKVM case study; no gated row moves.

## 3. Verdict

The attribute loss is an instance of a broader defect, and the defect has one shape: **the front end's syntax is wider
than its tree.** The grammar accepts a form, and the next representation has no place for part of it, so the part is
dropped at the hand-over without a diagnostic. It happens at three hand-overs:

1. **Parser action to Cabs.** The production names no value (`ioption(attribute_specifier_sequence)` at 19 of the 37
   sites; the nested balanced tokens; the K&R identifier and declaration lists; `#pragma`). The Cabs tree never sees it.
2. **Cabs to Ail.** The Cabs node carries the value and the desugarer's arm binds it to `_` or passes it to a callee
   that reads it on one path only (12 attribute rows; the alignment specifier of a type name and of a `for`-init
   declaration; `_Atomic` on a parameter's object; function specifiers on objects; empty declarations).
3. **Ail to Core.** The Ail node carries it and the elaboration does not read it (the operand of `return` under
   `_Noreturn`; `const` on three kinds of object).

Upstream marks many of these sites itself (`TODO: this is a dummy declaration`, `TODO: align_specs is ignored here`,
`TODO(attributes ignored)`, `WARNING: … erasing some attributes!`, `desugar_declaration_base` labelled `BROKEN`): they
are unfinished hand-overs, not readings of the standard.

Most losses are invisible to a C program: an attribute the model gives no meaning to, a hint, a comment. A further
group turns an invalid program into an accepted one (a missed constraint or a missed undefined behaviour). Six change
the answer of a valid program on all three engines, and were reported to the orchestrator as they were found: the
`cerb::byte` attribute after a typedef's name (§1.5), the alignment specifier of a compound literal (W7) and of a
`for`-init declaration (W8), `_Atomic` on a parameter (W12), the operand of `return` under `_Noreturn` (W17), and the
neighbouring MISAPPLIED pair (M1, M2); the macro defect X1 is a seventh wrong answer of another kind. For a consumer
that READS attributes, every attribute row is observable: a written contract that does not arrive is a contract of
`True`.

## 4. Decisions taken on the reports ([AGENT 2026-11-20], the orchestrator's, paraphrased; the worker's are marked)

- §1.5: the attributes after the declarator-id join the typedef registration at both sites (file and block scope),
  so `cerb::byte` applies at both placements; `cerb::with_address` is not implemented or altered, and where carriage
  newly delivers it to upstream's TODO crash the result is a declared refusal instead of a crash.
- A9: the attribute declaration is accepted and carried if the grammar change is small and conflict-neutral;
  otherwise the rejection is kept with a correct, located diagnostic and filed. A18 aligns with the struct form.
  S6: nested balanced tokens are carried whole.
- W8: fixed by mirroring the block-scope arm's alignment call (C17 6.8.5#3 makes it an ordinary declaration). W7:
  the compound literal is a declared refusal; the other type-name contexts get a constraint-violation diagnostic with
  the clause, or, if the arm cannot tell the contexts apart without a wide change, one refusal whose text names both.
- W17: fixed by elaborating the operand before the undefined behaviour, so it fires exactly when the function would
  return; a refusal is the fallback if that is not a small local change. W12: a declared refusal.
- M1 and M2: declared refusals as narrow as the arms allow (the plain `_Atomic int x;` object must keep working),
  filed with upstream's intended placement; not repaired.
- X1: fixed in this slice as its own commit, with the libc dumps and pins measured, a witness row, a tray report with
  the patch and a registered fork-ahead delta.
- Before any refusal is added, every gated corpus and the libc are measured for the form.
- [AGENT 2026-11-20, worker] The remaining DISCARDED-SILENTLY rows are closed in M2 by the charter's rule: W5 and W6
  join the existing K&R refusal; W1 is left as upstream's judgement and filed (C17 6.10.6#1), with `#pragma pack` named
  in the report as the case a consumer's layout depends on; W2, W3, W19, W20 lose nothing and are listed; the
  accepts-invalid rows (W4, W9, W10, W11, W13-W16, W18) and the loud rows of §2.3 are filed, not built.
