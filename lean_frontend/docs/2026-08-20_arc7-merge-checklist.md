# Arc 7 merge checklist (awaiting operator sign-off — do not merge without it)

SINGLE-REPO merge this arc: **lem-lean is untouched** — zero commits on
any lem branch, and the pins never moved. Verified at S5b close-prep:
Lake manifest LemLib rev `bd7e2eb` (lakefile.toml rev `mdd/lean-backend`
resolves to it) = `deps/lem-pinned` HEAD `bd7e2eb` = the opam pin — all
three still at the arc-6 close state, so there is NO pin dance: no lem
merge, no re-pin, no `lake update LemLib`, no opam upgrade.

The arc branch is `arc/layer2` (cerberus-lean), 35 commits over the
arc-6 close (`mdd/cerberus-lean` @ `78ee1d520`, verified still the
merge base at S5b), INCLUDING the 9 spike/relsem commits
(rebased onto the arc branch at S1 per D2 — spike history is IN this
arc's history). Head at
checklist time: `798431ebf` (D9); S5b close-prep commits follow it.
Audit-disposition commits (2 adversarial audits, in progress) land
before the merge ask is made.

Order (ff-only, exactly):

1. **Pre-merge state check** (cerberus-lean primary, parked on
   `mdd/cerberus-lean`): confirm the mainline has not moved since the
   arc branched; if it has, rebase the arc branch, re-run the gate,
   re-ask (playbook).
2. cerberus-lean primary: `git merge --ff-only arc/layer2`.
3. **POST-MERGE REBUILD ON THE PRIMARY — NOT OPTIONAL THIS ARC (the
   toolchain bump):** the primary's build state is 4.29-era; the merge
   brings lean-toolchain v4.32.2 and **leanc changed with the
   toolchain**, so stale `native/*.o` are guaranteed. Run, in order:
   - `source scripts/env.sh` (project env; offline redirects — the
     iris/Qq/batteries pins resolve via deps/gitconfig to local paths);
   - `make lean-prelude-src` (regenerates from the .lem declares — the
     opam lem is unchanged, safe);
   - `make lean-native-obj` (**required**: leanc changed; the
     fresh-counter floor assertion FAIL-STOPs on stale .o — this is the
     gotcha that fired at the arc-4 merge);
   - full `lake build` through `scripts/capped` (first 4.32 build on
     the primary is cold — expect the full ~595-job elaboration,
     including the in-build RelSem audit + statement gate).
4. **Post-merge certification** (all through `scripts/capped` where
   lake/lean is invoked): Tier A per scripts/LADDER.md **+ the
   statement gate** (in-build — a green `lake build` in step 3 already
   ran it; re-confirm its "slate statements fuel-opsem-clean" line in
   the build log) **+ `./scripts/test_verify.sh`** (23/23) **+ one
   battery slice** (`test_libxml2.sh` slice 00 at minimum; full Tier B
   battery if time permits) + `test_exec.sh tests/ci` reporting sweep
   (not re-run mid-arc; re-baseline the report).
5. **spike/relsem branch disposition — operator's call:** its 9
   commits are INCLUDED in this arc's history via the S1 graft (rebase
   — same content, new ids, e.g. spike `7bd884ad3` = arc `1567ab997`),
   so the branch is redundant as code; it can be DELETED or KEPT as
   the historical record. Either way it must not be merged separately.
   The spike worktree (if still present) can be pruned.
6. **Container-doc updates** (operator-run or operator-approved;
   container CLAUDE.md is outside the repo):
   - CLAUDE.md arcs line: arc 7 (Layer-2 bridge: T1–T4 first theorems,
     adequacy, toolchain 4.32.2, CerbND/CerbMem totalization) merged;
     "No arc currently open" pointer updated; arc-8 queue per the
     results doc's pricing section.
   - CLAUDE.md gates line: totality gate now 16 generated modules +
     CerbND; in-build RelSem audit + statement-TCB gate; test_verify;
     capped discipline (already partially recorded via D7/D8).
   - CLAUDE.md toolchain note: cerberus-lean Lean side is now 4.32.2
     (the "Lean 4.29.0" build line + elan note); `make lean-native-obj`
     reminder unchanged.
   - ROADMAP: Layer 2/3 phase status — **EXISTS, first theorems
     proved** (Layer 1 substrate + Layer 2 relational + Layer 3
     minimal iris coupling + adequacy + T1–T4; T5 and the Q4
     refinement are the open edges).
7. **Next-network-window reminders** (do NOT gate the merge; recorded
   in deps/gitconfig too):
   - create `deps/mirrors/iris-lean.git` (bare mirror of the pinned
     iris-lean) and re-point the deps/gitconfig redirect at it (D6);
   - refresh the other mirrors while at it; `git push` of the merged
     mainline is a separate operator-gated action.

Validation gate at every step: Tier A per LADDER.md; step 4 is the full
post-merge certification. The merge ask is unconditional — audits must
be dispositioned first; the decision is the operator's.
