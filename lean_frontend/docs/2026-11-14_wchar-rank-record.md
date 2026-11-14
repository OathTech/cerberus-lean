# `wchar_t` and `wint_t` leave the rank normalisation (the correction of D14); the micro probe package retired — slice record (2026-11-14)

Worker [AGENT] (Claude Fable 5.2). Branch `fix/wchar-rank`, base mainline `mdd/cerberus-lean` `06afa3ef7`. Charter
`2026-11-14_worker-charter-wchar-rank.md` (committed at the head of the branch, `6ae2434c9`). The slice corrected:
D14, `2026-11-04_macro-type-ranks-record.md` (`9b15a1f69`, landed with `bb6e8e9f9`). Every line in a code block
below is a machine output copied as printed; every count not inside a code block is derived and says from what.

## 0. Rulings and decisions

- [USER 2026-11-14], as the charter records them: (1) `wchar_t` is taken out of the rank normalisation, its rank
  comparisons returning to upstream's behaviour exactly, defects included, every other macro type keeping D14; not
  a refusal and not a repair of `wchar_t`'s signedness; (2) `tests/mem-scale-probes/micro` is retired.
- [USER 2026-11-14] `wint_t` leaves the normalisation with `wchar_t`: the operator approved the extension as the
  same defect and the same mechanism (ruled after the pre-merge review's F7; before that it stood as the worker's
  decision, [AGENT 2026-11-14], under the charter's delegation). How it arose: the charter asked for a measurement
  and gave the rule (a row where the fork differs from both pristine and gcc is a second regression, fixed the same
  way if it is the same mechanism). Measured, §1.3: `WINT_MIN > -1`, `WINT_MAX > -1` and `~WINT_MIN < 0` answered 1
  on both fork engines and 0 on pristine and gcc. The mechanism is the same one (`Wint_t` normalised to `Signed
  Int_` against a model range of `[0, 2^31-1]`), so the fix is the same one.
- [AGENT 2026-11-14, worker] The exclusion is two edits, not one. The charter's hypothesis was that excluding
  `Wchar_t` in `rank_operand` and nowhere else restores pristine. It restores the reproducer and breaks other
  programs (§1.2): D14 made the table's catch-all a loud `error`, and a bare `Wchar_t` reaches it. The table
  therefore answers upstream's `false` for a pair with a `Wchar_t` or `Wint_t` operand ahead of the catch-all. This
  is what "upstream's behaviour exactly" needs and nothing more; the catch-all stays loud for every other
  constructor.
- [AGENT 2026-11-14, worker] A pair that mixes `wchar_t` or `wint_t` with another macro type is treated by the
  same two edits (the other operand is still normalised), and no third rule was added. Measured, §3.2: all 6,094
  such rows of the vicinity print pristine's line — but every one of them is a single two-operand expression. The
  equality the slice claims is the charter's narrow one (programs whose only macro-typed operands are
  `wchar_t`/`wint_t`); a three-operand program with another macro type is NOT equal to pristine in general (§3.2,
  the pre-merge review's F4, which corrected an over-wide statement of this bullet).
- [AGENT 2026-11-14, orchestrator, on the pre-merge review's F5, under the gate-cruft rule] Row 1 keeps a CORE of the
  witness at about the leg's pre-slice cost; the six `limits_*` programs and the six bulk KEPT matrices run under
  `--full` as Tier B row 16, same programs and pins; the generator of the generated programs is committed beside
  them (§4.1).
- [USER 2026-11-14] The mainline commit subjects from before the rule of 2026-10-16 that carry quoted phrases are
  grandfathered; history is not rewritten (§8).
- [AGENT 2026-11-14, worker] `scripts/build_provider_smoke.py` is kept and reads the pin from the manifest: row 1
  runs its entry through `scripts/test_release.py`, so it is not a script nothing runs (§6).
- [AGENT 2026-11-14, worker] The existing `wchar_t` witness rows are re-pinned to pristine's line, not deleted, and
  the witness gains a negative control of its own for them (`d14.txt`): a row whose pin IS pristine's line cannot
  be guarded by the pristine-replaying plants (§4).

## 1. The cause, established by runs

### 1.1 The defect on this tree before any change

The tree at `6ae2434c9` (generated trees re-derived by `make clean-prelude-src prelude-src lean-prelude-src`, then
the full rebuild), the reproducer `#include <stdint.h>` / `int main(void) { return WCHAR_MAX > 0; }`, `--nolibc
--exec --batch`; the fork oracle, pristine `c3ff8c53f`, the Lean engine on the fork oracle's Cabs JSON, gcc 13.3.0
`-std=c11 -w -O0`:

```text
fork oracle:  Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
pristine:     Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}
fork Lean:    Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}
gcc:          exit status 1
```

### 1.2 Experiment 1: `Wchar_t` excluded in `rank_operand` and nowhere else

`rank_operand` returning `Wchar_t` for `Wchar_t` and the normalised type otherwise; `make prelude-src`, the oracle
rebuilt. The reproducer answers pristine's line:

```text
Defined {value: "Specified(1)", stdout: "", stderr: "", blocked: "false"}
```

Seven of nine one-line probes with a `wchar_t` object then stop in D14's catch-all where pristine answers
(`#include <stddef.h>`, `wchar_t w = 5;`, a partner `i = 3` of the type named, the expression returned):

```text
== wchar_t w = 5; int i = 3; return i < w;
internal error: AilTypesAux.lt_integer_rank: unranked integer type after normalisation
```

The same text for `long i; i + w`, `char i; i + w`, `ptrdiff_t i; i + w`, `long long i; i + w`, `wchar_t i; i + w`
and `_Bool i; i + w`; `w + i` with `int i` and `i + w` with `unsigned long i` answer pristine's 8. So the
exclusion in `rank_operand` alone is the cause's removal but not a fix: with the bare constructor back, the pairs
upstream's catch-all answered `false` need that answer back.

### 1.3 Experiment 2 and 3: upstream's `false` for the bare constructor; `wint_t`

With the two arms `(Wchar_t, _)` and `(_, Wchar_t)` answering `false` immediately before the catch-all, all ten
programs (the reproducer and the nine probes) print pristine's line. Thirteen `wint_t` probes were then run on the
pre-fix fork oracle, the experiment-2 oracle, pristine and gcc (`#include <stdint.h>`, the expression returned;
the fork column is the same before and after experiment 2):

| expression | fork (D14) | pristine | gcc |
|---|---|---|---|
| `WINT_MIN > -1` | `Specified(1)` | `Specified(0)` | 0 |
| `WINT_MAX > -1` | `Specified(1)` | `Specified(0)` | 0 |
| `~WINT_MIN < 0` | `Specified(1)` | `Specified(0)` | 0 |
| `WINT_MIN - 1 > 0` | `Specified(0)` | `UB036_exceptional_condition` | 1 |
| `-WINT_MAX < 0` | `Specified(1)` | `UB036_exceptional_condition` | 0 |
| `-1 < WINT_MAX` | `Specified(1)` | `Specified(1)` | 0 |
| `WINT_MAX == 2147483647` | `Specified(1)` | `Specified(1)` | 0 |

(of the other six, five agree on all three: `WINT_MAX > 0`, `WINT_MIN == 0`, `WINT_MAX < -1l`, `(WINT_MAX | 0) < 0`,
`WINT_MAX - 2147483648u > 0`; `WINT_MAX + 1 > 0` is `UB036` on both Cerberus sides, gcc 0). The fork column is the
oracle's; the pre-fix Lean driver, copied aside before the rebuild, answers the same `Specified(1)` on the first
three rows (and `Specified(0)` on the reproducer). The first three rows are
the charter's second-regression shape; `Wint_t` got the same two edits (experiment 3) and all 23 programs then
print pristine's line.

### 1.4 The other sites of `9b15a1f69`

`9b15a1f69` changed one model file, `frontend/model/ail/ailTypesAux.lem`, in three places: `rank_operand` (new),
its two uses in `eq_integer_rank` and `lt_integer_rank`, and the table's last arms (the two `long long` rows and
the loud catch-all). The normalisation at `:294-295` (`le_integer_range`) and at `:837-841` (`are_compatible`) is
upstream's own (`f8dde7df6`, "better treatment of std types defined as aliases") and is in pristine; it was not
part of D14 and is not touched. Of D14's sites, the two `long long` rows cannot see a `Wchar_t`/`Wint_t` operand
differently from pristine (they answer `false`, as the catch-all did), and the catch-all is the site experiment 1
found. No other site of the diff concerns the two types; the vicinity (§3) is the measurement that nothing else
moved them.

## 2. The change

`frontend/model/ail/ailTypesAux.lem`, two edits and their comments; both engines by generation.

```text
let rank_operand ity =
  if Global.is_CHERI () then ity else
  match ity with
    | Wchar_t -> Wchar_t
    | Wint_t -> Wint_t
    | _ -> Implementation.normalise_integerType ity
  end
```

and, in `lt_integer_rank`'s ISO table, after the two `long long` rows and immediately before the catch-all:

```text
    | (Wchar_t, _) ->
        false
    | (_, Wchar_t) ->
        false
    | (Wint_t, _) ->
        false
    | (_, Wint_t) ->
        false
```

Why these four arms give upstream's answer and no other: in pristine's table a pair with a bare `Wchar_t` (or
`Wint_t`) operand is answered by `(_, Bool)`/`(Bool, _)` and the `(_, T)` arms of the standard types where they
match, and by the catch-all's `false` otherwise; the fork's table has the same arms in the same order plus the two
`long long` rows (`false`, what the catch-all said), so a pair that reaches the new arms is one that reached
pristine's catch-all. The other operand may now arrive normalised where pristine saw a bare macro constructor; for
a pair with `Wchar_t` that changes no answer (a normalised type is a standard type, never `Bool` for a macro type,
and `(Wchar_t, standard)` and `(macro, Wchar_t)` are `false` on both sides). `eq_integer_rank` needs no arm: a
bare `Wchar_t` equals only itself. Under CHERI nothing changes (`rank_operand` was already the identity there, and
the new arms answer what the CHERI catch-all answers). This argument is a reading; §3 is the measurement.
One pair that was loud is now a silent `false` (the pre-merge review's F8): a bare `Wchar_t`/`Wint_t` first operand
against `Ptraddr_t`, which before arrived as `(Signed Int_, Ptraddr_t)` and fell to the loud catch-all; it is
upstream's answer for a `wchar_t` pair, and it cannot be reached from C outside CHERI, where a `__cerbty_ptraddr_t`
operand is stopped before any rank comparison on the oracle, pristine and Lean (`internal error: ptraddr_t is
CHERI-specific`; the reviewer's twelve programs).

Generated delta, read against trees generated from `6ae2434c9` by the same lem in a scratch worktree (`diff -rq`):

```text
Files .tmp/basewt/ocaml_frontend/generated/ailTypesAux.ml and ocaml_frontend/generated/ailTypesAux.ml differ
Files .tmp/basewt/lean_frontend/generated/AilTypesAux.lean and lean_frontend/generated/AilTypesAux.lean differ
```

Nothing else differs in either tree: the comment, the `match` in `rank_operand` and the four arms in each. No
signature changed (D14 had already given the rank functions their reader parameters on the Lean side), no
`*_lemMeasureProofs.lean` file differs, no hand-written seam was touched.

## 3. The vicinity

### 3.1 The instrument (`.tmp/vic/gen.py`, `run.py`, `report.py`, `stats.py`; deleted at the end)

54,329 programs, one expression each, the value printed as `%llu` of `(unsigned long long)`, each run alone so that
an undefined-behaviour verdict or a crash on one expression hides no other. Five columns: the fork oracle built at
`06afa3ef7` before the change (binary and install tree copied aside), the fork oracle after it, pristine
`c3ff8c53f`, gcc 13.3.0, and the fork's Lean engine after the change on 2,567 of the rows (every row the fix moved
and every single-operand `wchar_t`/`wint_t` row; the witness, §4, runs Lean on the rest it pins). All Cerberus runs
`--nolibc --exec --batch`.

- **The macros.** Every `#define` of `runtime/libc/include/{limits.h,stdint.h,stddef.h,wchar.h}` whose name ends in
  `_MIN` or `_MAX`, and `CHAR_BIT`: 72 names (read from the headers by the generator; `<stdint.h>`'s live branch is
  `FIXED_STDINT`). `<stddef.h>` and `<wchar.h>` define none. 36 of the 72 are textual aliases of another (the
  exact-width, least and fast names expand to the `<limits.h>` macros, e.g. `INT_FAST16_MAX` → `INT16_MAX` →
  `SHRT_MAX` → `__cerbvar_SHRT_MAX`), so a Cerberus program using one is token-identical after preprocessing to the
  program using its target; the generator runs the 36 distinct ones: `CHAR_BIT CHAR_MAX CHAR_MIN INT16_MAX
  INT16_MIN INT32_MAX INT32_MIN INT64_MAX INT64_MIN INT8_MAX INT8_MIN INTMAX_MAX INTMAX_MIN INTPTR_MAX INTPTR_MIN
  LONG_MAX LONG_MIN MB_LEN_MAX PTRDIFF_MAX PTRDIFF_MIN SIG_ATOMIC_MAX SIG_ATOMIC_MIN SIZE_MAX UCHAR_MAX UINT16_MAX
  UINT32_MAX UINT64_MAX UINTMAX_MAX UINTPTR_MAX ULONG_MAX WCHAR_MAX WCHAR_MIN WINT_MAX WINT_MIN IOV_MAX NAME_MAX`
  (the exact-width name stands for its `<limits.h>` target: `INT32_MAX` is `INT_MAX`, `INT64_MAX` is `LLONG_MAX`).
  Plus the 36 direct `__cerbvar_*` spellings of the exact-width, least and fast families (the header's other
  branch, unreachable through the shipped headers: D14's macro types).
- **Per macro M** (441 rows): compared with 0 (nine forms, both orders); promoted (`+M -M ~M !M`, `sizeof`, the
  `_Generic` type code `TC` of `M`, `+M`, `-M`, `~M`); converted (a cast to each of eleven standard types, an
  initialisation of `int`/`unsigned`/`long`/`unsigned long` objects); against literals (`M + 1`, `M - 1u`, …); and
  in the usual arithmetic conversions against an `int`, `unsigned`, `long` and `unsigned long` object holding 0, 1
  and -1: six comparisons and four reversed, `+ - *` in both orders, `/ %`, `& | ^`, the conditional operator, the
  type codes and `sizeof` of the results, and `+= -= &= |=` into the partner's type.
- **With each other** (12,654 rows): the 36 header macros pairwise (666 unordered pairs, 19 expressions each).
- **`wchar_t` objects** (9,923 rows): an object holding 0, 5, 200000005 and 2147483647 against every standard
  integer type, both enums, the six other macro types and `wchar_t` itself (partner 0, 3, -3), every operator in both orders and every
  `op=` in both directions; the object alone (promotion, unary operators, shifts, casts); wide character constants
  and casts to `wchar_t`; the programs of tray 62.
- **gcc as referee.** `gcc -std=c11 -w -O0`; a second build with `-fsanitize=undefined`, plus gcc's own
  `-Woverflow` diagnostics for constant-folded overflow, marks the rows whose gcc run is undefined, and those rows
  are never counted as agreement or disagreement with gcc. Three repairs of the referee were made before the
  numbers below, each after a row was misread: (i) gcc was given the shipped header's own definitions of the
  exact-width limits (glibc types `uint64_t` as `unsigned long`, the shipped `<stdint.h>` as `unsigned long long`:
  eight `_Generic` rows had looked like a fork error); (ii) gcc narrows `t += M` on an `int` object to 32-bit
  arithmetic and its sanitizer then never sees the overflow of the standard's type, so each compound assignment is
  also evaluated in the usual arithmetic type on the same source line (four `ptrdiff_t` rows had looked like a fork
  error: `int t = 1; t += PTRDIFF_MAX` overflows `long`, and UBSan says so of `(long)t + PTRDIFF_MAX`); (iii) the
  two POSIX names `IOV_MAX`/`NAME_MAX`, which gcc's `<limits.h>` does not define under `-std=c11`, were given the
  shipped header's literal 1024. And one of the reader: a diagnostic's source position is dropped before
  comparison (the generated header grew by gcc-only lines between runs).

### 3.2 Results (derived by `stats.py` from the five result files; "moved" = the fork's line before ≠ after)

| family | rows | moved by the fix | all three equal | fork = gcc, pristine differs | fork = pristine, gcc differs | fork = pristine, gcc run undefined | fork != pristine, gcc run undefined | FORK DIFFERS FROM BOTH |
|---|---|---|---|---|---|---|---|---|
| `<limits.h>` and exact-width limits | 12810 | 0 | 12532 | 0 | 16 | 262 | 0 | 0 |
| INTPTR/UINTPTR/INTMAX/UINTMAX/PTRDIFF/SIZE limits | 8244 | 0 | 7389 | 416 | 85 | 323 | 31 | 0 |
| WCHAR_* | 939 | 209 | 378 → 405 | 94 → 0 | 339 → 511 | 13 → 23 | 10 → 0 | 105 → 0 |
| WCHAR_* x WINT_* | 76 | 24 | 27 → 36 | 5 → 0 | 25 → 40 | 0 | 0 | 19 → 0 |
| WCHAR_* x other limit | 1216 | 230 | 548 → 566 | 69 → 0 | 381 → 572 | 57 → 78 | 21 → 0 | 140 → 0 |
| WINT_* | 939 | 195 | 561 → 584 | 123 → 0 | 183 → 355 | 0 | 0 | 72 → 0 |
| WINT_* x other limit | 1216 | 205 | 651 → 673 | 120 → 0 | 350 → 523 | 10 → 20 | 10 → 0 | 75 → 0 |
| direct __cerbvar_* spellings | 15876 | 0 | 12696 | 2961 | 0 | 219 | 0 | 0 |
| undeclared in Cerberus (MB_LEN_MAX, SIG_ATOMIC_*) | 3090 | 0 | 0 | 0 | 2977 | 113 | 0 | 0 |
| wchar_t object | 6261 | 826 | 5086 → 5087 | 745 → 0 | 245 → 1042 | 104 → 132 | 28 → 0 | 53 → 0 |
| wchar_t object x macro type/enum | 3662 | 558 | 3005 | 537 → 0 | 85 → 641 | 14 → 16 | 2 → 0 | 19 → 0 |
| total | 54329 | 2247 | 42873 → 42973 | 5070 → 3377 | 4686 → 6762 | 1115 → 1186 | 102 → 31 | 483 → 0 |

Read as: `a → b` is the count before the fix and after it; a single number did not change.

- **The equality the charter states holds, in the charter's form.** The charter's statement is about programs
  whose ONLY macro-typed operands are `wchar_t`/`wint_t`. Rows with a `wchar_t`/`wint_t` operand where the fixed
  fork differs from pristine: 0 of 14,309; the 6,094 of them that mix one with another limit macro, macro type or
  enum are equal too, but each is one two-operand expression, and that does NOT generalise (the pre-merge review's
  F4; an earlier text of this record, CONTRACT D14, VALIDATION and tray 20 said "every program with a `wchar_t` or
  `wint_t` operand", which is false). The reviewer's counter-example, reproduced by the worker 2026-11-14,
  `wchar_t x = 5; size_t sz = 3; int i = -3;` printing `(x+sz)+i` as `%llu` (fixed fork; pristine; gcc):

  ```text
  Defined {value: "Specified(0)", stdout: "5\n", stderr: "", blocked: "false"}
  Defined {value: "Specified(0)", stdout: "4294967301\n", stderr: "", blocked: "false"}
  5
  ```

  `x+sz` is typed `size_t` by upstream's NON-STD arm and `size_t + int` is then D14's fix: the behaviour is right,
  the sentence was wrong. Rows without a `wchar_t`/`wint_t` operand where the fixed fork differs from the fork
  before: 0 of 40,020.
- **The regression is gone and was 483 rows wide, not one.** Rows where the fork differed from both pristine and
  gcc: 483 before, 0 after; all 483 had a `wchar_t` or `wint_t` operand. 100 of them now agree with both; 383 are
  now pristine's line where gcc differs (upstream's own behaviour).
- **No second regression of another mechanism.** In the 40,020 rows without a `wchar_t`/`wint_t` operand the fork
  differs from both pristine and gcc on none, before or after.
- **What the ruling costs, stated as a count.** 1,693 rows where the fork of 2026-11-04 agreed with gcc and
  pristine did not are pristine's line again (for example `wchar_t w = 1; long l = 2^33; w + l`: 8589934593 → 1,
  the witness `p_wchar_long`; `WINT_MIN - 1u`: 4294967295 → `UB036`). Verdict kinds of the 2,247 moved rows, before →
  after: value → another value 1,590; value → `Undefined` 528; `Undefined` → value 45; crash → `Undefined` 71;
  `Undefined` → crash 13 (the crash is tray 62's `bytes_of_int` assertion, pristine's on the same rows).
- **Lean = oracle.** On the 2,567 rows run: the same line on 2,551; on 16 both stop without a verdict (tray 62's
  crash: the oracle exits 125 on its assertion, Lean stops with the mirrored `CerbMem.intToBytes` text); no row
  where one engine answers and the other differs.
- **Rows where fork = pristine and gcc differs, without a `wchar_t`/`wint_t` operand** (3,078; none is a
  regression, all are upstream's, unchanged): 2,977 are `MB_LEN_MAX`, `SIG_ATOMIC_MIN` and `SIG_ATOMIC_MAX`, which
  the shipped headers `#define` to `__cerbvar_*` names the front end does not declare (`error: use of undeclared
  identifier '__cerbvar_MB_LEN_MAX'`; pristine the same; so `SIG_ATOMIC_*` is not "declared" in the charter's
  sense and has no value rows); 85 are D14's declared residual (the type checker's NON-STD `Size_t`/`Intptr_t` arms: the
  `_Generic` codes and the false `UB036` of `intptr_t` against an unsigned 64-bit partner, tray 20's related
  findings); 16 are the type of the narrow limits (`sizeof(CHAR_MAX)` is 1 and its `_Generic` code is `char`'s,
  where C17 5.2.4.2.1 gives the promoted type: `int`). The last is not in the tray; it is listed in §8.
- **Rows where the fork differs from pristine and gcc's run is undefined** (31, unchanged, none with a
  `wchar_t`/`wint_t` operand): D14's intended verdicts — the fork reports `UB036` for a signed overflow of the
  standard's type (`int p = 1; p + PTRDIFF_MAX`, `int t = 1; t += PTRDIFF_MAX`), where pristine answers a value.

### 3.3 The four macros, row by row (the comparisons with 0, the promotions and the literal arithmetic)

`TC` is the `_Generic` type code (7 `int`, 8 `unsigned`); `UB036` is `UB036_exceptional_condition`; "undefined:" marks
a gcc run that overflows in gcc's types.

| expression | fork before | fork after | pristine | gcc 13 |
|---|---|---|---|---|
| `WCHAR_MAX > 0` | 0 | 1 | 1 | 1 |
| `WCHAR_MAX < 0` | 1 | 0 | 0 | 0 |
| `WCHAR_MAX == 0` | 0 | 0 | 0 | 0 |
| `WCHAR_MAX != 0` | 1 | 1 | 1 | 1 |
| `WCHAR_MAX >= 0` | 0 | 1 | 1 | 1 |
| `WCHAR_MAX <= 0` | 1 | 0 | 0 | 0 |
| `0 < WCHAR_MAX` | 0 | 0 | 0 | 1 |
| `0 > WCHAR_MAX` | 1 | 1 | 1 | 0 |
| `0 == WCHAR_MAX` | 0 | 0 | 0 | 0 |
| `+WCHAR_MAX` | 18446744073709551615 | 4294967295 | 4294967295 | 2147483647 |
| `-WCHAR_MAX` | 1 | UB036 | UB036 | 18446744071562067969 |
| `~WCHAR_MAX` | 0 | 18446744069414584320 | 18446744069414584320 | 18446744071562067968 |
| `!WCHAR_MAX` | 0 | 0 | 0 | 0 |
| `(+WCHAR_MAX) > 0` | 0 | 1 | 1 | 1 |
| `sizeof(WCHAR_MAX)` | 4 | 4 | 4 | 4 |
| `sizeof(+WCHAR_MAX)` | 4 | 4 | 4 | 4 |
| `TC(WCHAR_MAX)` | 7 | 7 | 7 | 7 |
| `TC(+WCHAR_MAX)` | 7 | 7 | 7 | 7 |
| `TC(-WCHAR_MAX)` | 7 | 7 | 7 | 7 |
| `TC(~WCHAR_MAX)` | 7 | 7 | 7 | 7 |
| `WCHAR_MAX + 1` | 0 | UB036 | UB036 | undefined: 18446744071562067968 |
| `WCHAR_MAX - 1` | 18446744073709551614 | 4294967294 | 4294967294 | 2147483646 |
| `WCHAR_MAX - 1 > 0` | 0 | 1 | 1 | 1 |
| `WCHAR_MAX + 1 > 0` | 0 | UB036 | UB036 | undefined: 0 |
| `WCHAR_MAX + 1u` | 0 | UB036 | UB036 | 2147483648 |
| `WCHAR_MAX - 1u` | 4294967294 | 4294967294 | 4294967294 | 2147483646 |
| `WCHAR_MAX + 1l` | 4294967296 | UB036 | UB036 | 2147483648 |
| `WCHAR_MAX - 1ul` | 4294967294 | 4294967294 | 4294967294 | 2147483646 |
| `WCHAR_MIN > 0` | 0 | 0 | 0 | 0 |
| `WCHAR_MIN < 0` | 0 | 0 | 0 | 1 |
| `WCHAR_MIN == 0` | 1 | 1 | 1 | 0 |
| `WCHAR_MIN != 0` | 0 | 0 | 0 | 1 |
| `WCHAR_MIN >= 0` | 1 | 1 | 1 | 0 |
| `WCHAR_MIN <= 0` | 1 | 1 | 1 | 1 |
| `0 < WCHAR_MIN` | 0 | 0 | 0 | 0 |
| `0 > WCHAR_MIN` | 0 | 0 | 0 | 1 |
| `0 == WCHAR_MIN` | 1 | 1 | 1 | 0 |
| `+WCHAR_MIN` | 0 | 0 | 0 | 18446744071562067968 |
| `-WCHAR_MIN` | 0 | 0 | 0 | undefined: 18446744071562067968 |
| `~WCHAR_MIN` | 18446744073709551615 | 18446744073709551615 | 18446744073709551615 | 2147483647 |
| `!WCHAR_MIN` | 1 | 1 | 1 | 0 |
| `(+WCHAR_MIN) > 0` | 0 | 0 | 0 | 0 |
| `sizeof(WCHAR_MIN)` | 4 | 4 | 4 | 4 |
| `sizeof(+WCHAR_MIN)` | 4 | 4 | 4 | 4 |
| `TC(WCHAR_MIN)` | 7 | 7 | 7 | 7 |
| `TC(+WCHAR_MIN)` | 7 | 7 | 7 | 7 |
| `TC(-WCHAR_MIN)` | 7 | 7 | 7 | 7 |
| `TC(~WCHAR_MIN)` | 7 | 7 | 7 | 7 |
| `WCHAR_MIN + 1` | 1 | 1 | 1 | 18446744071562067969 |
| `WCHAR_MIN - 1` | 18446744073709551615 | UB036 | UB036 | undefined: 2147483647 |
| `WCHAR_MIN - 1 > 0` | 0 | UB036 | UB036 | undefined: 1 |
| `WCHAR_MIN + 1 > 0` | 1 | 1 | 1 | 0 |
| `WCHAR_MIN + 1u` | 1 | 1 | 1 | 2147483649 |
| `WCHAR_MIN - 1u` | 4294967295 | UB036 | UB036 | 2147483647 |
| `WCHAR_MIN + 1l` | 1 | 1 | 1 | 18446744071562067969 |
| `WCHAR_MIN - 1ul` | 18446744073709551615 | UB036 | UB036 | 18446744071562067967 |
| `WINT_MAX > 0` | 1 | 1 | 1 | 1 |
| `WINT_MAX < 0` | 0 | 0 | 0 | 0 |
| `WINT_MAX == 0` | 0 | 0 | 0 | 0 |
| `WINT_MAX != 0` | 1 | 1 | 1 | 1 |
| `WINT_MAX >= 0` | 1 | 1 | 1 | 1 |
| `WINT_MAX <= 0` | 0 | 0 | 0 | 0 |
| `0 < WINT_MAX` | 1 | 1 | 1 | 1 |
| `0 > WINT_MAX` | 0 | 0 | 0 | 0 |
| `0 == WINT_MAX` | 0 | 0 | 0 | 0 |
| `+WINT_MAX` | 2147483647 | 2147483647 | 2147483647 | 4294967295 |
| `-WINT_MAX` | 18446744071562067969 | UB036 | UB036 | 1 |
| `~WINT_MAX` | 18446744071562067968 | 18446744071562067968 | 18446744071562067968 | 0 |
| `!WINT_MAX` | 0 | 0 | 0 | 0 |
| `(+WINT_MAX) > 0` | 1 | 1 | 1 | 1 |
| `sizeof(WINT_MAX)` | 4 | 4 | 4 | 4 |
| `sizeof(+WINT_MAX)` | 4 | 4 | 4 | 4 |
| `TC(WINT_MAX)` | 7 | 7 | 7 | 8 |
| `TC(+WINT_MAX)` | 7 | 7 | 7 | 8 |
| `TC(-WINT_MAX)` | 7 | 7 | 7 | 8 |
| `TC(~WINT_MAX)` | 7 | 7 | 7 | 8 |
| `WINT_MAX + 1` | UB036 | UB036 | UB036 | 0 |
| `WINT_MAX - 1` | 2147483646 | 2147483646 | 2147483646 | 4294967294 |
| `WINT_MAX - 1 > 0` | 1 | 1 | 1 | 1 |
| `WINT_MAX + 1 > 0` | UB036 | UB036 | UB036 | 0 |
| `WINT_MAX + 1u` | 2147483648 | UB036 | UB036 | 0 |
| `WINT_MAX - 1u` | 2147483646 | 2147483646 | 2147483646 | 4294967294 |
| `WINT_MAX + 1l` | 2147483648 | UB036 | UB036 | 4294967296 |
| `WINT_MAX - 1ul` | 2147483646 | 2147483646 | 2147483646 | 4294967294 |
| `WINT_MIN > 0` | 0 | 0 | 0 | 0 |
| `WINT_MIN < 0` | 0 | 0 | 0 | 0 |
| `WINT_MIN == 0` | 1 | 1 | 1 | 1 |
| `WINT_MIN != 0` | 0 | 0 | 0 | 0 |
| `WINT_MIN >= 0` | 1 | 1 | 1 | 1 |
| `WINT_MIN <= 0` | 1 | 1 | 1 | 1 |
| `0 < WINT_MIN` | 0 | 0 | 0 | 0 |
| `0 > WINT_MIN` | 0 | 0 | 0 | 0 |
| `0 == WINT_MIN` | 1 | 1 | 1 | 1 |
| `+WINT_MIN` | 0 | 0 | 0 | 0 |
| `-WINT_MIN` | 0 | 0 | 0 | 0 |
| `~WINT_MIN` | 18446744073709551615 | 18446744073709551615 | 18446744073709551615 | 4294967295 |
| `!WINT_MIN` | 1 | 1 | 1 | 1 |
| `(+WINT_MIN) > 0` | 0 | 0 | 0 | 0 |
| `sizeof(WINT_MIN)` | 4 | 4 | 4 | 4 |
| `sizeof(+WINT_MIN)` | 4 | 4 | 4 | 4 |
| `TC(WINT_MIN)` | 7 | 7 | 7 | 8 |
| `TC(+WINT_MIN)` | 7 | 7 | 7 | 8 |
| `TC(-WINT_MIN)` | 7 | 7 | 7 | 8 |
| `TC(~WINT_MIN)` | 7 | 7 | 7 | 8 |
| `WINT_MIN + 1` | 1 | 1 | 1 | 1 |
| `WINT_MIN - 1` | 18446744073709551615 | UB036 | UB036 | 4294967295 |
| `WINT_MIN - 1 > 0` | 0 | UB036 | UB036 | 1 |
| `WINT_MIN + 1 > 0` | 1 | 1 | 1 | 1 |
| `WINT_MIN + 1u` | 1 | 1 | 1 | 1 |
| `WINT_MIN - 1u` | 4294967295 | UB036 | UB036 | 4294967295 |
| `WINT_MIN + 1l` | 1 | 1 | 1 | 1 |
| `WINT_MIN - 1ul` | 18446744073709551615 | UB036 | UB036 | 18446744073709551615 |

The asymmetries in the pristine column (`WCHAR_MAX > 0` is 1 and `0 < WCHAR_MAX` is 0) are upstream's and are the
fork's again; tray 62 carries them.

## 4. The witness (`scripts/check_macro_type_ranks.sh`, row 1; `tests/macro_type_ranks/`, 126 programs)

The script had one class of pinned row (gcc's line on both engines) and now has two. This section describes the
witness as M1 committed it (one mode, 126 programs, eight plants); §4.1 is what the pre-merge review changed, and
is the present shape.

- **KEPT rows (19; `kept.txt`).** A row named in `kept.txt` is pinned to PRISTINE's line: the script fails the row
  unless its line in `expected.txt` equals its line in `pristine.txt` (check K0), then requires both engines to
  print it with the exit code the verdict implies (0 for `Defined`, 1 for `Undefined`). gcc 13's line stands beside
  each name in `kept.txt` (declared: upstream's behaviour kept, gcc's beside). `d14.txt` carries, for each, the line
  the fork printed from 2026-11-04 to 2026-11-14 (the oracle built at `06afa3ef7` before the change): all 19 differ
  from the pin. The rows:

| row | fork 2026-11-04..14 (`d14.txt`) | pin = pristine | gcc beside (`kept.txt`) |
|---|---|---|---|
| `audit_rank_wchar` | `Specified(0)`, stdout `100001 100001 1 1 500010…` | `UB036` | `Specified(0)`, stdout `100001 100001 1 1 500010…` |
| `dense_wchar_t_bneg` | `Specified(0)`, stdout `200000002 200000002 2000…` | `UB036` | `Specified(0)`, stdout `200000002 200000002 2000…` |
| `dense_wchar_t_pos` | `Specified(0)`, stdout `200000006 200000006 2000…` | `UB036` | `Specified(0)`, stdout `200000006 200000006 2000…` |
| `dense_wchar_vs_macro_pos` | `Specified(0)`, stdout `4294967304 4294967304 42…` | `UB036` | `Specified(0)`, stdout `4294967304 4294967304 42…` |
| `kept_limits_pairs_1` | `UB036` | `Specified(0)`, stdout `0 1 0 1 0 1 0 8 42949672…` | `Specified(0)`, stdout `1 0 0 1 1 0 0 8 21474836…` |
| `kept_limits_pairs_2` | `UB036` | `Specified(0)`, stdout `2147483647 9223372036854…` | `Specified(0)`, stdout `9223372036854775807 9223…` |
| `kept_limits_wchar` | `Specified(0)`, stdout `0 1 0 1 0 1 0 1 0 184467…` | `Specified(0)`, stdout `1 0 0 1 1 0 0 1 0 429496…` | `Specified(0)`, stdout `1 0 0 1 1 0 1 0 0 214748…` |
| `kept_limits_wint` | `UB036` | `Specified(0)`, stdout `1 0 0 1 1 0 1 0 0 214748…` | `Specified(0)`, stdout `1 0 0 1 1 0 1 0 0 429496…` |
| `kept_ub_wchar_max_plus_1` | `Specified(0)` | `UB036` | `Specified(0)` (undefined in gcc) |
| `kept_ub_wchar_sub_false` | `Specified(1)` | `UB036` | `Specified(1)` |
| `kept_ub_wint_min_minus_1` | `Specified(0)` | `UB036` | `Specified(1)` |
| `kept_wchar_max_gt_0` | `Specified(0)` | `Specified(1)` | `Specified(1)` |
| `kept_wchar_obj_macro` | `Specified(0)`, stdout `0 1 0 1 0 1 1 0 0 200000…` | `Specified(0)`, stdout `0 1 0 1 0 1 1 0 0 200000…` | `Specified(0)`, stdout `0 1 0 1 0 1 1 0 0 200000…` |
| `kept_wchar_obj_std_200000005` | `Specified(0)`, stdout `0 1 0 1 0 1 1 0 0 200000…` | `Specified(0)`, stdout `0 1 0 1 0 1 1 0 0 200000…` | `Specified(0)`, stdout `0 1 0 1 0 1 1 0 0 200000…` |
| `kept_wchar_obj_std_2147483647` | `Specified(0)`, stdout `0 1 0 1 0 1 1 0 0 214748…` | `Specified(0)`, stdout `0 1 0 1 0 1 1 0 0 214748…` | `Specified(0)`, stdout `0 1 0 1 0 1 1 0 0 214748…` |
| `kept_wchar_self` | `UB036` | `Specified(0)`, stdout `0 0 18446744073709551615…` | `Specified(0)`, stdout `0 0 18446744073709551615…` |
| `kept_wint_min_gt_m1` | `Specified(1)` | `Specified(0)` | `Specified(0)` |
| `p_wchar_long` | `Specified(0)`, stdout `8589934593 8589934593 1\n` | `Specified(0)`, stdout `1 8589934593 0\n` | `Specified(0)`, stdout `8589934593 8589934593 1\n` |
| `promo_wchar_t` | `Specified(0)`, stdout `200000005 18446744073509…` | `UB036` | `Specified(0)`, stdout `200000005 18446744073509…` |

  The five single-purpose programs are hand-written (the reproducer; its `wint_t` sibling; three `Undefined` rows
  upstream answers, `kept_ub_wchar_sub_false` being its false verdict of tray 62). The eight generated ones carry
  every vicinity row with a `wchar_t`/`wint_t` operand of the kinds named in their header for which the fixed fork
  = pristine is `Defined` and gcc's run is not undefined, one value per expression. The five rows of the 2026-11-04
  set (`dense_wchar_t_pos`, `dense_wchar_t_bneg`, `promo_wchar_t`, `audit_rank_wchar`, `p_wchar_long`) were pinned
  to gcc's line and are re-pinned to pristine's (their committed `pristine.txt` lines of 2026-11-04 equal today's
  runs). `dense_wchar_vs_macro_pos` is the `wchar_t` part of `dense_macro_vs_macro_pos`, text unchanged, moved out
  so that the six remaining types keep a gcc-pinned positive matrix (its gcc line re-derived; pristine prints the
  same line for those six on positive operands, so that row no longer counts as moved).
- **gcc-pinned rows (104, was 103): six new** — the limit macros of the other types, every selected vicinity row
  where the fork equals gcc: `limits_header_1..4` (the 29 header macros that Cerberus declares, other than `WCHAR_*`/`WINT_*`: compared
  with 0, promoted, converted, the literal arithmetic, and against the four partner types at -1), `limits_direct_1`
  (the 36 direct `__cerbvar_*` spellings: compared with 0, promoted, converted) and `limits_pairs_1` (the nine
  limits of the macro types that carry their rank, pairwise). gcc is given the shipped header's own definitions of
  the exact-width limits inside `#ifndef __cerb__` (§3.1 (i)).
- Expressions per generated program (derived from the generator's plan): `kept_limits_wchar` 822, `kept_limits_wint` 833, `kept_limits_pairs_1` 1123, `kept_limits_pairs_2` 1122, `kept_wchar_obj_std_200000005` 1496, `kept_wchar_obj_std_2147483647` 1382, `kept_wchar_obj_macro` 1497, `kept_wchar_self` 178, `limits_header_1` 1235, `limits_header_2` 1235, `limits_header_3` 1235, `limits_header_4` 1233, `limits_direct_1` 1581, `limits_pairs_1` 818.
- **Counts pinned in the script** (a dropped or reclassified row fails a full run): 126 programs = 104 gcc-pinned +
  19 KEPT + 2 declared residuals + 1 gap control. Of the KEPT pins 8 are `Undefined`; 2 equal gcc's line (the two
  one-line reproducers), 17 do not.
- **Plants** (13-program subset: 6 moved and 2 unmoved gcc rows, the UB control, the gap control, 3 KEPT rows — the
  reproducer, the `WCHAR_*` matrix, one `Undefined`; counts derived in the script's comment): the five of
  2026-11-04 re-derived (`dense_wchar_t_pos` left the moved subset for `dense_intmax_t_pos`), and three new.
  `pristine-pair` now also shows the design: the two `Defined` KEPT rows PASS a pristine-replaying pair (their pin
  is pristine's line; the selftest asserts they pass), so the pristine plants cannot guard them — `d14-pair` (both
  engines replay `d14.txt` on the KEPT rows, every other program delegated to the real engines) and `lean-d14` (the
  Lean side only) do, and `kept-tamper` (a KEPT row's pin replaced by gcc's line) trips K0. The selftest refuses to
  run if a KEPT plant row's `d14.txt` line equals its pin.

Verbatim (`--selftest`, 2026-11-14, the M1 tree):

```text
check_macro_type_ranks: selftest plant 'pristine-pair' caught: 18 failing check(s) (= expected 18; incl. the required programs)
check_macro_type_ranks: selftest plant 'lean-pristine' caught: 9 failing check(s) (= expected 9; incl. the required programs)
check_macro_type_ranks: selftest plant 'lean-fixed' caught: 13 failing check(s) (= expected 13; incl. the required programs)
check_macro_type_ranks: selftest plant 'oracle-rc' caught: 19 failing check(s) (= expected 19; incl. the required programs)
check_macro_type_ranks: selftest plant 'expect-tamper' caught: 2 failing check(s) (= expected 2; incl. the required programs)
check_macro_type_ranks: selftest plant 'd14-pair' caught: 6 failing check(s) (= expected 6; incl. the required programs)
check_macro_type_ranks: selftest plant 'lean-d14' caught: 3 failing check(s) (= expected 3; incl. the required programs)
check_macro_type_ranks: selftest plant 'kept-tamper' caught: 1 failing check(s) (= expected 1; incl. the required programs)
check_macro_type_ranks: OK (126 programs: 104 batch lines of both engines = gcc 13's pinned line, exit codes equal — the dense per-type matrices (every standard partner and both enums, both operand orders, every operator and op=, positive and negative values) for size_t, ptrdiff_t, intptr_t, uintptr_t, intmax_t, uintmax_t and the two enums, the two macro-versus-macro matrices, the promotion probes, the direct __cerbty_* families, the limit macros of the shipped headers other than WCHAR_*/WINT_* and the direct __cerbvar_* limit spellings, tray 20's reproducer, the consumer's three programs, the audit's Set A probes, the measured siblings and the cluster K controls, 51 of them moved from pristine's pre-fix lines; 19 KEPT rows = pristine's line on both engines, upstream's behaviour for wchar_t and wint_t kept (8 of them Undefined, exit 1; 2 equal to gcc's line beside, 17 not): the reproducer WCHAR_MAX > 0 and its wint_t sibling, the WCHAR_*/WINT_* limit macros, wchar_t objects against every standard partner, the enums, the other macro types and themselves; 2 lines pinned to the fork's declared residuals (the intptr_t-against-unsigned false UB036 from the upstream NON-STD typing arm, filed; the size_t/intptr_t-against-long-long typing codes); 1 gap control: the negative wchar_t store still crashes both engines (tray 62, unchanged))
```

The pin files as committed were re-derived once more from the two referees after M1 (a scratch script over all 125
rows of `expected.txt`), verbatim:

```text
pristine binary vs pristine.txt: 125 equal, 0 differ; gcc vs its pinned line (expected.txt, or kept.txt for the KEPT rows): 123 equal, 0 differ, 2 rows have no gcc pin (the two declared residuals)
kept rows: 19 d14 rows: 19 d14 != expected on 19 ; kept pin == pristine.txt on 19
```

Cost, measured: the real run alone 87 s (`time`: 77 s user) with row 1 running beside it; the self-test and the real
run together 2 min 17 s (115 s user) with two other gate runs beside it, and 2 min 38 s (129 s user) on a box at
load 9. The record of 2026-11-04 gives about 60 s for the self-test
and the real run of the 106-program set, so this leg costs about two and a half times what it did: 20 more programs,
15,790 expressions in the 14 generated ones (derived: the sum of the line above). Named in §8 as a trim the
orchestrator may want.

### 4.1 After the pre-merge review (F5, F6): a row-1 core, `--full` as Tier B row 16, the generator committed

Ruling [AGENT 2026-11-14, orchestrator] under the gate-cruft rule, on the reviewer's F5: the leg as M1 committed it
was a measurement kept as a gate. Same programs, same pin files; what changed is which mode runs them.

- **CORE (default; row 1): 114 programs** = 98 gcc-pinned + 13 KEPT + 2 residual + 1 gap. The KEPT rows of the core:
  the five hand-written programs (the reproducer family), the five re-pinned rows of 2026-11-04 with
  `dense_wchar_vs_macro_pos`, and one generated matrix per type (`kept_limits_wchar`, `kept_limits_wint`).
- **`--full` (Tier B row 16, `scripts/LADDER.md`): all 126** = 104 + 19 + 2 + 1: the core plus the twelve programs of
  the script's `FULL_ONLY` list — the six gcc-pinned `limits_*` programs (7,337 expressions) and the six bulk KEPT
  matrices (`kept_limits_pairs_1..2`, `kept_wchar_obj_std_200000005`, `kept_wchar_obj_std_2147483647`,
  `kept_wchar_obj_macro`, `kept_wchar_self`; 6,798 expressions). A `FULL_ONLY` name that is not a pinned program
  fails either mode. The class counts are pinned per mode. The printf witness's split is the precedent
  (`scripts/check_printf_refusals.sh`).
- **Plants (F6): seven, was eight.** `lean-d14` is dropped: on the same rows `lean-fixed` already shows that a wrong
  Lean line on a KEPT row fails. `d14-pair` now runs on EVERY KEPT row of the mode and on nothing else (13 rows in
  the core, 19 under `--full`; expected 2 failing checks per row: 26 / 38), and the selftest refuses to run unless
  every one of those rows has a `d14.txt` line that differs from its pin, so all 19 lines of the file are read under
  `--full` and 13 in row 1. Since both of its engines are replay stubs, its Cabs export is a placeholder, not a real
  oracle run. `expect-tamper` and `kept-tamper` run on their one tampered row. To stay inside the cost bound the
  plant subset's KEPT rows are the two one-line reproducers and one `Undefined` row (the `WCHAR_*` matrix is no
  longer run by five plants; it is the row `kept-tamper` alters), and the subset's sixth moved row is
  `audit_rank_size_t_compound` (0.3 s) where M1 had put `dense_intmax_t_pos` (1.1 s) in the place
  `dense_wchar_t_pos` had left. The counts of the first five plants are unchanged (18/9/13/19/2).
- **The generator: `tests/macro_type_ranks/generate.py`**, committed beside the fourteen programs it produces. It is
  the scratch generator of §3.1 and the witness generator of this section, re-created from the worker's session
  after the scratch had been deleted (they were gone at M3: the reviewer's point), reduced to the three referees
  the selection reads (this tree's oracle, an un-forked Cerberus given on the command line, gcc with its UBSan
  build) and to the 17,652 of the 54,329 enumerated rows that a program can select. `--check` re-measures and
  compares each emitted program with the committed file; `--emit DIR` writes them. It names no path of this box.
  It does not write pin lines: those are each engine's own line for the emitted program. Verbatim, 2026-11-14, on
  the built tip tree against `deps/cerberus-upstream` at `c3ff8c53f`:

  ```text
  generate.py: 54329 rows enumerated, 17652 measured (the rows a program can select)
  generate.py: oracle: 17652 rows measured, 15902 with a value
  generate.py: pristine: 17652 rows measured, 15855 with a value
  generate.py: gcc: 558 groups, 17142 rows with a value, 510 undefined in gcc's types
  generate.py: emitted kept_limits_wchar (822), kept_limits_wint (833), kept_limits_pairs_1 (1123), kept_limits_pairs_2 (1122), kept_wchar_obj_std_200000005 (1496), kept_wchar_obj_std_2147483647 (1382), kept_wchar_obj_macro (1497), kept_wchar_self (178), limits_header_1 (1235), limits_header_2 (1235), limits_header_3 (1235), limits_header_4 (1233), limits_direct_1 (1581), limits_pairs_1 (818)
  generate.py: CHECK OK (14 programs, 15790 expressions: each emitted file is byte-identical to the committed one)
  ```

  (`time`: 3:21.87 total at `--jobs 6`.) Plant: with one space inserted into the committed `kept_wchar_self.c`,
  `--check` exits 1:

  ```text
  generate.py: CHECK FAILED -- kept_wchar_self: differs from the committed file
  ```

  It is a claim-point instrument, not a ladder row: it needs an un-forked Cerberus build. When tray 62 is settled
  upstream, at a merge-base bump, or when the shipped headers' limit macros change (the script stops if the
  enumeration is no longer 54,329 rows), re-run it and re-derive the pins of the programs that moved.
- **Cost, measured 2026-11-14 on an idle box (load 1 to 2), `time` totals.** The pre-slice leg cannot be run as it
  was on a fixed tree (its five `wchar_t` pins fail), so it was replicated: the script and the 106-program set of
  `06afa3ef7` in a scratch worktree on today's binaries, with the `wchar_t` pins set to today's lines and
  `dense_intmax_t_pos` in the plant subset for `dense_wchar_t_pos` — the same 106 programs and five plants on ten
  programs, every plant at its 2026-11-04 count (16/8/10/17/2).

  | leg | `--selftest` (plants + real run) | real run alone |
  |---|---|---|
  | pre-slice replica (106 programs, 5 plants) | 62.85 s and 62.02 s (two runs) | 43.3 s |
  | M1 as committed (126 programs, 8 plants) | 2 min 17 s (worker), 2 min 14 s (reviewer) | 87 s, 84 s |
  | core, row 1 (114 programs, 7 plants) | 62.88 s and 63.48 s (two runs) | 47.5 s, 48.6 s |
  | `--full`, Tier B row 16 (126 programs, 7 plants) | 1 min 40.97 s and 1 min 41.83 s | 87.4 s |

  The core is at the pre-slice leg's cost to within the run-to-run spread, 0 to 1.5 s above it and not below: its
  real run is about 4 to 5 s longer (8 more programs, the two per-type matrices 1.9 s each) and its plants about 4 s
  shorter. The ruling's bound was that cost or less; this is what was reached without thinning the 2026-11-04 plants
  further.

Verbatim, the tip tree (`--selftest`, then `--selftest --full`):

```text
check_macro_type_ranks: selftest plant 'pristine-pair' caught: 18 failing check(s) (= expected 18; incl. the required programs)
check_macro_type_ranks: selftest plant 'lean-pristine' caught: 9 failing check(s) (= expected 9; incl. the required programs)
check_macro_type_ranks: selftest plant 'lean-fixed' caught: 13 failing check(s) (= expected 13; incl. the required programs)
check_macro_type_ranks: selftest plant 'oracle-rc' caught: 19 failing check(s) (= expected 19; incl. the required programs)
check_macro_type_ranks: selftest plant 'expect-tamper' caught: 2 failing check(s) (= expected 2; incl. the required programs)
check_macro_type_ranks: selftest plant 'd14-pair' caught: 26 failing check(s) (= expected 26; incl. the required programs)
check_macro_type_ranks: selftest plant 'kept-tamper' caught: 1 failing check(s) (= expected 1; incl. the required programs)
check_macro_type_ranks: OK (core, row 1; the six limits_* programs and the six bulk KEPT matrices run in --full: 114 programs: 98 batch lines of both engines = gcc 13's pinned line, exit codes equal — the dense per-type matrices (every standard partner and both enums, both operand orders, every operator and op=, positive and negative values) for size_t, ptrdiff_t, intptr_t, uintptr_t, intmax_t, uintmax_t and the two enums, the two macro-versus-macro matrices, the promotion probes, the direct __cerbty_* families, the limit macros of the shipped headers other than WCHAR_*/WINT_* and the direct __cerbvar_* limit spellings, tray 20's reproducer, the consumer's three programs, the audit's Set A probes, the measured siblings and the cluster K controls, 48 of them moved from pristine's pre-fix lines; 13 KEPT rows = pristine's line on both engines, upstream's behaviour for wchar_t and wint_t kept (8 of them Undefined, exit 1; 2 equal to gcc's line beside, 11 not): the reproducer WCHAR_MAX > 0 and its wint_t sibling, the WCHAR_*/WINT_* limit macros, wchar_t objects against every standard partner, the enums, the other macro types and themselves; 2 lines pinned to the fork's declared residuals (the intptr_t-against-unsigned false UB036 from the upstream NON-STD typing arm, filed; the size_t/intptr_t-against-long-long typing codes); 1 gap control: the negative wchar_t store still crashes both engines (tray 62, unchanged))
```

```text
check_macro_type_ranks: selftest plant 'pristine-pair' caught: 18 failing check(s) (= expected 18; incl. the required programs)
check_macro_type_ranks: selftest plant 'lean-pristine' caught: 9 failing check(s) (= expected 9; incl. the required programs)
check_macro_type_ranks: selftest plant 'lean-fixed' caught: 13 failing check(s) (= expected 13; incl. the required programs)
check_macro_type_ranks: selftest plant 'oracle-rc' caught: 19 failing check(s) (= expected 19; incl. the required programs)
check_macro_type_ranks: selftest plant 'expect-tamper' caught: 2 failing check(s) (= expected 2; incl. the required programs)
check_macro_type_ranks: selftest plant 'd14-pair' caught: 38 failing check(s) (= expected 38; incl. the required programs)
check_macro_type_ranks: selftest plant 'kept-tamper' caught: 1 failing check(s) (= expected 1; incl. the required programs)
check_macro_type_ranks: OK (--full, Tier B: every program: 126 programs: 104 batch lines of both engines = gcc 13's pinned line, exit codes equal — the dense per-type matrices (every standard partner and both enums, both operand orders, every operator and op=, positive and negative values) for size_t, ptrdiff_t, intptr_t, uintptr_t, intmax_t, uintmax_t and the two enums, the two macro-versus-macro matrices, the promotion probes, the direct __cerbty_* families, the limit macros of the shipped headers other than WCHAR_*/WINT_* and the direct __cerbvar_* limit spellings, tray 20's reproducer, the consumer's three programs, the audit's Set A probes, the measured siblings and the cluster K controls, 51 of them moved from pristine's pre-fix lines; 19 KEPT rows = pristine's line on both engines, upstream's behaviour for wchar_t and wint_t kept (8 of them Undefined, exit 1; 2 equal to gcc's line beside, 17 not): the reproducer WCHAR_MAX > 0 and its wint_t sibling, the WCHAR_*/WINT_* limit macros, wchar_t objects against every standard partner, the enums, the other macro types and themselves; 2 lines pinned to the fork's declared residuals (the intptr_t-against-unsigned false UB036 from the upstream NON-STD typing arm, filed; the size_t/intptr_t-against-long-long typing codes); 1 gap control: the negative wchar_t store still crashes both engines (tray 62, unchanged))
```

## 5. Moved rows, pins and registers

### 5.1 The corpus sweep (the instrument `.tmp/sweep/sweep.py`, deleted at the end)

Every tracked `tests/**/*.c` and `lean_frontend/corpus/*.c` except `tests/csmith`, `tests/gcc-torture`,
`tests/cheri-ci` and `tests/mem-scale-probes` — but including every file of those four that mentions `wchar_t`,
`wint_t`, `WCHAR_M*`, `WINT_M*` or a wide literal — and the 203 `deps/cn/tests/cn/*.c`, each run in `--nolibc` and in
libc mode on the fork oracle before and after the change (30 s per run), the whole batch output and the exit code
compared:

```text
sweep: 3055 files x 2 modes = 6110 runs per engine; 12 rows with a timeout on a side; 37 rows differ before/after
```

The 37 differing rows are 24 files (derived from the instrument's `DIFF` lines):

| files | rows | what |
|---|---|---|
| `tests/macro_type_ranks/{audit_rank_wchar,dense_wchar_t_bneg,dense_wchar_t_pos,promo_wchar_t,p_wchar_long}.c` | 10 | **moved by the fix**: the five `wchar_t` witness programs of 2026-11-04, now pristine's line (§4) |
| `tests/parity-probes/uncertainty/E-wchar_t/wt-06-sizeof-signedness.c` | 2 | **moved by the fix**: `Specified(14)` → `Specified(4)`, pristine's (`(wchar_t)-1 < 0` is 0 again; gcc 14). Not gated; the survey record's row is annotated |
| `tests/parity-probes/probes/setjmp_basic.c` | 2 | not a difference: the `#error` diagnostic prints the runtime's path, and the two oracles have different install paths |
| 17 others | 23 | run-to-run nondeterminism of `--exec` on programs with unspecified evaluation order or address-dependent output, on BOTH oracles: each rerun 8 times per oracle, the two sets of outputs overlap in every case (`tests/coverage/z2/z2-00{5,6}-*`, `tests/z2-probes/nd/order{2,3}.c`, `tests/libc_exec/exhaustive/001-unseq-order-libc.c`, three `tests/pnvi_testsuite/provenance_equality_*_yx.c`, `tests/suite/{memory/a,sequencing/presentation2,undefined/unspec_vs_undef}.c`, `tests/coverage/mem4/mem4-024-memcpy-half-pointer.c`, `tests/sc-recovery/runtime/parallel-fputc.c`, four `tests/cn_coverage/drivers/*.driver.c` whose error names whichever unknown procedure is met first) |

The 12 rows with a timeout timed out on both oracles and are not in the 37. So in every corpus a lane gates on
(`tests/minimal`, `coverage`, `debug`, `float`, `bytes`, `libc_exec`, `multi_tu`, `immaculate`, `cn_coverage`,
`verify`, `stdio_exit`, `address_constants`, `printf_refusals`, `half_mirrors`, `pnvi_*`, the corpus fixtures) no
row moved; the lanes that pin a single trace of a nondeterministic program are not this slice's subject. The Lean
engine was not swept: it is generated from the same Lem, the generated delta is the one function (§2), and the
vicinity's 2,567 Lean rows and the witness's 125 programs agree with the oracle.

### 5.2 The libc Core and its pins: unchanged

The shipped C library uses `wchar_t` (`runtime/libc/src/stdlib.c`, `vfscanf.c`, the headers), so the dumps could
have moved; they did not. `scripts/libc_prep.sh --check` on the M1 tree, the four pin and census lines verbatim:

```text
libc_prep: OK (libc: pin + regenerated dump == 519d7c927cca883da2a004c101e064ffd52c352cb4d037d38ac589a29077f210, 4156776 bytes)
libc_prep: census OK (libc: 192 transported procs/funs; 6 shared bare names in 5 procs = the register; a speedbump on the printed spelling, not transport fidelity)
libc_prep: OK (libc_inner_arg_temps: pin + regenerated dump == dcd0499f5463ea0dd12a10ecb23a889ec9c366ab3133c0928c6d95329fb3481d, 4011125 bytes)
libc_prep: census OK (libc_inner_arg_temps: 192 transported procs/funs; 6 shared bare names in 5 procs = the register; a speedbump on the printed spelling, not transport fidelity)
```

No `tests/libc/*.core*`, `scripts/libc_float_literals.txt` or `test/CoreQuote/*.sha256` file is in the diff.

### 5.3 The fork-drift manifest

`scripts/fork_drift_manifest.txt`, single-row edits with a dated NOTE, no `--refresh`: `[source-content]`
`ailTypesAux.lem` `e278a3f6…` → `6acee29b…`; `[expected-semantic]` `ailTypesAux.ml` `52804c6c…` → `b90d962b…` (an
already-differing file; 23 rows and layer 2's 33 files unchanged). The delta stays a fork-ahead delta of the first
kind (the fork's own fix, tray 20, now with its correction). Verbatim:

```text
check_fork_drift: OK — layer 1: 96 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 33 differing generated files, all hash-pinned (merge-base c3ff8c53f05982745f9b3a10b3d05442e214bcb5; lem-pin 2220010bc25f0c5682d8200f016e786ee66d65c6 matches lem -v lean-backend-v0.1.0-alpha.1-88-g2220010 (hex prefix))
check_fork_drift: SELFTEST OK (31 plants with declared verdict/message: S1-S10 prerequisite/locale/name controls; S31 advanced upstream ref (not drift); S11 copied-content control; S12 inside-listed-file drift; S13/S14 duplicate/missing content pins; S15-S30 version forms, full-pin validation and refresh retention; unplanted gate green)
```

### 5.4 Failure reach, fuel forms, kernel replay

No `error`/`failwithI` site was added (the catch-all's is D14's and stays); the four new arms answer a value. No
measure proof changed: `rank_operand` and the rank functions are not recursive, their callers' measure-proof
modules are textually unchanged. Verbatim:

```text
check_failure_reach: OK (235 pure failure sites = the 235 register rows exactly (233 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, shared keys lengthened, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=174 REACHABLE=40 UNKNOWN=21; every row sealed; tally line consistent)
check_fuel_forms: OK (88 fuel'd workers: 67 MEASURED (obligation of the contract's shape incl. argument correspondence against the wrapper's body; every obligation + proof cone ⊆ the standard three; 13 of them under a hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions), 13 ABSORBING = kill at zero (the _zero lemma is the worker at literal 0 on its own binders = the monad's absorbing element, cone ⊆ the standard three; propagation NOT proved — lem TODO 13), 0 reachable-AMBIENT = the 0 rows of fuel_forms_pending.txt exactly, 8 ambient unreachable from the drive cone)
```

Kernel replay, run although no proof module changed (the definitions the callers' proofs elaborate against did):
`CERB_MEM_MAX=32G ../scripts/capped lake env leanchecker AilTypesAux AilTypesAux_lemMeasureProofs Translation
Translation_lemMeasureProofs` from `lean_frontend/`: no output, exit status 0.

### 5.5 The pristine register

Not moved. `scripts/upstream_oracle_differences.json` has no row about `wchar_t`, and §5.1 shows no row of any
corpus the pristine lane walks changed on the fork side. The lane itself (Tier B row 10) was not run by the worker:
it is the battery's.

## 6. M2: `tests/mem-scale-probes/micro` retired ([USER 2026-11-14])

The package (`Micro.lean`, `lakefile.toml`, `lake-manifest.json`, `lean-toolchain`, `.gitignore`; the
`memscale-micro` timing executable of the memory-scale arc) had not built since 2026-09-20 (five type errors since
the program-data parameters; found at the Lean 4.35 move) and no ladder row built it. Deleted, with every reference:

- `scripts/check_pin_sites.sh`: the pin sites are the lakefile rev, TWO lake-manifests (`lean_frontend/`,
  `lean_frontend/speclab/`) and the README's pin command. The eight plants never touched the third manifest (P3
  plants speclab's `inputRev`, P8 the root package's `rev`), so their set and count are unchanged — re-derived by
  reading each and by the selftest; the scratch copies carry two manifests and the OK line says 2.
- `scripts/release.py`: the three `REQUIRED_ARTIFACTS` entries removed (its unit test builds its fixture from the
  list, so nothing else moves).
- `scripts/build_provider_smoke.py`: KEPT, not deleted. Something does run it: `scripts/test_release.py`
  (`test_provider_cancellation_during_cleanup_stops_before_next_checkout`, in row 1 through `test_unit.sh`) imports
  the module and drives its `main()` with `LEM_REV` patched. The hard-coded revision (`f6542f8e…`, a 2026-09 pin
  that no pin gate knew: the lem TODO 54 re-pin review's F4) is replaced by `manifest_lem_pin()`, which reads
  `scripts/fork_drift_manifest.txt` `[meta] lem-pin` — the value `check_pin_sites.sh` holds every site to — and
  fails closed on a missing or malformed pin; `PACKAGES` drops the micro package and the runtime-pin plant uses
  speclab's manifest. NOT verified: the rehearsal itself (cold worktrees of both repositories, about an hour of
  builds) has not been run since 2026-09 and was not run here. An earlier text of this record and of the `TODO.md`
  entry asserted that it would stop at its compiler check; that was wrong (the pre-merge review's F3): the script
  builds lem with `LEMVERSION=<7 hex>` on the make command line (`build_provider_smoke.py:148-149`), which
  overrides lem's own `git describe` version, so the lem it builds prints the form its check compares with, by the
  reviewer's reading and the worker's re-reading. The entry now says "unverified" and asserts nothing.
- `scripts/LADDER.md` (the instruments table and row 1's "3 lake-manifests"), `scripts/test_unit.sh` and
  `scripts/check_no_fuel_numerals.sh` (comments), `lean_frontend/CLAUDE.md` (the gate list's "three
  lake-manifests"), `VALIDATION.md` (the warnings-are-errors coverage sentence, the gate table's pin-site row, the
  instruments sentence), `TODO.md` (the two items closed in place, the package-set item's "ALL THREE" now two, the
  sentence in the re-pin entry). No Tier C row named the instrument. The measurement records
  `tests/mem-scale-probes/results/*micro*.tsv` and the dated documents that describe the package are records and
  stay. The container's `CLAUDE.md` wording (three lake-manifests) is the orchestrator's.

Verbatim (the M2 tree):

```text
$ ./scripts/check_pin_sites.sh --selftest
check_pin_sites: SELFTEST OK (8 plants red with the declared message, unplanted copies green)
$ ./scripts/check_pin_sites.sh
check_pin_sites: OK — lem-pin 2220010bc25f0c5682d8200f016e786ee66d65c6 at every site (lakefile rev, 2 lake-manifests rev+inputRev, README pin command)
$ python3 scripts/test_release.py
Ran 16 tests in 3.343s

OK
```

## 7. Gates

All on the worker's worktree, focused gates only; Tier A on M1 and the battery on the tip are the orchestrator's.
`scripts/release.py` was not used to run anything (one `--list` call, which only prints the row IDs parsed from
`LADDER.md`, was made after editing a row's description; it ran no lane and left no artefact).

### 7.1 M1 (`0b10975b6`)

Build: `make clean-prelude-src prelude-src lean-prelude-src` at the start, the three dune steps, `make
lean-native-obj`, `CERB_MEM_MAX=32G scripts/capped lake build CerberusLean cerberus-lean`: `Build completed
successfully (409 jobs).` under `-DwarningAsError=true`; no linter option, no resource limit changed.

```text
$ ./scripts/test_unit.sh        # exit 0; `time`: 24:07.08 total
Total: 21 passed, 0 failed
check_theorem_axioms: hand-written axiom census OK (0 axioms — the arc-17 S2b end state)
check_theorem_axioms: generated-tree census OK (229 files: 0 axioms, boundary-opaque population = the 9 registered rows exactly-once (incl. CerbFuel.fuelExhaustedLoc), 0 unsafeCast)
check_pin_sites: SELFTEST OK (8 plants red with the declared message, unplanted copies green)
check_pin_sites: OK — lem-pin 2220010bc25f0c5682d8200f016e786ee66d65c6 at every site (lakefile rev, 3 lake-manifests rev+inputRev, README pin command)
check_macro_type_ranks: selftest plant 'pristine-pair' caught: 18 failing check(s) (= expected 18; incl. the required programs)
check_macro_type_ranks: selftest plant 'lean-pristine' caught: 9 failing check(s) (= expected 9; incl. the required programs)
check_macro_type_ranks: selftest plant 'lean-fixed' caught: 13 failing check(s) (= expected 13; incl. the required programs)
check_macro_type_ranks: selftest plant 'oracle-rc' caught: 19 failing check(s) (= expected 19; incl. the required programs)
check_macro_type_ranks: selftest plant 'expect-tamper' caught: 2 failing check(s) (= expected 2; incl. the required programs)
check_macro_type_ranks: selftest plant 'd14-pair' caught: 6 failing check(s) (= expected 6; incl. the required programs)
check_macro_type_ranks: selftest plant 'lean-d14' caught: 3 failing check(s) (= expected 3; incl. the required programs)
check_macro_type_ranks: selftest plant 'kept-tamper' caught: 1 failing check(s) (= expected 1; incl. the required programs)
check_macro_type_ranks: OK (126 programs: 104 batch lines of both engines = gcc 13's pinned line, exit codes equal — the dense per-type matrices (every standard partner and both enums, both operand orders, every operator and op=, positive and negative values) for size_t, ptrdiff_t, intptr_t, uintptr_t, intmax_t, uintmax_t and the two enums, the two macro-versus-macro matrices, the promotion probes, the direct __cerbty_* families, the limit macros of the shipped headers other than WCHAR_*/WINT_* and the direct __cerbvar_* limit spellings, tray 20's reproducer, the consumer's three programs, the audit's Set A probes, the measured siblings and the cluster K controls, 51 of them moved from pristine's pre-fix lines; 19 KEPT rows = pristine's line on both engines, upstream's behaviour for wchar_t and wint_t kept (8 of them Undefined, exit 1; 2 equal to gcc's line beside, 17 not): the reproducer WCHAR_MAX > 0 and its wint_t sibling, the WCHAR_*/WINT_* limit macros, wchar_t objects against every standard partner, the enums, the other macro types and themselves; 2 lines pinned to the fork's declared residuals (the intptr_t-against-unsigned false UB036 from the upstream NON-STD typing arm, filed; the size_t/intptr_t-against-long-long typing codes); 1 gap control: the negative wchar_t store still crashes both engines (tray 62, unchanged))
translation-fuel: PASS (two dead-code witnesses, constant-expression refusal in batch and pp-core, five successful controls)
$ ./scripts/test_exec.sh --check-baseline
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
$ ./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
$ ./scripts/test_exec.sh --check-baseline=scripts/exec_debug_baseline.txt tests/debug
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
$ ./scripts/test_exec.sh --check-baseline=scripts/exec_float_baseline.txt tests/float
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
$ ./scripts/test_libc_exec.sh
SUMMARY: match=42 loc_only=2 diff=0
ALL MATCH RECORDED BASELINE
$ ./scripts/test_inner_arg_temps.sh --gate        # its selftest lines omitted; the real run:
SUMMARY: inner_arg_temps rows=188 AGREE=138 AGREE-FIRST=41 BOTH_FAIL=5 LOC_ONLY-FIRST=2 RESOURCE oracle:KILL=2 failures=0
BASELINE OK (inner_arg_temps: 188 rows; classes and both distinct-observation/status hashes exact)
$ (cd lean_frontend && CERB_MEM_MAX=32G ../scripts/capped lake env leanchecker AilTypesAux AilTypesAux_lemMeasureProofs Translation Translation_lemMeasureProofs)   # no output; exit 0
```

### 7.2 M2 and M3

M2 (`511fab783`): the block of §6. M3: documents only. Row 1 was then run again on the tip tree (M1 and M2
committed, the M3 documents in the working tree), which exercises M2's script changes inside the row:

```text
$ ./scripts/test_unit.sh        # exit 0; `time`: 31:00.16 total
Total: 21 passed, 0 failed
check_pin_sites: SELFTEST OK (8 plants red with the declared message, unplanted copies green)
check_pin_sites: OK — lem-pin 2220010bc25f0c5682d8200f016e786ee66d65c6 at every site (lakefile rev, 2 lake-manifests rev+inputRev, README pin command)
check_macro_type_ranks: selftest plant 'pristine-pair' caught: 18 failing check(s) (= expected 18; incl. the required programs)
check_macro_type_ranks: selftest plant 'lean-pristine' caught: 9 failing check(s) (= expected 9; incl. the required programs)
check_macro_type_ranks: selftest plant 'lean-fixed' caught: 13 failing check(s) (= expected 13; incl. the required programs)
check_macro_type_ranks: selftest plant 'oracle-rc' caught: 19 failing check(s) (= expected 19; incl. the required programs)
check_macro_type_ranks: selftest plant 'expect-tamper' caught: 2 failing check(s) (= expected 2; incl. the required programs)
check_macro_type_ranks: selftest plant 'd14-pair' caught: 6 failing check(s) (= expected 6; incl. the required programs)
check_macro_type_ranks: selftest plant 'lean-d14' caught: 3 failing check(s) (= expected 3; incl. the required programs)
check_macro_type_ranks: selftest plant 'kept-tamper' caught: 1 failing check(s) (= expected 1; incl. the required programs)
translation-fuel: PASS (two dead-code witnesses, constant-expression refusal in batch and pp-core, five successful controls)
```

The row took 24 min on M1 and 31 min on the tip; the box's load differed, no leg was added.

### 7.3 After the pre-merge review (`fc505be99`, then the documents)

The review is `2026-11-14_wchar-rank-premerge-review.md` (committed on the branch by the orchestrator, `45388a14c`;
no P1, five P2, five P3); its "Dispositions" section answers each finding. Code and witness: `fc505be99` (§4.1 has
its lines and times: both modes of the witness with their selftests, `generate.py --check` and its plant,
`python3 scripts/test_release.py` `Ran 16 tests` `OK`). Row 1 as a whole was not re-run after it; Tier A and the
battery on the new tip are the orchestrator's.

## 8. Not done, open, observed

- **Not run by the worker:** Tier A as a tier (rows 6 to 14 not at all), Tier B (the pristine lane, row 10,
  included), any lane through `scripts/release.py` (the one `--list` call is in §7), `lake check`. Run: row 1 on
  M1 and again on the tip, rows 2, 3, 4, 4b, 5 and 15 on M1 (§7.1), the focused scripts of §5.
- **`wchar_t` and `wint_t` are upstream's again, defects included.** 1,693 measured rows that had gcc's answer
  from 2026-11-04 to 2026-11-14 have upstream's (§3.2); the false `UB036` verdicts and the narrowing against the
  `int` family are back; the negative-store crash never left. Tray 62 carries all of it, with the `wint_t` and
  limit-macro table added in this slice.
- **The witness leg's cost: resolved after the review** (F5, §4.1). As first committed the leg was two and a half
  times as slow as before the slice; row 1 now runs a 114-program core at the pre-slice leg's cost and the twelve
  bulk generated programs run under `--full` (Tier B row 16).
- **Observed in the vicinity, upstream's, not filed by this slice** (fork = pristine; none is a regression):
  `MB_LEN_MAX`, `SIG_ATOMIC_MIN` and `SIG_ATOMIC_MAX` are `#define`d by the shipped `<limits.h>`/`<stdint.h>` to
  `__cerbvar_*` names the front end does not declare (any use is `error: use of undeclared identifier`); the narrow
  limits have their own type instead of the promoted one (`sizeof(CHAR_MAX)` is 1, C17 5.2.4.2.1#1 says `int`:
  `CHAR_MIN`/`CHAR_MAX`, `SCHAR_*`, `UCHAR_MAX`, `SHRT_*`, `USHRT_MAX`); `WCHAR_MAX > 0` and `0 < WCHAR_MAX`
  disagree on pristine (now in tray 62's table). Each wants a tray report or a line in an existing one: an
  orchestrator call.
- **`scripts/build_provider_smoke.py`'s rehearsal is unverified** (§6: not run since 2026-09; the worker's first
  claim that it would stop at its compiler check was wrong and is withdrawn).
- **One comment line of `ailTypesAux.lem` is 114 characters long** (the correction's cross-reference, inside the
  D14 comment); left, because reflowing it re-pins the manifest rows and re-runs every gate for no behaviour.
- **cerberus-caesium's present pin carries the defect** (the pre-merge review's F1; the worker had failed to find
  the pin): `deps/refinedc-lean/scripts/semantics-pin.env:26`, `CERBERUS_LEAN_COMMIT="03c8b4451ff08830306d687e639f7dc57baf6827"`
  (read by the worker 2026-11-14), the mainline head after the formatter landing of 2026-11-09, a descendant of
  `9b15a1f69`. Its note now says so and what to check. cerberus-sl's pin (`2b51d2a57`, this repository's landing
  note of 2026-09-23) predates `9b15a1f69` and carries neither D14 nor the defect.
- **The defective range** (the pre-merge review's F2): `9b15a1f69` up to but not including `0b10975b6`, i.e. the 59
  mainline commits `9b15a1f69`..`06afa3ef7` and, after a fast-forward, the charter commit `6ae2434c9`. The first
  text of the notes, CONTRACT D14, VALIDATION and TODO started the range at `bb6e8e9f9`, three commits late; the
  notes list the range by landing.
- **Quoted phrases in old commit subjects.** The worker's first report pointed at commit `2b51d2a57` as carrying a
  quoted operator phrase in its subject and described it wrongly: it is a commit of THIS repository (the mainline's
  landing note of 2026-09-23, which cerberus-sl pins), and it is one of 48 mainline commit subjects dated before
  the rule of 2026-10-16 that carry such a phrase (the pre-merge review's F9, its count). [USER 2026-11-14]: they
  are grandfathered; history is not rewritten.

## 9. Scratch, deleted at close-out

(The generator and witness generator named here were deleted with the scratch at M3 and RE-CREATED after the
pre-merge review as the committed `tests/macro_type_ranks/generate.py`, §4.1; the five-column vicinity instrument —
the pre-fix column, the report and statistics scripts — stays deleted.) `.tmp/vic/` (the generator, the runners, the five result files, the witness generator and its plan),
`.tmp/sweep/`, `.tmp/before/` (the pre-fix oracle, install tree and Lean driver), `.tmp/basewt/` (a detached
worktree at `6ae2434c9` with its generated trees, removed with `git worktree remove`), `.tmp/patch/`, `.tmp/v/`,
`.tmp/logs/`. The conclusions are in this record; the instruments are described closely enough in §3.1 and §5.1 to
be rebuilt.
