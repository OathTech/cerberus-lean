// fmt-035: %hc: a length modifier other than l on %c (DUMMY UB in the model).
#include <stdio.h>
int main(void) { return printf("[%hc]\n", 'a'); }
