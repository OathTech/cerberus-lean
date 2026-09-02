# CN-corpus coverage lane (arc/cn-coverage, 2026-08-22)

Differential execution coverage over the CN repo's own test programs:
OCaml cerberus (fork oracle) vs the full Lean pipeline, run by
`scripts/test_cn_coverage.sh` against the committed `baseline.txt`.

## Corpus and license provenance

The corpus is EXACTLY the 213 `.c` files under
`deps/cn/tests/cn/` (container-level vendored copy of
[rems-project/cn](https://github.com/rems-project/cn), 2026-08-20).
CN is distributed under the **BSD-2-Clause license** — grant text in
`deps/cn/LICENSE` ("Redistribution and use in source and binary forms,
with or without modification, are permitted provided that ..."); the
exceptions list (`deps/cn/THIRD_PARTY_FILES.md`) covers only files in
CN's executable-checks runtime, none under `tests/`. That license
permits the derived work in this directory.

**No corpus text is copied into this repository.** Corpus files are
consumed include-by-reference: each is passed by path, as its own
translation unit, to both pipelines; where a file lacks `main`, a
separate driver TU from `drivers/` is linked with it (multi-TU linking,
the `test_multi_tu.sh` mechanism). Driver and support TUs are fresh
authorship for this lane, derived only from the C function signatures
and CN specification comments of the licensed corpus files.

Provenance flag (recorded, operator's call): one corpus file,
`simplify_array_shift.c`, carries an upstream comment saying it was
minimised from an external tutorial source. The file itself is
distributed by rems-project/cn under BSD-2 and is part of the
operator-designated corpus, so it is included; nothing outside
`deps/cn` was consulted.

## Layout

| Path | What |
|------|------|
| `manifest.txt` | one row per corpus file: `relpath\|CLASS\|extras\|note` — the coverage accounting is fail-closed against `find` over the corpus |
| `drivers/*.driver.c` | driver TUs (fresh `main`s) for corpus files without one; name = corpus relpath with `/`→`__` |
| `support/*.c` | support TUs supplying externs some corpus files call (`cn_malloc` family, `foo`, `f2`) |
| `baseline.txt` | committed per-file status baseline (exact-match, fail-closed both directions) |

Manifest classes: `DIRECT` (file runs standalone), `DRIVEN` (linked
with a driver `main` that calls the corpus functions on concrete
inputs), `ELAB` (driver `main` is trivial — the file has no callable
non-static C entry: spec-only / type-only / decl-only / static-only /
deliberately non-terminating; the differential still elaborates,
translates and links the whole corpus TU on both sides), `LINKED`
(file has its own `main` but calls externs it does not define; a
support TU closes the program).

## Driver doctrine

Per the container CLAUDE.md "harnesses are programs" doctrine: drivers
are boring, readable, concretely executable C programs; all variation
enters at program level (literal arguments in `main`, chosen to satisfy
the corpus file's own CN preconditions, cited per driver); the verdict
is encoded in `main`'s return value; no magic machine states. Every
driver header cites the corpus file, the license, and the input/verdict
choice.

Known corpus quirk coverage: no corpus file defines POSIX-named
functions (`read`/`write`/`open`/...), so the tray-14 ailname-proxy
shadowing workaround (rename in driver) is not needed here; the single
`malloc` caller goes through the std.core proxy deliberately.

## Resolved divergences

* `mask_ptr.c` double-DUMMY (found by this lane's first full sweep,
  FIXED 2026-08-22 in the same arc): Lean printed
  `UB:DUMMY(DUMMY(align_alloc))` where the oracle printed
  `UB:DUMMY(align_alloc)`. Root cause: the hand-written Lean core
  parser (`lean_frontend/CoreParser.lean`, `undef(...)` arm) wrapped
  EVERY parsed `<<...>>` UB payload in the `DUMMY` carrier, while
  OCaml `scan_ub` (parsers/core/core_lexer.mll:221-232) first resolves
  the payload through `Undefined.ub_str_bimap` and unwraps the
  `DUMMY(<str>)` spelling that std.core's proxy stubs carry (e.g.
  `undef(<<DUMMY(align_alloc)>>)` in `aligned_alloc`). Mirror-OCaml
  seam fix in CoreParser (bimap lookup + DUMMY-unwrap + loud failure
  on unknown names), with the designed downstream re-pin of the
  emit-lean-core drift gate (the then-present proof package's pinned
  Core terms re-emitted — since parked, tag park/reasoning-era-20260831; the
  pinned proof terms' `DUMMY "UB036/UB088"` literals became the real
  constructors — byte-identical to the fresh emitter output). The row
  is UB_MATCH in `baseline.txt`.
