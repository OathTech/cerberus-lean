# Public-readiness remediation — MUST checkpoint

Date: 2026-09-24. [AGENT] Cleanup branch `cleanup/public-readiness-20260924`,
based on `e9f9d049ffaaf005c392495b0f6418d21f4df29f`. Reviewed implementation:
`abe505d3d856162c058653019b27388e8523ce47`; Lem dependency: `9bb6c6b583c2eb4ecf6ca5b21a274dacc29e0fa4`. Gates measured the worktree bytes subsequently committed at that
implementation pin. Documentation follows in a separate commit.

## Scope and disposition

| Ledger | Change / disposition |
|---|---|
| M1 | Remove the `GIT_CONFIG_GLOBAL` requirement in `scripts/common.sh`; require the fork Lem executable in the caller's opam environment. Remove ancestor `env.sh` discovery from `scripts/capped`. Lem's own suite gains a local wrapper. Cap platform/fallback documentation is the operator's SHOULD portion, documented without changing its loud fallback. |
| M2 | Publish explicit fork clone, local opam switch, immutable Lem pin, local runtime install, native-object compilation, Lean build and one-C-program recipe. Explain panic environment and toolchain. |
| M4 | Replace all 23 excluded `cmm_csem.lem` `sorry` reps with named `LemUnsupported.Cmm.*` markers. No concurrency implementation is added; the current generated sequential model still builds. |
| M6 | Add current SUPPORTED.md; update fuel counts, boundary inventory and digest-bearing entry arity. September 6 profiles/results remain dated history. Operator-reported customer acceptance is quoted separately from release certification. |
| M7 | Correct minimal baseline inventory to 113 rows = 90 MATCH + 18 UB_MATCH + five CERB_SKIP (derived from the base pin). Correct pristine differences to seven case rows, including repeated allocator witness forms. Limit the root claim to documented differential lanes. |
| M8 | Lem restores source notices and documents license exceptions; the inherited linking-exception ambiguity still needs maintainer resolution before more specific assurances. See the Lem remediation record and NOTICE. |
| M9 | UNVERIFIED-OFFLINE. Public default branches, anonymous URLs and pinned-revision fetchability remain operator checks below. |
| M10 | Commit `d6618ecb9` untracks 21 archives / 21,888,265 bytes at HEAD only (derived inventory). Working files and history remain; the dated inventory records SHA256 and recovery instructions. |
| M11 | Lem's contract states reader-seed lexical extent and global positional order, including same-typed slides; this consumer's explicit enum/digest data is described in the current profile. |

The top-level upstream README is otherwise preserved. Existing dated
records and quoted rulings are not rewritten. No mainline, shared switch,
`deps/`, prototype or retired checkout is modified. No push, tag, merge,
history rewrite or branch/worktree deletion is performed.

## Local newcomer-path measurement

This worktree began without generated/build artifacts. To avoid downloads
and shared-switch writes, its OCaml 5.4.0 compiler/dependencies were copied
into an owned `_opam`, with separate opam metadata under `.tmp/readiness/`.
Copied environment/findlib paths were corrected in that owned copy and
`OCAMLFIND_CONF`/`OCAMLLIB` pointed at it. The exact final local environment
helper is shown below; the initial build and first unit run predate its
explicit TMPDIR override. The final Lem pin was installed
there only. This is a cold **source** build with reused dependencies, not
a fresh public dependency-install test.

A worktree-local Git config maps only the public Lem URL to the local Lem
repository for offline fetching. That substitution is explicit in the
measurement and absent from the public recipe. The fork-drift gate uses
`CERB_UPSTREAM_TREE` to read the existing upstream generated reference;
its portable setup/fallback help is scheduled for the SHOULD block.

Final local measurement helper (test adaptation only):

```bash
# Local test adaptation: copied compiler/dependencies, owned install destinations.
export OPAMROOT="$PWD/.tmp/readiness/opam-root"
export OCAMLFIND_CONF="$PWD/_opam/lib/findlib.conf"
export OCAMLLIB="$PWD/_opam/lib/ocaml"
export GIT_CONFIG_GLOBAL="$PWD/.tmp/readiness/gitconfig"
export GIT_CONFIG_NOSYSTEM=1
export CERB_MEM_MAX=32G
export LEAN_ABORT_ON_PANIC=1
export DUNE_CACHE=disabled
export CERB_UPSTREAM_TREE=/home/dev/projects/cerberus-lean-proj/deps/cerberus-upstream/ocaml_frontend/generated
export TMPDIR="$PWD/.tmp/readiness/tmp"
mkdir -p "$TMPDIR"
```

The public switch command uses `--no-install` so opam does not attempt
to build the local Cerberus packages with the upstream Lem dependency
before the fork pin is installed (opam 2.1.5 local help, 2026-09-24).

The environment controls showed that common.sh accepts an explicitly
selected opam switch with `GIT_CONFIG_GLOBAL` unset, and capped does not
source ancestor environments. The final path/install checks and build
outputs follow. Dune compilation used `DUNE_CACHE=disabled` and `--force`;
both generated trees were re-derived. Every Lean invocation was enclosed
by `scripts/capped` at `CERB_MEM_MAX=32G`. Foreign heavy jobs were waited for.

The draft native-object command initially stopped at Makefile's Dune
prerequisite check because it had not entered the selected opam environment.
The published command now prefixes `make lean-native-obj` with
`opam exec --switch=. --`, like the other Make/Dune commands. Regeneration
had already succeeded; the complete command sequence was rerun after this
recipe correction. Source builds began cold, but the corrected rerun reused
that attempt's OCaml outputs; the Lean driver had not yet been built.

Installed tools: opam 2.1.5, OCaml 5.4.0, Dune 3.23.1, Lean 4.32.2.
The source build and one-program command sequence returned **exit 0**.
The local wrapper exports the explicit copied-switch/Git configuration
above; it does not source an ancestor environment. Exact command script:

```bash
#!/usr/bin/env bash
set -euo pipefail
source .tmp/readiness/build-env.sh
opam exec --switch=. -- make prelude-src
opam exec --switch=. -- dune build --force backend/driver/main.exe cerberus-lib.install
opam exec --switch=. -- dune install --prefix "$PWD/_build/local-install" cerberus-lib
opam exec --switch=. -- dune build --force cerberus.install
opam exec --switch=. -- make lean-prelude-src
opam exec --switch=. -- ./scripts/capped make lean-native-obj
(cd lean_frontend && ../scripts/capped lake build CerberusLean cerberus-lean)
opam exec --switch=. -- env -u GIT_CONFIG_GLOBAL ./scripts/test_exec.sh tests/minimal/001-return-literal.c
```

Verbatim build/result lines:

```text
Build completed successfully (395 jobs).
[1/1] MATCH 001-return-literal: VAL:{value: "Specified(42)", stdout: "", stderr: "", blocked: "false"}
SUMMARY: total=1 match=1 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
```

The one-C run explicitly unsets `GIT_CONFIG_GLOBAL` after dependencies have
been fetched. Existing parser conflict, Lean lint/deprecation and Dune
parent-directory discovery warnings remain; none was suppressed to obtain
the pass. Raw local build log SHA256:
`fdc203e63055aac2adbd756fa789f0bf62e72d93eea4393b3795cb2fc667c15b`.


## One Lem re-pin

All Lem non-documentation changes precede this update. The opam pin, Lake
revision, every tracked Lake manifest and `scripts/fork_drift_manifest.txt`
meta line move together. A tracked-file inventory found **three** Lake
manifests at the base, rather than four: `lean_frontend/lake-manifest.json`,
`lean_frontend/speclab/lake-manifest.json`, and
`tests/mem-scale-probes/micro/lake-manifest.json`. No fourth tracked manifest
is fabricated; the consumed LemLib checkout has its own empty dependency
manifest. The fork-drift content pins move only for the reviewed common.sh
and cmm_csem.lem changes; any generated OCaml delta is inspected before a
pin change. The historical header is retained.

The first generation attempt stopped on `Cmm_csem.overlap_behaviour`:
the new fail-closed guard found 20 further dormant representations in
addition to the three initially counted. All 23 are now named unsupported
markers. This corrects the preliminary three-representation inventory in
the earlier Lem checkpoint record; that dated record is preserved. The
refusal is intentional, and no concurrency implementation or weakening of
the guard was introduced.

The owned-switch install was:

```bash
opam pin add --switch=. lem git+https://github.com/OathTech/lem-lean.git#9bb6c6b583c2eb4ecf6ca5b21a274dacc29e0fa4 --yes --no-depexts
opam exec --switch=. -- lem -v
opam pin list --switch=.
```

Exit 0; verbatim final lines:

```text
Done.
Lem 9bb6c6b5
lem.2026-05-01    git  git+https://github.com/OathTech/lem-lean.git#9bb6c6b583c2eb4ecf6ca5b21a274dacc29e0fa4
```

`lem-pin=9bb6c6b5` matches the executable's measured abbreviation, not an
assumed seven-character abbreviation. The following derived comparison
reads the earlier review scratch clone at the exact base, compares file
names and SHA256 bytes, and checks all consumed dependency revisions:

```text
reference HEAD e9f9d049ffaaf005c392495b0f6418d21f4df29f
{"tree": "ocaml_frontend/generated", "old_files": 86, "new_files": 86, "missing": [], "added": [], "changed": []}
{"tree": "lean_frontend/generated", "old_files": 219, "new_files": 219, "missing": [], "added": [], "changed": []}
lean_frontend/lake-manifest.json LemLib rev=inputRev=9bb6c6b583c2eb4ecf6ca5b21a274dacc29e0fa4
lean_frontend/speclab/lake-manifest.json LemLib rev=inputRev=9bb6c6b583c2eb4ecf6ca5b21a274dacc29e0fa4
tests/mem-scale-probes/micro/lake-manifest.json LemLib rev=inputRev=9bb6c6b583c2eb4ecf6ca5b21a274dacc29e0fa4
consumed LemLib HEAD 9bb6c6b583c2eb4ecf6ca5b21a274dacc29e0fa4
```

Thus the 86 generated OCaml files and 219 generated/copied Lean source
files are byte-identical to the reviewed base. No generated-OCaml delta
hash was refreshed. The two source-content rows are the reviewed
`common.sh` and CMM declaration edits only.


## Required gates

The MUST checkpoint uses row 1 and these six LADDER Tier A lanes: minimal,
coverage, debug, float, bytes, libc-exec. It is not the entire Tier A ladder
or a full release run. Each invocation has a timeout, captures its exit
status and runs serially with the box's other heavy jobs excluded.

The six lanes use `SKIP_BUILD=1` against the freshly recorded driver
stamps: each entry checks source/generation/binary freshness; byte/libc
helpers may also replay their build checks. `GIT_CONFIG_GLOBAL` is unset
for these runs after dependencies are available. All six return **exit 0**;
no baseline is rewritten. Baseline success includes the registered
exclusions and does not turn them into semantic agreements.

The first unit run also returned **exit 0**. Its temporary files used the
inherited container `TMPDIR`; a final repetition explicitly sets
`TMPDIR="$PWD/.tmp/readiness/tmp"` in the owned worktree, removing that
ambient workspace setting from the measurement. This changes only the
local test environment. Unit details follow.

### Unit row 1

Final owned-temporary-directory run: **exit 0**, all 15 executables and
all following gates passed. Exact local command:

```bash
source .tmp/readiness/build-env.sh; opam exec --switch=. -- ./scripts/capped ./scripts/test_unit.sh
```

Verbatim result lines (selected, not a new aggregate gate):

```text
Total: 15 passed, 0 failed
check_exec_purity: CLEAN (11 modules)
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
check_sorry_token: OK (321 files scanned comment-stripped — generated 219, hand-written+test 67, LemLib 35; 0 sorry tokens)
check_fuel_forms: forms partition OK (62 MEASURED + 13 ABSORBING + 0 ambient-reachable + 6 ambient-unreachable = 81 fuel'd workers)
check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)
check_fork_content: OK — 84 source files content/mode-pinned
check_fork_drift: OK — layer 1: 84 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 29 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 9bb6c6b5 = lem -v)
```

Verbatim final gate tail:

```text
  OK (refused as declared): s5_string_content
  OK (refused as declared): l1_string_ws
  OK (refused as declared): l3_comment_absorb
  OK (refused as declared): l4_comment_release
  OK (refused as declared): count_mismatch
  OK (refused as declared): appended_line
  OK (refused as declared): token_change
  OK (refused as declared): section_reorder
  OK (admitted as declared): strict_renumber [RENUMBER-ONLY ADMIT plant/strict_renumber class=STRICT ids=1 moved=1 canon=d7b6d3c7463e]
  OK (admitted as declared): layout_rewrap [RENUMBER-ONLY ADMIT plant/layout_rewrap class=LAYOUT ids=2 moved=2 canon=9b2ed22f1988]
  OK (refused as declared): crlf_string
  OK (admitted as declared): crlf_code [RENUMBER-ONLY ADMIT plant/crlf_code class=LAYOUT ids=1 moved=1 canon=8c8910c71fce]
test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)
```

Raw final local log SHA256: `a93d8b14ae59ae34602751336b63c2c7454e7709a15658f849c929d64bd002f0`.
The 305.44-second wall interval includes pauses for foreign work and is
not a performance measurement. The earlier unit pass log SHA256 is
`0451533e370cd5a7110a273d7d76229f681098185fc237cb0e4b29d688afd9f3`.


### minimal

Exact local command; exit 0:

```bash
source .tmp/readiness/build-env.sh; opam exec --switch=. -- env -u GIT_CONFIG_GLOBAL SKIP_BUILD=1 ./scripts/capped ./scripts/test_exec.sh --check-baseline
```

Verbatim gate tail:

```text

SUMMARY: total=113 match=90 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=5 cerb_floor=0 cerb_inconsistent=0

Checking against baseline: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-cleanup-public-readiness-20260924/scripts/exec_baseline.txt

Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
```

Raw local log SHA256: `c01117b68be6d2a41403548e604cc8190738ee099730d037019dc92afecff7ac`.

### coverage

Exact local command; exit 0:

```bash
source .tmp/readiness/build-env.sh; opam exec --switch=. -- env -u GIT_CONFIG_GLOBAL SKIP_BUILD=1 ./scripts/capped ./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage
```

Verbatim gate tail:

```text

SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0

Checking against baseline: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-cleanup-public-readiness-20260924/scripts/exec_coverage_baseline.txt

Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
```

Raw local log SHA256: `47a391449ec0369b47a9eb3ee598d6da9daaaaf6ec892333f7e649c6d6576b84`.

### debug

Exact local command; exit 0:

```bash
source .tmp/readiness/build-env.sh; opam exec --switch=. -- env -u GIT_CONFIG_GLOBAL SKIP_BUILD=1 ./scripts/capped ./scripts/test_exec.sh --check-baseline=scripts/exec_debug_baseline.txt tests/debug
```

Verbatim gate tail:

```text

SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0

Checking against baseline: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-cleanup-public-readiness-20260924/scripts/exec_debug_baseline.txt

Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
```

Raw local log SHA256: `e432923306f66698dd7ec1324ff043f78521f8f047fa30a11ff559f35d9fbc35`.

### float

Exact local command; exit 0:

```bash
source .tmp/readiness/build-env.sh; opam exec --switch=. -- env -u GIT_CONFIG_GLOBAL SKIP_BUILD=1 ./scripts/capped ./scripts/test_exec.sh --check-baseline=scripts/exec_float_baseline.txt tests/float
```

Verbatim gate tail:

```text

SUMMARY: total=93 match=93 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0

Checking against baseline: /home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-cleanup-public-readiness-20260924/scripts/exec_float_baseline.txt

Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
```

Raw local log SHA256: `9af48f4c415610606c3d621f588bb32c461720312f71b9ea2033886dce4a83f2`.

### bytes

Exact local command; exit 0:

```bash
source .tmp/readiness/build-env.sh; opam exec --switch=. -- env -u GIT_CONFIG_GLOBAL SKIP_BUILD=1 ./scripts/capped ./scripts/test_bytes.sh
```

Verbatim gate tail:

```text
SUMMARY: exec_match=9 neg_pinned=5 fail=0
ALL AT COMMITTED EXPECTEDS
```

Raw local log SHA256: `8aef23cdc247da95929a785abba9b7acfafaa617d09f00891e58f3f520a72abf`.

### libc-exec

Exact local command; exit 0:

```bash
source .tmp/readiness/build-env.sh; opam exec --switch=. -- env -u GIT_CONFIG_GLOBAL SKIP_BUILD=1 ./scripts/capped ./scripts/test_libc_exec.sh
```

Verbatim gate tail:

```text
SUMMARY: match=12 diff=0
ALL MATCH RECORDED BASELINE
```

Raw local log SHA256: `9aa0960493fc3b10d370f758d67d3d63ff330f1e1b7c96ea0cec712cbe1f811a`.


## Operator publication checks and next block

The next operator review is the complete cleanup range from each stated
base to `cleanup/public-readiness-20260924`. Each merge requires its own
operator sign-off after that delta review and must be fast-forward-only.
No merge is performed here. Publication must make Lem revision
`9bb6c6b583c2eb4ecf6ca5b21a274dacc29e0fa4` fetchable before advertising the
Cerberus recipe that consumes it.

After the approved commits are published, use a new directory with Git
redirects disabled and no cached credentials:

```bash
GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 \
  timeout 30s git ls-remote --symref https://github.com/OathTech/cerberus-lean.git \
  HEAD refs/heads/mdd/cerberus-lean
GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 \
  timeout 30s git ls-remote --symref https://github.com/OathTech/lem-lean.git \
  HEAD refs/heads/mdd/lean-backend
GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 \
  timeout 180s git clone --branch mdd/cerberus-lean \
  https://github.com/OathTech/cerberus-lean.git public-cerberus-check
GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0 \
  timeout 180s git clone --branch mdd/lean-backend \
  https://github.com/OathTech/lem-lean.git public-lem-check
timeout 10s git -C public-lem-check cat-file -e 9bb6c6b583c2eb4ecf6ca5b21a274dacc29e0fa4^{commit}
```

Then execute the README with fresh opam/Lake state. A `ls-remote` result
alone does not establish complete dependency installation or a build.
The new pin is intentionally unpublished at this checkpoint; announcing
before it is fetchable would leave the build broken for newcomers.

Stop here before the remaining SHOULD block: S1 and S3–S8 remain.
S2 (fork issue-reporting links) was completed alongside both build pages;
this supersedes the earlier Lem checkpoint's tracker-follow-up wording. The companion Lem
record extends the ledger with S9 (enforcing totality by default), S10
(portable fork-drift prerequisites and the remaining unshipped
`env.sh`/`scripts/ce` recipes in freshness/sync diagnostic help), and S11 (qualified core-name import
handling found while updating a Lem fixture). M1b, documenting the
intentional cap fallback, is already included in the new build pages. No audit/merge approval is
requested until there is a concrete range for the operator's delta review.
[AGENT] Before announcing, complete the remaining current-document
reconciliation in the SHOULD block, the public fetch/build checks, and
notice resolution. Announce the experimental supported profile; this
checkpoint does not establish a stable release. Any tag or
upstream notice is a separate operator publication action; none is sent.
