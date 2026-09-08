#include <time.h>
static volatile unsigned long sink;
static double cpu(void) { struct timespec t; clock_gettime(CLOCK_PROCESS_CPUTIME_ID,&t); return t.tv_sec+t.tv_nsec*1e-9; }
__attribute__((noinline)) static void fixture_measure(void) { double stop=cpu()+0.7; while(cpu()<stop) for(int i=0;i<10000;i++) sink+=i; }
__attribute__((noinline)) static void fixture_rest(void) { double stop=cpu()+0.7; while(cpu()<stop) for(int i=0;i<10000;i++) sink+=i; }
int main(void) { fixture_measure(); fixture_rest(); return 0; }
