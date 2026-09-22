enum E { A = -1, B }; int main(void) { typeof(({ enum E e = A; int *p = &e; p; })) x = 0; return x == 0; }
