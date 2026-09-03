/-
  Concrete nondeterminism monad runner.
  Corresponds to: ocaml_frontend/smt2.ml (runND with concrete memory model)

  This runner implements exhaustive evaluation of all nondeterministic
  branches, with NO constraint tracking: NDguard always continues and
  NDbranch explores both sides. NOTE this is a divergence from OCaml,
  where guards/branches go through `with_constraints ... check_sat` and
  the CONCRETE model's cs_module (impl_mem.ml:321-361) really does
  evaluate the accumulated constraints (its `with_constraints` runs
  `eval_cs` over MC_eq/MC_le/MC_lt/... and `check_sat` reports UNSAT if
  any constraint evaluated false, pruning that branch). Constraints are
  NOT trivially satisfiable in the concrete model; pruning is simply not
  implemented here yet (recorded divergence — survey finding 23).

  Symbolic execution is NOT supported.

  TOTALIZED (arc-7 S2, 2026-08-19 — the operator's Q1 AMENDED ruling;
  its record is parked: tag park/reasoning-era-20260831,
  lean_frontend/docs/2026-08-19_relsem-spike.md): the former `partial def runND`/
  `runND1` are now fuel-totalized workers (`runNDFuel`/`runND1Fuel`,
  arc-3 wrapper pattern) with default-fuel wrappers keeping the caller
  signature unchanged. `partial` had made the production runner opaque
  to the kernel (no equations — the arc-3 pathology at the top of the
  stack); with fuel, the runner has kernel equations, so any downstream
  theorem about it is stated against THIS code — the executable and the
  proof object are the same artifact. (The reasoning-era soundness
  theorem that first used this is parked: tag
  park/reasoning-era-20260831; check_exec_totality.sh keeps this file
  partial-free regardless.)

  EXHAUSTION OUTCOME (FUEL arc, 2026-09-03 — docs/2026-09-02_fuel-arc-design.md,
  Option C [USER 2026-09-02]; Q3 runner leaf RULED + consumer-ACKed):
  the fuel-0 leaf of every runner is the DISTINGUISHED kernel-transparent
  kill `[(Killed st0 fuelExhaustedKill, [], st0)]` — the same value the
  nine ND-typed fueled workers return at fuel 0 (`nd_bind`, `liftND`,
  `liftAction`, `print_eval_conv_aux`, `drive_nonmemory_steps_aux2`,
  `driver2`, `find_array_index`, `easy_update_mem_value_aux`,
  `memcmp_load_aux`), so a ∀-fuel statement over `runND` is not vacuous
  past the runner's own depth budget: exhaustion at EITHER fuel is the
  one left disjunct `∃ st, o.1 = Killed st fuelExhaustedKill`. It replaced
  the arc-7 S2 `panic!`-returning-`[]` marker (proof-transparent `= []`,
  which claimed no behaviours but made theorems past the budget vacuous;
  the reasoning-era soundness theorem stated against that `[]` leaf was
  retired by the 2026-09-02 RelSem prune). Loudness is preserved at the
  HARNESS level: Main prints the kill as `Error {msg: "lem: fuel
  exhausted"}` (exit 1) and every classifying lane assigns FUEL (fail-
  noisy, never agreement — scripts/common.sh classify_fuel_outcome);
  nothing becomes quieter. `fuelExhaustedKill = Error0 fuelExhaustedLoc
  fuelExhaustedMsg` with `fuelExhaustedLoc` a pure OPAQUE (CerbFuel.lean,
  census-pinned): every proof is uniform in the atom, so no distinctness
  lemma is needed (design note §1.3) and none ships.

  BUDGET: `ndDefaultFuel := CerbFuel.driverFuel` — the runner is a member
  of the coupled driver family (design note §4; the C1 manifest §8
  coupling analysis: the trees this runner walks are built by `nd_bind`'s
  own fuel, so the family moves together). Fuel counts ND-TREE DEPTH.
  `runND_eq` pins the wrapper to the worker at `driverFuel` by rfl.
-/

import Nondeterminism
import Defacto_memory
import Driver
import CerbFuel

set_option autoImplicit true

namespace CerbND

export CerbFuel (fuelExhaustedLoc fuelExhaustedMsg driverFuel)

/-- The distinguished fuel-exhaustion kill (design note §1.1).
    `'err`-polymorphic: it never mentions the error type, so it is the same
    value in `driverM` (`kill_reason driver_error`) and `impl_memM`
    (`kill_reason mem_error`). One delta step on a plain `def` away from
    the generated arms' spelling `Error0 CerbFuel.fuelExhaustedLoc
    CerbFuel.fuelExhaustedMsg` (the generated Nondeterminism.lean defines
    `kill_reason`, so no seam it imports can name this constant); the
    `_zero` lemmas below close that gap by `rfl`. -/
def fuelExhaustedKill {err : Type} : kill_reason err :=
  Error0 CerbFuel.fuelExhaustedLoc CerbFuel.fuelExhaustedMsg

/-- Default ND-tree depth budget for the production runners (see BUDGET in
    the file header: the coupled driver family's `CerbFuel.driverFuel`). -/
def ndDefaultFuel : Nat := CerbFuel.driverFuel

/-- Fuel-totalized exhaustive runner (worker; callers use `runND`).
    Runs the nondeterminism monad exhaustively with the concrete memory
    model, returning a list of (status, trace_strings, final_state)
    triples. Corresponds to: Smt2.runND Exhaustive Impl_mem.cs_module.
    Fuel bounds tree DEPTH; the fuel-0 leaf is the distinguished
    fuel-exhaustion kill (file header).

    Result ORDER matters (the harness compares the first verdict):
    OCaml's exhaustive NDnd case (smt2.ml:75-82) is
      `foldlM (fun acc (idx, (info, m_act)) ->
         aux m_act st' >>= fun z -> return (z @ acc)) []`
    i.e. each branch's results are PREPENDED to the accumulator, yielding
    R_n ++ ... ++ R_1 (last branch's results first). We mirror that
    exactly. NDstep (smt2.ml:134-138) delegates to the NDnd case, so it
    gets the same order. NDbranch's exhaustive case (smt2.ml:117-132)
    returns `xs1 @ xs2` (in-order), mirrored below. -/
def runNDFuel (fuel : Nat)
    (m : ndM a info err cs st) (st0 : st) :
    List (nd_status a err st × List String × st) :=
  match fuel with
  | 0 =>
    -- Exhaustion: the distinguished kill (file header; `runNDFuel_zero`).
    [(Killed st0 fuelExhaustedKill, [], st0)]
  | fuel + 1 =>
    match m with
    | ND m_act =>
      match m_act st0 with
      | (NDactive result, st') =>
        [(Active result, [], st')]

      | (NDkilled reason, st') =>
        [(Killed st' reason, [], st')]

      | (NDnd _info branches, st') =>
        -- Exhaustive: explore ALL branches; prepend each branch's results
        -- (mirrors smt2.ml:75-82 `return (z @ acc)` — R_n ++ ... ++ R_1)
        branches.foldl (fun acc (_, branch) =>
          runNDFuel fuel branch st' ++ acc
        ) []

      | (NDguard _info _constraint continuation, st') =>
        -- DIVERGENCE: no constraint pruning (OCaml would eval the constraint
        -- via the concrete cs_module, impl_mem.ml:321-361, and backtrack on
        -- UNSAT); we always continue.
        runNDFuel fuel continuation st'

      | (NDbranch _info _constraint left right, st') =>
        -- Both sides explored, left-then-right (mirrors smt2.ml:117-132
        -- `xs1 @ xs2`); same no-pruning divergence as NDguard.
        runNDFuel fuel left st' ++ runNDFuel fuel right st'

      | (NDstep _info branches, st') =>
        -- OCaml re-dispatches NDstep to the NDnd case (smt2.ml:134-138):
        -- same prepend accumulation order.
        branches.foldl (fun acc (_, branch) =>
          runNDFuel fuel branch st' ++ acc
        ) []

/-- THE production exhaustive runner (arc-3 wrapper pattern: defeq to the
    worker at the default budget, so proofs against `runNDFuel` transfer
    by `rfl`). Signature unchanged from the retired `partial` form. -/
def runND (m : ndM a info err cs st) (st0 : st) :
    List (nd_status a err st × List String × st) :=
  runNDFuel ndDefaultFuel m st0

/-- Fuel-totalized single-trace runner (worker; callers use `runND1`):
    follow exactly ONE branch at every nondeterminism point, yielding at
    most one execution. Same exhaustion kill/budget as `runNDFuel`.

    OCaml counterpart: `Smt2.runND Random` (smt2.ml:23-31 `with_backtracking`
    + the Random cases at smt2.ml:67-68/108-115), which picks ONE branch via
    `Random.int` — and that PRNG is TIME-SEEDED PER RUN, not default-seeded
    [corrected per arc-5 audits]: util/cerb_any.ml:1 runs `Random.self_init`
    at module load (`Cerb_any.bounded_integer` is linked into the driver via
    generated core_run.ml:1099), and driver_ocaml.ml:153/190 call
    `Random.self_init` again in batch_drive/drive. The OCaml oracle's branch
    choices may therefore differ from run to run.

    DELIBERATE DIVERGENCE (trace selection only): we always pick branch
    INDEX 0 (and the left/positive side of NDbranch) instead of mirroring
    OCaml's PRNG stream. Both selections are members of the same exhaustive
    trace set explored by `runND` above; a differential harness comparing a
    single-trace run against OCaml `--mode=random` is therefore comparing
    two (possibly different, and on the OCaml side run-varying) traces of
    the same program — sound only for programs whose observable verdict is
    trace-independent (e.g. the chvalid battery of scripts/test_libxml2.sh,
    which is PURE: empirically all 175 exhaustive executions of the probe
    program produced identical verdicts). The differential is sound because
    the battery is pure, NOT because the oracle is deterministic. Any
    disagreement is a real signal: either a semantic defect or observable
    trace-sensitivity, both of which require classification.

    `--first` naming note: this runner (surfaced as `cerberus-lean --first`)
    returns branch-index-0's trace, which equals the LAST execution of the
    exhaustive list (`runND` mirrors OCaml's PREPEND accumulation order) —
    it is NOT exhaustive's EXECUTION 0.

    Same no-constraint-pruning divergence as `runND` (survey finding 23):
    NDguard always continues, NDbranch takes the positive side without a
    `check_sat` (OCaml Random evaluates constraints and can return [] with
    its backtracking commented out, smt2.ml:26-34). Empty NDnd/NDstep
    branch lists yield [] (OCaml `Random.int 0` would raise — the driver
    reports zero executions either way). -/
def runND1Fuel (fuel : Nat)
    (m : ndM a info err cs st) (st0 : st) :
    List (nd_status a err st × List String × st) :=
  match fuel with
  | 0 =>
    -- Exhaustion: the distinguished kill (file header; `runND1Fuel_zero`).
    [(Killed st0 fuelExhaustedKill, [], st0)]
  | fuel + 1 =>
    match m with
    | ND m_act =>
      match m_act st0 with
      | (NDactive result, st') =>
        [(Active result, [], st')]

      | (NDkilled reason, st') =>
        [(Killed st' reason, [], st')]

      | (NDnd _info branches, st') =>
        match branches with
        | [] => []
        | (_, branch) :: _ => runND1Fuel fuel branch st'

      | (NDguard _info _constraint continuation, st') =>
        runND1Fuel fuel continuation st'

      | (NDbranch _info _constraint left _right, st') =>
        runND1Fuel fuel left st'

      | (NDstep _info branches, st') =>
        match branches with
        | [] => []
        | (_, branch) :: _ => runND1Fuel fuel branch st'

/-- Single-trace runner (arc-5 S3 seam; `--first`). Wrapper at the
    default budget, signature unchanged from the retired `partial` form. -/
def runND1 (m : ndM a info err cs st) (st0 : st) :
    List (nd_status a err st × List String × st) :=
  runND1Fuel ndDefaultFuel m st0

/-- Node-kind trace runner (arc-7 S3 instrumentation; surfaced as
    `cerberus-lean --trace-nodes`): follows exactly the branch-0 trace of
    `runND1Fuel` above, additionally returning the LABEL of every ND-tree
    node crossed — constructor kind, `info` (via the caller's printer,
    the runner is `info`-generic), and branch count where applicable.
    Instrumentation only, never a proof object and never on a harness's
    verdict path: its role is the Step-coverage-BY-NEED evidence (which
    node kinds a given fixture's driver-level execution traverses).
    Same fuel discipline and exhaustion kill as the production
    runners. -/
def runND1TraceFuel (showInfo : info → String) (fuel : Nat)
    (m : ndM a info err cs st) (st0 : st) :
    List String × List (nd_status a err st × List String × st) :=
  match fuel with
  | 0 =>
    -- Exhaustion: the distinguished kill, no node label (file header;
    -- `runND1TraceFuel_zero`).
    ([], [(Killed st0 fuelExhaustedKill, [], st0)])
  | fuel + 1 =>
    match m with
    | ND m_act =>
      match m_act st0 with
      | (NDactive result, st') =>
        (["NDactive"], [(Active result, [], st')])
      | (NDkilled _reason, st') =>
        (["NDkilled"], [(Killed st' _reason, [], st')])
      | (NDnd info branches, st') =>
        let label := s!"NDnd[{showInfo info}] |branches|={branches.length}"
        match branches with
        | [] => ([label], [])
        | (_, branch) :: _ =>
          let (labels, execs) := runND1TraceFuel showInfo fuel branch st'
          (label :: labels, execs)
      | (NDguard info _constraint continuation, st') =>
        let (labels, execs) := runND1TraceFuel showInfo fuel continuation st'
        (s!"NDguard[{showInfo info}]" :: labels, execs)
      | (NDbranch info _constraint left _right, st') =>
        let (labels, execs) := runND1TraceFuel showInfo fuel left st'
        (s!"NDbranch[{showInfo info}]" :: labels, execs)
      | (NDstep info branches, st') =>
        let label := s!"NDstep[{showInfo info}] |branches|={branches.length}"
        match branches with
        | [] => ([label], [])
        | (_, branch) :: _ =>
          let (labels, execs) := runND1TraceFuel showInfo fuel branch st'
          (label :: labels, execs)

/-- Trace-runner wrapper at the default budget. -/
def runND1Trace (showInfo : info → String) (m : ndM a info err cs st)
    (st0 : st) :
    List String × List (nd_status a err st × List String × st) :=
  runND1TraceFuel showInfo ndDefaultFuel m st0

/-! ## The customer contract (design note §1; consumer: refined-cerberus)

Every statement below is kernel-checked by `rfl`, FULLY APPLIED against
the generated signatures (binder names = the generated ones, e.g. the
reader argument `_lemReader_tagDefs`, `n`/`f1` for `nd_bind`, `get2`/
`put1` for the lifts). They are the citable form of the nine generated
fuel-zero arms, the three runner leaves, and the wrapper/budget pins.
Any drift in the generated text — a renamed binder, an arity change, a
moved `_lemFuel` worker, a regenerated `drive` body — fails THIS file's
build (the consumer's requirement R2: our build is the pinned-lemma
gate). -/

section FuelContract

/-! ### The nine ND-typed worker arms (design note §1.2) -/

theorem nd_bind_lemFuel_zero {a b c d e f : Type}
    (n : ndM f b d a c) (f1 : f → ndM e b d a c) :
    nd_bind_lemFuel 0 n f1 = ND (fun st => (NDkilled fuelExhaustedKill, st)) := rfl

theorem liftND_lemFuel_zero {a cs err1 err2 info1 info2 st1 st2 : Type}
    (get2 : st2 → st1) (put1 : st2 → st1 → st2) (liftInfo : info1 → info2)
    (liftErr : err1 → err2) (n : ndM a info1 err1 cs st1) :
    liftND_lemFuel 0 get2 put1 liftInfo liftErr n
      = ND (fun st => (NDkilled fuelExhaustedKill, st)) := rfl

/-- NOTE (design note Q2): the fuel-0 arm DISCARDS the incoming action —
    including a genuine kill it was lifting — and reports exhaustion; the
    lift did not complete, and the shape is what the type forces. -/
theorem liftAction_lemFuel_zero {a cs err1 err2 info1 info2 st1 st2 : Type}
    (get2 : st2 → st1) (put1 : st2 → st1 → st2) (liftInfo : info1 → info2)
    (liftErr : err1 → err2) (act : nd_action a info1 err1 cs st1) :
    liftAction_lemFuel 0 get2 put1 liftInfo liftErr act = NDkilled fuelExhaustedKill := rfl

theorem print_eval_conv_aux_lemFuel_zero
    (_lemReader_tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (dr_st : driver_state) (th_st : thread_state) (pe : generic_pexpr Unit sym) :
    print_eval_conv_aux_lemFuel 0 _lemReader_tagDefs dr_st th_st pe
      = ND (fun st => (NDkilled fuelExhaustedKill, st)) := rfl

theorem drive_nonmemory_steps_aux2_lemFuel_zero
    (_lemReader_tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (acc : Fmap thread_id (List core_step2)) (xs : List Nat) :
    drive_nonmemory_steps_aux2_lemFuel 0 _lemReader_tagDefs acc xs
      = ND (fun st => (NDkilled fuelExhaustedKill, st)) := rfl

theorem driver2_lemFuel_zero
    (_lemReader_tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (with_concurrency : Bool) :
    driver2_lemFuel 0 _lemReader_tagDefs with_concurrency
      = ND (fun st => (NDkilled fuelExhaustedKill, st)) := rfl

theorem find_array_index_lemFuel_zero (size : Nat) (i : Nat) (ival_ : integer_value_base) :
    find_array_index_lemFuel 0 size i ival_
      = ND (fun st => (NDkilled fuelExhaustedKill, st)) := rfl

theorem easy_update_mem_value_aux_lemFuel_zero
    (_lemReader_tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (loc1 : CerbLocation.Loc) (is_strong : Bool) (write_ty : ctype)
    (sh : List shift_path_element) (write_mval : impl_mem_value)
    (current_mval : impl_mem_value) :
    easy_update_mem_value_aux_lemFuel 0 _lemReader_tagDefs loc1 is_strong write_ty sh
        write_mval current_mval
      = ND (fun st => (NDkilled fuelExhaustedKill, st)) := rfl

theorem memcmp_load_aux_lemFuel_zero
    (_lemReader_tagDefs : Fmap sym (CerbLocation.Loc × tag_definition))
    (ptrval : impl_pointer_value) (offset : Int) (max_offset : Int)
    (acc : List impl_mem_value) :
    memcmp_load_aux_lemFuel 0 _lemReader_tagDefs ptrval offset max_offset acc
      = ND (fun st => (NDkilled fuelExhaustedKill, st)) := rfl

/-! ### The three runner leaves (design note Q3) -/

theorem runNDFuel_zero {a info err cs st : Type} (m : ndM a info err cs st) (st0 : st) :
    runNDFuel 0 m st0 = [(Killed st0 fuelExhaustedKill, [], st0)] := rfl

theorem runND1Fuel_zero {a info err cs st : Type} (m : ndM a info err cs st) (st0 : st) :
    runND1Fuel 0 m st0 = [(Killed st0 fuelExhaustedKill, [], st0)] := rfl

theorem runND1TraceFuel_zero {a info err cs st : Type} (showInfo : info → String)
    (m : ndM a info err cs st) (st0 : st) :
    runND1TraceFuel showInfo 0 m st0 = ([], [(Killed st0 fuelExhaustedKill, [], st0)]) := rfl

/-! ### Constructor disjointness — NOT distinctness from a genuine `Error` kill

These two are free (constructor disjointness of `kill_reason`). They are
NOT a distinctness lemma against `Error0 loc msg`: no such lemma is
provable for an opaque `loc` and, by the parametricity argument of the
design note §1.3, none is needed — a proved acceptance-shape theorem is
uniform in `fuelExhaustedLoc` and holds under the reading where the atom
is a location no model term denotes. Consumers state the STRUCTURAL
equation `o.1 = Killed st fuelExhaustedKill` and discharge it with the
`_zero` lemmas; no `DecidableEq`, no decidable `isFuelExhaustedKill`
ships (Q6). -/

theorem fuelExhaustedKill_ne_Undef0 {err : Type} (loc : CerbLocation.Loc)
    (ubs : List undefined_behaviour) :
    (fuelExhaustedKill : kill_reason err) ≠ Undef0 loc ubs := by
  intro h; cases h

theorem fuelExhaustedKill_ne_Other {err : Type} (e : err) :
    (fuelExhaustedKill : kill_reason err) ≠ Other e := by
  intro h; cases h

/-! ### The wrappers pinned to the budget constant (design note §4.3) -/

theorem driverFuel_eq : CerbFuel.driverFuel = 100000000 := rfl

theorem driver2_wrapper_defeq : driver2 = driver2_lemFuel CerbFuel.driverFuel := rfl

theorem print_eval_conv_aux_wrapper_defeq :
    print_eval_conv_aux = print_eval_conv_aux_lemFuel CerbFuel.driverFuel := rfl

theorem drive_nonmemory_steps_aux2_wrapper_defeq :
    drive_nonmemory_steps_aux2 = drive_nonmemory_steps_aux2_lemFuel CerbFuel.driverFuel := rfl

theorem hack_wrapper_defeq : hack = hack_lemFuel CerbFuel.driverFuel := rfl

/-- Fully applied (the generated `nd_bind` wrapper binds its six implicit
    type arguments BEFORE the worker's fuel argument, so the point-free
    `@nd_bind = @nd_bind_lemFuel driverFuel` of the design note does not
    typecheck as written; this is the same equation at every instance). -/
theorem nd_bind_wrapper_defeq {a b c d e f : Type}
    (n : ndM f b d a c) (f1 : f → ndM e b d a c) :
    nd_bind n f1 = nd_bind_lemFuel CerbFuel.driverFuel n f1 := rfl

theorem runND_eq {a info err cs st : Type} (m : ndM a info err cs st) (st0 : st) :
    runND m st0 = runNDFuel CerbFuel.driverFuel m st0 := rfl

theorem runND1_eq {a info err cs st : Type} (m : ndM a info err cs st) (st0 : st) :
    runND1 m st0 = runND1Fuel CerbFuel.driverFuel m st0 := rfl

end FuelContract

/-! ## The fuel-parametric shipped pipeline (design note §1.6; consumer requirement R1)

`drive_lemFuel fuel` is the generated `drive` (Driver.lean, `def  drive`)
with its ONE `driver2 _lemReader_tagDefs with_concurrency` occurrence
replaced by `driver2_lemFuel fuel _lemReader_tagDefs with_concurrency`
— the MAIN-program call only (the globals phase inside `driver_globals`
runs at the fixed `driverFuel`; consumer §7 accepted exactly this).
Hand-written MIRROR, produced mechanically: the generated body copied
VERBATIM (binder names, comments, spacing included) plus that single
substitution — nothing else is touched, so a reviewer can `diff` it
against the generated text. The SYNC GUARANTEE is `drive_wrapper_defeq`
below: `drive = drive_lemFuel driverFuel` by `rfl`. Any drift in the
generated `drive` breaks that `rfl` and OUR build goes red — it shows as
`(deterministic) timeout at whnf` in `drive_wrapper_defeq` (the two ~10 KB
bodies stop being syntactically identical and the elaborator falls back
to evaluating them). The remedy is to RE-MIRROR (copy the regenerated
body + the one substitution), never a heartbeat bump.

`drive_lemFuel 0 …` is NOT the kill term (no `_zero` lemma): fuel 0 does
not short-circuit the setup phase, which runs at fixed budgets first;
when setup reaches `main`, `driver2_lemFuel 0` kills with
`fuelExhaustedKill` and `nd_bind`'s `NDkilled` arm propagates it (design
note §1.6, "What `drive_lemFuel 0` returns").

The `open`s below are exactly the generated Driver.lean's, scoped to this
section so the mirror elaborates in the same name environment. -/

section DriveMirror
open Lem_Num Lem_Pervasives Lem_List Lem_Set Lem_Map Lem_Maybe Lem_Function
  Lem_Show Lem_Show_extra Lem_Bool Lem_Basic_classes Lem_Map_extra
  Lem_String_extra Lem_Num_extra Lem_Set_helpers Lem_Either Lem_Assert_extra
  Lem_Set_extra Lem_List_extra Lem_Relation Lem_Tuple Lem_String Lem_Word Mem

def drive_lemFuel (fuel : Nat) (_lemReader_tagDefs : Fmap (sym) ((CerbLocation.Loc ×tag_definition)))   (with_concurrency : Bool) (file1 : generic_file (Unit) (core_run_annotation))  (arg_strs : List  String)  : ndM (driver_result) (step_kind) (driver_error) (mem_constraint (CerbMem.IntegerValue)) (driver_state) :=  nd_bind 
  ((
  /-  Setting the read-only tag definitions (used by the memory model)  -/
  /-  first we execute the body of global definitions and remove their symbols
     from the rest of the program  -/driver_globals _lemReader_tagDefs)  with_concurrency  file1)  (fun (tid0 : Nat) /- , post_globals_dr_st)  -/ =>  nd_bind 
  nd_get  (fun (post_globals_dr_st : driver_state) =>  nd_bind (
  
  /-  we need a startup function to have been declared  -/
  match  post_globals_dr_st.core_file.main with  |  some  sym1 =>          nd_return  sym1 |  none =>          kill  (Other  (DErr_other  "no startup function was declared"))
  )  (fun (main_sym : sym) => 
  
  /-  setting the arena of thread 0 to the body of the main function  -/
  match  (fmapLookupBy  (fun (sym1 : sym) (sym2 : sym)=> ordCompare  sym1  sym2)  main_sym  post_globals_dr_st.core_file.funs) with  |  none =>          kill  (Other  (DErr_other  "couldn't find the startup function")) |  some  decl =>  nd_bind (         match  decl with  |  Fun   _  params  pe =>                nd_return  (CerbLocation.other  "main args", params, Expr  []  (Epure  pe)) |  ProcDecl  _  _  _ =>                kill  (Other  (DErr_other  "the startup function has no definition")) |  BuiltinDecl  _  _  _ =>                kill  (Other  (DErr_other  "the startup function has no definition")) |  Proc  loc1  _  _  params  e =>                nd_return  (loc1, params, e)         )  (fun (p : (CerbLocation.Loc ×List ((sym ×core_base_type)) ×generic_expr (core_run_annotation) (Unit) (sym))) =>  match p with |  (loc1,  params,  expr1) =>  nd_bind (                  match  params with  |  [(argc_sym,  _),  (argv_sym,  _)] =>  nd_bind                ((  /-                /-  memory_values to be stored in memory objects pointed to by                  the element of main.argv   -/               let args_mem_val_tys =                 List.map (fun arg_str ->                   let mem_vals =                     List.map (fun c ->                       /-  TODO: fixing impl choice here (ASCII)  -/                       Mem.integer_mval Ctype.Char $ Decode.decode_character_constant (String.toString [c])                     ) (String.toCharList arg_str) in                   /-  NOTE: adding a null termination to the char array  -/                   (                     Mem.array_mval $ mem_vals ++ [Mem.integer_mval Ctype.Char 0],                     Ctype.Ctype [] (Ctype.Array Ctype.char (Just ((integerFromNat (List.length mem_vals)) + 1)))                   )                 ) arg_strs in                              /-  memory value to be stored in the memory object pointed to by main.argc  -/               let number_of_args = integerFromNat (List.length args_mem_val_tys) in               let argc_mem_val = Mem.integer_mval (Ctype.Signed Ctype.Int_) number_of_args in                              /-  begin if false /- Global.has_switch Global.SW_inner_arg_temps -/ then                 /-  in this switch (for CN) Core procedures elaborating C functions                    receive values (and to the temp allocation themselves)  -/                    ND.return (Core.Vobject (Core.OVinteger (Mem.integer_ival number_of_args)))               else  -/                 /-  allocating and initialising an object for main.argc  -/                 liftMem (                   Mem.bind (Mem.allocate_object tid0 (Symbol.PrefSource loc [main_sym; argc_sym])                               (Mem.alignof_ival Ctype.signed_int) Ctype.signed_int Nothing Nothing) (fun ptr_val ->                     Mem.bind (Mem.store (Loc.other "argc init") Ctype.signed_int false ptr_val argc_mem_val) (fun _ ->                       Mem.return (Core.Vobject (Core.OVpointer ptr_val))                     )                   )                 )               /- end -/ >>= fun argc_cval ->                              /-  allocating and initialising the objects pointed to by the elements of argv  -/               ND.foldlM (fun ptr_vals (arg_mem_val, arg_ty) ->                 liftMem (                   Mem.bind (Mem.allocate_object tid0 (Symbol.PrefOther "argv refs") (Mem.alignof_ival arg_ty) arg_ty Nothing Nothing) (fun ptr_val ->                     Mem.bind (Mem.store (Loc.other "argv refs init") arg_ty false ptr_val arg_mem_val) (fun _ ->                       Mem.return (ptr_val :: ptr_vals)                     )                   )                 )               ) [] args_mem_val_tys >>= fun ptr_vals_rev ->                              /-  allocating and initialising an object for main.argv  -/               /-  NOTE: the element argv[argc] is required to be a null pointer                  by the STD, hence argv has one more element than the number                  of supplied arguments  -/               let argv_array_elem_ty = Ctype.Ctype [] (Ctype.Pointer Ctype.no_qualifiers Ctype.char) in               let argv_array_ty = Ctype.Ctype [] (Ctype.Array argv_array_elem_ty (Just (1 + (integerFromNat $ List.length ptr_vals_rev)))) in               let argv_array_mem_val = Mem.array_mval $                 List.map (Mem.pointer_mval Ctype.char) (List.reverse ptr_vals_rev ++ [Mem.null_ptrval Ctype.char]) in               liftMem (                 Mem.bind (Mem.allocate_object tid0 (Symbol.PrefSource loc [main_sym; argv_sym/- TODO: change the sym? -/])                             (Mem.alignof_ival argv_array_ty) argv_array_ty Nothing Nothing) (fun array_ptr_val ->                 Mem.bind (Mem.store (Loc.other "argv array init") argv_array_ty false array_ptr_val argv_array_mem_val) (fun _ ->                                  /-  NOTE: because of argument promotions, the char *argv[] is turned into a char **argv                    so two objects are allocated: an array and a pointer to that array (which is what argv designate)  -/                 let argv_ty = Ctype.Ctype [] (Ctype.Pointer Ctype.no_qualifiers (Ctype.Ctype [] (Ctype.Pointer Ctype.no_qualifiers Ctype.char))) in                 Mem.bind (Mem.allocate_object tid0 (Symbol.PrefSource loc [main_sym; argv_sym])                             (Mem.alignof_ival argv_ty) argv_ty Nothing Nothing) (fun argv_ptr_val ->                 Mem.bind (Mem.store (Loc.other "argv init") argv_ty false argv_ptr_val                             (Mem.pointer_mval (Ctype.Ctype [] (Ctype.Pointer Ctype.no_qualifiers Ctype.char)) array_ptr_val)) ( fun _ ->                  Mem.return (Core.Vobject (Core.OVpointer argv_ptr_val))                 ))))               ) >>= fun argv_cval ->  -/prepare_main_args _lemReader_tagDefs)  loc1  file1.calling_convention0  tid0  main_sym  arg_strs  argc_sym  argv_sym)  (fun (p : (value ×value)) =>  match p with |  (argc_cval,  argv_cval) =>  nd_bind  (nd_bind                 /-  Adding the values of argc and argv to the Core symbol environment  -/               get_thread_states  (fun (x : List ((Nat ×((Option (thread_id) ×thread_state))))) =>  match x with  |  [(_,  (_,  th_st))] =>                    driver_update_thread_state  tid0                      {  th_st  with env  :=                            match  th_st.env with  |  [] =>                                  [Lem_Map.fromList  [ (argc_sym ,argc_cval)                                               , (argv_sym, argv_cval)] ] | ( xs  ::  xs') =>                                  ((fmapAddBy  (fun (sym1 : sym) (sym2 : sym)=> ordCompare  sym1  sym2)  argc_sym  argc_cval                                    ((fmapAddBy  (fun (sym1 : sym) (sym2 : sym)=> ordCompare  sym1  sym2)  argv_sym  argv_cval  xs))))  ::  xs'                                                } |  _ => (failwithI  "ERROR (in Driver 1)" : ndM (Unit) (step_kind) (driver_error) (mem_iv_constraint) (driver_state))               ))  (fun (u : Unit) =>  match u with |  () =>                nd_return  expr1 ) ) |  _ =>                nd_return  expr1         )  (fun (expr1 : generic_expr (core_run_annotation) (Unit) (sym)) =>  nd_bind          (                  /-  allocating and initialising errno  -/liftMem  (           nd_bind  ((CerbMem.allocateObject _lemReader_tagDefs)  tid0  (PrefOther  "errno")  ((CerbMem.alignofIval _lemReader_tagDefs)  signed_int)  signed_int  none  none)  (fun (ptr_val : CerbMem.PointerValue) =>              let  zero  := CerbMem.integerValueMval  (Signed  Int_)  (CerbMem.integerIval (( 0 :  Int)));              nd_bind  ((CerbMem.storeM _lemReader_tagDefs)  (CerbLocation.other  "errno init")  signed_int  false  ptr_val  zero)  (fun ( _ : CerbMem.Footprint) =>                nd_return  ptr_val             )           )         ))  (fun (errno_ptr_val : CerbMem.PointerValue) =>  nd_bind  (nd_bind  (nd_bind  get_thread_states  (fun (x : List ((Nat ×((Option (thread_id) ×thread_state))))) =>  match x with  |  [(_,  (_,  th_st))] =>                driver_update_thread_state  tid0  (({ arena :=  expr1,stack0 :=  Stack_empty /- Core_run.push_empty_continuation (Just main_sym) Core_run.empty_stack -/,errno :=  errno_ptr_val,current_loc :=  (CerbLocation.other  "Driver.drive"),exec_loc :=  (ELoc_normal  [(main_sym, CerbLocation.other  "Driver.drive")]),env  :=  th_st.env,current_proc_opt :=  (some  main_sym)                } : thread_state)) |  _ => (failwithI  "ERROR (in Driver 2)" : ndM (Unit) (step_kind) (driver_error) (mem_iv_constraint) (driver_state))         ))  (fun ( _ : Unit) => ( driver2_lemFuel fuel _lemReader_tagDefs)  with_concurrency))  (fun ( _ : Unit) =>  if  with_concurrency then (failwithI  "CONCURRENCY IS BROKEN" : ndM (driver_result) (step_kind) (driver_error) (mem_constraint (CerbMem.IntegerValue)) (driver_state))          else  nd_bind            nd_get  (fun (dr_st' : driver_state) =>            nd_return  ((finalize _lemReader_tagDefs)  "drive (without concur)"  dr_st'))))) )
)))

/-- THE SYNC GUARANTEE (design note §1.6): the shipped `drive` IS the
    fuel-parametric mirror at the budget constant. Kernel-checked. -/
theorem drive_wrapper_defeq : drive = drive_lemFuel CerbFuel.driverFuel := rfl

end DriveMirror

end CerbND
