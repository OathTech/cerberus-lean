-- V3a continuation probe (measurement instrument; not registered):
-- the T5 body walk under mint-first — stop points + fallback classes
-- toward the loop machinery (work-order items ii/iii/iv).
import RelSem.M1Guard
set_option autoImplicit false
set_option maxHeartbeats 2000000
set_option trace.RelSem.segRun true
set_option pp.deepTerms true
set_option pp.maxSteps 5000000
namespace RelSem.T5W
open RelSem RelSem.Cerb RelSem.CerbSt RelSem.Seg RelSem.T1 RelSem.Slate
open Iris Iris.BI Iris.ProgramLogic

def t5nSym : sym := Symbol "" 8148669997605808657 (SD_Id "n")

def t5ar0 : T1.RExpr :=
  match fmapLookupBy (fun (s1 s2 : sym) => Lem_Basic_classes.ordCompare s1 s2) sumT5Sym
      t5File.funs with
  | some (Proc _ _ _ _ e) => e
  | _ => Expr [] (Epure (Pexpr [] () (PEval Vunit)))

@[reducible] def t5Th0 (arena : T1.RExpr) (f₁ : Fmap sym value) :
    thread_state :=
  { arena := arena,
    stack0 := Stack_empty,
    errno := errPtr,
    current_loc := CerbLocation.other "RelSem.callND",
    exec_loc := ELoc_normal
      [(sumT5Sym, CerbLocation.other "RelSem.callND")],
    env := [f₁],
    current_proc_opt := some sumT5Sym }

@[reducible] def t5σ0 (f₁ : Fmap sym value)
    (tS aS eS sS : Nat) (ls : CerbMem.MemState) : driver_state :=
  { core_file := t5File,
    core_extern := create_extern_symmap t5File,
    core_state0 :=
      { thread_states := [(0, (none, t5Th0 t5ar0 f₁))],
        io := initial_io_state },
    core_run_state0 :=
      { tid_supply := tS, aid_supply := aS, excluded_supply := eS,
        sym_supply := sS,
        labeled := (initial_core_run_state_threaded 0
          (collect_labeled_continuations_NEW t5File)).labeled },
    layout_state := ls,
    concurrency_state := symInitialState symInitialPre,
    fs_state0 := CerbFS.fs_initial_state,
    trace := [],
    symbolic_assoc := fmapEmpty,
    blocked := false,
    dr_step_counter := 0 }

def t5Ctl0 : driver_state :=
  ctlOf (t5σ0 fmapEmpty 0 0 0 0 CerbMem.initialMemState)

@[reducible] def t5K : Fmap thread_id (List core_step2) → KDriveExpr :=
  fun m => KExpr.seq (ndctPick m) (fun tid_steps =>
    KExpr.seq (driver2Rest t5File.tagDefs false
        (driver2_lemFuel 999999 t5File.tagDefs) tid_steps)
      (fun _ => KExpr.seq nd_get (fun dr_st' =>
        KExpr.done (Outcome.value
          (finalize t5File.tagDefs "callND" dr_st')))))

theorem t5_walk_probe (n : Int) (seed : Nat) [CerbStGS CerbStS]
    (hn1 : 0 ≤ n) (hn2 : n ≤ 100)
    (hw1 : -2147483648 ≤ n) (hw2 : n ≤ 2147483647)
    (hclose : ∀ (Γ' : Ctx) (F : Nat),
      Ctx.interp (GF := CerbStS) Γ' ⊢
        WP (dnmsK t5File.tagDefs F fmapEmpty 0 [] t5K)
          @ Stuckness.NotStuck ; ⊤
          {{ o, ⌜o = o⌝ }}) :
    (Ctx.interp (GF := CerbStS)
      ⟨t5Ctl0, ⟨1, 0, 0, seed⟩, [(t5nSym, xPtrV)], mr2, al0,
        bs0 n⟩) ⊢
      WP (dnmsK t5File.tagDefs 1000000 fmapEmpty 0 [] t5K)
        @ Stuckness.NotStuck ; ⊤
        {{ o, ⌜o = o⌝ }} := by
  seg_run_c
  exact hclose _ _

end RelSem.T5W

open Lean Lean.Meta Lean.Elab Lean.Elab.Command in
run_cmd liftTermElabM do
  let rec normAst (fuel : Nat) (e : Lean.Expr) : Lean.MetaM Lean.Expr := do
    match fuel with
    | 0 => return e
    | fuel + 1 =>
      let e' ← match Lean.Kernel.whnf (← Lean.getEnv) (← Lean.getLCtx) e with
        | .ok r => pure r | .error _ => pure e
      let isCtorHead ←
        if e'.getAppFn.isConst then do
          pure (match (← Lean.getEnv).find? e'.getAppFn.constName! with
            | some (.ctorInfo _) => true | _ => false)
        else pure false
      if isCtorHead then
        return Lean.mkAppN e'.getAppFn (← e'.getAppArgs.mapM (normAst fuel))
      else return e'
  let env ← getEnv
  let h ← IO.FS.Handle.mk "/home/dev/projects/cerberus-lean-proj/.v3a-logs/t5s.live" .append
  for (n, ci) in env.constants.toList do
    unless (n.toString.splitOn "segCtl").length > 1 do continue
    unless n.toString.startsWith "RelSem.T5W" do continue
    let some v := ci.value? | continue
    Lean.Meta.lambdaTelescope v fun _xs body => do
      unless body.isAppOfArity ``driver_state.mk 11 do return
      let f := body.getAppArgs
      let th := f[2]!.getAppArgs[0]!.getAppArgs[1]!.getAppArgs[3]!.getAppArgs[3]!
      h.putStrLn s!"===== {n} CTR {← Lean.Meta.ppExpr (← normAst 8 f[10]!)} ====="
      h.putStrLn s!"TRACE {← Lean.Meta.ppExpr (← normAst 64 f[7]!)}"
      h.putStrLn s!"ARENA:"
      h.putStrLn (toString (← Lean.Meta.ppExpr (← normAst 200 th.getAppArgs[0]!)))
      h.flush
