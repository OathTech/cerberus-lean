enum E {A,B}; int main(void){typeof(({enum E *p=0; unsigned int *q=0; 1?p:q;})) x=0;return x==0;}
