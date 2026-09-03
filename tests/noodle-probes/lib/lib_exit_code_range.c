/* Corner: exit status outside 0..255: the value is the model's verdict
   (Specified(300)); the OS truncates to 44 for gcc (7.22.4.4 impl-defined). */
#include <stdlib.h>
int main(void) { exit(300); }
