/* total-arith sweep pin (2026-10-03; record docs/2026-10-03_total-arith-and-bookkeeping-record.md §2, §7).
   _Alignas(2^62) on an object whose struct type has a 2^62-aligned member: the desugarer compares the
   declared type's alignment (cabs_to_ail.lem desugar_alignment_specifiers -> Implementation.alignof_ty),
   and Ocaml_implementation.alignof reads the member alignment through Z.to_int (ocaml_implementation.ml:501):
   Z.Overflow (uncaught, exit 125). ISO-fix register R7: Lean keeps the unbounded alignment (2^62, not less
   strict than the specifier: accepted), then g (sizeof 2^62, align 2^62) cannot be placed below the default
   address-space top -> the allocator's out-of-memory Error. Pinned ORACLE_CRASH | L=ERR (re-pinned 2026-10-03;
   the program changed from `_Alignas(8) struct s g;`, whose Lean answer — a less-strict-alignment desugaring failure —
   carries the input's absolute path in its token, so it cannot be pinned portably). */
struct s { _Alignas(0x4000000000000000) char x; };
_Alignas(0x4000000000000000) struct s g;
int main(void) { return 0; }
