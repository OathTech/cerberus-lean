/* tests/multi_tu_tray/node — TU 2 of 2. `main` receives a `struct node` value
   RETURNED across the TU boundary and member-selects `.v` (gcc: 7). */
struct node { int v; struct node *next; };
struct node ident(struct node n);
int main(void) { struct node n; n.v = 7; n.next = 0; return ident(n).v; }
