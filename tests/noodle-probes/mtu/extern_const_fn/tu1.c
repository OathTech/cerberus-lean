/* Corner (multi-TU): extern const object and a function pointer table
   defined in another TU, string literal identity across TUs (6.2.2p2). */
extern const int table[3];
extern int (*const ops[2])(int);
const char *name(void);
int main(void) { return table[2] + ops[1](3) + (name()[0] == 'z'); }   /* 30 + 6 + 1 = 37 */
