int main(void){ int n = 1; int x = ({ if (n) n = 2; n; }); return x*10 + n; }
