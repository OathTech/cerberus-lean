# The formatter's unparsed and crashing conversions refuse; `*`, `%jd`/`%zd`/`%td`, `snprintf`'s length and the `0`/`#` flags fixed (trays 26, 16, 68, 69, 70) — slice record (2026-11-07)

Branch `fix/printf-refusals`, worktree `worktrees/cerberus-lean-fix/printf-refusals`, from mainline
`mdd/cerberus-lean` = `1e5f2cbca` (merge-base upstream `c3ff8c53f`, Lean 4.35.0, lem `e6d8db5`); charter
`docs/2026-11-07_worker-charter-printf-refusals.md` (commit `d66ae6287`). Worker: Claude Fable 5.1 (agent). Every
judgement below that no operator ruling covers is marked [AGENT]. Status: **M1 (`c732fde49`), M2 (`31de67fac`) and M3 committed, the
focused gates of §6 green on the M2 tree; Tier A and the full battery are the orchestrator's (§6.2/§6.3, appended after
the runs).** The charter's premises held, with two corrections: the charter's line numbers for the `LM_j` arm were the
bump tip's (`:559-560`), pristine `c3ff8c53f`'s are `:530-531` (§2.4); and the `%ls` probe shape the audit used
(`wchar_t w[] = L"ab"`) does not reach the formatter at all (a constraint violation at the wide-string initializer, the
audit's §4 item 6, another slice) — the witness initialises the array elementwise.

## 0. Rulings and standing rules

- [USER 2026-11-04] the fix pass in the audited order; the bar (the container working-practices doc): a fork fix only
  where the standard is very clear or a consumer is blocked, no invented semantics, otherwise a declared refusal and a
  filing; the vicinity rule: fix the mechanism's neighbourhood, probe it, refuse or file what is a judgement call.
- [USER 2026-11-07] this slice dispatched (the charter), in parallel with the address-constants and half-mirrors slices;
  this slice touches `frontend/model/formatted.lem`, its witnesses, pins and documents only.
- [AGENT 2026-11-07, worker] within that bar (§2): the `*` forms are implemented (the charter's option: "the obvious
  loads"), not refused; the vicinity probe's siblings (§3.3) — the `0` flag's placement, `#` on `%f`, a non-`l`
  modifier on `%s`, `%zd`/`%tu` of the corresponding types — are fixed as clear-standard, small implementations; an
  indeterminate `*` argument is a refusal, not a guess; the `j`/`z`/`t` tests are made uniform in either signedness
  (upstream's `l`/`ll` laxity kept, 7.21.6.1#7 names both types for `z` and `t`); the strict tray-27 readings, the
  `DUMMY` verdicts, the padded `%5%`, the space flag on an unsigned conversion and the `%s`-of-a-non-pointer crash are
  kept as upstream's judgement, pinned and filed.
- The refusals take the D11/D12/D13 form (a pure Lem `error` with one attributed text per class), in MONADIC position
  (the arm's value is the memM action): rendered by generation as the oracle's `Cerb_debug.error` (`internal error:
  <text>`, the uncaught `Failure`, exit 125) and the Lean engine's `failwithI … : ndM …` (abort under
  `LEAN_ABORT_ON_PANIC=1`, exit 134), the texts byte-identical; no failure-reach register row (a monadic-ascribed site,
  as the old `CS_n` arm). Mirror doctrine holds by construction (one `.lem`, both engines generated; the generated
  delta is confined to `Formatted`, §2.6). Fail-closed; no new opaque atom; no `set_option`; no hand edit of
  `generated/`; no hand-written seam or proof module changed, so the kernel-replay gate of [USER 2026-10-18] does not
  apply (the fuel forms are unchanged: `printf_aux` and `store_chars_in_array` stay structural, the two fuel'd workers
  untouched, §6).
- Precedents followed: D13 (`docs/2026-10-29_compound-assignment-refusal-record.md`, the Lem-level refusal), D15
  (`docs/2026-11-05_stdio-exit-flush-record.md`, the libc-mode row-1 witness run from the project root), D14
  (`docs/2026-11-04_macro-type-ranks-record.md`, an alias-normalisation fix).

## 1. The defects, as they stood (both engines; pristine `c3ff8c53f` agrees on every row)

`frontend/model/formatted.lem` at pristine `c3ff8c53f` (the fork's copy differed only by the stage-1
`store_chars_in_array` restatement and Lean-target declares outside the cited regions):

1. `:32` `(*   | LM_L *)`, `:40` `| CS_f (* | CS_F | CS_e | CS_E | CS_g | CS_G | CS_a | CS_A *)`, `:133`, `:143`: the
   parser accepts `f` alone among the floating conversions and no `L`, so a conforming `printf("%e", 3.5)` fails to
   parse and is reported as `Invalid_format` UB (the audit's §4 item 1; tray 68).
2. `:742` `| Just FW_asterisk -> error "TODO: formatted.lem 6"`, `:424`/`:585`/`:644` `error "TODO: Formatted.convert,
   * prec"`: `%*d`, `%.*d` and every `*` form die with an uncaught internal error (tray 26).
3. `:697` `| CS_n -> error "WIP: Formatted.convert, CS_n"`; `:624` `CS_s` with any modifier `error "WIP: …CS_s with
   length modifier"`; `:612` `CS_c` with `l` `error "NOT YET SUPPORTED: %lc"` (the audit's §4 item 10).
4. `:530-531` `| Just LM_j -> (Just (Implementation.is_signed_or_unsigned Ctype.Intmax_t), Nothing)`: the argument's
   type is normalised through the alias table (`intmax_t` = `__cerbty_intmax_t` = `Signed Intmax_t` ↦ `Signed Long`,
   `ocaml_implementation.ml:165`) by `is_signed_or_unsigned`, the expected side is not, so `%jd` of an `intmax_t` is
   UB153b (the audit's §4 item 3; tray 69); `:532-535` the `z`/`t` arms test the width and one signedness
   (`is_compatible_with_size_t`: unsigned; `_ptrdiff_t`: signed), so `%zd` of a `long` and `%tu` of an `unsigned
   long` — the types 7.21.6.1#7 names — are UB153b (found by the vicinity probe).
5. `:794` `if n = 0 then Mem.return (Right (U.return 0))`, `:803` `List.length cs'`, `:805` `| _ -> error "TODO:
   snprintf()"`: `snprintf` returns the truncated length, 0 without formatting at `n = 0`, and crashes on a format whose
   conversion reports UB (tray 16; the audit's row 16).
6. `:223-236` `justify`: `replicate d j ++ str` with `j = #'0'` over a result that already carries the sign and the
   `0x` prefix; `:201-205` `expand`'s `#` arm for the floating conversions: `(* TODO: not doing the right thing for
   now *) str` (found by the vicinity probe; tray 70).

The 161-program matrix of §3 before the change (the fork oracle in libc mode; pristine identical on every row but the
D15 locations and `vprintf`): 36 crashes, 52 UB verdicts — 13 of them the false `Invalid_format` of item 1, 8 the false
UB153b of item 4 —, 52 values equal to gcc 13's, 21 values differing from gcc (the snprintf returns, the `0`/`#` flag
rows, the `%p` text, `%5%`, `% u`, `-0.0`). Verbatim (the fork oracle, `--exec --batch`, libc mode, before):

```text
star_width      rc=125  internal error: TODO: formatted.lem 6
star_prec_neg   rc=125  internal error: TODO: Formatted.convert, * prec
n_int           rc=125  internal error: WIP: Formatted.convert, CS_n
lc_wint         rc=125  internal error: NOT YET SUPPORTED: %lc
hs_strict       rc=125  internal error: WIP: Formatted.convert, CS_s with length modifier
sn_ub_insufficient rc=125 internal error: TODO: snprintf()
e_double        rc=1    Undefined {ub: "Invalid_format[[%e]      (the format's newline follows inside the ub text)
jd_intmax       rc=1    Undefined {ub: "UB153b_illtyped_argument_for_format", stderr: "", loc: "<717:10--717:40>"}
zd_long_arg     rc=1    Undefined {ub: "UB153b_illtyped_argument_for_format", stderr: "", loc: "<717:10--717:40>"}
sn_trunc        rc=0    Defined {value: "Specified(0)", stdout: "3:123:1\n", stderr: "", blocked: "false"}
sn_zero_null    rc=0    Defined {value: "Specified(0)", stdout: "0\n", stderr: "", blocked: "false"}
flags_zero      rc=0    Defined {value: "Specified(0)", stdout: "[00005][000-5][000+5][000 5][00005][000ff]\n", stderr: "", blocked: "false"}
flags_hash      rc=0    Defined {value: "Specified(0)", stdout: "[0xff][0XFF][010][0][0][ 0xff][00xff][0xff  |][0x00ff][00000XFF]\n", stderr: "", blocked: "false"}
f_inf           rc=0    Defined {value: "Specified(0)", stdout: "[inf][-inf][       inf][inf       |][0000000inf]\n", stderr: "", blocked: "false"}
f_hash          rc=0    Defined {value: "Specified(0)", stdout: "[3][2.500000][-7]\n", stderr: "", blocked: "false"}
```

(gcc 13.3.0 on the same programs: `[   9]`, `[7]`, `ab`/`2`, `[a]`, `[ab]`, `10`, `[3.500000e+00]`, `[-7]`, `[-3]`,
`6:123:1`, `4`, `[00005][-0005][+0005][ 0005][00005][000ff]`, `[0xff][0XFF][010][0][0][ 0xff][0x0ff][0xff  |][0x00ff]
[0X0000FF]`, `[inf][-inf][       inf][inf       |][       inf]`, `[3.][2.500000][-7.]`.)

## 2. Design (one `.lem`, both engines by generation; the libc C text untouched — the formatter is the Core builtin's model)

### 2.1 The parser and the specifier types

`length_modifier` gains `LM_L`, `conversion_specifier` the seven floating constructors; `lengthModifier` and
`conversionSpecifier` parse `L` and `F e E g G a A` — the full syntax of C17 7.21.6.1#7-#8. A format the parser cannot
parse (`%q`, a trailing `%`, `%ll`, `%hhhd`, `%.5.3d`, `%5*d`, `%*5d`) stays `Invalid_format`: that is the standard's
rule for a malformed specification (7.21.6.1#9), unchanged. Helpers: `isFloatingConversion`, `isIntegerConversion`,
`stringFromLengthModifier`, `stringFromConversionSpecifier` (the texts name the conversion as written: `%e`, `%le`,
`%Lf`, `%ls`), `isDigitChar`/`isLetterChar` (by code point: Lem has no `Ord char`).

### 2.2 The refusals (the D11/D12/D13 form; four text classes; §0)

- `floating_refusal lm_opt cspec` — the `F e E g G a A` conversions and `L` with any floating conversion (so `%Lf`,
  `%Le`): `Formatted.convert: refused - the %<lm><conv> conversion is not implemented (C17 7.21.6.1#8: the a, A, e, E,
  f, F, g and G conversions of a double argument; 7.21.6.1#7: the L length modifier, a long double argument); the
  formatter implements %f and %lf of a double only, and upstream parses none of e, E, g, G, a, A, F and L - the
  constructors CS_F, CS_e, CS_E, CS_g, CS_G, CS_a, CS_A and LM_L are commented out at formatted.lem c3ff8c53f :40 and
  :32 - so it reported a conforming call as Invalid_format undefined behaviour, a silently wrong verdict; the fork
  parses the conversion and refuses rather than decides (upstream-tray report 68, 2026-11-07)`. Why a refusal and not
  the implementation: the floating formatting of `%e`/`%g`/`%a` is a chunk of well-specified work on both engines (an
  OCaml `Printf` form and its `CerbFloat` mirror with the pp-test's zero-discrepancy pin; `L` needs a `long double`
  argument model); queued in TODO with a size. A refusal is the honest interim and never a wrong answer. The
  length-modifier rule is shared with the `%f` arm (`floating`): `hh h ll j z t` with a floating conversion are UB158
  first (7.21.6.1#7), then `L` or an unimplemented conversion refuses, `l` has no effect.
- `n_refusal` — `%n`: `Formatted.convert: refused - the %n conversion (C17 7.21.6.1#8 n: the number of characters
  written so far is stored into the signed int the argument points to; no argument is converted); upstream's arm is
  the uncaught internal error 'WIP: Formatted.convert, CS_n' (formatted.lem c3ff8c53f :697), a crash on a conforming
  call - the fork refuses rather than decides (upstream-tray report 26, 2026-11-07)`.
- `wide_refusal cspec` — `%ls`, `%lc`: `Formatted.convert: refused - the %ls conversion (C17 7.21.6.1#8 s with l: the
  argument points to an array of wchar_t whose wide characters are converted through wcrtomb); upstream's arm is the
  uncaught internal error 'WIP: Formatted.convert, CS_s with length modifier' (formatted.lem c3ff8c53f :624), a crash
  on a conforming call - the fork refuses rather than decides (upstream-tray report 26, 2026-11-07)` (for `%lc`: `c
  with l: the wint_t argument is converted through an ls conversion of a two-element wchar_t array`, `'NOT YET
  SUPPORTED: %lc'`, `:612`). The first text said "converted as if by wcrtomb" (the standard's words); the failure-reach
  selftest's P6 premise asserts that generated `Formatted.lean` has no plain `if` token and does not skip string
  literals, so the two phrases were reworded rather than the gate changed [AGENT].
- `star_refusal what` — a `*` argument the formatter cannot pad by: `Formatted.printf_aux: refused - a * field width
  or precision whose int argument is <an unspecified value | not a constant> (C17 7.21.6.1#5: an int argument supplies
  the field width or precision; the formatter cannot pad by an indeterminate amount); upstream never read the argument
  (the uncaught internal errors 'TODO: formatted.lem 6' and 'TODO: Formatted.convert, * prec', formatted.lem c3ff8c53f
  :742 and :424) - the fork refuses rather than decides (upstream-tray report 26, 2026-11-07)`. The unspecified case is
  witnessed (`int w; printf("%*d", w, 9)`); the non-constant case cannot arise in the concrete memory model (no abstract
  integer value is ever loaded) and has no witness.

Every refusal site is in monadic position: the arm's value is the `memM` action, so a refusal is raised when
`printf_aux` reaches that conversion (after the conversions before it), never at parse time. A first version bound
`floating_unimplemented` as a VALUE (`let floating_unimplemented = floating false …`); both targets are strict, so the
floating refusal was raised on entry to `convert` for EVERY conversion — caught by the after-matrix (every `%d` row
refused), fixed to a unit function before anything was committed [AGENT].

### 2.3 The `*` field width and precision (7.21.6.1#5; the fix chosen over the refusal)

`load_star_argument loc args` reads the next argument exactly as `convert`'s `aux` reads a conversion's: no argument →
`UB153a_insufficient_arguments_for_format`; a type other than `signed int` after `Implementation.normalise_ctype` →
`UB153b_illtyped_argument_for_format` (the formatter's strictness, as the `%c` arm's; a `char` argument is promoted
to `int` by the call, so it passes; a `long`/`unsigned` width argument is UB153b — gcc warns on it); `Mem.load`, then
`Core_aux.valueFromMemValue`: a specified integer value is the number, an unspecified value or a non-constant one the
refusal above. `printf_aux` resolves the width first and then the precision, each before the argument to be converted
(the standard's order): a negative width is the `-` flag plus the magnitude, a negative precision an omitted one; the
resolved `maybe nat` precision is what `convert` and `justify` receive (so upstream's three `P_asterisk` placeholders
are gone, not refused, and `convert`'s signature changed from `maybe precision` to `maybe nat`). `bind_defined` is the
Defined-continuation bind over `memM (either error (U.t 'a))` (an Error, an Undef or a Left passed through
unchanged — the four-arm match upstream repeated at every step), used for the two resolutions, the conversion and
`vsnprintf`; `printf_aux` stays structural on the format list under it (`termination_argument automatic`, Lean derives
it as before).

### 2.4 `j`, `z`, `t` through the alias table (7.21.6.1#7; tray 69)

`is_alias_base ity` normalises the EXPECTED side: `Implementation.normalise_integerType ity` is `Signed`/`Unsigned`
of a base type (`Intmax_t` ↦ `Long`, `Size_t` ↦ `Unsigned Long`, `Ptrdiff_t` ↦ `Signed Long`; `ocaml_implementation.ml:
165-170`, `CerberusImpl.normalise_aliases` arm for arm), and the predicate is `Implementation.is_signed_or_unsigned`
of that base — the argument side already normalised, either signedness accepted (the `l`/`ll` arms' laxity, kept:
`%ld` of an `unsigned long` was accepted before and still is; 7.21.6.1#7 names "size_t or the corresponding signed
integer type" for `z` and "ptrdiff_t or the corresponding unsigned integer type" for `t`, so uniformity is the
standard's own reading for those two and the harmless superset for `j`). The third arm (the alias table mapping a
macro type to something other than `Signed`/`Unsigned`) is a pure `error` — the one new failure-reach register row,
`UNREACHABLE-BY-INVARIANT` (§5). `LM_L` with an integer conversion is UB158 (`mk_diouxX_expected_and_conv` returns
`Nothing` for it; `diouxX` turns that into the verdict); `wrap_is_compatible` is gone.

### 2.5 `snprintf` (7.21.6.5#2-#3; tray 16), the flags (7.21.6.1#6; tray 70), `%s` with a modifier (7.21.6.1#7)

`vsnprintf` formats whatever `n` is, stores `List.take (n-1) cs` with the null only when `n > 0`, returns `List.length
cs`, and passes `printf_aux`'s `Error`/`Undef`/`Left` results through (`bind_defined`) — `snprintf(b, 8, "%d")` is now
`UB153a` as `printf("%d")` is, where it crashed with `TODO: snprintf()`; `snprintf(NULL, 0, "%d", 1.5)` is `UB153b`
where it returned 0 (the format is checked at `n = 0` too). `justify` takes the resolved precision; when the fill is
`0` it splits a leading `-`/`+`/space (what `expand` prepends) and, after it, `0x`/`0X` (only a `#` hexadecimal
conversion produces one; an integer conversion's digits never contain `x`), and puts the zeros between the prefix and
the digits; a floating result carrying a letter (`inf`, `nan`) is space-padded; the `0`-with-precision rule is
unchanged. `expand`'s `#` arm appends the decimal point to a floating result that has none and is a plain
`[-]digits` (so `inf`/`nan` keep none; of the floating conversions only `%f` reaches it). `CS_s` with a modifier other
than `l` is `UB158_invalid_length_modifier` (the rule the `%f` arm already applied; a crash before); `CS_c` with a
modifier other than `l` keeps upstream's `DUMMY "TODO_find_quote_printf_CS_c"` verdict (a placeholder NAME for the
right verdict — upstream's judgement). `isSignedConversion` counts the floating conversions as signed (7.21.6.1#6
`+`); the `#`/`0`-flag admissibility lists in `printf_aux` carry the floating set.

### 2.6 The generated delta, the proofs

`make prelude-src lean-prelude-src` (rc 0, three times: the first version, the strictness fix, the rewording); the
generated delta is confined to `ocaml_frontend/generated/formatted.ml` (551 differing lines against pristine
`c3ff8c53f`'s `formatted.ml`, the stage-1 restatement included) and `lean_frontend/generated/Formatted.lean`; every
new refusal site renders `(failwithI … : ndM …)` (monadic, no register row), the alias-table invariant `(failwithI … :
ctype → Bool)` (pure, one row). `Formatted_lemMeasureProofs.lean` and the two fuel'd workers
(`showNonNegativeWithBasis_aux`, `load_character_array_aux`) are untouched; `check_fuel_forms` is unchanged at 88
workers (§6); no kernel replay owed. Four `unused termination_by` warnings on `generated/Formatted.lean` (the
backend's derived `beq`/`compare` instances of `field_width` and `precision`, `termination_by structural` on
non-recursive functions) are the lem backend's pre-existing class, present on every variant type (`Symbol.lean`
shows the same) — not introduced here, not suppressed; a lem-lean item.

## 3. The vicinity (the instrument `.tmp/printf/gen_probes.py` + `run_matrix.sh`, deleted at slice end)

### 3.1 The matrix

162 programs (161 before the `-0.0` diagnosis probe was added), each run on the fork oracle (libc mode: the library's
`printf` → `vfprintf` → the builtin, the path every linked program takes since D15), pristine `c3ff8c53f` (its own
runtime), the Lean engine (libc mode, `--first`) and gcc 13.3.0 (`-std=c11 -w -O0`, the streams captured separately,
OCaml `String.escaped`), on the tree before the change and on the final M2 tree: every conversion specifier × every
length modifier (`hh h l ll j z t L` and none) × the flags (`- + space # 0`, repeated, combined) × the width/precision
forms (literal, `*`, negative and zero through `*`, `.` alone) × the argument-type matrix (`int`, `long`, `long long`,
`intmax_t`, `size_t`, `ptrdiff_t`, the unsigned forms, `char`/`short` through `hh`/`h`, `double`, `float`, `long double`,
`char *`/`const char *`/an array/`unsigned char *`/`signed char *`, `wchar_t *`, `void *`, `int *`, a null pointer),
`%%` with and without a width, `%c` with `int`/`char`/`'\n'`, `%s` with precisions and widths, `%p`, `INT_MIN`/`LLONG_MIN`
with widths, the malformed formats; `printf`, `fprintf(stderr, …)`, `fprintf(stdout, …)`, `vprintf` through a wrapper,
`sprintf`, `snprintf` (truncation, `n = 0` with a null and a real buffer, `n = 1`, the exact fit, one short, a big
buffer, an empty format, the sizing idiom, `*` inside, a UB format), `vsnprintf` through a user wrapper; the return
values of `printf`/`fprintf`/`snprintf`/`sprintf`.

### 3.2 Results (derived from the matrix files)

Before: 36 crashes, 52 UB verdicts, 52 values = gcc, 21 values ≠ gcc; Lean = oracle on every row but the N4
location inside `vfprintf` and the Lean NaN refusal. After (the final M2 binaries): 16 refusals, 99 values = gcc, 38 UB
verdicts, 8 values ≠ gcc, 1 crash; Lean = oracle on 161 of 162 rows (the NaN refusal, the GAP control), the refusal
texts compared whole, the UB rows with the location projected. The transitions (before class → after class, derived):
66 value = gcc unchanged; 25 crash → value = gcc (the `*` family in every writer); 8 false UB153b → value = gcc
(`j`/`z`/`t`); 12 false `Invalid_format` → refusal (the floating family); 4 crash → refusal (`%n`, `%ls`, `%lc`, the
unspecified `*`); 2 crash → UB158 (`%hs`, `%lls`), 2 crash → UB153a (`snprintf("%d")`, `%*d` with the value missing),
1 crash → UB153b (`snprintf("%d", 1.5)`); 1 `Invalid_format` → UB158 (`%Ld`); 1 value → UB153b (`snprintf(NULL, 0,
"%d", 1.5)`: the format is checked at `n = 0`); 6 value ≠ gcc unchanged + 1 new (the `%p` texts, `%5%`, `% u`, `-0.0`);
1 crash → value ≠ gcc (`%*%`: the `*` consumed, upstream's padding); 13 UB153b, 8 `Invalid_format`, 3 `UB157`, 3
`DUMMY(+)`, 2 UB153a, 1 UB158, 1 `DUMMY(c)` unchanged; 1 crash unchanged (`%s` of an `int`). Verbatim after (the fork
oracle; the Lean engine's line identical on each but the `PANIC …` prefix of a refusal and `<unknown location>` on a UB
row):

```text
star_width      rc=0    Defined {value: "Specified(0)", stdout: "[   9]\n", stderr: "", blocked: "false"}
star_prec_neg   rc=0    Defined {value: "Specified(0)", stdout: "[7]\n", stderr: "", blocked: "false"}
jd_intmax       rc=0    Defined {value: "Specified(0)", stdout: "[-7]\n", stderr: "", blocked: "false"}
zd_long_arg     rc=0    Defined {value: "Specified(0)", stdout: "[-3]\n", stderr: "", blocked: "false"}
sn_trunc        rc=0    Defined {value: "Specified(0)", stdout: "6:123:1\n", stderr: "", blocked: "false"}
sn_zero_null    rc=0    Defined {value: "Specified(0)", stdout: "4\n", stderr: "", blocked: "false"}
flags_zero      rc=0    Defined {value: "Specified(0)", stdout: "[00005][-0005][+0005][ 0005][00005][000ff]\n", stderr: "", blocked: "false"}
flags_hash      rc=0    Defined {value: "Specified(0)", stdout: "[0xff][0XFF][010][0][0][ 0xff][0x0ff][0xff  |][0x00ff][0X0000FF]\n", stderr: "", blocked: "false"}
f_inf           rc=0    Defined {value: "Specified(0)", stdout: "[inf][-inf][       inf][inf       |][       inf]\n", stderr: "", blocked: "false"}
f_hash          rc=0    Defined {value: "Specified(0)", stdout: "[3.][2.500000][-7.]\n", stderr: "", blocked: "false"}
hs_strict       rc=1    Undefined {ub: "UB158_invalid_length_modifier", stderr: "", loc: "<717:10--717:40>"}
sn_ub_insufficient rc=1 Undefined {ub: "UB153a_insufficient_arguments_for_format", stderr: "", loc: "<730:10--730:44>"}
e_double        rc=125  internal error: Formatted.convert: refused - the %e conversion is not implemented (C17 7.21.6.1#8: the a, A, e, E, f, F, g and G conversions of a double argument; 7.21.6.1#7: the L length modifier, a long double argument); the formatter implements %f and %lf of a double only, and upstream parses none of e, E, g, G, a, A, F and L - the constructors CS_F, CS_e, CS_E, CS_g, CS_G, CS_a, CS_A and LM_L are commented out at formatted.lem c3ff8c53f :40 and :32 - so it reported a conforming call as Invalid_format undefined behaviour, a silently wrong verdict; the fork parses the conversion and refuses rather than decides (upstream-tray report 68, 2026-11-07)
n_int           rc=125  internal error: Formatted.convert: refused - the %n conversion (C17 7.21.6.1#8 n: the number of characters written so far is stored into the signed int the argument points to; no argument is converted); upstream's arm is the uncaught internal error 'WIP: Formatted.convert, CS_n' (formatted.lem c3ff8c53f :697), a crash on a conforming call - the fork refuses rather than decides (upstream-tray report 26, 2026-11-07)
star_width_uninit rc=125 internal error: Formatted.printf_aux: refused - a * field width or precision whose int argument is an unspecified value (C17 7.21.6.1#5: an int argument supplies the field width or precision; the formatter cannot pad by an indeterminate amount); upstream never read the argument (the uncaught internal errors 'TODO: formatted.lem 6' and 'TODO: Formatted.convert, * prec', formatted.lem c3ff8c53f :742 and :424) - the fork refuses rather than decides (upstream-tray report 26, 2026-11-07)
```

(the Lean engine on `e_double`: `PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: Formatted.convert: refused -
the %e conversion …` the same text to the end, exit 134.)

### 3.3 Findings (every sibling the matrix found, with its disposition)

| # | finding (before, both engines and pristine) | class | disposition [AGENT 2026-11-07] | after |
|---|---|---|---|---|
| 1 | `%e %E %g %G %a %A %F`, `%Lf`, `%Le`, `%le` → `Invalid_format` UB | silently wrong verdict on conforming input | REFUSED (tray 68; implementation queued) | refusal, both engines |
| 2 | `%*d`, `%-*d`, negative/zero `*` width, `%.*d`, negative `*` precision, `%*.*d`, `%*.*f`, `%*s`, `%.*s`, `%*c`, `%#*x`, `%0*d`, `%*jd`, in printf/fprintf/sprintf/snprintf/vprintf/vsnprintf → crash | crash on legal input | FIXED (7.21.6.1#5; tray 26) | = gcc, 28 rows |
| 3 | `%n`, `%ls`, `%lc` → crash | crash on legal input | REFUSED (tray 26) | refusal |
| 4 | `%jd %ju %ji %jo %jx %jX` of `intmax_t`/`uintmax_t`, `%jd` of a `long`, `%ld` of an `intmax_t` → UB153b | false UB on conforming input | FIXED (7.21.6.1#7; tray 69) | = gcc |
| 5 | `%zd` of a `long`, `%tu` of an `unsigned long` → UB153b | false UB (the corresponding types #7 names) | FIXED with 4, uniformly | = gcc |
| 6 | `snprintf` returns the truncated length; 0 at `n = 0`; the sizing idiom allocates 0 | silently wrong | FIXED (7.21.6.5#3; tray 16) | = gcc, 12 rows |
| 7 | `snprintf` with a UB format (`"%d"` without an argument, `"%d"` of a double) → `TODO: snprintf()` crash | crash on UB input, the verdict lost | FIXED: `printf`'s verdict passed through | UB153a / UB153b |
| 8 | `%05d` of -5 = `000-5`, `%+05d` = `000+5`, `% 05d` = `000 5`, `%012d` of `INT_MIN`, `%025lld` of `LLONG_MIN` | silently wrong | FIXED (7.21.6.1#6; tray 70) | = gcc |
| 9 | `%#05x` = `00xff`, `%#08X` = `00000XFF`; `%010.3f` of a negative = `0000-3.142` | silently wrong | FIXED with 8 | = gcc |
| 10 | `%010f` of an infinity = `0000000inf` | silently wrong (#6: "except … an infinity or NaN") | FIXED with 8 | = gcc |
| 11 | `%#.0f` of 3.0 = `3`, of -7.0 = `-7` | silently wrong (#6 `#`) | FIXED (tray 70) | = gcc |
| 12 | `%hs`, `%lls` → crash | crash on UB input (7.21.6.1#7) | FIXED: UB158 (the `%f` arm's rule) | UB158 |
| 13 | `%Ld` → `Invalid_format` (unparsed `L`) | a UB verdict with the wrong name | now parsed: UB158 (#7) | UB158 |
| 14 | `int w; printf("%*d", w, 9)` → crash | crash (an indeterminate width; UB if `w`'s address is never taken, 6.3.2.1#2) | REFUSED (the formatter does not guess) | refusal |
| 15 | `%x %X %o %u` of an `int`, `%d` of an `unsigned`/`long`, `%ld` of an `int`, `%jd` of a `long long`, `%zd` of an `int`, a `long`/`unsigned` `*` width, `%p` of an `int *` → UB153b | the strict 7.21.6.1#9 reading; gcc warns on most | KEPT (tray 27, REFUSE-AND-FILE) | UB153b, pinned |
| 16 | `%+u`, `%+s`, `%-+ #08x` → `DUMMY(+ flag with unsigned conversion)`; `%hc` → `DUMMY(TODO_find_quote_printf_CS_c)` | upstream's placeholder-named verdicts | KEPT | pinned |
| 17 | `%5%` = `    %` (gcc `%`); `%*%` consumes the int and pads | invalid specification (#8: "shall be %%"), upstream's padding | KEPT, filed with tray 70 | pinned (fork-declared) |
| 18 | `% u`, `% x` = ` 5` (gcc `5`, warns) | the space flag applied to an unsigned conversion; #6 does not declare it UB | KEPT, filed with tray 70 | pinned (fork-declared) |
| 19 | `printf("%s", 5)` → crash `WIP, Formatted => CS_s, ty <> Pointer ==> (signed int, ptr(…))` | crash on UB input | KEPT (a crash is tolerated; not legal input) | unchanged, not in the witness |
| 20 | `%f` of `-0.0` = `0.000000` (gcc `-0.000000`) | silently wrong — but NOT the formatter: `z * -1.0` prints `-0.000000`, `-z` and `0.0 - z` print `0.000000` | OUT OF THE MECHANISM: the negation/subtraction loses the sign before the formatter; TODO names it, tray 70's related finding | unchanged |
| 21 | `%p` of a `void *` prints `(@70, 0xffffffffedf4)`, of a null pointer `NULL(void)` (gcc `0x7ffc…`, `(nil)`) | implementation-defined text | KEPT; `p_null` pinned fork-declared, the address rows left out of the witness (layout-dependent) | unchanged |
| 22 | `%f` of a NaN: oracle `-nan`, Lean the float-format REFUSAL | the declared Lean refusal (CONTRACT §3) | KEPT: the witness's gap control | unchanged |
| 23 | `wchar_t w[] = L"ab"` rejected (`initializing 'wchar_t' with an expression with a non arithmetic type`) | the audit's §4 item 6 (wide string initializers) | another slice; the `%ls` witness initialises elementwise | unchanged |

Rows 1-14 are the mechanism's; the csmith shim's `printf("…checksum after hashing %s : %X\n", …)` (`%s`, `%X`/`%lX` of
an unsigned) is row 15's accepted shape and unchanged.

### 3.4 The witness (`scripts/check_printf_refusals.sh`, row 1 via `test_unit.sh`; `tests/printf_refusals/`, 161 programs)

The stdio script's shape (libc mode from the project root, the metadata TUs from `libc_prep.sh --jsons`, every class
count pinned) with four row classes in `expected.txt` (`name TAB class TAB pin`): VALUE (both engines' batch line =
the pin, exit codes equal; the pin is gcc 13's line from `gcc.txt`, or the fork's declared line for the four
`FORK_PINNED` rows `p_null`, `percent_width`, `space_u`, `star_percent`), UB (both engines' `Undefined` line = the pin
with the `loc` field removed — N4: the oracle locates a libc-mode format UB inside `vfprintf`, Lean at `<unknown
location>`; the verdict, the UB id and every other field must agree), REFUSAL (the oracle's `internal error: <text>`
and `Failure("internal error: <text>")`, exit 125; the Lean `PANIC … LemLib…: <text>`, exit 134; both texts = the pin
whole, and equal to each other), GAP (`f_nan`: the oracle's `-nan` line, the Lean float-format REFUSAL envelope); four
`nolibc_*` controls run both engines under `--nolibc` (std.core's `printf` proxy, the other path to the formatter:
`star_width`, `jd_intmax`, `flags_zero` VALUE = gcc, `e_double` REFUSAL). 161 rows: 105 VALUE (101 gcc-pinned, 4
fork-pinned), 38 UB, 17 REFUSAL, 1 GAP; `pristine.txt` carries pristine `c3ff8c53f`'s lines (a crash as
`CRASH:<first stderr line>`; 75 rows moved, derived). Plants (`--selftest`), each at its derived count on a 15-program
subset: `pristine-pair` 27 (both stubs replay pristine's lines, a crash as upstream's crash), `lean-pristine` 19,
`lean-fixed` 19, `oracle-rc` 18, `expect-tamper` 5 (a VALUE pin and a REFUSAL text each altered by a character),
`lean-other-text` 27. The first derivation of `pristine-pair` said 24 — an addition slip over the per-row checks; the
plant caught it (the script's own plant found the worker's miscount, as the D13 precedent's did) and the comment
carries the corrected sum. Result on the final M2 tree, verbatim:

```text
check_printf_refusals: selftest plant 'pristine-pair' caught: 27 failing check(s) (= expected 27; incl. the required programs)
check_printf_refusals: selftest plant 'lean-pristine' caught: 19 failing check(s) (= expected 19; incl. the required programs)
check_printf_refusals: selftest plant 'lean-fixed' caught: 19 failing check(s) (= expected 19; incl. the required programs)
check_printf_refusals: selftest plant 'oracle-rc' caught: 18 failing check(s) (= expected 18; incl. the required programs)
check_printf_refusals: selftest plant 'expect-tamper' caught: 5 failing check(s) (= expected 5; incl. the required programs)
check_printf_refusals: selftest plant 'lean-other-text' caught: 27 failing check(s) (= expected 27; incl. the required programs)
check_printf_refusals: OK (161 programs, libc mode but for the 4 nolibc controls: 105 VALUE rows with both engines' batch lines equal to the pin and exit codes equal — 101 gcc 13's line (the * field width and precision in every form incl. negative, zero, with flags and modifiers, in printf/fprintf/sprintf/snprintf/vprintf; %jd/%ju/%zd/%zu/%td/%tu with the macro types and their corresponding types; snprintf's would-be length on truncation, at n = 0 with a null buffer, at n = 1, at the exact fit and in the sizing idiom; the 0 flag after the sign and the 0x base, the # decimal point of %f, infinities space-padded; every integer, character, string and %f conversion with its flags, widths, precisions and length modifiers as controls) and 4 the fork's declared lines with gcc's beside them (implementation-defined %p text, upstream's padded %% and space flag on an unsigned conversion); 38 UB rows with the pinned verdict on both engines, the location projected (a snprintf format's UB passed through instead of the crash, a non-l modifier with %s as UB158, the strict 7.21.6.1#9 readings of tray 27 kept, the malformed formats as Invalid_format); 17 REFUSAL rows with the oracle's internal error and the Lean engine's PANIC carrying the identical pinned text (every floating conversion other than %f/%lf, the L modifier, %n, %ls, %lc, an unspecified * argument, in printf and snprintf); 1 gap control (%f of a NaN refused on the Lean engine); 75 rows moved from pristine c3ff8c53f's lines)
```

## 4. Moved rows and pins (gcc the referee)

### 4.1 The sweeps (the instruments `.tmp/printf/candidates.txt` + `sweep_candidates.sh`, deleted at slice end)

The affected forms are text-visible, so the measurement is a regular-expression grep over every corpus the lanes
walk (the `*`, `.*`, `%e/E/g/G/a/A/F/n`, `%L`, `%ls/lc`, `j`/`z`/`t`, `0`-flag, `#…f`, `snprintf` and `hh/h/ll/L`-with-`s`/`c`
forms), then every candidate file run on the oracle BEFORE the change (the snapshot of the pre-rebuild binary, the
live runtime — unchanged by this slice) and AFTER, in both modes. The grep (derived): `tests/minimal` 0 of 113,
`coverage` 13 of 277, `debug` 0/90, `float` 0/93, `bytes` 0/14, `libc_exec` 7 of 44, `multi_tu` 0/16, `multi_tu_tray`
0/14, `immaculate` 5 of 105, `verify` 0/25, `ci` 1 of 253, `pnvi_refusals` 0/3, `stdio_exit` 0/46, `macro_type_ranks`
45 of 106 (the row-1 witnesses, run by their own script), `census` 1/14, `lean_frontend/corpus` 0/16, `libxml2` 1/5,
`noodle-probes` 4/153, `parity-probes` 7/301, `gcc-torture` 16/2858, `bmc` 0/201, `tcc` 1/70, `suite` 0/144, the CN
corpus 1; the csmith corpus 0 of 1669 (its shim's `printf("...checksum after hashing %s : %X\n", …)` / `%lX` lines
are the kept strict-reading shape; nothing there carries a `*`, a floating conversion, a macro-type modifier, a
`0`/`#` flag form or `snprintf`). The 57 candidate files outside `macro_type_ranks`, both modes (114 rows): 33 rows
moved in 19 files, 81 same — census: 0 moved / 2 same; ci: 0 moved / 2 same; cn: 0 moved / 2 same; coverage: 16 moved / 10 same (fmt-003-f-precision-zero.c, fmt-005-f-negative-zero.c, fmt-010-f-width-flags.c, fmt-014-e-unserved-ub.c, fmt-015-g-unserved-ub.c, fmt-020-int-width-flags.c, fmt-022-hex-octal.c, fmt-043-j-intmax-ub.c); gcc-torture: 0 moved / 32 same; immaculate: 4 moved / 6 same (ts-fmt-star-precision.c, ts-fmt-star-width.c); libc_exec: 3 moved / 11 same (026-snprintf-truncation.c, 027-snprintf-exact-fit.c, 028-vsnprintf-wrapper-truncation.c); libxml2: 0 moved / 2 same; noodle-probes: 2 moved / 6 same (lib_printf_star_width.c); parity-probes: 8 moved / 6 same (pf-05-neg-precision.c, pf-09-pct-n.c, printf_float.c, snprintf_trunc.c, sprintf_num.c); tcc: 0 moved / 2 same. The `ci`, `gcc-torture`, `tcc`, `census`, `libxml2` and CN candidates all
SAME: no ci-sweep scoreboard row moves (the TSVs are untouched).

### 4.2 The lanes on the M2 tree (verbatim last lines)

```text
SUMMARY: match=42 loc_only=2 diff=0
ALL MATCH RECORDED BASELINE                                       (test_libc_exec.sh, A5: 026/027/028 both engines at gcc's values, class unchanged)
SUMMARY: total=277 match=223 ub_match=34 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=18 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK                                                        (test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage, A3, after the three rows were re-recorded; the run before the re-record: `REGRESSION: fmt-014-e-unserved-ub.c baseline=UB_MATCH current=CERB_SKIP`, `REGRESSION: fmt-015-g-unserved-ub.c baseline=UB_MATCH current=CERB_SKIP`, `changed (same rank, non-regressing): fmt-043-j-intmax-ub.c baseline=UB_MATCH current=MATCH`, `Baseline check: 2 regression(s), 0 improvement(s)`)
check_macro_type_ranks: OK (106 programs: 103 batch lines of both engines = gcc 13's pinned line, …)   (row 1)
check_stdio_exit: OK (46 programs in libc mode: 34 batch lines of both engines = gcc 13's pinned line, …)   (row 1)
OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip/zd-r2-highbyte DIFF and zd-r2-crash…)   (test_immaculate.sh, on the hand-edited baseline; rc 0)
Independent oracle: subset_passed; {'semantic_agreement': 8, 'reviewed_difference': 13}   (test_upstream_oracle.py --only over the 13 cases + 8 regex neighbours, after the register rows; rc 0. A first --only run after the M2 commit read 3 of the 13 as `difference`: the three coverage programs whose HEADER COMMENTS this slice rewrote after the tier-b run — the engines embed the source line in the UB location, so pristine's recorded signatures were the pre-edit ones; re-derived from that run's captures (the fork's signatures unchanged), the rationale says so)
```

The immaculate lane before the re-record, verbatim: `DEVIATION: ts-fmt-star-width expected [MATCH | L=CRASH] got
[MATCH | L=VAL:{value: "Specified(9)", stdout: "[     7]\n", stderr: "", blocked: "false"}]`, `DEVIATION:
ts-fmt-star-precision expected [MATCH | L=CRASH] got [MATCH | L=VAL:{value: "Specified(6)", stdout: "[007]\n", stderr:
"", blocked: "false"}]` — the two rows hand-edited to the values with a dated note (`--record-baseline` rewrites the
file and drops its history block, so it was not used; the stdio precedent's way). The pristine lane (Tier B row 10)
before the register rows, verbatim: `Independent oracle: failed; {'semantic_agreement': 934, 'reviewed_difference':
24, 'matching_failure': 28, 'difference': 13, 'interface_agreement': 2}` — the 13 differences are exactly the 13 moved
gated rows of 4.3.

### 4.3 The table (both engines agree before and after on every row; pristine `c3ff8c53f` prints the before-lines; gcc 13 the referee)

| row | lane | before (both engines = pristine) | after (both engines) | gcc | disposition |
|---|---|---|---|---|---|
| `coverage/fmt/fmt-014-e-unserved-ub.c` | A3 | `Undefined {ub: "Invalid_format[[%e]]", …}` (UB_MATCH) | REFUSAL `… the %e conversion is not implemented …` (CERB_SKIP) | `[1.000000e+00]` | class move: re-recorded CERB_SKIP, reason in the baseline header; register `missing-feature` |
| `coverage/fmt/fmt-015-g-unserved-ub.c` | A3 | `Undefined {ub: "Invalid_format[%g]", …}` | REFUSAL `… the %g conversion …` | `0.5` | the same |
| `coverage/fmt/fmt-043-j-intmax-ub.c` | A3 | `Undefined {ub: "UB153b_illtyped_argument_for_format", …}` | `Defined {value: "Specified(5)", stdout: "[-7]\n", …}` | `[-7]` | the fix: re-recorded MATCH; register `shared-model-fix` |
| `coverage/fmt/fmt-003-f-precision-zero.c` | A3 | `[3\|3.000000\|3.0]`, status 83 | `[3.\|3.000000\|3.0]`, status 84 | = after | MATCH → MATCH (value); register `shared-model-fix` |
| `coverage/fmt/fmt-005-f-negative-zero.c` | A3 | `…\|0000-0.0]` | `…\|-00000.0]` | = after on that cell; `-0.000000` where both engines print `0.000000` (the negation, §3.3 row 20) | MATCH → MATCH; register `shared-model-fix` |
| `coverage/fmt/fmt-010-f-width-flags.c` | A3 | `000-3.250000\|000000-3.250`, `000000+2.500` | `-003.250000\|-0000003.250`, `+000002.500` | = after | the same |
| `coverage/fmt/fmt-020-int-width-flags.c` | A3 | `00+42\|00 42\|…\|00-42` | `+0042\| 0042\|…\|-0042` | = after | the same |
| `coverage/fmt/fmt-022-hex-octal.c` | A3 | `00000x1f` | `0x0001f` | = after | the same |
| `libc_exec/026-snprintf-truncation.c` | A5 | `Specified(3001)` | `Specified(6341)` | 6341 | MATCH → MATCH; register `shared-model-fix` |
| `libc_exec/027-snprintf-exact-fit.c` | A5 | `5:hello:# 4:hell:# 0:0:#` | `5:hello:# 5:hell:# 2:0:#` | = after | the same |
| `libc_exec/028-vsnprintf-wrapper-truncation.c` | A5 | `9 2 abc--ab`, status 12 | `13 4 abc--ab`, status 13 | = after | the same |
| `immaculate/nolibc/ts-fmt-star-width` | B | `MATCH \| L=CRASH` (`TODO: formatted.lem 6`) | `MATCH \| L=VAL … "[     7]\n"` | `[     7]` | re-recorded by hand; register `shared-model-fix` |
| `immaculate/nolibc/ts-fmt-star-precision` | B | `MATCH \| L=CRASH` (`TODO: Formatted.convert, * prec`) | `MATCH \| L=VAL … "[007]\n"` | `[007]` | the same |

Not gated, moved the same way (the candidate sweep): `tests/noodle-probes/lib/lib_printf_star_width.c` (crash → `[   9]`),
`tests/parity-probes/probes/printf_float.c` (`Invalid_format[%d %.2f %g %s…` → the `%g` refusal), `snprintf_trunc.c`
(`Specified(9)` → `Specified(15)` = gcc), `sprintf_num.c` (the `TODO: snprintf()` crash → `UB153b`), the R-printf
uncertainty probes `pf-05-neg-precision.c` (crash → `[7][7   ]` = gcc) and `pf-09-pct-n.c` (the old crash text → the
`%n` refusal). The `tests/failure-probes/reach` printf probes: §5.


## 5. Register entries

- **Fork-drift manifest (`scripts/fork_drift_manifest.txt`):** two single-row edits with a dated header NOTE
  (`fix/printf-refusals, 2026-11-07`), never `--refresh`: `[source-content]` `frontend/model/formatted.lem` `c630d086…
  → 642760ec…` (re-pinned at each of the three regenerations: the first version, the strictness fix, the rewording and
  the corrected line cite), `[expected-semantic]` `formatted.ml` `afd35a12… → 0e13f202…` (an already-differing file:
  stage 1's `store_chars_in_array` restatement); layer 2 stays at 33 differing files, layer 1 at 95.
- **Failure-reach register (`scripts/failure_reach_register.txt`):** the four `Formatted.convert`/`printf_aux` rows
  of the `* prec` and `formatted.lem 6` sites RETIRED (the sites are gone: `check_failure_reach` reported them STALE
  and the new site NEW, verbatim `NEW pure exec-closure site … Formatted.lean:1371 convert failwithI «"Formatted.convert:
  the implementation's alias table maps in» position=LAMBDA-BODY`); ONE new row, `convert` `is_alias_base`'s alias-table
  invariant, `NON-TAIL/LAMBDA-BODY`, `UNREACHABLE-BY-INVARIANT` (need: the arm passes literal constructors only —
  `Signed Intmax_t`, `Size_t`, `Ptrdiff_t` — and the alias table maps each to a `Signed`/`Unsigned` base), emitted with
  `--emit`, reviewed, resealed (`resealed 235 rows`); 238 → 235 rows. Every refusal site is monadic-ascribed (no row).
  The selftest's P8 plant (the two `Formatted.convert` `* prec` rows' reach classes swapped with their seals) lost its
  premise and was re-targeted onto the register's other key group of the same shape, the two `CerbMem.combineProv`
  R-PNVI-01 rows (`REACHABLE` / `UNREACHABLE-BY-INVARIANT`, one 60-char key) [AGENT]; the P6 premise (no plain `if`
  token in generated `Formatted.lean`) forced the rewording of §2.2.
- **Fuel forms:** unchanged (88 workers; `printf_aux` and `store_chars_in_array` structural; the two fuel'd workers
  untouched); `scripts/fuel_forms_pending.txt`, `scripts/fuel_hypotheses.txt`, the parametricity pins (17) untouched.
- **lem-sync stamps** re-derived by `make prelude-src lean-prelude-src` (final: `src 675737dd…`);
  `check_handwritten_sync: OK (57 …)`.
- **`tests/libc/libc.core`** unchanged: `libc_prep: OK (libc: pin + regenerated dump == 519d7c92…, 4156776 bytes)` (the
  D15 pin) — the formatter is the Core builtin's model, the library's `printf`/`snprintf` C text is untouched.
- **`scripts/upstream_oracle_differences.json`:** 13 new rows (24 → 37), additions only (the file re-serialised with its
  own settings, `0 deletions`), each with pristine's and the fork's first lines quoted and the two signatures computed
  with the lane's own projection from the capture directories of the tier-b run: `shared-model-fix` for the five
  `0`/`#` coverage rows, `fmt-043`, `libc_exec/026`/`027`/`028` and the two immaculate `*` rows (the fork = gcc,
  pristine wrong or crashing); `missing-feature` for `fmt-014`/`fmt-015` (the fork REFUSES where pristine answers a
  false UB — not a claim of an answer) [AGENT]. The citations are the tray filings (the lane is fail-closed on
  tracked citations, so trays 16, 26, 68, 69, 70 ride in the M2 commit). Validated by a `--only` run over the 13
  cases (§4.2).
- **Outcome-protocol migration map** (`docs/2026-10-20_outcome-protocol-register-migration.tsv`): one UNMIGRATED
  inventory line for the formatter's four refusal classes under the same shared-model mapping mover as D11/D12/D13's
  (protocol status, not a register row).
- `tests/failure-probes/reach/README.md`: the four `printf_star_*` entries retired as failure witnesses (both engines
  print the values now; their lines recorded), `printf_lc`/`printf_n` carry the refusal texts.
- `lean_frontend/CONTRACT.md`: a §3 row, the unmigrated-sites sentence (D16 added), §4.1's witness sentence, decision
  **D16**. `VALIDATION.md`: the §3(c) bullet, the fork ≠ pristine inventory entry, the §6 gate-table row.
  `SUPPORTED.md`: the formatted-output table. `scripts/LADDER.md` row 1. `scripts/test_unit.sh` runs
  `check_printf_refusals.sh --selftest` after the stdio script. Trays 26 and 16 rewritten as the filings (the
  reproducers re-run at `c3ff8c53f`, the remedies = the fork's code, the fork status), 68/69/70 new, 27 annotated (the
  `%jd` case moved out of it; the fork keeps its verdict), the INDEX rows. Consumer notes
  `docs/2026-11-07_consumer-note-cerberus-{sl,caesium}-printf-refusals.md`. `TODO.md`: this item DONE with the moved
  rows named; the floating-conversion implementation and `%n`/`%ls`/`%lc` queued with sizes; the `-0.0` finding; the
  crash-to-refusal item's arm (5) closed; the audit's §4 items 1, 3, 10 closed.

## 6. Gates

Builds (worktree primed on Lean 4.35.0 / lem `e6d8db5`; `scripts/ce`, `CERB_MEM_MAX=32G`), four times (the first
version, the strictness fix of §2.2, the rewording of §2.2, the corrected line cite of §2.4): `make prelude-src
lean-prelude-src` (rc 0 each; final stamps `check_lem_sync: recorded lean_frontend/lem_sync.sha256 (src 675737dd…, gen
e7e2c852…)`), `dune build backend/driver/main.exe cerberus-lib.install`, `dune install --prefix _build/local-install
cerberus-lib`, `dune build cerberus.install` (rc 0 each; `libc.co` restaged, its text unchanged), `capped lake build
CerberusLean cerberus-lean`: `Build completed successfully (409 jobs).` each time.

Focused gates on the M2 tree (every exit 0), verbatim last lines:

```text
check_handwritten_sync: OK (57 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
check_fork_content: OK — 95 source files content/mode-pinned
check_fork_drift: OK — layer 1: 95 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 33 differing generated files, all hash-pinned (merge-base c3ff8c53f05982745f9b3a10b3d05442e214bcb5; lem-pin e6d8db5680962f49060257d6c2bcb13c284b910f matches lem -v lean-backend-v0.1.0-alpha.1-78-ge6d8db5 (hex prefix))
check_fork_drift: SELFTEST OK (31 plants with declared verdict/message: S1-S10 prerequisite/locale/name controls; S31 advanced upstream ref (not drift); S11 copied-content control; S12 inside-listed-file drift; S13/S14 duplicate/missing content pins; S15-S30 version forms, full-pin validation and refresh retention; unplanted gate green)
check_pin_sites: OK — lem-pin e6d8db5680962f49060257d6c2bcb13c284b910f at every site (lakefile rev, 3 lake-manifests rev+inputRev, README pin command)
check_failure_reach: OK (235 pure failure sites = the 235 register rows exactly (233 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, shared keys lengthened, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=174 REACHABLE=40 UNKNOWN=21; every row sealed; tally line consistent)
check_failure_reach: SELFTEST OK (8 plants with the declared message — a new site in a generated exec-closure definition, a DISCARDABLE dead let-binding, an unsealed class edit, a phantom row, an edited tally, mis-shaped lem_if heads over a registered arm, a mis-shaped lemSeq continuation, a same-key pair's reach classes swapped with their seals; classifier witnesses C1-C7; key-group witness K1; the unplanted register OK)
check_exec_purity: CLEAN (11 modules)
check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)
check_lakefile_roots: OK (228 roots = 228 generated modules + the exe root Main; 86 auxiliary modules listed as roots — names only; every carrier is built by check_fuel_forms.sh)
check_no_fuel_numerals: OK (360 files scanned comment-stripped; no lemDefaultFuel/driverFuel/ndDefaultFuel, no LemFuel instance, no literal fuel (F1-F6), no address-space-top literal (A1-A3), no switch-set instance declaration (W1), no production call of the default-pinned reconstructValue wrappers (W2); allowed Main.lean sites seen: 6 of 6 (hand-written + generated copy); W2 wrapper lines seen: 6
check_sorry_token: OK (353 files scanned comment-stripped — generated 229, hand-written+test 89, LemLib 35; 0 sorry tokens)
gen_fuel_parametricity: OK (17 ambient fuel wrappers in the generated tree = the 17 pins of TotalityProofTest.lean Part 1, both directions)
check_fuel_forms: OK (88 fuel'd workers: 67 MEASURED (obligation of the contract's shape incl. argument correspondence against the wrapper's body; every obligation + proof cone ⊆ the standard three; 13 of them under a hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions), 13 ABSORBING = kill at zero (…), 0 reachable-AMBIENT = the 0 rows of fuel_forms_pending.txt exactly, 8 ambient unreachable from the drive cone)
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
libc_prep: OK (libc: pin + regenerated dump == 519d7c927cca883da2a004c101e064ffd52c352cb4d037d38ac589a29077f210, 4156776 bytes)
libc_prep: OK (libc_inner_arg_temps: pin + regenerated dump == dcd0499f5463ea0dd12a10ecb23a889ec9c366ab3133c0928c6d95329fb3481d, 4011125 bytes)
Ran 26 tests in 3.406s
OK                                                                 (python3 scripts/test_stops.py --lean-bin lean_frontend/.lake/build/bin/stop-test)
```

(the `check_fuel_forms` line's elision stands for the unchanged ABSORBING clause of the D13 record's quote.) The
witness (§3.4) and the lanes (§4.2) on the same tree. The failure-reach selftest on the first M1 build was RED on its
P6 premise (`P6 premise: Formatted.lean has a plain `if` token`) and the P8 premise (the two `* prec` rows gone): the
rewording and the re-targeting of §2.2/§5 made both OK; the first witness selftest run was RED on the miscounted
`pristine-pair` plant (27 caught, 24 expected): the comment and the count corrected (§3.4).

### 6.1 Tier A on the M1 tree (orchestrator-run) — 18/20, the two reds dispositioned by M2 and M3b

Run by the orchestrator on `c732fde49` in a separate audit checkout after a forced regeneration and rebuild
(`scripts/ce python3 scripts/release.py --mode fast`), verbatim: `fast: failed; 18/20 selected commands completed
successfully.` / `Source unchanged: True. Complete tier selection: True.` A1 passed (1228 s); everything else passed
but two rows, both the expected movements of this slice, verbatim:

```text
A3  REGRESSION: fmt-014-e-unserved-ub.c baseline=UB_MATCH current=CERB_SKIP
    changed (same rank, non-regressing): fmt-043-j-intmax-ub.c baseline=UB_MATCH current=MATCH
    REGRESSION: fmt-015-g-unserved-ub.c baseline=UB_MATCH current=CERB_SKIP
    Baseline check: 2 regression(s), 0 improvement(s)
A15 inner_arg_temps: FAIL — libc/026-snprintf-truncation: baseline changed: {'class': 'AGREE-FIRST', 'cross_mode': 'SAME_SET', 'lean': '8c1fa891b04a', 'mode': 'first', 'oracle': '8c1fa891b04a'} -> {'class': 'AGREE-FIRST', 'mode': 'first', 'oracle': '0ab631c4cd62', 'lean': '0ab631c4cd62', 'cross_mode': 'SAME_SET'}
    SUMMARY: inner_arg_temps rows=188 AGREE=138 AGREE-FIRST=41 BOTH_FAIL=5 LOC_ONLY-FIRST=2 RESOURCE oracle:KILL=2 failures=0
```

Dispositions: A3 is the coverage class move of §4 (`fmt-014`/`fmt-015` from the false `Invalid_format` UB to the
refusal, `fmt-043` the `%jd` fix), re-recorded with the reason in M2 (`31de67fac`: `scripts/exec_coverage_baseline.txt`,
the three programs' headers; the lane on that tree: `Baseline check: 0 regression(s), 0 improvement(s)` / `BASELINE OK`).
A15 is `snprintf`'s new return value moving BOTH engines' observation hashes together (class `AGREE-FIRST`
unchanged, Lean = oracle before and after; the same movement as the libc_exec lane's §4.3 rows) — a lane this slice's
focused list had missed (`scripts/test_inner_arg_temps.sh --gate`, Tier A row 15; found by the orchestrator's run).
Re-recorded in M3b through the lane's own path (`--record-baseline` over the whole population: `BASELINE RECORDED (188
rows)`; the lane refuses a `--rows`-restricted record, and the JSON carries no comment field, so the reason is here and
in the commit message). The resulting diff against the M3 tree is THREE rows, not one — the lane raises on the first
mismatching row, so Tier A's line named `026` only; `027` and `028` sat behind it, the same movement — verbatim:

```text
-  "libc/026-snprintf-truncation": {"class": "AGREE-FIRST", "cross_mode": "SAME_SET", "lean": "8c1fa891b04a", "mode": "first", "oracle": "8c1fa891b04a"},
-  "libc/027-snprintf-exact-fit": {"class": "AGREE-FIRST", "cross_mode": "SAME_SET", "lean": "808b693231f5", "mode": "first", "oracle": "808b693231f5"},
-  "libc/028-vsnprintf-wrapper-truncation": {"class": "AGREE-FIRST", "cross_mode": "SAME_SET", "lean": "a8be98317f17", "mode": "first", "oracle": "a8be98317f17"},
+  "libc/026-snprintf-truncation": {"class": "AGREE-FIRST", "cross_mode": "SAME_SET", "lean": "0ab631c4cd62", "mode": "first", "oracle": "0ab631c4cd62"},
+  "libc/027-snprintf-exact-fit": {"class": "AGREE-FIRST", "cross_mode": "SAME_SET", "lean": "73413035d7ea", "mode": "first", "oracle": "73413035d7ea"},
+  "libc/028-vsnprintf-wrapper-truncation": {"class": "AGREE-FIRST", "cross_mode": "SAME_SET", "lean": "88293a1b687b", "mode": "first", "oracle": "88293a1b687b"},
```

(`026`'s new hash is the one Tier A printed, so the audit checkout and this worktree observe the same program.) The
gate re-run on the M3b tree, verbatim:

```text
SUMMARY: inner_arg_temps rows=188 AGREE=138 AGREE-FIRST=41 BOTH_FAIL=5 LOC_ONLY-FIRST=2 RESOURCE oracle:KILL=2 failures=0
inner_arg_temps elapsed: 378.60s   (scripts/test_inner_arg_temps.sh --gate: the plants, then the whole population; rc 0)
```


### 6.2 The full battery at close-out (orchestrator-run)

Appended by the orchestrator after the run on the M3 tip.


## 7. Not done / open

- The seven floating conversions and `L`, `%n`, `%ls`, `%lc`: refusals, not implementations (TODO, with sizes).
- `%f` of `-0.0`: the sign is lost before the formatter (the negation); not this mechanism, not filed, named in TODO
  and in tray 70's related findings.
- `printf("%s", 5)`: a crash on UB input, tolerated and unchanged (a refusal would be the valid refinement; not in
  this slice's charter).
- The witness's UB pins for the malformed formats (`%q`, `%ll`, …) pin the FIRST line of the verdict only: upstream
  embeds the format string raw in the `Invalid_format` text, newline included, so the batch line is cut there on both
  engines (a pre-existing printer behaviour, not changed).
- In libc mode a format UB's location is inside the library's `vfprintf` on the oracle and `<unknown location>` on
  Lean (N4, since D15); the witness projects it on its UB rows.
- The commit message of M1 cites the `LM_j` arm at `:559-560` (the charter's tip numbering); pristine's is `:530-531`
  — corrected in the Lem comment, the trays and here (a committed message is not rewritten).
