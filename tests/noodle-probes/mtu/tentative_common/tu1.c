/* Corner (multi-TU): a tentative definition in tu1 plus an initialised
   definition in tu2 for the same external object: two external definitions
   (C11 6.9p5, UB — no diagnostic required). gcc >= 10 (-fno-common default)
   rejects at link time; both Cerberus engines link it and agree on 43 43. */
#include <stdio.h>
int shared;
int get(void);
int main(void) { shared += 1; printf("%d %d\n", shared, get()); return 0; }   /* 43 43 */
