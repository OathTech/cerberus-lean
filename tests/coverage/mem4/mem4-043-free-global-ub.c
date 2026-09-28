// mem4-043: free of a static-storage object.
#include <stdlib.h>
int g;
int main(void) { free(&g); return 0; }
