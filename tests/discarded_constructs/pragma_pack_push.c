#pragma pack(push, 1)
struct S { char c; int i; };
#pragma pack(pop)
int main(void) { return sizeof(struct S); }
