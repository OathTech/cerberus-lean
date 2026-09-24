#include <fcntl.h>
#include <unistd.h>
#include <stdio.h>
#include <errno.h>
#include <sys/stat.h>
extern ssize_t pread(int, void *, size_t, off_t);
extern int truncate(const char *, off_t);
int global; int main(void) { int f=open("f",O_CREAT|O_RDWR,0644); write(f,"A",1); global=7; puts("prefix"); umask(077); return 99; }
