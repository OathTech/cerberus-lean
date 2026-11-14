# CoreB / Cerberus-Nice integration

`feature/cerberus-nice` is a research integration branch. Its first deliverable
is the complete, initially unchanged CoreB path: a distinct AST, typed-AIL
lowering, runtime loading, evaluator and driver, with bidirectional choice-tape
and trace comparisons. Nice semantic changes follow that baseline.

Start with the [CoreB scope](coreb-baseline-scope.md), then the
[roadmap](cerberus-nice-roadmap.md). The [design](cerberus-nice-design.md)
explains the later breakpoint/checking experiments. The
[scope review](coreb-baseline-review.md) records independent scrutiny of the
proposal and its remaining uncertainties.

## Branch and build ownership

This clone lives at `deps/cerberus-lean` in the cerberus-caesium workspace. It
owns its Git database, generated sources and build directories. Milestone
branches/worktrees derive from this integration branch and stay within that
workspace. The installed refinedc-lean provider remains a separate dependency.

Integration base: `8fa3050bf73fe92803f56c49ca53ed00d76aee88`.
Lem/LemLib: `2220010bc25f0c5682d8200f016e786ee66d65c6`; Lean: 4.35.0.
The ordinary [provider build instructions](../../README.md#build-and-run-one-differential-test)
apply. Use project-local provisioning; do not install into another checkout's
switch or link to its mutable build directories. The installed consumer's
older Lem is not the generator for this base.

The eventual draft PR targets `mdd/cerberus-lean` for discussion. No mainline
merge or consumer re-pin is authorized. Use focused compilation, behavior and
instrument checks during development; full relevant trust checks belong at
actual theorem, landing or shipping claims. This is the agreed research
workflow, not a claim that the baseline or a Nice equivalence theorem exists.

## Current evidence and next experiment

The [interpreter and runner](interpreter-runner.md) contain the current build,
smoke commands and measured limits. Both complete target paths execute real C,
with bidirectional choice replay, passive memory/output observations, structural
artifact comparison and calibration against the existing runner. The frozen
[generated campaign](campaign.md) passed 1,000 defined inputs and 2,000 distinct
input/tape pairs. Six [built source controls](source-mutations.md) exercise real
differences, a harmless extra step and native failure. The optional
[stutter comparison](stutter-comparison.md) permits extra nonbranching steps
while retaining genuine choice barriers. Exact comparison remains the default.

This is the tested baseline tool for beginning Nice AST/interpreter changes.
The [review](interpreter-review.md) records the evidence and limitations. No
Nice checkpoint or checked-control AST node has been introduced yet; future
nodes and new observation channels need explicit semantics and admission rules.

The [type-separation record](type-separation.md) preserves the earlier first
checkpoint. Neither checkpoint is a general equivalence result.

## Planning provenance

The four documents were imported from cerberus-caesium
`c73f459b2` on `plan/cerberus-nice-restart`. The independent scope review names
its earlier parent revision explicitly. Transport edits describe the independent
clone, integration status and parent-only archive/review references; they do
not change the technical scope or transfer old prototype test results.

The parent repository retains its earlier proposal and archived prototype.
This directory is the implementation branch's working plan from this point.

* [USER, 2026-11-14] Keep development in an independent clone inside the
  approved cerberus-caesium workspace, rather than modifying the sibling
  development checkout or broadening sandbox access.
