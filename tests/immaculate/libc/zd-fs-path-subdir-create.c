/* zd-fs-path-subdir-create — variant of the "pathleak" report (Kiran, kiranandcode,
 * https://gist.github.com/kiranandcode/bcd1e8190d29e238e8becf797c2bb80a
 * (X post: https://x.com/kirancodes/status/2104306363195134423)): open("sub/f", O_CREAT)
 * with no directory "sub". SibylFS answers ENOENT (fd < 0 -> return 2); before 2026-09-28 CerbFS
 * created a file literally named "sub/f" (return 0). Now a loud CerbFS refusal. */
#include <fcntl.h>
#include <unistd.h>
int main(void) {
  int fd = open("sub/f", O_CREAT | O_WRONLY, 0600);
  if (fd < 0) return 2;
  close(fd);
  return 0;
}
