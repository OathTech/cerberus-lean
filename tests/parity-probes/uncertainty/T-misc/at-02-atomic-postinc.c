int main(void){ _Atomic int x = 1; int y = x++; return x*10 + y; }
