/* addr-const-init-unresolved, TU 2: static-storage pointers initialised with
   addresses of the OTHER TU's objects (address constants that ISO resolves at
   link time), including an interior array element. OBSERVED (2026-09-28,
   thin-surface tests slice): both engines stop with
   Error "unresolved symbol: target at unknown location" — the shared linker
   does not resolve an extern object named in another TU's static
   initializer. Pinned as the observed agreement (a shared-model limitation,
   recorded in docs/2026-09-28_thin-surface-tests-record.md), not endorsed.
   ISO expectation: 600 + 90 + 8 + 1 = 699. */
extern int target;
extern int vec[3];
int *pt = &target;
int *pv = &vec[2];
struct holder { int *a; int *b; } h = { &target, vec };
int main(void) {
  *pt += 1;
  return target * 100 + *pv * 10 + h.b[1] + (h.a == pt);
}
