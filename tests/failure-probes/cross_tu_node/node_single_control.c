/* control: the SAME struct and call in ONE translation unit — the same-TU
   fast path (ctype_aux.lem:115-116 `tag1 = tag2`) terminates. */
struct node { int v; struct node *next; };
struct node ident(struct node n) { return n; }
int main(void) { struct node n; n.v = 7; n.next = 0; return ident(n).v; }
