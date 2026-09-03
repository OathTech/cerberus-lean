/* Z2 probe (case_ptrval fallback): impl_mem.ml:1808-1814 `| _ -> failwith
   "case_ptrval"` for a Prov_device/Prov_symbolic concrete pointer;
   CerbMem.casePtrval:1241 has a fail-OPEN `onConcrete none addr` fallback.
   0xABC is in device_ranges (impl_mem.ml:620-624), so the oracle mints
   Prov_device at the cast (:2164-2167) and the Eccall reaches case_ptrval
   (core_eval.lem:920). Lean today mints Prov_none here (charter Z-06), so the
   fallback is unreachable UNTIL Z-06 lands — this probe pins what Z1 must also
   mirror. nolibc. */
int main(void) { ((void (*)(void))0xABC)(); return 0; }
