/* locking store: const-qualified global object is read-only after init */
const int c = 5;
int main(void) {
  *(int *)&c = 6;
  return c;
}
