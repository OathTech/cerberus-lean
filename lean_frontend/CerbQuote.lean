/- Representation quotation of the executed Core file.
   Comparator names come from the producer audit in
   docs/2026-10-18_core-quote-record.md, not from inspecting closures.
   This is an instrument on the declared boundary, not a correctness proof. -/
import Core_run_aux
import CerbDriverConfig
import Std.Data.HashMap

namespace CerbQuote

/-- A named refusal; the enclosing file field is added by `quoteFile`. -/
structure Refusal where
  construct : String
  detail : String
  deriving BEq, Repr

def Refusal.message (r : Refusal) : String :=
  s!"CerbQuote refused {r.construct}: {r.detail}"

/-- Constructor applications and literal leaves, retained as a tree until rendering. -/
inductive Term where
  | atom : String → Term
  | app : String → List Term → Term
  | list : List Term → Term
  | consList : String → List Term → Term → Term
  | typed : String → Term → Term
  deriving Inhabited

abbrev Result := Except Refusal Term

private def node (name : String) (args : List Term) : Term := .app ("_root_." ++ name) args

private def typedNode (typeName name : String) (args : List Term) : Term :=
  .typed typeName (node name args)

private def qNat (n : Nat) : Result := .ok (.atom (toString n))
private def qInt : Int → Result
  | .ofNat n => return node "Int.ofNat" [← qNat n]
  | .negSucc n => return node "Int.negSucc" [← qNat n]
private def qString (s : String) : Result := .ok (.atom (reprStr s))
private def qBool (b : Bool) : Result := .ok (.atom (if b then "Bool.true" else "Bool.false"))
private def qUnit (_ : Unit) : Result := .ok (.atom "()")

/-- Reject before `toBits`: the pinned Float implementation canonicalizes NaNs. -/
def quoteFloat (f : Float) : Result :=
  if f.isNaN then
    .error ⟨"Float.NaN", "Float.toBits canonicalizes NaNs; their representation cannot be quoted"⟩
  else
    .ok (node "Float.ofBits" [.atom (toString f.toBits.toNat)])

private def qList {α : Type} (elementType : String) (q : α → Result) (xs : List α) : Result := do
  let values ← xs.mapM q
  if values.length ≤ 256 then return .list values
  -- Large array initializers can contain a million elements. Keep literal
  -- List.cons/List.nil representation, but bound each elaboration unit. The
  -- block constructor also keeps the intermediate quotation's depth bounded
  -- by the number of blocks rather than the number of elements.
  let values := values.toArray
  let mut blocks : List (List Term) := []
  for first in [:values.size:128] do
    blocks := (values.extract first (first + 128)).toList :: blocks
  let mut tail := Term.list []
  for block in blocks do
    tail := .typed ("(List " ++ elementType ++ ")") (.consList elementType block tail)
  return tail
private def qOption {α : Type} (q : α → Result) : Option α → Result
  | none => return node "Option.none" []
  | some x => return node "Option.some" [← q x]
private def qProd {α β : Type} (qa : α → Result) (qb : β → Result) (p : α × β) : Result :=
  return node "Prod.mk" [← qa p.1, ← qb p.2]

private def qPset {α : Type} (q : α → Result) : Pset α → Result
  | .Empty => return node "Pset.Empty" []
  | .Node l x r h => return node "Pset.Node" [← qPset q l, ← q x, ← qPset q r, ← qNat h]

private def qPmap {α β : Type} (typeName : String) (qk : α → Result) (qv : β → Result) : Pmap α β → Result
  | .Empty => return typedNode typeName "Pmap.Empty" []
  | .Node l k v r h =>
    return typedNode typeName "Pmap.Node"
      [← qPmap typeName qk qv l, ← qk k, ← qv v, ← qPmap typeName qk qv r, ← qNat h]

/-- The six distinct construction terms from the D0 audit. -/
inductive Comparator where
  | S | O | L | I | N | E
  deriving BEq, Repr

def Comparator.term : Comparator → String
  | .S => "(@Lem_Map.MapKeyType.mapKeyCompare sym (@Lem_Map.instMapKeyTypeOfSetType sym instSetTypeSym_1))"
  | .O => "(@Lem_Basic_classes.ordCompare sym instEq0Sym_1 instOrd0Sym_1)"
  | .L => "symbol_compare"
  | .I => "implementation_constant_compare"
  | .N => "(@defaultCompare Nat instOrdNat)"
  | .E => "(fun (a b : identifier) => match a with | .Identifier _ sa => match b with | .Identifier _ sb => @defaultCompare String String.instOrd sa sb)"

/-- `none` means the outer constructor is `.empty`, not a tree with no bindings. -/
structure Provenance where
  tagDefs : Option Comparator
  enumDefs : Option Comparator
  stdlib : Option Comparator
  impl0 : Option Comparator
  funs : Option Comparator
  extern : Option Comparator
  funinfo : Option Comparator
  loop_attributes : Option Comparator
  visible_objects_env : Option Comparator
  deriving BEq, Repr

private def capture {α β : Type} (c : Comparator) : Fmap α β → Option Comparator
  | .empty => none
  | .mk _ _ => some c

/-- Call only at the translated-TU construction audited in D0. -/
def translatedProvenance {a b : Type} (f : generic_file a b) : Provenance :=
  ⟨capture .S f.tagDefs, capture .S f.enumDefs, capture .S f.stdlib,
   capture .I f.impl0, capture .O f.funs, capture .E f.extern,
   capture .O f.funinfo, capture .N f.loop_attributes1, capture .N f.visible_objects_env0⟩

/-- Call only on the result of Main.loadLibc, before linking user TUs. -/
def libcProvenance {a b : Type} (f : generic_file a b) : Provenance :=
  ⟨capture .L f.tagDefs, none, capture .S f.stdlib,
   capture .I f.impl0, capture .L f.funs, capture .E f.extern,
   capture .L f.funinfo, none, none⟩

/-- The provenance counterpart of `link_aux f1 f2`. The caller must retain
    the driver's reverse-cons order and `link_aux next accumulated` fold.
    Extern is an insertion fold; all admitted insertions use E. Its outer
    constructor is read from the successful result: inserting the bindings
    of a right `.mk _ .Empty` into `.empty` leaves `.empty`. -/
def linkProvenance {a b : Type} (p1 p2 : Provenance) (linked : generic_file a b) : Provenance :=
  ⟨p1.tagDefs.or p2.tagDefs, p1.enumDefs.or p2.enumDefs, p1.stdlib, p1.impl0,
   p1.funs.or p2.funs, capture .E linked.extern, p1.funinfo.or p2.funinfo,
   p1.loop_attributes.or p2.loop_attributes, p1.visible_objects_env.or p2.visible_objects_env⟩

/-- Mirror `Core_linking.link` on the driver's reverse-consed inputs.
    The final result is used only for extern's insertion-produced outer tag;
    all union comparator choices follow the original inputs, including empty trees. -/
def linkedProvenance {a b : Type} (reverseInputs : List Provenance)
    (linked : generic_file a b) : Except Refusal Provenance :=
  match reverseInputs with
  | [] => .error ⟨"link", "no input provenance records"⟩
  | p :: ps => .ok (ps.foldl (fun acc next => linkProvenance next acc linked) p)

private def qFmap {α β : Type} (keyType valueType : String) (allowed : List Comparator)
    (origin : Option Comparator) (qk : α → Result) (qv : β → Result) : Fmap α β → Result
  | .empty =>
    match origin with
    | none => return node "Fmap.empty" []
    | some _ => .error ⟨"Fmap.empty", "comparator provenance claims .mk, but the map is .empty"⟩
  | .mk _ tree =>
    match origin with
    | none => .error ⟨"Fmap.mk", "missing comparator provenance"⟩
    | some c =>
      if allowed.contains c then
        return node "Fmap.mk" [.atom c.term, ← qPmap ("(Pmap " ++ keyType ++ " " ++ valueType ++ ")") qk qv tree]
      else .error ⟨"Fmap.mk", s!"comparator {reprStr c} is not an admitted producer for this field"⟩

-- The model-constructor cases follow below. No wildcard constructor arm is used.

private def q_CerbLocation_Pos : (CerbLocation.Pos) → Result
  | CerbLocation.Pos.mk x0 x1 x2 x3 x4 => return typedNode "(CerbLocation.Pos)" "CerbLocation.Pos.mk" [← qString x0, ← qNat x1, ← qNat x2, ← qString x3, ← qNat x4]

private def q_CerbLocation_Cursor : (CerbLocation.Cursor) → Result
  | CerbLocation.Cursor.noCursor => return typedNode "(CerbLocation.Cursor)" "CerbLocation.Cursor.noCursor" []
  | CerbLocation.Cursor.pointCursor x0 => return typedNode "(CerbLocation.Cursor)" "CerbLocation.Cursor.pointCursor" [← q_CerbLocation_Pos x0]
  | CerbLocation.Cursor.regionCursor x0 x1 => return typedNode "(CerbLocation.Cursor)" "CerbLocation.Cursor.regionCursor" [← q_CerbLocation_Pos x0, ← q_CerbLocation_Pos x1]

private def q_CerbLocation_Loc : (CerbLocation.Loc) → Result
  | CerbLocation.Loc.unknown => return typedNode "(CerbLocation.Loc)" "CerbLocation.Loc.unknown" []
  | CerbLocation.Loc.other x0 => return typedNode "(CerbLocation.Loc)" "CerbLocation.Loc.other" [← qString x0]
  | CerbLocation.Loc.point x0 => return typedNode "(CerbLocation.Loc)" "CerbLocation.Loc.point" [← q_CerbLocation_Pos x0]
  | CerbLocation.Loc.region x0 x1 x2 => return typedNode "(CerbLocation.Loc)" "CerbLocation.Loc.region" [← q_CerbLocation_Pos x0, ← q_CerbLocation_Pos x1, ← q_CerbLocation_Cursor x2]
  | CerbLocation.Loc.regions x0 x1 => return typedNode "(CerbLocation.Loc)" "CerbLocation.Loc.regions" [← (qList "(Prod (CerbLocation.Pos) (CerbLocation.Pos))" (qProd q_CerbLocation_Pos q_CerbLocation_Pos)) x0, ← q_CerbLocation_Cursor x1]

private def q_CerbMem_FootprintAccess : (CerbMem.FootprintAccess) → Result
  | CerbMem.FootprintAccess.W => return typedNode "(CerbMem.FootprintAccess)" "CerbMem.FootprintAccess.W" []
  | CerbMem.FootprintAccess.R => return typedNode "(CerbMem.FootprintAccess)" "CerbMem.FootprintAccess.R" []

private def q_CerbMem_Footprint : (CerbMem.Footprint) → Result
  | CerbMem.Footprint.FP x0 x1 x2 => return typedNode "(CerbMem.Footprint)" "CerbMem.Footprint.FP" [← q_CerbMem_FootprintAccess x0, ← qInt x1, ← qInt x2]

private def q_CerbMem_Provenance : (CerbMem.Provenance) → Result
  | CerbMem.Provenance.Prov_none => return typedNode "(CerbMem.Provenance)" "CerbMem.Provenance.Prov_none" []
  | CerbMem.Provenance.Prov_some x0 => return typedNode "(CerbMem.Provenance)" "CerbMem.Provenance.Prov_some" [← qInt x0]
  | CerbMem.Provenance.Prov_symbolic x0 => return typedNode "(CerbMem.Provenance)" "CerbMem.Provenance.Prov_symbolic" [← qInt x0]
  | CerbMem.Provenance.Prov_device => return typedNode "(CerbMem.Provenance)" "CerbMem.Provenance.Prov_device" []

private def q_CerbMem_IntegerValue : (CerbMem.IntegerValue) → Result
  | CerbMem.IntegerValue.IV x0 x1 => return typedNode "(CerbMem.IntegerValue)" "CerbMem.IntegerValue.IV" [← q_CerbMem_Provenance x0, ← qInt x1]

private def q_identifier : (identifier) → Result
  | identifier.Identifier x0 x1 => return typedNode "(identifier)" "identifier.Identifier" [← q_CerbLocation_Loc x0, ← qString x1]

private def q_attribute0 : (attribute0) → Result
  | attribute0.mk x0 x1 x2 => return typedNode "(attribute0)" "attribute0.mk" [← (qOption q_identifier) x0, ← q_identifier x1, ← (qList "(Prod (CerbLocation.Loc) (Prod String (List (Prod (CerbLocation.Loc) String))))" (qProd q_CerbLocation_Loc (qProd qString (qList "(Prod (CerbLocation.Loc) String)" (qProd q_CerbLocation_Loc qString))))) x2]

private def q_attributes : (attributes) → Result
  | attributes.Attrs x0 => return typedNode "(attributes)" "attributes.Attrs" [← (qList "(attribute0)" q_attribute0) x0]

private def q_bmc_annot : (bmc_annot) → Result
  | bmc_annot.Abmc_id x0 => return typedNode "(bmc_annot)" "bmc_annot.Abmc_id" [← qNat x0]

private def q_cerb_attribute : (cerb_attribute) → Result
  | cerb_attribute.ACerb_with_address x0 => return typedNode "(cerb_attribute)" "cerb_attribute.ACerb_with_address" [← qInt x0]
  | cerb_attribute.ACerb_hidden => return typedNode "(cerb_attribute)" "cerb_attribute.ACerb_hidden" []

private def q_label_annot : (label_annot) → Result
  | label_annot.LAloop x0 => return typedNode "(label_annot)" "label_annot.LAloop" [← qNat x0]
  | label_annot.LAloop_continue x0 => return typedNode "(label_annot)" "label_annot.LAloop_continue" [← qNat x0]
  | label_annot.LAloop_break x0 => return typedNode "(label_annot)" "label_annot.LAloop_break" [← qNat x0]
  | label_annot.LAreturn => return typedNode "(label_annot)" "label_annot.LAreturn" []
  | label_annot.LAswitch => return typedNode "(label_annot)" "label_annot.LAswitch" []
  | label_annot.LAcase => return typedNode "(label_annot)" "label_annot.LAcase" []
  | label_annot.LAdefault => return typedNode "(label_annot)" "label_annot.LAdefault" []
  | label_annot.LAactual_label => return typedNode "(label_annot)" "label_annot.LAactual_label" []

private def q_symbol_description : (symbol_description) → Result
  | symbol_description.SD_None => return typedNode "(symbol_description)" "symbol_description.SD_None" []
  | symbol_description.SD_unnamed_tag x0 => return typedNode "(symbol_description)" "symbol_description.SD_unnamed_tag" [← q_CerbLocation_Loc x0]
  | symbol_description.SD_Id x0 => return typedNode "(symbol_description)" "symbol_description.SD_Id" [← qString x0]
  | symbol_description.SD_CN_Id x0 => return typedNode "(symbol_description)" "symbol_description.SD_CN_Id" [← qString x0]
  | symbol_description.SD_ObjectAddress x0 => return typedNode "(symbol_description)" "symbol_description.SD_ObjectAddress" [← qString x0]
  | symbol_description.SD_Return => return typedNode "(symbol_description)" "symbol_description.SD_Return" []
  | symbol_description.SD_FunArgValue x0 => return typedNode "(symbol_description)" "symbol_description.SD_FunArgValue" [← qString x0]
  | symbol_description.SD_FunArg x0 x1 => return typedNode "(symbol_description)" "symbol_description.SD_FunArg" [← q_CerbLocation_Loc x0, ← qNat x1]

private def q_sym : (sym) → Result
  | sym.Symbol x0 x1 x2 => return typedNode "(sym)" "sym.Symbol" [← qString x0, ← qNat x1, ← q_symbol_description x2]

private def q_integerBaseType : (integerBaseType) → Result
  | integerBaseType.Ichar => return typedNode "(integerBaseType)" "integerBaseType.Ichar" []
  | integerBaseType.Short => return typedNode "(integerBaseType)" "integerBaseType.Short" []
  | integerBaseType.Int_ => return typedNode "(integerBaseType)" "integerBaseType.Int_" []
  | integerBaseType.Long => return typedNode "(integerBaseType)" "integerBaseType.Long" []
  | integerBaseType.LongLong => return typedNode "(integerBaseType)" "integerBaseType.LongLong" []
  | integerBaseType.IntN_t x0 => return typedNode "(integerBaseType)" "integerBaseType.IntN_t" [← qNat x0]
  | integerBaseType.Int_leastN_t x0 => return typedNode "(integerBaseType)" "integerBaseType.Int_leastN_t" [← qNat x0]
  | integerBaseType.Int_fastN_t x0 => return typedNode "(integerBaseType)" "integerBaseType.Int_fastN_t" [← qNat x0]
  | integerBaseType.Intmax_t => return typedNode "(integerBaseType)" "integerBaseType.Intmax_t" []
  | integerBaseType.Intptr_t => return typedNode "(integerBaseType)" "integerBaseType.Intptr_t" []

private def q_integerType : (integerType) → Result
  | integerType.Char0 => return typedNode "(integerType)" "integerType.Char0" []
  | integerType.Bool0 => return typedNode "(integerType)" "integerType.Bool0" []
  | integerType.Signed x0 => return typedNode "(integerType)" "integerType.Signed" [← q_integerBaseType x0]
  | integerType.Unsigned x0 => return typedNode "(integerType)" "integerType.Unsigned" [← q_integerBaseType x0]
  | integerType.Enum0 x0 => return typedNode "(integerType)" "integerType.Enum0" [← q_sym x0]
  | integerType.Wchar_t => return typedNode "(integerType)" "integerType.Wchar_t" []
  | integerType.Wint_t => return typedNode "(integerType)" "integerType.Wint_t" []
  | integerType.Size_t => return typedNode "(integerType)" "integerType.Size_t" []
  | integerType.Ptrdiff_t => return typedNode "(integerType)" "integerType.Ptrdiff_t" []
  | integerType.Ptraddr_t => return typedNode "(integerType)" "integerType.Ptraddr_t" []

private def q_value_annot : (value_annot) → Result
  | value_annot.Ainteger x0 => return typedNode "(value_annot)" "value_annot.Ainteger" [← q_integerType x0]

private def q_annot : (annot) → Result
  | annot.Astd x0 => return typedNode "(annot)" "annot.Astd" [← qString x0]
  | annot.Aloc x0 => return typedNode "(annot)" "annot.Aloc" [← q_CerbLocation_Loc x0]
  | annot.Auid x0 => return typedNode "(annot)" "annot.Auid" [← qString x0]
  | annot.Amarker x0 => return typedNode "(annot)" "annot.Amarker" [← qNat x0]
  | annot.Amarker_object_types x0 => return typedNode "(annot)" "annot.Amarker_object_types" [← qNat x0]
  | annot.Abmc x0 => return typedNode "(annot)" "annot.Abmc" [← q_bmc_annot x0]
  | annot.Aattrs x0 => return typedNode "(annot)" "annot.Aattrs" [← q_attributes x0]
  | annot.Atypedef x0 => return typedNode "(annot)" "annot.Atypedef" [← q_sym x0]
  | annot.Alabel x0 => return typedNode "(annot)" "annot.Alabel" [← q_label_annot x0]
  | annot.Acerb x0 => return typedNode "(annot)" "annot.Acerb" [← q_cerb_attribute x0]
  | annot.Avalue x0 => return typedNode "(annot)" "annot.Avalue" [← q_value_annot x0]
  | annot.Ainlined_label x0 => return typedNode "(annot)" "annot.Ainlined_label" [← (qProd q_CerbLocation_Loc (qProd q_sym q_label_annot)) x0]
  | annot.Astmt => return typedNode "(annot)" "annot.Astmt" []
  | annot.Aexpr => return typedNode "(annot)" "annot.Aexpr" []

private def q_realFloatingType : (realFloatingType) → Result
  | realFloatingType.Float0 => return typedNode "(realFloatingType)" "realFloatingType.Float0" []
  | realFloatingType.Double => return typedNode "(realFloatingType)" "realFloatingType.Double" []
  | realFloatingType.LongDouble => return typedNode "(realFloatingType)" "realFloatingType.LongDouble" []

private def q_floatingType : (floatingType) → Result
  | floatingType.RealFloating x0 => return typedNode "(floatingType)" "floatingType.RealFloating" [← q_realFloatingType x0]

private def q_basicType : (basicType) → Result
  | basicType.Integer x0 => return typedNode "(basicType)" "basicType.Integer" [← q_integerType x0]
  | basicType.Floating x0 => return typedNode "(basicType)" "basicType.Floating" [← q_floatingType x0]

private def q_qualifiers : (qualifiers) → Result
  | qualifiers.mk x0 x1 x2 => return typedNode "(qualifiers)" "qualifiers.mk" [← qBool x0, ← qBool x1, ← qBool x2]

mutual
private partial def q_ctype : (ctype) → Result
  | ctype.Ctype x0 x1 => return typedNode "(ctype)" "ctype.Ctype" [← (qList "(annot)" q_annot) x0, ← q_ctype_ x1]

private partial def q_ctype_ : (ctype_) → Result
  | ctype_.Void0 => return typedNode "(ctype_)" "ctype_.Void0" []
  | ctype_.Basic x0 => return typedNode "(ctype_)" "ctype_.Basic" [← q_basicType x0]
  | ctype_.Array0 x0 x1 => return typedNode "(ctype_)" "ctype_.Array0" [← q_ctype x0, ← (qOption qInt) x1]
  | ctype_.Function x0 x1 x2 => return typedNode "(ctype_)" "ctype_.Function" [← (qProd q_qualifiers q_ctype) x0, ← (qList "(Prod (qualifiers) (Prod (ctype) Bool))" (qProd q_qualifiers (qProd q_ctype qBool))) x1, ← qBool x2]
  | ctype_.FunctionNoParams x0 => return typedNode "(ctype_)" "ctype_.FunctionNoParams" [← (qProd q_qualifiers q_ctype) x0]
  | ctype_.Pointer x0 x1 => return typedNode "(ctype_)" "ctype_.Pointer" [← q_qualifiers x0, ← q_ctype x1]
  | ctype_.Atomic x0 => return typedNode "(ctype_)" "ctype_.Atomic" [← q_ctype x0]
  | ctype_.Struct x0 => return typedNode "(ctype_)" "ctype_.Struct" [← q_sym x0]
  | ctype_.Union0 x0 => return typedNode "(ctype_)" "ctype_.Union0" [← q_sym x0]
  | ctype_.Byte => return typedNode "(ctype_)" "ctype_.Byte" []

end

private def q_CerbMem_PointerValueBase : (CerbMem.PointerValueBase) → Result
  | CerbMem.PointerValueBase.PVnull x0 => return typedNode "(CerbMem.PointerValueBase)" "CerbMem.PointerValueBase.PVnull" [← q_ctype x0]
  | CerbMem.PointerValueBase.PVfunction x0 => return typedNode "(CerbMem.PointerValueBase)" "CerbMem.PointerValueBase.PVfunction" [← q_sym x0]
  | CerbMem.PointerValueBase.PVconcrete x0 x1 => return typedNode "(CerbMem.PointerValueBase)" "CerbMem.PointerValueBase.PVconcrete" [← (qOption q_identifier) x0, ← qInt x1]

private def q_CerbMem_PointerValue : (CerbMem.PointerValue) → Result
  | CerbMem.PointerValue.PV x0 x1 => return typedNode "(CerbMem.PointerValue)" "CerbMem.PointerValue.PV" [← q_CerbMem_Provenance x0, ← q_CerbMem_PointerValueBase x1]

private partial def q_CerbMem_MemValue : (CerbMem.MemValue) → Result
  | CerbMem.MemValue.MVunspecified x0 => return typedNode "(CerbMem.MemValue)" "CerbMem.MemValue.MVunspecified" [← q_ctype x0]
  | CerbMem.MemValue.MVinteger x0 x1 => return typedNode "(CerbMem.MemValue)" "CerbMem.MemValue.MVinteger" [← q_integerType x0, ← q_CerbMem_IntegerValue x1]
  | CerbMem.MemValue.MVfloating x0 x1 => return typedNode "(CerbMem.MemValue)" "CerbMem.MemValue.MVfloating" [← q_floatingType x0, ← quoteFloat x1]
  | CerbMem.MemValue.MVpointer x0 x1 => return typedNode "(CerbMem.MemValue)" "CerbMem.MemValue.MVpointer" [← q_ctype x0, ← q_CerbMem_PointerValue x1]
  | CerbMem.MemValue.MVarray x0 => return typedNode "(CerbMem.MemValue)" "CerbMem.MemValue.MVarray" [← (qList "(CerbMem.MemValue)" q_CerbMem_MemValue) x0]
  | CerbMem.MemValue.MVstruct x0 x1 => return typedNode "(CerbMem.MemValue)" "CerbMem.MemValue.MVstruct" [← q_sym x0, ← (qList "(Prod (identifier) (Prod (ctype) (CerbMem.MemValue)))" (qProd q_identifier (qProd q_ctype q_CerbMem_MemValue))) x1]
  | CerbMem.MemValue.MVunion x0 x1 x2 => return typedNode "(CerbMem.MemValue)" "CerbMem.MemValue.MVunion" [← q_sym x0, ← q_identifier x1, ← q_CerbMem_MemValue x2]

private def q_alignment : (alignment) → Result
  | alignment.AlignInteger x0 => return typedNode "(alignment)" "alignment.AlignInteger" [← qInt x0]
  | alignment.AlignType x0 => return typedNode "(alignment)" "alignment.AlignType" [← q_ctype x0]

private def q_arithmeticOperator : (arithmeticOperator) → Result
  | arithmeticOperator.Mul0 => return typedNode "(arithmeticOperator)" "arithmeticOperator.Mul0" []
  | arithmeticOperator.Div0 => return typedNode "(arithmeticOperator)" "arithmeticOperator.Div0" []
  | arithmeticOperator.Mod0 => return typedNode "(arithmeticOperator)" "arithmeticOperator.Mod0" []
  | arithmeticOperator.Add0 => return typedNode "(arithmeticOperator)" "arithmeticOperator.Add0" []
  | arithmeticOperator.Sub0 => return typedNode "(arithmeticOperator)" "arithmeticOperator.Sub0" []
  | arithmeticOperator.Shl => return typedNode "(arithmeticOperator)" "arithmeticOperator.Shl" []
  | arithmeticOperator.Shr => return typedNode "(arithmeticOperator)" "arithmeticOperator.Shr" []
  | arithmeticOperator.Band => return typedNode "(arithmeticOperator)" "arithmeticOperator.Band" []
  | arithmeticOperator.Bxor => return typedNode "(arithmeticOperator)" "arithmeticOperator.Bxor" []
  | arithmeticOperator.Bor => return typedNode "(arithmeticOperator)" "arithmeticOperator.Bor" []

private def q_binaryOperator : (binaryOperator) → Result
  | binaryOperator.Arithmetic x0 => return typedNode "(binaryOperator)" "binaryOperator.Arithmetic" [← q_arithmeticOperator x0]
  | binaryOperator.Comma => return typedNode "(binaryOperator)" "binaryOperator.Comma" []
  | binaryOperator.And0 => return typedNode "(binaryOperator)" "binaryOperator.And0" []
  | binaryOperator.Or0 => return typedNode "(binaryOperator)" "binaryOperator.Or0" []
  | binaryOperator.Lt => return typedNode "(binaryOperator)" "binaryOperator.Lt" []
  | binaryOperator.Gt => return typedNode "(binaryOperator)" "binaryOperator.Gt" []
  | binaryOperator.Le => return typedNode "(binaryOperator)" "binaryOperator.Le" []
  | binaryOperator.Ge => return typedNode "(binaryOperator)" "binaryOperator.Ge" []
  | binaryOperator.Eq1 => return typedNode "(binaryOperator)" "binaryOperator.Eq1" []
  | binaryOperator.Ne0 => return typedNode "(binaryOperator)" "binaryOperator.Ne0" []

private def q_binop : (binop) → Result
  | binop.OpAdd => return typedNode "(binop)" "binop.OpAdd" []
  | binop.OpSub => return typedNode "(binop)" "binop.OpSub" []
  | binop.OpMul => return typedNode "(binop)" "binop.OpMul" []
  | binop.OpDiv => return typedNode "(binop)" "binop.OpDiv" []
  | binop.OpRem_t => return typedNode "(binop)" "binop.OpRem_t" []
  | binop.OpRem_f => return typedNode "(binop)" "binop.OpRem_f" []
  | binop.OpExp => return typedNode "(binop)" "binop.OpExp" []
  | binop.OpEq => return typedNode "(binop)" "binop.OpEq" []
  | binop.OpGt => return typedNode "(binop)" "binop.OpGt" []
  | binop.OpLt => return typedNode "(binop)" "binop.OpLt" []
  | binop.OpGe => return typedNode "(binop)" "binop.OpGe" []
  | binop.OpLe => return typedNode "(binop)" "binop.OpLe" []
  | binop.OpAnd => return typedNode "(binop)" "binop.OpAnd" []
  | binop.OpOr => return typedNode "(binop)" "binop.OpOr" []

private def q_calling_convention : (calling_convention) → Result
  | calling_convention.Normal_callconv => return typedNode "(calling_convention)" "calling_convention.Normal_callconv" []
  | calling_convention.Inner_arg_callconv => return typedNode "(calling_convention)" "calling_convention.Inner_arg_callconv" []

private partial def q_core_object_type : (core_object_type) → Result
  | core_object_type.OTy_integer => return typedNode "(core_object_type)" "core_object_type.OTy_integer" []
  | core_object_type.OTy_floating => return typedNode "(core_object_type)" "core_object_type.OTy_floating" []
  | core_object_type.OTy_pointer => return typedNode "(core_object_type)" "core_object_type.OTy_pointer" []
  | core_object_type.OTy_array x0 => return typedNode "(core_object_type)" "core_object_type.OTy_array" [← q_core_object_type x0]
  | core_object_type.OTy_struct x0 => return typedNode "(core_object_type)" "core_object_type.OTy_struct" [← q_sym x0]
  | core_object_type.OTy_union x0 => return typedNode "(core_object_type)" "core_object_type.OTy_union" [← q_sym x0]

private partial def q_core_base_type : (core_base_type) → Result
  | core_base_type.BTy_unit => return typedNode "(core_base_type)" "core_base_type.BTy_unit" []
  | core_base_type.BTy_boolean => return typedNode "(core_base_type)" "core_base_type.BTy_boolean" []
  | core_base_type.BTy_ctype => return typedNode "(core_base_type)" "core_base_type.BTy_ctype" []
  | core_base_type.BTy_list x0 => return typedNode "(core_base_type)" "core_base_type.BTy_list" [← q_core_base_type x0]
  | core_base_type.BTy_tuple x0 => return typedNode "(core_base_type)" "core_base_type.BTy_tuple" [← (qList "(core_base_type)" q_core_base_type) x0]
  | core_base_type.BTy_object x0 => return typedNode "(core_base_type)" "core_base_type.BTy_object" [← q_core_object_type x0]
  | core_base_type.BTy_loaded x0 => return typedNode "(core_base_type)" "core_base_type.BTy_loaded" [← q_core_object_type x0]
  | core_base_type.BTy_storable => return typedNode "(core_base_type)" "core_base_type.BTy_storable" []

private def q_core_run_annotation : (core_run_annotation) → Result
  | core_run_annotation.mk x0 x1 x2 => return typedNode "(core_run_annotation)" "core_run_annotation.mk" [← (qPset (qProd qNat qNat)) x0, ← (qPset qNat) x1, ← (qPset qNat) x2]

private def q_ctor : (ctor) → Result
  | ctor.Cnil x0 => return typedNode "(ctor)" "ctor.Cnil" [← q_core_base_type x0]
  | ctor.Ccons => return typedNode "(ctor)" "ctor.Ccons" []
  | ctor.Ctuple => return typedNode "(ctor)" "ctor.Ctuple" []
  | ctor.Carray => return typedNode "(ctor)" "ctor.Carray" []
  | ctor.Civmax => return typedNode "(ctor)" "ctor.Civmax" []
  | ctor.Civmin => return typedNode "(ctor)" "ctor.Civmin" []
  | ctor.Civsizeof => return typedNode "(ctor)" "ctor.Civsizeof" []
  | ctor.Civalignof => return typedNode "(ctor)" "ctor.Civalignof" []
  | ctor.CivCOMPL => return typedNode "(ctor)" "ctor.CivCOMPL" []
  | ctor.CivAND => return typedNode "(ctor)" "ctor.CivAND" []
  | ctor.CivOR => return typedNode "(ctor)" "ctor.CivOR" []
  | ctor.CivXOR => return typedNode "(ctor)" "ctor.CivXOR" []
  | ctor.Cspecified => return typedNode "(ctor)" "ctor.Cspecified" []
  | ctor.Cunspecified => return typedNode "(ctor)" "ctor.Cunspecified" []
  | ctor.Cfvfromint => return typedNode "(ctor)" "ctor.Cfvfromint" []
  | ctor.Civfromfloat => return typedNode "(ctor)" "ctor.Civfromfloat" []
  | ctor.CivNULLcap x0 => return typedNode "(ctor)" "ctor.CivNULLcap" [← qBool x0]

private def q_unaryOperator : (unaryOperator) → Result
  | unaryOperator.Plus => return typedNode "(unaryOperator)" "unaryOperator.Plus" []
  | unaryOperator.Minus => return typedNode "(unaryOperator)" "unaryOperator.Minus" []
  | unaryOperator.Bnot => return typedNode "(unaryOperator)" "unaryOperator.Bnot" []
  | unaryOperator.Address => return typedNode "(unaryOperator)" "unaryOperator.Address" []
  | unaryOperator.Indirection => return typedNode "(unaryOperator)" "unaryOperator.Indirection" []
  | unaryOperator.PostfixIncr => return typedNode "(unaryOperator)" "unaryOperator.PostfixIncr" []
  | unaryOperator.PostfixDecr => return typedNode "(unaryOperator)" "unaryOperator.PostfixDecr" []

private def q_derivecap_op : (derivecap_op) → Result
  | derivecap_op.DCunary x0 => return typedNode "(derivecap_op)" "derivecap_op.DCunary" [← q_unaryOperator x0]
  | derivecap_op.DCbinary x0 => return typedNode "(derivecap_op)" "derivecap_op.DCbinary" [← q_binaryOperator x0]

private def q_dyn_annotation : (dyn_annotation) → Result
  | dyn_annotation.DA_neg x0 x1 x2 => return typedNode "(dyn_annotation)" "dyn_annotation.DA_neg" [← qNat x0, ← (qList "Nat" qNat) x1, ← q_CerbMem_Footprint x2]
  | dyn_annotation.DA_pos x0 x1 => return typedNode "(dyn_annotation)" "dyn_annotation.DA_pos" [← (qList "Nat" qNat) x0, ← q_CerbMem_Footprint x1]

private def q_flexible_array_member : (flexible_array_member) → Result
  | flexible_array_member.FlexibleArrayMember x0 x1 x2 x3 => return typedNode "(flexible_array_member)" "flexible_array_member.FlexibleArrayMember" [← q_attributes x0, ← q_identifier x1, ← q_qualifiers x2, ← q_ctype x3]

private def q_implementation_constant : (implementation_constant) → Result
  | implementation_constant.Environment__startup_name => return typedNode "(implementation_constant)" "implementation_constant.Environment__startup_name" []
  | implementation_constant.Environment__startup_type => return typedNode "(implementation_constant)" "implementation_constant.Environment__startup_type" []
  | implementation_constant.Characters__bits_in_byte => return typedNode "(implementation_constant)" "implementation_constant.Characters__bits_in_byte" []
  | implementation_constant.Characters__execution_character_set_values => return typedNode "(implementation_constant)" "implementation_constant.Characters__execution_character_set_values" []
  | implementation_constant.Characters__TODO1 => return typedNode "(implementation_constant)" "implementation_constant.Characters__TODO1" []
  | implementation_constant.Characters__TODO2 => return typedNode "(implementation_constant)" "implementation_constant.Characters__TODO2" []
  | implementation_constant.Characters__plain_char_is_signed => return typedNode "(implementation_constant)" "implementation_constant.Characters__plain_char_is_signed" []
  | implementation_constant.Characters__TODO3 => return typedNode "(implementation_constant)" "implementation_constant.Characters__TODO3" []
  | implementation_constant.Characters__TODO4 => return typedNode "(implementation_constant)" "implementation_constant.Characters__TODO4" []
  | implementation_constant.Characters__TODO5 => return typedNode "(implementation_constant)" "implementation_constant.Characters__TODO5" []
  | implementation_constant.Characters__TODO6 => return typedNode "(implementation_constant)" "implementation_constant.Characters__TODO6" []
  | implementation_constant.Characters__TODO7 => return typedNode "(implementation_constant)" "implementation_constant.Characters__TODO7" []
  | implementation_constant.Characters__TODO8 => return typedNode "(implementation_constant)" "implementation_constant.Characters__TODO8" []
  | implementation_constant.Characters__TODO9 => return typedNode "(implementation_constant)" "implementation_constant.Characters__TODO9" []
  | implementation_constant.Characters__TODO10 => return typedNode "(implementation_constant)" "implementation_constant.Characters__TODO10" []
  | implementation_constant.Integer__encode => return typedNode "(implementation_constant)" "implementation_constant.Integer__encode" []
  | implementation_constant.Integer__decode => return typedNode "(implementation_constant)" "implementation_constant.Integer__decode" []
  | implementation_constant.Integer__conv_nonrepresentable_signed_integer => return typedNode "(implementation_constant)" "implementation_constant.Integer__conv_nonrepresentable_signed_integer" []
  | implementation_constant.Sizeof => return typedNode "(implementation_constant)" "implementation_constant.Sizeof" []
  | implementation_constant.Alignof => return typedNode "(implementation_constant)" "implementation_constant.Alignof" []
  | implementation_constant.SHR_signed_negative => return typedNode "(implementation_constant)" "implementation_constant.SHR_signed_negative" []
  | implementation_constant.Bitwise_complement => return typedNode "(implementation_constant)" "implementation_constant.Bitwise_complement" []
  | implementation_constant.Plain_bitfield_sign => return typedNode "(implementation_constant)" "implementation_constant.Plain_bitfield_sign" []
  | implementation_constant.Bitfield_other_types => return typedNode "(implementation_constant)" "implementation_constant.Bitfield_other_types" []
  | implementation_constant.Atomic_bitfield_permitted => return typedNode "(implementation_constant)" "implementation_constant.Atomic_bitfield_permitted" []
  | implementation_constant.Ctype_min => return typedNode "(implementation_constant)" "implementation_constant.Ctype_min" []
  | implementation_constant.Ctype_max => return typedNode "(implementation_constant)" "implementation_constant.Ctype_max" []
  | implementation_constant.BuiltinFunction x0 => return typedNode "(implementation_constant)" "implementation_constant.BuiltinFunction" [← qString x0]

private def q_generic_name : (generic_name (sym)) → Result
  | generic_name.Sym x0 => return typedNode "(generic_name (sym))" "generic_name.Sym" [← q_sym x0]
  | generic_name.Impl x0 => return typedNode "(generic_name (sym))" "generic_name.Impl" [← q_implementation_constant x0]

mutual
private partial def q_generic_pattern : (generic_pattern (sym)) → Result
  | generic_pattern.Pattern x0 x1 => return typedNode "(generic_pattern (sym))" "generic_pattern.Pattern" [← (qList "(annot)" q_annot) x0, ← q_generic_pattern_ x1]

private partial def q_generic_pattern_ : (generic_pattern_ (sym)) → Result
  | generic_pattern_.CaseBase x0 => return typedNode "(generic_pattern_ (sym))" "generic_pattern_.CaseBase" [← (qProd (qOption q_sym) q_core_base_type) x0]
  | generic_pattern_.CaseCtor x0 x1 => return typedNode "(generic_pattern_ (sym))" "generic_pattern_.CaseCtor" [← q_ctor x0, ← (qList "(generic_pattern (sym))" q_generic_pattern) x1]

end

private def q_iop : (iop) → Result
  | iop.IOpAdd => return typedNode "(iop)" "iop.IOpAdd" []
  | iop.IOpSub => return typedNode "(iop)" "iop.IOpSub" []
  | iop.IOpMul => return typedNode "(iop)" "iop.IOpMul" []
  | iop.IOpShl => return typedNode "(iop)" "iop.IOpShl" []
  | iop.IOpShr => return typedNode "(iop)" "iop.IOpShr" []
  | iop.IOpDiv => return typedNode "(iop)" "iop.IOpDiv" []
  | iop.IOpRem_t => return typedNode "(iop)" "iop.IOpRem_t" []

private partial def q_mem_constraint : (mem_constraint (CerbMem.IntegerValue)) → Result
  | mem_constraint.MC_empty => return typedNode "(mem_constraint (CerbMem.IntegerValue))" "mem_constraint.MC_empty" []
  | mem_constraint.MC_eq x0 x1 => return typedNode "(mem_constraint (CerbMem.IntegerValue))" "mem_constraint.MC_eq" [← q_CerbMem_IntegerValue x0, ← q_CerbMem_IntegerValue x1]
  | mem_constraint.MC_le x0 x1 => return typedNode "(mem_constraint (CerbMem.IntegerValue))" "mem_constraint.MC_le" [← q_CerbMem_IntegerValue x0, ← q_CerbMem_IntegerValue x1]
  | mem_constraint.MC_lt x0 x1 => return typedNode "(mem_constraint (CerbMem.IntegerValue))" "mem_constraint.MC_lt" [← q_CerbMem_IntegerValue x0, ← q_CerbMem_IntegerValue x1]
  | mem_constraint.MC_in_device x0 => return typedNode "(mem_constraint (CerbMem.IntegerValue))" "mem_constraint.MC_in_device" [← q_CerbMem_IntegerValue x0]
  | mem_constraint.MC_or x0 x1 => return typedNode "(mem_constraint (CerbMem.IntegerValue))" "mem_constraint.MC_or" [← q_mem_constraint x0, ← q_mem_constraint x1]
  | mem_constraint.MC_conj x0 => return typedNode "(mem_constraint (CerbMem.IntegerValue))" "mem_constraint.MC_conj" [← (qList "(mem_constraint (CerbMem.IntegerValue))" q_mem_constraint) x0]
  | mem_constraint.MC_not x0 => return typedNode "(mem_constraint (CerbMem.IntegerValue))" "mem_constraint.MC_not" [← q_mem_constraint x0]

private def q_pure_memop : (pure_memop) → Result
  | pure_memop.DeriveCap x0 x1 => return typedNode "(pure_memop)" "pure_memop.DeriveCap" [← q_derivecap_op x0, ← qBool x1]
  | pure_memop.CapAssignValue => return typedNode "(pure_memop)" "pure_memop.CapAssignValue" []
  | pure_memop.Ptr_tIntValue => return typedNode "(pure_memop)" "pure_memop.Ptr_tIntValue" []
  | pure_memop.ByteFromInt => return typedNode "(pure_memop)" "pure_memop.ByteFromInt" []
  | pure_memop.IntFromByte => return typedNode "(pure_memop)" "pure_memop.IntFromByte" []

private def q_undefined_by_omission : (undefined_by_omission) → Result
  | undefined_by_omission.UB_OMIT_memcpy_non_object => return typedNode "(undefined_by_omission)" "undefined_by_omission.UB_OMIT_memcpy_non_object" []
  | undefined_by_omission.UB_OMIT_memcpy_out_of_bound => return typedNode "(undefined_by_omission)" "undefined_by_omission.UB_OMIT_memcpy_out_of_bound" []

private def q_unspecified_ub_context : (unspecified_ub_context) → Result
  | unspecified_ub_context.UB_unspec_equality_ptr_vs_NULL => return typedNode "(unspecified_ub_context)" "unspecified_ub_context.UB_unspec_equality_ptr_vs_NULL" []
  | unspecified_ub_context.UB_unspec_equality_both_arith_or_ptr => return typedNode "(unspecified_ub_context)" "unspecified_ub_context.UB_unspec_equality_both_arith_or_ptr" []
  | unspecified_ub_context.UB_unspec_pointer_add => return typedNode "(unspecified_ub_context)" "unspecified_ub_context.UB_unspec_pointer_add" []
  | unspecified_ub_context.UB_unspec_pointer_sub => return typedNode "(unspecified_ub_context)" "unspecified_ub_context.UB_unspec_pointer_sub" []
  | unspecified_ub_context.UB_unspec_conditional => return typedNode "(unspecified_ub_context)" "unspecified_ub_context.UB_unspec_conditional" []
  | unspecified_ub_context.UB_unspec_copy_alloc_id => return typedNode "(unspecified_ub_context)" "unspecified_ub_context.UB_unspec_copy_alloc_id" []
  | unspecified_ub_context.UB_unspec_rvalue_memberof => return typedNode "(unspecified_ub_context)" "unspecified_ub_context.UB_unspec_rvalue_memberof" []
  | unspecified_ub_context.UB_unspec_memberofptr => return typedNode "(unspecified_ub_context)" "unspecified_ub_context.UB_unspec_memberofptr" []
  | unspecified_ub_context.UB_unspec_do => return typedNode "(unspecified_ub_context)" "unspecified_ub_context.UB_unspec_do" []

private def q_undefined_behaviour : (undefined_behaviour) → Result
  | undefined_behaviour.DUMMY x0 => return typedNode "(undefined_behaviour)" "undefined_behaviour.DUMMY" [← qString x0]
  | undefined_behaviour.UB_unspecified_lvalue => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB_unspecified_lvalue" []
  | undefined_behaviour.UB_std_omission x0 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB_std_omission" [← q_undefined_by_omission x0]
  | undefined_behaviour.UB001 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB001" []
  | undefined_behaviour.UB002 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB002" []
  | undefined_behaviour.UB003 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB003" []
  | undefined_behaviour.UB004a_incorrect_main_return_type => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB004a_incorrect_main_return_type" []
  | undefined_behaviour.UB004b_incorrect_main_argument1 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB004b_incorrect_main_argument1" []
  | undefined_behaviour.UB004c_incorrect_main_argument2 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB004c_incorrect_main_argument2" []
  | undefined_behaviour.UB004d_main_not_function => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB004d_main_not_function" []
  | undefined_behaviour.UB005_data_race => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB005_data_race" []
  | undefined_behaviour.UB006 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB006" []
  | undefined_behaviour.UB007 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB007" []
  | undefined_behaviour.UB008_multiple_linkage => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB008_multiple_linkage" []
  | undefined_behaviour.UB009_outside_lifetime => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB009_outside_lifetime" []
  | undefined_behaviour.UB010_pointer_to_dead_object => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB010_pointer_to_dead_object" []
  | undefined_behaviour.UB011_use_indeterminate_automatic_object => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB011_use_indeterminate_automatic_object" []
  | undefined_behaviour.UB_modifying_temporary_lifetime => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB_modifying_temporary_lifetime" []
  | undefined_behaviour.UB012_lvalue_read_trap_representation => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB012_lvalue_read_trap_representation" []
  | undefined_behaviour.UB013_lvalue_side_effect_trap_representation => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB013_lvalue_side_effect_trap_representation" []
  | undefined_behaviour.UB014_unsupported_negative_zero => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB014_unsupported_negative_zero" []
  | undefined_behaviour.UB015_incompatible_redeclaration => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB015_incompatible_redeclaration" []
  | undefined_behaviour.UB016 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB016" []
  | undefined_behaviour.UB017_out_of_range_floating_integer_conversion => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB017_out_of_range_floating_integer_conversion" []
  | undefined_behaviour.UB018 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB018" []
  | undefined_behaviour.UB019_lvalue_not_an_object => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB019_lvalue_not_an_object" []
  | undefined_behaviour.UB020_nonarray_incomplete_lvalue_conversion => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB020_nonarray_incomplete_lvalue_conversion" []
  | undefined_behaviour.UB021 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB021" []
  | undefined_behaviour.UB022_register_array_decay => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB022_register_array_decay" []
  | undefined_behaviour.UB023 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB023" []
  | undefined_behaviour.UB024_out_of_range_pointer_to_integer_conversion => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB024_out_of_range_pointer_to_integer_conversion" []
  | undefined_behaviour.UB025_misaligned_pointer_conversion => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB025_misaligned_pointer_conversion" []
  | undefined_behaviour.UB026 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB026" []
  | undefined_behaviour.UB027 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB027" []
  | undefined_behaviour.UB028 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB028" []
  | undefined_behaviour.UB029 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB029" []
  | undefined_behaviour.UB030 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB030" []
  | undefined_behaviour.UB031 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB031" []
  | undefined_behaviour.UB032 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB032" []
  | undefined_behaviour.UB033_modifying_string_literal => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB033_modifying_string_literal" []
  | undefined_behaviour.UB034 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB034" []
  | undefined_behaviour.UB035_unsequenced_race => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB035_unsequenced_race" []
  | undefined_behaviour.UB036_exceptional_condition => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB036_exceptional_condition" []
  | undefined_behaviour.UB037_illtyped_load => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB037_illtyped_load" []
  | undefined_behaviour.UB038_number_of_args => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB038_number_of_args" []
  | undefined_behaviour.UB039 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB039" []
  | undefined_behaviour.UB040 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB040" []
  | undefined_behaviour.UB041_function_not_compatible => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB041_function_not_compatible" []
  | undefined_behaviour.UB042_access_atomic_structUnion_member => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB042_access_atomic_structUnion_member" []
  | undefined_behaviour.UB043_indirection_invalid_value => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB043_indirection_invalid_value" []
  | undefined_behaviour.UB044 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB044" []
  | undefined_behaviour.UB045a_division_by_zero => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB045a_division_by_zero" []
  | undefined_behaviour.UB045b_modulo_by_zero => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB045b_modulo_by_zero" []
  | undefined_behaviour.UB045c_quotient_not_representable => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB045c_quotient_not_representable" []
  | undefined_behaviour.UB046_array_pointer_outside => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB046_array_pointer_outside" []
  | undefined_behaviour.UB047a_array_pointer_addition_beyond_indirection => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB047a_array_pointer_addition_beyond_indirection" []
  | undefined_behaviour.UB047b_array_pointer_subtraction_beyond_indirection => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB047b_array_pointer_subtraction_beyond_indirection" []
  | undefined_behaviour.UB048_disjoint_array_pointers_subtraction => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB048_disjoint_array_pointers_subtraction" []
  | undefined_behaviour.UB049 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB049" []
  | undefined_behaviour.UB050_pointers_subtraction_not_representable => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB050_pointers_subtraction_not_representable" []
  | undefined_behaviour.UB051a_negative_shift => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB051a_negative_shift" []
  | undefined_behaviour.UB51b_shift_too_large => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB51b_shift_too_large" []
  | undefined_behaviour.UB052a_negative_left_shift => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB052a_negative_left_shift" []
  | undefined_behaviour.UB052b_non_representable_left_shift => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB052b_non_representable_left_shift" []
  | undefined_behaviour.UB053_distinct_aggregate_union_pointer_comparison => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB053_distinct_aggregate_union_pointer_comparison" []
  | undefined_behaviour.UB054a_inexactly_overlapping_assignment => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB054a_inexactly_overlapping_assignment" []
  | undefined_behaviour.UB054b_incompatible_overlapping_assignment => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB054b_incompatible_overlapping_assignment" []
  | undefined_behaviour.UB055_invalid_integer_constant_expression => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB055_invalid_integer_constant_expression" []
  | undefined_behaviour.UB056 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB056" []
  | undefined_behaviour.UB057 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB057" []
  | undefined_behaviour.UB058 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB058" []
  | undefined_behaviour.UB059_incomplete_no_linkage_identifier => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB059_incomplete_no_linkage_identifier" []
  | undefined_behaviour.UB060_block_scope_function_with_storage_class => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB060_block_scope_function_with_storage_class" []
  | undefined_behaviour.UB061_no_named_members => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB061_no_named_members" []
  | undefined_behaviour.UB062 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB062" []
  | undefined_behaviour.UB063 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB063" []
  | undefined_behaviour.UB064_modifying_const => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB064_modifying_const" []
  | undefined_behaviour.UB065 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB065" []
  | undefined_behaviour.UB066_qualified_function_specification => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB066_qualified_function_specification" []
  | undefined_behaviour.UB067 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB067" []
  | undefined_behaviour.UB068 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB068" []
  | undefined_behaviour.UB069 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB069" []
  | undefined_behaviour.UB070_inline_not_defined => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB070_inline_not_defined" []
  | undefined_behaviour.UB071_noreturn => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB071_noreturn" []
  | undefined_behaviour.UB072_incompatible_alignment_specifiers => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB072_incompatible_alignment_specifiers" []
  | undefined_behaviour.UB073 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB073" []
  | undefined_behaviour.UB074 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB074" []
  | undefined_behaviour.UB075 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB075" []
  | undefined_behaviour.UB076 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB076" []
  | undefined_behaviour.UB077 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB077" []
  | undefined_behaviour.UB078_modified_void_parameter => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB078_modified_void_parameter" []
  | undefined_behaviour.UB079 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB079" []
  | undefined_behaviour.UB080 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB080" []
  | undefined_behaviour.UB081_scalar_initializer_not_single_expression => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB081_scalar_initializer_not_single_expression" []
  | undefined_behaviour.UB082 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB082" []
  | undefined_behaviour.UB083 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB083" []
  | undefined_behaviour.UB084 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB084" []
  | undefined_behaviour.UB085 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB085" []
  | undefined_behaviour.UB086_incomplete_adjusted_parameter => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB086_incomplete_adjusted_parameter" []
  | undefined_behaviour.UB087 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB087" []
  | undefined_behaviour.UB088_reached_end_of_function => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB088_reached_end_of_function" []
  | undefined_behaviour.UB089_tentative_definition_internal_linkage => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB089_tentative_definition_internal_linkage" []
  | undefined_behaviour.UB090 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB090" []
  | undefined_behaviour.UB091 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB091" []
  | undefined_behaviour.UB092 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB092" []
  | undefined_behaviour.UB093 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB093" []
  | undefined_behaviour.UB094 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB094" []
  | undefined_behaviour.UB095 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB095" []
  | undefined_behaviour.UB096 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB096" []
  | undefined_behaviour.UB097 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB097" []
  | undefined_behaviour.UB098 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB098" []
  | undefined_behaviour.UB099 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB099" []
  | undefined_behaviour.UB100 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB100" []
  | undefined_behaviour.UB101 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB101" []
  | undefined_behaviour.UB102 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB102" []
  | undefined_behaviour.UB103 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB103" []
  | undefined_behaviour.UB104 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB104" []
  | undefined_behaviour.UB105 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB105" []
  | undefined_behaviour.UB106 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB106" []
  | undefined_behaviour.UB107 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB107" []
  | undefined_behaviour.UB108 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB108" []
  | undefined_behaviour.UB109 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB109" []
  | undefined_behaviour.UB110 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB110" []
  | undefined_behaviour.UB111_illtyped_assert => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB111_illtyped_assert" []
  | undefined_behaviour.UB112 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB112" []
  | undefined_behaviour.UB113 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB113" []
  | undefined_behaviour.UB114 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB114" []
  | undefined_behaviour.UB115 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB115" []
  | undefined_behaviour.UB116 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB116" []
  | undefined_behaviour.UB117 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB117" []
  | undefined_behaviour.UB118 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB118" []
  | undefined_behaviour.UB119 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB119" []
  | undefined_behaviour.UB120 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB120" []
  | undefined_behaviour.UB121 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB121" []
  | undefined_behaviour.UB122 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB122" []
  | undefined_behaviour.UB123 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB123" []
  | undefined_behaviour.UB124 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB124" []
  | undefined_behaviour.UB125 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB125" []
  | undefined_behaviour.UB126 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB126" []
  | undefined_behaviour.UB127 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB127" []
  | undefined_behaviour.UB128 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB128" []
  | undefined_behaviour.UB129 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB129" []
  | undefined_behaviour.UB130 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB130" []
  | undefined_behaviour.UB131 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB131" []
  | undefined_behaviour.UB132 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB132" []
  | undefined_behaviour.UB133 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB133" []
  | undefined_behaviour.UB134 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB134" []
  | undefined_behaviour.UB135 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB135" []
  | undefined_behaviour.UB136 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB136" []
  | undefined_behaviour.UB137 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB137" []
  | undefined_behaviour.UB138 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB138" []
  | undefined_behaviour.UB139 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB139" []
  | undefined_behaviour.UB140 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB140" []
  | undefined_behaviour.UB141 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB141" []
  | undefined_behaviour.UB142 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB142" []
  | undefined_behaviour.UB143 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB143" []
  | undefined_behaviour.UB144 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB144" []
  | undefined_behaviour.UB145 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB145" []
  | undefined_behaviour.UB146 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB146" []
  | undefined_behaviour.UB147 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB147" []
  | undefined_behaviour.UB148 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB148" []
  | undefined_behaviour.UB149 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB149" []
  | undefined_behaviour.UB150 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB150" []
  | undefined_behaviour.UB151 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB151" []
  | undefined_behaviour.UB152 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB152" []
  | undefined_behaviour.UB153a_insufficient_arguments_for_format => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB153a_insufficient_arguments_for_format" []
  | undefined_behaviour.UB153b_illtyped_argument_for_format => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB153b_illtyped_argument_for_format" []
  | undefined_behaviour.Invalid_format x0 => return typedNode "(undefined_behaviour)" "undefined_behaviour.Invalid_format" [← qString x0]
  | undefined_behaviour.UB154 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB154" []
  | undefined_behaviour.UB155 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB155" []
  | undefined_behaviour.UB156 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB156" []
  | undefined_behaviour.UB157 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB157" []
  | undefined_behaviour.UB158_invalid_length_modifier => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB158_invalid_length_modifier" []
  | undefined_behaviour.UB159 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB159" []
  | undefined_behaviour.UB160 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB160" []
  | undefined_behaviour.UB161 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB161" []
  | undefined_behaviour.UB162 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB162" []
  | undefined_behaviour.UB163 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB163" []
  | undefined_behaviour.UB164 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB164" []
  | undefined_behaviour.UB165 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB165" []
  | undefined_behaviour.UB166 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB166" []
  | undefined_behaviour.UB167 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB167" []
  | undefined_behaviour.UB168 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB168" []
  | undefined_behaviour.UB169 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB169" []
  | undefined_behaviour.UB170 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB170" []
  | undefined_behaviour.UB171 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB171" []
  | undefined_behaviour.UB172 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB172" []
  | undefined_behaviour.UB173 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB173" []
  | undefined_behaviour.UB174 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB174" []
  | undefined_behaviour.UB175 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB175" []
  | undefined_behaviour.UB176 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB176" []
  | undefined_behaviour.UB177 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB177" []
  | undefined_behaviour.UB178 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB178" []
  | undefined_behaviour.UB179a_non_matching_allocation_free => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB179a_non_matching_allocation_free" []
  | undefined_behaviour.UB179b_dead_allocation_free => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB179b_dead_allocation_free" []
  | undefined_behaviour.UB179c_non_matching_allocation_realloc => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB179c_non_matching_allocation_realloc" []
  | undefined_behaviour.UB179d_dead_allocation_realloc => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB179d_dead_allocation_realloc" []
  | undefined_behaviour.UB180 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB180" []
  | undefined_behaviour.UB181 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB181" []
  | undefined_behaviour.UB182 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB182" []
  | undefined_behaviour.UB183 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB183" []
  | undefined_behaviour.UB184 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB184" []
  | undefined_behaviour.UB185 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB185" []
  | undefined_behaviour.UB186 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB186" []
  | undefined_behaviour.UB187 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB187" []
  | undefined_behaviour.UB188 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB188" []
  | undefined_behaviour.UB189 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB189" []
  | undefined_behaviour.UB190 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB190" []
  | undefined_behaviour.UB191 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB191" []
  | undefined_behaviour.UB192 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB192" []
  | undefined_behaviour.UB193 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB193" []
  | undefined_behaviour.UB194 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB194" []
  | undefined_behaviour.UB195 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB195" []
  | undefined_behaviour.UB196 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB196" []
  | undefined_behaviour.UB197 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB197" []
  | undefined_behaviour.UB198 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB198" []
  | undefined_behaviour.UB199 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB199" []
  | undefined_behaviour.UB200 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB200" []
  | undefined_behaviour.UB201 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB201" []
  | undefined_behaviour.UB202 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB202" []
  | undefined_behaviour.UB203 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB203" []
  | undefined_behaviour.UB204_illtyped_Static_assert => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB204_illtyped_Static_assert" []
  | undefined_behaviour.UB205_atomic_store_memorder => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB205_atomic_store_memorder" []
  | undefined_behaviour.UB206_atomic_load_memorder => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB206_atomic_load_memorder" []
  | undefined_behaviour.UB207_atomic_compare_exchange_memorder => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB207_atomic_compare_exchange_memorder" []
  | undefined_behaviour.UB_CERB001_integer_to_dead_pointer => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB_CERB001_integer_to_dead_pointer" []
  | undefined_behaviour.UB_CERB002a_out_of_bound_load => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB_CERB002a_out_of_bound_load" []
  | undefined_behaviour.UB_CERB002b_out_of_bound_store => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB_CERB002b_out_of_bound_store" []
  | undefined_behaviour.UB_CERB002c_out_of_bound_free => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB_CERB002c_out_of_bound_free" []
  | undefined_behaviour.UB_CERB002d_out_of_bound_realloc => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB_CERB002d_out_of_bound_realloc" []
  | undefined_behaviour.UB_CERB003_invalid_function_pointer => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB_CERB003_invalid_function_pointer" []
  | undefined_behaviour.UB_CHERI_InvalidCap => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB_CHERI_InvalidCap" []
  | undefined_behaviour.UB_CHERI_InsufficientPermissions => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB_CHERI_InsufficientPermissions" []
  | undefined_behaviour.UB_CHERI_BoundsViolation => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB_CHERI_BoundsViolation" []
  | undefined_behaviour.UB_CHERI_UndefinedTag => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB_CHERI_UndefinedTag" []
  | undefined_behaviour.UB_CHERI_ZeroLength => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB_CHERI_ZeroLength" []
  | undefined_behaviour.UB_CERB004_unspecified x0 => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB_CERB004_unspecified" [← q_unspecified_ub_context x0]
  | undefined_behaviour.UB_CERB005_free_nullptr => return typedNode "(undefined_behaviour)" "undefined_behaviour.UB_CERB005_free_nullptr" []

mutual
private partial def q_loaded_value : (loaded_value) → Result
  | loaded_value.LVspecified x0 => return typedNode "(loaded_value)" "loaded_value.LVspecified" [← q_object_value x0]
  | loaded_value.LVunspecified x0 => return typedNode "(loaded_value)" "loaded_value.LVunspecified" [← q_ctype x0]

private partial def q_object_value : (object_value) → Result
  | object_value.OVinteger x0 => return typedNode "(object_value)" "object_value.OVinteger" [← q_CerbMem_IntegerValue x0]
  | object_value.OVfloating x0 => return typedNode "(object_value)" "object_value.OVfloating" [← quoteFloat x0]
  | object_value.OVpointer x0 => return typedNode "(object_value)" "object_value.OVpointer" [← q_CerbMem_PointerValue x0]
  | object_value.OVarray x0 => return typedNode "(object_value)" "object_value.OVarray" [← (qList "(loaded_value)" q_loaded_value) x0]
  | object_value.OVstruct x0 x1 => return typedNode "(object_value)" "object_value.OVstruct" [← q_sym x0, ← (qList "(Prod (identifier) (Prod (ctype) (CerbMem.MemValue)))" (qProd q_identifier (qProd q_ctype q_CerbMem_MemValue))) x1]
  | object_value.OVunion x0 x1 x2 => return typedNode "(object_value)" "object_value.OVunion" [← q_sym x0, ← q_identifier x1, ← q_CerbMem_MemValue x2]

end

private partial def q_value : (value) → Result
  | value.Vobject x0 => return typedNode "(value)" "value.Vobject" [← q_object_value x0]
  | value.Vloaded x0 => return typedNode "(value)" "value.Vloaded" [← q_loaded_value x0]
  | value.Vunit => return typedNode "(value)" "value.Vunit" []
  | value.Vtrue => return typedNode "(value)" "value.Vtrue" []
  | value.Vfalse => return typedNode "(value)" "value.Vfalse" []
  | value.Vctype x0 => return typedNode "(value)" "value.Vctype" [← q_ctype x0]
  | value.Vlist x0 x1 => return typedNode "(value)" "value.Vlist" [← q_core_base_type x0, ← (qList "(value)" q_value) x1]
  | value.Vtuple x0 => return typedNode "(value)" "value.Vtuple" [← (qList "(value)" q_value) x0]

mutual
private partial def q_generic_pexpr : (generic_pexpr (PUnit) (sym)) → Result
  | generic_pexpr.Pexpr x0 x1 x2 => return typedNode "(generic_pexpr (PUnit) (sym))" "generic_pexpr.Pexpr" [← (qList "(annot)" q_annot) x0, ← qUnit x1, ← q_generic_pexpr_ x2]

private partial def q_generic_pexpr_ : (generic_pexpr_ (PUnit) (sym)) → Result
  | generic_pexpr_.PEsym x0 => return typedNode "(generic_pexpr_ (PUnit) (sym))" "generic_pexpr_.PEsym" [← q_sym x0]
  | generic_pexpr_.PEimpl x0 => return typedNode "(generic_pexpr_ (PUnit) (sym))" "generic_pexpr_.PEimpl" [← q_implementation_constant x0]
  | generic_pexpr_.PEval x0 => return typedNode "(generic_pexpr_ (PUnit) (sym))" "generic_pexpr_.PEval" [← q_value x0]
  | generic_pexpr_.PEconstrained x0 => return typedNode "(generic_pexpr_ (PUnit) (sym))" "generic_pexpr_.PEconstrained" [← (qList "(Prod (mem_constraint (CerbMem.IntegerValue)) (generic_pexpr (PUnit) (sym)))" (qProd q_mem_constraint q_generic_pexpr)) x0]
  | generic_pexpr_.PEundef x0 x1 => return typedNode "(generic_pexpr_ (PUnit) (sym))" "generic_pexpr_.PEundef" [← q_CerbLocation_Loc x0, ← q_undefined_behaviour x1]
  | generic_pexpr_.PEerror x0 x1 => return typedNode "(generic_pexpr_ (PUnit) (sym))" "generic_pexpr_.PEerror" [← qString x0, ← q_generic_pexpr x1]
  | generic_pexpr_.PEctor x0 x1 => return typedNode "(generic_pexpr_ (PUnit) (sym))" "generic_pexpr_.PEctor" [← q_ctor x0, ← (qList "(generic_pexpr (PUnit) (sym))" q_generic_pexpr) x1]
  | generic_pexpr_.PEcase x0 x1 => return typedNode "(generic_pexpr_ (PUnit) (sym))" "generic_pexpr_.PEcase" [← q_generic_pexpr x0, ← (qList "(Prod (generic_pattern (sym)) (generic_pexpr (PUnit) (sym)))" (qProd q_generic_pattern q_generic_pexpr)) x1]
  | generic_pexpr_.PEarray_shift x0 x1 x2 => return typedNode "(generic_pexpr_ (PUnit) (sym))" "generic_pexpr_.PEarray_shift" [← q_generic_pexpr x0, ← q_ctype x1, ← q_generic_pexpr x2]
  | generic_pexpr_.PEmember_shift x0 x1 x2 => return typedNode "(generic_pexpr_ (PUnit) (sym))" "generic_pexpr_.PEmember_shift" [← q_generic_pexpr x0, ← q_sym x1, ← q_identifier x2]
  | generic_pexpr_.PEmemop x0 x1 => return typedNode "(generic_pexpr_ (PUnit) (sym))" "generic_pexpr_.PEmemop" [← q_pure_memop x0, ← (qList "(generic_pexpr (PUnit) (sym))" q_generic_pexpr) x1]
  | generic_pexpr_.PEnot x0 => return typedNode "(generic_pexpr_ (PUnit) (sym))" "generic_pexpr_.PEnot" [← q_generic_pexpr x0]
  | generic_pexpr_.PEop x0 x1 x2 => return typedNode "(generic_pexpr_ (PUnit) (sym))" "generic_pexpr_.PEop" [← q_binop x0, ← q_generic_pexpr x1, ← q_generic_pexpr x2]
  | generic_pexpr_.PEconv_int x0 x1 => return typedNode "(generic_pexpr_ (PUnit) (sym))" "generic_pexpr_.PEconv_int" [← q_integerType x0, ← q_generic_pexpr x1]
  | generic_pexpr_.PEwrapI x0 x1 x2 x3 => return typedNode "(generic_pexpr_ (PUnit) (sym))" "generic_pexpr_.PEwrapI" [← q_integerType x0, ← q_iop x1, ← q_generic_pexpr x2, ← q_generic_pexpr x3]
  | generic_pexpr_.PEcatch_exceptional_condition x0 x1 x2 x3 => return typedNode "(generic_pexpr_ (PUnit) (sym))" "generic_pexpr_.PEcatch_exceptional_condition" [← q_integerType x0, ← q_iop x1, ← q_generic_pexpr x2, ← q_generic_pexpr x3]
  | generic_pexpr_.PEstruct x0 x1 => return typedNode "(generic_pexpr_ (PUnit) (sym))" "generic_pexpr_.PEstruct" [← q_sym x0, ← (qList "(Prod (identifier) (generic_pexpr (PUnit) (sym)))" (qProd q_identifier q_generic_pexpr)) x1]
  | generic_pexpr_.PEunion x0 x1 x2 => return typedNode "(generic_pexpr_ (PUnit) (sym))" "generic_pexpr_.PEunion" [← q_sym x0, ← q_identifier x1, ← q_generic_pexpr x2]
  | generic_pexpr_.PEcfunction x0 => return typedNode "(generic_pexpr_ (PUnit) (sym))" "generic_pexpr_.PEcfunction" [← q_generic_pexpr x0]
  | generic_pexpr_.PEmemberof x0 x1 x2 => return typedNode "(generic_pexpr_ (PUnit) (sym))" "generic_pexpr_.PEmemberof" [← q_sym x0, ← q_identifier x1, ← q_generic_pexpr x2]
  | generic_pexpr_.PEcall x0 x1 => return typedNode "(generic_pexpr_ (PUnit) (sym))" "generic_pexpr_.PEcall" [← q_generic_name x0, ← (qList "(generic_pexpr (PUnit) (sym))" q_generic_pexpr) x1]
  | generic_pexpr_.PElet x0 x1 x2 => return typedNode "(generic_pexpr_ (PUnit) (sym))" "generic_pexpr_.PElet" [← q_generic_pattern x0, ← q_generic_pexpr x1, ← q_generic_pexpr x2]
  | generic_pexpr_.PEif x0 x1 x2 => return typedNode "(generic_pexpr_ (PUnit) (sym))" "generic_pexpr_.PEif" [← q_generic_pexpr x0, ← q_generic_pexpr x1, ← q_generic_pexpr x2]
  | generic_pexpr_.PEis_scalar x0 => return typedNode "(generic_pexpr_ (PUnit) (sym))" "generic_pexpr_.PEis_scalar" [← q_generic_pexpr x0]
  | generic_pexpr_.PEis_integer x0 => return typedNode "(generic_pexpr_ (PUnit) (sym))" "generic_pexpr_.PEis_integer" [← q_generic_pexpr x0]
  | generic_pexpr_.PEis_signed x0 => return typedNode "(generic_pexpr_ (PUnit) (sym))" "generic_pexpr_.PEis_signed" [← q_generic_pexpr x0]
  | generic_pexpr_.PEis_unsigned x0 => return typedNode "(generic_pexpr_ (PUnit) (sym))" "generic_pexpr_.PEis_unsigned" [← q_generic_pexpr x0]
  | generic_pexpr_.PEbmc_assume x0 => return typedNode "(generic_pexpr_ (PUnit) (sym))" "generic_pexpr_.PEbmc_assume" [← q_generic_pexpr x0]
  | generic_pexpr_.PEare_compatible x0 x1 => return typedNode "(generic_pexpr_ (PUnit) (sym))" "generic_pexpr_.PEare_compatible" [← q_generic_pexpr x0, ← q_generic_pexpr x1]

end

private def q_kill_kind : (kill_kind) → Result
  | kill_kind.Dynamic0 => return typedNode "(kill_kind)" "kill_kind.Dynamic0" []
  | kill_kind.Static0 x0 => return typedNode "(kill_kind)" "kill_kind.Static0" [← q_ctype x0]

private def q_linux_memory_order : (linux_memory_order) → Result
  | linux_memory_order.Once => return typedNode "(linux_memory_order)" "linux_memory_order.Once" []
  | linux_memory_order.LAcquire => return typedNode "(linux_memory_order)" "linux_memory_order.LAcquire" []
  | linux_memory_order.LRelease => return typedNode "(linux_memory_order)" "linux_memory_order.LRelease" []
  | linux_memory_order.Rmb => return typedNode "(linux_memory_order)" "linux_memory_order.Rmb" []
  | linux_memory_order.Wmb => return typedNode "(linux_memory_order)" "linux_memory_order.Wmb" []
  | linux_memory_order.Mb => return typedNode "(linux_memory_order)" "linux_memory_order.Mb" []
  | linux_memory_order.RbDep => return typedNode "(linux_memory_order)" "linux_memory_order.RbDep" []
  | linux_memory_order.RcuLock => return typedNode "(linux_memory_order)" "linux_memory_order.RcuLock" []
  | linux_memory_order.RcuUnlock => return typedNode "(linux_memory_order)" "linux_memory_order.RcuUnlock" []
  | linux_memory_order.SyncRcu => return typedNode "(linux_memory_order)" "linux_memory_order.SyncRcu" []

private def q_memory_order : (memory_order) → Result
  | memory_order.NA => return typedNode "(memory_order)" "memory_order.NA" []
  | memory_order.Seq_cst => return typedNode "(memory_order)" "memory_order.Seq_cst" []
  | memory_order.Relaxed => return typedNode "(memory_order)" "memory_order.Relaxed" []
  | memory_order.Release => return typedNode "(memory_order)" "memory_order.Release" []
  | memory_order.Acquire => return typedNode "(memory_order)" "memory_order.Acquire" []
  | memory_order.Consume => return typedNode "(memory_order)" "memory_order.Consume" []
  | memory_order.Acq_rel => return typedNode "(memory_order)" "memory_order.Acq_rel" []

private def q_prefix0 : (prefix0) → Result
  | prefix0.PrefSource x0 x1 => return typedNode "(prefix0)" "prefix0.PrefSource" [← q_CerbLocation_Loc x0, ← (qList "(sym)" q_sym) x1]
  | prefix0.PrefFunArg x0 x1 x2 => return typedNode "(prefix0)" "prefix0.PrefFunArg" [← q_CerbLocation_Loc x0, ← qString x1, ← qInt x2]
  | prefix0.PrefStringLiteral x0 x1 => return typedNode "(prefix0)" "prefix0.PrefStringLiteral" [← q_CerbLocation_Loc x0, ← qString x1]
  | prefix0.PrefCompoundLiteral x0 x1 => return typedNode "(prefix0)" "prefix0.PrefCompoundLiteral" [← q_CerbLocation_Loc x0, ← qString x1]
  | prefix0.PrefMalloc => return typedNode "(prefix0)" "prefix0.PrefMalloc" []
  | prefix0.PrefTemporaryLifetime x0 x1 => return typedNode "(prefix0)" "prefix0.PrefTemporaryLifetime" [← q_CerbLocation_Loc x0, ← qString x1]
  | prefix0.PrefOther x0 => return typedNode "(prefix0)" "prefix0.PrefOther" [← qString x0]

private def q_generic_action_ : (generic_action_ (PUnit) (sym)) → Result
  | generic_action_.Create x0 x1 x2 => return typedNode "(generic_action_ (PUnit) (sym))" "generic_action_.Create" [← q_generic_pexpr x0, ← q_generic_pexpr x1, ← q_prefix0 x2]
  | generic_action_.CreateReadOnly x0 x1 x2 x3 => return typedNode "(generic_action_ (PUnit) (sym))" "generic_action_.CreateReadOnly" [← q_generic_pexpr x0, ← q_generic_pexpr x1, ← q_generic_pexpr x2, ← q_prefix0 x3]
  | generic_action_.Alloc0 x0 x1 x2 => return typedNode "(generic_action_ (PUnit) (sym))" "generic_action_.Alloc0" [← q_generic_pexpr x0, ← q_generic_pexpr x1, ← q_prefix0 x2]
  | generic_action_.Kill x0 x1 => return typedNode "(generic_action_ (PUnit) (sym))" "generic_action_.Kill" [← q_kill_kind x0, ← q_generic_pexpr x1]
  | generic_action_.Store0 x0 x1 x2 x3 x4 => return typedNode "(generic_action_ (PUnit) (sym))" "generic_action_.Store0" [← qBool x0, ← q_generic_pexpr x1, ← q_generic_pexpr x2, ← q_generic_pexpr x3, ← q_memory_order x4]
  | generic_action_.Load0 x0 x1 x2 => return typedNode "(generic_action_ (PUnit) (sym))" "generic_action_.Load0" [← q_generic_pexpr x0, ← q_generic_pexpr x1, ← q_memory_order x2]
  | generic_action_.SeqRMW x0 x1 x2 x3 x4 => return typedNode "(generic_action_ (PUnit) (sym))" "generic_action_.SeqRMW" [← qBool x0, ← q_generic_pexpr x1, ← q_generic_pexpr x2, ← q_sym x3, ← q_generic_pexpr x4]
  | generic_action_.RMW0 x0 x1 x2 x3 x4 x5 => return typedNode "(generic_action_ (PUnit) (sym))" "generic_action_.RMW0" [← q_generic_pexpr x0, ← q_generic_pexpr x1, ← q_generic_pexpr x2, ← q_generic_pexpr x3, ← q_memory_order x4, ← q_memory_order x5]
  | generic_action_.Fence0 x0 => return typedNode "(generic_action_ (PUnit) (sym))" "generic_action_.Fence0" [← q_memory_order x0]
  | generic_action_.CompareExchangeStrong x0 x1 x2 x3 x4 x5 => return typedNode "(generic_action_ (PUnit) (sym))" "generic_action_.CompareExchangeStrong" [← q_generic_pexpr x0, ← q_generic_pexpr x1, ← q_generic_pexpr x2, ← q_generic_pexpr x3, ← q_memory_order x4, ← q_memory_order x5]
  | generic_action_.CompareExchangeWeak x0 x1 x2 x3 x4 x5 => return typedNode "(generic_action_ (PUnit) (sym))" "generic_action_.CompareExchangeWeak" [← q_generic_pexpr x0, ← q_generic_pexpr x1, ← q_generic_pexpr x2, ← q_generic_pexpr x3, ← q_memory_order x4, ← q_memory_order x5]
  | generic_action_.LinuxFence x0 => return typedNode "(generic_action_ (PUnit) (sym))" "generic_action_.LinuxFence" [← q_linux_memory_order x0]
  | generic_action_.LinuxLoad x0 x1 x2 => return typedNode "(generic_action_ (PUnit) (sym))" "generic_action_.LinuxLoad" [← q_generic_pexpr x0, ← q_generic_pexpr x1, ← q_linux_memory_order x2]
  | generic_action_.LinuxStore x0 x1 x2 x3 => return typedNode "(generic_action_ (PUnit) (sym))" "generic_action_.LinuxStore" [← q_generic_pexpr x0, ← q_generic_pexpr x1, ← q_generic_pexpr x2, ← q_linux_memory_order x3]
  | generic_action_.LinuxRMW x0 x1 x2 x3 => return typedNode "(generic_action_ (PUnit) (sym))" "generic_action_.LinuxRMW" [← q_generic_pexpr x0, ← q_generic_pexpr x1, ← q_generic_pexpr x2, ← q_linux_memory_order x3]

private def q_generic_action : (generic_action (core_run_annotation) (PUnit) (sym)) → Result
  | generic_action.Action x0 x1 x2 => return typedNode "(generic_action (core_run_annotation) (PUnit) (sym))" "generic_action.Action" [← q_CerbLocation_Loc x0, ← q_core_run_annotation x1, ← q_generic_action_ x2]

private def q_generic_memop : (generic_memop (sym)) → Result
  | generic_memop.PtrEq => return typedNode "(generic_memop (sym))" "generic_memop.PtrEq" []
  | generic_memop.PtrNe => return typedNode "(generic_memop (sym))" "generic_memop.PtrNe" []
  | generic_memop.PtrLt => return typedNode "(generic_memop (sym))" "generic_memop.PtrLt" []
  | generic_memop.PtrGt => return typedNode "(generic_memop (sym))" "generic_memop.PtrGt" []
  | generic_memop.PtrLe => return typedNode "(generic_memop (sym))" "generic_memop.PtrLe" []
  | generic_memop.PtrGe => return typedNode "(generic_memop (sym))" "generic_memop.PtrGe" []
  | generic_memop.Ptrdiff => return typedNode "(generic_memop (sym))" "generic_memop.Ptrdiff" []
  | generic_memop.IntFromPtr => return typedNode "(generic_memop (sym))" "generic_memop.IntFromPtr" []
  | generic_memop.PtrFromInt => return typedNode "(generic_memop (sym))" "generic_memop.PtrFromInt" []
  | generic_memop.PtrValidForDeref => return typedNode "(generic_memop (sym))" "generic_memop.PtrValidForDeref" []
  | generic_memop.PtrWellAligned => return typedNode "(generic_memop (sym))" "generic_memop.PtrWellAligned" []
  | generic_memop.PtrArrayShift => return typedNode "(generic_memop (sym))" "generic_memop.PtrArrayShift" []
  | generic_memop.PtrMemberShift x0 x1 => return typedNode "(generic_memop (sym))" "generic_memop.PtrMemberShift" [← q_sym x0, ← q_identifier x1]
  | generic_memop.Memcpy => return typedNode "(generic_memop (sym))" "generic_memop.Memcpy" []
  | generic_memop.Memcmp => return typedNode "(generic_memop (sym))" "generic_memop.Memcmp" []
  | generic_memop.Realloc => return typedNode "(generic_memop (sym))" "generic_memop.Realloc" []
  | generic_memop.Va_start => return typedNode "(generic_memop (sym))" "generic_memop.Va_start" []
  | generic_memop.Va_copy => return typedNode "(generic_memop (sym))" "generic_memop.Va_copy" []
  | generic_memop.Va_arg => return typedNode "(generic_memop (sym))" "generic_memop.Va_arg" []
  | generic_memop.Va_end => return typedNode "(generic_memop (sym))" "generic_memop.Va_end" []
  | generic_memop.Copy_alloc_id => return typedNode "(generic_memop (sym))" "generic_memop.Copy_alloc_id" []
  | generic_memop.CHERI_intrinsic x0 x1 => return typedNode "(generic_memop (sym))" "generic_memop.CHERI_intrinsic" [← qString x0, ← (qProd q_ctype (qList "(ctype)" q_ctype)) x1]

private def q_polarity : (polarity) → Result
  | polarity.Pos => return typedNode "(polarity)" "polarity.Pos" []
  | polarity.Neg0 => return typedNode "(polarity)" "polarity.Neg0" []

private def q_generic_paction : (generic_paction (core_run_annotation) (PUnit) (sym)) → Result
  | generic_paction.Paction x0 x1 => return typedNode "(generic_paction (core_run_annotation) (PUnit) (sym))" "generic_paction.Paction" [← q_polarity x0, ← q_generic_action x1]

private def q_pass_by_value_or_pointer : (pass_by_value_or_pointer) → Result
  | pass_by_value_or_pointer.By_pointer => return typedNode "(pass_by_value_or_pointer)" "pass_by_value_or_pointer.By_pointer" []
  | pass_by_value_or_pointer.By_value => return typedNode "(pass_by_value_or_pointer)" "pass_by_value_or_pointer.By_value" []

mutual
private partial def q_generic_expr : (generic_expr (core_run_annotation) (PUnit) (sym)) → Result
  | generic_expr.Expr x0 x1 => return typedNode "(generic_expr (core_run_annotation) (PUnit) (sym))" "generic_expr.Expr" [← (qList "(annot)" q_annot) x0, ← q_generic_expr_ x1]

private partial def q_generic_expr_ : (generic_expr_ (core_run_annotation) (PUnit) (sym)) → Result
  | generic_expr_.Epure x0 => return typedNode "(generic_expr_ (core_run_annotation) (PUnit) (sym))" "generic_expr_.Epure" [← q_generic_pexpr x0]
  | generic_expr_.Ememop x0 x1 => return typedNode "(generic_expr_ (core_run_annotation) (PUnit) (sym))" "generic_expr_.Ememop" [← q_generic_memop x0, ← (qList "(generic_pexpr (PUnit) (sym))" q_generic_pexpr) x1]
  | generic_expr_.Eaction x0 => return typedNode "(generic_expr_ (core_run_annotation) (PUnit) (sym))" "generic_expr_.Eaction" [← q_generic_paction x0]
  | generic_expr_.Ecase x0 x1 => return typedNode "(generic_expr_ (core_run_annotation) (PUnit) (sym))" "generic_expr_.Ecase" [← q_generic_pexpr x0, ← (qList "(Prod (generic_pattern (sym)) (generic_expr (core_run_annotation) (PUnit) (sym)))" (qProd q_generic_pattern q_generic_expr)) x1]
  | generic_expr_.Elet x0 x1 x2 => return typedNode "(generic_expr_ (core_run_annotation) (PUnit) (sym))" "generic_expr_.Elet" [← q_generic_pattern x0, ← q_generic_pexpr x1, ← q_generic_expr x2]
  | generic_expr_.Eif x0 x1 x2 => return typedNode "(generic_expr_ (core_run_annotation) (PUnit) (sym))" "generic_expr_.Eif" [← q_generic_pexpr x0, ← q_generic_expr x1, ← q_generic_expr x2]
  | generic_expr_.Eccall x0 x1 x2 x3 => return typedNode "(generic_expr_ (core_run_annotation) (PUnit) (sym))" "generic_expr_.Eccall" [← q_core_run_annotation x0, ← q_generic_pexpr x1, ← q_generic_pexpr x2, ← (qList "(generic_pexpr (PUnit) (sym))" q_generic_pexpr) x3]
  | generic_expr_.Eproc x0 x1 x2 => return typedNode "(generic_expr_ (core_run_annotation) (PUnit) (sym))" "generic_expr_.Eproc" [← q_core_run_annotation x0, ← q_generic_name x1, ← (qList "(generic_pexpr (PUnit) (sym))" q_generic_pexpr) x2]
  | generic_expr_.Eunseq x0 => return typedNode "(generic_expr_ (core_run_annotation) (PUnit) (sym))" "generic_expr_.Eunseq" [← (qList "(generic_expr (core_run_annotation) (PUnit) (sym))" q_generic_expr) x0]
  | generic_expr_.Ewseq x0 x1 x2 => return typedNode "(generic_expr_ (core_run_annotation) (PUnit) (sym))" "generic_expr_.Ewseq" [← q_generic_pattern x0, ← q_generic_expr x1, ← q_generic_expr x2]
  | generic_expr_.Esseq x0 x1 x2 => return typedNode "(generic_expr_ (core_run_annotation) (PUnit) (sym))" "generic_expr_.Esseq" [← q_generic_pattern x0, ← q_generic_expr x1, ← q_generic_expr x2]
  | generic_expr_.Ebound x0 => return typedNode "(generic_expr_ (core_run_annotation) (PUnit) (sym))" "generic_expr_.Ebound" [← q_generic_expr x0]
  | generic_expr_.End x0 => return typedNode "(generic_expr_ (core_run_annotation) (PUnit) (sym))" "generic_expr_.End" [← (qList "(generic_expr (core_run_annotation) (PUnit) (sym))" q_generic_expr) x0]
  | generic_expr_.Esave x0 x1 x2 => return typedNode "(generic_expr_ (core_run_annotation) (PUnit) (sym))" "generic_expr_.Esave" [← (qProd q_sym q_core_base_type) x0, ← (qList "(Prod (sym) (Prod (Prod (core_base_type) (Option (Prod (ctype) (pass_by_value_or_pointer)))) (generic_pexpr (PUnit) (sym))))" (qProd q_sym (qProd (qProd q_core_base_type (qOption (qProd q_ctype q_pass_by_value_or_pointer))) q_generic_pexpr))) x1, ← q_generic_expr x2]
  | generic_expr_.Erun x0 x1 x2 => return typedNode "(generic_expr_ (core_run_annotation) (PUnit) (sym))" "generic_expr_.Erun" [← q_core_run_annotation x0, ← q_sym x1, ← (qList "(generic_pexpr (PUnit) (sym))" q_generic_pexpr) x2]
  | generic_expr_.Epar x0 => return typedNode "(generic_expr_ (core_run_annotation) (PUnit) (sym))" "generic_expr_.Epar" [← (qList "(generic_expr (core_run_annotation) (PUnit) (sym))" q_generic_expr) x0]
  | generic_expr_.Ewait x0 => return typedNode "(generic_expr_ (core_run_annotation) (PUnit) (sym))" "generic_expr_.Ewait" [← qNat x0]
  | generic_expr_.Eannot x0 x1 => return typedNode "(generic_expr_ (core_run_annotation) (PUnit) (sym))" "generic_expr_.Eannot" [← (qList "(dyn_annotation)" q_dyn_annotation) x0, ← q_generic_expr x1]
  | generic_expr_.Eexcluded x0 x1 => return typedNode "(generic_expr_ (core_run_annotation) (PUnit) (sym))" "generic_expr_.Eexcluded" [← qNat x0, ← q_generic_action x1]

end

private def q_generic_fun_map_decl : (generic_fun_map_decl (PUnit) (core_run_annotation)) → Result
  | generic_fun_map_decl.Fun x0 x1 x2 => return typedNode "(generic_fun_map_decl (PUnit) (core_run_annotation))" "generic_fun_map_decl.Fun" [← q_core_base_type x0, ← (qList "(Prod (sym) (core_base_type))" (qProd q_sym q_core_base_type)) x1, ← q_generic_pexpr x2]
  | generic_fun_map_decl.Proc x0 x1 x2 x3 x4 => return typedNode "(generic_fun_map_decl (PUnit) (core_run_annotation))" "generic_fun_map_decl.Proc" [← q_CerbLocation_Loc x0, ← (qOption qNat) x1, ← q_core_base_type x2, ← (qList "(Prod (sym) (core_base_type))" (qProd q_sym q_core_base_type)) x3, ← q_generic_expr x4]
  | generic_fun_map_decl.ProcDecl x0 x1 x2 => return typedNode "(generic_fun_map_decl (PUnit) (core_run_annotation))" "generic_fun_map_decl.ProcDecl" [← q_CerbLocation_Loc x0, ← q_core_base_type x1, ← (qList "(core_base_type)" q_core_base_type) x2]
  | generic_fun_map_decl.BuiltinDecl x0 x1 x2 => return typedNode "(generic_fun_map_decl (PUnit) (core_run_annotation))" "generic_fun_map_decl.BuiltinDecl" [← q_CerbLocation_Loc x0, ← q_core_base_type x1, ← (qList "(core_base_type)" q_core_base_type) x2]

private def q_generic_globs : (generic_globs (core_run_annotation) (PUnit)) → Result
  | generic_globs.GlobalDef x0 x1 => return typedNode "(generic_globs (core_run_annotation) (PUnit))" "generic_globs.GlobalDef" [← (qProd q_core_base_type q_ctype) x0, ← q_generic_expr x1]
  | generic_globs.GlobalDecl x0 => return typedNode "(generic_globs (core_run_annotation) (PUnit))" "generic_globs.GlobalDecl" [← (qProd q_core_base_type q_ctype) x0]

private def q_generic_impl_decl : (generic_impl_decl (PUnit)) → Result
  | generic_impl_decl.Def x0 x1 => return typedNode "(generic_impl_decl (PUnit))" "generic_impl_decl.Def" [← q_core_base_type x0, ← q_generic_pexpr x1]
  | generic_impl_decl.IFun x0 x1 x2 => return typedNode "(generic_impl_decl (PUnit))" "generic_impl_decl.IFun" [← q_core_base_type x0, ← (qList "(Prod (sym) (core_base_type))" (qProd q_sym q_core_base_type)) x1, ← q_generic_pexpr x2]

private def q_linking_kind : (linking_kind) → Result
  | linking_kind.LK_none => return typedNode "(linking_kind)" "linking_kind.LK_none" []
  | linking_kind.LK_tentative x0 => return typedNode "(linking_kind)" "linking_kind.LK_tentative" [← q_sym x0]
  | linking_kind.LK_normal x0 => return typedNode "(linking_kind)" "linking_kind.LK_normal" [← q_sym x0]

private def q_loop_attribute : (loop_attribute) → Result
  | loop_attribute.mk x0 x1 x2 x3 => return typedNode "(loop_attribute)" "loop_attribute.mk" [← qNat x0, ← q_attributes x1, ← q_CerbLocation_Loc x2, ← q_CerbLocation_Loc x3]

private def q_tag_definition : (tag_definition) → Result
  | tag_definition.StructDef x0 x1 => return typedNode "(tag_definition)" "tag_definition.StructDef" [← (qList "(Prod (identifier) (Prod (attributes) (Prod (Option (alignment)) (Prod (qualifiers) (ctype)))))" (qProd q_identifier (qProd q_attributes (qProd (qOption q_alignment) (qProd q_qualifiers q_ctype))))) x0, ← (qOption q_flexible_array_member) x1]
  | tag_definition.UnionDef x0 => return typedNode "(tag_definition)" "tag_definition.UnionDef" [← (qList "(Prod (identifier) (Prod (attributes) (Prod (Option (alignment)) (Prod (qualifiers) (ctype)))))" (qProd q_identifier (qProd q_attributes (qProd (qOption q_alignment) (qProd q_qualifiers q_ctype))))) x0]

private def inField (field : String) (r : Result) : Result :=
  r.mapError fun e => { e with construct := field ++ "." ++ e.construct }

/-- Quote every file field. The provenance argument is construction evidence
    supplied at the audited producer sites, not a claim inferred from bindings. -/
def quoteFile (p : Provenance) : file core_run_annotation → Result
  | .mk main calling_convention0 tagDefs enumDefs stdlib impl0 globs funs extern funinfo loop_attributes1 visible_objects_env0 => do
    let main ← inField "main" ((qOption q_sym) main)
    let calling_convention0 ← inField "calling_convention0" (q_calling_convention calling_convention0)
    let tagDefs ← inField "tagDefs" (qFmap "(sym)" "(Prod (CerbLocation.Loc) (tag_definition))" [.S, .L] p.tagDefs q_sym (qProd q_CerbLocation_Loc q_tag_definition) tagDefs)
    let enumDefs ← inField "enumDefs" (qFmap "(sym)" "(integerType)" [.S] p.enumDefs q_sym q_integerType enumDefs)
    let stdlib ← inField "stdlib" (qFmap "(sym)" "(generic_fun_map_decl (PUnit) (core_run_annotation))" [.S] p.stdlib q_sym q_generic_fun_map_decl stdlib)
    let impl0 ← inField "impl0" (qFmap "(implementation_constant)" "(generic_impl_decl (PUnit))" [.I] p.impl0 q_implementation_constant q_generic_impl_decl impl0)
    let globs ← inField "globs" ((qList "(Prod (sym) (generic_globs (core_run_annotation) (PUnit)))" (qProd q_sym q_generic_globs)) globs)
    let funs ← inField "funs" (qFmap "(sym)" "(generic_fun_map_decl (PUnit) (core_run_annotation))" [.O, .L] p.funs q_sym q_generic_fun_map_decl funs)
    let extern ← inField "extern" (qFmap "(identifier)" "(Prod (List (sym)) (linking_kind))" [.E] p.extern q_identifier (qProd (qList "(sym)" q_sym) q_linking_kind) extern)
    let funinfo ← inField "funinfo" (qFmap "(sym)" "(Prod (CerbLocation.Loc) (Prod (attributes) (Prod (ctype) (Prod (List (Prod (Option (sym)) (ctype))) (Prod (Bool) (Bool))))))" [.O, .L] p.funinfo q_sym (qProd q_CerbLocation_Loc (qProd q_attributes (qProd q_ctype (qProd (qList "(Prod (Option (sym)) (ctype))" (qProd (qOption q_sym) q_ctype)) (qProd qBool qBool))))) funinfo)
    let loop_attributes1 ← inField "loop_attributes1" (qFmap "(Nat)" "(loop_attribute)" [.N] p.loop_attributes qNat q_loop_attribute loop_attributes1)
    let visible_objects_env0 ← inField "visible_objects_env0" (qFmap "(Nat)" "(List (Prod (sym) (ctype)))" [.N] p.visible_objects_env qNat (qList "(Prod (sym) (ctype))" (qProd q_sym q_ctype)) visible_objects_env0)
    return typedNode "(generic_file (PUnit) (core_run_annotation))" "generic_file.mk" [main, calling_convention0, tagDefs, enumDefs, stdlib, impl0, globs, funs, extern, funinfo, loop_attributes1, visible_objects_env0]

/-- Keys compare exact quotation syntax, with children already interned. They never
    use the model's weaker equality instances or inspect comparator closures. -/
private inductive NodeKey where
  | atom : String → NodeKey
  | app : String → List Nat → NodeKey
  | list : List Nat → NodeKey
  | listBody : String → List Nat → NodeKey
  | apply : Nat → Nat → NodeKey
  | typed : String → Nat → NodeKey
  deriving BEq, Hashable, Inhabited

private structure Entry where
  key : NodeKey
  uses : Nat
  cost : Nat := 1
  helper : Option (String × Nat) := none
  deriving Inhabited

private structure Dag where
  index : Std.HashMap NodeKey Nat := {}
  entries : Array Entry := #[]

private def internKey (key : NodeKey) : StateM Dag Nat := do
  let dag ← get
  match dag.index[key]? with
  | some id =>
    let entry := dag.entries[id]!
    set { dag with entries := dag.entries.set! id { entry with uses := entry.uses + 1 } }
    return id
  | none =>
    let id := dag.entries.size
    set ({ index := dag.index.insert key id, entries := dag.entries.push { key := key, uses := 1 } } : Dag)
    return id

private partial def intern : Term → StateM Dag Nat
  | .atom s => internKey (.atom s)
  | .app head args => do internKey (.app head (← args.mapM intern))
  | .list xs => do internKey (.list (← xs.mapM intern))
  | .consList ty xs tail => do
    let body ← internKey (.listBody ty (← xs.mapM intern))
    let block ← internKey (.typed ("(List " ++ ty ++ ") → (List " ++ ty ++ ")") body)
    internKey (.apply block (← intern tail))
  | .typed ty t => do internKey (.typed ty (← intern t))

private def shared (entry : Entry) : Bool := entry.helper.isSome

/-- Limit the work in each declaration without changing the represented value.
    Small subterms stay inline; larger repeated terms and large subterms become
    private typed definitions. The thresholds affect formatting only. -/
private def planSharing (root : Nat) (entries : Array Entry) : Array Entry := Id.run do
  let mut result := entries
  for id in [:entries.size] do
    let entry := result[id]!
    let cost := match entry.key with
      | .atom _ => 1
      | .app _ children | .list children =>
        1 + children.foldl (fun total child => total + result[child]!.cost) 0
      | .listBody _ children =>
        1 + children.length + children.foldl (fun total child => total + result[child]!.cost) 0
      | .apply fn arg => 1 + result[fn]!.cost + result[arg]!.cost
      | .typed _ child => 1 + result[child]!.cost
    let helper := match entry.key with
      | .typed ty child =>
        if id != root && (cost > 256 || (entry.uses > 1 && cost > 16)) then
          some (ty, child)
        else none
      | .atom _ | .app _ _ | .list _ | .listBody _ _ | .apply _ _ => none
    result := result.set! id { entry with cost := if helper.isSome then 1 else cost, helper := helper }
  return result

private def helperName (id : Nat) : String := "cq_" ++ toString id

private inductive RenderTask where
  | term : Nat → RenderTask
  | text : String → RenderTask

private def separated (separator : String) (xs : List Nat) : List RenderTask :=
  match xs with
  | [] => []
  | x :: rest => .term x :: rest.flatMap (fun t => [.text separator, .term t])

private partial def renderTasks (entries : Array Entry)
    (todo : List RenderTask) (chunks : List String) : String :=
  match todo with
  | [] => String.join chunks.reverse
  | .text s :: rest => renderTasks entries rest (s :: chunks)
  | .term id :: rest =>
    let entry := entries[id]!
    if shared entry then renderTasks entries rest (helperName id :: chunks)
    else match entry.key with
    | .atom s => renderTasks entries rest (s :: chunks)
    | .typed _ child => renderTasks entries (.term child :: rest) chunks
    | .app head args =>
      let inside := args.flatMap fun t => [RenderTask.text " ", .term t]
      renderTasks entries (.text "(" :: .text head :: (inside ++ .text ")" :: rest)) chunks
    | .list xs =>
      renderTasks entries (.text "[" :: (separated ", " xs ++ .text "]" :: rest)) chunks
    | .listBody ty xs =>
      let opening := xs.flatMap fun x => [.text "(_root_.List.cons ", .term x, .text " "]
      let closing := String.ofList (List.replicate xs.length ')') ++ ")"
      renderTasks entries (.text ("(fun (cq_tail : List " ++ ty ++ ") => ") ::
        (opening ++ .text "cq_tail" :: .text closing :: rest)) chunks
    | .apply fn arg =>
      renderTasks entries (.text "(" :: .term fn :: .text " " :: .term arg :: .text ")" :: rest) chunks

/-- Helpers share exact closed syntax, and split large subterms into separate
    elaboration units. They retain every constructor and field, including map
    and set shape and cached heights. Child IDs precede parent IDs, so private
    helper dependencies are acyclic. No printer code is imported by the output. -/
def render (term : Term) : String := Id.run do
  let (root, dag) := (intern term).run {}
  let entries := planSharing root dag.entries
  let body := renderTasks entries [.term root] []
  let mut helpers : Array String := #[]
  for id in [:entries.size] do
    let entry := entries[id]!
    if let some (ty, child) := entry.helper then
      let rhs := renderTasks entries [.term child] []
      helpers := helpers.push ("private def " ++ helperName id ++ " : " ++ ty ++ " := " ++ rhs ++ "\n\n")
  return String.join helpers.toList ++ "def quotedCore : file core_run_annotation :=\n" ++ body ++ "\n"

/-- One self-contained module and one public file definition with private typed
    subterms. The public name is fixed, not caller-supplied source text. -/
def moduleSource (switches : List CerbGlobal.CerbSwitch) (p : Provenance)
    (f : file core_run_annotation) : Except Refusal String := do
  let term ← quoteFile p f
  return "import Core_run_aux\n\n-- " ++ CerbDriverConfig.switchReport switches ++ "\n" ++ render term

end CerbQuote
