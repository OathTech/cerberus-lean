# mem/ — allocation and string.h probes (libc mode)

Findings: record §L1 (strncmp), §R1 (RC-3 witness), §F-note calloc.

| Probe | Corner (ISO C11) | Result | Integration |
|---|---|---|---|
| mem_free_null.c | free(NULL) no-op (7.22.3.3p2) | AGREE 3-way 3 (UB_CERB005 not raised) | libc_exec MATCH, gate-worthy |
| mem_malloc_zero.c | malloc(0) null-ness only (7.22.3p1) | AGREE 3-way 0 (non-null) | libc_exec MATCH |
| mem_realloc_semantics.c | realloc(NULL,n), grow preserves, shrink preserves prefix (7.22.3.5) | AGREE 3-way `99 11` | libc_exec MATCH, gate-worthy |
| mem_calloc_overflow.c | calloc nmemb*size overflow -> NULL (7.22.3.2) | oracle `Specified(2)` (libc calloc has no overflow check: stdlib.c:128 `malloc(nmemb*size)` wraps to 2 — but the SIZE_MAX/2+2 operand is itself U1-truncated, so the product is 4294967298); Lean OOM-KILLED (RC-3 byte materialisation of the 4 GiB request); gcc 1 — ORACLE-SUSPECT L2 (missing overflow check) + known RC-3 | reporting-only until RC-3; libc_exec would read LEAN_KILL |
| mem_malloc_4gb_lazy.c | untouched 4 GiB+2 malloc (7.22.3.4) | oracle 2 (lazy), gcc 2, Lean OOM-KILLED — the clean RC-3 witness (EXCLUDED-KNOWN) | reporting-only (mem-scale probe family) |
| mem_memset_truncation.c | memset value -> unsigned char, size 0 (7.24.6.1p2) | AGREE 3-way | libc_exec MATCH, gate-worthy |
| mem_memcpy_pointer_bytes.c | memcpy of a pointer's representation keeps value+provenance (6.2.6.1p4) | AGREE 3-way 41 | libc_exec MATCH, gate-worthy |
| mem_memcpy_struct_padding.c | memcpy struct with padding, members read back (6.2.6.1p6) | AGREE 3-way 47 | libc_exec MATCH, gate-worthy |
| mem_use_after_realloc_move.c | old pointer after realloc; same-pointer case defined (7.22.3.5p2) | oracle==Lean `Specified(1)` x2 traces; gcc 1 | libc_exec MATCH |
| mem_strlen_strcmp_edges.c | strncpy pad, strcmp unsigned, strchr NUL, strncmp n=0, memcmp sign (7.24.4) | oracle==Lean `0 0 1 -23 0 1`; gcc `0 0 1 0 0 1` — L1 in the 4th column | libc_exec MATCH; gcc-lane pinned pair |
| mem_strncmp_zero.c | minimal L1: strncmp(...,0) == 0 (7.24.4.4p2-3) | oracle==Lean 2; gcc 1 — ORACLE-SUSPECT L1 (upstream-confirmed; runtime/libc/src/string.c:87) | libc_exec MATCH; gcc-lane pinned DISAGREE pair; flips on the libc fix |
