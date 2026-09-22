union U { unsigned long long bits; double value; };
int main(void) { union U src = { .bits=0x7ff8000000000001ULL }, dst;
 dst.value=src.value; return dst.bits==src.bits; }
