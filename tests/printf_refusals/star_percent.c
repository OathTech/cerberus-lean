/* REFUSAL: `%*%` is a %% conversion specification carrying a `*` field width (7.21.6.1#8 "shall be %%": undefined
   behaviour, 4#2). Upstream crashed (`TODO: formatted.lem 6`); the first version of this slice consumed the int and
   padded (an invented value, the pre-merge review's P2-1); since 2026-11-07 a declared refusal with its attributed
   text, pinned whole on both engines. gcc prints `%`. */
#include <stdio.h>

int main(void) { printf("[%*%]\n", 3); return 0; }
