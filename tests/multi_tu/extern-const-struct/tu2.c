/* extern-const-struct, TU 2: reads the other TU's const struct (with a
   pointer member into a string literal) and const array. */
struct cfg { int w; int h; const char *name; };
extern const struct cfg config;
extern const int primes[4];
int main(void) {
  return config.w * config.h * 10 + primes[3] + (config.name[0] == 'g') * 1000;   /* 1127 */
}
