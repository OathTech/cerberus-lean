/* pr44468 defect class (CI-sweep finding; 2026-09-01 S-basket item 1):
   offsetof on a struct with a struct-typed member is constant-folded at
   ELABORATION time (translation.lem:2730 -> Mem.offsetof_ival), before
   the tagDefs global is populated — the layout family must thread the
   explicit tagDefs (impl_mem.ml ~tagDefs) or the inner tag lookup dies.
   Pre-fix Lean: PANIC CerbMem.offsetsof unknown tag. Oracle: Specified(0). */
#include <stddef.h>
struct S { int i; int j; };
struct R { int k; struct S a; };
int main(void) {
  return offsetof(struct R, a) == sizeof(int) ? 0 : 1;
}
