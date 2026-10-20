struct S { const char *name; int v; }; int main(void){ struct S s = { "ab", 7 }; return s.name[1] + s.v; }
