/* TU 1 of the 2-TU linking fixture (arc-5 S2). Expected: 42.
   Same-named statics as tu2.c at every scope: file-scope `v`,
   static function `bump`, function-local static `s`. Each TU must keep
   its OWN copies (probed OCaml semantics, S0 survey §c.ii); any
   cross-TU aliasing (e.g. a concatenation stopgap) breaks the value or
   turns the program into a redefinition error. */
#include "shared.h"

static int v = 1;

static int bump(void) {
    static int s = 0;
    s += 1;
    return s;            /* first call: 1 */
}

int main(void) {
    struct pair p = { 40, 1 };
    /* helper (other TU) = 41; v (this TU's static) = 1; bump() = 1 */
    return helper(p) + v + bump() - 1;
}
