static int g(void){ return 9; } int main(void){ long l = (long)g; return ((int(*)(void))l)(); }
