/-
SpecLabAudit — arc-15 S1: the speclab IN-BUILD statement-TCB + axiom
gate (the relsem/RelSem/Audit.lean pattern, attributed — the S0
record's "in-build Audit twin, due with S1's first semantics-facing
theorems", now due and delivered).

This file is its OWN default-target lib (NOT under the SpecLab/
statement surface: the grep floor scripts/check_speclab_statements.sh
word-bans the literal proof-layer root names there, and a gate that
must NAME the banned roots cannot live inside its own scan scope —
same reason relsem's Audit sits with the proofs, not the statements): the checks below run inside
the package's plain `lake build` and FAIL THE BUILD on violation.
Two layers:

  1. THE STATEMENT-TCB GATE: a speclab statement's constant closure
     (transitively through SpecLab-rooted Prop-family defs) must not
     reach any `Iris`- or `RelSem`-rooted constant. Structurally the
     SpecLab lib cannot even import those packages today (the one-way
     require direction); this gate makes the invariant survive the
     future proofs-lib require — statements stay in this lib, and the
     gate rides this lib's build. NEGATIVE-TESTED in-build on a
     locally-declared RelSem-rooted probe hidden behind a Prop-def
     wrapper (the audit-1 F2 wrapper-hole lesson).
     SCOPE HONESTY: the full executable/first-order discipline
     (no noncomputable/proposition-valued statement data) is enforced
     by review + the grep floor (scripts/check_speclab_statements.sh);
     this gate mechanizes the Iris/RelSem-reachability core.

  2. CURATED AXIOM PINS: `#guard_msgs in #print axioms` on every S1
     kernel theorem + the pinned program terms + the statement defs.
     Expected sets: subsets of the classical trio for the pure layer;
     the trio + `runEffectful` (the declared boundary, entering
     through the quoted generated `drive` substrate) for anything
     mentioning the runner — exactly the arc-7 slate discipline.
     Growth (sorryAx above all) fails the build.

House rules: no sorry, no axioms declared here.
-/

import Lean
import SpecLab.DivModFiles
import SpecLab.ByteArrFiles

set_option autoImplicit false

/-! ## 1. The statement-TCB gate -/

open Lean in
/-- Syntactic "ends in Prop" (the transitive-unfolding trigger —
relsem Audit's `endsInProp`, verbatim shape). -/
private def slEndsInProp : Expr → Bool
  | .forallE _ _ b _ => slEndsInProp b
  | .mdata _ b => slEndsInProp b
  | .sort l => l == .zero
  | _ => false

open Lean in
/-- Banned-root constants reachable from `n`'s statement through
transitive SpecLab-rooted Prop-def unfolding (empty = pass). -/
def slStmtViolations (env : Environment) (n : Name) :
    Except String (List Name) := do
  let some ci := env.find? n
    | .error s!"speclab statement gate: {n} not found"
  let mut viol : Array Name := #[]
  let mut seen : NameSet := {}
  let mut queue : Array Name := ci.type.getUsedConstants
  while h : queue.size > 0 do
    let c := queue[queue.size - 1]
    queue := queue.pop
    if seen.contains c then continue
    seen := seen.insert c
    if c.getRoot == `Iris || c.getRoot == `RelSem then
      viol := viol.push c
      continue
    if c.getRoot == `SpecLab then
      match env.find? c with
      | some (.defnInfo dv) =>
        if slEndsInProp dv.type then
          queue := queue ++ dv.value.getUsedConstants
        else
          -- non-Prop SpecLab data (codecs, file terms, models) is
          -- statement-legal; its own closure is Iris/RelSem-free by
          -- the lib's import structure, re-walked here for depth
          queue := queue ++ dv.value.getUsedConstants
      | _ => pure ()
  .ok viol.toList

/-- PERMANENT NEGATIVE-TEST FIXTURE: a locally-declared RelSem-rooted
constant (no relsem import — the gate detects by NAME ROOT) hidden
behind a Prop-def wrapper. Probe only, never statement material. -/
def RelSem.speclabGateProbe : Nat := 0

/-- The wrapper hiding the probe (audit-1 F2 wrapper-hole shape). -/
def SpecLab.DivMod.auditWrapperHoleProbe : Prop :=
  RelSem.speclabGateProbe = 0

/-- The probe theorem the gate must REJECT. -/
theorem SpecLab.DivMod.auditWrapperHole_thm :
    SpecLab.DivMod.auditWrapperHoleProbe →
    SpecLab.DivMod.auditWrapperHoleProbe := id

open Lean in
#eval show CoreM Unit from do
  let env ← getEnv
  let statements : List Name :=
    [`SpecLab.DivMod.DivModI8SampleStatement,
     `SpecLab.DivMod.DivModI8SampleStreamStatement,
     `SpecLab.DivMod.DivModI8PlantHealthyClaim,
     `SpecLab.DivMod.sample_model_iff_stream,
     `SpecLab.DivMod.model_forall_iff_stream_forall,
     `SpecLab.DivMod.fileOfStream_encode,
     -- arc-15 S2 (R2 byte-blaster rung)
     `SpecLab.ByteArr.MemcpySampleStatement,
     `SpecLab.ByteArr.MemcpySampleStreamStatement,
     `SpecLab.ByteArr.MemcpyPlantHealthyClaim,
     `SpecLab.ByteArr.GetarrSampleStatement,
     `SpecLab.ByteArr.GetarrPlantHealthyClaim,
     `SpecLab.ByteArr.memcpy_sample_model_iff_stream,
     `SpecLab.ByteArr.model_forall_iff_stream_forall,
     `SpecLab.ByteArr.getarr_model_forall_iff_stream_forall,
     `SpecLab.ByteArr.memcpyFileOfStream_encode]
  for n in statements do
    match slStmtViolations env n with
    | .error e => throwError "{e}"
    | .ok [] => pure ()
    | .ok vs =>
      throwError "speclab statement gate: {n}'s STATEMENT reaches \
        banned constants {vs} — speclab statements are \
        executable/first-order, fuel-opsem only"
  -- NEGATIVE TEST: the wrapper-hole probe must be rejected, seeing
  -- the RelSem-rooted name THROUGH the Prop-def wrapper.
  match slStmtViolations env `SpecLab.DivMod.auditWrapperHole_thm with
  | .error e => throwError "{e}"
  | .ok vs =>
    unless vs.contains `RelSem.speclabGateProbe do
      throwError "speclab statement gate NEGATIVE TEST FAILED: the \
        wrapper-hole probe passed — the transitive walk is not \
        detecting"
  logInfo m!"speclab statement-TCB gate: {statements.length} \
    statements clean; wrapper-hole negative test detecting"

/-! ## 2. Curated axiom pins (exact, fail-closed both directions).
    The expected sets were captured VERBATIM from `#print axioms` at
    S1 and are the permanent bar: any growth — sorryAx above all —
    fails this build. `runEffectful` is the declared boundary axiom
    (BaseIO bridge), entering exactly where a statement quotes the
    generated `drive`/`runND` substrate. -/

/-- info: 'SpecLab.Codec.decode_encode_u8' does not depend on any axioms -/
#guard_msgs in #print axioms SpecLab.Codec.decode_encode_u8
/-- info: 'SpecLab.Codec.decode_encode_u16le' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.Codec.decode_encode_u16le
/-- info: 'SpecLab.Codec.decode_encode_u32le' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.Codec.decode_encode_u32le
/-- info: 'SpecLab.Codec.decode_encode_u64le' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.Codec.decode_encode_u64le
/-- info: 'SpecLab.Codec.decodeElems_encodeElems' depends on axioms: [propext] -/
#guard_msgs in #print axioms SpecLab.Codec.decodeElems_encodeElems
/-- info: 'SpecLab.Codec.decode_encode_arrayU16' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.Codec.decode_encode_arrayU16
/-- info: 'SpecLab.DivMod.ofU32_toU32' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.DivMod.ofU32_toU32
/-- info: 'SpecLab.DivMod.toU32_ofU32' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.DivMod.toU32_ofU32
/-- info: 'SpecLab.DivMod.decode_encode_i32le' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.DivMod.decode_encode_i32le
/-- info: 'SpecLab.DivMod.encode_decode_u16le' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.DivMod.encode_decode_u16le
/-- info: 'SpecLab.DivMod.encode_decode_u32le' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.DivMod.encode_decode_u32le
/-- info: 'SpecLab.DivMod.encode_decode_i32le'' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.DivMod.encode_decode_i32le'
/-- info: 'SpecLab.DivMod.decode_encode_input' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.DivMod.decode_encode_input
/-- info: 'SpecLab.DivMod.encode_decode_input' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.DivMod.encode_decode_input
/-- info: 'SpecLab.DivMod.model_forall_iff_stream_forall' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.DivMod.model_forall_iff_stream_forall
/-- info: 'SpecLab.DivMod.divmod_reconstruction' depends on axioms: [propext] -/
#guard_msgs in #print axioms SpecLab.DivMod.divmod_reconstruction
/-- info: 'SpecLab.DivMod.modelMod_bound' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.DivMod.modelMod_bound
/-- info: 'SpecLab.DivMod.modelDiv_inRange' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.DivMod.modelDiv_inRange
/-- info: 'SpecLab.DivMod.modelMod_inRange' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.DivMod.modelMod_inRange
/-- info: 'SpecLab.DivMod.ofByteI8_toByteI8' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.DivMod.ofByteI8_toByteI8
/-- info: 'SpecLab.DivMod.decode_encode_inputI8' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.DivMod.decode_encode_inputI8
/-- info: 'SpecLab.DivMod.fileOfStream_encode' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.DivMod.fileOfStream_encode
/-- info: 'SpecLab.DivMod.sample_model_iff_stream' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.DivMod.sample_model_iff_stream
/-- info: 'SpecLab.DivMod.divmodI8File' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.DivMod.divmodI8File
/-- info: 'SpecLab.DivMod.divmodI8PlantFile' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.DivMod.divmodI8PlantFile
/-- info: 'SpecLab.DivMod.divmodI8FileOf' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.DivMod.divmodI8FileOf
/-- info: 'SpecLab.DivMod.DivModI8SampleStatement' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.DivMod.DivModI8SampleStatement
/-- info: 'SpecLab.DivMod.DivModI8SampleStreamStatement' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.DivMod.DivModI8SampleStreamStatement
/-- info: 'SpecLab.DivMod.DivModI8PlantHealthyClaim' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.DivMod.DivModI8PlantHealthyClaim
/-- info: 'SpecLab.DivModCore.mainParamDecl' does not depend on any axioms -/
#guard_msgs in #print axioms SpecLab.DivModCore.mainParamDecl
/-- info: 'SpecLab.DivModCore.divisionDecl' does not depend on any axioms -/
#guard_msgs in #print axioms SpecLab.DivModCore.divisionDecl

/-! ### arc-15 S2 pins (R2 byte-blaster rung; captured verbatim at
    S2 — same discipline: classical-trio subsets for the pure layer,
    `runEffectful` exactly where a statement quotes the drive
    substrate, AST terms axiom-free). -/

/-- info: 'SpecLab.Codec.canonical_u8' depends on axioms: [propext] -/
#guard_msgs in #print axioms SpecLab.Codec.canonical_u8
/-- info: 'SpecLab.Codec.canonical_u16le' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.Codec.canonical_u16le
/-- info: 'SpecLab.Codec.decodeElems_length' depends on axioms: [propext] -/
#guard_msgs in #print axioms SpecLab.Codec.decodeElems_length
/-- info: 'SpecLab.Codec.encodeElems_decodeElems' depends on axioms: [propext] -/
#guard_msgs in #print axioms SpecLab.Codec.encodeElems_decodeElems
/-- info: 'SpecLab.Codec.canonical_arrayU16' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.Codec.canonical_arrayU16
/-- info: 'SpecLab.Codec.encodeElems_u8_id' depends on axioms: [propext] -/
#guard_msgs in #print axioms SpecLab.Codec.encodeElems_u8_id
/-- info: 'SpecLab.ByteArr.decode_encode_input' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ByteArr.decode_encode_input
/-- info: 'SpecLab.ByteArr.encode_decode_input' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ByteArr.encode_decode_input
/-- info: 'SpecLab.ByteArr.model_forall_iff_stream_forall' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ByteArr.model_forall_iff_stream_forall
/-- info: 'SpecLab.ByteArr.getarr_model_forall_iff_stream_forall' depends on axioms: [propext] -/
#guard_msgs in #print axioms SpecLab.ByteArr.getarr_model_forall_iff_stream_forall
/-- info: 'SpecLab.ByteArr.src_unchanged' does not depend on any axioms -/
#guard_msgs in #print axioms SpecLab.ByteArr.src_unchanged
/-- info: 'SpecLab.ByteArr.dst_copied' depends on axioms: [propext] -/
#guard_msgs in #print axioms SpecLab.ByteArr.dst_copied
/-- info: 'SpecLab.ByteArr.expectedBytes_length' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ByteArr.expectedBytes_length
/-- info: 'SpecLab.ByteArr.getarrExpected_length' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ByteArr.getarrExpected_length
/-- info: 'SpecLab.ByteArr.verdictOf_eq_zero_iff' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ByteArr.verdictOf_eq_zero_iff
/-- info: 'SpecLab.ByteArr.encodeElems_u16_flatten' depends on axioms: [propext] -/
#guard_msgs in #print axioms SpecLab.ByteArr.encodeElems_u16_flatten
/-- info: 'SpecLab.ByteArr.structured_forall_of_byte_forall' does not depend on any axioms -/
#guard_msgs in #print axioms SpecLab.ByteArr.structured_forall_of_byte_forall
/-- info: 'SpecLab.ByteArr.memcpyFileOfStream_encode' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ByteArr.memcpyFileOfStream_encode
/--
info: 'SpecLab.ByteArr.memcpy_sample_model_iff_stream' depends on axioms: [propext,
 runEffectful,
 Classical.choice,
 Quot.sound]
-/
#guard_msgs in #print axioms SpecLab.ByteArr.memcpy_sample_model_iff_stream
/-- info: 'SpecLab.ByteArr.MemcpySampleStatement' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ByteArr.MemcpySampleStatement
/-- info: 'SpecLab.ByteArr.MemcpySampleStreamStatement' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ByteArr.MemcpySampleStreamStatement
/-- info: 'SpecLab.ByteArr.MemcpyPlantHealthyClaim' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ByteArr.MemcpyPlantHealthyClaim
/-- info: 'SpecLab.ByteArr.GetarrSampleStatement' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ByteArr.GetarrSampleStatement
/-- info: 'SpecLab.ByteArr.GetarrPlantHealthyClaim' depends on axioms: [propext, runEffectful, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ByteArr.GetarrPlantHealthyClaim
/-- info: 'SpecLab.ByteArr.memcpyI3File' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ByteArr.memcpyI3File
/-- info: 'SpecLab.ByteArr.memcpyPlantFile' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ByteArr.memcpyPlantFile
/-- info: 'SpecLab.ByteArr.memcpyFileOf' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ByteArr.memcpyFileOf
/-- info: 'SpecLab.ByteArr.getarrFileA' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ByteArr.getarrFileA
/-- info: 'SpecLab.ByteArr.getarrFileB' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ByteArr.getarrFileB
/-- info: 'SpecLab.ByteArr.getarrPlantFile' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ByteArr.getarrPlantFile
/-- info: 'SpecLab.ByteArrCore.memcpyMainParamDecl' does not depend on any axioms -/
#guard_msgs in #print axioms SpecLab.ByteArrCore.memcpyMainParamDecl
/-- info: 'SpecLab.ByteArrCore.naiveMemcpyDecl' does not depend on any axioms -/
#guard_msgs in #print axioms SpecLab.ByteArrCore.naiveMemcpyDecl
/-- info: 'SpecLab.ByteArrCore.getarrMainADecl' does not depend on any axioms -/
#guard_msgs in #print axioms SpecLab.ByteArrCore.getarrMainADecl
