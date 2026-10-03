/* total-arith sweep pin (2026-10-03; record docs/2026-10-03_total-arith-and-bookkeeping-record.md §2).
   A front-end-accepted _Alignas of 2^62 (a power of two) on a struct member; sizeof(struct s) runs
   Concrete.sizeof -> alignof, whose member fold reads the alignment through Z.to_int (impl_mem.ml:248),
   which raises Z.Overflow outside OCaml's native int range (uncaught, exit 125). Lean mirrors the read as a
   fail-stop (CerbMem.alignofMemberRead / CerberusImpl.zToInt); it used to answer Specified(0).
   Both-crash pair, MATCH | L=CRASH. */
struct s { char c; _Alignas(0x4000000000000000) char x; };
int main(void) { return (int)sizeof(struct s); }
