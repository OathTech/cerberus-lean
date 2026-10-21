# Core pretty-printing merges parameter values and object addresses

Draft, 2026-10-21; no submission or external duplicate search performed.
Checked on the fork based on upstream `b9aeedcb4`, with backports
`f10329b44` and `3230aa494`. AI provenance: Codex, inner_arg_temps slice.

`ocaml_frontend/pprinters/pp_symbol.ml:12-24` prints `SD_Id name`,
`SD_ObjectAddress name` and `SD_FunArgValue name` identically at ordinary
debug levels, omitting their numeric identity. Under `inner_arg_temps`,
`translation.lem:4366-4373` creates fresh loaded-value parameter symbols
whose descriptions retain the original parameter object's name. Both
symbols occur in the function prelude, so the printer loses a distinction
that is necessary for execution.

Reproduce after building/staging the runtime:

```sh
mkdir -p .tmp
CERB_MEM_MAX=4G ./scripts/capped _build/default/backend/driver/main.exe \
  --runtime=_build/install/default --nolibc --pp=core \
  --pp_core_out=.tmp/libc-inner.core \
  _build/install/default/lib/cerberus/runtime/libc/libc_inner_arg_temps.co
```

The output's `exit` definition contains:

```text
proc exit (code: loaded integer): eff unit :=
  let strong code: pointer = create(Ivalignof('signed int'), 'signed int') in
  store('signed int', code, code) ;
```

The loaded argument and object address are distinct in the original Core.
In the printed body, both store operands spell `code`; a reader cannot
recover which original symbol the printer meant. Printing the same dump
with the switch flag does not restore the missing identity.

The Lean fork's name-interning text importer consequently conflates those
symbols. `tests/libc_exec/001-exit.c` crashes there instead of returning 42;
`005-strlen.c` returns 16 instead of the oracle's 15. The matched-mode
execution sweep found 36 libc discrepancies. The oracle uses its binary
library and is not shown to have an execution defect. Full results and
commands are in the [park record](../2026-10-21_inner-arg-temps-libc-park.md).
The fork now refuses this library import, including quotations, until a
lossless transport has been validated.

Classification: a correctness bug if this pretty-printer is intended as
a machine-consumable serialization; otherwise a representation/documentation
gap that consumers must not bridge by name interning. This report does not
claim the ordinary upstream driver produces these wrong answers.

Proposed remedy: provide an explicitly lossless machine format that retains
symbol identity, or an unambiguous printer mode with unique symbols and a
corresponding reader. Numeric suffixes available at debug level above 4
are not yet a validated replacement: syntax, linkage, metadata identity
and round trips must all be checked. The fork has not implemented a repair.

Related local reports: [03](03-pp-core-ambiguous-output.md) covers expression
association, [07](07-symbol-identity-fragility.md) covers fresh-counter
invariants, and [48](48-funptrmap-keyed-by-number-conflates-libc-statics.md)
covers function-map keys. This finding is the loss of two already-distinct
symbols when printing callee-allocated parameter temporaries.
