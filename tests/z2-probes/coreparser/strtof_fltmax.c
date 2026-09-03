/* Z2 probe (lossy float literal in the pinned dump): libc.core:41698
   `Specified(3.40282347e+38)` is FLT_MAX printed with %.12g (17 significant
   digits are needed); Lean parses the rounded text, the oracle holds the
   exact double. Try the strtof overflow boundary. libc mode. */
#include <stdlib.h>
#include <stdio.h>
int main(void) {
  float a = strtof("3.4028234663852886e38", 0);   /* exactly FLT_MAX */
  float b = strtof("3.4028235e38", 0);
  float c = strtof("3.40282347e38", 0);
  printf("%d %d %d\n", a == b, b == c, c > 3.4e38f);
  return 0;
}
