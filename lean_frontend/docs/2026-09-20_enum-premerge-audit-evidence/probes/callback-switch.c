enum E {A,B}; int main(void){typeof(({enum E e=A; switch(e){case A:break;} 1;})) x=3;return x;}
