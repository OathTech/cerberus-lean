/-
SpecLab.TreeRotFiles — arc-15 S4: the R4 tree-rotation FILE TERMS and
the exec-level STATEMENTS (rotate_right — THE REFERENCE INSTANCE),
including the leak conjunct (the R3 observable, reused) and the
POINTER-SELECTION STATEMENT FAMILY (the path is model/stream data:
the parametric family quantifies vals at the pinned path, and the
verbatim path instances pin further paths — root and depth-2).

Assembly follows the S1-S3 pattern (arc-7 T1File lineage): pinned
parsed declarations (SpecLab/TreeRotCore.lean, generated +
drift-gated) + hand-pinned funinfo metadata, `main := some mainSym`.
R4 firsts: SIX procs per TU (target + the recursive helper trio +
free + main) — funinfo carries all of them, per-TU symbol sets
(`TUSyms`), and the S3 symbol-numbering-coupling finding bites per
helper: the root/deep/build TUs are assembled entirely from their own
dumps' decls; the plant TUs share the healthy helper decls (asserted
byte-identical at emission).

THE LEAK OBSERVABLE: `ListAppend.HarnessFinalAllocs` +
`ListAppend.driverBaseline` REUSED VERBATIM (the R3 observable is
target-independent — idiom library). Rotation is ALLOCATION-NEUTRAL
(`TreeRot.rotateAt_size` is the pure face), so every healthy
statement pins the driver baseline; the DROPPED-SUBTREE plant pins
baseline + 1 (the orphaned middle subtree at the pinned instance,
`orphanedAt = 1`), and the WRONG-CHILD-SWAP plant pins the BASELINE
itself — a broken-but-leak-free target, the observable's green
contrast (its pure face: `TreeRot.swapPlant_size`).

STATEMENT DISCIPLINE: statement surface (gate-scanned) — fuel-opsem
vocabulary only.
-/

import Core_run_aux
import Driver
import CerbND
import SpecLab.TreeRot
import SpecLab.TreeRotHarness
import SpecLab.TreeRotCore
import SpecLab.DivModFiles
import SpecLab.ListAppendFiles

set_option autoImplicit false

namespace SpecLab
namespace TreeRot

open SpecLab.TreeRotCore

/-! ## File assembly -/

/-- Pointer-to-struct-node (the target signature's type). -/
def nodePtr : ctype :=
  mk_ctype_pointer no_qualifiers (Ctype [] (Struct nodeSym))

def ucharPtr : ctype := mk_ctype_pointer no_qualifiers unsigned_char
def ulongPtr : ctype := mk_ctype_pointer no_qualifiers unsigned_long
def intPtr : ctype := mk_ctype_pointer no_qualifiers signed_int

/-- The `struct node` tag map. -/
def nodeTagDefs : Fmap sym (CerbLocation.Loc × tag_definition) :=
  Lem_Map.fromList
    [(nodeSym, (CerbLocation.Loc.unknown, nodeTagDef))]

/-- One TU's proc symbols (per-TU pinning — the numbering-coupling
finding at R4 scale). -/
structure TUSyms where
  rotate : sym
  scan : sym
  build : sym
  serialize : sym
  free : sym
  main : sym

/-- funinfo for a rotate-family TU: the six procs + the allocator
proxies (hand-pinned per the T1File practice; validated behaviorally
by the gate exe's exec checks + both differential pipelines). -/
def rotateFuninfo (s : TUSyms) : Fmap sym (CerbLocation.Loc ×
    attributes × ctype × List (Option sym × ctype) × Bool × Bool) :=
  Lem_Map.fromList
    [(s.rotate, (CerbLocation.Loc.unknown, Attrs [], nodePtr,
      [((none : Option sym), nodePtr)], false, true)),
     (s.scan, (CerbLocation.Loc.unknown, Attrs [], signed_long,
      [((none : Option sym), ucharPtr), ((none : Option sym), unsigned_long),
       ((none : Option sym), unsigned_long), ((none : Option sym), ulongPtr)],
      false, true)),
     (s.build, (CerbLocation.Loc.unknown, Attrs [], nodePtr,
      [((none : Option sym), ucharPtr), ((none : Option sym), ulongPtr),
       ((none : Option sym), intPtr)], false, true)),
     (s.serialize, (CerbLocation.Loc.unknown, Attrs [], signed_long,
      [((none : Option sym), nodePtr), ((none : Option sym), ucharPtr),
       ((none : Option sym), signed_long), ((none : Option sym), ulongPtr)],
      false, true)),
     (s.free, (CerbLocation.Loc.unknown, Attrs [], void,
      [((none : Option sym), nodePtr)], false, true)),
     (ListAppendCore.mallocProxySym, (CerbLocation.Loc.unknown, Attrs [],
      ListAppend.voidPtr, [((none : Option sym), unsigned_long)],
      false, true)),
     (ListAppendCore.freeProxySym, (CerbLocation.Loc.unknown, Attrs [], void,
      [((none : Option sym), ListAppend.voidPtr)], false, true)),
     (s.main, (CerbLocation.Loc.unknown, Attrs [], signed_int,
      ([] : List (Option sym × ctype)), false, true))]

/-- Assemble a rotate-family file (pre-conversion form) from one TU's
symbol set + six declarations. Stdlib = the R3 closure REUSED
(`ListAppend.listStdlib`: the divmod scalar closure + the allocator
proxies + all_values_representable_in — same reached set, drift-gated
at S1/S3). -/
def rotateFileU (s : TUSyms)
    (mainDecl rotateDecl scanDecl buildDecl serializeDecl freeDecl :
      generic_fun_map_decl Unit Unit) : file Unit :=
  { main := some s.main
    calling_convention0 := Normal_callconv
    tagDefs := nodeTagDefs
    stdlib := ListAppend.listStdlib
    impl0 := fmapEmpty
    globs := []
    funs := Lem_Map.fromList
      [(s.rotate, rotateDecl), (s.scan, scanDecl), (s.build, buildDecl),
       (s.serialize, serializeDecl), (s.free, freeDecl),
       (s.main, mainDecl)]
    extern := fmapEmpty
    funinfo := rotateFuninfo s
    loop_attributes1 := fmapEmpty
    visible_objects_env0 := fmapEmpty }

/-- The parametric family's TU symbols (dumps a/b/d/c — identical
main structure ⇒ identical numbering; the plant TUs share the helper
symbols, asserted at emission). -/
def paramSyms : TUSyms :=
  ⟨rotateRightSym, scanTreeSym, buildTreeSym, serializeTreeSym,
   freeTreeSym, mainSym⟩

def rootSyms : TUSyms :=
  ⟨rootRotateRightSym, rootScanTreeSym, rootBuildTreeSym,
   rootSerializeTreeSym, rootFreeTreeSym, rootMainSym⟩

def deepSyms : TUSyms :=
  ⟨deepRotateRightSym, deepScanTreeSym, deepBuildTreeSym,
   deepSerializeTreeSym, deepFreeTreeSym, deepMainSym⟩

def swapSyms : TUSyms :=
  ⟨swapRotateRightSym, scanTreeSym, buildTreeSym, serializeTreeSym,
   freeTreeSym, swapMainSym⟩

def dropSyms : TUSyms :=
  ⟨dropRotateRightSym, scanTreeSym, buildTreeSym, serializeTreeSym,
   freeTreeSym, dropMainSym⟩

def buildSyms : TUSyms :=
  ⟨buildRotateRightSym, buildScanTreeSym, buildBuildTreeSym,
   buildSerializeTreeSym, buildFreeTreeSym, buildMainSym⟩

/-- THE PARAMETRIC rotate FILE: the healthy pinned-shape/pinned-path
harness family, indexed by the TWENTY-FOUR pre-order element wire
bytes (expected[] sites are derived — the parametric term shares the
parameters; 24 params / 48 sites). -/
def rotateI24File (b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14
    b15 b16 b17 b18 b19 b20 b21 b22 b23 : Int) :
    file core_run_annotation :=
  convert_file (rotateFileU paramSyms
    (rotateMainParamDecl b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13
      b14 b15 b16 b17 b18 b19 b20 b21 b22 b23)
    rotateRightDecl scanTreeDecl buildTreeDecl serializeTreeDecl
    freeTreeDecl)

/-- The junk instance (all-zero bytes) for out-of-family models. -/
def junkFile : file core_run_annotation :=
  rotateI24File 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0

/-- The ROOT-PATH instance (path [] — pinned verbatim; the
pointer-selection statement family's first non-parametric path). -/
def rotateRootFile : file core_run_annotation :=
  convert_file (rotateFileU rootSyms rootMainDecl rootRotateRightDecl
    rootScanTreeDecl rootBuildTreeDecl rootSerializeTreeDecl
    rootFreeTreeDecl)

/-- The DEEP-PATH instance (path [l,l] on a 4-spine — pinned
verbatim). -/
def rotateDeepFile : file core_run_annotation :=
  convert_file (rotateFileU deepSyms deepMainDecl deepRotateRightDecl
    deepScanTreeDecl deepBuildTreeDecl deepSerializeTreeDecl
    deepFreeTreeDecl)

/-- The WRONG-CHILD-SWAP PLANT file (instance a; shared helper
decls — asserted byte-identical at emission). -/
def swapPlantFile : file core_run_annotation :=
  convert_file (rotateFileU swapSyms swapMainDecl swapRotateRightDecl
    scanTreeDecl buildTreeDecl serializeTreeDecl freeTreeDecl)

/-- The DROPPED-SUBTREE PLANT file (instance a). -/
def dropPlantFile : file core_run_annotation :=
  convert_file (rotateFileU dropSyms dropMainDecl dropRotateRightDecl
    scanTreeDecl buildTreeDecl serializeTreeDecl freeTreeDecl)

/-- The BUILD-ONLY file (pinned whole from its own dump) — the
builder-correctness statement's object. -/
def rotateBuildFile : file core_run_annotation :=
  convert_file (rotateFileU buildSyms buildMainDecl
    buildRotateRightDecl buildScanTreeDecl buildBuildTreeDecl
    buildSerializeTreeDecl buildFreeTreeDecl)

/-- The twenty-four wire bytes of a pinned-shape model (pre-order
vals through the pure element codec — the parametric file's index). -/
def wireBytes (m : Input) : List Int :=
  (m.tree.preorderVals.flatMap DivMod.encodeI32LE).map DivMod.byteToInt

/-- MODEL-INDEXED rotate file (the model-∀ face; junk instance on
models outside the pinned shape/path family — statements own the
shape via their sample sets). -/
def rotateFileOf (m : Input) : file core_run_annotation :=
  match m.tree, m.path with
  | .node _ (.node _ (.node _ .leaf (.node _ .leaf .leaf))
      (.node _ .leaf .leaf)) (.node _ .leaf .leaf), [false] =>
    (match wireBytes m with
     | [b0, b1, b2, b3, b4, b5, b6, b7, b8, b9, b10, b11, b12, b13,
        b14, b15, b16, b17, b18, b19, b20, b21, b22, b23] =>
       rotateI24File b0 b1 b2 b3 b4 b5 b6 b7 b8 b9 b10 b11 b12 b13 b14
         b15 b16 b17 b18 b19 b20 b21 b22 b23
     | _ => junkFile)
  | _, _ => junkFile

/-- STREAM-INDEXED rotate file (the stream-∀ face): the full
tree-and-path codec decodes the stream; junk on malformed /
out-of-family streams (callers own validity). -/
def rotateFileOfStream (s : Stream) : file core_run_annotation :=
  match decodeInput s with
  | some (m, []) => rotateFileOf m
  | _ => junkFile

/-! ## The R4 exec statements (fuel opsem only; `DivMod.HarnessRunsTo`
    and the R3 leak observable reused verbatim) -/

/-- The R4 sample set (finite explicit quantification — LABEL: four
concrete pinned-shape models at the pinned path [l], not the family;
the fixed-shape family-∀ rides the parametric term as the priced
follow-on). Wire bytes: a = 1..24, b = 101..124, d = 201..224
(sign-bit maxima exercised), c = out-of-trio boundary vals
[0, -1, INT_MIN, INT_MAX, 1, -INT_MAX]. -/
def sampleSet : List Input :=
  [⟨pinnedShape 67305985 134678021 202050057 269422093 336794129
      404166165, pinnedPath⟩,
   ⟨pinnedShape 1751606885 1818978921 1886350957 1953722993 2021095029
      2088467065, pinnedPath⟩,
   ⟨pinnedShape (-859059511) (-791687475) (-724315439) (-656943403)
      (-589571367) (-522199331), pinnedPath⟩,
   ⟨pinnedShape 0 (-1) (-2147483648) 2147483647 1 (-2147483647),
      pinnedPath⟩]

/-- THE R4 MODEL-∀ STATEMENT (finite sample form): every healthy
pinned instance runs to verdict 0 — the post-state tree read back
through the walker equals `rotateAt tree path` (full-tree readback
equality: the S4-E1 experiment's Way 1, THE statement form), with the
untouched remainder checked byte-for-byte through the same
observation. -/
def RotateSampleStatement : Prop :=
  ∀ m ∈ sampleSet, DivMod.HarnessRunsTo (rotateFileOf m) 0

/-- The sample streams (full tree-and-path codec). -/
def sampleStreams : List Stream := sampleSet.map encodeInput

/-- THE R4 STREAM-∀ STATEMENT (finite sample form). -/
def RotateSampleStreamStatement : Prop :=
  ∀ s ∈ sampleStreams, DivMod.HarnessRunsTo (rotateFileOfStream s) 0

/-- THE POINTER-SELECTION STATEMENT FAMILY (the S3 prototype,
promoted): the pinned instances at FURTHER paths — the root rotation
(path []) and the depth-2 spine rotation (path [l,l]) — each runs to
verdict 0. Verbatim-pinned file list (the S2-E4 floor for 1-2
instance targets); together with the parametric family's in-stream
path, the path dimension is statement-level data, not harness
configuration. -/
def RotatePathSampleStatement : Prop :=
  ∀ f ∈ [rotateRootFile, rotateDeepFile], DivMod.HarnessRunsTo f 0

/-- THE BUILDER-CORRECTNESS OBLIGATION, stated (the build-only
harness — builder then walker, NO call — runs to verdict 0: the heap
structure the builder constructs serializes back as exactly the
encoded model, `expected = choices`; the pure mirror is `decodeInput`
itself, the free-generator reading). Proof parked with the
exec-equation campaign per the S1-S3 pattern — statement side
complete; the gate exe checks it executably. -/
def BuildOnlyStatement : Prop :=
  DivMod.HarnessRunsTo rotateBuildFile 0

/-- The wrong-child-swap plant's healthy-shaped claim — refuted by
`HarnessRunsTo swapPlantFile 7` (the locus val's first wire byte). -/
def SwapPlantHealthyClaim : Prop :=
  DivMod.HarnessRunsTo swapPlantFile 0

/-- The dropped-subtree plant's healthy-shaped claim — refuted by
`HarnessRunsTo dropPlantFile 255` (structural breaks land in the
length arm). -/
def DropPlantHealthyClaim : Prop :=
  DivMod.HarnessRunsTo dropPlantFile 0

/-! ## The leak conjunct (the R3 observable, reused verbatim) -/

/-- THE R4 LEAK STATEMENT (finite sample form): after teardown, every
healthy pinned instance's final allocation map is exactly the driver
baseline — rotation is allocation-neutral (`rotateAt_size` is the
pure face) and the harness owns no heap. -/
def RotateSampleLeakStatement : Prop :=
  ∀ m ∈ sampleSet,
    ListAppend.HarnessFinalAllocs (rotateFileOf m) ListAppend.driverBaseline

/-- The path instances' leak conjunct. -/
def RotatePathSampleLeakStatement : Prop :=
  ∀ f ∈ [rotateRootFile, rotateDeepFile],
    ListAppend.HarnessFinalAllocs f ListAppend.driverBaseline

/-- The build-only instance's leak conjunct. -/
def BuildOnlyLeakStatement : Prop :=
  ListAppend.HarnessFinalAllocs rotateBuildFile ListAppend.driverBaseline

/-- The wrong-child-swap plant's leak face: BASELINE — a broken
target that leaks nothing (all nodes stay reachable;
`swapPlant_size`). The observable separates the two plant classes:
content break (swap, leak-free) vs structural break (drop, +1). -/
def SwapPlantLeakStatement : Prop :=
  ListAppend.HarnessFinalAllocs swapPlantFile ListAppend.driverBaseline

/-- The dropped-subtree plant's leak face — the orphaned middle
subtree (exactly 1 node at the pinned instance: `orphanedAt` = 1,
`dropPlant_size`) survives teardown: final size = baseline + 1.
Stating the EXACT leaked count keeps the observable
differential-grade. -/
def DropPlantLeakClaim : Prop :=
  ListAppend.HarnessFinalAllocs dropPlantFile
    (ListAppend.driverBaseline + 1)

/-! ## The file-level bridge (kernel-checked): the stream face and
    the model face build THE SAME program — through the recursive
    tree codec -/

/-- On pinned-shape in-range models, the stream-indexed file at the
encoded stream IS the model-indexed file. -/
theorem rotateFileOfStream_encode (m : Input) (h : Wf m) :
    rotateFileOfStream (encodeInput m) = rotateFileOf m := by
  unfold rotateFileOfStream
  rw [show encodeInput m = encodeInput m ++ [] by simp,
    decode_encode_input m h []]

/-- THE R4 SAMPLE BRIDGE (kernel-checked): the model-∀ and stream-∀
sample statements are interderivable. -/
theorem rotate_sample_model_iff_stream :
    RotateSampleStatement ↔ RotateSampleStreamStatement := by
  constructor
  · intro hm s hs
    unfold sampleStreams at hs
    obtain ⟨m, hmem, rfl⟩ := List.mem_map.mp hs
    have hwf : Wf m := by
      simp only [sampleSet, List.mem_cons, List.not_mem_nil,
        or_false] at hmem
      rcases hmem with rfl | rfl | rfl | rfl <;> decide
    rw [rotateFileOfStream_encode m hwf]
    exact hm m hmem
  · intro hs m hm
    have hwf : Wf m := by
      simp only [sampleSet, List.mem_cons, List.not_mem_nil,
        or_false] at hm
      rcases hm with rfl | rfl | rfl | rfl <;> decide
    have := hs (encodeInput m)
      (List.mem_map.mpr ⟨m, hm, rfl⟩)
    rwa [rotateFileOfStream_encode m hwf] at this

end TreeRot
end SpecLab
