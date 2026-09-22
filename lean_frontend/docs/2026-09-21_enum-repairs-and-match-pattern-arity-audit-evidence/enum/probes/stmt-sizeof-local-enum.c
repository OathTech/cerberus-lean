int main(void) { return sizeof(({ enum E { A, B }; (enum E)1 + 1; })); }
