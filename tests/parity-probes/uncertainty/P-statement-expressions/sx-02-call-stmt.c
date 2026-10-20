static int n; static int g(void){ return ++n; } int main(void){ int x = ({ g(); 5; }); return x*10 + n; }
