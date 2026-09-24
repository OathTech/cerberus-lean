# Public-readiness MUST closure — Cerberus consumer

2026-09-24. [AGENT] Closure of the review adjudicated in orchestrator note
`aab00b9b6`, `2026-09-24_public-readiness-must-checkpoint-orchestrator-note.md`
§6 (on its separate documentation branch, not merged here).
Prior reviewed head: `0a6d59eedd21cb9b8754000b225b07219676dfa0`.
Implementation measured: `603c9b69bd056cbffeca8a669bc3510a4349f882`. Consumer Lem pin:
`6b20bfd02de924d078725efa96c6675115b8b17a` (Lem implementation `292db8b0e2a905031c797f08ebbe692a535c66c4`).
The documentation commit containing this record does not alter those code bytes.

## Closure findings

| Finding | Result at the implementation pin |
|---|---|
| F1 / M1 portability | The manifest stores a full 40-hex Lem commit. The gate validates and compares 7–40 hex prefixes from bare hashes or hash-bearing Git describe versions, after removing one trailing `-dirty`. Malformed, too short/long, wrong and duplicate pins fail. `--refresh` requires a matching version and preserves the full reviewed pin. Thirty self-test plants pass with expected verdicts and messages, including refresh retention. |
| F2 / M10 | [Archive record](2026-09-24_evidence-archive-untracking.md) gains an append-only provenance addendum: derived inventory tagged [AGENT], verbatim [USER 2026-09-06] retention excerpt, and the already-pushed-history limitation. Original body and inventory remain intact. |
| F3 / M4 | An in-file FORK comment explains the 23 excluded CMM markers and absence of concurrency implementation. The comment occupies three pre-existing blank lines, preserving source diagnostic locations. |
| F6 | [SUPPORTED.md](../SUPPORTED.md) cites the actual [USER 2026-09-16] retirement ruling for refined-cerberus. |
| Closure re-pin | All five committed source sites agree: Lake requirement, three manifests, fork-drift metadata. The README install command also carries the new pin. One dependency revision move occurred after all Lem closure changes; the owned opam switch was updated once. |

[AGENT] A version prefix identifies a commit; stripping `-dirty` is not a
clean-source attestation. A bare tag contains no hash and is intentionally
rejected. Before tagging, arrange a reviewed hash-bearing Lem version at
exact tags (for example, a separately reviewed `git describe --long` change)
and check the build from the tag. Lem's version-generation Makefile is
unchanged in this closure. This remains a tag-preparation follow-up.

## Generated-output review

[AGENT] Derived comparison against the prior checkpoint: all **219 Lean
files under generated/** are byte-identical (170 Lem outputs plus 49 copied
hand-written files). Of **86 OCaml files**, only `cmm_csem.ml` differs: the
three-line FORK explanation replaces three blank lines. Blanking that exact
comment, retaining its line breaks, reproduces the prior and pristine-upstream
file byte-for-byte. Thus the fork-drift manifest adds exactly one
`[expected-cosmetic]` row, SHA256 of the label-normalized diff:
`e0a1740dc4f5a18b91e7d6cc7cde9d5f4189e74ab9ed2c2217fdc8c4dac9a185`.
The source-content pin for `cmm_csem.lem` moves. No pre-existing generated-diff
pin is refreshed; the manifested differing-file count becomes 30 (was 29).

An initial comment placement inserted six lines and shifted CMM diagnostic
locations in generated Lean. That intermediate build passed, but was not
used for closure certification. The comment was fitted into existing blank
lines, both trees regenerated again, and all gates below ran afterward.
Local comparison receipts: `.tmp/readiness/closure-generated-comparison.json`
and `closure-cmm-generated.diff` in the same directory. No generated files,
evidence archives or test baselines are newly tracked.

## Measurement environment and commands

2026-09-24, OCaml 5.4.0, opam 2.1.5, Dune 3.23.1, Cerberus Lean 4.32.2.
The Lem pin was installed from its public URL with a worktree-local Git
redirect to the local Lem repository. The opam root, physical switch copy,
findlib config, install destinations, TMPDIR and logs belong to this cleanup
worktree. The preinstalled compiler/dependencies and pristine OCaml tree
were reused. Git's system config was disabled. The shared switch and
`deps/lem-pinned` were not modified. This is an offline, warm validation;
it is not an anonymous fresh public clone or download test.

A bounded runner serialized jobs and waited for foreign release/Lake/Dune
builds. Every Lean invocation ran through `scripts/capped` under an outer
`CERB_MEM_MAX=32G` cap. `LEAN_ABORT_ON_PANIC=1`, `DUNE_CACHE=disabled` and
`CERB_UPSTREAM_TREE` pointing to the existing pristine tree were set.
The small local `build-env.sh` records those scoped settings. During lane
execution `GIT_CONFIG_GLOBAL` was explicitly unset and `SKIP_BUILD=1` reused
the already regenerated and freshness-checked binaries. No baseline-write
mode was used. Row 1 and the named lanes are a subset, not full Tier A/B
or release certification. Baseline passes retain recorded skips and
immaculate exceptions; they do not establish universal semantic equivalence.

Exact build script executed by `bash .tmp/readiness/cold-build.sh` (the
script's historical filename does not describe this warm run):

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

Other exact commands, each from this cleanup worktree root:

```bash
source .tmp/readiness/build-env.sh; opam pin add --switch=. lem git+https://github.com/OathTech/lem-lean.git#6b20bfd02de924d078725efa96c6675115b8b17a --yes --no-depexts
source .tmp/readiness/build-env.sh; opam exec --switch=. -- ./scripts/capped bash -c "./scripts/check_fork_drift.sh --selftest && ./scripts/test_unit.sh"
source .tmp/readiness/build-env.sh; opam exec --switch=. -- env -u GIT_CONFIG_GLOBAL SKIP_BUILD=1 ./scripts/capped ./scripts/test_exec.sh --check-baseline
source .tmp/readiness/build-env.sh; opam exec --switch=. -- env -u GIT_CONFIG_GLOBAL SKIP_BUILD=1 ./scripts/capped ./scripts/test_exec.sh --check-baseline=scripts/exec_coverage_baseline.txt tests/coverage
source .tmp/readiness/build-env.sh; opam exec --switch=. -- env -u GIT_CONFIG_GLOBAL SKIP_BUILD=1 ./scripts/capped ./scripts/test_exec.sh --check-baseline=scripts/exec_debug_baseline.txt tests/debug
source .tmp/readiness/build-env.sh; opam exec --switch=. -- env -u GIT_CONFIG_GLOBAL SKIP_BUILD=1 ./scripts/capped ./scripts/test_exec.sh --check-baseline=scripts/exec_float_baseline.txt tests/float
source .tmp/readiness/build-env.sh; opam exec --switch=. -- env -u GIT_CONFIG_GLOBAL SKIP_BUILD=1 ./scripts/capped ./scripts/test_bytes.sh
source .tmp/readiness/build-env.sh; opam exec --switch=. -- env -u GIT_CONFIG_GLOBAL SKIP_BUILD=1 ./scripts/capped ./scripts/test_libc_exec.sh
source .tmp/readiness/build-env.sh; opam exec --switch=. -- env -u GIT_CONFIG_GLOBAL SKIP_BUILD=1 ./scripts/capped ./scripts/test_multi_tu.sh
source .tmp/readiness/build-env.sh; opam exec --switch=. -- env -u GIT_CONFIG_GLOBAL SKIP_BUILD=1 ./scripts/capped ./scripts/test_multi_tu.sh --failure-class-projection tests/multi_tu_tray
source .tmp/readiness/build-env.sh; opam exec --switch=. -- env -u GIT_CONFIG_GLOBAL SKIP_BUILD=1 ./scripts/capped ./scripts/test_address_space.sh --selftest
source .tmp/readiness/build-env.sh; opam exec --switch=. -- env -u GIT_CONFIG_GLOBAL SKIP_BUILD=1 ./scripts/capped ./scripts/test_address_space.sh
source .tmp/readiness/build-env.sh; opam exec --switch=. -- env -u GIT_CONFIG_GLOBAL SKIP_BUILD=1 ./scripts/capped ./scripts/test_immaculate.sh
```

The build completed successfully (395 jobs), and the one-C-program smoke
returned `Specified(42)` with MATCH. Replayed/deprecation/unused-variable
warnings remain. Dune also warned that parent directory `/home/dev` was
unreadable while searching for a root; the builds completed successfully.

All required commands returned **0**. Log filenames under `.tmp/readiness/`
are `closure-cerb-<name>.log`; hashes identify the exact local logs, which
are ephemeral rather than committed archives. Wall intervals are recorded
for provenance, not performance claims.

| Name | Exit | Wall seconds | Raw log SHA256 |
|---|---|---|---|
| opam-pin | 0 | 26.28 | `ae5687755b8d0775ae907c49a1c7fc0f1162e4b9fce3cd18494228261fa72f36` |
| final-build | 0 | 80.85 | `b66736db6166a3e7fcd3c00a789a1973db1b51a642c86b9b606c162c90db282b` |
| unit | 0 | 254.66 | `0f5a57d9c8a57e2ea4cf4de01bad2bc15610cd29143fdffb9d657b15e415bd28` |
| minimal | 0 | 28.3 | `4735b69a8647a34e7892ffc2bf77225bdc0d790caf83eace9f3807c1a6e9feda` |
| coverage | 0 | 52.54 | `dc10cffc9dd7df963c0da0a46e7fdb4c8471c3e06d6ae4d5173647418d366784` |
| debug | 0 | 22.23 | `86d6213a03201311efe0890ea263d2bd639952736b415690d45dae68ed67fc8a` |
| float | 0 | 24.25 | `540f7273d857f368c085538e3802682b220c10f1b4adbf5fb109a01c66fcd841` |
| bytes | 0 | 4.04 | `29340dc60b78d3262d8052b510f911412fd7e7c0af7751561d02a0e5c16bca08` |
| libc-exec | 0 | 24.25 | `1a589f5021b68dfda64ca16f56f25412a4324552b98de8f5e5600532ab0b436e` |
| multi-tu | 0 | 4.04 | `ec8108cd7b641c5e95aa609f0f5aa8f881d943c3a5830b789d5921f48629a689` |
| multi-tu-tray | 0 | 4.04 | `76c73f583b26800de236cb72af6b0abfe3d44dfe841ac7290d0b9c155430b4c5` |
| address-space-selftest | 0 | 6.06 | `f86a877a0b375695d5a15e6a337b5438e2d62753b0cd5bbbb60e15e2c6ad841a` |
| address-space | 0 | 6.06 | `c2b74596d60fbcdf06428ca246e6b90e18d6a30e23b72ad568562a0db3caa4a4` |
| immaculate | 0 | 72.76 | `996beaf3d4f090884109fc8e7fe3955271702f2c216470eb1019967d7b7bc37b` |

## Verbatim gate lines

### Row 1 and fork-drift self-tests

```text
check_fork_drift: SELFTEST OK (30 plants with declared verdict/message: S1-S10 prerequisite/locale/name controls; S11 copied-content control; S12 inside-listed-file drift; S13/S14 duplicate/missing content pins; S15-S30 version forms, full-pin validation and refresh retention; unplanted gate green)
Total: 15 passed, 0 failed
check_theorem_axioms: OK (effect-retirement C2 bar: zero axiom declarations anywhere; entry cones ⊆ the standard three)
check_sorry_token: OK (321 files scanned comment-stripped — generated 219, hand-written+test 67, LemLib 35; 0 sorry tokens)
check_fuel_forms: OK (81 fuel'd workers: 62 MEASURED (obligation of the contract's shape incl. argument correspondence against the wrapper's body; every obligation + proof cone ⊆ the standard three; 12 of them under a hypothesis, each = a reviewed row of fuel_hypotheses.txt, both directions), 13 ABSORBING = kill at zero (the _zero lemma is the worker at literal 0 on its own binders = the monad's absorbing element, cone ⊆ the standard three; propagation NOT proved — lem TODO 13), 0 reachable-AMBIENT = the 0 rows of fuel_forms_pending.txt exactly, 6 ambient unreachable from the drive cone)
check_failure_reach: OK (239 pure failure sites = the 239 register rows exactly (237 in the exec dependency closure + 2 unresolved-owner; key = file/owner/token/message, both directions); position classes unchanged; 0 DISCARDABLE; reach UNREACHABLE-BY-INVARIANT=170 REACHABLE=48 UNKNOWN=21; every row sealed; tally line consistent)
check_exec_totality: CLEAN (22 generated modules + hand-written CerbND, 0 allowlisted)
check_lem_sync: OK (src b2a78090bb9617fa5067c54145df8d775669571e30f0c9629539031975dc6e16, gen b79e328e77aa6c784c2ef260b341c98c473a35bf1e1d1523b73680949ba41d9e)
check_lem_sync: lean OK (src b2a78090bb9617fa5067c54145df8d775669571e30f0c9629539031975dc6e16, gen f4893e95ac3462defae87f737580b172f4e4e1cf35941d5be07edd82c8df808e)
check_fork_drift: OK — layer 1: 84 oracle-surface files = manifest (set, C-locale canonical, no duplicates); layer 2: 30 differing generated files, all hash-pinned (merge-base b9aeedcb4dd438763b0eef7f95ac19e93875d7de; lem-pin 6b20bfd02de924d078725efa96c6675115b8b17a matches lem -v 6b20bfd0 (hex prefix))
```

### minimal

```text
SUMMARY: total=113 match=90 ub_match=18 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=5 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
```

### coverage

```text
SUMMARY: total=212 match=183 ub_match=16 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=13 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
```

### debug

```text
SUMMARY: total=90 match=66 ub_match=20 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=4 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
```

### float

```text
SUMMARY: total=93 match=93 ub_match=0 ub_diff=0 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
Baseline check: 0 regression(s), 0 improvement(s)
BASELINE OK
```

### bytes

```text
SUMMARY: exec_match=9 neg_pinned=5 fail=0
ALL AT COMMITTED EXPECTEDS
```

### libc-exec

```text
SUMMARY: match=12 diff=0
ALL MATCH RECORDED BASELINE
```

### multi-tu

```text
SUMMARY: total=2 match=2 fail=0
ALL PASSED
```

### multi-tu-tray

```text
SUMMARY: total=7 match=7 fail=0
ALL PASSED
```

### address-space-selftest

```text
test_address_space: SELFTEST OK (14 plants — P1 the discriminator's derived pre-fix observation, P2 missing file, P3 truncated, P4 phantom row, P5-P7 phantom/duplicate/malformed rows without a final newline all REJECTED; P8 the valid file without a final newline ACCEPTED; P9/P10 the out-of-domain and non-decimal tops REFUSED on both engines, P11 a decimal top accepted; P12/P13 underscore-separated spellings REFUSED on both, P14 2^64 - 1 ACCEPTED on both; the committed file green)
```

### address-space

```text
test_address_space: OK (18 cases: LEAN = FORK through the shared codec at tops 64 32 8; every fork observation = its pinned row in expectations.txt)
```

### immaculate

```text
OK: lane matches the committed baseline (MATCH except the ISO-fix register pins R1 g5-decode-question/zd-e2-ptr-string-literals ORACLE_CRASH, R2 g5-escape-roundtrip DIFF, R3 s4b-memcmp-hugesize ORACLE_CRASH, R5 r5-hex-subnormal-double-rounding DIFF — VALIDATION.md 'ISO-fix register' — and the in-Lean probes g6 TRIPWIRE / illtyped-store KILL).
```

## Handoff and remaining work

[AGENT] Ready for the orchestrator's independent re-gate and short second
review of the closure deltas. This checkpoint performs no merge, shared
switch update, push, tag, history rewrite, branch/worktree deletion or
announcement. Each later merge still requires the operator's per-merge
sign-off and must be fast-forward only. The Lem merge, separately authorized
shared-switch re-pin, Cerberus re-gate/merge must be coordinated so that no
older worktree regenerates against the new Lem during the transition.

The SHOULD block remains separate: S1, S3–S11, the reviewers' current-facing
clarifications, `ci_lean.sh`'s residual Git-config requirement, portable
fork-drift prerequisites, cap/version documentation, and the bare-tag
version follow-up above. The concurrency prototype is a parked record;
nothing here depends on it or performs the separate concurrency remediation.
M8 maintainer licensing resolution and M9 public-remote/fresh-clone checks
remain open; public availability is **UNVERIFIED-OFFLINE**. The M9 commands
in the original readiness review must use the final Lem pin `6b20bfd02de924d078725efa96c6675115b8b17a`
and the final reviewed Cerberus closure head supplied at handoff.
