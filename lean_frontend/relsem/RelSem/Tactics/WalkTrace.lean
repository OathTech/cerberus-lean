/-
  RelSem.Tactics.WalkTrace — arc-11 S1 batch 1 (2026-08-21): THE TRACE
  IR types (design: docs/2026-08-20_arc9-s1-design.md §12.1) + the
  engine revision constant + the sealed-aux registry (A-F6 fix).

  The trace is UNTRUSTED DATA (§12.2): nothing here is proof-facing;
  a trace can only guide replay, never justify acceptance — every
  kernel check re-runs at replay. The structures store NAMES, key
  paths, indices, and ledger numbers — never `Expr`s (compactness
  invariant, §12.1).

  Batch-1 scope notes (build record): residual CLASSIFICATION slots
  are `Option Residual` (populated in S1 batch 4 with the typed
  residual protocol); `Fingerprint`/`GoalKey` land in batch 3 with
  replay. `FiredTrace` flattens the design's nested hyp traces into
  depth-tagged `HypEv` rows (serialization detail; same information).

  Import discipline: Lean only — no Iris, no fixtures, no generated
  code. House rules: no sorry, no axioms.
-/

import Lean

set_option autoImplicit false

open Lean Meta

namespace RelSem.Tactics

/-- ENGINE REVISION (§12.2 trace stability): bumped manually on any
    behavioral change to the walker/emitter. A forgotten bump can only
    produce a loud mid-replay failure, never unsoundness (the trace is
    untrusted data). History: 1 = arc-11 S1 batch 1 (lane
    consolidation, sealing-as-default, structured events). -/
def engineRev : Nat := 1

/-! ## The sealed-aux registry (A-F6).

    The engine's seal/avatar filters used to key on NAME CONVENTIONS
    (`walkSt*`/`kwSt*` prefixes, `_aux` suffixes) — a rename would
    silently change engine behavior (arc-9 audit A-F6). The registry
    records every auxiliary the emitter CREATES, by construction; the
    filters consult it first. The legacy suffix check remains as a
    documented fallback ONLY for auxes imported from other modules
    (not in this process's registry); it can only widen discovery-side
    unfolding, never affect what the kernel checks. -/

initialize sealedAuxRegistry : IO.Ref NameSet ← IO.mkRef {}

/-- Record an emitter-created auxiliary constant. -/
def registerSealedAux (n : Name) : BaseIO Unit :=
  sealedAuxRegistry.modify (·.insert n)

/-- Is `n` an emitter-created auxiliary (this process)? -/
def isRegisteredAux (n : Name) : BaseIO Bool :=
  return (← sealedAuxRegistry.get).contains n

/-- Registry-first aux test with the documented legacy-suffix
    fallback (imported-module auxes). -/
def isSealedAuxName (n : Name) : BaseIO Bool := do
  if (← isRegisteredAux n) then return true
  return match n with
    | .str _ t => t.endsWith "_aux" || t.startsWith "kwSt"
        || t.startsWith "walkSt"
    | _ => false

/-! ## The trace IR (§12.1 grammar) -/

/-- Typed residual classes (§12.3). Batch 1 defines the enum;
    classification lands in batch 4. -/
inductive Residual where
  /-- app-shaped crossing no registered law fires on (human
      `app_walk_step` territory — the G12 division). -/
  | semantic (head : Name)
  /-- pure residual with arithmetic head. -/
  | arithmetic
  /-- computed-value defeq failed with agreeing heads (normalization/
      spelling divergence — the S3 hfind class). -/
  | defeqBridge (lhead rhead : Name)
  /-- ≥2 same-priority applicable candidates (an ERROR per §12.3). -/
  | ambiguousLaw (laws : Array Name)
  /-- empty candidate set on an app-shaped position. -/
  | missingLaw
  deriving Inhabited, Repr

/-- Why a candidate law did or did not fire. -/
inductive CandFate where
  | lhsMismatch
  | hypFailed (i : Nat) (r : Option Residual := none)
  | residualMvars
  /-- the candidate's attempt window aborted (budget/runtime trip)
      before a specific failure was recorded. -/
  | aborted
  | fired
  deriving Inhabited, Repr

/-- One candidate considered (recorded for EVERY candidate — the
    survey rank-3 acceptance requirement). -/
structure CandTrace where
  law : Name
  prio : Nat
  fate : CandFate
  deriving Inhabited, Repr

/-- Which normalization lane produced a computed value. -/
inductive NormLane where
  | selectionKWhnf | normCompute | kWhnfAvatars | spineV1
  deriving Inhabited, Repr, BEq

inductive SealKind where
  | value | state | enumVerbatim | round | cert
  deriving Inhabited, Repr, BEq

/-- One sealing event (aux constant created by the emitter). -/
structure SealEv where
  name : Name
  kind : SealKind
  depthBefore : Nat := 0
  depthAfter : Nat := 0
  deriving Inhabited, Repr

/-- One hypothesis-discharge event, depth-tagged (depth 0 = a
    top-level premise of the fired law; deeper = the recursive
    one-shot-law lane). -/
inductive HypEv where
  | computed (depth : Nat) (lane : NormLane) (cert : Option Name)
  | decideFact (fact : Name) (pos : Bool)
  | scalarPf (depth : Nat) (cert : Option Name)
  | assumption (depth : Nat) (fact : Name)
  | lawFired (depth : Nat) (law : Name)
  | rflClosed (depth : Nat) (cert : Option Name)
  | seal (ev : SealEv)
  deriving Inhabited, Repr

/-- Per-round ledger row (the F-S3-6 accounting, recorded). -/
structure Ledger where
  ms : Nat := 0
  hb : Nat := 0
  deriving Inhabited, Repr

/-- The fired law + its discharge events. -/
structure FiredTrace where
  law : Name
  hyps : Array HypEv := #[]
  deriving Inhabited, Repr

/-- One walker round. -/
structure RoundTrace where
  idx : Nat
  cands : Array CandTrace := #[]
  fired : Option FiredTrace := none
  ledger : Ledger := {}
  deriving Inhabited, Repr

inductive Outcome where
  | closedTerminal | closedRfl
  | stuck (r : Option Residual := none)
  | budget
  deriving Inhabited, Repr

/-- The whole-walk trace (Fingerprint/GoalKey: batch 3). -/
structure WalkTrace where
  rounds : Array RoundTrace := #[]
  outcome : Option Outcome := none
  deriving Inhabited, Repr

/-! ## The trace builder (walk-time state) -/

/-- Builder state: the closed rounds + the open round's candidate and
    hypothesis buffers. -/
structure TraceSt where
  rounds : Array RoundTrace := #[]
  curCands : Array CandTrace := #[]
  curHyps : Array HypEv := #[]
  outcome : Option Outcome := none
  deriving Inhabited

abbrev TraceRef := IO.Ref TraceSt

/-- The low-level engine event buffer: seal/cert/decide-fact sites
    (sealCtorLeaves, normAppState, mkAuxRfl, kWhnfWithFacts) have no
    access to the walk configuration, so they append here when tracing
    is enabled; the walker drains the buffer into the open round. The
    enable flag is set by the traced walk loop only. -/
initialize engineEvEnabled : IO.Ref Bool ← IO.mkRef false
initialize engineEvBuf : IO.Ref (Array HypEv) ← IO.mkRef #[]

/-- Append a low-level engine event (no-op unless a traced walk is
    running). -/
def pushEngineEv (ev : HypEv) : BaseIO Unit := do
  if (← engineEvEnabled.get) then
    engineEvBuf.modify (·.push ev)

/-- Drain the low-level buffer into the open round's hyp buffer. -/
def drainEngineEv (tr? : Option TraceRef) : BaseIO Unit := do
  match tr? with
  | none => engineEvBuf.set #[]
  | some tr =>
    let evs ← engineEvBuf.get
    engineEvBuf.set #[]
    if !evs.isEmpty then
      tr.modify fun st => { st with curHyps := st.curHyps ++ evs }

/-- Record a hypothesis-discharge event. -/
def trHyp (tr? : Option TraceRef) (ev : HypEv) : BaseIO Unit := do
  if let some tr := tr? then
    tr.modify fun st => { st with curHyps := st.curHyps.push ev }

/-- Record a candidate's fate; a `fired` fate consumes the open hyp
    buffer into the round's `FiredTrace`. -/
def trFate (tr? : Option TraceRef) (law : Name) (prio : Nat)
    (fate : CandFate) : BaseIO Unit := do
  if let some tr := tr? then
    drainEngineEv tr?
    tr.modify fun st =>
      { st with curCands := st.curCands.push ⟨law, prio, fate⟩ }

/-- Reset the per-candidate hyp buffer (called before each candidate
    attempt). -/
def trResetHyps (tr? : Option TraceRef) : BaseIO Unit := do
  engineEvBuf.set #[]
  if let some tr := tr? then
    tr.modify fun st => { st with curHyps := #[] }

/-- Close the current round. -/
def trCloseRound (tr? : Option TraceRef) (idx : Nat)
    (fired : Option Name) (ledger : Ledger) : BaseIO Unit := do
  if let some tr := tr? then
    drainEngineEv tr?
    tr.modify fun st =>
      let f := fired.map fun n => { law := n, hyps := st.curHyps }
      { st with
        rounds := st.rounds.push
          { idx := idx, cands := st.curCands, fired := f,
            ledger := ledger },
        curCands := #[], curHyps := #[] }

/-- Record the walk outcome. -/
def trOutcome (tr? : Option TraceRef) (o : Outcome) : BaseIO Unit := do
  if let some tr := tr? then
    tr.modify fun st => { st with outcome := some o }

/-- Snapshot the builder into a `WalkTrace`. -/
def TraceSt.toTrace (st : TraceSt) : WalkTrace :=
  { rounds := st.rounds, outcome := st.outcome }

/-! ## Human-readable dump (debug lanes) -/

def NormLane.tag : NormLane → String
  | .selectionKWhnf => "sel-kwhnf"
  | .normCompute => "normCompute"
  | .kWhnfAvatars => "kwhnf-av"
  | .spineV1 => "spine-v1"

def HypEv.line : HypEv → String
  | .computed d lane c =>
    s!"  hyp[{d}] computed/{lane.tag}{match c with | some n => s!" cert={n}" | none => ""}"
  | .decideFact f p => s!"  decide-fact {f} pos={p}"
  | .scalarPf d c =>
    s!"  hyp[{d}] scalarPf{match c with | some n => s!" cert={n}" | none => ""}"
  | .assumption d f => s!"  hyp[{d}] assumption {f}"
  | .lawFired d l => s!"  hyp[{d}] law {l}"
  | .rflClosed d c =>
    s!"  hyp[{d}] rfl{match c with | some n => s!" cert={n}" | none => ""}"
  | .seal ev =>
    s!"  seal[{repr ev.kind}] {ev.name} depth {ev.depthBefore}→{ev.depthAfter}"

def CandFate.tag : CandFate → String
  | .lhsMismatch => "lhs-mismatch"
  | .hypFailed i r =>
    s!"hyp-{i}-failed{match r with | some c => s!" ({repr c})" | none => ""}"
  | .residualMvars => "residual-mvars"
  | .aborted => "aborted"
  | .fired => "FIRED"

/-- Multi-line dump of a trace (debug lanes; the batch-3 bench probe
    prints the ledger columns from the same data). -/
def WalkTrace.dump (t : WalkTrace) (hyps : Bool := false) : String := Id.run do
  let mut out := s!"walk trace: {t.rounds.size} round(s), outcome "
    ++ (match t.outcome with
        | some o => s!"{repr o}" | none => "(open)") ++ "\n"
  for r in t.rounds do
    let fired := match r.fired with
      | some f => s!"{f.law}" | none => "-"
    out := out ++ s!"R{r.idx}: fired={fired} " ++
      s!"({r.ledger.ms}ms, {r.ledger.hb} hb) cands=[" ++
      String.intercalate ", "
        (r.cands.map (fun c => s!"{c.law}:{c.fate.tag}")).toList ++ "]\n"
    if hyps then
      if let some f := r.fired then
        for ev in f.hyps do
          out := out ++ ev.line ++ "\n"
  return out

/-- One-line summary (round count + fired-law census + outcome). -/
def WalkTrace.summary (t : WalkTrace) : String := Id.run do
  let mut fired : Nat := 0
  for r in t.rounds do
    if r.fired.isSome then fired := fired + 1
  s!"walk trace: {t.rounds.size} rounds ({fired} fired), outcome " ++
    (match t.outcome with | some o => s!"{repr o}" | none => "(open)")

end RelSem.Tactics
