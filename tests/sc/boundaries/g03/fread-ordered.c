#include <stdio.h>
int main(void){char a=0,b=0;size_t x=0,y=0;x=fread(&a,0,1,stdin);y=fread(&b,0,1,stdin); return x+y+a+b;}
