#include <stddef.h>
struct S { int m; }; int main(void) { return offsetof(struct S [[m::mk("s")]], m); }
