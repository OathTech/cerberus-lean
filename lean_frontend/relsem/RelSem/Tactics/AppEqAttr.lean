/-
  RelSem.Tactics.AppEqAttr — arc-9 S2 (2026-08-20): the L2 attribute
  layer (design docs/2026-08-20_arc9-s1-design.md §1.3).

  * `app_norm` — THE state normal form simp set (Q3): registered
    lemmas/unfoldings maintain the canonical state spelling after each
    walker step.
  * `@[app_eq]` — registers an app-equation lemma into a DiscrTree
    keyed on its conclusion's LHS `app <computation> <state>` pattern
    (the golean `lawKeys` move: the lemma's telescope variables index
    as wildcards). The walker (RelSem.Tactics.AppWalk) consults this
    tree with most-specific-first candidate order.

  Import discipline (design §6): this file imports Lean only — no
  Iris, no fixtures, no generated code. Meta-code residency: this is
  metaprogramming, not proof-facing semantics; every proof produced
  through it is kernel-checked and swept by the in-build audit.

  House rules: no sorry, no axioms.
-/

import Lean

set_option autoImplicit false

open Lean Meta

namespace RelSem.Tactics

/-- The walker's state normal form simp set (design Q3). -/
register_simp_attr app_norm

/-- One registered app-equation law: the lemma name plus its
    conclusion-LHS DiscrTree keys and a specificity weight (deeper
    keys = more specific, tried first). -/
structure AppEqLaw where
  name : Name
  keys : Array DiscrTree.Key
  prio : Nat
  deriving Inhabited, BEq

/-- The law table: a DiscrTree over conclusion LHS patterns. -/
structure AppEqLaws where
  tree : DiscrTree AppEqLaw := {}
  deriving Inhabited

private def addLaw (laws : AppEqLaws) (l : AppEqLaw) : AppEqLaws :=
  { laws with tree := laws.tree.insertKeyValue l.keys l }

/-- Compute the DiscrTree keys of a candidate `@[app_eq]` lemma: the
    conclusion must be an `Eq` whose LHS is (after telescope) the
    `app`-shaped pattern to index. Fails loudly otherwise. -/
def appEqKeysOfDecl (declName : Name) : MetaM (Array DiscrTree.Key) := do
  let cinfo ← getConstInfo declName
  -- METAVARIABLE telescope (the golean `lawKeys` move): the lemma's
  -- variables must index as DiscrTree WILDCARDS — a plain
  -- forallTelescope would key them as fvars, which match nothing.
  let (_, _, concl) ← forallMetaTelescopeReducing cinfo.type
  let some (_, lhs, _) := concl.eq?
    | throwError "@[app_eq]: {declName}'s conclusion is not an \
        equation (got {concl})"
  DiscrTree.mkPath lhs

initialize appEqExt :
    SimpleScopedEnvExtension AppEqLaw AppEqLaws ←
  registerSimpleScopedEnvExtension {
    initial := {}
    addEntry := addLaw
  }

initialize registerBuiltinAttribute {
  name := `app_eq
  descr := "register an app-equation law for the app_walk tactic \
    (DiscrTree-keyed on the conclusion's LHS)"
  add := fun declName _stx kind => do
    let keys ← MetaM.run' (appEqKeysOfDecl declName)
    ScopedEnvExtension.add appEqExt
      { name := declName, keys := keys, prio := keys.size } kind
}

/-- All laws matching an expression, most-specific-first (key-depth
    descending — golean's ordering delta). -/
def appEqMatches (e : Expr) : MetaM (Array AppEqLaw) := do
  let laws := appEqExt.getState (← getEnv)
  let hits ← laws.tree.getMatch e
  return hits.qsort (fun a b => a.prio > b.prio)

end RelSem.Tactics
