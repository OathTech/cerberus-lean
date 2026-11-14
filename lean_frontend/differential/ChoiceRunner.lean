import Nondeterminism
import Lean

/- A positional choice protocol for the initially unchanged Core/CoreB paths.
   The ND action is evaluated once at each visited node. Only compact observer
   events and choice descriptors leave the machine; states stay in memory. -/

namespace CoreBDiff.Choice

open Lean

structure Header where
  version : Nat := 1
  input : String
  prepared : String
  config : Json
  coreBuild : String
  coreBBuild : String
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
  expected.coreBuild == actual.coreBuild && expected.coreBBuild == actual.coreBBuild

def validateTape (expected : Header) (tape : Tape) : Except String Unit := do
  if expected.version != 1 || tape.header.version != 1 then
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
  let checked := match mode with
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

private def choose {a info err cs st : Type} (mode : Mode) (header : Header)
    (session : Session) (state : st) (node : Nat) (kind : Kind) (parent : Json)
    (branches : List (Json × ndM a info err cs st))
    (continue : Session → ndM a info err cs st → Run a err st) : Run a err st :=
  let alternatives := (branches.map Prod.fst).toArray
  match branches with
  | [] =>
    let session := { session with events := session.events.push
      (nodeEvent node kind.label parent alternatives) }
    finish mode header session state .empty
  | [(_, continuation)] =>
    let session := { session with events := session.events.push
      (nodeEvent node kind.label parent alternatives (some 0)) }
    continue session continuation
  | _ :: _ :: _ =>
    match selected mode session kind parent alternatives with
    | .error (replaying, reason) =>
      let session := { session with events := session.events.push
        (nodeEvent node kind.label parent alternatives) }
      result header session state
        (if replaying then .replayMismatch reason else .inputError reason)
    | .ok (index, random) =>
      match branches[index]? with
      | none => result header session state (.inputError "selected branch is out of range")
      | some (_, continuation) =>
        let entry : Entry := { ordinal := session.entries.size, kind, parent, alternatives, index }
        let session := { session with entries := session.entries.push entry, random,
          events := session.events.push (nodeEvent node kind.label parent alternatives (some index)) }
        continue session continuation

private def traverse {a info err cs st : Type} (fuel : Nat)
    (observer : Observer info err cs st) (mode : Mode) (header : Header)
    (session : Session) (machine : ndM a info err cs st) (state : st) : Run a err st :=
  match fuel with
  | 0 => result header session state (.incomplete "ND traversal fuel exhausted")
  | fuel + 1 =>
    let .ND action := machine
    -- There is exactly one call to the actual ND action at this node.
    let (next, state') := action state
    let node := session.visited
    let session := { session with visited := node + 1 }
    match observer.observeDelta state state' with
    | .error reason => result header session state' (.observationError reason)
    | .ok delta =>
      let session := { session with events := session.events ++ delta }
      let continue := fun session machine => traverse fuel observer mode header session machine state'
      match next with
      | .NDactive value =>
        let session := { session with events := session.events.push (nodeEvent node "active") }
        finish mode header session state' (.returned value)
      | .NDkilled reason =>
        let session := { session with events := session.events.push (nodeEvent node "killed") }
        if observer.isExhaustion reason then
          result header session state' (.incomplete "model fuel exhausted")
        else finish mode header session state' (.killed reason)
      | .NDguard info constraint continuation =>
        let session := { session with events := session.events.push
          (nodeEvent node "guard" (observer.encodeInfo info)) }
        if observer.isTrivialConstraint constraint then continue session continuation
        else result header session state' (.refused "nontrivial NDguard constraint")
      | .NDbranch info constraint left right =>
        if observer.isTrivialConstraint constraint then
          choose mode header session state' node .branch (observer.encodeInfo info)
            [(Json.mkObj [("side", toJson "left")], left),
             (Json.mkObj [("side", toJson "right")], right)] continue
        else
          let session := { session with events := session.events.push
            (nodeEvent node "branch" (observer.encodeInfo info)) }
          result header session state' (.refused "nontrivial NDbranch constraint")
      | .NDnd info branches =>
        choose mode header session state' node .nd (observer.encodeInfo info)
          (branches.map fun (label, branch) => (observer.encodeInfo label, branch)) continue
      | .NDstep info branches =>
        choose mode header session state' node .step (observer.encodeInfo info)
          (branches.map fun (label, branch) => (observer.encodeInfo label, branch)) continue

/-- Run one path, recording or strictly replaying positional choices. Neither
    expected outcomes nor other-lane state participate in selection. The caller
    must require LEAN_ABORT_ON_PANIC=1 before evaluating native model code. -/
def run {a info err cs st : Type} (fuel : Nat) (observer : Observer info err cs st)
    (mode : Mode) (header : Header) (machine : ndM a info err cs st) (state : st) :
    Run a err st :=
  let outputHeader := match mode with
    | .record _ => header
    | .replay tape => tape.header
  let validation := match mode with
    | .record _ => if header.version == 1 then .ok () else .error "unsupported choice protocol version"
    | .replay tape => validateTape header tape
  match validation with
  | .error reason => result outputHeader {} state (.inputError reason)
  | .ok () =>
    let random := match mode with
      | .record (.seeded seed) => seed
      | _ => 0
    traverse fuel observer mode outputHeader { random } machine state

end CoreBDiff.Choice
