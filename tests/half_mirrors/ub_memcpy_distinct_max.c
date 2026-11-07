/* sibling control: memcpy already loops on Z (impl_mem.ml:2561-2570): UB_CERB002a on every engine before and after. gcc 13: SIGSEGV (139). Unmoved. */
#include <string.h>
int main(void) { char a[4] = {1,2,3,4}; char b[4] = {1,2,3,4}; memcpy(a, b, (size_t)-1); return a[3]; }
