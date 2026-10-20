struct S { union { int b; unsigned char c; }; }; int main(void){ struct S s; s.b = 0x01020304; return s.c; }
