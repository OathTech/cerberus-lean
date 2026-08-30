int main(void) {
  char s[10] = "abc";
  char t[] = "xy";
  return (s[0]=='a') + (s[3]==0) + (s[9]==0) + (t[2]==0) + (int)sizeof(t);  /* 1+1+1+1+3 = 7 */
}
