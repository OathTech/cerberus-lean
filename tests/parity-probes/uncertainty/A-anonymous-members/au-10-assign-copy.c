struct S { union { int b; unsigned char c; }; }; int main(void){ struct S s, t; s.b = 0x0102; t = s; return t.c; }
