/* control: every byte 1..255 stored through the shipped library's strcpy (C code, byte loads and stores: no
   escape round trip is involved), read back as unsigned char. gcc 13 and every engine, before and after the
   fix: the 255 values in order, bad=0, Specified(0). */
#include <stdio.h>
#include <string.h>
int main(void) {
  char src[2] = {0, 0};
  char buf[4];
  int bad = 0;
  for (int i = 1; i < 256; i++) {
    src[0] = (char)i; buf[0] = 1; buf[1] = 1;
    strcpy(buf, src);
    int v = (unsigned char)buf[0];
    if (v != i || buf[1] != 0) bad++;
    printf("%d%c", v, (i % 32 == 31) ? '\n' : ' ');
  }
  printf("bad=%d\n", bad);
  return bad;
}
