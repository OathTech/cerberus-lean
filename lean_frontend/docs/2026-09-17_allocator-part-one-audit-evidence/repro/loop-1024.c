/* AUDITOR timing probe: 1024 x malloc(0xFFFFFFF0) lowers the cursor by ~2^42; report the last address's top bits. */
#include <stdlib.h>
#include <stdint.h>
int main(void) {
  uintptr_t a = 0;
  for (unsigned i = 0; i < 1024u; i++) { char *p = malloc(0xFFFFFFF0u); if (!p) return 3; a = (uintptr_t)p; }
  return (int)((a >> 40) & 0xff);
}
