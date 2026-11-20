struct S { int m [[cerb::with_address("0x1000")]]; }; int main(void) { struct S s; s.m = 0; return s.m; }
