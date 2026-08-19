/* Csmith runtime header for cerberus-lean differential testing (arc-4 S4b).
 *
 * Ported from cerberus-lean-prototype/tests/csmith/csmith_cerberus.h
 * (itself a modified csmith_minimal.h: no printf on the hot path, checksum
 * surfaced as the program result). ONE deliberate adaptation for this
 * pipeline:
 *
 *   The prototype's platform_main_end() called exit((int)(x & 0xFF)).
 *   Neither the Lean pipeline (links no C library) nor OCaml cerberus
 *   under --nolibc (how scripts/test_exec.sh runs it) can resolve exit()
 *   — every run would die "calling an unknown procedure" (the known
 *   libc-linking FAIL class, cf. tests/minimal 073/074). Instead,
 *   platform_main_end is now a MACRO that expands to a `return` of the
 *   checksum's low byte from main (csmith only ever calls
 *   platform_main_end from main, as its last statement before
 *   `return 0;`). Same checksum signal, no libc dependency, and both
 *   sides of the differential see identical source.
 *
 * Usage: generated tests get their `#include "csmith.h"` replaced by
 *   #define CSMITH_MINIMAL
 *   #include "csmith_cerberus.h"
 * (scripts/fuzz_csmith.sh does this), with this header + safe_math.h
 * copied next to the generated .c files.
 */

#ifndef CSMITH_CERBERUS_H
#define CSMITH_CERBERUS_H

/* Integer types from custom_stdint_x86.h */
typedef signed char int8_t;
typedef unsigned char uint8_t;
typedef short int16_t;
typedef unsigned short uint16_t;
typedef int int32_t;
typedef unsigned int uint32_t;
typedef long long int64_t;
typedef unsigned long long uint64_t;

/* Limits from custom_limits.h */
#define INT8_MAX 127
#define INT8_MIN (-128)
#define UINT8_MAX 255
#define INT16_MAX 32767
#define INT16_MIN (-32768)
#define UINT16_MAX 65535
#define INT32_MAX 2147483647
#define INT32_MIN (-2147483647-1)
#define UINT32_MAX 4294967295U
#define INT64_MAX 9223372036854775807LL
#define INT64_MIN (-9223372036854775807LL-1)
#define UINT64_MAX 18446744073709551615ULL

#define STATIC static
#define UNDEFINED(__val) (__val)
#define LOG_INDEX
#define LOG_EXEC
#define FUNC_NAME(x) (safe_##x)
#define assert(x)
#define _CSMITH_BITFIELD(x) ((x>32)?(x%32):x)

/* Include safe math operations */
#include "safe_math.h"

/* Global checksum context */
static uint64_t crc32_context = 0;

/* No-op platform init - NOT inline so Cerberus exports the body */
static void platform_main_begin(void) {}
static void crc32_gentab(void) {}

/* transparent_crc: just accumulate into checksum, no printing
 * NOT inline so Cerberus exports the body */
static void
transparent_crc(uint64_t val, char* vname, int flag)
{
    (void)vname;  /* unused */
    (void)flag;   /* unused */
    crc32_context += val;
}

/* transparent_crc_bytes: accumulate bytes into checksum
 * NOT inline so Cerberus exports the body */
static void
transparent_crc_bytes(char *ptr, int nbytes, char* vname, int flag)
{
    int i;
    (void)vname;
    (void)flag;
    for (i = 0; i < nbytes; i++) {
        crc32_context += ptr[i];
    }
}

/* printf declaration - needed for array index printing in csmith tests.
 * These calls are guarded by print_hash_value which is 0, so they never
 * actually execute. We just need the declaration for compilation. */
int printf(const char *format, ...);

/* platform_main_end: RETURN the checksum's low byte from main (see the
 * header comment — the prototype exit()ed here, which needs libc).
 * csmith emits `platform_main_end(crc32_context ^ ..., print_hash_value);`
 * as the last statement of main before `return 0;`; this macro turns it
 * into main's actual return. The flag argument is deliberately dropped. */
#define platform_main_end(x, flag) return (int)((x) & 0xFF)

#endif /* CSMITH_CERBERUS_H */
