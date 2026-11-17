static void (*target)(void);
static void recur(void) { target(); }
int main(void) { target = recur; recur(); }
