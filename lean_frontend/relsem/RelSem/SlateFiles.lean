/-
  RelSem.SlateFiles — arc-7 S5a (2026-08-20): THE T2–T6 PROGRAM TERMS
  (T6 added arc-17 S1: the acceptance-probe fixture).

  Assembles the kernel-transparent Core files the T2–T6 slate theorems
  quantify over, from the emitted parsed ASTs (RelSem/SlateCore.lean —
  generated, drift-gated) plus pinned metadata, exactly as
  RelSem/T1File.lean does for T1:

  * `funs`    := the designated function only (verbatim from the pinned
                 oracle dump of the fixture);
  * `stdlib`  := the SAME conv_loaded_int closure as T1
                 (RelSem.T1.t1Stdlib — conv_loaded_int, conv_int,
                 is_representable_integer, catch_exceptional_condition):
                 every slate body's pure evaluation reaches only these
                 (T2/T5's overflow check is the PEcatch_exceptional_
                 condition BUILTIN, evaluated by Core_eval directly, and
                 the loop comparisons call conv_int — all in-closure);
  * `funinfo` := the designated function's C signature, hand-pinned to
                 the elaborated funinfo of the fixture (checked
                 behaviorally by the drift-gate's concrete
                 differential);
  * `tagDefs` := empty except T4, which carries `struct S` (the parsed
                 tag definition, verbatim from the pinned dump —
                 the struct layout the theorem's statement depends on);
  * everything else empty/none (single-TU: Erun label resolution falls
    back to the current procedure).

  HONESTY NOTE (statement data, as T1File): these are the pinned oracle
  dumps' designated functions + the reached stdlib closure, not the
  whole linked pipeline files.

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import Core_run_aux
import RelSem.T1File
import RelSem.SlateCore

set_option autoImplicit false

namespace RelSem.Slate

/-- Shared: `signed int`, the only C type the slate signatures use. -/
def intParam : Option sym × ctype := ((none : Option sym), signed_int)

/-- funinfo entry payload for `signed int f(signed int, ...)`. -/
def funinfoOf (params : List (Option sym × ctype)) :
    CerbLocation.Loc × attributes × ctype × List (Option sym × ctype) ×
      Bool × Bool :=
  (CerbLocation.Loc.unknown, Attrs [], signed_int, params, false, true)

/-- The shared empty-file skeleton (differs from t1FileU only in the
    fixture-specific fields set at each use site). -/
def slateFileU (funs : Fmap sym (generic_fun_map_decl Unit Unit))
    (funinfo : Fmap sym (CerbLocation.Loc × attributes × ctype ×
      List (Option sym × ctype) × Bool × Bool))
    (tagDefs : Fmap sym (CerbLocation.Loc × tag_definition)) : file Unit :=
  { main := none
    calling_convention0 := Normal_callconv
    tagDefs := tagDefs
    stdlib := RelSem.T1.t1Stdlib
    impl0 := fmapEmpty
    globs := []
    funs := funs
    extern := fmapEmpty
    funinfo := funinfo
    loop_attributes1 := fmapEmpty
    visible_objects_env0 := fmapEmpty }

/-! ## T2: `int add(int a, int b)` -/

def t2FileU : file Unit :=
  slateFileU (Lem_Map.fromList [(addT2Sym, addT2Decl)])
    (Lem_Map.fromList [(addT2Sym, funinfoOf [intParam, intParam])])
    fmapEmpty

/-- THE T2 file, in the runtime annotation form the driver consumes. -/
def t2File : file core_run_annotation := convert_file t2FileU

/-! ## T3: `int roundtrip(int v)` -/

def t3FileU : file Unit :=
  slateFileU (Lem_Map.fromList [(roundtripT3Sym, roundtripT3Decl)])
    (Lem_Map.fromList [(roundtripT3Sym, funinfoOf [intParam])])
    fmapEmpty

/-- THE T3 file. -/
def t3File : file core_run_annotation := convert_file t3FileU

/-! ## T4: `int memb(int v)` over `struct S { int a; int b; }` -/

def t4FileU : file Unit :=
  slateFileU (Lem_Map.fromList [(membT4Sym, membT4Decl)])
    (Lem_Map.fromList [(membT4Sym, funinfoOf [intParam])])
    (Lem_Map.fromList [(structSSym, structSDef)])

/-- THE T4 file. -/
def t4File : file core_run_annotation := convert_file t4FileU

/-! ## T5: `int sum(int n)` -/

def t5FileU : file Unit :=
  slateFileU (Lem_Map.fromList [(sumT5Sym, sumT5Decl)])
    (Lem_Map.fromList [(sumT5Sym, funinfoOf [intParam])])
    fmapEmpty

/-- THE T5 file. -/
def t5File : file core_run_annotation := convert_file t5FileU

/-! (2026-08-27 kill-list execution: the t6/t7/e1–e5/c4/c5/c3a/c3b/
    c9/x7/x2/x3/z1/z2 file assemblies + x3Stdlib — fixture data whose
    only consumers were the killed concrete-input theorems and their
    test rows — are DELETED; SlateCore is regenerated to the T2–T5
    slate in the same commit. The .c fixtures + pinned .core dumps
    stay in tests/verify on the test ledger.) -/


end RelSem.Slate
