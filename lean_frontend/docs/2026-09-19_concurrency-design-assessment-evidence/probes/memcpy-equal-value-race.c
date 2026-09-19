#include <string.h>
int main(void) { int x=0; int y=0; {-{ memcpy(&x,&y,sizeof x); ||| x=0; }-} return 0; }
