import Outcomes_probe_nd
set_option autoImplicit false

theorem stop_bind {α β : Type} (s : interp_stop) (f : α → t β) :
    bind1 (Stopped s : t α) f = Stopped s := rfl

theorem stop_lift {α β : Type} (s : interp_stop) (f : α → β) :
    lift_reason f (Stopped0 s : kill_reason α) = Stopped0 s := rfl

theorem stop_channels {α ε : Type} (s : interp_stop) :
    stopped_from_pure (a := α) (err := ε) (Stopped s) = some (Stopped0 s) := rfl

theorem exhaustion_ne_failure {ε : Type} (msg : String) :
    (Stopped0 Exhausted : kill_reason ε) ≠ Stopped0 (FailStop msg) := by
  intro h
  cases h

theorem stop_ne_program_error {ε : Type} (s : interp_stop) (msg : String) :
    (Stopped0 s : kill_reason ε) ≠ Error0 msg := by
  intro h
  cases h

theorem default_becomes_exhaustion {α : Type} :
    (default : t α) = Stopped Exhausted := rfl

#print axioms stop_bind
#print axioms stop_lift
#print axioms stop_channels
#print axioms exhaustion_ne_failure
#print axioms stop_ne_program_error
#print axioms default_becomes_exhaustion

inductive OldResult (α : Type) where
  | defined : α → OldResult α
  | undef : String → OldResult α
  | error : String → OldResult α

def embed {α : Type} : OldResult α → t α
  | .defined x => Defined x
  | .undef s => Undef s
  | .error s => Error s

def oldBind {α β : Type} (m : OldResult α) (f : α → OldResult β) : OldResult β :=
  match m with
  | .defined x => f x
  | .undef s => .undef s
  | .error s => .error s

theorem old_bind_preserved {α β : Type} (m : OldResult α) (f : α → OldResult β) :
    embed (oldBind m f) = bind1 (embed m) (fun x => embed (f x)) := by
  cases m <;> rfl
#print axioms old_bind_preserved
