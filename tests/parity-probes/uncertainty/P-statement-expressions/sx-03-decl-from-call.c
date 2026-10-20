static int n; static int g(void){ return ++n; } int main(void){ int x = ({ int y = g(); y; }); return x*10 + n; }
