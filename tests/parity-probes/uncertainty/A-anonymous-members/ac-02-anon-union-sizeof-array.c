struct S { union { unsigned v; unsigned char bytes[4]; }; }; int main(void){ struct S a[3]; return (int)sizeof(a); }
