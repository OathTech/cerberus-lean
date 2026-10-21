import Lean
import Core_run_aux
import CerbQuote

/- Whole-file representation test. The visitor below is derived from datatype
   declarations independently of CerbQuote. It preserves all constructor
   arguments except Fmap closures, whose elaborated syntax is checked separately.
   These executable instruments are outside the semantics execution cone. -/
namespace CoreQuoteTest
open Lean

inductive Shape where
  | scalar : String → String → Shape
  | node : String → Array Shape → Shape
  deriving Inhabited

def require (b : Bool) (message : String) : IO Unit :=
  unless b do throw (IO.userError s!"Core quote test: {message}")

partial def sameShape (a b : Shape) : Bool :=
  match a, b with
  | .scalar ka va, .scalar kb vb => ka == kb && va == vb
  | .node ka va, .node kb vb =>
    ka == kb && va.size == vb.size && (va.zip vb).all (fun (x, y) => sameShape x y)
  | _, _ => false

partial def census (s : Shape) (counts : Std.HashMap String Nat := {}) : Std.HashMap String Nat :=
  match s with
  | .scalar k v =>
    let counts := counts.insert k (counts.getD k 0 + 1)
    if k == "Pos.path" && (System.FilePath.mk v).isAbsolute then
      counts.insert "absolute-position" (counts.getD "absolute-position" 0 + 1)
    else counts
  | .node "List" children =>
    -- A list has only its length and ordered elements; a flat array is a
    -- lossless view that avoids a million recursive cons frames. Count the
    -- original constructors, including the terminating nil, in the census.
    let counts := counts.insert "List.cons" (counts.getD "List.cons" 0 + children.size)
    let counts := counts.insert "List.nil" (counts.getD "List.nil" 0 + 1)
    children.foldl (fun acc child => census child acc) counts
  | .node k children => children.foldl (fun acc child => census child acc)
      (counts.insert k (counts.getD k 0 + 1))

-- BEGIN DATATYPE VISITOR (test/CoreQuote/CoreQuoteVisitor.lean)
mutual
partial def view0 (x : generic_file Unit core_run_annotation) : Shape :=
  match x with
  | .mk a0 a1 a2 a3 a4 a5 a6 a7 a8 a9 a10 a11 => .node "generic_file.mk" #[(view1 a0), (view11 a1), (view12 a2), (view57 a3), (view59 a4), (view145 a5), (view148 a6), (view59 a7), (view152 a8), (view156 a9), (view165 a10), (view168 a11)]
partial def view1 (x : Option sym) : Shape :=
  match x with
  | .none  => .node "Option.none" #[]
  | .some a0 => .node "Option.some" #[(view2 a0)]
partial def view2 (x : sym) : Shape :=
  match x with
  | .Symbol a0 a1 a2 => .node "sym.Symbol" #[(view3 a0), (view4 a1), (view5 a2)]
partial def view3 (x : String) : Shape :=
  .scalar "String" x
partial def view4 (x : Nat) : Shape :=
  .scalar "Nat" (toString x)
partial def view5 (x : symbol_description) : Shape :=
  match x with
  | .SD_None  => .node "symbol_description.SD_None" #[]
  | .SD_unnamed_tag a0 => .node "symbol_description.SD_unnamed_tag" #[(view6 a0)]
  | .SD_Id a0 => .node "symbol_description.SD_Id" #[(view3 a0)]
  | .SD_CN_Id a0 => .node "symbol_description.SD_CN_Id" #[(view3 a0)]
  | .SD_ObjectAddress a0 => .node "symbol_description.SD_ObjectAddress" #[(view3 a0)]
  | .SD_Return  => .node "symbol_description.SD_Return" #[]
  | .SD_FunArgValue a0 => .node "symbol_description.SD_FunArgValue" #[(view3 a0)]
  | .SD_FunArg a0 a1 => .node "symbol_description.SD_FunArg" #[(view6 a0), (view4 a1)]
partial def view6 (x : CerbLocation.Loc) : Shape :=
  match x with
  | .unknown  => .node "CerbLocation.Loc.unknown" #[]
  | .other a0 => .node "CerbLocation.Loc.other" #[(view3 a0)]
  | .point a0 => .node "CerbLocation.Loc.point" #[(view7 a0)]
  | .region a0 a1 a2 => .node "CerbLocation.Loc.region" #[(view7 a0), (view7 a1), (view8 a2)]
  | .regions a0 a1 => .node "CerbLocation.Loc.regions" #[(view9 a0), (view8 a1)]
partial def view7 (x : CerbLocation.Pos) : Shape :=
  match x with
  | .mk a0 a1 a2 a3 a4 => .node "CerbLocation.Pos.mk" #[(.scalar "Pos.path" a0), (view4 a1), (view4 a2), (.scalar "Pos.path" a3), (view4 a4)]
partial def view8 (x : CerbLocation.Cursor) : Shape :=
  match x with
  | .noCursor  => .node "CerbLocation.Cursor.noCursor" #[]
  | .pointCursor a0 => .node "CerbLocation.Cursor.pointCursor" #[(view7 a0)]
  | .regionCursor a0 a1 => .node "CerbLocation.Cursor.regionCursor" #[(view7 a0), (view7 a1)]
partial def view9 (x : List (CerbLocation.Pos × CerbLocation.Pos)) : Shape :=
  .node "List" (x.toArray.map view10)
partial def view10 (x : CerbLocation.Pos × CerbLocation.Pos) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view7 a0), (view7 a1)]
partial def view11 (x : calling_convention) : Shape :=
  match x with
  | .Normal_callconv  => .node "calling_convention.Normal_callconv" #[]
  | .Inner_arg_callconv  => .node "calling_convention.Inner_arg_callconv" #[]
partial def view12 (x : Fmap sym (CerbLocation.Loc × tag_definition)) : Shape :=
  match x with
  | .empty  => .node "Fmap.empty" #[]
  | .mk _ a1 => .node "Fmap.mk" #[(view13 a1)]
partial def view13 (x : Pmap sym (CerbLocation.Loc × tag_definition)) : Shape :=
  match x with
  | .Empty  => .node "Pmap.Empty" #[]
  | .Node a0 a1 a2 a3 a4 => .node "Pmap.Node" #[(view13 a0), (view2 a1), (view14 a2), (view13 a3), (view4 a4)]
partial def view14 (x : CerbLocation.Loc × tag_definition) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view6 a0), (view15 a1)]
partial def view15 (x : tag_definition) : Shape :=
  match x with
  | .StructDef a0 a1 => .node "tag_definition.StructDef" #[(view16 a0), (view55 a1)]
  | .UnionDef a0 => .node "tag_definition.UnionDef" #[(view16 a0)]
partial def view16 (x : List (identifier × attributes × Option alignment × qualifiers × ctype)) : Shape :=
  .node "List" (x.toArray.map view17)
partial def view17 (x : identifier × attributes × Option alignment × qualifiers × ctype) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view18 a0), (view19 a1)]
partial def view18 (x : identifier) : Shape :=
  match x with
  | .Identifier a0 a1 => .node "identifier.Identifier" #[(view6 a0), (view3 a1)]
partial def view19 (x : attributes × Option alignment × qualifiers × ctype) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view20 a0), (view29 a1)]
partial def view20 (x : attributes) : Shape :=
  match x with
  | .Attrs a0 => .node "attributes.Attrs" #[(view21 a0)]
partial def view21 (x : List attribute0) : Shape :=
  .node "List" (x.toArray.map view22)
partial def view22 (x : attribute0) : Shape :=
  match x with
  | .mk a0 a1 a2 => .node "attribute0.mk" #[(view23 a0), (view18 a1), (view24 a2)]
partial def view23 (x : Option identifier) : Shape :=
  match x with
  | .none  => .node "Option.none" #[]
  | .some a0 => .node "Option.some" #[(view18 a0)]
partial def view24 (x : List (CerbLocation.Loc × String × List (CerbLocation.Loc × String))) : Shape :=
  .node "List" (x.toArray.map view25)
partial def view25 (x : CerbLocation.Loc × String × List (CerbLocation.Loc × String)) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view6 a0), (view26 a1)]
partial def view26 (x : String × List (CerbLocation.Loc × String)) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view3 a0), (view27 a1)]
partial def view27 (x : List (CerbLocation.Loc × String)) : Shape :=
  .node "List" (x.toArray.map view28)
partial def view28 (x : CerbLocation.Loc × String) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view6 a0), (view3 a1)]
partial def view29 (x : Option alignment × qualifiers × ctype) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view30 a0), (view49 a1)]
partial def view30 (x : Option alignment) : Shape :=
  match x with
  | .none  => .node "Option.none" #[]
  | .some a0 => .node "Option.some" #[(view31 a0)]
partial def view31 (x : alignment) : Shape :=
  match x with
  | .AlignInteger a0 => .node "alignment.AlignInteger" #[(view32 a0)]
  | .AlignType a0 => .node "alignment.AlignType" #[(view33 a0)]
partial def view32 (x : Int) : Shape :=
  .scalar "Int" (toString x)
partial def view33 (x : ctype) : Shape :=
  match x with
  | .Ctype a0 a1 => .node "ctype.Ctype" #[(view34 a0), (view44 a1)]
partial def view34 (x : List annot) : Shape :=
  .node "List" (x.toArray.map view35)
partial def view35 (x : annot) : Shape :=
  match x with
  | .Astd a0 => .node "annot.Astd" #[(view3 a0)]
  | .Aloc a0 => .node "annot.Aloc" #[(view6 a0)]
  | .Auid a0 => .node "annot.Auid" #[(view3 a0)]
  | .Amarker a0 => .node "annot.Amarker" #[(view4 a0)]
  | .Amarker_object_types a0 => .node "annot.Amarker_object_types" #[(view4 a0)]
  | .Abmc a0 => .node "annot.Abmc" #[(view36 a0)]
  | .Aattrs a0 => .node "annot.Aattrs" #[(view20 a0)]
  | .Atypedef a0 => .node "annot.Atypedef" #[(view2 a0)]
  | .Alabel a0 => .node "annot.Alabel" #[(view37 a0)]
  | .Acerb a0 => .node "annot.Acerb" #[(view38 a0)]
  | .Avalue a0 => .node "annot.Avalue" #[(view39 a0)]
  | .Ainlined_label a0 => .node "annot.Ainlined_label" #[(view42 a0)]
  | .Astmt  => .node "annot.Astmt" #[]
  | .Aexpr  => .node "annot.Aexpr" #[]
partial def view36 (x : bmc_annot) : Shape :=
  match x with
  | .Abmc_id a0 => .node "bmc_annot.Abmc_id" #[(view4 a0)]
partial def view37 (x : label_annot) : Shape :=
  match x with
  | .LAloop a0 => .node "label_annot.LAloop" #[(view4 a0)]
  | .LAloop_continue a0 => .node "label_annot.LAloop_continue" #[(view4 a0)]
  | .LAloop_break a0 => .node "label_annot.LAloop_break" #[(view4 a0)]
  | .LAreturn  => .node "label_annot.LAreturn" #[]
  | .LAswitch  => .node "label_annot.LAswitch" #[]
  | .LAcase  => .node "label_annot.LAcase" #[]
  | .LAdefault  => .node "label_annot.LAdefault" #[]
  | .LAactual_label  => .node "label_annot.LAactual_label" #[]
partial def view38 (x : cerb_attribute) : Shape :=
  match x with
  | .ACerb_with_address a0 => .node "cerb_attribute.ACerb_with_address" #[(view32 a0)]
  | .ACerb_hidden  => .node "cerb_attribute.ACerb_hidden" #[]
partial def view39 (x : value_annot) : Shape :=
  match x with
  | .Ainteger a0 => .node "value_annot.Ainteger" #[(view40 a0)]
partial def view40 (x : integerType) : Shape :=
  match x with
  | .Char0  => .node "integerType.Char0" #[]
  | .Bool0  => .node "integerType.Bool0" #[]
  | .Signed a0 => .node "integerType.Signed" #[(view41 a0)]
  | .Unsigned a0 => .node "integerType.Unsigned" #[(view41 a0)]
  | .Enum0 a0 => .node "integerType.Enum0" #[(view2 a0)]
  | .Wchar_t  => .node "integerType.Wchar_t" #[]
  | .Wint_t  => .node "integerType.Wint_t" #[]
  | .Size_t  => .node "integerType.Size_t" #[]
  | .Ptrdiff_t  => .node "integerType.Ptrdiff_t" #[]
  | .Ptraddr_t  => .node "integerType.Ptraddr_t" #[]
partial def view41 (x : integerBaseType) : Shape :=
  match x with
  | .Ichar  => .node "integerBaseType.Ichar" #[]
  | .Short  => .node "integerBaseType.Short" #[]
  | .Int_  => .node "integerBaseType.Int_" #[]
  | .Long  => .node "integerBaseType.Long" #[]
  | .LongLong  => .node "integerBaseType.LongLong" #[]
  | .IntN_t a0 => .node "integerBaseType.IntN_t" #[(view4 a0)]
  | .Int_leastN_t a0 => .node "integerBaseType.Int_leastN_t" #[(view4 a0)]
  | .Int_fastN_t a0 => .node "integerBaseType.Int_fastN_t" #[(view4 a0)]
  | .Intmax_t  => .node "integerBaseType.Intmax_t" #[]
  | .Intptr_t  => .node "integerBaseType.Intptr_t" #[]
partial def view42 (x : CerbLocation.Loc × sym × label_annot) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view6 a0), (view43 a1)]
partial def view43 (x : sym × label_annot) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view2 a0), (view37 a1)]
partial def view44 (x : ctype_) : Shape :=
  match x with
  | .Void0  => .node "ctype_.Void0" #[]
  | .Basic a0 => .node "ctype_.Basic" #[(view45 a0)]
  | .Array0 a0 a1 => .node "ctype_.Array0" #[(view33 a0), (view48 a1)]
  | .Function a0 a1 a2 => .node "ctype_.Function" #[(view49 a0), (view52 a1), (view51 a2)]
  | .FunctionNoParams a0 => .node "ctype_.FunctionNoParams" #[(view49 a0)]
  | .Pointer a0 a1 => .node "ctype_.Pointer" #[(view50 a0), (view33 a1)]
  | .Atomic a0 => .node "ctype_.Atomic" #[(view33 a0)]
  | .Struct a0 => .node "ctype_.Struct" #[(view2 a0)]
  | .Union0 a0 => .node "ctype_.Union0" #[(view2 a0)]
  | .Byte  => .node "ctype_.Byte" #[]
partial def view45 (x : basicType) : Shape :=
  match x with
  | .Integer a0 => .node "basicType.Integer" #[(view40 a0)]
  | .Floating a0 => .node "basicType.Floating" #[(view46 a0)]
partial def view46 (x : floatingType) : Shape :=
  match x with
  | .RealFloating a0 => .node "floatingType.RealFloating" #[(view47 a0)]
partial def view47 (x : realFloatingType) : Shape :=
  match x with
  | .Float0  => .node "realFloatingType.Float0" #[]
  | .Double  => .node "realFloatingType.Double" #[]
  | .LongDouble  => .node "realFloatingType.LongDouble" #[]
partial def view48 (x : Option Int) : Shape :=
  match x with
  | .none  => .node "Option.none" #[]
  | .some a0 => .node "Option.some" #[(view32 a0)]
partial def view49 (x : qualifiers × ctype) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view50 a0), (view33 a1)]
partial def view50 (x : qualifiers) : Shape :=
  match x with
  | .mk a0 a1 a2 => .node "qualifiers.mk" #[(view51 a0), (view51 a1), (view51 a2)]
partial def view51 (x : Bool) : Shape :=
  .scalar "Bool" (toString x)
partial def view52 (x : List (qualifiers × ctype × Bool)) : Shape :=
  .node "List" (x.toArray.map view53)
partial def view53 (x : qualifiers × ctype × Bool) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view50 a0), (view54 a1)]
partial def view54 (x : ctype × Bool) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view33 a0), (view51 a1)]
partial def view55 (x : Option flexible_array_member) : Shape :=
  match x with
  | .none  => .node "Option.none" #[]
  | .some a0 => .node "Option.some" #[(view56 a0)]
partial def view56 (x : flexible_array_member) : Shape :=
  match x with
  | .FlexibleArrayMember a0 a1 a2 a3 => .node "flexible_array_member.FlexibleArrayMember" #[(view20 a0), (view18 a1), (view50 a2), (view33 a3)]
partial def view57 (x : Fmap sym integerType) : Shape :=
  match x with
  | .empty  => .node "Fmap.empty" #[]
  | .mk _ a1 => .node "Fmap.mk" #[(view58 a1)]
partial def view58 (x : Pmap sym integerType) : Shape :=
  match x with
  | .Empty  => .node "Pmap.Empty" #[]
  | .Node a0 a1 a2 a3 a4 => .node "Pmap.Node" #[(view58 a0), (view2 a1), (view40 a2), (view58 a3), (view4 a4)]
partial def view59 (x : Fmap sym (generic_fun_map_decl Unit core_run_annotation)) : Shape :=
  match x with
  | .empty  => .node "Fmap.empty" #[]
  | .mk _ a1 => .node "Fmap.mk" #[(view60 a1)]
partial def view60 (x : Pmap sym (generic_fun_map_decl Unit core_run_annotation)) : Shape :=
  match x with
  | .Empty  => .node "Pmap.Empty" #[]
  | .Node a0 a1 a2 a3 a4 => .node "Pmap.Node" #[(view60 a0), (view2 a1), (view61 a2), (view60 a3), (view4 a4)]
partial def view61 (x : generic_fun_map_decl Unit core_run_annotation) : Shape :=
  match x with
  | .Fun a0 a1 a2 => .node "generic_fun_map_decl.Fun" #[(view62 a0), (view65 a1), (view67 a2)]
  | .Proc a0 a1 a2 a3 a4 => .node "generic_fun_map_decl.Proc" #[(view6 a0), (view111 a1), (view62 a2), (view65 a3), (view112 a4)]
  | .ProcDecl a0 a1 a2 => .node "generic_fun_map_decl.ProcDecl" #[(view6 a0), (view62 a1), (view63 a2)]
  | .BuiltinDecl a0 a1 a2 => .node "generic_fun_map_decl.BuiltinDecl" #[(view6 a0), (view62 a1), (view63 a2)]
partial def view62 (x : core_base_type) : Shape :=
  match x with
  | .BTy_unit  => .node "core_base_type.BTy_unit" #[]
  | .BTy_boolean  => .node "core_base_type.BTy_boolean" #[]
  | .BTy_ctype  => .node "core_base_type.BTy_ctype" #[]
  | .BTy_list a0 => .node "core_base_type.BTy_list" #[(view62 a0)]
  | .BTy_tuple a0 => .node "core_base_type.BTy_tuple" #[(view63 a0)]
  | .BTy_object a0 => .node "core_base_type.BTy_object" #[(view64 a0)]
  | .BTy_loaded a0 => .node "core_base_type.BTy_loaded" #[(view64 a0)]
  | .BTy_storable  => .node "core_base_type.BTy_storable" #[]
partial def view63 (x : List core_base_type) : Shape :=
  .node "List" (x.toArray.map view62)
partial def view64 (x : core_object_type) : Shape :=
  match x with
  | .OTy_integer  => .node "core_object_type.OTy_integer" #[]
  | .OTy_floating  => .node "core_object_type.OTy_floating" #[]
  | .OTy_pointer  => .node "core_object_type.OTy_pointer" #[]
  | .OTy_array a0 => .node "core_object_type.OTy_array" #[(view64 a0)]
  | .OTy_struct a0 => .node "core_object_type.OTy_struct" #[(view2 a0)]
  | .OTy_union a0 => .node "core_object_type.OTy_union" #[(view2 a0)]
partial def view65 (x : List (sym × core_base_type)) : Shape :=
  .node "List" (x.toArray.map view66)
partial def view66 (x : sym × core_base_type) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view2 a0), (view62 a1)]
partial def view67 (x : generic_pexpr Unit sym) : Shape :=
  match x with
  | .Pexpr a0 a1 a2 => .node "generic_pexpr.Pexpr" #[(view34 a0), (view68 a1), (view69 a2)]
partial def view68 (x : PUnit) : Shape :=
  let _ := x; .node "Unit.unit" #[]
partial def view69 (x : generic_pexpr_ Unit sym) : Shape :=
  match x with
  | .PEsym a0 => .node "generic_pexpr_.PEsym" #[(view2 a0)]
  | .PEimpl a0 => .node "generic_pexpr_.PEimpl" #[(view70 a0)]
  | .PEval a0 => .node "generic_pexpr_.PEval" #[(view71 a0)]
  | .PEconstrained a0 => .node "generic_pexpr_.PEconstrained" #[(view86 a0)]
  | .PEundef a0 a1 => .node "generic_pexpr_.PEundef" #[(view6 a0), (view90 a1)]
  | .PEerror a0 a1 => .node "generic_pexpr_.PEerror" #[(view3 a0), (view67 a1)]
  | .PEctor a0 a1 => .node "generic_pexpr_.PEctor" #[(view93 a0), (view94 a1)]
  | .PEcase a0 a1 => .node "generic_pexpr_.PEcase" #[(view67 a0), (view95 a1)]
  | .PEarray_shift a0 a1 a2 => .node "generic_pexpr_.PEarray_shift" #[(view67 a0), (view33 a1), (view67 a2)]
  | .PEmember_shift a0 a1 a2 => .node "generic_pexpr_.PEmember_shift" #[(view67 a0), (view2 a1), (view18 a2)]
  | .PEmemop a0 a1 => .node "generic_pexpr_.PEmemop" #[(view101 a0), (view94 a1)]
  | .PEnot a0 => .node "generic_pexpr_.PEnot" #[(view67 a0)]
  | .PEop a0 a1 a2 => .node "generic_pexpr_.PEop" #[(view106 a0), (view67 a1), (view67 a2)]
  | .PEconv_int a0 a1 => .node "generic_pexpr_.PEconv_int" #[(view40 a0), (view67 a1)]
  | .PEwrapI a0 a1 a2 a3 => .node "generic_pexpr_.PEwrapI" #[(view40 a0), (view107 a1), (view67 a2), (view67 a3)]
  | .PEcatch_exceptional_condition a0 a1 a2 a3 => .node "generic_pexpr_.PEcatch_exceptional_condition" #[(view40 a0), (view107 a1), (view67 a2), (view67 a3)]
  | .PEstruct a0 a1 => .node "generic_pexpr_.PEstruct" #[(view2 a0), (view108 a1)]
  | .PEunion a0 a1 a2 => .node "generic_pexpr_.PEunion" #[(view2 a0), (view18 a1), (view67 a2)]
  | .PEcfunction a0 => .node "generic_pexpr_.PEcfunction" #[(view67 a0)]
  | .PEmemberof a0 a1 a2 => .node "generic_pexpr_.PEmemberof" #[(view2 a0), (view18 a1), (view67 a2)]
  | .PEcall a0 a1 => .node "generic_pexpr_.PEcall" #[(view110 a0), (view94 a1)]
  | .PElet a0 a1 a2 => .node "generic_pexpr_.PElet" #[(view97 a0), (view67 a1), (view67 a2)]
  | .PEif a0 a1 a2 => .node "generic_pexpr_.PEif" #[(view67 a0), (view67 a1), (view67 a2)]
  | .PEis_scalar a0 => .node "generic_pexpr_.PEis_scalar" #[(view67 a0)]
  | .PEis_integer a0 => .node "generic_pexpr_.PEis_integer" #[(view67 a0)]
  | .PEis_signed a0 => .node "generic_pexpr_.PEis_signed" #[(view67 a0)]
  | .PEis_unsigned a0 => .node "generic_pexpr_.PEis_unsigned" #[(view67 a0)]
  | .PEbmc_assume a0 => .node "generic_pexpr_.PEbmc_assume" #[(view67 a0)]
  | .PEare_compatible a0 a1 => .node "generic_pexpr_.PEare_compatible" #[(view67 a0), (view67 a1)]
partial def view70 (x : implementation_constant) : Shape :=
  match x with
  | .Environment__startup_name  => .node "implementation_constant.Environment__startup_name" #[]
  | .Environment__startup_type  => .node "implementation_constant.Environment__startup_type" #[]
  | .Characters__bits_in_byte  => .node "implementation_constant.Characters__bits_in_byte" #[]
  | .Characters__execution_character_set_values  => .node "implementation_constant.Characters__execution_character_set_values" #[]
  | .Characters__TODO1  => .node "implementation_constant.Characters__TODO1" #[]
  | .Characters__TODO2  => .node "implementation_constant.Characters__TODO2" #[]
  | .Characters__plain_char_is_signed  => .node "implementation_constant.Characters__plain_char_is_signed" #[]
  | .Characters__TODO3  => .node "implementation_constant.Characters__TODO3" #[]
  | .Characters__TODO4  => .node "implementation_constant.Characters__TODO4" #[]
  | .Characters__TODO5  => .node "implementation_constant.Characters__TODO5" #[]
  | .Characters__TODO6  => .node "implementation_constant.Characters__TODO6" #[]
  | .Characters__TODO7  => .node "implementation_constant.Characters__TODO7" #[]
  | .Characters__TODO8  => .node "implementation_constant.Characters__TODO8" #[]
  | .Characters__TODO9  => .node "implementation_constant.Characters__TODO9" #[]
  | .Characters__TODO10  => .node "implementation_constant.Characters__TODO10" #[]
  | .Integer__encode  => .node "implementation_constant.Integer__encode" #[]
  | .Integer__decode  => .node "implementation_constant.Integer__decode" #[]
  | .Integer__conv_nonrepresentable_signed_integer  => .node "implementation_constant.Integer__conv_nonrepresentable_signed_integer" #[]
  | .Sizeof  => .node "implementation_constant.Sizeof" #[]
  | .Alignof  => .node "implementation_constant.Alignof" #[]
  | .SHR_signed_negative  => .node "implementation_constant.SHR_signed_negative" #[]
  | .Bitwise_complement  => .node "implementation_constant.Bitwise_complement" #[]
  | .Plain_bitfield_sign  => .node "implementation_constant.Plain_bitfield_sign" #[]
  | .Bitfield_other_types  => .node "implementation_constant.Bitfield_other_types" #[]
  | .Atomic_bitfield_permitted  => .node "implementation_constant.Atomic_bitfield_permitted" #[]
  | .Ctype_min  => .node "implementation_constant.Ctype_min" #[]
  | .Ctype_max  => .node "implementation_constant.Ctype_max" #[]
  | .BuiltinFunction a0 => .node "implementation_constant.BuiltinFunction" #[(view3 a0)]
partial def view71 (x : value) : Shape :=
  match x with
  | .Vobject a0 => .node "value.Vobject" #[(view72 a0)]
  | .Vloaded a0 => .node "value.Vloaded" #[(view79 a0)]
  | .Vunit  => .node "value.Vunit" #[]
  | .Vtrue  => .node "value.Vtrue" #[]
  | .Vfalse  => .node "value.Vfalse" #[]
  | .Vctype a0 => .node "value.Vctype" #[(view33 a0)]
  | .Vlist a0 a1 => .node "value.Vlist" #[(view62 a0), (view85 a1)]
  | .Vtuple a0 => .node "value.Vtuple" #[(view85 a0)]
partial def view72 (x : object_value) : Shape :=
  match x with
  | .OVinteger a0 => .node "object_value.OVinteger" #[(view73 a0)]
  | .OVfloating a0 => .node "object_value.OVfloating" #[(view75 a0)]
  | .OVpointer a0 => .node "object_value.OVpointer" #[(view76 a0)]
  | .OVarray a0 => .node "object_value.OVarray" #[(view78 a0)]
  | .OVstruct a0 a1 => .node "object_value.OVstruct" #[(view2 a0), (view80 a1)]
  | .OVunion a0 a1 a2 => .node "object_value.OVunion" #[(view2 a0), (view18 a1), (view83 a2)]
partial def view73 (x : CerbMem.IntegerValue) : Shape :=
  match x with
  | .IV a0 a1 => .node "CerbMem.IntegerValue.IV" #[(view74 a0), (view32 a1)]
partial def view74 (x : CerbMem.Provenance) : Shape :=
  match x with
  | .Prov_none  => .node "CerbMem.Provenance.Prov_none" #[]
  | .Prov_some a0 => .node "CerbMem.Provenance.Prov_some" #[(view32 a0)]
  | .Prov_symbolic a0 => .node "CerbMem.Provenance.Prov_symbolic" #[(view32 a0)]
  | .Prov_device  => .node "CerbMem.Provenance.Prov_device" #[]
partial def view75 (x : Float) : Shape :=
  .scalar (if x.isNaN then "NaN" else "Float.bits") (toString x.toBits.toNat)
partial def view76 (x : CerbMem.PointerValue) : Shape :=
  match x with
  | .PV a0 a1 => .node "CerbMem.PointerValue.PV" #[(view74 a0), (view77 a1)]
partial def view77 (x : CerbMem.PointerValueBase) : Shape :=
  match x with
  | .PVnull a0 => .node "CerbMem.PointerValueBase.PVnull" #[(view33 a0)]
  | .PVfunction a0 => .node "CerbMem.PointerValueBase.PVfunction" #[(view2 a0)]
  | .PVconcrete a0 a1 => .node "CerbMem.PointerValueBase.PVconcrete" #[(view23 a0), (view32 a1)]
partial def view78 (x : List loaded_value) : Shape :=
  .node "List" (x.toArray.map view79)
partial def view79 (x : loaded_value) : Shape :=
  match x with
  | .LVspecified a0 => .node "loaded_value.LVspecified" #[(view72 a0)]
  | .LVunspecified a0 => .node "loaded_value.LVunspecified" #[(view33 a0)]
partial def view80 (x : List (identifier × ctype × CerbMem.MemValue)) : Shape :=
  .node "List" (x.toArray.map view81)
partial def view81 (x : identifier × ctype × CerbMem.MemValue) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view18 a0), (view82 a1)]
partial def view82 (x : ctype × CerbMem.MemValue) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view33 a0), (view83 a1)]
partial def view83 (x : CerbMem.MemValue) : Shape :=
  match x with
  | .MVunspecified a0 => .node "CerbMem.MemValue.MVunspecified" #[(view33 a0)]
  | .MVinteger a0 a1 => .node "CerbMem.MemValue.MVinteger" #[(view40 a0), (view73 a1)]
  | .MVfloating a0 a1 => .node "CerbMem.MemValue.MVfloating" #[(view46 a0), (view75 a1)]
  | .MVpointer a0 a1 => .node "CerbMem.MemValue.MVpointer" #[(view33 a0), (view76 a1)]
  | .MVarray a0 => .node "CerbMem.MemValue.MVarray" #[(view84 a0)]
  | .MVstruct a0 a1 => .node "CerbMem.MemValue.MVstruct" #[(view2 a0), (view80 a1)]
  | .MVunion a0 a1 a2 => .node "CerbMem.MemValue.MVunion" #[(view2 a0), (view18 a1), (view83 a2)]
partial def view84 (x : List CerbMem.MemValue) : Shape :=
  .node "List" (x.toArray.map view83)
partial def view85 (x : List value) : Shape :=
  .node "List" (x.toArray.map view71)
partial def view86 (x : List (mem_iv_constraint × generic_pexpr Unit sym)) : Shape :=
  .node "List" (x.toArray.map view87)
partial def view87 (x : mem_iv_constraint × generic_pexpr Unit sym) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view88 a0), (view67 a1)]
partial def view88 (x : mem_constraint CerbMem.IntegerValue) : Shape :=
  match x with
  | .MC_empty  => .node "mem_constraint.MC_empty" #[]
  | .MC_eq a0 a1 => .node "mem_constraint.MC_eq" #[(view73 a0), (view73 a1)]
  | .MC_le a0 a1 => .node "mem_constraint.MC_le" #[(view73 a0), (view73 a1)]
  | .MC_lt a0 a1 => .node "mem_constraint.MC_lt" #[(view73 a0), (view73 a1)]
  | .MC_in_device a0 => .node "mem_constraint.MC_in_device" #[(view73 a0)]
  | .MC_or a0 a1 => .node "mem_constraint.MC_or" #[(view88 a0), (view88 a1)]
  | .MC_conj a0 => .node "mem_constraint.MC_conj" #[(view89 a0)]
  | .MC_not a0 => .node "mem_constraint.MC_not" #[(view88 a0)]
partial def view89 (x : List (mem_constraint CerbMem.IntegerValue)) : Shape :=
  .node "List" (x.toArray.map view88)
partial def view90 (x : undefined_behaviour) : Shape :=
  match x with
  | .DUMMY a0 => .node "undefined_behaviour.DUMMY" #[(view3 a0)]
  | .UB_unspecified_lvalue  => .node "undefined_behaviour.UB_unspecified_lvalue" #[]
  | .UB_std_omission a0 => .node "undefined_behaviour.UB_std_omission" #[(view91 a0)]
  | .UB001  => .node "undefined_behaviour.UB001" #[]
  | .UB002  => .node "undefined_behaviour.UB002" #[]
  | .UB003  => .node "undefined_behaviour.UB003" #[]
  | .UB004a_incorrect_main_return_type  => .node "undefined_behaviour.UB004a_incorrect_main_return_type" #[]
  | .UB004b_incorrect_main_argument1  => .node "undefined_behaviour.UB004b_incorrect_main_argument1" #[]
  | .UB004c_incorrect_main_argument2  => .node "undefined_behaviour.UB004c_incorrect_main_argument2" #[]
  | .UB004d_main_not_function  => .node "undefined_behaviour.UB004d_main_not_function" #[]
  | .UB005_data_race  => .node "undefined_behaviour.UB005_data_race" #[]
  | .UB006  => .node "undefined_behaviour.UB006" #[]
  | .UB007  => .node "undefined_behaviour.UB007" #[]
  | .UB008_multiple_linkage  => .node "undefined_behaviour.UB008_multiple_linkage" #[]
  | .UB009_outside_lifetime  => .node "undefined_behaviour.UB009_outside_lifetime" #[]
  | .UB010_pointer_to_dead_object  => .node "undefined_behaviour.UB010_pointer_to_dead_object" #[]
  | .UB011_use_indeterminate_automatic_object  => .node "undefined_behaviour.UB011_use_indeterminate_automatic_object" #[]
  | .UB_modifying_temporary_lifetime  => .node "undefined_behaviour.UB_modifying_temporary_lifetime" #[]
  | .UB012_lvalue_read_trap_representation  => .node "undefined_behaviour.UB012_lvalue_read_trap_representation" #[]
  | .UB013_lvalue_side_effect_trap_representation  => .node "undefined_behaviour.UB013_lvalue_side_effect_trap_representation" #[]
  | .UB014_unsupported_negative_zero  => .node "undefined_behaviour.UB014_unsupported_negative_zero" #[]
  | .UB015_incompatible_redeclaration  => .node "undefined_behaviour.UB015_incompatible_redeclaration" #[]
  | .UB016  => .node "undefined_behaviour.UB016" #[]
  | .UB017_out_of_range_floating_integer_conversion  => .node "undefined_behaviour.UB017_out_of_range_floating_integer_conversion" #[]
  | .UB018  => .node "undefined_behaviour.UB018" #[]
  | .UB019_lvalue_not_an_object  => .node "undefined_behaviour.UB019_lvalue_not_an_object" #[]
  | .UB020_nonarray_incomplete_lvalue_conversion  => .node "undefined_behaviour.UB020_nonarray_incomplete_lvalue_conversion" #[]
  | .UB021  => .node "undefined_behaviour.UB021" #[]
  | .UB022_register_array_decay  => .node "undefined_behaviour.UB022_register_array_decay" #[]
  | .UB023  => .node "undefined_behaviour.UB023" #[]
  | .UB024_out_of_range_pointer_to_integer_conversion  => .node "undefined_behaviour.UB024_out_of_range_pointer_to_integer_conversion" #[]
  | .UB025_misaligned_pointer_conversion  => .node "undefined_behaviour.UB025_misaligned_pointer_conversion" #[]
  | .UB026  => .node "undefined_behaviour.UB026" #[]
  | .UB027  => .node "undefined_behaviour.UB027" #[]
  | .UB028  => .node "undefined_behaviour.UB028" #[]
  | .UB029  => .node "undefined_behaviour.UB029" #[]
  | .UB030  => .node "undefined_behaviour.UB030" #[]
  | .UB031  => .node "undefined_behaviour.UB031" #[]
  | .UB032  => .node "undefined_behaviour.UB032" #[]
  | .UB033_modifying_string_literal  => .node "undefined_behaviour.UB033_modifying_string_literal" #[]
  | .UB034  => .node "undefined_behaviour.UB034" #[]
  | .UB035_unsequenced_race  => .node "undefined_behaviour.UB035_unsequenced_race" #[]
  | .UB036_exceptional_condition  => .node "undefined_behaviour.UB036_exceptional_condition" #[]
  | .UB037_illtyped_load  => .node "undefined_behaviour.UB037_illtyped_load" #[]
  | .UB038_number_of_args  => .node "undefined_behaviour.UB038_number_of_args" #[]
  | .UB039  => .node "undefined_behaviour.UB039" #[]
  | .UB040  => .node "undefined_behaviour.UB040" #[]
  | .UB041_function_not_compatible  => .node "undefined_behaviour.UB041_function_not_compatible" #[]
  | .UB042_access_atomic_structUnion_member  => .node "undefined_behaviour.UB042_access_atomic_structUnion_member" #[]
  | .UB043_indirection_invalid_value  => .node "undefined_behaviour.UB043_indirection_invalid_value" #[]
  | .UB044  => .node "undefined_behaviour.UB044" #[]
  | .UB045a_division_by_zero  => .node "undefined_behaviour.UB045a_division_by_zero" #[]
  | .UB045b_modulo_by_zero  => .node "undefined_behaviour.UB045b_modulo_by_zero" #[]
  | .UB045c_quotient_not_representable  => .node "undefined_behaviour.UB045c_quotient_not_representable" #[]
  | .UB046_array_pointer_outside  => .node "undefined_behaviour.UB046_array_pointer_outside" #[]
  | .UB047a_array_pointer_addition_beyond_indirection  => .node "undefined_behaviour.UB047a_array_pointer_addition_beyond_indirection" #[]
  | .UB047b_array_pointer_subtraction_beyond_indirection  => .node "undefined_behaviour.UB047b_array_pointer_subtraction_beyond_indirection" #[]
  | .UB048_disjoint_array_pointers_subtraction  => .node "undefined_behaviour.UB048_disjoint_array_pointers_subtraction" #[]
  | .UB049  => .node "undefined_behaviour.UB049" #[]
  | .UB050_pointers_subtraction_not_representable  => .node "undefined_behaviour.UB050_pointers_subtraction_not_representable" #[]
  | .UB051a_negative_shift  => .node "undefined_behaviour.UB051a_negative_shift" #[]
  | .UB51b_shift_too_large  => .node "undefined_behaviour.UB51b_shift_too_large" #[]
  | .UB052a_negative_left_shift  => .node "undefined_behaviour.UB052a_negative_left_shift" #[]
  | .UB052b_non_representable_left_shift  => .node "undefined_behaviour.UB052b_non_representable_left_shift" #[]
  | .UB053_distinct_aggregate_union_pointer_comparison  => .node "undefined_behaviour.UB053_distinct_aggregate_union_pointer_comparison" #[]
  | .UB054a_inexactly_overlapping_assignment  => .node "undefined_behaviour.UB054a_inexactly_overlapping_assignment" #[]
  | .UB054b_incompatible_overlapping_assignment  => .node "undefined_behaviour.UB054b_incompatible_overlapping_assignment" #[]
  | .UB055_invalid_integer_constant_expression  => .node "undefined_behaviour.UB055_invalid_integer_constant_expression" #[]
  | .UB056  => .node "undefined_behaviour.UB056" #[]
  | .UB057  => .node "undefined_behaviour.UB057" #[]
  | .UB058  => .node "undefined_behaviour.UB058" #[]
  | .UB059_incomplete_no_linkage_identifier  => .node "undefined_behaviour.UB059_incomplete_no_linkage_identifier" #[]
  | .UB060_block_scope_function_with_storage_class  => .node "undefined_behaviour.UB060_block_scope_function_with_storage_class" #[]
  | .UB061_no_named_members  => .node "undefined_behaviour.UB061_no_named_members" #[]
  | .UB062  => .node "undefined_behaviour.UB062" #[]
  | .UB063  => .node "undefined_behaviour.UB063" #[]
  | .UB064_modifying_const  => .node "undefined_behaviour.UB064_modifying_const" #[]
  | .UB065  => .node "undefined_behaviour.UB065" #[]
  | .UB066_qualified_function_specification  => .node "undefined_behaviour.UB066_qualified_function_specification" #[]
  | .UB067  => .node "undefined_behaviour.UB067" #[]
  | .UB068  => .node "undefined_behaviour.UB068" #[]
  | .UB069  => .node "undefined_behaviour.UB069" #[]
  | .UB070_inline_not_defined  => .node "undefined_behaviour.UB070_inline_not_defined" #[]
  | .UB071_noreturn  => .node "undefined_behaviour.UB071_noreturn" #[]
  | .UB072_incompatible_alignment_specifiers  => .node "undefined_behaviour.UB072_incompatible_alignment_specifiers" #[]
  | .UB073  => .node "undefined_behaviour.UB073" #[]
  | .UB074  => .node "undefined_behaviour.UB074" #[]
  | .UB075  => .node "undefined_behaviour.UB075" #[]
  | .UB076  => .node "undefined_behaviour.UB076" #[]
  | .UB077  => .node "undefined_behaviour.UB077" #[]
  | .UB078_modified_void_parameter  => .node "undefined_behaviour.UB078_modified_void_parameter" #[]
  | .UB079  => .node "undefined_behaviour.UB079" #[]
  | .UB080  => .node "undefined_behaviour.UB080" #[]
  | .UB081_scalar_initializer_not_single_expression  => .node "undefined_behaviour.UB081_scalar_initializer_not_single_expression" #[]
  | .UB082  => .node "undefined_behaviour.UB082" #[]
  | .UB083  => .node "undefined_behaviour.UB083" #[]
  | .UB084  => .node "undefined_behaviour.UB084" #[]
  | .UB085  => .node "undefined_behaviour.UB085" #[]
  | .UB086_incomplete_adjusted_parameter  => .node "undefined_behaviour.UB086_incomplete_adjusted_parameter" #[]
  | .UB087  => .node "undefined_behaviour.UB087" #[]
  | .UB088_reached_end_of_function  => .node "undefined_behaviour.UB088_reached_end_of_function" #[]
  | .UB089_tentative_definition_internal_linkage  => .node "undefined_behaviour.UB089_tentative_definition_internal_linkage" #[]
  | .UB090  => .node "undefined_behaviour.UB090" #[]
  | .UB091  => .node "undefined_behaviour.UB091" #[]
  | .UB092  => .node "undefined_behaviour.UB092" #[]
  | .UB093  => .node "undefined_behaviour.UB093" #[]
  | .UB094  => .node "undefined_behaviour.UB094" #[]
  | .UB095  => .node "undefined_behaviour.UB095" #[]
  | .UB096  => .node "undefined_behaviour.UB096" #[]
  | .UB097  => .node "undefined_behaviour.UB097" #[]
  | .UB098  => .node "undefined_behaviour.UB098" #[]
  | .UB099  => .node "undefined_behaviour.UB099" #[]
  | .UB100  => .node "undefined_behaviour.UB100" #[]
  | .UB101  => .node "undefined_behaviour.UB101" #[]
  | .UB102  => .node "undefined_behaviour.UB102" #[]
  | .UB103  => .node "undefined_behaviour.UB103" #[]
  | .UB104  => .node "undefined_behaviour.UB104" #[]
  | .UB105  => .node "undefined_behaviour.UB105" #[]
  | .UB106  => .node "undefined_behaviour.UB106" #[]
  | .UB107  => .node "undefined_behaviour.UB107" #[]
  | .UB108  => .node "undefined_behaviour.UB108" #[]
  | .UB109  => .node "undefined_behaviour.UB109" #[]
  | .UB110  => .node "undefined_behaviour.UB110" #[]
  | .UB111_illtyped_assert  => .node "undefined_behaviour.UB111_illtyped_assert" #[]
  | .UB112  => .node "undefined_behaviour.UB112" #[]
  | .UB113  => .node "undefined_behaviour.UB113" #[]
  | .UB114  => .node "undefined_behaviour.UB114" #[]
  | .UB115  => .node "undefined_behaviour.UB115" #[]
  | .UB116  => .node "undefined_behaviour.UB116" #[]
  | .UB117  => .node "undefined_behaviour.UB117" #[]
  | .UB118  => .node "undefined_behaviour.UB118" #[]
  | .UB119  => .node "undefined_behaviour.UB119" #[]
  | .UB120  => .node "undefined_behaviour.UB120" #[]
  | .UB121  => .node "undefined_behaviour.UB121" #[]
  | .UB122  => .node "undefined_behaviour.UB122" #[]
  | .UB123  => .node "undefined_behaviour.UB123" #[]
  | .UB124  => .node "undefined_behaviour.UB124" #[]
  | .UB125  => .node "undefined_behaviour.UB125" #[]
  | .UB126  => .node "undefined_behaviour.UB126" #[]
  | .UB127  => .node "undefined_behaviour.UB127" #[]
  | .UB128  => .node "undefined_behaviour.UB128" #[]
  | .UB129  => .node "undefined_behaviour.UB129" #[]
  | .UB130  => .node "undefined_behaviour.UB130" #[]
  | .UB131  => .node "undefined_behaviour.UB131" #[]
  | .UB132  => .node "undefined_behaviour.UB132" #[]
  | .UB133  => .node "undefined_behaviour.UB133" #[]
  | .UB134  => .node "undefined_behaviour.UB134" #[]
  | .UB135  => .node "undefined_behaviour.UB135" #[]
  | .UB136  => .node "undefined_behaviour.UB136" #[]
  | .UB137  => .node "undefined_behaviour.UB137" #[]
  | .UB138  => .node "undefined_behaviour.UB138" #[]
  | .UB139  => .node "undefined_behaviour.UB139" #[]
  | .UB140  => .node "undefined_behaviour.UB140" #[]
  | .UB141  => .node "undefined_behaviour.UB141" #[]
  | .UB142  => .node "undefined_behaviour.UB142" #[]
  | .UB143  => .node "undefined_behaviour.UB143" #[]
  | .UB144  => .node "undefined_behaviour.UB144" #[]
  | .UB145  => .node "undefined_behaviour.UB145" #[]
  | .UB146  => .node "undefined_behaviour.UB146" #[]
  | .UB147  => .node "undefined_behaviour.UB147" #[]
  | .UB148  => .node "undefined_behaviour.UB148" #[]
  | .UB149  => .node "undefined_behaviour.UB149" #[]
  | .UB150  => .node "undefined_behaviour.UB150" #[]
  | .UB151  => .node "undefined_behaviour.UB151" #[]
  | .UB152  => .node "undefined_behaviour.UB152" #[]
  | .UB153a_insufficient_arguments_for_format  => .node "undefined_behaviour.UB153a_insufficient_arguments_for_format" #[]
  | .UB153b_illtyped_argument_for_format  => .node "undefined_behaviour.UB153b_illtyped_argument_for_format" #[]
  | .Invalid_format a0 => .node "undefined_behaviour.Invalid_format" #[(view3 a0)]
  | .UB154  => .node "undefined_behaviour.UB154" #[]
  | .UB155  => .node "undefined_behaviour.UB155" #[]
  | .UB156  => .node "undefined_behaviour.UB156" #[]
  | .UB157  => .node "undefined_behaviour.UB157" #[]
  | .UB158_invalid_length_modifier  => .node "undefined_behaviour.UB158_invalid_length_modifier" #[]
  | .UB159  => .node "undefined_behaviour.UB159" #[]
  | .UB160  => .node "undefined_behaviour.UB160" #[]
  | .UB161  => .node "undefined_behaviour.UB161" #[]
  | .UB162  => .node "undefined_behaviour.UB162" #[]
  | .UB163  => .node "undefined_behaviour.UB163" #[]
  | .UB164  => .node "undefined_behaviour.UB164" #[]
  | .UB165  => .node "undefined_behaviour.UB165" #[]
  | .UB166  => .node "undefined_behaviour.UB166" #[]
  | .UB167  => .node "undefined_behaviour.UB167" #[]
  | .UB168  => .node "undefined_behaviour.UB168" #[]
  | .UB169  => .node "undefined_behaviour.UB169" #[]
  | .UB170  => .node "undefined_behaviour.UB170" #[]
  | .UB171  => .node "undefined_behaviour.UB171" #[]
  | .UB172  => .node "undefined_behaviour.UB172" #[]
  | .UB173  => .node "undefined_behaviour.UB173" #[]
  | .UB174  => .node "undefined_behaviour.UB174" #[]
  | .UB175  => .node "undefined_behaviour.UB175" #[]
  | .UB176  => .node "undefined_behaviour.UB176" #[]
  | .UB177  => .node "undefined_behaviour.UB177" #[]
  | .UB178  => .node "undefined_behaviour.UB178" #[]
  | .UB179a_non_matching_allocation_free  => .node "undefined_behaviour.UB179a_non_matching_allocation_free" #[]
  | .UB179b_dead_allocation_free  => .node "undefined_behaviour.UB179b_dead_allocation_free" #[]
  | .UB179c_non_matching_allocation_realloc  => .node "undefined_behaviour.UB179c_non_matching_allocation_realloc" #[]
  | .UB179d_dead_allocation_realloc  => .node "undefined_behaviour.UB179d_dead_allocation_realloc" #[]
  | .UB180  => .node "undefined_behaviour.UB180" #[]
  | .UB181  => .node "undefined_behaviour.UB181" #[]
  | .UB182  => .node "undefined_behaviour.UB182" #[]
  | .UB183  => .node "undefined_behaviour.UB183" #[]
  | .UB184  => .node "undefined_behaviour.UB184" #[]
  | .UB185  => .node "undefined_behaviour.UB185" #[]
  | .UB186  => .node "undefined_behaviour.UB186" #[]
  | .UB187  => .node "undefined_behaviour.UB187" #[]
  | .UB188  => .node "undefined_behaviour.UB188" #[]
  | .UB189  => .node "undefined_behaviour.UB189" #[]
  | .UB190  => .node "undefined_behaviour.UB190" #[]
  | .UB191  => .node "undefined_behaviour.UB191" #[]
  | .UB192  => .node "undefined_behaviour.UB192" #[]
  | .UB193  => .node "undefined_behaviour.UB193" #[]
  | .UB194  => .node "undefined_behaviour.UB194" #[]
  | .UB195  => .node "undefined_behaviour.UB195" #[]
  | .UB196  => .node "undefined_behaviour.UB196" #[]
  | .UB197  => .node "undefined_behaviour.UB197" #[]
  | .UB198  => .node "undefined_behaviour.UB198" #[]
  | .UB199  => .node "undefined_behaviour.UB199" #[]
  | .UB200  => .node "undefined_behaviour.UB200" #[]
  | .UB201  => .node "undefined_behaviour.UB201" #[]
  | .UB202  => .node "undefined_behaviour.UB202" #[]
  | .UB203  => .node "undefined_behaviour.UB203" #[]
  | .UB204_illtyped_Static_assert  => .node "undefined_behaviour.UB204_illtyped_Static_assert" #[]
  | .UB205_atomic_store_memorder  => .node "undefined_behaviour.UB205_atomic_store_memorder" #[]
  | .UB206_atomic_load_memorder  => .node "undefined_behaviour.UB206_atomic_load_memorder" #[]
  | .UB207_atomic_compare_exchange_memorder  => .node "undefined_behaviour.UB207_atomic_compare_exchange_memorder" #[]
  | .UB_CERB001_integer_to_dead_pointer  => .node "undefined_behaviour.UB_CERB001_integer_to_dead_pointer" #[]
  | .UB_CERB002a_out_of_bound_load  => .node "undefined_behaviour.UB_CERB002a_out_of_bound_load" #[]
  | .UB_CERB002b_out_of_bound_store  => .node "undefined_behaviour.UB_CERB002b_out_of_bound_store" #[]
  | .UB_CERB002c_out_of_bound_free  => .node "undefined_behaviour.UB_CERB002c_out_of_bound_free" #[]
  | .UB_CERB002d_out_of_bound_realloc  => .node "undefined_behaviour.UB_CERB002d_out_of_bound_realloc" #[]
  | .UB_CERB003_invalid_function_pointer  => .node "undefined_behaviour.UB_CERB003_invalid_function_pointer" #[]
  | .UB_CHERI_InvalidCap  => .node "undefined_behaviour.UB_CHERI_InvalidCap" #[]
  | .UB_CHERI_InsufficientPermissions  => .node "undefined_behaviour.UB_CHERI_InsufficientPermissions" #[]
  | .UB_CHERI_BoundsViolation  => .node "undefined_behaviour.UB_CHERI_BoundsViolation" #[]
  | .UB_CHERI_UndefinedTag  => .node "undefined_behaviour.UB_CHERI_UndefinedTag" #[]
  | .UB_CHERI_ZeroLength  => .node "undefined_behaviour.UB_CHERI_ZeroLength" #[]
  | .UB_CERB004_unspecified a0 => .node "undefined_behaviour.UB_CERB004_unspecified" #[(view92 a0)]
  | .UB_CERB005_free_nullptr  => .node "undefined_behaviour.UB_CERB005_free_nullptr" #[]
partial def view91 (x : undefined_by_omission) : Shape :=
  match x with
  | .UB_OMIT_memcpy_non_object  => .node "undefined_by_omission.UB_OMIT_memcpy_non_object" #[]
  | .UB_OMIT_memcpy_out_of_bound  => .node "undefined_by_omission.UB_OMIT_memcpy_out_of_bound" #[]
partial def view92 (x : unspecified_ub_context) : Shape :=
  match x with
  | .UB_unspec_equality_ptr_vs_NULL  => .node "unspecified_ub_context.UB_unspec_equality_ptr_vs_NULL" #[]
  | .UB_unspec_equality_both_arith_or_ptr  => .node "unspecified_ub_context.UB_unspec_equality_both_arith_or_ptr" #[]
  | .UB_unspec_pointer_add  => .node "unspecified_ub_context.UB_unspec_pointer_add" #[]
  | .UB_unspec_pointer_sub  => .node "unspecified_ub_context.UB_unspec_pointer_sub" #[]
  | .UB_unspec_conditional  => .node "unspecified_ub_context.UB_unspec_conditional" #[]
  | .UB_unspec_copy_alloc_id  => .node "unspecified_ub_context.UB_unspec_copy_alloc_id" #[]
  | .UB_unspec_rvalue_memberof  => .node "unspecified_ub_context.UB_unspec_rvalue_memberof" #[]
  | .UB_unspec_memberofptr  => .node "unspecified_ub_context.UB_unspec_memberofptr" #[]
  | .UB_unspec_do  => .node "unspecified_ub_context.UB_unspec_do" #[]
partial def view93 (x : ctor) : Shape :=
  match x with
  | .Cnil a0 => .node "ctor.Cnil" #[(view62 a0)]
  | .Ccons  => .node "ctor.Ccons" #[]
  | .Ctuple  => .node "ctor.Ctuple" #[]
  | .Carray  => .node "ctor.Carray" #[]
  | .Civmax  => .node "ctor.Civmax" #[]
  | .Civmin  => .node "ctor.Civmin" #[]
  | .Civsizeof  => .node "ctor.Civsizeof" #[]
  | .Civalignof  => .node "ctor.Civalignof" #[]
  | .CivCOMPL  => .node "ctor.CivCOMPL" #[]
  | .CivAND  => .node "ctor.CivAND" #[]
  | .CivOR  => .node "ctor.CivOR" #[]
  | .CivXOR  => .node "ctor.CivXOR" #[]
  | .Cspecified  => .node "ctor.Cspecified" #[]
  | .Cunspecified  => .node "ctor.Cunspecified" #[]
  | .Cfvfromint  => .node "ctor.Cfvfromint" #[]
  | .Civfromfloat  => .node "ctor.Civfromfloat" #[]
  | .CivNULLcap a0 => .node "ctor.CivNULLcap" #[(view51 a0)]
partial def view94 (x : List (generic_pexpr Unit sym)) : Shape :=
  .node "List" (x.toArray.map view67)
partial def view95 (x : List (generic_pattern sym × generic_pexpr Unit sym)) : Shape :=
  .node "List" (x.toArray.map view96)
partial def view96 (x : generic_pattern sym × generic_pexpr Unit sym) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view97 a0), (view67 a1)]
partial def view97 (x : generic_pattern sym) : Shape :=
  match x with
  | .Pattern a0 a1 => .node "generic_pattern.Pattern" #[(view34 a0), (view98 a1)]
partial def view98 (x : generic_pattern_ sym) : Shape :=
  match x with
  | .CaseBase a0 => .node "generic_pattern_.CaseBase" #[(view99 a0)]
  | .CaseCtor a0 a1 => .node "generic_pattern_.CaseCtor" #[(view93 a0), (view100 a1)]
partial def view99 (x : Option sym × core_base_type) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view1 a0), (view62 a1)]
partial def view100 (x : List (generic_pattern sym)) : Shape :=
  .node "List" (x.toArray.map view97)
partial def view101 (x : pure_memop) : Shape :=
  match x with
  | .DeriveCap a0 a1 => .node "pure_memop.DeriveCap" #[(view102 a0), (view51 a1)]
  | .CapAssignValue  => .node "pure_memop.CapAssignValue" #[]
  | .Ptr_tIntValue  => .node "pure_memop.Ptr_tIntValue" #[]
  | .ByteFromInt  => .node "pure_memop.ByteFromInt" #[]
  | .IntFromByte  => .node "pure_memop.IntFromByte" #[]
partial def view102 (x : derivecap_op) : Shape :=
  match x with
  | .DCunary a0 => .node "derivecap_op.DCunary" #[(view103 a0)]
  | .DCbinary a0 => .node "derivecap_op.DCbinary" #[(view104 a0)]
partial def view103 (x : unaryOperator) : Shape :=
  match x with
  | .Plus  => .node "unaryOperator.Plus" #[]
  | .Minus  => .node "unaryOperator.Minus" #[]
  | .Bnot  => .node "unaryOperator.Bnot" #[]
  | .Address  => .node "unaryOperator.Address" #[]
  | .Indirection  => .node "unaryOperator.Indirection" #[]
  | .PostfixIncr  => .node "unaryOperator.PostfixIncr" #[]
  | .PostfixDecr  => .node "unaryOperator.PostfixDecr" #[]
partial def view104 (x : binaryOperator) : Shape :=
  match x with
  | .Arithmetic a0 => .node "binaryOperator.Arithmetic" #[(view105 a0)]
  | .Comma  => .node "binaryOperator.Comma" #[]
  | .And0  => .node "binaryOperator.And0" #[]
  | .Or0  => .node "binaryOperator.Or0" #[]
  | .Lt  => .node "binaryOperator.Lt" #[]
  | .Gt  => .node "binaryOperator.Gt" #[]
  | .Le  => .node "binaryOperator.Le" #[]
  | .Ge  => .node "binaryOperator.Ge" #[]
  | .Eq1  => .node "binaryOperator.Eq1" #[]
  | .Ne0  => .node "binaryOperator.Ne0" #[]
partial def view105 (x : arithmeticOperator) : Shape :=
  match x with
  | .Mul0  => .node "arithmeticOperator.Mul0" #[]
  | .Div0  => .node "arithmeticOperator.Div0" #[]
  | .Mod0  => .node "arithmeticOperator.Mod0" #[]
  | .Add0  => .node "arithmeticOperator.Add0" #[]
  | .Sub0  => .node "arithmeticOperator.Sub0" #[]
  | .Shl  => .node "arithmeticOperator.Shl" #[]
  | .Shr  => .node "arithmeticOperator.Shr" #[]
  | .Band  => .node "arithmeticOperator.Band" #[]
  | .Bxor  => .node "arithmeticOperator.Bxor" #[]
  | .Bor  => .node "arithmeticOperator.Bor" #[]
partial def view106 (x : binop) : Shape :=
  match x with
  | .OpAdd  => .node "binop.OpAdd" #[]
  | .OpSub  => .node "binop.OpSub" #[]
  | .OpMul  => .node "binop.OpMul" #[]
  | .OpDiv  => .node "binop.OpDiv" #[]
  | .OpRem_t  => .node "binop.OpRem_t" #[]
  | .OpRem_f  => .node "binop.OpRem_f" #[]
  | .OpExp  => .node "binop.OpExp" #[]
  | .OpEq  => .node "binop.OpEq" #[]
  | .OpGt  => .node "binop.OpGt" #[]
  | .OpLt  => .node "binop.OpLt" #[]
  | .OpGe  => .node "binop.OpGe" #[]
  | .OpLe  => .node "binop.OpLe" #[]
  | .OpAnd  => .node "binop.OpAnd" #[]
  | .OpOr  => .node "binop.OpOr" #[]
partial def view107 (x : iop) : Shape :=
  match x with
  | .IOpAdd  => .node "iop.IOpAdd" #[]
  | .IOpSub  => .node "iop.IOpSub" #[]
  | .IOpMul  => .node "iop.IOpMul" #[]
  | .IOpShl  => .node "iop.IOpShl" #[]
  | .IOpShr  => .node "iop.IOpShr" #[]
  | .IOpDiv  => .node "iop.IOpDiv" #[]
  | .IOpRem_t  => .node "iop.IOpRem_t" #[]
partial def view108 (x : List (identifier × generic_pexpr Unit sym)) : Shape :=
  .node "List" (x.toArray.map view109)
partial def view109 (x : identifier × generic_pexpr Unit sym) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view18 a0), (view67 a1)]
partial def view110 (x : generic_name sym) : Shape :=
  match x with
  | .Sym a0 => .node "generic_name.Sym" #[(view2 a0)]
  | .Impl a0 => .node "generic_name.Impl" #[(view70 a0)]
partial def view111 (x : Option Nat) : Shape :=
  match x with
  | .none  => .node "Option.none" #[]
  | .some a0 => .node "Option.some" #[(view4 a0)]
partial def view112 (x : generic_expr core_run_annotation Unit sym) : Shape :=
  match x with
  | .Expr a0 a1 => .node "generic_expr.Expr" #[(view34 a0), (view113 a1)]
partial def view113 (x : generic_expr_ core_run_annotation Unit sym) : Shape :=
  match x with
  | .Epure a0 => .node "generic_expr_.Epure" #[(view67 a0)]
  | .Ememop a0 a1 => .node "generic_expr_.Ememop" #[(view114 a0), (view94 a1)]
  | .Eaction a0 => .node "generic_expr_.Eaction" #[(view117 a0)]
  | .Ecase a0 a1 => .node "generic_expr_.Ecase" #[(view67 a0), (view130 a1)]
  | .Elet a0 a1 a2 => .node "generic_expr_.Elet" #[(view97 a0), (view67 a1), (view112 a2)]
  | .Eif a0 a1 a2 => .node "generic_expr_.Eif" #[(view67 a0), (view112 a1), (view112 a2)]
  | .Eccall a0 a1 a2 a3 => .node "generic_expr_.Eccall" #[(view120 a0), (view67 a1), (view67 a2), (view94 a3)]
  | .Eproc a0 a1 a2 => .node "generic_expr_.Eproc" #[(view120 a0), (view110 a1), (view94 a2)]
  | .Eunseq a0 => .node "generic_expr_.Eunseq" #[(view132 a0)]
  | .Ewseq a0 a1 a2 => .node "generic_expr_.Ewseq" #[(view97 a0), (view112 a1), (view112 a2)]
  | .Esseq a0 a1 a2 => .node "generic_expr_.Esseq" #[(view97 a0), (view112 a1), (view112 a2)]
  | .Ebound a0 => .node "generic_expr_.Ebound" #[(view112 a0)]
  | .End a0 => .node "generic_expr_.End" #[(view132 a0)]
  | .Esave a0 a1 a2 => .node "generic_expr_.Esave" #[(view66 a0), (view133 a1), (view112 a2)]
  | .Erun a0 a1 a2 => .node "generic_expr_.Erun" #[(view120 a0), (view2 a1), (view94 a2)]
  | .Epar a0 => .node "generic_expr_.Epar" #[(view132 a0)]
  | .Ewait a0 => .node "generic_expr_.Ewait" #[(view4 a0)]
  | .Eannot a0 a1 => .node "generic_expr_.Eannot" #[(view140 a0), (view112 a1)]
  | .Eexcluded a0 a1 => .node "generic_expr_.Eexcluded" #[(view4 a0), (view119 a1)]
partial def view114 (x : generic_memop sym) : Shape :=
  match x with
  | .PtrEq  => .node "generic_memop.PtrEq" #[]
  | .PtrNe  => .node "generic_memop.PtrNe" #[]
  | .PtrLt  => .node "generic_memop.PtrLt" #[]
  | .PtrGt  => .node "generic_memop.PtrGt" #[]
  | .PtrLe  => .node "generic_memop.PtrLe" #[]
  | .PtrGe  => .node "generic_memop.PtrGe" #[]
  | .Ptrdiff  => .node "generic_memop.Ptrdiff" #[]
  | .IntFromPtr  => .node "generic_memop.IntFromPtr" #[]
  | .PtrFromInt  => .node "generic_memop.PtrFromInt" #[]
  | .PtrValidForDeref  => .node "generic_memop.PtrValidForDeref" #[]
  | .PtrWellAligned  => .node "generic_memop.PtrWellAligned" #[]
  | .PtrArrayShift  => .node "generic_memop.PtrArrayShift" #[]
  | .PtrMemberShift a0 a1 => .node "generic_memop.PtrMemberShift" #[(view2 a0), (view18 a1)]
  | .Memcpy  => .node "generic_memop.Memcpy" #[]
  | .Memcmp  => .node "generic_memop.Memcmp" #[]
  | .Realloc  => .node "generic_memop.Realloc" #[]
  | .Va_start  => .node "generic_memop.Va_start" #[]
  | .Va_copy  => .node "generic_memop.Va_copy" #[]
  | .Va_arg  => .node "generic_memop.Va_arg" #[]
  | .Va_end  => .node "generic_memop.Va_end" #[]
  | .Copy_alloc_id  => .node "generic_memop.Copy_alloc_id" #[]
  | .CHERI_intrinsic a0 a1 => .node "generic_memop.CHERI_intrinsic" #[(view3 a0), (view115 a1)]
partial def view115 (x : ctype × List ctype) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view33 a0), (view116 a1)]
partial def view116 (x : List ctype) : Shape :=
  .node "List" (x.toArray.map view33)
partial def view117 (x : generic_paction core_run_annotation Unit sym) : Shape :=
  match x with
  | .Paction a0 a1 => .node "generic_paction.Paction" #[(view118 a0), (view119 a1)]
partial def view118 (x : polarity) : Shape :=
  match x with
  | .Pos  => .node "polarity.Pos" #[]
  | .Neg0  => .node "polarity.Neg0" #[]
partial def view119 (x : generic_action core_run_annotation Unit sym) : Shape :=
  match x with
  | .Action a0 a1 a2 => .node "generic_action.Action" #[(view6 a0), (view120 a1), (view124 a2)]
partial def view120 (x : core_run_annotation) : Shape :=
  match x with
  | .mk a0 a1 a2 => .node "core_run_annotation.mk" #[(view121 a0), (view123 a1), (view123 a2)]
partial def view121 (x : Pset (thread_id × aid)) : Shape :=
  match x with
  | .Empty  => .node "Pset.Empty" #[]
  | .Node a0 a1 a2 a3 => .node "Pset.Node" #[(view121 a0), (view122 a1), (view121 a2), (view4 a3)]
partial def view122 (x : thread_id × aid) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view4 a0), (view4 a1)]
partial def view123 (x : Pset aid) : Shape :=
  match x with
  | .Empty  => .node "Pset.Empty" #[]
  | .Node a0 a1 a2 a3 => .node "Pset.Node" #[(view123 a0), (view4 a1), (view123 a2), (view4 a3)]
partial def view124 (x : generic_action_ Unit sym) : Shape :=
  match x with
  | .Create a0 a1 a2 => .node "generic_action_.Create" #[(view67 a0), (view67 a1), (view125 a2)]
  | .CreateReadOnly a0 a1 a2 a3 => .node "generic_action_.CreateReadOnly" #[(view67 a0), (view67 a1), (view67 a2), (view125 a3)]
  | .Alloc0 a0 a1 a2 => .node "generic_action_.Alloc0" #[(view67 a0), (view67 a1), (view125 a2)]
  | .Kill a0 a1 => .node "generic_action_.Kill" #[(view127 a0), (view67 a1)]
  | .Store0 a0 a1 a2 a3 a4 => .node "generic_action_.Store0" #[(view51 a0), (view67 a1), (view67 a2), (view67 a3), (view128 a4)]
  | .Load0 a0 a1 a2 => .node "generic_action_.Load0" #[(view67 a0), (view67 a1), (view128 a2)]
  | .SeqRMW a0 a1 a2 a3 a4 => .node "generic_action_.SeqRMW" #[(view51 a0), (view67 a1), (view67 a2), (view2 a3), (view67 a4)]
  | .RMW0 a0 a1 a2 a3 a4 a5 => .node "generic_action_.RMW0" #[(view67 a0), (view67 a1), (view67 a2), (view67 a3), (view128 a4), (view128 a5)]
  | .Fence0 a0 => .node "generic_action_.Fence0" #[(view128 a0)]
  | .CompareExchangeStrong a0 a1 a2 a3 a4 a5 => .node "generic_action_.CompareExchangeStrong" #[(view67 a0), (view67 a1), (view67 a2), (view67 a3), (view128 a4), (view128 a5)]
  | .CompareExchangeWeak a0 a1 a2 a3 a4 a5 => .node "generic_action_.CompareExchangeWeak" #[(view67 a0), (view67 a1), (view67 a2), (view67 a3), (view128 a4), (view128 a5)]
  | .LinuxFence a0 => .node "generic_action_.LinuxFence" #[(view129 a0)]
  | .LinuxLoad a0 a1 a2 => .node "generic_action_.LinuxLoad" #[(view67 a0), (view67 a1), (view129 a2)]
  | .LinuxStore a0 a1 a2 a3 => .node "generic_action_.LinuxStore" #[(view67 a0), (view67 a1), (view67 a2), (view129 a3)]
  | .LinuxRMW a0 a1 a2 a3 => .node "generic_action_.LinuxRMW" #[(view67 a0), (view67 a1), (view67 a2), (view129 a3)]
partial def view125 (x : prefix0) : Shape :=
  match x with
  | .PrefSource a0 a1 => .node "prefix0.PrefSource" #[(view6 a0), (view126 a1)]
  | .PrefFunArg a0 a1 a2 => .node "prefix0.PrefFunArg" #[(view6 a0), (view3 a1), (view32 a2)]
  | .PrefStringLiteral a0 a1 => .node "prefix0.PrefStringLiteral" #[(view6 a0), (view3 a1)]
  | .PrefCompoundLiteral a0 a1 => .node "prefix0.PrefCompoundLiteral" #[(view6 a0), (view3 a1)]
  | .PrefMalloc  => .node "prefix0.PrefMalloc" #[]
  | .PrefTemporaryLifetime a0 a1 => .node "prefix0.PrefTemporaryLifetime" #[(view6 a0), (view3 a1)]
  | .PrefOther a0 => .node "prefix0.PrefOther" #[(view3 a0)]
partial def view126 (x : List sym) : Shape :=
  .node "List" (x.toArray.map view2)
partial def view127 (x : kill_kind) : Shape :=
  match x with
  | .Dynamic0  => .node "kill_kind.Dynamic0" #[]
  | .Static0 a0 => .node "kill_kind.Static0" #[(view33 a0)]
partial def view128 (x : memory_order) : Shape :=
  match x with
  | .NA  => .node "memory_order.NA" #[]
  | .Seq_cst  => .node "memory_order.Seq_cst" #[]
  | .Relaxed  => .node "memory_order.Relaxed" #[]
  | .Release  => .node "memory_order.Release" #[]
  | .Acquire  => .node "memory_order.Acquire" #[]
  | .Consume  => .node "memory_order.Consume" #[]
  | .Acq_rel  => .node "memory_order.Acq_rel" #[]
partial def view129 (x : linux_memory_order) : Shape :=
  match x with
  | .Once  => .node "linux_memory_order.Once" #[]
  | .LAcquire  => .node "linux_memory_order.LAcquire" #[]
  | .LRelease  => .node "linux_memory_order.LRelease" #[]
  | .Rmb  => .node "linux_memory_order.Rmb" #[]
  | .Wmb  => .node "linux_memory_order.Wmb" #[]
  | .Mb  => .node "linux_memory_order.Mb" #[]
  | .RbDep  => .node "linux_memory_order.RbDep" #[]
  | .RcuLock  => .node "linux_memory_order.RcuLock" #[]
  | .RcuUnlock  => .node "linux_memory_order.RcuUnlock" #[]
  | .SyncRcu  => .node "linux_memory_order.SyncRcu" #[]
partial def view130 (x : List (generic_pattern sym × generic_expr core_run_annotation Unit sym)) : Shape :=
  .node "List" (x.toArray.map view131)
partial def view131 (x : generic_pattern sym × generic_expr core_run_annotation Unit sym) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view97 a0), (view112 a1)]
partial def view132 (x : List (generic_expr core_run_annotation Unit sym)) : Shape :=
  .node "List" (x.toArray.map view112)
partial def view133 (x : List (sym × (core_base_type × Option (ctype × pass_by_value_or_pointer)) × generic_pexpr Unit sym)) : Shape :=
  .node "List" (x.toArray.map view134)
partial def view134 (x : sym × (core_base_type × Option (ctype × pass_by_value_or_pointer)) × generic_pexpr Unit sym) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view2 a0), (view135 a1)]
partial def view135 (x : (core_base_type × Option (ctype × pass_by_value_or_pointer)) × generic_pexpr Unit sym) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view136 a0), (view67 a1)]
partial def view136 (x : core_base_type × Option (ctype × pass_by_value_or_pointer)) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view62 a0), (view137 a1)]
partial def view137 (x : Option (ctype × pass_by_value_or_pointer)) : Shape :=
  match x with
  | .none  => .node "Option.none" #[]
  | .some a0 => .node "Option.some" #[(view138 a0)]
partial def view138 (x : ctype × pass_by_value_or_pointer) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view33 a0), (view139 a1)]
partial def view139 (x : pass_by_value_or_pointer) : Shape :=
  match x with
  | .By_pointer  => .node "pass_by_value_or_pointer.By_pointer" #[]
  | .By_value  => .node "pass_by_value_or_pointer.By_value" #[]
partial def view140 (x : List dyn_annotation) : Shape :=
  .node "List" (x.toArray.map view141)
partial def view141 (x : dyn_annotation) : Shape :=
  match x with
  | .DA_neg a0 a1 a2 => .node "dyn_annotation.DA_neg" #[(view4 a0), (view142 a1), (view143 a2)]
  | .DA_pos a0 a1 => .node "dyn_annotation.DA_pos" #[(view142 a0), (view143 a1)]
partial def view142 (x : List Nat) : Shape :=
  .node "List" (x.toArray.map view4)
partial def view143 (x : CerbMem.Footprint) : Shape :=
  match x with
  | .FP a0 a1 a2 => .node "CerbMem.Footprint.FP" #[(view144 a0), (view32 a1), (view32 a2)]
partial def view144 (x : CerbMem.FootprintAccess) : Shape :=
  match x with
  | .W  => .node "CerbMem.FootprintAccess.W" #[]
  | .R  => .node "CerbMem.FootprintAccess.R" #[]
partial def view145 (x : Fmap implementation_constant (generic_impl_decl Unit)) : Shape :=
  match x with
  | .empty  => .node "Fmap.empty" #[]
  | .mk _ a1 => .node "Fmap.mk" #[(view146 a1)]
partial def view146 (x : Pmap implementation_constant (generic_impl_decl Unit)) : Shape :=
  match x with
  | .Empty  => .node "Pmap.Empty" #[]
  | .Node a0 a1 a2 a3 a4 => .node "Pmap.Node" #[(view146 a0), (view70 a1), (view147 a2), (view146 a3), (view4 a4)]
partial def view147 (x : generic_impl_decl Unit) : Shape :=
  match x with
  | .Def a0 a1 => .node "generic_impl_decl.Def" #[(view62 a0), (view67 a1)]
  | .IFun a0 a1 a2 => .node "generic_impl_decl.IFun" #[(view62 a0), (view65 a1), (view67 a2)]
partial def view148 (x : List (sym × generic_globs core_run_annotation Unit)) : Shape :=
  .node "List" (x.toArray.map view149)
partial def view149 (x : sym × generic_globs core_run_annotation Unit) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view2 a0), (view150 a1)]
partial def view150 (x : generic_globs core_run_annotation Unit) : Shape :=
  match x with
  | .GlobalDef a0 a1 => .node "generic_globs.GlobalDef" #[(view151 a0), (view112 a1)]
  | .GlobalDecl a0 => .node "generic_globs.GlobalDecl" #[(view151 a0)]
partial def view151 (x : core_base_type × ctype) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view62 a0), (view33 a1)]
partial def view152 (x : Fmap identifier (List sym × linking_kind)) : Shape :=
  match x with
  | .empty  => .node "Fmap.empty" #[]
  | .mk _ a1 => .node "Fmap.mk" #[(view153 a1)]
partial def view153 (x : Pmap identifier (List sym × linking_kind)) : Shape :=
  match x with
  | .Empty  => .node "Pmap.Empty" #[]
  | .Node a0 a1 a2 a3 a4 => .node "Pmap.Node" #[(view153 a0), (view18 a1), (view154 a2), (view153 a3), (view4 a4)]
partial def view154 (x : List sym × linking_kind) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view126 a0), (view155 a1)]
partial def view155 (x : linking_kind) : Shape :=
  match x with
  | .LK_none  => .node "linking_kind.LK_none" #[]
  | .LK_tentative a0 => .node "linking_kind.LK_tentative" #[(view2 a0)]
  | .LK_normal a0 => .node "linking_kind.LK_normal" #[(view2 a0)]
partial def view156 (x : Fmap sym (CerbLocation.Loc × attributes × ctype × List (Option sym × ctype) × Bool × Bool)) : Shape :=
  match x with
  | .empty  => .node "Fmap.empty" #[]
  | .mk _ a1 => .node "Fmap.mk" #[(view157 a1)]
partial def view157 (x : Pmap sym (CerbLocation.Loc × attributes × ctype × List (Option sym × ctype) × Bool × Bool)) : Shape :=
  match x with
  | .Empty  => .node "Pmap.Empty" #[]
  | .Node a0 a1 a2 a3 a4 => .node "Pmap.Node" #[(view157 a0), (view2 a1), (view158 a2), (view157 a3), (view4 a4)]
partial def view158 (x : CerbLocation.Loc × attributes × ctype × List (Option sym × ctype) × Bool × Bool) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view6 a0), (view159 a1)]
partial def view159 (x : attributes × ctype × List (Option sym × ctype) × Bool × Bool) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view20 a0), (view160 a1)]
partial def view160 (x : ctype × List (Option sym × ctype) × Bool × Bool) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view33 a0), (view161 a1)]
partial def view161 (x : List (Option sym × ctype) × Bool × Bool) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view162 a0), (view164 a1)]
partial def view162 (x : List (Option sym × ctype)) : Shape :=
  .node "List" (x.toArray.map view163)
partial def view163 (x : Option sym × ctype) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view1 a0), (view33 a1)]
partial def view164 (x : Bool × Bool) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view51 a0), (view51 a1)]
partial def view165 (x : Fmap loop_id loop_attribute) : Shape :=
  match x with
  | .empty  => .node "Fmap.empty" #[]
  | .mk _ a1 => .node "Fmap.mk" #[(view166 a1)]
partial def view166 (x : Pmap loop_id loop_attribute) : Shape :=
  match x with
  | .Empty  => .node "Pmap.Empty" #[]
  | .Node a0 a1 a2 a3 a4 => .node "Pmap.Node" #[(view166 a0), (view4 a1), (view167 a2), (view166 a3), (view4 a4)]
partial def view167 (x : loop_attribute) : Shape :=
  match x with
  | .mk a0 a1 a2 a3 => .node "loop_attribute.mk" #[(view4 a0), (view20 a1), (view6 a2), (view6 a3)]
partial def view168 (x : Fmap Nat (List (sym × ctype))) : Shape :=
  match x with
  | .empty  => .node "Fmap.empty" #[]
  | .mk _ a1 => .node "Fmap.mk" #[(view169 a1)]
partial def view169 (x : Pmap Nat (List (sym × ctype))) : Shape :=
  match x with
  | .Empty  => .node "Pmap.Empty" #[]
  | .Node a0 a1 a2 a3 a4 => .node "Pmap.Node" #[(view169 a0), (view4 a1), (view170 a2), (view169 a3), (view4 a4)]
partial def view170 (x : List (sym × ctype)) : Shape :=
  .node "List" (x.toArray.map view171)
partial def view171 (x : sym × ctype) : Shape :=
  match x with
  | .mk a0 a1 => .node "Prod.mk" #[(view2 a0), (view33 a1)]
end
-- END DATATYPE VISITOR
-- 638 model constructors; 172 instantiated types; 75 model + 6 container heads.

def unwrap {α : Type} : Except String α → IO α
  | .ok x => pure x
  | .error e => throw (IO.userError e)

/- Deliberately duplicated specification vocabulary: do not call the printer's
   Comparator.term. Expr equality retains constants and explicit instances; no
   reduction is allowed to identify S, O and L because they compute alike. -/
open Lean Meta Elab Term Command

private def comparatorSpec : String → String
  | "S" => "(@Lem_Map.MapKeyType.mapKeyCompare sym (@Lem_Map.instMapKeyTypeOfSetType sym instSetTypeSym_1))"
  | "O" => "(@Lem_Basic_classes.ordCompare sym instEq0Sym_1 instOrd0Sym_1)"
  | "L" => "symbol_compare"
  | "I" => "implementation_constant_compare"
  | "N" => "(@defaultCompare Nat instOrdNat)"
  | "E" => "(fun (a b : identifier) => match a with | .Identifier _ sa => match b with | .Identifier _ sb => @defaultCompare String String.instOrd sa sb)"
  | _ => "" -- rejected by the parser below; never a substitute comparator

private partial def expandHelpers (e : Expr) : MetaM Expr := do
  let e := e.consumeMData
  if let .const n _ := e then
    if n == `quotedCore || n.isInternal then
      if let .defnInfo d ← getConstInfo n then return ← expandHelpers d.value
  return e

/-- Match elaboration invents module-local names and hygienic binder names.
    Expand only registered matchers, erase metadata and alpha-rename binders.
    Comparator constants, dictionaries, applications and all arguments remain
    syntax: in particular there is no delta reduction of S, O, L or instances. -/
private partial def comparatorForm (e : Expr) : MetaM Expr := do
  match e with
  | .const n levels =>
    if ← isMatcher n then
      let .defnInfo d ← getConstInfo n | throwError "matcher is not a definition: {n}"
      comparatorForm (d.value.instantiateLevelParams d.levelParams levels)
    else pure e
  | .app f a => return .app (← comparatorForm f) (← comparatorForm a)
  | .lam _ t b bi => return .lam `_ (← comparatorForm t) (← comparatorForm b) bi
  | .forallE _ t b bi => return .forallE `_ (← comparatorForm t) (← comparatorForm b) bi
  | .letE _ t v b nd => return .letE `_ (← comparatorForm t) (← comparatorForm v) (← comparatorForm b) nd
  | .mdata _ b => comparatorForm b
  | .proj n i b => return .proj n i (← comparatorForm b)
  | _ => pure e

def checkComparatorSyntax (value : Expr) (mode : String) : TermElabM Unit := do
  unless mode == "tu" || mode == "libc" || mode == "linked" do
    throwError "Core quote comparator check: unknown pipeline mode {mode}"
  let value ← expandHelpers value
  unless value.isAppOfArity ``generic_file.mk 14 do
    throwError "Core quote comparator check: expected generic_file.mk"
  let fields := value.getAppArgs.extract 2 14
  -- The canonical library has .mk L tagDefs/funs/funinfo. Outer .mk wins
  -- even for an empty tree. Libc is last in the list, hence the final left operand
  -- of link_aux. Its enumDefs is .empty: translated .mk S wins there. Shared
  -- stdlib/impl retain S/I; link_extern rebuilds E; populated Nat maps retain N.
  -- Linked vector by field (not comparator reduction): L,S,S,I,L,E,L,N,N.
  let codes := if mode == "libc" || mode == "linked" then #["L", "S", "S", "I", "L", "E", "L", "N", "N"]
    else #["S", "S", "S", "I", "O", "E", "O", "N", "N"]
  for (index, code) in (#[2, 3, 4, 5, 7, 8, 9, 10, 11].zip codes) do
    let some field := fields[index]? | throwError "missing file field {index}"
    let field ← expandHelpers field
    if field.isAppOf ``Fmap.empty then continue
    unless field.isAppOfArity ``Fmap.mk 4 do throwError "field {index}: expected Fmap constructor"
    let some actual := field.getAppArgs[2]? | throwError "field {index}: missing comparator"
    let stx ← match Parser.runParserCategory (← getEnv) `term (comparatorSpec code) with
      | .ok s => pure s
      | .error e => throwError "comparator specification: {e}"
    let expected ← elabTerm stx none
    synthesizeSyntheticMVarsNoPostponing
    let expected ← instantiateMVars expected
    unless (← comparatorForm actual) == (← comparatorForm expected) do
      throwError "Core quote comparator mismatch in field {index} (expected {code}): {actual}"

elab "check_core_comparators " value:ident mode:str : command => liftTermElabM do
  let value ← elabTerm value none
  checkComparatorSyntax value mode.getString

def emptyFile : file core_run_annotation :=
  ⟨none, .Normal_callconv, .empty, .empty, .empty, .empty, [], .empty,
   .empty, .empty, .empty, .empty⟩
def symbol : sym := .Symbol "quote-control" 7 (.SD_Id "original")
def active : sym → sym → LemOrdering :=
  @Lem_Map.MapKeyType.mapKeyCompare sym (@Lem_Map.instMapKeyTypeOfSetType sym instSetTypeSym_1)
def structural : sym → sym → LemOrdering :=
  @Lem_Map.MapKeyType.mapKeyCompare sym (@Lem_Map.instMapKeyTypeOfSetType sym instSetTypeSym)
def floatExpr (x : Float) : generic_pexpr Unit sym :=
  .Pexpr [.Amarker 81] () (.PEval (.Vobject (.OVfloating x)))
def sample (bits : UInt64) : file core_run_annotation :=
  { emptyFile with
    main := some symbol,
    globs := [(symbol, .GlobalDef (.BTy_unit, .Ctype [] .Void0) (.Expr [] (.Epure (floatExpr (Float.ofBits bits)))))],
    enumDefs := .mk active (.Node .Empty symbol .Char0 .Empty 91),
    stdlib := .mk active .Empty }

def listSample (xs : List Nat) : file core_run_annotation :=
  { sample 0 with
    globs := [(symbol, .GlobalDef (.BTy_unit, .Ctype [] .Void0)
      (.Expr [] (.Epure (.Pexpr [] () (.PEctor .Carray
        (xs.map fun n => floatExpr (Float.ofBits n.toUInt64)))))))] }

def control (name : String) : Except String (file core_run_annotation × file core_run_annotation × Bool) := do
  let base := sample 0
  match name with
  | "main" => return (base, {base with main := none}, false)
  | "global" => return (base, sample 0x3ff0000000000000, false)
  | "binding" => return (base, {base with enumDefs := .mk active (.Node .Empty symbol .Bool0 .Empty 91)}, false)
  | "height" => return (base, {base with enumDefs := .mk active (.Node .Empty symbol .Char0 .Empty 92)}, false)
  | "empty-to-mk" => return (emptyFile, {emptyFile with enumDefs := .mk active .Empty}, false)
  | "mk-to-empty" => return ({emptyFile with enumDefs := .mk active .Empty}, emptyFile, false)
  | "zero-sign" => return (base, sample 0x8000000000000000, false)
  | "positive-zero" => return (base, base, true)
  | "negative-zero" => let f := sample 0x8000000000000000; return (f, f, true)
  | "infinity" => let f := sample 0x7ff0000000000000; return (f, f, true)
  | "negative-infinity" => let f := sample 0xfff0000000000000; return (f, f, true)
  | "long-list" => let f := listSample (List.range 257); return (f, f, true)
  | "long-list-order" => return (listSample (List.range 257), listSample ((List.range 257).reverse), false)
  | _ => throw s!"unknown control {name}"

def checkControl (name : String) (quoted : file core_run_annotation) : IO Unit := do
  let (expected, _, agrees) ← unwrap (control name)
  require ((sameShape (view0 expected) (view0 quoted)) == agrees) s!"mutation control {name}"
  if agrees then require (expected == quoted) s!"auxiliary BEq: {name}"
  -- These are specifically invisible to the weak auxiliary relation.
  if ["height", "empty-to-mk", "mk-to-empty", "zero-sign"].contains name then
    require (expected == quoted) s!"weak-relation witness changed: {name}"
  IO.println s!"CORE_QUOTE_CONTROL {name}: expected {if agrees then "agreement" else "rejection"} observed"

def emitControl (name path : String) : IO Unit := do
  let (_, f, _) ← unwrap (control name)
  let source ← match CerbQuote.moduleSource [] (CerbQuote.translatedProvenance f) f with
    | .ok s => pure s
    | .error e => throw (IO.userError e.message)
  IO.FS.writeFile path source

def localControls : IO Unit := do
  let f := sample (Float.ofBits 0x7ff8000000000001).toBits
  match CerbQuote.moduleSource [] (CerbQuote.translatedProvenance f) f with
  | .ok _ => throw (IO.userError "NaN was not refused")
  | .error e => require (e.construct == "globs.Float.NaN") "NaN refusal does not name the construct"
  let alias : sym := .Symbol "quote-control" 7 (.SD_Id "absent-alias")
  let a : Fmap sym Nat := .mk active (.Node .Empty symbol 1 .Empty 1)
  let b : Fmap sym Nat := .mk structural (.Node .Empty symbol 1 .Empty 1)
  require (fmapLookupBy active alias a == some 1 && fmapLookupBy active alias b == none) "absent alias comparator control"
  IO.println "CORE_QUOTE_CONTROL NaN named refusal; absent alias distinguishes explicit instances"

end CoreQuoteTest
