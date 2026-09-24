#pragma GCC diagnostic ignored "-Wundef"
#define LF __cerbvar_ATOMIC_INT_LOCK_FREE
#if LF
int x=1;
#else
int x=2;
#endif
