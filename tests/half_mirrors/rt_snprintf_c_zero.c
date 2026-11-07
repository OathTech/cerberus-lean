/* control: %c of 0 stored mid-string (the NUL terminates the stored text; r = 3). gcc 13 and every engine: Specified(37). Unmoved. */
#include <stdio.h>
int main(void) { char buf[8] = "zzzzzzz"; int r = snprintf(buf, 8, "a%cb", 0); return r * 10 + (buf[0] == 'a') + (buf[1] == 0) * 2 + (buf[2] == 'b') * 4 + (buf[3] == 0) * 8; }
