/* Corner: printf integer conversions: length modifiers hh/h/l/ll/z, flags
   (+, space, 0, -), width, precision incl. %.0d of 0, %%, %c, %.2s, %5s
   (ISO C11 7.21.6.1). Arguments typed exactly as the conversions expect
   (unsigned for %x/%o/%u — see lib_printf_hex_int_arg.c). */
#include <stdio.h>
#include <stddef.h>
int main(void) {
  printf("[%hhd][%hd][%ld][%lld][%zu][%u][%hhu][%hu]\n", 300, 70000, -5L, 1LL << 40, (size_t)7, 4294967295u, 300u, 70000u);
  printf("[%x][%X][%o][%#x][%#o][%+d][% d][%05d][%-5d][%5.3d][%.0d][%.0d]\n", 255u, 255u, 8u, 255u, 8u, 5, 5, 42, 42, 7, 0, 1);
  printf("[%c][%.2s][%5s][%-5s][%%][%3c]\n", 65, "hello", "ab", "ab", 'z');
  return 0;
}
