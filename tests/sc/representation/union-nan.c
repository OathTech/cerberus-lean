int main(void){union{unsigned long u;double d;}x;x.u=0x7ff8000000000000UL;double y=x.d;return y!=y;}
