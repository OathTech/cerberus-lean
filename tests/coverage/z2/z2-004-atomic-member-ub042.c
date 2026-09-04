/* zero-discrepancy Z2 probe integration (2026-09-03; audit docs/2026-09-03_zero-discrepancy-Z2-audit.md §4,
   record docs/2026-09-04_zero-discrepancy-Z2-record.md). Origin: tests/z2-probes/mem/atomic_member_stderr.c — is_atomic_member_access UB042 (Z2-M-17: the oracle's two extra TOOL-stderr lines are not verdict content).
   Three-engine AGREE at the audit and after the Z2 fix group; pinned here as a standing exec nolibc UB_MATCH row. */
/* Z2 probe (is_atomic_member_access): both engines must give UB042; the
   oracle additionally prints two diagnostic lines to ITS stderr
   (impl_mem.ml:698-702 Printf.fprintf stderr) that Lean does not — tool
   stderr, not the program's `stderr:` field. nolibc. */
struct S { int a; int b; };
_Atomic struct S s;
int main(void) { return s.a; }
