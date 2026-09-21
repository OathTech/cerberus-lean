enum E { A=-1,B }; union U {enum E e; unsigned char a[sizeof(enum E)];}; int main(void){union U u; u.e=A; return u.a[0];}
