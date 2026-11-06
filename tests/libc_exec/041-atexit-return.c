// 041: returning from main runs the atexit handlers (ISO C17 5.1.2.2.3: the return
// is equivalent to exit(7); 7.22.4.4#2: the handlers run) -- both engines print
// "main\nbye\n" and report Specified(7) since fix/stdio-exit-flush (2026-11-06,
// upstream-tray report 25); gcc 13 the same with $?=7. Before the fix both
// engines printed only "main" (pinned then as a mirrored upstream behaviour;
// now a shared-model-fix register row against pristine c3ff8c53f).
#include <stdio.h>
#include <stdlib.h>
void bye(void) { printf("bye\n"); }
int main(void) { atexit(bye); printf("main\n"); return 7; }
