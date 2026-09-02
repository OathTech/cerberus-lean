struct big { char b[262144]; };
struct big gb;
struct big mk(void) { struct big s = gb; s.b[262144 - 1] = 7; return s; }
int main(void) { struct big r = mk(); return r.b[262144 - 1]; }
