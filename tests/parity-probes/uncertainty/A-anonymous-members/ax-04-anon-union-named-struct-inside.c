struct S { union { struct { unsigned char lo, hi; } p; unsigned short v; }; };
int main(void){ struct S s; s.v = 0x0201; return s.p.lo*10 + s.p.hi; }
