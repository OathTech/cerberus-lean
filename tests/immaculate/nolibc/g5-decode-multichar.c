// G5: a multi-character constant. Upstream decode failwiths on unknown
// multi-char; Lean returns the first char's code silently.
int main(void) { int c = 'ab'; return c & 0x7f; }
