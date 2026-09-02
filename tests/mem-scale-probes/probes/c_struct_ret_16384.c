struct big { char b[16384]; };
struct big gb;
struct big mk(void) { struct big s = gb; s.b[16384 - 1] = 7; return s; }
int main(void) { struct big r = mk(); return r.b[16384 - 1]; }
