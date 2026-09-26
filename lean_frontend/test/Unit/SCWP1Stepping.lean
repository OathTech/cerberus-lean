import Unit.SCWP1SteppingProofs
import Unit.MemoryAccess

namespace SCWP1Stepping
open CerbMem Lem_Pervasives Lem_Basic_classes

def loc := CerbLocation.Loc.other "wp1-stepping"
def mainSym : sym := Symbol "wp1" 1 (SD_Id "main")
def loopSym : sym := Symbol "wp1" 2 (SD_Id "loop")
def globSym : sym := Symbol "wp1" 3 (SD_Id "global")
def spinSym : sym := Symbol "wp1" 4 (SD_Id "spin")
def iv := IntegerValue.IV .Prov_none
def answer : value := Vloaded (LVspecified (OVinteger (iv 42)))
def done : expr core_run_annotation := mk_value_e answer
def loop : expr core_run_annotation := Expr [] (Esave (loopSym, (BTy_loaded OTy_integer)) []
  (Expr [] (Erun empty_annotation loopSym [])))
def bounds : Nat → expr core_run_annotation
  | 0 => done
  | n + 1 => Expr [] (Ebound (bounds n))
def symMap {a : Type} (xs : List (sym × a)) : Fmap sym a :=
  xs.foldl (fun m (k, v) => fmapAddBy ordCompare k v m) fmapEmpty
def fileFor (body : expr core_run_annotation) : file core_run_annotation :=
  { main := some mainSym, calling_convention0 := default,
    tagDefs := fmapEmpty, enumDefs := fmapEmpty, stdlib := fmapEmpty,
    impl0 := fmapEmpty, globs := [],
    funs := symMap [(mainSym, Proc loc none (BTy_loaded OTy_integer) [] body)],
    extern := fmapEmpty, funinfo := fmapEmpty, loop_attributes1 := fmapEmpty,
    visible_objects_env0 := fmapEmpty }
def initial (f : file core_run_annotation) : driver_state :=
  (initial_driver_state 5 65536 "wp1-stepping" f CerbFS.fs_initial_state).1
def start [LemFuel] (f : file core_run_annotation) : experiment_config :=
  let st := initial f
  experiment_start fmapEmpty fmapEmpty f []
    { st with layout_state := { st.layout_state with observations := some [] } }
def step [LemFuel] := experiment_step fmapEmpty fmapEmpty
def run [LemFuel] := experiment_run fmapEmpty fmapEmpty
def bounded [LemFuel] := experiment_bounded fmapEmpty fmapEmpty
def require := MemoryAccess.require
def evalND {a i e cs s : Type} (m : ndM a i e cs s) (st : s) :=
  match m with | .ND f => f st
def th (arena : expr core_run_annotation) : thread_state :=
  { (default : thread_state) with arena := arena, stack0 := Stack_empty, env := [fmapEmpty] }
def coreConfig (st : driver_state) : experiment_config :=
  ⟨Exp_core (nd_return default), st, 0⟩
def storeArena (p : PointerValue) : expr core_run_annotation :=
  Expr [] (Eaction (Paction Pos (Action loc default
    (Store0 false (mk_value_pe (Vctype unsigned_char))
      (mk_value_pe (Vobject (OVpointer p)))
      (mk_value_pe (Vobject (OVinteger (iv 42)))) NA))))
def loadArena (p : PointerValue) : expr core_run_annotation :=
  Expr [] (Eaction (Paction Pos (Action loc default
    (Load0 (mk_value_pe (Vctype unsigned_char))
      (mk_value_pe (Vobject (OVpointer p))) NA))))
def receiptCount (st : driver_state) : Nat :=
  st.layout_state.observations.getD [] |>.length

def check [LemFuel] : IO Unit := do
  let cold := start (fileFor (bounds 3))
  let .Exp_incomplete untouched := bounded [] cold
    | throw (IO.userError "zero budget was not incomplete")
  require (untouched.experiment_steps == 0 && receiptCount untouched.experiment_state == 0 &&
    untouched.experiment_state.core_state0.thread_states.isEmpty) "zero budget executed startup"
  let (entered, _) := run [0] cold
  require (match entered.experiment_phase0 with | .Exp_core _ => true | _ => false) "lost main continuation"
  require (entered.experiment_steps == 1 && receiptCount entered.experiment_state == 1)
    "startup did not execute exactly the errno initialization segment"
  let .Exp_stopped finished unused := bounded (List.replicate 10 0) cold
    | throw (IO.userError "finite program did not finish")
  require (match finished.experiment_phase0 with | .Exp_done r => r.dres_core_value == answer | _ => false)
    "finalization lost main value"
  require (finished.experiment_steps == 6 && unused.length == 4 &&
    finished.experiment_state.dr_step_counter == 3) "finite budget accounting"
  IO.println "lifecycle: zero budget passive; main entered; 3 tau steps; finalized 42; 4 choices unused"

  -- Erun resolves the label collected by the actual cold-start constructor.
  -- Thousands of scheduler steps at the same small per-call fuel must work.
  for budget in [1, 2, 7, 4096] do
    let .Exp_incomplete cfg := bounded (List.replicate budget 0) (start (fileFor loop))
      | throw (IO.userError s!"loop failed to yield at scheduler budget {budget}")
    require (cfg.experiment_steps == budget && experiment_choice_count cfg == 1)
      "loop budget or singleton discovery"
    require (cfg.experiment_state.dr_step_counter == budget - 1 && receiptCount cfg.experiment_state == 1)
      "loop did not take one Core reduction per remaining entry"
  IO.println "singleton Core loop: incomplete at 1, 2, 7, 4096 steps; call fuel does not count loop iterations"

  let f := fileFor done
  let gf := { f with globs := [(globSym, GlobalDef ((BTy_loaded OTy_integer), signed_int) (bounds 2))] }
  let .Exp_incomplete inGlobal := bounded [0] (start gf)
    | throw (IO.userError "global startup failed")
  require (receiptCount inGlobal.experiment_state == 0) "main errno initialized before global completed"
  let .Exp_stopped globalDone globalUnused := bounded (List.replicate 20 0) (start gf)
    | throw (IO.userError "global continuation failed")
  require (match globalDone.experiment_phase0 with | .Exp_done r => r.dres_core_value == answer | _ => false)
    "global program did not finalize with the main value"
  require (globalDone.experiment_steps == 7 && globalUnused.length == 13 &&
    receiptCount globalDone.experiment_state == 1) "global/main/finalization continuation budget"
  let globalEnv := globalDone.experiment_state.core_state0.thread_states.head?.map (fun t => t.2.2.env)
  require (match globalEnv with | some (env :: _) => fmapLookupBy ordCompare globSym env == some answer | _ => false)
    "global value was not published into main environment"
  let spinFile := { f with
    funs := symMap [(mainSym, Proc loc none (BTy_loaded OTy_integer) [] done), (spinSym, Proc loc none (BTy_loaded OTy_integer) [] loop)],
    globs := [(globSym, GlobalDef ((BTy_loaded OTy_integer), signed_int) (Expr [] (Eproc empty_annotation (Sym spinSym) [])))] }
  let .Exp_incomplete spinningGlobal := bounded (List.replicate 100 0) (start spinFile)
    | throw (IO.userError "nonterminating global did not yield")
  require (spinningGlobal.experiment_steps == 100 && receiptCount spinningGlobal.experiment_state == 0)
    "nonterminating global entered main"
  IO.println "globals: suspended before main; environment retained; looping initializer incomplete at 100"

  let (.NDactive p, mem) := evalND (allocateRegion 0 (PrefOther "wp1") (iv 1) (iv 1))
      (initialMemState 65536) | throw (IO.userError "allocation fixture")
  let (.NDactive _, mem) := evalND
      (storeM fmapEmpty fmapEmpty loc unsigned_char false p (.MVinteger (.Unsigned .Ichar) (iv 0))) mem
    | throw (IO.userError "store fixture")
  let st := { initial f with layout_state := { mem with observations := some [] } }
  -- A malformed Erun would panic inside step_ctx_at. Pure discovery and
  -- selecting the other thread must not interpret it (LEAN_ABORT_ON_PANIC=1).
  let bad := Expr [] (Erun empty_annotation loopSym [])
  let st := { st with core_state0 := { st.core_state0 with thread_states :=
    [(0, (none, th (storeArena p))), (1, (none, th bad))] } }
  let cfg := coreConfig st
  require (experiment_choice_count cfg == 2 && receiptCount cfg.experiment_state == 0) "effectful discovery"
  let stored := step 0 cfg
  require (receiptCount stored.experiment_state == 1) "selected store missing receipt"
  let (.NDactive (_, .MVinteger _ (.IV _ n)), _) := evalND
      (loadM fmapEmpty fmapEmpty loc unsigned_char p) (stopObserving stored.experiment_state.layout_state)
    | throw (IO.userError "readback failed")
  require (n == 42) "selected store missing memory write"
  IO.println "discovery: two contexts; unchosen faulty Erun untouched; selected store writes 42 once"

  -- A real Core null load is killed with its actual reason, not treated as
  -- empty discovery, done, blocked, or unsupported.
  let nullSt := { st with core_state0 := { st.core_state0 with thread_states :=
    [(0, (none, th (loadArena (nullPtrval unsigned_char))))] } }
  let killed := step 0 (coreConfig nullSt)
  require (match killed.experiment_phase0 with
    | .Exp_killed (.Undef0 _ [.UB019_lvalue_not_an_object]) => true | _ => false) "null load lost UB"
  let waiting := { st with core_state0 := { st.core_state0 with thread_states :=
    [(0, (none, th (Expr [] (Ewait 99))))] } }
  let empty := { st with core_state0 := { st.core_state0 with thread_states := [] } }
  require (match (step 0 (coreConfig waiting)).experiment_phase0 with | .Exp_blocked => true | _ => false)
    "blocked conflated with done"
  require (match (step 0 (coreConfig empty)).experiment_phase0 with | .Exp_empty => true | _ => false)
    "empty conflated with done"
  require (match (step 2 cfg).experiment_phase0 with | .Exp_bad_choice => true | _ => false)
    "invalid index accepted"
  IO.println "outcomes: UB, blocked, empty, invalid choice, done and incomplete distinguished"

  let act := SeqRMW false (mk_value_pe (Vctype unsigned_char))
    (mk_value_pe (Vobject (OVpointer p))) globSym (mk_value_pe (Vobject (OVinteger (iv 1))))
  let rmw := Expr [] (Ebound (Expr [] (Eaction (Paction Pos (Action loc default act)))))
  let rmwSt := { st with core_state0 := { st.core_state0 with thread_states := [(0, (none, th rmw))] } }
  let refused := step 0 (coreConfig rmwSt)
  require (match refused.experiment_phase0 with | .Exp_unsupported _ => true | _ => false)
    "SeqRMW silently executed as atomic"
  require (receiptCount refused.experiment_state == 0 && MemoryAccess.stateEq
    refused.experiment_state.layout_state st.layout_state) "refused SeqRMW accessed memory"
  IO.println "SeqRMW: explicitly unsupported; no load/store performed"

def checkAt (fuel : Nat) : IO Unit :=
  letI := LemFuel.mk fuel
  do
    IO.println s!"generated-call fuel {fuel}"
    check

#eval checkAt 64
#eval checkAt 128

def checkFuelZero (fuel : Nat) : IO Unit :=
  letI := LemFuel.mk fuel
  do
    let stopped := step 0 (start (fileFor done))
    require (match stopped.experiment_phase0 with
      | .Exp_killed (.Error0 l msg) => l == CerbFuel.fuelExhaustedLoc && msg == CerbFuel.fuelExhaustedMsg
      | _ => false) "call-fuel exhaustion conflated with scheduler exhaustion"
    IO.println "zero call fuel: explicit fuel failure, not incomplete"

#eval checkFuelZero 0

end SCWP1Stepping
