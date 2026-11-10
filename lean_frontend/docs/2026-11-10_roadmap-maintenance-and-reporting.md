# Roadmap: maintenance and upstream reporting (2026-11-10)

Status: the direction for this repository from 2026-11-10 until it is revised. It replaces the fix-pass ordering of
2026-11-04 for everything not yet started. `TODO.md` stays the backlog; this note says which parts of it are active.

## The decision

[USER 2026-11-10] The project stops adding fork-ahead changes to the Lem model and the generated layer, except where
a consumer is blocked, and puts its effort into (1) leaving the two repositories in a consistent state, (2) reporting
what it has found upstream, and (3) supporting its consumers at their pins.

The reasoning, in the agent's words: every fix or refusal written against the current model is a fork-ahead delta
that has to be carried, re-gated and re-explained at each merge-base move, and it is only as durable as the code it
patches. The outputs that keep their value whatever happens to that code are the findings (the upstream tray), the
witness programs pinned to a reference compiler, the differential method, and the Core-level surface the consumers
build on. The fork is already ahead of upstream on fourteen reported defects; sixty-four of the seventy reports have
not been sent (derived from `docs/upstream-tray/INDEX.md` at `03c8b4451`). Reporting is the larger unpaid debt.

## Active work

1. **Close the lem pin invariant.** The lem mainline carries TODO 54 (unreferenced binders, inert `termination_by`)
   since `df9743c`; the cerberus pin is still `e6d8db5`. One slice re-pins, regenerates (Lean-only delta, OCaml
   byte-identical), and removes the generated tree's linter warnings. After it both repositories are consistent and
   the working-practices doc's pin line is true again.
2. **The reporting slice (documents only).** The true-bug audit of 2026-11-04 is distilled into the tray (its
   sibling findings filed, the report texts it found wrong corrected); every report is classed as a defect of C
   semantics that any implementation of the model would have to answer, or as an artifact of this code; the witness
   corpora (`tests/macro_type_ranks`, `stdio_exit`, `printf_refusals`, `address_constants`, `half_mirrors` and the
   refusal witnesses) get one index that lets them be run and read without this repository's ladder. The crash sites
   the audit lists are reported, not refused in code.
3. **Consumer support.** cerberus-caesium and cerberus-sl pin this repository by commit. A defect that blocks either
   is fixed under the standing rules (the standard very clear or the consumer blocked; otherwise a declared refusal
   and a report). Their filings are answered; re-pin notes are written for every landing.
4. **Upstream filing.** Sending is the operator's action. The tray's reports are kept ready to send: a reproducer,
   the clause, the locus at the merge-base, and a patch where the fork carries one.

## Not started unless a consumer needs it

- Crash-to-refusal as code (wide characters, statement expressions, multi-character and UCN constants, the argv
  store, the GNU `?:` contexts, `bswap64`, `aligned_alloc` of zero, the braced-initializer and incomplete-struct
  crashes): reported under item 2 instead.
- The shipped library's false-UB items (trays 30, 31, `sscanf`), the nested-initializer refusal (08), string-literal
  members (23): reported, not fixed.
- Implementing the refused printf conversions (`%e`/`%g`/`%a`, `L`, `%n`, `%ls`, `%lc`): they stay D16 refusals.
- Merge-base bump stage 2 and the implementation switch.
- Further lem-lean backend work beyond keeping the pinned revision building (TODO 24, 58, 59 and the rest of its
  register stay logged).

## Unchanged

The working practices (branches, ff-only landings on sign-off, the validation battery before any claim, reviews,
record integrity) apply to the active work as before. The trust surface that exists is kept green: ladder row 1 on
every commit, the battery and kernel replay where a slice owes them, `lake check` by the operator at claim points.
Nothing here retires a gate.

## Revisit

When a consumer's needs change, when upstream answers the reports, or at the operator's call.
