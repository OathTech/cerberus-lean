import CerbMem
open CerbMem
-- WITNESS of the OLD `BEq MemValue` (the `unsafe beqMemValueImpl` behind the opaque
-- `beqMemValueSafe`, reached through `==`) on the values the H3 agreement test pins.
def c0 : ctype := default
def c1 : ctype := Ctype [] (.Basic (.Integer .Bool0))
def i1 : MemValue := .MVinteger default (.IV .Prov_none 1)
def i2 : MemValue := .MVinteger default (.IV .Prov_none 2)
def i1p : MemValue := .MVinteger default (.IV (.Prov_some 3) 1)
def u0 : MemValue := .MVunspecified c0
def u1 : MemValue := .MVunspecified c1
def f1 : MemValue := .MVfloating default 1.0
def fnan : MemValue := .MVfloating default (0.0 / 0.0)
def p0 : MemValue := .MVpointer c0 (.PV .Prov_none (.PVnull c0))
def p1 : MemValue := .MVpointer c0 (.PV .Prov_none (.PVconcrete none 8))
def a0 : MemValue := .MVarray []
def a1 : MemValue := .MVarray [i1, i2]
def a1' : MemValue := .MVarray [i1, i2]
def a2 : MemValue := .MVarray [i1]
def a3 : MemValue := .MVarray [i2, i1]
def s1 : MemValue := .MVstruct default [(default, c0, i1)]
def s1' : MemValue := .MVstruct default [(default, c0, i1)]
def s2 : MemValue := .MVstruct default [(default, c0, i2)]
def s3 : MemValue := .MVstruct default []
def s4 : MemValue := .MVstruct default [(default, c1, i1)]
def n1 : MemValue := .MVunion default default i1
def n2 : MemValue := .MVunion default default i2
def pairs : List (String × MemValue × MemValue) :=
  [("u0,u0", u0, u0), ("u0,u1", u0, u1), ("i1,i1", i1, i1), ("i1,i2", i1, i2), ("i1,i1p", i1, i1p),
   ("f1,f1", f1, f1), ("fnan,fnan", fnan, fnan), ("p0,p0", p0, p0), ("p0,p1", p0, p1),
   ("a0,a0", a0, a0), ("a1,a1'", a1, a1'), ("a1,a2", a1, a2), ("a1,a3", a1, a3),
   ("s1,s1'", s1, s1'), ("s1,s2", s1, s2), ("s1,s3", s1, s3), ("s1,s4", s1, s4),
   ("n1,n1", n1, n1), ("n1,n2", n1, n2), ("u0,i1", u0, i1), ("a1,s1", a1, s1),
   ("[a1],[a1']", .MVarray [a1], .MVarray [a1']), ("[a1],[a2]", .MVarray [a1], .MVarray [a2])]
#eval pairs.map (fun (n, x, y) => (n, x == y))
