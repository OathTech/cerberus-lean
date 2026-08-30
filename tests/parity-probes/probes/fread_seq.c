/* two sequential freads must return consecutive chunks */
#include <stdio.h>
int main(void) {
  FILE *f = fopen("u.txt", "w");
  if (!f) return 99;
  fwrite("abcd", 1, 4, f);
  fclose(f);
  f = fopen("u.txt", "r");
  char x[2], y[2];
  fread(x, 1, 2, f);
  fread(y, 1, 2, f);
  fclose(f);
  return (x[0]=='a') + (x[1]=='b') + 10*((y[0]=='c') + (y[1]=='d'));  /* 22 */
}
