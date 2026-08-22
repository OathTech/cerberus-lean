# Arc 14 charter: the immaculate pass + the re-mark ("the professor's study")

Date: 2026-08-22. Mode: long-cycle autonomous under the orchestrator/
worker doctrine. BLESSED in advance by operator, 2026-08-22 ("happy to
roll straight into 2 once the hotfix is done") — launches on the
hotfix merge. Branch pair: `arc/immaculate` in BOTH repos (lem WILL
change — full pin dance at close).

## Objective

Remediate the grumpy-professor campaign's findings to the operator's
standard ("immaculate, impeccable, exquisitely in keeping with PL
theory and practice, indistinguishable from the pre-existing backend,
aligned with upstream standards" — semantic fragility weighted over
style), closed by THE RE-MARK: fresh auditor instances, same persona
and standard, the original registers in hand, grading the remediation
— the arc's SUCCESS CONDITION, not a follow-up. Inputs: the two
registers (notes/2026-08-21_grumpy-audit-lem-backend.md — B−, 5
GRAVE/17 SERIOUS/13 NIT; notes/2026-08-21_grumpy-audit-cerberus-
semantics.md — B−, 6 GRAVE/18 SERIOUS/14 NIT), 73 findings total,
each priced in-register.

## Slices

**S0 — triage + test-first (short).** Both registers into one
execution table (fix order, batching, the register's own prices
sanity-checked); then THE TARGETED DIFFERENTIAL TESTS FIRST, before
any fix: the semantics register's GRAVE items are latent precisely
because the corpus never exercises them — write the failing-input
tests NOW (realloc-UB codes, null/function-pointer relationals,
memcmp-on-uninit, memcpy-OOB/read-only/dead, ffs/ctz/decode edge
values incl. ffs(-1)/ctz(0)/'\?', CoreParser hash-collision probe),
run them against the CURRENT tree, and record the failures verbatim —
the honest baseline the fixes then flip. Oracle-side verdicts via the
(now upstream-identical) oracle; where the ORACLE is also wrong,
three-way with gcc + upstream and classify per the standing rules.

**S1 — the semantics F-row (cerberus side).** Re-mirror the
pre-doctrine seam residue to the arc-4-10 citation-and-isomorphism
standard: lt/gt/le/gePtrval (kill-paths restored, impl_mem.ml:1886-
1955 cited), memcpyM/memcmpM through the checked per-byte load/store
path, reallocM's error constructors (MerrUndefinedRealloc — the
wrong-UB-code fix), the CerbUtils builtins + CerbDecode with
upstream's C11 clause citations restored, bytefromint/update_prefix
and the register's remaining F-row items, the CoreParser symbol-hash
collision tripwire (loud, fail-closed), the effect-erasure armoring
levelled up to the CerbTags standard where the register found it
unarmored (CerbGlobal/CerbDebug, the Main.lean discarded-pure-call).
Every fix flips its S0 test; every changed seam mirror-cited or
documented-deliberate. Differential surface: expected movement ONLY
on the new targeted tests (standing corpora zero movement unless a
fix legitimately corrects a latent row — per-row justified).

**S2 — the backend structural pass (lem side).** In the register's
own priority: (a) DE-GLOBALIZATION — the ~24 module-level refs into
one explicit analysis-state record, restoring effect-free emission
(the single change the register says dissolves the prepass sediment,
the fold_right order hazards, and the reentrancy debt — execute it
as a behavior-preserving refactor: generated output byte-identical
before/after, gate-checked); (b) the OTT GRAMMAR repair — lem.ott
gains the five declare forms, ast.ml regenerated from it (upstream's
own build rule), byte-compared against the hand-edited version,
divergences resolved GRAMMAR-first; (c) the Set-layer equality fix
(setAdd/setEqualBy comparator coherence — the sym case — with
property tests to the Fmap standard); (d) the instance-priority
GUARD (a generation-time or test-time check that the intended
comparison instance wins resolution — kill the G1 elaboration-order
reliance); (e) the SERIOUS/NIT tail as batch work, registered
residuals allowed with prices. Every lem checkpoint cerberus-scale
validated (standing April lesson); generated-output neutrality
gate-checked per refactor batch.

**S3 — records + docs.** Results with the per-finding disposition
table (all 73: FIXED with evidence / RECORDED-RESIDUAL with price +
mover); docs de-stale; the standing-rules promotions folded in
(cache-disabled validation for build-rule changes; audit-plant
rebuild-after-revert — both to the container playbook at merge).

**S4 — THE RE-MARK (the success condition).** Two FRESH auditor
instances (new sessions, no remediation context), the original
persona and standard, the original registers + the disposition table
in hand: grade the remediation — is it A−? What did the fixes
regress or miss? What did the first pass overlook that the cleaner
code now reveals? Their findings get one fix-or-record batch;
their GRADE is reported to the operator verbatim, whatever it is.
Then the standard 2-agent close-out audit scopes fold into the
re-mark (record integrity, pin dance, discipline). Merge checklist;
full pin dance (lem first); stop; the merge ask.

## Success conditions

1. Every GRAVE finding FIXED with its S0 test flipped (no GRAVE
   residuals); SERIOUS items fixed or recorded-with-price;
   the re-mark finds no NEW GRAVE.
2. THE RE-MARK GRADE reported verbatim; target A− (an honest miss
   with the residual priced is a legal outcome — the grade is the
   measurement, not a gate to game).
3. De-globalization lands with generated-output neutrality
   gate-verified; the Ott grammar is normative again (ast.ml
   regenerated, upstream's rule green).
4. Standing gates + full differential surface green; movement only
   on justified rows/new tests; pins aligned at close (full dance).
5. Records complete; branch pair gate-green; merge checklist ready.

## Risks / tripwires

- De-globalization is the big-churn item: behavior-preservation is
  the bar (byte-identical generated output per batch); if it can't
  hold the bar it parks with evidence — the arc's floor is the
  F-row + Ott + Set + guard + re-mark.
- The S0 tests may indict the ORACLE on some edges (three-way +
  classify; oracle-wrong = upstream-filing candidates, never
  "fix to match").
- Re-mark honesty: fresh auditors, no coaching; the grade is
  whatever it is.
- Standing: capped, verbatim records, park-don't-improvise,
  cache-disabled for build-rule validation, per-merge ask.
