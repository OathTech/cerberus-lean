union U { int x; struct { short lo; short hi; }; }; int main(void){ union U u; u.x = 0x00050003; return u.lo + u.hi*10; }
