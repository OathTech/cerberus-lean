# Pre-merge review: the reporting slice (`docs/reporting`)

Date 2026-11-10. Reviewer [AGENT] (Claude Fable 5.2), independent of the worker. Under review: branch
`docs/reporting`, tip `5cdffc432` (M1 `f2fdd0c8e`, M2 `5cdffc432`), base mainline `b66374eac`; charter
`2026-11-10_worker-charter-reporting.md`. Reviewed against the container working practices (record integrity,
provenance tags, no operator quotes) and against the slice's purpose: documents an upstream Cerberus maintainer can
use with no knowledge of this fork.

## Verdict

**Not ready to merge as it stands: one blocking finding (F1), six should-fix findings (F2-F7).** All seven are
document edits or operator rulings; none needs an engine change inside this slice.

The evidence in the slice is good. Every reproducer I ran (about 85 programs, listed below) behaves on pristine
upstream at `c3ff8c53f` and on gcc 13.3.0 exactly as the reports say, every file:line locus I checked is right at
`c3ff8c53f`, the INDEX counts are right, CORPORA.md's runner works on a plain Cerberus binary, the diff is
documents-only, no operator text is quoted and no document speculates about upstream's plans. The failures are of
placement: facts the worker established are recorded where a maintainer will not meet them (F1, F4, F5), and the
tray's front door was left describing a different project state (F3).

The fork regression the worker reported is real on both engines, and the attributed cause is supported by reading.
It is a standing silent wrong answer of the fork, which the working practices do not tolerate; it is not introduced
by this branch, and it needs an operator ruling whatever happens to this merge (F1, F2).

## What was run

Pristine: `deps/cerberus-upstream` at `c3ff8c53f`, `_build/default/backend/driver/main.exe
--runtime=_build/install/default [--nolibc] --exec --batch f.c`, read-only. gcc: `gcc (Ubuntu 13.3.0-6ubuntu2~24.04.1)
13.3.0`, `-std=c11 -w -O0` (`-lm` added). Fork oracle: the worktree's `_build/default/backend/driver/main.exe`. Fork
Lean engine: `main.exe --nolibc --cabs-json f.c > f.json`, then `CERB_INSTALL_PREFIX=<worktree>/_build/install/default
cerberus-lean --batch f.json`. One engine process at a time; load average 2.6-4.7 throughout. Programs were retyped
from the reports into scratch files (heredocs; a first attempt through zsh `echo` mangled three backslash programs
and was redone). No gate, build, regeneration, `test_unit.sh` or pin check was run.

Reproduced as stated on pristine and gcc (first line and exit status compared with the report's text):

- 72: both `sscanf` programs. 73: the six crash programs, and all twelve
  `tests/parity-probes/uncertainty/P-statement-expressions/*.c` (six run, six die, gcc statuses as stated).
- 74: the three `--args` programs. 75: all five contexts. 76: all nine programs. 77: the four non-finite programs,
  the finite control, the `_Bool` control.
- 04 (closed): `Undefined {ub: "UB046_array_pointer_outside", stderr: "", loc: "<3:12--3:17>"}`, and the offset-0
  form. 15 (closed): both reproducers `Specified(42)`.
- 08 (four shapes), 10 (`'\?'`, `"\?"`, `'é'`, `'\0123'`), 12, 21 (`&` and `+ 0`), 22, 23 (two members, the wide
  top-level form, the narrow control), 30 (`strncmp`, `strncpy`), 31 (both), 33, 34 (zero alignment, zero size,
  non-multiple size), 47 (forward-declared, `int` member, `void`, function type, `int[]`, `int a[2](void)`), 61,
  62 (five programs), 63 (multi-character, non-ASCII, `\U0001F600`, `u8` both).

Fork engines, sampled (oracle and Lean): 62's five programs, 73, 75 (enumerator), 77, 12, 08 (fourth shape), 10
(`'\?'` 63, `'\0123'` 83), 47 (the three new operands rejected with the `_Alignof` diagnostic, the array-of-functions
crash), 23 (wide), 34, 61 (the D13 refusal text). All as the reports' fork-status paragraphs say.

Loci read at `c3ff8c53f` and found as cited: `core_reduction.lem:804-846`; `stdio.c:113-122`, `:726-734`, `:937-940`;
`string.c:40-47`, `:85-90`, `:347-352`; `driver.lem:1628-1636`; `decode.ml:42`, `:167`, `:197`, `:199`, `:224`;
`translation.lem:2317-2320`, `:3222`; `cabs_to_ail.lem:2819`, `:3540`; `impl_mem.ml:11`, `:932`, `:1777-1790`,
`:2072-2076`, `:2213`, `:2243`, `:2305-2306`, `:2372-2373`; `std.core:96`, `:386-393`; `ocaml_gcc_builtins.ml:29-30`;
`ocaml_implementation.ml:167`, `:523`, `:536`; `ailTypesAux.lem:240`; `ctype_aux.lem:77-80`; `core_aux.lem:1994`,
`:2007-2014`; `desugaring_init.lem:461-462`; `cerb_floating.ml:5`; `stdint.h:103-104`; `math.h:151`, `:196`;
`uchar.h`, `wchar.h`, `float.h`, `runtime/libc/dune`. Ancestry: `766073467`, `f4a3a3d54`, `3230aa494`, `cee382443`
are ancestors of `c3ff8c53f`; `9f23c62b3` is not (checked in the worktree's repository; the object is absent from
`deps/cerberus-upstream`).

Clause cites checked against `tools/n1570.html` (C11) where I looked them up: 7.22.3.2#2-#3, 7.22.3.1#2; the others
(5.1.2.2.1#2, 5.2.4.2.2#13, 6.3.1.4#1, 6.4.4.4, 6.5.3.4#1, 6.5.6#9, 6.7.5#5, 6.7.6.2#1, 6.7.9#15, 7.21.6.7, 7.21.10.4,
7.24.2.4#2, 7.24.6.2, 7.28, 7.29.1#4, 7.29.4.6.1, 7.12.7.5, 7.12.10.1, F.4) agree with my recollection of the text
and were not each looked up.

Counts recomputed from INDEX.md's table by my own script (derived): 81 rows; all rows semantics 45 / robustness 20 /
code 16; Cerberus rows 43 / 18 / 15; states unchanged 44, fixed 21, fixed-and-refused 1, refused 10; class by state
24/13/6, 11/4/1/2, 9/4/2. They equal the header's. CORPORA.md's program, row, class and group counts recomputed
(derived) and equal, except F12.

Not checked: 47's non-terminating reproducer (the 60 s timeout claim), 18, the multi-translation-unit reproducers
(37-39), the Core-level ones (19, 45), any report the slice did not touch beyond its INDEX row, the Lean engine in
libc mode, the audit's 576 probes as a set, the daggered states other than the sample above, and any quotation
against a primary copy of C17 (none is on the box).

## Findings

### F1 (P1, blocking). Report 20 carries the patch that causes the `WCHAR_MAX` wrong answer and does not say so

The regression is real, on both fork engines:

```
== wcmax_gt0 [--nolibc]            (pristine)
Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}
gcc: [rc=1]
== FORK wcmax_gt0 [--nolibc]
Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
== LEAN wcmax_gt0
Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
```

(`#include <stdint.h>` / `int main(void) { return WCHAR_MAX > 0; }`.) The printing program gives
`stdout: "4294967295 0 1 0\n"` on pristine and `stdout: "4294967295 0 0 0\n"` on the fork's oracle, as report 62
records.

The slice records this in report 62's fork-status paragraph and in INDEX row 62. It is absent from report 20, which
is the report whose "Proposed remedy (the fork's fix, a patch against `c3ff8c53f`)" a maintainer would apply, whose
status line says "Draft for upstream, to be filed", and whose only word on `wchar_t` under the patch is the
improvement ("With the patch `wchar_t` arithmetic is done in `int`, so `wchar_t w = 100000; (w - 200000) < 0` no
longer reports a false UB036"). INDEX row 20 reads `fixed (D14) †` with no qualification. A maintainer who takes
report 20 at its word gets a new silent wrong answer on a program pristine answers correctly. The charter's M1 asks
for the report texts that are wrong or stale to be corrected; this one became wrong by a fact the worker itself
found.

Needed before merge: report 20 states the consequence beside the patch (the program, pristine 1, patched 0, gcc 1,
and that the patch should not be applied without aligning the `wchar_t` range), and INDEX row 20's state is
qualified. The regression itself is for the operator: a silent wrong answer of the fork stands on the mainline
today.

### F2 (P2). The regression has no fork-side record, and its cause is asserted, not shown

- Its only homes are two upstream-facing files (report 62, INDEX row 62) and a commit message. `TODO.md`,
  `CONTRACT.md` D14 and `docs/2026-11-04_macro-type-ranks-record.md` do not mention it (`grep WCHAR_MAX` over the
  three: no hit). D14's row still says "196 wrong before, 0 after on every program both sides complete"; that matrix
  had no program reading `<stdint.h>`'s `WCHAR_MAX`. The worker's account says it was raised with the operator in the
  slice's chat report, which is not a record.
- Report 62 says "Since the fork's integer-rank change (contract D14 …)" as fact. No pre-D14 fork binary was run by
  the worker or by me. What reading supports: `git log c3ff8c53f..HEAD -- frontend/model/ail/ailTypesAux.lem` has one
  semantic commit, `9b15a1f69` (the others are Lean-only `declare` lines and a comment scrub); it normalises `Wchar_t`
  to `Signed Int_` before the rank comparison; D14's own row lists "`wchar_t` and enums promote to `int`" as a
  consequence by construction; `impl_mem.ml:2243` still groups `Wchar_t` with the unsigned maxima; and the fork
  answers `(long long)WCHAR_MAX` with 4294967295 while `WCHAR_MAX > 0` is 0, which is what a promotion of that value
  to `int` gives. The other fork-ahead deltas since the base (D15-D18) do not touch integer typing. So the attribution
  is right as far as reading goes; the write-up should say it was established by reading and not by a bisect.
- I probed two neighbours for the same effect and found none: `WINT_MAX > 0` is 1 on pristine, fork and gcc;
  `(long long)WCHAR_MAX > 0` is 1 on all three.

### F3 (P2). The tray's README, the page upstream is told to start at, describes a state that no longer exists

INDEX.md's first line sends Cerberus developers to README.md. The slice did not touch it (the worker said so). It now
contradicts the material the slice added:

- "All citations and reproducer runs are against `b9aeedcb4` (2026-08-13)"; the slice re-ran at `c3ff8c53f`.
- "The Lean port is meant to compute exactly what Cerberus computes, including where we believe Cerberus is wrong
  … Today that list has three entries"; INDEX now shows 21 reports fixed in the fork and 10 refused.
- Its triage table stops at report 35 and lists 01, 04 and 15 as live; all three are closed as fixed upstream.
- "So far two issues have been filed … Nothing else has been submitted" against INDEX's four Sent reports; "Nothing
  further is in preparation" against reports 36-77.
- It calls INDEX.md "the ranked list of drafts", defines one classification (TRUE BUG / INTENDED GAP / UNCLEAR) and
  says nothing of the new CLASS and STATE columns or of CORPORA.md, so a reader meets two classification schemes
  with one explained.
- "where an output is cut short, the draft says so" (see F11).

For documents whose stated reader has no knowledge of the fork, the guide is the first thing read. It should be
brought up to date in this slice or the merge should say plainly that the tray is not yet presentable.

### F4 (P2). Report 31 still opens with a quotation that is not in the standard it names

The Description still reads: C17 §7.22.3.2#2 "(the C11 text as clarified by DR 460): … If the product of `nmemb` and
`size` would overflow `size_t`, the `calloc` function returns a null pointer". The slice's correction is appended at
the end of the file and says the sentence is not in `tools/n1570.html` and could not be checked against C17. A
maintainer reads the false quotation first, and the remedy's code comment (`/* C17 §7.22.3.2 */`) leans on it.

What I could establish without a primary copy: n1570's 7.22.3.2 is two sentences plus "returns either a null pointer
or a pointer to the allocated space" (read from `tools/n1570.html:18189-18193`). A web search's result summaries
(secondary: WG14 N2810 "calloc overflow handling", a C23 proposal; an ESBMC issue comparing the editions) say C17's
text is the same and that the explicit wraparound wording arrived with C23 (7.24.3.2). My recollection agrees, and
also that DR 460 concerns `aligned_alloc`, not `calloc`; neither recollection was checked against the documents
themselves. The quotation and the DR attribution should be removed from the Description in place; the claim stands
on #2 and #3 as the appended paragraph already argues.

### F5 (P2). Corrections are appended at the bottom while the text a reader meets first stays wrong

The worker's [AGENT] decision was to append dated sections and leave earlier text as a record of its date. For an
upstream reader that leaves:

- 21: the title still says "every integer arithmetic operator drops pointer provenance"; the appended section shows
  a bitwise `&` keeps it.
- 15: closed as fixed in the base, but with no status line at the top (01 and 04 got one in this slice).
- 22, 34, 62, 63: the "Affected" lines at the top still cite `b9aeedcb4` or fork line numbers; the `c3ff8c53f` loci
  are at the bottom.
- 31: F4.

Each of these needs a one-line status at the top pointing at the dated section, and 21's title needs narrowing.

### F6 (P2). Report 33 is counted as "answered in the base" while its own re-run says the question stands

INDEX's opening paragraph lists 33 among the reports "closed in this index as fixed upstream", its row says
`unchanged (answered in the base) †`, and the counts carry it as one of four "fixed or answered in the base". The
section this slice appended to report 33 says, correctly, that `cee382443` "concerns branching; the additive
operator's verdict asked about here is the same today as when the question was written" (re-run:
`Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<1:33--1:44>"}`; the commit's own message is about
branching on an unspecified value only). Report 33's question is about the additive operator. The two documents
disagree and the slice does not flag it. The closure rests on a [USER 2026-10-29] ruling, so this is a conflict to
raise with the operator, not one for an agent to settle either way. Minor: the re-run's program
(`int y = (x & 0) + 3; return y;`) is a variant of the report's reproducer, under a heading that says "the
reproducer's verdict".

### F7 (P2). Report 73's Impact overclaims, against its own control

"Statement expressions with statements inside are the body of most `MIN`/`MAX`/`container_of`-style macros." Those
macros are declarations followed by a final expression, the shape the report's Description says runs, and its own
control `se-04-min-macro` runs on pristine (`Defined {value: "Specified(2)", …}`, gcc 2). The failing shapes are an
assignment, `++` or `if` as a statement inside the block. The Impact paragraph should name those.

### F8 (P3). CLASS of report 47

By the header's own definition ("crashes … or does not terminate where … a diagnostic belongs") 47 is `robustness`:
its three original reproducers hang or die with `Not_found`, and two of the three new operands die on an assertion.
It is classed `semantics` because the title-is-the-crash rule looks at the title only. Moving it changes the derived
counts (semantics 42, robustness 19 for Cerberus reports; fixed 12 and 5). The other classes I looked at are
defensible under the stated rules, including the two the rules had to name (01 and 39 as `code`, the library
defects by symptom).

### F9 (P3). Report 72: a macro name and a universal

"reached from `vfscanf` through `shlim(f, 0)`": at `c3ff8c53f` the macro is `fshlim` (`internal.h:43`
`#define fshlim(f, lim) __shlim((f), (lim))`, `vfscanf.c:79`). "every call, whatever the format": an empty format
does not reach it (`sscanf("x", "")`: `Defined {value: "Specified(0)", …}` on pristine).

### F10 (P3). Report 10: gcc's value of `'\0123'`

"gcc's is the last character, 51": gcc's value for the two-character constant is 2611 (0x0A33); 51 is what the
reproducer's `(unsigned char)` cast leaves. The exit status quoted is right.

### F11 (P3). "Verbatim" blocks cut without saying so

The backtraces in 73, 74, 75, 77 and the appended sections of 08, 12, 34, 47, 62, 63 stop after two to five lines of
a longer trace (74's is 24 lines on pristine), and 72's omits the `Time spent` line. What is shown is exact. The
README promises that a cut is stated; "first lines" in each caption would do.

### F12 (P3). CORPORA.md

- "The two `parity-probes/uncertainty` directories (58 files together, derived)": I count 55 (41 + 14,
  `find … -type f | wc -l`).
- `tests/address_constants/pristine.txt`'s third column is described as "the Lean engine's" line under a heading
  that defines `pristine.txt` as un-forked upstream's output. The file's own header says that column is the fork's
  Lean engine before the change. Upstream has no Lean engine; the sentence should say whose it is.
- The runner works as written. With the fork's driver the three commands print `SAME-AS-GCC`; with pristine the first
  leaves an empty `got.txt` and the other two equal `pristine.txt`'s second field, as the page says.

### F13 (P3). Fork vocabulary in the new reports

The Provenance sections of 72-77 and some bodies use terms a maintainer cannot resolve: "failure-register row 183",
"cluster P", "sibling probe `sscanf_d`", "sibling findings 20 and 21", "the half-mirrors slice", "contract D10",
"Reported, not refused in code". None changes a claim; a plain sentence each would serve the stated reader better.

### F14 (P3). Stale statements left in INDEX.md and report 62

- Rows 62 and 63: "the fork plans declared refusals in place of the crashes ([USER 2026-10-20], queued)", and report
  62's Origin says the same. The roadmap of 2026-11-10 lists crash-to-refusal as not started unless a consumer needs
  it, and the new sections say "not refused in code".
- The 2026-10-20 paragraph still says of reports 04 and 15 that "the operator's ruling is pending — their tray files
  are unchanged here"; both were closed and both files changed in this slice.
- The "Submission status" block is headed "Reconciled 2026-09-25 … at `c13a105…`".

### F15 (note). What I found no fault with

No operator text is quoted in any added line (the two `[USER …]` tags added are date tags on paraphrases). I found no
statement about upstream's plans or intentions; the nearest are 76's "INTENDED GAP" (the README's term, justified
from the stub's own text) and 72's remark that the idiom is harmless in musl. Report 18 says plainly that it was
not re-run and must be checked against `9f23c62b3` before filing. The diff touches only `lean_frontend/docs/` and
`lean_frontend/TODO.md`. The TODO header deletes and renumbers nothing.
