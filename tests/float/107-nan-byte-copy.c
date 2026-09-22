#include <string.h>
int main(void) { unsigned long long bits=0x7ff8000000000001ULL, out=0; double src, dst;
 memcpy(&src, &bits, sizeof src); dst=src; memcpy(&out, &dst, sizeof out); return bits==out; }
