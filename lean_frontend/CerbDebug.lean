/-
  Debug output — pure stubs only.
  Corresponds to: util/cerb_debug.ml

  Effect-retirement C1 (charter section 5, [USER 2026-08-31] decision
  2): debug output is OUT of the semantics cone — the model returns
  values, the driver prints. The model's debug path has been stubbed
  pure since arc-1 (debug.lem: `get_level u = 0` on Lean;
  `print_debug -> print_debug_pure`); this slice deletes the vestigial
  level machinery (the C global + getLevelIO/setLevelIO externs +
  armoured wrappers + the dbg_trace print_debug, native/debug.c). The
  driver's verbosity choice is ordinary driver-local state in Main; if
  Core-step tracing is wanted later it is a driver feature over
  returned values (the --trace-nodes pattern), not a model effect.
-/

import CerbLocation

set_option autoImplicit true

namespace CerbDebug

/-- The debug level, pure and constant: the generated model is compiled
    at level 0 (debug.lem's Lean target_rep for the model path is the
    literal 0; this def backs the residual hand-written readers in
    CerbMem, whose oracle counterparts read a level the batch driver
    leaves at 0). -/
def get_level (_ : Unit) : Nat := 0

def output_string (_ : String) : Unit := ()

def print_debug_located (_ : Nat) (_ : List d) (_ : CerbLocation.Loc) (_ : Unit → String) : Unit := ()

/-- Pure no-op replacement for the debug print path (arc-1 ruling 2026-08-18:
    debug is stubbed everywhere; the proof path must not see IO). -/
def print_debug_pure (_ : Nat) (_ : List d) (_ : Unit → String) : Unit := ()

/-- `Cerb_debug.print_unsupported` — cerb_debug.ml:43-45 prints
    `"unsupported: " ^ msg` on the TOOL's stderr UNCONDITIONALLY (not
    level-gated). DECLARED EXC(a) (zero-discrepancy Z2-U-01): its only
    callers are translation_effect.lem:250-265 `record_error` paths that
    end in an `error` crash on both engines — tool-stderr text on a
    both-crash path. -/
def print_unsupported (_ : String) : Unit := ()

def warn (_ : List d) (_ : Unit → String) : Unit := ()

end CerbDebug
