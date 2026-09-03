/-
  FuelExemplar — the FUEL arc's in-repo exemplar over the SHIPPED
  fuel-parametric pipeline `CerbND.drive_lemFuel` (design note
  docs/2026-09-02_fuel-arc-design.md §1.4/§6; consumer shape = the
  refined-cerberus review 2026-09-02 §6).

  The program: a synthetic one-procedure Core file — `main` returning the
  constant `Specified(42)`, no globals, no externs, no tags — built
  directly as a Lean term (the consumer's own `prodFile` shape,
  refined-cerberus ProdEntry.lean:88-114), NOT parsed from text: kernel
  evaluation of the Parsec text parser would be an uninformative cost in
  the statement; the driver pipeline under judgment is the same.

  WHAT IS SHIPPED (kernel-checked, axiom cone = the standard three,
  probed by scripts/check_theorem_axioms.sh):

  * `exemplar_certified_shipped_zero` — the consumer's acceptance shape at
    fuel 0: the run is the distinguished kill (left disjunct), by
    evaluation of the fuel-INDEPENDENT setup phase (`driver_globals` with
    no globals, main lookup, errno allocation on the cold memory — all at
    the fixed budgets) and `driver2_lemFuel_zero` — closed by `rfl` in
    well under a second (at the seed `sup = 0`; with `sup` symbolic the
    setup does not evaluate to a singleton by unification — a
    measured fact, recorded, not investigated further in this slice).
  * `exemplar_certified_shipped_one` — the same shape at fuel 1: the run is
    the single `Active` execution with value `Specified(42)` (right
    disjunct). One driver round + `finalize`. The round reads the opaque
    `CerbGlobal.current_execution_mode ()` (the scheduler-mode switch),
    so the proof exposes that read (`driver2_lemFuel.eq_2`), CASES on it,
    and closes every branch by `decide +kernel` — kernel evaluation of
    the closed instance (`exemplar_run_one_kernel`, ~0.1 s), lifted to
    the consumer shape by `resultOk_sound`. `decide +kernel` is
    kernel-checked (`of_decide_eq_true (Eq.refl true)`; no `ofReduce*`
    axiom, no compiled-code decision — the D14 ban does not touch it).

  WHAT IS NOT SHIPPED — STOP-AND-REPORT (FUEL arc implementation slice,
  2026-09-03; for the second design review):

    theorem exemplar_certified_shipped (fuel : Nat) :
      ∀ o ∈ CerbND.runND (CerbND.drive_lemFuel fuel fmapEmpty false exemplarFile ["cmdname"]) dst₀,
        (∃ st, o.1 = Killed st CerbND.fuelExhaustedKill) ∨ (∃ r, o.1 = Active r ∧ post r o.2.2)

  The ∀-fuel statement IS provable with the shipped lemmas and canon
  tactics — `cases fuel`; the zero case above; the `n+1` case by the
  same unfold/`eq_2`/cases route with the fuel SYMBOLIC (`n+1`, the
  fuel-erasure `rfl` pattern: the completed round never forces the
  residual `driver2_lemFuel n`) — and the proof CLOSED in a probe with
  the heartbeat limit lifted (25 s wall, `set_option maxHeartbeats 0`),
  but it does NOT close at the default 200000 heartbeats, nor at
  400000, nor at 800000 (measured 2026-09-03, scratch probes, this
  file's definitions verbatim). The cost is the ELABORATOR's (Meta-level)
  `whnf` evaluation of one driver round on the open term — the kernel
  evaluates the same round in ~0.1 s (`exemplar_run_one_kernel` below),
  but `decide +kernel` accepts only CLOSED propositions, and `∀ fuel` is
  not decidable. Heartbeat bumps are a registered-defect shape and were
  NOT applied. Candidate remedies, each needing a ruling: (a) a
  kernel-only reflexivity elaboration (the `decide +kernel` mechanism —
  build the `Eq.refl` declaration and let the kernel check it — applied
  to an open equation such as `∀ n, run (n+1) = run 1`; ~10 lines of
  meta code, a NEW proof-method mechanism in the tree, kernel-trusted);
  (b) a per-theorem heartbeat budget registered as a defect with a named
  remover; (c) symbolic round lemmas (the consumer's DriverCollapse
  approach, ~1.6 kLOC on their side). Until ruled, the two instances
  above are the exemplar.

  Compile-time proofs; `main` reports success at runtime.
-/

import CerbND
import Core
import Core_run_aux
import Driver

open Lem_Num Lem_Pervasives Lem_List Lem_Set Lem_Map Lem_Maybe Lem_Function
  Lem_Show Lem_Show_extra Lem_Bool Lem_Basic_classes Lem_Map_extra
  Lem_String_extra Lem_Num_extra Lem_Set_helpers Lem_Either Lem_Assert_extra
  Lem_Set_extra Lem_List_extra Lem_Relation Lem_Tuple Lem_String Lem_Word Mem

set_option autoImplicit false

namespace FuelExemplar

/-! ## The program -/

/-- `main`'s symbol: digest "", id 0, no description (the consumer's
    `mainSym`). -/
def mainSym : sym := Symbol "" 0 SD_None

/-- The constant the program returns: `Specified(42)` as a Core value. -/
def fortyTwo : value := Vloaded (LVspecified (OVinteger (CerbMem.integerIval 42)))

/-- `main`'s body: `pure(Specified(42))`. -/
def mainBody : generic_expr core_run_annotation Unit sym :=
  Expr [] (Epure (Pexpr [] () (PEval fortyTwo)))

/-- `main`'s declaration: a parameterless `Proc` (Core.lean `Proc loc
    marker ret params body`). -/
def mainDecl : generic_fun_map_decl Unit core_run_annotation :=
  Proc CerbLocation.unknown none BTy_unit [] mainBody

/-- The synthetic one-procedure Core file: `main` only, no globals, no
    externs, no tags. Only `main`, `funs` and `globs` are read on the
    production path; every other field is inert context. -/
def exemplarFile : file core_run_annotation :=
  { main := some mainSym,
    calling_convention0 := default,
    tagDefs := default,
    stdlib := fmapEmpty,
    impl0 := fmapEmpty,
    globs := [],
    funs := fmapAddBy (fun (s1 s2 : sym) => ordCompare s1 s2) mainSym mainDecl fmapEmpty,
    extern := fmapEmpty,
    funinfo := fmapEmpty,
    loop_attributes1 := default,
    visible_objects_env0 := default }

/-- The shipped cold start: `(initial_driver_state sup file fs).1` with the
    production filesystem state (Main.lean's `drSt`). -/
def dst₀ (sup : Nat) : driver_state :=
  (initial_driver_state sup exemplarFile CerbFS.fs_initial_state).1

/-- The postcondition: the delivered Core value is `Specified(42)`. -/
def post (r : driver_result) (_ : driver_state) : Prop :=
  r.dres_core_value = fortyTwo

/-! ## Fuel 0: the distinguished kill (consumer shape, left disjunct) -/

/-- The consumer's acceptance shape at fuel 0. The setup phase is
    fuel-independent and evaluates on the concrete program;
    `driver2_lemFuel 0` is the kill (`CerbND.driver2_lemFuel_zero`) and
    `nd_bind`'s `NDkilled` arm propagates it. -/
theorem exemplar_certified_shipped_zero :
    ∀ o ∈ CerbND.runND (CerbND.drive_lemFuel 0 fmapEmpty false exemplarFile ["cmdname"]) (dst₀ 0),
      (∃ st, o.1 = Killed st CerbND.fuelExhaustedKill) ∨ (∃ r, o.1 = Active r ∧ post r o.2.2) := by
  intro o ho
  have h := List.mem_singleton.mp ho
  subst h
  exact Or.inl ⟨_, rfl⟩

/-! ## Fuel 1: the Active execution (consumer shape, right disjunct) -/

/-- Decidable reading of a Core value: `Specified(42)` — provenance-free
    integer 42, the exact shape of `fortyTwo`. Structural (constructor
    match + `Int.decEq`), so the kernel can evaluate it; no `BEq` instance
    of any opaque-carrying type is involved. -/
def valueOk : value → Bool
  | Vloaded (LVspecified (OVinteger (CerbMem.IntegerValue.IV CerbMem.Provenance.Prov_none n))) =>
    decide (n = 42)
  | _ => false

theorem valueOk_sound (v : value) (h : valueOk v = true) : v = fortyTwo := by
  unfold valueOk at h
  split at h
  · rename_i n
    have hn : n = 42 := of_decide_eq_true h
    subst hn
    rfl
  · cases h

/-- Decidable reading of a run's outcome list: exactly one execution, no
    trace strings, `Active` with `valueOk`. -/
def resultOk (l : List (nd_status driver_result driver_error driver_state × List String × driver_state)) :
    Bool :=
  match l with
  | [(Active r, [], _)] => valueOk r.dres_core_value
  | _ => false

/-- `resultOk` is sound for the consumer's right disjunct. -/
theorem resultOk_sound
    (l : List (nd_status driver_result driver_error driver_state × List String × driver_state))
    (h : resultOk l = true) :
    ∀ o ∈ l, ∃ r, o.1 = Active r ∧ post r o.2.2 := by
  intro o ho
  unfold resultOk at h
  split at h
  · rename_i r st
    have hmem : o = (Active r, [], st) := List.mem_singleton.mp ho
    subst hmem
    exact ⟨r, rfl, valueOk_sound _ h⟩
  · cases h

/-- The closed fuel-1 instance, KERNEL-evaluated: expose the scheduler-mode
    read, cases on it, `decide +kernel` per branch (every branch takes the
    same singleton-pick path; ~0.1 s in the kernel). -/
theorem exemplar_run_one_kernel :
    resultOk (CerbND.runND (CerbND.drive_lemFuel 1 fmapEmpty false exemplarFile ["cmdname"]) (dst₀ 0)) = true := by
  unfold CerbND.drive_lemFuel
  rw [driver2_lemFuel.eq_2]
  generalize hm : CerbGlobal.current_execution_mode () = m
  cases m with
  | none => decide +kernel
  | some md => cases md <;> decide +kernel

/-- The consumer's acceptance shape at fuel 1 (right disjunct). -/
theorem exemplar_certified_shipped_one :
    ∀ o ∈ CerbND.runND (CerbND.drive_lemFuel 1 fmapEmpty false exemplarFile ["cmdname"]) (dst₀ 0),
      (∃ st, o.1 = Killed st CerbND.fuelExhaustedKill) ∨ (∃ r, o.1 = Active r ∧ post r o.2.2) :=
  fun o ho => Or.inr (resultOk_sound _ exemplar_run_one_kernel o ho)

end FuelExemplar

def main : IO UInt32 := do
  IO.println "FuelExemplar: exemplar_certified_shipped_zero (fuel 0 → the distinguished kill) — kernel-checked at compile time"
  IO.println "FuelExemplar: exemplar_certified_shipped_one (fuel 1 → Active Specified(42); decide +kernel per scheduler-mode branch) — kernel-checked at compile time"
  IO.println "FuelExemplar: the ∀-fuel statement is STOP-AND-REPORT (file header): closes only above the default heartbeat budget"
  return 0
