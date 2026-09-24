#include <string.h>
int main(void){unsigned long u=0x8000000000000000UL;double d;memcpy(&d,&u,sizeof d);return d==0.0;}
