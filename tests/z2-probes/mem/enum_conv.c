/* Z2 probe (conv_int through Enum -> typeof_enum): enum E is compatible with
   unsigned int under the GCC rule, so (enum E)4294967295u stays positive
   (1); with an int-typed stub it would wrap to -1 (0). nolibc. */
enum E { A = 1 };
int main(void) { enum E e = (enum E)4294967295u; return (int)(e > 0); }
