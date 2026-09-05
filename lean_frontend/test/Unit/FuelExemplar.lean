/-
  FuelExemplar — the FUEL arc's in-repo exemplar over the SHIPPED
  fuel-parametric pipeline, restated for the fuel-parameter arc
  (2026-09-04, docs/2026-09-04_fuel-parameter-C1-record.md): the pipeline
  is the GENERATED `drive [LemFuel]` itself — fuel is the ambient
  `[LemFuel]` instance every fuel'd function reads, instantiated `⟨fuel⟩`
  by the theorem (the hand-written mirror `CerbND.drive_lemFuel` and the
  budget constants are deleted). Design note docs/2026-09-02_fuel-arc-
  design.md §1.4/§6; consumer shape = the refined-cerberus review
  2026-09-02 §6; the ∀-fuel restatement = lem-lean fuel-parameter record
  §6.7 ("`∀ n, … @f ⟨n⟩ …`").

  The program: a synthetic one-procedure Core file — `main` returning the
  constant `Specified(42)`, no globals, no externs, no tags — built
  directly as a Lean term (the consumer's own `prodFile` shape), NOT
  parsed from text: kernel evaluation of the Parsec text parser would be
  an uninformative cost in the statement; the driver pipeline under
  judgment is the same.

  WHAT IS SHIPPED (kernel-checked, axiom cone = the standard three,
  probed by scripts/check_theorem_axioms.sh's FUEL leg):

  * `exemplar_certified_shipped_forall (fuel : Nat)` — THE ∀-fuel theorem
    in EXACTLY the consumer's §6 shape over `run fuel` = the production
    runner on the production pipeline, both at the instance `⟨fuel⟩`, by
    the consumer's SYMBOLIC route (design note §1.6 route iii): a
    test-local round library (`Round`: `runOne` and its bind/get/update/
    read/liftMem/runND equations at a SYMBOLIC positive fuel
    `Nat.succ k`, `prepare_exit_single`, `loop_step_done`,
    `process_done`, `driver2_done` — the scheduler-mode read
    `CerbGlobal.current_execution_mode ()` is a plain `def` (= `none`)
    since 2026-09-05, rewritten by its `rfl` lemma; it used to be a
    `cases` on an opaque read —, `finalize_done`) plus
    the exemplar-specific `S₁` (the post-setup state: the engine's own
    setup stages composed — `driver_globals`, then the errno allocation
    (drive's stage, driver.lem:1860-1868: `CerbCall.allocErrno`'s text
    with the alignment written as its value, `alignofIval_signed_int`)
    and the arena park (driver.lem:1870-1880) — at the SAME symbolic
    instance; `drive_after_setup` CHECKS that composition against the
    generated `drive` by one `rfl` per setup bind) and `round_done`
    (PROGRAM-DONE in one round at ANY fuel ≥ 2). Closes at the DEFAULT
    heartbeat budget; no option bumps (a bump is a defect).
  * `exemplar_certified_shipped_zero` — fuel 0: the runner's own leaf
    (`runNDFuel_zero`), by `rfl`.
  * `exemplar_killed_at_one` — fuel 1 (`Nat.succ 0`): with ONE ambient
    fuel for the whole pipeline (no separate setup budget any more), the
    setup's first memory operation — the errno allocation's `liftMem`,
    `liftND_lemFuel 1` → `liftAction_lemFuel 0` — is the distinguished
    kill; by `rfl` evaluation of the fuel-1 setup prefix. Hence the
    left disjunct at fuels 0 and 1, the right disjunct from fuel 2 on.
    (The former `exemplar_certified_shipped_one` — Active at fuel 1 —
    described the old split budgets; the former kernel-evaluated closed
    instance `exemplar_run_one_kernel` is retired with it: a closed
    ACTIVE instance would name a fuel numeral inside the test text,
    which the no-fuel-numerals gate forbids, and the ∀-theorem's
    `Nat.succ (Nat.succ k)` case delivers the Active result list for
    every such fuel symbolically.)

  DIAGNOSIS recorded (arc record §4): the brute route — unfold the run,
  expose the scheduler-mode read (then opaque; `cases`), then
  `List.mem_singleton.mp`/`rfl` —
  times out at the default 200000 heartbeats EVEN AT A LITERAL FUEL,
  so the blow-up is the ELABORATOR's (Meta) whnf of a concrete driver
  round, not the open fuel variable; the kernel evaluates the same round
  in well under a second. The consumer's symbolic method is the only
  viable shape, and it scales (one lemma per engine round shape).

  Compile-time proofs; `main` reports success at runtime.
-/

import CerbND
import CerbCall
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
    production filesystem state (Main.lean's `drSt`), at the ambient
    instance (the generated `initial_driver_state` is fuel-lifted). -/
def dst₀ [LemFuel] (sup : Nat) : driver_state :=
  (initial_driver_state sup exemplarFile CerbFS.fs_initial_state).1

/-- THE SHIPPED RUN at fuel `n`: the production runner `CerbND.runND` on
    the production pipeline `drive`, cold start, `["cmdname"]` — the
    whole thing at ONE instance `⟨n⟩` (Main.lean's `letI : LemFuel :=
    ⟨fuel⟩` around `runPipeline`, exactly). -/
def run (n : Nat) :
    List (nd_status driver_result driver_error driver_state × List String × driver_state) :=
  @CerbND.runND _ _ _ _ _ ⟨n⟩ (@drive ⟨n⟩ fmapEmpty false exemplarFile ["cmdname"]) (@dst₀ ⟨n⟩ 0)

/-- The postcondition: the delivered Core value is `Specified(42)`. -/
def post (r : driver_result) (_ : driver_state) : Prop :=
  r.dres_core_value = fortyTwo

/-! ## Fuel 0: the distinguished kill (consumer shape, left disjunct) -/

/-- The consumer's acceptance shape at fuel 0: the runner's own leaf
    (`CerbND.runNDFuel_zero`) — nothing of the pipeline runs. -/
theorem exemplar_certified_shipped_zero :
    ∀ o ∈ run 0,
      (∃ st, o.1 = Killed st CerbND.fuelExhaustedKill) ∨ (∃ r, o.1 = Active r ∧ post r o.2.2) := by
  intro o ho
  have h := List.mem_singleton.mp ho
  subst h
  exact Or.inl ⟨_, rfl⟩

/-! ## Fuel 1: the kill at the first memory operation -/

/-- At fuel `Nat.succ 0` the setup prefix runs (every `nd_bind` at fuel 1
    unfolds one level) until the errno allocation's `liftMem`:
    `liftND_lemFuel 1 … (ND g)` is `liftAction_lemFuel 0 …` — the
    distinguished kill, state unchanged. By `rfl` evaluation of the
    concrete prefix (the elaborator's whnf of the SETUP is cheap; it is a
    driver ROUND that is not). -/
theorem exemplar_killed_at_one :
    ∀ o ∈ run (Nat.succ 0), ∃ st, o.1 = Killed st CerbND.fuelExhaustedKill := by
  intro o ho
  have h := List.mem_singleton.mp ho
  subst h
  exact ⟨_, rfl⟩

/-! ## The ∀-fuel exemplar — the symbolic route (design note §1.6 route iii) -/

/-! ## Proof devices: the symbolic round library (consumer: DriverCollapse.lean
    shapes), at a SYMBOLIC positive ambient fuel; test-local, NOT the CerbND
    contract -/
namespace Round

/-! ### runOne layer (consumer: DriverCollapse.lean:98-146) -/

def runOne {a info err cs st : Type} (m : ndM a info err cs st) (s : st) :
    nd_action a info err cs st × st :=
  match m with | ND f => f s

theorem runOne_return {a b c d st : Type} (x : a) (s : st) :
    runOne (nd_return x : ndM a c b d st) s = (NDactive x, s) := rfl
theorem runOne_get {a b c : Type} {st : Type} (s : st) :
    runOne (nd_get : ndM st c b a st) s = (NDactive s, s) := rfl
theorem runOne_update {a b c st : Type} (f : st → st) (s : st) :
    runOne (nd_update f : ndM Unit c b a st) s = (NDactive (), f s) := rfl
theorem runOne_read {a b c st r : Type} (f : st → r) (s : st) :
    runOne (nd_read f : ndM r c b a st) s = (NDactive (f s), s) := rfl

/-- `nd_bind` at any POSITIVE ambient fuel `Nat.succ k` steps through an
    active first component (the worker's `| lemFuel + 1 =>` arm; the
    counter is the instance's `LemFuel.fuel ⟨Nat.succ k⟩ = Nat.succ k`
    by projection). -/
theorem runOne_bind_active {k : Nat} {a b cs err info st : Type}
    {m : ndM a info err cs st} {f : a → ndM b info err cs st} {s s' : st} {z : a}
    (h : runOne m s = (NDactive z, s')) :
    runOne (@nd_bind _ _ _ _ _ _ ⟨Nat.succ k⟩ m f) s = runOne (f z) s' := by
  rcases m with ⟨g⟩
  dsimp only [runOne] at h
  show runOne (nd_bind_lemFuel (Nat.succ k) (ND g) f) s = _
  unfold nd_bind_lemFuel
  dsimp only [runOne]
  rw [h]
  dsimp only
  rcases hf : f z with ⟨g'⟩
  rfl

/-- `liftMem` at ambient fuel `Nat.succ (Nat.succ k)`: `liftND_lemFuel
    (k+2)` unfolds to `liftAction_lemFuel (k+1)`, which lifts an active
    memory action (at ambient fuel 1 the same term is the kill:
    `exemplar_killed_at_one`). -/
theorem runOne_liftMem_active {k : Nat} {a : Type}
    {m : ndM a String mem_error (mem_constraint CerbMem.IntegerValue) CerbMem.MemState}
    {dst : driver_state} {z : a} {σ' : CerbMem.MemState}
    (h : runOne m dst.layout_state = (NDactive z, σ')) :
    runOne (@liftMem _ ⟨Nat.succ (Nat.succ k)⟩ m) dst = (NDactive z, { dst with layout_state := σ' }) := by
  rcases m with ⟨g⟩
  dsimp only [runOne] at h
  show runOne (liftND_lemFuel (Nat.succ (Nat.succ k)) _ _ _ _ (ND g)) dst = _
  unfold liftND_lemFuel
  dsimp only [runOne]
  rw [h]
  unfold liftAction_lemFuel
  rfl

/-- The exhaustive runner at any positive ambient fuel on an active
    single-step computation. -/
theorem runND_active {k : Nat} {a info err cs st : Type}
    {m : ndM a info err cs st} {s s' : st} {z : a}
    (h : runOne m s = (NDactive z, s')) :
    @CerbND.runND _ _ _ _ _ ⟨Nat.succ k⟩ m s = [(nd_status.Active z, ([] : List String), s')] := by
  rcases m with ⟨g⟩
  dsimp only [runOne] at h
  show CerbND.runNDFuel (Nat.succ k) (ND g) s = _
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
    finalize_done), at a symbolic ambient fuel `Nat.succ k` -/

/-- One worklist step at counter `fl + 2` (ambient `Nat.succ k`): the
    single thread's step list is `[Step_done2 v]`; the loop records it and
    stops (`find_can_advance` finds nothing to advance). -/
theorem loop_step_done {k : Nat} (fl : Nat) (tds : Fmap sym (CerbLocation.Loc × tag_definition))
    (acc : Fmap thread_id (List core_step2))
    {dst : driver_state} {th : thread_state} {v : value}
    (hth : dst.core_state0.thread_states = [(0, (none, th))])
    (hsteps : @step_ctx ⟨Nat.succ k⟩ tds dst.layout_state dst.core_file dst.core_extern 0
      (none, th) = [Step_done2 v]) :
    runOne (@drive_nonmemory_steps_aux2_lemFuel ⟨Nat.succ k⟩ (Nat.succ (Nat.succ fl))
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
        @step_ctx ⟨Nat.succ k⟩ tds dst.layout_state dst.core_file dst.core_extern 0 th_info) = _
    rw [hth]
    exact hsteps
  · dsimp only [find_can_advance, can_advance]
    conv => lhs; unfold drive_nonmemory_steps_aux2_lemFuel
    rfl

theorem process_done {k : Nat} (tds : Fmap sym (CerbLocation.Loc × tag_definition))
    (cont : Bool → ndM Unit step_kind driver_error
      (mem_constraint CerbMem.IntegerValue) driver_state)
    (v : value) (dst : driver_state) (th : thread_state)
    (hth : dst.core_state0.thread_states = [(0, (none, th))]) :
    runOne (@process_core_step2 ⟨Nat.succ k⟩ tds false cont (Step_done2 v)) dst =
      (NDactive (), { dst with core_state0 :=
        { dst.core_state0 with thread_states :=
            [(0, (none, { th with stack0 := Stack_empty, arena := mk_value_e v }))] } }) := by
  unfold process_core_step2
  dsimp only
  refine (runOne_bind_active (z := ()) (s' := dst) (by rfl)).trans ?_
  rw [runOne_update]
  rw [prepare_exit_single dst.core_state0 th v hth]

/-- The scheduler round at counter `fl + 1`, ambient `Nat.succ k`: with the
    loop's result `[Step_done2 v]` for thread 0, the round prepares the
    exit (the arena becomes the value, the stack empties). -/
theorem driver2_done {k : Nat} (fl : Nat)
    (tds : Fmap sym (CerbLocation.Loc × tag_definition))
    (dst dstF : driver_state) (th thF : thread_state) (v : value)
    (hth : dst.core_state0.thread_states = [(0, (none, th))])
    (hloop : runOne (@drive_nonmemory_steps_aux2_lemFuel ⟨Nat.succ k⟩ (Nat.succ k) tds
        fmapEmpty [0]) dst =
      (NDactive (fmapAddBy defaultCompare 0 [Step_done2 v] fmapEmpty), dstF))
    (hthF : dstF.core_state0.thread_states = [(0, (none, thF))]) :
    runOne (@driver2_lemFuel ⟨Nat.succ k⟩ (Nat.succ fl) tds false) dst =
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
    -- The scheduler-mode test (driver.lem:1380) is a plain definition
    -- since 2026-09-05 (CerbGlobal step 1): `current_execution_mode () =
    -- none`, so the test is `false` by `rfl` and only the exhaustive arm
    -- exists to prove (it used to be a `cases` on an opaque read, both
    -- arms discharged).
    rw [CerbGlobal.current_execution_mode_eq]
    rw [if_neg (fun h => Bool.noConfusion h)]
    refine (runOne_bind_active (z := ()) (s' := dstF) (by rfl)).trans ?_
    refine (runOne_bind_active (z := ((0 : Nat), some (Step_done2 v)))
      (s' := dstF) (by rfl)).trans ?_
    dsimp only
    exact process_done tds _ v dstF thF hthF

theorem finalize_done {k : Nat} (tds : Fmap sym (CerbLocation.Loc × tag_definition))
    (s : String) (dst : driver_state) (th : thread_state) (v : value)
    (hth : dst.core_state0.thread_states = [(0, (none, th))])
    (harena : th.arena = mk_value_e v) :
    (@finalize ⟨Nat.succ k⟩ tds s dst).dres_core_value = v := by
  unfold finalize
  rw [hth]
  dsimp only
  rw [harena]
  rfl

end Round

open Round

/-! ### The exemplar: setup split (consumer: drive_after_setup) + round + finalize -/

/-- The alignment of `signed_int` at any positive ambient fuel, as a value
    (`alignofCtype_lemFuel (Nat.succ k) … = 4` in one unfolding: the
    integer case does not recurse). FINDING recorded with this slice
    (Lean 4.32.2, minimal reproducer in the C1 record): `Nat.div`/`Nat.mod`
    (and the `Int` division built on them) do NOT fold by `rfl` when the
    DIVISOR is a symbolic-argument application that merely EVALUATES to a
    literal (`8 / f (Nat.succ k) = 2 := rfl` fails while `f (Nat.succ k) =
    4 := rfl`, `8 - f (Nat.succ k) = 4 := rfl` and `8 / f 5 = 2 := rfl` all
    hold); the memory model's `allocator` divides by the alignment, so the
    errno stage at a SYMBOLIC fuel needs the alignment rewritten to its
    value first (`drive_after_setup` does `rw [alignofIval_signed_int]`
    before the errno step; `setupTail` states it as the value). At a
    literal fuel — the pre-arc exemplar — the same term folded. -/
theorem alignofIval_signed_int (k : Nat) :
    @CerbMem.alignofIval ⟨Nat.succ k⟩ fmapEmpty signed_int = CerbMem.integerIval 4 := rfl

/-- The post-setup state, from the ENGINE's own setup stages composed at
    the ambient instance: `driver_globals` (spawns thread 0; no globals),
    then drive's errno allocation (driver.lem:1860-1868 — the text of
    `CerbCall.allocErrno` with `alignofIval fmapEmpty signed_int` written
    as its value `integerIval 4`, `alignofIval_signed_int`) and the arena
    park of thread 0 on `main`'s body (driver.lem:1870-1880, the record
    `drive` builds).
    The composition is CHECKED against the generated `drive` by
    `drive_after_setup`'s per-bind `rfl`s: a disagreement fails that
    theorem, so no hand-built state can drift from the pipeline. -/
def setupTail [LemFuel] (tid0 : Nat) : driverM Unit :=
  nd_bind (liftMem (nd_bind
      (CerbMem.allocateObject fmapEmpty tid0 (PrefOther "errno")
        (CerbMem.integerIval 4) signed_int none none)   -- = alignofIval fmapEmpty signed_int (alignofIval_signed_int)
      (fun (ptr_val : CerbMem.PointerValue) =>
        let zero := CerbMem.integerValueMval (Signed Int_) (CerbMem.integerIval (0 : Int))
        nd_bind
          (CerbMem.storeM fmapEmpty (CerbLocation.other "errno init") signed_int false ptr_val zero)
          (fun (_ : CerbMem.Footprint) => nd_return ptr_val))))
    (fun (errno_ptr_val : CerbMem.PointerValue) =>
  nd_bind get_thread_states (fun (x : List (Nat × (Option thread_id × thread_state))) =>
    match x with
    | [(_, (_, th_st))] =>
      driver_update_thread_state tid0
        ({ arena := mainBody, stack0 := Stack_empty, errno := errno_ptr_val,
           current_loc := CerbLocation.other "Driver.drive",
           exec_loc := ELoc_normal [(mainSym, CerbLocation.other "Driver.drive")],
           env := th_st.env, current_proc_opt := some mainSym } : thread_state)
    | _ => (failwithI "ERROR (in Driver 2)" : ndM Unit step_kind driver_error mem_iv_constraint driver_state)))

/-- The state at `driver2`'s entry, at the ambient instance. -/
def S₁ [LemFuel] : driver_state :=
  (runOne (setupTail 0) (runOne (driver_globals fmapEmpty false exemplarFile) (dst₀ 0)).2).2

/-- The setup split at the shipped pipeline (consumer shape
    `drive_after_setup`), ambient `Nat.succ (Nat.succ k)`: the concrete
    setup prefix is discharged step by step (each `rfl` evaluates ONE
    setup bind on a concrete state, at the symbolic fuel — every fuel
    match reduces on `Nat.succ _`), leaving `driver2` at `S₁` as a
    hypothesis. -/
theorem drive_after_setup (k : Nat) (dstD : driver_state)
    (hdrv2 : runOne (@driver2 ⟨Nat.succ (Nat.succ k)⟩ fmapEmpty false) (@S₁ ⟨Nat.succ (Nat.succ k)⟩)
      = (NDactive (), dstD)) :
    runOne (@drive ⟨Nat.succ (Nat.succ k)⟩ fmapEmpty false exemplarFile ["cmdname"])
        (@dst₀ ⟨Nat.succ (Nat.succ k)⟩ 0)
      = (NDactive (@finalize ⟨Nat.succ (Nat.succ k)⟩ fmapEmpty "drive (without concur)" dstD), dstD) := by
  conv => lhs; unfold drive
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
  -- errno: real allocateObject/storeM on the cold memory. The alignment
  -- argument is rewritten to its value first (alignofIval_signed_int:
  -- `allocator` divides by it, and div/mod do not fold on a symbolic-fuel
  -- divisor by rfl).
  rw [alignofIval_signed_int]
  refine (runOne_bind_active (z := _) (s' := _) (runOne_liftMem_active rfl)).trans ?_
  -- park main's arena; driver2; finalize
  refine (runOne_bind_active (z := ()) (s' := dstD) ?_).trans ?_
  · refine (runOne_bind_active (z := ()) (s' := @S₁ ⟨Nat.succ (Nat.succ k)⟩) rfl).trans ?_
    exact hdrv2
  · refine (runOne_bind_active (z := dstD) (s' := dstD) rfl).trans ?_
    rfl

/-- The round on `S₁` at ANY ambient fuel ≥ 2: PROGRAM-DONE in one round
    (consumer shape `driver2_done`); the successor state is explicit. -/
theorem round_done (k : Nat) :
    ∃ (thF : thread_state),
      runOne (@driver2 ⟨Nat.succ (Nat.succ k)⟩ fmapEmpty false) (@S₁ ⟨Nat.succ (Nat.succ k)⟩) =
        (NDactive (), { @S₁ ⟨Nat.succ (Nat.succ k)⟩ with core_state0 :=
          { (@S₁ ⟨Nat.succ (Nat.succ k)⟩).core_state0 with thread_states :=
            [(0, (none, { thF with stack0 := Stack_empty, arena := mk_value_e fortyTwo }))] } }) := by
  refine ⟨_, driver2_done (Nat.succ k) fmapEmpty _ _ _ _ fortyTwo rfl
    (loop_step_done k fmapEmpty fmapEmpty rfl rfl) rfl⟩

/-- THE ∀-FUEL EXEMPLAR (the consumer's §6 shape), by the symbolic route:
    fuel 0 and 1 kill (the runner leaf; the first memory operation),
    every fuel ≥ 2 delivers `Specified(42)` in one round. -/
theorem exemplar_certified_shipped_forall (fuel : Nat) :
    ∀ o ∈ run fuel,
      (∃ st, o.1 = Killed st CerbND.fuelExhaustedKill) ∨ (∃ r, o.1 = Active r ∧ post r o.2.2) := by
  cases fuel with
  | zero => exact exemplar_certified_shipped_zero
  | succ n =>
    cases n with
    | zero =>
      intro o ho
      exact Or.inl (exemplar_killed_at_one o ho)
    | succ k =>
      obtain ⟨thF, hdrv2⟩ := round_done k
      have hrun := drive_after_setup k _ hdrv2
      intro o ho
      unfold run at ho
      rw [runND_active hrun] at ho
      have h := List.mem_singleton.mp ho
      subst h
      exact Or.inr ⟨_, rfl, finalize_done fmapEmpty _ _ _ fortyTwo rfl rfl⟩

end FuelExemplar

def main : IO UInt32 := do
  IO.println "FuelExemplar: exemplar_certified_shipped_forall (∀ fuel over the shipped `@drive ⟨fuel⟩`; the consumer's §6 shape, symbolic round library) — kernel-checked at compile time"
  IO.println "FuelExemplar: exemplar_certified_shipped_zero (fuel 0 → the runner's distinguished kill) — kernel-checked at compile time"
  IO.println "FuelExemplar: exemplar_killed_at_one (fuel 1 → the kill at the first memory operation; fuels ≥ 2 deliver Specified(42)) — kernel-checked at compile time"
  return 0
