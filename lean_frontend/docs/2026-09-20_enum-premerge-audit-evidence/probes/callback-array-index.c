enum E {A,B}; int main(void){typeof(({int a[2]; enum E e=A; a[e];})) x=3;return x;}
