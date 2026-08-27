/-
  RelSem.PriorCensus — V0 (2026-08-27): THE PRIOR-VOCABULARY CENSUS
  INSTRUMENT for the consistency-freshness statement layer
  (relsemcore/RelSem/Threaded.lean §CONSISTENCY).

  Each consistency-quantified statement carries `prior` — the
  program's static symbol-number vocabulary — as PINNED FIXTURE DATA
  (the same trust class as the emitted program terms: both come from
  the same pinned emitted sources). This instrument makes the pin
  FAIL-CLOSED against drift: it walks the syntactic value closure of
  a fixture's file term (RelSem-rooted constants, transitively),
  collects every `sym.Symbol` application's numeric literal, and the
  in-build gates in RelSem/Audit.lean compare the collected set to
  the pinned `*Prior` list EXACTLY (both directions: a symbol
  appearing in the emitted term but not the pin, or a stale pin
  entry, fails the build).

  TRUST LABEL (honest-gaps): this is an UNTRUSTED-EVALUATOR
  instrument — meta code on the test ledger, not a kernel theorem.
  The agreement "prior ⊇ the file's symbol numbers" is TEMPORAL
  (registered; mover = a total symbol-census function over the Core
  AST, V2-class with the per-construct rules). FAIL-CLOSED
  discipline: a `sym.Symbol` application whose numeric argument is
  not a closed literal is a hard error, never a skip.

  House rules: meta code only; no proofs, no axioms.
-/

import Lean
import RelSem.T1File
import RelSem.SlateFiles

set_option autoImplicit false

namespace RelSem.PriorCensus

open Lean

/-- Read a closed Nat from a literal or an `OfNat.ofNat`
    application (the two spellings numerals elaborate to). -/
private def closedNat? (e : Expr) : Option Nat :=
  match e with
  | .lit (.natVal n) => some n
  | _ =>
    if e.isAppOfArity ``OfNat.ofNat 3 then
      match e.getArg! 1 with
      | .lit (.natVal n) => some n
      | _ => none
    else none

/-- Scan one expression for `sym.Symbol` applications; collect the
    numeric argument. FAIL-CLOSED: a non-literal numeric argument is
    an error naming the host constant. -/
private partial def scanExpr (host : Name) (e : Expr)
    (acc : Std.HashSet Nat) : Except String (Std.HashSet Nat) := do
  let mut acc := acc
  -- walk the application spine and all subterms
  match e with
  | .app .. =>
    let fn := e.getAppFn
    if fn.isConstOf `sym.Symbol && e.getAppNumArgs == 3 then
      match closedNat? (e.getArg! 1) with
      | some n => acc := acc.insert n
      | none =>
        throw s!"PriorCensus: {host}: sym.Symbol application with a \
          NON-LITERAL numeric argument (fail-closed — the census \
          cannot certify this term)"
    for a in e.getAppArgs do
      acc ← scanExpr host a acc
    acc ← scanExpr host fn acc
    return acc
  | .lam _ t b _ | .forallE _ t b _ =>
    acc ← scanExpr host t acc; scanExpr host b acc
  | .letE _ t v b _ =>
    acc ← scanExpr host t acc
    acc ← scanExpr host v acc
    scanExpr host b acc
  | .mdata _ b => scanExpr host b acc
  | .proj _ _ b => scanExpr host b acc
  | _ => return acc

/-- Collect the symbol-number census of `root`'s syntactic value
    closure (RelSem-rooted constants, transitively — the emitted
    fixture data all lives there; generated-semantics constants like
    `convert_file` are code, not fixture data, and carry no symbol
    literals of the fixture). -/
def censusOf (env : Environment) (root : Name) :
    Except String (List Nat) := do
  let mut seen : NameSet := {}
  let mut queue : Array Name := #[root]
  let mut acc : Std.HashSet Nat := {}
  while h : queue.size > 0 do
    let c := queue[queue.size - 1]
    queue := queue.pop
    if seen.contains c then continue
    seen := seen.insert c
    unless c.getRoot == `RelSem do continue
    let some ci := env.find? c
      | throw s!"PriorCensus: constant {c} not found"
    if let some v := ci.value? then
      acc ← scanExpr c v acc
      for used in v.getUsedConstants do
        queue := queue.push used
  return (acc.toList.mergeSort (· ≤ ·))

/-- The gate body (called from RelSem/Audit.lean): pinned list vs
    census, exact, both directions. -/
def checkPin (env : Environment) (root : Name) (pinned : List Nat)
    (pinName : String) : Except String Unit := do
  let got ← censusOf env root
  let missing := got.filter (fun n => !pinned.contains n)
  let stale := pinned.filter (fun n => !got.contains n)
  unless missing.isEmpty do
    throw s!"PriorCensus gate: {pinName} is MISSING symbol numbers \
      present in {root}'s emitted term closure (re-pin deliberately, \
      same commit, with the reason): {missing}"
  unless stale.isEmpty do
    throw s!"PriorCensus gate: {pinName} has STALE entries not in \
      {root}'s emitted term closure: {stale}"

end RelSem.PriorCensus
