/* Corner: char arrays initialised from string literals: exact fit without
   the NUL (6.7.9p14), embedded NUL sizes, zero-padding, char-list form. */
#include <stdio.h>
int main(void) {
  char s[3] = "abc";        /* no NUL */
  char t[] = "ab\0cd";      /* 6 */
  char u[5] = "ab";         /* u[4] == 0 */
  char v[2] = {'a', 'b'};
  const char w[] = "";      /* 1 */
  printf("%d %d %d %d %d %d %d\n", (int)sizeof s, s[2], (int)sizeof t, t[3], (int)sizeof u, u[4], (int)sizeof w);   /* 3 99 6 99 5 0 1 */
  return v[1] - 'b';
}
