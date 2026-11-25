# Cerberus Lean Frontend — working practices

**Read this whole file before you do any work in this repository**: code,
proofs, tests, gate scripts, documentation, setup or migration. Every section
is a standing rule or something you need in order to follow one, and the
rules that are easiest to break are not all at the top. Stopping part-way is
how gates get missed. Lookup detail (what each test, file and script is)
lives in [REFERENCE.md](REFERENCE.md); that one you consult, not read
through.

Sections 1 to 3 are the rules: soundness, landing, working practices.
Section 4 is what a machine needs before the gates can run. The rest is how
to build and test.

## 1. Soundness comes first

This is a Lean 4 port of the Cerberus C semantics, generated from the same
`.lem` source as the OCaml implementation. Other projects build verification
results on top of it, so a wrong answer here becomes a false theorem
somewhere else. **Soundness is the project's key value** ([USER 2026-11-24]):
when soundness and speed, convenience or a tidy status report pull apart,
soundness wins.

What users are asked to trust, and why, is [VALIDATION.md](VALIDATION.md).
In brief:

- **There is no proof that the Lean port equals the OCaml implementation.**
  Trust rests on (a) structure: both are generated from one Lem model, and
  the hand-written residue mirrors its OCaml counterpart; and (b) evidence:
  differential lanes against the fork's OCaml oracle, an independently built
  pristine upstream oracle, and gcc, all with pinned, fail-closed baselines.
- **A green build is never the signal.** The differential baselines and the
  gates are.
- **The rule** ([USER 2026-09-03], VALIDATION §0): Lean differing from the
  oracle in matched mode, on a program both run, is a bug. The oracle's own
  deviations from ISO C are mirrored and reported upstream, not corrected
  here. No innovation relative to upstream unless something is very obviously
  a bug ([USER 2026-10-03]); where the answer is unclear, refuse loudly.
- **Fail closed.** A check that cannot run fails; it does not skip. Refusals,
  fuel exhaustion, timeouts and UB differences never count as agreement.
- **The Lean artifact is axiom-free and total on the execution path**:
  zero `axiom` declarations in this repository and in LemLib, enforced by
  `scripts/check_theorem_axioms.sh` (VALIDATION §6, §9).

## 2. Landing on mainline

**Nothing lands on `mdd/cerberus-lean` unless the full validation battery has
been run on the exact commit being landed and is green. Skipping or
shortening it must never happen unless the user explicitly and directly asks
for exactly that, for that landing** ([USER 2026-11-24]). A setup task, a
one-line fix to a gate script or a "trivial" change is a landing like any
other.

- **The battery** is the tiers of [`scripts/LADDER.md`](../scripts/LADDER.md),
  the executable authority for their membership. **Tier A** (the fast
  ladder): every commit and every claim that a piece of work is done.
  **Tier A + Tier B** (the slow ladder): slice boundaries, close-out, any
  checkpoint claim or audit, and **before any merge to mainline**.

  ```bash
  python3 scripts/release.py --list                        # what will run
  opam exec --switch=. -- ./scripts/ci_lean.sh --mode fast # Tier A
  opam exec --switch=. -- ./scripts/ci_lean.sh             # Tier A + B (pre-merge)
  ```

- **One run, on the exact commit, from re-derived generated trees**
  ([USER 2026-11-23]). A run on an earlier commit plus re-runs of some rows
  and an argument about which files changed is not landing evidence. The one
  exception: commits after the run that change documentation only (Markdown
  records, notes, reviews) do not need a new run. Anything else after the
  run (a script, a test or probe file, a baseline, a pin, a table a gate
  parses, any source) means a new full run on the new commit. Check with
  `git diff --name-only`, not by description.
- **A subset is not a certification.** `--lane` selections, a single script,
  or the one suite that showed a failure are labelled by the rows they ran
  and never reported as the ladder. A run with a missing prerequisite, a
  timeout, changed source or an override in the environment
  (`CERB_FORK_DRIFT_DEV_SKIP`, `CERB_ORACLE_BIN_OVERRIDE`,
  `CERB_LEAN_BIN_OVERRIDE`, `CERB_DRIVER_FRESH_OVERRIDE`) is not green.
- **A lane you cannot run is a blocker, not a footnote.** If a corpus, an
  oracle build or a tool is missing, provision it (§4) or stop and say so.
  Do not land around it.
- **Certification integrity.** Validation of changes that affect build rules
  runs cache-disabled (`DUNE_CACHE=disabled`, `--force`) from re-derived
  generated trees; audit plants mandate rebuild-after-revert; a gap between
  the artifact that was verified and the artifact that is loaded is a
  finding.
- **Kernel replay is a named trust gate** ([USER 2026-10-18]). For any slice
  that adds or changes proofs (measure-sufficiency carriers,
  `*_lemMeasureProofs.lean`, the Props-only seams), run
  `lake env leanchecker` over the built `.olean` of the affected modules
  before the slice-exit claim, and quote the modules and the checker's exit
  status in the record. A failed or skipped replay is a red gate, never a
  note. The axiom censuses of ladder row 1 remain the per-commit check.
- **The pre-merge audit ask is unconditional.** Before any merge, propose an
  audit scope and scale to the user. They may waive or trim it; the ask is
  never skipped.
- **Merges are ff-only, exactly, on the user's explicit sign-off for that
  merge.** If the mainline moved: rebase, re-gate, re-ask. No merge commits,
  no `git branch -f`, no pointer surgery. Ask with the evidence: which rows
  ran, on which commit, with what result, and which did not. The user's
  approval of a landing is not a waiver of gates you did not tell them were
  outstanding as a requirement.
- **No push without authorization.** `git push` is a separate action,
  authorized explicitly at the point of the push. Standing permission does
  not exist.
- **The primary checkout follows every landing** ([USER 2026-10-16]). Gates
  run in worktrees; the primary checkout's generated trees, stamps and
  binaries do not move with a fast-forward. After any ff onto the mainline
  there: `opam exec --switch=. -- make clean-prelude-src prelude-src
  lean-prelude-src`, rebuild (OCaml, then the capped `lake build`), run
  ladder row 1 there, and only then write the landing note.
- **Red means stop.** Report a failing gate as a failure, with its output.
  No baseline, register or gate changes to get green without an independent
  explanation of why the new value is right.

## 3. Working practices

The repository is the record: decisions go in dated files, never only in
chat.

- **Branches.** All work happens on arc/feature branches in worktrees; the
  primary checkout stays parked on `mdd/cerberus-lean`. Never commit on the
  mainline except user-sanctioned hotfixes; never commit on `master`
  (upstream-tracking). Parked branches are records: wrong-abstraction work is
  pruned, not merged. Roles: [root CLAUDE.md](../CLAUDE.md#branch-roles).
- **Orchestrator and worker.** Workers commit their own work: only on green
  gates, one coherent commit per slice, the message stating what was
  verified. The orchestrator independently re-verifies gates at boundaries; a
  worker's claim of green is never accepted as evidence. A committed park
  record ends the slice: working past it without approval is a violation.
  Status pings get an immediate interim reply.
- **Record integrity.** Quoted machine outputs are verbatim; derived tallies
  are labelled as derived. Decisions carry provenance, `[AGENT date]` for
  agent-called and `[USER date]` for user-called; failing to distinguish them
  is a critical trust failure. The user's messages are never quoted verbatim
  in files or commit messages ([USER 2026-10-16]): record a decision as a
  paraphrase in your own words with its tag and date, or omit the words.
  Quotes present before that date were paraphrased then; history was not
  rewritten.
- **Fail closed, fail noisy. Everywhere.** Fail-open behaviour (a default
  absorbing a failure silently) is a defect unless the user explicitly
  authorized it. Never `2>/dev/null` an install or build step.
- **Gates are plant-tested** (vacuity must be loud) and reserved for
  load-bearing trust properties. Discipline points get documentation notes
  and structurally forcing examples, not more gates.
- **No internal trust gaps.** Agreement between Lean artifacts is a theorem,
  not a test. Kernel-opaque artifacts are eliminated or sit on the declared
  boundary list (permanent, or temporal with a named mover). Non-kernel proof
  methods (`native_decide`, `bv_decide`, `ofReduce*`) are banned and
  gate-enforced.
- **Upstream's judgement stands; only its mistakes are overridden**
  ([USER 2026-10-20]). The Cerberus team are the C-semantics experts and this
  project mostly is not. A deliberate upstream reading, or a case upstream
  left open with a TODO, is a judgement: the fork keeps it as it is or
  refuses loudly, and never substitutes its own semantics (be slow to call
  any C initialization or memory question obvious). A refusal is a declared,
  attributed stop; an internal error, assertion or uncaught exception on
  valid C is a crash, and turning a crash into a refusal is always a valid
  refinement. No silently wrong answer is ever tolerated. A demonstrable
  mistake against the standard, one upstream would recognise as such, may be
  overridden, mirrored in both engines and registered as a fork-ahead delta
  against pristine upstream, with the report in the upstream tray. Refuse
  until it hurts.
- **Fork-ahead deltas are of two kinds only** ([USER 2026-10-29]): (1) the
  fork's own fixes and refusals, each filed in the upstream tray; (2) the
  minimal backports of upstream fixes that a consumer delivery needs, each
  authorized by the user in the slice's charter and registered as a delta
  expected to come out again at the merge-base bump. Nothing else: until the
  bump, a case upstream has since fixed is refused, not re-implemented.
- **Fixes stay semantically uncontroversial** ([USER 2026-11-04]): a fork fix
  of an upstream mistake is made only where the standard's intent is very
  clear or where the defect genuinely blocks a consumer. The fork does not
  invent semantics; everything else is a declared refusal and a tray filing.
- **Mirror-OCaml doctrine.** Gratuitous Lean/OCaml divergence in hand-written
  seams is a defect as such: mirror the OCaml with file:line cites, or
  document the divergence in the code as deliberate.
- **Zero warnings, by the build** ([USER 2026-11-14]). The root package,
  `speclab` and LemLib compile with `-DwarningAsError=true`. The flag is
  never removed to get a warning through. Not covered: ad-hoc probe files
  compiled through `scripts/lean_probe.sh`.
- **Never run a Lean build uncapped.** Every `lake`/`lean` invocation goes
  through `scripts/capped` (cgroup cap, `CERB_MEM_MAX`; `=none` is a loud
  opt-out needing the user's approval). One heavy job at a time; suspect an
  out-of-memory kill on any unexplained session death; commit promptly.
- **The grind ban.** Any build or proof pass approaching an hour is a
  stop-and-report event; more than an hour needs written justification in
  advance (measurement sweeps over differential corpora may qualify; kernel
  or term grind never does). The banned pattern is brute force in place of
  structure. Heartbeat and `maxRecDepth` bumps are defects by definition
  (register them with an expected remover); giant terms in goals are a
  representation smell.
- **Profile before optimizing.** Performance mechanisms are named in classic
  PL terms and understood before they are imposed; representation-coupled
  hacks without insight are forbidden. Performance plans are discussed
  before dispatch and adversarially reviewed.
- **Design passes and core documents.** The scope of a design-level pass is
  decided with the user before an agent is briefed. Core documents at major
  revisions get a fresh full review by a new reviewer, never a
  same-reviewer delta.
- **Shared machine.** Do not modify machine-global state (`~/.gitconfig`,
  the default opam switch, shell profiles, shared caches). Everything this
  project needs is scoped to the repository directory or the environment. An
  exception is proposed with a clear warning and needs the user's approval at
  the moment of execution.
- **Rule conflicts** are raised with the user; if that is impossible,
  default fail-closed with the minimum globally visible change.
- **Consumers pin this repository by commit** (cerberus-sl in its
  `scripts/semantics-pin.env`; cerberus-caesium; refinedc-lean). A change to
  an interface they read gets a consumer note in `docs/`
  (`*_consumer-note-<consumer>-*.md`), and a commit they pin must exist on
  the remote.

## 4. What the full ladder needs on the machine

The ladder compares against things that are not in this repository. They
must be present at the pinned revisions before a full run; the lanes fail
closed without them. Until 2026-11-23 a surrounding workspace folder supplied
them; they are now provisioned per checkout.

Two scripts do the provisioning and check it (2026-11-25); neither is a gate:

```bash
scripts/preflight.sh            # report, in seconds: what the ladder needs and what is missing
scripts/bootstrap.sh --help     # switch | sources | build | oracles | all | worktree NAME [BASE]
```

Run `scripts/preflight.sh` before starting a ladder run: a lane that lacks
its prerequisite fails closed, but only when it is reached, which can be
hours in. A clean preflight means the lanes can start, not that they pass.

| Prerequisite | Used by | Where | Revision |
|---|---|---|---|
| Local opam switch, fork Lem | everything | `./_opam` ([README](README.md#build-and-run-one-differential-test)) | the Lem rev in `lakefile.toml`; one value at every pin site (`scripts/check_pin_sites.sh`) |
| `gcc` on the path | A1 (implementation-profile lane), B7 (gcc second oracle) | system | not pinned; rows recorded against gcc's output can move with its version |
| `upstream` git ref + pristine generated tree | A1 (fork drift) | [VALIDATION: provisioning](VALIDATION.md#provisioning-the-fork-drift-oracle); export `CERB_UPSTREAM_TREE` | `merge-base=` in `scripts/fork_drift_manifest.txt` |
| Independent upstream oracle | B10, B12 | `scripts/ensure_independent_oracle.py --lem-repo … --cerberus-repo …` builds `.validation-foundations/independent-oracle-v2` | `CERBERUS_REV`, `LEM_REV` in `scripts/build_independent_oracle.py` (upstream Lem, rems-project/lem, not the fork) |
| CN test corpus | A11 | `deps/cn` (rems-project/cn), or `CN_CORPUS_DIR` | the `cn` pin in `scripts/external_pins.txt` |
| libxml2 | A10, B1, B12 | `deps/libxml2` (GNOME/libxml2), or `LIBXML2_DIR` | the `libxml2` pin in `scripts/external_pins.txt` (a master commit, not a release tag) |
| pKVM buddy-allocator case study | A14 | `deps/CN-pKVM-buddy-allocator-case-study` (rems-project), or `PKVM_CASE_STUDY` | the `pkvm` pin in `scripts/external_pins.txt` |
| Un-forked upstream Cerberus, built | non-gating probes (`tests/noodle-probes`, `tests/z2-probes`) | `deps/cerberus-upstream`, or `CERB_UPSTREAM` | the fork's merge-base |

`deps/` is a directory in the repository root or an ancestor of it; the
lanes walk upwards to find it. It is not tracked. The three corpora are
pinned by commit in `scripts/external_pins.txt`, and each lane checks its
checkout with `scripts/check_external_pin.sh` before reading it (its own git
checkout, HEAD at the pin, no modified tracked file; fail-closed). A pin
moves in the same commit as the baseline it moves with.

The runner puts each lane in its own cgroup, so it needs a writable,
delegated cgroup v2 parent with the memory controller; without one it fails
before dispatch. Gate scripts must not depend on the caller's locale or on
which coreutils implementation is installed: comparisons that feed `comm`,
`uniq` or `diff` sort under `LC_ALL=C`.

**A gate pins what the repository determines, never what the machine does.**
A baseline, ledger or register may record a value only if it follows from
the repository's content and the pinned inputs above. A value produced by
the host (an address, a host tool's message text or default, a path, a
timing) is printed for the reader, not compared; if it must be compared,
the tool and its options are stated in the gate. Assumptions the ladder
does make about the machine, on purpose:

- x86-64 Linux. A few rows record x86-64 behaviour (a NaN's sign bit, a
  segmentation fault's exit status, a signed-`char` host preprocessor).
- The host C preprocessor (`cc -E`) feeds every oracle run and is not
  versioned; the preprocessor is the host's by contract D20.
- gcc, run with a stated standard (`$GCC_BIN`, else the first `gcc` on the
  path).
- A delegated cgroup v2 parent, enough memory for the capped lanes (one
  elaboration peaks near 15 GB), and a machine fast enough that rows near
  their wall-clock limits do not time out.

**A new worktree is not ready to gate until it is primed.**
`scripts/bootstrap.sh worktree NAME [BASE]` does this: a new branch in
`worktrees/NAME`, the switch shared by a link, the LemLib source copied, and
everything else built there from scratch. What it provides, if you prime one
by hand: its own
`lean_frontend/.lake` (copy the primary checkout's; a fresh clone of LemLib
needs the network), an `_opam` (a symlink to the primary checkout's switch is
allowed: never add or remove opam packages through it), regenerated or
copied `generated/` trees with their `lem_sync.sha256` stamps, the
`driver_fresh.*.sha256` stamps if binaries were copied, and its own
independent oracle (`scripts/ensure_independent_oracle.py`). A stale or
missing stamp fails closed; do not copy a stamp over a tree it does not
describe. A worktree placed inside the repository directory needs
`--root .` on every `dune` command of the build recipe: without it dune
takes the enclosing checkout as its root and fails with "Don't know how to
build" (the lane scripts pass `--root` themselves). After priming, read the
build log for errors and confirm the exit status of every step; a quiet
tail is not a successful build.

## Architecture

```
cerberus (OCaml)                    cerberus-lean (Lean)
┌──────────────────┐               ┌──────────────────────────┐
│ C parser (menhir)│──Cabs JSON──→│ CabsImport.lean           │
│ cerberus --cabs-json             │ CoreParser.lean (.core)   │
└──────────────────┘               │ Cabs_to_ail (desugar)     │
                                   │ GenTyping (typecheck)      │
                                   │ Translation (elaborate)    │
                                   │ Driver (execute)           │
                                   └──────────────────────────┘
```

**Boundary:** Cabs (parsed C AST). OCaml parses C, serializes to JSON. Lean deserializes and runs the entire semantic pipeline.

**Core text parser:** Lean parses `.core` and `.impl` files directly using `Std.Internal.Parsec`.

**Trust story:** see [VALIDATION.md](VALIDATION.md) (differential
validation + gates) and [DESIGN.md](DESIGN.md) for architecture.
Operational map:

- The root package builds the semantics: generated model + seams +
  the `cerberus-lean` driver exe (incl. `CerbCall.lean`, the driver's
  `--call` engine — a hand-written seam, not a separate lib). There is
  NO second semantics package: the reasoning-era `RelSemCore` lib was
  removed 2026-09-02 (`docs/2026-09-02_relsem-prune-record.md`; park
  tag `park/reasoning-era-20260831`).
- `speclab/` is a second Lake package (requires the semantics by
  path; git deps shared via `packagesDir = "../.lake/packages"`): the
  harness-family models/codecs/renderer and the gate exes the
  `test_speclab*.sh` differential lanes consume (`speclab/README.md`).
- PROBE RECIPE: ad-hoc probes of package files run via
  `scripts/lean_probe.sh` FROM the owning package dir (e.g. from
  `lean_frontend/`: `../scripts/lean_probe.sh MyProbe.lean`) — it
  drives `lake setup-file` (the complete per-module artifact map) +
  `lean --setup` under the memory cap. `lake build <lib>.<Mod>`
  remains correct for lib members. After moving modules between
  packages, delete the orphaned artifacts stranded in the other
  package's `.lake` tree (a stale-shadowed probe is a doctored
  instrument).
- Lake deps: `LemLib` at the immutable lem-lean revision in
  `lakefile.toml` and the three committed Lake manifests. Public clones use
  the GitHub URL; optional local redirects are development infrastructure.

## Build

Use [README.md](README.md#build-and-run-one-differential-test) for the complete first-build recipe and
local switch installation. Commands below run from the repository root,
after that installation. Lean is pinned by `lean_frontend/lean-toolchain`
(4.35.0 since the 2026-10-25 toolchain move); the opam Lem revision must match Lake's LemLib revision.

```bash
opam exec --switch=. -- make prelude-src lean-prelude-src
opam exec --switch=. -- dune build backend/driver/main.exe cerberus-lib.install
# Install worktree-locally, including when _opam is a shared symlink.
opam exec --switch=. -- dune install --prefix "$PWD/_build/local-install" cerberus-lib
# Stage the libc package used by libc-mode oracle lanes.
opam exec --switch=. -- dune build cerberus.install
CERB_MEM_MAX=32G opam exec --switch=. -- ./scripts/capped make lean-native-obj
(cd lean_frontend && CERB_MEM_MAX=32G ../scripts/capped lake build CerberusLean cerberus-lean)
# Separate package; the speclab lanes also build it themselves.
(cd lean_frontend/speclab && CERB_MEM_MAX=32G ../../scripts/capped lake build)
```

Every Lake/Lean invocation goes through `scripts/capped`; cap prerequisites
and the loud uncapped fallback are described in the README. An owned
switch is distinct from a development worktree whose `_opam` points to a
shared switch: installing into the latter changes other checkouts' tools.
Use the local install prefix above for the runtime; engine invocations use
`--runtime=_build/install/default`, staged by the two Dune build commands.
After a `dune clean`, rebuild both install targets. Manually tampering with
`_build` can defeat Dune's incremental database; clean and rebuild a damaged
owned build tree instead of trusting a cached executable.

Lem updates use an owned switch and immutable public revision as described
under [Lem backend interaction](#lem-backend-interaction). A container
`deps/lem-pinned` checkout is not part of the public build procedure.

## Testing

The ladder (§2) is the test surface; [`scripts/LADDER.md`](../scripts/LADDER.md)
has every row, its bar and its cost. While developing, run the rows your
change touches, for example:

```bash
opam exec --switch=. -- ./scripts/test_unit.sh                 # row 1: unit exes + build-time gates
opam exec --switch=. -- ./scripts/test_unit.sh fresh-int-test  # one unit exe
opam exec --switch=. -- ./scripts/test_exec.sh --check-baseline  # tests/minimal vs its baseline
```

Hand-written unit tests live in `lean_frontend/test/Unit/<Name>Test.lean`,
each with a `[[lean_exe]]` in `lakefile.toml` that exits 0 on pass. What each
unit test, gate script and lane checks is catalogued in
[REFERENCE.md](REFERENCE.md#testing). Running a few rows while you work is
development; it is not the gate run that §2 requires.

## IMPORTANT: Hand-written files must be copied to `generated/`

Lake compiles from `generated/` (set via `srcDir = "generated"` in `lakefile.toml`), NOT from `lean_frontend/` directly. Hand-written files live in `lean_frontend/` and are copied into `generated/` by the Makefile.

**After editing any hand-written file, you MUST copy it:**
```bash
cp CoreParser.lean generated/CoreParser.lean   # or whichever file you changed
```

Or copy all hand-written files at once:
```bash
make lean-prelude-src   # from project root
```

If you skip this step, Lake will compile the stale `generated/` copy and your changes will have no effect. Do NOT use symlinks — they break `lake update`.

**Since 2026-09-02 this is GATED, not just documented** (hotfix
`fix/freshness-copy-gap`, `docs/2026-09-02_freshness-copy-gap.md`): the
copy set is `lean_frontend/handwritten_copy.manifest` — the one list the
Makefile copies from — and `tools/check_handwritten_sync.sh` requires
every listed file to be byte-identical to its `generated/` copy (and
every `lean_frontend/*.lean` to be listed; empty manifest = FAIL). It
runs as a precondition of `scripts/common.sh build_lean` (refuses to
build), inside `tools/check_driver_fresh.sh --record-lean/--check` (no
freshness stamp over a stale copy), and as `test_unit.sh`'s sync gate.
Adding a hand-written file = add it to the manifest, or the gate names
it. The gap it closed: a merge changed `CerbMem.lean`, `build_lean` ran
without `make lean-prelude-src`, and the freshness stamp read green over
a binary built from the old copy.

## Lem backend interaction

Lem is the OCaml tool from the lem-lean fork. The public installation
recipe is [README.md](README.md), including an explicit local opam switch
and the revision shared with Lake's LemLib. No parent `scripts/env.sh`,
private Git redirects or container `deps/` worktree is a prerequisite.
Checked 2026-09-25 against `bb487dda7c56981e76d67f53ae16e874cfe5ed61`; cleanup measurements:
[follow-up record](docs/2026-09-25_public-readiness-followup.md).

When updating Lem, install the chosen immutable revision into an owned
local switch, update the Lake revision/manifests and fork-drift metadata,
regenerate both trees (`make prelude-src lean-prelude-src`), and run the
required ladder gates. Do not install into a shared switch from a worktree.
The `lem-sync` stamps hash sources and outputs, not the Lem version.

**The two-repository pin dance.** A change that needs a Lem change uses a
same-name branch in both repositories. Merge order: lem-lean first (ff-only
on its mainline `mdd/lean-backend`), re-pin this repository to the merged
Lem commit, re-gate, then this repository merges ff-only. The work is closed
only when the branch heads, the opam pin and the Lake pin agree. Lem-backend
defects are reported in the lem-lean repository.

Backend mechanisms (`target_rep`, `skip_instances`, derived instances, the
instance-priority lattice) are described in
[REFERENCE.md](REFERENCE.md#lem-backend-mechanisms).

## Records and reporting

- Decisions and rulings go in committed, dated records in `docs/`, with
  their provenance tags (§3, record integrity). Working documents are born
  in the repository and committed; scratch and log directories (`.tmp/`) are
  ephemeral and deleted at slice end.
- Dated records go in `docs/`; they are history, not current status. Current
  scope is [SUPPORTED.md](SUPPORTED.md), the consumer contract
  [CONTRACT.md](CONTRACT.md), the backlog [TODO.md](TODO.md).
- For concurrency work, begin with the governing
  [SC concurrency master plan](../SC-CONCURRENCY.md). Its current slice and
  acceptance criteria supersede prototype roadmaps; keep current status in
  that plan.
- This file is working practices only ([USER 2026-08-31]): not a log of
  decisions. Edit it in place and keep it current; put catalogue detail in
  [REFERENCE.md](REFERENCE.md) and history in a dated record. Changing a
  rule in §1 to §3 is a proposal to the user.

## Conventions

- Hand-written files in `lean_frontend/`, generated files in `lean_frontend/generated/`
- `set_option autoImplicit true` in hand-written files (project default is false)
- Follow OCaml implementation as reference, with lean-c-semantics as secondary reference
- No sorry in hand-written code — use `fail`, `failwithI` (LemLib's opaque failure leaf — never `panic!`, which is transparent and reduces to `default` in the kernel; seam-hygiene 2026-09-19, `docs/2026-09-18_seam-hygiene-record.md`), or real implementations
- Bug reports: lem-backend defects → the lem-lean repo (`doc/lean-backend/` records, `tests/comprehensive` reproducers); upstream-facing reports → `lean_frontend/docs/upstream-tray/<target>/`
