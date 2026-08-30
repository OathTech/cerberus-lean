/* CerbFS offset hole: does fgetc advance and hit EOF? */
#include <stdio.h>
int main(void) {
  FILE *f = fopen("t.txt", "w");
  if (!f) return 99;
  fwrite("ab", 1, 2, f);
  fclose(f);
  f = fopen("t.txt", "r");
  if (!f) return 98;
  int n = 0, c;
  while ((c = fgetc(f)) != EOF && n < 10) n++;
  fclose(f);
  return n;  /* expect 2; a non-advancing read gives 10 */
}
