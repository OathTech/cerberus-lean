struct big { char b[1024]; };
struct big gb;
struct big mk(void) { struct big s = gb; s.b[1024 - 1] = 7; return s; }
int main(void) { struct big r = mk(); return r.b[1024 - 1]; }
