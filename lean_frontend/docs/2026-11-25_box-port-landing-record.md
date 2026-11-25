# Landing record: the ladder off its first machine, and the practices doc (2026-11-25)

Mainline `mdd/cerberus-lean` moved by fast-forward from `7d16b9b8c` to
`48891c82a` on 2026-11-25, on the user's sign-off for that commit
([USER 2026-11-25]). Seven commits: five from `fix/box-port` (head
`457961f40`) and two documentation commits from `docs/frontend-practices`.
This record also covers `7d16b9b8c` itself, which was landed on 2026-11-24
without the required gates.

## 1. What went wrong first

On 2026-11-24 the project was set up on a second machine (Ubuntu 26.04,
kernel 7.0, bash 5.3, uutils coreutils, gcc 15.2) as a single repository,
without the workspace folder that had surrounded it. An agent fixed a
locale-dependent `comm` comparison in two gate scripts and landed it as
`7d16b9b8c`, and it was pushed, after running ladder row 1 only. The landing
rule (the full battery, one run on the exact commit) was in the workspace's
practices file, which had not come with the repository, and at line 337 of a
460-line `lean_frontend/CLAUDE.md` of which the agent had read 150 lines.
The agent listed the unrun tiers beside its request to land instead of
treating them as a blocker. The user called this a trust failure by the
project's own standard [USER 2026-11-24].

`7d16b9b8c` never had a green full run of its own. A diagnostic full run on
it had 41 of 48 commands green; the seven red rows are §2. Its change is
contained in the gated head below.

## 2. What the first full runs found

Seven Tier B commands were red on the second machine, for four causes, none
in the semantics:

| Rows | Cause |
|---|---|
| B5 | `scripts/observations.py` accepted bash's abort line only with a single space before `(core dumped)`; bash 5.3 pads it. 18 Lean crash rows read INVALID. |
| B8.3, B8.4 | `tests/mem-scale-probes/measure.sh` required `GIT_CONFIG_GLOBAL`, a sentinel of the retired workspace `env.sh`. |
| B10.1, B10.2, B12 | `scripts/test_upstream_oracle.py` looked for `deps/cn` in the repository's ancestors only. |
| B7 | Six `TRIAGED_ADDR` ledger rows pinned the exit byte of a gcc-compiled address observer; the values moved with the machine (244 to 228, 236 to 220, 64 to 192), identically under gcc 13.4 and gcc 15.2. |

An audit of the Tier A/B surface for other machine dependence ([AGENT],
2026-11-24) reported thirteen latent ones. Three were fixed here on the
user's agreement: external corpora not pinned by revision, the gcc lane
compiling at the compiler's default standard, three different rules for
choosing gcc.

## 3. What landed

| Commit | Content |
|---|---|
| `5198e50b9` | The abort-line pattern (with controls), the workspace guard removed, `deps/` looked for from the repository root. |
| `d79f56445` | An address-class triage entry pins the program's sha256 and Lean's value; gcc's value is printed, not compared. Design agreed by the user [USER 2026-11-24]; amendment in `2026-08-30_gcc-second-oracle-design.md` §4. |
| `83f6c9f63` | `scripts/external_pins.txt` and `scripts/check_external_pin.sh` (CN, libxml2, pKVM by commit; called by the lanes that read them); `-std=gnu17` in the gcc lane; one rule for `GCC_BIN`. |
| `d5d8f306e` | Dispositions of the first pre-merge review (nine findings). |
| `457961f40` | Dispositions of the second review (five findings). |
| `7495f14f2`, `48891c82a` | `lean_frontend/CLAUDE.md` rewritten: soundness and the landing rule first, the working practices from the archived workspace file, the ladder's prerequisites; catalogues moved unchanged to `lean_frontend/REFERENCE.md`; the root `CLAUDE.md` states the landing rule. Markdown only. |

New standing rule, [USER 2026-11-24], paraphrased: soundness is a key value
of the project, and landing on mainline without the gates having been run
must never happen unless the user explicitly and directly asks for it.

## 4. Evidence

- **The battery.** `python3 scripts/release.py --mode full` on `457961f40`:
  48 of 48 selected commands passed, complete Tier A + Tier B selection,
  source unchanged, from generated trees re-derived at that commit (every
  build step's exit status checked). Environment: `CERB_MEM_MAX=32G`,
  `CERB_UPSTREAM_TREE` (the fork-drift prerequisite); no override variable;
  gcc 15.2. Run in a worktree on the second machine, 2026-11-25. Earlier
  full runs on the branch: `5198e50b9` 46/48 (A1 red from a priming error
  of the agent's, §5; B7 red, fixed by `d79f56445`), `83f6c9f63` 48/48,
  `d5d8f306e` 48/48.
- **After the run.** `git diff --name-only 457961f40..48891c82a` lists
  `CLAUDE.md`, `lean_frontend/CLAUDE.md`, `lean_frontend/REFERENCE.md`
  only: the documentation-only exception [USER 2026-11-23].
- **Reviews.** Two independent pre-merge reviews [AGENT reviewers]: of
  `7d16b9b8c..83f6c9f63` (no wrong-pass path found in the two
  gate-accepting changes; nine findings) and of `d5d8f306e` (nothing
  blocking; five findings). Each finding's disposition is in the message of
  the commit that answers it. `457961f40` was not separately reviewed; the
  user landed it on the green battery [USER 2026-11-25]. The audit of the
  documentation commits was waived by the user [USER 2026-11-24].
- **Failure controls.** The codec's padded and malformed abort lines; five
  plants on the address-class rule (wrong source pin, wrong Lean pin,
  edited program, each spelling in the other class's place); the full gcc
  lane against a baseline with one row's class changed (fatal); the pin
  checker's 13 plants, in row 1.
- **Primary checkout after the fast-forward** ([USER 2026-10-16] rule):
  `make clean-prelude-src prelude-src lean-prelude-src`, both engines and
  speclab rebuilt, `scripts/test_unit.sh` exit 0, 21 of 21 executables, at
  `48891c82a`.
- **Not run:** kernel replay (no proof changed), Tier C.

## 5. Limits and what remains

- For the fourteen address rows gcc is no longer an oracle: any
  deterministic native result passes. Stated in the design note. An optional
  gcc pin on rows the ABI fixes was considered and declined as a marginal
  gain [USER 2026-11-25].
- The corpus revisions in `scripts/external_pins.txt` are the first
  machine's checkouts as archived on 2026-11-23; the lanes' baselines pass
  at them.
- A worktree nested in the repository needs `--root .` on `dune`; without it
  a priming build fails with "Don't know how to build". The agent reported
  such a build as clean after reading only its tail; the practices doc now
  says to check every step.
- Raised, not decided: the release runner neither records nor refuses
  several environment variables that change lane outcomes (`TIMEOUT_SECS`,
  `CERB_TEST_FUEL`, `CERB_TEST_MEM_MAX`); the gcc lane lets a row move
  between skip classes without failing, and two rows
  (`ts-fmt-star-precision.c`, `ts-fmt-star-width.c`) differ from the
  baseline that way on every run; `ABORT_WRAPPER` requires a slash before
  `scripts/capped`.
- The audit's remaining latent dependences (the unversioned host
  preprocessor, x86-64 assumptions in three rows, wall-clock margins) are
  listed as stated assumptions in `lean_frontend/CLAUDE.md` §4.
- Stale workspace references remain in the `make rebuild-lem` comments and
  in two non-gating probe scripts that look for `../deps`.

[AGENT 2026-11-25] wrote this record.
