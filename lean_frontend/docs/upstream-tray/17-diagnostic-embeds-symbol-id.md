# Diagnostic output embeds raw fresh-symbol ids (numbering-dependent observable)

**Classification: TRUE BUG (minor, diagnostic-quality / reproducibility)**
— under the standing project principle ([USER 2026-08-31], the
effect-retirement Q1b ruling's companion: "the oracle *should not*
depend on naming, that seems like a defect in itself"), any engine
output that depends on symbol NUMBERING beyond binding identity is a
defect class. This is the one such site found by the arc's full-battery
sweep (registered as finding C1-F2,
`docs/2026-09-01_C1-adoption-record.md` §11).

## The observable

`core_run.lem:69`:

```
(Illformed_program ("calling an unknown procedure: " ^ show psym))
```

`show psym` renders the raw fresh counter value, so the user-facing
error message for a call to an unlinked procedure embeds an id that
depends on the exact allocation history of the fresh-symbol supply —
e.g. (verbatim, our libxml2-uri lane baseline, both pipelines):

```
OCAML_NOLIBC: Error {msg: "ill-formed program: `calling an unknown procedure: Symbol(1451, SD_Id("memset"))'"}
LEAN_NOLIBC:  Error {msg: "Illformed_program: calling an unknown procedure: Symbol(968, SD_Id("memset"))"}
```

The message is semantically "memset is not linked"; the number carries
no user meaning, varies across frontends/allocation orders (upstream's
own value differs from any fork's or any future pipeline change's), and
makes error output non-reproducible under semantically-neutral
renumbering. Our differential harness had to pin this row modulo the
embedded id (the only such row in the whole battery).

## Proposed remedy

Render diagnostics with the symbol's DESCRIPTION only (`SD_Id`
name/location) and omit — or demote to a debug-level detail — the raw
counter value in user-facing messages: e.g.
`calling an unknown procedure: memset`. `show psym` remains available
for debug output.

## Provenance

Found 2026-08-31/09-01 during the effect-retirement rebaseline
(finding C1-F2): the fork's Lean-side supply unification renumbered
symbols and moved exactly this one output row; every other gated
observable was numbering-invariant. Cited file verified against
upstream master @ b9aeedcb4 (merge base; core_run.lem byte-identical
there).
