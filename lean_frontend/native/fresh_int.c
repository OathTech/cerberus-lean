/* Fresh integer counter for CerberusFresh.freshIntIO : Unit → BaseIO Nat

   Calling convention (Lean ≥ 4.29 new code generator): the RealWorld token is
   erased, so BaseIO externs receive only their explicit arguments and return
   the result value DIRECTLY (no lean_io_result_mk_ok wrapper). */
#include <lean/lean.h>

/* Counter BASE (arc-4 S3a). OCaml's counter (util/cerb_fresh.ml) starts at 0,
   but by the time the .c translation unit is processed it has been advanced
   past every symbol registration of the core stdlib parse: the OCaml Core
   parser draws Cerb_fresh.int() once per registered symbol
   (parsers/core/core_parser.mly:184 register_sym, :220 register_label), so
   translation-time ambient ids (Symbol.fresh, frontend/model/symbol.lem)
   start ABOVE the 0-based ids the desugar stage threads through desugM
   (cabs_to_ail_effect.lem fresh_sym_supply, commit 8923d6436) — the two id
   streams are disjoint per translation unit.

   The Lean CoreParser interns std.core symbols by name hash instead of
   drawing from this counter (CoreParser.mkSym), so without an offset the
   ambient stream would restart at 0 and collide with the desugar stream:
   distinct symbols with equal (digest, nat) compare EQUAL
   (symbol.lem symbolEqual ignores the description), which clobbered env
   bindings at run time (arc-4 S3a: ACTION_ILLTYPED Store/Load/Kill on 15 of
   tests/minimal). Starting the counter at 2^20 reproduces the OCaml
   invariant (ambient ids strictly above the per-unit desugar range) with a
   larger margin than OCaml's (~488 for the current std.core). Collision with
   the 64-bit name-hash ids of stdlib symbols remains as (im)probable as it
   was for the previous 0-based range. */
#define CERB_FRESH_BASE ((size_t)1 << 20)

static size_t cerb_fresh_counter = CERB_FRESH_BASE;

LEAN_EXPORT lean_obj_res cerb_fresh_int_io(b_lean_obj_arg unit) {
    size_t n = cerb_fresh_counter++;
    /* Floor invariant (arc-2 Phase-2 non-escape obligation): the ambient
       stream must stay at or above CERB_FRESH_BASE — below it, ambient ids
       could collide with the 0-based desugar-threaded supply (see the BASE
       comment above). A violation here means corruption or a bad re-init;
       fail-stop rather than hand out a colliding id. */
    if (n < CERB_FRESH_BASE)
        __builtin_trap();
    if (n <= LEAN_MAX_SMALL_NAT)
        return lean_box(n);
    return lean_usize_to_nat(n);
}
