int main(void){ int a[4]={0,0,0,0}; int *p = a; *p++ += 7; return (int)(p - a)*10 + a[0]; }
