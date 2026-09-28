// mem4-010: a growth loop (the classic dynamic-array pattern): repeated
// doubling via realloc with content checks after each step.
#include <stdlib.h>
int main(void) {
  int cap = 1, n = 0;
  int *a = malloc(sizeof(int));
  if (!a) return 255;
  for (int i = 0; i < 20; i++) {
    if (n == cap) {
      cap *= 2;
      int *b = realloc(a, cap * sizeof(int));
      if (!b) return 254;
      a = b;
    }
    a[n++] = i * i;
  }
  int s = 0;
  for (int i = 0; i < n; i++) s += a[i];
  free(a);
  return (s % 256) + cap;
}
