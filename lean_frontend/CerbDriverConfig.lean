import Core
import CerbGlobal

/-! The driver's switch-dependent configuration, shared by runtime validation
and loading. The selectors mirror the OCaml pipeline; the switch set remains
an explicit reader parameter throughout the model. -/
namespace CerbDriverConfig

/-- `backend/common/pipeline.ml:34`: choose the matching Core standard library. -/
def stdCoreName [CerbGlobal.Switches] : String :=
  if CerbGlobal.has_switch .inner_arg_temps then "std_inner_arg_temps.core" else "std.core"

/-- `backend/common/pipeline.ml:271`: choose the elaborator's calling convention. -/
def callingConvention [CerbGlobal.Switches] : calling_convention :=
  if CerbGlobal.has_switch .inner_arg_temps then Inner_arg_callconv else Normal_callconv

/-- Names used by the oracle's switch parser; this is reporting, not acceptance. -/
def switchName : CerbGlobal.CerbSwitch → String
  | .strict_reads => "strict_reads"
  | .forbid_nullptr_free => "forbid_nullptr_free"
  | .zap_dead_pointers => "zap_dead_pointers"
  | .inner_arg_temps => "inner_arg_temps"
  | .permissive_printf => "permissive_printf"
  | .no_integer_provenance => "no_integer_provenance"
  | .cheri => "CHERI"
  | .pointer_arith .PERMISSIVE => "permissive_pointer_arith"
  | .pointer_arith .STRICT => "strict_pointer_arith"
  | .strict_pointer_equality => "strict_pointer_equality"
  | .strict_pointer_relationals => "strict_pointer_relationals"
  | .zero_initialised => "zero_initialised"
  | .PNVI .PLAIN => "PNVI"
  | .PNVI .AE => "PNVI_ae"
  | .PNVI .AE_UDI => "PNVI_ae_udi"

def switchReport (switches : List CerbGlobal.CerbSwitch) : String :=
  "cerberus-lean switches: [" ++ String.intercalate "," (switches.map switchName) ++ "]"

end CerbDriverConfig
