# Arc 6 charter: C-libc loading + varargs + perf ("libc & speed")

Date: 2026-08-19. Mode: long-cycle autonomous under the orchestrator/
worker doctrine; dual-lineage discipline (OCaml = what, cited; prototype
= how, attributed) throughout. DRAFT until operator-blessed. Fully
OFFLINE (no network-window dependency; the window items gate arc 7's
Layer-2 charter, not this).

## Objective

Make **real libxml2 code with libc dependencies execute differentially**
— exit criterion: the 5-TU `xmlParseURISafe` harness (arc-5 stretch,
currently blocked on `memset` under `--nolibc` on BOTH sides
identically) runs at **10/10 differential agreement**, flipping
`test_libxml2_uri.sh` from reporting to GATING. Riders, each priced by
arc-4/5 data: varargs execution (the last 5 coverage DIFFs, register
15), and the quadratic allocation-retention perf defect (arc-5 D5) —
the three remaining items between us and a serious uri.c verification
substrate.

## Slices

**S0 — survey (before any code; the arc-5 lesson: surveys collapse
work).** One worker, four questions:
(a) THE LIBC ARTIFACT: what exactly does OCaml load when libc is on —
`runtime/libc/libc.co` format (OCaml-marshalled Core? text?), where the
pipeline loads/links it (pipeline.ml / main.ml cites), and what subset
the uri closure actually needs (memset first; enumerate the closure's
full undefined-symbol set empirically).
**MANDATORY PRIOR-ART STUDY (operator directive): the prototype already
supports libc loading — study its path closely before deciding ours.**
Known shape (arc-5 survey): it let OCaml pre-link EVERYTHING including
libc and consumed post-link Core JSON; its harness records the scale
cliff (`--nolibc`: "2MB vs 200MB JSON") and `strip_core_json.py` exists
— catalog exactly how it ingested, subset, stripped, and performed
(file:line), what mitigations it built, and which of those transfer to
our text-based CoreParser + arc-5 Core_linking situation. Then price
THREE Lean ingestion paths: (i) libc as an OCaml-side TEXT DUMP
instrument (unlinked library Core, e.g. --pp-core of libc or a small
dump mode), linked by OUR arc-5 Core_linking — strongest obj-2 parity
claim, boundary-doctrine consistent (oracle-produced input, pinned +
drift-checked); (ii) prototype-style POST-LINK whole-program dump —
cheapest, but bypasses our own linker and weakens the parity claim
(record what it would un-exercise); (iii) parsing libc's C sources
through our own pipeline — maximal dogfooding, likely slowest. Subset
strategy (only the closure's needed symbols) is orthogonal and applies
to all three — the prototype's stripping experience prices it.
Recommend one path with the prototype evidence in hand.
(b) HARNESS FLAGS: OCaml side of the differential currently runs
`--nolibc` everywhere. Loading libc changes BOTH sides — map the exact
flag/loading story per corpus (minimal/coverage stay --nolibc for
baseline stability? uri/libxml2 gain libc?) so instrument changes are
lockstep and justified (arc-5 risk-note pattern).
(c) VARARGS: confirm the donor design (prototype varargs state; OCaml
impl_mem.ml:2698-2760 varargs map) against our MemState (fields exist,
never touched — arc-4 survey finding 15); enumerate the 5 failing
coverage files' exact va_* usage.
(d) PERF: profile one chvalid slice (where does the quadratic time go —
allocation-list lookups? bytemap? ND tree?); identify the OCaml data
structure at the same seam (Pmap = balanced tree vs our assoc lists);
state the mirror-doctrine position (data-structure choice is
performance, not semantics — divergence documented-deliberate with a
behavioral-equivalence argument, e.g. insertion-order-preserving map).
Output: survey doc + recommendations; no fixes.

**S1 — libc loading.** Per S0's chosen path. Lean pipeline loads/links
the libc Core (full or the needed subset — S0 decides; scope is the uri
closure + the coverage corpus's libc wants, not "all of musl"). Cited
against OCaml's load path; linking through the existing arc-5
Core_linking machinery. Standing corpora must be unmoved under their
existing flags (baseline rc 0); new libc-enabled runs are NEW harness
modes, not silent flag flips.

**S2 — varargs execution.** Implement vaStart/Copy/Arg/End on MemState
mirroring impl_mem.ml:2698-2760 (cited), prototype design attributed
where used. Bar: the 5 coverage varargs DIFFs → MATCH; register 15 →
FIXED. printf-with-varargs interplay: the generated Formatted path
already works (arc 5); verify the two compose on at least one new test.

**S3 — perf: allocation retention.** Per S0's profile. Likely shape:
replace the hot assoc-list(s) in CerbMem with a behaviorally-equivalent
faster structure (documented-deliberate divergence: performance, with an
explicit iteration-order-preservation argument so no observable
changes). Bar: the FULL 1354-point chvalid battery in ≤4 slices within
the standing caps (today: 28), with ZERO differential movement anywhere
(that is the semantic-neutrality proof). If S0's profile shows the fix
is disproportionate (e.g. it wants a Lean hashmap with different
iteration order threading through observables), park with pricing —
this rider must not eat the arc.

**S4 — the gate + scoreboards.** `test_libxml2_uri.sh` flips to GATING
(10/10 bar; corpus may grow with edge-case URIs — committed battery
style). RIDER (reporting only): first exec differential sweep over
`tests/ci` (128 upstream files, never exec-diffed — parse/core only
today) as a committed reporting scoreboard — the next honest parity
frontier, priced for arc 7+.

**S5 — close-out.** Results doc (register movements; perf numbers
before/after), decision log, docs de-stale, 2-agent adversarial audit
(mandatory scopes: libc-ingestion boundary honesty — the dump
instrument, if chosen, is oracle-produced input and must be pinned +
drift-checked like the libxml2 config; varargs citation fidelity;
perf-change semantic neutrality — differential movement anywhere =
finding), fix-or-record, merge checklist. Stop. Do not merge.

## Success conditions (machine-checkable)

1. `test_libxml2_uri.sh` GATING at 10/10 (xmlParseURISafe corpus,
   oracle-with-libc vs Lean-with-libc), pinned + fail-closed like the
   chvalid gate.
2. Coverage: the 5 varargs DIFFs → MATCH; overall strictly improved;
   residuals classified. Register: 15 FIXED.
3. Perf: full chvalid battery ≤4 slices under standing caps with zero
   differential movement (or the rider is parked with S0-priced
   justification — parking is a legal outcome for S3 ONLY).
4. Standing corpora under their existing flags: minimal ≥103/106 and
   all baselines rc 0 at every commit; libc-enabled modes are additive.
5. tests/ci exec reporting scoreboard committed (rider; numbers are
   whatever they are — honesty over aspiration).
6. Dual-lineage discipline audit-verified; any libc dump instrument
   pinned + drift-checked; zero .lem changes expected (any lem change
   triggers the full pin dance).
7. Records complete; arc branch `arc/libc-load` gate-green; merge
   checklist ready; mainlines untouched.

## Risks / pre-declared calls

- libc.co may be marshalled OCaml — then the dump instrument is the
  path; its output is ORACLE-PRODUCED INPUT (same trust class as
  cabs-json) and must be reproducibly regenerable + pinned.
- Loading full libc may explode symbol counts / exec time — S0 scopes
  the subset; the 2^20 symbol invariant and digest machinery (arc 5)
  should absorb it, but S1 must re-verify the invariant note.
- Perf work is the classic rathole — S3 has an explicit park clause and
  may not eat the arc.
- Varargs touches MemState shape — watch the effect-erasure pattern
  (4 bites) and the arc-4 G2 sync gate; any new native code follows the
  lean-native-obj discipline.

## Autonomy protocol

As arcs 4-5: workers commit (green gates only), orchestrator scopes and
verifies at every boundary, decision log D<n> throughout, emergency exit
always available (nature declared). Tripwires: bar 1 unreachable after
honest attempts; the libc ingestion path turning into an OCaml-side
feature project (that is upstream work — park and replan); any gate
keepable-green only by weakening. Machine-global state untouchable.
