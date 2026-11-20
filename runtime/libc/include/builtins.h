// Some gcc builtins we support
[[ cerb::hidden ]] int __builtin_ffs (int x);
[[ cerb::hidden ]] int __builtin_ffsl (long x);
[[ cerb::hidden ]] int __builtin_ffsll (long long x);
[[ cerb::hidden ]] int __builtin_ctz (unsigned int x);
[[ cerb::hidden ]] int __builtin_ctzl (unsigned long x);
[[ cerb::hidden ]] int __builtin_ctzll (unsigned long long x);
[[ cerb::hidden ]] __cerbty_uint16_t __builtin_bswap16 (__cerbty_uint16_t x);
[[ cerb::hidden ]] __cerbty_uint32_t __builtin_bswap32 (__cerbty_uint32_t x);
[[ cerb::hidden ]] __cerbty_uint64_t __builtin_bswap64 (__cerbty_uint64_t x);
[[ cerb::hidden ]] void __builtin_unreachable(void);

// this is an optimisation hint that we can erase
// FORK FIX (2026-11-20, contract D19; lean_frontend/docs/2026-11-20_attribute-preservation-record.md, census X1):
// the parameter is parenthesised. Upstream wrote `((long)EXP)`, so the cast bound to the first operand of the
// argument: __builtin_expect(u + 1, 0) was `(long)u + 1` (0x100000000 for u == 0xffffffffu, where gcc gives 0).
#define __builtin_expect(EXP, C) ((long)(EXP))
