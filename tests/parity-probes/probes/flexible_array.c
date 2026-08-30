#include <stdlib.h>
struct F { int n; int data[]; };
int main(void) {
  struct F *f = malloc(sizeof(struct F) + 3*sizeof(int));
  if (!f) return 99;
  f->n = 3;
  for (int i = 0; i < 3; i++) f->data[i] = i+1;
  int s = f->data[0] + f->data[1] + f->data[2];
  free(f);
  return s;  /* 6 */
}
