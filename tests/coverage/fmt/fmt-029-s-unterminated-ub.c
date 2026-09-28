// fmt-029: plain %s on an unterminated array: the scan runs off the end.
#include <stdio.h>
int main(void) { char buf[2] = {'x','y'}; return printf("[%s]\n", buf); }
