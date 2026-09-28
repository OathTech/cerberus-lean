# The cerberus-lean contract — DRAFT for operator review (2026-09-28)

Status: **draft; operator decisions D1–D5 recorded in §5.** Author: the orchestrator [AGENT], on [USER 2026-09-28]: "Really the correct fix here is
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
4. **A registered deviation** — one of the few [USER]-ruled ISO fixes (class (d)), a [USER]-ruled named deviation where
   the mismatch cannot easily be resolved (class (e), VALIDATION §2b), or a failure whose message text alone differs
   (class (a)).

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
| Function pointers | SUPPORTED except their numeric value: converting one to an integer is REFUSED; its bytes and `%p` are named deviation N1 | `zd-funptr-*` rows; `ptr3-001` pinned UNSUPPORTED | none |
| Integer/float/layout implementation choices | SUPPORTED (LP64) | CerberusImpl, CerbFloat, float/bytes lanes | other ABIs OUT OF SCOPE [DECIDE] |
| libc (the oracle's libc.co, loaded) | functions written in C (`runtime/libc/src/*.c`): SUPPORTED — they run through the same Core semantics as user code; the 36 **builtins** of `runtime/libcore/std.core` (hand-implemented in each engine): one state each, §3.1 (D4) | libc_exec lane, libxml2 lanes | none |
| Filesystem (CerbFS) | **REFUSED** (D2) — every filesystem operation, including `read` on any fd; `write`/`vprintf` on fds 1/2 are served (the driver routes them to the stdout/stderr records, never reaching CerbFS) | `zd-fs-*`, `zd-f1-truncate-negative-length`, `zd-z2f01-lseek-whence` pinned refusals | none |
| Standard input / environment / argv | partially SUPPORTED | `--stdin` single-TU; argv lane | enumerate what is served [audit] |
| Concurrency (threads, atomics, Epar, C11 model) | REFUSED at the CLI flag; default-mode atomics and `{-{ ||| }-}` SUPPORTED as the oracle's sequential reading | `refuseFlag`; served-surface audit: 15 default-mode probes agree, `statically_satisfied` has no generated caller | none |
| Non-default memory models (symbolic, VIP, CHERI) and switches (PNVI, strict reads, …) | REFUSED at the CLI | `refuseFlag` | none |
| Debug/pretty-print seams (CerbDebug, CerbPP) | OUT OF SCOPE for verdicts | no-op stubs; served-surface audit: no verdict path reads them | none |
| `.core` text input (CoreParser) | SUPPORTED (as the oracle's `--pp core` output) | core-parser tests; verify lane | hand-written malformed Core: arity checks since item 7 |

### 3.1 The builtin boundary (D4)

`runtime/libcore/std.core` declares 36 `builtin` procedures. Unlike libc's C functions, each is implemented by hand in
both engines, so each has its own state. The live stepper's fallback arm fails any builtin not handled here, in both
engines, so a builtin added upstream fails closed until it is reviewed and listed.

| Builtin(s) | State | Where / evidence |
|---|---|---|
| `printf`, `vprintf`, `vsnprintf` | SUPPORTED (`vprintf` to fds 1/2; other fds reach CerbFS and refuse) | generated `Formatted`; immaculate programs that print (measured: 11 files call printf), libc_exec, libxml2 |
| `exit` | SUPPORTED | generated `Core_reduction`; every lane's exit path |
| `errno` | SUPPORTED | generated `Core_reduction`; libc_exec |
| `generic_ffs`, `ctz`, `bswap16`, `bswap32`, `bswap64` | SUPPORTED | `CerbUtils` line mirrors of `ocaml_gcc_builtins.ml`; immaculate `g4-*` rows |
| `write` | SUPPORTED on fds 1/2; fd 0 fails in both engines; other fds REFUSED (CerbFS) | `driver.lem` routing |
| `read` | REFUSED (CerbFS, every fd) | D2 |
| `any_bounded_int` | NOT SERVED by either engine: both fail it (`core_reduction.lem:1012-1013`) | `zd-any-bounded-int-crash` pinned MATCH / both crash |
| `open`, `close`, `pread`, `pwrite`, `lseek`, `truncate`, `link`, `readlink`, `symlink`, `unlink`, `rename`, `rmdir`, `mkdir`, `stat`, `lstat`, `umask`, `chmod`, `chdir`, `chown`, `opendir`, `readdir`, `rewinddir`, `closedir` | REFUSED (D2) | `CerbFS` refusals; `zd-fs-*` rows |

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
- **D2 — refuse the filesystem for now** ([USER 2026-09-28] "D2 refuse FS for now, this seems safer"). Implemented:
  every CerbFS operation refuses with a feature-attributed message; `write` to fds 1/2 stays served (driver-routed,
  never CerbFS). Three immaculate rows moved from MATCH to pinned refusals; the full ladder passed
  (`docs/2026-09-28_cerbfs-refuse-all-record.md`).
- **D3 — adopted** ([USER 2026-09-28] "D3 agree"): the served-surface audit (§4.2) ran
  (`docs/2026-09-28_served-surface-audit.md`). Its P1 finding (function-pointer numbers) is enforced: the integer cast
  refuses, the byte and `%p` channels are named deviation N1 ([USER 2026-09-28] "agree with (1)").
- **D4 — adopted, option 1** ([USER 2026-09-28] "Yeah, (1) is fine"): libc is supported by mechanism. Functions written
  in C inherit the core semantics' state; the 36 builtins are a named list with one state each (§3.1). `any_bounded_int`
  is listed as not served by either engine (the audit found it fails in both); its dead Lean seam, which returned `lo`,
  now fails loudly (`docs/2026-09-28_contract-enforcement-builtins-record.md`).
- **D5 — adopted, amended** ([USER 2026-09-28] "D5 - amended, yes, link from top level README.md"): this document is the
  public statement, linked from the top-level README.
