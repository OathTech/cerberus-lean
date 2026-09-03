/* Z2 probe (max_ival/min_ival/sizeof via typeof_enum): the oracle consults
   DefaultImpl.registered_enums (ocaml_implementation.ml:124-150, GCC rule);
   CerberusImpl.typeof_enum must agree at every read. gcc: sizeof(enum E)=4
   (unsigned int), sizeof(enum E2)=8 (long) -> 48. nolibc. */
enum E { A = 4294967295u };
enum E2 { B = 5000000000 };
int main(void) { return (int)(sizeof(enum E) * 10 + sizeof(enum E2)); }
