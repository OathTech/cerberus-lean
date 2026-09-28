// 022: qsort of structs by a key, then bsearch for present and absent keys.
#include <stdio.h>
#include <stdlib.h>
struct kv { int k; char c; };
static int cmp(const void *a, const void *b) {
  return ((const struct kv *)a)->k - ((const struct kv *)b)->k;
}
int main(void) {
  struct kv t[5] = {{40, 'd'}, {10, 'a'}, {30, 'c'}, {20, 'b'}, {50, 'e'}};
  qsort(t, 5, sizeof t[0], cmp);
  struct kv key = {30, 0}, miss = {35, 0};
  struct kv *hit = bsearch(&key, t, 5, sizeof t[0], cmp);
  struct kv *none = bsearch(&miss, t, 5, sizeof t[0], cmp);
  return printf("%c%c%c%c%c %c %d\n", t[0].c, t[1].c, t[2].c, t[3].c, t[4].c,
                hit ? hit->c : '?', none == NULL);
}
