enum E { A, B }; int main(void) { typeof(({ enum E e = A; typeof(({ unsigned int *p = &e; p; })) y = 0; y; })) x = 0; return x == 0; }
