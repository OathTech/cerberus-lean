/* Corner: string literal concatenation, escapes at concatenation
   boundaries, sizeof of literals, the implicit NUL (ISO C11 6.4.5). */
#include <stdio.h>
int main(void) {
  char *s = "a" "b";
  const char *t = "\x41" "B";       /* "AB" (hex escape ends at the literal boundary) */
  const char *o = "\1234";          /* octal 123 = 'S' then '4' */
  const char *e = "\n\t\\\"\'\?";
  printf("%d %d %d %d ", s[1], t[0], t[1], (int)sizeof("abc"));   /* 98 65 66 4 */
  printf("%d %d %d ", o[0], o[1], (int)sizeof("\1234"));            /* 83 52 3 */
  printf("%d %d %d %d %d %d ", e[0], e[1], e[2], e[3], e[4], e[5]); /* 10 9 92 34 39 63 */
  printf("%d %d\n", "abc"[3], (int)sizeof("a\0b"));                 /* 0 4 */
  return 0;
}
