/* Z2 probe (is_atomic_member_access): both engines must give UB042; the
   oracle additionally prints two diagnostic lines to ITS stderr
   (impl_mem.ml:698-702 Printf.fprintf stderr) that Lean does not — tool
   stderr, not the program's `stderr:` field. nolibc. */
struct S { int a; int b; };
_Atomic struct S s;
int main(void) { return s.a; }
