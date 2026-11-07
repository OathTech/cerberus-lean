/* control: memmove with d == s returns at once whatever n is (the shipped library). gcc 13 and every engine: Specified(4). Unmoved. */
#include <string.h>
int main(void) { char a[4] = {1,2,3,4}; char *b = a; memmove(a, b, (size_t)-1); return a[3]; }
