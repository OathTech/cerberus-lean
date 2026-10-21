# Literal library-directory test misclassifies aliased spellings of the runtime, including cpp's own `./` header positions

**State:** Draft; no submission or duplicate search recorded.
**Classification:** TRUE BUG. The classifier compares directory strings
literally against the runtime argument as given, so any spelling that
denotes a runtime library directory but differs from that key is classified
as not library: cpp's `./`-prefixed header path under a relative `--runtime`,
an absolute path under a relative `--runtime`, a relative path under an
absolute one. Classification can therefore depend on spelling rather than
which library supplied the code, and the reported UB location moves with it.

Checked on `feature/core-quote` at `167f1360d` plus the D5 witness,
2026-10-20. The oracle implementation is `util/cerb_location.ml:512-523`:
`is_library_location` builds three keys with `Cerb_runtime.in_runtime` and
looks up `Filename.dirname path` by literal string equality. Runtime prefix
selection is `util/cerb_runtime.ml:38-56`; `in_runtime` is at lines 66-76.

## Reproducer and observed classification

From the project root, with the normal built oracle/runtime and Lean test
prerequisites, run `scripts/check_runtime_resolution.sh`. Its fixture-001
witness reads the committed `tests/fixtures/001-return-literal/cabs.json`:
154 positions name
`./_build/install/default/lib/cerberus-lib/runtime/libc/include/builtins.h`.
The fixture's source is `tests/fixtures/001-return-literal/source.c`.
A fresh export uses:

```sh
_build/default/backend/driver/main.exe --runtime=_build/install/default \
  --nolibc --cabs-json tests/fixtures/001-return-literal/source.c
```

At `--runtime=_build/install/default`, the oracle's directory key starts with
`_build/`, whereas cpp's header position starts with `./_build/`.
The witness links the built `cerb_util` library and calls its actual
`Cerb_location.is_library_location`: **false**. Removing only `./` gives
**true**, a positive control on the same classifier and runtime. The Lean
port's actual suffix test gives **true** for the original stored path, and
its resolved-directory guard accepts the fixture. Both engines execute this
particular program as `Specified(42)`; this program exposes classification,
not a UB-location difference.

## Consequence and proposed remedy

Library classification participates in UB-location selection
(`frontend/model/core_eval.lem:602`, `core_run.lem:477,782`; in the port,
`generated/Core_eval.lean:672` and `generated/Core_reduction.lean:1804,1822`).
A library location whose spelling differs literally from the key selects a
different reported UB location even though it denotes the same library file.
Observed with an eight-line `#line` plant (`scripts/check_runtime_resolution.sh`,
both engines at `--runtime=_build/install/default` from the repository root):
a signed-overflow UB inside a function placed by
`#line 1 "./_build/install/default/lib/cerberus-lib/runtime/libc/include/plant.h"`
is reported by the oracle at the function body, `loc: "<2:10--2:15>"`, and by
the Lean port at the call site, `loc: "<11:10--11:23>"`; with the unprefixed
`_build/...` spelling both report `<11:10--11:23>`. An absolute spelling of
the same directory under the relative runtime, and the `libcore` directory,
behave like the `./` case. The differential lanes' absolute spellings agree,
so they do not detect this class. Core quotation preserves all stored labels;
the literal is unaffected.

Compare resolved directory identities for exact membership in the three
runtime library directories, with an explicit failure for paths that cannot
be resolved. Resolve at the invocation/import boundary; do not rewrite source
or lexing labels. This also handles relative aliases and symlinks without
classifying foreign directories merely because their suffix matches. Tests
should include cpp's `./` spelling beside the unprefixed control, an absolute
runtime, and an existing foreign directory with the same suffix. The fork's
Lean import guard uses this rule; the OCaml classifier remains literal.

Origin: pre-merge Core quotation audit P2-1; D5 records the measured divergence
under the operator's retained relative-runtime convention.
