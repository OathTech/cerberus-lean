# Note to the SC track — coordinating with the next-phase plan (2026-09-27)

> **Landed on mainline 2026-09-29 (from `docs/sc-coordination-20260927`
> `49c3162af`) so the claims register below has one shared home.** Outcome:
> the SC track's [response](2026-09-28_sc-next-phase-coordination-response.md)
> was accepted with one amendment [USER 2026-09-29]. Text unchanged apart
> from this banner and the register rows.

From: the orchestrator of the next-phase (QoL / defect-fix / usefulness) plan [AGENT].
To: the owner of the SC concurrency track (`SC-CONCURRENCY.md` on `arc/sc-concurrency`).
Mandate: [USER 2026-09-27] "(4) agree, write a note for them in a worktree", on
the question "May I contact the SC track's owner to agree the fence?".

Status: a PROPOSAL. Nothing here constrains the SC track until you agree or
counter-propose; nothing in it is a user ruling beyond the mandate quoted above.

## Why you are getting this

The operator has approved a next-phase plan for the sequential semantics:
`lean_frontend/docs/2026-09-25_next-phase-plan.md` on branch
`docs/next-phase-plan-20260925` (§11 is the current sequence). It was written
while concurrency was parked. SC WP0 has since landed (`5ecc0aa33`) and WP1 is
complete on `arc/sc-wp1` (`af1342d32`), so both tracks are now live on the same
mainline. An independent review of the plan found that the overlap is much
wider than the memory model: WP1 already edits `frontend/model/driver.lem`
(+247 lines) and `core_reduction.lem`, and your S1 owns the run loop,
initialization/finalization, output streaming, resource accounting and the
shared-Lem fork/wait repairs. We want to avoid two tracks editing the same
surfaces in parallel, and to avoid two concurrent lem-lean pin dances.

Your own rule applies to us too and we adopt it: short branches from the
current mainline, one slice per landing, no long-lived accumulation branch
(`SC-CONCURRENCY.md` §4).

## The proposed fence

| Surface | Our items (plan IDs) | Your packages | Proposed rule |
|---|---|---|---|
| `driver.lem`, `core_run*.lem`, `core_reduction.lem`, the run loop | step-runner stack ceiling (P3-4), run-loop rendering of monadic list combinators in lem-lean (P3-3), their design notes (P1f-3) | WP1, S1 | **You own these files.** Our two scale fixes start as design notes; we ask to write the step-runner note JOINTLY with you, since S1's selected-loop scale acceptance depends on the same loop. Our implementation lands through S1's review or strictly after S1 lands. |
| Outcome / kill-reason types | structured kill reasons for cerberus-sl (P2b-1), a loud "unsupported" refusal for `aligned_alloc(0, n)` (P2d-2), a JSON outcome schema (P2a-6), a fuel-exhaustion message naming the worker (P1d-6) | S1's exit: "Completion/UB/unsupported/blocked/exhausted are distinct" | **One jointly owned outcome-taxonomy note** (our P1f-4), also reviewed by cerberus-sl, before either track codes its outcome changes. Proposed content: which outcomes are typed constructors a theorem can state (normal, UB, unsupported, blocked, exhausted, fail-stop) and how each prints. |
| `global.lem` / `CerbGlobal` configuration | the configuration as a reader-lifted parameter (P2b-2; registered step 2) | S5 public mode; `using_concurrency`'s step 2 is yours (`CerbGlobal.lean:44-54`) | **You design the record's concurrency field first**; we lift the rest after that design exists. |
| `CerbMem.lean`, `mem_common.lem`, the OCaml `impl_mem.ml` models | dead `[LemFuel]` binders (P2c-1), `aligned_alloc` refusal (P2d-2), optional `MerrOutOfMemory` (P2d-4), a possible sparse byte representation (P3-6, only on profile evidence) | WP0 (landed), S4 | **Announce-before-start**: each side records a one-line claim on this surface (below) before starting a slice; landings are sequential, the second rebases. |
| `Main.lean` CLI | `--help`, exit-code table, runtime-dir override, non-batch exit status (P1b-1/P1b-2); moving the pipeline into a library module (P2a-1) | S5 public mode flags | **We land our CLI work first** (small, near-term); your S5 flags rebase on it. |
| The lem-lean pin | LemLib residuals and toolchain alignment to 4.32.2 (P1d), one generated-surface bundle (P2c) | S1's shared-Lem repairs | **One pin dance at a time.** Whoever starts first holds the pin until its cerberus re-pin lands; the other rebases onto the new pin. |
| Upstream re-sync from `b9aeedcb4` | P4-2, at the next network window | all SC branches | **Scheduled jointly**, never during an SC landing; we would prefer it before S1 lands broadly. |

Everything else in our plan touches none of your surfaces and proceeds
independently: instruments and gates, docs, measurements, tray drafts,
lem-lean diagnostics, a fork-delta triage, a report-only real-C reach census,
the cross-TU union-twin and `_Alignas` compatibility fixes (`core_eval.lem`,
`core_aux.lem`, `ctype_aux.lem`), libc-body UB locations, and packaging for
Lean clients (a release line carrying the generated tree).

## Claims register (announce-before-start)

One line per active slice on a shared surface: date · track · surface ·
branch · expected landing. Append-only; strike when landed.

| Date | Track | Surface | Branch | Expected |
|---|---|---|---|---|
| 2026-09-29 | SC | S1 bounded step API: new SC step/lifecycle definitions in `driver.lem` (and, as needed, `core_run.lem` / `core_reduction.lem` / `core_run_aux.lem`), added alongside the unchanged sequential `drive`; no change to upstream-supported behaviour | `arc/sc-s1-*` (sub-slices named in the S1 charter) | per sub-slice; charter first |
| 2026-09-30 | next-phase (bug-hunt fixes) | `Main.lean` runtime resolution (`--runtime`/`CERB_INSTALL_PREFIX`) and Cabs-import refusals (library-location, non-UTF-8), `CerbLocation.isLibraryLocation` docs, batch `ub:` byte printing, every harness passing the runtime to the Lean driver (`scripts/common.sh` + direct sites), new row-1 checks, VALIDATION/CONTRACT N1–N3; no `.lem` or SC-surface change | `arc/bug-hunt-fixes` | after the full ladder + pre-merge audit |
| 2026-10-04 | next-phase (lem re-pin) | the lem pin (Lake rev, manifests, fork-drift `lem-pin`, the shared switch, `deps/lem-pinned`) moves `77ad4fa` → `4e70bb5`; generated OCaml byte-identical; generated Lean re-laid-out (statement/specifiers as structures; BEq at base types is core's); `natEq0_iff` proof; purity / fuel-parametricity gate scripts | `arc/lem-repin-4e70bb5` | landing now (SC session notified before the switch moved) |

## What we ask of you

1. Agree to the fence, or counter-propose per row.
2. Say whether you want the step-runner design note written jointly, and who
   drafts first.
3. Name your next Lem pin move, if any, and its expected timing, so the pin
   rule has a starting holder.
4. Say whether the outcome-taxonomy note should live on your branch or ours.

Reply by committing an answer section to this file on this branch, or on your
own branch with a pointer here. The operator relays and approves the result;
agreed rows are copied into both plans.
