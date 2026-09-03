/* Corner: string literals initialising the char-array ELEMENTS of a 2-D
   char array (ISO C11 6.7.9p14, p20). gcc returns 99 ('c'). Both Cerberus
   engines: "constraint violation: initializing 'char' with an expression
   with a non arithmetic type 'char*'". */
char a[2][3] = {"ab", "cd"};
int main(void) { return a[1][0]; }
