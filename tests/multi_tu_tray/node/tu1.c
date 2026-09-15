/* tests/multi_tu_tray/node — TU 1 of 2 (draft 38's positive reproducer, cf.
   tests/failure-probes/cross_tu_node). Defines `ident`; the struct is defined
   identically in both TUs. Classification and the three-engine table: ../README.md. */
struct node { int v; struct node *next; };
struct node ident(struct node n) { return n; }
