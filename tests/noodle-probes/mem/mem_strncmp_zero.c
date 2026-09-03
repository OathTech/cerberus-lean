/* Corner: strncmp with n == 0 compares no characters and returns 0
   (ISO C11 7.24.4.4p2-3). gcc returns 1. */
#include <string.h>
int main(void) {
  return strncmp("abc", "xyz", 0) == 0 ? 1 : 2;
}
