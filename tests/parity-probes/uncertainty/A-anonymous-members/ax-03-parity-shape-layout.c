struct S { int tag; union { struct { int x, y; }; long l; }; };
int main(void){ struct S s; s.x = 20; s.y = 22; return (int)(sizeof(struct S)) + (s.l == ((long)22 << 32 | 20)); }
