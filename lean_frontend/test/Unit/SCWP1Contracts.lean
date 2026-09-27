import Unit.SCWP1Decision
import Unit.SCWP1SourceProofs

/-! Typechecked WP-C statement SCHEMAS, not established correspondence.
    `project` and `corePath` are named S1/S2 obligations, not executable
    callbacks to a model checker. No theorem here assumes SC acceptance to
    prove SC acceptance. The concrete production-source lemmas are in
    SCWP1SourceProofs; their limited domain is stated there.

    `ReferenceSC` names the pinned cmm_csem predicates. Its use in a released
    theorem additionally requires the finite scalar reference port/instance
    audit: executable program-level stubs and concrete-location comparison
    instances are NOT endorsed by these schemas. In particular the upstream
    global `bigthm` is not imported or asserted. -/
namespace SCWP1Contracts
open SCWP1Decision
open Lem_Basic_classes

abbrev Transition := Config × Nat × Config

def history [LemFuel] : List Nat → Config → List Transition
  | [], _ => []
  | i :: rest, c =>
    if experiment_terminal c.base then []
    else let next := SCWP1Decision.step i c
         (c,i,next) :: history rest next

def ScalarActions (X : candidate_execution) : Prop :=
  ∀ a ∈ setToList X.1.actions, match a with
    | .Load _ _ mo _ _ | .Store _ _ mo _ _ => mo = NA ∨ mo = Seq_cst
    | .RMW _ _ mo _ _ _ => mo = Seq_cst
    | _ => False

/-- Initial restricted theorem domain: finite scalar graphs, no lifetime,
    fences or locks, atomic initialization preceding *all* later accesses.
    This is deliberately distinct from the full runtime/MVP target. -/
def ScalarDomain (X : candidate_execution) : Prop :=
  ScalarActions X ∧ atomic_initialisation_before_all X = true ∧
    well_formed_threads X = true

def ReferenceSC (X : candidate_execution) : Prop :=
  apply_tree SC_memory_model.consistent X = true ∧
    X.2.2 = SC_memory_model.relation_calculation X.1 X.2.1

/-- Consistency and absence of undefinedness are separate in the reference.
    Per-execution definedness does not establish program-level definedness,
    which quantifies over all consistent feasible executions. -/
def ReferenceDefinedSC (X : candidate_execution) : Prop :=
  ReferenceSC X ∧ each_empty SC_memory_model.undefined X = true

def ReferenceTotal (X : candidate_execution) : Prop :=
  apply_tree tot_memory_model.consistent X = true ∧
    X.2.2 = tot_memory_model.relation_calculation X.1 X.2.1

/-- Nonempty domain witness: initialization, SC store, SC load, in one thread.
    This illustrates graph hypotheses only; object validity is established by
    the concrete allocation witnesses in the execution probes. -/
def scalarWitness : candidate_execution :=
  let p := CerbMem.PointerValue.PV .Prov_none (.PVconcrete none 4096)
  let v0 := CerbMem.MemValue.MVinteger (.Unsigned .Ichar) (.IV .Prov_none 0)
  let v1 := CerbMem.MemValue.MVinteger (.Unsigned .Ichar) (.IV .Prov_none 1)
  let i := Store 0 0 NA p v0
  let w := Store 1 0 Seq_cst p v1
  let r := Load 2 0 Seq_cst p v1
  let edges := setFromListBy setElemCompare [(i,w),(w,r),(i,r)]
  let pre : pre_execution := { actions := setFromListBy setElemCompare [i,w,r], threads := setFromListBy setElemCompare [0], lk := fun _ => Atomic0, sb := edges, asw := setEmpty, dd := setEmpty }
  let witness := { empty_witness with rf := setFromListBy setElemCompare [(w,r)], mo := setFromListBy setElemCompare [(i,w)], sc := setFromListBy setElemCompare [(w,r)] }
  (pre,witness,SC_memory_model.relation_calculation pre witness)

/-- Source-path feasibility is a Core property, independent of consistency.
    The future relation must replay actual read-dependent control flow and
    source choices. `CoreFeasible := ReferenceSC` would violate this contract. -/
def ExecutionFidelity [LemFuel]
    (initial : Config → Prop)
    (project : List Transition → candidate_execution)
    (corePath : Config → pre_execution → Prop) : Prop :=
  ∀ c schedule, initial c → let X := project (history schedule c)
    ScalarActions X → corePath c X.1

/-- No axiomatic premise appears on the right-to-left runtime direction.
    Access faithfulness, fresh action identities, correct sb/asw/rf and object
    well-formedness must be established by the preceding projection lemmas. -/
def ScalarSoundness [LemFuel]
    (initial : Config → Prop)
    (project : List Transition → candidate_execution)
    (raceFree : List Transition → Prop) : Prop :=
  ∀ c schedule result, initial c →
    (SCWP1Decision.run schedule c).base.experiment_phase0 = .Exp_done result →
    let h := history schedule c
    ScalarDomain (project h) → raceFree h → ReferenceDefinedSC (project h)

/-- Coverage is about choosing concrete operational reads and continuing the
    actual program, not merely topologically sorting a supplied graph. The
    equivalence relation preserves observations and rf; it may rename fresh
    action/thread identities and erase nonobservable administrative steps.
    `corePath` here describes a complete feasible path. `adequate` accounts
    for generated-call fuel, including closures captured at initialization;
    it must be justified from the source path, independently of runtime
    success. Neither low fuel nor an arbitrary malformed initial state is
    silently covered. Racy graphs instead require the first-prefix/UB law. -/
def ScalarCoverage [LemFuel]
    (initial : Config → Prop)
    (project : List Transition → candidate_execution)
    (corePath : Config → pre_execution → Prop)
    (adequate : Config → pre_execution → Prop)
    (equivalent : candidate_execution → candidate_execution → Prop) : Prop :=
  ∀ c X, initial c → corePath c X.1 → adequate c X.1 →
    ScalarDomain X → ReferenceDefinedSC X →
    ∃ schedule result,
      (SCWP1Decision.run schedule c).base.experiment_phase0 = .Exp_done result ∧
      equivalent (project (history schedule c)) X

/-- Earliest-prefix race obligation. Prefix closure/UB lifting are additional
    program-level obligations; an exhausted run is never a defined result. -/
def FirstRace [LemFuel]
    (race : List Transition → Prop) (reported : Config → Prop) : Prop :=
  ∀ c schedule next,
    ¬ race (history schedule c) →
    experiment_terminal (SCWP1Decision.run schedule c).base = false →
    (reported (SCWP1Decision.run (schedule ++ [next]) c) ↔
      race (history (schedule ++ [next]) c))

end SCWP1Contracts
