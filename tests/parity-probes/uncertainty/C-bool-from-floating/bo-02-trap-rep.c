int main(void){ union { unsigned char c; _Bool b; } u; u.c = 2; return u.b; }
