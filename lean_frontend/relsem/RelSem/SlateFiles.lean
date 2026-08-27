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

/-! ## T6: `int pick(int x)` (arc-17 S1: the acceptance-probe fixture —
    branch + arithmetic + scalar locals) -/

def t6FileU : file Unit :=
  slateFileU (Lem_Map.fromList [(pickT6Sym, pickT6Decl)])
    (Lem_Map.fromList [(pickT6Sym, funinfoOf [intParam])])
    fmapEmpty

/-- THE T6 file. -/
def t6File : file core_run_annotation := convert_file t6FileU

/-! ## T7: `int flip(int n)` (arc-18 R2 [F1]: the branch-in-loop
    fixture — a while loop whose body branches with arms of different
    statement counts: data-dependent per-iteration round counts, the
    ∃-round segment composition's acceptance case) -/

def t7FileU : file Unit :=
  slateFileU (Lem_Map.fromList [(flipT7Sym, flipT7Decl)])
    (Lem_Map.fromList [(flipT7Sym, funinfoOf [intParam])])
    fmapEmpty

/-- THE T7 file. -/
def t7File : file core_run_annotation := convert_file t7FileU

/-! ## Arc-18 R6 breadth-campaign corpus, batch 1 (EASY tier):
    e1 `int clamp0(int x)`, e2 `int abs3(int x)`,
    e3 `int scale(int x)`, e4 `int is_digit(int c)`,
    e5 `int is_mark(int c)` — same assembly recipe as T2–T7
    (designated function + the shared stdlib closure + pinned
    funinfo; drift-gated through SlateCore). -/

def e1FileU : file Unit :=
  slateFileU (Lem_Map.fromList [(clampE1Sym, clampE1Decl)])
    (Lem_Map.fromList [(clampE1Sym, funinfoOf [intParam])])
    fmapEmpty

/-- THE e1 file. -/
def e1File : file core_run_annotation := convert_file e1FileU

def e2FileU : file Unit :=
  slateFileU (Lem_Map.fromList [(absE2Sym, absE2Decl)])
    (Lem_Map.fromList [(absE2Sym, funinfoOf [intParam])])
    fmapEmpty

/-- THE e2 file. -/
def e2File : file core_run_annotation := convert_file e2FileU

def e3FileU : file Unit :=
  slateFileU (Lem_Map.fromList [(scaleE3Sym, scaleE3Decl)])
    (Lem_Map.fromList [(scaleE3Sym, funinfoOf [intParam])])
    fmapEmpty

/-- THE e3 file. -/
def e3File : file core_run_annotation := convert_file e3FileU

def e4FileU : file Unit :=
  slateFileU (Lem_Map.fromList [(isdigitE4Sym, isdigitE4Decl)])
    (Lem_Map.fromList [(isdigitE4Sym, funinfoOf [intParam])])
    fmapEmpty

/-- THE e4 file. -/
def e4File : file core_run_annotation := convert_file e4FileU

def e5FileU : file Unit :=
  slateFileU (Lem_Map.fromList [(ismarkE5Sym, ismarkE5Decl)])
    (Lem_Map.fromList [(ismarkE5Sym, funinfoOf [intParam])])
    fmapEmpty

/-- THE e5 file. -/
def e5File : file core_run_annotation := convert_file e5FileU

end RelSem.Slate
