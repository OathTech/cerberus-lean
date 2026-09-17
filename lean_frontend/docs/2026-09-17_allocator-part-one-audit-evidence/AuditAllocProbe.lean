import CerbMemAllocatorProofs
/-! AUDITOR probe — the SAME state table as .tmp/audit/ocaml/alloc_arith.ml, evaluated on the
    ACTUAL `CerbMem.allocator` through `CerbMem.allocatorStep` (the theorem's own observer), plus
    `#print axioms` for both theorems and the statement as elaborated. Output format shared with
    the OCaml probe so the two `## NEW` blocks diff line by line. -/
open CerbMem

def show1 (last sz align : Int) : String :=
  let st : MemState := { lastAddress := last }
  let out := match allocatorStep sz align st with
    | (NDactive (_, a), st') => s!"active addr={a} cursor'={st'.lastAddress}"
    | (NDkilled (Other (MerrOther "Concrete.allocator: failed (out of memory)")), st') =>
        s!"killed(out of memory) cursor'={st'.lastAddress}"
    | (NDkilled (Other (MerrOther msg)), st') => s!"killed[MerrOther {msg}] cursor'={st'.lastAddress}"
    | (NDkilled _, _) => "killed[other kind]"
    | (_, _) => "other outcome"
  s!"last={last} sz={sz} align={align}: {out}"

def p70 : Int := 2^70
def p80 : Int := 2^80
def top : Int := 281474976710655
def states : List (Int × Int × Int) := [
  (3,4,4), (7,8,8), (2,4,4), (8,4,4),
  (8,-4,4), (8,-1,1), (0,-5,4), (-3,-8,4),
  (8,4,1), (4,4,1), (5,4,1), (3,4,1),
  (8,0,4), (0,0,4), (3,0,4), (16,0,16), (1,0,1),
  (4,4,4), (16,16,8), (1,1,1),
  (7,4,4), (11,4,8), (15,8,8),
  (100,4,p70), (p80,4,p70), (p70+96,32,p70),
  (8,4,-4), (7,4,-4), (3,4,-4), (9,4,-4), (-5,4,-4),
  (-5,4,4), (-1,0,4),
  (8,4,0), (3,4,0), (4,4,0),
  (top, top+1, 16), (top, top+7, 16), (top, top+8, 16), (top, top, 16), (top, 16, 16), (top, top+1, 1) ]

#eval IO.println s!"Int emod/ediv: (-1)%4={(-1:Int)%4} (-1)/4={(-1:Int)/4}; 7%(-4)={(7:Int)%(-4)} 7/(-4)={(7:Int)/(-4)}; (-7)%(-4)={(-7:Int)%(-4)} (-7)/(-4)={(-7:Int)/(-4)}; (-7)%4={(-7:Int)%4} (-7)/4={(-7:Int)/4}"
#eval IO.println "## NEW (fork after remedy 1)"
#eval do for (l, s, a) in states do IO.println (show1 l s a)
#eval IO.println "## theorem statements as elaborated"
#check @CerbMem.allocator_active_sound
#check @CerbMem.allocator_below_request_kills
#check @CerbMem.allocatorStep
#print axioms CerbMem.allocator_active_sound
#print axioms CerbMem.allocator_below_request_kills
#print axioms CerbMem.allocatorStep
#print axioms CerbMem.allocator
-- the Address/StorageInstanceId abbrevs are Int definitionally (no coercion function in the statement)
example (st : MemState) : (st.lastAddress : Int) = st.lastAddress := rfl
example : CerbMem.Address = Int := rfl
example : CerbMem.StorageInstanceId = Int := rfl
-- Int `%` IS Int.emod and `/` IS Int.ediv on this toolchain (the mirror's claim)
example (a b : Int) : a % b = Int.emod a b := rfl
example (a b : Int) : a / b = Int.ediv a b := rfl
#eval Lean.versionString
