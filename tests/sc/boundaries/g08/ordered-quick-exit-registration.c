#include <stdlib.h>
void end_hook(void) {}
int main(void) { int a=at_quick_exit(end_hook); int b=at_quick_exit(end_hook); return a || b; }
