/- S0 probe: the one-reader seed control — seed_entry1 is NOT lifted; via_seed1 passes {1 ↦ 5}. -/
import Probe_seed1
open Lem_Basic_classes Lem_Pervasives Lem_Map

example : Fmap Nat Nat → Nat → Nat := seed_entry1
example : Nat → Nat := via_seed1
example : via_seed1 5 = 220 := by decide

#print axioms via_seed1
