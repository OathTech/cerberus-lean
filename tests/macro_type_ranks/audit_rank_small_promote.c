#include <stdint.h>
#include <stdio.h>
int main(void) { int8_t a = 100, b = 100; uint8_t c = 200; int16_t d = 30000, e = 30000; uint16_t f = 60000; uint32_t g = 4000000000u; int32_t h = 2000000000;
  printf("%d %d %d %d %d %d %d\n", (a + b) > 127, (c + 100) > 255, (d + e) > 32767, (f + f) > 65535, (g + 1u) > 0, (unsigned)(g + g) < g, sizeof(a + b) == sizeof(int)); return 0; }
