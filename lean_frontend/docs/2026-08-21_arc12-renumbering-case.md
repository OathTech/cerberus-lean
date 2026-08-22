# The renumbering case — design note for the post-arc-13 agenda

Date: 2026-08-21 (arc-12, D2 ruling item 3: Option D deferred WITH the
case recorded). Status: AGENDA ITEM, not scheduled. Owner decision:
operator + orchestrator at the post-arc-13 slate.

## Why renumbering is now the strongest-cased repair

The arc-12 fail-stop floor made the F-D collision family loud instead
of silent, but the measurements that came out of it show the margin is
not a tail condition — it is a structural ceiling on the fork oracle:

1. **The margin is ~483 ambient ids in EVERY mode** (std.core + impl
   parse draws; libc.co is marshalled and draws nothing — the S0
   assumption of a large libc-mode margin was wrong, S0 addendum).
   Any TU whose desugar registers more than ~460 identifiers
   (locals included) is beyond it.
2. **The fork cannot regenerate its own libc under the floor**:
   stdio/stdlib/internal/vfscanf are beyond-margin (hwm 856/673/682/
   521); three carry live collisions (214/58/106 duplicate keys) in
   the very elaborations the pinned libc.co was built from. Rebuild
   paths are floored; the pinned artifacts are D2-grandfathered with
   loud warnings.
3. **~31% of the standing csmith corpus is beyond-margin** (516/1669
   CERB_FLOOR after re-baseline; 34 of those were MATCH rows —
   coincidentally correct, one head-morph from corruption).
4. **The uri gate's oracle side always ran exposed** (uri.c hwm 1798,
   252 live collisions) — its 16/16 stands only via byte-agreement
   with the protected Lean side.

The floor therefore trades silent corruption for a large honest
refusal class. Only renumbering removes the refusal class while
keeping honesty.

## The design space (sketched, not decided)

- **(R1) Restore the single counter on the OCaml target**
  (`declare ocaml target_rep` for the desugar helpers back onto
  `Cerb_fresh.int` — the drift-review §4 "cleaner, bigger" option).
  Pros: exactly upstream's architecture; smallest conceptual delta.
  Cons: desugar ids become ambient (≈483+), translation ids shift by
  N_d — EVERY pinned .core fixture, both drift-gate hash sets, the
  csmith/ci/coverage baselines, and the uri/chvalid/libc pinned
  expectations re-derive; Lean-side numbering diverges from OCaml
  numbering unless the Lean side mirrors the same draw order
  (it cannot — its desugar supply is pure/threaded by design), so
  cross-side symbol-id comparisons (if any ever gate) must stay
  id-insensitive.
- **(R2) Partitioned id space** (stage tag in high bits: ambient ids
  at base 2^20 mirroring the Lean side's native/fresh_int.c, desugar
  0-based below): numbering-stable for desugar ids, shifts only
  ambient ids; restores disjointness by construction with NO
  threading changes. Cons: still re-pins every fixture containing
  ambient ids (`a_N`/`ret_N` names embed them); diverges from
  upstream's layout (upstream-coordination question).
- **(R3) Upstream-coordinated threaded supplies** (upstream adopts
  explicit supplies with a partitioned space; the fork re-syncs):
  the only route that closes our notes/upstream/07 fragility filing
  upstream too. Slowest; cleanest end state.

Common to all: one full re-derivation event for every pinned oracle
artifact (drift-gate refresh recipe run once, libc.co rebuilt, uri/
chvalid/csmith baselines re-recorded, the D2 grandfather modes and
their register entries RETIRED — that retirement is the mover
recorded on each grandfather entry). The Lean artifact and its
kernel-checked theorems are untouched by any variant (Lean-side ids
are already collision-free at base 2^20).

## Prerequisites for scheduling

- Arc-11 (workbench v2) merged (the parallel-stream collision D2
  designed around).
- An upstream position on R3 (the notes/upstream/07 filing's
  reception) — or an explicit decision to carry R1/R2 as fork-only.
- A priced fixture-re-pin inventory (the arc-12 S1 record's gate list
  is the checklist skeleton).

---

## EXECUTED (arc-13, 2026-08-22)

This case was scheduled as arc 13 and EXECUTED as **R1 in its full
form** (= arc-13 D1 "scheme R-B": ocaml target_reps for the desugar
helpers AND the run supply back onto `Cerb_fresh.int`; the arc-2 run
seed also removed on OCaml). The S0 probes settled the design space on
evidence: fork `--pp core` output and the rebuilt libc.co dump are
byte-identical to the un-forked upstream oracle; the generated-Lean
diff is EMPTY (the R1 con "Lean-side numbering diverges" is real and
handled — cross-side comparisons stay id-insensitive, canonicalizer
extended); R2's partitioned space was probed too (desugar at 2^20) and
rejected (pp leakage via tag-suffix/glob-order + a run-supply growth
hazard). Decision + probe evidence:
`2026-08-22_arc13-s0-scheme-decision.md`; execution:
`2026-08-22_arc13-s1-build.md`. R3 (upstream adopting threaded
supplies) remains the notes/upstream/07 conversation — now with the
fork re-converged, any future upstream scheme change surfaces as a
byte-diff.
