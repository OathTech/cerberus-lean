# cerberus-lean: the Cerberus C semantics in Lean 4

This directory contains a Lean 4 port of the [Cerberus](https://www.cl.cam.ac.uk/~pes20/cerberus/)
C semantics. It is generated from the **same Lem model** as Cerberus's
OCaml implementation, so the two share one semantics by construction;
the Lean side is then **differentially validated** against the OCaml
implementation (the "oracle") on every test corpus we can get our
hands on. The point of having the semantics in Lean is that you can
**prove theorems about the execution of real C programs**, checked by
the Lean kernel, with no gap between the semantics you test and the
semantics you reason about.

Who this is for:

- You want to **run C** through an executable, rigorously defined
  semantics from inside Lean (undefined-behaviour verdicts included).
- You want to **verify C programs** against the semantics — see
  [PROOF.md](PROOF.md) for exactly what can be proved today and how
  the trust story works.
- You want to understand **how the port works** — see
  [DESIGN.md](DESIGN.md).

## Five-minute orientation

```
lean_frontend/
├── generated/        # Lean code generated from the Lem model (do not edit)
├── *.lean            # hand-written "seam" files (memory model, ND runner,
│                     #   parsers, implementation-defined behaviour, ...)
├── relsem/           # the proof package: relational semantics, iris-lean
│                     #   coupling, proof machinery, the theorem slate
├── relsemcore/       # exec-facing proof-support modules (root package side)
├── speclab/          # the spec lab: harness-based specification of real C
│                     #   functions (models, codecs, statements, proofs)
├── test/             # unit tests + gate executables
├── docs/             # dated design records and results (the project history)
└── lembugs/          # bug reports against the Lem backend, with reproducers
```

The C parser stays in OCaml: `cerberus --cabs-json` parses C and emits
a JSON AST; the Lean pipeline does everything after that (desugaring,
typing, elaboration to Core, execution).

## Build and run one differential test

From the repository root (see `../scripts/env.sh` if your shell lacks
the opam switch):

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
cd .. && ./scripts/test_exec.sh tests/minimal/001-return.c
```

The full test surface (unit gates, differential lanes, baselines) is
catalogued in `scripts/LADDER.md`; the agent-facing operating manual
with all build gotchas is [CLAUDE.md](CLAUDE.md).

## Where the proofs live

- `relsem/` — the theorem substrate: a relational layer over the
  executable semantics, iris-lean based proof machinery, and the
  current theorem slate. Build: `cd relsem && ../../scripts/capped
  lake build` (the build itself runs the proof-integrity gates).
- `speclab/` — specifications of real C functions in the
  "harnesses are programs" style, with their models, differential
  lanes, and kernel-checked statement layers.

Start with [PROOF.md](PROOF.md) for the capabilities and the precise
status of what is proved; [DESIGN.md](DESIGN.md) for architecture;
`docs/` for the dated record of how everything got here.
