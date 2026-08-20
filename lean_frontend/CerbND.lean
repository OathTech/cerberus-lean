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

  TOTALIZED (arc-7 S2, 2026-08-19 — the operator's Q1 AMENDED ruling,
  docs/2026-08-19_relsem-spike.md): the former `partial def runND`/
  `runND1` are now fuel-totalized workers (`runNDFuel`/`runND1Fuel`,
  arc-3 wrapper pattern) with default-fuel wrappers keeping the caller
  signature unchanged. `partial` had made the production runner opaque
  to the kernel (no equations — the arc-3 pathology at the top of the
  stack); with fuel, the runner-vs-Step soundness theorem is proved
  against THIS code (RelSem/RunND.lean `runND_sound`): the executable
  and the proof object are the same artifact.

  EXHAUSTION MARKER ([AGENT:S2] design decision): the fuel-0 leaf is
  `panic!` returning `[]` — the "panic-marker" option, chosen over an
  `.exhausted` status constructor because (a) `nd_status` is a GENERATED
  type (nondeterminism.lem); a new constructor is a model type change,
  out of scope (declares-only .lem budget), and (b) the marker must keep
  Main's batch verdicts and every harness's parsing byte-identical on
  non-exhausted runs — `panic!` is invisible until hit. If ever hit it
  is LOUD twice over: a "PANIC at CerbND.runNDFuel ..." line on stderr
  naming exhaustion, and (since the exhausted subtree contributes no
  executions) a batch-level "runND returned no executions" error when
  the whole run exhausts — never a silently wrong verdict. Unlike the
  opaque `fuelExhaustedWith` sentinel (LemLib.lean:148), `panic!` is
  proof-TRANSPARENT (logically `= default = []`), which is exactly what
  the soundness theorem needs: an exhausted leaf CLAIMS no behaviors, so
  soundness ("every enumerated behavior is Steps-reachable") holds
  honestly; what exhaustion loses is only enumeration COMPLETENESS,
  which was never claimed (spike doc §C2). Fuel-monotonicity
  (`runNDFuel_mono`) keeps the fuel-indexed enumerations an increasing
  chain, so `∃ fuel` statements and the default budget agree on every
  execution the budget reaches.

  BUDGET RATIONALE ([AGENT:S2]): `ndDefaultFuel := lemDefaultFuel`
  (= 10^6). Fuel counts ND-TREE DEPTH, the same measure as `nd_bind`'s
  own fuel (Nondeterminism.lean nd_bind_lemFuel, budget lemDefaultFuel):
  the trees this runner walks are themselves built by 10^6-fuel'd binds,
  so a deeper budget could never be exercised past the substrate's own
  ceiling. Empirically the binding limit is elsewhere anyway: the
  step-runner STACK ceiling (arc-6 S3 register; onset ~1.5k plain loop
  iterations) kills a run at depths orders of magnitude below 10^6 —
  fuel exhaustion is strictly dominated by it on today's corpus, and the
  marker's loudness means an eventual stack fix that exposes the fuel
  ceiling shows up as an explicit PANIC, not a silent [].
-/

import Nondeterminism
import Driver

set_option autoImplicit true

namespace CerbND

/-- Default ND-tree depth budget for the production runners (see BUDGET
    RATIONALE in the file header: = the substrate's own `nd_bind` fuel). -/
def ndDefaultFuel : Nat := lemDefaultFuel

/-- Fuel-totalized exhaustive runner (worker; callers use `runND`).
    Runs the nondeterminism monad exhaustively with the concrete memory
    model, returning a list of (status, trace_strings, final_state)
    triples. Corresponds to: Smt2.runND Exhaustive Impl_mem.cs_module.
    Fuel bounds tree DEPTH; the fuel-0 leaf is the loud exhaustion
    marker (file header).

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
    -- Exhaustion marker: loud (stderr PANIC), proof-transparent (= []).
    panic! "CerbND.runNDFuel: ND-tree depth budget exhausted — this is \
            FUEL EXHAUSTION, not an empty behavior set (see CerbND.lean \
            header; budget: ndDefaultFuel)"
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
    most one execution. Same exhaustion marker/budget as `runNDFuel`.

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
    panic! "CerbND.runND1Fuel: ND-tree depth budget exhausted — this is \
            FUEL EXHAUSTION, not an empty behavior set (see CerbND.lean \
            header; budget: ndDefaultFuel)"
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
    Same fuel discipline and exhaustion marker as the production
    runners. -/
def runND1TraceFuel (showInfo : info → String) (fuel : Nat)
    (m : ndM a info err cs st) (st0 : st) :
    List String × List (nd_status a err st × List String × st) :=
  match fuel with
  | 0 =>
    panic! "CerbND.runND1TraceFuel: ND-tree depth budget exhausted — this \
            is FUEL EXHAUSTION, not an empty behavior set (see CerbND.lean \
            header; budget: ndDefaultFuel)"
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

end CerbND
