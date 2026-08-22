// %c must store the argument's value unchanged, including non-printable chars
#include <stddef.h>
#include <stdarg.h>

// calling the builtin directly: this suite runs with --nolibc
int __builtin_vsnprintf(char * restrict, size_t, const char * restrict, va_list);

static int my_snprintf(char * restrict s, size_t n, const char * restrict fmt, ...)
{
  va_list ap;
  va_start(ap, fmt);
  int ret = __builtin_vsnprintf(s, n, fmt, ap);
  va_end(ap);
  return ret;
}

static int store_one(int c)
{
  char buf[2];
  my_snprintf(buf, sizeof buf, "%c", c);
  return (unsigned char)buf[0];
}

int main(void)
{
  if (store_one(127) != 127) return 1;  // \177: octal and decimal notations differ
  if (store_one(129) != 129) return 2;  // \201: decimal notation contains a non-octal digit
  if (store_one(11)  != 11)  return 3;  // \013: control char without a symbolic escape
  if (store_one(255) != 255) return 4;  // \377: highest char value
  if (store_one(10)  != 10)  return 5;  // '\n': chars with symbolic escapes
  if (store_one('a') != 'a') return 6;  // printable chars
  return 0;
}
