// mem4-021: memcpy of a struct containing pointers: the copy's pointers keep
// their provenance and can be used to write through.
#include <string.h>
struct node { int *p; int *q; int v; };
int main(void) {
  int x = 5, y = 6;
  struct node a = { &x, &y, 7 }, b;
  memcpy(&b, &a, sizeof a);
  *b.p = 50; *b.q += 1;
  return x + y + b.v;
}
