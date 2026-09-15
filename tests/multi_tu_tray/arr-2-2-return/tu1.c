/* tests/multi_tu_tray/arr-2-2-return — TU 1 of 2. POSITIVE twin of arr-1-2-return:
   equal bounds (`int a[2]` in both TUs), value RETURNED and member-selected.
   Compatible (§6.2.7#1); rejected by pristine upstream at its exact-tag guard (draft 38). */
struct S { int a[2]; };
struct S mk(void) { struct S s; s.a[0] = 7; s.a[1] = 8; return s; }
