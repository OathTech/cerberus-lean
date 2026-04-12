/-
  Concrete nondeterminism monad runner.
  Corresponds to: ocaml_frontend/smt2.ml (runND with concrete memory model)

  For the concrete (defacto) memory model, constraints are trivially
  satisfiable — check_sat always returns SAT. This runner implements
  exhaustive evaluation of all nondeterministic branches.

  Symbolic execution is NOT supported.
-/

import Nondeterminism
import Driver

set_option autoImplicit true

namespace CerbND

/-- Run the nondeterminism monad exhaustively with the concrete memory model.
    All guards are assumed satisfiable (concrete = no symbolic constraints).
    Returns a list of (status, trace_strings, final_state) triples.
    Corresponds to: Smt2.runND Exhaustive Impl_mem.cs_module -/
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
      -- Exhaustive: explore ALL branches
      branches.foldl (fun acc (_, branch) =>
        acc ++ runND branch st'
      ) []

    | (NDguard _info _constraint continuation, st') =>
      -- Concrete memory model: all guards are satisfiable
      runND continuation st'

    | (NDbranch _info _constraint left right, st') =>
      -- Concrete: explore both branches (no constraint pruning)
      runND left st' ++ runND right st'

    | (NDstep _info branches, st') =>
      -- Like NDnd: explore all branches
      branches.foldl (fun acc (_, branch) =>
        acc ++ runND branch st'
      ) []

end CerbND
