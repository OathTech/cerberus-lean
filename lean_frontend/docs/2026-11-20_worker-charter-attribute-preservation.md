# Worker charter: no parsed construct is silently discarded — the attribute class repaired, the wider category surveyed

Date 2026-11-20. Orchestrator [AGENT]. Branch `fix/attribute-preservation`, worktree
`worktrees/cerberus-lean-fix/attribute-preservation`, base = mainline `mdd/cerberus-lean` `dd0f52fe6`. Roadmap
`docs/2026-11-10_roadmap-maintenance-and-reporting.md`, active item 3 (a consumer is blocked).

## Provenance

- The consumer refinedc-lean (`/home/dev/projects/refinedc-lean`, read-only; its pin of this repository is in
  `scripts/semantics-pin.env`) reports that eight placements of a C23 attribute silently lose it: four before the Cabs
  tree is written, four during lowering to Ail. Its probe: `worktrees/release-public-alpha-prep/scripts/probes/discarded-contracts.py`;
  its account: `worktrees/release-public-alpha-prep/docs/PUBLIC-ALPHA.md` (the section on lost postconditions). For a
  verifier the loss turns a written postcondition into `True`.
- Orchestrator's reproduction on `dd0f52fe6` and on pristine upstream `c3ff8c53f` (2026-11-20; `[[rc::ensures("{False}")]]`
  at ten placements, the count of `ensures` in `--cabs-json` and in `--pp=ail --ast=ail`): kept at the function
  declaration and on a `return` statement; absent from Cabs after the parameter list, after the return type, on a
  parameter before its type, after a local's type; present in Cabs and absent from Ail after the function name, after
  a parameter name, after a local name, before a local declaration. Pristine is identical: upstream's behaviour, a
  fork-ahead change and a filing, not a regression. gcc 13 `-std=c2x` accepts all ten.
- [USER 2026-11-20] ruling: establish whether this is an instance of a broader category of defect, and repair the
  category if it is.

## The principle

A construct the front end accepts is, at every later stage, either carried, or given its meaning, or refused loudly.
It is never dropped without a trace. For attributes the fork gives NO new meaning to anything: preservation is
carriage (the attribute, its arguments' tokens and its source location reach Ail attached to the entity the C23
grammar says it appertains to, 6.7.12.1), which is what a consumer needs and changes no C semantics.

## M0: the census (commit it before any code)

`docs/2026-11-20_discarded-constructs-census.md`: a table built by READING the grammar and the desugarer and
CONFIRMED by probes on both engines and pristine.
- Attributes: every production of `parsers/c/c_parser.mly` that mentions `attribute_specifier_sequence` or
  `attribute_specifier` (39 mentions), and every C23 6.7.12 placement the grammar does not accept at all (a parse
  error is loud: fine; record it); for each, whether the semantic action keeps the value, where `cabs_to_ail.lem`
  drops it (its own TODOs at `:4011`, `:4388`, `:5218` are starting points), whether Ail has a slot, whether the Ail
  typing, the Core elaboration and the Cabs JSON export / `CabsImport.lean` keep it, and what both engines print.
  Include struct/union/enum specifiers and members, enumerators, labels, every statement form, declarations at file
  and block scope, parameters, abstract declarators and type names, `for`-init declarations, function definitions,
  the empty attribute declaration, `[[a, b]]` lists, repeated specifiers, `ns::name`, arguments with balanced tokens,
  and the standard attributes (`deprecated`, `fallthrough`, `maybe_unused`, `nodiscard`, `noreturn`, `unsequenced`,
  `reproducible`). GNU `__attribute__((…))`: what the lexer/parser does with it today.
- The wider category: every other place the parser or desugarer ACCEPTS a construct and discards it with no effect
  and no diagnostic. Search for it systematically (semantic actions that bind a value to `_` or never use it;
  desugarer arms that match a constructor and return the result without it; comments containing "ignore", "TODO",
  "for now"): candidates include `#pragma` lines, `register`, `restrict`, `inline`, `_Noreturn`, `_Alignas` on
  forms where it is not applied, bit-field details, `static`/qualifiers in array parameter declarators, old-style
  parameter lists, `asm` forms beyond the D9 refusals, designator forms, `_Atomic`, `_Thread_local`, `typeof`,
  enum underlying types. For each: DISCARDED-SILENTLY (with what a C program can observe, if anything),
  CARRIED, GIVEN-MEANING or REFUSED, with the probe.
- A verdict paragraph: is the attribute loss an instance of a broader defect, and of what shape.
Send the orchestrator the census commit hash and its verdict when it is committed, and continue to M1 without
waiting unless the census finds a discarded construct whose loss changes a C program's observable behaviour on
valid input (a silent wrong answer): that is reported at once.

## M1: the attribute class (parser, Cabs, the JSON boundary, the desugarer, both engines)

- Every attribute the grammar accepts reaches Ail with its location, attached to the entity it appertains to. Where
  Ail has a slot (declarations, statements, tag definitions and members already carry `Annot.attributes`), use it.
  Where the attribute appertains to a TYPE occurrence or a declarator part with no slot, the order of preference is:
  (1) attach to the nearest enclosing declared entity with a marker of the placement, if that is information-
  preserving and unambiguous; (2) add a carrier slot, if the change to the Ail/Core types is small and the consumers'
  surface is unaffected or the effect is stated; (3) refuse loudly (a declared refusal in the D11/D12/D13 form,
  attributed, the placement named). Never (4) drop. A refusal must not reject a program for a STANDARD attribute in
  a placement the standard permits unless carriage is truly impossible: say which case each placement fell into and
  why. If (2) would change a type a consumer pattern-matches on widely, STOP with a park record and the options.
- The Cabs JSON export and `lean_frontend/CabsImport.lean` carry the new fields (fail closed on a missing field, as
  the position fields do); the committed fixtures regenerate; `cabs-import-test` gains the cases.
- Both engines by generation for the desugarer; the Lean engine's Cabs import by hand, mirrored with cites.
- The parser's reduce/reduce note at `:1117` is upstream's; do not make the conflict count worse (the build prints
  it: quote before and after).

## M2: the rest of the category

Every DISCARDED-SILENTLY row of the census outside attributes is closed by the standing rules: carried where that
is the construct's whole meaning to a consumer; REFUSED where discarding it can change what a valid program does
and the model has no semantics for it (a declared refusal, attributed); left as upstream's judgement, FILED, where
the standard lets an implementation ignore it and nothing observable is lost (say which clause). No fork semantics
are invented. Anything larger than a small arm (a construct needing a real implementation) is filed and listed,
not built.

## M3: witness, documents, filings

- `scripts/check_attribute_carriage.sh` in ladder row 1, a CORE kept under a minute with plants (the ten consumer
  placements, each census placement class once, the refusals' texts whole, pristine the negative control), and the
  full placement matrix as a Tier B row if it is larger (the printf and rank witnesses are the precedent).
- The consumer's own probe is the acceptance test: run `discarded-contracts.py`'s ten programs through this
  worktree's engines and show the attribute reaching Ail (or the refusal) at each; you cannot run their CLI against
  your build, so state exactly what you ran instead.
- CONTRACT (D19), VALIDATION, SUPPORTED, LADDER, TODO; tray reports (the attribute losses; one per other category
  row filed) in the tray's form with reproducers on pristine and patches where the fork carries a fix, INDEX rows with
  CLASS and STATE; consumer notes for refinedc-lean, cerberus-caesium and cerberus-sl (what now arrives in Cabs JSON
  and Ail, which fields are new, what refuses); the record `docs/2026-11-20_attribute-preservation-record.md`.

## Process

Focused gates only; never `scripts/release.py` (the orchestrator runs Tier A on M1 and the battery on the tip). All
make/dune through `/home/dev/projects/cerberus-lean-proj/scripts/ce`; lake/lean through `scripts/capped`,
`CERB_MEM_MAX=32G`; the build is under `-DwarningAsError=true` and stays so. A change to generated types can move
measure proofs and the Core-quotation digests: kernel replay over every changed proof module is owed and quoted; say
which digests move and why. Fork-drift manifest: single-row edits with dated NOTEs, never `--refresh`; hand-written
OCaml files entering the delta are registered. Check `/proc/loadavg` (< 12) and `free -g` before heavy jobs; long
runs through the harness's background execution; no poller, watcher or sleep loop; never `pgrep -f`/`pkill`. No
network; `/tmp` unreadable; scratch under the worktree's `.tmp/`, deleted at the end. Commits per milestone on green
gates, provenance tags, never quote the operator, no speculation about upstream's plans, ending with
`Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`. Nothing pushed; no mainline commit. A blocker: a
committed park record (`docs/2026-11-20_attribute-preservation-park.md`) and a stop. A build approaching an hour:
stop and report. Report: hashes, the diff stat, gate lines verbatim, the census table's counts by class before and
after, the placement-by-placement outcome, what was not done.
