int main(void){ unsigned u[2]={1,1}; int i=0; u[i++] <<= 2; return i*10 + (int)u[0]; }
