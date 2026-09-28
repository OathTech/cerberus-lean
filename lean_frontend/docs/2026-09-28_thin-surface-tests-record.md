# Thin-surface tests — record (2026-09-28)

[AGENT — test-writing worker, Claude subagent, 2026-09-28]. Branch `tests/thin-surfaces-20260928`, cut from
`arc/contract-enforcement` @ `f2efd8a9e`. No push, no merge. No change to `lean_frontend/*.lean`, the generated tree,
or `CONTRACT.md`. The only harness changes are the exhaustive libc-mode rows (§5).

**Why.** [USER 2026-09-28], verbatim: "Yes, definitely agree rolling in more tests, and sending off an agent to build
more would be great if it meaningfully increases coverage of edge cases". The target list is CONTRACT §3.2's thinly
tested parts, measured in `docs/2026-09-28_test-depth-map.md`.

**Rule applied.** Only programs on which Lean and the oracle agree became lane rows. Every disagreement, and every
case where Lean refuses and the oracle answers, is kept out of the lanes and quoted in §3. Where both engines agree on
behaviour that ISO C does not allow, the row pins the observed agreement and the test comment says so. Those cases are
listed in §4 as shared-model observations. They are not Lean-vs-oracle discrepancies.

## 1. What was added (per surface)

| Surface (CONTRACT §3.2) | Lane / files | Programs |
|---|---|---|
| `printf("%f")` (`CerbFloat.formatFixed`) | `tests/coverage/fmt/fmt-001…015` (exhaustive, nolibc) | 14: default precision (`001`), exact binary ties and near-ties (`002`), `%.0f`, `#`, carry into a new digit (`003`), precision 17–60 exact expansion (`004`), real negative zeros from `*` and underflow, with `+`/` ` flags (`005`), `inf`/`-inf` with width/flags (`006`), subnormals with `%.330f`/`%.320f` (`008`), DBL_MAX, 1e23, 2^53+1 (`009`), width + `-0+ ` flags (`010`), float arguments (`011`), `%hhf` UB158 (`012`), `%f` of an int UB153b (`013`), `%e` and `%g` are `Invalid_format` in the model (`014`, `015`) |
| printf width, precision, flags, `%c`, `%x`/`%X`/`%o`, length modifiers, `%%`, `%s` | `tests/coverage/fmt/fmt-020…043` | 21: `%d` width/flags (`020`), precision (`021`), `%x %X %o` with `#`/`0`/precision (`022`), integer limits with `l`/`ll` (`023`), `hh`/`h`/`z`/`t` (`024`), `%%` and `%c` of 127/200/-1/321/0 (`025`), `%s` width/precision (`026`), `%.Ns` of an array with no NUL (`027`, served-surface `p2_printf_s_nonul` verbatim), `%.4s` and `%s` reading past the object (`028`, `029`, UB), the return value (`030`), `%p` of NULL/object/one-past (`031`), the model's flag checks (`032`–`035`), type checks (`036`, `037`, `043` `%jd` of `intmax_t`), too few arguments (`040`), unsigned values with precision (`042`) |
| same, not served by either engine | `tests/immaculate/nolibc/ts-fmt-{star-width,star-precision,s-null}` | 3 both-crash pins (`MATCH \| L=CRASH`): `*` width, `*` precision, `%s` of NULL |
| `realloc` | `tests/coverage/mem4/mem4-001…010` | 10: grow with every byte preserved (`001`), shrink (`002`), the old tail after a shrink is out of bounds (`003`), `realloc(NULL,n)` (`004`), `realloc(p,0)` (`005`), the old pointer is dead (`006`), realloc of pointers keeps provenance (`007`), the grown tail is unspecified (`008`), freeing the old pointer is a double free (`009`), a doubling loop (`010`); plus `tests/libc_exec/038-realloc-libc-mode` (libc mode) |
| `memcpy` | `tests/coverage/mem4/mem4-020…027` | 8: overlapping ranges (`020`), a struct of pointers (`021`), 3 bytes of an int (`022`), length 0 (`023`), half a pointer's bytes (`024`, two executions), a pointer rebuilt from a byte buffer (`025`), reading past the source (`026`, UB), an uninitialised source (`027`) |
| `memcmp` | `tests/coverage/mem4/mem4-030…034`; `tests/immaculate/nolibc/ts-memcmp-struct-padding` | 5 value/UB rows: sign with bytes ≥ 0x80 and plain `char` -1 (`030`), the returned value (`031`), length 0 and a prefix (`032`), pointer representations (`033`), reading past an object (`034`); plus 1 both-crash pin (padding bytes never written) |
| `free` | `tests/coverage/mem4/mem4-040…043` | 4: `free(NULL)` repeated (`040`), comparing a freed pointer (`041`), freeing a string literal (`042`) and a global (`043`) (UB179a) |
| `memset` | `tests/libc_exec/036-memset-edge` (+ `013`, `026`, `027` use it) | the value is converted to `unsigned char` (0x1ff → 255, -2 → 254), length 0, the return value |
| `snprintf`/`vsnprintf`, `sprintf` | `tests/libc_exec/025-sprintf`, `026-snprintf-truncation` (`p2_snprintf` verbatim), `027-snprintf-exact-fit`, `028-vsnprintf-wrapper-truncation` | 4 |
| `errno` | `tests/libc_exec/019-strtol-erange` (ERANGE both directions), `029-errno-basic` (`p2_errno_basic` verbatim), `exhaustive/002-errno-basic` | 3 |
| `exit` codes | `tests/libc_exec/030-exit-negative` (`p2_exit_codes` verbatim), `031-exit-256` (`p2_exit_256` verbatim) | 2 (`atexit`: not added — Lean refuses, §3 D2) |
| libc breadth | `tests/libc_exec/013…039` | 27 single-trace programs (the rows above plus): `strcpy/strncpy/strcat/strncat` (`013`), `strcmp/strncmp` (`014`), `strchr/strrchr/strstr` up to four-byte needles/`strpbrk/strspn/strcspn` (`015`), `strstr` two-way path (`016`, UB in both), `memmove/memchr` (`017`), `strtol/strtoul` bases and end pointers (`018`), `atoi/atol/atoll` (`020`), `qsort` (`021`), `qsort`+`bsearch` on structs (`022`), `abs/labs/llabs/div/ldiv` (`023`), all 12 `ctype.h` classifiers + `toupper/tolower` over -1…255 (`024`), `strdup` (`032`), `srand/rand` (`033`), `puts/putchar/fputs/fputc/fwrite` and `fputs(stderr)` (`034`), `getenv` (`035`), `calloc` (`037`), `strerror` (`039`, both stop at an `assert`) |
| libc mode compared exhaustively | `tests/libc_exec/exhaustive/001-unseq-order-libc` (80 executions, two outcomes), `exhaustive/002-errno-basic` (5 executions) | 2, with the new harness mode (§5) |
| programs of several TUs | `tests/multi_tu/{funptr-cross,extern-array,static-shadows-extern,addr-const-init-unresolved,tentative-both,extern-const-struct}` | 6: a table of function pointers (one to a static function) called from another TU, and a static callback passed across (`funptr-cross`); `extern int arr[]` / `extern char msg[]` read and written across TUs (`extern-array`); a TU's static `f`/`g` beside another TU's external `f`/`g` (`static-shadows-extern`); two tentative definitions in one TU and none initialised anywhere (`tentative-both`); const struct with a pointer member and const array (`extern-const-struct`); static pointers initialised with another TU's addresses (`addr-const-init-unresolved`, both engines stop, §4) |
| argv, non-ASCII | none (probe only, §3 D6) | the immaculate lane hard-codes `--args "ab cd"`; a per-row argument string would be a harness change outside this slice |

Total: 101 new lane programs (35 fmt + 27 mem4 in `tests/coverage`, 4 immaculate, 27 + 2 libc_exec, 6 multi_tu).

## 2. Before and after, per CONTRACT §3.2 row

Measured by the depth map's census script (§A.5 of `docs/2026-09-28_test-depth-map.md`, run verbatim) on the tree
of `f2efd8a9e` ("before") and on this branch's working tree before the commits ("after"); each tree was extracted
under `.tmp/` and the script run from its root. Two extra patterns were added to a copy of the script, marked "(x)"
below. They are the width/precision/flag regex
``"[^"\n]*%(?=[-+ #0]|[1-9]|\.)[-+ #0]*[0-9]*(\.[0-9]*)?(hh|h|ll|l|z|j|t)?[diouxXfcsp]`` and
`\bexit\s*\(`. "d" = derived. The census globs `tests/libc_exec/*.c` only, so it does not see the two exhaustive rows.
They are added by hand where noted (d).

| Part | Before | After | Note |
|---|---|---|---|
| libc breadth: libc functions called directly by libc-mode agreement programs | 11 of 188 | **61** of 188 | measured |
| libc-mode agreement programs | 32 (all `--first`) | 59 `--first` (measured) + 2 exhaustive (d) = 61 | first exhaustive libc-mode rows |
| `printf("%f")` | 0 | **13** (d) | census `f` conversions in agreement rows: 14, less the known `uri` false positive (depth map §A.3); 12 in `coverage/fmt`, 1 in `libc_exec/025` |
| printf width/precision/flags (x) | 1, the `uri` false positive, so 0 | 23, so **22** (d) | 21 `coverage/fmt`, 1 `libc_exec/025` |
| `%c` / `%x` / `%X` / `%o` (conversions in agreement rows) | 0 / 1 (via `PRIxPTR`; census 0) / 0 / 0 | **6 / 8 / 2 / 3** | measured (census conversion table) |
| length modifiers `hh`/`h`/`z`/`t`/`j` | 0 each | 2 / 2 / 1 / 1 / 1 (`j` is the UB153b row) | measured |
| `realloc` | 4 | **16** | measured (13 coverage, 2 immaculate, 1 libc_exec) |
| `memcpy`/`memmove` | 5 | **15** | measured |
| `memcmp` | 2 (1 value row) | **7** (6 value/UB rows in coverage) | measured, and 1 more both-crash pin (not counted as agreement) |
| `memset` | 1 | **5** | measured |
| `snprintf`/`sprintf`/`vsnprintf` | 2 | **6** | measured |
| `errno` | 1 | 4 (measured) + 1 exhaustive (d) = **5** | |
| `exit` calls (x) | 1 | **3** | `atexit` stays 0: every `atexit` program is now refused on Lean (§3 D2) |
| `getenv` | 0 | **1** | measured |
| strto*/ato* | 1 | **4** | measured |
| argv | 5 | 5 | UTF-8 probe run, not added (§3 D6) |
| programs of several TUs (user) | 8 | **14** | `multi_tu` 2 → 8 (measured) |
| default-mode atomics / par | 1 | 1 | out of this slice's priority list |
| gating agreement programs, total | 872 | 967 (measured) + 2 exhaustive libc (d) = **969** | nolibc-exh 795 → 863, libc-first 32 → 59 |

Both-crash pins (`MATCH | L=CRASH`) are counted as `MATCH_BOTHCRASH` by the census, not as agreement: immaculate
12 → 16.

## 3. Disagreements found (NOT pinned; for the orchestrator)

Each was run as: oracle `main.exe --runtime=_build/install/default [--nolibc] --exec --batch [--mode=exhaustive] F.c`;
Lean `cerberus-lean --batch [--first] F.json [--libc tests/libc/libc.core --libc-tu <12 jsons>]` under
`LEAN_ABORT_ON_PANIC=1` and `scripts/capped` (8G), from the worktree root, on the binaries of `f2efd8a9e`. Exit codes
are the processes' own. Outputs are verbatim.

### D1 — `printf("%f")` of a NaN: the oracle prints `-nan`, Lean prints `nan` (nolibc, exhaustive)

```c
// fmt-007: NaN under %f. inf - inf is an IEEE invalid operation producing a
// NaN; its printed text (and sign) is observable.
#include <stdio.h>
int main(void) {
  double inf = 1e309;
  double n = inf - inf;
  return printf("[%f|%.2f|%5f]\n", n, n, n);
}
```
oracle (exit 0): `Defined {value: "Specified(18)", stdout: "[-nan|-nan| -nan]\n", stderr: "", blocked: "false"}`
Lean (exit 0): `Defined {value: "Specified(16)", stdout: "[nan|nan|  nan]\n", stderr: "", blocked: "false"}`

The same with `double n = -(inf - inf);` (fmt-007b):
oracle (exit 0): `Defined {value: "Specified(7)", stdout: "[-nan]\n", stderr: "", blocked: "false"}`
Lean (exit 0): `Defined {value: "Specified(6)", stdout: "[nan]\n", stderr: "", blocked: "false"}`

The value (the number of characters printed) differs as well as the output. `CerbFloat.formatFixed`'s docstring
already describes this as a deliberate divergence ("a negative NaN's '-nan' is not reproduced … unobservable in the
corpora"). The claim that it cannot be observed is wrong: the NaN from `inf - inf` is negative on this machine. The
unary minus in 007b leaves the oracle's output at `-nan`. That fits the model negating as `0 - x` (§4 O6), but I
inferred this and did not trace it in code.

### D2 — every `atexit` call is now refused on Lean in libc mode (the function-pointer-to-integer refusal)

The runtime libc's `atexit` is `return __cxa_atexit(call, (void *)(uintptr_t)func, 0);`
(`runtime/libc/src/stdlib.c:197-200`). The cast `(uintptr_t)func` converts a function pointer to an integer. That
conversion is now REFUSED (`45a53c421`). The served-surface probe `p2_exit_atexit` agreed before that commit; re-run
now:

```c
#include <stdio.h>
#include <stdlib.h>
void bye(void) { printf("bye\n"); }
int main(void) { atexit(bye); printf("main\n"); exit(7); }
```
oracle (exit 0): `Defined {value: "Specified(7)", stdout: "main\nbye\n", stderr: "", blocked: "false"}`
Lean `--first` (exit 1): `ModelFailure {msg: "cerberus-lean: refused \226\128\148 converting a function pointer to an integer is not supported: the number is the function symbol's fresh-supply number (impl_mem.ml:2487-2488), which this port does not reproduce (CONTRACT.md, served-surface audit P1-1)"}`

The same refusal (identical Lean line, exit 1) for the slice's two `atexit` programs. Their oracle outputs (exit 0):
- `032-atexit-order` (handlers h1, h2, h3, h1 registered, then `exit(7)`): `Defined {value: "Specified(7)", stdout: "main\nh1\nh3\nh2\nh1\n", stderr: "", blocked: "false"}`
- `033-atexit-main-return` (one handler, then `return 9` from main): `Defined {value: "Specified(9)", stdout: "main\n", stderr: "", blocked: "false"}`. Here the oracle does not run the handler when main returns; ISO 7.22.4.4 says returning from main calls `exit`, which would run it.

This is a refusal where the oracle answers (class (c) by the contract's wording), and it covers a whole libc function.
The funptr-refusal record's blast-radius measurement did not see it, because no lane program called `atexit`. The
integer is only carried through `void *` and back, never inspected.

### D3 — `strtok`: both engines report an unknown procedure; the Error text differs in the symbol number

```c
#include <stdio.h>
#include <string.h>
int main(void) {
  char s[] = ",a,,bc;d;;,";
  int n = 0;
  for (char *t = strtok(s, ",;"); t; t = strtok(NULL, ",;")) n += printf("[%s]", t);
  return n + printf("\n");
}
```
oracle (exit 1): ``Error {msg: "ill-formed program: `calling an unknown procedure: Symbol(707, SD_Id("strtok"))'"}``
Lean `--first` (exit 1): ``Error {msg: "ill-formed program: `calling an unknown procedure: Symbol(37686, SD_Id("strtok"))'"}``

`strtok` is defined in `runtime/libc/src/string.c` but neither engine can call it. The symbol number in the message
differs, the known symbol-supply offset (N1 family). The immaculate and libc_exec lanes compare the full token, so
this would be a DIFF row.

### D4 — `strtod` of a finite decimal: unknown procedure `scalbn`; symbol numbers differ

```c
#include <stdio.h>
#include <stdlib.h>
int main(void) {
  char *e;
  double a = strtod(" -1.5e3xyz", &e);
  double b = strtod("0.125", 0), c = strtod("+.5", 0), d = strtod("abc", 0);
  return printf("%f %s %f %f %f\n", a, e, b, c, d);
}
```
oracle (exit 1): ``Error {msg: "ill-formed program: `calling an unknown procedure: Symbol(23251, SD_Id("scalbn"))'"}``
Lean `--first` (exit 1): ``Error {msg: "ill-formed program: `calling an unknown procedure: Symbol(22822, SD_Id("scalbn"))'"}``

So `strtod` of a finite decimal is served by neither engine. Only the `inf` literal row (`zd-z2cp01-strtod-inf`) works.

### D5 — `calloc` with an overflowing size: oracle still running at 300 s, Lean aborts on a stack overflow

```c
#include <stdint.h>
#include <stdlib.h>
int main(void) { void *big = calloc(SIZE_MAX / 2, 4); return big == NULL; }
```
oracle `--exec --batch` (libc), `timeout 300`: exit 124, no stdout, no stderr.
Lean `--batch --first` (libc), `timeout 300`: exit 134; stderr `Stack overflow detected. Aborting.` then
`timeout: the monitored command dumped core`. The whole probe took `6:02.95 total` (≈ 300 s oracle + ≈ 63 s Lean,
derived).

The runtime libc's `calloc` (`stdlib.c:125-134`) does not check for overflow: it mallocs `nmemb*size` (wrapped) and
zeroes it byte by byte. Neither engine finishes. Under the resource-limit direction rule this may be admissible, but
the rule is the orchestrator's to apply.

### D6 — non-ASCII `--args`: both engines stop; the failure texts differ (bytes vs code points)

The probe is not a lane row. The immaculate lane's argv section always passes `--args "ab cd"`.

```c
int main(int argc, char *argv[]) {
  unsigned s = 0, n = 0;
  for (int i = 1; i < argc; i++)
    for (int j = 0; argv[i][j]; j++) { s = s * 31u + (unsigned char)argv[i][j]; n++; }
  return (int)((s % 1000u) * 100u + n);
}
```
`--args "ab cd"` (control): both `Defined {value: "Specified(7404)", stdout: "", stderr: "", blocked: "false"}`, exit 0.
`--args "é ü"`: oracle exit 125, `Failure("decode_character_constant: invalid char constant ==> \188")`
(`prepare_main_args` → `Decode.decode_character_constant`); Lean exit 134,
`PANIC at _private.LemLib.0.failwithIImpl LemLib:213:2: decode_character_constant: invalid char constant ==> é (decode.ml:199-200)`.
`--args "日本 €x"`: oracle `… ==> \172`, Lean `… ==> 日`. `--args $'a\xffb'`: oracle `… ==> \255`, Lean `… ==> �`
(U+FFFD: the invalid byte was replaced before the semantics saw it).

Neither engine serves non-ASCII argv. Both fail-stop at the same decoder. The failure class matches; the text does
not. The oracle reports a byte, Lean a Unicode scalar, and Lean has already lost an invalid byte. This answers the depth
map's open item "UTF-8 `--args` behaviour on both engines". A pin needs a per-row `--args` string in
`test_immaculate.sh`, or a refusal on the Lean side.

## 4. Shared-model observations (both engines agree; ISO C disagrees)

These are pinned as observed where a row exists. None is a Lean-vs-oracle discrepancy.

- O1 `%0Nf` and `%0Nd`: the zero padding goes BEFORE the sign (`%012f` of -3.25 → `000-3.250000`; `%05d` of -42 →
  `00-42`; ISO/glibc `-00003.250000`, `-0042`) (`fmt-010`, `fmt-020`; formatted.lem `justify`).
- O2 `#` on `%f` is ignored (`%#.0f` of 3.0 → `3`, glibc `3.`) (`fmt-003`; formatted.lem `expand` "not doing the
  right thing").
- O3 `%jd` of an `intmax_t` is UB153b (`fmt-043`).
- O4 `snprintf`/`vsnprintf` return the number of characters STORED, not the untruncated length
  (`snprintf(buf,4,"%d",123456)` → 3, `snprintf(NULL,0,…)` → 0) (`026`, `027`, `028`; formatted.lem `vsnprintf`).
- O5 `%e`, `%g` (and `%a`, `%F`, `%Lf`, per the served-surface audit) are `Invalid_format`. The UB payload embeds
  the format text unescaped, so a format containing a newline prints a batch record that spans lines. The shared
  codec then rejects both engines' output (`OBSERVATION ERROR: unknown or malformed stdout record: b'Undefined {ub:
  "Invalid_format[[%e]'`, `HARNESS ERROR: … no tokens extracted`). `fmt-014` therefore has no newline in its format.
- O6 unary minus does not produce `-0.0` (`-0.0` and `-z` print `0.000000`; `0.0 * -1.0` prints `-0.000000`)
  (`fmt-005`).
- O7 `memcpy` with overlapping ranges is not reported (ISO 7.24.2.1#2 UB); it copies forward, byte by byte
  (`mem4-020`: `11111`).
- O8 reading a freed pointer's value (`q == p` after `free(p)`) is not UB in the model (`mem4-041`).
- O9 `realloc(p, 0)` returns a non-null pointer (`mem4-005`), which is implementation-defined.
- O10 cross-TU function identity: `table[1] == inc`, where `table` is initialised with `inc` in TU 1 and compared in TU
  2, evaluates to 0 in both engines (ISO 6.5.9#6 requires 1). It was deliberately left out of `funptr-cross`'s result,
  so no row pins it.
- O11 a static initializer naming another TU's object (`extern int target; int *pt = &target;`) stops both engines
  with `Error {msg: "unresolved symbol: target at unknown location"}` (`multi_tu/addr-const-init-unresolved`).
- O12 `strstr` with a needle of ≥ 5 bytes (musl two-way) reads past the haystack: `UB_CERB002a_out_of_bound_load` in
  both (`016`).
- O13 `strerror` stops on an `assert` (`039`). `strtok` and finite `strtod` are unknown procedures (D3, D4).
- O14 memcmp over never-written padding: both fail-stop (the oracle's `assert false` in `impl_mem.ml` memcmp and
  Lean's mirror), rather than reporting UB (`ts-memcmp-struct-padding`).
- O15 `%s` of NULL, `*` width and `*` precision fail-stop in both (`ts-fmt-*`).

## 5. Exhaustive libc-mode comparison — the answer

**Question.** Can any lane compare a libc-mode program exhaustively? Before this slice, no. `test_libc_exec.sh`,
`test_immaculate.sh` (libc), `test_libxml2*.sh` and the gcc csmith tier all run Lean `--first` against a default-mode
(random) oracle.

**Nothing in either engine blocked it.** Both engines already run libc mode exhaustively: oracle
`--exec --batch --mode=exhaustive`, Lean `--batch --libc … --libc-tu …` without `--first`. The codec's `tokens` already
parses multi-execution framing. The served-surface audit's libc probes were run that way.

**Added (small, fail-closed, plant-tested).** `scripts/test_libc_exec.sh` gains `tests/libc_exec/exhaustive/*.c`:
- Each file runs with the oracle at `--mode=exhaustive` and Lean without `--first`. The full ordered token sequences
  are compared. Baseline rows are named `exhaustive/<name>`.
- An existing but empty `exhaustive/` directory fails the lane.
- Every exhaustive row carries a non-vacuity plant, run on every pass: (a) the oracle's exhaustive observation must
  hold at least 2 executions, and (b) a Lean `--first` run of the same program must not compare equal to it. A row
  failing either is `VACUOUS`, never `MATCH`.
- `scripts/test_upstream_oracle.py` (the pristine gate, Tier B row 10) mirrors the new flags for these paths. It had
  been walking `tests/libc_exec` recursively with default-mode flags, and a default-mode run of a multi-execution row
  is not a function of the program.

Rows: `exhaustive/001-unseq-order-libc` (80 executions, outcomes `Specified(31)`/`Specified(32)`; the single-trace
lane cannot pin it: Lean `--first` gives `Specified(31)`, one random oracle run gave `Specified(32)`), and
`exhaustive/002-errno-basic` (5 executions).

Plants (scratch copies of the lane restricted to the exhaustive rows, deleted before commit; each doctors one thing).
Every one turns the lane red:

| Plant | Doctoring | Result (verbatim status lines) |
|---|---|---|
| P1 | oracle without `--mode=exhaustive` | `DIFF  exhaustive/001-unseq-order-libc:` / `DIFF  exhaustive/002-errno-basic:`; `SUMMARY: match=0 diff=2`, rc 1 |
| P2 | oracle default mode AND Lean `--first` | `DIFF  exhaustive/001-unseq-order-libc:` / `VACUOUS exhaustive/002-errno-basic: oracle exhaustive observation has 1 execution(s) (< 2)`; rc 1 |
| P3 | the plant's Lean run without `--first` | `VACUOUS exhaustive/001-unseq-order-libc: the Lean --first observation equals the exhaustive one` / `VACUOUS exhaustive/002-errno-basic: the Lean --first observation equals the exhaustive one`; rc 1 |
| P4 | `EXH_DIR` pointed at an empty directory | `FAIL: empty exhaustive corpus: …/.tmp/thin/plant/emptydir`; rc 1 |

Cost: the whole libc_exec lane (41 rows including the plants) took `1:31.82 total`. Programs whose libc calls fan out
are expensive exhaustively (the served-surface `p2_errno_strtol` has 8192 executions, and `p2_errno` timed out at
300 s on both sides). Exhaustive rows should keep the non-determinism in user code, as `001` does.

Not done: `test_immaculate.sh`'s libc section and the libxml2 lanes stay `--first`. LADDER row 5's description does
not yet mention the exhaustive rows.

## 6. Lane verdicts (verbatim)

All lanes ran on this branch's working tree (the committed content) with `scripts/ce`, one at a time. No lane run
approached the hour tripwire.

- Tier A row 3, `./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage`, rc 0:
  ```
  SUMMARY: total=274 match=223 ub_match=37 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0
  Baseline check: 0 regression(s), 0 improvement(s)
  BASELINE OK
  ```
- Tier B row 5, `./scripts/test_immaculate.sh`, rc 0 (the four new rows: `MATCH ts-fmt-s-null O[CRASH] L[CRASH]`,
  `MATCH ts-fmt-star-precision O[CRASH] L[CRASH]`, `MATCH ts-fmt-star-width O[CRASH] L[CRASH]`,
  `MATCH ts-memcmp-struct-padding O[CRASH] L[CRASH]`):
  ```
  OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH, R5 r5-hex-subnormal-double-rounding DIFF — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
  ```
- Tier A row 5, `./scripts/test_libc_exec.sh`, rc 0:
  ```
    PLANT exhaustive/001-unseq-order-libc: exhaustive 80 verdicts; Lean --first 1 verdict(s) — differs, as required
    PLANT exhaustive/002-errno-basic: exhaustive 5 verdicts; Lean --first 1 verdict(s) — differs, as required
  SUMMARY: match=41 diff=0
  ALL MATCH RECORDED BASELINE
  ```
- Tier A row 6, `./scripts/test_multi_tu.sh`, rc 0:
  ```
  SUMMARY: total=8 match=8 fail=0
  ALL PASSED
  ```
- Tier B row 10, `python3 scripts/test_upstream_oracle.py`, rc 0. It walks every new row; the new nolibc/libc/multi-TU
  rows are `semantic_agreement` and the four `ts-*` rows are `matching_failure`. The register is unchanged.
  ```
  Independent oracle scope: tier-b; 983 rows in 172.2s; source unchanged: True
  Independent oracle: passed; {'semantic_agreement': 941, 'matching_failure': 33, 'reviewed_difference': 7, 'interface_agreement': 2}; …/report.json
  ```
  and `python3 scripts/test_upstream_oracle.py --plant`, rc 0:
  ```
  Independent oracle scope: plant; 53 rows in 1.6s; source unchanged: True
  Independent oracle: plants_passed; {'semantic_agreement': 1, 'plant_rejected': 1, 'plant_ok': 51}; …/report.json
  ```

Not run: the rest of the ladder (unit/row-1 gates, Tier C). No semantics, generated or Lean code changed.

## 7. Baseline edits

All by hand, minimal insertions, never `--record-baseline`/`--write-baseline`:
- `scripts/exec_coverage_baseline.txt`: 62 rows inserted in sorted position, and a dated `#` note just before
  `fmt-001`.
- `tests/immaculate/baseline.txt`: 4 rows after the `tray44-*` rows, and a dated `#` note after the last header note.
- `tests/libc_exec/baseline.txt`: 29 rows appended in the lane's run order (27 top-level, then the 2
  `exhaustive/`). This file cannot carry a `#` note: the lane compares it with `diff -u` against a regenerated
  status list that has no comments. The note is this record and the commit message.
- `tests/multi_tu` has no baseline (every directory must pass).

Scratch (`.tmp/thin/`, the plant copies, the observation and pristine-report directories of these runs) was deleted
before the commit. Other files already in `.tmp/` were not touched.

## Orchestrator addendum: dispositions (2026-09-28)

Lanes re-verified independently on `7a25d679e` before acting (immaculate "OK: lane matches the committed baseline";
coverage "Baseline check: 0 regression(s), 0 improvement(s)"; libc_exec "ALL MATCH RECORDED BASELINE"; multi-TU
"ALL PASSED").

- **D1 (`%f` of a NaN).** Mirroring was attempted and is impossible in Lean: `Float.toBits` canonicalizes every NaN
  to `0x7ff8000000000000` (measured: `(Float.ofBits 0xfff8000000000000).toBits = 9221120237041090560`), so the sign
  bit that decides "-nan" vs "nan" cannot be read. Since it can be refused cheaply and precisely, it is REFUSED
  (`CerbFloat.formatFixed`, register row REACHABLE, witnesses `fmt-007*.unsupported.c`). `string_of_float` keeps
  "nan" for every NaN; it feeds only the pretty-printers.
- **D2 (`atexit` refused).** [USER 2026-09-28] "agree on atexit as you propose": the function-pointer-to-integer
  refusal is withdrawn and the integer channel joins named deviation N1
  (`docs/2026-09-28_funptr-int-refusal-record.md`, addendum). New libc_exec rows `040-atexit-order` (MATCH,
  handlers in reverse order after `exit`) and `041-atexit-return` (MATCH: neither engine runs handlers when `main`
  returns, although ISO C 5.1.2.2.3 says it should — a mirrored oracle behaviour, upstream candidate).
- **D3/D4 (`strtok`, finite `strtod`).** Both engines fail with "unknown procedure"; only the symbol number in the
  message differs: class (a), no action.
- **D5 (`calloc` of a huge size).** The oracle does not finish within 300 s and Lean overflows its stack: class (b)
  permits Lean failing where the oracle does not complete. No action.
- **D6 (non-ASCII `--args`).** Both fail-stop, with different message text: class (a). Lean's U+FFFD replacement of
  invalid bytes before the semantics is hidden today by the shared fail-stop; noted in CONTRACT §3.2 (argv row).
