/* zd-fs-path-plain-control — control for the "pathleak" hotfix (report by Kiran, kiranandcode,
 * https://gist.github.com/kiranandcode/bcd1e8190d29e238e8becf797c2bb80a
 * (X post: https://x.com/kirancodes/status/2104306363195134423)): plain file names only
 * (create, write, reopen read-only, read, unlink) stay SERVED and must MATCH the oracle. */
#include <fcntl.h>
#include <unistd.h>
int main(void) {
  char buf[8] = {0};
  int fd = open("plain.txt", O_CREAT | O_WRONLY, 0600);
  if (fd < 0) return 1;
  write(fd, "abc", 3);
  close(fd);
  fd = open("plain.txt", O_RDONLY);
  if (fd < 0) return 2;
  ssize_t n = read(fd, buf, 7);
  close(fd);
  if (unlink("plain.txt") != 0) return 3;
  return (int)n;   /* 3 */
}
