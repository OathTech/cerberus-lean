enum E {A,B}; int f(unsigned int *p){return 1;} int main(void){typeof(({enum E e=A; f(&e);})) x=2; return x;}
