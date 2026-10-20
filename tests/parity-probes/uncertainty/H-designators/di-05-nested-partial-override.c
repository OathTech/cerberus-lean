int main(void){ struct { int a[2]; int b; } s = {.a = {1,2}, .a[1] = 9}; return s.a[0]*10 + s.a[1]; }
