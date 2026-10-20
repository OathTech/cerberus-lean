struct S { int v; }; int main(void){ struct S s[2]={{1},{1}}; int i=0; s[i++].v |= 4; return i*10 + s[0].v; }
