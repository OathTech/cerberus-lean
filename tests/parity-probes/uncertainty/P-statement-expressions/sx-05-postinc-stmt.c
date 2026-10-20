int main(void){ int n = 0; int x = ({ n++; 5; }); return x*10 + n; }
