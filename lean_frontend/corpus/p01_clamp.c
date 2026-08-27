/* P01 clamp — THE EMBLEM. Families: branch/case-split (F1), multi-return (F13).
 * Fresh-written. Theorem: forall x in int range: result = max(x,0).
 * The assessment's emblem program, stated correctly: the postcondition is a
 * nontrivial function of x requiring a case analysis the substrate must
 * perform at a SYMBOLIC x. */
int clamp0(int x) {
  if (x < 0) return 0;
  return x;
}
/* harness: scalar init — args enter at the call boundary (T4/T5 route).
 * Theorem calls clamp0 directly:  forall x, intRange x -> outcome = {Specified (max x 0)} */
int main(void) { return clamp0(-3); } /* oracle differential sample only — NOT the theorem */
