int main(void){ struct { int x, y; } s = {.y=2, .x=1, .y=3}; return s.x*10+s.y; }
