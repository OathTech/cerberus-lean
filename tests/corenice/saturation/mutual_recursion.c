static void second(void);
static void first(void) { second(); }
static void second(void) { first(); }
int main(void) { first(); }
