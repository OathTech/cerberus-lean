/* 2^53+1 ties to even (2^53); 2^53+3 ties to even (2^53+4) (expect 3) */
int main(void) { int a = 9007199254740993.0 == 9007199254740992.0; int b = 9007199254740995.0 == 9007199254740996.0; return a * 2 + b; }
