struct S { char a; struct { char b; int c; }; }; int main(void){ return (int)sizeof(struct S); }
