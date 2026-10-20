int main(void){ int n = 0; int x = ({ int y = 1; n++; y + n; }); return x*10 + n; }
