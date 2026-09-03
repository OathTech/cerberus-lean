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
  probed by scripts/check_theorem_axioms.sh's FUEL leg):

  * `exemplar_certified_shipped_forall (fuel : Nat)` — THE ∀-fuel theorem
    in EXACTLY the consumer's §6 shape, by the consumer's SYMBOLIC route
    (design note §1.6 route iii; second design review 2026-09-03): a
    test-local round library (`Round`: `runOne` and its bind/get/update/
    read/liftMem/runND equations, `prepare_exit_single`, `loop_step_done`,
    `process_done`, `driver2_done` — CASES on the opaque scheduler-mode
    read `CerbGlobal.current_execution_mode ()` — `finalize_done`,
    `budget_succ : CerbFuel.driverFuel = Nat.succ 99999999 := rfl`) plus
    the exemplar-specific `S₁` (the post-setup state, named by PROJECTION
    from the shipped fuel-0 run — engine-derived, no hand-built record),
    `drive_after_setup` (each setup bind discharged by one `rfl` on a
    concrete state) and `round_done` (PROGRAM-DONE in one round at ANY
    positive fuel). Closes in under a second at the DEFAULT heartbeat
    budget. The library is a proof device of this test file; it is NOT
    part of the `CerbND` contract (it stays test-local unless the
    consumer asks for it).
  * `exemplar_certified_shipped_zero` — the consumer shape at fuel 0 (the
    distinguished kill), by `rfl` evaluation of the fuel-independent setup
    + `driver2_lemFuel_zero`; also the base case of the theorem above.
  * `exemplar_certified_shipped_one` — the consumer shape at fuel 1 by a
    different route: the closed instance `exemplar_run_one_kernel`
    evaluated by `decide +kernel` per scheduler-mode branch (kernel-
    checked `of_decide_eq_true (Eq.refl true)`; no `ofReduce*` axiom, no
    compiled-code decision), lifted by `resultOk_sound`. Kept as the
    kernel-evaluation witness.

  DIAGNOSIS recorded (arc record §4): the brute route — unfold the run,
  expose the opaque read, `cases`, then `List.mem_singleton.mp`/`rfl` —
  times out at the default 200000 heartbeats EVEN AT THE LITERAL FUEL 1,
  so the blow-up is the ELABORATOR's (Meta) whnf of a concrete driver
  round, not the open fuel variable; the kernel evaluates the same round
  in well under a second. The consumer's symbolic method is the only
  viable shape, and it scales (one lemma per engine round shape).

  Compile-time proofs; `main` reports success at runtime.
-/

import CerbND
import Core
import Core_run_aux
import Driver
-- pin-bump 2026-09-03 (LemLib 3c88f0d, parity-fix F7): the generated
-- `nd_mapM` folds with the tail-recursive `lemListFoldr` (an Array.foldr
-- under the hood), which does not reduce by `dsimp` the way `List.foldr`
-- did; LemLib ships the kernel-checked equation `lemListFoldr_eq`
-- (LemLibTheorems.lean) and the proof below rewrites through it.
import LemLibTheorems

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


/-! ## The ∀-fuel exemplar — the symbolic route (design note §1.6 route iii) -/

/-! ## Proof devices: the symbolic round library (consumer: DriverCollapse.lean
    shapes, ported at `CerbFuel.driverFuel`; test-local, NOT the CerbND contract) -/
namespace Round

/-! ### runOne layer (consumer: DriverCollapse.lean:98-146), at driverFuel -/

def runOne {a info err cs st : Type} (m : ndM a info err cs st) (s : st) :
    nd_action a info err cs st × st :=
  match m with | ND f => f s

theorem budget_succ : CerbFuel.driverFuel = Nat.succ 99999999 := rfl
theorem lemDefaultFuel_succ : lemDefaultFuel = Nat.succ 999999 := rfl

theorem runOne_return {a b c d st : Type} (x : a) (s : st) :
    runOne (nd_return x : ndM a c b d st) s = (NDactive x, s) := rfl
theorem runOne_get {a b c : Type} {st : Type} (s : st) :
    runOne (nd_get : ndM st c b a st) s = (NDactive s, s) := rfl
theorem runOne_update {a b c st : Type} (f : st → st) (s : st) :
    runOne (nd_update f : ndM Unit c b a st) s = (NDactive (), f s) := rfl
theorem runOne_read {a b c st r : Type} (f : st → r) (s : st) :
    runOne (nd_read f : ndM r c b a st) s = (NDactive (f s), s) := rfl

theorem runOne_bind_active {a b cs err info st : Type}
    {m : ndM a info err cs st} {f : a → ndM b info err cs st} {s s' : st} {z : a}
    (h : runOne m s = (NDactive z, s')) :
    runOne (nd_bind m f) s = runOne (f z) s' := by
  rcases m with ⟨g⟩
  dsimp only [runOne] at h
  show runOne (nd_bind_lemFuel CerbFuel.driverFuel (ND g) f) s = _
  rw [budget_succ]
  unfold nd_bind_lemFuel
  dsimp only [runOne]
  rw [h]
  dsimp only
  rcases hf : f z with ⟨g'⟩
  rfl

theorem runOne_liftMem_active {a : Type}
    {m : ndM a String mem_error (mem_constraint CerbMem.IntegerValue) CerbMem.MemState}
    {dst : driver_state} {z : a} {σ' : CerbMem.MemState}
    (h : runOne m dst.layout_state = (NDactive z, σ')) :
    runOne (liftMem m) dst = (NDactive z, { dst with layout_state := σ' }) := by
  rcases m with ⟨g⟩
  dsimp only [runOne] at h
  show runOne (liftND_lemFuel lemDefaultFuel _ _ _ _ (ND g)) dst = _
  rw [lemDefaultFuel_succ]
  unfold liftND_lemFuel
  dsimp only [runOne]
  rw [h]
  rw [show (999999 : Nat) = Nat.succ 999998 from rfl]
  unfold liftAction_lemFuel
  rfl

theorem runND_active {a info err cs st : Type}
    {m : ndM a info err cs st} {s s' : st} {z : a}
    (h : runOne m s = (NDactive z, s')) :
    CerbND.runND m s = [(nd_status.Active z, ([] : List String), s')] := by
  rcases m with ⟨g⟩
  dsimp only [runOne] at h
  show CerbND.runNDFuel CerbFuel.driverFuel (ND g) s = _
  rw [budget_succ]
  unfold CerbND.runNDFuel
  dsimp only
  rw [h]

/-! ## Thread-map helpers (consumer: DriverCollapse.lean:242-252) -/

theorem prepare_exit_single (cs : core_state) (th : thread_state) (v : value)
    (hth : cs.thread_states = [(0, (none, th))]) :
    prepare_exit cs v =
      { cs with thread_states :=
          [(0, (none, { th with stack0 := Stack_empty, arena := mk_value_e v }))] } := by
  have hcs : cs = { thread_states := [(0, (none, th))], io := cs.io } := by
    rw [← hth]
  rw [hcs]
  rfl

/-! ## The done round (consumer: loop_step_done, process_done, driver2_done,
    finalize_done), restated at driverFuel -/

theorem loop_step_done (fl : Nat) (tds : Fmap sym (CerbLocation.Loc × tag_definition))
    (acc : Fmap thread_id (List core_step2))
    {dst : driver_state} {th : thread_state} {v : value}
    (hth : dst.core_state0.thread_states = [(0, (none, th))])
    (hsteps : step_ctx tds dst.layout_state dst.core_file dst.core_extern 0
      (none, th) = [Step_done2 v]) :
    runOne (drive_nonmemory_steps_aux2_lemFuel (Nat.succ (Nat.succ fl))
        tds acc [0]) dst =
      (NDactive (fmapAddBy defaultCompare 0 [Step_done2 v] acc), dst) := by
  conv => lhs; unfold drive_nonmemory_steps_aux2_lemFuel
  refine (runOne_bind_active (z := [Step_done2 v]) (s' := dst) ?_).trans ?_
  · rw [runOne_read]
    refine congrArg (fun x => (NDactive x, dst)) ?_
    show (let th_info := match lookupBy (fun x y => x == y) 0
            dst.core_state0.thread_states with
          | some z => z
          | none => failwithI _;
        step_ctx tds dst.layout_state dst.core_file dst.core_extern 0 th_info) = _
    rw [hth]
    exact hsteps
  · dsimp only [find_can_advance, can_advance]
    conv => lhs; unfold drive_nonmemory_steps_aux2_lemFuel
    rfl

theorem process_done (tds : Fmap sym (CerbLocation.Loc × tag_definition))
    (cont : Bool → ndM Unit step_kind driver_error
      (mem_constraint CerbMem.IntegerValue) driver_state)
    (v : value) (dst : driver_state) (th : thread_state)
    (hth : dst.core_state0.thread_states = [(0, (none, th))]) :
    runOne (process_core_step2 tds false cont (Step_done2 v)) dst =
      (NDactive (), { dst with core_state0 :=
        { dst.core_state0 with thread_states :=
            [(0, (none, { th with stack0 := Stack_empty, arena := mk_value_e v }))] } }) := by
  unfold process_core_step2
  dsimp only
  refine (runOne_bind_active (z := ()) (s' := dst) (by rfl)).trans ?_
  rw [runOne_update]
  rw [prepare_exit_single dst.core_state0 th v hth]

theorem driver2_done (fl : Nat)
    (tds : Fmap sym (CerbLocation.Loc × tag_definition))
    (dst dstF : driver_state) (th thF : thread_state) (v : value)
    (hth : dst.core_state0.thread_states = [(0, (none, th))])
    (hloop : runOne (drive_nonmemory_steps_aux2_lemFuel CerbFuel.driverFuel tds
        fmapEmpty [0]) dst =
      (NDactive (fmapAddBy defaultCompare 0 [Step_done2 v] fmapEmpty), dstF))
    (hthF : dstF.core_state0.thread_states = [(0, (none, thF))]) :
    runOne (driver2_lemFuel (Nat.succ fl) tds false) dst =
      (NDactive (), { dstF with core_state0 :=
        { dstF.core_state0 with thread_states :=
            [(0, (none, { thF with stack0 := Stack_empty, arena := mk_value_e v }))] } }) := by
  conv => lhs; unfold driver2_lemFuel
  refine (runOne_bind_active (z := [((0 : Nat), some (Step_done2 v))])
    (s' := dstF) ?_).trans ?_
  · unfold new_drive_core_threads
    refine (runOne_bind_active (z := dst) (by rfl)).trans ?_
    dsimp only
    rw [hth]
    dsimp only [List.map]
    refine (runOne_bind_active
      (z := fmapAddBy defaultCompare 0 [Step_done2 v] fmapEmpty)
      (s' := dstF) hloop).trans ?_
    rw [show fmapElements (fmapAddBy defaultCompare (0 : Nat) [Step_done2 v]
      fmapEmpty) = [((0 : Nat), [Step_done2 v])] from rfl]
    unfold nd_mapM
    dsimp only [List.map]
    rw [LemLibTheorems.lemListFoldr_eq]
    dsimp only [List.foldr]
    refine (runOne_bind_active (z := ((0 : Nat), some (Step_done2 v)))
      (s' := dstF) ?_).trans ?_
    · refine (runOne_bind_active (z := Step_done2 v) (s' := dstF)
        (by rfl)).trans (by rfl)
    · refine (runOne_bind_active
        (z := ([] : List (Nat × Option core_step2))) (by rfl)).trans (by rfl)
  · refine (runOne_bind_active (z := dstF) (by rfl)).trans ?_
    dsimp only
    cases hmode : maybeEqualBy (fun x y => x == y)
        (CerbGlobal.current_execution_mode ())
        (some CerbGlobal.ExecutionMode.random) with
    | true =>
      rw [if_pos rfl]
      unfold bindExhaustive
      refine (runOne_bind_active (z := ((0 : Nat), some (Step_done2 v)))
        (s' := dstF) (by rfl)).trans ?_
      dsimp only
      exact process_done tds _ v dstF thF hthF
    | false =>
      rw [if_neg (fun h => Bool.noConfusion h)]
      refine (runOne_bind_active (z := ()) (s' := dstF) (by rfl)).trans ?_
      refine (runOne_bind_active (z := ((0 : Nat), some (Step_done2 v)))
        (s' := dstF) (by rfl)).trans ?_
      dsimp only
      exact process_done tds _ v dstF thF hthF

theorem finalize_done (tds : Fmap sym (CerbLocation.Loc × tag_definition))
    (s : String) (dst : driver_state) (th : thread_state) (v : value)
    (hth : dst.core_state0.thread_states = [(0, (none, th))])
    (harena : th.arena = mk_value_e v) :
    (finalize tds s dst).dres_core_value = v := by
  unfold finalize
  rw [hth]
  dsimp only
  rw [harena]
  rfl


end Round

open Round

/-! ### The exemplar: setup split (consumer: drive_after_setup) + round + finalize -/


/-- The post-setup state, named by PROJECTION from the shipped fuel-0 run:
    `driver2_lemFuel 0` kills with the state unchanged and `nd_bind`'s kill
    arm propagates it (design note §1.6), so the fuel-0 execution's final
    state IS the state at `driver2` entry. Engine-derived, no hand-built
    record. -/
def S₁ : driver_state :=
  match CerbND.runND (CerbND.drive_lemFuel 0 fmapEmpty false exemplarFile ["cmdname"]) (dst₀ 0) with
  | [(_, _, s)] => s
  | _ => dst₀ 0

/-- The setup split at the fuel-parametric pipeline (consumer shape
    `drive_after_setup`, ProdEntry.lean:325): the concrete setup prefix is
    discharged step by step (each `rfl` evaluates ONE setup bind on a
    concrete state), leaving `driver2_lemFuel fuel` at `S₁` as a hypothesis. -/
theorem drive_after_setup (fuel : Nat) (dstD : driver_state)
    (hdrv2 : runOne (driver2_lemFuel fuel fmapEmpty false) S₁ = (NDactive (), dstD)) :
    runOne (CerbND.drive_lemFuel fuel fmapEmpty false exemplarFile ["cmdname"]) (dst₀ 0)
      = (NDactive (finalize fmapEmpty "drive (without concur)" dstD), dstD) := by
  conv => lhs; unfold CerbND.drive_lemFuel
  -- driver_globals: spawn thread 0, no globals
  refine (runOne_bind_active (z := (0 : Nat)) (s' := _) rfl).trans ?_
  -- nd_get
  refine (runOne_bind_active (z := _) (s' := _) rfl).trans ?_
  -- main lookup
  refine (runOne_bind_active (z := mainSym) (s' := _) rfl).trans ?_
  -- the decl
  refine (runOne_bind_active
    (z := (CerbLocation.unknown, ([] : List (sym × core_base_type)), mainBody)) (s' := _) rfl).trans ?_
  -- no params: argc/argv skipped
  refine (runOne_bind_active (z := mainBody) (s' := _) rfl).trans ?_
  -- errno: real allocateObject/storeM on the cold memory
  refine (runOne_bind_active (z := _) (s' := _) (runOne_liftMem_active rfl)).trans ?_
  -- park main's arena; driver2; finalize
  refine (runOne_bind_active (z := ()) (s' := dstD) ?_).trans ?_
  · refine (runOne_bind_active (z := ()) (s' := S₁) rfl).trans ?_
    exact hdrv2
  · refine (runOne_bind_active (z := dstD) (s' := dstD) rfl).trans ?_
    rfl

/-- The round on `S₁` at ANY positive fuel: PROGRAM-DONE in one round
    (consumer shape `driver2_done`); the successor state is explicit. -/
theorem round_done (n : Nat) :
    ∃ (thF : thread_state),
      runOne (driver2_lemFuel (n+1) fmapEmpty false) S₁ =
        (NDactive (), { S₁ with core_state0 := { S₁.core_state0 with thread_states :=
            [(0, (none, { thF with stack0 := Stack_empty, arena := mk_value_e fortyTwo }))] } }) := by
  refine ⟨_, driver2_done n fmapEmpty S₁ S₁ _ _ fortyTwo rfl
    (loop_step_done 99999998 fmapEmpty fmapEmpty rfl rfl) rfl⟩

/-- THE ∀-FUEL EXEMPLAR (the consumer's §6 shape), by the symbolic route. -/
theorem exemplar_certified_shipped_forall (fuel : Nat) :
    ∀ o ∈ CerbND.runND (CerbND.drive_lemFuel fuel fmapEmpty false exemplarFile ["cmdname"]) (dst₀ 0),
      (∃ st, o.1 = Killed st CerbND.fuelExhaustedKill) ∨ (∃ r, o.1 = Active r ∧ post r o.2.2) := by
  cases fuel with
  | zero => exact exemplar_certified_shipped_zero
  | succ n =>
    obtain ⟨thF, hdrv2⟩ := round_done n
    have hrun := drive_after_setup (n+1) _ hdrv2
    intro o ho
    rw [runND_active hrun] at ho
    have h := List.mem_singleton.mp ho
    subst h
    exact Or.inr ⟨_, rfl, finalize_done fmapEmpty _ _ _ fortyTwo rfl rfl⟩

end FuelExemplar

def main : IO UInt32 := do
  IO.println "FuelExemplar: exemplar_certified_shipped_forall (∀ fuel; the consumer's §6 shape, symbolic round library) — kernel-checked at compile time"
  IO.println "FuelExemplar: exemplar_certified_shipped_zero (fuel 0 → the distinguished kill) — kernel-checked at compile time"
  IO.println "FuelExemplar: exemplar_certified_shipped_one (fuel 1 → Active Specified(42); decide +kernel per scheduler-mode branch) — kernel-checked at compile time"
  return 0
