/* zero-discrepancy Z2 probe integration (2026-09-03; audit docs/2026-09-03_zero-discrepancy-Z2-audit.md §4,
   record docs/2026-09-04_zero-discrepancy-Z2-record.md). Origin: tests/z2-probes/mem/unspec_const_ptr.c — Z-19 route: the cast's type wins, Unspecified('signed int') on all engines.
   Three-engine AGREE at the audit and after the Z2 fix group; pinned here as a standing exec nolibc MATCH row. */
/* Z2 probe (abst, unspecified pointer ctype — charter Z-19): impl_mem.ml:
   1056-1057 rebuilds `Pointer (no_qualifiers, ref_ty)` for the unspecified
   value; CerbMem.reconstructValue keeps the requested ctype (qualifiers and
   annotations). Attempt to make the Unspecified value's ctype text reach the
   verdict line. nolibc. */
int main(void) { const int *p; return (int)(long)p; }
