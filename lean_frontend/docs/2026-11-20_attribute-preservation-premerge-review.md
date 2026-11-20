# Pre-merge review: `fix/attribute-preservation` (2026-11-20)

Reviewer [AGENT 2026-11-20, pre-merge reviewer], independent of the worker and of the orchestrator's battery. Under
review: tip `98648dbdd`, base mainline `dd0f52fe6` (M0 `89f252dd5`, M1 `3b7c0568e`, M2 `4b260827c`, `ed7925183`, M3
`98648dbdd`). Documents read: the charter, the census, the record, contract D19, the three consumer notes, tray
reports 78-96 and the INDEX rows. Code read in full: the diffs of `parsers/c/c_parser.mly`, `lexer_feedback.ml(i)`,
`c_parser_driver.ml`, `frontend/model/{cabs,annot,cabs_to_ail,cabs_to_ail_effect,cabs_to_ail_aux,translation,constraint}.lem`,
`ail/ailSyntax.lem`, `backend/lean_export/cabs_json.ml`, `backend/common/pipeline.ml`, `lean_frontend/CabsImport.lean`,
`Main.lean`, `scripts/discard_witness.py` and the two wrappers.

## 0. Verdict

**Not ready to merge: two blocking findings.** F1 is a red gate on the tip (Tier B row 10, measured). F2 is a
remaining silent attribute loss that the census does not list and that contract D19, the record's count
"DISCARDED-SILENTLY 33 -> 0" and tray 78's state deny; it is on the path a contract-reading consumer uses for a
global declared in a header. Both look small to close. Everything else I tested held: the carriage is exactly-once,
identical on both engines, changes no verdict outside the declared rows, the Cabs import is fail-closed, the M2
fixes and refusals are what the record says they are and none of them is a fork reading of an open question, the
tray reproducers reproduce on pristine. The should-fix items are F3 (the carried argument text) and F4 (the
consumer notes).

## 1. What was run (this worktree, the worker's built tree; engines not rebuilt by me)

All probes are one-file programs under the worktree's `.tmp/review/` (deleted at the end), each run through four
instruments: the fork's oracle (`--pp=ail --ast=ail`, `--exec --batch`, `--cabs-json`, `--nolibc`), the Lean engine
on the exported JSON (staged output and `--batch`, `LEAN_ABORT_ON_PANIC=1`), pristine `c3ff8c53f`
(`deps/cerberus-upstream`) and gcc 13 `-std=c2x`. Lines quoted below are verbatim; counts are labelled derived.

- Both row-1 witnesses with `--selftest`: `discard_witness(attribute_carriage): OK — 64 programs on both engines
  (carried 52, exec 4, parse 2, refusal 2, stop 4); 35 negative-control rows differ from pristine` (13 s wall) and
  `discard_witness(discarded_constructs): OK — 45 programs on both engines (exec 23, parse 4, refusal 8, stop 6, ub
  4); 22 negative-control rows differ from pristine` (23 s wall). The cost in row 1 is acceptable.
- About 160 probes of my own in eight batches (placement and multiplicity, redeclaration, the attribute declaration,
  argument text, `cerb::` attributes, the `_Noreturn`/alignment rulings, the `_Atomic`/array-parameter refusals,
  constant-expression contexts).
- The negative controls re-measured on pristine: every row of `tests/discarded_constructs/pristine.txt` (22 of 22
  equal pristine's line), and for all 202 programs of `tests/attribute_carriage` the number of attributes in
  pristine's Ail dump against the number of lines the control claims (F5).
- Verdict preservation: all 202 attribute programs, fork against pristine and Lean against fork (§3).
- A sweep of 8,078 C files (`tests/` without the two new corpora, `lean_frontend/corpus`, `runtime/libc`,
  `deps/cn/tests`) through the fork's front end for any D19 text, the K&R stop and the two attribute stops, each hit
  re-run on pristine (§4.6).
- The Cabs import: eight fields dropped and ill-typed in turn, and a two-element enumerator, on a real export (§3).
- Tier B row 10, `scripts/test_upstream_oracle.py`: `--only 'libc_exec/04[0-4]'` and the whole default selection
  (F1).
- Every reproducer of tray reports 78-96 on pristine (§5).

## 2. Blocking findings

### F1 (P1). Tier B row 10, the pristine-oracle gate, is red on the tip: `tests/libc_exec/044` is an unregistered fork-versus-pristine difference

M2 adds `tests/libc_exec/044-noreturn-return-operand-exits.c` to a corpus that `scripts/test_upstream_oracle.py`
walks (`'tier-b': ('minimal', 'coverage', 'debug', 'float', 'bytes', 'libc_exec', …)`). The fork answers
`Specified(3)`, pristine `UB071_noreturn`, and `scripts/upstream_oracle_differences.json` (43 cases; the branch does
not touch it) has no row for it. Earlier fix slices registered theirs (`libc_exec/041-atexit-return.c`,
`libc_exec/043-printf-format-ub-loc.c`). Run:

    scripts/ce python3 scripts/test_upstream_oracle.py --only 'libc_exec/04[0-4]' --out .tmp/review/uo
    2/5 reviewed_difference: libc_exec/041-atexit-return.c (pristine 0.2s, fork 0.2s)
    4/5 reviewed_difference: libc_exec/043-printf-format-ub-loc.c (pristine 0.2s, fork 0.2s)
    5/5 difference: libc_exec/044-noreturn-return-operand-exits.c (pristine 0.2s, fork 0.2s)
    Independent oracle: failed; {'semantic_agreement': 2, 'reviewed_difference': 2, 'difference': 1}; …/report.json

The whole default selection: see §6 (the result line is quoted there). The record says the worker did not run rows
8-15 and Tier B, which is honest; but its sentences "No baselined row moved" (§4, and contract D19) and §7 ("What
moved outside this repository's code") do not mention the register, and the M2 commit message calls 044 "a new
baseline row" without it. Owed: a reviewed register row (class `shared-model-fix`, citing C17 6.7.4#8 and tray 80),
row 10 green, and the record corrected.

### F2 (P1). An object with linkage that is declared more than once keeps only the LAST declaration's attributes; the earlier ones are dropped silently, on both engines

`register_external_object_declaration` (`frontend/model/cabs_to_ail_effect.lem:2353-2412`) stores the new
declaration's `attrs` over the previous entry (`let decl = (isTentative, loc, attrs, …)`), where
`register_function_declaration` (:2264, :2281, :2288) and `register_typedef` (:955) call `Annot.combine_attributes`.
Pristine does the same, so this is upstream's behaviour and not a regression; it is, however, exactly the class this
branch exists to close, the census has no row for it, and after the branch it is the one placement I found where an
accepted attribute reaches neither an Ail slot nor `carried_attributes` nor a refusal. Probes (fork oracle and Lean
engine print the same lines; `A` lines are the `attribute:` lines, without the prefix):

    [[m::a("s")]] extern int e; [[m::b("t")]] int e = 0; int main(void) { return e; }
       A object e: m::b("t") @ r1.c:1:34-35
    [[m::a("s")]] extern int e; int e; int main(void) { return e; }                    (no attribute line at all)
    [[m::a("s")]] int e; int main(void) { extern int e; return e; }                    (no attribute line at all)
    int e [[m::a("s")]] = 1; int e; int main(void) { return e - 1; }                   (no attribute line at all)
    [[m::a("s")]] static int e; int main(void) { [[m::b("t")]] extern int e; return e; }
       A carried declaration e: m::b("t") @ r7.c:1:51-52                               (m::a is gone)

and the same for the after-name placement (`extern int e [[m::a("s")]]; int e [[m::b("t")]] = 0;` prints only
`object e: m::b("t")`). All run to `Specified(0)` with no diagnostic. The second program is the ordinary shape of an
annotated global: the attribute on the declaration in a header, the definition without it. For functions the
equivalent works (`[[m::a]] int f(void); [[m::b]] int f(void); int f [[m::c]] (void) {…}` prints all three). The same
arm silently drops upstream's own `cerb::with_address` (`[[cerb::with_address("0x1000")]] extern int g; int g;`
runs to `Specified(0)`), so a repair that combines the attributes will newly deliver that attribute to upstream's
TODO crash on that shape and needs the same crash-to-refusal treatment the branch gave the block-scope `extern`.

What this falsifies as written: contract D19 ("every attribute the grammar accepts is carried to Ail"), the record
§5 ("DISCARDED-SILENTLY 33 -> 0"), the census's claim to list the Cabs-to-Ail drops, tray 78's count (31 sites) and
its INDEX state "fixed (D19)", and the consumer notes. Disposition is the orchestrator's: combine as the function
arm does (with the `with_address` consequence handled), or carry the earlier attributes in the table, or declare
the limit in D19, the census, the notes and a witness row. It should not merge undeclared.

## 3. The attribute class: what held

- **Exactly once, right entity, both engines.** Over my probes no attribute was duplicated or lost other than F2:
  type names in `sizeof`, casts, `_Generic` associations, `typeof`, `_Alignas( )`, `__builtin_types_compatible_p`,
  enumerator values, array bounds, designators, `case` labels and `_Static_assert` are each carried once (the
  constant-expression evaluators do not re-desugar them); a prototype and its definition carry their own parameter
  attributes; a statement expression's declarations are carried; multi-declarator declarations give each
  declarator the leading attributes. The Lean engine's lines equalled the oracle's in every probe, non-ASCII and
  multi-line argument text included.
- **Meaning.** Derived from my run over the 202 corpus programs: the fork's verdict equals pristine's on 187; the 15
  that differ are the declared ones (the attribute declaration now accepted: `b01`-`b06`, `r02`; `e11`; the union and
  enum tag-reference stops `e04`, `g02`; `cerb::byte` after the name: `u_gen_after_name`, `u_gen_block_after_name`,
  `u_byte_after_name_bad`; the two refusals `u_addr_block_extern_after_name`, `u_for_attrdecl`). The Lean verdict
  equalled the oracle's on all 163 programs the oracle accepts.
- **`cerb::byte`** applies before the declaration and after the typedef's name, at file and block scope, per
  declarator (`typedef unsigned char byte, b2 [[cerb::byte]];` makes only `b2` the byte type), and nowhere else:
  after the type, after `*`, after an array declarator, on an object or a parameter it is carried and inert.
  `typedef int T [[cerb::byte]];` is now upstream's constraint violation (pristine accepted it). Note: this extends
  one of upstream's own extension attributes to a placement where upstream did not read it; it follows the
  appertainment rule and the leading form, and I think it is right, but only upstream knows what it intended there,
  so the tray report should ask rather than assert.
- **`cerb::with_address`** is neither implemented nor silently applied. It reaches upstream's TODO stop exactly where
  it did (leading or after the name of a file-scope object, leading on a block-scope `extern`), is carried and inert
  on block-scope automatic and static objects, parameters, `for`-init objects, functions and the type placements,
  and the one newly delivered placement is refused. (F2 names the one shape where it is dropped.)
- **The Cabs import is fail-closed.** On a real export, deleting `specifier_attrs` from `Type_name`,
  `Struct_declaration`, `Specifiers` or `attrs` from `TSpec_enum`, `ADecl`, `PDecl`, `Params`, `PDeclaration_decl`
  gives `Error {msg: "cabs-json parse error: getField: missing field '…' in …`, an ill-typed value gives
  `… getTag: expected string or object, got 42`, and a two-element enumerator gives `… jsonToEnumerator: expected
  3-element array [id, attrs, value]`; exit 1 each. The cites in `CabsImport.lean` name the exporter's function and
  not a line, which is enough to find it.
- **The new record field.** A side table on `sigma` beside `typedef_attributes` and `loop_attributes` is the least
  invasive carrier and I agree with it over ctype annotations. What breaks for a consumer is compile-time and
  stated in the cerberus-sl note: a `sigma` literal needs the field, and positional matches on the nine changed Cabs
  constructors and the `specifiers` record need the extra component. The Core `file` record is untouched (the
  consumers' `loop_attributes` uses I found in cerberus-sl are the Core file's). Design notes, not defects (P3): the
  key is a `Symbol.identifier` (name and location), not the Ail symbol, so a consumer joins on the location; an
  attribute in an abstract parameter or in a parameter of a nested function declarator has no entity or only the
  inner name (`int (*fp)(int [[m::c("u")]])` gives `carried specifiers -`); and the comment "in source order" on the
  field is not true in general (`for ([[a]] int i [[b]] = 0, * [[c]] p = 0; …)` gives `declaration i`,
  `declarator-id i`, `pointer p`, `declaration p`).
- **Proof modules and digests.** `git diff --name-only dd0f52fe6..HEAD` touches three hand-written Lean files
  (`CabsImport.lean`, `Main.lean`, `test/Unit/CabsImportTest.lean`), no `*_lemMeasureProofs.lean` and no seam; the
  six new recursive Lem functions generate as `partial def` in `Cabs_to_ail.lean`, outside the totality set. I
  agree no kernel replay is owed. I did not re-run the Core-quotation or libc pins; the orchestrator's battery does.

### F3 (P2). A non-string attribute argument is carried as a raw slice of the PREPROCESSOR OUTPUT, comments, newlines and line markers included

`Lexer_feedback.source_text` slices the string given to `parse_from_string`, which is cpp's output. So the text of
one and the same argument depends on layout, and the instrument's "one line per attribute" breaks:

    int h [[m::mk(( "a"            (then twelve blank lines)            "b" ))]];
    attribute: object h: m::mk(( "a"
    # 13 "lm.c"
     "b" )) @ lm.c:1:12-14

    int k [[m::mk(( "a"
    #include "empty.h"
     "b" ))]];
    attribute: object k: m::mk(( "a"
    # 1 "empty.h" 1
    # 17 "lm.c" 2
     "b" )) @ lm.c:15:12-14

A comment inside the group is carried too (`m::mk(( "a" /* in */ "b"` …), and a macro is carried expanded
(`m::mk(GRP)` with `#define GRP (STR STR)` arrives as `("s" "s")`). Consequences: (a) the charter asked for the
arguments' tokens, the record, D19 and the consumer notes say "source text", and what arrives is neither; a consumer
that parses the group meets cpp line markers; (b) the witness reads only lines that start with `attribute: `, so
the continuation lines are invisible to it and a multi-line argument is compared truncated, on both engines alike.
Suggested: normalise at the parser (re-lex the slice to tokens and join them with single spaces, or at least drop
line-marker lines and collapse whitespace), or refuse a group that spans a line break; say "preprocessed text" in the
documents; add a multi-line witness row. The accepted argument grammar is also narrower than "a nested
balanced-token group is carried whole" suggests (`m::mk("a", ("b"))`, `m::mk(("a", ("b")))`, `m::mk(( ))` are
parse errors); that is loud and the record's §2 lists the classes, so only the wording in D19 needs care.

### F4 (P2). The consumer notes misstate the cost of the refusals and omit what the record knows

All three notes say of the refusals: "Each replaced a silently wrong answer or a crash." That is not so for:
`int f(_Atomic int x) { return x + 1; } int main(void) { return f(0) - 1; }` (pristine `Specified(0)`, correct, now
refused; the record §4 names it, the notes do not, and they end by asking the consumer to report exactly this);
`int f(int a[restrict]);` and `int f(int a[volatile 1]); int f(int * volatile a) {…}` (pristine stopped with a
constraint diagnostic, loud); the attribute declaration in a `for`-init clause (pristine's located-nowhere
constraint violation, loud). The refinedc-lean note should also carry F2 and F3 once they are disposed, since both
are about what a contract reader receives.

## 4. The M2 rulings, one by one

None of the fixes is a fork reading; each mirrors an arm upstream already has or a constraint the standard states,
and gcc agrees on every probe below.

1. **`_Alignas` on a `for`-init declaration: fixed.** Agreed. Two declarators, the type form, two specifiers, an
   array and an uninitialised object all answer as gcc (pristine `Specified(1)`/`(2)`, fork `Specified(0)`);
   `_Alignas(3)` is now upstream's own constraint text where gcc rejects.
2. **`return e;` under `_Noreturn`: fixed.** The elaboration is the non-`_Noreturn` arm's binding followed by the
   undefined behaviour, which is what C17 6.7.4#8 needs. Probed: an operand that divides by zero in a callee reports
   `UB045a_division_by_zero` (pristine `UB071_noreturn`); `return x++ + x++;` reports `UB035_unsequenced_race`;
   struct, pointer, `_Bool`-from-pointer, `double` and nested-call operands that do return report `UB071_noreturn`;
   `return;` and falling off the end are unchanged; `_Noreturn void f(void) { return g(); }` is the constraint
   violation `void function should not return a value` on both engines, as before. The `is_void` branch copied from
   the arm below is therefore dead here; harmless.
3. **`_Alignas` in a type name: constraint violation; in a compound literal: refused.** C17 6.7.5#2 is as cited and
   gcc rejects each (`sizeof`, `_Generic` association, `typeof`, `_Alignas( )`). The compound literal has one caller
   (`CabsEcompound`); the comment in `desugar_type_name` says "its two callers", a slip. The refusal also stops an
   alignment that changes nothing (`&(_Alignas(4) int){0}`); narrow enough.
4. **`_Atomic` on a parameter of a definition: refused.** As narrow as claimed: `_Atomic(int) x`, a typedef of the
   atomic type, a declaration without a body, and a parameter of a function-pointer parameter of a definition
   (`int f(void (*cb)(_Atomic int x)) {…}`) are not refused. Cost: the program in F4.
5. **`_Atomic` qualifier with a derived declarator at block scope or on a parameter: refused.** Narrow: plain and
   parenthesised objects, several plain declarators, an atomic struct, members, file scope, `for`-init, casts and
   `sizeof` type names are untouched and answer as gcc. It also stops a block-scope `typedef _Atomic int *PA;` and a
   block-scope `extern _Atomic int *p;` (pristine: a crash later and a false `UB015_incompatible_redeclaration`), so
   those are improvements. The text calls the typedef "a block-scope or parameter declaration", fine.
6. **Qualifiers in an array parameter's brackets, declarations: refused.** Narrow (`static` keeps upstream's
   not-yet-supported text, a definition keeps upstream's rejection). One misattribution (P3): the invalid
   `int f(int a[2][const 3]);` (gcc rejects) gets the refusal text that explains where the qualifiers belong, where
   upstream's `ArrayDeclarationQsAndStaticOnlyOutmost` diagnostic was meant to fire; pristine accepted it silently.
7. **K&R stops.** The two gcc-torture rows the sweep found moved (`execute/950221-1.c`, `execute/920922-1.c`) were
   parse errors on pristine as well, with a different text.

**4.6 The corpora, measured.** Derived from the sweep: 39 of 8,078 files stop with one of the texts; 35 stop on
pristine with the same K&R diagnostic; the four that moved are the two K&R rows above, the named parity probe
`tests/parity-probes/uncertainty/T-misc/ag-04-alignas-typename-cl.c`, and `tests/suite/parsing/attributes.c`, which
pristine rejects at the same place (`attributes.c:14:8: error: TODO: Attribute constraint violation …`) after two
level-0 debug lines the fork no longer prints; its row in the non-gating scoreboard
`tests/ci_sweep/results/suite.tsv:65` quotes the first of them and will read differently at the next sweep. No
refused `_Atomic` or array-parameter form exists in these corpora; the worker's grep result stands.

**4.8 `#pragma` (my view, as asked).** The worker's reason is correct as far as it goes: C17 6.10.6#1 lets an
implementation ignore a pragma it does not recognise, so `Specified(8)` for the packed struct is a conforming
answer, and turning it into a stop is not a crash-to-refusal refinement. But the charter's own principle is that an
accepted construct is carried, given its meaning or refused, never dropped without a trace, and `#pragma pack` is
the one row left that fails it while changing something a program and a verifier both observe (`sizeof`,
`offsetof`, member addresses). `[[gnu::packed]]` at least arrives in Ail for a consumer to refuse; a pragma leaves
nothing. For the consumers this project serves, which reason about code that gcc compiles, a layout that is not the
compiled one is the same kind of unsoundness as a contract that reads `True`. I would make `#pragma pack` (the
push/pop forms and `_Pragma("pack…")` included) a declared refusal, and nothing wider: every other pragma keeps
upstream's skip. Cost, measured by grep: eight uses in four gcc-torture programs (each present twice), one of them
under `breakdown/success` (`20131127-1.c`), all in the non-gating sweep; none in libxml2, the pKVM case study, the cn
tests or the shipped libc. It is the operator's call because it stops programs upstream accepts with a conforming
answer.

**4.9 `__builtin_expect` and its siblings.** The fix is right and `builtins.h` is the only forced header and has no
other macro. In the shipped headers the same slip exists in `<stdatomic.h>` `atomic_init(obj,value) (*obj = value)`
(named in tray 84 and the record) and in `posix/sys/ioctl.h` `_IOC(inout,group,num,len)` (`inout` and `len` bare; its
in-header users pass parenthesised or constant arguments). Neither is forced; reporting them is enough.

## 5. Witnesses, census, tray, documents (P3 unless marked)

- **F5. The attribute negative control is incomplete.** `pristine.txt`'s header says a row pristine rejected, or
  whose marker was absent from pristine's Ail, is listed with `-`. Ten programs whose pin has attribute lines that
  pristine did not carry have no control row: `b01`-`b05`, `e11_struct_forward_block`, `r02_std_fallthrough`
  (pristine rejects), `u_addr_block_static_after_name`, `u_addr_block_static_lead`, `u_addr_file_after_type`
  (pristine's Ail has no attribute). Every row that IS listed agrees with pristine's measured Ail count, and the
  discarded-constructs control is exact. The counts "96 negative-control rows" understate by ten.
- **The witness's blind spots.** A `carried` row checks neither engine's exit status nor verdict (one row,
  `r09_kw_Noreturn_returns`, pins `-` and so passes on a Lean engine that printed nothing); F3's continuation lines;
  `SELFTEST OK (5 plants)` for the discarded corpus counts two plants that "have no row to touch" (three ran). The
  plants doctor recorded observations, which the script declares; that is proportionate for a speedbump.
- **Stale numbers.** `scripts/test_unit.sh` says "40 programs under tests/discarded_constructs"; it is 45.
- **Census gaps that are loud.** C23 placements the grammar rejects and the census does not record: the attribute
  declaration directly after a label (`case 0: [[fallthrough]]; case 1:` and `lbl: [[a]];` are
  `error: unexpected token after ']' and before ';'`; only the form after another statement is accepted) and
  `int f() [[a]] { … }` (`unexpected token after ')' and before '[['`). Parse errors, so the principle holds, but the
  record's "`[[a]];` is accepted and carried" should say where it is not.
- **Clause numbers.** The code and documents cite "C23 6.7.12.1" for attributes and, in the same file, "C23 6.7.3.4"
  for tags and "C23 6.7.1" for declaration specifiers. To my knowledge those belong to two different numberings (in
  the one where attributes are 6.7.12, tags are 6.7.2.3; in the one where tags are 6.7.3.4, attributes are 6.7.13).
  Two of the cites are in refusal texts pinned whole and one in tray 78. Name the document once (the existing code
  says N2335) and make them agree before filing. Likewise census T2's "6.7.12.7" for `noreturn` looks one off. I
  could not check a copy of the standard on this box.
- **Tray 78-96.** All 34 reproducers give pristine's quoted line (re-run; the Ail-dump ones checked by attribute
  count). Slips: reports 94, 95 and 96 end "an invalid program is accepted; nothing is refused or repaired", but
  their programs are valid C that crashes or is rejected; every report's footer says `--nolibc`, and 80's first
  reproducer is libc mode; 83 and census W6 call a declaration list after a prototype "a syntax error", though the
  C17 function-definition syntax derives it (gcc rejects it; say "gcc rejects" or find the constraint); 78's count
  and state depend on F2. No speculation about upstream's plans and no fork-internal vocabulary in the bodies beyond
  the customary "Fork status" section.
- **Record integrity.** No operator text is quoted in the commits or documents I read; decisions carry their tags.

## 6. The whole Tier B row 10 selection

`scripts/ce python3 scripts/test_upstream_oracle.py --out .tmp/review/uo2` on the tip:

    630/1002 difference: libc_exec/044-noreturn-return-operand-exits.c (pristine 0.2s, fork 0.2s)
    Independent oracle scope: tier-b; 1002 rows in 188.2s; source unchanged: True
    Independent oracle: failed; {'semantic_agreement': 932, 'reviewed_difference': 42, 'matching_failure': 25, 'difference': 1, 'interface_agreement': 2}; …/report.json

One unregistered difference, the row of F1, and no other: the branch moves nothing else in the gated corpora against
pristine. Also run on the tip: `./scripts/check_attribute_carriage.sh --full` gives `discard_witness(attribute_carriage):
OK — 202 programs on both engines (carried 173, exec 4, parse 12, refusal 2, stop 10, ub 1); 96 negative-control rows
differ from pristine` in 36 s wall (LADDER row 17 says 32 s; consistent).

## 7. Not done by this review

No rebuild from re-derived trees (the worker's binaries were used; `check_driver_fresh: oracle OK` was printed by
row 10's harness); no Tier A battery (the orchestrator's); no kernel replay (none owed); the consumers' own
pipelines were not run; the standard's text was not consulted on the box.
