# CoreNice / Cerberus-Nice integration

`feature/cerberus-nice` is a research integration branch. Its first deliverable
is the complete, initially unchanged CoreNice path: a distinct AST, typed-AIL
lowering, runtime loading, evaluator and driver, with bidirectional choice-tape
and trace comparisons. Nice semantic changes follow that baseline.

The reviewed comesfrom, breakpoint, repair and saturation milestones landed
locally on this integration branch on 2026-11-17 at `e75c895c0`. The landing
was a fast-forward of the tested tree; no remote push or consumer re-pin was
performed. The evidence and limits below remain those of each named checkpoint.

The pathway was named CoreB through `727b5f2a3`; it is now CoreNice. The
rename covers the Lean namespace, build targets, source directories and tools.
That rename introduced no Nice semantic changes. Earlier measurements below belong to
the explicitly recorded pre-rename revisions and binaries.

Commands now use `corenice-*`, `--corenice-bin` and `--corenice-build`.
Choice protocol version 2 names the build identity `coreNiceBuild`; old
ephemeral tapes must be regenerated. No compatibility aliases are installed.

Start with the [CoreNice scope](corenice-baseline-scope.md), then the
[roadmap](cerberus-nice-roadmap.md). The [design](cerberus-nice-design.md)
explains the later breakpoint/checking experiments. The
[scope review](corenice-baseline-review.md) records independent scrutiny of the
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
workflow, not a Nice equivalence claim.

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

The [baseline review](interpreter-review.md) records that earlier evidence and
its limitations. The first semantic experiment, [checked incoming jumps
(`comesfrom`)](comesfrom.md), is now implemented on the milestone branch
`corenice/comesfrom`. Its [checkpoint](comesfrom-checkpoint.md) describes the
actual AST/rule changes, structural tightening, differential evidence, limits
and a proposed local proof scope. Ordinary runs remain subject to exact
comparison; deliberate metadata corruptions exercise typed `NiceFault`.
The [breakpoint milestone](breakpoints-checkpoint.md) is implemented on
`corenice/breakpoints`, governed by its [charter](breakpoints-charter.md). It adds
restricted strong-tail syntax, explicit resumable driver phases, retained choice
sessions and AIL composition sites. Its executable heap-midpoint demonstration
and [AIL/Nice/Caesium mapping](breakpoint-composition.md) motivate a later
simulation sequence rule. This branch remains an experimental checkpoint;
differential validation precedes the broad proof effort.
Follow-up work on `corenice/checkpoint-semantics-repair` gives those sites
precise normalized-AIL roles and typed origins. The
[repair assessment](checkpoint-semantics-repair.md) records focused phase tests
and removal of the inherited inactive evaluator. The normal and resumable C
drivers use the context-based reducer inherited from upstream and mainline.
The [landing review](breakpoints-landing-review.md) records the independent
restart audit, current focused results and the disposition of the
configuration question. It recommends research feature integration; approval
was subsequently given and the reviewed work is now integrated locally.
The subsequent [saturation experiment](breakpoint-saturation.md), on
`corenice/breakpoint-saturation`, adds linked procedure/label-entry cuts and
explicit call-return cuts. `corenice-saturated` compares this variant against
Core while the original AIL composition-cut runner remains available.

The explored [integer-representability guard](conversion-guard.md) is parked
on `plan/corenice-conversion-guard`; its runtime mechanism has been reviewed,
but a structural generation invariant making the checks redundant has not
been identified. The standalone [extension-selection criterion](generation-invariants.md)
makes that requirement explicit. No guard implementation has begun. The
[generator-structure assessment](generator-structure-candidates.md) ranks
further candidates, led by identity-forwarding label interfaces and ordered
lifetime-transfer plans; these remain proposals, not implemented features.

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
