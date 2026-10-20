# Pre-merge audit: feature/core-quote (2e1777b27..e557782f2)

Trimmed independent audit (one fresh reviewer, about twenty minutes of run time; scope offered: the relation's independence from the printer, the comparator provenance through the link fold, the F9 list rendering, the determinism convention, the test mechanism's robustness, the consumer note's claims; the reviewer was free to look anywhere). Launched by the orchestrator 2026-10-20 with the pre-merge ask outstanding. Dispositions are in the D5 fix commit and the landing note. Verbatim report follows.


Reviewer: independent (Claude), 2026-10-20. Worktree read-only; probes under
/home/dev/projects/cerberus-lean-proj/.tmp/audit-core-quote-20261020/.

## Verdict

MERGEABLE WITH FIXES. The instrument is sound where the test can see; the two P2 items are
(1) a driver-wide weakening of the BUG-3 oracle mirror whose oracle-side consequence the docs
do not state, and (2) an advertised quotation mode (--quote-core together with --libc) that no
round trip ever checks. Neither requires a design change; both are fixable before merge.

## Findings

### P2-1. refuseLibraryLocations now admits runs on which the oracle and the port disagree about library classification; VALIDATION does not say so

File: lean_frontend/Main.lean:611-631; doc entries lean_frontend/VALIDATION.md:483-497 and :565-572.

Claim: the switch from literal-string to IO.FS.realPath comparison applies to every driver run
(not only quotation) and re-opens exactly the class BUG-3 closed: the port's suffix test
(CerbLocation.lean:243-245) says "library", the oracle's literal test says "not library", and
the port no longer refuses.

Evidence:
- Oracle rule, util/cerb_location.ml:512-523: Hashtbl.mem excluded (Filename.dirname path), keys
  Cerb_runtime.in_runtime "libc/include" etc. (literal strings).
- Committed fixture spelling:
    $ grep -o '"file": *"[^"]*"' tests/fixtures/001-return-literal/cabs.json | ... | xargs -n1 dirname | sort | uniq -c
        154 ./_build/install/default/lib/cerberus-lib/runtime/libc/include
         14 tests/fixtures/001-return-literal
  Under the canonical convention (--runtime=_build/install/default) the oracle's key is
  _build/install/default/lib/cerberus-lib/runtime/libc/include; ./_build/... is not a member, so
  the oracle classifies all 154 builtins.h positions as non-library; the port classifies them as
  library and, since D2b, accepts the run (realPath equal). Before D2b this pair was refused.
- Regenerated libc metadata mixes both spellings in one TU:
    "file": "./_build/install/default/lib/cerberus-lib/runtime/libc/include/builtins.h"
    "file": "_build/install/default/lib/cerberus-lib/runtime/libc/include/ctype.h"
- The classification feeds output: generated/Core_eval.lean:672, generated/Core_reduction.lean:1804,1822
  select the reported UB location by CerbLocation.isLibraryLocation.
- BUG-3 witnesses (scripts/check_runtime_resolution.sh:141-165) plant only nonexistent or foreign
  existing directories; nothing witnesses an accepted alias of the real runtime against the oracle.

Lanes are unaffected (both engines use absolute CERB_INSTALL_PREFIX, scripts/common.sh:340), which is
why no baseline moved. The decision is tagged [USER 2026-10-19] (record :750-758); not contested.
The finding: VALIDATION.md:489-491 ("the suffix and resolved-directory tests agree on the served
import paths") describes only the port's internal consistency and omits that the oracle's verdict
can now differ on a served input; the Z-67 retirement at :565-572 is conditional on consistent
runtime spelling. Fix (either): state the re-opened divergence class and the spelling condition in
both entries and add one witness (fixture 001 at --runtime=_build/install/default with the oracle's
verdict beside it); or restore the literal rule and re-export fixtures/metadata without "./".

### P2-2. The advertised --quote-core + --libc (libc-linked program) mode has no round-trip check, and the shipped test cannot check such a module

Files: test/CoreQuote/CoreQuoteRoundTrip.py:66-76 (cli never passes --libc with --quote-core);
test/CoreQuote/CoreQuoteCompare.lean:14-42 (original has modes "libc" and "tu" only);
test/Unit/CoreQuoteTest.lean:1171-1173 (comparator vectors for "libc" and "tu" only);
consumer note :49-53 ("It can be combined with --quote-core .tmp/Linked.lean and multiple user JSON inputs").

Claim: the most intricate provenance path (libc L maps meeting TU S/O maps through
linkedProvenance) is exercised by no comparison; the unwired smoke probe only elaborated such a
literal (probes/CoreQuoteCliSmoke.py:54-58). A consumer cannot verify a linked-with-libc module:
--module requires either --libc alone or --inputs without libc.

Check (driver on scratch, fixture 001 linked with twelve regenerated metadata TUs):
    libc_prep exit 0; 12 jsons
    driver exit 0   (stdout/stderr empty; Linked.lean = 33,187,748 bytes)
    == comparator term occurrences ==
          3 Fmap.empty
          1 Fmap.mk (fun (a b : identifier)
          1 Fmap.mk implementation_constant_compare
          1 Fmap.mk (@Lem_Map.MapKeyType.mapKeyCompare sym (@Lem_Map.instMapKeyTypeOfSetType sym instSetTypeSym_1)
          3 Fmap.mk symbol_compare
Consistent with the audited fold (libc is the last f1, so L wins for tagDefs/funs/funinfo although
the TU's funs is .mk O); no defect found, but the agreement rests on reading, not on the test.
Fix: add a "linked" mode to original (libc + TUs through link), a per-field "L or S/O" vector to
check_core_comparators, one Python row (fixture 001 + metadata) and --module support; or remove
the combination from the consumer note and refuse it in the driver.

### P3-1. Record and consumer note cite pre-rebase hashes with no map to the committed history

record :5 (base e7e9bb427a...), :993 and :1326 (88bf20f5f8...); consumer note :6-7 (base
e7e9bb427a..., "D0 checkpoint fb8705c686...").
    88bf20f5f8acabaa72142653e22a7ec2e0f13359 commit []   <- dangling, on no branch
    e7e9bb427a514b6053865c303c4af512907da75b commit [arc/outcome-protocol ...]  <- not this branch's base (2e1777b27)
    fb8705c686d1de34f66426e3da4f1477d077632e commit []   <- dangling; the committed D0 is 6d2543c92
Add a rebase map (pre-rebase -> committed, base e7e9bb427 -> 2e1777b27) and fix "D0 checkpoint".

### P3-2. Tier B row 13 hard-codes GNU time at /usr/bin/time

CoreQuoteRoundTrip.py:191-193. Declared only in the consumer note, not in LADDER row 13 or the
VALIDATION boundary entry. Missing on clones without the time package; BSD time lacks -f/-o.
Present here (GNU). Declare in LADDER row 13, or probe and fail with a named message.

### P3-3. Instrument code uses panicking "!" indexing

CerbQuote.lean, 10 sites (entries[id]!, result[child]!, set!). Outside the exec cone and
unreachable by construction, but hand-written convention is failwithI, never panic!. Convert, or
note the exemption in the boundary entry.

### Note-1. D4 commit e557782f2 has a subject line only; practice is that the message states what was verified (the record has it).

### Note-2. --quote-core with --libc and no user TU (Main.lean:1848-1851, libraryOnly) quotes the library as the "program". Harmless; refuse or document.

## Checked, no finding

- Comparator vocabulary vs compiled producers (pp.explicit prints importing Main): loadCoreStdlib ->
  Lem_Map.fromList with instMapKeyTypeOfSetType ... instSetTypeSym_1 (S); loadCoreImpl ->
  implementation_constant_compare (I); translate_program -> 6x @Lem_Basic_classes.ordCompare sym
  instEq0Sym_1 instOrd0Sym_1 (O), none of the structural instances; translate_tag_definitions ->
  instSetTypeSym_1 (S); link_extern -> 8x @defaultCompare String String.instOrd (E); no other Ord Nat
  instance in generated/ (N). All match CerbQuote.Comparator.term and the test's comparatorSpec.
- Link fold and provenance: Core_linking.lean:452-496, LemLib fmapUnionBy/fmapAddBy/safe_map_union,
  link_extern E on every arm, convert_file uses fmapMap only; CerbQuote.linkProvenance/linkedProvenance
  mirror the argument order; driver reverse-cons order and origins order coincide (Main.lean:1171-1200);
  the libc-linked probe agrees.
- Visitor independence/completeness: derived from getConstInfo on the declared inductives; visits
  every non-function field (both Pos filenames, Pmap/Pset heights, floats by toBits, NaN distinct);
  errors on unexpected function fields; pins 638 constructors / 81 heads; sameShape compares scalars
  by value and nodes by tag, arity, order; flat List view lossless; no printer code in the comparison.
- F9 long lists (CerbQuote.lean:50-66, 1007-1016, 1070-1080): blocks consed back-to-front so order is
  preserved; each block is a typed (List T) -> (List T) function with n cons and n+1 closing parens;
  sharing keyed on type string plus child ids; only .typed nodes hoisted, with explicit types;
  post-order interning makes helper order acyclic and planSharing costs final when read; the
  257-element control plus reversed mutation cover two full blocks and a remainder.
- Leaves: reprStr emits \x.. for control bytes and Lean reads them back (#eval ... -> true); ints via
  Int.ofNat/Int.negSucc; floats via Float.ofBits, NaN refused before toBits; -0.0 and infinities
  covered by controls. Inline type-ascription dropping is safe (expected types always present).
- Driver wiring: all modules rendered before any publish; rename from exclusive scratch dir; quoting
  forces quiet; execution-flag conflicts refused (exit 2); distinct outputs enforced; exit code propagated.
- Test rebuild vs driver: same supply 0, per-TU setDigestIO, defaultAddressSpaceTop, default switches,
  explicit fuel instance (F10 form); suite fuel in scripts/test_unit.sh like other suite fuels.
- Determinism controls implemented as described; docs do not overclaim machine independence; census
  forbids absolute paths in both Pos filename fields; .tmp/ gitignored (.gitignore:73).
- Row 13 wired: scripts/release.py executes LADDER.md tables (read_ladder); --core-quote-libc exits
  before the shared gates by design.
- Boundary entry accurate: CerbQuote.lean has exactly 17 partial defs as listed; CoreQuoteTest 176;
  CoreQuoteCompare 0; trace-schema pin and plugin loading declared; CerbQuote in
  handwritten_copy.manifest and CerberusLean roots; probes not matched by globs = ["Unit.+"].
- No sorry, axiom, native_decide, implemented_by, unsafe or option bump in the slice's Lean files.
- Record integrity otherwise: provenance tags on decisions; release summaries and time lines quoted
  as code blocks; [USER] entries are paraphrases.

## Probe inventory (.tmp/audit-core-quote-20261020/)

ProbeProducers.lean, ProbeO.lean, ProbeE.lean (+ .out): pp.explicit prints of loadCoreStdlib,
loadCoreImpl, translate_program, translate_tag_definitions, link_extern via
scripts/ce ../scripts/capped lake env lean from lean_frontend/. probe_linked.sh: libc_prep.sh --jsons
metadata2, then the built driver with --quote-core Linked.lean --libc ... --libc-tu x12 fixture 001
(exit 0, silent). metadata/ is a partial earlier export (oracle binary transiently absent while the
battery rebuilt it); metadata2/ is complete. No tracked file touched; nothing built in the worktree.
