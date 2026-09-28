// fmt-020: %d with field width and every flag combination the model serves:
// '-' left-justify, '0' pad (sign before zeros), '+', ' ', and '-' overriding '0'.
#include <stdio.h>
int main(void) {
  int r = 0;
  r += printf("[%5d|%-5d|%05d|%+d|% d|%+5d|%-+6d]\n", 42, 42, 42, 42, 42, 42, 42);
  r += printf("[%+05d|% 05d|%-08d|%05d|%-05d|%+d|% d]\n", 42, 42, 42, -42, -42, -42, -42);
  r += printf("[%1d|%2d|%+d|% d|%3d]\n", 12345, -7, 0, 0, 0);
  return r;
}
