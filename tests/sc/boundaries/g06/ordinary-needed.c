#define LF __cerbvar_ATOMIC_INT_LOCK_FREE
#if LF == 0
int result=11;
#else
int result=22;
#endif
