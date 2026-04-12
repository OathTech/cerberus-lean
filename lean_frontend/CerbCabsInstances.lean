/-
  BEq/Ord instances for Cabs types in the mutual block.

  The Cabs mutual block contains ~40 types including simple enums.
  Lem generates sorry BEq/Ord because they're mutual. We provide
  real instances for the types actually compared at runtime.
-/

import Cabs

-- storage_class_specifier: simple enum, compared in determinate_linkage
instance : BEq storage_class_specifier where
  beq a b := match a, b with
    | .SC_typedef, .SC_typedef => true
    | .SC_extern, .SC_extern => true
    | .SC_static, .SC_static => true
    | .SC_Thread_local, .SC_Thread_local => true
    | .SC_auto, .SC_auto => true
    | .SC_register, .SC_register => true
    | _, _ => false

-- cabs_type_qualifier: simple enum
instance : BEq cabs_type_qualifier where
  beq a b := match a, b with
    | .Q_const, .Q_const => true
    | .Q_restrict, .Q_restrict => true
    | .Q_volatile, .Q_volatile => true
    | .Q_Atomic, .Q_Atomic => true
    | _, _ => false

-- function_specifier: simple enum
instance : BEq function_specifier where
  beq a b := match a, b with
    | .FS_inline, .FS_inline => true
    | .FS_Noreturn, .FS_Noreturn => true
    | _, _ => false

-- cabs_unary_operator: simple enum
instance : BEq cabs_unary_operator where
  beq a b := match a, b with
    | .CabsAddress, .CabsAddress => true
    | .CabsIndirection, .CabsIndirection => true
    | .CabsPlus, .CabsPlus => true
    | .CabsMinus, .CabsMinus => true
    | .CabsBnot, .CabsBnot => true
    | .CabsNot, .CabsNot => true
    | _, _ => false

-- cabs_binary_operator: simple enum
instance : BEq cabs_binary_operator where
  beq a b := match a, b with
    | .CabsMul, .CabsMul => true | .CabsDiv, .CabsDiv => true
    | .CabsMod, .CabsMod => true | .CabsAdd, .CabsAdd => true
    | .CabsSub, .CabsSub => true | .CabsShl, .CabsShl => true
    | .CabsShr, .CabsShr => true | .CabsLt, .CabsLt => true
    | .CabsGt, .CabsGt => true | .CabsLe, .CabsLe => true
    | .CabsGe, .CabsGe => true | .CabsEq, .CabsEq => true
    | .CabsNe, .CabsNe => true | .CabsBand, .CabsBand => true
    | .CabsBxor, .CabsBxor => true | .CabsBor, .CabsBor => true
    | .CabsAnd, .CabsAnd => true | .CabsOr, .CabsOr => true
    | _, _ => false

-- cabs_assignment_operator: simple enum
instance : BEq cabs_assignment_operator where
  beq a b := match a, b with
    | .Assign, .Assign => true
    | .Assign_Mul, .Assign_Mul => true | .Assign_Div, .Assign_Div => true
    | .Assign_Mod, .Assign_Mod => true | .Assign_Add, .Assign_Add => true
    | .Assign_Sub, .Assign_Sub => true | .Assign_Shl, .Assign_Shl => true
    | .Assign_Shr, .Assign_Shr => true | .Assign_Band, .Assign_Band => true
    | .Assign_Bxor, .Assign_Bxor => true | .Assign_Bor, .Assign_Bor => true
    | _, _ => false
