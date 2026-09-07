/* cross_tu_node — the F-C4-1 reproducer (fuel-parameter C4 record §7,
   pre-merge audit §5.1): a self-referential struct defined in TWO
   translation units and a struct VALUE crossing them. Legal C (a linked-list
   node). Both Cerberus oracles never terminate on it (Ctype_aux.are_compatible_aux
   recurses through the pointer member into the other TU's definition of the
   same struct, forever); the Lean port dies by native stack overflow. NOT a lane
   corpus (tests/multi_tu is the lane): an upstream-tray reproducer (draft 37). */
struct node { int v; struct node *next; };
struct node ident(struct node n) { return n; }
