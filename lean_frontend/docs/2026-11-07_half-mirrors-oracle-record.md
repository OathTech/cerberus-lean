# The three oracle half-mirrors closed on the OCaml side (tray 10, 11, 13) — slice record (2026-11-07)

Branch `fix/half-mirrors-oracle`, worktree `worktrees/cerberus-lean-fix/half-mirrors-oracle`, from mainline `mdd/cerberus-lean` =
`1e5f2cbca` (merge-base upstream `c3ff8c53f`, Lean 4.35.0, lem `e6d8db5`); charter
`docs/2026-11-07_worker-charter-half-mirrors-oracle.md` (commit `0c60413f6`). Worker: Claude Fable 5.1 (agent). Every judgement
below that no operator ruling covers is marked [AGENT]. Status: **fixed in the fork's OCaml oracle (hand-written OCaml only: no
Lem change, no generated delta, no proof change; the Lean edits are comments), the two engines byte-identical on the three
classes and their vicinity; witnessed in row 1; every moved row dispositioned with gcc 13 as the referee; the ISO-fix register
rows R1/R2/R3 retired.** The gates and the lane runs are quoted in §6.

## 0. Rulings and standing rules

- [USER 2026-11-04] agreed the fix pass in the audited order; the bar for a fork fix: only where the standard's intent is very
  clear or a consumer is blocked, no invented semantics; the vicinity rule: fix the mechanism, probe its neighbours, refuse or
  file what is a judgement call. [USER 2026-11-07] dispatched this slice in parallel with two others (the formatter's refusals,
  the address constants): every shared-document edit is an appended entry or an in-place retirement of this slice's own rows.
- The mirror-OCaml doctrine (the container's working-practices doc): a hand-written seam mirrors the OCaml with cites or
  documents the divergence. Here the OCaml side was wrong and the Lean side right (the audit's HALF-MIRRORED rows 10, 11, 13),
  so the oracle moves to the Lean engine's behaviour and the divergence entries retire; the Lean engine is the reference, gcc
  13.3.0 (`-std=c11 -w -O0`) the referee for conforming programs.
- [AGENT 2026-11-07] `memcmp`'s terminal test is `count <= 0`, not `count = 0`: the Lean engine's `Int.toNat` already runs zero
  iterations on a negative count, `memcpy` in the same file has that shape (`Z.lt i size_n`), and the count is unreachable
  from C (a `size_t` is non-negative after `conv_int`); the declared difference Z2-M-13 (a negative count: upstream recursed
  forever, the Lean engine answered the empty comparison) retires with it. No other reading was open.
- [AGENT 2026-11-07] universal character names (`\u`, `\U`; the charter's candidate for a declared refusal) are left to the
  crash-to-refusal item (TODO, tray 63's site): both engines crash identically today in the decoder's catch-all, exactly as
  tray 63's multi-character and non-ASCII constants do, and a declared refusal needs a Lean stop site (a new `failwithI`
  envelope, a failure-reach row, a stop-site id) — a Lean semantics change outside this slice's "comments only" bound. One
  refusal arm at that site will cover all three shapes; UCNs need the execution character set, so a refusal, not an
  implementation, is the right end state. Pinned here as gap controls so the state is visible and a change is loud.
- [AGENT 2026-11-07] the contract decision is numbered D18 (the charter's number; the parallel slices take D16/D17) and
  appended at the end of CONTRACT §5 rather than after D15, so the orchestrator's rebase onto the other landings is mechanical.
- Clauses: C17 6.4.4.4#1 (the simple-escape-sequences: `\' \" \? \\ \a \b \f \n \r \t \v`), #4 (their values), #9 (the range of
  octal/hexadecimal escapes), #10 (multi-character constants: implementation-defined); 7.21.6.1#8 (`%c`: the `int` argument
  converted to `unsigned char` is written); 7.24.4.1 (`memcmp`).

## 1. The defects, as they stood (the fork's oracle at `1e5f2cbca` = pristine `c3ff8c53f` on every line below)

Verbatim, 2026-11-07 (`--exec --batch`, `--nolibc` for the two tray-10 programs, the shipped library otherwise; the Lean engine
`--batch --first`, libc mode = the pinned dump + the twelve metadata TUs; gcc 13.3.0):

```text
t10_char.c   int main(void) { char c = '\?'; return c; }
  fork oracle rc=125: Failure("decode_character_constant, started like an octal constant, but failed: ?")
  Lean        rc=0:   Defined {value: "Specified(63)", stdout: "", stderr: "", blocked: "false"}        gcc: 63
t10_str.c    int main(void) { const char *s = "a\?b"; return s[1]; }
  fork oracle rc=125: Failure("decode_character_constant, started like an octal constant, but failed: ?")
  Lean        rc=0:   Defined {value: "Specified(63)", stdout: "", stderr: "", blocked: "false"}        gcc: 63
t11_c127.c   char buf[8]; snprintf(buf, 8, "%c", 127); return buf[0];
  fork oracle rc=0:   Defined {value: "Specified(87)", stdout: "", stderr: "", blocked: "false"}
  Lean        rc=0:   Defined {value: "Specified(127)", stdout: "", stderr: "", blocked: "false"}       gcc: 127
t11_c19.c    char b[4]; snprintf(b, 4, "%c", 19); return b[0];
  fork oracle rc=125: Failure("decode_character_constant, started like an octal constant, but failed: 019")
  Lean        rc=0:   Defined {value: "Specified(19)", stdout: "", stderr: "", blocked: "false"}        gcc: 19
t13_memcmp.c char a[4] = {1,2,3,4}; char b[4] = {1,2,3,4}; return memcmp(a, b, (size_t)-1);
  fork oracle rc=125: Z.Overflow  (Raised by primitive operation at Z.to_int in file "z.ml", line 221)
  Lean        rc=1:   Undefined {ub: "UB_CERB002a_out_of_bound_load", stderr: "", loc: "<5:10--5:34>"}  gcc: exit 1 (UB)
```

The mechanisms (the sites at `1e5f2cbca`): `ocaml_frontend/decode.ml:146-154` (the simple-escape arms, no `"\\?"`) and
`:186-197` (the octal catch-all that `?` falls into); `decode.ml:220-221` `let escaped_char c = Char.escaped c` composed with the
octal reader inside `frontend/model/formatted.lem:802-824` `store_chars_in_array`, the `vsnprintf` builtin's store
(`formatted.lem:849`; reachable from the shipped library's `snprintf`/`sprintf`/`vsprintf`/`vsnprintf` and from a direct
`__builtin_vsnprintf` call — no other caller); `memory/concrete/impl_mem.ml:2585-2586` `get_bytes ptrval1 [] (Z.to_int size_n)`
(pristine `:2481-2482`; upstream's tip `:2503-2504` per the audit). The two tray-10 entry points share the decoder:
`translation.lem:211` (the character constant, `translate_constant`) and `:3124` (the string-literal arm, one call per
lexer-split escape unit); the lexer (`parsers/c/c_lexer.mll:409-424`) accepts `\?` as a `simple_escape_sequence` and
`universal_character_name`s as escapes, so both reach the decoder; `\8`, `\e`, an empty `\x` and an empty constant are lexer
rejections (`invalid symbol`), never decoded.

## 2. The fixes (M1, commit `c9f4435bf`)

### 2.1 `decode.ml` — the `\?` arm (tray 10)

One arm in the simple-escape group, `| "\\?" -> Z.of_int 63` (`decode.ml:155-163` with its registration note; the Lean
`CerbDecode.decode_character_constant_aux` has carried the same arm since 2026-09-03). Arm-for-arm comparison of the two tables
(the charter's sibling check): the Lean table = {`\a \b \f \n \r \t \v`, `\\ \' \" \?`, the single-character set (letters, digits,
the graphic characters of 5.2.1#2, space, tab, `$ @ \``), `\x`+hex of any length, `\`+octal digits (the `'8'` quirk mirrored:
`48 <= n && n <= 56`), and the four failure arms}; the OCaml table lacked exactly `\?` and now has it. The `'8'` quirk stays
mirrored in both: it is unreachable from source (the lexer takes octal digits only) and, since tray 11's fix, from the store
(the decimal rendering that produced `\018` is gone); tray 10's remark is corrected accordingly.

### 2.2 `decode.ml` — `escaped_char` as the decoder's right inverse (tray 11)

`decode.ml:229-255`, mirroring `CerbDecode.escaped_char` arm for arm: `\n \t \r` → their simple escapes, `\\` `'` `"` → their
escaped forms, every other byte outside 32..126 → `\x%x` (lower case, unpadded: the decoder's hexadecimal arm accepts any
length), the byte itself otherwise. Why every byte round-trips: 0..31 and 127..255 take the hexadecimal arm (exact); 32 is the
table's space; 33..126 are all in the single-character table except backslash (92), which takes the escaped form, and the two
quotes, whose escaped forms are table arms too. Measured (§3.2): all 256 values through `snprintf("%c")` and 1..255 through
`snprintf("%s")` read back unchanged on both engines, the printed lines equal to gcc's byte for byte. Pristine's `Char.escaped`
emits OCaml's DECIMAL `\ddd` for the same bytes: 127 → `\127` → 0o127 = 87, 200 → 128, 18 → 16 (the `'8'` quirk), and every
decimal rendering containing a 9 (19, 29, …, 199, including 0xC3 = 195, the usual UTF-8 lead byte) is the octal validator's
uncaught Failure — a crash in the formatted path.

### 2.3 `impl_mem.ml` — `memcmp` counts on `Z` (tray 13)

`impl_mem.ml:2574-2602`: `get_bytes ptrval acc size` recurses on `Z.pred size` from `size_n` itself, stopping at `size <= 0`;
no `Z.to_int`. A huge size now runs the checked per-byte `load` until the first out-of-bound byte, whose `UB_CERB002a` is the
verdict, at the memop's location — exactly `CerbMem.memcmpM`. Sibling sites in `impl_mem.ml` (the charter's list; the audit
found them correct): `memcpy` (`:2561-2570`) already loops on `Z` (`Z.lt i size_n`); `realloc` (`:2604-2634`) takes `Z.min
alloc.size size_n` and allocates on `Z` (a huge request is the allocator's out-of-memory failure, a model design); `memset`,
`memmove`, `strncmp`, `strncpy`, `calloc` are not memops — they are C code in the shipped library (`runtime/libc/src/string.c`,
`stdlib.c`), each access checked by the model, so a huge `size_t` reaches the out-of-bound UB or the allocator's failure on
every engine (§3.2). The remaining `Z.to_int` reads in the file convert sizes of TYPES (`sizeof`, the file's own "will raise
Overflow on huge structs" TODOs — the retired R7 class) or allocation sizes bounded by the address space, not C-controlled
counts; `Z.pow n1 (Z.to_int n2)` (`:2374`) is an integer-power exponent outside this slice's mechanism (noted, not touched).

### 2.4 The Lean side, the manifest, the proofs

`CerbDecode.lean` (the R1 arm's comment, `escaped_char`'s doc comment) and `CerbMem.lean` (`memcmpM`'s doc comment and the R3
block) are rewritten as "both engines since 2026-11-07" with the cites; the `-- ISO-fix register Rn` markers are kept, marked
RETIRED, so the register's grep still finds the sites. Comments only: the generated tree is byte-identical (`make
lean-prelude-src`: the sync gate OK, no generated delta), no proof changed, no kernel replay is owed. The fork-drift manifest:
`[files]` + `[source-content]` ENTER `ocaml_frontend/decode.ml` (byte-identical to pristine before; 95 → 96 oracle-surface
files), `[source-content]` `memory/concrete/impl_mem.ml` re-pinned `e36ca672…` → `d61e7425…`, layer 2 unchanged (33), a dated
NOTE; single-row edits, never `--refresh`. The three patches against pristine `c3ff8c53f` (`git apply --check` in the pristine
checkout: OK for each) are in the tray drafts.

## 3. The vicinity

### 3.1 The instrument (`.tmp/vic/gen.py` + `run.sh`, deleted at slice end)

Every probe on four engines — the fork oracle (this tree), the Lean engine (libc mode where the probe needs the library),
pristine `c3ff8c53f` (`deps/cerberus-upstream`) and gcc 13.3.0 (`-std=c11 -w -O0`) — one row per probe, the audit's row shape.
Decoding (`--nolibc`, 83 + 5 probes): every simple escape as a character constant and inside a string (22) plus all eleven in
one printed program; octal escapes of one to three digits (`\0 \7 \17 \101 \177 \377`) and above 255 (`\400 \777`) in both forms,
the signed wrap of `'\377'`, the three-digit boundary (`"\1234"`), the four-digit `'\0123'`; hexadecimal escapes of several
lengths (`\x7 \x41 \x7f \xff \x0ff \x100 \xabc \xffff`) in both forms, the signed wrap of `'\xff'`, the greedy `"\x41B"` and the
literal boundary `"\x41" "B"`; universal character names (`é`, `\U0001F600`) in both forms; multi-character constants
(`'ab'`, `'\?\?'`); wide and prefixed forms (`L'a'`, `L'\?'`, `L'\377'`, `L'é'`, `L'ab'`, `L"a\?b"`, `L"\377"`, `sizeof(L"ab")`,
`u8"a\?b"`, `u8"é"`, `u'a'`, `U"a"`); raw UTF-8 in both forms; the lexer's rejections (`''`, `'\8'`, `'\e'`, `'\x'`,
`"\xg"`). Memory sizes (libc mode, 90 probes): `memcmp`, `memcpy`, `memmove`, `memset`, `strncmp`, `strncpy` × sizes 0, 1,
`SIZE_MAX`, `SIZE_MAX/2`, 2^31, 2^32 on two distinct 4-byte objects; × the same object, adjacent members of one struct (sizes 1
and `SIZE_MAX`), a null pointer (sizes 0 and 1); `strncmp`/`strncpy` on terminated strings; `memcmp` with an `int` −1 and with
n = 8; the round trip of every byte through `snprintf("%c")`, `snprintf("%s")` and `strcpy`; `sprintf` with mixed
conversions; `%c` of 0; a `"\?"` literal through `%s`; `realloc`/`calloc` with huge and overflowing sizes.

### 3.2 Results (derived from the row files)

Decoding, 88 rows: 67 all four engines equal; **6 moved by the fix** (fork = Lean = gcc, pristine's uncaught Failure):
`'\?'`, `"a\?b"`, the eleven-escape program (`39 34 63 92 7 8 12 10 13 9 11` twice and `sizeof` 12, gcc's two lines byte for
byte), `L'\?'`, `L"a\?b"[1]`, `u8"a\?b"[1]`; 5 lexer rejections on both engines (`''`, `'\8'`, `'\e'`, `'\x'`, `"\xg"`:
`invalid symbol` / `invalid string character` — gcc rejects three of them and accepts `\8` as 56 and `\e` as 27, GNU); **9
crash both engines identically** in the decoder's catch-all, pristine the same: `'é'` (gcc 169), `'\U0001F600'` (128),
`"é"` (195), `"\U0001F600"` (240), `u8"é"` (195), `'ab'` (98), `'\?\?'` (63: a multi-character constant of two `\?`),
`'é'` (169), `"é"` (195) — the oracle's `Failure("decode_character_constant, started like an octal constant, but failed: u00e9")`
/ `invalid char constant ==> ab`, the Lean engine's mirrored `UPSTREAM_CRASH` stop with the same text; `L'é'` and `L'ab'` the
same crash; `'\0123'` = **83 on all three engines**, gcc 51 (an octal escape of three digits then `'3'`: a multi-character
constant, implementation-defined 6.4.4.4#10; the engines read one four-digit escape); `L"\377"` crashes all three engines at
the `wchar_t` store (`bytes_of_int(signed), i= 4294967295, nbits= 32`; tray 62); `'\400'`, `'\777'`, `'\x100'`, `'\xabc'`,
`'\xffff'`, `"\400"`, `"\x41B"` (constraint violations, 6.4.4.4#9) are accepted by all three engines as the wrapped value, which
is gcc `-w`'s value too (gcc `-std=c11 -pedantic-errors` rejects each: `octal/hex escape sequence out of range`); `u'a'` and
`U"a"` are parser rejections on both engines (`char16_t`/`char32_t` undeclared without `<uchar.h>`); `sizeof(L"ab")` = 12 on
all four.

Memory sizes, 90 rows: 27 all four engines equal (every size 0 and 1 row of the memops and the library, `memmove` with
`d == s` at any size, `strncmp`/`strncpy` on terminated strings, `strcpy` of every byte, `%c` of 0); **`memcmp`: 5 rows moved
from pristine's `Z.Overflow` to `UB_CERB002a` at the memop on both engines** (`SIZE_MAX` on distinct, the same and adjacent
objects; an `int` −1; the tray reproducer), a sixth moved from the BASE oracle `1e5f2cbca` (`SIZE_MAX/2` = 2^63−1, outside
OCaml's 63-bit `int`: the base overflowed; pristine answered the UB because its rank bug computed the size at 32 bits, tray
20 / D14), 2^31, 2^32 and n = 8 the same UB on every engine before and after, a null source `UB019_lvalue_not_an_object` on
every engine; `memcpy`: every huge size `UB_CERB002a` on every engine (it already looped on `Z`), null → `UB046`, the same
object and adjacent members → the fork's D10 overlap refusal on both engines (pristine copies or reports the UB: known);
`memmove`/`memset`/`strncmp`/`strncpy` with a huge size: the library's loop reaches `UB_CERB002a`/`UB_CERB002b` on every
engine, the Lean engine's location `<unknown location>` (N4, the libc Core text transport; the oracle `string.c:27`, `:343`,
`:87`, `:43`), null → `UB046`/`UB043` likewise; `memmove(NULL, b, 1)`: fork and Lean `UB046` (the base too), pristine
`Memory WIP: lt_ptrval ==> one null pointer` — D14's rank fix changes which branch of musl's `memmove` the uintptr arithmetic
takes, not this slice; **`strncmp(a, b, 0)` and `strncpy(a, b, 0)` read before honouring n = 0** on every engine (`string.c:87`
`while ((*s1 && *s1 == *s2) && --n > 0)`, `:43` `while ((*s1++ = *s2++) && --n > 0)`: tray 30, with the `strncpy` sibling the
audit added; gcc 0 and 4); `calloc((size_t)1 << 63, 4)` returns non-null on every engine (tray 31; gcc NULL); `calloc(SIZE_MAX,
1)` and `realloc(p, SIZE_MAX)` are the allocator's out-of-memory `Error` on every engine (a model design; gcc NULL).
**The round trip:** all 256 values through `snprintf("%c")` and 1..255 through `snprintf("%s")` read back unchanged on both
fork engines, each printed line = gcc's byte for byte, `bad=0`; pristine dies at 19 (`"\019"`); `strcpy` (no round trip) is
equal on every engine before and after; the mixed `sprintf` (`%c` of 127, 200, 19, then a UTF-8 `%s`) sums to 217 on both
engines and gcc, pristine dies.

### 3.3 Findings (the vicinity table)

| # | finding | engines (fork / Lean / pristine / gcc) | disposition |
|---|---|---|---|
| 1 | `\?` in every literal form: the character constant, the string literal, `L'\?'`, `L"…\?…"`, `u8"…\?…"`, through `snprintf("%s")` | 63 / 63 / crash / 63 | **the fix** (tray 10); witnessed (`nolibc_esc_*`, `nolibc_wide_*`, `nolibc_u8_str_q`, `rt_snprintf_q_literal`) |
| 2 | every byte through the `snprintf` family's store | all equal / all equal / 87, 128, crash at 19 / all equal | **the fix** (tray 11); witnessed (`rt_*`) |
| 3 | `memcmp` with a size beyond OCaml's `int`, every pointer shape | `UB_CERB002a` / same / `Z.Overflow` / 1 or 0 | **the fix** (tray 13); witnessed (`ub_memcmp_*`) |
| 4 | universal character names in constants and strings (`é`, `\U0001F600`, also under `u8`) | crash / crash (mirrored) / crash / the UTF-8 bytes | a sibling at tray 63's site: the crash-to-refusal item (TODO) gains the UCN shape; [AGENT] not refused here (§0); gap controls `gap_ucn_*` |
| 5 | multi-character constants `'ab'`, `'\?\?'`, `L'ab'`; raw non-ASCII `'é'`, `"é"`, `L'é'` | crash / crash (mirrored) / crash / impl.-defined | tray 63 (recorded there); gap controls `gap_multi_char_ab`, `gap_utf8_str_raw` |
| 6 | `'\0123'`: three octal digits then `'3'` | 83 / 83 / 83 / 51 | tray 63's class (a multi-character constant read as one four-digit escape; implementation-defined); declared row `nolibc_fork_oct_char_0123`; noted in tray 63's scope by this record |
| 7 | out-of-range escapes `'\400'`, `'\x100'`, `"\x41B"`, … (constraint violation 6.4.4.4#9) | wrapped / wrapped / wrapped / wrapped under `-w`, rejected under `-pedantic-errors` | a front-end gap (an accepted constraint violation), both engines equal; declared rows `nolibc_*_cv`; no fix (a diagnostic is a judgement call, not this mechanism) |
| 8 | `L"\377"`, a negative value stored into `wchar_t` | crash / crash / crash / 255 | tray 62 (the crash-to-refusal item); gap control `gap_wide_str_L_377` |
| 9 | `'\8'`, `'\e'`, `'\x'`, `"\xg"`, `''` | lexer rejection on both engines; pristine the same | consistent front-end diagnostics (gcc accepts `\8` = 56 and GNU `\e` = 27); not a crash; not filed |
| 10 | `u'a'`, `U"a"` | parser rejection (`char16_t` undeclared) on both | the shipped headers lack `<uchar.h>`; a missing feature, not this slice |
| 11 | `strncmp`/`strncpy` with n = 0 read the strings | UB on every engine / gcc 0, 4 | tray 30 (`strncmp`; the `strncpy` sibling noted there by the audit); the shipped library, not this mechanism |
| 12 | `calloc` with an overflowing product | non-null on every engine / gcc NULL | tray 31; the shipped library |
| 13 | `memmove(NULL, b, 1)` fork ≠ pristine | `UB046` / `UB046` / `lt_ptrval` WIP error / SIGSEGV | tray 20's rank fix (D14; the base oracle already answers `UB046`), not this slice; no gated corpus row |
| 14 | library-code UB locations `<unknown location>` on the Lean engine | — | N4 (the libc Core text transport), unchanged |
| 15 | `memcpy` on the same/adjacent object | the D10 refusal on both fork engines | contract D10, unchanged |
| 16 | `realloc`/`calloc` of `SIZE_MAX` | the allocator's out-of-memory `Error` on every engine | the model's design (the allocator kills instead of returning NULL; tray 44's family), unchanged |
| 17 | `memcmp` with `SIZE_MAX/2` on pristine answers the UB | — | pristine's 32-bit size (tray 20); the fork's base overflowed; now the UB on both fork engines (`ub_memcmp_distinct_half`) |
| 18 | the decoder's third live caller, the `argv` store (`driver.lem:1792` `prepare_main_args`: every byte of every program argument through `decode_character_constant (String.toString [c])`, the raw character, no `escaped_char`): a backslash or any byte outside the single-character table in `argv` — found by the pre-merge review (F3) | crash / crash (mirrored) / crash / 92 for `'a\b'`, the byte for a non-ASCII one | a sibling of trays 10/11's mechanism at tray 63's site: the store needs the same right inverse the formatted store got, or the crash-to-refusal arm; the code change is a Lem edit (`driver.lem`, a generated delta), outside this hand-written-OCaml slice — recorded in the TODO crash-to-refusal item (3); both engines crash identically, the zero-discrepancy rule holds |

No sibling wrong on conforming input remains in the vicinity other than the known-and-filed library items (11, 12) and the
crash-to-refusal items (4, 5, 6, 8, and 18 — the `argv` store, a mirrored crash on both engines the pre-merge review found;
its reproducer and lines are in the review, F3).

### 3.4 The witness (`scripts/check_half_mirrors.sh`, row 1 via `test_unit.sh`; `tests/half_mirrors/`, 41 programs; M2 = commit `e7fcddb51`)

Every program carries its clause, gcc's answer and pristine's in its header. `expected.txt` pins ONE line per program that
both engines' `--batch` output must equal byte for byte with equal exit codes; the three pin files are DERIVED by the slice's
pin instrument (gcc 13.3.0 `-std=c11 -w -O0` with the streams captured separately and OCaml `String.escaped` escaping; the fork
oracle; pristine `c3ff8c53f`), never typed. Classes by name: 15 libc-mode rows pinned to gcc's line (`rt_*`: the tray-11
reproducers 127/19/200/0xC7, a mixed `sprintf`, a `"\?"` literal through `%s`, every byte 0..255 through `%c` and 1..255
through `%s` — the two printed lines — and the `strcpy` and `%c`-of-0 controls; the memop/library size controls
`memcmp_distinct_0/1`, `memmove_same_max`, `strncmp_strings_max`, `strncpy_strings_pad`); 8 libc-mode `ub_*` rows pinned to
the fork's own `Undefined` line on both engines, exit 1 (the tray-13 reproducer; `SIZE_MAX` on the same and adjacent objects;
`SIZE_MAX/2`; an `int` −1; the unmoved 2^32 and n = 8 controls; the `memcpy` sibling control) — declared FORK-PINNED, gcc's
exit beside them in `gcc.txt`; 12 `nolibc_*` rows pinned to gcc's line under `--nolibc` on both engines (the tray-10
reproducers `'\?'`, `"a\?b"`, the eleven-escape program, `L'\?'`, `L"a\?b"`, `u8"a\?b"`; the octal/hexadecimal controls
`"\1234"`, `"\x41" "B"`, `'\377'`, `'\xff'`; the two declared constraint violations `'\400'`, `'\x100'` at gcc `-w`'s
wrapped value); 1 `nolibc_fork_*` row (`'\0123'` = 83, FORK-PINNED, gcc's 51 beside it); 5 `gap_*` controls (both engines
must crash with the pinned ASCII text: `\u00e9` in a constant, `\U0001F600` in a string, `'ab'`, a raw non-ASCII string
byte, `L"\377"` at the `wchar_t` store). A pin that is neither gcc's line nor declared is a FAIL, so a silent re-pin cannot
pass; the total (41), the class counts (27/9/5) and the moved count (18 rows differ from `pristine.txt`) are pinned. Five
plants on an 8-program subset (one moved and one unmoved row per class, the gap control, the declared row), their counts
derived in the script: `pristine-pair` 10, `lean-pristine` 5, `lean-fixed` 8, `oracle-rc` 8, `expect-tamper` 3. Cost, the
pre-merge reviewer's measurement on a quiet box (1-minute load 2.9 to 5.7; the worker's own runs were on the shared box
beside two other workers and are not quoted): the self-test run `71.79s user 14.50s system 92% cpu 1:33.64 total`, the
plain run 55.0 s wall, the two 256-byte sweep rows alone 10.5 s wall including the libc transport — the stdio precedent's
band (70 s / 110 s); no trimming or tier move is warranted. Verbatim, the M2 run:

```text
check_half_mirrors: selftest plant 'pristine-pair' caught: 10 failing check(s) (= expected 10; incl. the required programs)
check_half_mirrors: selftest plant 'lean-pristine' caught: 5 failing check(s) (= expected 5; incl. the required programs)
check_half_mirrors: selftest plant 'lean-fixed' caught: 8 failing check(s) (= expected 8; incl. the required programs)
check_half_mirrors: selftest plant 'oracle-rc' caught: 8 failing check(s) (= expected 8; incl. the required programs)
check_half_mirrors: selftest plant 'expect-tamper' caught: 3 failing check(s) (= expected 3; incl. the required programs)
check_half_mirrors: OK (41 programs: 27 batch lines of both engines = gcc 13's pinned line, exit codes equal — the tray-11 reproducers (%c of 127, 19, 200; %s of 0xC7; a mixed sprintf; a "\?" literal through %s), every byte 0..255 through snprintf's %c and %s stores, a strcpy and a %c-of-0 control, the memop/library size controls, the tray-10 reproducers under --nolibc (the character constant, the string literal, every simple escape printed, the L and u8 prefixes) and the octal/hexadecimal escape controls incl. two declared constraint violations; 9 pinned to the fork's declared lines (the tray-13 reproducer and its size/pointer-shape neighbours as UB_CERB002a on both engines, two UB controls, the four-digit octal multi-character constant of tray 63's class); 5 gap controls (universal character names, a multi-character constant and a raw non-ASCII byte still crash both engines identically, tray 63; the negative wchar_t store, tray 62); 18 rows moved from pristine c3ff8c53f's lines)
```

## 4. Moved rows and pins (gcc the referee)

### 4.1 The census of what could move

The three mechanisms have lexical triggers: `\?` in a character constant or string literal (tray 10); a program storing
through the `snprintf` family (`snprintf`, `sprintf`, `vsnprintf`, `vsprintf`, a direct `__builtin_vsnprintf`) a byte outside
32..126 (tray 11; the `%c` and `%s` stores both go through `store_chars_in_array`); `memcmp` with a size beyond OCaml's
63-bit `int` (tray 13; `memcmp` is a memop in libc mode and through std.core's `memcmp_proxy` in nolibc mode). A grep over
every gated corpus (`tests/{ci,csmith,minimal,coverage,debug,float,bytes,libc_exec,pnvi_testsuite,pnvi_refusals,multi_tu,
multi_tu_tray,cn,verify,immaculate,macro_type_ranks,stdio_exit,address_space}`, `lean_frontend/corpus`, `lean_frontend/tests`;
derived 2026-11-07): `\?` occurs only in the two immaculate nolibc pins; the `snprintf` family only in `tests/libc_exec/006,
007, 025-028, exhaustive/001` (every stored byte printable: `v=%d s=%s`, `%-4d|%05.1f|%x|%s|%c` of `'z'`, …) and the three
immaculate libc R2 pins; `memcmp` in `tests/coverage/mem4/*`, `tests/coverage/libc/libc-010`, the pnvi litmus files,
`tests/libc_exec/016` and the immaculate pins — every size small except `s4b-memcmp-hugesize`. The csmith corpus (1669
programs: `printf`/`transparent_crc` through the kit shim) and `tests/ci` (253) carry none of the three. So at most the six
immaculate pins can move, and the lanes confirm it.

### 4.2 The table (both engines agree after on every row; pristine `c3ff8c53f` prints the before-lines)

| row | lanes | before (fork oracle = pristine) | after (fork oracle = Lean) | gcc 13 | disposition |
|---|---|---|---|---|---|
| `tests/immaculate/nolibc/g5-decode-question.c` | B5 (`ORACLE_CRASH` → `MATCH`), B10 (new difference) | uncaught `Failure("decode_character_constant, started like an octal constant, but failed: ?")`, rc 125 | `Specified(63)` | 63 | **the fix** (tray 10); register row; witnessed `nolibc_esc_char_q` |
| `tests/immaculate/nolibc/zd-e2-ptr-string-literals.c` | B5 (`ORACLE_CRASH` → `MATCH`), B10 | the same Failure from the string-literal arm | `Specified(0)`, `98 65 66 4 83 52 3 10 9 92 34 39 63 0 4` | the same line | **the fix** (tray 10, the string form); register row; witnessed `nolibc_esc_str_q`, `nolibc_esc_all_simple` |
| `tests/immaculate/libc/g5-escape-roundtrip.c` | B5 (`DIFF` → `MATCH`), B10 | `Specified(87)` | `Specified(127)` | 127 | **the fix** (tray 11); register row; witnessed `rt_snprintf_c_127` |
| `tests/immaculate/libc/zd-r2-highbyte.c` | B5 (`DIFF` → `MATCH`), B10 | `Specified(128)` | `Specified(200)` | 200 | **the fix** (tray 11); register row; witnessed `rt_snprintf_c_200` |
| `tests/immaculate/libc/zd-r2-crash-digit9.c` | B5 (`ORACLE_CRASH` → `MATCH`), B10 (the row's class `diagnostic-text` → `shared-model-fix`) | uncaught `Failure("… but failed: 199")`, rc 125 | `Specified(199)` | 199 | **the fix** (tray 11, the crash variant); witnessed `rt_snprintf_s_c7` |
| `tests/immaculate/libc/s4b-memcmp-hugesize.c` | B5 (`ORACLE_CRASH` → `MATCH`), B10 | uncaught `Z.Overflow`, rc 125 | `Undefined {ub: "UB_CERB002a_out_of_bound_load", stderr: "", loc: "<13:10--13:34>"}` | exit 1 (UB) | **the fix** (tray 13); register row; witnessed `ub_memcmp_hugesize` |

No other gated row moved: `test_libc_exec.sh` `SUMMARY: match=42 loc_only=2 diff=0`, `ALL MATCH RECORDED BASELINE`;
`test_pnvi.sh` `BASELINE OK (164 rows …)`; `test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage`
`0 regression(s), 0 improvement(s) / BASELINE OK`; the pristine lane `--corpus ci` `passed` (245 rows: 137 agreement, 104
matching failure, 4 `matching_incomplete` — both engines at the mirrored 30 s bound on a box shared with two other workers;
the LADDER row names two such files at its recording); the csmith corpus is a nolibc lane with none of the triggers (§4.1).
The immaculate baseline is hand-edited on the six rows (the status word only; the Lean tokens are unchanged) with a dated
note, as that file's precedents: the lane's recorder would drop its curated comments.

### 4.3 The manifest and the register

`scripts/fork_drift_manifest.txt` (§2.4): `check_fork_drift: OK — layer 1: 96 oracle-surface files = manifest …; layer 2: 33
differing generated files, all hash-pinned`, `SELFTEST OK (31 plants …)`, `check_pin_sites: OK`. The pristine-difference
register `scripts/upstream_oracle_differences.json`: 24 → 29 rows (`shared-model-fix` 17 → 23, `diagnostic-text` 2 → 1,
`address-layout` 5; derived from the committed register) — five new `shared-model-fix` rows (the
class of the allocator precedent, a fork-ahead fix of the hand-written OCaml oracle) for `g5-decode-question`,
`zd-e2-ptr-string-literals`, `g5-escape-roundtrip`, `zd-r2-highbyte`, `s4b-memcmp-hugesize`, each quoting pristine's crash
or wrong value verbatim and both full signatures from the lane's report; `zd-r2-crash-digit9` moved from `diagnostic-text`
(both engines crashed, one frame name apart) to `shared-model-fix` (the fork answers 199). Citations: the three tray drafts
and VALIDATION.md (the record joins them at M3, once tracked — the loader refuses an untracked citation).

## 5. Register entries

- **ISO-fix register** (VALIDATION §2): R1, R2, R3 RETIRED 2026-11-07 in the R6/R7 shape; the live register is R5 alone;
  the `-- ISO-fix register Rn (RETIRED 2026-11-07)` markers in `CerbDecode.lean`/`CerbMem.lean` are historical notes.
- **Named deviations** (§2b): unchanged (N4 covers the library-code `<unknown location>` rows of §3.2).
- **Failure-reach register:** no new row (238 = 238; no Lean failure site changed). **Fuel forms, fuel hypotheses,
  fuel-parametricity pins:** unchanged (a binder rename, §7, changes no statement).
- **Pins:** `tests/immaculate/baseline.txt` (six rows, §4.2); the libc dumps and `core-quote` digests untouched (the shipped
  library's sources are not involved); `tests/libc_exec`, `tests/pnvi_lane`, the coverage baseline unchanged.
- `CONTRACT.md` (D18, §4), `VALIDATION.md` (§2, the gate table), `SUPPORTED.md`, `scripts/LADDER.md` row 1, `TODO.md`,
  `lean_frontend/CLAUDE.md` (the `CerbDecode.lean` row), the trays 10/11/13 ("Sent; fixed in the fork", the patches), the
  INDEX rows, the two consumer notes.

## 6. Gates

### 6.1 M1 (`c9f4435bf`): the focused gates (verbatim, the M1 tree)

```text
dune build backend/driver/main.exe cerberus-lib.install: rc 0; dune install --prefix _build/local-install cerberus-lib: rc 0; dune build cerberus.install: rc 0   (the shell's exit codes, 2026-11-07)
check_handwritten_sync: OK (57 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
Build completed successfully (409 jobs).
lake build rc=0
OK                                                                         (test_stops.py)
check_fork_drift: OK — layer 1: 96 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 33 differing generated files, all hash-pinned (merge-base c3ff8c53f05982745f9b3a10b3d05442e214bcb5; lem-pin e6d8db5680962f49060257d6c2bcb13c284b910f matches lem -v lean-backend-v0.1.0-alpha.1-78-ge6d8db5 (hex prefix))
check_fork_drift: SELFTEST OK (31 plants with declared verdict/message: S1-S10 prerequisite/locale/name controls; S31 advanced upstream ref (not drift); S11 copied-content control; S12 inside-listed-file drift; S13/S14 duplicate/missing content pins; S15-S30 version forms, full-pin validation and refresh retention; unplanted gate green)
check_pin_sites: OK — lem-pin e6d8db5680962f49060257d6c2bcb13c284b910f at every site (lakefile rev, 3 lake-manifests rev+inputRev, README pin command)
check_failure_reach: OK (238 pure failure sites = the 238 register rows exactly (236 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, shared keys lengthened, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=175 REACHABLE=42 UNKNOWN=21; every row sealed; tally line consistent)
check_failure_reach: SELFTEST OK (8 plants with the declared message — a new site in a generated exec-closure definition, a DISCARDABLE dead let-binding, an unsealed class edit, a phantom row, an edited tally, mis-shaped lem_if heads over a registered arm, a mis-shaped lemSeq continuation, a same-owner reach+seal swap (A3) — 7 classifier witnesses (lem_if arms/condition, lemSeq continuation, controls), the key-group 
```

### 6.2 M2: the lanes (verbatim last lines, the M1 tree with the baselines of `1e5f2cbca`)

```text
DEVIATION: g5-escape-roundtrip expected [DIFF | L=VAL:{value: "Specified(127)", stdout: "", stderr: "", blocked: "false"}] got [MATCH | L=VAL:{value: "Specified(127)", stdout: "", stderr: "", blocked: "false"}]
DEVIATION: zd-e2-ptr-string-literals expected [ORACLE_CRASH | L=VAL:{value: "Specified(0)", stdout: "98 65 66 4 83 52 3 10 9 92 34 39 63 0 4\n", stderr: "", blocked: "false"}] got [MATCH | L=VAL:{value: "Specified(0)", stdout: "98 65 66 4 83 52 3 10 9 92 34 39 63 0 4\n", stderr: "", blocked: "false"}]
DEVIATION: s4b-memcmp-hugesize expected [ORACLE_CRASH | L=UB:{ub: "UB_CERB002a_out_of_bound_load", stderr: "", loc: "<13:10--13:34>"}] got [MATCH | L=UB:{ub: "UB_CERB002a_out_of_bound_load", stderr: "", loc: "<13:10--13:34>"}]
DEVIATION: zd-r2-crash-digit9 expected [ORACLE_CRASH | L=VAL:{value: "Specified(199)", stdout: "", stderr: "", blocked: "false"}] got [MATCH | L=VAL:{value: "Specified(199)", stdout: "", stderr: "", blocked: "false"}]
DEVIATION: g5-decode-question expected [ORACLE_CRASH | L=VAL:{value: "Specified(63)", stdout: "", stderr: "", blocked: "false"}] got [MATCH | L=VAL:{value: "Specified(63)", stdout: "", stderr: "", blocked: "false"}]
DEVIATION: zd-r2-highbyte expected [DIFF | L=VAL:{value: "Specified(200)", stdout: "", stderr: "", blocked: "false"}] got [MATCH | L=VAL:{value: "Specified(200)", stdout: "", stderr: "", blocked: "false"}]
SUMMARY: match=42 loc_only=2 diff=0
ALL MATCH RECORDED BASELINE
pnvi_lane: BASELINE OK (164 rows = the baseline, classes, oracle hashes and BOTH_FAIL/RESOURCE lean hashes exact)
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
Independent oracle: failed; {'semantic_agreement': 943, 'reviewed_difference': 23, 'matching_failure': 27, 'interface_agreement': 2, 'difference': 6}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-fix/half-mirrors-oracle/.tmp/lanes/pristine-tier-b.json/report.json
Independent oracle: passed; {'semantic_agreement': 137, 'matching_incomplete': 4, 'matching_failure': 104}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-fix/half-mirrors-oracle/.tmp/lanes/pristine-ci.json/report.json
```

(The immaculate lane's six DEVIATION lines are exactly the six pins of §4.2 flipping to `MATCH`; the pristine lane's six
`difference` rows are the same six programs, the register rows of §4.3 admit them.)

### 6.3 M2: the rebuilt tree (the binder renames of §7, the cite corrections, the register rows, the hand-edited baseline)

```text
check_handwritten_sync: OK (57 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
Build completed successfully (409 jobs).
lake build rc=0
trace warnings: 0
trace mtime: 2026-11-07 19:43:05.307068651 +0000
check_handwritten_sync: OK (57 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
check_theorem_axioms: FUEL arc leg OK (63 contract lemmas — generated _zero, runner leaves/parametricity, ∀-fuel exemplar, measured obligations, fail-stop propagation, and six-worker ND stability, every cone ⊆ [propext, Classical.choice, Quot.sound])
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
check_fuel_forms: OK (88 fuel'd workers: 67 MEASURED (obligation of the contract's shape incl. argument correspondence against the wrapper's body; every obligation + proof cone ⊆ the standard three; 13 of them under a hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions), 13 ABSORBING = kill at zero (the _zero lemma is the worker at literal 0 on its own binders = the monad's absorbing element, co
check_fuel_forms: SELFTEST OK (25 plants with the declared label — 6 on the table (incl. the ABSORBING-cone plant), 3 on the hypothesis register, 15 compiled decoys: the C4 four (type True / wrong worker / contradictory hypothesis caught by the register / extra binder), the whole-project audit's two decoys verbatim (review_bad _zero about runNDFuel; review_shift at literal 0), wrong fuel position, swapped worker-side
Independent oracle: passed; {'semantic_agreement': 943, 'reviewed_difference': 29, 'matching_failure': 27, 'interface_agreement': 2}; /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-fix/half-mirrors-oracle/.tmp/m2/pristine-tier-b.json/report.json
```

### 6.4 After the pre-merge review (`docs/2026-11-07_half-mirrors-oracle-premerge-review.md`, 8802f4a3c; dispositions in its last section)

The dispositions commit changes documents, script text, the register's citations and one header sentence of
`CerbDecode.lean`. Re-run on that tree, verbatim:

```text
OK: lane matches the committed baseline (MATCH except the ISO-fix register pin R5 r5-hex-subnormal-double-rounding DIFF — VALIDATION.md 'ISO-fix register'; the R1/R2/R3 pins g5-decode-question, zd-e2-ptr-string-literals, g5-escape-roundtrip, zd-r2-highbyte, zd-r2-crash-digit9, s4b-memcmp-hugesize are MATCH since 2026-11-07 (retired, trays 10/11/13 fixed in the fork) and the R7 pins zd-ta-alignas-huge-{sizeof,union-alignof,desugar} MATCH since 2026-10-30 (retired) — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).   (test_immaculate.sh, rc 0)
check_handwritten_sync: OK (57 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
lake build rc=0
lake build rc=0
check_handwritten_sync: OK (57 hand-written files byte-identical to lean_frontend/generated/; manifest lean_frontend/handwritten_copy.manifest)
check_failure_reach: OK (238 pure failure sites = the 238 register rows exactly (236 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, shared keys lengthened, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=175 REACHABLE=42 UNKNOWN=21; every row sealed; tally line consistent)
```

The orchestrator's full battery on this branch's tip `ce5d7b564` (2026-11-08; run by the orchestrator in a separate audit
checkout after a forced regeneration — `make clean-prelude-src prelude-src lean-prelude-src`, the three dune steps and the
capped lake build; evidence directory `.tmp/release/` under that checkout, ephemeral), verbatim last lines:

```text
full: passed; 45/45 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
release rc=0
```

## 7. The two `CerbMem.lean` unused-binder warnings (scope added at M2)

[USER 2026-10-27] standing ruling, relayed by the orchestrator at M2: the next slice that touches `CerbMem.lean` fixes its two
hand-written linter warnings — the only ones in the tree — the proper way, never with a linter option. They were
`Variable name `tagDefs` is not explicitly referenced` at `CerbMem.lean:1498:50` (`offsetofIval`'s signature) and `Variable
name `onConcurRead` is not explicitly referenced` at `:1655:28` (`caseMemValue`'s callback), both the `unusedVariables` linter
(2 matches of `not explicitly referenced` in `.lake/build/lib/lean/CerbMem.trace` on the M1 tree). [AGENT 2026-11-07] the
form: both functions are lem `target_rep`s whose arity the lem side fixes (`mem.lem:317` `offsetof_ival`, `:450`
`case_mem_value`), so neither binder can be removed; each takes the leading-underscore form keeping the OCaml-mirroring name —
`_tagDefs` (the threaded tag map `tagDefsMap` is what the body reads; the `TagDefs` value is the lem-side argument the
layout family carries), `_onConcurRead` (the OCaml `case_mem_value`'s never-called `f_concur` callback, the existing comment
extended with the arity note). A binder rename changes no statement: the fuel-forms gate and the axiom census are re-run
after the rebuild and quoted in §6; the trace of the rebuilt module has no `not explicitly referenced` match. The same
rebuild carries the cite corrections of M1's comments (`decode.ml:155-163`, `:229-255`; `impl_mem.ml:2574-2602`, memcpy
`:2561-2570`; pristine's `:2481-2482`).

## 8. Not done / open

- Universal character names stay a crash on both engines (§0, §3.3 row 4): the declared refusal is owed by the
  crash-to-refusal item (TODO), which now names the UCN shape beside tray 63's; pinned here as gap controls so a change is
  loud. A reviewer who prefers the refusal in this slice should know it is a Lean stop site (a new `failwithI` envelope, a
  failure-reach row, a `CerbStopSites` id) mirrored by an attributed OCaml `failwith` — a small slice, not a comment.
- `'\0123'` (§3.3 row 6) and the out-of-range escapes (row 7) are declared rows, not fixes: the first is tray 63's class
  (an implementation-defined value the crash-to-refusal slice should refuse with the other multi-character shapes), the
  second a front-end diagnostic gap (a constraint violation accepted as gcc `-w` accepts it) that is a judgement call
  under the standing bar and is left to a filing of its own if the operator wants one.
- The library-code siblings (§3.3 rows 11, 12) are trays 30 and 31, unchanged; `memmove(NULL, b, 1)`'s fork≠pristine
  difference (row 13) is D14's and sits in no gated corpus, so no register row exists for it.
- The `Z.pow n1 (Z.to_int n2)` exponent at `impl_mem.ml:2374` (§2.3) is the one remaining `Z.to_int` of a C-controlled
  quantity in the file outside the retired R7 class; not this slice's mechanism, not measured, noted for the audit's
  "`Z.to_int` family" item (tray 13's remedy section).
- The csmith corpus was bounded by the trigger census (§4.1), not re-run: its lane is nolibc and carries none of the three
  triggers; the ci corpus was re-run on the pristine lane (passed).
- The orchestrator's Tier A on M1 and the full battery on M3 are theirs; the M1 tree's gates and the M2 lanes are this
  record's.

## 9. Scratch, deleted at close-out

`.tmp/m1/` (the reproducers, the libc metadata TUs), `.tmp/vic/` (the vicinity generator, runner, rows and outputs, the pin
instrument), `.tmp/patches/` (the three patches, carried into the tray drafts), `.tmp/lanes/`, `.tmp/m2/` and the `.tmp/m1-*`,
`.tmp/m2-*` logs (every quoted line is in §6), `.tmp/scripts/` (the witness's working directories).
