#include <stdio.h>
int main(void) { long a=0,b=0; {-{ {a=ftell(stdout);} ||| {b=ftell(stdout);} }-}; return (a==b); }
