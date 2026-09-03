/* Z2 probe (CerbFS.lean:311-318 fs_lseek: invalid whence falls to
   `| _ => entry.offset` = success, where POSIX/SibylFS give EINVAL). libc. */
#include <fcntl.h>
#include <unistd.h>
int main(void) { int fd = open("z2_probe_file.txt", O_WRONLY | O_CREAT, 0644); write(fd, "abc", 3); return (int)lseek(fd, 0, 7) + 10; }
