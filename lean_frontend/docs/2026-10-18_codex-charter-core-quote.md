# Codex charter — a printer of translated Core files to Lean literals, with a round-trip check (cerberus-caesium filing F, secondary) (2026-10-18, rev 5 after four reviews and the consumer's correction)

**Branch:** `feature/core-quote` · **worktree:** `worktrees/cerberus-lean-feature/core-quote` (created primed at dispatch from a
mainline carrying this charter). **Worker:** one Codex worker. Never merges, never pushes, never edits lem-lean or `deps/`.
Rev 2 incorporates review findings 3, 12, 13, 14, 16.

## 0. Goal, the relation, and the success condition

**Goal.** A hand-written seam that prints the Core file the driver EXECUTES — `runFile := convert_file coreFile`, of type
`file core_run_annotation` (`Main.lean:1212`), taken at that very point of the driver — as Lean source text that elaborates, in a
module importing the generated types, to a value standing in a STATED relation to the original. There is no Core expression printer
in Lean today: `--pp-core` is a signature-level dump (`Main.lean:470-491`, `ppCoreSignature` at `:509`) and `CerbPP.lean` prints
values and ctypes only. So this printer covers the expression and statement syntax for the first time.

**The relation (review findings 3 and S1) — DECIDED 2026-10-18 by the consumer's stated need, as CORRECTED by the consumer the same
day (cerberus-caesium's answers, relayed by the operator; paraphrased): option (A), an instrument on the declared boundary, and the
quotation PRESERVES REPRESENTATION. Propositional equality to the pipeline's value is not needed: the consumer's theorem is stated over
the quoted literal with a computed link to the pipeline, and the translation-fuel slice is the route that later turns the quoted form
into an induction over Ail. What the quotation must preserve is LOOKUP behaviour, and the consumer's kernel-checked probes show that
rebuilding a map from its bindings does NOT preserve it even under the right comparator: two maps with identical bindings and heights
can give different results under a later union. So:**

- **Quote the ORIGINAL map, outer constructor included.** `Fmap` has TWO constructors at the pin (`LemLib.lean:1192-1194`):
  `.empty`, which carries NO comparator, and `.mk cmp tree`; `.empty` and `.mk cmp .Empty` are different states (`Fmap.rep`
  `:1200-1202` erases the difference, so a tree-only check cannot see it, and the libc file is initialised with `fmapEmpty` in three
  fields, `Main.lean:1021, :1028-1029`, preserved by `convert_file`, `generated/Core_run_aux.lean:944, :951-952`). The literal emits
  `.empty` exactly when the original is `.empty` (no comparator term), and otherwise `Fmap.mk <comparator term> <the original Pmap
  tree>` with the `Pmap.Node`/`Pmap.Empty` constructors (`LemLib.lean:937-940`), their keys, values AND cached heights exactly as the
  value carries them. No from-list builder, no canonicalisation, no re-balancing. Sets (`Pset`) likewise by representation.
- **Name the comparator per field, FULLY INSTANTIATED, by provenance.** A closure cannot be printed; the printer names, per field, the
  comparator constant the pipeline's CONSTRUCTION used, as a monomorphic term with its instance arguments fixed (a head name alone is
  not enough: `mapKeyCompare` is a projection from a `MapKeyType` instance, `LemLib/Map.lean:49-63, :101-105`; `ordCompare` carries
  implicit instances). The consumer's corrected reading, which the worker VERIFIES against this tree and reports any difference as a
  finding: the symbol-keyed maps (`tagDefs`, `enumDefs`, the stdlib maps, the inner `labeled` maps `collect_saves` builds) are ordered
  by the ACTIVE instances of `generated/Symbol.lean` (`Eq0`/`Ord0`/`SetType`: digest and number, description ignored), through which
  `ordCompare` and `mapKeyCompare` resolve — NOT by the derived `defaultCompare`; `loop_attributes1` and `visible_objects_env0` ARE
  built with `defaultCompare`; the libc maps go through `libcSymMapCmp = symbol_compare` (`Main.lean:246`, used at `:993` and
  `:1025`); `fmapUnionBy` ignores its explicit argument: the result captures the LEFT operand's comparator when the left is `.mk`
  (even `.mk cmp .Empty`, which `fmapIsEmpty` calls empty, `LemLib.lean:1204-1208`), the RIGHT operand's when the left is `.empty`,
  and is `.empty` when both are (`:1271-1274`); the discriminator is the outer constructor, never "non-empty"; linking
  (`generated/Core_linking.lean:465-496`, `safe_map_union`) is traced through both branches per field; insertion into
  `.empty` captures the inserted comparator (`:1211-1213`); `fromList` resolves through the `MapKeyType` instance in scope; the
  Nat-keyed maps are populated with `defaultCompare` (`generated/Cabs_to_ail_effect.lean:2136-2137`, `generated/Translation_effect.lean:301-303`).
  Each field's provenance path is written into the record.
- **The check is a comparison of the WHOLE file.** The round-trip test compares the elaborated literal to the original over the ENTIRE
  `file core_run_annotation` — every field and constructor, recursively, from the D0 type inventory (`main`, `calling_convention0`,
  `globs`, the maps, `funinfo`, the annotations with their `Pset` fields, `generated/Core.lean:2491-2501`, `generated/Core_run_aux.lean:53-57`)
  — where (i) every container is compared BY REPRESENTATION: the outer `Fmap` constructor, then shape, cached heights, keys and values
  of the tree, recursively (a comparison written in the test; `Pmap` derives no `BEq` at the pin; the pinned `Pset`/`Fmap` `BEq`
  instances compare element spines only, `LemLib.lean:928-929, :1241-1242`, and are NOT the check); (ii) every leaf is compared
  representation-sensitively: scalars structurally, and floating leaves (`CerbMem.lean:75` `FloatingValue := Float`; the generated
  `BEq` at `Core.lean:486-489` is IEEE equality, which equates +0 and -0 while the printer distinguishes them, `CerbFloat.lean:325-330,
  :382-388`) by their bits — non-NaN floating leaves, signed zeros and infinities INCLUDED, are IN the supported domain and quoted
  representation-preservingly (the libc file itself carries them: `tests/libc/libc.core:53379` a floating zero, `:53897` an infinity,
  24 numeric occurrences in `scripts/libc_float_literals.txt:6-29`, parsed into `OVfloating` by `CoreParser.lean:1058, :1524, :1573`),
  so refusing the floating constructor is NOT an admissible choice in this slice; NaN leaves are REFUSED BY NAME (`CerbFloat.lean:348-354`:
  the shipped `toBits` canonicalises NaNs, so no representation-preserving quotation of a NaN exists without a new seam, which is not
  licensed), after checking that no required input carries one; (iii) every map's comparator TERM as emitted against the term its
  construction path names (syntactic, fully instantiated); plus (iv) the generated whole-file `BEq` as an additional, weaker check,
  evaluated only on the supported (NaN-free) domain — it is not consulted on a refused input, and a false auxiliary result is never
  reported as a pass.
  Lookup sweeps over stored keys are POSITIVE evidence only and never identify a captured comparator. (The consumer's per-field
  lookup-equivalence lemma over the quoted construction is theirs, not this slice's.)
**What is quoted:** the executed file after `convert_file` (`Main.lean:1212`), and the stdlib (`libc.co`) file quoted ONCE after the
same conversion. NOT quoted: the run-state maps the driver builds at start (`labeled`, `core_extern`), which the consumer derives in
Lean from the quoted file through the driver's own functions.

The two options as they were put to the consumer, for the record:
- **(A) Instrument on the declared boundary — CHOSEN**, with the representation contract above.
- **(B) Kernel-checked bridge** (a printer-correctness proof, M–L) — NOT chosen; remains the named mover of the boundary entry.

**Success condition:**
1. A driver flag (name yours; `--quote-core <out.lean>` suggested), through the SAME pipeline the exec path uses, writing one
   self-contained Lean module declaring one `def` of the executed file's value (after `convert_file`), for single-TU inputs AND for a
   linked multi-TU input; and the same for the converted stdlib file, quoted once. Every `Fmap` field is emitted as its original tree
   with its fully instantiated comparator constant per the verified provenance table.
2. **Round trip, mechanically checked, fail-closed:** a unit test (`core-quote-test`, wired into `lakefile.toml`, `scripts/test_unit.sh`,
   LADDER row 1's exe list — row 1 then has 20 exes; the fast ladder still has 19 commands — and `lean_frontend/CLAUDE.md`) that, for
   every `tests/fixtures/*/cabs.json` and the `lean_frontend/corpus` fixtures, prints the executed file, compiles the printed module
   under capped `lake env lean`, and applies the whole-file check above; PLUS one linked multi-TU round trip with a cross-TU declaration
   and reference (review finding 12); PLUS the stdlib file's round trip. Negative controls that must FAIL: a literal with `main`
   changed (a scalar OUTSIDE every map); a literal with one global initializer changed; a literal with one altered map binding; a
   literal whose tree has the SAME inorder spine but a different shape or heights; a literal with `.mk cmp .Empty` where the original
   has `.empty` (and the reverse); a literal with a floating leaf's zero sign flipped (while unchanged +0 and -0 leaves, and an
   infinity, round-trip and PASS); a NaN-bearing input refused by name (tested separately, not through the round trip); a literal whose
   comparator is the SAME head
   (`mapKeyCompare`) applied to a DIFFERENT explicit instance — the term comparison must reject it, and a behavioural control queries an
   ABSENT alias key `s'` (same digest and number, another description) that the active instance finds and the structural one does not
   (`LemLib.lean:985-991`: under the active comparator inserting `s'` replaces `s`), since a sweep over stored keys alone cannot witness
   the difference. An unprintable constructor, an unsupported annotation, or a non-elaborating module is an
   ERROR naming the construct — never a dropped field, a placeholder, or `default`.
3. The printer handles everything the REQUIRED INPUT SET exercises — the fixtures, the corpus, the multi-TU case AND the converted libc
   file — and refuses, by name, anything else (the refusal list in the note, with counts over ALL required inputs, not the small
   fixtures alone; memory values inside `object_value` may be refused in this slice only if no required input carries one in a quoted
   position — say so with the count).
4. No existing lane row moves; Tier A green at handoff. The boundary-list entry in `VALIDATION.md` §3: the quotation as a
   kernel-opaque instrument, named mover = the printer-correctness bridge (option B).
5. The consumer note `docs/2026-10-18_consumer-note-cerberus-caesium-core-quote.md`: invocation, module shape, the relation exactly as
   decided, the verified per-field comparator-provenance table (any difference from the consumer's corrected reading flagged), the
   boundary-list entry, the refusal list.

Rulings, paraphrased: [USER 2026-10-17] charter it. The no-magic-values rule ([USER 2026-09-03]). The container rule that agreement
between Lean artifacts is a theorem, with kernel-opaque artifacts on the declared boundary list (its "No internal trust gaps" bullet).
Fail-closed everywhere. No verbatim quotes of the operator.

## 1. What is known (verify what you touch)

| Fact | Where |
|---|---|
| The executed file and the extraction point | `Main.lean:1171, :1192`: `coreFile : file Unit` is already the LINKED file (`link coreFiles`); `:1203-1212` dumps it for `--pp-core`, then `runFile := convert_file coreFile` — the quotation point |
| The types and their instances | `generated/Core.lean:2490` `structure generic_file`; `:2509` `Inhabited`; `:2514` `SetType`; the AST inductives `:1076-1928`; `deriving BEq, Ord` on the simple types `:35-409` — check what the large inductives derive |
| `Fmap`'s equality ignores the comparator and the tree | lem-lean `lean-lib/LemLib.lean` at the cerberus pin: `Fmap` is `.empty \| .mk cmp (m : Pmap …)` (`:1192-1194`); `Pmap` is `Empty \| Node … (height)` (`:937-940`, no search-order invariant on the constructor); `BEq` compares `fmapElements` inorder spines (`:1241-1242`); `fmapLookupBy` follows the tree with the CAPTURED comparator (`:1216-1220`, `:994-1000`); `fmapUnionBy` keeps the left operand's comparator when the left is `.mk`, takes the right's when the left is `.empty`, and gives `.empty` for two `.empty` operands (`:1271-1274`); `Fmap.rep` erases the outer constructor (`:1200-1202`) |
| Comparator provenance paths | `Main.lean:246` `libcSymMapCmp`, `:993`, `:1025`; `generated/Core_linking.lean:465-485`; `generated/Symbol.lean:237-250` (structural instances) versus `:277-343, :383-385` (the active comparisons ignoring descriptions); `LemLib/Map.lean:49-63, :101-105` (`MapKeyType`, `fromList`) |
| Symbols carry digests and numbers | `generated/Symbol.lean`; `Main.lean:185` the pretty-name rule — the literal reconstructs exact `sym` values |
| Precedent for a flag + unit test landing | commit `424253fac` (cabs-json lexing position) |

## 2. Deliverables (ordered)

**D0 — Base.** Tier A on the untouched worktree; the constructor inventory reachable from `file core_run_annotation` (derived from
`Core.lean`), the printer's coverage checklist; the per-field comparator-PROVENANCE table VERIFIED against the pipeline's constructions
in this tree (`Main.lean`'s linking, libc loading and conversion, `generated/Core_linking.lean`, `collect_saves`) with the fully
instantiated comparator term per field — any difference from the consumer's corrected reading reported as a finding in the record and
the consumer note.
**D1 — The printer seam** (`lean_frontend/CerbQuote.lean` suggested): total over the checklist, each constructor printed or refused by
name; every map and set quoted by the full outer-constructor rule of §0 (`.empty` as `.empty`; `.mk` with its named comparator term
and its original tree). Tier A; commit.
**D2 — The flag** in `Main.lean` at the extraction point; refusal shape consistent with existing refusals. Tier A; commit.
**D3 — The round-trip test** (success item 2) with ALL of its controls, the multi-TU case and the stdlib case. Tier A; commit.
**D4 — Boundary entry**; documents (record `docs/2026-10-18_core-quote-record.md`, LADDER, CLAUDE, VALIDATION §3 list, the consumer
note). Close-out: Tier B (`python3 scripts/release.py --mode full`) on the final tree, quoted.

## 3. Flex — what you decide, and when to stop instead

- Yours: flag name, module shape, the quoting of sets by representation, the refusal list for constructs outside §0's supported domain
  (with counts over all required inputs), fixture selection beyond the required ones, commit splits. NOT yours: refusing non-NaN
  floating leaves (libc carries them) or quoting NaNs (no representation-preserving method exists at this pin).
- Not yours: the relation (decided, above); generated types; `.lem`; baselines; pins; canonicalising or rebuilding any map or set;
  weakening the test (printed-text comparison is NOT the round trip; spine `BEq` alone is NOT the check).
- **Stop and report when:** a construct cannot be quoted without a generated-type change (propose it); a field's comparator provenance
  cannot be established from the construction path (refuse that field by name and report); elaboration of a printed fixture approaches
  the cap or the tripwire (a slow-to-elaborate quoting design is the finding); any lane row moves; you are done.

## 4. Rules (binding)

Environment, hand-written-copy synchronisation (`make lean-prelude-src` after any `lean_frontend/*.lean` edit, before every capped
`lake build`; `handwritten_copy.manifest` registration for the new seam), checks (Tier A before every commit, per `scripts/LADDER.md`'s
rule for commits and worker-boundary claims; Tier B at close-out; the orchestrator re-runs Tier A at the boundary and Tier B before
landing), provenance, no trust gaps — as the translation charter §4 states them, EXCEPT its `.lem` regeneration, oracle-rebuild and
manifest instructions, which do not apply here. File fence: `lean_frontend/CerbQuote.lean`
(new), `lean_frontend/Main.lean` (the flag), `lean_frontend/test/Unit/CoreQuoteTest.lean` (new), `lakefile.toml`,
`handwritten_copy.manifest`, `scripts/test_unit.sh`, `scripts/LADDER.md`, `lean_frontend/{CLAUDE,VALIDATION}.md`, `lean_frontend/docs/`.

## 5. Reading list

Container `CLAUDE.md` · `lean_frontend/CLAUDE.md` · `generated/Core.lean` · `CerbPP.lean` · `Main.lean:470-520, :1203-1212` ·
lem-lean `lean-lib/LemLib.lean` (Fmap, Pmap, union) · `scripts/LADDER.md` · commit `424253fac` · `docs/2026-10-18_codex-charters-review.md`
(findings 3, 12, 16; S1; R1–R4; the fourth pass's provenance-path table — the per-field construction paths a worker traces, with cites
into `generated/Translation.lean`, `Main.lean`, `generated/Core_linking.lean`, `generated/Core_run_aux.lean`, `generated/Core_aux.lean`)
· `scripts/libc_float_literals.txt` · the consumer's ask: note 2 §F (secondary) and its agent's list, item 2.
