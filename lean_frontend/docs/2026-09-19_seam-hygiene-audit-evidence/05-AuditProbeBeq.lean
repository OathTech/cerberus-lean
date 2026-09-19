import CerbMem

/-! AUDITOR probe (item 5): does the structural `CerbMem.beqMemValue` (H3) agree with the RETIRED
    `beqMemValueImpl` (git show 0457732e1:lean_frontend/CerbMem.lean:230-243 — body copied VERBATIM
    below as a `partial def`, the only change being the modifier so it evaluates here)? Checked on ALL
    ORDERED PAIRS of an adversarial value set (both directions + reflexive pairs by construction). -/

namespace AuditBeq
open CerbMem

-- the retired impl, body verbatim (only `private unsafe def` -> `partial def` and the self-name)
partial def beqOld : MemValue → MemValue → Bool
  | .MVunspecified t1, .MVunspecified t2 => t1 == t2
  | .MVinteger ity1 v1, .MVinteger ity2 v2 => ity1 == ity2 && v1 == v2
  | .MVfloating fty1 v1, .MVfloating fty2 v2 => fty1 == fty2 && v1 == v2
  | .MVpointer t1 v1, .MVpointer t2 v2 => t1 == t2 && v1 == v2
  | .MVarray e1, .MVarray e2 =>
    e1.length == e2.length && (e1.zip e2).all (fun (a, b) => beqOld a b)
  | .MVstruct t1 ms1, .MVstruct t2 ms2 =>
    t1 == t2 && ms1.length == ms2.length &&
    (ms1.zip ms2).all (fun ((i1, c1, v1), (i2, c2, v2)) =>
      i1 == i2 && c1 == c2 && beqOld v1 v2)
  | .MVunion t1 m1 v1, .MVunion t2 m2 v2 =>
    t1 == t2 && m1 == m2 && beqOld v1 v2
  | _, _ => false

-- building blocks
def c0 : ctype := default
def c1 : ctype := Ctype [] (.Basic (.Integer .Bool0))
def c2 : ctype := Ctype [] (.Basic (.Integer (.Signed .Int_)))
def s0 : sym := Symbol "d" 0 .SD_None
def s1 : sym := Symbol "d" 1 .SD_None
def idA : identifier := .Identifier .unknown "a"
def idB : identifier := .Identifier .unknown "b"
def i1 : MemValue := .MVinteger (.Signed .Int_) (.IV .Prov_none 1)
def i1L : MemValue := .MVinteger (.Signed .Long) (.IV .Prov_none 1)   -- same value, different ity
def i2 : MemValue := .MVinteger (.Signed .Int_) (.IV .Prov_none 2)
def i1p : MemValue := .MVinteger (.Signed .Int_) (.IV (.Prov_some 3) 1)
def u0 : MemValue := .MVunspecified c0
def u2 : MemValue := .MVunspecified c2
def f1 : MemValue := .MVfloating default 1.0
def fnan : MemValue := .MVfloating default (0.0 / 0.0)
def p8 : MemValue := .MVpointer c0 (.PV .Prov_none (.PVconcrete none 8))
def p8p : MemValue := .MVpointer c0 (.PV (.Prov_some 1) (.PVconcrete none 8))   -- provenance only
def pnull : MemValue := .MVpointer c0 (.PV .Prov_none (.PVnull c0))
def aE : MemValue := .MVarray []
def aEE : MemValue := .MVarray [.MVarray []]
def a12 : MemValue := .MVarray [i1, i2]
def a1 : MemValue := .MVarray [i1]
def a21 : MemValue := .MVarray [i2, i1]
def nA : MemValue := .MVarray [.MVarray [i1, i2], .MVarray [i1]]       -- nested, inner lengths 2,1
def nB : MemValue := .MVarray [.MVarray [i1, i2], .MVarray [i1, i2]]   -- nested, inner lengths 2,2
def nC : MemValue := .MVarray [.MVarray [i1, i2], .MVarray [i1], .MVarray []]  -- outer length 3
def aNaN : MemValue := .MVarray [fnan]
def st1 : MemValue := .MVstruct s0 [(idA, c0, i1)]
def st1c : MemValue := .MVstruct s0 [(idA, c2, i1)]                    -- member ctype only
def st1i : MemValue := .MVstruct s0 [(idB, c0, i1)]                    -- member name only
def st1t : MemValue := .MVstruct s1 [(idA, c0, i1)]                    -- tag only
def st2 : MemValue := .MVstruct s0 [(idA, c0, i1), (idB, c0, i2)]
def st2r : MemValue := .MVstruct s0 [(idB, c0, i2), (idA, c0, i1)]     -- members reordered
def stE : MemValue := .MVstruct s0 []
def un1 : MemValue := .MVunion s0 idA i1
def un1b : MemValue := .MVunion s0 idB i1                              -- member name only
def un1t : MemValue := .MVunion s1 idA i1                              -- tag only
def un2 : MemValue := .MVunion s0 idA i2
def deep1 : MemValue := .MVstruct s0 [(idA, c0, .MVarray [.MVunion s1 idB (.MVstruct s1 [(idA, c1, a12)])])]
def deep2 : MemValue := .MVstruct s0 [(idA, c0, .MVarray [.MVunion s1 idB (.MVstruct s1 [(idA, c1, a21)])])]
def deep1' : MemValue := .MVstruct s0 [(idA, c0, .MVarray [.MVunion s1 idB (.MVstruct s1 [(idA, c1, .MVarray [i1, i2])])])]

def vals : List (String × MemValue) :=
  [("i1", i1), ("i1L", i1L), ("i2", i2), ("i1p", i1p), ("u0", u0), ("u2", u2), ("f1", f1), ("fnan", fnan),
   ("p8", p8), ("p8p", p8p), ("pnull", pnull), ("aE", aE), ("aEE", aEE), ("a12", a12), ("a1", a1), ("a21", a21),
   ("nA", nA), ("nB", nB), ("nC", nC), ("aNaN", aNaN), ("st1", st1), ("st1c", st1c), ("st1i", st1i), ("st1t", st1t),
   ("st2", st2), ("st2r", st2r), ("stE", stE), ("un1", un1), ("un1b", un1b), ("un1t", un1t), ("un2", un2),
   ("deep1", deep1), ("deep2", deep2), ("deep1'", deep1')]

def named : List (String × String) :=
  [("nA","nB"), ("nA","nC"), ("aE","aEE"), ("st1","st1c"), ("st1","st1i"), ("st1","st1t"), ("st2","st2r"),
   ("un1","un1b"), ("un1","un1t"), ("u0","u2"), ("p8","p8p"), ("i1","i1L"), ("fnan","fnan"), ("aNaN","aNaN"),
   ("deep1","deep1'"), ("deep1","deep2"), ("aE","stE")]

def main : IO UInt32 := do
  let mut disagreements : List String := []
  let mut n := 0
  let mut trues := 0
  for (nx, x) in vals do
    for (ny, y) in vals do
      n := n + 1
      let o := beqOld x y
      let w := (x == y)          -- the HEAD instance: CerbMem.beqMemValue
      if w then trues := trues + 1
      if o != w then disagreements := disagreements ++ [s!"{nx},{ny}: old={o} new={w}"]
  IO.println s!"ordered pairs checked: {n} (values: {vals.length}); new==true on {trues}; DISAGREEMENTS: {disagreements.length}"
  for d in disagreements do IO.println s!"  DISAGREE {d}"
  IO.println "named adversarial pairs (old, new), both directions:"
  for (a, b) in named do
    match vals.lookup a, vals.lookup b with
    | some x, some y => IO.println s!"  {a},{b}: ({beqOld x y}, {x == y})   {b},{a}: ({beqOld y x}, {y == x})"
    | _, _ => IO.println s!"  {a},{b}: MISSING"
  -- reflexivity except NaN-carrying values
  let refl := vals.filter (fun (_, x) => !(x == x))
  IO.println s!"non-reflexive under the new instance: {refl.map (·.1)} (expected exactly the NaN carriers: fnan, aNaN)"
  return (if disagreements.isEmpty then 0 else 1)

#eval main
end AuditBeq
