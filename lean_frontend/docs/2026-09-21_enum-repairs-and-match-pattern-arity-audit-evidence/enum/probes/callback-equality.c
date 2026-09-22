enum E {A,B}; int main(void){typeof(({enum E e=A; unsigned int n=0; &e==&n;})) x=3;return x;}
