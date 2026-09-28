// mem4-022: partial memcpy of an int's bytes into another int: the result
// combines bytes of both objects (little-endian, LP64 concrete model).
#include <string.h>
int main(void) {
  unsigned a = 0x11223344u, b = 0xaabbccddu;
  memcpy(&b, &a, 3);
  return (int)(b >> 16);
}
