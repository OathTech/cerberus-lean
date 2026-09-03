/-!
Control: the same recursion shape with no allocation per frame.  The
guard page is hit inside `deep` itself, no lock is held, and the runtime
reports the overflow as designed.

Expected and observed: "Stack overflow detected. Aborting." + SIGABRT.
-/

@[export repro_deep] partial def deep (n : Nat) (x : Nat) : Nat :=
  if n == 0 then x
  else deep (n - 1) (x + 1) + 1

def main (args : List String) : IO Unit := do
  let n := (args.head? >>= String.toNat?).getD 1000000000
  IO.println s!"depth {n}"
  (← IO.getStdout).flush   -- so the line survives if the process never exits
  IO.println s!"result {deep n 0}"
