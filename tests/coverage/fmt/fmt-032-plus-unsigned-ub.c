// fmt-032: the '+' flag on an unsigned conversion is rejected by the model
// (formatted.lem printf_aux: DUMMY "+ flag with unsigned conversion").
#include <stdio.h>
int main(void) { return printf("[%+u]\n", 5u); }
