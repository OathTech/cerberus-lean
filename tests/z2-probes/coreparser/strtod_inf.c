/* Z2 probe (CoreParser vs the oracle's in-memory libc.co): the pinned
   --pp=core dump tests/libc/libc.core:53897 prints `pure(Specified(inf))`
   (pp_core.ml:279-282 string_of_float) inside proc decfloat's overflow path;
   CoreParser.lean:1072/1321-1328 lexes `inf` as an identifier -> PEsym
   (unbound), where the oracle's AST holds OVfloating +inf. libc mode. */
#include <stdlib.h>
int main(void) { double d = strtod("1e5000", 0); return d > 1e308; }
