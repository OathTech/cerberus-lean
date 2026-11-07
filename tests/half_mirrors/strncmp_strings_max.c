/* control: strncmp on terminated strings stops at the first difference whatever n is. gcc 13 and every engine: Specified(1). Unmoved. */
#include <string.h>
int main(void) { char a[4] = "abc"; char b[4] = "abd"; return strncmp(a, b, (size_t)-1) < 0 ? 1 : 2; }
