enum E {A,B}; unsigned int *f(void){typeof(({enum E *p=0; return p; 1;})) x=0;return 0;} int main(void){return f()==0;}
