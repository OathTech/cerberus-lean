# cn_spec_export — golden fixtures for `cerberus --cn-spec-json`

Lane: `scripts/test_cn_spec_export.sh` (Tier C reporting; CN-0,
2026-08-24). Design + schema: `lean_frontend/docs/2026-08-24_cn0-spec-export.md`.

## License / provenance

The corpus inputs are `deps/cn/tests/cn` (rems-project/cn,
BSD-2-Clause) consumed BY REFERENCE, exactly like `tests/cn_coverage`
(see its README for the license statement): no corpus source text is
copied into this repo. The committed `golden/*.json` files are the
OUTPUT of our exporter over those inputs — they embed short quoted
fragments (identifiers, source locations) only.

`malformed.c` and `split.c` are original fixtures written for this
repo (the fail-closed plants: a syntactically broken CN annotation and
a split function spec, both of which must fail LOUDLY with an empty
stdout).

## Goldens

Regenerating (`--write-golden`) is a deliberate, reviewed act — every
golden diff is a claim about the exporter's output surface. The
exporter runs with the corpus directory as cwd and a bare filename, so
embedded locations are corpus-relative and the goldens are
machine-independent.
