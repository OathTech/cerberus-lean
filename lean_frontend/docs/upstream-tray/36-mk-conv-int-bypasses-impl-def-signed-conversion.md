# `Core_eval.mk_conv_int` wraps non-representable SIGNED conversions directly, bypassing the impl-defined `<Integer.conv_nonrepresentable_signed_integer>` that `std.core`'s `conv_int` calls

**Affected:** `frontend/model/core_eval.lem:61-81` (`mk_conv_int`, the
evaluator's rule for the Core AST constructor `PEconv_int ity pe`) vs
`runtime/libcore/std.core:25-55` (`conv_int`, the library's own
conversion function). Checked against `master` @ `b9aeedcb4`: `std.core`
and the gcc impl file are byte-identical; `core_eval.lem` differs from
upstream only by our Lean-target declares at its tail (lines 1201+), the
`mk_conv_int` region is byte-identical.

**Classification:** UNCLEAR → most likely TRUE BUG (latent). The two
paths agree under the shipped gcc impl, so no current test can observe
the difference; they disagree for any impl whose signed
non-representable conversion is not modular wrap (ISO C17 §6.3.1.3#3
allows an implementation-defined result OR signal). The code's own
`TODO` says the impl-def call is the intent.

## The two paths

`std.core:25-55` follows §6.3.1.3 clause by clause:

```
    else
      if is_unsigned(ty) then
        wrapI(ty, n)
      else
        <Integer.conv_nonrepresentable_signed_integer>(ty, n)
```

`core_eval.lem:61-81` handles `_Bool`, then the representable case, then:

```
                else
                  (* TODO need to have the impl-def <Integer.conv_nonrepresentable_signed_integer>(ty, n) (if ity is unsigned) *)
                  mk_wrapI ity n_ival
```

so a signed non-representable conversion evaluated through `PEconv_int`
is unconditionally `wrapI`. (The `TODO`'s parenthetical says "if ity is
unsigned"; from context it means the signed case — the unsigned case IS
`wrapI` per §6.3.1.3#2.)

Under `runtime/libcore/impls/gcc_4.9.0_x86_64-apple-darwin10.8.0.impl:17-19`:

```
fun <Integer.conv_nonrepresentable_signed_integer>(ty: ctype, n: integer) : integer :=
-- TODO doc
  wrapI(ty, n)
```

the two coincide, which is why this is unobservable today. The other
shipped impl (`i686-apple-darwin10-gcc-4.2.1.impl`) does not define the
function at all.

## Why it matters

`PEconv_int` is what the elaboration emits for most integer conversions
(`translation.lem`), so the evaluator path — not `std.core`'s
`conv_int` — is what almost every program exercises. An implementation
whose choice for §6.3.1.3#3 is saturation, a trap, or a signal cannot be
modelled by supplying an impl file: the evaluator ignores the impl for
this case. That defeats the purpose of making the conversion
impl-defined in `std.core`, and it means the semantics is silently
gcc-specific here regardless of the selected impl.

## Proposed remedy

In `mk_conv_int`, mirror `std.core`: after the representable check,
branch on `is_unsigned ity`: unsigned → `mk_wrapI ity n_ival`; signed →
evaluate the impl-defined `<Integer.conv_nonrepresentable_signed_integer>`
(the same mechanism `Core_eval` uses for other `Eimpl` constants; the
constant already exists in `implementation.lem:188/271/326`). Behaviour
under the shipped gcc impl is unchanged, so no test baseline moves; the
`TODO` comment can go.

## Provenance

Found by the refined-cerberus team [AGENT] while designing their
emitted-Core dialect (their note
`refined-cerberus/docs/2026-09-05_note-cerberus-lean-conv-int-divergence.md`,
2026-09-05, measured at semantics pin `f95ef8d9c`); cites verified and
the byte-identity against upstream re-checked by the cerberus-lean
orchestrator [AGENT] 2026-09-05. NOT a Lean-vs-OCaml discrepancy: both
oracles run the same `mk_conv_int`. Our port mirrors the OCaml here
(aim 1) and does not apply the remedy locally; it is on this tray so the
divergence is not rediscovered.
