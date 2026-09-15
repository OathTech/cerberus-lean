# Reports for the OCaml runtime authors

This subdirectory holds draft reports against
[ocaml/ocaml](https://github.com/ocaml/ocaml) — the same format as the
Cerberus drafts one level up (classification, verbatim evidence, remedy,
provenance note), with its own numbering. The index is `../INDEX.md`,
"Other upstreams".

Why this project reports against the OCaml runtime at all: the Cerberus
C semantics is executed by an OCaml program, and its Lean 4 port
(`lean_frontend/`) is validated differentially against that OCaml
oracle under a zero-discrepancy rule (`lean_frontend/VALIDATION.md`).
When the two disagree and the cause is traced into the OCaml runtime
library rather than into Cerberus's own sources, the port keeps the
correct answer under an individually [USER]-ruled ISO-fix register
entry (VALIDATION.md §2) and the runtime defect is drafted here, with a
short Cerberus-facing note in the main tray saying the behaviour is
inherited. The first such case is `01-float-of-hex-double-rounding-subnormal.md`
(register entry R5; Cerberus-facing note `../40-*.md`).

Cited against the OCaml 5.4.0 sources as installed in this project's
opam switch (`_opam/.opam-switch/sources/ocaml-compiler.5.4.0/`);
`runtime/floats.c` line numbers are that release's.
