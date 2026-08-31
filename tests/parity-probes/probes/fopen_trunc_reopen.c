/* audit F1 (trust-basket audit response): reopening an existing file
   with "w" must truncate; a flag-blind open serves STALE data later
   with no refused op on the path. */
#include <stdio.h>
int main(void) {
  FILE *f = fopen("t.txt", "w");
  if (!f) return 99;
  fwrite("ab", 1, 2, f);
  fclose(f);
  f = fopen("t.txt", "w");   /* POSIX: truncates to empty */
  if (!f) return 98;
  fclose(f);
  f = fopen("t.txt", "r");
  if (!f) return 96;
  int c = fgetc(f);
  fclose(f);
  return c == EOF ? 5 : c;   /* truncated: EOF -> 5; stale: 'a' = 97 */
}
