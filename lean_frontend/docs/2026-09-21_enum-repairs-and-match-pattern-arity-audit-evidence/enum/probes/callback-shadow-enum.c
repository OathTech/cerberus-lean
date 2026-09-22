enum E { A, B }; int main(void) { typeof(({ enum E { C = -1, D }; enum E e = C; int *p = &e; p; })) x = 0; return x == 0; }
