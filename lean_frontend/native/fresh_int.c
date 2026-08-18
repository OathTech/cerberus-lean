/* Fresh integer counter for CerberusFresh.freshIntIO : Unit → BaseIO Nat

   Calling convention (Lean ≥ 4.29 new code generator): the RealWorld token is
   erased, so BaseIO externs receive only their explicit arguments and return
   the result value DIRECTLY (no lean_io_result_mk_ok wrapper). */
#include <lean/lean.h>

static size_t cerb_fresh_counter = 0;

LEAN_EXPORT lean_obj_res cerb_fresh_int_io(b_lean_obj_arg unit) {
    size_t n = cerb_fresh_counter++;
    if (n <= LEAN_MAX_SMALL_NAT)
        return lean_box(n);
    return lean_usize_to_nat(n);
}
