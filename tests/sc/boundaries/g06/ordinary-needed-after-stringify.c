#define LF __cerbvar_ATOMIC_INT_LOCK_FREE
#define S_(x) #x
#define S(x) S_(x)
char *text=S(LF);
#if LF
int result=11;
#else
int result=22;
#endif
