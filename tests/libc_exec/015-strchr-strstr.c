// 015: search functions: strchr for '\0' finds the terminator, strrchr,
// strstr with needles of length 0, 1, 2, 3 and 4 (musl's separate one-, two-,
// three- and four-byte paths), strpbrk, strspn, strcspn. (Needles of length
// >= 5 take musl's two-way path: see 016.)
#include <stdio.h>
#include <string.h>
int main(void) {
  const char *h = "abcabcabcdabcde-xyzzy";
  const char *n0 = strstr(h, "");
  const char *n4miss = strstr(h, "abce");
  return printf("%d %d %d %d %d %d %d %d %d %d %d %d\n",
    (int)(strchr(h, 'c') - h), (int)(strchr(h, 0) - h), (int)(strrchr(h, 'a') - h),
    (int)(n0 - h), (int)(strstr(h, "d") - h), (int)(strstr(h, "da") - h),
    (int)(strstr(h, "zzy") - h), (int)(strstr(h, "-xyz") - h), n4miss == NULL,
    (int)strspn(h, "abc"), (int)strcspn(h, "-y"), (int)(strpbrk(h, "yx") - h));
}
