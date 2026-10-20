struct S { union { int b; char c; } u; }; int main(void){ return (int)sizeof(struct S); }
