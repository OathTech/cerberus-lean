int main(void){ int a[4] = {[2]=5, 6, [0]=7}; return a[0]*10 + a[2] + a[3]*100 + a[1]*1000; }
