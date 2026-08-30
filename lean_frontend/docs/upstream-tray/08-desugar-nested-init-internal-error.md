# Draft 08 — Desugaring of nested braced initializers fails; surfaces as an uncaught internal error

Status: DRAFT, not filed (filing is the operator's call). Classification:
**TRUE BUG** (ISO-legal initializers; the tool dies with an uncaught
internal-error exception, not a diagnostic).
Verified against: upstream `master` @ `b9aeedcb4`
(`deps/cerberus-upstream`, built 2026-08-21 per
`notes/2026-08-21_upstream-oracle-build.md`); un-forked repro re-run
2026-08-21 (arc-12 S3).

## Reproducer 1 — 3-D scalar array (any csmith `--max-array-dim 3` output)

```c
int g[2][2][2] = {{{1,2},{3,4}},{{5,6},{7,8}}};
int main(void) { return g[1][1][1]; }
```

gcc 15 `-std=c11`: compiles clean, returns 8. Upstream cerberus
(`--nolibc --exec --batch`), verbatim, exit code 125:

```
internal error: Translation called on Ail program with an invalid node
cerberus: internal error, uncaught exception:
          Failure("internal error: Translation called on Ail program with an invalid node")
          Raised at Stdlib.failwith in file "stdlib.ml", line 29, characters 17-33
          Called from Cerb_frontend__Translation.translate_expression.(fun) in file "ocaml_frontend/generated/translation.ml", line 3257, characters 10-83
```

2-D control (`int g[2][2] = {{1,2},{3,4}};`) works: `Specified(4)`.

## Reproducer 2 — struct-in-struct-in-struct (same failure)

```c
struct S0 { int p; };
struct S1 { long a; struct S0 inner; };
struct S2 { struct S1 s; int x; };
static struct S2 g = {{2L, {7}}, 1};
int main(void) { return g.x + g.s.inner.p; }
```

gcc: clean, returns 8. Upstream: identical internal error. Depth-2
nesting works. NOTE the class is not literally "depth ≥ 3": we hold a
depth-4 nested-struct csmith case that IS exec-accepted — the failing
class appears to be a specific `desugar_initializer_` shape (unexplored
boundary; both witnesses above are deterministic members).

## Reproducer 3 — 2-D array of struct, depth 3, 3 lines (added 2026-08-30)

The parity-detective campaign minimized a further variant showing the
class is hit already at TWO array dimensions when the element is a
struct (the scalar 2-D control above works):

```c
struct S { unsigned f0; signed char f1; };
static struct S g[1][1] = {{{1,2}}};
int main(void) { return g[0][0].f0; }
```

gcc 13.3.0 `-std=c11`: compiles clean, returns 1. Upstream cerberus
(`--nolibc --exec --batch`, un-forked `deps/cerberus-upstream` binary +
runtime @ `b9aeedcb4`, re-run verbatim 2026-08-30), exit code 125:

```
internal error: Translation called on Ail program with an invalid node
cerberus: internal error, uncaught exception:
          Failure("internal error: Translation called on Ail program with an invalid node")
          Raised at Stdlib.failwith in file "stdlib.ml", line 29, characters 17-33
          Called from Cerb_frontend__Translation.translate_expression.(fun) in file "ocaml_frontend/generated/translation.ml", line 3257, characters 10-83
```

Kept in-tree as `tests/parity-probes/probes/oracle_2d_struct_init.c`.
Blast-radius measurement on fresh csmith seeds (320 programs,
disjoint from any prior corpus): 58% (186/320, derived) die on
exactly this message — the dominant single cause of oracle skips
(`lean_frontend/docs/2026-08-30_parity-detective-report.md` §5).
Fixing this defect would raise fresh-seed differential coverage from
~17% to a majority. (Our Lean port, sharing the .lem lineage, dies on
this input with the byte-identical message — recorded there for
completeness; the defect is upstream's desugaring.)

## Mechanism (as far as we traced it)

The desugaring of the nested initializer produces an `AilEinvalid` node
(the desugar-failure placeholder, `AilInvalid_desugaring_init_failed`)
instead of either a correct desugaring or a user-facing diagnostic;
`Translation.translate_expression` then (correctly) refuses the invalid
node — but as an uncaught `Failure`, so the user sees an internal error
+ OCaml backtrace, exit 125. Related same-neighborhood symptom we also
observe on upstream: some nested static aggregate initializers are
flagged `UB081_scalar_initializer_not_single_expression` where gcc/
clang accept (probable Desugaring_init false positive; can supply
seeds).

## Impact

At csmith defaults (`--max-array-dim 3`) this killed ~52% of all
generated programs in our campaign (105/105 of one 200-seed block's
skip_internal correlated with this error). Any real code with 3-D
arrays or deeper braced aggregates is affected.

## Proposed remedy

1. Minimum: `Translation` treating `AilEinvalid` as a proper
   diagnostic (the desugar failure reason is already carried in
   `AilInvalid_desugaring_init_failed`) instead of `failwith` — turns
   an internal error into a report with a location.
2. Actual fix: extend `desugar_initializer_` to cover the failing
   nested-brace shapes (we can contribute all three reproducers as
   tests; minimized, deterministic).
