# Reports for the Lem authors

This subdirectory holds draft reports against
[rems-project/lem](https://github.com/rems-project/lem) — the same
format as the Cerberus drafts one level up (classification, verbatim
evidence, remedy, provenance note), with its own numbering. The index
is `../INDEX.md`, "Other upstreams".

The Lean 4 backend for Lem itself is a feature contribution, not a bug
report, and lives in its own repository:
[github.com/OathTech/lem-lean](https://github.com/OathTech/lem-lean),
branch `mdd/lean-backend`, landing page `doc/lean-backend/README.md`
(design in `doc/lean-backend/DESIGN.md`; the upstream-facing manual
chapter is `doc/manual/backend_lean.md`).

One note that is deliberately *not* a report: Lem's `nat` and `int`
are 63-bit machine integers on the OCaml target, by documented upstream
choice (`library/num.lem`, the comment on `nat`), while the
theorem-prover targets map them to unbounded numbers; the Lean backend
follows the prover-side reading (`Nat`/`Int`).
