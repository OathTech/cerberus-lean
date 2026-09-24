int ferror(void *p) { return p==0 ? 7 : 8; }
int main(void) { return ferror((void*)0); }
