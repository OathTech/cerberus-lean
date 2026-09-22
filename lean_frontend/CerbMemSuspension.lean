import CerbMem

namespace CerbMemSuspension
variable {α : Type}

def node (m : CerbMem.memM α) (s : CerbMem.MemState) :=
  match m with | ND run => run s

theorem disabled (operation : Unit → CerbMem.memM α) (s : CerbMem.MemState)
    (h : s.suspendEnabled = false) :
    node (CerbMem.beforePrimitive operation) s = node (operation ()) s := by
  simp [node, CerbMem.beforePrimitive, h]
  rfl

theorem first (operation : Unit → CerbMem.memM α) (s : CerbMem.MemState)
    (h : s.suspendNext = false) :
    node (CerbMem.beforePrimitive operation) s = node (operation ()) s := by
  simp [node, CerbMem.beforePrimitive, h]
  rfl

theorem paused (operation : Unit → CerbMem.memM α) (s : CerbMem.MemState)
    (enabled : s.suspendEnabled = true) (later : s.suspendNext = true) :
    node (CerbMem.beforePrimitive operation) s =
      (NDsuspend (ND fun current => node (operation ()) current), s) := by
  simp [node, CerbMem.beforePrimitive, enabled, later]
  rfl

theorem disable (s : CerbMem.MemState) :
    CerbMem.setSuspending false s = some { s with suspendEnabled := false, suspendNext := false } := rfl

theorem observer_required (s : CerbMem.MemState) (h : s.observations = none) :
    CerbMem.setSuspending true s = none := by simp [CerbMem.setSuspending, h]

end CerbMemSuspension
