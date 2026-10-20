int main(void){ struct { int *q; } s; { int x = 5; s.q = &x; } return s.q == 0; }
