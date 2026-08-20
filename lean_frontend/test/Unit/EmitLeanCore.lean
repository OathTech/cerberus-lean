/-
  Unit.EmitLeanCore — arc-7 S4 (2026-08-20): THE TERM-EMISSION INSTRUMENT.

  Prints CoreParser-parsed Core declarations as LEAN SOURCE TERMS.
  Why it exists (S4 record §6.1): slate theorem statements need the
  compiled Core program as a kernel-TRANSPARENT Lean term. The Lean
  frontend draws fresh symbols through the `CerberusFresh.forceIO`
  boundary axiom, and CoreParser is built from `partial def`s — both
  are opaque to the kernel — so neither can MATERIALIZE the term
  in-logic. This instrument runs the (compiled) parser at TOOL TIME and
  prints the resulting AST as constructor literals; the committed
  output (relsem/RelSem/T1Core.lean) is drift-gated by
  Unit.EmitLeanCoreTest, which re-parses the pinned inputs, re-emits,
  and compares byte-for-byte.

  FIDELITY CONTRACT: the printed term is EXACTLY the parsed AST —
  every literal (including the name-hash symbol ids `mkSym` computes)
  is evaluated at emission time and printed as a numeral/string, so
  the term needs no opaque function calls to reduce. Unhandled
  constructors ERROR LOUDLY (Except), never guess.

  Scope: what tests/verify/t1_id.core + the T1 stdlib closure
  (conv_loaded_int / conv_int / is_representable_integer /
  catch_exceptional_condition from runtime/libcore/std.core) exercise.
  Extending to new constructors = adding match arms (the growth path to
  whole-linked-file emission is the S4 record §8 register item).

  Usage (from the repo root):
    .lake/build/bin/emit-lean-core            # prints the T1Core module
-/

import CoreParser

set_option autoImplicit false

namespace EmitLeanCore

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
  -- CoreParser wraps every parsed UB name in the DUMMY carrier
  -- (CoreParser.lean:1065) — its payload string is what the driver
  -- prints; keep parser fidelity and emit exactly that.
  match ub with
  | DUMMY s => pure s!"(DUMMY {s.quote})"
  | _ => throw s!"ppUB: non-DUMMY undefined_behaviour in parsed Core"

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

/-- The declarations the T1 slice pins: `id` from the t1 dump; the
    `conv_loaded_int` closure from std.core. `catch_exceptional_condition`
    rides along (it is the UB-surfacing arm T2's instances hit). -/
def t1Plan : List (String × String) :=
  [("id", "idT1")]

def stdPlan : List (String × String) :=
  [("conv_loaded_int", "convLoadedInt"),
   ("conv_int", "convInt"),
   ("is_representable_integer", "isReprInteger"),
   ("catch_exceptional_condition", "catchExceptional")]

def header : String :=
"/-
  RelSem.T1Core — GENERATED by emit-lean-core (arc-7 S4). DO NOT EDIT.

  Kernel-transparent Lean terms for the T1 slate program: the parsed
  AST of tests/verify/t1_id.core (the pinned oracle Core dump of
  tests/verify/t1_id.c) and the conv_loaded_int closure of
  runtime/libcore/std.core, exactly as CoreParser produces them
  (symbol ids are the name-hash literals mkSym computes; locations are
  CerbLocation.Loc.unknown; every node annotation is the parser's
  [Aloc unknown]).

  Drift gate: Unit.EmitLeanCoreTest re-parses the pinned inputs,
  re-emits this module, and compares byte-for-byte — plus runs the
  assembled file (RelSem/T1File.lean) on concrete points against the
  recorded spec. Regenerate with:
    .lake/build/bin/emit-lean-core > relsem/RelSem/T1Core.lean
-/

import Core

set_option autoImplicit false

namespace RelSem.T1

"

def footer : String := "\nend RelSem.T1\n"

def emitModule (t1Text stdText : String) : Except String String := do
  let t1 ← CoreParser.parseFile t1Text
  let std ← CoreParser.parseFile stdText
  let mut out := header
  for (name, base) in t1Plan do
    out := out ++ (← emitDecl t1 name base) ++ "\n"
  for (name, base) in stdPlan do
    out := out ++ (← emitDecl std name base) ++ "\n"
  pure (out ++ footer)

def findRoot : IO String := do
  for dir in ["", "../", "../../"] do
    if ← System.FilePath.pathExists (dir ++ "tests/verify/t1_id.core") then
      return dir
  throw (IO.Error.userError
    "emit-lean-core: run from the repo root (tests/verify/t1_id.core not found)")

def readInputs : IO (String × String) := do
  let root ← findRoot
  let t1 ← IO.FS.readFile (root ++ "tests/verify/t1_id.core")
  let std ← IO.FS.readFile (root ++ "runtime/libcore/std.core")
  pure (t1, std)

/-! ## The slate module (arc-7 S5a): T2–T5 program terms.
    Same contract as the T1 module; one generated module for the four
    remaining slate fixtures (designated functions only — `main` is
    never read by `callND`), plus T4's struct tag definition. -/

/-- Emit one tagDef pair (symbol + located definition) for a named tag. -/
def emitTagDef (cf : CoreFile) (name defBase : String) :
    Except String String := do
  match cf.tagDefs.find? (fun kv => match kv.1 with
    | Symbol _ _ (SD_Id n) => n == name
    | _ => false) with
  | none => throw s!"tag definition '{name}' not found in parsed Core file"
  | some (s, (l, td)) => do
    pure (s!"/-- `struct {name}`: tag symbol, as interned by CoreParser. -/\n" ++
      s!"def {defBase}Sym : sym :=\n  {← ppSym s}\n\n" ++
      s!"/-- `struct {name}`: the parsed tag definition, verbatim. -/\n" ++
      s!"def {defBase}Def : CerbLocation.Loc × tag_definition :=\n  ({← ppLoc l}, {← ppTagDef td})\n")

/-- fixture-stem → (function name, def base, needs-tagDef?) -/
def slatePlan : List (String × String × String) :=
  [("t2_add", "add", "addT2"),
   ("t3_roundtrip", "roundtrip", "roundtripT3"),
   ("t4_struct_member", "memb", "membT4"),
   ("t5_sum", "sum", "sumT5")]

def slateHeader : String :=
"/-
  RelSem.SlateCore — GENERATED by emit-lean-core slate (arc-7 S5a).
  DO NOT EDIT.

  Kernel-transparent Lean terms for the T2–T5 slate programs: the
  parsed ASTs of the designated functions of
  tests/verify/{t2_add,t3_roundtrip,t4_struct_member,t5_sum}.core
  (the pinned oracle Core dumps of the .c fixtures), plus the `struct
  S` tag definition T4's file carries, exactly as CoreParser produces
  them (same fidelity contract as RelSem/T1Core.lean; `main` is
  deliberately not emitted — `callND` never reads it).

  Drift gate: Unit.EmitLeanCoreTest re-parses the pinned inputs,
  re-emits this module, and compares byte-for-byte. Regenerate with:
    .lake/build/bin/emit-lean-core slate > relsem/RelSem/SlateCore.lean
-/

import Core

set_option autoImplicit false

namespace RelSem.Slate

"

def slateFooter : String := "\nend RelSem.Slate\n"

def emitSlateModule (texts : List (String × String)) :
    Except String String := do
  let mut out := slateHeader
  for (stem, fname, base) in slatePlan do
    match texts.find? (fun p => p.1 == stem) with
    | none => throw s!"emitSlateModule: no input text for {stem}"
    | some (_, text) =>
      let cf ← CoreParser.parseFile text
      out := out ++ (← emitDecl cf fname base) ++ "\n"
      if stem == "t4_struct_member" then
        out := out ++ (← emitTagDef cf "S" "structS") ++ "\n"
  pure (out ++ slateFooter)

def readSlateInputs : IO (List (String × String)) := do
  let root ← findRoot
  slatePlan.mapM (fun (stem, _, _) => do
    let text ← IO.FS.readFile (root ++ s!"tests/verify/{stem}.core")
    pure (stem, text))

end EmitLeanCore
