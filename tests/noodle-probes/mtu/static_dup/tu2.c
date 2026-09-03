static int counter = 0;
static int bump(void) { return ++counter; }
int other_bump(void) { return bump(); }
