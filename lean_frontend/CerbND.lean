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
-/

import Nondeterminism
import Driver

set_option autoImplicit true

namespace CerbND

/-- Run the nondeterminism monad exhaustively with the concrete memory model.
    Returns a list of (status, trace_strings, final_state) triples.
    Corresponds to: Smt2.runND Exhaustive Impl_mem.cs_module

    Result ORDER matters (the harness compares the first verdict):
    OCaml's exhaustive NDnd case (smt2.ml:75-82) is
      `foldlM (fun acc (idx, (info, m_act)) ->
         aux m_act st' >>= fun z -> return (z @ acc)) []`
    i.e. each branch's results are PREPENDED to the accumulator, yielding
    R_n ++ ... ++ R_1 (last branch's results first). We mirror that
    exactly. NDstep (smt2.ml:134-138) delegates to the NDnd case, so it
    gets the same order. NDbranch's exhaustive case (smt2.ml:117-132)
    returns `xs1 @ xs2` (in-order), mirrored below. -/
partial def runND
    (m : ndM a info err cs st) (st0 : st) :
    List (nd_status a err st × List String × st) :=
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
        runND branch st' ++ acc
      ) []

    | (NDguard _info _constraint continuation, st') =>
      -- DIVERGENCE: no constraint pruning (OCaml would eval the constraint
      -- via the concrete cs_module, impl_mem.ml:321-361, and backtrack on
      -- UNSAT); we always continue.
      runND continuation st'

    | (NDbranch _info _constraint left right, st') =>
      -- Both sides explored, left-then-right (mirrors smt2.ml:117-132
      -- `xs1 @ xs2`); same no-pruning divergence as NDguard.
      runND left st' ++ runND right st'

    | (NDstep _info branches, st') =>
      -- OCaml re-dispatches NDstep to the NDnd case (smt2.ml:134-138):
      -- same prepend accumulation order.
      branches.foldl (fun acc (_, branch) =>
        runND branch st' ++ acc
      ) []

/-- Single-trace runner (arc-5 S3 seam): follow exactly ONE branch at every
    nondeterminism point, yielding at most one execution.

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
partial def runND1
    (m : ndM a info err cs st) (st0 : st) :
    List (nd_status a err st × List String × st) :=
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
      | (_, branch) :: _ => runND1 branch st'

    | (NDguard _info _constraint continuation, st') =>
      runND1 continuation st'

    | (NDbranch _info _constraint left _right, st') =>
      runND1 left st'

    | (NDstep _info branches, st') =>
      match branches with
      | [] => []
      | (_, branch) :: _ => runND1 branch st'

end CerbND
