struct S { int v; }; int main(void){ struct S s[2] = {{1},{2}}; struct S *p = s; (p++)->v += 5; return (int)(p - s)*10 + s[0].v; }
