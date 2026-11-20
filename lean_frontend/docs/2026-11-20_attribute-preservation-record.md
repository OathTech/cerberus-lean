# Record: no parsed construct is silently discarded (2026-11-20)

Worker [AGENT], branch `fix/attribute-preservation`, base mainline `dd0f52fe6`. Charter
`2026-11-20_worker-charter-attribute-preservation.md`; census `2026-11-20_discarded-constructs-census.md` (M0).
Contract row D19. Commits: M0 `89f252dd5`, M1 `3b7c0568e`, M2 `4b260827c`, the forced header `ed7925183`, M3 this one.

## 0. Provenance and rulings

- [USER 2026-11-20], through the charter: establish whether the consumer's lost attributes are an instance of a
  broader category of defect, and repair the category if they are.
- The consumer refinedc-lean reported eight placements of a C23 attribute that silently lose it.
- [AGENT 2026-11-20, orchestrator], on the census's report-at-once rows (census §4, paraphrased): `cerb::byte` applies
  at both typedef placements and `cerb::with_address` is neither implemented nor altered (a newly delivered placement
  is refused); `[[a]];` is accepted and carried; the union form aligns with the struct form; nested argument tokens
  are carried whole; the `for`-init alignment and the `_Noreturn` return operand are FIXED; the compound-literal
  alignment, the `_Atomic` parameter and the two misapplied forms are REFUSED; the other type-name alignments are
  constraint violations; `__builtin_expect` is fixed as its own commit; corpora are measured before a refusal.
- [AGENT 2026-11-20, worker]: the carrier (§2), the refusal texts, the two parser stops for old-style lists, `#pragma`
  left as upstream's judgement and filed (C17 6.10.6#1), the accepts-invalid and loud rows filed and not built.

## 1. Verdict of the census

The attribute loss is an instance of a broader defect of one shape: the front end's syntax is wider than its tree.
A form is accepted and the next representation has no place for part of it. It happens at three hand-overs: parser
action to Cabs, Cabs to Ail, Ail to Core. Upstream marks many of the sites itself (`TODO`, `BROKEN`, `erasing some
attributes`). Counts, before: attributes 57 rows = CARRIED 18, REFUSED 6, DISCARDED-SILENTLY 33; wider category
DISCARDED-SILENTLY 20, MISAPPLIED 2.

## 2. M1: the attribute class

**The carrier** [AGENT 2026-11-20, worker]. An attribute goes to the Ail slot of the entity it appertains to (C23
6.7.12.1) where Ail has one: a function (declaration and definition), an object with linkage, a typedef name, a
struct or union definition, a member, a statement or label. Everything else is recorded in one new `sigma` field,

    carried_attributes : list (Annot.attribute_placement * maybe Symbol.identifier * Annot.attributes)

the placement it was written at, the identifier of the nearest declared entity (`Nothing`: a type name, an abstract
declarator, a declaration with no declarator, an attribute declaration), and the attributes with their own locations.
The charter's order of preference, case by case:

| placement | case | where it arrives |
|---|---|---|
| leading or after the declarator-id: function, file-scope or `extern` object, typedef name, member | exact slot | `declarations`, `function_definitions`, `typedef_attributes`, the member |
| leading or after the declarator-id: block-scope object, `for`-init object | (1) nearest declared entity, marked | `AP_declaration` / `AP_declarator_id` with the object's identifier |
| a parameter, leading or after its name | (1) | `AP_parameter` / `AP_declarator_id` with the parameter's identifier (`Nothing` for an abstract one) |
| in the declaration specifiers or specifier-qualifier list (the type's) | (1) | `AP_specifiers` with the declared identifier |
| after `*`, an array declarator, a function declarator (the types') | (1) | `AP_pointer` / `AP_array` / `AP_function` |
| after `enum` in a definition; after an enumeration constant | (1) | `AP_enum` (the tag), `AP_enumerator` |
| `struct [[a]] S;` (file and block scope) | (1) | `AP_tag_declaration` |
| a type name (`sizeof`, cast, compound literal, `_Generic`, `_Atomic( )`, `_Alignas( )`, `va_arg`, `offsetof`, `typeof`) | (1), no entity | the placement with `Nothing` |
| `[[a]];` in a block | exact slot | an attributed null statement, in its position |
| `[[a]];` at file scope | (1), no entity | `AP_attribute_declaration` |
| `[[a]] struct S {…};` (no declarator; not a C23 form) | (1), no entity | `AP_declaration` with `Nothing` |

Case (2), a new slot, is the one field; it is a record field of `sigma` beside upstream's `typedef_attributes` and
`loop_attributes` (side tables of the same kind), not a change to `bindings` or to `Decl_object`, which consumers
pattern-match. Ctype annotations were rejected as a carrier: they are lost at parameter adjustment and typedef
resolution. Case (3), refusal, was needed three times, none for a standard attribute in a placement the standard
permits:

- an attribute on a union or enum tag REFERENCE (`union [[a]] U g;`, `enum [[a]] E g;`): the struct arm's stop,
  `E.fail … Desugar_TODO "Attribute constraint violation ==> N2335 6.7.2.1#6 and 6.7.2.3#4"` (for the enum: `… ==> an
  enum specifier without an enumerator list takes no attribute specifier sequence (N2335 6.7.2.2, syntax)`);
- `cerb::with_address` after the name of a block-scope `extern` declaration, the one placement carriage newly
  delivers to upstream's `TODO: cerb::with_address() is yet implemented` crash: a declared refusal in its place;
- an attribute declaration as the first clause of a `for` statement.

**Arguments.** A nested balanced-token group and a prefixed string literal are one argument each, carried as their
source text with NO pieces (a plain string-literal argument always has at least one piece). Tokens that are neither a
string nor a bracket remain parse errors, as do `()`, `[[]]` and an empty list element.

**Meaning.** None is given. `cerb::byte`, which upstream's `register_typedef` reads, now sees the attributes after
the typedef's name too, so the two placements answer alike.

**Cabs and the JSON boundary.** New slots: `specifiers.specifier_attributes`; an attributes argument on
`Struct_declaration` (second: the specifier-qualifier list's), `Type_name`, `TSpec_enum`, each enumerator, `ADecl`,
`PDecl`, `Params`, `PDeclaration_decl`, `PDeclaration_abs_decl`; the form `Declaration_attribute`. JSON fields:
`specifier_attrs` on `Specifiers`, `Struct_declaration`, `Type_name`; `attrs` on `TSpec_enum`, `ADecl`, `PDecl`,
`Params`, the two parameter forms; a three-element enumerator `[id, attrs, value]`; the tag
`Declaration_attribute`. `CabsImport.lean` reads each fail-closed. The ten committed fixtures were regenerated: each
equals the committed one once the new fields are stripped.

**The parser's conflicts.** menhir on the grammar before and after: `Warning: one state has shift/reduce conflicts.`
`Warning: one state has reduce/reduce conflicts.` `Warning: one shift/reduce conflict was arbitrarily resolved.`
`Warning: 4 reduce/reduce conflicts were arbitrarily resolved.` — identical.

**The instrument.** `cabs_to_ail.lem` `show_attribute_carriage`: one line per attribute over every slot,
`<slot> <entity>: <ns>::<name>(<arguments>) @ <location>`. The oracle prints the lines after the Ail tree under
`--pp=ail --ast=ail` (`AilAttributeCarriage`, each line prefixed `attribute: `); the Lean driver prints them in its
staged (non-batch) output. One Lem definition, so the witness compares the engines as text.

## 3. The consumer's ten programs

What was run: refinedc-lean's `scripts/probes/discarded-contracts.py` drives its own CLI, which cannot be pointed at
this build. Its ten C programs (the same `CONTRACT` prefix and `[[rc::ensures("{False}")]]` at the ten placements) are
`tests/attribute_carriage/t01..t10`; each was run through this worktree's oracle (`--pp=ail --ast=ail --nolibc`) and
Lean engine (staged output on the exported Cabs JSON), and the `rc::ensures` line is quoted below (both engines print
the same line; the pins are in `expected.txt`). Before = the count of `ensures` in the fork's Cabs JSON / Ail dump at
`dd0f52fe6` (pristine's Ail count identical).

| placement | before | after: the line both engines print |
|---|---|---|
| function declaration | 1 / 2 | `function sample: rc::ensures("{False}")` and `definition sample: …` (unchanged) |
| return statement | 1 / 1 | `statement return: rc::ensures("{False}")` (unchanged) |
| after the parameter list | 0 / 0 | `carried function sample: rc::ensures("{False}")` |
| after the function name | 1 / 0 | `function sample: …` and `definition sample: …` (the function's own slot) |
| after the return type | 0 / 0 | `carried specifiers sample: …` |
| after a parameter name | 1 / 0 | `carried declarator-id x: …` |
| on a parameter | 0 / 0 | `carried parameter x: …` |
| after a local's type | 0 / 0 | `carried specifiers y: …` |
| after a local's name | 1 / 0 | `carried declarator-id y: …` |
| before a local declaration | 1 / 0 | `carried declaration y: …` |

No placement is refused. The consumer decides what each means; one that gives a meaning to an attribute must now read
`carried_attributes` (and the function slot receives the after-name placement).

## 4. M2: the rest of the category

| census row | disposition | where |
|---|---|---|
| W8 alignment on a `for`-init declaration | FIXED: the block-scope arm's computation | `cabs_to_ail.lem`, the `FC_decl` arm |
| W17 operand of `return` under `_Noreturn` | FIXED: elaborated before the UB071 (C17 6.7.4#8) | `translation.lem`, `AilSreturn` |
| W7 alignment in a type name | constraint violation (C17 6.7.5#2), `IllegalAlignas_type_name`; the compound literal REFUSED | `desugar_type_name`; the `CabsEcompound` arm |
| W12 `_Atomic` on a parameter of a definition | REFUSED | `desugar_parameter_declaration` |
| M1 `_Atomic` with a derived declarator, block scope and parameters | REFUSED (the block-scope array crash becomes this refusal) | `desugar_declaration_base`, both parameter arms |
| M2 qualifiers in array-parameter brackets, declarations | REFUSED | `desugar_array_declarator`, prototype arm |
| W5, W6 old-style lists dropped | stopped with upstream's `found K&R-style declaration (unsupported)` | `lexer_feedback.ml` |
| X1 `__builtin_expect` | FIXED, its own commit | `runtime/libc/include/builtins.h` |
| W1 `#pragma` | upstream's judgement (C17 6.10.6#1), filed (85) | — |
| W2, W3, W19, W20 | nothing observable is lost; listed | — |
| W4, W9, W10, W11, W13, W14, W15, W16, W18 | an invalid program accepted: filed (83, 86-93), not built | — |
| C1, C2, C6, C7 (loud) | filed (94-96), not built | — |

The refusal texts, whole (each is one line on both engines, `internal error: <text>` / `PANIC at …: <text>`; pinned in
`tests/attribute_carriage/expected.txt` and `tests/discarded_constructs/expected.txt`):

1. `Cabs_to_ail.desugar_declaration_base: refused - [[cerb::with_address]] after the declarator-id of the block-scope extern declaration of '<name>' (contract D19): the attribute appertains to the declared object (C23 6.7.12.1) and is now carried to its declaration, where upstream's elaboration reads it (translation.lem decode_with_address) and the run then dies in upstream's 'TODO: cerb::with_address() is yet implemented'; the fork neither implements nor alters cerb::with_address, so the placement is refused in place of that crash. Write the object without the attribute.`
2. `Cabs_to_ail.desugar_statement: refused - an attribute declaration ('[[...]];', C23 6.7.12.1) as the first clause of a for statement (contract D19): Ail has no statement to carry it on in that position and no standard attribute may be written there; move the attribute declaration before the for statement.`
3. `Cabs_to_ail.desugar_expression: refused - an alignment specifier in the type name of a compound literal (C17 6.7.5#2 permits it there; contract D19): upstream ignores it ('TODO: align_specs is ignored here', c3ff8c53f cabs_to_ail.lem :3321), so the unnamed object is created at its type's natural alignment and its address need not be a multiple of the requested one; Ail's compound literal has no alignment to carry. Declare a named object with the alignment specifier instead.`
4. `Cabs_to_ail.desugar_parameter_declaration: refused - the _Atomic type qualifier on parameter '<name>' of a function definition (contract D19): upstream registers the object the function body sees WITHOUT the qualifier (c3ff8c53f cabs_to_ail.lem :2565) while the function type carries it, so typeof, sizeof and & of the parameter see a non-atomic type. Write the parameter with the specifier form _Atomic(T).`
5. `Cabs_to_ail: refused - the _Atomic type qualifier in the specifiers of a block-scope or parameter declaration whose declarator is not a plain identifier ('<name>') (contract D19): upstream makes the WHOLE declared type atomic there (c3ff8c53f cabs_to_ail.lem :3966, :2567, :2588) where the qualifier belongs to the specified type (C17 6.7.3, 6.7.6): '_Atomic int *p' is a pointer to atomic int, which upstream types as an atomic pointer to int, and an array declarator ends in an internal error; its file-scope arm (wrap_atomic) has the other placement. Write the specifier form _Atomic(T), or a typedef of the atomic type.` (without the parenthesised name for an abstract parameter)
6. `Cabs_to_ail.desugar_array_declarator: refused - type qualifiers inside the brackets of an array parameter of a function declaration (C17 6.7.6.3#7: they qualify the POINTER the parameter is adjusted to; contract D19): upstream puts them on the element type ('int a[const 1]' becomes 'const int *a'; its own commented code at c3ff8c53f cabs_to_ail.lem :2245-2256 has the pointer placement). Write the parameter as a qualified pointer ('int * const a').`

**Measured before the refusals** (grep, then the lanes): over `tests/`, `lean_frontend/corpus`, the libc, `deps/cn/tests`,
libxml2 and the pKVM case study there is no qualifier-form `_Atomic` parameter or derived declarator (the corpora's
uses are plain objects, `_Atomic(T)` and a pointer's own qualifier, all unchanged), no qualifier in array-parameter
brackets (two error-expected definitions with `static`, an unchanged path), and one `_Alignas` compound literal, in an
ungated parity probe (`tests/parity-probes/uncertainty/T-misc/ag-04-alignas-typename-cl.c`, now refused). No baselined
row moved (§6). A known cost of refusal 4: `int f(_Atomic int x) { return x + 1; }` answered correctly by another path
and is now refused; no gated corpus has the form.

## 5. Counts by class, before and after (derived from the census tables and the witness)

| table | class | before | after |
|---|---|---|---|
| attributes, §1.2 (57 rows) | CARRIED | 18 | 51 (the 18, 31 of the 33 discarded rows, and A9 and A20, which were wrongly refused) |
| | REFUSED | 6 | 6 (A17, A18, A29: tag references, the last two formerly discarded; A21, A23, A40: unchanged upstream stops). Within A9 the `for`-init clause and within A35 `cerb::with_address` on a block-scope `extern` are refused sub-cases |
| | DISCARDED-SILENTLY | 33 | 0 |
| attribute syntax, §1.3 (9 rows) | CARRIED / DISCARDED / PARSE-ERROR | 4 / 2 / 3 | 6 / 0 / 3 |
| wider, §2.1 (20 rows) | DISCARDED-SILENTLY | 20 | 14: W1, W2, W3, W19, W20 (nothing observable or the standard's rule) and W4, W9, W10, W11, W13, W14, W15, W16, W18 (an invalid program accepted; filed) |
| | fixed | — | 2 (W8, W17) |
| | refused or diagnosed | — | 4 (W7, W12, W5, W6) |
| misapplied, §2.2 | MISAPPLIED | 2 | 0 (both refused) |
| adjacent, §2.4 | wrong value | 1 | 0 (fixed) |

Of the seven losses that changed a valid program's answer, none remains: three are fixed (`cerb::byte`'s placement,
W8, W17) and four stop with a declared refusal (W7 for the compound literal, W12, M1, M2); the adjacent wrong value
X1 is fixed.

## 6. Gates

Run by the worker in the worktree, both engines rebuilt from re-derived generated trees (`make clean-prelude-src
prelude-src lean-prelude-src` at the start; `prelude-src lean-prelude-src` after each Lem change). Lines are verbatim.
The orchestrator runs Tier A on M1 and the battery on the tip; `scripts/release.py` was not run by the worker.

- Builds: dune `exit=0`; `Build completed successfully (409 jobs).` under `-DwarningAsError=true` (M1 and M2 trees).
- Ladder row 1, `./scripts/test_unit.sh`, on the M1 tree and again on the tip tree (M2, the header fix and the
  witnesses wired; before the documents of this commit): `Total: 21 passed, 0 failed`, exit 0, including
  - `discard_witness(attribute_carriage): SELFTEST OK (5 plants)`
  - `discard_witness(attribute_carriage): OK — 64 programs on both engines (carried 52, exec 4, parse 2, refusal 2, stop 4); 35 negative-control rows differ from pristine`
  - `discard_witness(discarded_constructs): SELFTEST OK (5 plants)`
  - `discard_witness(discarded_constructs): OK — 45 programs on both engines (exec 23, parse 4, refusal 8, stop 6, ub 4); 22 negative-control rows differ from pristine`
  - `check_fork_drift: OK — layer 1: 105 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 37 differing generated files, all hash-pinned` (its selftest: 31 plants)
  - `check_failure_reach: OK (235 pure failure sites = the 235 register rows exactly` …
  - `cabs-import-test: all checks passed` (T7 nine imports, T8 eight refusals, `T9: 33 objects checked`)
- `./scripts/check_attribute_carriage.sh --full` (Tier B row 17), tip:
  `discard_witness(attribute_carriage): OK — 202 programs on both engines (carried 173, exec 4, parse 12, refusal 2, stop 10, ub 1); 96 negative-control rows differ from pristine`
- `./scripts/test_exec.sh --check-baseline` (row 2), tip: `Baseline check: 0 regression(s), 0 improvement(s)` `BASELINE OK`
- `./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage` (row 3), tip: the same two lines.
- `./scripts/test_libc_exec.sh` (row 5), tip: `SUMMARY: match=43 loc_only=2 diff=0` `ALL MATCH RECORDED BASELINE`, with
  `MATCH 044-noreturn-return-operand-exits: Defined {value: "Specified(3)", stdout: "", stderr: "", blocked: "false"}`
- `./scripts/test_parse.sh` (row 7), tip: `ALL PASSED`; `./scripts/test_parse.sh tests/ci` (M2 tree): `ALL PASSED`.
- `./scripts/test_golden.sh` (M1 tree): `Golden tests: 10 passed, 0 failed, 0 skipped`.
- `./scripts/libc_prep.sh`: rc 0 on the M2 tree and after the header fix (the libc dump pin did not move).
- Kernel replay: not owed (no proof module changed; `git diff --stat dd0f52fe6..HEAD` touches no `*_lemMeasureProofs.lean`
  and no seam). Not run by the worker: rows 4, 4b, 4c, 6, 8-15 of Tier A and Tier B.

## 7. What moved outside this repository's code

- Fork-ahead deltas (first kind), registered in `scripts/fork_drift_manifest.txt` by three dated NOTEs: [files] 96 ->
  105, layer 2 33 -> 37 differing generated files. Hand-written OCaml entering the delta: `lexer_feedback.ml(i)`,
  `c_parser_driver.ml`, `pp_cabs.ml`, `pp_errors.ml`, `runtime/libc/include/builtins.h`.
- No measure proof, no Core-quotation digest and no failure-reach row moved (the desugarer is outside the exec
  dependency closure: 235 = 235); no proof module changed, so no kernel replay was owed. The libc Core dump pin did
  not move.
- `tests/libc_exec/baseline.txt` gains one row (044). `--pp=ail --ast=ail` now ends with the carriage block and the
  Lean driver's staged output gains `attribute:` lines; no script read either.
- Tray: reports 78-96 (INDEX rows with CLASS and STATE).

## 8. Not done

- No attribute is given a meaning: `[[noreturn]]` on a function that returns is still not UB (the keyword is),
  `[[gnu::packed]]` changes no layout, `cerb::with_address` is still upstream's TODO.
- Attribute arguments that are not strings or brackets (`m::mk(1)`), `()`, `[[]]`, and GNU `__attribute__` are parse
  errors, as before: loud, not carried.
- The statements inside a GNU statement expression are not walked by the instrument (their attributes are in Ail).
- Order: the leading attributes of a function DEFINITION arrive in reverse source order (upstream's
  `create_function_definition`), unchanged; the after-name ones follow them.
- The accepts-invalid rows, the loud misattributed rows (`static`/qualifiers in a definition's array parameter, a
  file-scope `_Atomic` array, the composite array type, block-scope `static _Thread_local`) and `#pragma pack` are
  filed, not changed. `<stdatomic.h>`'s `atomic_init` has the macro slip X1 had; reported in tray 84, not changed.
- The consumer's CLI was not run (§3 says what was run instead).
