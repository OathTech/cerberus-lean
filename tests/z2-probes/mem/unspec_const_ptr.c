/* Z2 probe (abst, unspecified pointer ctype — charter Z-19): impl_mem.ml:
   1056-1057 rebuilds `Pointer (no_qualifiers, ref_ty)` for the unspecified
   value; CerbMem.reconstructValue keeps the requested ctype (qualifiers and
   annotations). Attempt to make the Unspecified value's ctype text reach the
   verdict line. nolibc. */
int main(void) { const int *p; return (int)(long)p; }
