struct S { char c; _Alignas(16) char d; }; int main(void) { return sizeof(struct S); }
