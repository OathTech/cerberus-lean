# Arc 5 results: link & libc

Companion to the charter, decision log D1–D5, the S0 dual-lineage survey,
and the S3 libxml2 record (`2026-08-19_arc5-s3-libxml2.md`).

## Headline

**libxml2 code runs through the Lean pipeline in 100% agreement with
OCaml Cerberus.** The chvalid differential — 1354 boundary code points ×
22 observations across 28 two-TU linked slices — is byte-identical on
verdicts, stdout, stderr, and exit codes, gated by `test_libxml2.sh`
with pinned reproducible config. En route: the coverage corpus jumped
from **154/199 to 178/199 comparable** (pre-arc baseline: 147 MATCH +
7 UB_MATCH; post-arc: 167 MATCH + 11 UB_MATCH — a +24 improvement; the
4 newly un-marked io files are counted inside the 167, with
byte-identical printf output); all 20 procedure-linking FAILs closed
(bar was ≥18, target 20 — hit 20). [Corrected per audit-2 finding 2:
an earlier draft of this paragraph both double-counted the io files and
used the post-S1 figure as the pre-arc baseline.]

## What landed (per slice)

| slice | result |
|---|---|
| S0 | dual-lineage survey: the 20-FAIL class reduced to ONE seam (discarded ailname attributes); real-linking-vs-concatenation decided on probed static-merging semantics; printf/varargs/exit-abort all resolved analytically (no work / out of scope / parity holds) |
| S1 | fix [A]: ailname capture + attribute-keyed proxy map + the masked builtin_-prefix strip — 20/20 flipped; io files un-marked (printf via generated Formatted.lean, byte-identical) |
| S2 | REAL multi-TU linking via generated Core_linking + per-TU native MD5 digests (hex-exact vs OCaml Digest); 31/31 identical exhaustive executions on the statics test; single-TU corpora unmoved by ""→real digests |
| S3 | EXIT CRITERION: chvalid 100% (28/28); stretch: 5-TU uri closure at exact `--nolibc` failure parity (identical memset symbol both sides) |

## Success conditions

1. tests/minimal ≥103/106 maintained at every commit ✓ (103/106,
   baseline rc 0 throughout).
2. ≥18 of 20 linking FAILs closed ✓ (20/20); coverage strictly improved
   (154→178 comparable, +24); every residual classified (5 varargs = register
   15, mem3-004 = pp placeholder, 2 provenance-fork = defect 8).
3. chvalid 100% on the committed battery ✓ (28/28).
4. Multi-TU landed and exercised ✓ (real Core_linking; real MD5 digests;
   symbol-identity invariant written; from_same_translation_unit no
   longer vacuous, single-TU behavior proven unmoved).
5. Dual-lineage discipline ✓ (OCaml citations throughout; prototype
   contributions: varargs donor design catalogued for later, negative
   knowledge recorded — its exit/abort hacks flagged do-not-import;
   audit verifies).
6. Standing gates green at every commit ✓. 7. Records complete ✓.

## New knowledge with standing value

- **Effect-erasure bite #4** (Lean let-sinks pure stage calls; per-TU
  digests would have been silently mis-stamped) — caught by a unit test
  BEFORE shipping; fixed with whole-extent-in-C forceIO. The pattern
  (runEffectful, set_tagDefs, with_tagDefs, digest/stage sequencing) is
  now a named register pattern: EVERY effectful-adjacent seam gets
  native-extent sequencing or armoring, and a unit test that would catch
  sinking.
- **Performance register item (new)**: exec cost is quadratic in
  allocation count (dead allocations retained in the concrete memory
  state) — chvalid needed 28 slices to stay under caps. A future perf
  arc's headline; harmless for correctness.
- forceIO is a new axiom (soundness note in-source); added to the
  declared boundary list. pImplConstant's lenient unknown-name fallback
  recorded (OCaml raises; unreachable on OCaml-produced .core).

## Arc-6 pricing (data-backed)

1. **C-libc (.core libc) loading** — the uri stretch fails on memset
   under --nolibc on BOTH sides identically; loading libc.co (or the
   needed subset) is the single delta to a running xmlParseURISafe.
   First symbol: memset.
2. Varargs execution (register 15; prototype donor design catalogued).
3. Performance: allocation retention (quadratic exec).
4. Then the Layer-2 (relational semantics) design charter — with the
   network-window prerequisites (elan 4.32.2, iris-lean vendoring,
   toolchain alignment) done first.

---

## ADDENDUM (arc-12 D2 honesty note, 2026-08-21)

The libc linking/loading machinery this arc introduced is unchanged,
but arc-12 measured that the ORACLE-side libc Core objects it links
were elaborated with live symbol-id collisions (4/12 TUs beyond the
F-D margin; details + grandfathering: the arc-6 s1-libc-load addendum
and the arc-12 S1/S2 records). Arc-5's differential greens stand as
agreement-evidence; the oracle-internal soundness qualifier now
attaches to every libc-mode row.
