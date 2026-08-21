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

/-- A declared REQUIRED-FACT key on one premise of a law (arc-11 S1
    batch 4, design §12.3 — the context-query extension; evidence:
    Lithium FindInContext/FindHypEqual, Islaris findR/findM keyed
    lookup, Diaframe required-logical-state rule formats).

    The premise (at telescope index `idx`, binder `binder`) is an
    equation whose LHS head is `head`; the argument at `keyPos` is
    the address/identifier KEY. At walk time the local context is
    queried newest-first for an equation hypothesis with the same
    head whose key argument matches (syntactic fast path, then
    budget-capped defeq); the FIRST key-match COMMITS to a full-type
    defeq check — no further scanning, no backtracking.

    `gate = true`  (`fact! :=`): APPLICABILITY — no key-match or a
      failed commit makes the law inapplicable this round.
    `gate = false` (`fact :=`): QUERY-FIRST discharge — a committed
      match discharges the premise; otherwise the normal mechanical
      lanes run (behavior-compatible acceleration/disambiguation). -/
structure RequiredFact where
  binder : Name
  idx : Nat
  head : Name
  keyPos : Nat
  gate : Bool
  deriving Inhabited, BEq, Repr

/-- One registered app-equation law: the lemma name plus its
    conclusion-LHS DiscrTree keys and a specificity weight (deeper
    keys = more specific, tried first), plus declared required-fact
    keys (§12.3). -/
structure AppEqLaw where
  name : Name
  keys : Array DiscrTree.Key
  prio : Nat
  facts : Array RequiredFact := #[]
  deriving Inhabited, BEq

/-- The law table: a DiscrTree over conclusion LHS patterns, plus the
    flat registry (arc-11 S1 batch 3: enumerable for the trace
    FINGERPRINT — design §12.2 stability). -/
structure AppEqLaws where
  tree : DiscrTree AppEqLaw := {}
  all : Array AppEqLaw := #[]
  deriving Inhabited

private def addLaw (laws : AppEqLaws) (l : AppEqLaw) : AppEqLaws :=
  { laws with tree := laws.tree.insertKeyValue l.keys l,
              all := laws.all.push l }

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

/-- Required-fact declaration: `(fact := hget 3)` (query-first
    discharge) or `(fact! := hget 3)` (applicability gate) —
    §12.3. -/
syntax appEqFact := "(" &"fact" ("!")? " := " ident num ")"

syntax (name := app_eq) "app_eq" (ppSpace num)? (ppSpace appEqFact)* : attr

/-- Resolve a declared required-fact against the lemma's telescope
    (loud failures — the Lithium `[instance]`-generator discipline). -/
def resolveRequiredFact (declName : Name) (binder : Name)
    (keyPos : Nat) (gate : Bool) : MetaM RequiredFact := do
  let cinfo ← getConstInfo declName
  forallTelescopeReducing cinfo.type fun xs _ => do
    let mut idx := 0
    for x in xs do
      let decl ← x.fvarId!.getDecl
      if decl.userName == binder then
        let some (_, plhs, _) := (← instantiateMVars decl.type).eq?
          | throwError "@[app_eq] (fact): premise '{binder}' of \
              {declName} is not an equation"
        let some h := plhs.getAppFn.constName?
          | throwError "@[app_eq] (fact): premise '{binder}' of \
              {declName} has a non-constant LHS head"
        unless keyPos < plhs.getAppArgs.size do
          throwError "@[app_eq] (fact): key position {keyPos} out of \
              range for premise '{binder}' of {declName} \
              ({plhs.getAppArgs.size} LHS args)"
        return { binder := binder, idx := idx, head := h,
                 keyPos := keyPos, gate := gate }
      idx := idx + 1
    throwError "@[app_eq] (fact): no premise named '{binder}' in \
        {declName}"

initialize registerBuiltinAttribute {
  name := `app_eq
  descr := "register an app-equation law for the app_walk tactic \
    (DiscrTree-keyed on the conclusion's LHS); optional explicit \
    priority (default: key depth); optional required-fact keys \
    `(fact := binder keyPos)` / `(fact! := binder keyPos)` (§12.3 \
    context queries)"
  add := fun declName stx kind => do
    let keys ← MetaM.run' (appEqKeysOfDecl declName)
    -- parse: node children = [atom app_eq, (num)?, (appEqFact)*]
    let prio := match stx[1].getOptional? with
      | some n => (n.isNatLit?.getD keys.size)
      | none => keys.size
    let mut facts : Array RequiredFact := #[]
    for f in stx[2].getArgs do
      -- appEqFact children: "(" "fact" ("!")? " := " ident num ")"
      let gate := !f[2].getOptional?.isNone
      let binder := f[4].getId
      let keyPos := f[5].isNatLit?.getD 0
      facts := facts.push
        (← MetaM.run' (resolveRequiredFact declName binder keyPos gate))
    -- STATIC AMBIGUITY CHECK (§12.3, survey rank-3 acceptance gate):
    -- two laws with IDENTICAL key paths AND equal priority is a
    -- registration error (conservative overlap approximation; the
    -- dynamic same-priority check + the trace cover the rest).
    let existing := (appEqExt.getState (← getEnv)).all
    for l in existing do
      if l.keys == keys && l.prio == prio && l.name != declName then
        throwError "@[app_eq]: AMBIGUOUS registration — {declName} \
          has the same DiscrTree key path and priority as {l.name}; \
          resolve with an explicit priority (§12.3 \
          ambiguity-is-error)"
    ScopedEnvExtension.add appEqExt
      { name := declName, keys := keys, prio := prio, facts := facts }
      kind
}

/-- All laws matching an expression, most-specific-first (key-depth
    descending — golean's ordering delta). -/
def appEqMatches (e : Expr) : MetaM (Array AppEqLaw) := do
  let laws := appEqExt.getState (← getEnv)
  let hits ← laws.tree.getMatch e
  return hits.qsort (fun a b => a.prio > b.prio)

/-- The whole registered-law surface (name-sorted; the fingerprint's
    input). -/
def appEqAll : MetaM (Array AppEqLaw) := do
  let laws := appEqExt.getState (← getEnv)
  return laws.all.qsort (fun a b => a.name.toString < b.name.toString)

/-! ## `#app_eq_lint` (arc-11 S1 batch 4, design §12.3): the
    on-demand registration linter — reports (a) identical-key-path
    law pairs (would-be ambiguities; equal-priority pairs are already
    a registration ERROR), and (b) metavariable-FREE (literal-pinned)
    conclusion-LHS argument positions per law — the `addrOpt`
    DiscrTree-miss bug class (arc-9 errata): a literal the semantics
    ignores makes dispatch miss varying call sites. Informational
    (many literal pins are legitimate ctor discriminants); run at kit
    reviews. -/

open Elab Command in
elab "#app_eq_lint" : command => do
  Command.liftTermElabM do
    let laws ← appEqAll
    let mut pairs : Nat := 0
    for i in [0:laws.size] do
      for j in [i+1:laws.size] do
        if laws[i]!.keys == laws[j]!.keys then
          pairs := pairs + 1
          logInfo m!"app_eq_lint: identical key paths: \
            {laws[i]!.name} (prio {laws[i]!.prio}) and \
            {laws[j]!.name} (prio {laws[j]!.prio})"
    let mut pinned : Nat := 0
    for l in laws do
      let cinfo ← getConstInfo l.name
      let (_, _, concl) ← Meta.forallMetaTelescopeReducing cinfo.type
      if let some (_, lhs, _) := concl.eq? then
        let args := lhs.getAppArgs
        for k in [0:args.size] do
          let a := args[k]!
          -- skip TYPE arguments (grounded type instantiations are
          -- normal, not the addrOpt bug class)
          if (← instantiateMVars (← Meta.inferType a)).isSort then
            continue
          if !a.hasExprMVar && !a.isConst then
            pinned := pinned + 1
            logInfo m!"app_eq_lint: {l.name}: LHS argument {k} is \
              literal-pinned ({a}) — if the semantics ignores this \
              position, dispatch misses varying call sites \
              (the addrOpt bug class)"
    logInfo m!"app_eq_lint: {laws.size} laws, {pairs} identical-key \
      pair(s), {pinned} literal-pinned LHS position(s)"

/-! ## Walker v2 (arc-9 S3, design §11.3): the state-atom opacity set.

    `@[app_state_atom]` marks a constant the v2 state normalizer must
    treat as OPAQUE (never delta-unfold): fixture files tag their own
    pinned defs (t5File, memD3, …) — the attribute lives here, the
    names stay fixture-side (the §4 fixture-free grep-gate on Kit/
    Tactics is unaffected). -/

initialize appStateAtomExt :
    SimpleScopedEnvExtension Name NameSet ←
  registerSimpleScopedEnvExtension {
    initial := {}
    addEntry := fun s n => s.insert n
  }

syntax (name := app_state_atom) "app_state_atom" : attr

initialize registerBuiltinAttribute {
  name := `app_state_atom
  descr := "mark a constant opaque for the app_walk_norm state \
    normalizer (never delta-unfolded; design §11.3 name preservation)"
  add := fun declName _ kind =>
    ScopedEnvExtension.add appStateAtomExt declName kind
}

/-- The current state-atom set. -/
def stateAtoms : MetaM NameSet :=
  return appStateAtomExt.getState (← getEnv)

end RelSem.Tactics
