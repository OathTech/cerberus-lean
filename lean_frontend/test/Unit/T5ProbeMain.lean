-- scratch instrument (arc-9 S2): round-by-round T5 execution census.
-- Build+run: lake build t5-probe && ./.lake/build/bin/t5-probe
import RelSem.SlateFiles
import RelSem.Call

open RelSem RelSem.Cerb RelSem.Slate


def stagePost {A : Type} [Inhabited A] (m : driverM A) (σ : driver_state) :
    A × driver_state :=
  match RelSem.app m σ with
  | (NDactive v, σ') => (v, σ')
  | (NDkilled _, _) => panic! "stage killed"
  | _ => panic! "stage not active"

def showTE : trace_event → String
  | ME_load _ _ _ (CerbMem.PointerValue.PV _ (CerbMem.PointerValueBase.PVconcrete _ a)) mv =>
      s!"load@{a}=" ++ (match mv with
        | CerbMem.MemValue.MVinteger _ (CerbMem.IntegerValue.IV _ v) => toString v
        | _ => "?")
  | ME_store _ _ _ _ (CerbMem.PointerValue.PV _ (CerbMem.PointerValueBase.PVconcrete _ a)) mv =>
      s!"store@{a}=" ++ (match mv with
        | CerbMem.MemValue.MVinteger _ (CerbMem.IntegerValue.IV _ v) => toString v
        | _ => "?")
  | ME_allocate_object _ _ _ _ _ (CerbMem.PointerValue.PV _ (CerbMem.PointerValueBase.PVconcrete _ a)) =>
      s!"alloc@{a}"
  | ME_kill _ _ (CerbMem.PointerValue.PV _ (CerbMem.PointerValueBase.PVconcrete _ a)) =>
      s!"kill@{a}"
  | ME_function_return _ _ => "fret"
  | _ => "other"

def stepKindStr : core_step2 → String
  | Step_tau2 dbg _ _ => s!"tau[{dbg}]"
  | Step_with_runstate2 (RSK_eval dbg) _ => s!"rseval[{dbg}]"
  | Step_with_runstate2 (RSK_tau dbg _) _ => s!"rstau[{dbg}]"
  | Step_action_request2 dbg _ _ unseq _ => s!"action[{dbg}]{if unseq then "U" else ""}"
  | Step_done2 _ => "DONE"
  | Step_ccall2 _ _ => "ccall"
  | Step_error2 e => s!"ERR[{e}]"
  | _ => "misc"

def main : IO Unit := do
  let n : Int := 2
  let fs := CerbFS.fs_initial_state
  let σ0 := initial_driver_state t5File fs
  -- callND stages (mirrors RelSem/Call.lean callND exactly)
  let (tid0, σ1) := stagePost (driver_globals t5File.tagDefs false t5File) σ0
  let (dr1, _) := stagePost nd_get σ1
  let (fsym, σ2) := stagePost (resolveFunSym dr1.core_file "sum") σ1
  let (pb, σ3) := stagePost (lookupFunBody dr1.core_file fsym) σ2
  let (ptys, σ4) := stagePost (lookupParamTys dr1.core_file fsym) σ3
  let (bound, σ5) := stagePost (injectArgs t5File.tagDefs tid0 pb.1 ptys [intValue n]) σ4
  -- callFinish prefix: get_thread_states, errno, update_thread_state
  let (ths, σ6) := stagePost get_thread_states σ5
  let th_st := (ths.head!).2.2
  let env' : List (Fmap sym value) :=
    match th_st.env with
    | [] => [Lem_Map.fromList bound]
    | xs :: xs' =>
      (List.foldl (fun (m : Fmap sym value) (pv : sym × value) =>
        fmapAddBy (fun (s1 s2 : sym) => Lem_Basic_classes.ordCompare s1 s2)
          pv.1 pv.2 m) xs bound) :: xs'
  let (errnoPtr, σ7) := stagePost (liftMem (nd_bind
      (CerbMem.allocateObject tid0 (PrefOther "errno")
        (CerbMem.alignofIval signed_int) signed_int none none)
      (fun (ptr_val : CerbMem.PointerValue) =>
        let zero := CerbMem.integerValueMval (Signed Int_)
          (CerbMem.integerIval (0 : Int))
        nd_bind
          (CerbMem.storeM (CerbLocation.other "errno init")
            signed_int false ptr_val zero)
          (fun (_ : CerbMem.Footprint) => nd_return ptr_val)))) σ6
  let (_, σ8) := stagePost (driver_update_thread_state tid0
    ({ arena := pb.2, stack0 := Stack_empty, errno := errnoPtr,
       current_loc := CerbLocation.other "RelSem.callND",
       exec_loc := ELoc_normal [(fsym, CerbLocation.other "RelSem.callND")],
       env := env', current_proc_opt := some fsym } : thread_state)) σ7
  IO.println s!"=== post-prefix: aid={σ8.core_run_state0.aid_supply} ctr={σ8.dr_step_counter} nextAlloc={σ8.layout_state.nextAllocId} lastAddr={σ8.layout_state.lastAddress}"
  IO.println s!"bound: {bound.length} binding(s)"
  for (s', v) in bound do
    IO.println s!"  {show_symbol s'} := {match v with | Vobject (OVpointer (CerbMem.PointerValue.PV _ (CerbMem.PointerValueBase.PVconcrete _ a))) => s!"ptr@{a}" | _ => "?"}"
  -- dnms rounds
  let mut σ := σ8
  let mut round := 0
  let mut done := false
  let mut heads : Array driver_state := #[]
  while !done && round < 250 do
    let th_info :=
      match Lem_List.lookupBy (fun x y => x == y) 0 σ.core_state0.thread_states with
      | some z => z
      | none => panic! "no tid0"
    let steps := step_ctx t5File.tagDefs σ.layout_state σ.core_file
      σ.core_extern 0 th_info
    match find_can_advance steps with
    | none =>
      IO.println s!"R{round}: TERMINAL steps={steps.map stepKindStr}"
      done := true
    | some step1 =>
      let (a, σ') := RelSem.app (advance_step t5File.tagDefs 0 step1) σ
      match a with
      | NDactive NOWAKEUP =>
        let aidD := σ'.core_run_state0.aid_supply - σ.core_run_state0.aid_supply
        let _ := aidD
        if (match step1 with
            | Step_with_runstate2 (RSK_eval dbg) _ => dbg == "Erun"
            | _ => false) then
          heads := heads.push σ'
        σ := σ'
      | _ => IO.println s!"R{round}: NON-ACTIVE advance"; done := true
      round := round + 1
  -- loop-head comparisons (post-Erun states)
  IO.println s!"=== end: rounds={round} aid={σ.core_run_state0.aid_supply} ctr={σ.dr_step_counter}"
  IO.println s!"Erun-post states captured: {heads.size}"
  if h2 : heads.size ≥ 2 then
    let a := heads[0]!
    let b := heads[1]!
    let tha := (Lem_List.lookupBy (fun x y => x == y) 0 a.core_state0.thread_states).get!.2
    let thb := (Lem_List.lookupBy (fun x y => x == y) 0 b.core_state0.thread_states).get!.2
    IO.println s!"loop-head arena equal (iter1 vs iter2): SKIP(BEq sorried)"
    IO.println s!"env depth: {tha.env.length} vs {thb.env.length}"
    let ea := tha.env.head!
    let eb := thb.env.head!
    let doma := (fmapDomainBy (fun (s1 s2 : sym) => Lem_Basic_classes.ordCompare s1 s2) ea)
    let domb := (fmapDomainBy (fun (s1 s2 : sym) => Lem_Basic_classes.ordCompare s1 s2) eb)
    let la := setToList doma
    let lb := setToList domb
    IO.println s!"env dom sizes: {la.length} vs {lb.length}"
    IO.println s!"iter1 env dom: {la.map show_symbol}"
    IO.println s!"iter2 env dom: {lb.map show_symbol}"
    -- which values differ
    for k in lb do
      let va := fmapLookupBy (fun (s1 s2 : sym) => Lem_Basic_classes.ordCompare s1 s2) k ea
      let vb := fmapLookupBy (fun (s1 s2 : sym) => Lem_Basic_classes.ordCompare s1 s2) k eb
      let eqs := match va, vb with
        | some x, some y => if x == y then "same" else "DIFF"
        | none, some _ => "NEW"
        | _, _ => "?"
      IO.println s!"  {show_symbol k}: {eqs}"
    IO.println s!"rs: aid {a.core_run_state0.aid_supply}/{b.core_run_state0.aid_supply} tid {a.core_run_state0.tid_supply}/{b.core_run_state0.tid_supply} sym {match a.core_run_state0.sym_supply, b.core_run_state0.sym_supply with | _, _ => "?"}"
    IO.println s!"ctr {a.dr_step_counter}/{b.dr_step_counter} trace {a.trace.length}/{b.trace.length}"
    IO.println s!"stack same: {tha.stack0 == thb.stack0} errno same: {tha.errno == thb.errno} exec_loc same: {tha.exec_loc == thb.exec_loc} cur_proc same: {tha.current_proc_opt == thb.current_proc_opt}"
where
  th_stArena (σ : driver_state) : generic_expr core_run_annotation Unit sym :=
    match Lem_List.lookupBy (fun x y => x == y) 0 σ.core_state0.thread_states with
    | some (_, th) => th.arena
    | none => panic! "gone"
