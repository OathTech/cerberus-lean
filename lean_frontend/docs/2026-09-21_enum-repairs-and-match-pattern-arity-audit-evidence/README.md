# Evidence for the enum-repair and tuple-arity audit

This evidence belongs to two separate source heads:

* `enum`: `e2fc391f21fd659c74f4dfdecdf7cc9fd45a2009`.
* `arity`: `14457f1a0b30e1de3762310af51684bf6d2e347f`.

The comparison base is `5407597d9eeba0259d65b728e86a860ad4614ab3`;
the previous enum audit's head is
`0e1968ffb6d4736e60a7b53bee2fb3eb2c336304`.
The earlier audit and its original captures are committed at `880a8ead8`.
The audit commit containing this directory changes documentation/evidence
only and was made after both full runs ended.
`arity/base-identities.json` binds the reused clean base checkout to its
actual binary hashes and successful source/binary freshness checks.

## Contents and interpretation

`verification.json` records the two full runs. Each subdirectory has the
complete `release-report.json`, runner summary/log, source/build stamps,
pristine-oracle manifest, and archives containing lane receipts and
case-level pristine reports. All source, external-input, and artifact
identities recorded by the runner were compared before/after; lane
stdout/stderr hashes were checked against their runner report before archiving.

`build-log.tar.gz` preserves the regeneration, forced Dune build, all-root
Lean build, and pristine-oracle build output. `lane-receipts.tar.gz` retains
every lane's complete stdout/stderr and its top-level JSON receipts.
`pristine-reports.tar.gz` retains the nested B10.1, B10.2 and B12 reports.
It does not contain every large standard-corpus intermediate or binary.
B10.2 is the oracle gate's `--plant` selftest: its `plant_rejected` row is
an expected rejection, and the report verdict is `plants_passed`.

`enum/focused-captures.tar.gz` contains the raw Cabs bridge captures and
64 fork/Lean runs on 32 C programs, plus the pristine/GCC/native output
for the 24 successful programs and the direct signedness probes.
It also retains the source/generated-code excerpts with their original
whitespace intact.
`probes-results.json` records engine statuses and full-codec tokens:
24 successful pairs, one matching UB pair, two rejection pairs, and five
shared internal-failure pairs. The last seven are not semantic passes.
The original six callback failures now succeed. Four additional callback
cases exercise local, nested, shadowed and signed enum definitions.
`independent-enum-results.json` contains 24 pristine comparisons and GCC
`-std=gnu11 -O0` compile/run results; native exit values use the process
exit-code projection. Native stdout/stderr were separately checked empty.
The permanent GCC lane's thirteen admissions are in
`gcc-witness-admission.txt` and its complete B7 receipt.

The constructor checks extract the actual web/BMC record expressions and
replace only their unchanged field-transform functions with identities.
They verify the record addition against fresh OCaml interfaces. They do
not establish that the complete optional backends build with all external
dependencies. The enum signedness probe's OCaml program calls the actual
`AilTypesAux.is_signed_ity`; the Lean snippets call the generated wrapper.
`EnumMapKeyAudit.lean` kernel-checks description-insensitive lookup parity.

`enum/register-route` retains two Core files, their runner, and six results
checking the new failure-register explanation. The signed-int control
executes on fork/pristine; the enum query is rejected by both parsers.
Lean accepts both through `--parse-core`, which performs no execution.
`setup-refusal.json` retains the initial invocation without the mandatory
panic-abort environment variable; the corrected runner sets it explicitly
and `results.json` contains the actual parser comparison.

`arity/focused-captures.tar.gz` contains:

* 54 Core runs: nine initial programs × base/head/pristine × default/typed;
* 24 additional Core runs on four sequence programs with the same matrix;
* 24 rewrite comparisons: six programs × base/head × default/rewrite;
* four Core dumps, with and without typechecking;
* the successful `ArityAudit.lean` transcript and the expected failed
  compilation of the branch's real unit source against the base.

The `seq-weak-mismatch.core` and `seq-strong-mismatch.core` explorations are
parser rejections on all three trees. They are retained for completeness
and are not witnesses for a successful execution or the new fix. The
`unseq-*` variants are accepted and expose operand truncation in typing.
Every capture has the process status recorded in JSON or a status file.
The Core collectors are diagnostic tools; their own exit code does not
mean all inputs succeeded or all engines agreed.

`arity/discarded-error-results.json` contains twelve additional executions
of two witnesses whose surplus operand is `error(<<<surplus>>>, 3)`.
All three engines return the error by default and `Specified(3)` with
`--typecheck-core`, which removes the operand. `run_discarded_error.py`
recreates these cases. `discarded-error-parser-exploration.json` preserves
the first attempt using C-style quotes for the Core diagnostic string;
all twelve of those attempts were parser rejections, not execution evidence.

`ArityAudit.lean` contains 196 runtime checks of the repaired functions,
kernel equations for the new guard and actual substitution behavior, and
two explicitly labeled observations of remaining wrong typing behavior.
Those last observations are audit characterizations, not proposed tests
that future fixes should preserve. Its general worker theorem assumes the
exact generated Boolean length comparison is false; it does not purport
to prove comparator coherence from a propositional length inequality.

`base-unit-plant.source.lean` is the unmodified new unit file from the arity
head. Its compilation against the base exits 1 at the new mismatch and
selector facts. The `sorryAx` diagnostics in that failed compilation are
Lean's error recovery for rejected proofs, not accepted axioms in the
audited head. The actual head probe exits 0 and reports `[propext]` for its
guard theorem.

`integration-merge-tree.txt` is a dry `git merge-tree --write-tree` result,
not a merge. It writes temporary Git objects but changes no branch or
working-tree files. It records conflicts that still need resolution when
the branches are integrated.

## Reproduction

Use isolated checkouts of the stated heads and the repository's build
instructions. All environment-dependent commands below are run through
the container's `scripts/ce`; all Lean invocations use `scripts/capped`
or `scripts/lean_probe.sh`. Never install from an audit worktree into the
shared opam switch.

The build recipe used for each head, from its repository root:

```sh
export DUNE_CACHE=disabled CERB_MEM_MAX=32G
make prelude-src lean-prelude-src
opam exec --switch=. -- dune build --root . --force \
  backend/driver/main.exe cerberus-lib.install cerberus.install
source scripts/common.sh
build_cerberus
build_lean
python3 scripts/ensure_independent_oracle.py
python3 scripts/release.py --mode full --out .tmp/two-range-audit/full
```

For the focused collectors, stage the relevant subdirectory's files under
that checkout's `.tmp/two-range-audit/`, preserving their relative paths.
Run `run_enum_probes.py`, `independent_enum_probes.py`, and
`check_constructors.py` from the enum root. The signedness runner expects
its three `EnumSignAudit-*.lean` snippets in `lean_frontend/.tmp/`.

For arity, run `prepare_core_probes.py`, `run_core_probes.py`, and
`run_sequence_probes.py`, then `run_discarded_error.py`, from the arity root.
Those collectors expect a
sibling `enum-base-20260920` checkout built at the recorded base. The
pristine oracle location is the normal `.validation-foundations` location.
For the kernel/direct-model probe, copy `ArityAudit.lean` to
`lean_frontend/.tmp/`, then from `lean_frontend/` run:

```sh
CERB_MEM_MAX=8G LEAN_ABORT_ON_PANIC=1 \
  ../scripts/lean_probe.sh .tmp/ArityAudit.lean
```

All Core execution/rewrite/dump invocations are retained as argument
arrays in their JSON files. Substitute the new checkout/input paths when
replaying them. The simple standalone commands and the two central
reproducers are also printed in the audit document.

`SHA256SUMS` covers every retained regular file except itself. Raw output
archives preserve original bytes, including ANSI output and whitespace.
Run `python3 verify_evidence.py` inside this directory to check the complete
file inventory, hashes, archived lane receipts, and exact-head full-run
identity assertions without the original audit worktrees.
