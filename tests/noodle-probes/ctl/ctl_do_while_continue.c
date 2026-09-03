/* Corner: continue in do-while jumps to the controlling expression; break
   out of nested loops; for with empty clauses (ISO C11 6.8.5, 6.8.6). */
#include <stdio.h>
int main(void) {
  int i = 0, n = 0, m = 0;
  do { i++; if (i & 1) continue; n += i; } while (i < 6);   /* n = 2+4+6 */
  for (;;) { if (++m > 4) break; }
  int k = 0;
  for (int a = 0; a < 3; a++) for (int b = 0; b < 3; b++) { if (b == 1) break; k++; }   /* 3 */
  printf("%d %d %d %d\n", i, n, m, k);   /* 6 12 5 3 */
  return 0;
}
