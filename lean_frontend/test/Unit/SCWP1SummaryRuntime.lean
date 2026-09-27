import Unit.SCWP1Summary

/-! Materialized named-root adapter used by WP1 measurements. Names denote
    current holders (source frontiers, publications and access summaries), not
    historical event IDs. All matrix cells and all root references are counted.
    Missing parents/queries are errors. -/
namespace SCWP1Summary

structure Runtime where
  n : Nat
  names : Vector String n
  matrix : Matrix n

def empty : Runtime := ⟨0, #v[], #v[]⟩

def index (s : Runtime) (name : String) : IO (Fin s.n) := do
  let some i := s.names.toList.findIdx? (fun x => x == name)
    | throw (IO.userError ("unknown endpoint " ++ name))
  if h : i < s.n then return ⟨i,h⟩ else throw (IO.userError "invalid endpoint index")

def precedes (s : Runtime) (a b : String) : IO Bool := do
  let i ← index s a
  let j ← index s b
  return lookup s.matrix i j

def emit (s : Runtime) (name : String) (parents : List String) : IO Runtime := do
  let ps ← parents.mapM (index s)
  let m := extend s.matrix ps
  if s.names.toList.contains name then
    let keep := Vector.ofFn fun i : Fin s.n =>
      if s.names.get i == name then Fin.last s.n else i.castSucc
    return ⟨s.n,s.names,project m keep⟩
  else return ⟨s.n+1, s.names.push name, m⟩

def copy (s : Runtime) (dst src : String) : IO Runtime := do
  let p ← index s src
  if s.names.toList.contains dst then
    let keep := Vector.ofFn fun i : Fin s.n => if s.names.get i == dst then p else i
    return ⟨s.n,s.names,project s.matrix keep⟩
  else
    let keep := Vector.ofFn fun i : Fin (s.n+1) =>
      if h : i.val < s.n then (⟨i.val,h⟩ : Fin s.n) else p
    return ⟨s.n+1,s.names.push dst,project s.matrix keep⟩

def discard (s : Runtime) (names : List String) : Runtime :=
  let kept := (List.finRange s.n).filter (fun i => !(names.contains (s.names.get i)))
  let keep := Vector.ofFn (fun i : Fin kept.length => kept[i])
  ⟨kept.length, Vector.ofFn (fun i => s.names.get (keep.get i)), project s.matrix keep⟩

/-- A direct count, with no hidden closure or predecessor list in Runtime. -/
def counts (s : Runtime) : Nat × Nat × Nat :=
  (s.n, s.matrix.toList.foldl (fun n row => n + row.toList.length) 0, s.names.toList.length)

end SCWP1Summary
