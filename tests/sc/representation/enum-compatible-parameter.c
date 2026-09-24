/* The two declarations use the implementation's actual compatible integer
   types. Both positive and negative enumerations cross a callable boundary. */
enum positive { positive_value = 5 };
unsigned int positive(enum positive);
unsigned int positive(unsigned int x) { return x; }
enum negative { negative_value = -1 };
int negative(enum negative);
int negative(int x) { return x; }
int main(void) {
  unsigned int p = positive(positive_value);
  int n = negative(negative_value);
  return p + n;
}
