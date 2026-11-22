#include <string.h>
int main(void) {
  int r = 0;
  char buf[4];
  memset(buf, 200, sizeof buf);
  if (buf[0] > 0) r += 1;
  if (buf[3] == 200) r += 2;
  if (buf[3] == -56) r += 4;
  unsigned char u[4] = { 255, 128, 1, 0 };
  memcpy(buf, u, 4);
  if (buf[0] + buf[1] == 383) r += 8;
  if (buf[0] + buf[1] == -129) r += 16;
  if (memchr(buf, 128, 4) == buf + 1) r += 32;
  return r;
}
