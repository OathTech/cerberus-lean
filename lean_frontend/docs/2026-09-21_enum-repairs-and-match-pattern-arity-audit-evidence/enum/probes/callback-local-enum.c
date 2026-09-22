int main(void) { typeof(({ enum E { A, B }; enum E e = A; unsigned int *p = &e; p; })) x = 0; return x == 0; }
