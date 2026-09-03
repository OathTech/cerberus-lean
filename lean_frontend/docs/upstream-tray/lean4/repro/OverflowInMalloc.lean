/-!
Stack overflow reached while the faulting thread is inside glibc `malloc`.

Every frame of `deep` performs one arithmetic operation on a bignum wider
than glibc's tcache limit (1032 bytes), so the operation's GMP
allocation and the free of the previous value both go through glibc's
locked arena path (`__libc_malloc` -> `_int_malloc`, `__libc_free` ->
`_int_free`).  Those glibc frames are the deepest point of every
recursion level, so the guard page is hit while the arena mutex is held.

Expected: "Stack overflow detected. Aborting." + SIGABRT.
Observed:  no output, no exit -- the SIGSEGV handler blocks on a futex.
-/

def big : Nat := 2 ^ 10000   -- 157 limbs = 1256 bytes of limb storage

-- `@[export]` makes both parameters owned (borrow inference is skipped), so each
-- frame frees its `x` BEFORE recursing and memory stays constant.  The `+ 1` after
-- the call keeps the recursion non-tail.
@[export repro_deep] partial def deep (n : Nat) (x : Nat) : Nat :=
  if n == 0 then x
  else deep (n - 1) (x + 1) + 1

def main (args : List String) : IO Unit := do
  let n := (args.head? >>= String.toNat?).getD 1000000000
  IO.println s!"depth {n}"
  (← IO.getStdout).flush   -- so the line survives if the process never exits
  IO.println s!"result {deep n big}"
