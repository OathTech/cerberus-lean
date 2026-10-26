/* Core quotation linked input 2: a second enum, the extern's definition and a
   static const table with an initializer, read by the function tu1 calls. */
enum shape { CIRCLE, SQUARE = 3 };
int shared_counter = 2;
static const int table[2] = { 7, 9 };
int bump(int k) { return table[k & 1] + (k == SQUARE); }
