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
     Expected sets: subsets of the classical trio EVERYWHERE — since
     the arc-18 C4 threading (statements at the seed-parametric
     `initial_driver_state_threaded`, R6-homed semantics-side) no
     speclab statement or lemma carries `runEffectful` any more (the
     S2b-registered prize, delivered; the ambient originals wore the
     quartet through the quoted ambient initial state).
     Growth (sorryAx above all) fails the build.

House rules: no sorry, no axioms declared here.
-/

import Lean
import SpecLab.DivModFiles
import SpecLab.ByteArrFiles
import SpecLab.ListAppendFiles
import SpecLab.TreeRotFiles
import SpecLab.CnSeedFiles

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
/-- THE HOMED STATEMENT VOCABULARY (arc-18 C4, register row R6): the
threaded initial state + whole-program face live SEMANTICS-SIDE
(relsemcore/RelSem/Threaded.lean — the exec-facing RelSemCore lib of
the ROOT package, not the proof package), so speclab statements may
reach EXACTLY these four `RelSem.Cerb` names. The allowlist is
exact-name (never root- or prefix-level); allowed constants are still
WALKED THROUGH (their closures scanned — defense in depth), and every
other RelSem- or Iris-rooted constant remains a violation.
Provenance: the blessed arc-18 charter C4 ([USER 2026-08-25]) +
contracts doc §5 target vocabulary / §6 R6. -/
def slAllowedSemanticsSide : List Name :=
  [`RelSem.Cerb.HarnessRunsToThr,
   `RelSem.Cerb.initial_driver_state_threaded,
   `RelSem.Cerb.initial_core_run_state_threaded,
   `RelSem.Cerb.specifiedInt]

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
      if slAllowedSemanticsSide.contains c then
        -- homed statement vocabulary: legal, but walk THROUGH it so
        -- nothing banned can smuggle behind an allowed name
        match env.find? c with
        | some (.defnInfo dv) => queue := queue ++ dv.value.getUsedConstants
        | _ => pure ()
        continue
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
     `SpecLab.ByteArr.memcpyFileOfStream_encode,
     -- arc-15 S3 (R3 list rung, incl. the live leak conjunct)
     `SpecLab.ListAppend.AppendSampleStatement,
     `SpecLab.ListAppend.AppendSampleStreamStatement,
     `SpecLab.ListAppend.BuildOnlyStatement,
     `SpecLab.ListAppend.AppendLinkPlantHealthyClaim,
     `SpecLab.ListAppend.AppendElemPlantHealthyClaim,
     `SpecLab.ListAppend.AppendSampleLeakStatement,
     `SpecLab.ListAppend.BuildOnlyLeakStatement,
     `SpecLab.ListAppend.LinkPlantLeakClaim,
     `SpecLab.ListAppend.append_sample_model_iff_stream,
     `SpecLab.ListAppend.model_forall_iff_stream_forall,
     `SpecLab.ListAppend.appendFileOfStream_encode,
     -- arc-15 S4 (R4 tree rung, the reference instance)
     `SpecLab.TreeRot.RotateSampleStatement,
     `SpecLab.TreeRot.RotateSampleStreamStatement,
     `SpecLab.TreeRot.RotatePathSampleStatement,
     `SpecLab.TreeRot.BuildOnlyStatement,
     `SpecLab.TreeRot.SwapPlantHealthyClaim,
     `SpecLab.TreeRot.DropPlantHealthyClaim,
     `SpecLab.TreeRot.RotateSampleLeakStatement,
     `SpecLab.TreeRot.RotatePathSampleLeakStatement,
     `SpecLab.TreeRot.BuildOnlyLeakStatement,
     `SpecLab.TreeRot.SwapPlantLeakStatement,
     `SpecLab.TreeRot.DropPlantLeakClaim,
     `SpecLab.TreeRot.rotate_sample_model_iff_stream,
     `SpecLab.TreeRot.model_forall_iff_stream_forall,
     `SpecLab.TreeRot.rotateFileOfStream_encode,
     -- arc-15 S5 (R5 CN-seed rung: the swap statement family; lookup
     -- has no pinned layer — the CoreParser enum-ctype gap)
     `SpecLab.CnSeed.SwapSampleStatement,
     `SpecLab.CnSeed.SwapSampleStreamStatement,
     `SpecLab.CnSeed.SwapPlantHealthyClaim,
     `SpecLab.CnSeed.swap_sample_model_iff_stream,
     `SpecLab.CnSeed.model_forall_iff_stream_forall,
     `SpecLab.CnSeed.swapFileOfStream_encode]
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
    fails this build. Since arc-18 C4 no pin here carries
    `runEffectful`: the threaded statements quote the seed-parametric
    initial state, and the boundary axiom's only remaining carriers
    repo-wide are the ambient relsem family (C5-bound). -/

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
/-- info: 'SpecLab.DivMod.sample_model_iff_stream' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.DivMod.sample_model_iff_stream
/-- info: 'SpecLab.DivMod.divmodI8File' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.DivMod.divmodI8File
/-- info: 'SpecLab.DivMod.divmodI8PlantFile' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.DivMod.divmodI8PlantFile
/-- info: 'SpecLab.DivMod.divmodI8FileOf' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.DivMod.divmodI8FileOf
/-- info: 'SpecLab.DivMod.DivModI8SampleStatement' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.DivMod.DivModI8SampleStatement
/-- info: 'SpecLab.DivMod.DivModI8SampleStreamStatement' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.DivMod.DivModI8SampleStreamStatement
/-- info: 'SpecLab.DivMod.DivModI8PlantHealthyClaim' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.DivMod.DivModI8PlantHealthyClaim
/-- info: 'SpecLab.DivModCore.mainParamDecl' does not depend on any axioms -/
#guard_msgs in #print axioms SpecLab.DivModCore.mainParamDecl
/-- info: 'SpecLab.DivModCore.divisionDecl' does not depend on any axioms -/
#guard_msgs in #print axioms SpecLab.DivModCore.divisionDecl

/-! ### arc-15 S2 pins (R2 byte-blaster rung; captured verbatim at
    S2 — same discipline: classical-trio subsets for the pure layer,
    (re-pinned trio at arc-18 C4: the threading removed
    `runEffectful` from the statement cones), AST terms axiom-free). -/

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
/-- info: 'SpecLab.ByteArr.memcpy_sample_model_iff_stream' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ByteArr.memcpy_sample_model_iff_stream
/-- info: 'SpecLab.ByteArr.MemcpySampleStatement' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ByteArr.MemcpySampleStatement
/-- info: 'SpecLab.ByteArr.MemcpySampleStreamStatement' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ByteArr.MemcpySampleStreamStatement
/-- info: 'SpecLab.ByteArr.MemcpyPlantHealthyClaim' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ByteArr.MemcpyPlantHealthyClaim
/-- info: 'SpecLab.ByteArr.GetarrSampleStatement' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ByteArr.GetarrSampleStatement
/-- info: 'SpecLab.ByteArr.GetarrPlantHealthyClaim' depends on axioms: [propext, Classical.choice, Quot.sound] -/
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

/-! ### arc-15 S3 pins (R3 list rung; captured verbatim at S3 — same
    discipline: classical-trio subsets for the pure layer,
    (re-pinned trio at arc-18 C4: the threading removed
    `runEffectful` from the statement cones) — the leak statements included, AST terms axiom-free). -/

/-- info: 'SpecLab.Codec.decodeElems_encodeElems_of' depends on axioms: [propext] -/
#guard_msgs in #print axioms SpecLab.Codec.decodeElems_encodeElems_of
/-- info: 'SpecLab.Codec.decode_encode_arrayU16_of' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.Codec.decode_encode_arrayU16_of
/-- info: 'SpecLab.ListAppend.decode_encode_list' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ListAppend.decode_encode_list
/-- info: 'SpecLab.ListAppend.decode_encode_input' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ListAppend.decode_encode_input
/-- info: 'SpecLab.ListAppend.canonical_i32le' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ListAppend.canonical_i32le
/-- info: 'SpecLab.ListAppend.canonical_list' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ListAppend.canonical_list
/-- info: 'SpecLab.ListAppend.encode_decode_input' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ListAppend.encode_decode_input
/-- info: 'SpecLab.ListAppend.model_forall_iff_stream_forall' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ListAppend.model_forall_iff_stream_forall
/-- info: 'SpecLab.ListAppend.append_is_model' does not depend on any axioms -/
#guard_msgs in #print axioms SpecLab.ListAppend.append_is_model
/-- info: 'SpecLab.ListAppend.modelFn_length' depends on axioms: [propext] -/
#guard_msgs in #print axioms SpecLab.ListAppend.modelFn_length
/-- info: 'SpecLab.ListAppend.modelFn_fits' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ListAppend.modelFn_fits
/-- info: 'SpecLab.ListAppend.modelFn_inRange' depends on axioms: [propext] -/
#guard_msgs in #print axioms SpecLab.ListAppend.modelFn_inRange
/-- info: 'SpecLab.ListAppend.alloc_free_balance' depends on axioms: [propext] -/
#guard_msgs in #print axioms SpecLab.ListAppend.alloc_free_balance
/-- info: 'SpecLab.ListAppend.linkSkip_leaks' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ListAppend.linkSkip_leaks
/-- info: 'SpecLab.ListAppend.xorOne_inRange' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ListAppend.xorOne_inRange
/-- info: 'SpecLab.ListAppend.xorOne_ne' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ListAppend.xorOne_ne
/-- info: 'SpecLab.ListAppend.appendFileOfStream_encode' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ListAppend.appendFileOfStream_encode
/-- info: 'SpecLab.ListAppend.append_sample_model_iff_stream' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ListAppend.append_sample_model_iff_stream
/-- info: 'SpecLab.ListAppend.AppendSampleStatement' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ListAppend.AppendSampleStatement
/-- info: 'SpecLab.ListAppend.AppendSampleStreamStatement' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ListAppend.AppendSampleStreamStatement
/-- info: 'SpecLab.ListAppend.BuildOnlyStatement' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ListAppend.BuildOnlyStatement
/-- info: 'SpecLab.ListAppend.AppendLinkPlantHealthyClaim' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ListAppend.AppendLinkPlantHealthyClaim
/-- info: 'SpecLab.ListAppend.AppendElemPlantHealthyClaim' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ListAppend.AppendElemPlantHealthyClaim
/-- info: 'SpecLab.ListAppend.HarnessFinalAllocs' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ListAppend.HarnessFinalAllocs
/-- info: 'SpecLab.ListAppend.AppendSampleLeakStatement' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ListAppend.AppendSampleLeakStatement
/-- info: 'SpecLab.ListAppend.BuildOnlyLeakStatement' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ListAppend.BuildOnlyLeakStatement
/-- info: 'SpecLab.ListAppend.LinkPlantLeakClaim' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ListAppend.LinkPlantLeakClaim
/-- info: 'SpecLab.ListAppend.appendI12File' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ListAppend.appendI12File
/-- info: 'SpecLab.ListAppend.appendLinkPlantFile' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ListAppend.appendLinkPlantFile
/-- info: 'SpecLab.ListAppend.appendElemPlantFile' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ListAppend.appendElemPlantFile
/-- info: 'SpecLab.ListAppend.appendBuildFile' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ListAppend.appendBuildFile
/-- info: 'SpecLab.ListAppend.appendFileOf' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.ListAppend.appendFileOf
/-- info: 'SpecLab.ListAppendCore.appendMainParamDecl' does not depend on any axioms -/
#guard_msgs in #print axioms SpecLab.ListAppendCore.appendMainParamDecl
/-- info: 'SpecLab.ListAppendCore.intListAppendDecl' does not depend on any axioms -/
#guard_msgs in #print axioms SpecLab.ListAppendCore.intListAppendDecl
/-- info: 'SpecLab.ListAppendCore.intListTagDef' does not depend on any axioms -/
#guard_msgs in #print axioms SpecLab.ListAppendCore.intListTagDef
/-- info: 'SpecLab.ListAppendCore.mallocProxyDecl' does not depend on any axioms -/
#guard_msgs in #print axioms SpecLab.ListAppendCore.mallocProxyDecl
/-- info: 'SpecLab.ListAppendCore.freeProxyDecl' does not depend on any axioms -/
#guard_msgs in #print axioms SpecLab.ListAppendCore.freeProxyDecl

/-! ### arc-15 S4 pins (R4 tree rung; captured verbatim at S4 — same
    discipline: classical-trio subsets for the pure layer,
    (re-pinned trio at arc-18 C4: the threading removed
    `runEffectful` from the statement cones) — the leak statements included, AST terms axiom-free). -/

/-- info: 'SpecLab.TreeRot.decodeTreeF_mono' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.decodeTreeF_mono
/-- info: 'SpecLab.TreeRot.decodeTreeF_encode' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.decodeTreeF_encode
/-- info: 'SpecLab.TreeRot.decode_encode_tree' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.decode_encode_tree
/-- info: 'SpecLab.TreeRot.decode_encode_path' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.decode_encode_path
/-- info: 'SpecLab.TreeRot.decode_encode_input' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.decode_encode_input
/-- info: 'SpecLab.TreeRot.encode_decodeTreeF' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.encode_decodeTreeF
/-- info: 'SpecLab.TreeRot.canonical_tree' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.canonical_tree
/-- info: 'SpecLab.TreeRot.canonical_path' depends on axioms: [propext] -/
#guard_msgs in #print axioms SpecLab.TreeRot.canonical_path
/-- info: 'SpecLab.TreeRot.encode_decode_input' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.encode_decode_input
/-- info: 'SpecLab.TreeRot.model_forall_iff_stream_forall' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.model_forall_iff_stream_forall
/-- info: 'SpecLab.TreeRot.rotateRight_size' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.rotateRight_size
/-- info: 'SpecLab.TreeRot.rotateAt_size' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.rotateAt_size
/-- info: 'SpecLab.TreeRot.swapPlant_size' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.swapPlant_size
/-- info: 'SpecLab.TreeRot.dropPlant_size' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.dropPlant_size
/-- info: 'SpecLab.TreeRot.rotateAt_valsOk' depends on axioms: [propext] -/
#guard_msgs in #print axioms SpecLab.TreeRot.rotateAt_valsOk
/-- info: 'SpecLab.TreeRot.expectedBytes_fits' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.expectedBytes_fits
/-- info: 'SpecLab.TreeRot.rotateAt_as_replace' depends on axioms: [propext] -/
#guard_msgs in #print axioms SpecLab.TreeRot.rotateAt_as_replace
/-- info: 'SpecLab.TreeRot.rotateAt_frame' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.rotateAt_frame
/-- info: 'SpecLab.TreeRot.rotateFileOfStream_encode' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.rotateFileOfStream_encode
/-- info: 'SpecLab.TreeRot.rotate_sample_model_iff_stream' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.rotate_sample_model_iff_stream
/-- info: 'SpecLab.TreeRot.RotateSampleStatement' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.RotateSampleStatement
/-- info: 'SpecLab.TreeRot.RotateSampleStreamStatement' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.RotateSampleStreamStatement
/-- info: 'SpecLab.TreeRot.RotatePathSampleStatement' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.RotatePathSampleStatement
/-- info: 'SpecLab.TreeRot.BuildOnlyStatement' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.BuildOnlyStatement
/-- info: 'SpecLab.TreeRot.SwapPlantHealthyClaim' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.SwapPlantHealthyClaim
/-- info: 'SpecLab.TreeRot.DropPlantHealthyClaim' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.DropPlantHealthyClaim
/-- info: 'SpecLab.TreeRot.RotateSampleLeakStatement' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.RotateSampleLeakStatement
/-- info: 'SpecLab.TreeRot.RotatePathSampleLeakStatement' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.RotatePathSampleLeakStatement
/-- info: 'SpecLab.TreeRot.BuildOnlyLeakStatement' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.BuildOnlyLeakStatement
/-- info: 'SpecLab.TreeRot.SwapPlantLeakStatement' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.SwapPlantLeakStatement
/-- info: 'SpecLab.TreeRot.DropPlantLeakClaim' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.DropPlantLeakClaim
/-- info: 'SpecLab.TreeRot.rotateI24File' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.rotateI24File
/-- info: 'SpecLab.TreeRot.rotateRootFile' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.rotateRootFile
/-- info: 'SpecLab.TreeRot.rotateDeepFile' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.rotateDeepFile
/-- info: 'SpecLab.TreeRot.swapPlantFile' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.swapPlantFile
/-- info: 'SpecLab.TreeRot.dropPlantFile' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.dropPlantFile
/-- info: 'SpecLab.TreeRot.rotateBuildFile' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.rotateBuildFile
/-- info: 'SpecLab.TreeRot.rotateFileOf' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.TreeRot.rotateFileOf
/-- info: 'SpecLab.TreeRotCore.rotateMainParamDecl' does not depend on any axioms -/
#guard_msgs in #print axioms SpecLab.TreeRotCore.rotateMainParamDecl
/-- info: 'SpecLab.TreeRotCore.rotateRightDecl' does not depend on any axioms -/
#guard_msgs in #print axioms SpecLab.TreeRotCore.rotateRightDecl
/-- info: 'SpecLab.TreeRotCore.nodeTagDef' does not depend on any axioms -/
#guard_msgs in #print axioms SpecLab.TreeRotCore.nodeTagDef
/-- info: 'SpecLab.TreeRotCore.rootMainDecl' does not depend on any axioms -/
#guard_msgs in #print axioms SpecLab.TreeRotCore.rootMainDecl
/-- info: 'SpecLab.TreeRotCore.swapRotateRightDecl' does not depend on any axioms -/
#guard_msgs in #print axioms SpecLab.TreeRotCore.swapRotateRightDecl

/-! ### arc-15 S5 pins (R5 CN-seed rung; captured verbatim at S5 —
    same discipline: classical-trio subsets for the pure layer
    (re-pinned trio at arc-18 C4: the threading removed
    `runEffectful` from the statement cones), AST terms axiom-free.
    The S5 novelties: the
    Wf-free bridge (full-domain swap model), the kernel-characterized
    plant blind set (`swapPlant_blind_iff`), and the library
    canonicity completions (`canonical_u32le`/`canonical_u64le`). -/

/-- info: 'SpecLab.Codec.canonical_u32le' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.Codec.canonical_u32le
/-- info: 'SpecLab.Codec.canonical_u64le' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.Codec.canonical_u64le
/-- info: 'SpecLab.CnSeed.swap_post' does not depend on any axioms -/
#guard_msgs in #print axioms SpecLab.CnSeed.swap_post
/-- info: 'SpecLab.CnSeed.swap_involutive' does not depend on any axioms -/
#guard_msgs in #print axioms SpecLab.CnSeed.swap_involutive
/-- info: 'SpecLab.CnSeed.decode_encode_pair' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.CnSeed.decode_encode_pair
/-- info: 'SpecLab.CnSeed.encode_decode_pair' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.CnSeed.encode_decode_pair
/-- info: 'SpecLab.CnSeed.encodeU64LE_inj' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.CnSeed.encodeU64LE_inj
/-- info: 'SpecLab.CnSeed.model_forall_iff_stream_forall' depends on axioms: [propext, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.CnSeed.model_forall_iff_stream_forall
/-- info: 'SpecLab.CnSeed.swapPlant_blind_iff' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.CnSeed.swapPlant_blind_iff
/-- info: 'SpecLab.CnSeed.lookup_is_model' does not depend on any axioms -/
#guard_msgs in #print axioms SpecLab.CnSeed.lookup_is_model
/-- info: 'SpecLab.CnSeed.lookup_bounds' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.CnSeed.lookup_bounds
/-- info: 'SpecLab.CnSeed.f_model_lt_1000' does not depend on any axioms -/
#guard_msgs in #print axioms SpecLab.CnSeed.f_model_lt_1000
/-- info: 'SpecLab.CnSeed.lookup_inRange' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.CnSeed.lookup_inRange
/-- info: 'SpecLab.CnSeed.swapFileOfStream_encode' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.CnSeed.swapFileOfStream_encode
/-- info: 'SpecLab.CnSeed.swap_sample_model_iff_stream' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.CnSeed.swap_sample_model_iff_stream
/-- info: 'SpecLab.CnSeed.SwapSampleStatement' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.CnSeed.SwapSampleStatement
/-- info: 'SpecLab.CnSeed.SwapSampleStreamStatement' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.CnSeed.SwapSampleStreamStatement
/-- info: 'SpecLab.CnSeed.SwapPlantHealthyClaim' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.CnSeed.SwapPlantHealthyClaim
/-- info: 'SpecLab.CnSeed.swapFileOf' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.CnSeed.swapFileOf
/-- info: 'SpecLab.CnSeed.pairSwapPlantFile' depends on axioms: [propext, Classical.choice, Quot.sound] -/
#guard_msgs in #print axioms SpecLab.CnSeed.pairSwapPlantFile
/-- info: 'SpecLab.CnSeedCore.swapMainParamDecl' does not depend on any axioms -/
#guard_msgs in #print axioms SpecLab.CnSeedCore.swapMainParamDecl
/-- info: 'SpecLab.CnSeedCore.swapPairDecl' does not depend on any axioms -/
#guard_msgs in #print axioms SpecLab.CnSeedCore.swapPairDecl
/-- info: 'SpecLab.CnSeedCore.swapPairPlantDecl' does not depend on any axioms -/
#guard_msgs in #print axioms SpecLab.CnSeedCore.swapPairPlantDecl
/-- info: 'SpecLab.CnSeedCore.ctypeWidthDecl' does not depend on any axioms -/
#guard_msgs in #print axioms SpecLab.CnSeedCore.ctypeWidthDecl
