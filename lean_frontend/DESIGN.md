# DESIGN — how cerberus-lean works

This document explains the architecture for a newcomer. It states what
each piece is and why the load-bearing choices were made. It is not a
history; the dated records in `docs/` carry the how-we-got-here.

## 1. One semantics, two implementations

Cerberus defines the C semantics in [Lem](https://github.com/rems-project/lem),
a specification language that compiles to executable code. Upstream
Cerberus compiles the Lem model to OCaml. This fork adds a **Lean
backend to Lem** (in the sibling `lem-lean` repository) and compiles
the *same model* to Lean 4.

Why: hand-porting a semantics of this size would create a second
semantics that drifts from the first. Generating both sides from one
source makes agreement structural, and reduces the validation question
to (a) is the Lean backend of Lem correct, and (b) are the few
hand-written parts equivalent? Both questions are attacked by
differential testing (§5) and, where the artifacts are both in Lean,
by theorems rather than tests.

The generated code lives in `generated/` and is never edited by hand.
A content-hash gate (`lem-sync`) makes a stale generated tree a build
failure, so the binary you test always corresponds to the model
sources.

## 2. The pipeline and the Cabs JSON boundary

```
            OCaml (upstream code)          Lean (this port)
 C source ──► C parser (menhir) ──JSON──► CabsImport.lean
                                          desugar (Cabs → Ail)
                                          GenTyping (Ail typing)
                                          Translation (Ail → Core)
                                          Driver (Core execution)
```

The **boundary is Cabs**, the parsed C abstract syntax tree: OCaml
parses C and serializes Cabs to JSON; Lean deserializes it and runs
the entire semantic pipeline — desugaring, typing, elaboration to the
Core intermediate language, and execution.

Why the parser stays in OCaml: parsing C is semantically shallow
(nothing about program *meaning* lives there) and mechanically deep
(preprocessor, grammar hacks). Reusing the upstream parser keeps the
Lean surface focused on semantics while the JSON boundary keeps the
interface auditable. Core text files (`.core`, the standard library)
are parsed by a hand-written Lean parser (`CoreParser.lean`), mirrored
line-by-line against the OCaml Core lexer/parser.

## 3. Hand-written seams and the mirror-OCaml discipline

Some parts of the semantics cannot be generated from Lem because
upstream implements them directly in OCaml: the concrete memory model
(`CerbMem.lean`), implementation-defined behaviour for LP64
(`CerberusImpl.lean`), constant decoding (`CerbDecode.lean`), floats,
the filesystem model, mutable tag-definition state, and similar. These
"seam" files are hand-written Lean, and they follow a strict
discipline: **gratuitous divergence from the OCaml implementation is a
defect even if no test exposes it.** Every seam function either
mirrors its OCaml counterpart (with `file:line` citations in
comments) or documents, in code, why it deliberately differs. Audits
check the citations against the cited code.

Why: differential testing can only sample behaviour. Structural
mirroring makes equivalence reviewable where it cannot be proved, and
turns "the tests pass" into "the code is the same computation, and
the tests agree".

## 4. Executing C: nondeterminism, effects, totality

**Nondeterminism.** C leaves evaluation order and allocation addresses
underdetermined, and Cerberus's Core execution is explicitly
nondeterministic. The Lean runner (`CerbND.lean`) can enumerate the
nondeterministic branch structure exhaustively or follow a single
trace; verdicts (defined result / undefined behaviour / error) are
compared across the whole enumeration in differential runs.

**Effects.** The OCaml model uses mutable references for ambient state
(fresh-name counters, tag definitions, debug output). The Lean port
carries NONE of that as effects — the effect-retirement arc
(2026-08/09, `docs/2026-08-31_effect-retirement-design.md`) ended the
effect-erasure era: the fresh-symbol counter is an explicit threaded
SUPPLY (lem's `declare {lean} supply` state-passing transform for the
first-order region + supply fields in the desugar/elaboration monads
the model already threads; one stream, seeded by the driver); the tag
table is passed by value (reader lifting + `reader_consumer`); debug
output returns values, the driver prints. `LemLib.runEffectful` — the
old effect-projection axiom — is DELETED, and lem refuses
`declare {lean} effectful` outright. Zero `axiom` declarations exist
in this repository OR in LemLib (gate-enforced recursively; see
VALIDATION.md §3). The surviving pure-signature runtime seams (the
per-TU digest read, config refs, the enum registry) are kernel-checked
opaques on the declared `@[implemented_by]`/`@[extern]` boundary,
machine-pinned in `scripts/unsafebaseio_allowlist.txt`.

**Totality.** The execution path contains no `partial` definitions:
every function on it is fuel-totalized — structural recursion over an
explicit fuel argument, with loud failure at exhaustion — so the
executable semantics is a total Lean artifact the kernel can evaluate
and future consumers can reason about. A build gate enforces an empty
`partial`-allowlist for the execution slice.

**No magic values.** [USER 2026-09-03]: a fuel budget, a bound, a
default, or any "magical" choice among nondeterministic alternatives
that upstream Cerberus does not fix "are absolutely completely
forbidden and are definitionally bugs". Every such choice is a
QUANTIFIED PARAMETER of the semantics, threaded from the entry point
(`drive fuel …`), so a consumer's theorem can range over it; a numeral
may live only in the binary's command-line default (`--fuel`), never in
a definition. The general form [USER 2026-09-03], verbatim: "any instance of a
value that can be quantified over by a context / theorem is fine.
Defaults that are chosen eg. in test suites are fine. Any and all magic
values that are hardcoded and can't be quantified over are definitionally
bugs (unless they mirror lem or ISO-C design choices)" — for this
repository the mirrored source is upstream Cerberus's OCaml. The aim, stated by the operator the same day: "to forbid values that
limit the semantics or limit the ways the customer can reason about the
semantics". So a bound CHOSEN inside a definition is forbidden (it limits
both), while structural recursion on a measure that IS the data (the AVL
height stored in a node) is admissible — nothing is chosen, nothing is
bounded, and a proof can unfold it; a caller-passed parameter or a
termination proof are the other admissible forms.
The fuel story as of this writing violates this (`driverFuel = 10^8`,
`lemDefaultFuel = 10^6` in every generated fuel wrapper); the
fuel-parameter arc removes it: lem-lean
`doc/lean-backend/2026-09-03_fuel-parameter-design.md`.

## 5. Differential validation: the oracle, lanes, baselines, plants

The OCaml implementation is **the oracle**: it cannot be reasoned
about, only compared against — so it sits permanently on the trust
boundary, and the comparison is industrialized.

- **Lanes.** Each corpus has a lane script (`scripts/test_*.sh`) that
  runs every program through both pipelines and compares full verdict
  sequences (values, undefined-behaviour codes, exit codes; stdout
  where applicable). Current lanes cover the upstream test suites
  (incl. a 2,186-file CI sweep and a 1,669-program csmith corpus),
  libc-linked execution, multi-translation-unit linking, libxml2
  slices, the CN test corpus (213 programs), and the spec lab's
  harness families. See `scripts/LADDER.md` for the normative tiers.
- **Baselines.** Lanes are pinned to committed baselines and fail
  closed in both directions: a regression fails, and an unexplained
  improvement also fails (silent movement is how errors hide).
- **Plants.** Gates and specs are themselves tested by deliberate
  sabotage: break the thing the gate should catch, confirm the gate
  goes red, revert, rebuild, confirm green. A gate that has never
  caught a plant is treated as untested code.
- **Three-way differential.** An un-forked upstream checkout
  (`deps/cerberus-upstream`) separates "our fork's behaviour" from
  "upstream's behaviour", so fork regressions and upstream bugs are
  attributed, not conflated. A fork-drift gate pins the fork's
  oracle-side surface to a reviewed manifest.

## 6. Package structure

The Lean build is organized as Lake packages with a strictly one-way
dependency:

- the **semantics package** (this directory's root build): generated
  model + seams + the executable driver, including the `--call` entry
  the fixture lanes use (`CerbCall.lean`, a hand-written seam: `drive`
  started at a named function with injected arguments). The Cerberus
  operational semantics is the ONLY semantics this repository carries
  ([USER 2026-09-02]); the reasoning-era relational presentation
  (`RelSemCore`) was removed from mainline on 2026-09-02 and lives on
  the park branch (`docs/2026-09-02_relsem-prune-record.md`);
- **`speclab/`**: the harness-family differential-lane package
  (models, codecs, the `mkHarness` renderer, and the lane gate exes —
  see `speclab/README.md`), consuming the semantics one-way.

Nothing under the semantics surface may reference speclab. Any
verification layer built on this semantics is intended to live
downstream, pinning this repository like any dependency (per-target
example repositories, including GPL-licensed ones, likewise);
anything that would make that consumption harder is treated as a
defect.

## 7. Offline, pinning, reproducibility

The project is designed to build with **no network**: toolchains
preinstalled, opam packages installed, all Lake/git dependencies
cloned locally and mirrored (`deps/mirrors/`), with git `insteadOf`
redirects supplied per-invocation via `GIT_CONFIG_GLOBAL` (never
installed globally — the machine is shared). The Lem tool is
opam-pinned to a fixed commit of `lem-lean` (`deps/lem-pinned`); the
Lake manifest pins the same commit, and the two pins are kept in
lockstep — work lands only when branch heads, opam pin, and Lake pin
agree.

Two operational rules exist because they were each earned the hard
way (records in `docs/`): every `lake`/`lean` invocation runs under a
cgroup memory cap (`scripts/capped`), and validation of anything that
affects build rules runs cache-disabled from freshly re-derived
generated trees.

## 8. Where to read more

- The trust story (differential validation + gates): [VALIDATION.md](VALIDATION.md)
- Agent-facing operating manual (build mechanics, gates, gotchas):
  [CLAUDE.md](CLAUDE.md)
- Dated design records and results: `docs/` (start with the most
  recent `*-results.md`)
