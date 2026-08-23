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

**Provenance.** This port was developed primarily by AI agents
(Claude, Anthropic) operating under the direction and review of a
human operator (Mike Dodds). The upstream Cerberus semantics is by
its own authors (see the top-level README); the dated records in
`docs/` are the working history of the port.

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
│                     #   coupling, proof machinery, the theorems
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
`scripts/LADDER.md`; the agent-facing operating manual with all build
gotchas is [CLAUDE.md](CLAUDE.md).

## What are we proving? A two-minute tour

Two concrete examples, with every artifact's actual location. The
guiding question for any claim here is *"where is the C, what is the
statement, and how do I check it?"* — if you can't answer all three
from the files below, that's a documentation bug.

**A proved kernel theorem** (struct member write/read):

| Artifact | Where |
|---|---|
| The C program | `../tests/verify/t4_struct_member.c` |
| Its elaborated (Core) form, pinned | pinned terms in `relsem/RelSem/T1Core.lean`; byte-checked against a fresh oracle dump by the `emit-lean-core-test` gate |
| The statement | `T4Statement` in `relsem/RelSem/T4.lean` — quantified, mentions only the executable semantics and the program |
| The proof | `theorem T4 : T4Statement`, same file — an ordinary kernel-checked theorem |
| Its exact axioms | `#print axioms RelSem.T4` = `[propext, runEffectful, Classical.choice, Quot.sound]`, pinned in-build in `relsem/RelSem/Audit.lean` |
| The differential check | `../scripts/test_verify.sh` — runs the same C on both implementations and against the recorded spec points |

**A specified real C function** (binary-tree rotation, the
harness style of PROOF.md §2):

| Artifact | Where |
|---|---|
| The target C + its harness | `../tests/speclab/rotate_a.c` (a closed, runnable program: the target function, the compiled-in choice/expected arrays, builder, comparator) |
| The pure model + spec | `Tree`/`rotateAt` in `speclab/SpecLab/TreeRot.lean` |
| The statement | `RotateSampleStatement` in `speclab/SpecLab/TreeRotFiles.lean` — note its status: *defined and differentially validated*; the kernel proof of the execution itself is the in-flight campaign (PROOF.md §3 states exactly what is and isn't proved) |
| What IS kernel-checked today | the model lemmas, codec round-trips, model↔stream bridges, and plant-refutation schemas — `speclab/proofs/SpecLabProofs.lean`, cones pinned in `speclab/SpecLabAudit.lean` |
| The differential check | `../scripts/test_speclab_tree.sh --gate` (and `--plant`: deliberately broken targets must go red at the predicted index) |

## Where the proofs live

- `relsem/` — the theorem substrate: a relational layer over the
  executable semantics, iris-lean based proof machinery, and the
  current theorems. Build: `cd relsem && ../../scripts/capped
  lake build` (the build itself runs the proof-integrity gates).
- `speclab/` — specifications of real C functions in the
  "harnesses are programs" style, with their models, differential
  lanes, and kernel-checked statement layers.

Start with [PROOF.md](PROOF.md) for the capabilities and the precise
status of what is proved; [DESIGN.md](DESIGN.md) for architecture;
[TODO.md](TODO.md) for the roadmap and backlog; `docs/` for the dated
record of how everything got here.
