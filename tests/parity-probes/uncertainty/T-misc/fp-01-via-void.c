static int g(void){ return 9; } int main(void){ void *p = (void*)g; return ((int(*)(void))p)(); }
