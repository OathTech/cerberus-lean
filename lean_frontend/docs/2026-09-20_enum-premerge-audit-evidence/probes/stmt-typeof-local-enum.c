int main(void) { typeof(({ enum E { A,B }; (enum E)1 + 1; })) x=3; return x; }
