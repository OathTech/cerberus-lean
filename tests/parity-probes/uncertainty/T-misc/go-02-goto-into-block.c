int main(void){ int x = 0; goto in; { int y = 5; x = 1; in: x += 10; } return x; }
