/* locking store: string-literal allocation transitions to read-only */
int main(void) {
  char *s = "ab";
  s[0] = 'x';
  return 0;
}
