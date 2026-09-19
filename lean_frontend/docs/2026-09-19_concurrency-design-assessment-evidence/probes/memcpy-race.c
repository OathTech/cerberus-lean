#include <string.h>
int main(void) { int x=0; int y=7; {-{ memcpy(&x,&y,sizeof x); ||| x=2; }-} return 0; }
