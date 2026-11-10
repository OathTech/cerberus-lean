# A reader's guide for the Cerberus developers

This page is for the maintainers of [rems-project/cerberus](https://github.com/rems-project/cerberus)
who have been pointed at this repository to look at the bug reports we have drafted against Cerberus. It explains what
this project is, how the reports came about, how to read one, and what to trust. The table of all reports with their
state is [INDEX.md](INDEX.md); the reports are the numbered files next to it; the test programs that go with them are
described in [CORPORA.md](CORPORA.md).

Last brought up to date: 2026-11-10 ([AGENT 2026-11-10]). Everything dated here was true on that date.

## 1. What this repository is

`cerberus-lean` is a fork of Cerberus that carries a Lean 4 port of the Cerberus C semantics. The Lean code under
`lean_frontend/generated/` is generated from the **same `.lem` sources** as Cerberus's OCaml implementation, by a Lean
backend we added to Lem (in a sibling repository, `lem-lean`). The parts that Cerberus implements directly in OCaml
rather than in Lem — the concrete memory model, the Core text parser, constant decoding, the
implementation-defined-behaviour tables, the command-line driver and nondeterministic runner — are hand-written Lean
that mirrors the OCaml line by line, with `file:line` citations in the source. The C parser is not ported: the `cerberus`
binary parses C and emits the Cabs AST as JSON, and the Lean pipeline takes over from there (desugaring, Ail typing,
elaboration to Core, Core execution).

The port is validated by differential execution: every test program is run through both implementations and the full
verdict lines are compared — `Defined` values, exact undefined-behaviour codes, errors, and stdout/stderr where
applicable. Three reference points are used: the OCaml Cerberus built from our fork's sources; an un-forked upstream
checkout pinned at the fork's merge-base, which separates "our fork's behaviour" from "upstream's"; and, for programs
whose behaviour is fully defined and deterministic, the same program compiled with gcc. This is why the port produced
bug reports: porting means reading every line of the OCaml against the model it implements, and differential testing
surfaces every place where two implementations of the same semantics disagree — or where both agree with each other
and disagree with gcc.

**The merge-base is upstream commit `c3ff8c53f` (2026-09-30).** It was `b9aeedcb4` (2026-08-13) until 2026-10-30, and
the reports written before then cite that commit.

## 2. Our stance toward upstream, and what the fork does with these reports

The Lean port is meant to compute exactly what the fork's OCaml Cerberus computes. The fork itself started as a
faithful mirror of upstream, including where we believed upstream wrong, and has since moved ahead of upstream in two
declared ways, both of which change the fork's OCaml and Lean engines together:

- **Fixes.** Where the standard is very clear and upstream's behaviour is a demonstrable mistake, the fork fixes it
  and the report carries the patch or describes it.
- **Refusals.** Where upstream gives a wrong answer or crashes and the right answer is a judgement about C that we do
  not want to make for you, the fork stops with a declared, attributed refusal instead. A refusal is not a fix: the
  report still asks for the feature or the verdict.

Everything else is unchanged: the fork behaves as upstream does at `c3ff8c53f`, and the report describes upstream.
Of the 76 reports against Cerberus (counts derived from INDEX.md's table on 2026-11-10): 44 are unchanged in the fork
(3 of those because upstream had already fixed them before `c3ff8c53f`: 01, 04, 15), 21 are fixed in the fork, 10 are
refused, and 1 (26) is fixed in part and refused in part. One of the fixes has a known defect that makes its patch
unsafe to apply as written (report 20: read the warning at its top).

We are not asking you to adopt anything from the Lean port. Every report stands on a reproducer that runs on plain
upstream `cerberus`.

## 3. How to read a report

Each report is a self-contained issue report. The layout varies between the older and newer files, but every one
contains:

- **Title** and **affected code**, cited as `file:line`. Reports written or re-run on 2026-11-10 give the lines at
  `c3ff8c53f`, either in the body or in a "Loci at `c3ff8c53f`" paragraph at the top; a report without one cites
  `b9aeedcb4` and has not been re-checked at the newer commit.
- **Classification**, in the report's own words: **TRUE BUG** — the code's evident intent and its behaviour disagree,
  or a legal program is mishandled; **INTENDED GAP** (also written KNOWN LIMITATION) — the behaviour is acknowledged in
  a `TODO` or comment, and we report it only because its consequence seemed disproportionate or worth confirming;
  **UNCLEAR** — we could not determine intent from the code and the report is framed as a question.
- **Reproducer**: a short C program, unless the report is a question or a code-audit finding with no executable
  witness (01).
- **Output**: the tool's output, pasted, with the date it was captured and the build it came from. What is shown is
  exact. A block that stops before the end of the output says so on its last line (`[… N more lines cut]`) in the
  reports written or extended on 2026-11-10; in older reports a backtrace may be cut after its first lines without
  a marker. Verdict blocks show standard output only: the driver's `Time spent: …` line on standard error is omitted
  throughout.
- **Observed vs expected**, the **mechanism** as far as we traced it, the **ISO C clause** where one applies, an
  **impact** note, and a **proposed remedy** (often a sketch — a suggestion, not a demand). Clause numbers were checked
  against the C11 text shipped with Cerberus (`tools/n1570.html`) where the report says so; no copy of C17 was
  available on the machine these were written on, and one report (31) was withdrawn as a C17 defect report for that
  reason.
- A **re-run section** at the end, in the reports revisited on 2026-11-10, giving that day's output on un-forked
  upstream at `c3ff8c53f` and on gcc 13.3.0. Where a re-run contradicts older text, a status line at the top of the file
  says so.
- A **provenance** note saying how the finding was made.

INDEX.md adds two columns of its own to every report, explained at the head of its table: **CLASS** (`semantics`, a
question of C's meaning; `robustness`, a crash, internal error or hang; `code`, an artifact of the present code) and
**STATE in the fork** (`fixed`, `refused`, `unchanged`). The CLASS is a coarser, second classification made on
2026-11-10 across all reports; it does not replace the report's own.

Every reproducer runs on plain upstream `cerberus` with the flags shown; no Lean is needed. The two command shapes used
throughout are

```
cerberus --exec --batch --nolibc prog.c     # no C library (most reports)
cerberus --exec --batch prog.c              # with the shipped libc (snprintf, memcmp, ...)
```

and, where gcc is used as the independent reference, `gcc -std=c11 -w -O0 prog.c && ./a.out; echo $?` (gcc 13.3.0).
Reports 02, 03 and 35 also use the Core text form: `cerberus --nolibc --pp=core prog.c > prog.core` to print the
elaborated Core, and `cerberus --nolibc --exec --batch prog.core` (or `--pp=core prog.core`) to read a `.core` file back.

## 4. Triage table

All 76 reports against Cerberus, in number order (54 is unused). The CLASS and STATE columns are copied from INDEX.md
(derived, 2026-11-10; INDEX.md is the authority and carries the qualifications in full).

| Report | One-line summary | CLASS | STATE in the fork | Note |
|---|---|---|---|---|
| [01](01-float-mul-is-addition.md) | `Cerb_floating.mul` is defined as `(+.)` (defacto model float multiplication; filed: issue 1009) | code | unchanged (fixed in the base) | CLOSED: fixed upstream before `c3ff8c53f` |
| [02](02-pp-core-unparseable-forms.md) | `--pp core` prints bodyless `proc` decls the grammar rejects; `Cfunction(f)` re-parses as NULL | code | unchanged |  |
| [03](03-pp-core-ambiguous-output.md) | `--pp core` output re-parses to a different tree (`if` operands, `;`-sequences) | code | unchanged |  |
| [04](04-null-pointer-arith-crash.md) | `p + 1` on a null pointer: uncaught `Failure("TODO…")` instead of a UB verdict | robustness | unchanged (fixed in the base) | CLOSED: fixed upstream before `c3ff8c53f` |
| [05](05-va-arg-missing-type-check.md) | `va_arg` performs no type-compatibility check (acknowledged TODO); the gap is observable | semantics | unchanged |  |
| [06](06-funinfo-has-proto-question.md) | `funinfo.has_proto` differs between declaration and definition entries; its runtime uses look dead | code | unchanged |  |
| [07](07-symbol-identity-fragility.md) | symbol identity rests on an implicit shared-counter invariant; equality ignores names | code | unchanged |  |
| [08](08-desugar-nested-init-internal-error.md) | nested braced initializers desugar to `AilEinvalid`; uncaught internal error | robustness | unchanged |  |
| [09](09-address-constant-member-rejected.md) | `&arr[i].field` address constant rejected in a static initializer | semantics | fixed (D17) |  |
| [10](10-decode-rejects-question-escape.md) | `'\?'` simple escape has no decoder arm; uncaught `Failure` | robustness | fixed (D18) |  |
| [11](11-escaped-char-octal-roundtrip-corruption.md) | `escaped_char` decimal `\ddd` read back as octal: `%c` of 127 stores 87 | semantics | fixed (D18) |  |
| [12](12-bswap64-overflow-crash.md) | `__builtin_bswap64` raises `Z.Overflow` for arguments ≥ 2^63 | robustness | unchanged |  |
| [13](13-memcmp-hugesize-overflow-crash.md) | `memcmp` with a huge size raises `Z.Overflow` where a UB verdict belongs | robustness | fixed (D18) |  |
| [14](14-ailname-proxy-shadows-user-functions.md) | Core stdlib `ailname` proxies hijack a program's own `read`/`write`/`open`… | semantics | unchanged |  |
| [15](15-bool-float-conversion-truncation.md) | float→`_Bool` truncates before the compare-to-zero test; non-finite crashes | semantics | unchanged (fixed in the base) | CLOSED: fixed upstream before `c3ff8c53f` |
| [16](16-snprintf-truncation-return-length.md) | `snprintf` returns the truncated length, not the would-have-been length | semantics | fixed (D16) |  |
| [17](17-diagnostic-embeds-symbol-id.md) | unknown-procedure diagnostic embeds the raw fresh-symbol id | code | unchanged |  |
| [18](18-monadic-list-combinators-non-tail.md) | non-tail monadic list combinators: stack depth ∝ aggregate size | robustness | unchanged |  |
| [19](19-dynamic-addrs-never-cleaned.md) | `dynamic_addrs` tracks dynamic allocations by address and is never cleaned: a zero-size `alloc` at the base of a live object makes `free` of that object pass the dynamic check | semantics | unchanged |  |
| [20](20-size-t-integer-rank-uac.md) | `size_t` has no integer conversion rank: arithmetic with `int`-family operands is done at 32 bits | semantics | fixed (D14) |the patch is NOT to be applied as it is: see the warning at the top of the report |
| [21](21-provenance-lost-through-arithmetic-pvi.md) | Under the default (PVI) model, integer addition drops pointer provenance (a bitwise `&` keeps it): `(int*)((unsigned long)p + 4)` is UB043 — is this intended? | semantics | unchanged |  |
| [22](22-ptrdiff-strips-array-layer.md) | pointer difference over pointers to arrays divides by the inner element size | semantics | unchanged |  |
| [23](23-string-literal-init-of-char-array-members.md) | string literal initialising a `char`-array element/member rejected (`char a[2][3] = {"ab","cd"}`) | semantics | unchanged |  |
| [24](24-stdio-buffer-not-flushed-at-exit.md) | `FILE`-buffered stdout never flushed at termination (return from `main`, `exit()`) | semantics | fixed (D15) |  |
| [25](25-atexit-not-run-on-main-return.md) | `atexit` handlers not run on return from `main` | semantics | fixed (D15) | merged into 24 |
| [26](26-printf-star-width-crash.md) | `printf("%*d", …)`: `*` width parsed, then uncaught `Failure("TODO: formatted.lem 6")` | robustness | fixed (D16: the `*` forms); refused (D16: `%n`, `%ls`, `%lc`, `%*%`) |  |
| [27](27-printf-hex-int-argument-ub153b.md) | `%x`/`%X`/`%o` with an `int` argument reported as UB153b | semantics | unchanged |  |
| [28](28-conditional-in-static-initializer.md) | `?:` in a static initialiser rejected as non-constant | semantics | fixed (D17) | merged into 09 |
| [29](29-string-literal-address-constant.md) | `"hello" + 1` not accepted as an address constant in a static initializer | semantics | fixed (D17) | merged into 09 |
| [30](30-strncmp-zero-length.md) | `strncmp(s1, s2, 0)` compares one character | semantics | unchanged |  |
| [31](31-calloc-overflow-check.md) | libc `calloc` multiplies `nmemb * size` without an overflow check (a wrapped request returns a block) — WITHDRAWN as a C17 defect report, kept as a hardening note | robustness | unchanged | WITHDRAWN as a C17 defect report; a hardening note |
| [32](32-float-evaluated-as-double.md) | `float` represented/evaluated as `double` (`TODO:hack`, `sizeof(float) == 8`) while `<float.h>` says `FLT_MANT_DIG 24` | semantics | unchanged |  |
| [33](33-unspecified-operand-exceptional-condition-question.md) | unspecified operand of signed `+` classified as `UB036_exceptional_condition` | semantics | unchanged |a question; its closure as "answered upstream" is under review |
| [34](34-aligned-alloc-zero-alignment-division-by-zero.md) | `aligned_alloc(0, n)`: Core `rem_t` by zero → uncaught `Division_by_zero` | robustness | unchanged |  |
| [35](35-pp-core-grammar-mismatches.md) | Core parser drops `seq_rmw`'s pointer operand (parser bug); printer spellings the grammar rejects (`Cfvfromint`, `wrapI_div`, `pcall(f, )`, `builtin …`, `PtrMemberShift[s, m]`) | code | unchanged |  |
| [36](36-mk-conv-int-bypasses-impl-def-signed-conversion.md) | `Core_eval.mk_conv_int` wraps non-representable SIGNED conversions directly, bypassing the impl-defined `<Integer.conv_nonrepresentable_signed_integer>` that `std.core`'s `conv_int` calls | semantics | unchanged |  |
| [37](37-are-compatible-cross-tu-recursive-struct-nontermination.md) | `Ctype_aux.are_compatible` never terminates on a self-referential struct defined in two translation units (STD §6.2.7#1 structural compatibility recurses through pointer members with no "assumed compatible" set) | robustness | fixed (no contract row; the report's fork-status section) |  |
| [38](38-pememberof-cross-tu-struct-value-tag-identity.md) | `PEmemberof(struct)` rejects a struct VALUE that crossed a translation-unit boundary: "mismatched tags" for two compatible definitions of the same struct (exact tag identity where STD §6.2.7#1 compatibility is what the program relies on) | semantics | unchanged |  |
| [39](39-are-compatible-array-bound-typo.md) | `Ctype_aux.are_compatible_aux` compares an array type's bound with ITSELF: `match (n1_opt, n1_opt)` — `int a[1]` and `int a[2]` are "compatible" wherever the Core-level compatibility predicate is consulted (STD §6.7.6.2#6) | code | fixed (no contract row; the report's fork-status section) |  |
| [40](40-float-literal-hex-subnormal-double-rounding-inherited.md) | Hexadecimal floating constants with a long mantissa and a subnormal value are off by one quantum: `str_fval` delegates to OCaml's `float_of_string`, which rounds twice (INHERITED from the OCaml runtime) | semantics | fixed in the Lean engine only (ISO-fix register R5, no contract row) |  |
| [41](41-struct-flexible-array-member-vs-sized-array-compatibility-question.md) | Question: is `struct S { int n; int a[]; }` INCOMPATIBLE with `struct S { int n; int a[2]; }` across translation units? `Ctype_aux.are_compatible_aux` keeps the flexible array member outside the member list it compares, so the two definitions differ in member COUNT | semantics | unchanged |  |
| [42](42-unary-minus-floating-zero-sign-question.md) | Question: unary minus on a floating ZERO yields +0 — `-x` is elaborated as `0.0 - x`, where IEEE 754 §5.5.1 / C11 Annex F negation gives −0 | semantics | unchanged |  |
| [43](43-many-many1-input-indexed-recursion-proposal.md) | Proposal: `many`/`many1` as input-indexed recursion — a termination-checkable formulation of the two parser combinators, extensionally identical to the current one | code | unchanged |  |
| [44](44-concrete-allocator-euclidean-align-down-overlap-at-exhaustion.md) | `Concrete.allocator` (and the VIP twin) SUCCEEDS with an overlapping, misaligned object once the address space is exhausted below the request: the align-down step is a truncating-division idiom applied to a Euclidean `quomod` | semantics | fixed (no contract row; the report's fork-status section) |  |
| [45](45-core-match-pattern-truncating-zip-arity.md) | `Core_aux.match_pattern` and `Core_typing.typecheck_pattern` zip tuple patterns with Lem's TRUNCATING `List.zip`: a tuple pattern of the wrong arity MATCHES (binding a prefix) and TYPECHECKS (surplus sub-patterns dropped) | code | fixed (no contract row; the report's fork-status section) |  |
| [46](46-function-pointer-number-is-a-fresh-supply-artefact.md) | Question: a function pointer's integer value is the symbol's fresh-counter number | semantics | unchanged |  |
| [47](47-alignas-incomplete-type-not-diagnosed.md) | `_Alignas(type-name)` never checks that the type is complete: a §6.5.3.4#1 constraint violation is accepted, and the program then hangs or crashes with `Not_found` instead of being diagnosed | robustness | fixed (no contract row; the report's fork-status section) |  |
| [48](48-funptrmap-keyed-by-number-conflates-libc-statics.md) | The concrete model's function-pointer map is keyed by symbol number alone; in libc mode a user function can take over a libc static's entry | semantics | unchanged |  |
| [49](49-par-results-returned-in-reverse-thread-order.md) | Core `par(e1, …, en)` returns its results in reverse order: a `List.reverse` was lost when `par` moved into `core_reduction` (2019) | semantics | unchanged |  |
| [50](50-switches-parser-fail-open.md) | `--switches`: an unknown or a conflicting switch name is ignored with a stderr note and the run proceeds, so a typo silently runs a different memory model | code | refused (R-PNVI-11, R-PNVI-12; no contract row) |  |
| [51](51-combine-prov-crash-on-pnvi-litmus.md) | PNVI-ae-udi: `combine_prov` crashes on four files of the PNVI litmus suite (`found a Prov_symbolic`) | robustness | refused (R-PNVI-01; no contract row) |  |
| [52](52-debug-printf-in-eff-array-shift-pnvi-arm.md) | PNVI-ae-udi: a debug `Printf.printf` to stdout in a semantics arm of `eff_array_shift_ptrval` | code | refused (R-PNVI-10; no contract row) |  |
| [53](53-array-shift-ptrval-crash-on-symbolic-pointer-memcpy.md) | PNVI-ae-udi: `memcpy` from a symbolic pointer crashes (`array_shift_ptrval found a Prov_symbolic`) | robustness | refused (R-PNVI-06; no contract row) |  |
| [55](55-ub088-reported-regardless-of-use.md) | `UB088_reached_end_of_function` is reported whether or not the caller uses the value (stricter than ISO §6.9.1#12) | semantics | unchanged |  |
| [56](56-memcpy-overlap-copies-silently.md) | `memcpy` on overlapping objects copies silently: the memory model's `memcpy` has no overlap check, so a C17 §7.24.2.1 UB program gets a defined verdict | semantics | refused (D10) |  |
| [57](57-aligned-alloc-invalid-alignment-allocates.md) | `aligned_alloc(3, 9)` allocates: the proxy checks only that `size` is a multiple of `alignment`, never that the alignment is valid (C17 §7.22.3.1 requires a null return; C11 made it UB) | semantics | refused (D10) |  |
| [58](58-relative-runtime-library-location.md) | Literal library-directory test misclassifies aliased spellings of the runtime, including cpp's own `./` header positions | code | fixed (no contract row; quotation hygiene Q1) |  |
| [59](59-union-initializer-desugaring.md) | Union initializers: the desugarer builds every braced union initializer as the FIRST member (its own TODO), and three neighbouring initializer defects it does not record | semantics | refused (D11: part (a)); parts (b), (c) unchanged |  |
| [60](60-anonymous-members-spliced-into-containing-aggregate.md) | Anonymous struct/union members are spliced into the containing aggregate: wrong layout, no aliasing inside an anonymous union, and initializers one slot late | semantics | refused (D12) |  |
| [61](61-compound-assignment-duplicates-left-operand.md) | Compound assignment is elaborated with the left operand duplicated: a side effect in the lvalue runs twice, and `a[i++] += v` is reported as UB035 | semantics | refused (D13) |  |
| [62](62-wchar-t-unsigned-range-signed-representation-crash.md) | `wchar_t` is given the unsigned range by the memory model but a signed representation by the implementation: a negative `wchar_t` value crashes the tool | robustness | unchanged |the fork has one more wrong answer here than upstream (`WCHAR_MAX > 0`); see the report |
| [63](63-character-decoding-crashes-on-multichar-and-utf8.md) | `decode_character_constant` crashes on a multi-character constant and on any non-ASCII byte in a string literal | robustness | unchanged |  |
| [64](64-recursive-main-guard-bypassed.md) | Recursive-main guard is bypassed by the driver's Eccall reduction | semantics | unchanged |  |
| [65](65-inner-arg-temps-core-symbol-loss.md) | Core pretty-printing merges parameter values and object addresses | code | fixed (no contract row; the fork's printer remedy) |  |
| [66](66-main-inner-arg-temps-comment.md) | Main uses inner_arg_temps despite the exclusion comment | code | unchanged |  |
| [67](67-const-expr-sizeof-struct-not-found-window.md) | Constant-expression sizeof/_Alignof of a struct raises Not_found at c3ff8c53f (regression window b3e11ea33..736690a65) | robustness | fixed (no contract row; the backport of upstream `736690a65`) | fixed upstream after `c3ff8c53f` (`736690a65`) |
| [68](68-printf-floating-conversions-unparsed-false-invalid-format.md) | `printf("%e", 3.5)` (and `%E`, `%g`, `%G`, `%a`, `%A`, `%F`, `%Lf`) is reported as `Invalid_format` undefined behaviour: the formatter parses only `%f` of the floating conversions and no `L` length modifier | semantics | refused (D16) |  |
| [69](69-printf-j-z-t-modifiers-false-ub153b.md) | `printf("%jd", (intmax_t)-7)` is reported as `UB153b_illtyped_argument_for_format`: the `j` modifier's argument test compares the argument's normalised type with the bare `Intmax_t` constructor (and `%zd`/`%tu` reject the corresponding signed/unsigned types) | semantics | fixed (D16) |  |
| [70](70-printf-zero-flag-before-sign-and-hash-f-no-point.md) | `printf("%05d", -5)` prints `000-5`: the `0` flag pads in front of the sign and the `0x` prefix (and over an infinity); `%#.0f` drops the decimal point | semantics | fixed (D16) |  |
| [71](71-unary-minus-floating-zero-loses-sign.md) | `-z` with `z == 0.0` is `+0.0`: unary minus on a floating operand is elaborated as `0.0 - e`, so negating a zero (and the literal `-0.0`) loses the sign | semantics | unchanged |  |
| [72](72-sscanf-false-ub048-null-pointer-subtraction-in-shlim.md) | `sscanf` with any non-empty format is reported as `UB048_disjoint_array_pointers_subtraction`: the shipped library's `__shlim` subtracts the string FILE's null read pointer from its buffer | semantics | unchanged |  |
| [73](73-statement-expression-with-statement-inside-crashes-break-at-sseq.md) | A GNU statement expression whose block contains an assignment, `++` or `if` statement dies with `internal error: break_at_sseq, Cbound` | robustness | unchanged |  |
| [74](74-program-argument-bytes-stored-through-character-decoder.md) | A backslash or a non-ASCII byte in a program argument (`--args`) crashes the tool: `prepare_main_args` stores every `argv` byte through the character-constant decoder | robustness | unchanged |  |
| [75](75-gnu-conditional-omitted-operand-internal-error.md) | The GNU conditional with an omitted operand (`a ?: b`) ends in an internal error; in an integer-constant context the error is an unrelated one (`PEcase, mismatched`) | robustness | unchanged |  |
| [76](76-libc-perror-strerror-stubs-and-missing-declarations.md) | Shipped library gaps on conforming programs: `strerror`/`perror` are `assert(0)` stubs; `<wchar.h>`, `<uchar.h>` and `<float.h>` lack required declarations; `<math.h>` functions are declared but not linked | semantics | unchanged |  |
| [77](77-floating-to-integer-non-finite-z-overflow.md) | Converting an infinity or a NaN to an integer type crashes the tool (uncaught `Z.Overflow` in `ivfromfloat`); an out-of-range finite value is a UB017 verdict | robustness | unchanged |  |

Not for you: `lean4/` (three reports for Lean 4), `ocaml/` (one for the OCaml runtime) and `lem/` (section 5).

## 5. For the Lem authors

If you also maintain Lem: the `lem/` subdirectory holds draft reports
against `rems-project/lem`, in the same format (currently one, a
run-time failure of structural `=` on values containing a set or map
on the OCaml target; see `lem/README.md`). The Lean backend for Lem
itself is a feature contribution, not a bug report; its landing page
is `doc/lean-backend/README.md` in the `lem-lean` repository
(`github.com/OathTech/lem-lean`, branch `mdd/lean-backend`).

## 6. How this work was produced

This port was developed primarily by AI agents (Claude, Anthropic) working under the direction and review of a human
operator. The Cerberus team asked that AI-derived work be labelled as such, and everything here follows that: each
issue body carries an explicit provenance note (the policy is spelled out in INDEX.md, "Provenance labeling policy").
Each report's classification is proposed in the report and reviewed by the operator, who decides what is filed.

Submission state, as recorded in INDEX.md (not a fresh census of the issue tracker): one report is filed,
[#1009](https://github.com/rems-project/cerberus/issues/1009) (report 01, since fixed upstream); issue #1010 (the Core
binary-expression checker ignoring the expected result type, `core_typing.lem:1025`) was filed without a report in
this directory; four reports (10, 11, 13, 40) were communicated privately to the maintainers on 2026-09-26; every other
report is a draft that has not been sent.

## 7. Caveats

- **Two pins.** Reports revisited on 2026-11-10 were run against `c3ff8c53f`; the others against `b9aeedcb4`. Please
  re-run a reproducer on current `master` before acting on it.
- **Not every report was revisited.** The 2026-11-10 pass re-ran the reports named in INDEX.md's note on reports
  72-77. Report 18's reproducer was not re-run, and neither were the multi-translation-unit reproducers (37-39) or the
  Core-level ones (19, 45).
- **Duplicate search.** Reports 02-14 were searched against the upstream issue tracker on 2026-08-23: no duplicates
  found; related but distinct: #154 and #370. Later reports have not been searched; a differently-worded duplicate
  could exist for any of them.
- **Per-report evidence limits**, as recorded in INDEX.md: report 01 was found by code audit; report 05's claim that
  adding the check would change verdicts rests on our review records rather than a preserved side-by-side run; report
  07's observed collision required a modification of our own, so it is a design question, not a defect claim.
- **Fork vocabulary.** Older reports and INDEX.md's notes use this project's internal terms (contract rows `D10`-`D18`,
  slice and record names). They point at files in this repository and are not needed to run a reproducer.

## 8. What was added when

Reports 01-14: August 2026. 15-35: announced here on 2026-09-05. 36-71: added between September and 2026-11-07, each
announced in INDEX.md. 72-77 and the re-run sections: 2026-11-10.

## 9. How to respond

Issues or comments on this repository are welcome, as are replies on any issue we file upstream. The repository owner
is the contact for anything about these reports or the project.
