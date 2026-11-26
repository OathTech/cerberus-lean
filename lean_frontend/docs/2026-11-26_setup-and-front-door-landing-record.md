# Landing record: setup scripts and the driver's front door (2026-11-26)

Mainline `mdd/cerberus-lean` moved by fast-forward from `8bb1fd0f9` to
`1da4624c3` on 2026-11-26, on the user's sign-off for that commit
([USER 2026-11-26]). Three commits from `feature/setup-and-front-door`.

## 1. Why

With the project mostly parked and a redesign of the semantics side
expected, the user asked which quality-of-life improvements would help users
and survive that redesign, and chose two ([USER 2026-11-25]): provisioning
with a preflight check, and a usable front door on the Lean driver. Setting
up a second machine had taken most of a day, and three full ladder runs had
failed on a missing or wrong prerequisite, each after a long wait
(`2026-11-25_box-port-landing-record.md`).

## 2. What landed

| Commit | Content |
|---|---|
| `418faa1eb` | `scripts/preflight.sh`, `scripts/bootstrap.sh`, `scripts/run_c.sh`; `--help` / `-h` on the Lean driver; controls in `scripts/check_cli_refusals.sh`; pointers in the README and the practices doc; `deps/` and `worktrees/` ignored. |
| `a2c724b4c` | Dispositions of the first pre-merge review (six should-fix findings and notes). |
| `1da4624c3` | Dispositions of the second review (three should-fix findings and notes), including the driver change of §3. |

- **`scripts/preflight.sh`** reports in seconds what a checkout lacks for the
  ladder, each missing item with the command that provides it. It reads
  only. It is not a gate: READY means the lanes can start, not that they
  pass.
- **`scripts/bootstrap.sh`** runs the documented recipes as checked steps:
  `switch`, `sources`, `build`, `oracles`, `all`, and `worktree NAME [BASE]`
  (the retired workspace's worktree script; nothing built is copied). A
  failing step stops the script and names the command.
- **`scripts/run_c.sh`** runs one C file through both engines and prints
  what each says and whether the outputs are byte-identical with the same
  exit status. It is a convenience and says so; the classified comparison
  remains the lanes'. It builds nothing and refuses stale or substituted
  engines.
- **`cerberus-lean --help` / `-h`**, as the sole argument, prints a usage
  text and exits 0, before the `LEAN_ABORT_ON_PANIC` refusal (it runs no
  semantics). In any other position `--help` is refused as an unknown flag.

## 3. A driver behaviour change beyond the help flag

Checking the usage text against the parser, the second reviewer found that
`cerberus-lean --parse-core` with no file exited 0 in silence: its file loop
ran zero times, so a caller whose file list expanded to nothing read
success. The repair is in the driver: the mode now prints a usage line and
exits 1, the shape of the other modes. No script in the repository called
the mode without a file. The user was told this was a change they had not
asked for and accepted it with the landing [USER 2026-11-26].
`check_cli_refusals.sh` checks all three modes.

## 4. Evidence

- **The battery.** `python3 scripts/release.py --mode full` on `1da4624c3`:
  48 of 48 selected commands passed, complete Tier A + Tier B selection,
  source unchanged, from generated trees re-derived at that commit through
  `scripts/bootstrap.sh build` (no error in the build log; preflight READY
  before dispatch). Environment: `CERB_MEM_MAX=32G`, `CERB_UPSTREAM_TREE`;
  no override variable. Run in a worktree, 2026-11-25/26. An earlier full
  run on `a2c724b4c` was also 48/48. A run on the first version of the
  second commit was stopped six minutes in and discarded when mainline moved
  under the branch (the assessment `8bb1fd0f9`); the branch was rebased and
  the run repeated on the rebased commit.
- **Reviews.** Two independent pre-merge reviews [AGENT reviewers]: of
  `bd109caeb` (the first commit before the rebase; nothing blocking, six
  should-fix) and of `a2c724b4c` (nothing blocking, three should-fix; about
  55 probes of the usage text against the built driver). Dispositions are in
  the messages of `a2c724b4c` and `1da4624c3`. `1da4624c3` was not separately
  reviewed; the user landed it on the green battery [USER 2026-11-26].
- **Failure controls.** `run_c.sh`: a changed hand-written source without a
  rebuild, a changed `runtime/libcore/std.core`, an override variable (each
  refused, exit 2); a non-terminating program (no agreement, exit 1). The
  bootstrap's oracle step failed closed when its first design needed the
  network. The gate: `--help` after `--batch` refused; `--help` with another
  argument and `-h` in three other positions do not exit 0; a run without
  `LEAN_ABORT_ON_PANIC` still refused; each mode with no input exits nonzero
  with a usage line.
- **Primary checkout after the fast-forward** ([USER 2026-10-16] rule):
  `make clean-prelude-src`, `scripts/bootstrap.sh build` (exit 0, no error
  line), preflight READY, `scripts/test_unit.sh` exit 0 with 21 of 21
  executables, at `1da4624c3`.
- **Not run:** kernel replay (no proof changed), Tier C.

## 5. Limits

- Not exercised as scripted: `bootstrap.sh switch` creating a switch from
  nothing, and `sources` cloning; the sandbox had no network and the machine
  was already provisioned. They run the commands used by hand on 2026-11-24.
  What `switch` does after an interrupted switch creation is not determined.
- `run_c.sh` does not check the compiled C library (`libc.co`) against
  `runtime/libc`; it says so.
- `bootstrap.sh` accepts a hand-made upstream clone at the pinned merge-base
  as the pristine tree without knowing whether its generation completed; the
  fork-drift gate compares the tree's file set and fails closed.
- The usage text is a description, not the contract; `CONTRACT.md` is. One
  parser behaviour it now states and does not change: an option takes the
  next argument as its value whatever that argument is.
- shellcheck was not run over the three new scripts.
- Still open from `2026-11-25_box-port-landing-record.md` §5: the runner and
  outcome-affecting environment variables (the preflight now lists the ones
  set, as a warning), skip-class changes in the gcc lane, the abort-line
  pattern and a relative `scripts/capped` path, stale workspace references
  in the `make rebuild-lem` comments and two probe scripts.

[AGENT 2026-11-26] wrote this record.
