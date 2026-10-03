# `tests/multi_tu_tray/` — tray-pinned multi-TU cases (LADDER Tier A row 6b)

Provenance: semantics-audit repairs, 2026-09-11 — charter D3(g) and §8 items 1–2
(`lean_frontend/docs/2026-09-11_codex-charter-semantics-audit-repairs.md`); record
`lean_frontend/docs/2026-09-11_semantics-audit-repairs-record.md` (D3). Pinned at the D3
shared-model repair (commit `dbe633ec5`: `Ctype_aux.are_compatible_aux`'s array-bound
typo `(n1_opt, n1_opt)` → `(n1_opt, n2_opt)`; `PEmemberof(struct)` consults
`Ctype_aux.are_compatible` when the tags differ — upstream-tray drafts 38/39).
Classifications are [AGENT] under the orchestrator's decisions in charter §8.

Lane: `./scripts/test_multi_tu.sh --failure-class-projection tests/multi_tu_tray` —
each case is a directory of two TUs linked in sorted name order (`tu1.c tu2.c`), the
fork OCaml oracle against the Lean pipeline, exactly as `tests/multi_tu/`.

## Why a separate corpus root, and when the cases move

Pristine upstream (`b9aeedcb4`) does not terminate on `node` (draft 37, fixed in the fork
2026-09-10) and rejects every cross-TU struct value at its exact-tag `PEmemberof` guard
(draft 38). Since WP-O (2026-09-16,
`lean_frontend/docs/2026-09-16_pristine-oracle-instrument-record.md`) the pristine-upstream
lane (`scripts/test_upstream_oracle.py`, LADDER Tier B row 10) WALKS this tray too, with the
same engine invocation as `tests/multi_tu/`.

**2026-10-03: draft 38's consult REVERTED.** The fork took draft 38's `are_compatible`
consult at D3 (2026-09-15) and reverted it on 2026-10-03 (branch
`fix/mirror-upstream-d38-alignas`, record
`lean_frontend/docs/2026-10-03_mirror-upstream-d38-alignas-record.md`), under [USER 2026-10-03]
"Generally, our rule is that we don't innovate wrt Cerberus-upstream, unless something is very
very very obviously a bug. ... fall back to loudly rejecting (either as unsupported, or matching
upstream)." The fork's `core_eval.lem` guard is upstream's text again. The fork's ONLY
deviation from pristine here is `node`: pristine loops, while the fork (draft 37's
assumed-compatible set, kept) terminates and rejects with `mismatched tags`. It is admitted only
through the cited `shared-model-fix` row of `scripts/upstream_oracle_differences.json`, the one
pristine-side timeout the register admits. The other six cases agree on fork and pristine.
`node` moves INTO `tests/multi_tu/` and its row retires when upstream fixes draft 37. Draft
39's one-token array-bound fix is also kept; the guard masks it on this tray (see draft 39's
2026-10-03 update).

## The projection — row 6b only

Fork OCaml and Lean number symbols differently, so an `Error` whose text quotes a symbol
(`PEmemberof(struct) ==> mismatched tags: Symbol(545, SD_Id("S")) vs Symbol(502, …)`)
is a `full`-projection MISMATCH even when the two engines agree (the record's D3(g)
trial: 5 MATCH / 2 MISMATCH on symbol numbers alone). Row 6b passes
`--failure-class-projection`, the codec's opt-in `failure-class` projection
(`scripts/observations.py`): the `full` verdict tokens with `Symbol(<digits>, ` rewritten
to `Symbol(_, ` inside `Error`/`Undefined` payloads and NOTHING else — `Defined` tokens
are untouched and any other payload byte still differs (plant-tested in
`scripts/test_observations.py`). It is a labelled WEAKER projection; every other lane row
keeps `full`, and applying it to an existing row is forbidden (charter §3).

## Cases and classification

| case | shape (TU1 vs TU2) | classification | fork engines (both) |
|---|---|---|---|
| `node` | `struct node {int v; struct node *next;}` in both; value RETURNED by `ident`, `.v` selected (draft 38's positive reproducer) | compatible; rejected by upstream's exact-tag guard (since 2026-10-03; was `Defined 7` under draft 38's consult) | `Error … mismatched tags` |
| `arr-2-2-return` | `int a[2]` in both; RETURNED, `.a[0]` | compatible (equal bounds); rejected by upstream's exact-tag guard (since 2026-10-03; was `Defined 7`) | `Error … mismatched tags` |
| `arr-incomplete-ptr-return` | member `int (*p)[]` vs `int (*p)[2]`; RETURNED, `.n` (§6.7.6.1#2 + §6.7.6.2#6) | compatible; rejected by upstream's exact-tag guard (since 2026-10-03; was `Defined 7`) | `Error … mismatched tags` |
| `arr-1-2-return` | `int a[1]` vs `int a[2]`; RETURNED, `.a[0]` | **NEGATIVE, incompatible, rejected** — by the exact-tag guard on every engine (from D3 until 2026-10-03 it was the load-bearing pin of the consult: rejected because `are_compatible` said false) | `Error … mismatched tags` |
| `fam-vs-array-return` | `struct S {int n; int a[];}` vs `{int n; int a[2];}`; RETURNED, `.n` | rejected on all three engines — incompatibility by member COUNT (Cerberus keeps the flexible array member outside the member list `are_compatible_aux` compares); gcc runs it (7); the ISO question is upstream-tray draft 41 | `Error … mismatched tags` |
| `arr-1-2-arg` | `int a[1]` vs `int a[2]`; value PASSED by value to `get`, `s.a[0]` read | **OBSERVED MODELLING LIMIT** (below) | `Defined 7` |
| `arr-2-2-arg` | `int a[2]` in both; PASSED by value | **OBSERVED MODELLING LIMIT** (below) — the compatible twin; its MATCH pins the offset-0 read, not a consult | `Defined 7` |
| *(record-only, not a lane case)* `return-then-store` | `int a[1]` vs `int a[2]`; RETURNED and then STORED into a caller local (`struct S s = mk(); return s.a[0];`) | **NEGATIVE, incompatible, rejected at the STORE-side consult** (`core_run.lem:544`) — an uncaught `Failure` (fork, rc 125) / `PANIC` (Lean, rc 134): the pure-failure class; pristine `7` (the typo), gcc `7`. The multi-TU lane has no crash class, so this shape lives in the record (D3 "Audit F2") and draft 39, not here. | crash (both fork engines) |

gcc (`-std=c11 -O0 -w`) exits 7 on every case (independent reference for the
`Defined` rows; for the two `Error` rows it is not a reference — gcc performs no
cross-TU compatibility check).

## OBSERVED MODELLING LIMIT — the two argument-shape rows

Charter §8 item 1, verbatim: "in the default switch set a by-value struct argument
crosses the TU boundary as a pointer to a caller temporary and no compatibility is
consulted; the offset-0 read succeeds. Pinned as the oracle's behaviour (the mirror rule),
NOT as an endorsement; the consult lives on the `inner_arg_temps` path".

Mechanism (record D3 "THE STOP"; `core_run.lem:962-970`): unless
`Global.SW_inner_arg_temps` is set — matched mode's switch set is `[]` — the ctype handed
to `memValueFromValue` for each argument is `Pointer no_qualifiers ty`, so the
`Struct/OVstruct` arm (the compatibility consult) is never reached on the argument path;
the callee loads through the pointer under its own definition (offset 0 in both layouts).
`arr-1-2-arg` — and even `struct S {int a;}` vs `struct S {int b;}` passed by value — is
`Specified(7)` on the fork oracle, on Lean AND on pristine upstream: the D3 repair changes
nothing on this path. Under `--switches=inner_arg_temps` (NOT matched mode) the fixed fork
rejects `arr-1-2-arg` at the store-side consult with an uncaught `Failure` (exit 125) and
accepts `arr-2-2-arg` — recorded in upstream-tray draft 39 as a related observation. The
charter's original NEGATIVE expectation for the argument shape was WITHDRAWN as a charter
erratum (§8); these two rows are pinned as what every engine does today.

## Three-engine table after the revert — 2026-10-03 (verbatim in `lean_frontend/docs/2026-10-03_mirror-upstream-d38-alignas-record.md`)

`E(m,n)` and `D7` as below.

| case | fork oracle | Lean | pristine | gcc |
|---|---|---|---|---|
| `arr-1-2-arg` | `D7` | `D7` | `D7` | 7 |
| `arr-1-2-return` | `E(545,502)` | `E(63,19)` | `E(545,502)` | 7 |
| `arr-2-2-arg` | `D7` | `D7` | `D7` | 7 |
| `arr-2-2-return` | `E(558,502)` | `E(76,19)` | `E(558,502)` | 7 |
| `arr-incomplete-ptr-return` | `E(536,502)` | `E(53,19)` | `E(536,502)` | 7 |
| `fam-vs-array-return` | `E(533,502)` | `E(50,19)` | `E(533,502)` | 7 |
| `node` (tag `node`) | `E(531,502)` | `E(48,19)` | rc=124 (30 s; draft 37) | 7 |

## Three-engine table — HISTORICAL, under draft 38's consult (D3(b)/(c); scratch corpus `.tmp/d3/cases`, 2026-09-15, fork bin `e40ae8e3…`)

`E(m,n)` abbreviates `Error {msg: "ill-formed program: \`PEmemberof(struct) ==> mismatched
tags: Symbol(m, SD_Id("S")) vs Symbol(n, SD_Id("S"))'"}` rc 1 (for `node` the tag is
`node`); `D7` = `Defined {value: "Specified(7)", stdout: "", stderr: "", blocked: "false"}`
rc 0. Pristine = the manifest build `.validation-foundations/independent-oracle-v2`.

| case | TU1 | TU2 | fork oracle (fixed) | Lean (fixed) | pristine | gcc |
|---|---|---|---|---|---|---|
| `node` (draft 38's positive: `struct node {int v; struct node *next;}` in both; value returned by `ident`, `.v` selected) | `ident` | `main` | **`D7`** | **`D7`** | `rc=124` (draft 37's non-termination; 60 s) | 7 |
| `arr-1-2-return` (NEGATIVE: `int a[1]` vs `int a[2]`, value RETURNED then `.a[0]`) | `mk` | `main` | `E(545,502)` | `E(63,19)` | `E(545,502)` | 7 |
| `arr-1-2-arg` (NEGATIVE: same structs, value PASSED by value to `get`) | `get` | `main` | **`D7`** | **`D7`** | `D7` | 7 |
| `arr-2-2-return` (positive twin, equal bounds) | | | `D7` | `D7` | `E(558,502)` | 7 |
| `arr-2-2-arg` (positive twin) | | | `D7` | `D7` | `D7` | 7 |
| `arr-incomplete-ptr-return` (positive twin: member `int (*p)[]` vs `int (*p)[2]`, §6.7.6.1#2 + §6.7.6.2#6; `.n` selected) | | | `D7` | `D7` | `E(536,502)` | 7 |
| `fam-vs-array-return` (`struct S {int n; int a[];}` vs `{int n; int a[2];}`; `.n`) | | | `E(533,502)` | `E(50,19)` | `E(533,502)` | 7 |
| probe `name-arg` (`{int a;}` vs `{int b;}`, PASSED by value) | | | `D7` | `D7` | — | — |
| probe `name-return` (same, RETURNED, `.b`) | | | `E(533,502)` | `E(50,19)` | — | — |

(The table's "NEGATIVE" labels on the `arr-1-2-arg` row are the charter's ORIGINAL
classification as the record quoted it; §8 withdrew it — see the section above. The two
probe rows are record probes, not corpus cases.) The committed files were re-observed on
all three engines + gcc before this README was written and reproduce the table row for
row, symbol numbers included:
`lean_frontend/docs/2026-09-11_semantics-audit-repairs-evidence/d3-tray-observed.txt`.
