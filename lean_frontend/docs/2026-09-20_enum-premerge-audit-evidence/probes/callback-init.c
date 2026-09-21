enum E {A,B}; int main(void){typeof(({enum E e=A; unsigned int *p=&e; p;})) x=0; return x==0;}
