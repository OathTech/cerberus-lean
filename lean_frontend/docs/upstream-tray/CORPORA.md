# Witness corpora: an index for readers without this repository's test ladder

[AGENT 2026-11-10] The reporting slice (roadmap `../2026-11-10_roadmap-maintenance-and-reporting.md`, item 2). Each
directory below holds small self-contained C programs written as witnesses for one or more reports of this tray, with
the answers of three implementations pinned beside them. This page says what the files mean and how to run ONE program
on any Cerberus binary and compare its answer, with nothing from this repository but the program and the pin file. The
directories are under `tests/` at the repository root; nothing here moves or edits them.

Counts below are derived (2026-11-10, `ls <dir>/*.c | wc -l` and `grep -vc '^#' <file>`).

## The three pin files

Every pin file is text, one program per line, fields separated by a TAB, the first field the program's name (the file
name without `.c`); lines starting with `#` are comments that state the file's own derivation.

- `gcc.txt` — what gcc 13.3.0 (Ubuntu 24.04, glibc) did with the program, rendered in the shape of Cerberus's
  `--batch` line so the two can be compared as strings: `Defined {value: "Specified(<exit status>)", stdout: "<escaped
  stdout>", stderr: "<escaped stderr>", blocked: "false"}`, or `GCC-REJECT: <first error line>` when gcc refused to
  compile. Flags: `gcc -std=c11 -w -O0` for `stdio_exit`, `printf_refusals` and `half_mirrors`;
  `gcc -std=c11 -pedantic-errors -O0` for `address_constants`. `macro_type_ranks` has no `gcc.txt`: its `expected.txt`
  is gcc's line (`gcc -std=c11 -w -O0`) for all but two declared rows.
- `pristine.txt` — what un-forked upstream Cerberus at `c3ff8c53f` printed (its `--batch` line; `CRASH…` or
  `REJECT(rc=1): …` where it printed no verdict line). This is the "before": a row where `pristine.txt` differs from
  `gcc.txt` is a program upstream gets wrong at that commit.
- `expected.txt` — what this fork's two engines are required to print (the fork's test compares against it). For a
  reader of the reports it is the "after", and it says which rows the fork deliberately does not answer as gcc does.
  Its layout differs per corpus (below).

## Running one program

`cerberus` below is any built Cerberus driver (upstream's `cerberus` script, or
`_build/default/backend/driver/main.exe --runtime=_build/install/default` in a build tree). Programs of a corpus marked
*libc* are run without `--nolibc`; programs marked *nolibc* with it. A `Defined`/`Undefined` verdict is the first line of
standard output; a rejection or crash prints no verdict line and the diagnostic is on standard error.

```sh
# one nolibc program against gcc's pinned line (address_constants; `gcc.txt` has 2 fields)
n=ac_arr_elem_member; d=tests/address_constants
cerberus --nolibc --exec --batch $d/$n.c 2>/dev/null | grep -E '^(Defined|Undefined|Error) ' | head -1 > got.txt
awk -F'\t' -v n=$n '$1==n{print $2}' $d/gcc.txt | diff - got.txt && echo SAME-AS-GCC

# one libc program against gcc's pinned line (stdio_exit, printf_refusals, half_mirrors)
n=flush_puts_twice; d=tests/stdio_exit
cerberus --exec --batch $d/$n.c 2>/dev/null | grep -E '^(Defined|Undefined|Error) ' | head -1 > got.txt
awk -F'\t' -v n=$n '$1==n{print $2}' $d/gcc.txt | diff - got.txt && echo SAME-AS-GCC

# macro_type_ranks (nolibc): the reference line is expected.txt's second field
n=tray20_int_size_t_uac_rank; d=tests/macro_type_ranks
cerberus --nolibc --exec --batch $d/$n.c 2>/dev/null | grep -E '^(Defined|Undefined|Error) ' | head -1 > got.txt
awk -F'\t' -v n=$n '$1==n{print $2}' $d/expected.txt | diff - got.txt && echo SAME-AS-GCC
```

(Checked 2026-11-10: with the fork's driver each of the three prints `SAME-AS-GCC`; with un-forked upstream at
`c3ff8c53f` the first program is rejected — an empty `got.txt` — and the other two print `pristine.txt`'s line.)

To compare with upstream's pinned answer instead, read the same field from `pristine.txt` (for `address_constants` its
second field is un-forked upstream's line; the third is NOT upstream's — upstream has no Lean engine — but this
fork's Lean engine before the fork's change, kept as that engine's "before"). A program that crashes or is rejected
produces an empty `got.txt`; its pin then starts with `CRASH`, `REJECT(rc=1):` or `GCC-REJECT:` and the comparison is
of the diagnostic on standard error, by eye. An `Undefined` line carries a `loc` field that differs between a
library-mode run of the two engines; compare it with that field removed.

## The corpora

| Directory | Programs | Mode | Reports | Pin files |
|---|---|---|---|---|
| `tests/macro_type_ranks` | 106 | nolibc | 20 (the integer conversion rank of `size_t`, `ptrdiff_t`, `wchar_t`, the `intptr_t`/`intmax_t` families and enums); one program for 62 | `expected.txt` (105 rows), `pristine.txt` (105) |
| `tests/stdio_exit` | 46 | libc; 5 `nolibc_*` | 24 and 25 (flushing at termination, `atexit` on return from `main`, the exit status) | `expected.txt`, `gcc.txt`, `pristine.txt` (46 each) |
| `tests/printf_refusals` | 161 | libc; 4 `nolibc_*` | 26 (`*`, `%n`, `%ls`, `%lc`), 16 (`snprintf`'s return), 68 (floating conversions), 69 (`j`/`z`/`t`), 70 (the `0` and `#` flags), 27 (the strict argument-type verdicts, kept) | `expected.txt`, `gcc.txt`, `pristine.txt` (161 each) |
| `tests/address_constants` | 244 | nolibc | 09 with 28 and 29 merged into it (constant expressions in static initializers and integer-constant contexts); one program for 75 | `expected.txt`, `gcc.txt`, `pristine.txt` (244 each) |
| `tests/half_mirrors` | 41 | libc; 13 `nolibc_*` | 10 (`\?`), 11 (the formatted store's character round trip), 13 (`memcmp` with a huge size); 63 (the `gap_*` rows) | `expected.txt`, `gcc.txt`, `pristine.txt` (41 each) |

### `tests/macro_type_ranks`

`expected.txt`: `<name> TAB <line>`. Groups by name prefix: `dense_*` (47; every operator over pairs of a macro type
and a standard type, with negative and large operands), `audit_*` (30; the true-bug audit's rank probes: `ptrdiff_t`
asymmetry, compound assignment, `%`, `|`, `^`, `?:`, comparisons), `promo_*` (9; integer promotion of the small types
and `wchar_t`), `st-*` (9) and `p_*` (4; typing-level checks through `_Generic` and pointer conversions),
`consumer_*` (3; the shapes a consumer filed), `tray20_int_size_t_uac_rank` (report 20's own program). Three programs are not
gcc's answer and say so in their names: `gap_intptr_t_unsigned_false_ub036` and `residual_size_t_llong_typing` are
pinned to the fork's line (two related findings in report 20, unchanged), and `gap_wchar_t_negative_store` has no pin
row (it is report 62's crash, checked for the crash text by the fork's script).

### `tests/stdio_exit`

All three files: `<name> TAB <line>`. Groups: `flush_*` (14; output left in a `FILE` buffer at termination), `order_*`
(13; the interleaving of `printf`, `puts`, `putchar`, `fputs` and `fwrite`), `atexit_*` (7), `status_*` (3; the exit
status of `main`'s return and of `exit`), `impl_*` (3; rows whose answer is the shipped library's documented choice),
`nolibc_*` (5; the same questions without the library, where upstream's behaviour is kept), `gap_fopen_unclosed` (1;
a row the Lean engine refuses, a control). 24's report says which rows are pinned to something other than gcc's line.

### `tests/printf_refusals`

`expected.txt`: `<name> TAB <class> TAB <pin>`; the classes (derived: VALUE 104, UB 38, REFUSAL 18, GAP 1):

- `VALUE` — the pin is the batch line; it is gcc's line in `gcc.txt` except for the rows the fork's script declares
  as its own (the implementation-defined `%p` text, `%5%`, the space flag on an unsigned conversion).
- `UB` — the pin is an `Undefined {ub: …}` line with its `loc` field removed; gcc's output for the same (undefined)
  program is in `gcc.txt` for information.
- `REFUSAL` — the fork stops with the pinned text (`internal error: <text>`); upstream's answer for the same program
  is in `pristine.txt` (a false `Invalid_format` verdict or an internal error) and gcc's in `gcc.txt`. These rows are
  the conversions reports 26 and 68 ask upstream to implement or to reject explicitly.
- `GAP` — one control row (`%f` of a NaN).

Groups by name prefix, the larger ones: `star_*` (28; report 26), `sn_*` and `vsn_*`, `ret_*` (18; report 16),
`f_*`, `e_*`, `g`, `G`, `a`, `A`, `E`, `F`, `Le`, `Lf`, `le`, `lf` (the floating conversions; report 68, and report
70's `#` flag for `%f`), `jd_*`, `ji_*`, `ju_*`, `zd_*`, `zu_*`, `zx_*`, `td_*`, `tu_*`, `tx_*` (report 69),
`flags_*`, `zero_*`, `plus_*`, `sp_*`, `space_*`, `hash_*`, `percent_*` (report 70), `n_*`, `ls_*`, `lls_*`, `lc_*`
(report 26's other conversions), `d_*`, `u_*`, `x_*`, `o_*`, `illtyped_*`, `ld_*`, `lu_*` (the argument-type verdicts,
report 27), `bad_*` (6; malformed formats).

### `tests/address_constants`

`expected.txt`: `<name> TAB <class> TAB <OCaml driver's line> TAB <Lean engine's line>`; `gcc.txt`: `<name> TAB
<line>`; `pristine.txt`: `<name> TAB <un-forked upstream's line> TAB <this fork's Lean engine before the
change>`. Classes (derived: gcc 183,
reject 39, fork 21, gap 1): `gcc` — the pin is gcc's line; `reject` — gcc rejects the program and so must Cerberus
(the pin is the first error line after the file prefix); `fork` — the fork keeps upstream's verdict where gcc accepts
an extension or the standard leaves a judgement (each is listed with its reason in report 09); `gap` — `ice_case_cond_gnu`,
the GNU `?:` in a case label, an internal error before and after (report 75). Groups by name prefix: `ice_*` (108;
integer constant expressions in static initializers, enumerators, case labels, array bounds and `_Static_assert`),
`ac_*` (121; address constants: every chain of `&`, `[]`, `.`, `->`, casts, `?:`, `_Generic`, string literals and
function designators, and the forms 6.6#3 forbids), `ar_*` (15; arithmetic constant expressions).

### `tests/half_mirrors`

All three files: `<name> TAB <line>`, a crash written `CRASH <text>`. Groups: `nolibc_*` (13; report 10: `\?` in a
character constant and a string literal, and the neighbouring escapes; `nolibc_fork_oct_char_0123` is pinned to the
fork's line, see report 10's 2026-11-10 section), `rt_*`, `memcmp_distinct_*`, `memmove_*`, `strncmp_*`, `strncpy_*`
(15; report 11: every byte value stored through `snprintf`/`sprintf` and read back), `ub_*` (8; report 13: undefined
programs, pinned to the verdict; `gcc.txt` holds only what gcc happened to do), `gap_*` (5; crashes that upstream and
the fork share: universal character names, multi-character constants, a non-ASCII byte — report 63).

## The refusal witnesses

Where this fork stops with a declared refusal instead of upstream's answer, the programs that pin the refusal are:

| Refusal (report; contract row) | Programs |
|---|---|
| anonymous struct/union members (60; D12) | `tests/parity-probes/uncertainty/A-anonymous-members/*.c`, and programs written inline in `scripts/check_anonymous_members_refusal.sh` |
| compound assignment with a side effect in the left operand (61; D13) | `tests/parity-probes/uncertainty/B-compound-assignment/*.c`, and inline in `scripts/check_compound_assignment_refusal.sh` |
| union initializers designating a non-first member (59; D11) | inline in `scripts/check_union_init_refusals.sh` |
| `memcpy` on overlapping objects, `aligned_alloc` with an invalid alignment (56, 57; D10) | inline in `scripts/check_item_g_refusals.sh` |
| PNVI-mode crashes (refusals R-PNVI-05, -06, -07; `r06` is report 53's reproducer) | `tests/pnvi_refusals/*.c` (3 programs) |
| the unimplemented `printf` conversions (26, 68; D16) | the `REFUSAL` rows of `tests/printf_refusals` above |

These directories have no `gcc.txt`/`pristine.txt`: each program's header comment, or the script beside it, states
what gcc and upstream answer. To see upstream's behaviour, run the program as in "Running one program" (all are
nolibc except `tests/pnvi_refusals`, which need the PNVI switches named in each file's header); the reports quote the
result. The two `parity-probes/uncertainty` directories (55 files together: 41 and 14; derived, `find <dir> -type f | wc -l`) also contain control programs that
are not refused.

Twelve statement-expression programs (`tests/parity-probes/uncertainty/P-statement-expressions/`, report 73) are
crash witnesses rather than refusal witnesses: six run and six die on upstream at `c3ff8c53f` and on the fork alike.
