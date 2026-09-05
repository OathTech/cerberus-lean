/-
  Standalone reproducer for upstream-tray lean4/02: `Nat.div` / `Nat.mod`
  (and `Int.div`) literal folding does not reduce its arguments to
  literals first, so `decide`/`rfl` fails on `8 / f (k+1)` although
  `f (k+1)` reduces to the literal `4` by `rfl` and every other
  arithmetic operator folds. No imports; run with `lean DivModLiteralFold.lean`.
  Each `example` is independent; the failing ones are the report.
-/
def f : Nat → Nat
  | 0     => 0
  | _ + 1 => 4

variable (k : Nat)

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
