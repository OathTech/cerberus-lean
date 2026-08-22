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
    -- function-pointer values (`Cfunction(sym)` — CoreParser.lean
    -- funPtrval) and, since S3 (the list rung's `xs == 0` /
    -- `p->tail = 0` null comparisons/stores), null pointer values
    -- (`NULL(ty)` — CoreParser.lean nullPtrval)
    match pv with
    | .PV .Prov_none (.PVfunction s) => do
      pure s!"(OVpointer (CerbMem.funPtrval {← ppSym s}))"
    | .PV .Prov_none (.PVnull ty) => do
      pure s!"(OVpointer (CerbMem.nullPtrval {← ppCtype ty}))"
    | _ => throw "ppObjectValue: unhandled pointer value in parsed Core"
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
  | Alloc0 pe1 pe2 pref => do
    -- S3 surface: `alloc(align, size)` in the std.core malloc_proxy
    -- body (CoreParser.lean pActionAlloc — PrefOther \"Core\")
    let p ← match pref with
      | PrefOther s => pure s!"(PrefOther {ppStr s})"
      | _ => throw "ppAction_: unhandled alloc prefix"
    pure s!"(Alloc0 {← ppPexpr pe1} {← ppPexpr pe2} {p})"
  | Store0 b pe1 pe2 pe3 mo => do
    pure s!"(Store0 {ppBool b} {← ppPexpr pe1} {← ppPexpr pe2} {← ppPexpr pe3} {← ppMemOrder mo})"
  | Load0 pe1 pe2 mo => do
    pure s!"(Load0 {← ppPexpr pe1} {← ppPexpr pe2} {← ppMemOrder mo})"
  | SeqRMW b pe1 pe2 s pe3 => do
    -- S2 surface: `seq_rmw(ty, ptr, x => e)` (postfix ++ in the
    -- harness loops) — CoreParser.lean pActionSeqRMW[Forward]
    pure s!"(SeqRMW {ppBool b} {← ppPexpr pe1} {← ppPexpr pe2} {← ppSym s} {← ppPexpr pe3})"
  | _ => throw "ppAction_: unhandled action constructor"

def ppAction : generic_action Unit Unit sym → Except String String
  | Action l a act => do
    let _ : Unit := a
    pure s!"(Action {← ppLoc l} () {← ppAction_ act})"

def ppPaction : generic_paction Unit Unit sym → Except String String
  | Paction p act => do pure s!"(Paction {← ppPolarity p} {← ppAction act})"

/-! ## Hoisting machinery (arc-15 S2, code-generator depth control).

The R2 dumps' pp'd AST terms exceed the Lean code generator's
recursion depth as SINGLE defs (naive_memcpy alone is ~170 Core lines
≈ >512 nested constructors). Budget bumps are banned (heartbeat
doctrine), so the emitter SPLITS deep terms structurally: any `Expr`
node whose emitted text exceeds a NORMALIZED-length threshold is
hoisted into its own named def (the EXACT subterm — fidelity
preserved; the composed value is definitionally the same AST), and the
parent references it. Normalization collapses every digit run to
weight 1, so hoisting decisions are LITERAL-INDEPENDENT — the three
zip instances split at identical points and the parametric zip stays
aligned. The S1 divmod emission path uses `noHoist` (threshold ∞) and
is byte-identical to before. -/

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

/-- Literal-independent text weight: digit runs count 1. -/
def nlen (s : String) : Nat :=
  (charRuns s).foldl (fun acc p => acc + if p.1 then 1 else p.2.length) 0

structure HoistCtx where
  /-- Helper-def name prefix (e.g. `naiveMemcpyDeclH`). -/
  base : String
  /-- Extra binder text for helper defs (parametric decls thread the
  zip parameters through every helper). -/
  sig : String
  /-- Application text at helper reference sites. -/
  app : String
  /-- Normalized-length hoisting threshold. -/
  thresh : Nat

/-- State: accumulated helper defs (in dependency order) + counter. -/
abbrev HoistM := StateT (Array String × Nat) (Except String)

def liftE {α : Type} : Except String α → HoistM α
  | .ok a => pure a
  | .error e => throw e

/-- Hoist `text` (a full `generic_expr Unit Unit sym` term) into a
named def if it exceeds the threshold; cheap raw-length pre-filter
(nlen ≤ length). -/
def hoistMaybe (ctx : HoistCtx) (text : String) : HoistM String := do
  if text.length ≤ ctx.thresh then return text
  if nlen text ≤ ctx.thresh then return text
  let (defs, n) ← get
  let name := s!"{ctx.base}_{n}"
  let d := s!"/-- Hoisted subterm {n} of `{ctx.base}` (code-generator depth control; the exact subterm — fidelity preserved). -/\ndef {name}{ctx.sig} : generic_expr Unit Unit sym :=\n  {text}\n\n"
  set (defs.push d, n + 1)
  return s!"({name}{ctx.app})"

mutual
partial def ppExprH_ (ctx : HoistCtx) :
    generic_expr_ Unit Unit sym → HoistM String
  | Epure pe => do pure s!"(Epure {← liftE (ppPexpr pe)})"
  | Eaction pa => do pure s!"(Eaction {← liftE (ppPaction pa)})"
  | Ecase pe arms => do
    let mut parts : List String := []
    for (pat, e) in arms do
      parts := parts ++
        [s!"({← liftE (ppPattern pat)}, {← ppExprH ctx e})"]
    pure s!"(Ecase {← liftE (ppPexpr pe)} [{String.intercalate ", " parts}])"
  | Elet pat pe e => do
    pure s!"(Elet {← liftE (ppPattern pat)} {← liftE (ppPexpr pe)} {← ppExprH ctx e})"
  | Eif pe e1 e2 => do
    pure s!"(Eif {← liftE (ppPexpr pe)} {← ppExprH ctx e1} {← ppExprH ctx e2})"
  | Eccall a pe1 pe2 pes => do
    let _ : Unit := a
    pure s!"(Eccall () {← liftE (ppPexpr pe1)} {← liftE (ppPexpr pe2)} {← liftE (ppList ppPexpr pes)})"
  | Eproc a nm pes => do
    let _ : Unit := a
    pure s!"(Eproc () {← liftE (ppName nm)} {← liftE (ppList ppPexpr pes)})"
  | Eunseq es => do
    let mut parts : List String := []
    for e in es do
      parts := parts ++ [← ppExprH ctx e]
    pure s!"(Eunseq [{String.intercalate ", " parts}])"
  | Ewseq pat e1 e2 => do
    pure s!"(Ewseq {← liftE (ppPattern pat)} {← ppExprH ctx e1} {← ppExprH ctx e2})"
  | Esseq pat e1 e2 => do
    pure s!"(Esseq {← liftE (ppPattern pat)} {← ppExprH ctx e1} {← ppExprH ctx e2})"
  | Ebound e => do pure s!"(Ebound {← ppExprH ctx e})"
  | End es => do
    let mut parts : List String := []
    for e in es do
      parts := parts ++ [← ppExprH ctx e]
    pure s!"(End [{String.intercalate ", " parts}])"
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
    pure s!"(Esave ({← liftE (ppSym s)}, {← liftE (ppCbt cbt)}) {← liftE (ppList ppParam params)} {← ppExprH ctx e})"
  | Erun a s pes => do
    let _ : Unit := a
    pure s!"(Erun () {← liftE (ppSym s)} {← liftE (ppList ppPexpr pes)})"
  | Ememop mo pes => do
    -- S3 additions: PtrEq/PtrNe (null comparisons in the list walks)
    -- + PtrWellAligned (the (struct int_list*) cast of malloc's
    -- void*)
    let m ← match mo with
      | PtrValidForDeref => pure "PtrValidForDeref"
      | PtrEq => pure "PtrEq"
      | PtrNe => pure "PtrNe"
      | PtrWellAligned => pure "PtrWellAligned"
      | _ => throw "ppExpr_: unhandled memop kind"
    pure s!"(Ememop {m} {← liftE (ppList ppPexpr pes)})"
  | _ => throw "ppExpr_: unhandled expression constructor"

partial def ppExprH (ctx : HoistCtx) :
    generic_expr Unit Unit sym → HoistM String
  | Expr anns e => do
    let t := s!"(Expr {← liftE (ppAnnots anns)} {← ppExprH_ ctx e})"
    hoistMaybe ctx t
end

/-- The no-hoist context (threshold ∞): the S1-compatible pure path. -/
def noHoist : HoistCtx :=
  ⟨"", "", "", 1000000000⟩

partial def ppExpr (e : generic_expr Unit Unit sym) :
    Except String String :=
  (ppExprH noHoist e).run ((#[] : Array String), 0) |>.map Prod.fst

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

/-! ## Hoist-emitting decl printers (S2; see the hoisting block) -/

/-- Like `ppFunMapDecl` but hoisting deep Proc bodies: returns
(helper-defs text, decl body text). -/
def ppFunMapDeclH (ctx : HoistCtx) (d : generic_fun_map_decl Unit Unit) :
    Except String (String × String) := do
  match d with
  | Proc l marker cbt params e =>
    match (ppExprH ctx e).run ((#[] : Array String), 0) with
    | .ok (body, (defs, _)) =>
      let lS ← ppLoc l
      let mS ← ppOpt (fun n => pure (ppNat n)) marker
      let cS ← ppCbt cbt
      let pS ← ppList (ppProd ppSym ppCbt) params
      pure (String.join defs.toList,
        s!"(Proc {lS} {mS} {cS} {pS} {body})")
    | .error e => throw e
  | Fun cbt params pe => do
    -- pure bodies in the R2 surface are shallow; no hoisting
    pure ("", s!"(Fun {← ppCbt cbt} {← ppList (ppProd ppSym ppCbt) params} {← ppPexpr pe})")
  | _ => throw "ppFunMapDeclH: unhandled declaration form"

/-- The R2 hoisting threshold (normalized chars ≈ well under the code
generator's depth ceiling per def). -/
def hoistThresh : Nat := 8000

/-- Emit one `def` pair with hoisted helpers (S2 verbatim decls). -/
def emitDeclH (cf : CoreParser.CoreFile) (name defBase : String) :
    Except String String := do
  let (s, d) ← findDecl cf name
  let ctx : HoistCtx := ⟨defBase ++ "DeclH", "", "", hoistThresh⟩
  let (helpers, declStr) ← ppFunMapDeclH ctx d
  let symStr ← ppSym s
  pure (helpers ++
    s!"/-- `{name}`: symbol, as interned by CoreParser (name-hash id). -/\n" ++
    s!"def {defBase}Sym : sym :=\n  {symStr}\n\n" ++
    s!"/-- `{name}`: the parsed declaration, verbatim (any helpers above are exact hoisted subterms). -/\n" ++
    s!"def {defBase}Decl : generic_fun_map_decl Unit Unit :=\n  {declStr}\n")

/-- One instance's FULL parametric-main block (hoisted helpers with
the parameter binders threaded + the def line), ready for the
whole-block zip. -/
def emitMainBlockP (cf : CoreParser.CoreFile)
    (defName sig app : String) : Except String String := do
  let (_, d) ← findDecl cf "main"
  let ctx : HoistCtx := ⟨defName ++ "H", sig, app, hoistThresh⟩
  let (helpers, declStr) ← ppFunMapDeclH ctx d
  pure (helpers ++
    s!"def {defName}{sig} : generic_fun_map_decl Unit Unit :=\n  {declStr}\n")

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

/-- (valueA, valueB, valueD) → parameter name, for the six splice
sites of the pinned instance trio. -/
def paramTable : List ((String × String × String) × String) :=
  [(("7", "251", "250"), "c0"), (("2", "3", "3"), "c1"),
   (("3", "255", "254"), "e0"), (("0", "255", "255"), "e1"),
   (("1", "254", "0"), "e2"), (("0", "255", "0"), "e3")]

/-- Zip three emitted decl texts into a parametric body: constant runs
pass through; varying digit runs are looked up in `table` by their
value TRIPLE and replaced by the parameter name; any other variation
is a loud error; exactly `nsites` substitutions must occur.
Generalized at S2 (R2 reuses the S1 mechanism with a different table;
coinciding sites — e.g. memcpy's expected[] repeating choices[] — map
to the SAME parameter, which is the semantically honest reading: the
healthy family is indexed by the choice bytes alone). -/
def zipParamWith (table : List ((String × String × String) × String))
    (nsites : Nat) (ta tb td : String) : Except String String := do
  let ra := charRuns ta
  let rb := charRuns tb
  let rd := charRuns td
  if ra.length ≠ rb.length || ra.length ≠ rd.length then
    throw s!"zipParamWith: run-count mismatch ({ra.length}/{rb.length}/{rd.length})"
  let mut out := ""
  let mut seen : List String := []
  for ((da, va), (db, vb), (dd, vd)) in ra.zip (rb.zip rd) do
    if da ≠ db || da ≠ dd then
      throw "zipParamWith: run-class mismatch"
    if va == vb && va == vd then
      out := out ++ va
    else if da then
      match table.find? (fun e => e.1 == (va, vb, vd)) with
      | some e =>
        -- the literal prints as `(N : Int)`; substituting the digits
        -- yields `(c0 : Int)` — type-correct, kernel-transparent
        out := out ++ e.2
        seen := seen ++ [e.2]
      | none => throw s!"zipParamWith: unknown literal triple ({va},{vb},{vd})"
    else
      throw s!"zipParamWith: non-digit divergence ({va} vs {vb} vs {vd})"
  if seen.length ≠ nsites then
    throw s!"zipParamWith: expected exactly {nsites} parameter sites, found {seen} "
  pure out

/-- The S1 divmod zip (6 distinct sites). -/
def zipParamMain (ta tb td : String) : Except String String :=
  zipParamWith paramTable 6 ta tb td

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

/-! ## The byte-blaster S2 emission plan (R2: memcpy + getarr).

The memcpy parametric main: instances a=[1,2,3], b=[250,251,252],
d=[9,8,7] differ at NINE digit-run sites — the three choices[] content
bytes and their SIX repetitions in expected[] (prefix bytes are
constant at n=3). Coinciding sites share a parameter (the healthy
family is indexed by the choice bytes alone — expected[] is DERIVED,
which the parametric term makes structural). The out-of-trio pin is
c=[0,255,42] (boundary contents + the dst canary value, deliberately:
a canary-colliding content byte must still pin byte-for-byte).

getarr mains are pinned VERBATIM per instance (no zip): the
contrasting statement style for the register's parametric-vs-verbatim
comparison (S2 register). -/

/-- (valueA, valueB, valueD) → parameter name, memcpy trio. -/
def byteArrParamTable : List ((String × String × String) × String) :=
  [(("1", "250", "9"), "c0"), (("2", "251", "8"), "c1"),
   (("3", "252", "7"), "c2")]

def byteArrModuleHeader : String :=
"/-
  SpecLab.ByteArrCore — GENERATED by speclab-emit-bytearr (arc-15 S2).
  DO NOT EDIT.

  Kernel-transparent Lean terms for the R2 byte-blaster harness
  families: naive_memcpy + get_from_arr (the CN targets, elaborated;
  deps/cn/tests/cn/{memcpy.c,get_from_arr.c}) + the memcpy PARAMETRIC
  main (a function of the three choice bytes c0 c1 c2 — nine
  substitution sites, expected[] derived; digit-run zip over the
  pinned instances a=[1,2,3], b=[250,251,252], d=[9,8,7] —
  tests/speclab/memcpy_{a,b,d}.core), the memcpy OFF-BY-ONE PLANT pair
  (tests/speclab/memcpy_plant.core, verbatim), the getarr mains
  VERBATIM per instance (tests/speclab/getarr_{a,b}.core — the
  contrasting statement style, register S2), and the getarr
  WRONG-INDEX PLANT pair — exactly as CoreParser produces them
  (fidelity contract of SLUnit.EmitCore). The std.core closure is
  SHARED with SpecLab.DivModCore (same 8 reached declarations,
  drift-gated there).

  Drift gate: SLUnit.ByteArrGateTest re-parses the pinned inputs,
  re-emits this module byte-for-byte, pins the parametric main back to
  ALL FOUR pinned memcpy dumps (incl. the out-of-trio c=[0,255,42]),
  and runs the assembled files through the generated `drive` at the
  pinned verdicts. Regenerate:
    .lake/build/bin/speclab-emit-bytearr > SpecLab/ByteArrCore.lean
-/

import Core

set_option autoImplicit false
-- parametric-main helpers bind (c0 c1 c2) uniformly; helpers without
-- literal sites do not reference them (generated file, cosmetic)
set_option linter.unusedVariables false

namespace SpecLab.ByteArrCore

"

def byteArrModuleFooter : String := "\nend SpecLab.ByteArrCore\n"

def emitByteArrModule (ma mb md mplant ga gb gplant : String) :
    Except String String := do
  let cfA ← CoreParser.parseFile ma
  let cfB ← CoreParser.parseFile mb
  let cfD ← CoreParser.parseFile md
  let cfP ← CoreParser.parseFile mplant
  let cgA ← CoreParser.parseFile ga
  let cgB ← CoreParser.parseFile gb
  let cgP ← CoreParser.parseFile gplant
  -- the targets must be literally identical across their healthy dumps
  let tm ← declText cfA "naive_memcpy"
  if (← declText cfB "naive_memcpy") ≠ tm
      || (← declText cfD "naive_memcpy") ≠ tm then
    throw "emitByteArrModule: 'naive_memcpy' differs across healthy dumps"
  let tg ← declText cgA "get_from_arr"
  if (← declText cgB "get_from_arr") ≠ tg then
    throw "emitByteArrModule: 'get_from_arr' differs across healthy dumps"
  -- the memcpy parametric main: per-instance FULL blocks (hoisted
  -- helpers, parameter binders threaded through every helper) are
  -- zipped WHOLE — hoisting decisions are literal-independent (nlen
  -- normalization), so the three blocks split at identical points
  let (mainSymA, _) ← findDecl cfA "main"
  let sig := " (c0 c1 c2 : Int)"
  let app := " c0 c1 c2"
  let ba ← emitMainBlockP cfA "memcpyMainParamDecl" sig app
  let bb ← emitMainBlockP cfB "memcpyMainParamDecl" sig app
  let bd ← emitMainBlockP cfD "memcpyMainParamDecl" sig app
  let pblock ← zipParamWith byteArrParamTable 9 ba bb bd
  let mut out := byteArrModuleHeader
  out := out ++ (← emitDeclH cfA "naive_memcpy" "naiveMemcpy") ++ "\n"
  out := out ++ s!"/-- `main`: symbol, as interned by CoreParser. -/\n"
  out := out ++ s!"def mainSym : sym :=\n  {← ppSym mainSymA}\n\n"
  out := out ++ "/- memcpy `main`, PARAMETRIC in the three choice bytes (see the\nmodule header; expected[] sites are DERIVED — they share the\nparameters; hoisted helpers below carry the binders).\n`memcpyMainParamDecl 1 2 3` is the parsed main of the pinned\ninstance a, byte-for-byte (SLUnit.ByteArrGateTest). -/\n"
  out := out ++ pblock ++ "\n"
  out := out ++ (← emitDeclH cfP "naive_memcpy" "naiveMemcpyPlant") ++ "\n"
  out := out ++ (← emitDeclH cfP "main" "memcpyMainPlant") ++ "\n"
  out := out ++ (← emitDeclH cgA "get_from_arr" "getFromArr") ++ "\n"
  out := out ++ (← emitDeclH cgA "main" "getarrMainA") ++ "\n"
  out := out ++ (← emitDeclH cgB "main" "getarrMainB") ++ "\n"
  out := out ++ (← emitDeclH cgP "get_from_arr" "getFromArrPlant") ++ "\n"
  out := out ++ (← emitDeclH cgP "main" "getarrMainPlant") ++ "\n"
  pure (out ++ byteArrModuleFooter)

def readByteArrInputs :
    IO (String × String × String × String × String × String × String) := do
  let root ← findRoot
  let ma ← IO.FS.readFile (root ++ "tests/speclab/memcpy_a.core")
  let mb ← IO.FS.readFile (root ++ "tests/speclab/memcpy_b.core")
  let md ← IO.FS.readFile (root ++ "tests/speclab/memcpy_d.core")
  let mp ← IO.FS.readFile (root ++ "tests/speclab/memcpy_plant.core")
  let ga ← IO.FS.readFile (root ++ "tests/speclab/getarr_a.core")
  let gb ← IO.FS.readFile (root ++ "tests/speclab/getarr_b.core")
  let gp ← IO.FS.readFile (root ++ "tests/speclab/getarr_plant.core")
  pure (ma, mb, md, mp, ga, gb, gp)

/-! ## The list-rung S3 emission plan (R3: IntList_append).

The append parametric main: instances a/b/d are the (2,1)-length
family with element wire bytes 1..12 / 101..112 / 201..212 — all 12
byte positions' value TRIPLES pairwise distinct, so the zip assigns
each its parameter unambiguously; each byte appears at TWO sites
(choices[] + expected[], the observation repeating the appended
input), so 12 parameters cover 24 substitution sites. The out-of-trio
pin is c = xs [0, -1], ys [-2147483648] (boundary bit patterns:
all-zeros, all-ones, INT_MIN). Plant mains + the build-only main are
pinned VERBATIM (single instances, the getarr style).

NEW SURFACES this rung (each added loudly per the fidelity
contract): null pointer values (`NULL(ty)`), `PtrEq`/`PtrNe`/
`PtrWellAligned` memops, the `Alloc0` action (std.core
malloc_proxy), struct TAG DEFINITIONS (the first rung with
`file.tagDefs` nonempty), and the std.core allocator proxies
(malloc_proxy/free_proxy) joining the pinned std closure. -/

/-- (valueA, valueB, valueD) → parameter name, append trio: wire byte
i+1 ↦ `bi`. -/
def listParamTable : List ((String × String × String) × String) :=
  (List.range 12).map fun i =>
    ((toString (i + 1), toString (i + 101), toString (i + 201)),
      s!"b{i}")

def listModuleHeader : String :=
"/-
  SpecLab.ListAppendCore — GENERATED by speclab-emit-list (arc-15 S3).
  DO NOT EDIT.

  Kernel-transparent Lean terms for the R3 linked-list harness
  family: IntList_append (the CN target, elaborated;
  deps/cn/tests/cn/append.c) + the `struct int_list` TAG DEFINITION
  (the first rung with a nonempty file.tagDefs) + the append
  PARAMETRIC main (a function of the twelve element wire bytes
  b0..b11 — 24 substitution sites, expected[] derived; digit-run zip
  over the pinned instances a/b/d, wire bytes 1..12 / 101..112 /
  201..212 — tests/speclab/applist_{a,b,d}.core), the WRONG-LINK and
  WRONG-ELEMENT PLANT pairs (applist_{linkplant,elemplant}.core,
  verbatim), the BUILD-ONLY main (applist_build.core, verbatim — the
  builder-correctness instance), and the std.core allocator proxies
  malloc_proxy/free_proxy (the allocation closure) plus
  all_values_representable_in (the R3 mains' pointer-conversion
  checks reach it; not in the divmod closure) — exactly as CoreParser
  produces them (fidelity contract of SLUnit.EmitCore). The remaining
  scalar std closure is SHARED with SpecLab.DivModCore (same 8
  reached declarations, drift-gated there).

  Drift gate: SLUnit.ListGateTest re-parses the pinned inputs,
  re-emits this module byte-for-byte, pins the parametric main back
  to ALL FOUR pinned healthy dumps (incl. the out-of-trio
  c = [0,-1]++[INT_MIN]), runs the assembled files through the
  generated `drive` at the pinned verdicts, and checks THE LEAK
  OBSERVABLE (final allocation map) on every run. Regenerate:
    .lake/build/bin/speclab-emit-list > SpecLab/ListAppendCore.lean
-/

import Core

set_option autoImplicit false
-- parametric-main helpers bind (b0 .. b11) uniformly; helpers
-- without literal sites do not reference them (generated file,
-- cosmetic)
set_option linter.unusedVariables false

namespace SpecLab.ListAppendCore

"

def listModuleFooter : String := "\nend SpecLab.ListAppendCore\n"

/-- Emit the struct int_list tag definition (sym + tag_definition;
the parsed Loc must be unknown — assembled with `Loc.unknown` in
SpecLab/ListAppendFiles.lean). -/
def emitIntListTagDef (cf : CoreFile) : Except String String := do
  match cf.tagDefs with
  | [(s, (loc, td))] =>
    let _ ← ppLoc loc  -- errors on non-unknown
    pure ("/-- `struct int_list`: tag symbol, as interned by CoreParser. -/\n" ++
      s!"def intListSym : sym :=\n  {← ppSym s}\n\n" ++
      "/-- `struct int_list`: the tag definition, verbatim. -/\n" ++
      s!"def intListTagDef : tag_definition :=\n  {← ppTagDef td}\n")
  | _ => throw s!"emitIntListTagDef: expected exactly one tag def, got {cf.tagDefs.length}"

def emitListModule (da db dd dc dlp dep dbuild stdText : String) :
    Except String String := do
  let cfA ← CoreParser.parseFile da
  let cfB ← CoreParser.parseFile db
  let cfD ← CoreParser.parseFile dd
  let cfC ← CoreParser.parseFile dc
  let cfLP ← CoreParser.parseFile dlp
  let cfEP ← CoreParser.parseFile dep
  let cfBu ← CoreParser.parseFile dbuild
  let std ← CoreParser.parseFile stdText
  -- the target must be literally identical across the four append
  -- dumps (a, b, d, c — identical main STRUCTURE ⇒ identical fresh
  -- numbering). The build-only dump's main differs structurally, so
  -- its whole TU numbers differently: its target is pinned SEPARATELY
  -- from its own dump (intListAppendBuildDecl) — the S3
  -- symbol-numbering-coupling finding (register S3).
  let tt ← declText cfA "IntList_append"
  for (lbl, cf) in [("b", cfB), ("d", cfD), ("c", cfC)] do
    if (← declText cf "IntList_append") ≠ tt then
      throw s!"emitListModule: 'IntList_append' differs in dump {lbl}"
  -- the tag def must be identical across all dumps
  let tagA ← emitIntListTagDef cfA
  for (lbl, cf) in [("b", cfB), ("d", cfD), ("c", cfC), ("lp", cfLP),
      ("ep", cfEP), ("build", cfBu)] do
    if (← emitIntListTagDef cf) ≠ tagA then
      throw s!"emitListModule: tag def differs in dump {lbl}"
  -- the append parametric main: per-instance FULL blocks zipped
  -- whole (hoisting decisions literal-independent — the S2
  -- mechanism)
  let (mainSymA, _) ← findDecl cfA "main"
  let sig := " (b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 : Int)"
  let app := " b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11"
  let ba ← emitMainBlockP cfA "appendMainParamDecl" sig app
  let bb ← emitMainBlockP cfB "appendMainParamDecl" sig app
  let bd ← emitMainBlockP cfD "appendMainParamDecl" sig app
  let pblock ← zipParamWith listParamTable 24 ba bb bd
  let mut out := listModuleHeader
  out := out ++ tagA ++ "\n"
  out := out ++ (← emitDeclH cfA "IntList_append" "intListAppend") ++ "\n"
  out := out ++ s!"/-- `main`: symbol, as interned by CoreParser. -/\n"
  out := out ++ s!"def mainSym : sym :=\n  {← ppSym mainSymA}\n\n"
  out := out ++ "/- append `main`, PARAMETRIC in the twelve element wire bytes (see\nthe module header; expected[] sites are DERIVED — they share the\nparameters; hoisted helpers below carry the binders).\n`appendMainParamDecl 1 2 3 4 5 6 7 8 9 10 11 12` is the parsed main\nof the pinned instance a, byte-for-byte (SLUnit.ListGateTest). -/\n"
  out := out ++ pblock ++ "\n"
  out := out ++ (← emitDeclH cfLP "IntList_append" "intListAppendLinkPlant") ++ "\n"
  out := out ++ (← emitDeclH cfLP "main" "appendMainLinkPlant") ++ "\n"
  out := out ++ (← emitDeclH cfEP "IntList_append" "intListAppendElemPlant") ++ "\n"
  out := out ++ (← emitDeclH cfEP "main" "appendMainElemPlant") ++ "\n"
  out := out ++ (← emitDeclH cfBu "IntList_append" "intListAppendBuild") ++ "\n"
  out := out ++ (← emitDeclH cfBu "main" "appendMainBuild") ++ "\n"
  out := out ++ (← emitDeclH std "malloc_proxy" "mallocProxy") ++ "\n"
  out := out ++ (← emitDeclH std "free_proxy" "freeProxy") ++ "\n"
  out := out ++ (← emitDeclH std "all_values_representable_in"
    "allValuesReprIn") ++ "\n"
  pure (out ++ listModuleFooter)

def readListInputs :
    IO (String × String × String × String × String × String × String
      × String) := do
  let root ← findRoot
  let a ← IO.FS.readFile (root ++ "tests/speclab/applist_a.core")
  let b ← IO.FS.readFile (root ++ "tests/speclab/applist_b.core")
  let d ← IO.FS.readFile (root ++ "tests/speclab/applist_d.core")
  let c ← IO.FS.readFile (root ++ "tests/speclab/applist_c.core")
  let lp ← IO.FS.readFile (root ++ "tests/speclab/applist_linkplant.core")
  let ep ← IO.FS.readFile (root ++ "tests/speclab/applist_elemplant.core")
  let bu ← IO.FS.readFile (root ++ "tests/speclab/applist_build.core")
  let std ← IO.FS.readFile (root ++ "runtime/libcore/std.core")
  pure (a, b, d, c, lp, ep, bu, std)

end SpecLabEmitCore
