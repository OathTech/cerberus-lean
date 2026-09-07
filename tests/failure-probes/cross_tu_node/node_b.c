struct node { int v; struct node *next; };
struct node ident(struct node n);
int main(void) {
  struct node n; n.v = 7; n.next = 0;
  return ident(n).v;
}
