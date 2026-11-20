struct S { char c; int i; } __attribute__((packed)); int main(void) { return sizeof(struct S) == 5; }
