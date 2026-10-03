/* total-arith sweep pin (2026-10-03; record docs/2026-10-03_total-arith-and-bookkeeping-record.md §2).
   As zd-ta-alignas-huge-sizeof.c through the UNION arm of Concrete.alignof (impl_mem.ml:267): _Alignof of
   a union with a 2^62-aligned member. Oracle Z.Overflow (exit 125); Lean fail-stop (was Specified(0)).
   Both-crash pair, MATCH | L=CRASH. */
union u { char c; _Alignas(0x4000000000000000) char x; };
int main(void) { return (int)_Alignof(union u); }
