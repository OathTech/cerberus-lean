# Pre-merge review: `fix/wchar-rank` (`wchar_t` and `wint_t` out of the rank normalisation; the micro package retired)

Reviewer [AGENT] (Claude Fable 5.2), independent of the worker. 2026-11-14. Under review: `fix/wchar-rank` at
`96bb31cab` (M1 `0b10975b6`, M2 `511fab783`, M3 `96bb31cab`), base mainline `06afa3ef7`, in the worker's built
worktree. Charter `2026-11-14_worker-charter-wchar-rank.md`; record `2026-11-14_wchar-rank-record.md`. Lines in code
blocks are machine output copied as printed; counts outside code blocks are derived and say from what.

## Verdict

**No blocking finding. The code change is right and may land; four documents should be corrected first (F1, F2, F3,
F4: documents only), and one decision about the witness's size is the operator's (F5).**

The central claim holds under my own probes: where the only macro-typed operands are `wchar_t`/`wint_t`, the fork
prints pristine's line, on both engines; the loud catch-all is reachable exactly as before from C; the other macro
types keep D14. The problems are in what the documents say around it: one consumer is told nothing about its own pin,
which carries the defect (F1); the range of defective commits is stated three commits too short (F2); a new TODO
entry asserts a defect in `build_provider_smoke.py` that reading does not bear out (F3); and an outward-facing
sentence in tray 20 is false as a universal (F4).

## What I ran

All on the worktree's binaries (oracle `_build/default/backend/driver/main.exe`, built at `511fab783` with M3's
documents uncommitted: `libc.co version … g511fab783-dirty`; M3 touches documents only, so they are the tip's), pristine
`deps/cerberus-upstream` at `c3ff8c53f`, gcc 13. Scratch under `.tmp/review/`, deleted.

1. **My own probe generator** (not the worker's): 13,348 programs, one expression each, `--nolibc --exec --batch`
   on the fork oracle, pristine and the Lean engine. Fifteen operand shapes: a `wchar_t` object (values 5,
   2147483647, 4000000000u), a typedef chain to it (plain and `const`), a struct field, an array element through a
   pointer, a cast, a function result, the constant `L'a'`, a bit-field, `WCHAR_MAX`, `WCHAR_MIN`, `WINT_MAX`,
   `WINT_MIN`, `WEOF`, and `<wchar.h>`'s `wint_t` object. Against 34 partners (every standard integer type, two
   enums, `size_t`, `ptrdiff_t`, `intptr_t`, `uintptr_t`, `intmax_t`, `uintmax_t`, six exact-width/least/fast
   names, `wchar_t`, `wint_t`, three literals) through comparisons, `+ - * / %`, `& | ^`, both arms of `?:`,
   `_Generic` codes, `sizeof`, compound assignment in both directions; and alone through unary operators, shifts,
   casts, `++`/`--`, `switch`, array indexing and pointer arithmetic with the wide operand as index, enum mixes,
   and three-operand expressions. Derived from the result file:

   | comparison | count |
   |---|---|
   | fork output = pristine output (exit code, stdout, stderr) | 11,448 |
   | both crash on the same assertion, the text differing only in an `impl_mem.ml` line number (967 fork, 932 pristine; tray 62's crash on storing 4000000000 into a `wchar_t`) | 1,884 |
   | fork differs from pristine in a value | 16 (F4: every one has a non-`wchar_t` macro-typed sub-expression) |
   | Lean = fork oracle (verdict line and exit code) | 10,753 |
   | neither engine gives a verdict (the 1,884 crashes, 19 parse errors of mine) | 1,903 |
   | oracle rejects statically, Lean prints `Error {msg: "desugaring failed …"}` (bit-fields 345, `WEOF` undeclared 304, 17 of my own typos) | 666 |
   | same verdict line, exit code 1 on the oracle and 0 on Lean | 26 (not a defect: see below) |

   The 26: all with a function call in the expression. I ran Lean without `--first`, so it enumerated two
   executions and exited 0, as the oracle does under `--mode=exhaustive` (checked on a plain-`int` program:
   `oracle exhaustive rc=0`). A mode mismatch of my harness, nothing of the slice's.

   Limits of this run, stated: bit-fields are unsupported by both Cerberus sides, so the bit-field shape tests only
   that both reject; `<wchar.h>`'s `wint_t` is `short`, so that shape is a `short` control, and the only `Wint_t`
   operands are `WINT_MIN`/`WINT_MAX` (no `__cerbty_wint_t` in `parsers/c/lexer_feedback.ml`, no `typeof`: the
   worker's statement is right).
2. **libc mode**, five programs (`mbtowc`/`wctomb`, `mbstowcs`/`wcstombs`, `%lc` with wide arithmetic, a mixed
   `wchar_t`/`long`/`size_t`/`unsigned` line, and a D14 control with `strcspn`/`strstr`). The four `wchar_t`
   programs: fork = pristine; Lean (`--libc` with the 12 metadata TUs) = oracle on the four I ran through it. The
   control keeps D14's answer:

   ```text
   fork:     Defined {value: "Specified(0)", stdout: "16 10 c 23\n", stderr: "", blocked: "false"}
   pristine: Undefined {ub: "UB_CERB002a_out_of_bound_load", stderr: "", loc: "<265:22--265:26>"}
   gcc:      16 10 c 23
   ```
3. **The catch-all**, twelve programs with a `__cerbty_ptraddr_t` operand against `int`, `long`, `wchar_t`,
   `WINT_MAX` and itself, both orders: all three engines stop before any rank comparison
   (`internal error: ptraddr_t is CHERI-specific`; Lean the mirrored stop).
4. **Tray 20's patch**: extracted from the report, applied to `c3ff8c53f`'s file in scratch.

   ```text
   checking file frontend/model/ail/ailTypesAux.lem
   patching file frontend/model/ail/ailTypesAux.lem
   ```

   Both exit 0. The patched file differs from the fork's only by the fork's Lean-target `declare` lines (28 diff
   lines, all `>`).
5. **The witness**, timed on an idle box (load about 2): real run `1:24.34 total`; `--selftest` (plants and real
   run) `2:14.48 total`, all eight plants at their declared counts, `OK (126 programs …`. Subsets through
   `CERB_MTR_ONLY`: the six `limits_*` programs `17.096 total`; the eight generated `kept_*` programs
   `23.912 total`.
6. **M2**: `check_pin_sites.sh --selftest` and the real run (`SELFTEST OK (8 plants …`, `OK — lem-pin 2220010b… (lakefile rev, 2 lake-manifests rev+inputRev, README pin command)`),
   `python3 scripts/test_release.py` (`Ran 16 tests … OK`), `check_fork_drift.sh` (`OK — layer 1: 96 … layer 2: 33 …`),
   `libc_prep.sh --check` (both dumps equal their pins, `519d7c92…` and `dcd0499f…`).
7. **Kernel replay**: `CERB_MEM_MAX=32G ../scripts/capped lake env leanchecker AilTypesAux
   AilTypesAux_lemMeasureProofs Translation Translation_lemMeasureProofs` from `lean_frontend/`: no output,
   `leanchecker exit=0` (2.8 s wall).

**Not run by me:** any build (`lake build`, dune, regeneration of the generated trees), row 1 as a whole, Tier A/B,
`lake check`, the provider rehearsal, and any comparison against a pre-fix fork BINARY (I had none and built none).
"The other macro types are byte-identical to the pre-fix fork" therefore rests, in this review, on reading (F8) plus
the 98 gcc-pinned rows of the 2026-11-04 set whose pins are unchanged from `06afa3ef7` and pass.

## Findings

### F1 (P2) cerberus-caesium's present pin carries the defect, and neither the note nor the record says so

The record (§8) says the consumer's pin "was not identified"; the correction note for cerberus-caesium says nothing
about its present pin. It is identifiable: cerberus-caesium's own scripts read it from
`deps/refinedc-lean/scripts/semantics-pin.env` (`scripts/certificate-pipeline.py:81`, `scripts/completion-target.py:45`),
a nested repository:

```text
26:CERBERUS_LEAN_COMMIT="03c8b4451ff08830306d687e639f7dc57baf6827"
```

`03c8b4451` is the mainline's landing note of 2026-11-09, and `git merge-base --is-ancestor 9b15a1f69 03c8b4451`
succeeds: that pin is inside the defective range. The note for cerberus-sl states its pin and what follows; this one
should too ("your present pin carries the defect; re-pin to the landing or later"). A `grep -i` for `wchar_t`,
`WCHAR_M` and `wint_t` over `completion/` and `examples-consumer/` `*.c` found nothing, so their exposure looks nil,
but that is theirs to confirm, and their certificates are stated "with respect to cerberus-lean" at that pin.

### F2 (P2) the range of defective commits is stated three commits too short at the bottom, one too long at the top

Both correction notes, CONTRACT D14, VALIDATION and TODO say the defect runs "from `bb6e8e9f9`", and the notes add
that a pin before `bb6e8e9f9` never had it. The landing was a fast-forward, so the mainline's history is linear
through the slice's own commits:

```text
bb6e8e9f9 Close-out: the full battery on ab6295a01, …
ab6295a01 M3: the record, contract D14, the filing (tray 20) and the consumer notes for the macro-type-rank fix
5dd549e54 M2: the macro-type-rank witnesses (row 1), the corpus sweeps, the moved rows dispositioned (tray 20)
9b15a1f69 M1: the macro integer types get their implementation rank (tray 20; cerberus-caesium filing 05)
```

`9b15a1f69`, `5dd549e54` and `ab6295a01` are mainline commits, a consumer pins by commit, and all three carry the
defect. At the other end "up to, and not including, the landing" is ambiguous: after a fast-forward the branch's
charter commit `6ae2434c9` is on the mainline and still defective; the first fixed commit is M1. The range to state
is: `9b15a1f69` up to but not including `0b10975b6` (or their hashes after a rebase). The charter worded it the
worker's way, so the origin is the charter.

### F3 (P2) the new TODO entry about `build_provider_smoke.py` asserts a defect that reading does not bear out

Record §6 and §8 and the new entry in `TODO.md` say the rehearsal "would stop at its compiler check" because
`pins()` compares `lem -v` with `'Lem ' + LEM_REV[:7]`, a form lem no longer prints. But the script builds lem with
the version forced on the make command line:

```text
148:        common = ['INSTALL_DIR='+str(prefix), 'LEMVERSION='+LEM_REV[:7]]
149:        run('lem-compiler', ['make', 'bin/lem', *common], lem)
```

and in lem at the pin (`deps/lem-pinned`, `2220010`) `Makefile:5` is `LEMVERSION:=$(shell git describe …)`, which a
command-line variable overrides; `bin/lem: lem`, `lem: build-lem`, `build-lem: version share_directory`, and
`version` writes `let v="$(LEMVERSION)"`; `src/main.ml:333` prints `"Lem " ^ Version.v`. So the lem the rehearsal
builds prints `Lem <7 hex>` and the comparison holds, by reading. Neither the worker nor I ran the rehearsal. The
entry should say what is known (not run since 2026-09; unverified) and drop the asserted stop and the "needs a
ruling" built on it. Keeping the script and reading the pin from the manifest is otherwise sound and fail-closed;
the unit test passes.

### F4 (P2) "every program with a `wchar_t` or `wint_t` operand prints pristine's line" is false as written

CONTRACT D14, VALIDATION and tray 20 (addressed to upstream: "with the patch every program with a `wchar_t` or
`wint_t` operand behaves exactly as it does without it") state the equality for every such program. The charter's
statement was narrower (programs whose ONLY macro-typed operands are those two), and the narrower one is the true
one. A counterexample, `wchar_t x = 5; size_t sz = 3; int i = -3;` printing `(x+sz)+i` (fork, pristine, Lean):

```text
0	Defined {value: "Specified(0)", stdout: "5\n", stderr: "", blocked: "false"}	0	Defined {value: "Specified(0)", stdout: "4294967301\n", stderr: "", blocked: "false"}	0	Defined {value: "Specified(0)", stdout: "5\n", stderr: "", blocked: "false"}
```

`x+sz` is typed `size_t` by upstream's NON-STD arm and `size_t + int` is then D14's fix (gcc: 5). Fourteen of my
probes are this shape (one per wide operand shape), two more are the `short` control against `ptrdiff_t`. Nothing is
wrong with the behaviour: it is D14 doing what it is for. The sentences need the charter's qualifier; in tray 20 it
matters most, because upstream will read it as a claim about their patch. The worker's 6,094 "mixed" rows are all
two-operand, which is why the measurement did not show it.

### F5 (P2, the operator's call) the witness is larger than the mechanism warrants; my recommendation

Measured on an idle box: the leg is 2 min 14 s (real run 84 s, plants about 50 s); before the slice about 60 s by
the 2026-11-04 record. Of the real run, the six `limits_*` programs are 17 s and the eight generated `kept_*`
programs 24 s. Row 1 as a whole is 24 to 31 minutes by the record, so the leg's growth is about 4 % of the row: not
a cost problem by itself. The problems are of kind:

- The six gcc-pinned `limits_*` programs (7,337 expressions) cover types this slice did not change and on which the
  vicinity found nothing. They are a measurement kept as a gate. I would take them out of row 1 (a slower tier, or
  out altogether).
- The eight generated KEPT programs pin 8,453 expressions of upstream's behaviour for `wchar_t`/`wint_t`, false
  `UB036` verdicts and narrowed sums included, as required outcomes. The mechanism is a three-arm `match` and four
  table arms; the five hand-written programs, the six re-pinned ones and the two macro matrices
  (`kept_limits_wchar`, `kept_limits_wint`) would turn red on any return of `int`'s rank. The other six are
  enumerative bulk; a slower tier suits them.
- The generator is gone (record §9) while 14 generated programs, about 17,000 lines of C and 596 KB of pin text,
  stay. They can be re-pinned but not regenerated, and their selection rule (fork = pristine, `Defined`, gcc not
  undefined) exists only as a sentence. When upstream settles tray 62, or at the next merge-base bump, every KEPT
  row moves and the bulk has to be re-derived by hand or deleted. Either commit the generator beside the programs
  or keep only what is hand-maintainable.

### F6 (P3) the `d14.txt` plants are real; one is redundant, and most of the file is unused

For the five re-pinned rows the `d14.txt` line equals the row's gcc pin at `06afa3ef7`, which passed there (checked
row by row: `audit_rank_wchar`, `dense_wchar_t_bneg`, `dense_wchar_t_pos`, `promo_wchar_t`, `p_wchar_long`), so those
lines are what the pre-fix fork printed. The other 14 I could not check without a pre-fix binary. The plants fail
at their declared counts. What each adds: `d14-pair` is the only plant that feeds a wrong LINE with exit code 0 to
the oracle side of a KEPT row (`oracle-rc` changes the exit code only), so it earns its place; `lean-d14` exercises
the same comparison on the same three rows as `lean-fixed`. The plants read 3 of the file's 19 rows; the other 16
(most of its 46 KB) are a record of the defect, which the vicinity table in the record already is.

### F7 (P3) `wint_t`: the same mechanism, and a separate judgement that the operator should confirm

The mechanism is the same code path (`Wint_t` normalised to `Signed Int_` against a non-`int` range), the charter
delegated the call ("fix it the same way if it is the same mechanism"), the worker measured the regression
(`WINT_MIN > -1`) and tagged the decision [AGENT]. My probes agree: 1,255 programs each for `WINT_MAX` and
`WINT_MIN`, all equal to pristine but the one three-operand row of F4 each. It is still an extension of a ruling
that named one type, written into CONTRACT D14 beside the [USER] tag: the sign-off should cover it in words.

### F8 (P3) the two-edit shape opens no reachable fail-open path

By reading: `Common.normalise_integerType_` (`ocaml_frontend/ocaml_implementation.ml:37-66`) yields `Wchar_t` or
`Wint_t` from no other input, so the four new arms match only a pair one of whose ORIGINAL operands is one of the
two; every other pair meets the same arms in the same order as before and the same catch-all. Exactly one kind of
pair that was loud is now a silent `false`: a bare `Wchar_t`/`Wint_t` as FIRST operand against `Ptraddr_t` (before,
`wchar_t` arrived as `Signed Int_` and that pair fell to the loud arm). It is upstream's answer for a `wchar_t`
pair, which is the ruling, and it is unreachable from C outside CHERI (run 3: the type is stopped before any rank
comparison on all three engines). The generated Lean and OCaml carry the arms in the source's order. The comment
"the loud catch-all below is for every other constructor" is accurate.

### F9 (P3) commit `2b51d2a57` and quoted sign-offs in history: the facts

`2b51d2a57` is a commit of THIS repository, not of another one: the mainline's landing note of 2026-09-23, an
ancestor of `bb6e8e9f9`. cerberus-sl only refers to it (`scripts/semantics-pin.env:26`,
`CERBERUS_LEAN_COMMIT="2b51d2a57179d890a51dda404aedf59d80196926"`; the sl note's statement that this pin carries
neither D14 nor the defect is correct). Its subject line does carry the operator's sign-off phrase in quotation
marks. It is not alone: 48 commit subjects on the mainline's history have a quoted phrase after a `[USER …]` tag,
dated 2026-09-03 to 2026-10-08, all before the rule of 2026-10-16. They are pushed (`origin/mdd/cerberus-lean`
and the tag `cerberus-lean-v0.1.0-alpha.1` contain `2b51d2a57`). No file at this tip carries that commit's phrase
(`git grep`, empty), and none of this branch's four commit messages quotes anyone. Nothing for this slice to do;
whether history is rewritten is the operator's decision alone.

### F10 (P3) smaller observations

- The micro package's retirement is complete in live files: the remaining mentions are the closed TODO items, the
  LADDER row that says it was retired, the comment in `check_pin_sites.sh`, dated records and the `results/*.tsv`
  measurements. `check_pin_sites.sh`'s eight plants never touched the third manifest (P3 plants speclab's, P8 the
  root's), as the worker says; selftest green. `release.py` lost the three artifact rows and its unit test passes.
- The container's `CLAUDE.md` still says three lake-manifests, and its pins paragraph names lem pin `e6d8db5`
  where the manifest and every site say `2220010`: the orchestrator's document, noted here only so it is not lost.
- The record's kernel-replay and libc-pin claims reproduce (runs 6 and 7).
- Row 1's KEPT pins make upstream's defects for `wchar_t` required outcomes on both engines
  (`wchar_t w = 1; long l = 2^33; w + l` is 1). That is the ruling, stated plainly in the record; it should stay
  visible in `TODO.md` as the thing that goes away when tray 62 is settled upstream.

## Dispositions I would expect before the merge

F1 to F4: four document edits, no rebuild. F5: a decision; if the bulk moves, the script's pinned counts and plant
arithmetic move with it and the leg is re-run. F7 and F9: a word from the operator. The rest: notes.

## Dispositions

Worker [AGENT 2026-11-14] (Claude Fable 5.2), on the orchestrator's instructions and rulings and two operator
rulings relayed by the orchestrator, each tagged where it applies. The reviewer's text above is unchanged. Code and
witness changes are commit `fc505be99`; the document changes are the commit that carries this section. Every finding
was accepted; none was argued down.

- **F1 (P2), fixed.** The worker read the pin itself: `/home/dev/projects/cerberus-caesium/deps/refinedc-lean/scripts/semantics-pin.env:26`
  is `CERBERUS_LEAN_COMMIT="03c8b4451ff08830306d687e639f7dc57baf6827"`, and `git merge-base --is-ancestor 9b15a1f69
  03c8b4451` succeeds. The worker's M3 statement that the pin "was not identified" was a failure to look in the
  nested repository. `2026-11-14_consumer-note-cerberus-caesium-wchar-rank-correction.md` has a new section, "Your
  present pin carries the defect": the pin, that its certificates stated with respect to cerberus-lean at that pin
  are with respect to the defective semantics, and what to check in order (whether any certified or compared
  program has a `wchar_t`/`wint_t` operand, wide literals included; the reviewer's `grep` is reported with its
  limits as theirs to confirm; what follows in each case; no re-pin into the range). Record §8 corrected.
- **F2 (P2), fixed everywhere.** The range is `9b15a1f69` (first defective) up to but not including `0b10975b6`
  (M1 of this branch, first fixed; or its hash after a rebase). Both consumer notes now list it by landing (the
  2026-11-04 slice's own four commits and its landing note, then the heads after the five later landings and the
  reporting slice's documents: 59 mainline commits to `06afa3ef7`, plus the charter commit `6ae2434c9` after a
  fast-forward), and say that their earlier text was three commits short. CONTRACT D14, VALIDATION, TODO, SUPPORTED
  and the record carry the same two hashes. Origin, as the orchestrator states it: the charter's wording ("pins
  from `bb6e8e9f9` up to this landing") was the orchestrator's and was wrong; the worker copied it without checking
  it against the history, which a `git log` would have settled.
- **F3 (P2), fixed.** The worker asserted a defect it had not established: it read `pins()`'s comparison and not
  the `LEMVERSION=` on the make command line that makes the comparison hold. The `TODO.md` entry now says the
  rehearsal is unverified (not run since 2026-09), asserts no stop and asks for no ruling; record §6 and §8 say the
  first claim was wrong and is withdrawn. The rehearsal was not run in this pass either (about an hour of cold
  builds); it stays unverified, stated as such.
- **F4 (P2), fixed.** The equality is restated in the charter's narrow form wherever it stood: a program whose only
  macro-typed operands are `wchar_t`/`wint_t` prints pristine's line. Tray 20 (most carefully: it is addressed to
  upstream) now says the claim is "this and no wider", says in so many words that it is not true of every program
  that contains a `wchar_t`, and carries the reviewer's counter-example with all three lines, which the worker
  reproduced on 2026-11-14 (fork `5`, un-patched `4294967301`, gcc `5`). The same qualifier, with the example, is
  in CONTRACT D14, VALIDATION, both consumer notes, SUPPORTED, tray 62's fork-status paragraph and the record
  (§0, §3.2). The worker's 6,094 "mixed" rows were all two-operand expressions; the record now says so where it
  had drawn the wider conclusion from them.
- **F5 (P2), ruled and done.** Ruling [AGENT 2026-11-14, orchestrator] under the gate-cruft rule: row 1 keeps a core
  at or below the leg's pre-slice cost; the bulk moves to `--full` as a Tier B row; the generator is committed. Done
  in `fc505be99` (record §4.1): the core is 114 programs (the 2026-11-04 set with its five re-pinned rows and the
  split matrix, the five hand-written KEPT programs, `kept_limits_wchar` and `kept_limits_wint`); `--full` is all
  126 and is Tier B row 16 in `scripts/LADDER.md`; same programs, same pin files, counts pinned per mode. Cost,
  measured the same day on an idle box: `--selftest` of the core 62.88 s and 63.48 s (two runs) against 62.85 s and 62.02 s for a replica
  of the pre-slice leg (the 106 programs and five plants of `06afa3ef7` on today's binaries) — at that cost to
  within the spread of two runs, 0 to 1.5 s above it and NOT below it, said plainly: the bound asked for was that cost or less, and the core's real run is about 4 to 5 s longer than the pre-slice one (47.5 s and 48.6 s against 43.3 s)
  while its plants are about 4 s shorter. Getting under it needs either a smaller per-type matrix or thinner
  2026-11-04 plants: the orchestrator's call. `--full --selftest`
  1 min 40.97 s and 1 min 41.83 s (real run alone 87.4 s). The generator is `tests/macro_type_ranks/generate.py`, re-created from the worker's session (the
  scratch original was deleted at M3); `--check` regenerates the fourteen committed programs byte for byte
  (`CHECK OK (14 programs, 15790 expressions: each emitted file is byte-identical to the committed one)`, 3 min
  22 s), and fails on a one-space plant in a committed file.
- **F6 (P3), done.** `lean-d14` is dropped (it repeated `lean-fixed` on the same rows). `d14-pair` runs on every
  KEPT row of the mode and on nothing else: 13 rows and 26 failing checks in the core, all 19 rows of `d14.txt` and
  38 under `--full`; the selftest stops if any of those rows lacks a D14 line differing from its pin. The reviewer's
  remark that 14 of the 19 lines could not be checked without a pre-fix binary stands: they were taken by the worker
  from the oracle built at `06afa3ef7` before the change, a binary that no longer exists; the five the reviewer
  could check agree.
- **F7 (P3), ruled.** [USER 2026-11-14]: the extension of the exclusion to `wint_t` is approved, as the same defect
  and the same mechanism. Recorded as the operator's ruling in the record (§0), CONTRACT D14, the consumer notes,
  the closed TODO entry, the witness script's header and `kept.txt`'s comment, replacing the worker's [AGENT] tag
  there. No code change.
- **F8 (P3), recorded.** One sentence in record §2: the pair `(Wchar_t | Wint_t, Ptraddr_t)` is now a silent
  `false` where it was loud, it is upstream's answer for a `wchar_t` pair, and it is unreachable from C outside
  CHERI (a `ptraddr_t` operand is stopped before any rank comparison on all three engines, the reviewer's run 3).
- **F9 (P3), corrected and ruled.** The worker's final report described `2b51d2a57` wrongly. It is this
  repository's mainline landing note of 2026-09-23, which cerberus-sl pins; it is not a commit of another
  repository. [USER 2026-11-14]: the commit subjects from before the rule of 2026-10-16 that carry quoted phrases
  are grandfathered, and history is not rewritten. The record (§0, §8) says so in a sentence and lists none of
  them.
- **F10 (P3), nothing to change in this repository.** The container document is the orchestrator's. The last
  bullet (the KEPT pins make upstream's `wchar_t` defects required outcomes until tray 62 is settled) is now a
  standing `TODO.md` entry with what to do when that happens.

Not done in this pass, stated: row 1 as a whole was not re-run after `fc505be99` (its witness leg was, in both
modes; `test_unit.sh` changed in a comment only); Tier A and the battery are the orchestrator's on the new tip.
