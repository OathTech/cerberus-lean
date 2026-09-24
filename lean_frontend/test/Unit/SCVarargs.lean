import Sc_varargs
import LemLibTheorems

namespace SCUnit.SCVarargs
open Lem_Basic_classes

private def edges (xs : List (Nat × Nat)) : Pset (Nat × Nat) :=
  setFromListBy setElemCompare xs

private def event (id thread : Nat) (cursor : Int) (operation : varargs_observation) :
    sc_varargs_event := ⟨id, id - 1, thread, cursor, operation⟩

private def observed (e : sc_varargs_event) : sc_effect :=
  ⟨e.sc_va_occurrence,
    ⟨e.sc_va_request,e.sc_va_thread,
      ⟨edges [], setFromListBy setElemCompare [], setFromListBy setElemCompare []⟩,
      SC_runtime "metadata control", []⟩,
    Observe_varargs e.sc_va_operation e.sc_va_identity⟩

private def checks : List (String × Bool) := Id.run do
  let kinds := [Varargs_create, Varargs_read, Varargs_advance, Varargs_delete]
  let a := event 2 0 0 Varargs_advance
  let b := event 4 1 0 Varargs_read
  let allocation : CerbMem.MemoryObservation := Observe_allocation
    (.PV .Prov_none (.PVnull (.Ctype [] .Void0))) 1 100 4 none none []
  let unrelated := { observed a with sc_effect_observation := allocation }
  let history := [observed b,unrelated,observed a,observed a]
  return [
    ("all sixteen operation combinations", kinds.all fun x => kinds.all fun y =>
      sc_varargs_conflict (event 2 0 0 x) (event 4 1 0 y) ==
        (x != Varargs_read || y != Varargs_read)),
    ("distinct metadata identities do not conflict", kinds.all fun x => kinds.all fun y =>
      !(sc_varargs_conflict (event 2 0 0 x) (event 4 1 1 y))),
    ("forward source order suppresses pair", (sc_varargs_unordered_pair (edges [(2,4)]) a b).isNone),
    ("reverse source order suppresses pair", (sc_varargs_unordered_pair (edges [(4,2)]) a b).isNone),
    ("occurrence ordering is only deduplication", (sc_varargs_unordered_pair (edges []) b a).isNone),
    ("unordered interthread witness", match sc_varargs_unordered_pair (edges []) a b with
      | some w => w.sc_va_conflict_kind == SC_va_interthread &&
          w.sc_va_conflict_left == a && w.sc_va_conflict_right == b
      | none => false),
    ("unordered same-thread witness", match
        sc_varargs_unordered_pair (edges []) a { b with sc_va_thread := 0 } with
      | some w => w.sc_va_conflict_kind == SC_va_unsequenced
      | none => false),
    ("extraction preserves order multiplicity and metadata while filtering object effects",
      sc_varargs_events history == [b,a,a]),
    ("pair collection retains repeated occurrences and ignores unrelated object effects",
      (sc_varargs_unordered_pairs (edges []) history).length == 2 &&
      sc_varargs_unordered_pairs (edges []) [observed b,unrelated,observed a] ==
        sc_varargs_unordered_pairs (edges []) [observed b,observed a]),
    ("an independent later cursor leaves prior witnesses intact",
      sc_varargs_unordered_pairs (edges []) [observed (event 6 1 1 Varargs_advance),observed b,observed a] ==
        sc_varargs_unordered_pairs (edges []) [observed b,observed a])]

def runTests : IO Unit := do
  for (label,good) in checks do
    IO.println s!"{label}: {good}"
    unless good do throw (IO.userError label)

end SCUnit.SCVarargs
