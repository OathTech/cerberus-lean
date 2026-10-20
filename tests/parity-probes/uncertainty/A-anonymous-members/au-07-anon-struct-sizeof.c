struct T { int a; struct { int b; int c; }; }; int main(void){ return (int)sizeof(struct T); }
