/* cross_tu_node — the F-C4-1 reproducer (fuel-parameter C4 record §7,
   pre-merge audit §5.1): a self-referential struct defined in TWO
   translation units and a struct VALUE crossing them. Legal C (a linked-list
   node; gcc exit 7). NOT a lane corpus: an upstream-tray reproducer (drafts 37
   and 38) — the SAME program is pinned as the lane case tests/multi_tu_tray/node
   (LADDER Tier A row 6b).
   HISTORY / CURRENT STATE (2026-09-15):
   - until 2026-09-10 both Cerberus oracles never terminated on it
     (Ctype_aux.are_compatible_aux recursed through the pointer member into the
     other TU's definition, forever) and the Lean port died by native stack
     overflow — draft 37; FIXED in the fork 2026-09-10 (assumed-compatible list,
     docs/2026-09-10_are-compatible-assumed-set-record.md);
   - then both fork engines rejected it at PEmemberof(struct)'s exact-tag guard
     ("ill-formed program: mismatched tags") — draft 38; FIXED in the fork
     2026-09-15 (semantics-audit repairs D3, dbe633ec5: the guard consults
     Ctype_aux.are_compatible when the tags differ) — both fork engines now give
     Specified(7);
   - pristine upstream (b9aeedcb4) still does not terminate (rc=124 at 60 s). */
struct node { int v; struct node *next; };
struct node ident(struct node n) { return n; }
