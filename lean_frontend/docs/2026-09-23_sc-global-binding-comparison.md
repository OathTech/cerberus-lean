# Global binding comparison and Core text transport

[AGENT, September 23] development evidence for the
[global-binding producer](2026-09-23_sc-global-bindings-work.md). SC-D16 is a
comparison/transport limitation, not a new runtime refusal or an ISO ambiguity.

Four actual C recordings retain each engine's complete preceding observation.
The native producer's entire JSON equals the earlier instrumented Driver result;
removing the new receipt field from Lean's output recovers its preceding
diagnostics, output, status and stderr exactly. Both engines have identical full
decoded outcomes for library registration, a caller global, a main-body fault
and an out-of-memory fault during the third global initializer. The latter keeps
the two successful preceding bindings and no receipt for the failed initializer.

This is not exact cross-engine metadata agreement. The reporting collection
`sc-global-bindings/actual-c-3` retains all raw differences:

| Case | Binding receipts | Receipt field differences | Effect-field differences |
|---|---:|---:|---:|
| Library registration | 68 | 167 | 92 |
| Caller global | 1 | 1 | 0 |
| Main-body fault | 1 | 1 | 0 |
| Initializer fault | 2 | 2 | 0 |

These are derived counts of differing JSON leaves. The three cases without libc
differ only in the frontend-generated symbol number. The libc receipt differences
are symbol numbers/names and driver-step counts. Its effect differences are
function-pointer representation bytes, including their lossless byte keys. The
[earlier prefix comparison](2026-09-23_sc-prefix-integration-work.md) already
retains the symbol/function-pointer differences. No normalization is applied to
turn these into exact agreement. The first two attempts deliberately fail their
overly strong exact-metadata assertions and remain retained. Attempt 3 separates
passing observation-retention checks from the still-different metadata report.

## A concrete source of different administrative step counts

The shared `sc_global_literal_controls.lem` fixture supplies the same two Core
inputs directly to the actual `Driver.driver_globals` on both engines. Both
complete with exactly one receipt for the actual bound symbol and `Specified(7)`,
thread zero and effect frontier zero. Their raw transcripts are byte-identical:

```
false: Specified(7); thread=0; step=0; frontier=0; symbol=true
true: Specified(7); thread=0; step=1; frontier=0; symbol=true
```

The first initializer contains `PEval (Vloaded (LVspecified ...))`; the second
contains `PEctor Cspecified [...]`. The native printer serializes the first as
`pure(Specified(7))`. The actual Lean Core parser reconstructs that text with
`PEctor Cspecified`, as a separate executable shape check confirms. The general
constructor reduction at `core_eval.lem` evaluates it to the original loaded
value. Thus the text does not preserve this distinction in the original Core
tree, and a receipt's step count cannot be treated as a cross-loader identity.
The native C library is read from `libc.co`, while Lean's loader stitches parsed
printed bodies onto separately elaborated metadata (`Main.loadLibc`).

`literal-generation-1` failed on missing whitespace in a type annotation;
generation 2 passes both targets. `literal-controls-1` inferred BaseIO for a
probe that needed IO and did not pass; controls 2 explicitly types the IO probe
and passes the paired Driver and actual-text checks. This minimal example
establishes one mechanism; it does not attribute every step-count difference in
the full library or prove a general correspondence allowing extra pure steps.

## Required handling

Keep the raw Core values, symbols, physical bytes and step counts. Use the actual
per-engine bindings when resolving that engine's runtime objects. Step-level
cross-engine claims require matching Core inputs or a stated and proved
correspondence for the transport; matching C outcomes alone supplies neither.
Further transport/correspondence work must preserve the distinction above or
justify it over its exact domain, including failure prefixes and exploration
bounds. Do not derive HB from these counters, discard pointer bytes, reject a
program because its frontend counters differ, or label this as an upstream ISO
semantic gap. The production recorder adds no such restriction.
