# Record: no parsed construct is silently discarded (2026-11-20)

Worker [AGENT], branch `fix/attribute-preservation`, base mainline `dd0f52fe6`. Charter
`2026-11-20_worker-charter-attribute-preservation.md`; census `2026-11-20_discarded-constructs-census.md` (M0).
Contract row D19. Commits: M0 `89f252dd5`, M1 `3b7c0568e`, M2 `4b260827c`, the forced header `ed7925183`, M3 `98648dbdd`;
the pre-merge review `ea1f726e1` (`2026-11-20_attribute-preservation-premerge-review.md`, verdict: not ready to merge) and
its fixes, §9. Sections 1-8 are corrected in place where the review showed them wrong; §9 says what was wrong.

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
- `cerb::with_address` where carriage newly delivers it to upstream's `TODO: cerb::with_address() is yet implemented`
  crash: after the name of a block-scope `extern` declaration, and on a declaration of an object that a later
  declaration without it follows. A declared refusal in its place, each time;
- an attribute declaration as the first clause of a `for` statement.

**Arguments.** A nested balanced-token group and a prefixed string literal are one argument each, carried as their
TOKENS joined by single spaces, with NO pieces (a plain string-literal argument always has at least one piece):
`m::mk(( "a"` … twelve blank lines … `"b" ))` and `m::mk(("a" /* c */ "b"))` both arrive as `( "a" "b" )`. The tokens
are those the parser read, so they are the tokens AFTER macro expansion (`m::mk(GRP)` with `#define GRP (STR STR)`
arrives as `( "s" "s" )`); comments, cpp line markers and layout are not carried; a string literal is exact, prefix and
escapes included. The grammar inside an argument is narrow and unchanged: string literals, commas between them, and
bracket groups of the same; `m::mk("a", ("b"))`, `m::mk(( ))`, a token that is neither a string nor a bracket, `()`,
`[[]]` and an empty list element are parse errors. So are two C23 placements the grammar does not accept: an attribute
declaration directly after a label (`case 0: [[fallthrough]];`) and an attribute after an empty parameter list of a
definition (`int f() [[a]] { … }`).

**Redeclarations.** An entity declared more than once keeps the attributes of every declaration: functions and typedef
names did (upstream combines), objects with linkage now do (the review's F2: `[[a]] extern int e; int e;` had lost `a`),
including a file-scope object with internal linkage redeclared `extern` in a block. A tag's forward declaration and its
definition each keep their own (the table and the tag definition).

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

1. `Cabs_to_ail.desugar_declaration_base: refused - [[cerb::with_address]] after the declarator-id of the block-scope extern declaration of '<name>' (contract D19): the attribute appertains to the declared object (C23 6.7.12.1 in draft N3096) and is now carried to its declaration, where upstream's elaboration reads it (translation.lem decode_with_address) and the run then dies in upstream's 'TODO: cerb::with_address() is yet implemented'; the fork neither implements nor alters cerb::with_address, so the placement is refused in place of that crash. Write the object without the attribute.`
2. `Cabs_to_ail.desugar_statement: refused - an attribute declaration ('[[...]];', C23 6.7.12.1 in draft N3096) as the first clause of a for statement (contract D19): Ail has no statement to carry it on in that position and no standard attribute may be written there; move the attribute declaration before the for statement.`
3. `Cabs_to_ail.desugar_expression: refused - an alignment specifier in the type name of a compound literal (C17 6.7.5#2 permits it there; contract D19): upstream ignores it ('TODO: align_specs is ignored here', c3ff8c53f cabs_to_ail.lem :3321), so the unnamed object is created at its type's natural alignment and its address need not be a multiple of the requested one; Ail's compound literal has no alignment to carry. Declare a named object with the alignment specifier instead.`
4. `Cabs_to_ail.desugar_parameter_declaration: refused - the _Atomic type qualifier on parameter '<name>' of a function definition (contract D19): upstream registers the object the function body sees WITHOUT the qualifier (c3ff8c53f cabs_to_ail.lem :2565) while the function type carries it, so typeof, sizeof and & of the parameter see a non-atomic type. Write the parameter with the specifier form _Atomic(T).`
5. `Cabs_to_ail: refused - the _Atomic type qualifier in the specifiers of a block-scope or parameter declaration whose declarator is not a plain identifier ('<name>') (contract D19): upstream makes the WHOLE declared type atomic there (c3ff8c53f cabs_to_ail.lem :3966, :2567, :2588) where the qualifier belongs to the specified type (C17 6.7.3, 6.7.6): '_Atomic int *p' is a pointer to atomic int, which upstream types as an atomic pointer to int, and an array declarator ends in an internal error; its file-scope arm (wrap_atomic) has the other placement. Write the specifier form _Atomic(T), or a typedef of the atomic type.` (without the parenthesised name for an abstract parameter)
6. `Cabs_to_ail.desugar_array_declarator: refused - type qualifiers inside the brackets of an array parameter of a function declaration (C17 6.7.6.3#7: they qualify the POINTER the parameter is adjusted to; contract D19): upstream puts them on the element type ('int a[const 1]' becomes 'const int *a'; its own commented code at c3ff8c53f cabs_to_ail.lem :2245-2256 has the pointer placement). Write the parameter as a qualified pointer ('int * const a').`

7. `Cabs_to_ail_effect.register_external_object_declaration: refused - [[cerb::with_address]] on a declaration of '<name>' that a later declaration without the attribute follows (contract D19): the attributes of every declaration of an object are now kept (upstream kept the last declaration's only and the object ran unannotated), which would deliver this one to upstream's 'TODO: cerb::with_address() is yet implemented' crash; the fork neither implements nor alters cerb::with_address, so the redeclaration is refused in place of that crash. Write the object without the attribute.`

What each refusal replaced on pristine (measured; the review's F4): a silently WRONG answer for 3, 4 when the body
inspects the parameter's type, 5 for a pointer declarator, and 6 for `const`; a CRASH for 5 with an array declarator; a
silent IGNORE for 1 and 7; an already LOUD stop for 2 (pristine's unlocated constraint violation), for 6 with
`restrict` (`restrict requires a pointer`) and with `volatile` against a pointer definition (`multiple declarations …
incompatible types`); and a CORRECT answer for 4 when the body does not inspect the type
(`int f(_Atomic int x) { return x + 1; }`, pristine `Specified(0)`, now refused: the arm cannot see the body).

**Measured before the refusals** (grep, then the lanes): over `tests/`, `lean_frontend/corpus`, the libc, `deps/cn/tests`,
libxml2 and the pKVM case study there is no qualifier-form `_Atomic` parameter or derived declarator (the corpora's
uses are plain objects, `_Atomic(T)` and a pointer's own qualifier, all unchanged), no qualifier in array-parameter
brackets (two error-expected definitions with `static`, an unchanged path), and one `_Alignas` compound literal, in an
ungated parity probe (`tests/parity-probes/uncertainty/T-misc/ag-04-alignas-typename-cl.c`, now refused). No row of a
fork-versus-Lean baseline moved; `tests/libc_exec/baseline.txt` GAINED row 044, and the pristine-oracle register
`scripts/upstream_oracle_differences.json` gained its row (class `shared-model-fix`: pristine answers
`Undefined {ub: "UB071_noreturn", stderr: "", loc: "<8:25--8:36>"}` where the fork answers `Specified(3)`). The first
version of this record omitted the register and Tier B row 10 was red on `98648dbdd` (the review's F1). The review's
sweep of 8,078 files found four moved rows outside the gated baselines: the parity probe above, two gcc-torture
old-style programs that were parse errors on pristine too (`execute/950221-1.c`, `execute/920922-1.c`), and
`tests/suite/parsing/attributes.c`, rejected at the same place without upstream's two debug lines. A known cost of refusal 4: `int f(_Atomic int x) { return x + 1; }` answered correctly by another path
and is now refused; no gated corpus has the form.

## 5. Counts by class, before and after (derived from the census tables and the witness)

| table | class | before | after |
|---|---|---|---|
| attributes, §1.2 (59 rows: 57, and A58, A59 added on the review) | CARRIED | 18 | 53 (the 18, 33 of the 35 discarded rows, and A9 and A20, which were wrongly refused) |
| | REFUSED | 6 | 6 (A17, A18, A29: tag references, the last two formerly discarded; A21, A23, A40: unchanged upstream stops). Within A9 the `for`-init clause and within A35 `cerb::with_address` on a block-scope `extern` are refused sub-cases |
| | DISCARDED-SILENTLY | 35 (the first version said 33: it had missed A58 and A59) | 0 on the tip after the review's fixes; at `98648dbdd` it was 2, not the 0 this record claimed |
| attribute syntax, §1.3 (11 rows) | CARRIED / DISCARDED / PARSE-ERROR | 4 / 2 / 5 | 6 / 0 / 5 |
| wider, §2.1 (20 rows) | DISCARDED-SILENTLY | 20 | 14: W1, W2, W3, W19, W20 (nothing observable or the standard's rule) and W4, W9, W10, W11, W13, W14, W15, W16, W18 (an invalid program accepted; filed) |
| | fixed | — | 2 (W8, W17) |
| | refused or diagnosed | — | 4 (W7, W12, W5, W6) |
| misapplied, §2.2 | MISAPPLIED | 2 | 0 (both refused) |
| adjacent, §2.4 | wrong value | 1 | 0 (fixed) |

Of the seven losses that changed a valid program's answer, none remains: three are fixed (`cerb::byte`'s placement,
W8, W17) and four stop with a declared refusal (W7 for the compound literal, W12, M1, M2); the adjacent wrong value
X1 is fixed.

## 6. Gates

All run by the worker in the worktree on the FINAL tree of the branch (the review fixes and the 14-line header, §9)
unless a line says otherwise; both engines rebuilt from re-derived generated trees after every Lem change (dune exit
0; `Build completed successfully (409 jobs).` under `-DwarningAsError=true`). Lines are verbatim.
`scripts/release.py` was not run by the worker in any form; the orchestrator gates the tip.

- Ladder row 1, `./scripts/test_unit.sh`: exit 0, `Total: 21 passed, 0 failed`, including
  - `check_fork_drift: OK — layer 1: 106 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 37 differing generated files, all hash-pinned`
  - `discard_witness(attribute_carriage): SELFTEST OK (6 plants ran and were caught; 0 skipped: none)`
  - `discard_witness(attribute_carriage): OK — 77 programs on both engines (carried 62, exec 4, parse 4, refusal 3, stop 4); 53 negative-control rows differ from pristine`
  - `discard_witness(discarded_constructs): SELFTEST OK (3 plants ran and were caught; 3 skipped: lean-drops-carried, oracle-drops-carried, args-truncated)`
  - `discard_witness(discarded_constructs): OK — 48 programs on both engines (exec 23, parse 4, refusal 10, stop 7, ub 4); 25 negative-control rows differ from pristine`
- `./scripts/check_attribute_carriage.sh --full` (Tier B row 17): `discard_witness(attribute_carriage): OK — 229 programs on both engines (carried 197, exec 4, parse 14, refusal 3, stop 10, ub 1); 128 negative-control rows differ from pristine`
- `python3 scripts/test_upstream_oracle.py` (Tier B row 10, the default selection): `Independent oracle scope: tier-b; 1002 rows in 186.8s; source unchanged: True` / `Independent oracle: passed; {'semantic_agreement': 932, 'reviewed_difference': 43, 'matching_failure': 25, 'interface_agreement': 2}`
- `./scripts/test_unit.sh --core-quote-libc` (Tier B row 13): `Total: 2 passed, 0 failed` (both SHA-256 pins unchanged; `LibcLiteral leanchecker: … exit 0`, `LinkedLiteral leanchecker: … exit 0`, `LinkedRichLiteral leanchecker: … exit 0`). On the tree with the 17-line header it was RED: `RuntimeError: libc literal SHA-256 drift: c5b66c2f…, pinned 0a845b19…` (§9).
- `./scripts/test_libc_exec.sh` (row 5): `SUMMARY: match=43 loc_only=2 diff=0` `ALL MATCH RECORDED BASELINE`
- `./scripts/test_exec.sh --check-baseline` (row 2): `Baseline check: 0 regression(s), 0 improvement(s)` `BASELINE OK`
- `./scripts/test_inner_arg_temps.sh --rows 'libc/'`: `SUMMARY: inner_arg_temps rows=45 AGREE=2 AGREE-FIRST=40 BOTH_FAIL=1 LOC_ONLY-FIRST=2 failures=0`
- The ten committed Cabs fixtures equal a fresh export byte for byte.

Tier A and Tier B rows run by hand on the review-fix tree `61e79a887` plus the `inner_arg_temps` baseline row (before
the header went back to 14 lines; the header change is comments only, and the rows it can reach were re-run above):

- Tier A 4, `test_exec.sh` debug baseline: rc=0; last line `BASELINE OK`
- Tier A 4b, float baseline: rc=0; last line `BASELINE OK`
- Tier A 4c, `test_bytes.sh`: rc=0; last line `ALL AT COMMITTED EXPECTEDS`
- Tier A 6, `test_multi_tu.sh`: rc=0; last line `ALL PASSED`
- Tier A 6b, the multi-TU tray: rc=0; last line `ALL PASSED`
- Tier A 8, `test_core.sh`: rc=0; last line `ALL PASSED`
- Tier A 9, `test_elab.sh`: rc=0; last line `SUMMARY: total=113 same=108 diff=5 ocaml_fail=0 lean_fail=0`
- Tier A 10, `test_libxml2_uri.sh`: rc=0; last line `GATE PASS: all lane expectations pinned-green + baseline unchanged (16/16)`
- Tier A 11, `test_cn_coverage.sh --check-baseline`: rc=0; last line `BASELINE OK (213 entries, exact match)`
- Tier A 15, `test_inner_arg_temps.sh --gate` (with the new baseline row): rc=0; last line `inner_arg_temps elapsed: 361.39s`
- Tier B 1, `test_libxml2.sh`: rc=0; last line `ALL PASSED`
- Tier B 2, `test_parse.sh tests/ci`: rc=0; last line `ALL PASSED`
- Tier B 3, `test_core.sh tests/ci`: rc=0; last line `ALL PASSED`
- Tier B 4, `test_verify.sh`: rc=0; last line `test_verify: 127 passed, 0 failed (25 fixtures, 28 call points, 14 corpus fixtures, 21 corpus points)`
- Tier B 5, `test_immaculate.sh`: rc=0; last line `OK: lane matches the committed baseline (MATCH except the ISO-fix register pin R5 r5-hex-subnormal-double-rounding DIFF — VALIDATION.md 'ISO-fix regis`
- Tier B 7, `test_gcc_oracle.sh --check-baseline`: rc=0; last line `gcc second-oracle lane OK`
- Tier B 9, `test_observation_lanes.py`: rc=0; last line `observation lane plants: 95/95 passed`
- Tier B 12, the pristine lane's chvalid row: rc=0; last line `Independent oracle: passed; {'semantic_agreement': 4}`
- Tier B 14, `libc_prep.sh --selftest`: rc=0; last line `libc_prep: census selftest plant 'count' caught (libc_inner_arg_temps)`
- Tier B 15, `check_printf_refusals.sh --full`: rc=0; last line `check_printf_refusals: OK (full, Tier B row 15: 161 programs, libc mode but for the 4 nolibc controls: 104 VALUE rows with both engines' batch lines e`
- Tier B 16, `check_macro_type_ranks.sh --full`: rc=0; last line `check_macro_type_ranks: OK (--full, Tier B: every program: 126 programs: 104 batch lines of both engines = gcc 13's pinned line, exit codes equal — th`
- Tier B 13 on that tree: rc=1, RED (the drift above); green on the final tree. Tier B 11 (`check_failure_reach.sh`) runs inside row 1.

Not run, and why they cannot be affected: Tier A 12 (`test_address_space.sh`), 13 (`test_memory_access.py`) and 14
(`test_pnvi.sh`) were not run by the worker — they walk `tests/minimal`, the PNVI litmus files and memory probes, none
of which contains a form this branch changes (no attribute outside the forced header's `cerb::hidden`, no `_Atomic`
qualifier form, no alignment specifier in a `for`-init or type name, no `_Noreturn` return operand: the review's sweep
of 8,078 files found the four moved rows of §4 and none in these corpora), and they are left to the orchestrator's
battery. Tier B 6 (the spec-lab gates) and 8 (the four harness plant batteries) exercise the harness's own
classifications on generated harness programs and planted failures, with no source file of this branch's forms.
Tier C was not run.

Kernel replay: not owed (no proof module changed: `git diff --name-only dd0f52fe6..HEAD` touches no
`*_lemMeasureProofs.lean` and no seam); Tier B row 13's three `leanchecker` replays of the quotation literals exit 0.

## 7. What moved outside this repository's code

- Fork-ahead deltas (first kind), registered in `scripts/fork_drift_manifest.txt` by three dated NOTEs: [files] 96 ->
  106, layer 2 33 -> 37 differing generated files (five dated NOTEs). Hand-written OCaml entering the delta:
  `lexer_feedback.ml(i)`, `c_parser_driver.ml`, `pp_cabs.ml`, `pp_errors.ml`, `pp_ast.ml`, and the header
  `runtime/libc/include/builtins.h`.
- No measure proof and no failure-reach row moved (the desugarer is outside the exec dependency closure: 235 = 235);
  no proof module changed, so no kernel replay was owed. The libc Core text dump's pin did not move. The libc
  Core-QUOTATION pins do not move on the tip, but they DID move at `ed7925183`, and the first version of this record
  denied it: see §9.
- `tests/libc_exec/baseline.txt` gains one row (044), and with it `scripts/upstream_oracle_differences.json` (the
  pristine-oracle register, class `shared-model-fix`) and `tests/inner_arg_temps/baseline.json` (Tier A row 15) one
  row each. `--pp=ail --ast=ail` now ends with the carriage block and the
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
- The entries of `carried_attributes` are in the desugarer's recording order, which is not source order in general
  (`for ([[a]] int i [[b]] = 0, * [[c]] p = 0; …)` gives `declaration i`, `declarator-id i`, `pointer p`,
  `declaration p`); the comment on the field in `ail/ailSyntax.lem` still says "in source order" and is to be corrected
  at the next change to that file (the review's design note; a comment-only Lem edit re-opens every gate).
- `#pragma pack` is unchanged and waits for the operator's ruling; the review's §4.8 argues for a declared refusal of
  `pack` alone, with its measured cost.
- Upstream's under-array test rejects the valid `int f(int a[const 2][3]);` (pristine and fork alike); seen while
  fixing the review's nested-bracket note, not changed; reported in tray 82.

## 9. The pre-merge review and what it showed wrong

`2026-11-20_attribute-preservation-premerge-review.md` (`ea1f726e1`): not ready to merge, two blocking findings. Both
were failures of this slice, not of its instruments; the dispositions are appended to the review file. What was wrong
in the work as first reported, in order of seriousness:

1. **A silent attribute loss remained while this record said "33 -> 0" (F2).** An object with linkage declared more
   than once kept only the last declaration's attributes. The census had been built from the grammar's use sites and
   the desugarer's arms and never read the registration functions of the effect module. Fixed by combining; the
   re-audit of every registration path found a second overwrite (a file-scope object with internal linkage redeclared
   `extern` in a block) and no other. The census has rows A58 and A59; the true count was 35, and 2 remained at
   `98648dbdd`.
2. **A red gate on the tip (F1), and a second one the review did not reach.** The new libc witness needed a row in
   the pristine-oracle register (Tier B row 10) and in the `inner_arg_temps` baseline (Tier A row 15). Neither lane
   had been run. Both rows are added and both lanes are green.
3. **A third red gate, found by the worker when it ran the remaining Tier B rows: the libc Core-quotation pins
   (Tier B row 13) had drifted since `ed7925183`.** That commit added three comment lines to the force-included
   header, which moved the lexing line of every position in every translation unit by three; the quotation literals
   embed positions. Its commit message and this record's §7 said the libc dump and its pins did not move, on the
   strength of `scripts/libc_prep.sh` alone. The header is back to 14 lines (one comment line) and the pins hold
   unchanged; the committed Cabs fixtures equal a fresh export byte for byte on the final tree.
4. **Attribute arguments were a raw slice of the preprocessor's output (F3)**, with comments and line markers, and
   the witness compared a multi-line argument truncated. They are tokens now (§2).
5. **The consumer notes overstated what the refusals replaced (F4).** Corrected in the notes and in §4.
6. The smaller items (the incomplete negative control, plants counted when skipped, stale counts, two clause
   numberings, three tray slips, two unrecorded parse errors, a misattributed refusal for a nested bracket) are each
   fixed; the dispositions list them.

One process note: the worker's run of the remaining Tier A/B rows was a single sequential job of about 105 minutes
(the gcc second-oracle lane 25, the observation-lane plants 40), past the one-hour tripwire for a single pass. They
were separate bounded gate rows and nothing was ground through, but the job should have been split and reported at
the hour.
