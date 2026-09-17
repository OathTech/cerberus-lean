/* AUDITOR side-observation #3 (nolibc, no printf): is `(size_t)x + 1` truncated to 32 bits on the Lean engine too?
   Returns the bit pattern: bit0 = ((size_t)b + 1) >> 32 is zero (TRUNCATED); bit1 = ((unsigned long)b + 1) >> 32 is zero. */
#include <stddef.h>
#include <stdint.h>
int main(void) {
  unsigned long b = 281474976705856ULL;
  int r = 0;
  if ((((size_t)b + 1) >> 32) == 0) r |= 1;            /* truncated cast-then-add */
  if ((((unsigned long)b + 1) >> 32) == 0) r |= 2;     /* control: same type spelled without the typedef */
  if ((((size_t)(b + 1)) >> 32) == 0) r |= 4;          /* control: add-then-cast */
  return r;   /* expected if only the typedef'd cast-then-add truncates: 1 */
}
