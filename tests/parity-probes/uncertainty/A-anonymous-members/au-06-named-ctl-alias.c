struct S { union { int b; unsigned char c; } u; }; int main(void){ struct S s; s.u.b = 0x01020304; return s.u.c; }
