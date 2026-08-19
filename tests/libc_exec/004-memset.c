#include <string.h>
int main(void) {
  char buf[8];
  memset(buf, 3, 8);
  return buf[0] + buf[7];
}
