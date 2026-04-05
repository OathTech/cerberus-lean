/-
  Global Cerberus configuration and switches.
  Corresponds to: util/cerb_global.ml and ocaml_frontend/switches.ml

  Uses mutable state (like the OCaml implementation) for runtime configuration.
  This is a leaf module — no imports from generated code.
-/

namespace CerbGlobal

/-! ## Execution Mode
    Corresponds to: Cerb_global.execution_mode -/

inductive ExecutionMode where
  | exhaustive
  | random
  deriving BEq, Inhabited, Repr

/-! ## Switches
    Corresponds to: Switches.cerb_switch in switches.ml
    The lem file only exposes a subset of the full OCaml switch type. -/

inductive CerbSwitch where
  | strict_reads
  | forbid_nullptr_free
  | zap_dead_pointers
  | inner_arg_temps
  | permissive_printf
  | no_integer_provenance
  | cheri
  deriving BEq, Inhabited, Repr

/-! ## Global Configuration
    Corresponds to: Cerb_global.cerberus_conf -/

structure CerbConf where
  backendName : String := "cerberus-lean"
  execMode : Option ExecutionMode := none
  concurrency : Bool := false
  defacto : Bool := false
  permissive : Bool := false
  agnostic : Bool := false
  ignoreBitfields : Bool := false
  deriving Inhabited

/-! ## Mutable global state
    Mirrors: cerb_conf ref and Switches.internal_ref in OCaml -/

private unsafe def confRef : IO.Ref CerbConf :=
  unsafeBaseIO (IO.mkRef default)

private unsafe def switchesRef : IO.Ref (List CerbSwitch) :=
  unsafeBaseIO (IO.mkRef [])

-- Config accessors (mirror cerb_global.ml)

private unsafe def getConf : CerbConf :=
  unsafeBaseIO confRef.get

unsafe def backend_name_impl (_ : Unit) : String :=
  getConf.backendName

unsafe def current_execution_mode_impl (_ : Unit) : Option ExecutionMode :=
  getConf.execMode

unsafe def using_concurrency_impl (_ : Unit) : Bool :=
  getConf.concurrency

unsafe def isDefacto_impl (_ : Unit) : Bool :=
  getConf.defacto

unsafe def isPermissive_impl (_ : Unit) : Bool :=
  getConf.permissive

unsafe def isAgnostic_impl (_ : Unit) : Bool :=
  getConf.agnostic

unsafe def isIgnoreBitfields_impl (_ : Unit) : Bool :=
  getConf.ignoreBitfields

-- Switch accessors (mirror switches.ml)

unsafe def has_switch_impl (sw : CerbSwitch) : Bool :=
  let sws := unsafeBaseIO switchesRef.get
  sws.any (· == sw)

unsafe def is_CHERI_impl (_ : Unit) : Bool :=
  has_switch_impl .cheri

unsafe def is_PNVI_impl (_ : Unit) : Bool := false  -- no PNVI switch in lem subset

unsafe def has_strict_pointer_arith_impl (_ : Unit) : Bool := false  -- not in lem subset

/-! ## Safe wrappers via implemented_by -/

@[implemented_by backend_name_impl]
opaque backend_name : Unit → String

@[implemented_by current_execution_mode_impl]
opaque current_execution_mode : Unit → Option ExecutionMode

@[implemented_by using_concurrency_impl]
opaque using_concurrency : Unit → Bool

@[implemented_by isDefacto_impl]
opaque isDefacto : Unit → Bool

@[implemented_by isPermissive_impl]
opaque isPermissive : Unit → Bool

@[implemented_by isAgnostic_impl]
opaque isAgnostic : Unit → Bool

@[implemented_by isIgnoreBitfields_impl]
opaque isIgnoreBitfields : Unit → Bool

@[implemented_by has_switch_impl]
opaque has_switch : CerbSwitch → Bool

@[implemented_by is_CHERI_impl]
opaque is_CHERI : Unit → Bool

@[implemented_by is_PNVI_impl]
opaque is_PNVI : Unit → Bool

@[implemented_by has_strict_pointer_arith_impl]
opaque has_strict_pointer_arith : Unit → Bool

end CerbGlobal
