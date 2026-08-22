/-
  Debug output and debug level.
  Corresponds to: util/cerb_debug.ml
-/

import CerbLocation

set_option autoImplicit true

namespace CerbDebug

/-- Debug level stored in a C global to avoid Lean's CSE on pure functions. -/
@[extern "cerb_debug_get_level"]
opaque getLevelIO : @& Unit → BaseIO Nat

@[extern "cerb_debug_set_level"]
opaque setLevelIO : @& Nat → BaseIO Unit

/-- Pure wrappers used by hand-written code (Main.lean etc.).
    Generated code uses the IO versions via effectful target_rep.
    @[never_extract, noinline] (arc-14 S1 F5, sem:S11): matches the
    CerbTags armour — without it the compiler may cache/CSE a closed
    `get_level ()` read (evaluated before any `set_level`) or drop the
    `set_level` effect. `set_level` is ALSO effect-discarding in pure
    position (its result is Unit), so hand-written call sites that need
    the write to happen MUST use the BaseIO extern `setLevelIO` directly
    (see the effect-erasure invariant page); the pure wrapper stays for
    generated read paths. -/
@[never_extract, noinline]
private unsafe def get_level_impl (_ : Unit) : Nat :=
  unsafeBaseIO (getLevelIO ())

@[never_extract, noinline]
private unsafe def set_level_impl (n : Nat) : Unit :=
  unsafeBaseIO (setLevelIO n)

@[implemented_by get_level_impl]
opaque get_level : Unit → Nat
attribute [never_extract] get_level

@[implemented_by set_level_impl]
opaque set_level : Nat → Unit
attribute [never_extract] set_level

def output_string (_ : String) : Unit := ()

/-- print_debug — effectful version for generated code.
    Returns BaseIO Unit so runEffectful wrapping prevents CSE. -/
def printDebugIO (level : Nat) (_ : List d) (msg : Unit → String) : BaseIO Unit := do
  let n ← getLevelIO ()
  if level ≤ n then
    dbg_trace (msg ()); pure ()
  else
    pure ()

def print_debug (level : Nat) (ds : List d) (msg : Unit → String) : Unit :=
  if level ≤ get_level () then dbg_trace (msg ()); () else ()

def print_debug_located (_ : Nat) (_ : List d) (_ : CerbLocation.Loc) (_ : Unit → String) : Unit := ()


/-- Pure no-op replacement for the debug print path (arc-1 ruling 2026-08-18:
    debug is stubbed everywhere; the proof path must not see IO). -/
def print_debug_pure (_ : Nat) (_ : List d) (_ : Unit → String) : Unit := ()

def print_unsupported (_ : String) : Unit := ()

def warn (_ : List d) (_ : Unit → String) : Unit := ()

end CerbDebug
