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
program is UB, so there is no native answer to compare). Each entry is
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
`gcc -std=c11 prog.c && ./a.out; echo $?`.

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
| 18 | non-tail monadic list combinators: stack depth ∝ aggregate size | TRUE BUG | robustness (resource) | — |
| 08 | nested braced initializers desugar to `AilEinvalid`; uncaught internal error | TRUE BUG | tool crash on legal input | — |
| 09 | `&arr[i].field` address constant rejected in a static initializer | TRUE BUG | legal program rejected | — |
| 17 | unknown-procedure diagnostic embeds the raw fresh-symbol id | TRUE BUG (minor) | diagnostic quality | — |
| 02 | `--pp core` prints bodyless `proc` decls the grammar rejects; `Cfunction(f)` re-parses as NULL | TRUE BUG (if round-trip is intended) | reload fails / silent wrong value | pp-roundtrip |
| 03 | `--pp core` output re-parses to a different tree (`if` operands, `;`-sequences) | TRUE BUG (same condition) | silent wrong tree on reload | pp-roundtrip |
| 04 | `p + 1` on a null pointer: uncaught `Failure("TODO…")` instead of a UB verdict | INTENDED GAP | tool crash (UB input) | — |
| 05 | `va_arg` performs no type-compatibility check (acknowledged TODO); the gap is observable | INTENDED GAP | missed UB verdict | — |
| 06 | `funinfo.has_proto` differs between declaration and definition entries; its runtime uses look dead | UNCLEAR | question | — |
| 07 | symbol identity rests on an implicit shared-counter invariant; equality ignores names | UNCLEAR | question (for the record) | — |

Not for you: `lean4/01-stack-overflow-handler-deadlock.md` targets the
Lean 4 runtime (a stack-overflow handler that deadlocks instead of
aborting), and `lem/` targets Lem (section 6).

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
  as 10/11) and #370 (closed lexer crash on `\e`). Drafts 15–18 have
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

## 9. What is coming

About fifteen further drafts are in preparation from the current
audit pass; they are not yet filed and will be added to INDEX.md as
they are finished. Topics, one line each:

- the `dynamic_addrs` set in the concrete model is never cleaned in
  `kill`, so a zero-size allocation at a live object's base lets
  `free` of that object pass (Core-level reproducer; already drafted
  on a development branch);
- `size_t` gets the wrong integer rank in the usual arithmetic
  conversions, so arithmetic is done at 32 bits;
- pointer difference strips an array layer when scaling;
- string-literal initialisation of `char` array members;
- stdio buffers not flushed at exit;
- `atexit` handlers not run when `main` returns;
- `printf("%*d", …)` crashes the tool;
- `printf("%x", int)` reported as undefined behaviour (over-strict);
- `?:` rejected in a static initialiser;
- a string-literal address constant (with offset) rejected;
- `strncmp` with `n = 0`;
- `calloc` size-overflow check;
- `float` arithmetic evaluated at `double` precision (a literal `TODO`
  in the code, but inconsistent with the shipped `FLT_MANT_DIG`);
- provenance lost through integer round-trips (a question against the
  PVI model), and an unspecified-value question;
- `aligned_alloc(0, n)` dies on an uncaught `Division_by_zero` from
  `rem_t` in the Core stdlib proxy (from the memory-model seam audit).

## 10. How to respond

Issues or comments on this repository are welcome, as are replies on
any issue we file upstream. The repository owner is the contact for
anything about these reports or the project.
