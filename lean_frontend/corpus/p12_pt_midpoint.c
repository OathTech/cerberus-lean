/* P12 pt_midpoint — structs in and out, inputs FRAMED. Families: struct
 * fields (F10), three-pointer disjointness + frame-as-observable (F9),
 * pointer args (F7), memory in/out (F14), arithmetic (F12). Derived
 * (arrow-access shape) from deps/cn/tests/cn/arrow_access.c (BSD-2).
 * BOUNDS (anti-brute-force ruling, derived inline): the sole hazard is
 * a->x + b->x — pre: |coords| <= 1073741823 = INT_MAX/2 (largest bound
 * making every sum representable; full range would admit overflow, so the
 * tighter bound is FORCED by the type, documented here). Domain ~ (2^31)^4
 * — non-enumerable.
 * Theorem: forall ax ay bx by in the derived range: out = midpoint AND the
 * final memory at a,b equals the initial (frame checked by readback: 9). */
struct pt { int x; int y; };
void midpoint(const struct pt *a, const struct pt *b, struct pt *out) {
  out->x = (a->x + b->x) / 2;
  out->y = (a->y + b->y) / 2;
}
int harness(int ax, int ay, int bx, int by) {
  struct pt a = {ax, ay}, b = {bx, by}, o = {0, 0};
  midpoint(&a, &b, &o);
  if (a.x != ax || a.y != ay || b.x != bx || b.y != by) return 9; /* frame */
  return (o.x == (ax + bx) / 2 && o.y == (ay + by) / 2) ? 0 : 1;
}
int main(void) { return harness(0, 2, 4, 6); }
