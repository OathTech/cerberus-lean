# Second look: `fix/attribute-preservation` after the pre-merge review's fixes (2026-11-20)

Reviewer [AGENT 2026-11-20], independent of the worker and of the first reviewer. Under review: tip `c2d893607`, base
mainline `dd0f52fe6`; the delta since the first review is `98648dbdd..c2d893607` (`61e79a887` code and witnesses,
`5c0a9a1ab` a baseline row and the forced header, `bcfc66d92` and `c2d893607` documents). Scale: about an hour of
probing with the worktree's built engines and pristine upstream (`deps/cerberus-upstream`, `c3ff8c53f`); this is not
a second full review and no ladder tier was re-run (see "What I did not run").

## Verdict

**Not ready to merge: one blocking finding (F1).** The response commit `61e79a887` introduced a new crash on a
program that pristine upstream and the previous tip both ran: the second overwrite site the worker's re-audit found
(a file-scope object with internal linkage redeclared `extern` in a block) now delivers `cerb::with_address` to
upstream's `TODO` crash, where the sibling path one function away was given a declared refusal for exactly that
reason. The record and all three consumer notes say the shape is refused; it is not. The fix is small and of the kind
the worker already wrote once.

Everything else in the response held up under the probes I ran. The combination of attributes across redeclarations
is right on every shape I tried; the token carriage of arguments is robust and the two engines agreed byte for byte
on every program (about 75); the three baseline and register edits are complete (I found no further enumerating lane
without its row); the forced header is 14 lines with the macro fix in effect; the witnesses and their plants pass
and the negative control matches pristine where I sampled it; the census counts add up. The remaining findings are
documents (two P2) and notes (P3).

## Findings

### F1 (P1, blocking). `cerb::with_address` on a file-scope object with internal linkage, redeclared `extern` in a block, now crashes; it ran before, and the record says it is refused

`frontend/model/cabs_to_ail_effect.lem`, `extract_program`, the arm "Adding internals object with static or thread
storage duration": since `61e79a887` the entry takes the file-scope declaration's attributes. That is the right
repair for an ordinary attribute (witness `v05`). For `cerb::with_address` it delivers the attribute to
`translation.lem`'s `decode_with_address` and the run dies in upstream's unimplemented arm. The same commit refuses
this delivery in `register_external_object_declaration` (refusal text 7) and says why in its comment; the extraction
site has no such guard.

```
$ cat s03.c
[[cerb::with_address("0x1000")]] static int g; int main(void) { extern int g; return 0; }
fork oracle   --exec --batch : cerberus: internal error, uncaught exception:
                                         Failure("TODO: cerb::with_address() is yet implemented")
fork Lean     --batch        : ModelFailure {msg: "cerberus-lean stop [\"1\",\"UPSTREAM_CRASH\",\"CerbMem.allocateRequested\",\"Mirrored upstream failure: TODO: cerb::with_address() is yet implemented\", ...
pristine      --exec --batch : Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
```

The thread-storage arm of the same site behaves the same way
(`[[cerb::with_address("0x1000")]] _Thread_local static int g; int main(void) { extern _Thread_local int g; return 0; }`:
pristine `Specified(0)`, both fork engines the crash). For comparison, the shapes the worker did guard are refused as
documented: `[[cerb::with_address("0x1000")]] static int g; static int g;` and
`int main(void) { [[cerb::with_address("0x1000")]] extern int g; return 0; } int g;` both print refusal text 7 on
both engines (pristine `Specified(0)` for each).

Why blocking. (a) It is an answer turned into a crash by this slice; the project rule allows the opposite direction
only. (b) The record §2 and §4 (text 7, "a silent IGNORE for 1 and 7"), CONTRACT D19 and the three consumer notes
state that `cerb::with_address` "on a declaration that a later one without it follows" is refused; this program is
that shape and is not refused. (c) The dispositions table marks this extraction path "a second site, fixed" after a
re-audit said to have probed every path on both engines and pristine; the probe set evidently had no
`with_address` program for this path, so the audit was narrower than its claim. No gated corpus contains the form
(`grep -rl with_address tests --include='*.c'` outside `tests/attribute_carriage` is empty), so no lane can see it.

What I would expect in the fix: a declared refusal for this shape (the natural place is where the block-scope
`extern` is registered against an entry that carries the attribute, so the text can name the object as text 7
does), witness rows for the static and the thread arm with pristine's `Specified(0)` in the control, and the record,
D19 and the notes brought into line. Whether to reuse text 7 or add a text 8 is the worker's call; the documents
must list whichever it is.

### F2 (P2). Counts that went stale with the response commits, and one the record says was corrected

Same kind as the first review's "stale numbers" note; these are in the normative ladder and the validation document.

- `scripts/LADDER.md` row 15 still reads `188 rows (derived from the population and the baseline, 2026-11-10: 113
  minimal, 10 fixtures, 16 corpus, 44 libc inputs — the 42 single-trace tests/libc_exec files and the 2 under
  exhaustive/ ...`. After `5c0a9a1ab` the baseline has 189 rows, 45 of them `libc/`, and `tests/libc_exec` has 43
  single-trace files (derived: `len(json)` = 189; keys starting `libc/` = 45; `ls tests/libc_exec/*.c | wc -l` = 43).
- `lean_frontend/VALIDATION.md:1448-1450` carries the same three numbers (44, 42, 188).
- The record's header says sections 1-8 are corrected in place, but §1 line 28 still says
  `attributes 57 rows = CARRIED 18, REFUSED 6, DISCARDED-SILENTLY 33`, against §5's 59 rows and 35.

### F3 (P2). The consumer notes do not say where a redeclaration's attributes land in three cases a consumer will meet

Measured on both engines (identical lines), with pristine beside:

1. **Internal linkage plus a block `extern`: the block declaration's attributes are NOT on the object's entry.**
   `[[m::a("s")]] static int e; int main(void) { [[m::b("t")]] extern int e; return e; }` gives
   `object e: m::a("s")` and `carried declaration e: m::b("t")` (witness `v05`), whereas with external linkage
   (`v08`, my `r08`, `r18`) every declaration's attributes are on the entry. The notes say without qualification that
   an object declared more than once keeps the attributes of every declaration on its `sigma.declarations` entry. The
   dispositions table knows the difference; the notes, which are what the consumer reads, do not.
2. **A block-scope typedef that SHADOWS a file-scope typedef is merged with it.**
   `typedef int T [[m::a("s")]]; int main(void) { [[m::b("t")]] typedef int T; T x = 0; return x; }` prints
   `typedef T: m::b("t")` and `typedef T: m::a("s")` on one entry, the same shape as the true redefinition `v13`. The
   inner `T` is a different entity in C. This is upstream's `register_typedef` ("if the identifier is already declared
   we reuse that existing declaration", with no scope test), unchanged by the slice, and pristine merges too; but the
   notes' sentence "functions and typedef names already behaved so" presents it as correct combination. A consumer
   that gives typedef attributes a meaning gets the inner typedef's attribute on the outer one. (Tags do not have
   the problem: `struct [[a]] S {…}; int main(void) { struct [[b]] S; struct [[c]] S {…}; }` keeps two `struct S`
   entries and the forward declaration in the table. Shadowing objects do not either: my `r02`, `r03`, `r06`.)
3. **The same attribute on two declarations is kept twice**, each with its own location
   (`[[m::a("s")]] extern int e; [[m::a("s")]] int e;` gives two `object e: m::a("s")` lines). That is a defensible
   choice (nothing is given a meaning, locations differ), but it is a choice the notes should state, since the common
   header-plus-source pattern produces it and a consumer that counts or forbids repeats must deduplicate itself.

None of these loses an attribute. They are stated here as P2 because the notes are the interface of the slice and
the first review's F4 was the same class of defect (a note saying more than the engines do).

### F4 (P3). A juxtaposed group and string print with a comma the source does not have

`int h [[m::mk(( "a" ) "b")]];` prints `m::mk(( "a" ), "b")`; `m::mk("a" ( "b" ))` prints `m::mk("a", ( "b" ))`;
`m::mk(( "a" ) "b" "c", "d")` prints `m::mk(( "a" ), "b" "c", "d")`. The argument list is split at a group boundary
as well as at a top-level comma, and the display joins arguments with `, `. There is no collision today, because the
comma form is a parse error (`m::mk(( "a" ), "b")`: `unexpected token after ')' and before ','`), but "carried as its
tokens joined by single spaces" is true per argument only, and a top-level comma is a separator while a comma inside
a group is a token. One sentence in D19 and the notes would do. If the grammar is ever widened to accept the comma
form the two spellings become indistinguishable to a consumer; worth a line beside the grammar.

### F5 (P3). A `#pragma` line inside an attribute argument is dropped without a word

```
int h [[m::mk((
#pragma foo
"a"))]];
```
arrives as `m::mk(( "a" ))` on both engines. `Lexer_feedback.argument_tokens` treats every `#` at the start of a line
as a cpp line marker. This is consistent with the lexer skipping pragma lines everywhere (census W1, tray 85, left as
upstream's judgement and awaiting the operator), so it is not a new class, but the function's comment says "a cpp
line marker" and the record's list of what is not carried says "cpp line markers"; both should name pragma lines, and
whatever is ruled for W1 should cover this site.

### F6 (P3). Cabs JSON import: missing and ill-typed fields are refused; an `Attribute` without its `tag` and unknown extra keys are accepted

Mutation run on the export of a 23-attribute program (every placement class), Lean engine, staged output; a mutation
counts as accepted when the run still prints `typechecking succeeded`. Derived tallies from my script:

| mutation of an `attrs` / `specifier_attrs` value (51 sites: all 22 non-empty, 29 of 85 empty) | refused | accepted |
|---|---|---|
| key deleted; value a string; a list; `null`; `tag` changed | 51 each | 0 |
| an unknown extra key added inside the `Attrs` object | 0 | 51 |

| mutation of one attribute (22 sites) | refused | accepted |
|---|---|---|
| `ns`, `id` or `args` deleted; argument with 2 or 4 elements; tokens a number; pieces a string | 22 each | 0 |
| a piece with 1 or 3 elements (21 sites with pieces) | 21 each | 0 |
| the attribute's `"tag": "Attribute"` deleted | 0 | 22 |

So every new field is fail-closed for absence and type, which is the claim in the record. The two acceptances: extra
keys are ignored (I take that to be the importer's convention throughout, not something this slice introduced), and
`jsonToAttribute` never reads the attribute's own tag (CabsImport.lean:665), so an object of another shape with
`ns`/`id`/`args` fields imports as an attribute. Low risk; one `getField`/tag test would close it.

### F7 (P3). The reason given for leaving the wrong field comment is contradicted by the same commit

The disposition and record §8 leave `ail/ailSyntax.lem:325` ("in source order", known wrong) because "a comment-only
Lem edit re-opens every gate". `61e79a887` itself makes comment-only and text edits in `annot.lem`, `cabs.lem` and
`cabs_to_ail.lem` (the N3096 cites), regenerates and re-pins. The comment could have gone in the same commit at no
extra gate cost. Since F1 needs a Lem change and a re-gate anyway, correct it then rather than carry a known-false
comment on a public field. Related, small: the "one draft, N3096" disposition leaves two texts citing N2335
(`cabs_to_ail.lem:1934`, upstream's own, and `:1936`, the fork's enum text modelled on it); say so or align the
fork's one.

### F8 (P3). The forced header's line count is now a silent invariant guarded by a comment and one Tier B row

The header is 14 lines as at the base, the macro reads `((long)(EXP))`, the installed copy is the same file, and the
five `builtin_expect_*` witness rows pass on both engines; it is the only macro in the header. But the property that
bit the slice (a line added to a force-included header moves every lexing line, which the quotation pins embed) is
recorded only in a comment in the header and is caught only by Tier B row 13. A Tier A landing can repeat the
mistake. A sentence in VALIDATION beside the quotation pins, or a one-line row-1 check of the header's line count,
would make it a speedbump rather than a memory.

### F9 (P3). Two upstream defects met while probing; neither is this slice's, neither is in the tray that I could find

- Two block-scope `extern` redeclarations of one internal-linkage object, in different functions, are reported as
  undefined behaviour: `static int e; int f(void) { extern int e; return e; } int main(void) { extern int e; return e + f(); }`
  gives `Undefined {ub: "UB015_incompatible_redeclaration", stderr: "", loc: "<1:83--1:84>"}` on the fork's two
  engines and on pristine; gcc 13 `-std=c2x -Wall -Wextra -pedantic` compiles it clean and it exits 0. A UB verdict
  on a defined program. It sits in the code the F2 re-audit touched (the same-symbol registration of block externs
  of internal objects), which is why I report it here.
- A block-scope typedef is treated as a redefinition of a file-scope typedef of the same name (F3 item 2):
  `[[m::a("s")]] typedef int T; int main(void) { [[m::b("t")]] typedef long T; T x = 0; return (int)x; }` is rejected
  with `constraint violation: typedef redefinition with different types` on all three; valid C.

Both are candidates for tray reports; by the project's rules neither is to be fixed here.

## What I checked and found right

- **Redeclarations** (25 programs of my own, plus the `v` rows): file-scope extern then definition, tentative twice
  and three times, `static` then `extern` at file scope, block `extern` before and after the file-scope declaration,
  two nested block externs, arrays completed by a later declaration, `_Thread_local`, comma lists, functions
  (declaration/declaration/definition, static then plain, block redeclaration, nested block redeclaration,
  parameter attributes differing between prototype and definition), tags (forward/definition in every order, four
  declarations, an inner-scope tag shadowing an outer one, enum redefinition in an inner scope), block objects
  shadowing file-scope ones. No attribute lost; none attached twice except where written twice (F3.3); the only
  misattachment is the inherited typedef merge (F3.2). The Lean engine's `attribute:` lines equalled the oracle's on
  every program.
- **Arguments as tokens** (28 programs): escapes and an embedded `]]` and comment openers inside strings; `L`, `u`,
  `U`, `u8` prefixes alone and mixed with plain literals; all three bracket kinds and digraphs; a `//` comment and a
  line splice inside a group; a trigraph; UTF-8; a tab inside a literal; a group in an included header and in libc
  mode; 20,000 literals in one group; 3,000 nested parentheses. All carried exactly and identically on both
  engines. Character constants, integers, identifiers, `()`, `{}`, a raw-string spelling and a pasted prefix are parse
  errors, loud, as the record says.
- **Lanes that enumerate `tests/libc_exec`**: `test_libc_exec.sh` (baseline.txt has the row),
  `inner_arg_temps_lane.py` (row present), `test_upstream_oracle.py` (register row present). The other scripts that
  name the directory (`test_kill_plant.sh`, `check_printf_refusals.sh`, `test_observation_lanes.py`,
  `test_ci_sweep.sh`, `test_pnvi.sh`) run the lane script or only mention it; none holds a per-file table. No lane
  other than the two wrappers walks `tests/attribute_carriage` or `tests/discarded_constructs`.
- **Fixtures**: the ten `tests/fixtures/*/cabs.json` equal a fresh export from the repository root, byte for byte
  (`SAME` for all ten with `--runtime=_build/install/default --nolibc --cabs-json tests/fixtures/<n>//source.c`).
- **Witnesses at the tip**, run by me:
  - `discard_witness(attribute_carriage): SELFTEST OK (6 plants ran and were caught; 0 skipped: none)`
  - `discard_witness(attribute_carriage): OK — 229 programs on both engines (carried 197, exec 4, parse 14, refusal 3, stop 10, ub 1); 128 negative-control rows differ from pristine`
  - `discard_witness(attribute_carriage): OK — 77 programs on both engines (carried 62, exec 4, parse 4, refusal 3, stop 4); 53 negative-control rows differ from pristine`
  - `discard_witness(discarded_constructs): SELFTEST OK (3 plants ran and were caught; 3 skipped: lean-drops-carried, oracle-drops-carried, args-truncated)`
  - `discard_witness(discarded_constructs): OK — 48 programs on both engines (exec 23, parse 4, refusal 10, stop 7, ub 4); 25 negative-control rows differ from pristine`

  The ran-versus-skipped logic is sound: a plant with no row is skipped and fails the selftest if required; each
  wrapper's required list is exactly the plants that have rows in its corpus. Two limits worth knowing, neither a
  defect: the plants doctor recorded observations, so they test the comparator and not the engines; and `lean-fixed`
  passes if any one row fails. `pristine.txt` is a static table (the gate cannot re-derive it without the upstream
  build); nine `v` rows I re-measured on pristine agree with it.
- **Census counts**: §1.2 has 59 `A` rows; 35 are DISCARDED-SILENTLY, 18 CARRIED, 6 REFUSED (derived by grep over
  the table), matching record §5.
- **The tip's code is the gated code**: `5c0a9a1ab..c2d893607` changes documents only, so the orchestrator's battery
  on `bcfc66d92` covers the tip. I found no further claim of the "did not move, checked by a narrower instrument"
  kind beyond F1's re-audit claim; the record's remaining "cannot be affected" arguments for rows it did not run are
  backed by that battery.
- Nothing in the delta quotes the operator.

## What I did not run

No ladder tier, no `dune build` or `lake build` (I relied on the built engines; the Lean binary prints the tip's
refusal texts, which the witness pins whole), no `leanchecker`, no `scripts/release.py`. The fix for F1 moves a Lem
source and so needs the regeneration, the battery and the orchestrator's independent re-gate again.

Scratch (`.tmp/review2/` in the worktree) was deleted after the run; the programs quoted above are complete.

## Dispositions

Worker [AGENT 2026-11-20]; the operator's ruling on `#pragma pack` is [USER 2026-11-20]; the orchestrator relayed the
findings' dispositions it wanted [AGENT 2026-11-20, orchestrator]. Code and witnesses: commit `9e0e69fc4`; documents:
the commit that carries this section. One round.

**F1 (P1) — accepted, fixed. A regression the worker's response commit introduced, and a re-audit claim wider than
its probes.** The extraction arm refuses a `cerb::with_address` it would newly deliver, with the text the sibling
site uses (refusal 7, now attributed to the module rather than to one function, since two sites raise it); the
`_Thread_local` form likewise. `Annot.is_cerb_with_address` is narrowed to the one-argument form the elaboration acts
on, so an instance with another argument count is carried and the program runs as it did. Witness rows `w01`-`w06`
on both engines, pristine's `Specified(0)` in the control for the four refused shapes. The enumeration the re-audit
should have made is in the record §10: every attribute the model interprets (found by grepping the model, the
oracle-surface OCaml and the Lean seams for attribute-name tests: `cerb::byte`, `cerb::with_address`, and the two
printing-only readers `cerb::hidden` and the `executable_spec` printer; `cerb::magic` has no caller in the built
tree), every path on which the branch newly delivers attributes to one of the two acting readers, and a probe of
each on pristine and on the tip (rows `x01`-`x17`, `w01`-`w06`, `u_*`, `v19`, `v20`). The claim in the record is stated
as exactly that wide: on those paths and forms no program that ran on pristine crashes, and none changes its answer
but the declared `cerb::byte` typedef placement; four `with_address` shapes that ran with the attribute ignored are
declared refusals. It is a claim about the readers and paths found by reading, not a proof that no other exists.

**F2 (P2) — accepted, fixed.** LADDER row 15 and VALIDATION say 189 rows, 45 libc inputs, 43 single-trace files; the
record §1 says 59 rows and 35.

**F3 (P2) — accepted, fixed.** Each note has a section "Where a redeclaration's attributes land": external linkage
(all on the entry), an internal object redeclared `extern` in a block (the block declaration's are in the carried
table, not on the entry), the same attribute written twice (kept twice), functions, and the shadowing block-scope
typedef merged with the file-scope one, stated as upstream's `register_typedef` defect that the consumer inherits and
filed as tray 98, not presented as correct. D19 says where the claim stops.

**F4 (P3) — accepted, fixed in the parser rather than in a sentence.** A clause made only of plain string literals is
upstream's list; any other clause is one argument, all its tokens, a top-level comma included as a token:
`m::mk(( "a" ) "b" "c", "d")` arrives and prints as `m::mk(( "a" ) "b" "c" , "d")`. Witness rows `w07`-`w09`, `q18`.

**F5 (P3) — accepted, stated; and covered by the ruling.** The function's comment, the record §2 and D19 name pragma
lines among what an argument does not carry. `#pragma pack` inside an argument is refused by the lexer like any
other (`pragma_pack_in_attr_arg`); another pragma there is skipped (`w10`).

**F6 (P3) — accepted, half fixed and half answered.** `jsonToAttribute` checks the attribute's tag (test T8i). Unknown
extra keys are ignored: that is the importer's convention everywhere (`jsonToPos` reads its five fields and no
more), so the new sites follow it rather than differ from it; the convention is now stated in the importer and pinned
by a test (T8j), so it is a choice on the record and not an accident. The bridge is fail-closed on a missing or
ill-typed field, not on an added one.

**F7 (P3) — accepted, fixed; the reviewer's objection to the earlier reason is right.** The comment now says the
order is the desugarer's recording order. The fork's enum-reference text cites draft N3096; upstream's own struct and
union text keeps upstream's N2335 cite, and the record says which is which.

**F8 (P3) — accepted, fixed.** `scripts/check_discarded_constructs.sh` (row 1) pins the forced header at 14 lines and
its `--selftest` plants a copy with one more line (`PLANT OK  [forced-header-line] …`); VALIDATION says why.

**F9 (P3) — accepted, filed, no code.** Tray 97 (the false UB015) and 98 (the shadowing typedef), reproducers
re-measured on pristine, INDEX rows.

**The operator's ruling — implemented.** `#pragma pack` in every form is a declared stop in the lexer on both engines
alike; every other pragma is untouched. The corpus measurement is in the census (W1 note) and the record §10: four
gcc-torture programs, each present twice, in the non-gating sweep; three are already rejections there and
`breakdown/success/20131127-1.c` becomes a stop at the next sweep; no gated row moves. Census W1 is split (pack:
REFUSED; the rest: DISCARDED-SILENTLY as upstream's judgement); D19, SUPPORTED, TODO, tray 85 and the notes say so;
witness rows `pragma_*`.

**Process.** The five gates were run as separate background jobs, none near an hour (the longest, row 1, about 25
minutes); their last lines are in the record §10. One of them, the pristine lane, first reported `failed` with
`source unchanged: False` because the worker edited tracked documents while it ran; it was re-run on an untouched
tree and passed, and nothing was edited during the three jobs after it. Row 1 ran while documents were being edited;
none of its gates reads them, and the record says so.


## Check of the response (2624a83cf)

Reviewer [AGENT 2026-11-20], the author of the second look above. Checked: `9e0e69fc4` (code and witnesses) and
`2624a83cf` (documents), the worktree's engines as built at that tip, pristine upstream beside them. About 80 new
probe programs; both witness lanes re-run; no ladder tier, no build.

### Verdict

**Not ready to merge: one blocking finding (R1), of the same kind as F1 and smaller.** F1 itself is closed: every
form of the shape I could write is a declared refusal on both engines. But the response commit's own parser change
(F4, one argument per clause) makes a `cerb::with_address` that pristine ignores as malformed match the reader's
one-argument arm, so a program that ran now crashes, and the comment, the dispositions and the notes say the
opposite. A second form has done the same since M1 and is in no table. Everything else in the response is right as
far as I probed: the `#pragma pack` refusal is exact, the other dispositions are as stated, the lanes are green.

If the operator or orchestrator rules that these two malformed forms may crash, R1 becomes a document correction;
as the documents stand it is an answer turned into a crash that the record denies.

### R1 (P1). `cerb::with_address` with an argument that is not one plain string literal: ran on pristine, crashes on the tip

```
c07: [[cerb::with_address("0x1000", L"0x2000")]] int g; int main(void) { return 0; }
  pristine    : Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}     (Ail: cerb::with_address("0x1000", "0x2000"), two arguments)
  fork oracle : cerberus: internal error, uncaught exception: Failure("TODO: cerb::with_address() is yet implemented")
  fork Lean   : ModelFailure {msg: "cerberus-lean stop [\"1\",\"UPSTREAM_CRASH\",\"CerbMem.allocateRequested\",\"Mirrored upstream failure: TODO: cerb::with_address() is yet implemented\", ...
  fork attribute line: object g: cerb::with_address("0x1000" , L"0x2000")

c05: [[cerb::with_address(("0x1000"))]] int g; int main(void) { return 0; }
  pristine    : Defined {value: "Specified(0)", ...}      (Ail: cerb::with_address(), no argument)
  fork oracle / Lean : the same two crash lines
  fork attribute line: object g: cerb::with_address(( "0x1000" ))
```

Mechanism. `Cerb_attributes.decode_with_address` acts on an attribute with exactly one argument and decodes that
argument's string as an integer constant. On pristine the group was dropped (no argument) and the prefixed literal
was a second plain argument (two arguments), so both were "invalid" and ignored. On the fork a group is one argument
(since M1: `c05`), and since `9e0e69fc4` a clause that contains a prefixed literal anywhere is ONE argument holding
the whole clause (`c07`), so both match the one-argument arm; the reader then decodes token text such as
`"0x1000" , L"0x2000"` as an integer constant (unobservable, because the run dies in the TODO). That `c07` ran before
`9e0e69fc4` is derived from the code (per-token arguments gave two), not measured: I have no binary of the earlier
tip.

Why blocking, by the test I applied to F1:

- It is an answer turned into a crash, at plain file scope, with no redeclaration involved.
- `c07` is introduced by the response commit, the third time in this slice that a fix delivers `with_address` to
  the crash on a path its author did not probe.
- The documents deny it. `annot.lem`'s new comment on `is_cerb_with_address`: "An instance with another argument
  count is carried like any attribute and annotates nothing". The dispositions: "an instance with another argument
  count is carried and the program runs as it did". The notes: "with any argument count but one it is an ordinary
  carried attribute". `c07` has two arguments in the source.
- The record's §10 tables enumerate paths that newly deliver ATTRIBUTES to a reader. The branch also changed what an
  attribute's ARGUMENT LIST is, and the acting reader's test is on the argument list. That channel is in neither
  table, so the claim "exactly as wide as those probes" is true only because the tables are narrower than the change.

The same forms on the redeclaration paths are refused with text 7 (`[[cerb::with_address(("0x1000"))]] static int g;
… { extern int g; }`, and likewise `L"0x1000"`, `"0x1000", L"0x2000"`, `"0x10" "00"`, `"zz"`, `""`, and two
instances in one list: all refused on both engines, pristine `Specified(0)` for each), which is at least consistent
with treating them as the one-argument form. The plain two-argument and no-argument forms run as on pristine on both
engines (`("0x1000", "0x2000")` and bare `cerb::with_address`, at file scope and across a block `extern`:
`Specified(0)` three ways).

What a fix has to settle, the worker's and the orchestrator's call: either the non-plain forms are refused where the
attribute is desugared (a declared stop in place of pristine's silent ignore, in line with the slice's other
refusals), or they are kept away from the one-argument arm; and §10 gains the argument channel with its probes. In
both cases witness rows with pristine's `Specified(0)` in the control.

### R2 (P3). Rows `w05` and `w06` do not pin the verdict the record cites them for

§10 cites `w05` and `w06` for "two arguments: `Specified(0)` -> `Specified(0)`". Both are `carried` rows, and a
`carried` row checks the attribute lines and that both engines reach the typed Ail, not the execution verdict (the
first review's note, answered then as deliberate). The verdicts are right (I measured `Specified(0)` on both engines
for the same shapes); they are just not pinned. `exec` rows beside them would make the table's claim a gated one.

### R3 (P3). The list of readers is complete for the built engines; three things it should say

My own grep of the Lem model, the hand-written OCaml and the Lean seams for `attr_ns`, `attr_id`, `attr_args`,
`Aattrs`, `is_cerb_*`, `decode_*`, `get_with_address` finds the readers of the record's table and no other that acts
in the oracle or the Lean engine. Omissions, none of which changes a run here:

- `backend/rustic/src/typechecker.ml` tests `rc::` attribute names and reads `attr_args`. It is a separate package
  that this tree does not build (`_build/default/backend` has `common`, `driver`, `lean_export`, `memory_probe`), so
  the sentence "Nothing else tests an attribute's name" is true of the built engines, not of the repository; say so.
- The readers that test the SHAPE of the argument list: `decode_with_address` (exactly one), `decode_hidden`
  (exactly none; printing only), `pp_ast.ml` (empty pieces). R1 is the first of these.
- `c_parser.mly:90-92` synthesises `cerb::magic` attributes from magic comments; the record lists only the reader
  with no caller. `core_reduction.lem:688,710` (`get_with_address`) and `CerbMem.lean:2336` are the downstream end
  of the `with_address` row and could be named with it.

### R4. `#pragma pack` (the operator's ruling): correct on every probe; notes only

Refused, with the pinned text, no Cabs JSON (0 bytes, exit 1), where pristine ran: `pack(1)` after a tab, after
`# ` with a space, bare `pack`, with a trailing comment, after a line splice, with CRLF line ends, written `%:pragma`,
in an included header (the diagnostic names the header: `packh.h:1:2`), inside `#ifdef __cerb__`, through
`_Pragma` in a macro in the middle of a line, with `pack` itself `#define`d to something else, and in libc mode
(`l02`: pristine printed `8`). Not refused, and identical to pristine on both engines: `PACK(1)`, `pack_x(1)`,
`pack1`, `packed`, `GCC pack(1)`, `unknown_thing pack(1)`, the three `STDC` pragmas, `GCC diagnostic` push/ignored/pop,
`omp`, `#pragma once` in a header included twice, `_Pragma("GCC diagnostic push")` and `_Pragma("STDC FP_CONTRACT
OFF")` in a macro. It does not fire in an `#if 0` region, in a string literal (also one spliced so that the text
starts a physical line), in a block comment or in a `//` comment. The shipped libc has no pragma line at all (one
commented mention in `math.h`); the corpus measurement in the census is right (the eight gcc-torture files are the
only `pack` uses under `tests/`; none in `deps/cn/tests`, libxml2 or the pKVM study; `tests/hacl-star`'s header and
libxml2's Python wrapper use `_Pragma` for diagnostics only).

Against gcc 13 on the edge forms (`sizeof(struct { char c; int i; })`): `#define pack other` then `#pragma pack(1)`
gives 5 (gcc packs; the fork refuses: right); `#define P pack` then `#pragma P(1)` gives 8 and `#pragma PACK(1)`
gives 8 (gcc ignores both; the fork leaves both alone: right); `#pragma pack(N)` with `N` a macro gives 8 on gcc and
is refused here (conservative).

Notes (P3):

- The witness rows are `parse` class: the Lean engine is not run, since there is no JSON. "Both engines stop alike"
  holds by construction, which is what the lexer comment says; it is not a second observation.
- The stop is raised as `Cparser_unimplemented_keyword`, so the line reads `error: unimplemented keyword '#pragma
  pack (refused, contract D19: …)'`. The parenthesis carries the declaration; the lead-in is a little off for a
  refusal. Cosmetic.
- A pragma on the last line of a file with no newline after it is `unexpected end of file` on the fork and on
  pristine, for any pragma; `#pragma pack(1)` there gets that message and not the refusal. Loud either way.
- For the operator's information, not a finding against the ruling as given: `struct [[gnu::packed]] S` is still
  carried with no meaning and answers the unpacked size (census T5: 8 where gcc gives 5), which is the same hazard
  the ruling closes for the pragma spelling. `__attribute__((packed))` is a parse error.

### R5. The clause-level argument rule (F4): what is split or joined differently

Only clauses that contain a bracket group or a prefixed literal change, as the notes now say. Measured, both engines
identical in every case:

| source | pristine | `7441fc2fd` (my earlier probes) | tip |
|---|---|---|---|
| `m::mk("a", "b" "c")`, `m::mk("", "")` | two arguments | two arguments | two arguments (unchanged) |
| `m::mk(L"w", u"x", U"y", u8"z")` | four plain arguments, prefixes dropped | four token arguments | ONE argument `L"w" , u"x" , U"y" , u8"z"` |
| `m::mk("a", L"b")` | two plain arguments | (not probed) | ONE argument `"a" , L"b"` |
| `m::mk(( "a" ) "b")` | one argument `"b"` | two, printed with a comma | ONE argument `( "a" ) "b"` |
| `m::mk("a" ( "b" ))` | one argument `"a"` | two, printed with a comma | ONE argument `"a" ( "b" )` |

A plain-string clause with a comment, a line break or a `#pragma` line inside it is still the list it was. The
display now separates a list's arguments with `, ` and shows a comma token as ` , `, so the two are distinguishable
in the `attribute:` lines. The forms that were parse errors still are (`(( "a" ), "b")`, `("a", ("b"))`, `(,)`,
`("a",)`, `("a",,L"b")`). The one consequence I found that the documents do not have is R1.

menhir: `9e0e69fc4` changes one semantic action in `c_parser.mly` and no production. The build tree's
`c_parser.conflicts` at the tip and pristine's both hold exactly `** Conflict (shift/reduce) in state 109.` and
`** Conflict (reduce/reduce) in state 367.`.

### The other dispositions

- **F1**: closed for the shape reported and for every variant I wrote: the attribute after the name, a nested
  block, an initialised object, a second attribute in the list, the attribute on both declarations (leading or after
  the name on the block `extern`), a file-scope `extern` after the `static`, the `_Thread_local` form. All print
  refusal text 7 on both engines; pristine `Specified(0)` for each. One wording point: when the block `extern` itself
  carries the attribute in leading position, the text still says a later declaration "without the attribute"
  follows (it is in the carried table, not on the entry). P3.
- **F2**: LADDER row 15 and VALIDATION read 189 / 45 / 43; the record's §1 reads 59 and 35. Closed.
- **F3**: the three notes have the landing-place section, with the typedef merge stated as an inherited upstream
  defect. Closed, but for the sentence R1 falsifies.
- **F5**: stated in the function's comment and the record; `w10` and `pragma_pack_in_attr_arg` are the rows. Closed.
- **F6**: `jsonToAttribute` checks its tag (test T8i); ignoring unknown extra keys is stated in the importer and
  pinned (T8j). I accept the answer: it is the importer's convention and is now on the record.
- **F7**: the field comment is corrected; the fork's enum text cites N3096. Closed.
- **F8**: the 14-line pin is in `check_discarded_constructs.sh` (row 1), and the plant runs the same predicate on a
  copy with one more line. Closed.
- **F9**: tray 97 and 98 exist with INDEX rows. Closed.

### What I ran

- `./scripts/check_discarded_constructs.sh --selftest`:
  `PLANT OK  [pristine] fails exactly the 31 negative-control rows` …
  `discard_witness(discarded_constructs): SELFTEST OK (3 plants ran and were caught; 3 skipped: lean-drops-carried, oracle-drops-carried, args-truncated)` /
  `discard_witness(discarded_constructs): OK — 56 programs on both engines (exec 25, parse 10, refusal 10, stop 7, ub 4); 31 negative-control rows differ from pristine`
- `./scripts/check_attribute_carriage.sh --selftest --full`:
  `discard_witness(attribute_carriage): SELFTEST OK (6 plants ran and were caught; 0 skipped: none)` /
  `discard_witness(attribute_carriage): OK — 256 programs on both engines (carried 203, exec 21, parse 14, refusal 7, stop 10, ub 1); 142 negative-control rows differ from pristine`
- The probe programs quoted above, each through the fork oracle (`--pp=ail --ast=ail`, `--cabs-json`,
  `--exec --batch`), the Lean engine on the exported JSON (staged and `--batch`), and pristine. The Lean engine's
  attribute lines equalled the oracle's on every program that produced a JSON.

Not run: any ladder tier, any build, `leanchecker`, `scripts/release.py`. The engines' binaries are dated before the
two commits (17:26 and 17:27 against 18:24); I took the coordinator's word that they are built from this tree, and
the refusal texts and witness pins they print are the tip's. A fix for R1 moves a Lem source or the parser and needs
the regeneration and the battery again. Scratch (`.tmp/review3/`) is deleted.

### Dispositions of the check ([AGENT 2026-11-20], the worker; code and witness `755e1baa1`, documents in the commit after it)

- **R1 — accepted; a failure of the response, fixed by changing the mechanism, not by a fourth guard.** The two
  programs crash on `2624a83cf` exactly as reported, and §10's claim was false for the argument channel. The
  orchestrator ruled ([AGENT 2026-11-20, orchestrator]) that `cerb::with_address` is refused at one point,
  independent of placement, argument shape and redeclaration, with the per-path refusals and the one-argument
  narrowing removed. Done: the semantic action of the parser's one `attribute` production stops the parse on that
  name; `Annot.is_cerb_with_address` and the three guards are gone. The reviewer's alternative (the two malformed
  forms may crash, a document correction) was not taken. The point is the parser, not a scan at the desugarer's entry
  ([AGENT 2026-11-20], the worker's choice within the ruling's "earliest single point both engines share"); the
  reason and the totality argument are in the record §11, with its stated boundary (C sources; a hand-written Cabs
  JSON does not pass the parser). The reviewer's two programs are rows `y_decl_file_object_prefixed` and
  `y_decl_file_object_group`. Consequence the reviewer should weigh: the uses pristine ran with the attribute ignored
  now stop (163 of the 184 witness rows), a declared change of verdict by the ruling.
- **R2 — accepted.** `w05`, `w06` are now `parse` rows (they hold the attribute) and pin the refusal; §11 cites
  `exec` rows for verdicts, `carried` rows for carriage and `parse` rows for stops, and says which is which.
- **R3 — accepted, all three.** §11 states the argument list as a channel, the shape-testing readers, the unbuilt
  `backend/rustic` reader of `rc::` (so the sentence is about the built engines), the downstream end
  (`get_with_address`, `CerbMem.lean:2336`) and the parser's synthesis of `cerb::magic`, with a check that the clause
  rule and carriage do not change what is synthesised or where it lands (a hand probe against pristine's Ail tree,
  labelled as not gated).
- **R4 — the notes.** "Both engines stop alike" is said to hold by construction, not as a second observation, in
  §11, VALIDATION.md and `expected.txt`'s header, for the pragma rows and the new `with_address` rows alike. The
  `unimplemented keyword` lead-in is kept (the D9 asm-label form; the new refusal uses it too): cosmetic, as the
  reviewer says. The pragma on a last line without a newline: unchanged, loud. `[[gnu::packed]]`: not refused
  ([AGENT 2026-11-20, orchestrator]); stated as a known hazard in D19, SUPPORTED.md, the census (T5), TODO.md and the
  three consumer notes.
- **R5 — no action asked.** One fact changes under R1's fix: a `cerb::with_address` clause is no longer carried in
  any shape, so the clause rule's one bad consequence is gone; the rule itself is unchanged. menhir: again one
  semantic action and no production; the four warning lines are identical before and after.
- **The other dispositions** — as the reviewer left them; the sentence R1 falsified is superseded by §11 and marked
  so at the head of §10.

Gates on `755e1baa1` are quoted in the record §11. Not done by the worker: the Tier A and Tier B rows outside that
list.

## Check of the second response (e69e2a380)

Reviewer [AGENT 2026-11-20], the author of the sections above. Checked: `755e1baa1` (code and witnesses) and
`e69e2a380` (documents), the worktree's engines as built at that code, pristine upstream beside them. About 35 new
probe programs, six hand-edited Cabs JSON files, both witness lanes re-run; no ladder tier, no build.

### Verdict

**No blocking finding. From this reviewer's side the branch is ready for the orchestrator's gate and the operator's
merge decision.** R1 is closed, and closed by a mechanism whose totality I could check rather than by a fourth guard:
every program that crashed in the three earlier rounds is now a declared parse stop, I found no route from a C source
to a `with_address` annotation or a requested address that does not pass the one production, and no program without
the attribute changes. Four notes follow (P3); none needs code before a merge. One matter is for the operator rather
than the worker: see S1.

### The totality argument (record §11): sound for C sources, checked step by step

- **Step 1, the crash site's only feeder.** `grep` for `with_address`, `ACerb`, `Acerb` over the Lem model, the
  hand-written OCaml and the Lean seams: `ACerb_with_address` is constructed at `translation.lem:4480` only
  (`decode_with_address_NEW` has no caller). Every `Mem.allocate_object` call in the model passes `Nothing` for the
  requested address except `driver.lem:689`, whose argument comes from `CreateRequest2`
  (`core_reduction.lem:688,710`, `get_with_address`). Neither Core text parser can produce the annotation: the OCaml
  `core_parser.mly` knows one attribute, `ailname`, and `CoreParser.lean` likewise; `pp_core.ml:591` prints nothing
  for `Acerb`.
- **Step 2, the same two string tests.** Confirmed in the code, and by probe: `with_address` bare,
  `Cerb::with_address`, `cerb::With_address`, `cerb::__with_address__`, `gnu::with_address`, `cerb::with_addres`,
  `cerb::with_address_` are all carried, inert and `Specified(0)` on both engines and on pristine.
- **Step 3, three makers.** `grep 'attr_id'` over the hand-written OCaml: `to_attrs`, `create_function_definition`,
  `magic_to_attr`; the two others that mention the fields (`cabs_json.ml`, the unbuilt `memory/cheri-coq`) read or
  convert. The Lem model makes no attribute value outside `annot.lem`'s combinators.
- **Step 4, one production.** `attribute_specifier -> attribute_list -> attribute` is the only chain; the grammar has
  six start symbols and the action is on the production, so the start symbol does not matter. GNU
  `__attribute__((…))` is a parse error on fork and pristine alike. The lexer makes `LBRACK_LBRACK` from
  `'[' whitespace* '['`, so the spaced opener goes through the same production (probe below).

Probes, each refused with text 9, 0 bytes of JSON, exit 1 (pristine's answer in brackets): the three programs of the
earlier rounds, F1's `[[cerb::with_address("0x1000")]] static int g; … { extern int g; }` [ran], R1's
`("0x1000", L"0x2000")` [ran] and `(("0x1000"))` [ran]; the plain one-argument form [TODO crash];
`[[ cerb :: with_address ( "0x1000" ) ]]` [crash]; `[ [cerb::with_address("0x1000")] ]` [crash]; the whole attribute
from a macro, and namespace and name each from a macro [crash]; the name pasted with `##` [crash]; the name split by
a line splice [crash]; second in a list after another attribute [crash]; in a second specifier with no argument
[ran]; in a `sizeof` type name [ran]; on a label [ran]; in an included header (the diagnostic names the header)
[ran]. Not refused, and unchanged from pristine: the text in a string literal, in a comment and in an `#if 0`
region; `int cerb, with_address; struct with_address { int cerb; };` as ordinary identifiers; `cerb::hidden`,
`cerb::byte`, `cerb::magic` written as attributes. Under `--switches=at_magic_comments`, a magic comment whose text
is `cerb::with_address("0x1000")` becomes `cerb::magic(" cerb::with_address("0x1000") ")` on both engines and runs
`Specified(0)`, as on pristine: the magic route makes `cerb::magic` and nothing else. The digraph opener `<:<:` is
not an attribute opener on the fork or on pristine (a parse error on both).

**Did removing the guards bring a crash back?** No. With no `cerb::with_address` value in any Cabs the parser
returns, the three removed guards were unreachable; the earlier crashing programs above are all the parse stop.

**Does a program without the attribute change?** The Lem delta of `755e1baa1` is the removal of
`is_cerb_with_address`, two refusal texts and three guarded branches, each of which fired only on that attribute;
the parser delta is one semantic action. In `tests/attribute_carriage/expected.txt` the only rows that changed, were
added or were removed are `with_address` rows and the one new control `y_control_cerb_hidden`; `tests/
discarded_constructs` is untouched. I found no way for a program that does not spell the attribute to see the change.

### The witness matrix

Derived from the tables by my own script: 184 rows carry text 9, with ONE distinct text after the position; every
program whose source spells `cerb::with_address` is such a row and no other row is; pristine's control on the 184 is
163 `Specified(0)`, 12 a constraint violation, 9 the TODO crash, which are the record's numbers. 163 `y_*.c` files
(160 matrix programs and three controls). I re-measured 26 of the controls on pristine (every seventh `y_` row, and
`u_addr_file_lead`, `v20`, `x08`): all agree with `pristine.txt`.

Run by me at the tip:

- `./scripts/check_attribute_carriage.sh --selftest --full`:
  `PLANT OK  [pristine] fails exactly the 313 negative-control rows` … `PLANT OK  [parse-accepted] fails all 198 rows it touches` /
  `discard_witness(attribute_carriage): SELFTEST OK (7 plants ran and were caught; 0 skipped: none)` /
  `discard_witness(attribute_carriage): OK — 419 programs on both engines (carried 196, exec 13, parse 198, refusal 1, stop 10, ub 1); 313 negative-control rows differ from pristine`
- `./scripts/check_discarded_constructs.sh --selftest`:
  `PLANT OK  [parse-accepted] fails all 10 rows it touches` /
  `discard_witness(discarded_constructs): SELFTEST OK (4 plants ran and were caught; 3 skipped: lean-drops-carried, oracle-drops-carried, args-truncated)` /
  `discard_witness(discarded_constructs): OK — 56 programs on both engines (exec 25, parse 10, refusal 10, stop 7, ub 4); 31 negative-control rows differ from pristine`

The new plant is honest and simple: it sets the recorded parser status to "accepted" and every `parse` row must
fail. It shows the comparator reads the status; like the other plants it does not touch an engine. The `parse` rows
observe the oracle's parser only, which the record, VALIDATION and the table's header now say in so many words.

### The documented boundary, measured

A Cabs JSON exported from a near-miss name and edited by hand to say `with_address`, given to the Lean engine:

```
[[cerb::with_address("0x1000")]] int g; …            staged: typechecks, prints `attribute: object g: cerb::with_address("0x1000")`
                                                     --batch, exit 1: ModelFailure {msg: "cerberus-lean stop [\"1\",\"UPSTREAM_CRASH\",\"CerbMem.allocateRequested\",\"Mirrored upstream failure: TODO: cerb::with_address() is yet implemented\",[\"cerberus\",…,\"memory/concrete/impl_mem.ml\",\"1294\",\"1295\",…
… static int g; … { extern int g; }                  the same stop
[[cerb::with_address(("0x1000"))]] int g; …          the same stop
[[cerb::with_address("")]] int g; …                  exit 134: PANIC … cerberus-lean stop ["1","UPSTREAM_CRASH","CerbDecode.integerEmpty", …
[[cerb::with_address("0x1000", "x")]] int g; …       Defined {value: "Specified(0)", …}   (ignored, as upstream ignores it)
[[cerb::with_address("0x1000")]] extern int g; …     Defined {value: "Specified(0)", …}   (never allocated)
```

So the stop is loud, nonzero and attributed to upstream's file and lines, as §11 says; it is the upstream-crash
class, not a refusal, and the two forms upstream ignores still run. That is exactly the pre-slice behaviour of the
Lean engine on such an input, now unreachable from the oracle's export.

### Notes (P3)

- **S1. The size of the verdict change is the operator's to see.** 163 of the 184 witness programs ran on pristine
  with the attribute ignored and now stop. The record states it plainly as a declared change of verdict made by an
  agent ruling ([AGENT 2026-11-20, orchestrator]), filed as tray 99, and I think it is the right engineering after
  three failed per-path guards. But it is a fork refusal of forms upstream accepts, wider than "crash to refusal",
  and the ruling is not the operator's; the merge request should put that sentence in front of the operator rather
  than leave it in §11. No gated corpus and no consumer corpus I could grep contains the attribute.
- **S2. The boundary is in the record only.** CONTRACT D19, SUPPORTED and the three consumer notes say the
  attribute is refused "anywhere"; none says the refusal is the parser's and that a Cabs JSON not exported by the
  oracle reaches the upstream-crash stop instead. The consumers are the only parties who could hand the Lean engine
  such a file; one sentence in D19 and the notes would do. If the orchestrator wants the point total over the Lean
  engine's inputs too, the same two string tests in `CabsImport.jsonToAttribute` would give it; I do not ask for
  that, it is a choice.
- **S3. The three Lean comments** (`CerbDecode.lean:43`, `CerbMem.lean:2319-2322`, `:2457-2460`) say those arms are
  reachable "only through the `cerb::with_address` attribute". As an upper bound that is still true; what they no
  longer say is that no C source reaches them, only a Cabs JSON the oracle did not export. They are not false and
  they describe reachability, not a mirrored computation, so I do not read the mirror rule as requiring an edit in
  this slice (an edit to a hand-written seam means the copy, a Lean rebuild and the battery again, for a comment).
  They should be on `TODO.md` by line so the next change to either file corrects them; the record names them but I
  did not find them there.
- **S4. The diagnostic's position is the token after the attribute** (`e02.c:1:42` for an attribute that ends at
  column 41; `wa.h:1:31` likewise): the driver reports the lexer's current position when the action raises. The file
  and line are right and the text names the attribute. Cosmetic; the pins hold whatever it is.

### The other dispositions

R2 (the cited rows are now of the class that pins what they are cited for), R3 (the argument channel, the
shape-testing readers, the unbuilt `backend/rustic`, the downstream end and the synthesis of `cerb::magic` are in
§11; I repeated the magic-comment probe and it agrees), R4 and R5 are as the worker states them. `[[gnu::packed]]`
is carried and answers the unpacked size (`Specified(8)` on both engines and pristine), and D19, SUPPORTED and the
three notes say so and say it is not refused. Tray 99 exists. `scripts/fork_drift_manifest.txt` keeps the removed
names in its dated NOTEs as history, which is what those NOTEs are for. In the documents I read against the tree
(record §2, §4, §5, §10 head, §11; D19; the notes' refusal tables; the wrapper's header) I found no statement the
tree does not bear out. menhir: the delta is again one semantic action and no production.

### What I did not run

Any ladder tier, any build, `leanchecker`, `scripts/release.py`. The engines' binaries are dated an hour before the
two commits (18:36 and 18:38 against 19:36); they print the tip's refusal text and pass the tip's 419 pins, and I
took the coordinator's word for the rest. Scratch (`.tmp/review4/`) is deleted.
