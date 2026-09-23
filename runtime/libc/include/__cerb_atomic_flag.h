#ifndef __CERB_ATOMIC_FLAG_H
#define __CERB_ATOMIC_FLAG_H

/* Shared representation for the public header and the out-of-line functions. */
typedef struct atomic_flag {
  _Atomic(_Bool) _Value;
} atomic_flag;

#endif
