/* Corner: main returns -1: the model reports Specified(-1); the OS shows 255
   (ISO C11 5.1.2.2.3 impl-defined status). */
int main(void) { return -1; }
