enum E { A, B }; int main(void) { enum E x=(enum E)-1; int a=x<0; {enum E { C=-1,D }; enum E y=C; a+=2*(y<0);} return a + 4*(x>0); }
