/* Debug level for CerbDebug — mutable global via C extern
   getLevelIO : Unit → BaseIO Nat
   setLevelIO : Nat → BaseIO Unit

   Calling convention (Lean ≥ 4.29 new code generator): the RealWorld token is
   erased, so BaseIO externs receive only their explicit arguments and return
   the result value DIRECTLY (no lean_io_result_mk_ok wrapper). */
#include <lean/lean.h>

static size_t cerb_debug_level = 0;

LEAN_EXPORT lean_obj_res cerb_debug_get_level(b_lean_obj_arg unit) {
    return lean_box(cerb_debug_level);
}

LEAN_EXPORT lean_obj_res cerb_debug_set_level(b_lean_obj_arg n) {
    cerb_debug_level = lean_unbox(n);
    return lean_box(0);
}
