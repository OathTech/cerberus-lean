# `Float.toBits` canonicalizes NaNs, but its docstring says "bit-for-bit"

**Target:** `leanprover/lean4`. **Checked at:** Lean v4.32.2 (`Init/Data/Float.lean:113-123`,
`lean_float_to_bits` in `libleanshared.so`). **Status:** Draft, not duplicate-searched.

## What happens

The docstring of `Float.toBits` reads: "Bit-for-bit conversion to `UInt64`. Interprets a `Float` as a `UInt64`,
ignoring the numeric value and treating the `Float`'s bit pattern as a `UInt64`." The runtime implementation
replaces every NaN with `0x7ff8000000000000`: the disassembly of `lean_float_to_bits` is
`ucomisd; movq; movabs $0x7ff8000000000000; cmovnp`. Measured:

```lean
#eval (Float.ofBits 0xfff8000000000000).toBits   -- 9221120237041090560 (= 0x7ff8000000000000), not 0xfff8…
#eval ((1e309 : Float) - 1e309).toBits          -- 9221120237041090560; the hardware NaN on x86 is 0xfff8…
```

## Why it matters

Canonicalizing is a reasonable choice (NaN signs and payloads are not deterministic across platforms or
optimizations), but code that follows the docstring loses the sign and payload silently. We hit it in a C semantics
that stores doubles as their bits: a stored NaN's bytes differ from the C program's.

## Suggestion

Document the canonicalization in the docstring; optionally provide a separate, clearly-labelled raw conversion for
code that needs the platform bits.
