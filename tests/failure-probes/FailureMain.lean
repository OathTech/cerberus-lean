import Discarded_failures

-- These equations are counterexamples to using unguarded value equality as
-- an OCaml failure contract. They are not desirable semantic guarantees.
theorem erased_binding (n : Nat) : unused_binding n = n + 1 := rfl
theorem erased_argument (n : Nat) : unused_argument n = n + 1 := rfl
theorem erased_projection (n : Nat) : projection n = n + 1 := rfl
theorem erased_result (n : Nat) : discarded_result n = n + 1 := rfl
theorem erased_callback (n : Nat) : callback n = n + 1 := rfl
theorem erased_mapped_projection (n : Nat) : mapped_projection n = 1 := rfl
#print axioms erased_binding
#print axioms erased_argument
#print axioms erased_projection
#print axioms erased_result
#print axioms erased_callback
#print axioms erased_mapped_projection

def main (args : List String) : IO Unit := do
  let n := args.tail.length
  let f := match args.head? with
    | some "unused_binding" => unused_binding
    | some "unused_argument" => unused_argument
    | some "projection" => projection
    | some "discarded_result" => discarded_result
    | some "callback" => callback
    | some "mapped_projection" => mapped_projection
    | some "required" => required
    | some "control" => positive_control
    | _ => fun _ => 999
  IO.println (f n)
