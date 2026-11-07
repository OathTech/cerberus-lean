/* control: strncpy pads with NULs up to n. gcc 13 and every engine: Specified(97). Unmoved. */
#include <string.h>
int main(void) { char a[4] = "xyz"; char b[4] = "a"; strncpy(a, b, 4); return a[0] + a[1] + a[2] + a[3]; }
