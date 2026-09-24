#include <stdio.h>
int replace_stream(FILE *f) { f=stderr; return ferror(f); }
int main(void) { return replace_stream(stdout); }
