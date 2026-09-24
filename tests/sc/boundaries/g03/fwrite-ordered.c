#include <stdio.h>
int main(void){char a=0,b=0;size_t x=0,y=0;x=fwrite(&a,0,1,stdout);y=fwrite(&b,0,1,stdout); return x+y+a+b;}
