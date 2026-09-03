/* zero-discrepancy pin (2026-09-03, Z2 audit row Z2-P-01, folded into Z1 before the §4.1 instrument commit).
   Origin: tests/z2-probes/main/stderr_escape.c (branch audit/z2-seams @ 9e86fe67c). The batch
   stdout/stderr fields are rendered with OCaml String.escaped on the oracle (driver_ocaml.ml:101;
   Bytes.unsafe_escape classes: \b \t \n \r \" \\ short forms, printable ASCII verbatim, every other
   byte as decimal \ddd); Lean before emitted raw control bytes and UTF-8 re-encoded bytes >= 0x80.
   Pinned DIFF at the current Lean rendering; the Z-01/02/03/72 commit re-records MATCH. libc mode. */
#include <stdio.h>
int main(void) { fprintf(stderr, "E\b\a\xff|"); return 0; }
