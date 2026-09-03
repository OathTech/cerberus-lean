/* Corner: constant expressions in static initialisers: relational, sizeof, shifts,
   negative %, unsigned wrap, char arithmetic, address constants
   (ISO C11 6.6p7-9). The ?: form is elab_const_expr_ternary_init.c; the
   string-literal-plus-integer address constant is elab_addr_const_string_plus.c. */
#include <stdio.h>
static int a = (3 > 2) * 10 + 0;
static int b = sizeof(int) * 3 + (1 << 4);
static int c = -5 % 3;
static unsigned d = -1;
static int e = 'a' + 1;
static long f = 1L << 40 >> 38;
static int arr[3] = {1, 2, 3};
static int *p = &arr[1];
static int *q = arr + 2;
int main(void) { printf("%d %d %d %u %d %ld %d %d\n", a, b, c, d, e, f, *p, (int)(q - p)); return 0; }   /* 10 28 -2 4294967295 98 4 2 1 */
