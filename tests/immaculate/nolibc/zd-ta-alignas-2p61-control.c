/* total-arith sweep pin (2026-10-03; record docs/2026-10-03_total-arith-and-bookkeeping-record.md §2).
   CONTROL for the zd-ta-alignas-huge-* pins: 2^61 is inside OCaml's native int range, so Z.to_int does not
   raise and both engines compute the layout (sizeof = 2^62, >> 60 = 4). MATCH. */
struct s { char c; _Alignas(0x2000000000000000) char x; };
int main(void) { return (int)(sizeof(struct s) >> 60); }
