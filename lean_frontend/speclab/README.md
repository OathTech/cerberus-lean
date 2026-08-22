# speclab — the spec lab (arc 15)

The harness-template example laboratory: instantiating the ratified
harness statement template
(`notes/2026-08-22_harness-statement-template.md`, container-repo
notes) on a ladder of real examples, deliberately experimentally.
Charter: `lean_frontend/docs/2026-08-22_arc15-spec-lab-charter.md`.
Twin registers (the arc's primary product):
`docs/2026-08-22_arc15-spec-register.md` and
`docs/2026-08-22_arc15-proof-register.md`.

## The two standing invariants (no experiment may violate)

1. **Statements stay executable/first-order.** Everything in a
   statement is computable pure functions + first-order data;
   propositions/separation-logic/noncomputable vocabulary stays out.
   Enforced: `scripts/check_speclab_statements.sh` (grep-level
   Iris/RelSem/non-kernel-tactic ban, run by `scripts/test_speclab.sh`
   and fail-closed), with an in-build Audit-gate twin (the relsem
   pattern) due when the first semantics-facing theorems land. The
   escape hatch (SL vocabulary in a statement) is a per-instance
   OPERATOR decision, never drift.
2. **Every harness instance stays concretely runnable and
   oracle-differentiable.** Harnesses are programs: all variation
   enters through channels the semantics defines for programs; each
   resolved instance is a closed, deterministic C program both
   pipelines run bit-for-bit (`scripts/test_speclab.sh`), and every
   template ships a plant test (broken target ⇒ red differential +
   unprovable theorem — vacuity must be loud).

## Package layout

| Path | What |
|------|------|
| `SpecLab/Codec.lean` | Self-delimiting byte codecs (LE scalars, length-prefixed arrays) with kernel-checked `decode∘encode = id` round-trip lemmas (`decode_encode_u8/u16le/u32le/u64le`, `decodeElems_encodeElems`, `decode_encode_arrayU16`) |
| `SpecLab/MkHarness.lean` | `mkHarness` v1 — the choice-stream C source splicer (mechanism A), THE single trust point: three literal template parts + rendered `choices[]`/`expected[]` byte arrays, four-way concatenation, nothing else. Includes the v1 identity reference template (byte-blaster builder + mismatch-index comparator) |
| `test/Unit/SpecLabTest.lean` | Executable sanity layer (a TEST, not a proof): codec spot checks, renderer parse-back round trip, splice decomposition; `--emit-identity`/`--emit-plant` harness emitters for the runner |
| `../../scripts/test_speclab.sh` | Plant-test runner: harness → BOTH pipelines (oracle `--nolibc --exec --batch`; Lean cabs-json + `cerberus-lean --batch`) → agreement + expected verdict; `--selftest` and `--plant` modes live at S0. NOT gating until a rung stabilizes |
| `../../scripts/check_speclab_statements.sh` | Statement-TCB grep extension (invariant 1) |

Dependency direction: speclab requires the semantics (`CerberusLean`,
by path) and may later require relsem for proof machinery; NOTHING
under the semantics or relsem may reference speclab (the one-way gate
pattern — this package rehearses the two-part design's third layer,
the per-target example repos).

## Attribution — the golean idiom lineage

The harness idiom is adopted from golean (`deps/golean`,
design-donor attribution per the warm-up doctrine):

**Adopted** (golean's harness ruling, `docs/2026-08-12_example-spec-form.md`
§11 + `docs/verified-examples.md`):
- The three-phase harness shape: setup (build all memory the test
  needs) → the call under test → test phase folding memory analysis
  into RETURNED VALUES.
- Statements observe only termination + returned observables — no
  Lean-side heap readback, no frame clauses; "the program converts
  memory to observables". Implicit framing via the empty-heap entry.
- The copy-relational check (a history ghost materialized as real
  program code — golean's ghost-ladder rung 0) as the honest way to
  state relations without re-deriving setup algebra.
- Claim honesty as a rendering rule: domain conditions are part of the
  claim; harnesses are printed IN FULL (the test phase is part of what
  the theorem means); enumeration is banned as a proof method.
- The CBMC parallel: a closed test program quantified over its inputs.

**Where we deliberately differ**:
- **Input channel.** golean parameterizes structures by SCALAR harness
  arguments (`n`, `seed`) whose setup loops build the data — input
  FAMILIES, recorded as honestly weaker than ∀-data; its ∀-data
  mechanism (a choice-consuming input pick under the runtime `∀ch`
  quantifier, CBMC `nondet_*` style) was DESIGNED, NOT BUILT, with a
  recorded differential obligation (the oracle must be able to witness
  picked inputs). Our mechanism A discharges exactly that obligation
  differently: the choice stream is compiled INTO the program
  (`choices[]`), so choice is resolved before the program exists —
  every instance is closed and deterministic, the oracle runs it
  natively, and `decode∘encode = id` lifts the stream-∀ to a model-∀
  headline. Genuine ∀-data, no runtime pick, full differential/replay.
- **Program families.** golean's ruling 1 bans AST splicing/program
  families in favor of the machine's native argument entry. We adopt
  the program family deliberately: our oracle (cerberus-OCaml) runs
  arbitrary C text — text is precisely the shared channel with no
  reasoned-about/ran gap — and the family collapses back to one
  parametric lemma via the symbolic-initializer route (T5 iter_compose
  technology). The argv channel (golean's analogue of native argument
  entry) is mechanism B, probed at S0 and recorded in
  `docs/2026-08-22_arc15-s0-preliminaries.md`.
- **Verdict shape.** Where golean's verdict harnesses return a boolean
  `ok`, our default comparator returns a mismatch INDEX (`0` agreement
  / `1+i` first divergence / `255` length divergence) — boolean
  verdicts stay legitimate only for genuinely boolean properties
  (template note, readback section).

## Building / running

```bash
# package build (all round-trip lemmas kernel-checked here) — capped, always
cd lean_frontend/speclab && ../../scripts/capped lake build

# executable sanity layer + emitters
../../scripts/capped lake build speclab-test && ./.lake/build/bin/speclab-test

# end-to-end (both pipelines, from repo root; scripts/ce for env)
./scripts/test_speclab.sh --selftest   # identity harness, expect Specified(0)
./scripts/test_speclab.sh --plant      # corrupted expected[], expect Specified(2)
./scripts/test_speclab.sh <harness.c> 'Specified(0)'
```
