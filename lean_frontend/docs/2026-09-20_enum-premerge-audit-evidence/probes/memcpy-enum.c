#include <string.h>
enum E {A=-1,B};int main(void){enum E a=A,b=B;memcpy(&b,&a,sizeof a);return b<0;}
