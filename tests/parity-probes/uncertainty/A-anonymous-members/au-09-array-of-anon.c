struct S { union { int b; unsigned char c; }; }; int main(void){ struct S s[2]; s[1].b = 7; return (int)sizeof(s) + s[1].c; }
