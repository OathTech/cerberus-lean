# The cerberus-lean contract — DRAFT for operator review (2026-09-28)

Status: **draft; operator decisions D1, D2, D3 and D5 recorded in §5, D4 pending.** Author: the orchestrator [AGENT], on [USER 2026-09-28]: "Really the correct fix here is
to much more explicitly define the contract that Cerberus Lean is trying to establish and then for the features that are
well-built, make sure that they're supported. For the ones that are not very well-built, make sure that they're
appropriately rejected." Occasion: the CerbFS path defect (`docs/2026-09-28_cerbfs-path-hotfix-record.md`), a SERVED wrong answer in a surface
the project never tried to clone, with no discrepancy found in the core semantics. Items marked **[DECIDE]** are the
operator's.

## 1. What cerberus-lean promises

cerberus-lean is a Lean 4 artifact that is meant to mean **what the Cerberus OCaml implementation means**, for a
declared set of C programs and a declared configuration. Concretely, for every input, an execution ends in exactly one of:

1. **The same observable verdict as the oracle** — value, stdout, stderr, the UB it reports — under the documented
   observation comparison (VALIDATION §4); or
2. **A loud refusal** — a nonzero exit and a message that names the unsupported feature and the boundary it belongs to;
   or
3. **A resource outcome** — fuel exhaustion or a declared resource limit, never counted as agreement (class (b)); or
4. **A registered deviation** — one of the few [USER]-ruled ISO fixes (class (d)) or a failure whose message text alone
   differs (class (a)).

There is no fifth outcome. **A different answer, or a silent absorption (a default, an errno, a zero, a success no-op),
where the oracle answers, is a defect by definition** — wherever in the tree it occurs, supported area or not. The
pathleak bug was a fifth outcome.

What the contract does NOT promise: ISO C conformance beyond the oracle's; agreement outside the declared configuration;
correctness of the oracle itself (the upstream tray records where we believe it is wrong); a proof of correspondence.
The evidence is differential testing on documented corpora plus kernel-checked local properties of the Lean artifact
(totality, axiom cone, fuel contracts); **testing samples behaviour and does not prove equivalence** (VALIDATION §9) —
which is exactly why every unmodelled surface must refuse rather than guess.

## 2. The declared configuration

Matched (default-switch) mode of the oracle at the fork merge-base `b9aeedcb4`; sequential execution; the concrete
memory model; LP64; `--nolibc` and libc modes as exercised by the lanes; explicit `--fuel` and address-space parameters.
Every non-default semantics switch is refused at the CLI today (`Main.lean` `refuseFlag`).

## 3. Feature areas and their states

Three states only: **SUPPORTED** (differentially validated; any disagreement is a bug), **REFUSED** (loud,
feature-attributed; each refusal has a witness), **OUT OF SCOPE** (not an input the artifact accepts at all).

| Area | State (proposed) | Evidence / refusal witness | Open questions |
|---|---|---|---|
| C frontend (parse → Cabs → Ail → Core) | SUPPORTED | shared OCaml parser; Lean desugar/typing/elaboration differentially tested (row 1 parser tests, all Tier A/B lanes) | frontend is `partial` (not kernel-evaluable) — a stated limit, not a discrepancy |
| Core dynamics (driver, reduction, pure eval) | SUPPORTED | Tier A/B lanes, pristine 835/28/7/2, gcc oracle, csmith corpus | none known; this is where the report found nothing |
| Concrete memory model | SUPPORTED | CerbMem mirror with cites; immaculate lane; allocator soundness theorem | the SC receipt buffer is disabled by default (WP0) |
| Integer/float/layout implementation choices | SUPPORTED (LP64) | CerberusImpl, CerbFloat, float/bytes lanes | other ABIs OUT OF SCOPE [DECIDE] |
| libc (the oracle's libc.co, loaded) | functions written in C (`runtime/libc/src/*.c`): SUPPORTED by inheritance — they run through the same Core semantics; the **builtin boundary** is the closed list of 36 `builtin` declarations in `runtime/libcore/std.core`, each with its own state (proposed D4 below) | libc_exec lane, libxml2 lanes | D4 |
| Filesystem (CerbFS) | **REFUSED** (D2) — every filesystem operation, except `write` on fds 1/2, which the driver routes to the stdout/stderr records and never reaches CerbFS | refusal witnesses in the immaculate lane | implementation slice pending (§5 D2) |
| Standard input / environment / argv | partially SUPPORTED | `--stdin` single-TU; argv lane | enumerate what is served [audit] |
| Concurrency (threads, atomics, Epar, C11 model) | REFUSED at the CLI flag | `refuseFlag` concurrency; SC recovery WP0 landed as instruments only | **`CerbConcurrency` stubs return defaults (e.g. `statically_satisfied := true`)**: are they reachable in default mode? If yes, a pathleak-class defect [audit, high priority] |
| Non-default memory models (symbolic, VIP, CHERI) and switches (PNVI, strict reads, …) | REFUSED at the CLI | `refuseFlag` | none |
| Debug/pretty-print seams (CerbDebug, CerbPP) | OUT OF SCOPE for verdicts | no-op stubs; must never change a verdict | confirm no verdict path reads them [audit] |
| `.core` text input (CoreParser) | SUPPORTED (as the oracle's `--pp core` output) | core-parser tests; verify lane | hand-written malformed Core: arity checks since item 7 |

## 4. How the contract is enforced

1. **Every REFUSED area has at least one witness in a lane that pins the refusal** (as the three `zd-fs-*` rows now do),
   so a return to a silent answer turns a gate red.
2. **A served-surface audit (the lesson of pathleak).** Every hand-written seam that can answer where it has no model —
   default arms, stub bodies, `Inhabited` defaults, lookups keyed on unnormalised data — is enumerated and classified:
   mirrors the oracle (with a cite), refuses (with a witness), or is unreachable (with the reason). The failure-reach
   register already does this for FAILURE sites; the audit extends the question to SUCCESS paths that answer without a
   model. Proposed as a fresh-reviewer pass with a finding ledger, before the contract is adopted.
3. **Adversarial inputs per area**, written from the contract rather than from the corpora: path spellings, fd reuse,
   environment and argv shapes, concurrency constructs in default mode. The corpora are upstream's tests and never
   exercised these.
4. `CONTRACT.md` becomes the front-page statement; `SUPPORTED.md` becomes its dated evidence table; VALIDATION keeps the
   mechanics. The announcement text points at `CONTRACT.md`.

## 5. Decisions

- **D1 — adopted** ([USER 2026-09-28] "D1 agree"): the outcome promise in §1 is the normative statement.
- **D2 — refuse the filesystem for now** ([USER 2026-09-28] "D2 refuse FS for now, this seems safer"). Implementation
  slice: every CerbFS operation refuses with a feature-attributed message; `write` to fds 1/2 stays served (driver-routed,
  never CerbFS). Measured baseline movement on the everyday lanes: three immaculate rows (`zd-f1-truncate-negative-length`,
  `zd-z2f01-lseek-whence`, `zd-fs-path-plain-control`) turn from MATCH into pinned refusals; Tier B/C corpora to be
  measured in the slice.
- **D3 — adopted** ([USER 2026-09-28] "D3 agree"): the served-surface audit (§4.2) is the next slice, concurrency stubs
  first.
- **D4 — pending; recommendation [AGENT]:** define "libc SUPPORTED" by mechanism, not by corpus. Functions written in C
  in the oracle's libc sources inherit the core-semantics state. The builtin boundary is a named, closed list — the 36
  `builtin` declarations of `std.core` — with a state per entry: `printf`, `vprintf`, `vsnprintf`, `exit`, `errno`,
  `any_bounded_int` and the GCC bit builtins (`generic_ffs`, `ctz`, `bswap`) SUPPORTED with their lanes; every file,
  directory, link and stat builtin REFUSED under D2; `write`/`read` supported only on the standard fds as the driver
  routes them. A new builtin upstream then shows up as an unlisted entry rather than silently inheriting a state.
- **D5 — adopted, amended** ([USER 2026-09-28] "D5 - amended, yes, link from top level README.md"): this document is the
  public statement, linked from the top-level README.
