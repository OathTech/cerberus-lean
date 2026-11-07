/* declared (tray 63's class, the crash-to-refusal item): '\0123' is an octal escape of three digits followed by '3' -- a multi-character constant whose value is implementation-defined (6.4.4.4#10; gcc 13: 2611, exit 51) -- which both engines decode as ONE four-digit octal escape (83) before and after; pinned to the fork's line. */
int main(void) { int c = '\0123'; return c & 0xff; }
