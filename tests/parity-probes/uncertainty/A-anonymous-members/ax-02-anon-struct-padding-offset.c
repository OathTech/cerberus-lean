struct S { char a; struct { char b; int c; }; }; int main(void){ struct S s; return (int)((char*)&s.c - (char*)&s); }
