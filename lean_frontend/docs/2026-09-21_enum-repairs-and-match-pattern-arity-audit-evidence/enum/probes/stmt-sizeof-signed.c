enum E { A = -1, B }; int main(void) { return sizeof(({ enum E x = A; x + 1; })); }
