/* static-shadows-extern, TU 1: a STATIC function and a static object with the
   same names as TU 2's EXTERNAL definitions; TU 1's own code must bind to its
   statics. */
static int f(void) { return 1; }
static int g = 10;
int from_tu1(void) { return f() + g; }   /* 11 */
