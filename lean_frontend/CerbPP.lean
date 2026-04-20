/-
  Pretty-printing functions for Cerberus types.
  Corresponds to: ocaml_frontend/pprinters/ (pp_core.ml, pp_ail.ml, etc.)

  Most functions are still stubs matching the Lem polymorphic target_rep
  signatures, but a few key ones (notably stringFromCore_value) have real
  implementations so diagnostics like "PEcase, mismatched" can show what
  value was actually seen.
-/

import Core

namespace CerbPP

-- Generic pretty-print: uses Repr if available, otherwise "<unknown>"
def ppRepr {α : Type} [inst : Repr α] (x : α) : String :=
  (repr x).pretty

def ppAny {α : Type} (_ : α) : String := "<...>"

/-! ## Symbol pretty-printing -/
def stringFromSymbol_prefix {α : Type} (_ : α) : String := "<prefix>"

/-! ## Cabs (C abstract syntax) pretty-printing -/
def stringFromCabs_type_specifier {α : Type} (_ : α) : String := "<type_specifier>"
def stringFromCabs_pointer_declarator {α : Type} (_ : α) : String := "<pointer_declarator>"
def stringFromCabs_declarator {α : Type} (_ : α) : String := "<declarator>"

/-! ## AIL pretty-printing -/
def stringFromAil_genType {α : Type} (_ : α) : String := "<ail_genType>"
def stringFromAil_statement {α : Type} (_ : α) : String := "<ail_statement>"
def stringFromAil_qualifiers {α : Type} (_ : α) : String := "<ail_qualifiers>"
def stringFromAil_ctype {α β : Type} (_ : α) (_ : β) : String := "<ail_ctype>"
def stringFromAil_expression {α : Type} (_ : α) : String := "<ail_expression>"
def stringFromAil_human_ctype {α β : Type} (_ : α) (_ : β) : String := "<ail_human_ctype>"

/-! ## Core IR pretty-printing -/
def stringFromCore_action {α : Type} (_ : α) : String := "<core_action>"
def stringFromCore_ctype {α : Type} (_ : α) : String := "<core_ctype>"
def stringFromCore_core_base_type {α : Type} (_ : α) : String := "<core_base_type>"
/-- Minimal pretty-printer for Core values. Surfaces just enough structure
    to diagnose evaluator errors (e.g. PEcase pattern mismatches). -/
partial def stringFromCore_value : value → String
  | .Vunit => "Unit"
  | .Vtrue => "True"
  | .Vfalse => "False"
  | .Vobject _ => "<Vobject>"
  | .Vloaded lv =>
    match lv with
    | .LVspecified _ => "Vloaded(Specified(<ov>))"
    | .LVunspecified _ => "Vloaded(Unspecified(<ty>))"
  | .Vctype _ => "<Vctype>"
  | .Vlist _ vs => "Vlist[" ++ (vs.map stringFromCore_value).foldl (fun a b => a ++ ", " ++ b) "" ++ "]"
  | .Vtuple vs => "Vtuple(" ++ (vs.map stringFromCore_value).foldl (fun a b => a ++ ", " ++ b) "" ++ ")"
def stringFromCore_pexpr {α : Type} (_ : α) : String := "<core_pexpr>"
def stringFromCore_expr {α : Type} (_ : α) : String := "<core_expr>"
def stringFromCore_params {α : Type} (_ : α) : String := "<core_params>"
def stringFromCore_file {α : Type} (_ : α) : String := "<core_file>"
def stringFromCore_core_state {α : Type} (_ : α) : String := "<core_state>"
def pp_exeState {α : Type} (_ : α) : String := "<exe_state>"
def pp_pexpr {α : Type} (_ : α) : String := "<pexpr>"

/-! ## Memory model pretty-printing -/
def stringFromMem_mem_value {α : Type} (_ : α) : String := "<mem_value>"
def pretty_stringFromMem_mem_value {α : Type} (_ : α) : String := "<mem_value>"
def stringFromMem_iv_mem_constraint {α : Type} (_ : α) : String := "<iv_mem_constraint>"
def stringFromCtype {α : Type} (_ : α) : String := "<ctype>"
def stringFromQualifiers {α : Type} (_ : α) : String := "<qualifiers>"
def stringFromInteger_value {α : Type} (_ : α) : String := "<integer_value>"
def stringFromPointer_value {α : Type} (_ : α) : String := "<pointer_value>"
def stringFromMem_value {α : Type} (_ : α) : String := "<mem_value>"
def stringFromShift_path {α : Type} (_ : α) : String := "<shift_path>"
def stringFromMemValue {α : Type} (_ : α) : String := "<mem_value>"
def stringFromPointerValue {α β : Type} (_ : α) (_ : β) : String := "<pointer_value>"
def format_string_of_float {α β : Type} (_ : α) (_ : β) : String := "<float>"

/-! ## Concurrency model pretty-printing -/
def stringFromCmm_op_symState {α : Type} (_ : α) : String := "<cmm_symState>"
def stringFromSequenceGraph {α : Type} (_ : α) : String := "<sequence_graph>"

end CerbPP
