/-
SpecLab.ByteArrFiles — arc-15 S2: the R2 byte-blaster FILE TERMS and
the exec-level STATEMENTS (memcpy + getarr).

Assembly follows the S1 DivModFiles pattern (itself the arc-7 T1File
pattern): pinned parsed declarations (SpecLab/ByteArrCore.lean,
generated + drift-gated) + hand-pinned funinfo metadata, `globs`
empty (block-scope arrays, S1-E4), `main := some mainSym`.

HONESTY NOTE (statement data): each file value is the pinned oracle
Core dump's procs + the REACHED std.core closure — which is SHARED
with the divmod family (`DivMod.divmodStdlib`: the same 8 std
declarations, drift-gated by the S1 CoreGateTest). The S2 drift gate
(SLUnit.ByteArrGateTest) re-parses the pinned dumps, byte-compares the
generated module, pins `memcpyMainParamDecl` back to all four memcpy
dumps (incl. the out-of-trio c), and runs the assembled files through
`drive` at the pinned verdicts — plus the .c twins run through BOTH
pipelines by scripts/test_speclab_bytearr.sh.

STATEMENT DISCIPLINE: statement surface (gate-scanned) — fuel-opsem
vocabulary only.
-/

import Core_run_aux
import Driver
import CerbND
import SpecLab.ByteArr
import SpecLab.ByteArrHarness
import SpecLab.ByteArrCore
import RelSem.Threaded
import SpecLab.DivModFiles

set_option autoImplicit false

-- Arc-18 C4 (R6 homing): the homed threaded statement vocabulary —
-- exactly these names are gate-allowlisted (see SpecLab/DivModFiles.lean).
open RelSem.Cerb (HarnessRunsToThr specifiedInt initial_driver_state_threaded)


namespace SpecLab

/-! (2026-08-27 KILL-LIST EXECUTION, operator-ratified: the finite
    sample-∀ / concrete statement Prop defs of this rung — the
    `*Sample*`/`*Plant*Claim`/`*Leak*` family with their pinned
    sample sets and the sample bridges — are DELETED: quantification
    by membership in a closed literal list is enumeration by
    construction, and their planned proof (the exec-equation
    campaign) is CANCELLED. The pure models, codec laws, the
    `model_forall_iff_stream_forall` bridges, the `fileOfStream_
    encode` program-term equalities, the family-∀ TARGET statements,
    and the file terms (test-lane data) all STAY. Record:
    lean_frontend/docs/2026-08-27_kill-list-execution.md.) -/
namespace ByteArr

open SpecLab.ByteArrCore

/-! ## File assembly -/

/-- Pointer-to-char (the target signatures' parameter type). -/
def charPtr : ctype := mk_ctype_pointer no_qualifiers char0

/-- funinfo: `void naive_memcpy(char*, char*, int)`,
`signed int main(void)` — hand-pinned to the elaborated funinfo of the
pinned fixtures, checked behaviorally by the ByteArrGateTest exec
checks + the differential lanes (the T1File practice). -/
def memcpyFuninfo : Fmap sym (CerbLocation.Loc × attributes × ctype ×
    List (Option sym × ctype) × Bool × Bool) :=
  Lem_Map.fromList
    [(naiveMemcpySym, (CerbLocation.Loc.unknown, Attrs [], void,
      [((none : Option sym), charPtr), ((none : Option sym), charPtr),
       ((none : Option sym), signed_int)], false, true)),
     (mainSym, (CerbLocation.Loc.unknown, Attrs [], signed_int,
      ([] : List (Option sym × ctype)), false, true))]

/-- funinfo: `char get_from_arr(char*)`, `signed int main(void)`. -/
def getarrFuninfo : Fmap sym (CerbLocation.Loc × attributes × ctype ×
    List (Option sym × ctype) × Bool × Bool) :=
  Lem_Map.fromList
    [(getFromArrSym, (CerbLocation.Loc.unknown, Attrs [], char0,
      [((none : Option sym), charPtr)], false, true)),
     (mainSym, (CerbLocation.Loc.unknown, Attrs [], signed_int,
      ([] : List (Option sym × ctype)), false, true))]

/-- Assemble a memcpy file (pre-conversion form) around a main +
target pair. -/
def memcpyFileU (mainDecl : generic_fun_map_decl Unit Unit)
    (targetDecl : generic_fun_map_decl Unit Unit) : file Unit :=
  { main := some mainSym
    calling_convention0 := Normal_callconv
    tagDefs := fmapEmpty
    stdlib := DivMod.divmodStdlib
    impl0 := fmapEmpty
    globs := []
    funs := Lem_Map.fromList
      [(naiveMemcpySym, targetDecl), (mainSym, mainDecl)]
    extern := fmapEmpty
    funinfo := memcpyFuninfo
    loop_attributes1 := fmapEmpty
    visible_objects_env0 := fmapEmpty }

/-- Assemble a getarr file around a main + target pair. -/
def getarrFileU (mainDecl : generic_fun_map_decl Unit Unit)
    (targetDecl : generic_fun_map_decl Unit Unit) : file Unit :=
  { main := some mainSym
    calling_convention0 := Normal_callconv
    tagDefs := fmapEmpty
    stdlib := DivMod.divmodStdlib
    impl0 := fmapEmpty
    globs := []
    funs := Lem_Map.fromList
      [(getFromArrSym, targetDecl), (mainSym, mainDecl)]
    extern := fmapEmpty
    funinfo := getarrFuninfo
    loop_attributes1 := fmapEmpty
    visible_objects_env0 := fmapEmpty }

/-- THE PARAMETRIC memcpy FILE: the healthy n = 3 harness family,
indexed by the THREE choice bytes (expected[] sites are derived — the
parametric term shares the parameters, register S2-E4). -/
def memcpyI3File (c0 c1 c2 : Int) : file core_run_annotation :=
  convert_file (memcpyFileU (memcpyMainParamDecl c0 c1 c2) naiveMemcpyDecl)

/-- The OFF-BY-ONE PLANT file (pinned verbatim; bytes [1,2,3]). -/
def memcpyPlantFile : file core_run_annotation :=
  convert_file (memcpyFileU memcpyMainPlantDecl naiveMemcpyPlantDecl)

/-- Byte-valued Int (the splice literal of a byte). -/
def byteToInt (b : UInt8) : Int := (b.toNat : Int)

/-- MODEL-INDEXED memcpy file (the model-∀ face; junk instance on
non-3-length models — statements own the length via their sample
sets). -/
def memcpyFileOf (bs : List UInt8) : file core_run_annotation :=
  match bs with
  | [b0, b1, b2] =>
    memcpyI3File (byteToInt b0) (byteToInt b1) (byteToInt b2)
  | _ => memcpyI3File 0 0 0

/-- STREAM-INDEXED memcpy file (the stream-∀ face): the full
byte-blaster codec decodes the stream; junk on malformed/non-3-length
streams (callers own validity). -/
def memcpyFileOfStream (s : Stream) : file core_run_annotation :=
  match decodeInput s with
  | some (bs, []) => memcpyFileOf bs
  | _ => memcpyI3File 0 0 0

/-- The getarr files, pinned VERBATIM per instance (the contrasting
statement style — register S2-E4): a = "hellohello",
b = [0,255,0,255,7,0,255,0,255,127]. -/
def getarrFileA : file core_run_annotation :=
  convert_file (getarrFileU getarrMainADecl getFromArrDecl)

def getarrFileB : file core_run_annotation :=
  convert_file (getarrFileU getarrMainBDecl getFromArrDecl)

/-- The getarr WRONG-INDEX PLANT file (pinned verbatim; "hellohello"). -/
def getarrPlantFile : file core_run_annotation :=
  convert_file (getarrFileU getarrMainPlantDecl getFromArrPlantDecl)

/-! ## The R2 exec statements (fuel opsem only; `HarnessRunsTo` is the
    R1 statement shape, reused verbatim from SpecLab.DivModFiles) -/

/-! ## The file-level bridge (kernel-checked): the stream face and the
    model face build THE SAME program — through the FULL byte-blaster
    codec (u16 prefix decode + verbatim bytes) -/

/-- On 3-byte models, the stream-indexed file at the encoded stream IS
the model-indexed file (`decode ∘ encode = id` at the file level; the
S0 array codec's round trip is the load-bearing step). -/
theorem memcpyFileOfStream_encode (bs : List UInt8)
    (h : bs.length = 3) :
    memcpyFileOfStream (encodeInput bs) = memcpyFileOf bs := by
  have hwf : Wf bs := by unfold Wf cap; omega
  unfold memcpyFileOfStream
  rw [show encodeInput bs = encodeInput bs ++ [] by simp,
    decode_encode_input bs hwf []]

end ByteArr
end SpecLab
