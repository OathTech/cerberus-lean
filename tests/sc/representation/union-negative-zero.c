int main(void){union{unsigned long u;double d;}x;x.u=0x8000000000000000UL;double y=x.d;return y==0.0;}
