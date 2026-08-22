// '\?' is a simple-escape-sequence (STD 6.4.4.4#1) with the value of '?' (STD 6.4.4.4#4)
int main(void)
{
  if ('\?' != 63)
    return 1;
  if ("\?"[0] != '?')
    return 2;
  return 0;
}
