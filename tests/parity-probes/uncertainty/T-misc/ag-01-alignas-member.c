struct S { char c; _Alignas(8) char d; }; int main(void){ return (int)sizeof(struct S); }
