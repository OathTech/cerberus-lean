int main(void){ int n = 0; int x = ({ n = n + 1; n + 10; }); return x*10 + n; }
