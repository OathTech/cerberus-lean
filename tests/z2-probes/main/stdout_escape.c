/* Z2 probe (Main.lean:366-373 batchEscape vs driver_ocaml.ml:101
   `String.escaped stdout`): OCaml escapes \b as "\b", other non-printables
   and every non-ASCII byte as decimal "\ddd" (bytes.ml unsafe_escape);
   Lean escapes only " \ \n \t \r and passes the rest raw. The stdout field
   of the Defined line is verdict content. libc mode (also valid nolibc:
   printf is a Core builtin). */
#include <stdio.h>
int main(void) { printf("a\bb\a\x7f\xc3\xa9\v\f\x1b|\n"); return 0; }
