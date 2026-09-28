// 035: getenv of an unset name returns NULL (the model has an empty
// environment; served-surface probe p3_getenv, extended).
#include <stdlib.h>
int main(void) { return (getenv("HOME") == NULL) + 2 * (getenv("") == NULL) + 4 * (getenv("PATH") == NULL); }
