# Codex charter — the outcome protocol, slices S1 and S2 (Q-B; cerberus-caesium note 2 §A–§C) (2026-10-18, rev 4 after three reviews)

**Status: DISPATCH-GATED.** Executes only after (i) the design note `docs/2026-10-17_outcome-protocol-design.md` (branch
`design/outcome-protocol-20261017`, `99a8ddb78` plus the orchestrator's errata section) has had a fresh full review by a new reviewer
and been accepted by the operator with its errata resolved, and (ii) the operator has ruled on its §6 open questions. The orchestrator
fills §0's blanks at dispatch; until then no worker is briefed. Rev 2 incorporates review findings 6, 7, 8, 9, 13, 14.

**Branch:** `arc/outcome-protocol` · **worktree:** `worktrees/cerberus-lean-arc/outcome-protocol` (created primed at dispatch from a
mainline carrying this charter AND the accepted design note). **Worker:** one Codex worker (S1 then S2). Never merges, never pushes,
never edits lem-lean.

## 0. Goal, success condition, rulings

**Goal.** Every non-verdict way a run ends carries its CLASS on the wire in one grammar, decided by one classifier that the lanes and
the consumers share. S1 builds the seam, the classifier and its plants, and migrates the typed kills; S2 migrates the declared refusals
and the CLI/runtime refusals. No verdict changes anywhere.

**The transitional contract (review finding 6), which the consumer note MUST carry as a table:**

| consumer message family (note 2) | accurate from | until then reads as |
|---|---|---|
| refusals (`formatFixed`, CerbFS, PNVI, CLI) | S2 | the old prefix-distinguished panic |
| typed kills (D `memcmp`, the 7 C-TF1 sites) | S1 | — |
| hand-written pure mirrors (A1, A2, A6, A7, `truncToInt` in A5) | **S3** (a later charter) | `SHARED_CRASH` — a documented misattribution (hand-written ≠ shared) |
| shared-model `failwith`s (A3, A4, C, `Formatted` in A5) | S1 | `SHARED_CRASH` (correct) |
| the stack overflow (B) | the stack-ceiling slice pins the text | RED (honest) |

So S1–S2's consumer exit is: the consumer classifies the FAMILIES THAT S1 AND S2 MIGRATE, demonstrated on one program each, and is
told exactly which families wait for S3. No charter claims the UPSTREAM/SHARED distinction for the pure mirrors before S3.

**Success condition (S1):** the seam exists with the builder API of the design §2 and its properties (never a value, never a free class
string, fail-closed); `scripts/observations.py` has the classifier of §3 AS AMENDED BY THE ERRATA (in particular: a bare exit 137 is NOT
`RESOURCE/cap` — cap evidence is required and an unexplained 137 stays RED; an envelope inside an `Error {msg}` line or any program-data
position is ordinary data, a VERDICT, never a stop and never RED for that reason), with the CLI action and the plant suite in which each
class's forged envelope is rejected on every channel the admission matrix does not admit it on, native-exit-137 and signal-without-OOM
controls included, and an unclassifiable stop is RED; the typed-kill sites emit the envelope; Tier A green, no baseline row moved.
**Success condition (S2):** the 37 declared refusals and the CLI/runtime refusals emit the envelope; `pnvi_lane.py` classifies through
the shared classifier with its baseline unchanged; the row-1 CLI witness scripts re-pinned; the failure-reach register re-sealed for the
affected rows — their `msg` KEYS AND SEALS change (review finding 9; the design §4 authorises exactly that), their reach, position,
need/invariant/witness columns do not, and each old-to-new mapping is listed in the commit; Tier A green; Tier B row 5
(`test_immaculate.sh`, per the design §4) green; the consumer demonstration per the transitional table.

**Rulings (filled at dispatch; paraphrased, tagged):**
- [USER ____] design note accepted at commit ____ (reviewer: ____; errata resolved: ____).
- [USER ____] class names: ____ · allocator OOM stays a verdict: ____ · CLI usage errors exit code: ____ · the 12 switch kills' channel:
  ____ · `Boundary` enumeration: ____ · the register speedbump: ____ · `INVARIANT` on the driver channel: ____ · bare exit 137: RED (errata).
- Standing: fail-closed and fail-noisy; mirror-OCaml doctrine; no magic values; nothing new out of policy; no verbatim quotes of the operator.

## 1. What is known

The accepted design note is the fact table (§1 classes and grammar, §2 builder, §3 classifier and adoption, §4 slices and moving gates,
§5 R1 mapping, §7 measured commands, plus the errata). The inventory `docs/2026-10-08_stop-paths-inventory.md` §3–§4 lists every site.
Where the tree has moved since the design's base, the tree wins and the record says so.

## 2. Deliverables (ordered)

**D0 — Base.** Tier A on the untouched worktree; today's output of every stop kind on one witness each (the design §1.2 table re-measured).
**D1 (S1) — The seam** and its unit test. Tier A; commit.
**D2 (S1) — The classifier and plants**, errata applied. Tier A; commit.
**D3 (S1) — The typed kills** through the seam; Tier A; then the S1 SLICE EXIT: Tier B (`python3 scripts/release.py --mode full`)
quoted, the S1 record section, and the orchestrator's independent Tier B at that boundary before S2 starts (`scripts/LADDER.md`
requires Tier B at slice boundaries, not only at close-out); commit.
**D4 (S2) — The refusals and the CLI/runtime refusals**; `pnvi_lane.py` as a wrapper; CLI witness scripts; register keys and seals;
Tier A; commit. Close-out: Tier B (`python3 scripts/release.py --mode full`, which includes row 5 as the design §4 requires), quoted.
**D5 — Documents.** `docs/2026-10-18_outcome-protocol-s1-s2-record.md`; `CONTRACT.md` §1 (the class vocabulary beside the four outcome
kinds); `VALIDATION.md` §4 (the classifier as the codec's rule); `LADDER.md` rows touched; consumer notes for cerberus-caesium (with the
transitional table) and cerberus-sl (its five relied-on items re-checked).

## 3. Flex — what you decide, and when to stop instead

- Yours: file names and layout within the accepted design; the order of sites within a slice; the plant suite's shape; splitting S2.
- Not yours: any class, grammar or exit-code decision the design fixed or the operator ruled; any verdict; any site outside S1/S2; the pins;
  lem-lean.
- **Stop and report when:** a baseline row moves (the design predicts none); a site cannot be migrated without a type change (S3/WP2
  territory — list it); the design is found wrong on contact (say where, propose the amendment, do not improvise a class); the tripwire;
  you are done.

## 4. Rules (binding)

Environment, hand-written-copy synchronisation (`make lean-prelude-src` after any `lean_frontend/*.lean` edit — the new seam, `CerbMem`,
`CerbFS`, `Main` are manifest-copied — before every capped `lake build`; `handwritten_copy.manifest` registration for the new seam), checks
(Tier A before every commit, per `scripts/LADDER.md`'s rule for commits and worker-boundary claims; Tier B at EACH slice exit, S1 and
S2; the orchestrator re-runs Tier A at every boundary and Tier B at each slice exit and before landing), provenance, no trust gaps — as the translation charter §4 states them, EXCEPT
its `.lem` regeneration, oracle-rebuild and manifest instructions (no `.lem` changes; the design requires the fork-drift manifest unchanged). File fence: the files the design §4 names for
S1 and S2, plus the records and notes of D5.

## 5. Reading list

`docs/2026-10-17_outcome-protocol-design.md` (whole, with errata) · `docs/2026-10-08_stop-paths-inventory.md` §3–§5 · `CONTRACT.md` §1 ·
`VALIDATION.md` §4 · `scripts/observations.py` (`parse` at `:278-286`: what 137 and 124 mean today) · `scripts/LADDER.md:144-150` (the
OOM witness rule) · `scripts/pnvi_lane.py`, `check_cli_refusals.sh`, `check_runtime_resolution.sh` · `CerbMem.lean`, `CerbFS.lean`,
`Main.lean` · `scripts/failure_reach_register.txt:18-26` (keys and seals) · `docs/2026-10-18_codex-charters-review.md` (findings 6–9) ·
the consumer's ask: note 2 §A–§C and its agent's list, item 4.
