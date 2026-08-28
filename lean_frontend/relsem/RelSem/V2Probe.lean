/-
  RelSem.V2Probe — V2 scratch instrument (NOT part of the build; run
  via scripts/lean_probe.sh). Round-inventory discovery for P01:
  replays the callND stage spine by app-chaining, then walks the dnms
  rounds one at a time printing (class, arena head, env keys, supplies).
  Untrusted-evaluator grade (test ledger); deleted at slice close.
-/
import RelSem.Threaded
import RelSem.CorpusFiles
import RelSem.ConstructLaws
import RelSem.PerStepCall

set_option autoImplicit false

open RelSem RelSem.Cerb RelSem.Corpus

namespace V2Probe

def tagDefs0 : Fmap sym (CerbLocation.Loc × tag_definition) := p01File.tagDefs

def symStr : sym → String
  | Symbol _ n sd =>
    match sd with
    | SD_Id name => s!"{name}#{n % 1000}"
    | _ => s!"?#{n}"

/-- Crash-loud active-app extraction. -/
def stepA {α : Type} [Inhabited α]
    (m : ndM α step_kind driver_error mem_iv_constraint driver_state)
    (σ : driver_state) : α × driver_state :=
  match app m σ with
  | (NDactive v, σ') => (v, σ')
  | (NDkilled _, σ') => panic! "probe: killed"
  | _ => panic! "probe: nondeterministic node"

def exprHead : generic_expr core_run_annotation Unit sym → String
  | Expr _ e =>
    match e with
    | Epure (Pexpr _ _ pe) =>
      match pe with
      | PEsym s => s!"Epure(PEsym {symStr s})"
      | PEval _ => "Epure(PEval _)"
      | PEcall _ _ => "Epure(PEcall …)"
      | PEcase _ _ => "Epure(PEcase …)"
      | PEif _ _ _ => "Epure(PEif …)"
      | PEop _ _ _ => "Epure(PEop …)"
      | PEctor _ _ => "Epure(PEctor …)"
      | _ => "Epure(other)"
    | Eaction (Paction _ (Action _ _ act)) =>
      match act with
      | Create _ _ _ => "Eaction(Create)"
      | Store0 _ _ _ _ _ => "Eaction(Store)"
      | Load0 _ _ _ => "Eaction(Load)"
      | Kill _ _ => "Eaction(Kill)"
      | _ => "Eaction(other)"
    | Ecase _ _ => "Ecase"
    | Eif _ _ _ => "Eif"
    | Eunseq _ => "Eunseq"
    | Ewseq _ _ _ => "Ewseq"
    | Esseq _ _ _ => "Esseq"
    | Ebound _ => "Ebound"
    | Esave _ _ _ => "Esave"
    | Erun _ _ _ => "Erun"
    | Eannot _ _ => "Eannot"
    | _ => "other-expr"

def stepClass : core_step2 → String
  | Step_ccall2 _ _ => "CCALL"
  | Step_with_runstate2 (RSK_eval d) _ => s!"RS_EVAL[{d}]"
  | Step_with_runstate2 (RSK_tau d _) _ => s!"RS_TAU[{d}]"
  | Step_tau2 d _ _ => s!"TAU[{d}]"
  | Step_action_request2 d _ _ u _ => s!"ACTION[{d},uc={u}]"
  | Step_memop_request2 _ _ _ _ _ _ => "MEMOP"
  | Step_blocked2 => "BLOCKED"
  | Step_error2 s => s!"ERROR[{s}]"
  | Step_thread_done2 _ _ => "THREAD_DONE"
  | Step_done2 _ => "DONE"
  | Step_spawn_threads2 _ _ => "SPAWN"
  | Step_fs2 _ _ _ => "FS"
  | Step_nd2 _ => "ND"

def thInfo (σ : driver_state) : String :=
  match σ.core_state0.thread_states with
  | (_, (_, th)) :: _ =>
    let envKeys := match th.env with
      | f :: _ => (fmapElements f).map (fun (p : sym × value) => symStr p.1)
      | [] => []
    s!"arena={exprHead th.arena} envTop={envKeys}"
  | [] => "NO-THREAD"

def supInfo (σ : driver_state) : String :=
  s!"sym={σ.core_run_state0.sym_supply} aid={σ.core_run_state0.aid_supply} exc={σ.core_run_state0.excluded_supply} ctr={σ.dr_step_counter} mem[next={σ.layout_state.nextAllocId},last={σ.layout_state.lastAddress}]"

partial def walkRounds (σ : driver_state) (i : Nat) (acc : List String) :
    List String × driver_state :=
  if i > 200 then ((("...OVERFLOW" : String) :: acc).reverse, σ)
  else
    let s := RelSem.Laws.stepAt tagDefs0 0 σ
    if can_advance s then
      let (_, σ') := stepA (advance_step tagDefs0 0 s) σ
      walkRounds σ' (i+1) (s!"[{i}] {stepClass s} | {thInfo σ} | {supInfo σ}" :: acc)
    else
      ((s!"[{i}] STOP class={stepClass s} | {thInfo σ} | {supInfo σ}" :: acc).reverse, σ)

def probe (x : Int) (seed : Nat) : List String := Id.run do
  let σ0 := initial_driver_state_threaded seed p01File corpusFs
  -- callK stage spine (PerStepCall.callK, transcribed)
  let (tid0, σ1) := stepA (driver_globals tagDefs0 false p01File) σ0
  let (fsym, σ2) := stepA (resolveFunSym σ1.core_file "clamp0") σ1
  let (pb, σ3) := stepA (lookupFunBody σ2.core_file fsym) σ2
  let (ptys, σ4) := stepA (lookupParamTys σ3.core_file fsym) σ3
  let (bound, σ5) := stepA (injectArgs tagDefs0 tid0 pb.1 ptys [intValue x]) σ4
  let (ths, σ6) := stepA (get_thread_states :
      ndM (List (Nat × (Option thread_id × thread_state))) step_kind
        driver_error mem_iv_constraint driver_state) σ5
  match ths with
  | [(_, (_, th_st))] =>
    let env' : List (Fmap sym value) :=
      match th_st.env with
      | [] => [Lem_Map.fromList bound]
      | xs :: xs' =>
        (List.foldl (fun (m : Fmap sym value) (pv : sym × value) =>
          fmapAddBy (fun (s1 s2 : sym) => Lem_Basic_classes.ordCompare s1 s2)
            pv.1 pv.2 m) xs bound) :: xs'
    let (errno_ptr, σ7) := stepA (liftMem (nd_bind
        (CerbMem.allocateObject tid0 (PrefOther "errno")
          (CerbMem.alignofIval signed_int) signed_int none none)
        (fun ptr_val =>
          nd_bind (CerbMem.storeM (CerbLocation.other "errno init")
              signed_int false ptr_val
              (CerbMem.integerValueMval (Signed Int_) (CerbMem.integerIval 0)))
            (fun _ => nd_return ptr_val)))) σ6
    let (_, σ8) := stepA (driver_update_thread_state tid0
      ({ arena := pb.2, stack0 := Stack_empty, errno := errno_ptr,
         current_loc := CerbLocation.other "RelSem.callND",
         exec_loc := ELoc_normal [(fsym, CerbLocation.other "RelSem.callND")],
         env := env', current_proc_opt := some fsym } : thread_state)) σ7
    let hdr := [
      s!"post-globals thread env spine: {th_st.env.length} frames, top keys: {(match th_st.env with | f :: _ => (fmapElements f).map (fun (p : sym × value) => symStr p.1) | [] => [])}",
      s!"bound = {bound.map (fun p => symStr p.1)}",
      s!"post-setup: {thInfo σ8} | {supInfo σ8}"]
    let (lines, σend) := walkRounds σ8 0 []
    let offers := RelSem.Laws.stepAt tagDefs0 0 σend
    return hdr ++ lines ++ [s!"final offered step: {stepClass offers}", s!"final: {supInfo σend}"]
  | _ => return ["probe: thread-count surprise"]

#eval do
  for l in probe (-3) 0 do IO.println l
  IO.println "==== x = 7 ===="
  for l in probe 7 0 do IO.println l

end V2Probe
