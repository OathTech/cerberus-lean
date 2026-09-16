import Outcomes_probe_undefined
set_option autoImplicit false

-- Reduced model of State_exception.mapM followed by Undefined.mapM id,
-- the layering in State_exception_undefined.stExceptUndef_mapM.
-- This is a design counterexample, not a modified production implementation.
def outerMap (f : Nat → Nat → Except String (t Nat × Nat)) :
    List Nat → Nat → Except String (List (t Nat) × Nat)
  | [], s => .ok ([], s)
  | x :: xs, s =>
    match f x s with
    | .error e => .error e
    | .ok (u, s') =>
      match outerMap f xs s' with
      | .error e => .error e
      | .ok (us, s'') => .ok (u :: us, s'')

def innerSequence : List (t Nat) → t (List Nat)
  | [] => Defined []
  | u :: us => bind1 u (fun x =>
      bind1 (innerSequence us) (fun xs => Defined (x :: xs)))

def layeredMap (f : Nat → Nat → Except String (t Nat × Nat))
    (xs : List Nat) (s : Nat) : Except String (t (List Nat) × Nat) :=
  match outerMap f xs s with
  | .error e => .error e
  | .ok (us, s') => .ok (innerSequence us, s')

def stopThenWrite (x s : Nat) : Except String (t Nat × Nat) :=
  if x = 0 then .ok (Stopped Exhausted, s) else .ok (Defined x, s + 1)

def stopThenError (x s : Nat) : Except String (t Nat × Nat) :=
  if x = 0 then .ok (Stopped Exhausted, s) else .error "later"

theorem state_changes_after_stop :
    layeredMap stopThenWrite [0, 1] 0 = .ok (Stopped Exhausted, 1) := rfl

theorem stop_replaced_by_later_exception :
    layeredMap stopThenError [0, 1] 0 = .error "later" := rfl

#print axioms state_changes_after_stop
#print axioms stop_replaced_by_later_exception
