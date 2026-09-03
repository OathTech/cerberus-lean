# cerberus-lean: the Cerberus C semantics in Lean 4

This directory contains a Lean 4 port of the [Cerberus](https://www.cl.cam.ac.uk/~pes20/cerberus/)
C semantics. It is generated from the **same Lem model** as Cerberus's
OCaml implementation, so the two share one semantics by construction;
the Lean side is then **differentially validated** against the OCaml
implementation (the "oracle") on every test corpus we can get our
hands on. The result is an executable, rigorously defined C semantics
that lives natively in Lean: parse real C (via the upstream front
end), elaborate it to Cerberus's Core language, and execute it —
undefined-behaviour verdicts included — inside a Lean artifact whose
execution path is total, pure (state is threaded, never ambient —
the effect-retirement arc deleted the last effect-projection axiom),
and axiom-free: zero `axiom` declarations exist in this repository or
its LemLib runtime, so every constant's axiom cone bottoms out in
Lean's three standard axioms (gate-enforced; VALIDATION.md).

**Provenance.** This port was developed primarily by AI agents
(Claude, Anthropic) operating under the direction and review of a
human operator (Mike Dodds). The upstream Cerberus semantics is by
its own authors (see the top-level README); the dated records in
`docs/` are the working history of the port.

Who this is for:

- You want to **run C** through an executable, rigorously defined
  semantics from inside Lean (undefined-behaviour verdicts included).
- You want to know **why you should trust it** — see
  [VALIDATION.md](VALIDATION.md) for the differential-validation
  story and the gate list.
- You want to understand **how the port works** — see
  [DESIGN.md](DESIGN.md).

## Five-minute orientation

```
lean_frontend/
├── generated/        # Lean code generated from the Lem model (do not edit)
├── *.lean            # hand-written "seam" files (memory model, ND runner,
│                     #   parsers, implementation-defined behaviour, ...)
├── speclab/          # harness-family differential lanes: models, codecs,
│                     #   and a C harness renderer (see speclab/README.md)
├── corpus/           # pinned differential-fixture programs (hash-frozen)
├── test/             # unit tests + gate executables
└── docs/             # dated design records and results (the port's history)
```

The C parser stays in OCaml: `cerberus --cabs-json` parses C and emits
a JSON AST; the Lean pipeline does everything after that (desugaring,
typing, elaboration to Core, execution).

## Build and run one differential test

From the repository root (`../scripts/env.sh`, one level above this
repository in the working layout, sets up the opam switch if your
shell lacks it):

```bash
# OCaml side (the oracle + the C parser front-end)
opam exec --switch=. -- make prelude-src
opam exec --switch=. -- dune build backend/driver/main.exe cerberus-lib.install
opam exec --switch=. -- dune install cerberus-lib
opam exec --switch=. -- dune build cerberus.install

# Lean side (always memory-capped — never run lake/lean uncapped)
make lean-prelude-src
cd lean_frontend && ../scripts/capped lake build

# One end-to-end differential run
cd .. && ./scripts/test_exec.sh tests/minimal/001-return-literal.c
```

The full test surface — unit gates plus the per-corpus differential
scripts ("lanes") and their pinned baselines — is catalogued in
`scripts/LADDER.md` and summarized in [VALIDATION.md](VALIDATION.md);
the agent-facing operating manual with all build gotchas is
[CLAUDE.md](CLAUDE.md).

## What you can do with it

- **Batch execution with verdicts.** `cerberus-lean --batch <cabs-json>`
  runs a program's `main` and reports the Cerberus verdict — a
  `Defined` value (with stdout/stderr), a specific undefined-behaviour
  code, or an error — exhaustively over the nondeterministic branch
  structure or as a single trace (`--first`).
- **Function-level execution.** `--call <f> [--call-args <ints>]`
  calls an individual function with injected arguments (the caller
  protocol mirrors elaborated call sites; `CerbCall.lean`, a port-side
  harness entry over the generated driver — the oracle has no such
  mode, so the lanes run it on a rendered wrapper TU), used by the
  fixture lanes to compare individual functions against the oracle
  point-by-point.
- **Libc-linked and multi-TU programs.** The Lean pipeline links
  multiple translation units and can load the C standard library the
  oracle ships, so real multi-file programs (libxml2 slices, the CN
  corpus, csmith output) run under both implementations.
- **Semantics-level differential testing of C tooling.** The lanes in
  `scripts/` are reusable instruments: point them at a corpus and any
  divergence between the two implementations — or between either and
  a recorded expectation — fails loudly.

## The headline validation numbers

Byte-level verdict agreement with the OCaml oracle across (see
[VALIDATION.md](VALIDATION.md) for the full lane list, semantics, and
run tiers):

- 106/106 upstream `tests/minimal` programs at the pinned baseline —
  exactly 85 MATCH + 18 UB_MATCH + 3 CERB_SKIP (rows the oracle itself
  cannot run: recorded, never counted as agreement) — plus the
  coverage, debug, and float suites at their pinned baselines;
- 213/213 programs of the CN test corpus (multi-TU, libc proxies);
- 16/16 URIs through libxml2's `xmlParseURISafe` (5 translation
  units, libc-linked, byte-identical output) plus a 1,354-point
  libxml2 `chvalid` boundary battery;
- a 1,669-program csmith corpus at a pinned classified baseline, and
  a 2,186-file sweep of the upstream CI suite (zero mismatches among
  the 1,316 comparable);
- ~2,000 rendered harness-program executions across the five
  spec-lab differential families;
- per-function call-point differentials over the `tests/verify` and
  `corpus/` fixture sets.

Start with [VALIDATION.md](VALIDATION.md) for the trust story;
[DESIGN.md](DESIGN.md) for architecture; [TODO.md](TODO.md) for the
backlog; `docs/` for the dated record of how everything got here.
