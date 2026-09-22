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

  * `exemplar_certified_shipped_forall (fuel : Nat) (top : Int) (digest : String) (h : 8 ≤ top)`
    — THE ∀-fuel, ∀-address-space-top theorem (the top since the address-space-
    bound slice, C4 2026-09-18: `errnoAction_active` discharges drive's errno
    allocation + store SYMBOLICALLY under `8 ≤ top` — the 4-byte/align-4 errno
    object is the first allocation, and below 8 the run is the out-of-memory
    kill before `main`; the post-setup state `S₁ top digest` is stated explicitly)
    in EXACTLY the consumer's §6 shape over `run fuel top digest` = the production
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
    enumDefs := default,
    stdlib := fmapEmpty,
    impl0 := fmapEmpty,
    globs := [],
    funs := fmapAddBy (fun (s1 s2 : sym) => ordCompare s1 s2) mainSym mainDecl fmapEmpty,
    extern := fmapEmpty,
    funinfo := fmapEmpty,
    loop_attributes1 := default,
    visible_objects_env0 := default }

/-- The shipped cold start: `(initial_driver_state sup top digest file fs).1` with the
    production filesystem state (Main.lean's `drSt`), at the ambient
    instance (the entry is supply-lifted only; the runner uses fuel); `top` is
    the address-space top and `digest` the run digest — PARAMETERS the theorems quantify (address-space-
    bound slice; the setup needs `8 ≤ top`, `errnoAction_active`). -/
def dst₀ [LemFuel] (sup : Nat) (top : Int) (digest : String) : driver_state :=
  (initial_driver_state sup top digest exemplarFile CerbFS.fs_initial_state).1

/-- THE SHIPPED RUN at fuel `n` and address-space top `top`: the production
    runner `CerbND.runND` on the production pipeline `drive`, cold start at
    `top`, `["cmdname"]` — the whole thing at ONE instance `⟨n⟩` (Main.lean's
    `letI : LemFuel := ⟨fuel⟩` around `runPipeline`, exactly; `top` is
    Main.lean's `--address-space-top`). -/
def run (n : Nat) (top : Int) (digest : String) :
    List (nd_status driver_result driver_error driver_state × List String × driver_state) :=
  @CerbND.runND _ _ _ _ _ ⟨n⟩ (@drive ⟨n⟩ fmapEmpty fmapEmpty false exemplarFile ["cmdname"]) (@dst₀ ⟨n⟩ 0 top digest)

/-- The postcondition: the delivered Core value is `Specified(42)`. -/
def post (r : driver_result) (_ : driver_state) : Prop :=
  r.dres_core_value = fortyTwo

/-! ## Fuel 0: the distinguished kill (consumer shape, left disjunct) -/

/-- The consumer's acceptance shape at fuel 0: the runner's own leaf
    (`CerbND.runNDFuel_zero`) — nothing of the pipeline runs. -/
theorem exemplar_certified_shipped_zero (top : Int) (digest : String) :
    ∀ o ∈ run 0 top digest,
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
theorem exemplar_killed_at_one (top : Int) (digest : String) :
    ∀ o ∈ run (Nat.succ 0) top digest, ∃ st, o.1 = Killed st CerbND.fuelExhaustedKill := by
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
theorem loop_step_done {k : Nat} (fl : Nat) (eds : Fmap sym integerType) (tds : Fmap sym (CerbLocation.Loc × tag_definition))
    (acc : Fmap thread_id (List core_step2))
    {dst : driver_state} {th : thread_state} {v : value}
    (hth : dst.core_state0.thread_states = [(0, (none, th))])
    (hsteps : @step_ctx ⟨Nat.succ k⟩ eds tds dst.layout_state dst.core_file dst.core_extern 0
      (none, th) = [Step_done2 v]) :
    runOne (@drive_nonmemory_steps_aux2_lemFuel ⟨Nat.succ k⟩ (Nat.succ (Nat.succ fl))
        eds tds acc [0]) dst =
      (NDactive (fmapAddBy defaultCompare 0 [Step_done2 v] acc), dst) := by
  conv => lhs; unfold drive_nonmemory_steps_aux2_lemFuel
  refine (runOne_bind_active (z := [Step_done2 v]) (s' := dst) ?_).trans ?_
  · rw [runOne_read]
    refine congrArg (fun x => (NDactive x, dst)) ?_
    show (let th_info := match lookupBy (fun x y => x == y) 0
            dst.core_state0.thread_states with
          | some z => z
          | none => failwithI _;
        @step_ctx ⟨Nat.succ k⟩ eds tds dst.layout_state dst.core_file dst.core_extern 0 th_info) = _
    rw [hth]
    exact hsteps
  · dsimp only [find_can_advance, can_advance]
    conv => lhs; unfold drive_nonmemory_steps_aux2_lemFuel
    rfl

theorem process_done {k : Nat} (eds : Fmap sym integerType) (tds : Fmap sym (CerbLocation.Loc × tag_definition))
    (cont : Bool → ndM Unit step_kind driver_error
      (mem_constraint CerbMem.IntegerValue) driver_state)
    (v : value) (dst : driver_state) (th : thread_state)
    (hth : dst.core_state0.thread_states = [(0, (none, th))]) :
    runOne (@process_core_step2 ⟨Nat.succ k⟩ eds tds false cont (Step_done2 v)) dst =
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
    (eds : Fmap sym integerType) (tds : Fmap sym (CerbLocation.Loc × tag_definition))
    (dst dstF : driver_state) (th thF : thread_state) (v : value)
    (hth : dst.core_state0.thread_states = [(0, (none, th))])
    (hloop : runOne (@drive_nonmemory_steps_aux2_lemFuel ⟨Nat.succ k⟩ (Nat.succ k) eds tds
        fmapEmpty [0]) dst =
      (NDactive (fmapAddBy defaultCompare 0 [Step_done2 v] fmapEmpty), dstF))
    (hthF : dstF.core_state0.thread_states = [(0, (none, thF))]) :
    runOne (@driver2_lemFuel ⟨Nat.succ k⟩ (Nat.succ fl) eds tds false) dst =
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
    exact process_done eds tds _ v dstF thF hthF

theorem finalize_done {k : Nat} (eds : Fmap sym integerType) (tds : Fmap sym (CerbLocation.Loc × tag_definition))
    (s : String) (dst : driver_state) (th : thread_state) (v : value)
    (hth : dst.core_state0.thread_states = [(0, (none, th))])
    (harena : th.arena = mk_value_e v) :
    (@finalize ⟨Nat.succ k⟩ eds tds s dst).dres_core_value = v := by
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
    @CerbMem.alignofIval ⟨Nat.succ k⟩ fmapEmpty fmapEmpty signed_int = CerbMem.integerIval 4 := rfl

/-! ### The errno allocation at a SYMBOLIC address-space top (address-space-bound slice,
    C4 2026-09-18, pre-merge audit F1): drive's first memory action — the errno `int`
    (4 bytes, align 4) allocated and stored `0` on the COLD state `initialMemState top` —
    discharged from `8 ≤ top` by the allocator's own arithmetic (`omega` over the Euclidean
    remainder) and the store's guards, instead of the former `rfl` on a concrete cursor. -/

/-- The errno object's address at top `top`: the cursor `top - 4` aligned down to 4. -/
def errnoAddr (top : Int) : Int := top - 4 - (top - 4) % 4

/-- The errno pointer: allocation id 0 at `errnoAddr top`. -/
def errnoPtr (top : Int) : CerbMem.PointerValue :=
  .PV (.Prov_some 0) (.PVconcrete none (errnoAddr top))

/-- The errno allocation record (uninitialised → writable, prefix "errno"). -/
def errnoAlloc (top : Int) : CerbMem.Allocation :=
  { base := errnoAddr top, size := 4, ty := some signed_int, isReadonly := .IsWritable, prefix_ := PrefOther "errno" }

/-- The memory state after `allocateObject` (before the store): the allocator's update, the
    record at id 0, the 4 unspecified bytes written at the address. -/
def σalloc (top : Int) : CerbMem.MemState :=
  CerbMem.writeBytesTo
    { CerbMem.initialMemState top with
        nextAllocId := 1
        lastUsed := some 0
        lastAddress := errnoAddr top
        allocations := (CerbMem.initialMemState top).allocations.insert 0 (errnoAlloc top) }
    (errnoAddr top)
    (CerbMem.memValueToBytes fmapEmpty fmapEmpty (CerbMem.initialMemState top).funptrmap (.MVunspecified signed_int)).snd

/-- drive's errno memory action, exactly as `drive` states it (driver.lem:1860-1868; the
    alignment written as its value, `alignofIval_signed_int`). -/
def errnoAction [LemFuel] : CerbMem.memM CerbMem.PointerValue :=
  nd_bind (CerbMem.allocateObject fmapEmpty fmapEmpty 0 (PrefOther "errno") (CerbMem.integerIval 4) signed_int none none)
    (fun (ptr_val : CerbMem.PointerValue) =>
      let zero := CerbMem.integerValueMval (Signed Int_) (CerbMem.integerIval (0 : Int))
      nd_bind (CerbMem.storeM fmapEmpty fmapEmpty (CerbLocation.other "errno init") signed_int false ptr_val zero)
        (fun (_ : CerbMem.Footprint) => nd_return ptr_val))

/-- The allocator on the cold state: ACTIVE at `errnoAddr top` whenever `8 ≤ top` (the two
    kills — `top - 4 < 0` and the aligned-down candidate `≤ 0` — are both excluded by `omega`). -/
theorem allocator_errno (top : Int) (h : 8 ≤ top) :
    runOne (CerbMem.allocator 4 4) (CerbMem.initialMemState top) =
      (NDactive ((0 : Int), errnoAddr top),
       { CerbMem.initialMemState top with nextAllocId := 1, lastUsed := some 0, lastAddress := errnoAddr top }) := by
  have h1 : ¬ ((top - 4 : Int) < 0) := by omega
  simp only [runOne, CerbMem.allocator, CerbMem.initialMemState, errnoAddr]
  simp [h1]
  omega

theorem allocateObject_errno (k : Nat) (top : Int) (h : 8 ≤ top) :
    runOne (@CerbMem.allocateObject ⟨Nat.succ k⟩ fmapEmpty fmapEmpty 0 (PrefOther "errno") (CerbMem.integerIval 4) signed_int none none)
        (CerbMem.initialMemState top) = (NDactive (errnoPtr top), σalloc top) := by
  have hsz : (CerbMem.sizeofCtype fmapEmpty fmapEmpty signed_int : Int) = 4 := by decide
  unfold CerbMem.allocateObject
  simp only [CerbMem.integerIval]
  rw [hsz]
  exact (runOne_bind_active (allocator_errno top h)).trans rfl

/-- The store of `0` through the errno pointer on `σalloc top` is ACTIVE: type-compatible,
    the record found at id 0, in bounds (the object is exactly the store), writable, not an
    atomic member access. -/
theorem storeM_errno_active (k : Nat) (top : Int) :
    (runOne (@CerbMem.storeM ⟨Nat.succ k⟩ fmapEmpty fmapEmpty (CerbLocation.other "errno init") signed_int false (errnoPtr top)
        (CerbMem.integerValueMval (Signed Int_) (CerbMem.integerIval (0 : Int)))) (σalloc top)).1
      = NDactive (.FP .W (errnoAddr top) 4) := by
  have hcompat : CerbMem.ctypeMemCompatible signed_int
      (CerbMem.typeofMval (CerbMem.integerValueMval (Signed Int_) (CerbMem.integerIval (0 : Int)))) = true := by decide
  have hget : (σalloc top).allocations.get? 0 = some (errnoAlloc top) := by
    first | rfl | decide | (simp [σalloc, CerbMem.writeBytesTo, CerbMem.initialMemState])
  have hsz : (CerbMem.sizeofCtype fmapEmpty fmapEmpty signed_int : Int) = 4 := by decide
  have hbounds : CerbMem.isInBounds (errnoAlloc top) (errnoAddr top) 4 = true := by
    simp [CerbMem.isInBounds, errnoAlloc]
  have hro : (errnoAlloc top).isReadonly = .IsWritable := rfl
  have hatomic : @CerbMem.isAtomicMemberAccess ⟨Nat.succ k⟩ fmapEmpty fmapEmpty (errnoAlloc top) signed_int (errnoAddr top) = false := rfl
  unfold CerbMem.storeM
  simp only [runOne, errnoPtr, hcompat, hget]
  simp only [hsz, hbounds, hro, hatomic, Bool.not_true, Bool.false_eq_true, if_false]

/-- The memory state after drive's whole errno action at top `top`. -/
def σstore [LemFuel] (top : Int) : CerbMem.MemState :=
  (runOne (CerbMem.storeM fmapEmpty fmapEmpty (CerbLocation.other "errno init") signed_int false (errnoPtr top)
      (CerbMem.integerValueMval (Signed Int_) (CerbMem.integerIval (0 : Int)))) (σalloc top)).2

/-- THE errno lemma: on the cold state at any top ≥ 8, drive's errno action is ACTIVE with the
    errno pointer and leaves `σstore top`. -/
theorem errnoAction_active (k : Nat) (top : Int) (h : 8 ≤ top) :
    runOne (@errnoAction ⟨Nat.succ k⟩) (CerbMem.initialMemState top) =
      (NDactive (errnoPtr top), @σstore ⟨Nat.succ k⟩ top) := by
  unfold errnoAction
  rw [runOne_bind_active (allocateObject_errno k top h)]
  dsimp only
  rw [runOne_bind_active (Prod.ext (storeM_errno_active k top) rfl)]
  rfl

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
      (CerbMem.allocateObject fmapEmpty fmapEmpty tid0 (PrefOther "errno")
        (CerbMem.integerIval 4) signed_int none none)   -- = alignofIval fmapEmpty signed_int (alignofIval_signed_int)
      (fun (ptr_val : CerbMem.PointerValue) =>
        let zero := CerbMem.integerValueMval (Signed Int_) (CerbMem.integerIval (0 : Int))
        nd_bind
          (CerbMem.storeM fmapEmpty fmapEmpty (CerbLocation.other "errno init") signed_int false ptr_val zero)
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

/-- The state after `driver_globals` (thread 0 spawned; no globals) at top `top` — the memory
    is still the cold `initialMemState top`. -/
def s₁ [LemFuel] (top : Int) (digest : String) : driver_state :=
  (runOne (driver_globals fmapEmpty fmapEmpty false exemplarFile) (dst₀ 0 top digest)).2

/-- Thread 0 at `driver2`'s entry: `main`'s arena parked, the errno pointer at top `top`, the
    spawned thread's environment (`[fmapEmpty]`, driver.lem's `driver_spawn_thread`). -/
def thS (top : Int) : thread_state :=
  { arena := mainBody, stack0 := Stack_empty, errno := errnoPtr top,
    current_loc := CerbLocation.other "Driver.drive",
    exec_loc := ELoc_normal [(mainSym, CerbLocation.other "Driver.drive")],
    env := [fmapEmpty], current_proc_opt := some mainSym }

/-- The state at `driver2`'s entry at top `top`, STATED EXPLICITLY (C4): `s₁ top digest` with the
    memory after the errno action and thread 0 updated — `drive_after_setup` CHECKS that the
    generated `drive` reaches exactly this record (its last setup `rfl`), so no hand-built
    state can drift from the pipeline. -/
def S₁ [LemFuel] (top : Int) (digest : String) : driver_state :=
  { s₁ top digest with
      layout_state := σstore top
      core_state0 := { (s₁ top digest).core_state0 with thread_states := [(0, (none, thS top))] } }

/-- The setup split at the shipped pipeline (consumer shape
    `drive_after_setup`), ambient `Nat.succ (Nat.succ k)`: the concrete
    setup prefix is discharged step by step (each `rfl` evaluates ONE
    setup bind on a concrete state, at the symbolic fuel — every fuel
    match reduces on `Nat.succ _`), leaving `driver2` at `S₁` as a
    hypothesis. -/
theorem drive_after_setup (k : Nat) (top : Int) (digest : String) (h : 8 ≤ top) (dstD : driver_state)
    (hdrv2 : runOne (@driver2 ⟨Nat.succ (Nat.succ k)⟩ fmapEmpty fmapEmpty false) (@S₁ ⟨Nat.succ (Nat.succ k)⟩ top digest)
      = (NDactive (), dstD)) :
    runOne (@drive ⟨Nat.succ (Nat.succ k)⟩ fmapEmpty fmapEmpty false exemplarFile ["cmdname"])
        (@dst₀ ⟨Nat.succ (Nat.succ k)⟩ 0 top digest)
      = (NDactive (@finalize ⟨Nat.succ (Nat.succ k)⟩ fmapEmpty fmapEmpty "drive (without concur)" dstD), dstD) := by
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
  -- errno: real allocateObject/storeM on the cold memory at the SYMBOLIC top —
  -- `errnoAction_active` (C4) under `8 ≤ top`. The alignment argument is
  -- rewritten to its value first (alignofIval_signed_int).
  rw [alignofIval_signed_int]
  refine (runOne_bind_active (z := errnoPtr top) (s' := _)
    (runOne_liftMem_active (errnoAction_active (Nat.succ k) top h))).trans ?_
  -- park main's arena (reaching EXACTLY the explicit `S₁ top digest`); driver2; finalize
  refine (runOne_bind_active (z := ()) (s' := dstD) ?_).trans ?_
  · refine (runOne_bind_active (z := ()) (s' := @S₁ ⟨Nat.succ (Nat.succ k)⟩ top digest) rfl).trans ?_
    exact hdrv2
  · refine (runOne_bind_active (z := dstD) (s' := dstD) rfl).trans ?_
    rfl

/-- The round on `S₁` at ANY ambient fuel ≥ 2: PROGRAM-DONE in one round
    (consumer shape `driver2_done`); the successor state is explicit. -/
theorem round_done (k : Nat) (top : Int) (digest : String) :
    ∃ (thF : thread_state),
      runOne (@driver2 ⟨Nat.succ (Nat.succ k)⟩ fmapEmpty fmapEmpty false) (@S₁ ⟨Nat.succ (Nat.succ k)⟩ top digest) =
        (NDactive (), { @S₁ ⟨Nat.succ (Nat.succ k)⟩ top digest with core_state0 :=
          { (@S₁ ⟨Nat.succ (Nat.succ k)⟩ top digest).core_state0 with thread_states :=
            [(0, (none, { thF with stack0 := Stack_empty, arena := mk_value_e fortyTwo }))] } }) := by
  refine ⟨_, driver2_done (Nat.succ k) fmapEmpty fmapEmpty _ _ _ _ fortyTwo rfl
    (loop_step_done k fmapEmpty fmapEmpty fmapEmpty rfl rfl) rfl⟩

/-- THE ∀-FUEL, ∀-TOP EXEMPLAR (the consumer's §6 shape), by the symbolic route:
    fuel 0 and 1 kill (the runner leaf; the first memory operation), every
    fuel ≥ 2 delivers `Specified(42)` in one round — at EVERY address-space top
    with room for the setup's errno object (`8 ≤ top`; below it the run is the
    out-of-memory kill before `main`, not covered by this statement). -/
theorem exemplar_certified_shipped_forall (fuel : Nat) (top : Int) (digest : String) (h : 8 ≤ top) :
    ∀ o ∈ run fuel top digest,
      (∃ st, o.1 = Killed st CerbND.fuelExhaustedKill) ∨ (∃ r, o.1 = Active r ∧ post r o.2.2) := by
  cases fuel with
  | zero => exact exemplar_certified_shipped_zero top digest
  | succ n =>
    cases n with
    | zero =>
      intro o ho
      exact Or.inl (exemplar_killed_at_one top digest o ho)
    | succ k =>
      obtain ⟨thF, hdrv2⟩ := round_done k top digest
      have hrun := drive_after_setup k top digest h _ hdrv2
      intro o ho
      unfold run at ho
      rw [runND_active hrun] at ho
      have h := List.mem_singleton.mp ho
      subst h
      exact Or.inr ⟨_, rfl, finalize_done fmapEmpty fmapEmpty _ _ _ fortyTwo rfl rfl⟩

end FuelExemplar

def main : IO UInt32 := do
  IO.println "FuelExemplar: exemplar_certified_shipped_forall (∀ fuel, ∀ address-space top ≥ 8, ∀ digest over the shipped `@drive ⟨fuel⟩` from `initial_driver_state _ top digest`; the consumer's §6 shape, symbolic round library + the symbolic errno lemma) — kernel-checked at compile time"
  IO.println "FuelExemplar: exemplar_certified_shipped_zero (fuel 0 → the runner's distinguished kill) — kernel-checked at compile time"
  IO.println "FuelExemplar: exemplar_killed_at_one (fuel 1 → the kill at the first memory operation; fuels ≥ 2 deliver Specified(42)) — kernel-checked at compile time"
  return 0
