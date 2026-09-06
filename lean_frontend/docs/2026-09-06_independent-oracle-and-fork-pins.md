# Independent oracle and fork source pins

2026-09-06 [AGENT], validation-foundations G3. Development record;
final-candidate runner evidence is still required.

## Three separate checks

1. Fork OCaml versus Lean uses the shared byte observation contract.
2. The existing generated-delta gate compares pristine and fork generated
   OCaml produced by the **same fork Lem**, currently `f6542f8`. Its 22
   reviewed diff hashes are unchanged by this work.
3. The new execution/API lane builds pristine Cerberus
   `b9aeedcb4dd438763b0eef7f95ac19e93875d7de` with upstream Lem
   `3802cb04b53d5f1096a464e51ecbfb2a750a7ccd`, then compares that engine
   with fork OCaml. It uses upstream Lem's compiler, generated OCaml
   libraries and installed OCaml runtime, all built in an owned prefix.

These checks cover different failure modes. The independent lane still
shares the identified OCaml compiler, standard libraries and system tools
with the fork. It is independent of the fork's model edits and Lem backend;
it is not an independent implementation of C or a proof of C conformance.

## Reproducible build and run

Load the container's project environment, then run from this repo root:

```bash
/home/dev/projects/cerberus-lean-proj/scripts/ce python3 scripts/build_independent_oracle.py \
  --lem-repo /home/dev/projects/cerberus-lean-proj/lem-lean \
  --cerberus-repo /home/dev/projects/cerberus-lean-proj/cerberus-lean \
  --out .validation-foundations/independent-oracle-v2

/home/dev/projects/cerberus-lean-proj/scripts/ce python3 scripts/test_upstream_oracle.py
/home/dev/projects/cerberus-lean-proj/scripts/ce python3 scripts/test_upstream_oracle.py --plant
```

The output directory must be new. `--lem-repo` and `--cerberus-repo` are
read-only object sources; their checked-out branch is irrelevant. Other
containers can use their own equivalent OCaml environment and repository
paths. `CERB_INDEPENDENT_MANIFEST=/absolute/path/manifest.json` selects a
different prepared build. Missing provenance fails the lane.

The recipe extracts immutable git archives into new directories. It copies
no generated Lean, OCaml output, native objects or build products from an
existing checkout. It builds upstream Lem and libraries, installs only
into `lem/local-install`, prepends that prefix to `PATH`/`OCAMLPATH`, and
checks `ocamlfind query lem` and `lem_zarith` before generating Cerberus.
`DUNE_CACHE=disabled` and Dune `--force` apply. Neither shared opam pins nor
shared installed packages change. In particular, upstream Lem's runtime
makefile requires `INSTALLDIR` without an underscore; supplying only the
root makefile's `INSTALL_DIR` would install into shared findlib storage.

Git archive builds need explicit source-version discipline. The first
development recipe let a version generator discover the enclosing fork's
git directory. The corrected recipe sets `GIT_CEILING_DIRECTORIES` to its
owned output directory, supplies Lem's immutable version explicitly and
lets archive-built Cerberus report `unknown`. Its real source identity is
the pinned commit and archive hash, not a fabricated version string.
The corrected cold build completed all six steps in about 50 seconds.

The manifest retains commands, statuses, timings, logs, source/archive
identities, tool hashes/versions, compiler/runtime/library trees, generated
OCaml and the actual oracle binary. The lane rechecks artifact bytes and
file sets, including the original source archives, before execution.

## Comparison scope and initial findings

The initial complete development run selected 723 cases: minimal, coverage,
debug, float, bytes, libc-exec, both multi-TU directories, all 213 CN rows
with their manifest-ordered support TUs, URI with and without libc, and
representative Core-dump/typecheck/argv CLI modes. The corpus selection
retains test_exec's explicit syntax-only/exhaustion exclusions. A public
OCaml package client compiles, links and runs `Utils.fromJust` through each
side's concrete-memory package and respective Lem runtime.

Derived initial results: 709 complete semantic observation agreements,
two legacy CLI agreements, and both OCaml library clients print `42`.
Twelve raw-diagnostic differences were investigated:

| Rows | Actual difference | Disposition |
|---|---|---|
| Eleven frontend rejections in coverage/debug/bytes | Only the `Time spent: <decimal> seconds` trailer differs | Compare status, stdout and all diagnostics after removing only that exact whole-line timing grammar. Preserve raw stderr. Report matching failure separately from semantic agreement. |
| `minimal/097-null-ptr-arith.undef.c` | Both exit 125 with empty stdout and the same deliberate null-pointer-arithmetic TODO. Generated Lem/OCaml backtrace frame locations differ. | Pin both complete raw stdout/stderr hashes and statuses in `scripts/upstream_oracle_differences.json`, with the reviewed rationale. This is an inherited model failure and a diagnostic-layout difference; it supplies no semantic result. |

The backtrace diff was read in full: failure text and the initial memory
frame agree; differences are Lem list line numbers, generated reduction/ND
locations and fork driver/pipeline locations. No semantic difference is
excused. An expected pin moving, even to apparent agreement, fails for review.
Unknown differences, timeouts, cap kills, malformed success and silent
success fail. `--only` reports a subset; it cannot certify the full lane.
The complete rerun passed all 723 classifications and both library clients;
the release runner recorded source unchanged. The actual-entry plant uses a real passing pair and then changes only the
fork's printed verdict through an explicit wrapper; acceptance requires
the unexpected comparison to fail.

Fork-only flags `--cabs-json`, `--call` and `--batch-alloc-census` have no
pristine counterpart. Lean kernel gates and generated fixture pins likewise
have no upstream OCaml interface. The report names these exclusions. The
small library client checks one genuine public package entry; it does not
claim binary compatibility or unchanged signatures across all public APIs.
The earlier fresh-supply work deliberately changed pipeline interfaces and
allows some Core dumps to move up to checked renaming; that historical
permission is not a wildcard exception in this execution lane.

## Content pin review

The 71 previously manifested source files are unchanged from assessed
mainline `89f7e6885`. Their existing historical reviews remain the semantic
rationale; adding whole-file content/mode hashes freezes those exact reviewed
bytes. It does not certify all historical edits correct afresh.

Five build/helper files join the source surface, for 76 total:

| File | Reviewed delta and limit |
|---|---|
| `Makefile` | OCaml generation records a source/output stamp after the existing Lem/sed recipe; cleaning removes the stamp. Lean-specific targets, copy manifest, totality transforms and native builds are separate additions. Existing `rebuild-lem` is an explicit maintenance target and is not used in this charter. |
| `tools/check_lem_sync.sh` | Compares source and generated-tree hashes, refuses empty/missing trees and malformed/moved stamps. It records derivation evidence; it cannot itself prove which compiler produced an output. Independent provenance and clean generation cover that separate question. |
| `tools/check_handwritten_sync.sh` | Checks the manifest's source/copy byte equality and reverse coverage of top-level Lean files before build/freshness claims. No semantic rewrite. |
| `tools/check_driver_fresh.sh` | Pins actual binaries and source sets; Lean records/checks first require the copy-set check. The existing loud development override is outside certification. Runtime/toolchain gaps in its source set remain the responsibility of the richer manifest and clean-build checks. |
| `scripts/common.sh` | Existing build/driver/cap helpers plus this charter's shared observations and explicit binary plants. Dune uses an explicit root and installs `cerberus-lib` under this worktree's `_build/local-install`; runtime selection remains the explicit staged tree. No model or compiler pin change. |

All original 22 generated-delta hashes are preserved. Whole-file pins also
cover `.lem` inputs, handwritten fresh supply, renumbering and driver code.
The name gate now detects untracked files on these surfaces. The content
reader rejects duplicate/malformed/missing pins and checks a bijection with
the complete live delta set. The 14-plant selftest passes, including an
unchanged scratch copy, an added declaration inside the already-listed
`util/cerb_fresh.ml`, and missing/duplicate content pins. Original locale,
prerequisite and Lem-pin plants remain in the battery.

No blanket refresh was used: five path entries and a new content section
were added, with the generated-delta section left byte-identical. A future
refresh is a proposed manifest change requiring the source diff to be
reviewed; hash acceptance alone is not an assessment of behavior.
