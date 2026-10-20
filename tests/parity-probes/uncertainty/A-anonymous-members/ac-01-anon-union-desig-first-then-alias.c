struct S { int tag; union { unsigned v; unsigned char bytes[4]; }; };
int main(void){ struct S s = { .tag = 1, .v = 0x01020304 }; return s.bytes[0] + s.tag*10; }
