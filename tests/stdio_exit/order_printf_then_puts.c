/* the other direction: printf first. gcc: "ab\nc\n". */
#include <stdio.h>
int main(void) { printf("a"); puts("b"); printf("c\n"); return 0; }
