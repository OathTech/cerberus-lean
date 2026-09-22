#include <stdio.h>
union U { unsigned long long bits; double value; };
int main(void) { union U x={.bits=0xfff8000000000001ULL}; printf("%f",x.value); return 0; }
