/* audit K2 k2_fwrite_twice shape; the second write unterminated. gcc: "ab\ncd". */
#include <stdio.h>
int main(void) { fwrite("ab\n", 1, 3, stdout); fwrite("cd", 1, 2, stdout); return 0; }
