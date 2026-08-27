/-
  RelSem.LawRegistry — arc-18 C1 (2026-08-25): THE ONE REGISTRY.

  The reasoning layer's SINGLE law interface (layer-3c contract,
  docs/2026-08-25_reasoning-layer-contracts.md §3c; closes register
  rows R3/R4). Every law the evaluator or the wp-tactic layer
  dispatches on is registered here via `@[step_law …]`; dispatch
  consults the registry by GOAL FORM (DiscrTree key over the law's
  conclusion — the LHS when Eq-shaped), never a hardcoded name table.

  ENTRY SCHEMA (the charter's C1 list): each entry carries
    * the law (declaration name) and its goal-form key (DiscrTree
      path, telescope variables as wildcards),
    * `kind`  — the dispatch lane (advance | perform | memBlock |
      roundGlue | construct | envMap | envAlg | memRW | wpSeq | loop),
    * `variant` — the discriminator WITHIN a shared goal form (e.g.
      envMap hit/skip: same lookup-over-insert LHS, different side
      condition), `.anonymous` when the goal form is unique,
    * `side` — the side-condition discharge route (`rfl | decide |
      omega | wp_ground | hyp | fed | none`),
    * `frontier` — the frontier tag a consumer raises when this lane
      is expected and no entry applies (fail-closed, S0 taxonomy),
    * `trace` — the trace-atom schema (S0 automation-trace format
      §3.3; the arc-19 search consumes this field),
    * `lineage` — the canon-first lineage sentence (doctrine: every
      mechanism names its lineage).

  UNIQUE-RULE-PER-GOAL-FORM (the RefinedC hint-mode lesson,
  typing/type.v:381): registering two laws with the same key path,
  kind, and variant is a REGISTRATION ERROR — applicability is
  determined by the key, disambiguation only by declared variant.
  `queryUnique` enforces the same discipline at consumption time.

  Relation to the retired `@[app_eq]` (Tactics/AppEqAttr.lean,
  DELETED at the 2026-08-27 kill-list execution): that DiscrTree
  attribute is this registry's in-house DONOR (the C0 adjudication,
  contracts doc §7 entry 3) — the indexing mechanism (metavariable-
  telescope keys, scoped env extension, specificity order) is lifted
  from it; the walker's copy stays frozen in place (freeze gate) and
  deletes with the chase corpus at C5. The proved lemmas under
  `@[app_eq]` survive only by re-registration here.

  Import discipline: Lean only — no Iris, no fixtures, no generated
  code (laws import THIS module, never the reverse; the engine may
  not contain semantic knowledge, laws may not know about the
  engine). Meta-code residency: every proof dispatched through the
  registry is kernel-checked at its addDecl; the registry shapes
  claims, never certifies them.

  House rules: no sorry, no axioms.
-/

import Lean

set_option autoImplicit false

open Lean Meta

namespace RelSem.LawRegistry

/-- One registered step law (see the module header for the field
    contract). -/
structure StepLaw where
  name : Name
  /-- Goal-form key: DiscrTree path of the conclusion (LHS when the
      conclusion is an equation), telescope variables as wildcards. -/
  keys : Array DiscrTree.Key
  kind : Name
  variant : Name := .anonymous
  side : Name
  frontier : String := ""
  trace : String
  lineage : String
  /-- Specificity (key depth by default; deeper = tried first). -/
  prio : Nat
  deriving Inhabited, BEq

/-- The registry state: a DiscrTree over goal forms plus the flat
    enumerable table (census/fingerprint input — the AppEqAttr
    `all` move). -/
structure Registry where
  tree : DiscrTree StepLaw := {}
  all : Array StepLaw := {}
  deriving Inhabited

private def addLaw (r : Registry) (l : StepLaw) : Registry :=
  { r with tree := r.tree.insertKeyValue l.keys l,
           all := r.all.push l }

/-- Goal-form keys of a candidate law: the conclusion's LHS when
    Eq-shaped, the whole conclusion otherwise (WP-shaped laws). The
    METAVARIABLE telescope indexes the law's variables as DiscrTree
    wildcards (the donor's `appEqKeysOfDecl` move). -/
def goalFormKeys (declName : Name) : MetaM (Array DiscrTree.Key) := do
  let cinfo ← getConstInfo declName
  let (_, _, concl) ← forallMetaTelescopeReducing cinfo.type
  let target := match concl.eq? with
    | some (_, lhs, _) => lhs
    | none => concl
  DiscrTree.mkPath target

initialize stepLawExt :
    SimpleScopedEnvExtension StepLaw Registry ←
  registerSimpleScopedEnvExtension {
    initial := {}
    addEntry := addLaw
  }

/-- `@[step_law (kind := …) (side := …) (trace := "…")
    (lineage := "…") ((variant := …) (frontier := "…") (prio := n))?]`
    — field order free; kind/side/trace/lineage REQUIRED
    (fail-closed: a law without its schema fields does not
    register). -/
syntax stepLawField := "(" ident " := " (ident <|> str <|> num) ")"
syntax (name := step_law) "step_law" (ppSpace stepLawField)* : attr

private def fieldIdent? (v : Syntax) : Option Name :=
  if v.isIdent then some v.getId else none

initialize registerBuiltinAttribute {
  name := `step_law
  descr := "register a law in THE ONE REGISTRY (RelSem.LawRegistry): \
    DiscrTree-keyed on the conclusion's goal form; entry fields \
    kind/side/trace/lineage required, variant/frontier/prio optional"
  add := fun declName stx kind => do
    let keys ← MetaM.run' (goalFormKeys declName)
    let mut fKind : Option Name := none
    let mut fVariant : Name := .anonymous
    let mut fSide : Option Name := none
    let mut fFrontier : String := ""
    let mut fTrace : Option String := none
    let mut fLineage : Option String := none
    let mut fPrio : Option Nat := none
    for f in stx[1].getArgs do
      -- stepLawField children: "(" ident " := " value ")"
      let fname := f[1].getId
      let v := f[3]
      match fname with
      | `kind =>
        let some n := fieldIdent? v
          | throwError "@[step_law] {declName}: kind must be an ident"
        fKind := some n
      | `variant =>
        let some n := fieldIdent? v
          | throwError "@[step_law] {declName}: variant must be an ident"
        fVariant := n
      | `side =>
        let some n := fieldIdent? v
          | throwError "@[step_law] {declName}: side must be an ident"
        fSide := some n
      | `frontier =>
        let some s := v.isStrLit?
          | throwError "@[step_law] {declName}: frontier must be a string"
        fFrontier := s
      | `trace =>
        let some s := v.isStrLit?
          | throwError "@[step_law] {declName}: trace must be a string"
        fTrace := some s
      | `lineage =>
        let some s := v.isStrLit?
          | throwError "@[step_law] {declName}: lineage must be a string"
        fLineage := some s
      | `prio =>
        let some n := v.isNatLit?
          | throwError "@[step_law] {declName}: prio must be a numeral"
        fPrio := some n
      | other =>
        throwError "@[step_law] {declName}: unknown field '{other}' \
          (known: kind variant side frontier trace lineage prio)"
    let some kindV := fKind
      | throwError "@[step_law] {declName}: missing required field \
          (kind := …)"
    let some sideV := fSide
      | throwError "@[step_law] {declName}: missing required field \
          (side := …)"
    let some traceV := fTrace
      | throwError "@[step_law] {declName}: missing required field \
          (trace := \"…\")"
    let some lineageV := fLineage
      | throwError "@[step_law] {declName}: missing required field \
          (lineage := \"…\")"
    -- UNIQUE-RULE-PER-GOAL-FORM (registration-time): same key path +
    -- kind + variant is an error (the RefinedC hint-mode discipline).
    let existing := (stepLawExt.getState (← getEnv)).all
    for l in existing do
      if l.keys == keys && l.kind == kindV && l.variant == fVariant
          && l.name != declName then
        throwError "@[step_law]: AMBIGUOUS registration — {declName} \
          has the same goal-form key path, kind '{kindV}', and \
          variant '{fVariant}' as {l.name}; declare distinct \
          variants (unique-rule-per-goal-form)"
    ScopedEnvExtension.add stepLawExt
      { name := declName, keys, kind := kindV, variant := fVariant,
        side := sideV, frontier := fFrontier, trace := traceV,
        lineage := lineageV, prio := fPrio.getD keys.size }
      kind
}

/-! ## The query interface (what the engine and the tactic layer
    consult; hardcoded-name dispatch is retired in their favor). -/

/-- FENCE-ROBUST FALLBACK (arc-18 C3b): a drive-scoped attribute
    fence (RoundEval's temporary `@[irreducible]` statuses on the
    hypothesis pack's pattern heads) changes DiscrTree KEY
    COMPUTATION — a structure accessor keys as a projection at
    registration time (accessors reducible) but as a plain const
    under a fence that happens to contain it, so tree matching
    silently misses registered laws during exactly the drives that
    need them (measured: the T5 body walk's round-59 memRW projection
    dispatch — the pack's `hfpm`/`hlum` facts fence the accessors
    themselves). On ZERO tree hits the query falls back to a linear
    scan of the kind's entries with a meta-telescope defeq match
    against the goal form — the same applicability semantics,
    key-computation-independent; assignments are rolled back per
    attempt so caller metavariables (skeleton stars) are untouched.
    Genuine misses still return empty: fail-closed frontiers are
    unchanged. -/
def matchByUnify (kind : Name) (e : Expr) : MetaM (Array StepLaw) := do
  let r := stepLawExt.getState (← getEnv)
  let mut out : Array StepLaw := #[]
  for l in r.all do
    if l.kind == kind then
      let ok ← try
        withoutModifyingState <| withCurrHeartbeats do
          let cinfo ← getConstInfo l.name
          let (_, _, concl) ← forallMetaTelescopeReducing cinfo.type
          let target := match concl.eq? with
            | some (_, lhs, _) => lhs
            | none => concl
          withReducible (isDefEq target e)
      catch _ => pure false
      if ok then out := out.push l
  return out

/-- All laws of `kind` matching the goal form `e`, most specific
    first. REDUCIBLE-transparency matching (measured, arc-18 C1): at
    ambient default transparency the DiscrTree's key reduction
    UNFOLDS plain definitions — on `app …` goal forms that runs the
    interpreter inside the query (a T4 round-18 heartbeat timeout);
    goal-form keys are matched as spelled, reducible-only. Zero tree
    hits fall back to the fence-robust unification scan when the
    caller opts in (`unifyFallback` — drives under an attribute
    fence; see `matchByUnify`'s note. OFF by default: ambient
    dispatch stays byte-identical to the tree semantics). -/
def query (kind : Name) (e : Expr)
    (unifyFallback : Bool := false) : MetaM (Array StepLaw) := do
  let r := stepLawExt.getState (← getEnv)
  let hits ← withReducible <| r.tree.getMatch e
  let hits := hits.filter (·.kind == kind)
  let hits ← if hits.isEmpty && unifyFallback then matchByUnify kind e
    else pure hits
  return hits.qsort (fun a b => a.prio > b.prio)

/-- THE dispatch query: exactly one law of `kind`/`variant` must
    match the goal form — zero matches raises the registry's
    fail-closed error naming the kind and the goal (the caller wraps
    it in its lane frontier); two matches at top priority is an
    ambiguity error (consumption-time unique-rule check). -/
def queryUnique (kind : Name) (e : Expr)
    (variant : Name := .anonymous) (unifyFallback : Bool := false) :
    MetaM StepLaw := do
  let hits ← query kind e unifyFallback
  let hits := if variant == .anonymous then hits
    else hits.filter (·.variant == variant)
  match hits.size with
  | 0 => throwError "LawRegistry: no registered '{kind}' law \
      (variant '{variant}') matches goal form:{indentExpr e}"
  | 1 => return hits[0]!
  | _ =>
    if hits[0]!.prio > hits[1]!.prio then return hits[0]!
    throwError "LawRegistry: AMBIGUOUS dispatch — '{kind}' laws \
      {hits[0]!.name} and {hits[1]!.name} both match at priority \
      {hits[0]!.prio}:{indentExpr e}"

/-- All laws of a kind (enumeration order = registration order). -/
def byKind (kind : Name) : MetaM (Array StepLaw) := do
  return (stepLawExt.getState (← getEnv)).all.filter (·.kind == kind)

/-- A registered law by declaration name (the trace/audit face). -/
def byName? (n : Name) : MetaM (Option StepLaw) := do
  return (stepLawExt.getState (← getEnv)).all.find? (·.name == n)

/-- The whole registered surface, name-sorted (census/fingerprint
    input). -/
def allLaws : MetaM (Array StepLaw) := do
  return (stepLawExt.getState (← getEnv)).all.qsort
    (fun a b => a.name.toString < b.name.toString)

/-- Head constants of the registered goal-form keys for the given
    kinds (the classifier feed: candidate collection derives its
    head set from the registry instead of a hardcoded list). -/
def keyHeads (kinds : Array Name) : MetaM NameSet := do
  let r := stepLawExt.getState (← getEnv)
  let mut out : NameSet := {}
  for l in r.all do
    unless kinds.contains l.kind do continue
    match l.keys[0]? with
    | some (DiscrTree.Key.const c _) => out := out.insert c
    | _ => pure ()
  return out

/-! ## `#step_law_census` — the machine-readable registry census
    (Audit pins its output: population drift is build-visible, the
    same discipline as the axiom-sweep count). -/

open Elab Command in
elab "#step_law_census" : command => do
  Command.liftTermElabM do
    let laws ← allLaws
    let mut kinds : Array (Name × Nat) := #[]
    for l in laws do
      match kinds.findIdx? (·.1 == l.kind) with
      | some i => kinds := kinds.set! i (kinds[i]!.1, kinds[i]!.2 + 1)
      | none => kinds := kinds.push (l.kind, 1)
    let sorted := kinds.qsort (fun a b => a.1.toString < b.1.toString)
    let perKind := ", ".intercalate
      (sorted.toList.map (fun (k, n) => s!"{k} {n}"))
    logInfo s!"step_law census: {laws.size} laws [{perKind}]"

-- Registration lint (on-demand, kit-review instrument — the donor's
-- `#app_eq_lint` move): reports identical-key-path pairs across
-- kinds (cross-kind overlap is legal but worth eyes) and entries
-- with empty frontier tags.
open Elab Command in
elab "#step_law_lint" : command => do
  Command.liftTermElabM do
    let laws ← allLaws
    let mut pairs : Nat := 0
    for i in [0:laws.size] do
      for j in [i+1:laws.size] do
        if laws[i]!.keys == laws[j]!.keys
            && laws[i]!.kind != laws[j]!.kind then
          pairs := pairs + 1
          logInfo m!"step_law_lint: cross-kind identical key paths: \
            {laws[i]!.name} ({laws[i]!.kind}) and {laws[j]!.name} \
            ({laws[j]!.kind})"
    let mut noFrontier : Nat := 0
    for l in laws do
      if l.frontier.isEmpty then noFrontier := noFrontier + 1
    logInfo m!"step_law_lint: {laws.size} laws, {pairs} cross-kind \
      identical-key pair(s), {noFrontier} without frontier tags"

end RelSem.LawRegistry
