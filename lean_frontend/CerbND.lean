/-
  Concrete nondeterminism monad runner.
  Corresponds to: ocaml_frontend/smt2.ml (runND with concrete memory model)

  This runner implements exhaustive evaluation of all nondeterministic
  branches, with NO constraint tracking: NDguard always continues and
  NDbranch explores both sides. UNREACHABLE BY CONSTRUCTION, not a
  divergence (zero-discrepancy Z-59 / Z2-N-03, charter §2.7 — the first
  draft's "recorded divergence — survey finding 23" is REVOKED): on the
  oracle, guards/branches go through `with_constraints … check_sat`
  (smt2.ml:42-44) and the CONCRETE model's cs_module (impl_mem.ml:321-361)
  does evaluate the accumulated constraints. But (1) `NDguard` is produced
  only by `addConstraints` (nondeterminism.lem:234-237, :499-502), whose
  sole exec-cone caller is driver.lem:148 under a `PEconstrained`, which
  arises only from the `Nothing` arms of `Mem.eq_ival`/`lt_ival`/`le_ival`
  (core_eval.lem:352-378) — and the concrete model returns `Some` ALWAYS,
  impl_mem.ml:2556-2562 ↔ `CerbMem.eqIval/ltIval/leIval` (the TRIPWIRE
  theorems `CerbMem.eqIval_isSome`/`ltIval_isSome`/`leIval_isSome` fail
  the build if that ever changes); (2) `NDbranch` is produced only at
  nondeterminism.lem:422 (`msum`) with EMPTY constraints (:465 variant
  commented out), so `with_constraints` there is trivially SAT and
  exploring both sides is exactly what the oracle does (and `NDbranch`'s
  other producer `ifM` lives in defacto_memory.lem, not linked). Probe
  evidence: trace COUNTS and ORDER agree on every completing program
  (tests/z2-probes/nd/order3.c 6-way `129,138,219,237,318,327` on fork,
  upstream and Lean; the noodle's 8/8, 40/40, 67650/67650). Should any
  `NDguard` ever be produced, port `with_constraints` evaluation.

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

  FUEL IS THE CALLER'S PARAMETER (fuel-parameter arc, 2026-09-04;
  docs/2026-09-04_fuel-parameter-C1-record.md): the production runners
  `runND`/`runND1`/`runND1Trace` take the LemLib ambient `[LemFuel]` and
  start their depth counter from `LemFuel.fuel` — the same instance every
  generated fuel'd function reads (lem-lean fuel-parameter design R1), so
  the whole run has ONE fuel, instantiated once at the entry point
  (Main.lean `--fuel N`, the only permitted numeral) or quantified by a
  theorem (`@runND ⟨n⟩ … = runNDFuel n …` by rfl: `runND_eq`). The former
  `ndDefaultFuel := CerbFuel.driverFuel` (= 10^8) is DELETED — a magic
  value [USER 2026-09-03]. Fuel counts ND-TREE DEPTH.
-/

import Nondeterminism
import Defacto_memory
import Driver
import CerbFuel

set_option autoImplicit true

namespace CerbND

export CerbFuel (fuelExhaustedLoc fuelExhaustedMsg)

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
        -- UNREACHABLE by construction (header, Z-59): no `NDguard` is ever
        -- produced with the concrete model's total eq/lt/le_ival; the
        -- oracle's cs_module evaluation (impl_mem.ml:321-361) is not ported.
        runNDFuel fuel continuation st'

      | (NDbranch _info _constraint left right, st') =>
        -- Both sides explored, left-then-right (mirrors smt2.ml:117-132
        -- `xs1 @ xs2`); the constraints are EMPTY at the only producer
        -- (nondeterminism.lem:422), so the oracle explores both too (Z-59).
        runNDFuel fuel left st' ++ runNDFuel fuel right st'

      | (NDstep _info branches, st') =>
        -- OCaml re-dispatches NDstep to the NDnd case (smt2.ml:134-138):
        -- same prepend accumulation order.
        branches.foldl (fun acc (_, branch) =>
          runNDFuel fuel branch st' ++ acc
        ) []

/-- THE production exhaustive runner: the worker started at the ambient
    fuel (`[LemFuel]`, file header), so proofs against `runNDFuel`
    transfer by `rfl` at every instance (`runND_eq`). -/
def runND [LemFuel] (m : ndM a info err cs st) (st0 : st) :
    List (nd_status a err st × List String × st) :=
  runNDFuel LemFuel.fuel m st0

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

/-- Single-trace runner (arc-5 S3 seam; `--first`): the worker at the
    ambient fuel (`runND1_eq`). -/
def runND1 [LemFuel] (m : ndM a info err cs st) (st0 : st) :
    List (nd_status a err st × List String × st) :=
  runND1Fuel LemFuel.fuel m st0

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

/-- Trace-runner wrapper at the ambient fuel (`runND1Trace_eq`). -/
def runND1Trace [LemFuel] (showInfo : info → String) (m : ndM a info err cs st)
    (st0 : st) :
    List String × List (nd_status a err st × List String × st) :=
  runND1TraceFuel showInfo LemFuel.fuel m st0

/-! ## The customer contract (design note §1; consumer: refined-cerberus)

Every statement below is kernel-checked by `rfl`, FULLY APPLIED against
the generated signatures. They are the citable form of the three runner
leaves and the fuel-parametricity pins. Any drift in the generated text —
a renamed binder, an arity change, a moved `_lemFuel` worker — fails THIS
file's build (the consumer's requirement R2: our build is the pinned-lemma
gate).

FUEL-PARAMETER ARC (2026-09-04): the nine ND-typed worker `_zero` arms
that used to be restated here are now GENERATED by lem beside each
wrapper, in the root namespace, with the payload spelled out
(`… = ND (fun st => (NDkilled (Error0 CerbFuel.fuelExhaustedLoc
CerbFuel.fuelExhaustedMsg), st))`): `nd_bind_lemFuel_zero`,
`liftND_lemFuel_zero`, `liftAction_lemFuel_zero` (Nondeterminism.lean),
`print_eval_conv_aux_lemFuel_zero`, `drive_nonmemory_steps_aux2_lemFuel_zero`,
`driver2_lemFuel_zero` (Driver.lean), `find_array_index_lemFuel_zero`,
`easy_update_mem_value_aux_lemFuel_zero`, `memcmp_load_aux_lemFuel_zero`
(Defacto_memory.lean) — the hand-written duplicates are deleted;
`fuelExhaustedKill_eq` below is the one-delta bridge to this file's
spelling. The budget pins (`driverFuel_eq`, `X_wrapper_defeq : X =
X_lemFuel driverFuel`, `drive_wrapper_defeq`, the hand-written mirror
`drive_lemFuel`) are replaced by the ∀-fuel forms: every fuel'd entry is
FUEL-PARAMETRIC, `@X ⟨n⟩ = X_lemFuel n` for every `n`, by `rfl`; the
generated `drive [LemFuel]` IS the fuel-parametric pipeline (the consumer
writes `@drive ⟨n⟩ …` where it wrote `CerbND.drive_lemFuel n …`). -/

section FuelContract

/-- The kill as the generated arms spell it (one delta step on the plain
    `def`; the generated `_zero` lemmas' right-hand side). -/
theorem fuelExhaustedKill_eq {err : Type} :
    (fuelExhaustedKill : kill_reason err)
      = Error0 CerbFuel.fuelExhaustedLoc CerbFuel.fuelExhaustedMsg := rfl

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

/-! ### Fuel parametricity: every entry is its worker at the instance's fuel

`@X ⟨n⟩ = X_lemFuel n` for EVERY `n`, by `rfl` (the wrapper is
`X_lemFuel LemFuel.fuel` and `LemFuel.fuel ⟨n⟩` is `n` by projection).
A worker that passes the ambient on to its callees (the driver family)
carries the instance itself: `@X ⟨n⟩ = @X_lemFuel ⟨n⟩ n`. The statement
that used to read `X = X_lemFuel CerbFuel.driverFuel` is the instance
`n := 100000000` of these. -/

theorem driver2_wrapper_defeq (n : Nat) :
    @driver2 ⟨n⟩ = @driver2_lemFuel ⟨n⟩ n := rfl

theorem print_eval_conv_aux_wrapper_defeq (n : Nat) :
    @print_eval_conv_aux ⟨n⟩ = @print_eval_conv_aux_lemFuel ⟨n⟩ n := rfl

theorem drive_nonmemory_steps_aux2_wrapper_defeq (n : Nat) :
    @drive_nonmemory_steps_aux2 ⟨n⟩ = @drive_nonmemory_steps_aux2_lemFuel ⟨n⟩ n := rfl

theorem hack_wrapper_defeq (n : Nat) :
    @hack ⟨n⟩ = @hack_lemFuel ⟨n⟩ n := rfl

/-- `nd_bind`'s worker is a LEAF (its only fuel is its counter), so the
    right-hand side carries no instance. -/
theorem nd_bind_wrapper_defeq {a b c d e f : Type} (n : Nat) :
    @nd_bind a b c d e f ⟨n⟩ = @nd_bind_lemFuel a b c d e f n := rfl

theorem liftND_wrapper_defeq {a cs err1 err2 info1 info2 st1 st2 : Type} (n : Nat) :
    @liftND a cs err1 err2 info1 info2 st1 st2 ⟨n⟩
      = @liftND_lemFuel a cs err1 err2 info1 info2 st1 st2 n := rfl

theorem liftAction_wrapper_defeq {a cs err1 err2 info1 info2 st1 st2 : Type} (n : Nat) :
    @liftAction a cs err1 err2 info1 info2 st1 st2 ⟨n⟩
      = @liftAction_lemFuel a cs err1 err2 info1 info2 st1 st2 n := rfl

theorem runND_eq {a info err cs st : Type} (n : Nat) (m : ndM a info err cs st) (st0 : st) :
    @runND a info err cs st ⟨n⟩ m st0 = runNDFuel n m st0 := rfl

theorem runND1_eq {a info err cs st : Type} (n : Nat) (m : ndM a info err cs st) (st0 : st) :
    @runND1 a info err cs st ⟨n⟩ m st0 = runND1Fuel n m st0 := rfl

theorem runND1Trace_eq {a info err cs st : Type} (n : Nat) (showInfo : info → String)
    (m : ndM a info err cs st) (st0 : st) :
    @runND1Trace info a err cs st ⟨n⟩ showInfo m st0 = runND1TraceFuel showInfo n m st0 := rfl

end FuelContract

end CerbND
