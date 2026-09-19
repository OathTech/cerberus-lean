# Concurrency design assessment evidence

Evidence for the [assessment](../2026-09-19_concurrency-design-assessment.md), collected on 2026-09-19. This directory preserves successful controls as well as counterexamples. A successful probe process does not mean the implementation passed the property being investigated.

## Scope and identities

- Reviewed landing charter and tree: `38d7d2123ca1dd2a0769c19518b9410c7d4ea1f5` (`arc/concurrency-landing`).
- Legacy implementation: `086d8762d382eff375c101f5f0c64d3ffe9bccc7` (`feature/concurrency`). The landing branch adds only its charter.
- Mainline used for the independent observation decoder and execution cap: `0457732e1865a3ba2bc678f6ca8c35e532471baa`.
- Isolated review worktree: `/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-audit/concurrency-design-20260919`.

`identity.json` records source, instrument, binary and generated-tree digests, the build command, and scope limits. Both generated targets and both engine executables were freshly built in the review worktree. The shared opam installation was used as a dependency, not overwritten with this branch's Cerberus library. No tracked implementation or expectation changed. This was not a rebase, a full release-battery run, or a theorem/consumer certification.

## File map

| Files | Contents |
|---|---|
| `build.log`, `identity.json` | Fresh-build receipt and identities. |
| `probes/*.c` | Twenty main-matrix C inputs plus two later `atomic-unseq-*` exploratory inputs. |
| `run_probes.py`, `fork-probes.*`, `lean-probes.*`, `paired-probes.json` | Both modes and both engines for the twenty inputs: original statuses, commands, full decoded observation sets or protocol failures. |
| `check_litmus.py`, `litmus.txt`, `litmus-results.json` | Independent check of all thirty committed targets, using current mainline decoding, full engine observations, original process statuses and strict expectation membership. |
| `CandidateCounterexamples.lean`, `abstract-counterexamples.txt` | Two abstract graphs refuting the stated L2 premise list, and an accepting control, evaluated against the generated checker. These are executable examples, not general proofs or assertions that the graphs arise from valid C. |
| `sc-bridge-test.txt` | Five passing controls from the shipped bridge executable. |
| `probe_litmus_instrument.py`, `instrument.txt`, `instrument-results.json` | Legacy helper plants: healthy control, retained valid output with failing engine statuses, and a duplicate reference row. Engine calls are replaced by fixtures; these are not OS-killed C executions. |
| `seqrmw-*-debug.txt` | Fork debug traces for the sequencing investigation. The assessment limits the claim to the observed event relation. |
| `atomic-unseq.json` | Two supplemental atomic/unsequenced observations, with commands; both engines report UB035. These do not establish a new blocker. |
| `raw-captures.tar.gz` | Raw stdout/stderr/status files and generated Cabs JSON under `captures/` and `litmus/`; extracted instrument helpers and planted files under `instrument/`. |
| Three dated reference documents | Mainline's September 6 integration proposal and supported profile, and September 17 scoping note, copied unchanged for portable assessment links. |
| `SHA256SUMS` | Integrity manifest for this evidence directory, excluding the manifest itself. |

The focused matrix reports the atomic-exchange frontend failures as incomplete/protocol failures, not matching semantic observations. The three concurrent-copy pairs disagree on their complete inconsistency payloads. The main matrix helper skips the two later `atomic-unseq-*` inputs so that replay retains the twenty-case scope.

## Reproduction in this workspace

Run from the review worktree root unless stated otherwise. These commands depend on the project's existing `ce` environment and pinned dependencies. The helper scripts deliberately use the current mainline's `scripts/observations.py` and `scripts/capped` at the absolute workspace path above; their measured hashes are in `identity.json`. For another workspace, update those paths and use that recorded mainline revision. The recorded JSON commands also contain original absolute paths.

The build used:

```sh
/home/dev/projects/cerberus-lean-proj/scripts/ce bash -c 'set -e; export DUNE_CACHE=disabled; make prelude-src lean-prelude-src; opam exec --switch=. -- dune build --force backend/driver/main.exe cerberus-lib.install; cd lean_frontend; CERB_MEM_MAX=32G ../scripts/capped lake build cerberus-lean sc-bridge-test'
```

The legacy `scripts/common.sh` build helper installs into the shared switch. It was not used for this isolated assessment.

Stage the retained inputs and run the main matrix and independent litmus check:

```sh
evidence=lean_frontend/docs/2026-09-19_concurrency-design-assessment-evidence
mkdir -p .tmp/concurrency-design-audit/probes
cp "$evidence"/probes/*.c .tmp/concurrency-design-audit/probes/
/home/dev/projects/cerberus-lean-proj/scripts/ce python3 "$evidence/run_probes.py" fork
/home/dev/projects/cerberus-lean-proj/scripts/ce python3 "$evidence/run_probes.py" lean
/home/dev/projects/cerberus-lean-proj/scripts/ce python3 "$evidence/check_litmus.py"
python3 "$evidence/probe_litmus_instrument.py"
```

Outputs are written beneath `.tmp/concurrency-design-audit`, preserving this evidence snapshot. `run_probes.py` and `probe_litmus_instrument.py` are diagnostic collectors; inspect their records rather than treating their own zero exit status as a passing gate. `check_litmus.py` fails if a committed target fails its checks.

For the abstract graphs and bridge controls:

```sh
mkdir -p lean_frontend/.tmp/concurrency-design-audit
cp "$evidence/CandidateCounterexamples.lean" lean_frontend/.tmp/concurrency-design-audit/
cd lean_frontend
/home/dev/projects/cerberus-lean-proj/scripts/ce ../scripts/lean_probe.sh .tmp/concurrency-design-audit/CandidateCounterexamples.lean
/home/dev/projects/cerberus-lean-proj/scripts/ce ../scripts/capped .lake/build/bin/sc-bridge-test
```

The supplemental atomic runs can be replayed from the argument arrays in `atomic-unseq.json`, adjusting paths if necessary. The debug traces use the retained corresponding C files and the fork's `-d 2` flag. They are explanatory traces, not independent acceptance tests.

To inspect the preserved raw captures, extract `raw-captures.tar.gz` into a new scratch directory. To check evidence integrity, run `sha256sum -c SHA256SUMS` from this directory.
