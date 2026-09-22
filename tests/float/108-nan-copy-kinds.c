#include <string.h>
int main(void) {
 unsigned long long patterns[8]={0x7ff8000000000001ULL,0x7ff8000000000002ULL,0xfff8000000000001ULL,0xfff8000000000002ULL,0x7ff0000000000001ULL,0x7ff0000000000002ULL,0xfff0000000000001ULL,0xfff0000000000002ULL};
 int i; for(i=0;i<8;i++) { double a,b; unsigned long long out=0; memcpy(&a,&patterns[i],8); b=a; memcpy(&out,&b,8); if(out!=patterns[i])return i+1; }
 return 0;
}
