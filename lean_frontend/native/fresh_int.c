/* Fresh integer counter for CerberusFresh.freshIntIO : Unit → BaseIO Nat */
#include <lean/lean.h>

static size_t cerb_fresh_counter = 0;

LEAN_EXPORT lean_obj_res cerb_fresh_int_io(b_lean_obj_arg unit, lean_obj_arg rw) {
    size_t n = cerb_fresh_counter++;
    lean_obj_res val;
    if (n <= LEAN_MAX_SMALL_NAT)
        val = lean_box(n);
    else
        val = lean_usize_to_nat(n);
    return lean_io_result_mk_ok(val);
}
