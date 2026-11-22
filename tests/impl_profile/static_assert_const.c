_Static_assert(('\377' < 0) || ('\377' == 255), "one of the two");
int g[('\377' + 1 == 0) ? 3 : 5];
int main(void) { return (int)(sizeof g / sizeof g[0]); }
