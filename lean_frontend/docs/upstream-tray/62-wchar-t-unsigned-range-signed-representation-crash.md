# `wchar_t` is given the unsigned range by the memory model but a signed representation by the implementation: a negative `wchar_t` value crashes the tool

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
valid C; an internal contradiction, not an implementation choice). Fork plan ([USER 2026-10-20]): the crash
becomes a declared refusal (a refinement: an unspecified stop turned into a specified one), queued behind the
cerberus-caesium deliveries; the alignment of `min_ival`/`max_ival` with `wchar_t_alias` is this report's proposal
to upstream. The report above describes upstream as it stands.
