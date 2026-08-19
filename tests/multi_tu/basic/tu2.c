/* TU 2 of the 2-TU linking fixture (arc-5 S2). Defines the extern
   `helper` called from tu1.c; carries same-named statics (`v`, `bump`,
   local `s`) with DIFFERENT values, so any cross-TU static aliasing is
   observable in the final result. */
#include "shared.h"

static int v = 100;

static int bump(void) {
    static int s = 10;
    s += 1;
    return s;            /* first call: 11 (this TU's own s) */
}

int helper(struct pair p) {
    if (bump() != 11)
        return 0;        /* aliased local static would derail here */
    /* own v must be 100; own file-static intact */
    return p.a + p.b - (v == 100 ? 0 : 1);   /* 41 */
}
