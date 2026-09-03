/* Corner: struct sizeof/offsetof/_Alignof with padding at every alignment
   boundary, nested structs, trailing padding (ISO C11 6.7.2.1p15-17,
   7.19; layout impl-defined, x86-64 SysV expected). */
#include <stdio.h>
#include <stddef.h>
struct A { char c; int i; char d; };            /* 12 */
struct B { char c; double d; char e; };         /* 24 */
struct C { char c; short s; char d; int i; };   /* 12 */
struct D { char a[3]; short s; };               /* 6 */
struct E { long long ll; char c; };             /* 16 */
struct F { char c; struct { char d; int i; } s; }; /* 12, s at 4 */
struct G { char c; char d[5]; short s; };       /* 8 */
struct H { struct A a; char x; };               /* 16 */
int main(void) {
  printf("%d %d %d %d %d %d %d %d\n", (int)sizeof(struct A), (int)sizeof(struct B), (int)sizeof(struct C), (int)sizeof(struct D), (int)sizeof(struct E), (int)sizeof(struct F), (int)sizeof(struct G), (int)sizeof(struct H));
  printf("%d %d %d %d %d %d\n", (int)offsetof(struct A, d), (int)offsetof(struct B, e), (int)offsetof(struct C, i), (int)offsetof(struct F, s), (int)offsetof(struct G, s), (int)offsetof(struct H, x));
  printf("%d %d %d %d\n", (int)_Alignof(struct A), (int)_Alignof(struct B), (int)_Alignof(struct D), (int)_Alignof(char[16]));
  return 0;
}
