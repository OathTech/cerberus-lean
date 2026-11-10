# `wchar_t` is given the unsigned range by the memory model but a signed representation by the implementation: a negative `wchar_t` value crashes the tool

**Loci at `c3ff8c53f` (2026-11-10):** `memory/concrete/impl_mem.ml:2213` and `:2243` (the `Wchar_t` arms of the minimum
and maximum), `ocaml_frontend/ocaml_implementation.ml:167` (`wchar_t_alias`), and the assertion at `impl_mem.ml:932`
(`bytes_of_int`), read from the un-forked tree. The line numbers in the paragraph below are this fork's at an earlier
date.

**Affected:** `memory/concrete/impl_mem.ml:2449` and `:2479` (`min_ival`/`max_ival`: `| Wchar_t (* TODO: it is
implementation defined if unsigned *)` grouped with the unsigned types, so `conv_int` wraps a negative value into
`[0, 2^32)`), against `ocaml_frontend/ocaml_implementation.ml:167` (`wchar_t_alias= Signed Int_; (*TODO: check
*)`) and `AilTypesAux.is_signed_ity Wchar_t` as used by `repr`'s `bytes_of_int (is_signed_ity ity) …`, which
then asserts because `4294967295` is outside the signed 32-bit range (`impl_mem.ml:1144` in the fork; upstream
`:1109` at the merge-base `b9aeedcb4`). The Lean port mirrors both sides (`CerberusImpl.lean:181`,
`CerbMem.lean` `intToBytes`) and fails with the same text.

## Description

Measured 2026-10-20 on the fork @ `3ac3ff336` (and on the pristine merge-base binary, same assertion):

```c
#include <stddef.h>
int main(void){ wchar_t w = -1; return w < 0; }     /* gcc 1 (wchar_t is int on x86-64 Linux) */
```
```text
cerberus: internal error, uncaught exception:
          File "memory/concrete/impl_mem.ml", line 1144, characters 6-12: Assertion failed
          Raised at Cerb_frontend__Impl_mem.Concrete.bytes_of_int in file "memory/concrete/impl_mem.ml", line 1144, characters 6-18
          Called from Cerb_frontend__Impl_mem.Concrete.repr in file "memory/concrete/impl_mem.ml", lines 1181-1185, characters 42-13
          Called from Cerb_frontend__Impl_mem.Concrete.store.do_store.(fun) in file "memory/concrete/impl_mem.ml", line 1743, characters 36-58
```
(exit 125; the Lean port: `CerbMem.intToBytes: failed: bytes_of_int(signed), i= 4294967295, nbits= 32,
[-2147483648 ... 2147483647]`.) The same for `wchar_t w = x` with `unsigned x = 0xffffffffu`, and for
`w == -1`. A positive `wchar_t` (`5`, `0x7fffffff`) is fine, and `(wchar_t)-1 < 0` evaluates to 0 where the
implementation's own alias (signed int) says 1 — the signedness of `wchar_t` is implementation-defined
(§7.19#2), but one implementation cannot have both. Witnesses: `tests/parity-probes/uncertainty/E-wchar_t/`.

## Expected

One signedness for `wchar_t` throughout: `min_ival`/`max_ival` (and `Wint_t` beside it, the same `TODO`)
following `wchar_t_alias` — signed int, as on x86-64 Linux — so that the conversion and the representation agree
and no valid program reaches the assertion.

## Origin

Found by the fork's upstream-uncertainty survey (2026-10-20, `lean_frontend/docs/2026-10-20_upstream-uncertainty-survey-record.md`,
cluster E) from the `TODO: it is implementation defined if unsigned` marker. Classification: TRUE BUG (a crash on
valid C; an internal contradiction, not an implementation choice). Fork status: the fork's engines crash as upstream does; an earlier plan to
turn the crash into a declared refusal ([USER 2026-10-20]) is not being carried out — since the roadmap of 2026-11-10
the crash is reported, not refused in code. The alignment of `min_ival`/`max_ival` with `wchar_t_alias` is this report's
proposal to upstream. The report above describes upstream as it stands.

## Re-run at `c3ff8c53f` (2026-11-10): still reproduces; loci moved; two silent witnesses and the limit macros

(Un-forked upstream binary + runtime @ `c3ff8c53f`, both fork engines and gcc 13.3.0 `-std=c11 -w -O0`, all run on 2026-11-10; outputs verbatim. [AGENT 2026-11-10], the reporting slice.)

```
$ cerberus --nolibc --exec --batch wc_neg.c          # wchar_t w = -1; return w < 0;
failed: bytes_of_int(signed), i= 4294967295, nbits= 32, [-2147483648 ... 2147483647]
cerberus: internal error, uncaught exception:
          File "memory/concrete/impl_mem.ml", line 932, characters 6-12: Assertion failed
          Raised at Cerb_frontend__Impl_mem.Concrete.bytes_of_int in file "memory/concrete/impl_mem.ml", line 932, characters 6-18
[… 19 more lines cut]
```

(exit 125; gcc exits 1.) Loci at `c3ff8c53f`: `memory/concrete/impl_mem.ml:2213` and `:2243` (the
`Wchar_t (* TODO: it is implementation defined if unsigned *)` arms of the minimum and maximum), against
`ocaml_frontend/ocaml_implementation.ml:167` (`wchar_t_alias= Signed Int_; (*TODO: check *)`); the assertion is
`impl_mem.ml:932` (`bytes_of_int`). The same assertion for a wide character constant:

```c
#include <stddef.h>
int main(void) { wchar_t w = L'\377'; return w == 255; }
```

(exit 125 with the same two first lines; gcc exits 1.) Not in this report before — the contradiction also gives
verdicts and values without crashing:

```c
#include <stddef.h>
int main(void) { wchar_t w = 100000; return (w - 200000) < 0; }
```
```
Undefined {ub: "UB036_exceptional_condition", stderr: "", loc: "<2:45--2:57>"}
```

(exit 1; gcc exits 1, the difference is -100000. A false undefined-behaviour verdict under either signedness.)

```c
#include <stdint.h>
#include <stdio.h>
int main(void) { printf("%lld %lld %d %d\n", (long long)WCHAR_MAX, (long long)WCHAR_MIN, WCHAR_MAX > 0, WCHAR_MIN < 0); return 0; }
```
```
Defined {value: "Specified(0)", stdout: "4294967295 0 1 0\n", stderr: "", blocked: "false"}
$ gcc -std=c11 -w -O0 wcmax_print.c && ./a.out
2147483647 -2147483648 1 1
```

(`<stdint.h>`'s `WCHAR_MAX`/`WCHAR_MIN`, `runtime/libc/include/stdint.h:103-104`, are the unsigned range's
4294967295 and 0 while the type's alias is `signed int`.) And `(wchar_t)-1 < 0` is 0 on pristine (gcc: 1).

**Fork status (2026-11-10).** The crash is unchanged in both engines (not refused in code). Since the fork's
integer-rank change (report 20's patch: `wchar_t` has the rank of `int` and promotes to it) the subtraction witness and
`(wchar_t)-1 < 0` answer gcc's 1 in both fork engines. **One program moved the wrong way and is a silent wrong
answer of the fork that pristine does not give:** `#include <stdint.h>` / `int main(void) { return WCHAR_MAX > 0; }`
is `Specified(1)` on pristine and `Specified(0)` on both fork engines (gcc: 1) — the fork's line for the program
above is `4294967295 0 0 0`. The macro's value is still the unsigned maximum while comparisons now treat the type as
signed. The cause was established by reading, not by running a build from before the change: the rank normalisation of
`Wchar_t` to `signed int` was introduced by this repository's commit `9b15a1f69` (2026-11-04, report 20's patch) in
`frontend/model/ail/ailTypesAux.lem`, the maxima at `impl_mem.ml:2243` still group `Wchar_t` with the unsigned types,
and 4294967295 converted to `int` is -1. Found on 2026-11-10; not fixed in that pass (documents only); a fix is queued
(`lean_frontend/TODO.md`, the entry at the top), and report 20 carries a warning beside its patch.
