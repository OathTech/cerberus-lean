# A reader's guide for the Cerberus developers

This page is for the maintainers of [rems-project/cerberus](https://github.com/rems-project/cerberus)
who have been pointed at this repository to look at the bug reports we
have drafted against Cerberus. It explains what this project is, how
the reports came about, how to read one, and what to trust. The
ranked list of drafts is [INDEX.md](INDEX.md); the drafts themselves
are the numbered files next to it.

## 1. What this repository is

`cerberus-lean` is a Lean 4 port of the Cerberus C semantics. The Lean
code under `lean_frontend/generated/` is generated from the **same
`.lem` sources** as Cerberus's OCaml implementation, by a Lean backend
we added to Lem (in a sibling repository, `lem-lean`). The parts that
Cerberus implements directly in OCaml rather than in Lem — the concrete
memory model, the Core text parser, constant decoding, the
implementation-defined-behaviour tables, the command-line driver and
nondeterministic runner — are hand-written
Lean that mirrors the OCaml line by line, with `file:line` citations
in the source. The C parser is not ported: the upstream `cerberus`
binary parses C and emits the Cabs AST as JSON, and the Lean pipeline
takes over from there (desugaring, Ail typing, elaboration to Core,
Core execution).

The port is validated by differential execution: every test program is
run through both implementations and the full verdict lines are
compared — `Defined` values, exact undefined-behaviour codes, errors,
and stdout/stderr where applicable — over the corpora we could get hold
of (Cerberus's own `tests/`, the CN test suite, libxml2 slices, and
csmith-generated programs, among others). Three reference points are
used: the OCaml Cerberus built from our fork's sources; an un-forked
upstream checkout pinned at the fork's merge base, commit `b9aeedcb4`
(2026-08-13), which separates "our fork's behaviour" from "upstream's";
and, for programs whose behaviour is fully defined and deterministic,
native execution of the same program compiled with gcc as an oracle
independent of the Cerberus lineage altogether. This is why the port
produced bug reports: porting means reading every line of the OCaml
against the model it implements, and differential testing surfaces
every place where two implementations of the same semantics disagree —
or where both agree with each other and disagree with gcc.

## 2. Our stance toward upstream

The Lean port is meant to compute exactly what Cerberus computes,
including where we believe Cerberus is wrong. Any difference between
the two (other than failure-message text and resource limits) is
treated as a bug in the port, and Cerberus's own deviations
from ISO C are mirrored faithfully and reported here rather than
silently corrected. The exceptions are a short, explicit list of
ISO-correctness fixes where the port deliberately sides with the
standard against Cerberus. Today that list has three entries, each
with a draft in this directory: the `'\?'` escape decodes to 63
instead of crashing the tool (draft 10; gcc agrees); `snprintf("%c",
127)` stores 127 rather than 87 (draft 11; gcc agrees); and `memcmp`
with a huge size reports the out-of-bounds read as undefined behaviour
instead of dying on an integer-conversion exception (draft 13; the
program is UB, so there is no native answer to compare — this entry is
admitted on the ground that an exception raised by the host language's
integer conversion is not part of the semantics being implemented). Each entry is
recorded in our test baseline as a Lean-differs-from-upstream pair;
when upstream fixes the defect the pair flips to agreement and the
entry is retired.

We are not asking you to adopt anything from the Lean port. Every
report stands on an upstream-only reproducer, and the three patches we
offer (section 5) are ordinary patches against your tree.

## 3. How to read a draft

Each draft is a self-contained issue report. The layout varies a little
between the older and newer files, but every one contains:

- **Title** and **affected code**, cited as `file:line` against
  upstream `master` at `b9aeedcb4`; every cited file was checked to be
  byte-identical to that commit (or the draft says exactly how it
  differs).
- **Classification**, one of three: **TRUE BUG** — the code's evident
  intent and its behaviour disagree, or a legal program is mishandled;
  **INTENDED GAP** (also written KNOWN LIMITATION) — the behaviour is
  acknowledged in a `TODO` or comment, and we report it only because
  its consequence seemed disproportionate or worth confirming;
  **UNCLEAR** — we could not determine intent from the code and the
  draft is framed as a question. The classification comes with its
  justification.
- **Reproducer**: a short C program, unless the draft is a question
  or (draft 01) a code-audit finding with no executable witness.
- **Verbatim output**: the exact tool output, pasted, with the date it
  was captured and the build it came from. "Verbatim" means literally
  pasted, never retyped; where an output is cut short, the draft says
  so.
- **Observed vs expected**, the **mechanism** as far as we traced it,
  the **ISO C11 clause** where one applies, an **impact** note, and a
  **proposed remedy** (often a code sketch — a suggestion, not a
  demand).
- A **provenance** note saying how the finding was made, in the
  newer drafts as a visible section and in the older ones as an HTML
  comment at the end of the file.

Every reproducer runs on plain upstream `cerberus` with the flags
shown; no Lean is needed. The two command shapes used throughout are

```
cerberus --exec --batch --nolibc prog.c     # no C library (most drafts)
cerberus --exec --batch prog.c              # with the shipped libc (snprintf, memcmp, ...)
```

and, where gcc is used as the independent reference,
`gcc -std=c11 prog.c && ./a.out; echo $?`. Draft 35 (and 02/03) also use
the Core text form: `cerberus --nolibc --pp=core prog.c > prog.core` to
print the elaborated Core, and `cerberus --nolibc --exec --batch
prog.core` (or `--pp=core prog.core`) to read a `.core` file back.

## 4. Triage table

Order follows INDEX.md's filing checklist (its ranking by value): the
already-filed draft first, then true bugs, acknowledged gaps, and
questions. "PR" names the branch on this repository that carries a fix
(section 5).

| Draft | One-line summary | Class | Severity | PR |
|---|---|---|---|---|
| 01 | `Cerb_floating.mul` is defined as `(+.)` (defacto model float multiplication) | TRUE BUG | silent wrong value | — (filed: issue 1009) |
| 10 | `'\?'` simple escape has no decoder arm; uncaught `Failure` | TRUE BUG | tool crash on legal input | char-escapes |
| 11 | `escaped_char` decimal `\ddd` read back as octal: `%c` of 127 stores 87 | TRUE BUG | silent wrong value | char-escapes |
| 12 | `__builtin_bswap64` raises `Z.Overflow` for arguments ≥ 2^63 | TRUE BUG | tool crash on legal input | bswap64 |
| 13 | `memcmp` with a huge size raises `Z.Overflow` where a UB verdict belongs | TRUE BUG | tool crash (UB input) | — |
| 14 | Core stdlib `ailname` proxies hijack a program's own `read`/`write`/`open`… | TRUE BUG | legal program refused / spurious UB | — |
| 15 | float→`_Bool` truncates before the compare-to-zero test; non-finite crashes | TRUE BUG | silent wrong value; crash | — |
| 16 | `snprintf` returns the truncated length, not the would-have-been length | TRUE BUG | silent wrong value | — |
| 20 | `size_t` has no integer conversion rank: arithmetic with `int`-family operands is done at 32 bits | TRUE BUG | silent wrong value and control flow | — |
| 23 | string literal initialising a `char`-array element/member rejected (`char a[2][3] = {"ab","cd"}`) | TRUE BUG | legal program rejected | — |
| 22 | pointer difference over pointers to arrays divides by the inner element size | TRUE BUG | silent wrong value | — |
| 24 | `FILE`-buffered stdout never flushed at termination (return from `main`, `exit()`) | TRUE BUG | silent lost output | — |
| 25 | `atexit` handlers not run on return from `main` | TRUE BUG | silent missing side effects | — |
| 27 | `%x`/`%X`/`%o` with an `int` argument reported as UB153b | TRUE BUG (over-strict) | false UB verdict | — |
| 28 | `?:` in a static initialiser rejected as non-constant | TRUE BUG | legal program rejected | — |
| 30 | `strncmp(s1, s2, 0)` compares one character | TRUE BUG | silent wrong value | — |
| 26 | `printf("%*d", …)`: `*` width parsed, then uncaught `Failure("TODO: formatted.lem 6")` | TRUE BUG | tool crash on legal input | — |
| 34 | `aligned_alloc(0, n)`: Core `rem_t` by zero → uncaught `Division_by_zero` | TRUE BUG | tool crash (invalid argument) | — |
| 18 | non-tail monadic list combinators: stack depth ∝ aggregate size | TRUE BUG | robustness (resource) | — |
| 08 | nested braced initializers desugar to `AilEinvalid`; uncaught internal error | TRUE BUG | tool crash on legal input | — |
| 09 | `&arr[i].field` address constant rejected in a static initializer | TRUE BUG | legal program rejected | — |
| 29 | `"hello" + 1` not accepted as an address constant in a static initializer | TRUE BUG | legal program rejected | — |
| 31 | `calloc` has no `nmemb * size` overflow check (upstream evidence only; Lean agrees with the oracle since Z2) | TRUE BUG (minor) | wrong value on overflow | — |
| 17 | unknown-procedure diagnostic embeds the raw fresh-symbol id | TRUE BUG (minor) | diagnostic quality | — |
| 02 | `--pp core` prints bodyless `proc` decls the grammar rejects; `Cfunction(f)` re-parses as NULL | TRUE BUG (if round-trip is intended) | reload fails / silent wrong value | pp-roundtrip |
| 03 | `--pp core` output re-parses to a different tree (`if` operands, `;`-sequences) | TRUE BUG (same condition) | silent wrong tree on reload | pp-roundtrip |
| 35 | Core parser drops `seq_rmw`'s pointer operand (parser bug); printer spellings the grammar rejects (`Cfvfromint`, `wrapI_div`, `pcall(f, )`, `builtin …`, `PtrMemberShift[s, m]`) | TRUE BUG / TRUE BUG (same condition) | silent wrong tree on reload / reload fails | — |
| 04 | `p + 1` on a null pointer: uncaught `Failure("TODO…")` instead of a UB verdict | INTENDED GAP | tool crash (UB input) | — |
| 05 | `va_arg` performs no type-compatibility check (acknowledged TODO); the gap is observable | INTENDED GAP | missed UB verdict | — |
| 32 | `float` represented/evaluated as `double` (`TODO:hack`, `sizeof(float) == 8`) while `<float.h>` says `FLT_MANT_DIG 24` | INTENDED GAP + inconsistency | no single-precision rounding; wrong `<float.h>` facts | — |
| 21 | provenance dropped by every integer arithmetic operator under the default PVI model (`(int*)((uintptr_t)p + 4)` is UB043) | TRUE BUG vs intent / UNCLEAR | question (false UB on a PVI idiom) | — |
| 33 | unspecified operand of signed `+` classified as `UB036_exceptional_condition` | UNCLEAR | question | — |
| 06 | `funinfo.has_proto` differs between declaration and definition entries; its runtime uses look dead | UNCLEAR | question | — |
| 07 | symbol identity rests on an implicit shared-counter invariant; equality ignores names | UNCLEAR | question (for the record) | — |

Not for you: `lean4/01-stack-overflow-handler-deadlock.md` and
`lean4/02-nat-div-mod-literal-folding.md` target Lean 4 (the runtime's
stack-overflow handler; `Nat.div`/`Nat.mod` literal folding), and `lem/`
targets Lem (section 6).

## 5. The three patch branches

Three fixes are prepared as branches on this repository
(`github.com/OathTech/cerberus-lean`), each based directly on
`b9aeedcb4` so it applies to your tree, and each carrying a
`PR-DESCRIPTION.md` at its root (the intended PR text; to be dropped
before merge):

- **`upstream-pr/bswap64`** — one code commit: `__builtin_bswap64`
  reinterprets its argument as a two's-complement int64 before the
  conversion that used to raise, and reads the swapped result back
  unsigned; adds `tests/ci/0345-builtin_bswap64.c`. Fixes draft 12.
- **`upstream-pr/char-escapes`** — three code commits: the missing
  `'\?'` arm; `escaped_char` emitting C octal escapes so the
  encode/decode pair is an inverse; the octal validator no longer
  accepting `'8'`. Adds `tests/ci/0342`–`0344`. Fixes drafts 10 and 11.
  Its description also notes that open issue #154 (`'\xFF'` under
  signed char) appears already fixed at `b9aeedcb4`.
- **`upstream-pr/pp-roundtrip`** — fourteen code commits making
  `--pp core` output round-trip through the Core parser (printer
  parenthesisation and dialect fixes; grammar gaps closed; the
  `Cfunction` and `seq_rmw` re-parse defects), plus
  `tests/run-roundtrip.sh`. On the 113 ci tests that elaborate, its
  fixpoint check goes from 59 passing / 54 failing on `b9aeedcb4` to
  110 / 3; `run-ci.sh` stays at 188 passed. Fixes drafts 02 and 03 and
  more; its description lists what remains.

Each branch's code neighbourhood was audited (2026-08-23) for adjacent
defects that should travel with the fix; all three are complete as
scoped, and the audits are written up in the descriptions. Every
standards claim on the three branches was checked against the N1570
text Cerberus itself embeds and against gcc's behaviour; that pass
found and corrected two mis-cited clause numbers in the char-escapes
description and comments. Every commit carries a `Co-Authored-By:
Claude … <noreply@anthropic.com>` trailer (section 7).

## 6. For the Lem authors

If you also maintain Lem: the `lem/` subdirectory holds draft reports
against `rems-project/lem`, in the same format (currently one, a
run-time failure of structural `=` on values containing a set or map
on the OCaml target; see `lem/README.md`). The Lean backend for Lem
itself is a feature contribution, not a bug report; its landing page
is `doc/lean-backend/README.md` in the `lem-lean` repository
(`github.com/OathTech/lem-lean`, branch `mdd/lean-backend`).

## 7. How this work was produced

This port was developed primarily by AI agents (Claude, Anthropic)
working under the direction and review of a human operator. The
Cerberus team asked that AI-derived code be labelled as such, and
everything here follows that: each issue and PR body carries an
explicit provenance note, every commit on the patch branches carries
a `Co-Authored-By: Claude …` trailer, and the code itself is written
to the surrounding style with no generation residue (the policy is
spelled out in INDEX.md, "Provenance labeling policy"). Each draft's
classification is proposed in the draft and reviewed by the operator,
who decides what is filed. So far two issues have been filed:
[#1009](https://github.com/rems-project/cerberus/issues/1009) (draft
01) and #1010 (the Core binary-expression checker ignoring the
expected result type, `core_typing.lem:1025`; no draft in this
directory). Nothing else has been submitted.

## 8. Caveats

- **The pin is dated.** All citations and reproducer runs are against
  `b9aeedcb4` (2026-08-13). Please re-run a reproducer on current
  `master` before acting on it. A spot-check on 2026-08-23 found
  drafts 01, 10, 11 and 12 still live on master at that date.
- **Duplicate search.** Drafts 02–14 were searched against the
  upstream issue tracker on 2026-08-23 (issues and PRs, open and
  closed, several keyword variants each): no duplicates found. Related
  but distinct: #154 (escape-sequence value semantics, same code region
  as 10/11) and #370 (closed lexer crash on `\e`). Drafts 15–35 have
  not been searched; a differently-worded duplicate could exist for
  any of them.
- **Per-draft evidence limits**, as recorded in INDEX.md: draft 01
  was found by code audit and has not been executed through an
  upstream defacto-model build (the data flow is direct); draft 05's
  claim that adding the check would change verdicts rests on our
  internal review records rather than a preserved side-by-side run;
  draft 07's observed collision required a modification of our own,
  so unmodified upstream has not been shown to misbehave — the draft
  is a design question, not a defect claim.

## 9. Added 2026-09-05 (the drafts announced here earlier are done)

The fifteen drafts announced in the previous version of this section are
now in INDEX.md (its "Added 2026-09-05" block) and in the triage table
above. Pointers, one line each:

- `19-dynamic-addrs-never-cleaned.md` — the `dynamic_addrs` set never
  cleaned in `kill` (Core-level reproducer);
- `20-size-t-integer-rank-uac.md` — `size_t` has no integer conversion
  rank, arithmetic at 32 bits;
- `22-ptrdiff-strips-array-layer.md` — pointer difference strips an array
  layer;
- `23-string-literal-init-of-char-array-members.md` — string-literal
  initialisation of `char`-array members/elements;
- `24-stdio-buffer-not-flushed-at-exit.md` — stdio buffers not flushed at
  termination;
- `25-atexit-not-run-on-main-return.md` — `atexit` handlers not run when
  `main` returns;
- `26-printf-star-width-crash.md` — `printf("%*d", …)` crashes the tool;
- `27-printf-hex-int-argument-ub153b.md` — `printf("%x", int)` reported
  as UB (over-strict);
- `28-conditional-in-static-initializer.md` — `?:` rejected in a static
  initialiser;
- `29-string-literal-address-constant.md` — string-literal address
  constant with offset rejected;
- `30-strncmp-zero-length.md` — `strncmp` with `n = 0`;
- `31-calloc-overflow-check.md` — `calloc` size-overflow check (held for
  a second look before filing, see INDEX.md);
- `32-float-evaluated-as-double.md` — `float` evaluated at `double`
  precision; inconsistent `FLT_MANT_DIG`;
- `21-provenance-lost-through-arithmetic-pvi.md` — provenance lost
  through integer arithmetic (question against the PVI model);
- `33-unspecified-operand-exceptional-condition-question.md` — the
  unspecified-value question;
- `34-aligned-alloc-zero-alignment-division-by-zero.md` —
  `aligned_alloc(0, n)` dies on an uncaught `Division_by_zero`;
- and, not announced: `35-pp-core-grammar-mismatches.md` (four more
  `--pp core` ↔ parser mismatches, one a parser bug), an addendum to
  draft 10 (the string-literal form of `\?`), and `lean4/02` (a Lean 4
  question, not for you).

Nothing further is in preparation from that audit pass; new drafts, if
any, will again be announced in INDEX.md first.

## 10. How to respond

Issues or comments on this repository are welcome, as are replies on
any issue we file upstream. The repository owner is the contact for
anything about these reports or the project.
