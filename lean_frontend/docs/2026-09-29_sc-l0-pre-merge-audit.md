# SC L0 — pre-merge audit of `docs/sc-l0-20260929` (f6fc60d4b..c1cb4f26a)

[AGENT — independent skeptical pre-merge auditor, Claude Fable 5.1 subagent,
2026-09-29.] Fresh reviewer: I authored none of the range. Authorization,
verbatim as relayed by the orchestrator: [USER 2026-09-29] "yes, go ahead with
the audit as proposed". The proposal was a full review of the three-commit
docs range with checks (a)–(f) below plus a fresh full review of the revised
plan and the landed WP1 decision record (ruling 5 of the 2026-09-29 rulings).
Audit worktree: branch `audit/sc-l0-20260929` from `c1cb4f26a`. Nothing on
`docs/sc-l0-20260929` or any other branch was modified. No build was run
(docs-only range; the runtime-ladder waiver is the operator's).

## Verdict: ACCEPT-WITH-FIXES

The range does what it says: the SC plan set is imported byte-for-byte where
it claims to be, the three WP1 records are unchanged apart from their banners
and one de-linked path, every [USER] quote I could source is verbatim,
[AGENT]/[USER] are distinguished throughout, the 2026-09-29 rulings are
reflected in `SC-CONCURRENCY.md`, and I found no obligation of the old plan
dropped or weakened other than by an explicitly attributed [USER] ruling
(one constraint is less specific than before, N1; one forward-carry pointer
is gone, S3).
All 169 relative links resolve, all cited hashes exist and say what is
claimed, `git diff --check` is clean, and no script, gate or baseline file is
touched.

No finding blocks the ff-only landing. The fixes are record-level: one goes
in the landing note (S1); three are small documentation edits (S2–S4) that
the operator may take before the merge (new head, re-sign) or as the first
post-L0 documentation landing. My recommendation [AGENT]: S1 in the landing
note; S2–S4 as one follow-up docs commit, either side of the merge.

## Findings, ranked

### BLOCKER — none.

### SHOULD

**S1 — Commit-message accuracy: "byte-identical" and "no … test … change" are
both looser than the facts.** `a9234c6ef`'s message says "Content is otherwise
byte-identical to 1b15b5b9a" with only `lean_frontend/README.md` and
`lean_frontend/TODO.md` hand-merged. Measured: 41 of the 45 imported paths are
blob-identical to `1b15b5b9a`; FOUR differ, not two — root `README.md` and
`lean_frontend/CLAUDE.md` also differ. For those two the arc's hunk is
applied verbatim at a shifted offset over mainline drift (mainline changed
`README.md` +19/−2 and `lean_frontend/CLAUDE.md` +86/−96 since `e9f9d049f`),
so the added text is exact; the files are not. Separately, all three commit
messages end "no source, test, gate or baseline change", but `a9234c6ef` adds
24 files under `tests/sc-recovery/` (22 `.c`, `provenance.json`, `README.md`).
They are inert: `git grep sc-recovery` outside `lean_frontend/docs`,
`tests/sc-recovery` and the plan returns nothing at `c1cb4f26a` and at
`f6fc60d4b`; the one lane that globs `tests/<folder>/**/*.c`
(`scripts/test_upstream_oracle.py:355`) iterates a fixed tuple
`('minimal', 'coverage', 'debug', 'float', 'bytes', 'libc_exec')`; the corpus
README says, verbatim, "they are not a passing concurrency suite." So the
runtime-ladder waiver's rationale holds. Fix: the landing note should state
"adds an unwired diagnostic input corpus under `tests/sc-recovery/` (no lane
or gate reads it)" and "four pointer files re-merged over mainline drift",
rather than repeating the two claims as written.

**S2 — The technical design still prescribes the fork/wait process that
ruling (2) removed; it has no banner.**
`lean_frontend/docs/2026-09-24_sc-concurrency-design.md:573` (S1 row):
"Resolve positional fork results and upstream's explicit `subst_wait_stack
==> Stack_cons2` refusal under the master plan's evidence/tray/register/[USER]
process before shared-Lem implementation." and `:634-635`: "resolve the
inherited fork/join behaviors under the master plan's
evidence/tray/register/[USER] process". The plan's constraint 4 and S1 row now
say mirror upstream and refuse loudly, with "No shared-model divergence, tray
draft or `shared-model-fix` row is prepared." The plan governs ("Detailed
designs and slice records support it; they do not silently change it"), but
a returning implementer who reads the design's S1 row — which is where the
plan sends them for "concrete transition contracts" — follows the wrong
process. The coordination response, which had the same paragraph
(`:116-120`), got exactly the right banner in `c1cb4f26a`; the design did
not. Fix: a two-line superseded note at the design's S1 row or a top banner
pointing to ruling (2) (docs-only).

**S3 — The plan no longer points at [USER 2026-09-04] "we don't change the lem
structure for ocaml", while constraint 1 mandates shared-Lem S1 code.** Not a
dropped obligation: the old plan attached that reconciliation only to WP1's
experimental factoring (M2), and ruling (1) closes M2 by not landing it.
But `1b15b5b9a` §6 was the plan's only pointer to the 2026-09-04 constraint
(`lean_frontend/docs/2026-09-05_typed-failure-outcomes-design.md:41`,
verbatim, truncated at the semicolon: "**Brief constraints** ([USER
2026-09-04], relayed): "we don't change the lem structure for ocaml" —
Lean-only declares are fine, `.lem` bodies and the OCaml output are not
touched" […]), and S1 will change `.lem`
bodies and the OCaml output by design (architecture constraint 2, ruling 1
"a single stepper in Lem"). M2's second lesson — the WP1 record's stated
reason for co-locating experiment code in `driver.lem` was "The fork-drift
gate requires the generated module set to match upstream", which the review
called "gate avoidance offered as design rationale" — is also not carried.
Fix: one sentence in constraint 1 or the S1 row: ruling (1) authorises
target-symmetric SC semantics in shared `.lem` (the 2026-09-04 constraint was
scoped to Lean-motivated restructuring in the typed-failure pass), and any new
lem module refreshes `scripts/fork_drift_manifest.txt` deliberately rather
than co-locating to avoid the gate.

**S4 — One derived tally in the assessment record does not reproduce.**
`2026-09-29_sc-assessment-and-rulings.md:37-39` says WP1 is "about 500 of
shared-Lem/OCaml changes", labelled "(measured, Opus)". Measured here over
`5ecc0aa33..186392a53` (`git diff --numstat`, restricted to
`frontend/model backend/web ocaml_frontend`; generated OCaml is untracked):

```
2	0	backend/web/instance.ml
17	5	frontend/model/core_reduction.lem
234	13	frontend/model/driver.lem
```

i.e. 253 insertions / 18 deletions over three files — about half the stated
figure. The other tallies in that finding reproduce: WP0 landing
`9bf8cdaa6..5ecc0aa33` has 4584 insertions under `lean_frontend/docs/`
("about 4.6k") and 134 semantics lines (`mem_common.lem` 21, `CerbMem.lean`
+50/−4, `memory/concrete/impl_mem.ml` +37/−1, the three other `impl_mem.ml`
6 each, `memory_model.ml` 8; "about 135"); WP1 has 5951 doc/evidence
insertions ("about 5.8k") and 2240 test/probe/harness insertions ("about
2.1k"). The Opus and Fable reports were not committed (record `:20-21`), so
"measured" here means quoted second-hand. Fix: correct the figure or label it
"as reported, not re-measured".

### NIT

**N1 — Constraint 5 lost the old rule inventory.** `1b15b5b9a:193-194`
"separate value-completion/all-effects frontiers, with
weak/strong/negative/unseq/call and fork/join rules" is now (HEAD `:314-317`)
"value-completion and all-effects frontiers, including Core's negative
actions". The inventory survives in the decision record (`:103-148`) and in
the S2 row; the constraint itself is less specific. Suggest restoring the list
or citing that section.

**N2 — "Lean-only experiments" (plan `:29-30`, `:353`) understates WP1.** The
package also compiled an experimental shared-Lem stepper into both engines
(`driver.lem` `experiment_*`, the subject of M2); the assessment `:41-45` says
so. Suggest "a Lean-only adapter plus an experimental shared-Lem stepper".

**N3 — Execution-decision banner overstates §5 item 1.** The banner says
"§5 item 1's plan to change the inherited fork-result order and `Stack_cons2`
refusal"; §5 item 1 (`:309-317`) says "Investigate … Before changing the
shared model, prepare … evidence, a tray draft and proposed `shared-model-fix`
register row, then obtain explicit [USER] adjudication" — a plan to
investigate and adjudicate, not to change. The substance (that path is
superseded by mirror-and-refuse) is right.

**N4 — Two Terms/constraint glosses could cite their sources.** "Negative
action: a Core memory action whose side effect is not sequenced before the
value it contributes" — `frontend/model/core.lem:152-154` defines it as
`Neg (* only sequenced by \ottkw{letstrong} *)` vs `Pos (* sequenced by
\ottkw{letweak} and \ottkw{letstrong} *)`; the gloss is a fair plain-language
rendering, a cite would anchor it. The examples check out:
`translation.lem:762` is the `Paction Neg` store of §6.5.2.4 postfix
increment/decrement, `:2485` the §6.5.16 assignment store. Constraint 4's
"(reached only through Cerberus's non-ISO C par-block extension)" is true from
C (`translation.lem:4203-4207` `AilSpar → Epar`); Core text is another entry
(`lean_frontend/CoreParser.lean:1977-1981` parses `par`). The review's
phrasing "reachable from the C front end, but only through…" was exact.

**N5 — Pre-existing tense/staleness in §4.** The L1 row (`:387`) still reads
as future ("As soon as minimal load/store receipts … pass their independent
audit") while §6 says L1/WP0 landed at `5ecc0aa33`; item 5 (`:429`)
"Synchronize the coordination branch" is stale once item 1's post-L0 policy
(arc/sc-concurrency parked) applies. Both were in `1b15b5b9a`.

**N6 — The hand-merge is not purely additive.** `lean_frontend/README.md`
replaces mainline's "Concurrency work is parked; the announcement concerns"
with "Concurrency is not part of the supported product; the announcement
concerns", and `lean_frontend/TODO.md` drops "A replacement needs a separate
charter." Both are correct now that the plan exists; the message's "keeping
mainline's text … and adding the plan pointer" is slightly loose. The
[USER 2026-09-24] quote in TODO.md is preserved verbatim.

**N7 — Imported 2026-09-25 records carry unlabelled `[USER]` tags.**
`2026-09-25_sc-concurrency-plan-review.md:7`, `…-plan-rereview.md:8`,
`…-review-response.md:5`, `…-coordination-response.md:33`: `[USER]` followed
by a paraphrase without quotation marks or a "paraphrased" label. Pre-existing
on `arc/sc-concurrency` (blob-identical), not introduced by this range; the
assessment's finding 6 listed only the plan's and `SC-WP1.md`'s instances.

**N8 — Chat-sourced quotes I could not verify.** Assessment `:4-5` (the
operator's request), `:97-113` (the six questions "as put", from the
uncommitted assessment), `:88-93` (Fable's re-run result lines, from the
uncommitted Fable report); the decision record's `[USER, 2026-09-27] "Push
forward to the end of WP1."` and the review's `[USER 2026-09-28] "WP1 + plan
update", "Targeted re-runs"` (both imported unchanged from their committed
sources). None is presented as more than it is.

**N9 — Not re-measured.** Assessment `:70-71` "a 206-line `experiment_*`
block" (driver.lem's total WP1 delta is +234/−13; the block bound was not
derived here).

## What I measured, and how

Worktree: `/home/dev/projects/cerberus-lean-proj/worktrees/cerberus-lean-docs/sc-l0-20260929`
at `c1cb4f26a` (clean). Range `f6fc60d4b..c1cb4f26a` = `a9234c6ef`,
`8a0e0c0dd`, `c1cb4f26a`; `a9234c6ef^` = `f6fc60d4b` (cut from mainline).
Branch tips at audit time (`git rev-parse --short=9`): `arc/sc-wp1`
`186392a53`, `review/sc-wp1-20260928` `1c7e52fad`, `arc/sc-concurrency`
`1b15b5b9a`, `mdd/cerberus-lean` `f6fc60d4b`, `docs/sc-l0-20260929`
`c1cb4f26a`. `git merge-base 1b15b5b9a f6fc60d4b` = `e9f9d049f`.

Method note: a first `git diff … -- $PATHS` returned empty because zsh does
not word-split an unquoted variable; the check was redone per file with blob
ids (below). Nothing was concluded from the empty run.

### (a) Import fidelity

Per-path blob comparison, `git rev-parse a9234c6ef:$p` vs
`1b15b5b9a:$p` for all 45 paths of `a9234c6ef`: 41 `SAME`; `DIFF` for
`README.md`, `lean_frontend/CLAUDE.md`, `lean_frontend/README.md`,
`lean_frontend/TODO.md`. `git diff --stat a9234c6ef 1b15b5b9a -- <45 paths>`
(via `xargs`):

```
 README.md               |  21 +-----
 lean_frontend/CLAUDE.md | 182 +++++++++++++++++++++++++-----------------------
 lean_frontend/README.md | 146 +++++++-------------------------------
 lean_frontend/TODO.md   | 133 ++++++++++++++++++-----------------
 4 files changed, 192 insertions(+), 290 deletions(-)
```

For `README.md`, `lean_frontend/CLAUDE.md`, `CLAUDE.md`,
`2026-09-05_master-plan.md`, `2026-09-06_concurrency-integration-charter.md`:
`git diff f6fc60d4b a9234c6ef -- <f>` (import over mainline) and
`git diff e9f9d049f 1b15b5b9a -- <f>` (arc over base) add the same text; the
first two at different offsets (mainline drift), the last three at identical
offsets (no mainline drift; blob-identical). The set of paths the arc changed
(`git diff --name-status e9f9d049f 1b15b5b9a`, 45 entries) equals the import's
set; nothing omitted, nothing extra.

`lean_frontend/README.md` / `TODO.md`: `git diff f6fc60d4b a9234c6ef` shows
mainline's 2026-09-25 health warning, documentation-check block and the
[USER 2026-09-24] quote retained; the SC pointer added; the rewording in N6.

### (b) WP1 records

```
git diff 186392a53:lean_frontend/docs/2026-09-27_sc-wp1-execution-decision.md 8a0e0c0dd:<same>
git diff 186392a53:lean_frontend/docs/2026-09-28_sc-wp1-review-response.md   8a0e0c0dd:<same>
git diff 1c7e52fad:lean_frontend/docs/2026-09-28_sc-wp1-independent-review.md 8a0e0c0dd:<same>
```

Execution decision: the 11-line banner plus exactly one hunk,
`-[`decision-validation.json`](sc-wp1-evidence/decision-validation.json);` →
`+`decision-validation.json` (on `arc/sc-wp1`);`. Review response and
independent review: banner only. `186392a53` and `1c7e52fad` are the current
tips of their branches; `lean_frontend/docs/sc-wp1-evidence/` exists on both
(tree `bb71f575b…` at `186392a53`) and is absent from the range. The three
earlier WP1 working records (`2026-09-25_sc-wp1-boundary-investigation.md`,
`2026-09-26_sc-wp1-bounded-stepping.md`,
`2026-09-26_sc-wp1-followup-measurements.md`) and `SC-WP1.md` stay on
`arc/sc-wp1`, as the message says. Banner content checked against the review:
M1 heading (`:94`) is the fork/wait upstream-behaviour finding, M2 (`:139`) is
experiment code in shared Lem; verdict (a) `:676` "WP1 decision — ACCEPT";
the banners' one-line summaries are faithful (N3 aside).

### (c) [USER] quotes

Assessment `:117-119` and `:131-132` are the operator's two 2026-09-29
answers as given to me, verbatim, line-wrapped. Plan `:306`
"mirror and refuse seems safest", `:386` "land on mainline seems reasonable",
`:475` "we're doing some bug hunting first on the main-line agent",
coordination banner `:4-6` "yeah, agree on (3) although we're doing some bug
hunting first on the main-line agent": all exact substrings. Plan `:104-107`
2026-09-25 quote = `2026-09-25_sc-semantics-mvp-scope.md:5` verbatim. Plan
`:96` and `:427` — the two lines the assessment's finding 6 named at
`1b15b5b9a:12-16` and `:316` (confirmed unlabelled there) — are now labelled
paraphrases. `SC-WP1.md:3,6` at `186392a53` confirmed unlabelled paraphrases
(not in range). Every added `[USER` line in the range was enumerated
(`git diff f6fc60d4b c1cb4f26a | grep '^+.*\[USER'`: 17 in the plan, 18 in the
independent review, 4/3/3/3 in the coordination response, assessment,
review response, execution decision, 6 across the five imported 2026-09-24/25
records); those with quotation marks are listed above or in N8. The
assessment's §3 consequence column is tagged [AGENT] (`:136-139`); the plan
tags the sequencing reading `[AGENT reading]` (`:475`) and the record-weight
details `[AGENT]` (`:401-403`). No agent decision is presented as the
operator's.

### (d) Rulings and obligations, `1b15b5b9a:SC-CONCURRENCY.md` vs HEAD

Rulings → plan: (1) constraint 1 + WP1/S1 rows + §6 WP1 row; (2) constraint 4
+ S1 row; (3) §6 coordination row + coordination-response banner, the
amendment attributed to [AGENT] follow-up and the sequencing reading tagged
[AGENT]; (4) §4 L0 row + §6 L0 row; (5) L0 row and §6 next action; (6)
summary, Terms, §4 item 2. All six present and attributed.

Obligation-by-obligation (old line → new line; verdict):

| Old obligation (`1b15b5b9a`) | HEAD | Verdict |
|---|---|---|
| WP1 §: selected Core stepping + narrowly justified pending ops (`:183-186`) | constraint 1–2 (`:288-302`) | carried |
| `SeqRMW` yields between read/update/store; updater uses current memory (`:186-187`) | constraint 2 | carried ("never a saved snapshot") |
| same-thread C call outside the pair (`:187-188`) | constraint 2 "(sibling operand, call)" | carried |
| neither ownership nor scheduler invents source order (`:188-189`) | constraint 2 last sentence + arch. constraint 3 | carried |
| child completion rewriting an owned parent waits (`:189-190`) | constraint 2 | carried |
| S1 carries primitive ND alternatives per owner; preserves lifecycle (`:190-191`) | constraint 3; S1 row "initialization/finalization" | carried |
| frontiers with weak/strong/negative/unseq/call/fork-join rules (`:193-194`) | constraint 5 | carried, less specific (N1) |
| retained roots: publications, per-location summaries (`:194-195`) | Terms "Retained summary"; constraint 5 | carried |
| kernel laws abstract; unseq/exclusion lemmas local; no Core→reference link (`:195-200`) | §2 "How WP1 met this" (`:266-272`); §6 last row | carried, sharpened |
| coverage hardest; reopen if S1/S2 replay fails (`:200-202`) | `:340-341`, summary "Hardest open problems" | carried, plus sb recovery |
| S1 must resolve fork order / `Stack_cons2` via evidence+tray+register+[USER] (`:204-212`) | constraint 4: mirror and refuse, none of that prepared | changed by [USER 2026-09-29] ruling (2), attributed |
| S1: retained output, env growth under negative hoisting, no numeric cutoff, churn with real child errno (`:214-223`) | constraint 6 | carried |
| scalar theorem domain, `each_empty … undefined`, resources non-circular, fences via `sc_fenced_memory_model`, S4 conservativity, no `true` stubs / `bigthm` (`:225-237`) | constraint 7 | carried verbatim in substance |
| §3 WP1 row exit witnesses (`:249`) | row closed as decision; assessment §1 named for what evidence establishes | closed by ruling (1); the review's §3.2 records each witness "Met" at feasibility scope with limits |
| §3 S1 row "resolve … through the evidence/tray/register/[USER] process" (`:250`) | "Mirror upstream's … refusal, reporting a classified unsupported outcome" | ruling (2) |
| §3 S1 row remainder; S2–S5, WP-C rows (`:250-255`) | `:354-359` | identical text |
| §4 L0 row (`:282`) | `:386` | now consistent with §6 (was the contradiction) |
| §4 item 1 long-lived branch rule (`:290-295`) | `:394-400` | carried; arc/sc-concurrency parked post-L0 |
| §4 item 2 acceptance-record contents (`:296-300`) | `:401-411` | list identical; "one" record per landing per ruling (6), details [AGENT] |
| §4 item 5 incl. [USER 2026-09-25] (`:313-320`) | `:424-431` | carried; paraphrase labelled; overseer→orchestrator (0 "overseer" remain) |
| §6 M2 condition: reconcile with September 4 ruling or isolate (`:369-375`) | M2 closed by not landing | closed by ruling (1); pointer to the 2026-09-04 constraint gone (S3) |
| §6 "Later receipt producers accompany actual execution consumers" (`:362`) | §4 L2 row `:388` | carried there |
| §6 `e1c1d2c3a` pointer to the WP0 candidate record (`:387-388`) | dropped | historical pointer; WP0 row says "Read the mainline WP0 records" |
| header "No executable SC implementation has landed" (`:10`) | summary "No concurrency yet", §1 "No public SC support exists" | carried |

Technical accuracy of the new Summary/Terms against the Lem sources:
`core_run_aux.lem:101-102` `| Stack_cons2 _ _ _ -> error "subst_wait_stack
==> Stack_cons2"` (exact); `cmm_csem.lem:2584` `SC_memory_model` with field
`undefined = locks_only_undefined_behaviour`, `:2563` `SC_condition`, `:2199`
`sc_fenced_memory_model`, `:646` `each_empty`, `:2855` `theorem {hol;
isabelle; tex} bigthm` (not Lean-targeted; "not used" is right);
`core_reduction.lem:1268-1371` handles `Neg` with `fresh_excluded_id` /
`add_exclusion` (the "recording exclusions" gloss); F1–F4 match the design's
§6 table `:433-436` word for word in substance; the design has a §7 "Scale is
an early acceptance condition" (the "§7 technical-design probes").

### (e) Readability and consistency

Status table vs sections: Summary "Where we are" = §6 (WP0 landed
`5ecc0aa33`; WP1 closed as decision; S1 not started; L0 candidate not
landed). §6 "Mainline base" claims verified: `5ecc0aa33`, `fa03a68a1`,
`d61dcb9c4`, `d62f52121` are ancestors of `f6fc60d4b`; `5ecc0aa33..f6fc60d4b`
contains `27f381b63 fix(CerbFS): refuse non-plain paths…` and `fa03a68a1
landing note … arc/contract-enforcement`. Lem `c2a68e79b…` is a commit in
`lem-lean` and `scripts/fork_drift_manifest.txt:1` records `lem-pin 67ec5de7
-> c2a68e79`. Every hash cited in the plan and assessment exists with the
described subject: `5ecc0aa33 af1342d32 186392a53 1c7e52fad a740c48ae
fa03a68a1 d61dcb9c4 3cb7f7587 0e3f67cd2 a997d49ce 2d445ea2f 06648fa94
d62f52121 f6fc60d4b 1b15b5b9a e9f9d049f 631382a9d… 4860f0ef0…
bb487dda7…`; `af1342d32` is an ancestor of `186392a53`, `a740c48ae` of
`1b15b5b9a`. Assessment finding 8 reproduces exactly: `git rev-list --count
e9f9d049f..d62f52121` = 45; `git rev-list --count 5ecc0aa33..d62f52121` = 4
(merge-base of `arc/sc-wp1` with mainline is `5ecc0aa33`). Finding 6's "17
commit hashes" = the 17 distinct hashes in `1b15b5b9a`'s plan. Finding 5's
"68–69 `ENTERING` lines" = review S1 `:187` "(68/69)". Finding 7's "four
plants" = review §6.2 P1–P4; "a real unrecorded oracle change" = review S1.

Links: python3 over every `.md` in the range, `](target)` with anchors
stripped, resolved relative to each file: `relative links checked: 169`,
`broken: 0`. Whitespace: `git diff --check f6fc60d4b c1cb4f26a` exit 0.

Diagnostic seeds: 22 `.c` files, 21 `sha256` entries in `provenance.json`,
README `:13` names `prefix/member-before-race-loop.c` as the one new input —
matches "21 donor inputs … one new input".

### (f) File classes

`git diff --name-status f6fc60d4b c1cb4f26a`: 18 A under
`lean_frontend/docs/` (+`SC-CONCURRENCY.md`), 24 A under
`tests/sc-recovery/`, 7 M pointer/plan files. No `scripts/`, `frontend/`,
`lean_frontend/*.lean`, `lakefile`, manifest or baseline change. Gate wiring
of the corpus: none (S1).

## Fresh full review of the revised plan and the WP1 decision record (ruling 5)

The plan is now readable by a returning human: the summary states goal,
history, position, the chosen mechanism, next step and the two hardest
problems in plain words; the Terms section defines what the body uses; the
provenance block distinguishes verbatim from paraphrase. The seven
constraints are checkable statements, each traceable to the decision record
or a ruling. The one structural weakness is that the supporting design is
now out of step on fork/wait (S2) and the plan's own forward-carry of the
2026-09-04 constraint is gone (S3). The decision record, read on mainline
with its banner, is honest about limits (its §2 table and the review's §3.2
say "Met" only at feasibility-instrument scope); the banner's one overstatement
is N3. The assessment record is candid (finding 3's "met it by rewording",
finding 2's "transfer to S1 as a specification, not as validated code") and
its provenance discipline is good; its one non-reproducing tally is S4.

## What I did not check

- Any build, lane or gate (docs-only waiver; none run, none needed to
  support a finding here).
- The imported 2026-09-24/25 records' technical content beyond blob identity
  with `1b15b5b9a` and the [USER]-tag sweep (N7); they were reviewed on their
  own branch (`a740c48ae` re-review).
- The WP1 records' technical claims beyond banner fidelity and the passages
  cited above; they were reviewed at `1c7e52fad`.
- The Opus/Fable assessment reports (uncommitted); every "measured" item I
  could re-derive from Git is listed under (e) and S4.
- Whether `tests/sc-recovery` inputs should eventually be gate-read; out of
  scope for L0 ("diagnostic, not a passing SC suite").

## Landing recommendation [AGENT]

Ff-only merge of exactly `c1cb4f26a` is acceptable with S1 recorded in the
landing note. S2–S4 (and N1–N5 at the author's discretion) fit one docs
commit; if the operator prefers them before the merge, the candidate head
changes and the per-merge sign-off is re-asked on the new head. Merge and
push authority rest with the operator; nothing here is a sign-off.
