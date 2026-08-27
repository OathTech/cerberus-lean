/-
  RelSem.T1File — arc-7 S4 (2026-08-20): THE T1 PROGRAM TERM.

  Assembles the kernel-transparent Core file the T1 slate theorem
  quantifies over, from the emitted parsed AST (RelSem/T1Core.lean —
  generated, drift-gated) plus pinned metadata:

  * `funs`    := { id }               (the designated function, verbatim
                                       from the pinned oracle dump);
  * `stdlib`  := the conv_loaded_int closure of std.core
                 (conv_loaded_int, conv_int, is_representable_integer,
                 catch_exceptional_condition) — the functions `id`'s
                 evaluation can reach;
  * `funinfo` := id : signed int (signed int) — the caller-protocol
                 metadata `callND`'s by-pointer injection reads
                 (parameter allocated at 'signed int'; hand-pinned to
                 the elaborated funinfo of tests/verify/t1_id.c, checked
                 behaviorally by the concrete differential);
  * everything else empty/none (no globals, no tags, no extern needs:
    Erun label resolution falls back to the current procedure when the
    extern map has no entry — the single-TU case).

  HONESTY NOTE (statement data; S4 record §6.1): this is the pinned
  oracle Core dump's `id` + the REACHED stdlib closure, not the whole
  linked pipeline file (whole-file emission is the priced follow-on).
  The drift gate (Unit.EmitLeanCoreTest) re-parses the pinned inputs
  and byte-compares the emitted module; the concrete differential runs
  `callND` on THIS file value at the recorded spec points.

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import Core_run_aux
import RelSem.T1Core

set_option autoImplicit false

namespace RelSem.T1

/-- The C `int` value range (statement vocabulary; RE-HOMED from the
    ambient statement file RelSem/T1.lean at arc-18 R5 — the LIVE
    threaded statements consume it, and the T4 live route must not
    ride the ambient chain. Text unchanged; every consumer resolves
    the same `RelSem.T1.intRange`. -/
def intRange (x : Int) : Prop := -2147483648 ≤ x ∧ x ≤ 2147483647

/-- The stdlib fragment `id`'s evaluation can reach. -/
def t1Stdlib : Fmap sym (generic_fun_map_decl Unit Unit) :=
  Lem_Map.fromList
    [(convLoadedIntSym, convLoadedIntDecl),
     (convIntSym, convIntDecl),
     (isReprIntegerSym, isReprIntegerDecl),
     (catchExceptionalSym, catchExceptionalDecl)]

/-- The function map: the designated function only. -/
def t1Funs : Fmap sym (generic_fun_map_decl Unit Unit) :=
  Lem_Map.fromList [(idT1Sym, idT1Decl)]

/-- funinfo for `id`: `signed int id(signed int)` — return type,
    one by-value parameter of C type 'signed int', not variadic,
    prototyped. The caller protocol allocates the pointer-passed
    parameter at this C type (RelSem/Call.lean `injectArg`). -/
def t1Funinfo : Fmap sym (CerbLocation.Loc × attributes × ctype ×
    List (Option sym × ctype) × Bool × Bool) :=
  Lem_Map.fromList
    [(idT1Sym, (CerbLocation.Loc.unknown, Attrs [], signed_int,
      [((none : Option sym), signed_int)], false, true))]

/-- THE T1 file (pre-conversion form). -/
def t1FileU : file Unit :=
  { main := none
    calling_convention0 := Normal_callconv
    tagDefs := fmapEmpty
    stdlib := t1Stdlib
    impl0 := fmapEmpty
    globs := []
    funs := t1Funs
    extern := fmapEmpty
    funinfo := t1Funinfo
    loop_attributes1 := fmapEmpty
    visible_objects_env0 := fmapEmpty }

/-- THE T1 file, in the runtime annotation form the driver consumes
    (the same `convert_file` move Main.lean makes before execution). -/
def t1File : file core_run_annotation := convert_file t1FileU

/-- T1's PRIOR VOCABULARY (V0, consistency-freshness statement layer):
    the static symbol numbers of `t1File`'s emitted term closure —
    pinned fixture data, validated fail-closed by the PriorCensus
    instrument gate (RelSem/Audit.lean; TEMPORAL — mover: a total
    Core-AST symbol census, V2-class). -/
def t1Prior : List Nat :=
  [362773788461399393, 1574597236902804563, 3579765898737599443,
   7363042538087792746, 7499171796590179012, 7764867060197914680,
   8148669997605808657, 8833183227039990084, 13429216386455784360,
   14671517598387306907, 15837442492999787586, 16562859848569467201,
   16930491615947487770, 17659931425627118568]

end RelSem.T1
