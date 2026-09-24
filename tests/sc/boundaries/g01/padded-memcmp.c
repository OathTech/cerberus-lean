#include <string.h>
struct P { unsigned char c; int i; };
int main(void) {
  struct P x = {1, 2};
  struct P y = {1, 2};
  return memcmp(&x, &y, sizeof x) == 0;
}
