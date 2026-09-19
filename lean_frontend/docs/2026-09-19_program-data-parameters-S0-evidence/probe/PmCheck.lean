/- S0 probe: kernel pins over the MULTI-MODULE pair (readers declared in
   Pm_readers, lifted defs in Pm_use). -/
import Pm_use
open Lem_Basic_classes Lem_Pervasives Lem_Map

def t1 : Fmap Nat Nat := fmapAddBy defaultCompare 1 7 fmapEmpty
def e1 : Fmap Nat Nat := fmapAddBy defaultCompare 1 3 (fmapAddBy defaultCompare 2 4 fmapEmpty)
def d1 : String := "ab"

example : String → Fmap Nat Nat → Fmap Nat Nat → Nat → Nat := uses_all
example : String → Fmap Nat Nat → Fmap Nat Nat → Nat → Nat → Nat × Nat := draw_all
example : uses_all d1 e1 t1 5 = 2070122 := by decide
example : draw_all d1 e1 t1 10 5 = (2070132, 11) := by decide

#print axioms uses_all
#print axioms draw_all
