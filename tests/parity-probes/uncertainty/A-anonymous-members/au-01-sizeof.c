struct S { union { int b; char c; }; }; int main(void){ return (int)sizeof(struct S); }
