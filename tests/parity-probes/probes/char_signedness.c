#include <limits.h>
int main(void) {
  char c = (char)200;
  int i = c;   /* impl-defined: -56 if char signed, 200 if unsigned */
  return (CHAR_MIN < 0) ? (i == -56 ? 42 : 1) : (i == 200 ? 42 : 1);
}
