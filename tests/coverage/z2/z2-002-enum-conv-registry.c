/* zero-discrepancy Z2 probe integration (2026-09-03; audit docs/2026-09-03_zero-discrepancy-Z2-audit.md §4,
   record docs/2026-09-04_zero-discrepancy-Z2-record.md). Origin: tests/z2-probes/mem/enum_conv.c — (enum E)4294967295u > 0 through the enum registry (Z2-M-14: CerberusImpl.typeof_enum is the real mirror).
   Three-engine AGREE at the audit and after the Z2 fix group; pinned here as a standing exec nolibc MATCH row. */
/* Z2 probe (conv_int through Enum -> typeof_enum): enum E is compatible with
   unsigned int under the GCC rule, so (enum E)4294967295u stays positive
   (1); with an int-typed stub it would wrap to -1 (0). nolibc. */
enum E { A = 1 };
int main(void) { enum E e = (enum E)4294967295u; return (int)(e > 0); }
