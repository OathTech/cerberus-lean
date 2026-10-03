/* total-arith sweep pin (2026-10-03; record docs/2026-10-03_total-arith-and-bookkeeping-record.md §2, §7).
   As zd-ta-alignas-huge-sizeof.c through the UNION arm of Concrete.alignof (impl_mem.ml:267 Z.to_int):
   oracle Z.Overflow (exit 125). ISO-fix register R7: Lean computes _Alignof(union u) = 2^62, (int) -> 0.
   Pinned ORACLE_CRASH | L=Specified(0) (re-pinned 2026-10-03). */
union u { char c; _Alignas(0x4000000000000000) char x; };
int main(void) { return (int)_Alignof(union u); }
