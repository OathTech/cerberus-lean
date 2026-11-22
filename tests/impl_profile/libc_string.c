#include <string.h>
int main(void) {
  int r = 0;
  char a[4] = "\377\200a", b[4];
  strcpy(b, a);
  if (b[0] == a[0] && b[1] == a[1]) r += 1;
  if (strlen(b) == 3) r += 2;
  if (strcmp("\377", "a") > 0) r += 4;
  if (memcmp("\200", "\177", 1) > 0) r += 8;
  if (strchr(a, '\200') == a + 1) r += 16;
  if (strchr(a, 128) == a + 1) r += 32;
  if (b[0] > 0) r += 64;
  return r;
}
