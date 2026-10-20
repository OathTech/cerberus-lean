struct S { unsigned bf : 3; }; int main(void){ struct S s[2] = {{1},{1}}; int i = 0; s[i++].bf += 2; return i*10 + s[0].bf; }
