import Mem

/-! Structural byte comparison for generated observation records. Mirrors
OCaml's AbsByte record field order and polymorphic provenance constructor rank.
SC scheduling and event identity do not use payload comparison. -/
namespace CerbSCByteInstances
open CerbMem
private def provenanceRank : Provenance → Nat
  | .Prov_none => 0
  | .Prov_device => 1
  | .Prov_some _ => 2
  | .Prov_symbolic _ => 3

def compareProvenance : Provenance → Provenance → Ordering
  | .Prov_some x, .Prov_some y => compare x y
  | .Prov_symbolic x, .Prov_symbolic y => compare x y
  | x, y => compare (provenanceRank x) (provenanceRank y)

instance : Ord AbsByte where
  compare a b := match compareProvenance a.prov b.prov with
    | .lt => .lt
    | .gt => .gt
    | .eq => match compare a.copyOffset b.copyOffset with
      | .lt => .lt
      | .gt => .gt
      | .eq => compare a.value b.value

end CerbSCByteInstances
