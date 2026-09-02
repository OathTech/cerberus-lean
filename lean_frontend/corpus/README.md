# The differential-fixture corpus

Fifteen small C programs (+ 1 marked alternate, p10alt) exercising a
spread of C constructs — scalar arithmetic, saturating/guarded
arithmetic, aliasing, arrays, linked lists, recursion, iteration,
structs, scan/classify loops. They serve as differential test
fixtures for the Lean semantics: `scripts/test_verify.sh` re-derives
each fixture's pinned Core dump from the OCaml oracle
(byte-identical / content-hash provenance, `tests/corpus/`), runs the
batch-A programs' `main` through both pipelines (oracle vs Lean,
verdicts compared), and checks the Lean driver's `--call` mode at the
concrete points of `tests/corpus/expectations.txt`.

Fixture-set integrity: the file set is pinned by the hash manifest
`scripts/fixture_corpus.sha256`, checked by
`scripts/check_fixture_freeze.sh` (rides `test_unit.sh`). Changing a
fixture invalidates its pinned Core dumps and expectation rows —
update the manifest, the `tests/corpus/` pins, and the expectations
together, in one commit, with the change's rationale.

Provenance: the set was assembled 2026-08-27 ([USER] sign-off) and is
re-roled here as a differential fixture set ([USER 2026-08-31],
semantics-first split).
