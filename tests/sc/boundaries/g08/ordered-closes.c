#include <stdio.h>
int main(void) { FILE *a=fopen("sc-first.tmp","w"), *b=fopen("sc-second.tmp","w"); if(!a || !b) return 7; fclose(a); fclose(b); return 0; }
