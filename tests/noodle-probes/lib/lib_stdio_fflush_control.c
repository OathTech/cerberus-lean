/* Corner: fputs followed by fflush then printf: ordered output "outz"
   (ISO C11 7.21.5.2). CONTROL: all engines agree. */
#include <stdio.h>
int main(void) { fputs("out", stdout); fflush(stdout); printf("z\n"); return 0; }
