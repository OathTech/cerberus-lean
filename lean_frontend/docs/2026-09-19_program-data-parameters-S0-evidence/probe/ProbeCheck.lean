/- S0 probe: kernel pins over the generated Probe_readers (three readers +
   consumer + supply). Values chosen so the two SAME-TYPED maps are
   distinguishable (tagDefs by entry count, enum_defs by value sum in
   ProbeImpl.consume): a swap of the two map positions changes the value. -/
import Probe_readers
open Lem_Basic_classes Lem_Pervasives Lem_Map

def t1 : Fmap Nat Nat := fmapAddBy defaultCompare 1 7 fmapEmpty                              -- {1 ↦ 7}: count 1
def e1 : Fmap Nat Nat := fmapAddBy defaultCompare 1 3 (fmapAddBy defaultCompare 2 4 fmapEmpty) -- {1 ↦ 3, 2 ↦ 4}: sum 7, count 2
def d1 : String := "ab"                                                                        -- length 2

/- signature pins: the binder order is (digest, enum_defs, tagDefs) then supply then own args;
   [Inhabited] precedes the readers -/
example : String → Fmap Nat Nat → Fmap Nat Nat → Nat → Nat := uses_one
example : String → Fmap Nat Nat → Fmap Nat Nat → Nat → Nat := uses_three
example : String → Fmap Nat Nat → Fmap Nat Nat → List Nat → List Nat := maps_consume
example : String → Fmap Nat Nat → Fmap Nat Nat → Nat → Nat → Nat × Nat := draw_and_read
example : {a : Type} → [Inhabited a] → String → Fmap Nat Nat → Fmap Nat Nat → Nat → List a → a × Nat := @all_binders

/- value pins (kernel) -/
example : uses_one d1 e1 t1 5 = 12 := by decide
example : uses_two d1 e1 t1 5 = 14 := by decide
example : ProbeImpl.consume d1 e1 t1 5 = 2070105 := by decide
example : uses_three d1 e1 t1 5 = 2070122 := by decide
example : maps_consume d1 e1 t1 [1, 2] = [2070101, 2070102] := by decide
example : draw_and_read d1 e1 t1 10 5 = (2070132, 11) := by decide
example : all_binders d1 e1 t1 10 [42] = (42, 11) := by decide

/- the swap witness: the two same-typed map positions are NOT interchangeable -/
example : ProbeImpl.consume d1 t1 e1 5 = 2070205 := by decide
example : ProbeImpl.consume d1 e1 t1 5 ≠ ProbeImpl.consume d1 t1 e1 5 := by decide

#print axioms uses_three
#print axioms maps_consume
#print axioms draw_and_read
#print axioms all_binders
