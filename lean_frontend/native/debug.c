/* Debug level for CerbDebug — mutable global via C extern
   getLevelIO : Unit → BaseIO Nat
   setLevelIO : Nat → BaseIO Unit */
#include <lean/lean.h>

static size_t cerb_debug_level = 0;

LEAN_EXPORT lean_obj_res cerb_debug_get_level(b_lean_obj_arg unit, lean_obj_arg rw) {
    return lean_io_result_mk_ok(lean_box(cerb_debug_level));
}

LEAN_EXPORT lean_obj_res cerb_debug_set_level(b_lean_obj_arg n, lean_obj_arg rw) {
    cerb_debug_level = lean_unbox(n);
    return lean_io_result_mk_ok(lean_box(0));
}
