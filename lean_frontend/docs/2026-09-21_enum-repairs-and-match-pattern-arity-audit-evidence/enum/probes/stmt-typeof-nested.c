enum E { A,B }; int main(void) { typeof(({ ({(enum E)1 + 1;}); })) x=3;return x;}
