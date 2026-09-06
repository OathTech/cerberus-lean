# Fresh primary observation audit

2026-09-06, independent reviewer `audit_observations`. Subject: primary
`6d6cfa858109a42561878db3d939024c5756ad4f`, base
`89f7e688530c6910884518811d645e4e892e4507` (verified from delivery source map).
Tracked source remained unchanged. No Lean/lake/make/dune or corpus job was
run by this reviewer. Legacy campaign worktrees/logs and refined-cerberus
were not inspected or operated on.

**Recommendation: do not call G1 complete or land its current trust claims
until O1–O3 are resolved.** The byte decoder itself passed the supplied unit
suite and the independent byte/framing controls below. The findings concern
real composition and classification paths that those tests do not cover.

## Findings

### O3 — P1: an actual descendant-OOM witness is accepted as completed agreement

Location: `scripts/observations.py:139`, `scripts/observations.py:165`;
producer `scripts/capped:76-78`. The decoder rejects `capped: OOM-KILLED`,
but the same shipped wrapper emits a different positive OOM witness when
its direct command returns 0 or 1 after a descendant is killed:

```
capped: OOM event recorded in cgroup (memory.events oom_kill=1, cap CERB_MEM_MAX=128M) though the command exited rc=0 — a descendant was killed by the cap; NOT a clean pass
```

A complete Defined/status-0 capture with this diagnostic compares equal to
the same Defined capture without it. `inspect` reports `completion: complete`.
See `oom-compare-result.status` (0), `oom-inspect-result.stdout`,
`capped-descendant-banner.stderr`, and their exact command JSON files.
The local reproducer extracts the actual wrapper's banner function and
injects its already-read witness value; it does not simulate kernel OOM.

The coordinator additionally confirmed this with **the actual shipped capped**
at 128M, a 256MiB Python child killed with return code -9, and a surviving
parent returning the Defined record/status 0. Independently dated raw
confirmation: `../descendant-oom/`, setup `../reproduce_descendant_oom.py`.
This proves wrapper/codec composition, not reachability from a C program.

Impact: capped semantic callers such as CI, libc-exec and libxml2 can report
agreement despite the wrapper's explicit resource-failure witness. This is
not the documented native exit-137 ambiguity, and the contract excludes cap
kill/partial exploration from agreement. Existing cap plants test this second
banner on capped alone, without passing it through the observation parser.

Correction: recognize every positive cap witness before comparison,
independent of the direct child's status; centralize the protocol so the
wrapper, codec, and native GCC classifier cannot drift. Add a composed
descendant-OOM plant plus ordinary diagnostic/semantic-payload controls.
The missing O2 `killed` branch described below is related but separate.

### O1 — P1: immaculate's crash exception bypasses fuel and malformed-output checks

Location: `scripts/test_immaculate.sh:105-108`, comparison at `:139`,
baseline use at `:180-184`. Before invoking the codec, the local verdict
function accepts any status 125/134 with an `internal error:`/`PANIC at`
line, provided no stdout line starts with four known verdict/header names.
It never performs the codec's fuel check, narrow panic-form check, or
unexpected-stdout check on that path.

The exact extracted production functions produce:

```
control: oracle=CRASH lean=CRASH row=MATCH | L=CRASH
fuel: oracle=CRASH lean=CRASH row=MATCH | L=CRASH
garbage: oracle=CRASH lean=CRASH row=MATCH | L=CRASH
wrong-panic: oracle=CRASH lean=CRASH row=MATCH | L=CRASH
valid-prefix: oracle=CRASH lean=INVALID row=INVALID | L=INVALID
```

`fuel` is empty stdout plus
`PANIC at LemLib.failwithIImpl LemLib.lean:10:3: lem: fuel exhausted` on
stderr/status 134. `garbage` adds `corrupted transport bytes` on stdout
beside an otherwise normal panic. The normal control and verdict-prefix
negative prevent a vacuous reproduction. The shared codec independently
rejects both fuel and garbage under its litmus failure policy.

Impact: eight committed rows already expect `MATCH | L=CRASH`, including
`tests/immaculate/baseline.txt:82` (`g2-memcmp-uninit`). Replacing the Lean
side of such a row by these failures leaves its exact baseline key/value
unchanged. The declared coarse crash pin is a legitimate existing limit;
allowing fuel exhaustion or arbitrary malformed stdout into that exception
contradicts the new contract. This is an incomplete repair of an older broad
exception, not a newly introduced semantic defect.

Coordinator confirmed the full unmodified `test_immaculate.sh` entry point
with our prepared wrapper injecting only that row's fuel PANIC and delegating
all other engine invocations to the actual engines. The run exits 0, prints
`g2-memcmp-uninit` as `MATCH O[CRASH] L[CRASH]`, and ends
`OK: lane matches the committed baseline`. Exact output/status and retained raw
captures are in `entry-immaculate.stdout`, `entry-immaculate.stderr`,
`entry-immaculate.status`, and the capture directory printed there. This is
a production control-flow plant, not evidence that the real C input exhausts
fuel. Coordinator then reran the full healthy lane with normal rebuilding
and no engine override: status 0 and the same committed-baseline success.
Control evidence is `../immaculate-healthy.stdout`,
`../immaculate-healthy.stderr`, `../immaculate-healthy.status`, and
`../immaculate-healthy-raw/`; exact invocation is retained in
`../immaculate-command-record.json`.

Correction: run common resource/fuel/framing checks before any coarse
projection. If additional actual OCaml crash forms must be supported, put
their explicitly reviewed grammar/status policy in the shared decoder;
collapse to CRASH only after validation. Plant actual pinned crash rows,
not only healthy Defined rows with exit-2 mutations.

### O2 — P1: UB differences still give a successful default run and a 100% headline

Location: `scripts/test_exec.sh:754-760`, `:824-829`, `:973-985`.
UB_DIFF increments `UB_CODE_DIFF` without incrementing the fatal mismatch
counter. This branch changes TOTAL_MATCH to omit UB_DIFF, but leaves
TOTAL_COMPARE derived from TOTAL_MATCH + MISMATCH, so UB_DIFF vanishes from
the denominator as well. Default-mode failure checks omit UB_CODE_DIFF.

The exact production comparison/summary/default-exit source on one equal
Defined pair and one UB pair differing only in location produces status 0:

```
[2/2] UB_DIFF ub-diff: Lean=UB:{ub: "UB036_exceptional_condition", stderr: "", loc: "<t.c:2:2>"} Cerberus=UB:{ub: "UB036_exceptional_condition", stderr: "", loc: "<t.c:2:1>"}
Match rate:   100% (complete observations; UB_DIFF is a difference)
SUMMARY: total=2 match=1 ub_match=0 ub_diff=1 mismatch=0 fail=0 crash=0 fuel=0 lean_error=0 timeout=0 hang=0 cerb_skip=0 cerb_floor=0 cerb_inconsistent=0
```

Impact: a UB-location/stderr/code regression is still accepted in default
multi-file runs if at least one other comparison succeeds. The new headline
claims complete-observation agreement while excluding a compared difference.
The old baseline had counted UB_DIFF as agreement; that older policy is
partially removed here. A fixed MATCH/UB_MATCH baseline moving to UB_DIFF
does fail the rank check, so this is not evidence that the shipped fixed
Tier A baseline would silently accept such movement.

Coordinator independently ran the unmodified actual `test_exec.sh` with
controlled engines, real capture/codec flow and healthy/different controls;
`../actual-exec-ubdiff/result.json` and `../reproduce_exec_ubdiff.py` retain
that confirmation. In addition to the default-mode result, deleting the
UB_DIFF row from the supplied baseline was accepted as a nonfatal new row:
the new-file case at `test_exec.sh:917-924` omits UB_DIFF. Include that case
in the correction's regression test.

Correction: count UB_DIFF in the comparison denominator and explicitly fail
default mode for it. Preserve the documented baseline policy as a separate
mode. Test mixed MATCH+UB_DIFF and all-UB_DIFF runs with expected counts and
exit statuses.

## Verification and reproducibility

Executed from the frozen primary root:

```
PYTHONDONTWRITEBYTECODE=1 python3 .validation-foundations/premerge-audit-20260906/observations/reproduce.py
PYTHONDONTWRITEBYTECODE=1 TMPDIR="$PWD/.validation-foundations/premerge-audit-20260906/observations/tmp" python3 scripts/test_observations.py
```

`reproduce.log` retains the raw aggregate output. Each subprocess also has
separate `.stdout`, `.stderr`, `.status`, and `.command.json` evidence.
`repro-source-hashes.json` binds the extracted source. `exec-driver.sh` and
`immaculate-functions.sh` contain the verbatim production branches used.
The extraction reproducer deliberately omits engine/build setup; it is not
described as a whole-lane run.

- Supplied codec suite: **13/13 passed**, `codec-tests.log`.
- Independent controls: all 256 decimal byte escapes decode exactly;
  fuel, garbage beside internal failure, verdict-then-fatal,
  verdict-then-timeout, empty success, noncontiguous/missing framing and
  out-of-range escapes reject. Sequence order/multiplicity differ while the
  intentional set projection agrees. `independent-properties.txt`.
- `bash -n` on all **27 changed shell files**: 0 failures;
  exact commands/results in `shell-syntax.json`.
- `git status --short` after reproductions: empty.

Prepared, **not run by this reviewer**: `actual-entry-commands.sh exec` and
`actual-entry-commands.sh immaculate`, with tiny fixtures and loud override
wrappers beside it. Coordinator ran the immaculate command, confirming O1
as recorded above; coordinator's separate exec reproducer confirmed O2.
The immaculate wrapper mutates only the output of the existing
g2-memcmp-uninit row while delegating every other Lean call. These plants
make no assertion about actual C semantics.

## Review coverage and remaining concerns

Read the full shared implementation (`observations.py`, `observations.sh`,
`speclab_observations.sh`, `common.sh`) and full affected primary callers:
`test_exec.sh`, `test_ci_sweep.sh`, `test_cn_coverage.sh`, `test_multi_tu.sh`,
`test_verify.sh`, `test_gcc_oracle.sh`, `test_bytes.sh`, `test_libc_exec.sh`,
`test_libxml2.sh`, `test_libxml2_uri.sh`, `test_immaculate.sh`, all six
`test_speclab*.sh`, `csmith_explore.sh`, and
`tests/parity-probes/run_probe.sh`. Also read `test_observations.py`, the
complete 67-case `test_observation_lanes.py` driver, `test_gcc_capture.sh`,
`test_fuel_plant.sh`, `test_hang_plant.sh`, `test_kill_plant.sh`,
`fuel_classify.sh`, `capped`, `test_unit.sh`, and the observation-related
capture/comparison paths of `test_upstream_oracle.py`.

Producer tracing inspected `Main.lean:307-418,1058-1097`,
`driver_ocaml.ml:22-184`, `backend/driver/main.ml:146-236`, and
`frontend/model/driver.lem:250-275,350-445,1461-1500`: modeled character lists
flow through the IO dlist into batch escaping. No Unicode normalization was
added or assumed. Higher-character producers, Error's missing internal
stderr, killed stdout, and undetectable removal of a complete framed suffix
remain the **declared printer/representation boundaries**, not new findings.

Additional concerns, not established new blockers in this review:

- Several Cabs bridge executions still discard diagnostics/status or delete
  them with lane scratch cleanup (`test_exec.sh:445-447`, CN `:233-235`,
  multi-TU `:155-156`, GCC `:424-427`, verify `:131-134`). The capture
  contract's wording “every attempted run” is broader than this retention.
  Main semantic batch captures are retained; complete bridge provenance is
  not uniformly retained. Clarify the claim or extend capture coverage.
- Six spec-lab generator builds still suppress build output and ignore the
  build's status before checking that an old executable exists (for example
  `test_speclab.sh:67-69`, `test_speclab_divmod.sh:59-61`). This is inherited,
  and distinct from the migrated decoder, but leaves a stale-generator
  failure path; no compiled plant was run by this reviewer.
- GCC's O2 switch (`test_gcc_oracle.sh:542-555`) still lacks the `killed`
  outcome that gcc_run can return. It silently leaves O2 as `-`; a baseline
  previously requiring O2_AGREE catches the rank loss, while unbaselined
  runs lose the kill classification. Also inherited; not a new introduction.
- libc-exec now compares canonical decoded tokens (`:118-122`), while the
  contract matrix still promises additional exact printer spelling there.
  The actual baseline is status-only. Equivalent escapes are deliberately
  equal in the codec; correct the matrix if printer equality was retired.
- Full actual-entry 67-plant battery, real C semantic probes, and heavy
  lane/build checks were left to coordinator. Current supplied plants do
  not cover O1–O3. Private concurrency receives a separate fresh report.

Instructions read: container CLAUDE.md, primary CLAUDE.md and
lean_frontend/CLAUDE.md. Initial login shell emitted an unrelated nono
`/etc/profile` denial while requested reads succeeded. Read the nono skill,
reported it to coordinator, and used `login:false` throughout afterwards.
Profile loading was unnecessary; no permission/profile/global changes were
made.
