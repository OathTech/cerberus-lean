/* Corner: the (size_t)-1 sentinel idiom: for size_t n == 0, n - 1 must equal
   (size_t)-1 == SIZE_MAX (ISO C11 6.2.5p9 modulo arithmetic in size_t after
   6.3.1.8 conversion of the int operand). gcc returns 1. CONTROL for U1:
   the operand truncation only bites for operand values >= 2^32; here the
   result is re-wrapped in size_t, so all engines return 1. */
#include <stddef.h>
int main(void) {
  size_t n = 0;
  size_t m = n - 1;
  return (m == (size_t)-1) ? 1 : 2;
}
