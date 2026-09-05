# Draft — Lean 4: `Nat.div`/`Nat.mod` (and `Int.div`) literal folding does not reduce its arguments first, so `rfl` fails on `8 / f (k+1)` although `f (k+1)` reduces to the literal `4` by `rfl` and every other arithmetic operator folds

Target: `leanprover/lean4` (elaborator/`Meta` reduction of `Nat`
arithmetic on literals — `Nat.reduceBinNatOp`/`reduceNat?` and the kernel's
GMP-accelerated `Nat.div`/`Nat.mod`). Drafted 2026-09-05; NOT filed —
filing is the operator's call (network + GitHub). Classification [AGENT
2026-09-05]: **UNCLEAR — reported as a question with a reproducer.** The
observable is an inconsistency between operators on identical inputs
(`- * +` and `Nat.beq` fold through a reducible argument, `/ %` do not);
whether the `Nat.div`/`Nat.mod` fast path is MEANT to fire only on closed
literals, or whether its argument normalisation is an omission, is for the
Lean developers to say. Reproduced identically on v4.28.0, v4.32.2,
v4.33.0 and nightly-2026-08-02 (4.34.0-nightly).

## Reproducer (standalone, no imports)

`lean4/repro/DivModLiteralFold.lean` (this directory), 12 independent
`example`s over

```lean
def f : Nat → Nat
  | 0     => 0
  | _ + 1 => 4

variable (k : Nat)
```

Run: `lean DivModLiteralFold.lean` (exit 1; four errors). Per line,
verbatim outcome (identical on the four toolchains):

```
example : f (Nat.succ k) = 4 := rfl                        -- OK
example : (8 : Nat) / f 5 = 2 := rfl                       -- OK (literal argument)
example : (8 : Nat) / f (Nat.succ k) = 2 := rfl            -- FAILS
example : (8 : Nat) / f (k + 1) = 2 := rfl                 -- FAILS
example : (8 : Nat) % f (Nat.succ k) = 0 := rfl            -- FAILS
example : (8 : Nat) - f (Nat.succ k) = 4 := rfl            -- OK
example : (8 : Nat) * f (Nat.succ k) = 32 := rfl           -- OK
example : (8 : Nat) + f (Nat.succ k) = 12 := rfl           -- OK
example : Nat.beq 4 (f (Nat.succ k)) = true := rfl         -- OK
example : (8 : Int) / (f (Nat.succ k) : Int) = 2 := rfl    -- FAILS
example : (8 : Nat) / f (Nat.succ k) = 2 := by simp [f]              -- OK (unfolds first)
example : (8 : Nat) / f (Nat.succ k) = 2 := by show 8 / 4 = 2; rfl   -- OK (rewritten first)
```

The four failures, verbatim (Lean 4.32.2; the other three toolchains
print the same text with the same positions):

```
DivModLiteralFold.lean:17:44: error: Type mismatch
  rfl
has type
  ?m.11 = ?m.11
but is expected to have type
  8 / f k.succ = 2
DivModLiteralFold.lean:18:39: error: Type mismatch
  rfl
has type
  ?m.17 = ?m.17
but is expected to have type
  8 / f (k + 1) = 2
DivModLiteralFold.lean:19:44: error: Type mismatch
  rfl
has type
  ?m.11 = ?m.11
but is expected to have type
  8 % f k.succ = 0
DivModLiteralFold.lean:24:52: error: Type mismatch
  rfl
has type
  ?m.11 = ?m.11
but is expected to have type
  8 / ↑(f k.succ) = 2
```

Toolchain matrix (2026-09-05, `~/.elan/toolchains`, each run under a
memory cap; all four: exit 1, the same four errors):

| toolchain | result |
|---|---|
| Lean (version 4.28.0, commit 7e01a1bf5c70) | 4 errors (lines 17, 18, 19, 24) |
| Lean (version 4.32.2, commit f3b06c705e6c) | 4 errors (same) |
| Lean (version 4.33.0, commit d8b18978322d) | 4 errors (same) |
| Lean (version 4.34.0-nightly-2026-08-02, commit 23d17351ab63) | 4 errors (same) |

## What we observed about the mechanism

From a `MetaM` probe in the original investigation (our record
`lean_frontend/docs/2026-09-04_fuel-parameter-C1-record.md` §4.3, Lean
4.32.2): `whnf (f (Nat.succ k))` is the literal `4` (`isLit = true`), but
`whnf (Nat.div 8 (f (Nat.succ k)))` is stuck at `Nat.div 8 (f k.succ)` and
`reduceNat?` reports `<not-available>`. Our reading: the `Nat.div`/`Nat.mod`
literal-folding step tests its arguments for raw literals WITHOUT
normalising them first, and since `Nat.div`/`Nat.mod` are well-founded
(irreducible) definitions there is no structural unfolding to fall back
on — whereas `Nat.add`/`Nat.sub`/`Nat.mul` unfold structurally on the
(reduced) second argument and then fold. The `Int` case inherits the
`Nat` one. We have not read the reducer's source to confirm this reading.

## Why it matters to us

Our Lean port of a C semantics quantifies over an execution parameter
(fuel). Layout arithmetic of the form `size / alignment` where the
alignment is computed by a fuel-indexed function is exactly the failing
shape: at a symbolic fuel `⟨Nat.succ k⟩` the alignment reduces to a
literal by `rfl` but the division does not fold, so every such proof step
needs an explicit rewrite of the divisor to its value first (we did that;
it is a workaround, not a blocker).

## Suggested remedy (if this is an omission)

Have the `Nat.div`/`Nat.mod` (and `Nat.pow`, if it shares the path) literal
fast path `whnf` its arguments to literals before testing them — the same
normalisation the other binary operators effectively get through
structural unfolding — so that `decide`/`rfl` behave uniformly across the
`Nat` operators on the same inputs.

## Provenance

Found 2026-09-04 while proving a fuel-parametric theorem in our Lean port
of Cerberus (record cited above); the minimal reproducer was re-derived
into the standalone file here and re-run 2026-09-05 on the four
toolchains (outputs verbatim). Investigation and draft by Claude (Fable
5.1) under operator direction; per the tray's provenance policy the filed
issue carries an AI-provenance note.
