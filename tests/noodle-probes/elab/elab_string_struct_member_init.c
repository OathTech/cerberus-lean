/* Corner: a string literal initialising a char-array MEMBER of a struct,
   with explicit inner braces (ISO C11 6.7.9p14). gcc returns 98 ('b').
   Both Cerberus engines reject (same diagnostic as elab_string_member_init.c). */
struct W { char c[3]; } w = {{"ab"}};
int main(void) { return w.c[1]; }
