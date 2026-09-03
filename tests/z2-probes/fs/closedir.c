/* Z2 probe (CerbFS.lean:335-345: fs_opendir hands out a fresh fd without
   registering it; fs_closedir = fs_close -> EBADF). libc mode. */
#include <dirent.h>
int main(void) { DIR *d = opendir("."); return d ? closedir(d) + 10 : 99; }
