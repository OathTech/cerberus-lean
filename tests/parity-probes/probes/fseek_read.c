/* seek-then-read must honor the offset */
#include <stdio.h>
int main(void) {
  FILE *f = fopen("v.txt", "w");
  if (!f) return 99;
  fwrite("wxyz", 1, 4, f);
  fclose(f);
  f = fopen("v.txt", "r");
  fseek(f, 2, SEEK_SET);
  int c = fgetc(f);
  fclose(f);
  return c == 'y' ? 42 : c;  /* 42 if honored; 'w'=119 if read-from-0 */
}
