enum E { A=-1,B }; int main(void) { typeof(({ enum E x=A; x+1; })) y=3; return y; }
