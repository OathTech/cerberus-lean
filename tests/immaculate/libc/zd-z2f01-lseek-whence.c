/* zero-discrepancy pin (2026-09-03, Z2 audit row Z2-F-01; record docs/2026-09-04_zero-discrepancy-Z2-record.md).
   Origin: tests/z2-probes/fs/lseek_whence.c. lseek with an invalid whence (7): SibylFS answers
   EINVAL (sibylfs fs_spec.lem:5084 `Error EINVAL (* posix/lseek.md EINVAL:1 *)`), so the oracle's
   libc lseek returns -1 and the program returns 9. At the audit Lean's CerbFS.fs_lseek fell to
   `| _ => entry.offset` (success, `Specified(13)`); Z1's Z-27 commit turned that arm into a loud
   REFUSAL (PANIC, exit 134) — the state pinned here (DIFF | L=CRASH). The Z2-F-01 fix mirrors
   SibylFS's EINVAL and re-records MATCH. libc mode. */
#include <fcntl.h>
#include <unistd.h>
int main(void) { int fd = open("z2_probe_file.txt", O_WRONLY | O_CREAT, 0644); write(fd, "abc", 3); return (int)lseek(fd, 0, 7) + 10; }
