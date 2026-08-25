/-
  RelSem.DeriveState — arc-17 S0 (2026-08-24): THE NAMED-STATE EMITTER
  (the giant-terms fix; charter S0 deliverable (a)).

  DONOR (canon-first lineage, cited per mechanism): ACL2Lean's
  `derive_world` (deps/ACL2Lean/ACL2Lean/Replay/Driver/DevQuery.lean:
  74-87) — reflect a fixture-scale object ONCE into a named top-level
  constant with `hints := .abbrev` + `enableRealizationsForConst`
  ("a concrete (fast-reducing) def"), reference it BY NAME in every
  statement and goal, and let it unfold only inside kernel
  `whnf`/`decide` on demand. The donor review
  (notes/2026-08-24_acl2lean-donor-review.md §4) names this pattern as
  the answer to the arc-16 S3 compute-forward park: goals that carry a
  `driver_state` spelling inline (or as a projection chain) force
  whnf-inlining of the whole fixture at the first cross-spelling defeq
  bridge; goals that carry a NAME stay small and bridge by
  once-kernel-checked equations.

  Two command forms:

  * `derive_state id (bs…) : ty := t` — the NAMING form: mint
    `def id bs… : ty := t` (abbrev hints, realizations enabled,
    provenance docstring) plus the equation lemma
    `theorem id_def : ∀ bs…, id bs… = t := rfl` tying the name to its
    definition (the tactic layer's `rw`/feeding handle). This is the
    generalization of the hand pattern already in the tree (S1's
    `sGlob`, S4's `rsD3_thr` ladder).

  * `derive_state_step id (bs…) from m at σ [expecting σ']` — the STEP
    form: compute `app m σ` ONCE in the meta layer (`whnf` — the
    HeapLang-ProofMode "compute successor states outside the goal"
    architecture, named in the S3 record §7), demand an active head
    `(NDactive v, σnext)` (fail-closed, tagged frontier error
    otherwise), and mint the step equation the `wp_step` feeding path
    consumes:
      - without `expecting`: `def id bs… : S := σnext` (named successor,
        abbrev hints + realizations) and
        `theorem id_app : ∀ bs…, app m σ = (NDactive v, id bs…) := rfl`;
      - with `expecting σ'`: only
        `theorem id : ∀ bs…, app m σ = (NDactive v, σ') := rfl` — the
        caller supplies the canonical spelling and the KERNEL
        recomputes and checks it at `addDecl` (the donor's
        recompute-and-check consumer contract, review §1: the meta
        result is never trusted, it only shapes the recorded claim).

  DELIBERATE DEVIATIONS from the donor (recorded per the S0 brief):
  1. No value-level reflection (`reflectWorld`): the donor reflects a
     RUNTIME value to an `Expr`; our states are already Lean terms, so
     the emitter abstracts binders instead (our states are seed/arg
     parametric — the donor's worlds are closed).
  2. Emission stays at COMMAND level (like `derive_world`), not inside
     tactics: under Lean ≥4.32 parallel elaboration, tactic-time
     `addDecl` visibility across concurrently elaborating theorems is
     fragile; command-level minting keeps the environment linear.
  3. The step form's meta `whnf` is a CONVENIENCE (extracts `v`, fails
     early with a typed message); the kernel re-derives the equation at
     `addDecl` — no inference is trusted from the meta layer.

  The frontier-tag mechanism is the donor's `frontierTag`/
  `throwFrontier` LIFT (Reflect.lean:79-91, verdict table row 2):
  deliberate fail-closed frontiers carry a TAG, classified by tag and
  never by message-string prefix, so a future engine (arc-17 S1) can
  catch-and-classify without a shared message namespace.

  House rules: no sorry, no axioms; meta code only — every emitted
  object is an ordinary kernel-checked declaration. Under the in-build
  audit (emitted lemmas are `rfl` objects; the T1Threaded `_def`
  family is cone-pinned in Audit.lean).
-/

import Lean
import RelSem.Machine
import RelSem.Cerberus

set_option autoImplicit false

namespace RelSem
namespace DeriveState

open Lean Lean.Meta Lean.Elab Lean.Elab.Command

/-- Tag marking a DELIBERATE frontier-class failure of the emitter
    (donor LIFT: ACL2Lean Reflect.lean:79-91). Catch sites classify by
    THIS tag, never by message-string prefix. -/
def frontierTag : Name := `RelSem.deriveStateFrontier

/-- Throw a TAGGED frontier-class error (see `frontierTag`): the input
    shape is a known, named limit of the emitter (e.g. a non-active
    step head). Internal invariant violations stay `throwError` so they
    surface as defects. -/
def throwFrontier {α : Type} (msg : MessageData) : TermElabM α := do
  throw <| Exception.error (← getRef) (.tagged frontierTag (← addMessageContext msg))

/-- Is this exception a deliberate emitter frontier (tagged
    `frontierTag`)? -/
def isFrontierErr : Exception → Bool
  | .error _ md => md.hasTag (· == frontierTag)
  | _ => false

/-- Fail-closed closure check on an emitted declaration's type/value:
    residual metavariables or loose fvars are internal errors (a
    partially elaborated emission must never reach `addDecl`). -/
private def checkClosed (what : String) (e : Expr) : TermElabM Unit := do
  if e.hasExprMVar || e.hasLevelMVar then
    throwError "derive_state: {what} contains unresolved metavariables:{indentExpr e}"
  if e.hasFVar then
    throwError "derive_state: {what} contains loose free variables:{indentExpr e}"

/-- Provenance trailer for every emitted constant (the donor records
    producer identity in the artifact — review §1 item 4; ours is the
    emitter name + arc, since the producer is in-repo). Public since
    arc-17 S2: the RoundEval loop emitter stamps the same trailer. -/
def provenanceNote (form : String) : String :=
  s!"Emitted by `{form}` (RelSem.DeriveState emitter family, arc-17; \
donor pattern: ACL2Lean derive_world, DevQuery.lean:74-87). Do not \
edit by hand — re-run the emitting command."

@[inherit_doc provenanceNote]
private def provenance (form : String) : String := provenanceNote form

/-- Add the definition (abbrev hints + realizations + docstring).
    `value`/`type` are already closed (binder-abstracted). Must run
    BEFORE any equation mentioning the constant is built (`mkEq`
    infers the constant's type). -/
private def emitDef (declName : Name) (type value : Expr) (doc : String) :
    TermElabM Unit := do
  checkClosed s!"type of {declName}" type
  checkClosed s!"value of {declName}" value
  addAndCompile <| .defnDecl
    { name := declName, levelParams := [], type, value,
      hints := .abbrev, safety := .safe }
  enableRealizationsForConst declName
  addDocStringCore declName doc

/-- Add an emitted equation lemma (kernel-checked at `addDecl`). -/
private def emitEq (eqName : Name) (eqType eqValue : Expr) (doc : String) :
    TermElabM Unit := do
  checkClosed s!"type of {eqName}" eqType
  checkClosed s!"proof of {eqName}" eqValue
  addDecl <| .thmDecl { name := eqName, levelParams := [], type := eqType, value := eqValue }
  addDocStringCore eqName doc

/-- `derive_state id (bs…) : ty := t` — the naming form (see module
    header). -/
elab doc:(docComment)? "derive_state " id:ident bs:bracketedBinder* " : " ty:term " := " val:term : command => do
  let ns ← getCurrNamespace
  let declName := ns ++ id.getId
  let eqName := declName.appendAfter "_def"
  runTermElabM fun _ => do
    Term.elabBinders bs fun fvars => do
      let tyE ← Term.elabType ty
      let valE ← Term.elabTermEnsuringType val tyE
      Term.synthesizeSyntheticMVarsNoPostponing
      let tyE ← instantiateMVars tyE
      let valE ← instantiateMVars valE
      let type ← mkForallFVars fvars tyE
      let value ← mkLambdaFVars fvars valE
      let userDoc ← match doc with
        | some d => pure s!"{(← getDocStringText d)}\n\n{provenance "derive_state"}"
        | none => pure (provenance "derive_state")
      -- The def must exist before the equation mentioning it is built.
      emitDef declName type value userDoc
      let appliedConst := mkAppN (mkConst declName) fvars
      let eqType ← mkForallFVars fvars (← mkEq appliedConst valE)
      -- proof: `Eq.refl (id bs…) : id bs… = id bs…`, defeq-cast to
      -- `id bs… = t` (the kernel unfolds the freshly added abbrev).
      let eqValue ← mkLambdaFVars fvars (← mkEqRefl appliedConst)
      emitEq eqName eqType eqValue
        s!"Equation lemma tying `{declName}` to its definition \
           (kernel-checked `rfl`). {userDoc}"

/-- The optional canonical-spelling clause of `derive_state_step`
    (its own named node — anonymous optional groups do not bind
    reliably in `elab` headers). -/
syntax deriveExpecting := " expecting " term

/-- `derive_state_step id (bs…) from m at σ [expecting σ']` — the step
    form (see module header). -/
elab doc:(docComment)? "derive_state_step " id:ident bs:bracketedBinder* " from " m:term " at " σ:term expc:(deriveExpecting)? : command => do
  let ns ← getCurrNamespace
  let baseName := ns ++ id.getId
  runTermElabM fun _ => do
    Term.elabBinders bs fun fvars => do
      -- Elaborate `app m σ` in the caller's scope (names resolve where
      -- the command is written, like any term).
      let appStx ← `(app $m $σ)
      let appE ← Term.elabTerm appStx none
      Term.synthesizeSyntheticMVarsNoPostponing
      let appE ← instantiateMVars appE
      -- THE META STEP (once, outside any goal): weak-head compute the
      -- application. Convenience only — the kernel recomputes below.
      -- arc-17 S1: DEFAULT-transparency first; `.all` only as the
      -- fallback. At `.default` the matcher fast-path can give up on
      -- match-of-match nests (the action-request wrap continuations)
      -- — `.all` lets whnf delta-unfold the matcher constants
      -- themselves. But `.all` is NOT safe as the primary mode: on
      -- memory-op successors it unfolds the byte-map's well-founded
      -- recursion (measured: one store-round mint allocated past the
      -- 64 G blast-radius cap). Convenience only, as before: the
      -- kernel recomputes at `addDecl`.
      let pairD ← whnf appE
      let pairE ←
        if pairD.isAppOfArity ``Prod.mk 4 then
          pure pairD
        else
          withTransparency .all <| whnf pairD
      unless pairE.isAppOfArity ``Prod.mk 4 do
        throwFrontier m!"derive_state_step: `app` application did not \
          weak-head compute to a pair — the step is not \
          meta-computable at this state (got:{indentExpr pairE})"
      let args := pairE.getAppArgs
      let headE ← whnf args[2]!
      unless headE.isAppOf ``nd_action.NDactive do
        throwFrontier m!"derive_state_step: step head is not \
          `NDactive` — only deterministic ACTIVE steps are emitted \
          (a killed/branching head needs a law, not a state name; \
          got:{indentExpr headE})"
      let σnextE := args[3]!
      let pairFn := pairE.getAppFn
      
      match expc with
      | some exp =>
        -- Canonical-spelling mode: the caller records the CHOICE (the
        -- expected successor spelling); the kernel recomputes and
        -- checks (donor review §1: the consumer does no inference).
        let σTy ← inferType σnextE
        let expE ← Term.elabTermEnsuringType exp.raw[1] σTy
        Term.synthesizeSyntheticMVarsNoPostponing
        let expE ← instantiateMVars expE
        let rhs := mkApp4 pairFn args[0]! args[1]! headE expE
        let eqType ← mkForallFVars fvars (← mkEq appE rhs)
        let eqValue ← mkLambdaFVars fvars (← mkEqRefl appE)
        checkClosed s!"type of {baseName}" eqType
        checkClosed s!"proof of {baseName}" eqValue
        addDecl <| .thmDecl { name := baseName, levelParams := [], type := eqType, value := eqValue }
        let userDoc ← match doc with
          | some d => pure s!"{(← getDocStringText d)}\n\n{provenance "derive_state_step (expecting)"}"
          | none => pure (provenance "derive_state_step (expecting)")
        addDocStringCore baseName userDoc
      | none =>
        -- Named-successor mode: mint the successor as a constant and
        -- the equation AT THE NAME.
        let σTy ← inferType σnextE
        let defType ← mkForallFVars fvars σTy
        let defValue ← mkLambdaFVars fvars σnextE
        let userDoc ← match doc with
          | some d => pure s!"{(← getDocStringText d)}\n\n{provenance "derive_state_step"}"
          | none => pure (provenance "derive_state_step")
        emitDef baseName defType defValue userDoc
        let appliedConst := mkAppN (mkConst baseName) fvars
        let rhs := mkApp4 pairFn args[0]! args[1]! headE appliedConst
        let eqName := baseName.appendAfter "_app"
        let eqType ← mkForallFVars fvars (← mkEq appE rhs)
        let eqValue ← mkLambdaFVars fvars (← mkEqRefl appE)
        emitEq eqName eqType eqValue
          s!"Step equation at the named successor `{baseName}` \
             (kernel-checked `rfl`). {userDoc}"

end DeriveState
end RelSem
