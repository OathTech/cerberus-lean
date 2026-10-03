/* total-arith sweep pin (2026-10-03; record docs/2026-10-03_total-arith-and-bookkeeping-record.md §2, §7).
   A front-end-accepted _Alignas of 2^62 (a power of two) on a struct member; sizeof(struct s) runs
   Concrete.sizeof -> alignof, whose member fold reads the alignment through Z.to_int (impl_mem.ml:248):
   Z.Overflow outside OCaml's native int range (uncaught, exit 125) — a host artifact: upstream's Lem
   interface is unbounded (implementation.lem:27, mem.lem:191). ISO-fix register R7 (the R3 class,
   [USER 2026-10-03] rulings): Lean computes the unbounded answer, sizeof = 2^63, (int) -> 0.
   Pinned ORACLE_CRASH | L=Specified(0) (re-pinned 2026-10-03 from a short-lived both-crash pin). */
struct s { char c; _Alignas(0x4000000000000000) char x; };
int main(void) { return (int)sizeof(struct s); }
