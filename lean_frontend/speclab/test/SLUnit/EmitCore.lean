/-
  Unit.EmitCore (speclab) — arc-15 S1: the divmod kernel-instance
  TERM-EMISSION INSTRUMENT.

  ADAPTED, WITH ATTRIBUTION, from the arc-7 S4 root instrument
  lean_frontend/test/Unit/EmitLeanCore.lean (same fidelity contract:
  the printed term is EXACTLY the parsed AST, every literal evaluated
  at emission time; unhandled constructors ERROR LOUDLY, never
  guess). Speclab-owned copy per the package-churn-isolation charter
  decision (D2) — the root instrument stays untouched.

  Additions over the root instrument (S1 dump surface):
    * `Ememop` (PtrValidForDeref — array-subscript deref checks),
    * `PEerror` (std.core params_nth's error arm),
    * function-pointer values (`Cfunction(sym)` → CerbMem.funPtrval),
    * the PARAMETRIC-MAIN emission: the divmod i8 harness main is
      emitted ONCE as a Lean function of the six spliced byte
      literals (c0 c1 e0 e1 e2 e3), derived by a digit-run zip over
      the emissions of THREE pinned instances — any structural
      difference beyond the six known literal triples is a loud
      error. Unit.CoreGateTest pins the parameterization back to all
      four dumps byte-for-byte.

  Usage (from the speclab dir, or repo root):
    speclab-emit-core > SpecLab/DivModCore.lean
-/

import CoreParser

set_option autoImplicit false

namespace SpecLabEmitCore

open CoreParser

/-! ## Small literal printers -/

def ppStr (s : String) : String := s.quote

def ppNat (n : Nat) : String := toString n

def ppInt (n : Int) : String :=
  if n < 0 then s!"({n} : Int)" else s!"({n} : Int)"

def ppBool : Bool → String
  | true => "true" | false => "false"

def ppOpt {α : Type} (pp : α → Except String String) : Option α → Except String String
  | none => pure "none"
  | some x => do pure s!"(some {← pp x})"

def ppList {α : Type} (pp : α → Except String String) (xs : List α) :
    Except String String := do
  let mut parts : List String := []
  for x in xs do
    parts := parts ++ [← pp x]
  pure ("[" ++ String.intercalate ", " parts ++ "]")

def ppProd {α β : Type} (ppa : α → Except String String) (ppb : β → Except String String)
    (p : α × β) : Except String String := do
  pure s!"({← ppa p.1}, {← ppb p.2})"

/-! ## Locations and annotations.
    CoreParser stamps every node with `[Aloc CerbLocation.unknown]`
    (annots0); anything else is out of contract. -/

def ppLoc (l : CerbLocation.Loc) : Except String String :=
  match l with
  | CerbLocation.Loc.unknown => pure "CerbLocation.Loc.unknown"
  | _ => throw "ppLoc: non-unknown location in parsed Core (out of contract)"

def ppAnnot : annot → Except String String
  | Aloc l => do pure s!"(Aloc {← ppLoc l})"
  | _ => throw "ppAnnot: non-Aloc annotation in parsed Core (out of contract)"

def ppAnnots (xs : List annot) : Except String String := ppList ppAnnot xs

/-! ## Symbols -/

def ppSymDesc : symbol_description → Except String String
  | SD_None => pure "SD_None"
  | SD_Id s => pure s!"(SD_Id {ppStr s})"
  | _ => throw "ppSymDesc: unexpected symbol description in parsed Core"

def ppSym : sym → Except String String
  | Symbol dig n desc => do
    pure s!"(Symbol {ppStr dig} {ppNat n} {← ppSymDesc desc})"

def ppIdent : identifier → Except String String
  | Identifier l s => do pure s!"(Identifier {← ppLoc l} {ppStr s})"

/-! ## C types -/

def ppIntegerBaseType : integerBaseType → Except String String
  | Ichar => pure "Ichar" | Short => pure "Short" | Int_ => pure "Int_"
  | Long => pure "Long" | LongLong => pure "LongLong"
  | IntN_t n => pure s!"(IntN_t {ppNat n})"
  | Int_leastN_t n => pure s!"(Int_leastN_t {ppNat n})"
  | Int_fastN_t n => pure s!"(Int_fastN_t {ppNat n})"
  | Intmax_t => pure "Intmax_t" | Intptr_t => pure "Intptr_t"

def ppIntegerType : integerType → Except String String
  | Char0 => pure "Char0" | Bool0 => pure "Bool0"
  | Signed ibt => do pure s!"(Signed {← ppIntegerBaseType ibt})"
  | Unsigned ibt => do pure s!"(Unsigned {← ppIntegerBaseType ibt})"
  | Enum0 s => do pure s!"(Enum0 {← ppSym s})"
  | Wchar_t => pure "Wchar_t" | Wint_t => pure "Wint_t"
  | Size_t => pure "Size_t" | Ptrdiff_t => pure "Ptrdiff_t"
  | Ptraddr_t => pure "Ptraddr_t"

def ppFloatingType : floatingType → Except String String
  | RealFloating Float0 => pure "(RealFloating Float0)"
  | RealFloating Double => pure "(RealFloating Double)"
  | RealFloating LongDouble => pure "(RealFloating LongDouble)"

def ppBasicType : basicType → Except String String
  | Integer ity => do pure s!"(Integer {← ppIntegerType ity})"
  | Floating fty => do pure s!"(Floating {← ppFloatingType fty})"

def ppQualifiers (q : qualifiers) : Except String String :=
  pure s!"(qualifiers.mk {ppBool q.const} {ppBool q.restrict} {ppBool q.volatile})"

mutual
partial def ppCtype_ : ctype_ → Except String String
  | Void0 => pure "Void0"
  | Basic bty => do pure s!"(Basic {← ppBasicType bty})"
  | Array0 ty n => do pure s!"(Array0 {← ppCtype ty} {← ppOpt (fun i => pure (ppInt i)) n})"
  | Pointer q ty => do pure s!"(Pointer {← ppQualifiers q} {← ppCtype ty})"
  | Atomic ty => do pure s!"(Atomic {← ppCtype ty})"
  | Struct s => do pure s!"(Struct {← ppSym s})"
  | Union0 s => do pure s!"(Union0 {← ppSym s})"
  | Byte => pure "Byte"
  | Function ret params var => do
    pure s!"(Function {← ppProd ppQualifiers ppCtype ret} {← ppList (fun (t : qualifiers × ctype × Bool) => do pure s!"({← ppQualifiers t.1}, {← ppCtype t.2.1}, {ppBool t.2.2})") params} {ppBool var})"
  | FunctionNoParams ret => do
    pure s!"(FunctionNoParams {← ppProd ppQualifiers ppCtype ret})"

partial def ppCtype : ctype → Except String String
  | Ctype anns ty => do pure s!"(Ctype {← ppAnnots anns} {← ppCtype_ ty})"
end

/-! ## Core base types, ctors, patterns -/

partial def ppCbt : core_base_type → Except String String
  | BTy_unit => pure "BTy_unit"
  | BTy_boolean => pure "BTy_boolean"
  | BTy_ctype => pure "BTy_ctype"
  | BTy_list t => do pure s!"(BTy_list {← ppCbt t})"
  | BTy_tuple ts => do pure s!"(BTy_tuple {← ppList ppCbt ts})"
  | BTy_object ot => do pure s!"(BTy_object {← ppCot ot})"
  | BTy_loaded ot => do pure s!"(BTy_loaded {← ppCot ot})"
  | BTy_storable => pure "BTy_storable"
where
  ppCot : core_object_type → Except String String
    | OTy_integer => pure "OTy_integer"
    | OTy_floating => pure "OTy_floating"
    | OTy_pointer => pure "OTy_pointer"
    | OTy_array t => do pure s!"(OTy_array {← ppCot t})"
    | OTy_struct s => do pure s!"(OTy_struct {← ppSym s})"
    | OTy_union s => do pure s!"(OTy_union {← ppSym s})"

def ppCtor : ctor → Except String String
  | Cnil t => do pure s!"(Cnil {← ppCbt t})"
  | Ccons => pure "Ccons" | Ctuple => pure "Ctuple" | Carray => pure "Carray"
  | Civmax => pure "Civmax" | Civmin => pure "Civmin"
  | Civsizeof => pure "Civsizeof" | Civalignof => pure "Civalignof"
  | CivCOMPL => pure "CivCOMPL" | CivAND => pure "CivAND"
  | CivOR => pure "CivOR" | CivXOR => pure "CivXOR"
  | Cspecified => pure "Cspecified" | Cunspecified => pure "Cunspecified"
  | Cfvfromint => pure "Cfvfromint" | Civfromfloat => pure "Civfromfloat"
  | CivNULLcap b => pure s!"(CivNULLcap {ppBool b})"

mutual
partial def ppPattern_ : generic_pattern_ sym → Except String String
  | CaseBase (osym, cbt) => do
    pure s!"(CaseBase ({← ppOpt ppSym osym}, {← ppCbt cbt}))"
  | CaseCtor c pats => do
    pure s!"(CaseCtor {← ppCtor c} {← ppList ppPattern pats})"

partial def ppPattern : generic_pattern sym → Except String String
  | Pattern anns p => do pure s!"(Pattern {← ppAnnots anns} {← ppPattern_ p})"
end

/-! ## Values -/

def ppProvenance : CerbMem.Provenance → Except String String
  | .Prov_none => pure "CerbMem.Provenance.Prov_none"
  | _ => throw "ppProvenance: non-Prov_none provenance in parsed Core"

def ppIntegerValue : CerbMem.IntegerValue → Except String String
  | .IV prov n => do pure s!"(CerbMem.IntegerValue.IV {← ppProvenance prov} {ppInt n})"

mutual
partial def ppObjectValue : object_value → Except String String
  | OVinteger iv => do pure s!"(OVinteger {← ppIntegerValue iv})"
  | OVarray lvs => do pure s!"(OVarray {← ppList ppLoadedValue lvs})"
  | OVpointer pv =>
    -- only function-pointer values occur in the pinned dumps
    -- (`Cfunction(sym)` — CoreParser.lean:1255-1268 funPtrval)
    match pv with
    | .PV .Prov_none (.PVfunction s) => do
      pure s!"(OVpointer (CerbMem.funPtrval {← ppSym s}))"
    | _ => throw "ppObjectValue: non-function pointer value in parsed Core"
  | _ => throw "ppObjectValue: unhandled object value in parsed Core"

partial def ppLoadedValue : loaded_value → Except String String
  | LVspecified ov => do pure s!"(LVspecified {← ppObjectValue ov})"
  | LVunspecified ty => do pure s!"(LVunspecified {← ppCtype ty})"

partial def ppValue : value → Except String String
  | Vobject ov => do pure s!"(Vobject {← ppObjectValue ov})"
  | Vloaded lv => do pure s!"(Vloaded {← ppLoadedValue lv})"
  | Vunit => pure "Vunit" | Vtrue => pure "Vtrue" | Vfalse => pure "Vfalse"
  | Vctype ty => do pure s!"(Vctype {← ppCtype ty})"
  | Vlist t vs => do pure s!"(Vlist {← ppCbt t} {← ppList ppValue vs})"
  | Vtuple vs => do pure s!"(Vtuple {← ppList ppValue vs})"
end

/-! ## Undefined behaviours / implementation constants (by need) -/

def ppUB (ub : undefined_behaviour) : Except String String :=
  -- CoreParser mirrors OCaml scan_ub (parsers/core/core_lexer.mll:221-232):
  -- known UB names round-trip through Undefined.ub_str_bimap to their REAL
  -- constructors; only unknown DUMMY(...) spellings remain in the DUMMY
  -- carrier. Emit accordingly: for every nullary bimap constructor the
  -- bimap string IS the constructor name (undefined.lem:840ff), so it is
  -- printed verbatim; the two applied families (UB_std_omission,
  -- UB_CERB004_unspecified) are spelled out; anything not parseable from
  -- Core text errors loudly per the fidelity contract.
  match ub with
  | DUMMY s => pure s!"(DUMMY {s.quote})"
  | UB_std_omission om =>
    let o := match om with
      | UB_OMIT_memcpy_non_object => "UB_OMIT_memcpy_non_object"
      | UB_OMIT_memcpy_out_of_bound => "UB_OMIT_memcpy_out_of_bound"
    pure s!"(UB_std_omission {o})"
  | UB_CERB004_unspecified ctx =>
    let c := match ctx with
      | UB_unspec_equality_ptr_vs_NULL => "UB_unspec_equality_ptr_vs_NULL"
      | UB_unspec_equality_both_arith_or_ptr => "UB_unspec_equality_both_arith_or_ptr"
      | UB_unspec_pointer_add => "UB_unspec_pointer_add"
      | UB_unspec_pointer_sub => "UB_unspec_pointer_sub"
      | UB_unspec_conditional => "UB_unspec_conditional"
      | UB_unspec_copy_alloc_id => "UB_unspec_copy_alloc_id"
      | UB_unspec_rvalue_memberof => "UB_unspec_rvalue_memberof"
      | UB_unspec_memberofptr => "UB_unspec_memberofptr"
      | UB_unspec_do => "UB_unspec_do"
    pure s!"(UB_CERB004_unspecified {c})"
  | ub =>
    match lookupL ub ub_str_bimap with
    | some s => pure s
    | none => throw s!"ppUB: undefined_behaviour not representable in parsed Core"

def ppImplConst : implementation_constant → Except String String
  | Integer__conv_nonrepresentable_signed_integer =>
    pure "Integer__conv_nonrepresentable_signed_integer"
  | Characters__plain_char_is_signed =>
    pure "Characters__plain_char_is_signed"
  | SHR_signed_negative => pure "SHR_signed_negative"
  | Ctype_min => pure "Ctype_min"
  | Ctype_max => pure "Ctype_max"
  | _ => throw "ppImplConst: unhandled implementation constant"

/-! ## Names, binops, pexprs -/

def ppName : generic_name sym → Except String String
  | Sym s => do pure s!"(Sym {← ppSym s})"
  | Impl ic => do pure s!"(Impl {← ppImplConst ic})"

def ppBinop : binop → Except String String
  | OpAdd => pure "OpAdd" | OpSub => pure "OpSub" | OpMul => pure "OpMul"
  | OpDiv => pure "OpDiv" | OpRem_t => pure "OpRem_t" | OpRem_f => pure "OpRem_f"
  | OpExp => pure "OpExp" | OpEq => pure "OpEq" | OpGt => pure "OpGt"
  | OpLt => pure "OpLt" | OpGe => pure "OpGe" | OpLe => pure "OpLe"
  | OpAnd => pure "OpAnd" | OpOr => pure "OpOr"

/-- Integer-op selector of the PEwrapI/PEcatch_exceptional_condition
    builtins (arc-7 S5a: the T2/T5 slate bodies carry
    `catch_exceptional_condition_add`, parsed to
    `PEcatch_exceptional_condition ity IOpAdd` — CoreParser.lean
    pIopFromStr). -/
def ppIop : iop → Except String String
  | IOpAdd => pure "IOpAdd" | IOpSub => pure "IOpSub"
  | IOpMul => pure "IOpMul" | IOpShl => pure "IOpShl"
  | IOpShr => pure "IOpShr" | IOpDiv => pure "IOpDiv"
  | IOpRem_t => pure "IOpRem_t"

mutual
partial def ppPexpr_ : generic_pexpr_ Unit sym → Except String String
  | PEsym s => do pure s!"(PEsym {← ppSym s})"
  | PEimpl ic => do pure s!"(PEimpl {← ppImplConst ic})"
  | PEval v => do pure s!"(PEval {← ppValue v})"
  | PEundef l ub => do pure s!"(PEundef {← ppLoc l} {← ppUB ub})"
  | PEctor c pes => do pure s!"(PEctor {← ppCtor c} {← ppList ppPexpr pes})"
  | PEcase pe arms => do
    pure s!"(PEcase {← ppPexpr pe} {← ppList (ppProd ppPattern ppPexpr) arms})"
  | PEnot pe => do pure s!"(PEnot {← ppPexpr pe})"
  | PEop op pe1 pe2 => do
    pure s!"(PEop {← ppBinop op} {← ppPexpr pe1} {← ppPexpr pe2})"
  | PEconv_int ity pe => do
    pure s!"(PEconv_int {← ppIntegerType ity} {← ppPexpr pe})"
  | PEwrapI ity op pe1 pe2 => do
    pure s!"(PEwrapI {← ppIntegerType ity} {← ppIop op} {← ppPexpr pe1} {← ppPexpr pe2})"
  | PEcatch_exceptional_condition ity op pe1 pe2 => do
    pure s!"(PEcatch_exceptional_condition {← ppIntegerType ity} {← ppIop op} {← ppPexpr pe1} {← ppPexpr pe2})"
  | PEcall nm pes => do pure s!"(PEcall {← ppName nm} {← ppList ppPexpr pes})"
  | PElet pat pe1 pe2 => do
    pure s!"(PElet {← ppPattern pat} {← ppPexpr pe1} {← ppPexpr pe2})"
  | PEif pe1 pe2 pe3 => do
    pure s!"(PEif {← ppPexpr pe1} {← ppPexpr pe2} {← ppPexpr pe3})"
  | PEis_scalar pe => do pure s!"(PEis_scalar {← ppPexpr pe})"
  | PEis_integer pe => do pure s!"(PEis_integer {← ppPexpr pe})"
  | PEis_signed pe => do pure s!"(PEis_signed {← ppPexpr pe})"
  | PEis_unsigned pe => do pure s!"(PEis_unsigned {← ppPexpr pe})"
  | PEare_compatible pe1 pe2 => do
    pure s!"(PEare_compatible {← ppPexpr pe1} {← ppPexpr pe2})"
  | PEcfunction pe => do pure s!"(PEcfunction {← ppPexpr pe})"
  | PEarray_shift pe1 ty pe2 => do
    pure s!"(PEarray_shift {← ppPexpr pe1} {← ppCtype ty} {← ppPexpr pe2})"
  | PEmember_shift pe s i => do
    pure s!"(PEmember_shift {← ppPexpr pe} {← ppSym s} {← ppIdent i})"
  | PEmemberof s i pe => do
    pure s!"(PEmemberof {← ppSym s} {← ppIdent i} {← ppPexpr pe})"
  | PEstruct s fields => do
    pure s!"(PEstruct {← ppSym s} {← ppList (ppProd ppIdent ppPexpr) fields})"
  | PEerror msg pe => do
    pure s!"(PEerror {ppStr msg} {← ppPexpr pe})"
  | _ => throw "ppPexpr_: unhandled pure-expression constructor"

partial def ppPexpr : generic_pexpr Unit sym → Except String String
  | Pexpr anns () pe => do pure s!"(Pexpr {← ppAnnots anns} () {← ppPexpr_ pe})"
end

/-! ## Actions and expressions (a := Unit, bty := Unit) -/

def ppMemOrder : memory_order → Except String String
  | NA => pure "NA"
  | Seq_cst => pure "Seq_cst"
  | _ => throw "ppMemOrder: unhandled memory order"

def ppPolarity : polarity → Except String String
  | Pos => pure "Pos" | Neg0 => pure "Neg0"

def ppKillKind : kill_kind → Except String String
  | Dynamic0 => pure "Dynamic0"
  | Static0 ty => do pure s!"(Static0 {← ppCtype ty})"

def ppAction_ : generic_action_ Unit sym → Except String String
  | Create pe1 pe2 pref => do
    let p ← match pref with
      | PrefOther s => pure s!"(PrefOther {ppStr s})"
      | _ => throw "ppAction_: unhandled prefix"
    pure s!"(Create {← ppPexpr pe1} {← ppPexpr pe2} {p})"
  | Kill kk pe => do pure s!"(Kill {← ppKillKind kk} {← ppPexpr pe})"
  | Store0 b pe1 pe2 pe3 mo => do
    pure s!"(Store0 {ppBool b} {← ppPexpr pe1} {← ppPexpr pe2} {← ppPexpr pe3} {← ppMemOrder mo})"
  | Load0 pe1 pe2 mo => do
    pure s!"(Load0 {← ppPexpr pe1} {← ppPexpr pe2} {← ppMemOrder mo})"
  | _ => throw "ppAction_: unhandled action constructor"

def ppAction : generic_action Unit Unit sym → Except String String
  | Action l a act => do
    let _ : Unit := a
    pure s!"(Action {← ppLoc l} () {← ppAction_ act})"

def ppPaction : generic_paction Unit Unit sym → Except String String
  | Paction p act => do pure s!"(Paction {← ppPolarity p} {← ppAction act})"

mutual
partial def ppExpr_ : generic_expr_ Unit Unit sym → Except String String
  | Epure pe => do pure s!"(Epure {← ppPexpr pe})"
  | Eaction pa => do pure s!"(Eaction {← ppPaction pa})"
  | Ecase pe arms => do
    pure s!"(Ecase {← ppPexpr pe} {← ppList (ppProd ppPattern ppExpr) arms})"
  | Elet pat pe e => do
    pure s!"(Elet {← ppPattern pat} {← ppPexpr pe} {← ppExpr e})"
  | Eif pe e1 e2 => do
    pure s!"(Eif {← ppPexpr pe} {← ppExpr e1} {← ppExpr e2})"
  | Eccall a pe1 pe2 pes => do
    let _ : Unit := a
    pure s!"(Eccall () {← ppPexpr pe1} {← ppPexpr pe2} {← ppList ppPexpr pes})"
  | Eproc a nm pes => do
    let _ : Unit := a
    pure s!"(Eproc () {← ppName nm} {← ppList ppPexpr pes})"
  | Eunseq es => do pure s!"(Eunseq {← ppList ppExpr es})"
  | Ewseq pat e1 e2 => do
    pure s!"(Ewseq {← ppPattern pat} {← ppExpr e1} {← ppExpr e2})"
  | Esseq pat e1 e2 => do
    pure s!"(Esseq {← ppPattern pat} {← ppExpr e1} {← ppExpr e2})"
  | Ebound e => do pure s!"(Ebound {← ppExpr e})"
  | End es => do pure s!"(End {← ppList ppExpr es})"
  | Esave (s, cbt) params e => do
    let ppParam := fun (p : sym × ((core_base_type ×
        Option (ctype × pass_by_value_or_pointer)) ×
        generic_pexpr Unit sym)) => do
      let inner ← ppOpt (fun (q : ctype × pass_by_value_or_pointer) => do
        let pv : String := match q.2 with
          | By_value => "By_value"
          | By_pointer => "By_pointer"
        pure s!"({← ppCtype q.1}, {pv})") p.2.1.2
      pure s!"({← ppSym p.1}, (({← ppCbt p.2.1.1}, {inner}), {← ppPexpr p.2.2}))"
    pure s!"(Esave ({← ppSym s}, {← ppCbt cbt}) {← ppList ppParam params} {← ppExpr e})"
  | Erun a s pes => do
    let _ : Unit := a
    pure s!"(Erun () {← ppSym s} {← ppList ppPexpr pes})"
  | Ememop mo pes => do
    let m ← match mo with
      | PtrValidForDeref => pure "PtrValidForDeref"
      | _ => throw "ppExpr_: unhandled memop kind"
    pure s!"(Ememop {m} {← ppList ppPexpr pes})"
  | _ => throw "ppExpr_: unhandled expression constructor"

partial def ppExpr : generic_expr Unit Unit sym → Except String String
  | Expr anns e => do pure s!"(Expr {← ppAnnots anns} {← ppExpr_ e})"
end

def ppFunMapDecl : generic_fun_map_decl Unit Unit → Except String String
  | Fun cbt params pe => do
    pure s!"(Fun {← ppCbt cbt} {← ppList (ppProd ppSym ppCbt) params} {← ppPexpr pe})"
  | Proc l marker cbt params e => do
    pure s!"(Proc {← ppLoc l} {← ppOpt (fun n => pure (ppNat n)) marker} {← ppCbt cbt} {← ppList (ppProd ppSym ppCbt) params} {← ppExpr e})"
  | _ => throw "ppFunMapDecl: unhandled declaration form"

/-! ## Tag definitions (arc-7 S5a: the T4 slate program's struct
    layout enters the theorem statement through file.tagDefs) -/

/-- A struct/union field entry, exactly as pDefField builds it
    (no_attributes, no alignment, no_qualifiers — CoreParser.lean). -/
def ppFieldEntry (p : identifier × (attributes × Option alignment ×
    qualifiers × ctype)) : Except String String := do
  match p.2 with
  | (Attrs [], none, q, ty) =>
    if q.const || q.restrict || q.volatile then
      throw "ppFieldEntry: qualified field (out of parser contract)"
    else
      pure s!"({← ppIdent p.1}, (no_attributes, (none : Option alignment), no_qualifiers, {← ppCtype ty}))"
  | _ => throw "ppFieldEntry: attributed/aligned field (out of parser contract)"

def ppTagDef : tag_definition → Except String String
  | StructDef fields none => do
    pure s!"(StructDef {← ppList ppFieldEntry fields} none)"
  | StructDef _ (some _) =>
    throw "ppTagDef: flexible array member (out of contract)"
  | UnionDef fields => do
    pure s!"(UnionDef {← ppList ppFieldEntry fields})"

/-! ## Module emission -/

/-- Find a named declaration in a parsed CoreFile (funs + procs). -/
def findDecl (cf : CoreFile) (name : String) :
    Except String (sym × generic_fun_map_decl Unit Unit) :=
  let all := cf.funs ++ cf.procs ++ cf.builtins
  match all.find? (fun kv => match kv.1 with
    | Symbol _ _ (SD_Id n) => n == name
    | _ => false) with
  | some kv => pure kv
  | none => throw s!"declaration '{name}' not found in parsed Core file"

/-- Emit one `def` pair (symbol + declaration) for a named decl. -/
def emitDecl (cf : CoreFile) (name defBase : String) :
    Except String String := do
  let (s, d) ← findDecl cf name
  let symStr ← ppSym s
  let declStr ← ppFunMapDecl d
  pure (s!"/-- `{name}`: symbol, as interned by CoreParser (name-hash id). -/\n" ++
    s!"def {defBase}Sym : sym :=\n  {symStr}\n\n" ++
    s!"/-- `{name}`: the parsed declaration, verbatim. -/\n" ++
    s!"def {defBase}Decl : generic_fun_map_decl Unit Unit :=\n  {declStr}\n")

/-! ## The divmod S1 emission plan -/

/-- The std.core closure the divmod harness's evaluation reaches
(discovered by inspection of the pinned dumps + std bodies; the
CoreGateTest exec checks fail loudly on any missing entry). -/
def stdPlan : List (String × String) :=
  [("conv_loaded_int", "convLoadedInt"),
   ("conv_int", "convInt"),
   ("is_representable_integer", "isReprInteger"),
   ("catch_exceptional_condition", "catchExceptional"),
   ("wrapI", "wrapI"),
   ("params_length", "paramsLength"),
   ("params_length_aux", "paramsLengthAux"),
   ("params_nth", "paramsNth")]

/-! ## The parametric-main derivation (digit-run zip).

The three pinned healthy instances a=(7,2), b=(-5,3), d=(-6,3) have
STRUCTURALLY IDENTICAL emitted mains differing only at the six
spliced byte literals (choices c0 c1; expected e0 e1 e2 e3, i16le
q ++ i16le r). The instances are chosen so the six (a,b,d) value
triples are pairwise distinct — the zip below therefore assigns each
literal site its parameter name unambiguously, and ANY other
difference is a loud error. -/

/-- Alternating same-class character runs (digit vs non-digit). -/
partial def charRuns (s : String) : List (Bool × String) :=
  go s.toList
where
  go : List Char → List (Bool × String)
    | [] => []
    | c :: rest =>
      let isD := c.isDigit
      let run := (c :: rest).takeWhile (fun c' => c'.isDigit == isD)
      let remainder := (c :: rest).dropWhile (fun c' => c'.isDigit == isD)
      (isD, run.foldl (fun acc ch => acc.push ch) "") :: go remainder

/-- (valueA, valueB, valueD) → parameter name, for the six splice
sites of the pinned instance trio. -/
def paramTable : List ((String × String × String) × String) :=
  [(("7", "251", "250"), "c0"), (("2", "3", "3"), "c1"),
   (("3", "255", "254"), "e0"), (("0", "255", "255"), "e1"),
   (("1", "254", "0"), "e2"), (("0", "255", "0"), "e3")]

/-- Zip the three emitted main texts into the parametric body. -/
def zipParamMain (ta tb td : String) : Except String String := do
  let ra := charRuns ta
  let rb := charRuns tb
  let rd := charRuns td
  if ra.length ≠ rb.length || ra.length ≠ rd.length then
    throw s!"zipParamMain: run-count mismatch ({ra.length}/{rb.length}/{rd.length})"
  let mut out := ""
  let mut seen : List String := []
  for ((da, va), (db, vb), (dd, vd)) in ra.zip (rb.zip rd) do
    if da ≠ db || da ≠ dd then
      throw "zipParamMain: run-class mismatch"
    if va == vb && va == vd then
      out := out ++ va
    else if da then
      match paramTable.find? (fun e => e.1 == (va, vb, vd)) with
      | some e =>
        -- the literal prints as `(N : Int)`; substituting the digits
        -- yields `(c0 : Int)` — type-correct, kernel-transparent
        out := out ++ e.2
        seen := seen ++ [e.2]
      | none => throw s!"zipParamMain: unknown literal triple ({va},{vb},{vd})"
    else
      throw s!"zipParamMain: non-digit divergence ({va} vs {vb} vs {vd})"
  if seen.length ≠ 6 then
    throw s!"zipParamMain: expected exactly 6 parameter sites, found {seen} "
  pure out

/-! ## Module emission -/

def moduleHeader : String :=
"/-
  SpecLab.DivModCore — GENERATED by speclab-emit-core (arc-15 S1).
  DO NOT EDIT.

  Kernel-transparent Lean terms for the divmod i8 kernel-instance
  harness family: division/mod (the CN targets, elaborated) + the
  PARAMETRIC main (a function of the six spliced byte literals,
  derived by the emitter's digit-run zip over the pinned instances
  a=(7,2), b=(-5,3), d=(-6,3) — tests/speclab/divmod_i8_{a,b,d}.core),
  the wrong-operator PLANT trio (tests/speclab/divmod_i8_plant.core,
  verbatim), and the reached std.core closure — exactly as CoreParser
  produces them (fidelity contract of Unit.EmitCore).

  Drift gate: Unit.CoreGateTest re-parses the pinned inputs, re-emits
  this module byte-for-byte, pins the parametric main back to ALL
  FOUR pinned dumps (incl. c=(-128,-1)), and runs the assembled files
  through the generated `drive` at the pinned verdicts. Regenerate:
    .lake/build/bin/speclab-emit-core > SpecLab/DivModCore.lean
-/

import Core

set_option autoImplicit false

namespace SpecLab.DivModCore

"

def moduleFooter : String := "\nend SpecLab.DivModCore\n"

/-- Find a named decl's pp text (used for the equal-across-dumps
assertions). -/
def declText (cf : CoreFile) (name : String) : Except String String := do
  let (_, d) ← findDecl cf name
  ppFunMapDecl d

def emitDivModModule (dumpA dumpB dumpD dumpPlant stdText : String) :
    Except String String := do
  let cfA ← CoreParser.parseFile dumpA
  let cfB ← CoreParser.parseFile dumpB
  let cfD ← CoreParser.parseFile dumpD
  let cfP ← CoreParser.parseFile dumpPlant
  let std ← CoreParser.parseFile stdText
  -- the targets must be literally identical across the healthy dumps
  for n in ["division", "mod"] do
    let t ← declText cfA n
    if (← declText cfB n) ≠ t || (← declText cfD n) ≠ t then
      throw s!"emitDivModModule: '{n}' differs across healthy dumps"
  -- the parametric main
  let (mainSymA, mainDeclA) ← findDecl cfA "main"
  let ta ← ppFunMapDecl mainDeclA
  let tb ← declText cfB "main"
  let td ← declText cfD "main"
  let pmain ← zipParamMain ta tb td
  let mut out := moduleHeader
  out := out ++ (← emitDecl cfA "division" "division") ++ "\n"
  out := out ++ (← emitDecl cfA "mod" "modFn") ++ "\n"
  out := out ++ s!"/-- `main`: symbol, as interned by CoreParser. -/\n"
  out := out ++ s!"def mainSym : sym :=\n  {← ppSym mainSymA}\n\n"
  out := out ++ "/-- `main`, PARAMETRIC in the six spliced byte literals\n(see the module header). `mainParamDecl 7 2 3 0 1 0` is the parsed\nmain of the pinned instance a, byte-for-byte (Unit.CoreGateTest). -/\n"
  out := out ++ s!"def mainParamDecl (c0 c1 e0 e1 e2 e3 : Int) : generic_fun_map_decl Unit Unit :=\n  {pmain}\n\n"
  out := out ++ (← emitDecl cfP "division" "divisionPlant") ++ "\n"
  out := out ++ (← emitDecl cfP "mod" "modFnPlant") ++ "\n"
  out := out ++ (← emitDecl cfP "main" "mainPlant") ++ "\n"
  for (name, base) in stdPlan do
    out := out ++ (← emitDecl std name base) ++ "\n"
  pure (out ++ moduleFooter)

def findRoot : IO String := do
  for dir in ["", "../", "../../", "../../../"] do
    if ← System.FilePath.pathExists
        (dir ++ "tests/speclab/divmod_i8_a.core") then
      return dir
  throw (IO.Error.userError
    "speclab-emit-core: run from the repo root or the speclab dir \
     (tests/speclab/divmod_i8_a.core not found)")

def readInputs : IO (String × String × String × String × String) := do
  let root ← findRoot
  let a ← IO.FS.readFile (root ++ "tests/speclab/divmod_i8_a.core")
  let b ← IO.FS.readFile (root ++ "tests/speclab/divmod_i8_b.core")
  let d ← IO.FS.readFile (root ++ "tests/speclab/divmod_i8_d.core")
  let pl ← IO.FS.readFile (root ++ "tests/speclab/divmod_i8_plant.core")
  let std ← IO.FS.readFile (root ++ "runtime/libcore/std.core")
  pure (a, b, d, pl, std)

end SpecLabEmitCore
