int main(void){ _Alignas(16) char buf[4]; return (int)((unsigned long)buf % 16); }
