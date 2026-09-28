/* zd-fs-pathleak-dot-slash — external report "pathleak" by Kiran (kiranandcode), 2026-09-27,
 * https://gist.github.com/kiranandcode/bcd1e8190d29e238e8becf797c2bb80a
 * (X post: https://x.com/kirancodes/status/2104306363195134423) (0-pathleak2.c, verbatim below).
 * CerbFS used the raw path string as the file key, so ./secret.txt and secret.txt were different
 * files: the access check was bypassed with no read (Lean Specified(0)); SibylFS/POSIX resolve both
 * to one file (oracle: assert() failure; gcc: prints hunter2, assert aborts). Since 2026-09-28 a
 * non-plain path is a loud CerbFS refusal (docs/2026-09-28_cerbfs-path-hotfix-record.md). */
#include <assert.h>
#include <fcntl.h>
#include <unistd.h>

/* The access check: is this the secret's path? */
static int is_secret(const char *p) {
  const char *s = "secret.txt";
  while (*p && *p == *s) { p++; s++; }
  return *p == *s;
}

/* Serve any file except the secret; missing files are created empty. */
static void serve(const char *req) {
  if (is_secret(req)) return;
  char buf[64] = {0};
  int fd = open(req, O_RDONLY | O_CREAT, 0600);
  if (fd < 0) return;
  ssize_t n = read(fd, buf, 63);
  close(fd);
  if (n > 0) write(1, buf, n);
  assert(n == 0);
}

int main(void) {
  int fd = open("secret.txt", O_CREAT | O_WRONLY, 0600);
  if (fd < 0) return 1;
  write(fd, "hunter2", 7);
  close(fd);
  serve("secret.txt");
  serve("./secret.txt");
  return 0;
}
