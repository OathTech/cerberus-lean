/-
  Pretty-printing functions for Cerberus types.
  Corresponds to: ocaml_frontend/pprinters/ (pp_core.ml, pp_ail.ml, etc.)

  Arc-10 S3 (pp-placeholder text class): the corpus-reaching printers are
  now REAL MIRRORS of the OCaml printers, with file:line citations at
  every definition. The ctype/symbol/mem-value sub-printers live in
  CerbMem.lean (import-graph placement note there); this module hosts the
  Core-value layer (pp_core.ml) and delegates the rest.

  What is still a placeholder is the ENUMERATED RESIDUAL of the
  pretty-printer arc, kept in the "Residual placeholders" section at the
  bottom with a per-function reason. All residual output shapes are
  "<...>"-bracketed so a residual leaking into compared text stays an
  honest mismatch (never accidentally oracle-shaped).
-/

import Core

namespace CerbPP

-- Generic pretty-print: uses Repr if available, otherwise "<unknown>"
def ppRepr {α : Type} [inst : Repr α] (x : α) : String :=
  (repr x).pretty

-- (sem:N14) The generic `ppAny := "<...>"` escape hatch was DELETED in
-- arc-14 S1 F6 — it had zero call sites, and the enumerated
-- pp-placeholder register (below / CerbPP throughout) is the only
-- sanctioned placeholder discipline. Reintroducing a catch-all is a
-- finding: every placeholder must be a reasoned, enumerated entry.

/-! ## Symbol pretty-printing (real mirrors) -/

/-- Mirrors String_symbol.string_of_prefix = Pp_symbol.pp_prefix
    (pp_symbol.ml:80-94). -/
def stringFromSymbol_prefix : prefix0 → String
  | .PrefSource _ syms =>
    "{" ++ String.intercalate "." (syms.map CerbMem.ppSymbol) ++ "}"
  | .PrefOther str => "{" ++ str ++ "}"
  | .PrefStringLiteral _ _ => "{string literal}"
  | .PrefTemporaryLifetime _ _ => "{rvalue temporary}"
  | .PrefFunArg _ _ n => "{arg" ++ toString n ++ "}"
  | .PrefMalloc => "{malloc'd}"
  | .PrefCompoundLiteral _ _ => "{compound literal}"

/-! ## ctype pretty-printing (real mirrors, shared impl in CerbMem) -/

/-- Mirrors String_core_ctype.string_of_ctype (string_core_ctype.ml:4-5)
    = Pp_core_ctype.pp_ctype — the lem referents are
    defacto_memory.lem:18-23 and formatted.lem:345-348. -/
def stringFromCtype (ty : ctype) : String := CerbMem.ppCtype ty

/-- Same OCaml referent as stringFromCtype (pp.lem:69-70,
    defacto_memory_aux.lem:65-66 both declare
    `String_core_ctype.string_of_ctype`). -/
def stringFromCore_ctype (ty : ctype) : String := CerbMem.ppCtype ty

/-! ## Core value pretty-printing (real mirrors of pp_core.ml)

All plain text: the mirrored paths run under Cerb_colour.without_colour
(driver_ocaml.ml:79) or compare-free diagnostics, so the ANSI wrappers
in pp_core.ml (pp_datactor etc., pp_core.ml:167-173) are identity. -/

mutual
/-- Mirrors Pp_core.pp_object_value (pp_core.ml:276-302). -/
def ppObjectValue : object_value → String
  | .OVinteger ival =>
    -- Impl_mem.pp_integer_value_for_core = pp_integer_value (impl_mem.ml:582)
    CerbMem.stringFromIntegerValue ival
  | .OVfloating fval =>
    -- pp_core.ml:279-282 case_fval; the concrete model's floating_value is
    -- a raw float so the unspec branch is unreachable → string_of_float
    CerbFloat.string_of_float fval
  | .OVpointer ptrval =>
    -- Impl_mem.pp_pointer_value (impl_mem.ml:563-572)
    CerbMem.stringFromPointerValue ptrval
  | .OVarray lvals =>
    -- pp_core.ml:289-290 (P.nest is layout-only; plain text keeps one line)
    "Array(" ++ ppLoadedValueList lvals ++ ")"
  | .OVstruct tagSym xs =>
    -- pp_core.ml:292-297; member shape ".m= v" incl. the `equals ^^^` space
    "(struct " ++ CerbMem.ppSymbol tagSym ++ "){" ++ ppStructMembers xs ++ "}"
  | .OVunion tagSym ident mval =>
    -- pp_core.ml:298-302
    "(union " ++ CerbMem.ppSymbol tagSym ++ "){." ++ CerbMem.ppIdentifier ident
      ++ "= " ++ CerbMem.stringFromMemValue mval ++ "}"

/-- Mirrors Pp_core.pp_loaded_value (pp_core.ml:304-308) — note the
    squotes around the Unspecified payload. -/
def ppLoadedValue : loaded_value → String
  | .LVspecified oval => "Specified(" ++ ppObjectValue oval ++ ")"
  | .LVunspecified ty => "Unspecified('" ++ CerbMem.ppCtype ty ++ "')"

/-- Mirrors Pp_core.pp_value (pp_core.ml:311-336). -/
def stringFromCore_value : value → String
  | .Vunit => "Unit"
  | .Vtrue => "True"
  | .Vfalse => "False"
  | .Vlist _ cvals => "[" ++ ppValueList cvals ++ "]"
  | .Vtuple cvals => "(" ++ ppValueList cvals ++ ")"
  | .Vctype ty =>
    -- DELIBERATE DIVERGENCE (documented): OCaml prints
    -- squotes(Pp_ail.pp_ctype no_qualifiers ty) — the human C-syntax
    -- printer (pp_core.ml:331-332). The Ail declarator printer is the
    -- registered pretty-printer-arc residual; until it exists we print
    -- the Pp_core_ctype text inside the same squotes. Debug/OtherValue
    -- path only — never reaches compared batch verdicts (main returns int).
    "'" ++ CerbMem.ppCtype ty ++ "'"
  | .Vobject oval => ppObjectValue oval
  | .Vloaded lval => ppLoadedValue lval

/-- comma_list pp_loaded_value (pp_core.ml:290). -/
def ppLoadedValueList : List loaded_value → String
  | [] => ""
  | [lv] => ppLoadedValue lv
  | lv :: rest => ppLoadedValue lv ++ ", " ++ ppLoadedValueList rest

/-- comma_list pp_value (pp_core.ml:328-330). -/
def ppValueList : List value → String
  | [] => ""
  | [v] => stringFromCore_value v
  | v :: rest => stringFromCore_value v ++ ", " ++ ppValueList rest

/-- comma_list over struct members (pp_core.ml:293-297): ".m= v". -/
def ppStructMembers : List (identifier × ctype × CerbMem.MemValue) → String
  | [] => ""
  | [(ident, _, mval)] =>
    "." ++ CerbMem.ppIdentifier ident ++ "= " ++ CerbMem.stringFromMemValue mval
  | (ident, _, mval) :: rest =>
    "." ++ CerbMem.ppIdentifier ident ++ "= " ++ CerbMem.stringFromMemValue mval
      ++ ", " ++ ppStructMembers rest
end

/-- Mirrors Pp_core.pp_core_object_type (pp_core.ml:177-189);
    struct/union tags print via Pp_symbol.to_string (NOT to_string_pretty). -/
def ppCoreObjectType : core_object_type → String
  | .OTy_integer => "integer"
  | .OTy_floating => "floating"
  | .OTy_pointer => "pointer"
  | .OTy_array bty => "array(" ++ ppCoreObjectType bty ++ ")"
  | .OTy_struct s => "struct " ++ CerbMem.ppSymbolRaw s
  | .OTy_union s => "union " ++ CerbMem.ppSymbolRaw s

mutual
/-- Mirrors Pp_core.pp_core_base_type (pp_core.ml:191-207) — note
    BTy_tuple separates with a bare comma (P.separate_map P.comma,
    pp_core.ml:206-207), unlike the ", " comma_list elsewhere. -/
def stringFromCore_core_base_type : core_base_type → String
  | .BTy_storable => "storable"
  | .BTy_object bty => ppCoreObjectType bty
  | .BTy_loaded bty => "loaded " ++ ppCoreObjectType bty
  | .BTy_boolean => "boolean"
  | .BTy_ctype => "ctype"
  | .BTy_unit => "unit"
  | .BTy_list bTy => "[" ++ stringFromCore_core_base_type bTy ++ "]"
  | .BTy_tuple bTys => "(" ++ ppCoreBaseTypeList bTys ++ ")"

def ppCoreBaseTypeList : List core_base_type → String
  | [] => ""
  | [bTy] => stringFromCore_core_base_type bTy
  | bTy :: rest => stringFromCore_core_base_type bTy ++ "," ++ ppCoreBaseTypeList rest
end

/-! ## Memory model pretty-printing (real mirrors, impl in CerbMem) -/

/-- Mirrors String_mem.string_of_mem_value (string_mem.ml:4-12)
    = Impl_mem.pp_mem_value, colour off. -/
def stringFromMemValue (mval : CerbMem.MemValue) : String :=
  CerbMem.stringFromMemValue mval

/-- Same OCaml referent (pp.lem:104-107 declares
    String_mem.string_of_mem_value). -/
def stringFromMem_mem_value (mval : CerbMem.MemValue) : String :=
  CerbMem.stringFromMemValue mval

/-- Mirrors String_mem.string_of_pointer_value (string_mem.ml:23-24) —
    which IGNORES its is_verbose argument (always passes
    ~is_verbose:false to Impl_mem.pp_pointer_value); mirrored as-is. -/
def stringFromPointerValue (_isVerbose : Bool) (ptrval : CerbMem.PointerValue) : String :=
  CerbMem.stringFromPointerValue ptrval

/-- Mirrors Decode.format_string_of_float (decode.ml:228-232):
    Printf.sprintf "%.<prec>f" — exact impl in CerbFloat.formatFixed. -/
def format_string_of_float (prec : Nat) (f : Float) : String :=
  CerbFloat.formatFixed prec f

/-! ## Residual placeholders — the ENUMERATED pretty-printer-arc residual

Each entry keeps its lem-target_rep signature and a "<...>"-bracketed
output (never oracle-shaped). Reasons:
  [AIL]     needs the Pp_ail human C-declarator printer (precedence,
            qualifiers) — the future pretty-printer arc's core deliverable;
            all call sites are frontend diagnostics, never compared.
  [CORE-PP] needs the full Core expression printer (pp_core.ml pp_pexpr/
            pp_expr/pp_file) — same future arc; test_elab.sh documents the
            signature-level granularity limitation this leaves.
  [CABS]    String_cabs printers; desugar diagnostics only.
  [DEFACTO] prints the DEFACTO memory model's symbolic types
            (String_defacto_memory); the defacto model is dead code in
            this pipeline (concrete model only) — these keep polymorphic
            signatures because their argument types are defacto-internal.
  [CMM]     concurrency boundary (declared TEMPORAL boundary; mover =
            concurrency arc).
  [PRETTY]  Impl_mem.pp_pretty_mem_value human/decimal form (distinct
            from pp_mem_value); no generated caller today. -/

def stringFromCabs_type_specifier {α : Type} (_ : α) : String := "<type_specifier>"        -- [CABS]
def stringFromCabs_pointer_declarator {α : Type} (_ : α) : String := "<pointer_declarator>" -- [CABS]
def stringFromCabs_declarator {α : Type} (_ : α) : String := "<declarator>"                 -- [CABS]

def stringFromAil_genType {α : Type} (_ : α) : String := "<ail_genType>"                    -- [AIL]
def stringFromAil_statement {α : Type} (_ : α) : String := "<ail_statement>"                -- [AIL]
def stringFromAil_qualifiers {α : Type} (_ : α) : String := "<ail_qualifiers>"              -- [AIL]
def stringFromAil_ctype {α β : Type} (_ : α) (_ : β) : String := "<ail_ctype>"              -- [AIL]
def stringFromAil_expression {α : Type} (_ : α) : String := "<ail_expression>"              -- [AIL]
def stringFromAil_human_ctype {α β : Type} (_ : α) (_ : β) : String := "<ail_human_ctype>"  -- [AIL]

def stringFromCore_action {α : Type} (_ : α) : String := "<core_action>"                    -- [CORE-PP]
def stringFromCore_pexpr {α : Type} (_ : α) : String := "<core_pexpr>"                      -- [CORE-PP]
def stringFromCore_expr {α : Type} (_ : α) : String := "<core_expr>"                        -- [CORE-PP]
def stringFromCore_params {α : Type} (_ : α) : String := "<core_params>"                    -- [CORE-PP]
def stringFromCore_file {α : Type} (_ : α) : String := "<core_file>"                        -- [CORE-PP]
def stringFromCore_core_state {α : Type} (_ : α) : String := "<core_state>"                 -- [CORE-PP]
def pp_exeState {α : Type} (_ : α) : String := "<exe_state>"                                -- [CORE-PP]
def pp_pexpr {α : Type} (_ : α) : String := "<pexpr>"                                       -- [CORE-PP]

def stringFromMem_iv_mem_constraint {α : Type} (_ : α) : String := "<iv_mem_constraint>"    -- [PRETTY] (Pp_mem.pp_mem_constraint over pretty integer values)
def pretty_stringFromMem_mem_value {α : Type} (_ : α) : String := "<mem_value>"             -- [PRETTY]

def stringFromInteger_value {α : Type} (_ : α) : String := "<integer_value>"                -- [DEFACTO]
def stringFromPointer_value {α : Type} (_ : α) : String := "<pointer_value>"                -- [DEFACTO]
def stringFromMem_value {α : Type} (_ : α) : String := "<mem_value>"                        -- [DEFACTO]
def stringFromShift_path {α : Type} (_ : α) : String := "<shift_path>"                      -- [DEFACTO]

def stringFromCmm_op_symState {α : Type} (_ : α) : String := "<cmm_symState>"               -- [CMM]
def stringFromSequenceGraph {α : Type} (_ : α) : String := "<sequence_graph>"               -- [CMM]

end CerbPP
