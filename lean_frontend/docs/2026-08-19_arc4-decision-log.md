# Arc 4 decision log (exec pipeline)

Orchestrator/worker doctrine (first full outing): workers commit their own
slices (green gates only), orchestrator scopes + verifies at batch
boundaries, merge is the user's. Format: **D<n>** — decision / why /
alternatives.

**D1** — Lane: branch `arc/exec-pipeline`, worktree
`worktrees/cerberus-lean-arc/exec-pipeline`. A lem-lean worktree is
created LAZILY only if S1 demands a backend change (the known
self-shadowing shape); the opam lem (574e326) serves regen meanwhile.
Charter + this log are the orchestrator's arc-opening commit.

**D2** — S0 findings accepted: the "silent" rc=1 was a stderr-lost
`INTERNAL PANIC: executed 'sorry'` from the generated BEq core_step2
fallback, fired by driver2's blocked-thread filter — NOT
easy_update_mem_value_aux (return-42 has no memory ops). Frontier map
(105 files) drove S1 scoping. Worker fixed nothing (semantics fixes out
of S0 scope) — correct restraint.

**D3** — S1a deviation APPROVED post-hoc: skip_instances is unusable for
core_step2 (suppresses the real Inhabited that Core_reduction's own
failwithI sites need; probed, ~8 synthesis failures, import-cycle
unfixable). Priority-override instead: hand instances at default priority
beat the (priority := low) sorry fallbacks; extra_import lives in
driver.lem (sole legal host in the import closure). Verified at boundary:
model diff = declares + comments only; OCaml token-neutral; gates green;
return-42 → Active 42. Caveat recorded in-file: new equality use sites on
core_step2 outside Driver.lean would silently get the fallback — audit
scope item.

**D4** — Ordering call: S2 (differential harness port) BEFORE further
crash-fixing. With 62 Active / 26 Killed, the bottleneck is
CLASSIFICATION (which results are right?), not crashes; the harness
turns the frontier into a mismatch list and S3 batches work that list.
The remaining crash classes (15 ACTION_ILLTYPED, 2 SeqRMW) become S3
batch items ranked by differential impact. Also noted: the execution
path uses the CONCRETE memory model (CerbMem) — easy_update (defacto)
is likely OFF the runtime path (which is why 62 programs store happily);
its elimination matters for driver2's KERNEL CONE (success condition 2)
and gets a dedicated later worker.

**D5** — S2 boundary passed: first differential baseline 73/105 matching
(58 value + 15 UB), independently reproduced by the orchestrator.
Notable worker calls, endorsed: zero-execution runND emits Error + rc 1
where OCaml silently exits 0 (honesty over byte-parity — the OCaml
behavior is arguably a bug); 097's oracle-side crash recorded as
CERB_SKIP (the OCaml TODO-failure is upstream-reportable). Operator
installed csmith 2.3.0 mid-slice; disposition updated live (fuzz kit:
port + S4b smoke run; creduce still absent → networked window). S3
batches will work the 29 fixable non-matches by class:
S3a=ACTION_ILLTYPED(15), S3b=memory FAILs(7)+Illformed(2),
S3c=SeqRMW(2)+individual mismatches 052/066/098.

**D6** — S3a boundary passed (91/105, +18, zero crashes, one-line C fix
mirroring the OCaml parser-offset invariant; fragility of the OCaml
invariant itself recorded — upstream-reportable). Seam survey (read-only
Opus worker, operator-requested) delivered 30 live-bug suspects; extract
committed as 2026-08-19_arc4-seam-survey.md.

**D7** — Reprioritization on the survey (operator asked; orchestrator
call): bar unchanged (≥95). Route changes: (a) ND accumulation-order fix
(finding 22) PROMOTED into S3b step 0 — it permutes multi-execution
first-verdicts and could make correct fixes read as baseline regressions;
instrument integrity precedes measurement. (b) S3b = struct/union memory
model to the survey spec (findings 1-4, 17). (c) S3c = survey-driven
cheap batch (5-7, 12, 18, 26, 28 + 066/098 closure). (d) ~20 remaining
findings = recorded backlog, explicitly OUT of this arc's bar; S4b's
coverage-corpus baseline measures which latents are live; next arc claims
them. (e) S5 audit scope += "seam fixes cite and match the OCaml lines
they claim to mirror".

**D8** — Operator doctrine (2026-08-19, codified in container CLAUDE.md +
ROADMAP obj 2): gratuitous Lean↔OCaml divergence in hand-written seams is
a DEFECT AS SUCH — differential failures raise priority, never define
defect status. Divergences: mirror-with-citation or document-deliberate;
undocumented = defect. Consequence for this arc: the seam-survey extract
is a DEFECT REGISTER; close-out reports fixed / documented-deliberate /
open counts; S5 audit verifies citations against cited OCaml code.

**D9** — S3b boundary passed: 97/105 (crossed the ≥95 bar), 0
regressions, independently reproduced. ND-order fix landed with ZERO
baseline delta (corpus is single-verdict — the fix protects future
multi-verdict programs; instrument-integrity rationale stands). Two
unplanned root causes endorsed: set_tagDefs dead-code-eliminated (pure
opaque, discarded result — fixed via BaseIO externs; classic arc-1/2
effect-erasure class, now on the survey register pattern list) and
description-sensitive symbol equality in tag lookups (symbolEquality /
idEqual now, OCaml-parity). S3c targets the 5 remaining fixables: 066
(float of_string), 098 (diffPtrval), 072/077 (mem_error→UB reporting
map), 056 (funptrmap) + survey cheap batch (ediv/emod, ivfromfloat,
NoProvPtr, decode 26/28, Bool0 max; enum registry only if corpus-forced).

**D10** — S3c boundary passed: 102/105 independently reproduced, harness
default mode rc=0 (zero mismatches — every Lean-side fixable closed; the
3 CERB_SKIPs are OCaml-side: 097 upstream TODO-crash, 073/074 prototype
skip-on-cerberus-Error semantics where both sides in fact agree). Success
condition 1 MET (bar ≥95, achieved 102, all non-matches classified).
Notable: worker empirically established OCaml integerRem_f is Euclidean
(mod_big_int) — Lean's emod was already correct there; the citation
discipline caught what intuition would have "fixed" into a bug. Register:
9 findings FIXED, 1 documented-deliberate, rest OPEN for next arc.
Remaining arc work: S4 (test_elab reporting), S4b (coverage/debug corpora
baselines + csmith smoke), easy_update elimination → driver2 cone
sorryAx-free (success condition 2), arc-2 obligations, S5 close-out.

**D11** — S4/S4b boundary passed (all verified independently: minimal
102/105 untouched with baseline rc 0; elab 102/105 SAME at signature
granularity, 3 DIFFs = one explained pp-visibility class; coverage 95.7%,
debug 97.6%, csmith smoke 3/3 MATCH with exact failure parity on oracle
non-yields). Next-arc pricing now data-backed: (1) libc/builtin proc
linking — 20 coverage FAILs, single largest parity item; (2) varargs
(register 15); (3) enum registry (18b — now shown to be a UB-soundness
miss, debug compat-04); (4) real Core/ctype pretty-printer (unlocks
body-level elab diff + fixes the Unspecified(<ctype>) textual class);
(5) csmith oracle yield 12% — scale-fuzz bottleneck is upstream cerberus
strictness on csmith output, not our side. Remaining this arc: cone
worker (easy_update + driver2 sorryAx-free + arc-2 obligations), S5
close-out + audits.

**D12** — S1r boundary passed (verified: 103/106, zero mismatches, all
gates green incl. the new driver2-sorryAx assertion; defacto_memory.lem
has zero sorry target_reps). driver2 was ALREADY sorryAx-free — arc-3
D9's observation predated the S1a BEq fix; the gate now locks it. The
obligation test exposed effect-erasure instance #3 (with_tagDefs set/
restore DCE'd; fixed by binding the pre-existing C-side atomic shim) —
the pattern (runEffectful arc-1, set_tagDefs S3b, with_tagDefs S1r) goes
to the S5 audit as a named checklist item: EVERY effectful Lean-side seam
must be armored or natively sequenced, and "it built and ran" is proven
insufficient three times now. Residue recorded, not gated:
flexible_array_member's derived BEq elaborates against ctype sorry stubs
(import-leaf limitation, §19) — inside easy_update's cone, OFF driver2's;
C-tier backend item, next arc.
