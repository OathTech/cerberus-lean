struct big { char b[4096]; };
struct big gb;
struct big mk(void) { struct big s = gb; s.b[4096 - 1] = 7; return s; }
int main(void) { struct big r = mk(); return r.b[4096 - 1]; }
