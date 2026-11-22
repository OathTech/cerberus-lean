#include <limits.h>
enum { LO = CHAR_MIN, HI = CHAR_MAX };
int a[CHAR_MAX > 127 ? 7 : 3];
int main(void) { return (LO == 0 ? 1 : 0) + (HI == 255 ? 2 : 0) + (int)(sizeof a / sizeof a[0]) * 4; }
