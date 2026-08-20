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

end RelSem.T1
