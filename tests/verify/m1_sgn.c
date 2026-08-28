/* m1_sgn — V3a PERF-2 tightened-exit pre-registered program
   (lean_frontend/docs/2026-08-29_v3a-loops-mechC.md §2; registered
   BEFORE the construct-set extension, per review A1). Never-seen
   scalar program containing a construct outside the probe set
   (branches); proof must use ZERO generated per-round facts —
   construct-package minting + ≤ 6 anchors (k = 2). */
int sgn(int x) {
  if (x < 0) { return -1; }
  if (x > 0) { return 1; }
  return 0;
}
int main(void) { return sgn(-7) == -1 ? 0 : 1; }
