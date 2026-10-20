int main(void){ float a[2] = {1.0f, 2.0f}; char *p = (char*)a; return (int)((char*)&a[1] - p); }
