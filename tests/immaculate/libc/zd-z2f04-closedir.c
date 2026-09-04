/* zero-discrepancy Z2 pin (2026-09-03; audit row Z2-F-04, tests/z2-probes/fs/closedir.c; record
   docs/2026-09-04_zero-discrepancy-Z2-record.md). opendir/closedir through the libc: BOTH engines crash in
   the shared model — `Failure("internal error: can_advance: Step_error2 ==> …the value of a store(signed int*)
   didn't match the lvalue type: Specified(1)")` on the oracle, the same failwithI text on Lean (the embedded
   fd number differs, 1 vs 3 — CerbFS's `nextFd := 3` fs-model literal, census #17). The EBADF outcome of
   CerbFS.fs_closedir is not reachable from C through this route. Pinned MATCH | L=CRASH. libc mode. */
/* Z2 probe (CerbFS.lean:335-345: fs_opendir hands out a fresh fd without
   registering it; fs_closedir = fs_close -> EBADF). libc mode. */
#include <dirent.h>
int main(void) { DIR *d = opendir("."); return d ? closedir(d) + 10 : 99; }
