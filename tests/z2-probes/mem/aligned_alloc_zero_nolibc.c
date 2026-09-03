/* Z2 probe: aligned_alloc_zero.c in --nolibc mode (same std.core proxy via
   the ailname redirect; shows the mode does not matter). */
extern void *aligned_alloc(unsigned long, unsigned long);
int main(void) { void *p = aligned_alloc(0, 8); return p != 0; }
