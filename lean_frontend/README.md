# cerberus-lean: the Cerberus C semantics in Lean 4

This directory contains a Lean 4 port of the [Cerberus](https://www.cl.cam.ac.uk/~pes20/cerberus/)
C semantics. Both targets are generated from shared Lem source, with
handwritten runtime seams. The Lean pipeline imports the OCaml parser's
Cabs JSON, elaborates it to Core, and executes Core inside Lean. Shared
source makes correspondence reviewable; it does not establish equivalent
failure behavior or a general conformance theorem by construction.

The execution definitions pass the repository's totality and axiom gates,
and differential lanes compare their printed observations with the fork's
OCaml engine. There are still explicit failure, fuel, representation and
runtime-boundary obligations. In particular, deliberate pure failures can
be erased by Lean evaluation, and enum/digest seams retain ambient runtime
state behind pure signatures. Zero added axiom declarations does not prove
agreement between those declarations and their native implementations.
See the [supported profile](docs/2026-09-06_supported-profile.md) and
[VALIDATION.md](VALIDATION.md) for measured scope and remaining release exits.
The [validation-foundations delivery](docs/2026-09-06_validation-foundations-delivery.md)
records the final gates, reporting findings, cold proof client and failure
census. The [master plan](docs/2026-09-05_master-plan.md) recommends scoped
SC integration next; it is a proposed arc, with landing discussed separately.

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
backlog; `docs/` for the dated record of how everything got here;
[docs/upstream-tray/README.md](docs/upstream-tray/README.md) if you
maintain Cerberus or Lem and were sent here to triage our bug reports.
