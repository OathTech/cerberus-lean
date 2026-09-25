# Public-readiness SHOULD follow-up — 2026-09-25

[USER 2026-09-25]: “Great. Can you pick up the rest (SHOULD work, M8/M9, and hash-bearing version output at exact release tags) on new branches starting at the final heads here. The overseer agent is handling the landing”

[AGENT] Prepared by OpenAI Codex under operator direction; independent overseer review and landing are separate. This work starts at Cerberus `c13a1054133b49c954fe27ac4c1b4e33a418c51f`
and Lem `6b20bfd02de924d078725efa96c6675115b8b17a`, on new same-named
`cleanup/public-readiness-should-20260925` branches/worktrees. The overseer
owns landing. No mainline commit, merge, push, release tag, branch/worktree
deletion, shared-switch install or upstream message is performed here.
The earlier dated records and operator quotations remain unchanged.

## Dispositions

| Item | Change | Scope / check |
|---|---|---|
| S1 | Current TODO, VALIDATION and agent-manual text now describe delivered digest/enum work, sorry refusal, closed pending workers, the current cerberus-sl consumer and the failed/parked SC prototype. | Original dated plans and quoted rulings remain records. No current product or announcement depends on the prototype. Dead memory fuel binders remain an actual open item. |
| S2 | Fork issue links and reporting inputs remain prominent; SUPPORTED now carries them inline. | Anonymous issue-creation banner still requires an operator check (M9). |
| S3 | Root badges and inherited workflows explicitly identify upstream OCaml/CHERI coverage. | No fork Lean Actions workflow or full certification is claimed; manual evidence is linked. |
| S4 | Tray index has a per-report Draft/Sent/Filed/Closed table. VALIDATION distinguishes prepared reports from filing and identifies the unenforced external policy condition. | Derived from committed records: 49 reports, 48 Draft, 0 Sent, 1 Filed, 0 Closed. No new upstream message or fresh whole-tray GitHub census. |
| S6 | Roots parsing, sorting and comparison share LC_ALL=C; command errors fail the gate. | Four plants, including failing comm, plus a clean baseline under en_US.utf8. |
| S7 | Both repositories' branches/worktrees are classified in the Lem follow-up inventory. | Advisory only; no deletion, no operation on retired/dependency checkouts. |
| S8 | README/SUPPORTED/LADDER and the README-linked agent manual distinguish one-program smoke, row 1 plus six small lanes, all Tier A, full A+B and reporting campaigns. | Public cap prerequisites, toolchain differences and independent-oracle provisioning are explicit. |
| S9 | Totality defaults to enforce; ENFORCE=0 is labelled report-only; invalid modes and missing allowlists fail. | Eight planted cases and two clean controls; tests wired into row 1. |
| S10 | Remove the absolute/container fallback for fork drift and the hard Git-config prerequisite in ci_lean.sh; use public remotes and repository-local remediation commands. | CERB_UPSTREAM_TREE is explicit. Missing prerequisites remain fatal. Three help-only tool edits receive reviewed source-content pins. |
| Version | Existing OCaml version output keeps the hash at annotated tags; date is read from HEAD. | Production generator tested with isolated tags; tools/gen_version.ml is added to the fork-drift source surface (85 source files, derived). No new Lean-driver CLI is introduced. |
| M8 | Consume the Lem runtime whose donor linking exception, base-license metadata and installed notices have been reconciled. | Refer to Lem NOTICE.md and LICENSE for per-file scope; no new licensing grant. |
| M9 | Verify public web pages; attempt anonymous Git transport without redirects/credentials; provide exact post-publication checks. | Anonymous Git and clean dependency downloads remain UNVERIFIED-OFFLINE because of the proxy failures, not a finding of private/unavailable repositories. |

## Build isolation and pin sequencing

All Lem non-documentation changes are committed before the one new Cerberus
re-pin in this round. Three committed Lake JSON manifests plus the Lakefile
carry the runtime revision; the installed opam Lem in the owned validation
switch and the fork-drift meta line must agree. The earlier instruction's
“four manifests” is not a fourth tracked Lake JSON file: `git ls-files
'*lake-manifest.json'` lists three in this base.

The new worktree uses a physical copy of the previous owned OCaml switch,
an owned OPAMROOT/findlib configuration, and copied Lake cache. It has no
pre-existing OCaml generated source/build tree. Both model trees are
regenerated, Dune cache is disabled and builds use --force; the native object
is built explicitly before Lake. The source build is new; dependency download
is not. The prior generated Lean tree is copied only to exercise the cheap
instrument plants before regeneration, and is compared after regeneration.

A local Git redirect is confined to the owned validation configuration so
opam/Lake can fetch unpublished Lem commits from the local object store.
The actual newcomer test runs with GIT_CONFIG_GLOBAL unset; installed tools
and sources still come from the owned environment. This establishes that the
scripts need no container Git-config sentinel, not that anonymous networking
or an empty dependency cache has passed. Every Lake/Lean command is capped
at 32G; one heavy job is admitted at a time, pausing for foreign builds.

## M9 and announcement exits

Anonymous web pages observed 2026-09-25:
[OathTech/lem-lean](https://github.com/OathTech/lem-lean) and
[OathTech/cerberus-lean](https://github.com/OathTech/cerberus-lean) are public
and land on the two mdd fork branches. This does not establish published
cleanup commits or successful Git/opam/Lake fetches. The issue pages show
“Issue creation is restricted in this repository”; the operator was asked
to check external issue creation while signed in. No settings were changed.

The Lem follow-up record carries the exact anonymous ls-remote commands and
verbatim proxy failures (both rc 128). The resulting external exits are:

- publish the reviewed heads in the overseer's order and verify anonymous
  branch/default-ref and exact Lem-pin fetches with redirects disabled;
- run each README from a fresh public clone and an empty dependency setup,
  including native-object construction and one C program;
- verify that external users can follow the advertised fork issue routes;
- after the operator's release decision, verify annotated alpha tags and
  hash-bearing binary versions. Candidate names remain
  `lean-backend-v0.1.0-alpha.1` and `cerberus-lean-v0.1.0-alpha.1`;
- upstream notice/submission is separate operator work, with AI provenance.

The executed gates and exact implementation pins are recorded below.
No full Tier A+B/C certification is claimed.


## Pinned Lem handoff and exact public checks

The one follow-up Lem pin is `67ec5de70e02e280bb348a4ba826696b76116732`,
after all its implementation and documentation commits. Its measured source
implementation is `fd048dbaeed9e0031496aa6ae4a56bb20c07841a`.
[Its follow-up record](https://github.com/OathTech/lem-lean/blob/67ec5de70e02e280bb348a4ba826696b76116732/doc/lean-backend/2026-09-25_public-readiness-followup.md)
carries M8 provenance, gate commands, the version/import repairs, and two
additional defects exposed by isolation: an exported OCAMLLIB collision and
premature extraction of a closed fuelExhausted sentinel. The latter is fixed
with never_extract on the public wrapper; strict native parity is now gated.
Compiler/setup failures can no longer count as registered XFAILs. Derived
Lem counts are 36 parity probes total, comprising 32 successes and four
registered differences (the record corrects an erroneous commit-message count).

[Branch/worktree inventory](https://github.com/OathTech/lem-lean/blob/67ec5de70e02e280bb348a4ba826696b76116732/doc/lean-backend/2026-09-25_branch-worktree-inventory.md):
derived snapshot counts are Lem 14 branches / 7 worktrees, Cerberus 53 / 22.
Operator deletion choices remain open; no cleanup action is implied by ancestry.

For the anonymous clone/default-ref checks, run the exact block in the Lem
record from a new directory outside existing checkouts. Then verify the
consumer's exact runtime pin rather than guessing that a similarly named
branch or upstream opam package is sufficient:

```bash
# From public-readiness-check after the two anonymous clones:
test "$(sed -n 's/^rev = "\([0-9a-f]*\)"/\1/p' cerberus-lean/lean_frontend/lakefile.toml)" = 67ec5de70e02e280bb348a4ba826696b76116732
git -C lem-lean cat-file -e 67ec5de70e02e280bb348a4ba826696b76116732^{commit}
```

After the operator has actually published the chosen annotated alpha tags,
these are the exact anonymous checks for the proposed names (use the chosen
names if the operator selects different ones):

```bash
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_COUNT=0 GIT_TERMINAL_PROMPT=0
unset GIT_CONFIG_PARAMETERS GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE
timeout 60s git -c credential.helper= ls-remote --tags https://github.com/OathTech/lem-lean.git refs/tags/lean-backend-v0.1.0-alpha.1 'refs/tags/lean-backend-v0.1.0-alpha.1^{}'
timeout 60s git -c credential.helper= ls-remote --tags https://github.com/OathTech/cerberus-lean.git refs/tags/cerberus-lean-v0.1.0-alpha.1 'refs/tags/cerberus-lean-v0.1.0-alpha.1^{}'
timeout 180s git -C lem-lean -c credential.helper= fetch origin tag lean-backend-v0.1.0-alpha.1
timeout 180s git -C cerberus-lean -c credential.helper= fetch origin tag cerberus-lean-v0.1.0-alpha.1
test "$(git -C lem-lean cat-file -t refs/tags/lean-backend-v0.1.0-alpha.1)" = tag
test "$(git -C cerberus-lean cat-file -t refs/tags/cerberus-lean-v0.1.0-alpha.1)" = tag
git -C lem-lean checkout --detach lean-backend-v0.1.0-alpha.1
git -C cerberus-lean checkout --detach cerberus-lean-v0.1.0-alpha.1
```

Rebuild both tagged checkouts using their README recipes and retain their
version outputs beside `git rev-parse HEAD`. No currently published tag or
empty-cache install is asserted by this local follow-up.


## Fresh local fork-drift prerequisite

To validate the S10 provisioning recipe independently of the container's
standing generated tree, a scratch clone was made from the local Cerberus
object store, detached at `b9aeedcb4dd438763b0eef7f95ac19e93875d7de`, then
`make prelude-src` ran with the owned switch's Lem `67ec5de7`. The local
source URL substitutes for the public clone/fetch step only. The unit run's
CERB_UPSTREAM_TREE points to this new output, not deps/cerberus-upstream.
The public URL and empty dependency-download legs remain M9 external checks.

The regenerated fork outputs are byte-identical to the previous closure:
**derived:** 219 Lean files and 86 OCaml files, no added/removed/changed file.
Source hash `b2a78090bb9617fa5067c54145df8d775669571e30f0c9629539031975dc6e16`,
OCaml generated hash `b79e328e77aa6c784c2ef260b341c98c473a35bf1e1d1523b73680949ba41d9e`,
Lean generated hash `f4893e95ac3462defae87f737580b172f4e4e1cf35941d5be07edd82c8df808e`.
LemLib itself changes the native extraction attribute; unchanged generated
model text does not mean the runtime dependency was unchanged.

The opam-installed LICENSE and NOTICE match the final Lem checkout byte for
byte. The consumed Lake package's LemLib.lean also matches that checkout;
its Git HEAD is the full pinned revision. No shared-switch installation was
used for these checks.


### S10 launcher admission correction

The first combined unit command reached its final CI-list smoke step and
failed there, after row 1 had returned zero:

```text
bash: line 1: ./scripts/ci_lean.sh: Permission denied
```

Inspection established that Git tracked this launcher as mode 100644. The
follow-up makes it 100755, matching the documented direct invocation, then
reruns row 1 and the differential set. The nono diagnostic skill was consulted;
its standalone `why` reported path_not_granted, but the readable file and
Git's missing executable bit established a concrete repository defect.
No sandbox/profile setting was changed. The initial compound command's rc 126
is retained and is not relabelled as a successful combined run.

## Executed build and gate commands

The scratch `build-env.sh` selects the owned OPAMROOT, OCAMLFIND_CONF,
OCAMLLIB and local-only Git redirect described above, sets
`CERB_MEM_MAX=32G`, `LEAN_ABORT_ON_PANIC=1`, `DUNE_CACHE=disabled`, an
owned TMPDIR and the fresh local CERB_UPSTREAM_TREE. The runner places
each command under `timeout`, admits only one heavy job and retains stdout
and stderr in `.tmp/readiness/`. It does not change shared configuration.
Commands below are the executed commands, including local validation
adaptations; they are not a claim to have fetched the public sources.

Single owned-switch re-pin, followed by the source build (rc 0, 266.75 s):

```bash
set -euo pipefail
source .tmp/readiness/build-env.sh
test "$(opam var prefix --switch=.)" = "$PWD/_opam"
opam pin add --switch=. lem git+https://github.com/OathTech/lem-lean.git#67ec5de70e02e280bb348a4ba826696b76116732 --yes --no-depexts
opam exec --switch=. -- lem -v
bash .tmp/readiness/cold-build.sh
```

Contents of the executed `cold-build.sh`:

```bash
#!/usr/bin/env bash
set -euo pipefail
source .tmp/readiness/build-env.sh
opam exec --switch=. -- make prelude-src
opam exec --switch=. -- dune build --force backend/driver/main.exe cerberus-lib.install
opam exec --switch=. -- dune install cerberus-lib
opam exec --switch=. -- dune build --force cerberus.install
opam exec --switch=. -- make lean-prelude-src
opam exec --switch=. -- ./scripts/capped make lean-native-obj
(cd lean_frontend && ../scripts/capped lake build CerberusLean cerberus-lean)
opam exec --switch=. -- env -u GIT_CONFIG_GLOBAL ./scripts/test_exec.sh tests/minimal/001-return-literal.c
```

The local fork-drift prerequisite was built with:

```bash
source .tmp/readiness/build-env.sh
git clone --no-hardlinks --no-checkout "$PWD" .tmp/readiness/fork-drift-upstream
git -C .tmp/readiness/fork-drift-upstream checkout --detach b9aeedcb4dd438763b0eef7f95ac19e93875d7de
opam exec --switch="$PWD" -- make -C .tmp/readiness/fork-drift-upstream prelude-src
```

Final unit command after the launcher mode correction (rc 0, 254.61 s):

```bash
set -euo pipefail
source .tmp/readiness/build-env.sh
opam exec --switch=. -- env -u GIT_CONFIG_GLOBAL ./scripts/capped bash -c "set -e; LC_ALL=en_US.utf8 ./scripts/check_lakefile_roots.sh --selftest; ./scripts/check_fork_drift.sh --selftest; ./scripts/test_unit.sh; ./scripts/ci_lean.sh --list"
```

Verbatim selected unit output:

```text
Total: 15 passed, 0 failed
check_lakefile_roots: SELFTEST OK (4 plants red, baseline green)
test_version: OK (untagged, exact annotated tag, dirty tag, post-tag, archive fallback)
test_exec_totality: OK (8 plants and 2 clean controls)
check_fork_drift: OK — layer 1: 85 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 30 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 67ec5de70e02e280bb348a4ba826696b76116732 matches lem -v 67ec5de7 (hex prefix))
test_renumber_plants: OK (12 plants: refusals refuse, admits admit with declared class)
```


The following eleven commands ran sequentially after the final unit run.
Each command was preceded by `source .tmp/readiness/build-env.sh` and
wrapped in a separate 1800-second timeout by the owned runner. SKIP_BUILD
requests reuse where a lane supports it; freshness checks still run, and
lanes that unconditionally build retain that behavior.

```bash
opam exec --switch=. -- env -u GIT_CONFIG_GLOBAL SKIP_BUILD=1 ./scripts/capped ./scripts/test_exec.sh --check-baseline
opam exec --switch=. -- env -u GIT_CONFIG_GLOBAL SKIP_BUILD=1 ./scripts/capped ./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage
opam exec --switch=. -- env -u GIT_CONFIG_GLOBAL SKIP_BUILD=1 ./scripts/capped ./scripts/test_exec.sh --check-baseline=scripts/exec_debug_baseline.txt tests/debug
opam exec --switch=. -- env -u GIT_CONFIG_GLOBAL SKIP_BUILD=1 ./scripts/capped ./scripts/test_exec.sh --check-baseline=scripts/exec_float_baseline.txt tests/float
opam exec --switch=. -- env -u GIT_CONFIG_GLOBAL SKIP_BUILD=1 ./scripts/capped ./scripts/test_bytes.sh
opam exec --switch=. -- env -u GIT_CONFIG_GLOBAL SKIP_BUILD=1 ./scripts/capped ./scripts/test_libc_exec.sh
opam exec --switch=. -- env -u GIT_CONFIG_GLOBAL SKIP_BUILD=1 ./scripts/capped ./scripts/test_multi_tu.sh
opam exec --switch=. -- env -u GIT_CONFIG_GLOBAL SKIP_BUILD=1 ./scripts/capped ./scripts/test_multi_tu.sh --failure-class-projection tests/multi_tu_tray
opam exec --switch=. -- env -u GIT_CONFIG_GLOBAL SKIP_BUILD=1 ./scripts/capped ./scripts/test_address_space.sh --selftest
opam exec --switch=. -- env -u GIT_CONFIG_GLOBAL SKIP_BUILD=1 ./scripts/capped ./scripts/test_address_space.sh
opam exec --switch=. -- env -u GIT_CONFIG_GLOBAL SKIP_BUILD=1 ./scripts/capped ./scripts/test_immaculate.sh
```

**Derived timing table** (seconds as recorded by the runner; every exit 0):

| Lane | Seconds |
|---|---:|
| minimal | 28.30 |
| coverage | 52.54 |
| debug | 22.23 |
| float | 24.25 |
| bytes | 4.04 |
| libc-exec | 24.25 |
| multi-tu | 4.04 |
| multi-tu-tray | 4.04 |
| address-space-selftest | 6.06 |
| address-space | 6.06 |
| immaculate | 72.77 |

Verbatim selected lane tails, in the command order above:

`minimal`:

```text
SUMMARY: total=113 match=90 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=5 cerb_floor=0 cerb_inconsistent=0
BASELINE OK
```

`coverage`:

```text
SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0
BASELINE OK
```

`debug`:

```text
SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0
BASELINE OK
```

`float`:

```text
SUMMARY: total=93 match=93 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
BASELINE OK
```

`bytes`:

```text
SUMMARY: exec_match=9 neg_pinned=5 fail=0
ALL AT COMMITTED EXPECTEDS
```

`libc-exec`:

```text
SUMMARY: match=12 diff=0
ALL MATCH RECORDED BASELINE
```

`multi-tu`:

```text
SUMMARY: total=2 match=2 fail=0
ALL PASSED
```

`multi-tu-tray`:

```text
SUMMARY: total=7 match=7 fail=0
ALL PASSED
```

`address-space-selftest`:

```text
test_address_space: SELFTEST OK (14 plants — P1 the discriminator's derived pre-fix observation, P2 missing file, P3 truncated, P4 phantom row, P5-P7 phantom/duplicate/malformed rows without a final newline all REJECTED; P8 the valid file without a final newline ACCEPTED; P9/P10 the out-of-domain and non-decimal tops REFUSED on both engines, P11 a decimal top accepted; P12/P13 underscore-separated spellings REFUSED on both, P14 2^64 - 1 ACCEPTED on both; the committed file green)
```

`address-space`:

```text
test_address_space: OK (18 cases: LEAN = FORK through the shared codec at tops 64 32 8; every fork observation = its pinned row in expectations.txt)
```

`immaculate`:

```text
OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH, R5 r5-hex-subnormal-double-rounding DIFF — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
```

The immaculate baseline includes the named registered differences and
failure observations above; its green exit does not classify them as
semantic agreements. No corpus baseline or generated-difference exception
was refreshed for this follow-up.

## Final measured handoff

Cerberus implementation commit: `4e875defb0cce250e841723c1be7ecb7c2240150`.
Lem consumed commit: `67ec5de70e02e280bb348a4ba826696b76116732`.
The gates ran on the working-tree implementation subsequently committed as
`4e875defb0cce250e841723c1be7ecb7c2240150`; only current-facing documentation
and this record change in the following commit. The binaries built during
that run reported the then-current source checkout (the base commit plus
`-dirty`), not an invented future commit identity. The isolated version
tests verify the real production generators at exact annotated tags;
actual public tag checkouts and rebuilt binary output remain the M9 exit.

The README-linked `lean_frontend/CLAUDE.md` also had stale container-only
build steps, a missing native-object step, an exe-only Lake build and a
“no OCaml” description of row 1. Its current instructions now follow the
public recipe, require the full roots build and point to the explicit
fork-drift prerequisite. The old SC integration and all-state-in-St claims
are reconciled with SUPPORTED and the pinned Lem design. This is a
documentation-only S1/S5/S8 follow-up; the container-level CLAUDE.md remains
outside this branch.

The non-documentation Cerberus footprint comprises the roots, totality,
fork-drift and CI-launcher scripts; two admission tests and their row-1
wiring; three help-only freshness/sync scripts; the version generator;
the fork-drift manifest; and the Lakefile plus three JSON manifests. The
README's opam pin was committed with these so no intermediate committed
pin set disagrees. All Lem non-documentation changes precede this single
re-pin. No model source or hand-written Cerberus Lean runtime changed.

The local environment used OCaml 5.4.0, opam 2.1.5, Dune 3.23.1 and
Cerberus Lean 4.32.2; Lem's own library tests used Lean 4.28.0. Copied
packages and cached Lake dependencies are explicitly part of this local
validation setup, not hidden evidence of a clean internet installation.

**[AGENT] Verdict:** the SHOULD remediations, M8 notice reconciliation and
hash-bearing version generators are ready for independent review and the
overseer's landing sequence. The required local gates and the additional
lanes above are green. The public announcement still needs M9's anonymous
fetch/exact-pin/empty-dependency-install checks, confirmation of the advertised
issue-reporting routes and, if chosen, published-tag verification. This is
an early sequential semantics/backend announcement, not full C support,
universal runtime correspondence, concurrency support or a complete release
ladder certification. No mainline, shared switch, project tag or project remote was
changed by this follow-up.

Local raw logs are not tracked archives. The committed commands and verbatim
excerpts above are the portable record. Log SHA-256 identities:

| Local log under `.tmp/readiness/` | SHA-256 |
|---|---|
| `followup-repin-build.log` | `6ed6ba3f8a69c7e245237aadbeae466401e85764f79559f0fc25d036cb66c876` |
| `followup-unit.log` | `fc156ac51f3c2910f6ca3fdd3a7f00d9071f5b1753d27f0f7030d31bed550a1e` |
| `followup-unit-final.log` | `5a29c8def2caa58fffdb4a3a17b462de851d45141e339c638a7e80b6f7744c5b` |
| `followup-cerb-minimal.log` | `6c3d56ce2402df12f5dad67f84b2efddf49573cac4acfbc0b5da7ff39106c27f` |
| `followup-cerb-coverage.log` | `8b287e2ec8ef36c32192e6e3535461295cfd8788b907f89460b6c5f93e686eeb` |
| `followup-cerb-debug.log` | `b124f0d9db59afad91153ac6e2d0988d8a3438dab2c4372494af8dbca1f4d511` |
| `followup-cerb-float.log` | `fcce2c3622700e0e4357e4a93304bb0489b025ff0b5231411a81fb2ca2ce6d30` |
| `followup-cerb-bytes.log` | `11296f8cd4c24f878e0506a4a3f50022cb391eac3a19f9c574d34201b97d1367` |
| `followup-cerb-libc-exec.log` | `4db848a8b71ff35037eba0d087c1d134503dd70cec0f691f98b0be2b7732b7e3` |
| `followup-cerb-multi-tu.log` | `9fb87a84de7869c672e1bb6d023f688ca5abb68f4fa8725d07971caff9db185a` |
| `followup-cerb-multi-tu-tray.log` | `0358859c52826fc51a965591ffa6e10c1510fc27e83d64009fe98a271476d9f0` |
| `followup-cerb-address-space-selftest.log` | `b15e49c978cd3d2ad0ceca00b1212af7aaec518a58c1868e7784ceb4265a2cea` |
| `followup-cerb-address-space.log` | `0591835aff017886f6a63aee589c8479a05dd4f5bc31fdb31a92231248baa2e9` |
| `followup-cerb-immaculate.log` | `af3930afae0cd398dac9e5b8ff295b2ec30ce4d12aa081b4281b2481e4d1f621` |

## Landing (2026-09-25) — orchestrator [AGENT]

[USER 2026-09-25] verbatim: "Great, go ahead with the whole merge and sweep as proposed" (the proposal: the four merge
steps below plus a P3 docs sweep, a cerberus-sl consumer note, and retiring the finished worktrees). Executed back to back:

1. lem-lean `mdd/lean-backend` ff-only `6b20bfd` -> `67ec5de` (3 commits: M8 notices/opam/install, S8/S11–S13/version,
   S1–S5/S7–S8/M9 docs). No lem-side landing commit, so the lem mainline head equals every pin.
2. Shared-switch re-pin: `deps/lem-pinned` `6b20bfd` -> `67ec5de`; `make rebuild-lem` -> `[LEM] installed Lem 67ec5de`;
   the switch's `lem -v` = `Lem 67ec5de`. Another session's `release.py --mode full` was running at the time; the new lem
   changes no generated code (both trees byte-identical to the previous mainline's under it, orchestrator-verified), so
   an older cerberus head regenerating against it would only trip the fork-drift pin check.
3. Re-gate of this branch's rebased head `5d3079184` against the SHARED switch's lem, verbatim: `Total: 15 passed, 0
   failed`; `test_version: OK (untagged, exact annotated tag, dirty tag, post-tag, archive fallback)`;
   `test_exec_totality: OK (8 plants and 2 clean controls)`; `check_failure_reach: OK (239 …`; `check_fork_drift: OK —
   layer 1: 85 oracle-surface files = manifest … layer 2: 30 differing generated files, all hash-pinned (… lem-pin
   67ec5de70e02e280bb348a4ba826696b76116732 matches lem -v 67ec5de (hex prefix))`; `ROW1 EXIT=0`.
   Earlier the same day, at the pre-rebase head `57ed81ca7` with an in-tree lem built from `67ec5de` (PATH-first): both
   generated trees wiped and re-derived — byte-identical to mainline's; dune --force / install --prefix / cerberus.install /
   native-obj / lake (395 jobs) all EXIT=0; row 1 and all ten differential lanes green (minimal 113 = 90/18/5, coverage 212,
   debug 90, float 93/93, bytes 9 + 5, libc 12/12, multi-TU 2/2 and 7/7, address space 18, immaculate at baseline; every
   `Baseline check: 0 regression(s), 0 improvement(s)`).
   The rebase `57ed81ca7` -> `5d3079184` onto mainline `8de1cf443` was performed by the orchestrator (the two range
   commits content-identical by `git range-diff`; the only difference the two docs-only landing commits beneath).
4. cerberus-lean `mdd/cerberus-lean` ff-only `8de1cf443` -> this commit (the rebased SHOULD head + this landing note).
   Post-landing: primary checkout regenerated from wiped trees, rebuilt, row 1 + lanes (tails in the orchestrator note §10).

Independent reviews of this range (Claude Fable, third pass): lem-lean `7b8af28` on `audit/public-readiness-must-20260924`
("Merge-ready as is at 67ec5de"; P3 T1–T3), cerberus `a42564363` on `audit/public-readiness-must-20260924` ("No P1 or P2";
P3 G1–G3; A1 = GitHub "Issue creation is restricted in this repository" — operator action before announcing; G5 = the
ISO-fix register's "filed upstream" criterion is unmet — operator decision). The P3s are closed by the sweep that follows
this landing; the review documents are brought onto both mainlines by that sweep.

## Sweep addendum (2026-09-25, orchestrator [AGENT])

Review G3: the executed `cold-build.sh` above ran `dune install cerberus-lib` WITHOUT `--prefix` — a LOCAL test adaptation
inside the remediator's owned copy of the switch (it installs into that owned copy, never the shared switch); the PUBLIC
recipe in `lean_frontend/README.md` keeps `--prefix "$PWD/_build/local-install"`. Review G2/F11: the front pages cited
`4e875defb…`, the pre-rebase SHOULD implementation commit; after the orchestrator's rebase the landed commit is
`bb487dda7`, and every citation now names it. Review G1: `check_fork_drift.sh`'s `--refresh` help text no longer refers
to the container's `scripts/env.sh`. Container consequence of S10 (orchestrator, not a repo change): the fork-drift gate
now REQUIRES `CERB_UPSTREAM_TREE`; the container's `scripts/env.sh` exports it (first post-landing row 1 on the primary
checkout was red for exactly this reason; rerun green). The lem pin moves once more, to the lem-lean sweep head
`c2a68e79b6369e19f099dfa48767319c1daf19b3` (comment/notice/record changes + the delta-review documents; no generated
code change).
