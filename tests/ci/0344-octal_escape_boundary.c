// octal-digit is one of 0..7 (STD 6.4.4.1#1, used by 6.4.4.4#1); boundary values of octal escapes
int main(void)
{
  if ('\0' != 0)            return 1;
  if ('\7' != 7)            return 2;
  if ('\10' != 8)           return 3;
  if ('\377' != (char)0xff) return 4;
  if ("\1770"[0] != 127)    return 5;  // at most three octal digits, then '0'
  if ("\1770"[1] != '0')    return 6;
  return 0;
}
