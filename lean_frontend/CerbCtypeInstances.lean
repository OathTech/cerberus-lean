/-
  Override instances for mutual recursive types (ctype_, ctype).

  The Lem backend generates sorry-based BEq/Ord/SetType/Eq0/Ord0 instances
  for mutual types because it can't derive them automatically. But ctype.lem
  defines an explicit `ctypeEqual` function. We use it to provide real
  instances at higher priority than the sorry-based ones.
-/

import Ctype

-- BEq uses the Lem-generated ctypeEqual function
instance : BEq ctype where
  beq := ctypeEqual

-- For ctype_, use the ord-based comparison (via Ctype constructor wrapping)
instance : BEq ctype_ where
  beq a b := ctypeEqual (Ctype [] a) (Ctype [] b)

-- Ord instances — use a structural comparison via ctypeEqual
-- (not a true ordering, but sufficient to prevent sorry panics)
instance : Ord ctype where
  compare a b := if ctypeEqual a b then .eq else .lt

instance : Ord ctype_ where
  compare a b := if ctypeEqual (Ctype [] a) (Ctype [] b) then .eq else .lt

-- Inhabited instances for the mutual types
instance : Inhabited ctype_ where
  default := Void0

instance : Inhabited ctype where
  default := Ctype [] Void0
