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

end CerbND
