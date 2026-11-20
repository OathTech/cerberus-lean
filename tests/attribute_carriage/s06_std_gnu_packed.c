struct [[gnu::packed]] S { char c; int i; }; int main(void) { return sizeof(struct S) == 5; }
