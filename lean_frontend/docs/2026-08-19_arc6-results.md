# Arc 6 results: libc & speed

Companion to the charter, decision log D1–D15 (provenance-tagged
throughout per the goal directive), the S0/S1/S3/S4 records, the ci
scoreboard, and scripts/LADDER.md.

## Headline

**Real libxml2 code with libc dependencies executes differentially at
16/16 — GATING** (`test_libxml2_uri.sh`: xmlParseURISafe over an
RFC-3986 edge corpus, byte-identical vs the oracle, fail-closed lanes).
Riders all landed: varargs execution (register 15 FIXED — coverage
183/199), perf (battery 28→4 slices, ~35→~8 min, Lean/OCaml ratio 1.7×
flat, ZERO differential movement, kernel-checked lookup_equiv), and the
first-ever tests/ci exec sweep: **110/114 comparable agree (96%)**, 4
non-agreements (3 textual pp-placeholder + 1 semantic = register
finding 11, now corpus-forced) vs the prototype's ~13 historical.
Windfall: test_core is 100% — the known-red 078 was a pp-only grammar
form, fixed by S1's parser work.

## Slice ledger

| slice | result |
|---|---|
| S0 | dual-lineage survey: 20-FAIL class = ONE seam; path (i) chosen under the operator's TCB principle (D3 [USER]); prototype's 365MB path empirically rejected |
| S1 | libc: pinned unlinked dump (4.2MB) + parser productions (191 procs/68 globs/1 tagDef all parse) + metadata by frontending the same 12 TUs through OUR pipeline + --libc link mode → uri 10/10 byte-for-byte; 078 green |
| S2 | varargs vs impl_mem.ml:2698-2764 (error strings byte-exact incl. sic); worker refused the orchestrator's nonexistent "type check" (mirror doctrine both directions) |
| S3 | Fmap dual-TreeMap (bucketed BEq/cmp mixed semantics preserved bit-for-bit) + CerbMem TreeMaps; lookup_equiv kernel-checked; zero movement |
| S4 | uri gate flip 16/16; ci first sweep; ladder tiers formalized |
| S5f | 2 audits (zero blockers) fully dispositioned; D14 ban gates live |

## Doctrines landed mid-arc (all [USER], codified in container CLAUDE.md)

TCB-minimization path choice (D3); no-internal-trust-gaps + temporal
boundaries recap applied; non-kernel proof-method BAN (D14:
native_decide/bv_decide/ofReduce* — gate-enforced, golean mechanism;
arc-7 adopts the in-build Audit.lean pattern); verbatim-transcript rule
(from the arc's one record-integrity finding — the ci scoreboard's
doctored SUMMARY quote, corrected; per-file data was deterministic and
accurate throughout).

## Register movement

FIXED: 15 (varargs). PROMOTED corpus-forced: 11 (read-only allocations —
ci 0086 semantic DIFF; top of next-arc queue). NEW: stack ceiling
(~1.4k iterations, QUIET EXIT-0 failure mode — needs a guard some arc);
lem tests/backends leantests srcDir breakage (pre-existing); harness
counter overlay (FIXED in S5f). Open register: 12.

## Ecosystem/spike assets banked this arc (parallel streams)

RelSem: ExecModel parametric adequacy interface (sequential instance
inhabits; concurrency instance = fields only) + runNDT_sound PROVED
(the theorem partial runND blocked — arc-7 dress rehearsal) + Q2
monotonicity. cmm Stage-1 survey (sorry census: 5 needed for RA+NA;
integration staleness total on BOTH sides → predicate-level validation
instrument). Upstream reports: 7 filing-ready drafts with remedies +
bug-vs-intended classifications (notes/upstream/). Weak-memory survey
v2 integrated; executable-equivalent concurrency direction +
model-parametricity principle recorded.

## Pins at close

lem-lean arc tip `bd7e2eb` = Lake manifest = deps/lem-pinned = opam
(certified from pins: 356/356, unit 4/4, minimal BASELINE OK, uri
16/16). Cerberus model .lem: ZERO changes all arc (audit-verified).

## Next-arc pricing

1. Register finding 11 (read-only allocations) — corpus-forced.
2. Layer-2 proper (arc 7): totalize CerbND (runNDT transfer),
   relational semantics on ExecModel, minimal Iris base + first
   adequacy; golean Audit.lean pattern adoption.
3. pp-placeholder text class (3 of the 4 ci non-agreements + mem3-004).
4. Stack-ceiling guard; csmith at scale (creduce now installed).
5. Concurrency arc (survey Stage 0-2): charter tray complete.
