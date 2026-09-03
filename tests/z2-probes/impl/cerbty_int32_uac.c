/* Z2 probe: the direct __cerbty_int32_t spelling (= Signed (IntN_t 32),
   builtins.lem) mixed with unsigned int — bypasses any header typedef. nolibc. */
int main(void) { __cerbty_int32_t s = -1; unsigned int u = 1; return (s + u) == 0; }
