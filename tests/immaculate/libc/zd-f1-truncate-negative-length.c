/* zero-discrepancy Z1 audit F1 pin (2026-09-03; docs/2026-09-03_zero-discrepancy-Z1-audit.md F1;
   record docs/2026-09-03_zero-discrepancy-Z1-record.md §11). truncate() with a NEGATIVE length:
   SibylFS fs_spec.lem:4020 `fsm_cond_raise EINVAL (len < 0)` (posix/truncate.md EINVAL:1) -> -1/EINVAL,
   file untouched; CerbFS.fs_truncate served `contents.take len.toNat` (= 0, file EMPTIED) and returned 0.
   Pinned DIFF at the pre-fix Lean value Specified(2); the audit-response commit re-records MATCH
   Specified(1). libc mode; unistd.h comments the prototype out, a user declaration suffices
   (core_run.lem dispatches the "truncate" builtin to FS_TRUNCATE). */
#include <fcntl.h>
#include <unistd.h>
int truncate(const char *path, long length);
int main(void) {
  int fd = open("t.txt", O_RDWR | O_CREAT);
  write(fd, "hello", 5);
  close(fd);
  int r = truncate("t.txt", -1);
  return r == -1 ? 1 : 2;
}
