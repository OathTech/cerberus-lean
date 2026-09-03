/* Direct read of the Core constant IvMaxAlignment on the Lean side:
   rand()'s Core body is REPLACED via cerberus-lean --libc with
   `pure(Specified(IvMaxAlignment))` (inject_maxalign.core). */
#include <stdlib.h>
int main(void) { return rand(); }
