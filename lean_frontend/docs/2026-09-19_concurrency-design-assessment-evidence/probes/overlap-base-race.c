int main(void) { int x=0; int r=0; {-{ x=0x01010101; ||| r=((unsigned char*)&x)[0]; }-} return r; }
