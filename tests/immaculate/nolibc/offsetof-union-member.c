/* Upstream asymmetry, MIRRORED (2026-09-01 S-basket item 1 probe;
   upstream-tray candidate): sizeof/alignof's Union arms read the Tags
   GLOBAL (impl_mem.ml:173,:255) even though the rest of the layout
   family threads ~tagDefs — elaboration-time offsetof over a
   union-containing struct therefore CRASHES upstream ("Tags definitions
   must be set", exit 125) and the Lean mirror panics identically-classed
   (unknown tag / not a UnionDef). This row pins the crash PAIR: both
   sides CRASH; a side starting to succeed is a divergence finding. */
#include <stddef.h>
union U { int i; char c; };
struct R { int k; union U u; };
int main(void) {
  return offsetof(struct R, u) == 4 ? 0 : 1;
}
