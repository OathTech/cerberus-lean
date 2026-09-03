/-!
Variants used to bracket the mechanism.  First argument selects the mode,
second is the recursion depth (default: effectively unbounded).

  bignum   -- same as OverflowInMalloc.lean (glibc malloc per frame)      -> hang
  task     -- `bignum` on a Task worker thread instead of the main thread -> hang
  cps      -- `bignum` through a function-typed monad (closure chain)     -> hang
  bytes    -- a fresh 2 KB ByteArray per frame (Lean's own allocator)     -> loud abort
  ref      -- an IO.Ref update per frame, no bignum                       -> loud abort
  plain    -- no allocation per frame                                     -> loud abort
-/

def big : Nat := 2 ^ 10000

@[export variants_deep] partial def deep (n : Nat) (x : Nat) : Nat :=
  if n == 0 then x
  else deep (n - 1) (x + 1) + 1

@[export variants_deepBytes] partial def deepBytes (n : Nat) (b : ByteArray) : ByteArray :=
  if n == 0 then b
  else deepBytes (n - 1) (ByteArray.emptyWithCapacity 2048 |>.push (b.size.toUInt8)) |>.push 1

partial def deepRef (r : IO.Ref Nat) (n : Nat) : IO Nat := do
  if n == 0 then r.get
  else
    r.modify (· + 1)
    let v ← deepRef r (n - 1)
    return v + 1

-- A function-typed state monad: every bind goes through a closure application.
structure M (α : Type) where
  run : Nat → (α × Nat)
instance [Inhabited α] : Inhabited (M α) := ⟨⟨fun s => (default, s)⟩⟩
@[inline] def M.pure (a : α) : M α := ⟨fun s => (a, s)⟩
@[inline] def M.bind (m : M α) (f : α → M β) : M β := ⟨fun s => let (a, s') := m.run s; (f a).run s'⟩
instance : Monad M := { pure := M.pure, bind := M.bind }
def M.tick (x : Nat) : M Nat := ⟨fun s => (x + 1, s + 1)⟩

partial def deepCps (n : Nat) (x : Nat) : M Nat :=
  if n == 0 then pure x
  else do
    let y ← M.tick x          -- bignum add on the way down
    let r ← deepCps (n - 1) y
    pure (r + 1)              -- non-tail

def main (args : List String) : IO Unit := do
  let mode := args.head?.getD "bignum"
  let n := (args[1]? >>= String.toNat?).getD 1000000000
  IO.println s!"mode {mode} depth {n}"
  (← IO.getStdout).flush
  match mode with
  | "bignum" => IO.println s!"result {deep n big % 1000}"
  | "plain"  => IO.println s!"result {deep n 0 % 1000}"
  | "task"   =>
    -- the closure body runs on a task-manager worker thread, not the thread running `main`
    let t := Task.spawn fun _ => deep n big % 1000
    IO.println s!"result {t.get}"
  | "cps"    => IO.println s!"result {((deepCps n big).run 0).1 % 1000}"
  | "bytes"  => IO.println s!"result {(deepBytes n ByteArray.empty).size}"
  | "ref"    =>
    let r ← IO.mkRef 0
    IO.println s!"result {← deepRef r n}"
  | _ => throw <| IO.userError s!"unknown mode {mode}"
