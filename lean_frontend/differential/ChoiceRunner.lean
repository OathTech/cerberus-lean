import Nondeterminism
import Lean

/- A positional choice protocol for the initially unchanged Core/CoreNice paths.
   The ND action is evaluated once at each visited node. Only compact observer
   events and choice descriptors leave the machine; states stay in memory. -/

namespace CoreNiceDiff.Choice

open Lean

structure Header where
  version : Nat := 2
  input : String
  prepared : String
  config : Json
  coreBuild : String
  coreNiceBuild : String
  origin : String
  deriving BEq, ToJson, FromJson

inductive Kind where
  | nd | step | branch
  deriving BEq, ToJson, FromJson

def Kind.label : Kind → String
  | .nd => "nd"
  | .step => "step"
  | .branch => "branch"

structure Entry where
  ordinal : Nat
  kind : Kind
  parent : Json
  alternatives : Array Json
  index : Nat
  deriving BEq, ToJson, FromJson

structure Tape where
  header : Header
  entries : Array Entry
  deriving BEq, ToJson, FromJson

inductive Policy where
  | first
  | seeded (seed : UInt64)
  /-- Follow the supplied branching prefix, then select index zero. An unused
      suffix or an out-of-range supplied index is a configuration error. -/
  | prefix (indices : Array Nat)

inductive Mode where
  | record (policy : Policy)
  | replay (tape : Tape)

inductive Outcome (a err : Type) where
  | returned (value : a)
  | killed (reason : kill_reason err)
  | empty
  | incomplete (reason : String)
  | refused (reason : String)
  | inputError (reason : String)
  | replayMismatch (reason : String)
  | observationError (reason : String)

structure Observer (info err cs st : Type) where
  /-- An optional recorder policy reads only the reached ND state and offered descriptors. -/
  sourceOrder : Option (st → Kind → Json → Array Json → Except String Nat) := none
  encodeInfo : info → Json
  observeDelta : st → st → Except String (Array Json)
  isExhaustion : kill_reason err → Bool
  /-- Return true only for actually empty/trivial constraints. No constraint
      solver is supplied here; every other guard/branch is explicitly refused. -/
  isTrivialConstraint : cs → Bool := fun _ => false

structure Run (a err st : Type) where
  outcome : Outcome a err
  finalState : st
  tape : Tape
  events : Array Json
  visited : Nat

private structure Session where
  entries : Array Entry := #[]
  events : Array Json := #[]
  visited : Nat := 0
  random : UInt64 := 0

/-- Recording origin is provenance, not part of the paired program identity. -/
def Header.sameExecution (expected actual : Header) : Bool :=
  expected.version == actual.version && expected.input == actual.input &&
  expected.prepared == actual.prepared && expected.config == actual.config &&
  expected.coreBuild == actual.coreBuild && expected.coreNiceBuild == actual.coreNiceBuild

def validateTape (expected : Header) (tape : Tape) : Except String Unit := do
  if expected.version != 2 || tape.header.version != 2 then
    throw "unsupported choice protocol version"
  if !expected.sameExecution tape.header then
    throw "choice tape header does not identify this prepared input/configuration/build pair"
  let mut i := 0
  for entry in tape.entries do
    if entry.ordinal != i then throw s!"choice tape entry {i}: wrong ordinal"
    if entry.alternatives.size < 2 then
      throw s!"choice tape entry {i}: choices require at least two alternatives"
    if entry.index >= entry.alternatives.size then
      throw s!"choice tape entry {i}: selected index is outside the alternatives"
    i := i + 1

private def selected (mode : Mode) (session : Session) (kind : Kind)
    (parent : Json) (alternatives : Array Json) :
    Except (Bool × String) (Nat × UInt64) := do
  let ordinal := session.entries.size
  match mode with
  | .record policy =>
    let (index, random) := match policy with
      | .first => (0, session.random)
      | .prefix indices => (indices[ordinal]?.getD 0, session.random)
      | .seeded _ =>
        -- Fixed integer arithmetic gives reproducible sampling independent of
        -- a host RNG. Modulo sampling is not claimed to be uniform.
        let next := session.random * 6364136223846793005 + 1442695040888963407
        (next.toNat % alternatives.size, next)
    if index >= alternatives.size then
      throw (false, s!"recording prefix index {index} is invalid at choice {ordinal}")
    return (index, random)
  | .replay tape =>
    let some expected := tape.entries[ordinal]?
      | throw (true, s!"replay needs a missing entry at choice {ordinal}")
    if expected.kind != kind || expected.parent != parent ||
        expected.alternatives != alternatives then
      throw (true, s!"replay descriptors differ at choice {ordinal} ({kind.label})")
    return (expected.index, session.random)

private def nodeEvent (node : Nat) (kind : String) (parent : Json := .null)
    (alternatives : Array Json := #[]) (index : Option Nat := none) : Json :=
  Json.mkObj [("channel", toJson "nd"), ("node", toJson node),
    ("kind", toJson kind), ("parent", parent), ("alternatives", toJson alternatives),
    ("selected", toJson index)]

private def result {a err st : Type} (header : Header) (session : Session)
    (state : st) (outcome : Outcome a err) : Run a err st :=
  { outcome, finalState := state, tape := { header, entries := session.entries },
    events := session.events, visited := session.visited }

private def finish {a err st : Type} (mode : Mode) (header : Header)
    (session : Session) (state : st) (outcome : Outcome a err) : Run a err st :=
  let checked : Outcome a err := match mode with
    | .replay tape =>
      if session.entries.size != tape.entries.size then
        .replayMismatch s!"replay completed with {tape.entries.size - session.entries.size} surplus entries"
      else outcome
    | .record (.prefix indices) =>
      if session.entries.size < indices.size then
        .inputError s!"recording completed with {indices.size - session.entries.size} unused prefix indices"
      else outcome
    | .record _ => outcome
  result header session state checked

private def choose {raw a info err cs st output : Type} (mode : Mode)
    (sourceOrder : Option (Kind → Json → Array Json → Except String Nat))
    (session : Session) (node : Nat) (kind : Kind) (parent : Json)
    (branches : List (Json × ndM raw info err cs st))
    (completePath errorPath : Session → Outcome a err → output)
    (resumePath : Session → ndM raw info err cs st → output) : output :=
  let alternatives := (branches.map Prod.fst).toArray
  match branches with
  | [] =>
    let session := { session with
      events := session.events.push (nodeEvent node kind.label parent alternatives) }
    completePath session .empty
  | [(_, continuation)] =>
    let session := { session with
      events := session.events.push (nodeEvent node kind.label parent alternatives (some 0)) }
    resumePath session continuation
  | _ :: _ :: _ =>
    let decision : Except (Outcome a err) (Nat × UInt64) := match mode, sourceOrder with
      | .record .first, some policy =>
        ((policy kind parent alternatives).map (fun n => (n, session.random))).mapError Outcome.refused
      | _, _ => (selected mode session kind parent alternatives).mapError fun (replaying, reason) =>
        if replaying then .replayMismatch reason else .inputError reason
    match decision with
    | .error reason =>
      let session := { session with
        events := session.events.push (nodeEvent node kind.label parent alternatives) }
      errorPath session reason
    | .ok (index, random) =>
      match branches[index]? with
      | none => errorPath session (.inputError "selected branch is out of range")
      | some (_, continuation) =>
        let entry : Entry := { ordinal := session.entries.size, kind, parent, alternatives, index }
        let session := { session with
          entries := session.entries.push entry,
          random := random,
          events := session.events.push (nodeEvent node kind.label parent alternatives (some index)) }
        resumePath session continuation

/-- One traversal implementation serves both terminal-only and resumable runs.
    The active callback alone decides whether an NDactive payload is terminal.
    The outcome callback's flag distinguishes real termination from incomplete
    or refused execution, for which surplus tape checks would be misleading. -/
private def traverseWith {raw a info err cs st output : Type} (fuel : Nat)
    (observer : Observer info err cs st) (mode : Mode)
    (onActive : Nat → Session → st → raw → output)
    (onOutcome : Bool → Session → st → Outcome a err → output)
    (session : Session) (machine : ndM raw info err cs st) (state : st) : output :=
  match fuel with
  | 0 => onOutcome false session state (.incomplete "ND traversal fuel exhausted")
  | fuel + 1 =>
    let .ND action := machine
    -- There is exactly one call to the actual ND action at this node.
    let (next, state') := action state
    let node := session.visited
    let session := { session with visited := node + 1 }
    match observer.observeDelta state state' with
    | .error reason => onOutcome false session state' (.observationError reason)
    | .ok delta =>
      let events := delta.map fun event => Json.mkObj [
        ("boundary", toJson node), ("observation", event)]
      let session := { session with events := session.events ++ events }
      let resumePath := fun session machine =>
        traverseWith fuel observer mode onActive onOutcome session machine state'
      let completePath := fun session outcome => onOutcome true session state' outcome
      let errorPath := fun session outcome => onOutcome false session state' outcome
      let chooseHere := choose mode (observer.sourceOrder.map (fun f => f state')) session node
      match next with
      | .NDactive value => onActive fuel session state' value
      | .NDkilled reason =>
        let session := { session with events := session.events.push (nodeEvent node "killed") }
        if observer.isExhaustion reason then
          errorPath session (.incomplete "model fuel exhausted")
        else completePath session (.killed reason)
      | .NDguard info constraint continuation =>
        let session := { session with
          events := session.events.push (nodeEvent node "guard" (observer.encodeInfo info)) }
        if observer.isTrivialConstraint constraint then resumePath session continuation
        else errorPath session (.refused "nontrivial NDguard constraint")
      | .NDbranch info constraint left right =>
        if observer.isTrivialConstraint constraint then
          chooseHere .branch (observer.encodeInfo info)
            [(Json.mkObj [("side", toJson "left")], left),
             (Json.mkObj [("side", toJson "right")], right)] completePath errorPath resumePath
        else
          let session := { session with
            events := session.events.push (nodeEvent node "branch" (observer.encodeInfo info)) }
          errorPath session (.refused "nontrivial NDbranch constraint")
      | .NDnd info branches =>
        chooseHere .nd (observer.encodeInfo info)
          (branches.map fun (label, branch) => (observer.encodeInfo label, branch))
          completePath errorPath resumePath
      | .NDstep info branches =>
        chooseHere .step (observer.encodeInfo info)
          (branches.map fun (label, branch) => (observer.encodeInfo label, branch))
          completePath errorPath resumePath

private def stop {a err st : Type} (mode : Mode) (header : Header)
    (terminal : Bool) (session : Session) (state : st) (outcome : Outcome a err) : Run a err st :=
  if terminal then finish mode header session state outcome
  else result header session state outcome

private def initial (mode : Mode) (header : Header) : Except String (Header × Session) := do
  let outputHeader := match mode with
    | .record _ => header
    | .replay tape => tape.header
  match mode with
  | .record _ =>
    if header.version != 2 then throw "unsupported choice protocol version"
  | .replay tape => validateTape header tape
  let random := match mode with
    | .record (.seeded seed) => seed
    | _ => 0
  return (outputHeader, { random })

/-- Run one path, recording or strictly replaying positional choices. Neither
    expected outcomes nor other-lane state participate in selection. The caller
    must require LEAN_ABORT_ON_PANIC=1 before evaluating native model code. -/
def run {a info err cs st : Type} (fuel : Nat) (observer : Observer info err cs st)
    (mode : Mode) (header : Header) (machine : ndM a info err cs st) (state : st) :
    Run a err st :=
  match initial mode header with
  | .error reason =>
    let outputHeader := match mode with | .record _ => header | .replay tape => tape.header
    result outputHeader {} state (.inputError reason)
  | .ok (outputHeader, session) =>
    traverseWith fuel observer mode
      (fun _ session state value =>
        let session := { session with
          events := session.events.push (nodeEvent (session.visited - 1) "active") }
        finish mode outputHeader session state (.returned value))
      (stop mode outputHeader) session machine state

/-- Classification of a model's returned payload. A checkpoint contains explicit
    model continuation data; it is not itself a successful program result. -/
inductive Active (a checkpoint : Type) where
  | done (value : a)
  | pause (point : checkpoint)
  /-- Explicit model-budget exhaustion, without terminal tape validation. -/
  | incomplete (reason : String)

/-- Fixed operations for a resumable model. `continueFrom` reconstructs the next
    action from explicit phase data. It must not restart setup, replenish model
    budgets or capture an opaque continuation of the entire driver. -/
structure Adapter (raw a checkpoint info err cs st : Type) where
  classify : raw → Active a checkpoint
  describe : checkpoint → Json
  continueFrom : checkpoint → ndM raw info err cs st

/-- In-memory continuation of both the model and the choice protocol. The
    constructor and protocol internals are private so the ordinary resume API
    cannot replace its mode, observer, tape cursor, RNG or accounting. -/
structure Suspension (raw a checkpoint info err cs st : Type) where
  private mk ::
  private adapter : Adapter raw a checkpoint info err cs st
  private observer : Observer info err cs st
  private mode : Mode
  private header : Header
  private session : Session
  private pointValue : checkpoint
  private stateValue : st
  private fuelLeft : Nat

variable {raw a checkpoint info err cs st : Type}

namespace Suspension

def point (s : Suspension raw a checkpoint info err cs st) : checkpoint := s.pointValue

def state (s : Suspension raw a checkpoint info err cs st) : st := s.stateValue

def remainingFuel (s : Suspension raw a checkpoint info err cs st) : Nat := s.fuelLeft

def visited (s : Suspension raw a checkpoint info err cs st) : Nat := s.session.visited

def tape (s : Suspension raw a checkpoint info err cs st) : Tape :=
  { header := s.header, entries := s.session.entries }

def events (s : Suspension raw a checkpoint info err cs st) : Array Json := s.session.events

end Suspension

inductive Progress (raw a checkpoint info err cs st : Type) where
  | complete (result : Run a err st)
  | suspended (suspension : Suspension raw a checkpoint info err cs st)

private def advanceResumable {raw a checkpoint info err cs st : Type} (fuel : Nat)
    (observer : Observer info err cs st) (mode : Mode) (header : Header)
    (adapter : Adapter raw a checkpoint info err cs st) (session : Session)
    (machine : ndM raw info err cs st) (state : st) :
    Progress raw a checkpoint info err cs st :=
  traverseWith fuel observer mode
    (fun remaining session state value =>
      let node := session.visited - 1
      match adapter.classify value with
      | .done value =>
        let session := { session with events := session.events.push (nodeEvent node "active") }
        .complete (finish mode header session state (.returned value))
      | .pause point =>
        let session := { session with
          events := session.events.push (nodeEvent node "pause" (adapter.describe point)) }
        .suspended (Suspension.mk adapter observer mode header session point state remaining)
      | .incomplete reason =>
        let session := { session with
          events := session.events.push (nodeEvent node "incomplete" (toJson reason)) }
        .complete (result header session state (.incomplete reason)))
    (fun terminal session state outcome => .complete (stop mode header terminal session state outcome))
    session machine state

/-- Start a choice session that may return nonterminal suspensions. Pause nodes
    retain their observer deltas and emit a compact administrative descriptor;
    they consume traversal fuel, but never consume a tape choice or finalize it.
    A client may inspect the returned state, then call `resume` eventually. -/
def startResumable {raw a checkpoint info err cs st : Type} (fuel : Nat)
    (observer : Observer info err cs st) (mode : Mode) (header : Header)
    (adapter : Adapter raw a checkpoint info err cs st)
    (machine : ndM raw info err cs st) (state : st) :
    Progress raw a checkpoint info err cs st :=
  match initial mode header with
  | .error reason =>
    let outputHeader := match mode with | .record _ => header | .replay tape => tape.header
    .complete (result outputHeader {} state (.inputError reason))
  | .ok (outputHeader, session) =>
    advanceResumable fuel observer mode outputHeader adapter session machine state

/-- Continue the same session from the model's saved phase and the exact saved
    state. Nothing is finalized, reseeded or reset between invocations. -/
def resume (s : Suspension raw a checkpoint info err cs st) :
    Progress raw a checkpoint info err cs st :=
  advanceResumable s.fuelLeft s.observer s.mode s.header s.adapter s.session
    (s.adapter.continueFrom s.pointValue) s.stateValue

end CoreNiceDiff.Choice
