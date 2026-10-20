int main(void){ int x = ({ int y = 5; y + 1; }); return x; }
