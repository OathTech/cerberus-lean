# Codex charter — the outcome protocol, checkpoints A–E (design v2 revision 3; cerberus-caesium note 2 §A–§C) (2026-10-18; rev 5 of 2026-10-20 replaces the S1–S2 form)

**Status: DISPATCH-READY on the operator's go.** The design is
`docs/2026-10-20_outcome-protocol-design-v2.md` at revision 3 (commit `a2622309b` on
the landing branch), accepted after two independent reviews
(`docs/2026-10-19_outcome-protocol-design-review.md`, which found v1 NOT READY
and whose author then drafted v2 on its revised mission plan, and
`docs/2026-10-20_outcome-protocol-v2-review.md`, commit `5aaef720f`, whose four
findings revision 3 disposes). Revisions 1–4 of this charter described the
S1–S2 delivery of the withdrawn v1 note and are superseded whole.

**Branch:** `arc/outcome-protocol` · **worktree:** `worktrees/cerberus-lean-arc/outcome-protocol`
(created primed at dispatch from a mainline carrying this charter AND design v2 revision 3).
**Worker:** one Codex worker, checkpoints A–E in order. Never merges, never pushes,
never edits lem-lean, `.lem` sources, the Lem pin or `deps/`.

## 0. Goal, rulings, success condition

**Goal.** Two goals and nothing else ([USER 2026-10-20]): (1) soundness with respect
to upstream Cerberus: our own lanes stop absorbing a port invariant failure as a
matching crash and stop inferring a shared-model origin from the absence of an
envelope; (2) what cerberus-caesium's `scripts/differential.py` needs: to read, from
batch output, which of REFUSAL / UPSTREAM_CRASH / INVARIANT stopped a run, with its
attribution metadata, and to get every cause the run emitted. No refactor of the
validation apparatus beyond that; v2 §9 lists the deferred work with the finding each
item addressed and why deferral is sound.

**Rulings (paraphrased, tagged):**
- [USER 2026-10-20] v1 is withdrawn as the fact table; v2 (revision 3) is the design.
  Delivery is operational now: the ModelFailure sentinel collision and the pure-abort
  runtime boundary are stated limits (v2 §1.2); the structural-outcome arc stays their
  named mover. No new opaque atom, no `.lem` change, no Lem pin move, CONTRACT §1's
  four outcomes unchanged.
- [USER 2026-10-20] Scope as narrowed (v2 revision 2, §9): kept = stop type and
  envelope, full producer migration, Python decoder over the existing channels, the
  two lane corrections, the consumer demonstration; deferred = capture sidecar and
  Host tuple, timeout/timing subtype, Report schema and machine CLI, usage-error exit
  change, all-lane rerouting, stack classification, extra speedbumps.
- [USER 2026-10-20] The reconstruction reference contract (v2 §5, second-review
  finding 1): the parameterised form — both reference algorithms in
  `test/Unit/ReconstructLegacyTest.lean` take their diagnostic messages as a
  parameter; a historical instance recovers the old frozen references; the production
  compatibility theorem is restated at the production renderer with every current
  quantifier; headers, theorem descriptions and the consumer note name the changed
  claim; axiom census and kernel replay run on the result.
- [USER 2026-10-20] v2 §6, Q1–Q14, as recommended there (class tags REFUSAL /
  UPSTREAM_CRASH / INVARIANT with RESOURCE evidence-derived; allocator OOM stays the
  semantic kill; usage errors deferred; switch kills through the existing memM panic
  with a structured refusal; the thirteen wire boundaries; the Q-A sweep annotates all
  hand-written mirror/guard sites and keeps the print-then-kill and defined arms;
  `.unsupported.c` requires an admitted REFUSAL; no new speedbump; stack deferred;
  trays cited/drafted with explicit state; CLI invariant exit 2; collections with
  invariants RED; no capture scope change; B–D delivered together).
- [USER 2026-10-18] gate scheduling: focused checks while developing; Tier A at every
  worker-boundary claim and before each reported commit; Tier B at close-out; the
  orchestrator re-runs both. [USER 2026-10-18] kernel replay is a named trust gate
  for any changed proof: `lake env leanchecker` over the affected modules, quoted.
- Standing: fail-closed and fail-noisy; mirror-OCaml doctrine; no magic values; no
  verbatim quotes of the operator; decisions tagged [AGENT]/[USER]; the user's
  rulings above are the operator's, everything the orchestrator adds is [AGENT].

**Success condition (one complete first consumer delivery, v2 §5):**
1. `CerbStop` (structured `Stop` with Refusal / UpstreamCrash / Invariant, Boundary,
   Upstream, Tray; `render`/`parse` with `parse (render s) = .ok s` on well-formed
   values; the frozen fixed-array JSON wire schema of v2 §2 with its escape-token
   guard) and the three channel adapters of v2 §2.3; pure sites keep the `failwithI`
   head applied to the rendered stop.
2. Every hand-written producer migrated (v2 §5 C): the nine typed kills; the existing
   pure/monadic and driver refusals; the remaining hand-written pure mirrors and
   annotated guards; the twelve config-dead switch refusals, one envelope per element
   then one exit; with their immediate tests and witnesses in the same commits — the
   seven `MonadicFailstop` pins, `PnviArmsTest`, the three CLI witness scripts and
   stubs, `test_fuel_plant.sh:220–227`'s three assertions, the observation-lane
   positive plant (envelope) with its envelope-less negative kept — and the
   reconstruction references under the ruled contract; the failure-reach register's
   affected hand-written keys resealed with old-to-new mappings (positions and reach
   recomputed, differences explained).
3. Python `decode_stop` over the existing channels (v2 §4): ModelFailure records (outer
   escaping decoded first), the LemLib panic frame, CLI stderr lines; returns every
   stop in a capture; distinguishes absent from malformed reserved prefix; never scans
   program data or ordinary Error payloads; fuel forms only in their exact frame
   positions; the wrapper suffix rule admitting the root-relative `scripts/capped`
   spelling; completeness defined over complete EMITTED records only.
4. The two lane corrections (v2 §4.3): INVARIANT is RED in `pnvi_lane.py` and
   `test_immaculate.sh` whatever the oracle did; an envelope-less panic is "legacy,
   origin unattributed", never SHARED_CRASH; their focused plants; baselines move only
   with a per-row explanation; a semantic verdict movement stops the slice.
5. Consumer demonstration (v2 §5 E): `differential.py`'s capture shapes for every
   family, a mixed emitted-cause batch, the mixed pure/typed program with zero emitted
   ModelFailures in exhaustive mode (the loss before emission, stated as such), the
   patch recipe; cerberus-sl's fuel/OOM aliases and kill lift rechecked; the family
   table at the first delivery; no external adoption claimed.
6. Gates: Tier A green at each checkpoint's commit; Tier B (`python3 scripts/release.py
   --mode full`) at close-out, quoted; kernel replay over every module whose proofs
   changed (at least `Unit.ReconstructLegacyTest` and whatever `CerbMemDefaultFacts`
   / `CerbMemAccessFacts` statements it touches), quoted; the axiom census entries
   of `scripts/check_theorem_axioms.sh:811–817` updated, never dropped.
7. Documents: the record `docs/2026-10-20_outcome-protocol-record.md`; `CONTRACT.md` §1
   (the class vocabulary beside the four outcomes, with the emitted-records limit);
   `VALIDATION.md` §4; `LADDER.md` rows touched; consumer notes for cerberus-caesium
   (families, limits, the patch recipe, the convention for capturing stdout/stderr
   separately) and cerberus-sl.

## 1. What is known

v2 revision 3 is the fact table: §1 claims and limits, §2 schema and adapters, §3 the
existing capture boundary (today's rule: a bare 137 is RED, the positive
`oom_kill` counter is the witness), §4 decoder and the two corrections, §5
checkpoints, fence, inventory and the reference contract, §6 rulings, §7–§8
dispositions and measured probes, §9 deferrals. The inventory
`docs/2026-10-08_stop-paths-inventory.md` §3–§5 lists every site. Where the tree has
moved since v2's base (`e7e9bb427`), the tree wins and the record says so.

## 2. Checkpoints (ordered; v2 §5 estimates, [AGENT])

| Checkpoint | Exit | Estimate |
|---|---|---|
| **A — settle** | Tier A on the untouched worktree; today's output of every stop kind re-measured on one witness each; the `ReconstructLegacyTest` inventory and the dependent theorem families listed with their current statements; the Q-A dispositions confirmed per site; the fence confirmed against the tree. Report before B. | 0.5 day |
| **B — core** | `CerbStop`, adapters, `decode_stop`, round-trip / escaping / absent-vs-malformed / collection / injection tests; no production producer moved yet. Tier A; commit. | 1–2 days |
| **C — migrate** | Every producer of success item 2 with its tests, witnesses and reseals in the same commits; the reference contract implemented and its theorems restated; axiom census + kernel replay. Tier A; one or more commits; report. | 2–4 days |
| **D — lanes** | The two corrections, their plants, the explained baseline rows. Tier A; commit. | 0.5–1 day |
| **E — close** | The consumer demonstrations and notes; the record; Tier B quoted; the candidate presented for the fresh pre-merge review. | 1 day + review |

## 3. Flex — what you decide, and when to stop instead

- Yours: module and file layout within the fence; the order of sites within C; the
  plant suites' shape; commit splits inside B–D; the exact detail/mover/see texts
  (within the schema).
- Not yours: the schema, class tags, boundaries, channels and exit codes v2 fixes; any
  verdict; any deferred item of v2 §9; any site needing a generated-type or `.lem`
  change (list it for WP2); lem-lean; the pins; baselines without a per-row explanation.
- **Stop and report when:** a semantic verdict moves; a site cannot be migrated
  without a type change; the reference-contract proof work exceeds a day; the design
  is found wrong on contact (say where, propose the amendment, do not improvise a
  class); any run approaches the one-hour tripwire; you are done.

## 4. Rules (binding)

Environment and hand-written-copy synchronisation (`make lean-prelude-src` after any
`lean_frontend/*.lean` edit, before every capped `lake build`; `handwritten_copy.manifest`
registration for `CerbStop.lean`; Lake roots / executable registration), checks (Tier A at
each checkpoint's commit; Tier B at close-out; kernel replay and axiom census for changed
proofs; the orchestrator re-runs independently at every boundary), provenance and
no-quotes — as the translation charter §4 states them, EXCEPT its `.lem` regeneration,
oracle-rebuild and manifest instructions (no `.lem` change; the generated OCaml and the
fork-drift manifest's oracle surface do not move; a `scripts/common.sh` edit, if any,
re-pins its single source-content row with a dated NOTE). File fence: v2 §5's list —
`CerbStop.lean` and its tests, `lakefile.toml`, `handwritten_copy.manifest`, the
affected seams (`CerbMem`, `CerbFS`, `CerbFloat`, `Main`, the inventory's other
hand-written sites), `test/Unit/MonadicFailstop.lean`, `test/Unit/ReconstructLegacyTest.lean`
and the statements it depends on, `PnviArmsTest.lean`, the three CLI witness scripts and
stubs, `scripts/test_fuel_plant.sh`, `scripts/observations.py` and its tests,
`scripts/pnvi_lane.py`, `scripts/test_immaculate.sh`, `test_observation_lanes.py`,
`scripts/failure_reach_register.txt`, `scripts/check_theorem_axioms.sh`'s entries,
`CONTRACT.md`, `VALIDATION.md`, `LADDER.md`, records and notes.

## 5. Reading list

`docs/2026-10-20_outcome-protocol-design-v2.md` (whole) · the two reviews and the
revised mission plan · `docs/2026-10-08_stop-paths-inventory.md` §3–§5 · `CONTRACT.md` §1
· `VALIDATION.md` §4 · `scripts/observations.py` (`parse`, `ABORT_WRAPPER`,
`FUEL_RECORD`, `CAP_OOM`) · `scripts/LADDER.md:144-150` (the OOM witness rule) ·
`scripts/pnvi_lane.py`, `test_immaculate.sh`, `check_cli_refusals.sh`,
`check_runtime_resolution.sh`, `test_fuel_plant.sh` · `CerbMem.lean`, `CerbFS.lean`,
`CerbFloat.lean`, `CerbFail.lean`, `Main.lean` · `test/Unit/ReconstructLegacyTest.lean`,
`test/Unit/MonadicFailstop.lean` · `scripts/failure_reach_register.txt:18-26` (keys and
seals) · the consumer's ask: note 2 §A–§C
(`docs/2026-10-17_consumer-note-cerberus-caesium-response-note-2.md`) and the consumer
agent's list of 2026-10-18, item 4 (a chat relay, not a file; its substance is in §0).
