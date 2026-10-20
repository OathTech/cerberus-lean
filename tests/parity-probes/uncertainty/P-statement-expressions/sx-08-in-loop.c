int main(void){ int s = 0; for (int i = 0; i < 3; i++) s += ({ int t = i * 2; t; }); return s; }
