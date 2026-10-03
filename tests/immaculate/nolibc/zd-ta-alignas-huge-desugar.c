/* total-arith sweep pin (2026-10-03; record docs/2026-10-03_total-arith-and-bookkeeping-record.md §2).
   _Alignas(8) on an object of a struct type whose member is 2^62-aligned: the desugarer compares the
   declared type's alignment (cabs_to_ail.lem desugar_alignment_specifiers -> Implementation.alignof_ty),
   and Ocaml_implementation.alignof reads the member alignment through Z.to_int (ocaml_implementation.ml:501),
   raising Z.Overflow (uncaught, exit 125). Lean's CerberusImpl.alignof_ty mirrors the read as a fail-stop
   (it used to compute the alignment and report a desugaring failure). Both-crash pair, MATCH | L=CRASH. */
struct s { _Alignas(0x4000000000000000) char x; };
_Alignas(8) struct s g;
int main(void) { return 0; }
