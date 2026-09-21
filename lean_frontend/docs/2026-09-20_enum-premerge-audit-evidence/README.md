# Enum pre-merge audit evidence

[AGENT: Codex], audit begun 2026-09-20. These artifacts support the adjacent
[audit](../2026-09-20_enum-premerge-audit.md), including its negative findings.
They do not certify a repaired branch.

## Exact subjects and build isolation

- BASE: `5407597d9eeba0259d65b728e86a860ad4614ab3`, rebuilt in
  `worktrees/cerberus-lean-audit/enum-base-20260920`.
- HEAD: `0e1968ffb6d4736e60a7b53bee2fb3eb2c336304`, rebuilt in
  `worktrees/cerberus-lean-audit/enum-premerge-20260920`.
- Pristine: the independently built oracle identified by the retained manifest,
  under HEAD's `.validation-foundations/independent-oracle-v2`.

Paths in the captures are the original absolute paths below
`/home/dev/projects/cerberus-lean-proj`. The two audit worktrees were created with
the container's `scripts/new-worktree.sh`, passing the exact commits above and
`CERB_SKIP_INDEPENDENT_ORACLE=1`; no original implementation worktree was edited.
The HEAD oracle was subsequently built with `ensure_independent_oracle.py`.
The shared opam switch was used read-only; runtime installation was local to
each worktree.

Both trees were freshly generated and built, with `DUNE_CACHE=disabled`,
`CERB_MEM_MAX=32G`, and the container's `scripts/ce` environment:

```sh
make prelude-src lean-prelude-src
opam exec --switch=. -- dune build --root . --force \
  backend/driver/main.exe cerberus-lib.install cerberus.install
source scripts/common.sh
build_cerberus
build_lean
```

HEAD's original forced-dune command omitted `--root .`; BASE used it. Both
completed successfully. `build_lean` builds all package roots and the driver
under `scripts/capped`. The fresh pristine build used:

```sh
python3 scripts/ensure_independent_oracle.py
```

`build-head.log`, `build-base.log`, `fresh-build-identities.json` and the retained
stamp/manifest files record these builds. The head Lean binary SHA-256 was
`80f2e318ce1cf114b03d4a2745aadad33f2533c69e154db42d5dacba4450b724`.

## Full standard battery

The full run was invoked in the HEAD audit worktree through `scripts/ce`:

```sh
export DUNE_CACHE=disabled CERB_MEM_MAX=32G
python3 scripts/release.py --mode full --out .tmp/enum-premerge/full
```

Completed 2026-09-21 01:03:04 UTC; runner exit 0; **5,185.3 seconds**
(86 minutes 25 seconds), derived from the retained timestamps. Verbatim:

```text
full: passed; 39/39 selected commands completed successfully.
Source unchanged: True. Complete tier selection: True.
Release certification: incomplete: reporting/adoption/audit exits require separate evidence.
```

`release-report.json` preserves the complete runner report, including both
source/external-input identities and both artifact inventories. Those inventories
are equal (`artifact-differences.json` is empty). `release-summary.txt` and
`full-run.log` retain the runner's words; `release-lane-receipts.tar.gz` retains
every lane's top-level stdout, stderr and process-scope receipts. The stdout and
stderr hashes were checked against the report when packaging. `pristine-reports.tar.gz`
retains both pristine comparison reports, including their per-case classifications.
Individual standard-corpus captures and compiler build products are not archived;
the corpus inputs remain at the recorded source revisions. All focused audit
captures are retained separately, as described below.


The run's complete source/external-input identities belong to the tested HEAD,
before this audit document and its evidence were added. A subsequent docs-only
audit commit is not a new tested implementation head.

## Focused semantic and constructor probes

`probes/` holds the 28 C inputs. The scripts are the diagnostic collectors used, with original worktree paths
retained; whitespace-only formatting of the readable copies is documented below. To repeat at the original paths,
copy `probes/` and the collector scripts to HEAD's `.tmp/enum-premerge/`, then
run the following through `scripts/ce` from HEAD:

```sh
python3 .tmp/enum-premerge/run_probes.py
python3 .tmp/enum-premerge/replay_controls.py
python3 .tmp/enum-premerge/integration_probes.py
python3 .tmp/enum-premerge/check_constructors.py
```

For relocated worktrees, adjust the explicit BASE path in `replay_controls.py`
and `check_constructors.py`. `run_probes.py` contains an unused legacy `base`
variable; all its actual engine entries are HEAD. These collectors intentionally
continue after engine failures and record them. **A collector's exit zero is
not a passing differential verdict.** Read the per-engine statuses and complete
codec observations in the result JSONs. Lean uses `scripts/capped`,
`CERB_MEM_MAX=8G`, `LEAN_ABORT_ON_PANIC=1`; each semantic engine has a 30-second
timeout. Raw stdout, stderr, status, and the exact Cabs inputs are retained in
`focused-captures.tar.gz`.

- `probes-results.json`: 28 programs × HEAD fork/Lean; classification in
  `focused-summary.json`. Six are the new Lean-only aborts in finding E1.
- `controls-results.json`: 13 selected programs × BASE fork/BASE Lean/pristine.
  The same HEAD-produced Cabs JSON is used for BASE Lean; the OCaml runs parse
  the same C source. The parser is unchanged by this arc.
- `integration-results.json`: six additional paired runs and the one `--call`
  run. Multi-TU input order is explicit in each command. The integration C inputs
  and raw captures are included in `focused-captures.tar.gz`.
- `gcc-results.json`: native GNU C11, `-O0` compile/run controls. GCC program exit
  values are the C return values; Cerberus uses protocol exit zero and prints
  `Specified(value)` instead. The commands and both statuses are retained.
- `constructors/`: extracted actual web and BMC record expressions and the
  compiler's complete diagnostics against both freshly generated interfaces.
  Identity stand-ins replace only unchanged transformation helpers. This
  isolates the missing field; it is **not** a build of either complete optional
  backend.
- `generated-callback-excerpts.txt`: the emitted call and seed-wrapper signature.
  The source files at HEAD remain the authority; excerpt line numbers refer to
  this fresh generation.
- `sign-normalisation/`: three direct signedness queries on the built base/head
  OCaml and Lean implementations, supporting E4. The two unsupported-width queries
  abort only in head Lean. These are function calls, not additional C-program
  observations. `results.json` includes complete compiler/run statuses and
  stdout/stderr; `artifact-identities.json` pins the linked libraries and Lean
  modules. The head OCaml library hash also matches the full runner's initial
  artifact inventory. `run.py` uses the built OCaml libraries and capped Lean probes;
  it requires the six retained `.lean` sources to be copied to the corresponding
  worktree's `lean_frontend/.tmp/EnumSignAudit-<case>.lean` first (remove the
  `head-`/`base-` filename prefix). Copy this directory into HEAD's
  `.tmp/enum-premerge/sign-normalisation/` and run its `run.py` through `scripts/ce`.
  Its exit zero means collection completed; it does not mean the queries agree.

The 15 matching full-observation pairs comprise 14 successful value executions
and one matching `Undefined` verdict (`cast-pointer`, exit 1 on both engines).
The seven rejected/internal-failure probe pairs are kept separate as well. In particular, `sizeof` statement-expression controls expose a shared
baseline limitation and are not reported as new enum-arc defects.

## Review aids and integrity

`source-identity-plant.json` records calls to the actual runner's
`source_identity` on a tiny scratch Git repository: an unchanged dirty tree
compares equal; changing its bytes compares unequal. `source_identity_probe.py`
is a reproduction recipe written after the original fixture run and successfully
replayed (`source-identity-replay.json`). It uses a new
scratch repository and local `git -c` identity options, changing no Git config.
This establishes the meaning of E3; it cannot recover the deleted historical
release report.

`scope-checks.json` records the exact baseline row movement and unchanged
boundary files. `reader-consumer-declarations.json` retains the 22 source
declarations behind the corrected census. `compare_proof_threading.py` / `proof-threading.json` are a
textual review aid: stripping comments and the newly introduced reader binders
and arguments makes the seven listed proof modules equal to BASE. This is not
a semantic equivalence theorem. `generated-ocaml-delta.json` records the eleven
freshly generated OCaml files that differ between BASE and HEAD.

`SHA256SUMS` covers every retained evidence file except itself. Captures and receipts in the archives and result JSONs are unmodified.
`formatting-originals.tar.gz` preserves the original bytes of five readable
files whose trailing whitespace or extra final blank lines were removed for
repository formatting: `constructors.txt`, `constructors/bmc_record.ml`,
`generated-callback-excerpts.txt`, `run_probes.py` and `sign-normalisation/run.log`.
The changes are whitespace-only; the original bytes remain in that archive. Other summaries
and excerpts are identified as such. Archives use relative paths and contain no binaries, opam state or
compiler build products.
