# Response to cerberus-lean's design note "the run's minting digest as run-state data"

**Status:** [AGENT 2026-09-20, the `s3-ladder` agent] cerberus-sl's review of cerberus-lean commit `b4422df14`
(`lean_frontend/docs/2026-09-20_run-digest-as-state-design-note.md`, branch `docs/run-digest-design`, written against
mainline `5407597d9`), requested by the operator ("would it meet the upstream needs we have for resolving our problem?").
The two rulings the note leaves to us that are the operator's (its questions 4 and 5) are recorded with [USER]
provenance in §4; the rest is the agent's under the C3.34 delegation. DECISIONS C3.56. The operator relays this
document.

## 0. Verdict

**The design meets the need.** It is our hidden-state note's item 1 (`docs/2026-09-18_hidden-state-upstream-note.md`)
made exact against the model, and it settles item 6 with it, as we said it would. After it lands, the assumed model
property `MintDigestC P` disappears from every signature in our tree: the property it states is `rfl` on the generated
definition once the program carries the run digest as data. We accept the one design point the note puts to us (§5:
the program's digest is the RUN's seeded digest, carried as data, not the digest of `main`'s symbol).

## 1. Fit against what we asked for

| We asked (item 1 / item 6) | The note delivers | Fit |
|---|---|---|
| the digest as DATA on `core_run_state`, seeded by the driver entry from the pipeline's TU digest | `sym_digest : Symbol.digest` beside `sym_supply`; `initial_core_run_state_given sup dg xs`; `initial_driver_state … digest …` with the digest an explicit entry parameter (§3.2–3.4) | exact |
| `fresh_given_int (d : String) (n : Nat)` with no hidden read | `fresh_given_int d n = Symbol d n SD_None`, `rfl`; `Core_run.fresh_symbol'` reads `run_st.sym_digest` beside the counter (§3.1, §3.3) | exact |
| the digest carried on the program so `fresh_given_int P.digest m` is a kernel term | left to us as the §5 decision (a field of `Program` or a `progOf` argument), seeded from the same value the entry receives | accepted, §2 |
| library `""` ≠ the run digest becomes a theorem (item 6) | `CoreParser.mkSym`'s `""` untouched; the run digest is a 32-hex MD5 (an entry-shape pin `runDigest … ≠ ""`); our `symFresh_of_digest` already takes `P.digest ≠ ""`, decidable per program | exact — the class disappears, the hypothesis stays where it is |
| effect-erasure compliance | the run path loses its ambient read; frontend minting keeps it (§3.6) — no theorem of ours mentions frontend minting (we quantify over the captured `file`) | compliant |
| the OCaml differential byte-identical | zero movement on every lane: the minted VALUE is unchanged on both engines, only its provenance moves; `Fork_renumber.fresh_symbol'` stays ambient as a documented mirror (§3.3, §6) | sound argument; their verification to ship |

**Confirmed at our pin (`e64819de7`)**, independently of the note's citations at mainline: the generated `Core_run.lean:126`
is the ONLY generated run-path caller of `fresh_given_int`; `Core_linking.create_extern_symmap` (our `Program.extern`)
calls only `CerberusFresh.digest_compare`, a pure string comparison (`CerberusFresh.lean:45-46`), never the ambient
digest; `Core_aux`, `Core_eval`, `Driver` mint nothing. So "the ONE run-time minting site" holds of the model we prove
against today, and the invariant we add in §3 is the whole of our side.

## 2. The note's §5, accepted: `Program.digest` is carried data seeded from the entry

Our `Program.digest P` (`SymFresh.lean:65-68`) reads the digest off `main`'s symbol — right for a single translation
unit, FALSE of the engine for `cerberus main.c helper.c` (the engine mints with the LAST unit's digest, §3.5 of the
note; `main`'s unit is not necessarily last). Every ladder program is a single unit, so nothing we have proved changes;
the definition change is what makes the multi-unit statement true. We accept, as a **field**:

```
structure Program where
  file   : generic_file Unit core_run_annotation
  supply : Nat
  digest : String          -- the run digest the driver entry receives (the LAST unit's; runDigest tunits)
def progOf (F : file Unit) (supply : Nat) (digest : String) : Program := ⟨convert_file F, supply, digest⟩
```

Consequences on our side, all routine:

- **The capture emits it.** `Corpus/Capture/Pipeline.lean:95-100` already holds the per-unit digest (it is what the
  capture installs for the frontend's own minting); the quoted modules `Corpus.T*` gain `def digest : String`, and
  `corpus-check` verifies it against a fresh frontend run exactly as it verifies `supply` and `tagDefs` today — "checked,
  not proved" (INTERFACE §7), one more quoted field. The endpoints take `progOf F Corpus.T*.supply Corpus.T*.digest`.
- **The fail-closed arm goes.** Today a program without `main` has digest `""` so `symFresh_of_digest` fails closed on
  it; with the field there is nothing to fail on. `symFresh_of_digest`'s hypothesis `P.digest ≠ ""` stays, decidable
  per program (`T11Guard.t11_digest_ne` is its instance today and becomes `decide` on the field).
- **`T11Guard.t11_digest`** (`(progOf F 68).digest = "4e7ec6…"`, proved today by unfolding `main`) becomes `rfl` on the
  captured field. A `#guard Corpus.T11.digest = symDigest main_sym` speedbump documents that a single-unit quote's run
  digest is `main`'s stamp; a test, not a proof.
- **The freshness discipline is unchanged** (C3.27): program symbols of the last unit are fresh by NUMBER (below the
  supply); program symbols of other units, and the library's (`""`), are fresh by DIGEST. `symFresh_of_lt` and
  `symFresh_of_digest_ne` are the two lemmas, as now.

## 3. Our side at the re-pin — what "true by `rfl`" leaves to us

`MintDigest` as the note restates it (`∀ m, symDigest (fresh_given_int P.digest m) = P.digest`) is `rfl`. Our
CONDITIONAL theorems becoming unconditional needs one more thing the note does not mention because it is ours: a
**run-state invariant** `rs.sym_digest = P.digest`, the twin of the label-table clause we already carry
(`ExecInv.Inv.table : rs.labeled = P.labels`) and of the supply bound (`P.supply ≤ rs.sym_supply` in `Sim.Rel`), so
that `SymFresh P x` — stated over the program's digest — can be consumed against the engine's minted term
`fresh_given_int rs.sym_digest rs.sym_supply` (`SimAssemble.lean:225` is the consumption site). Established by the seeded
initial state (`rfl`), preserved because no step writes the field (a one-line twin of `headStep_sym_supply_mono`).

The consumer surface, all mechanical (counted at C3.54):

| Change | Where | Sites |
|---|---|---|
| `Program` gains `digest`; `progOf` takes it; `Corpus.T*` emit it; the capture prints it | `Lang`, `Interface`, `Capture.Printer`, 8 quoted modules | 1 + 1 + 1 + 8 |
| `core_run_state` literals gain `sym_digest := P.digest` | `Lang`, `DriverLoop`, `SimAssemble`, `RoundCtrl`, `HeapNeg`, `Call` | 7 |
| the run-state clause `rs.sym_digest = P.digest` beside every `P.supply ≤ rs.sym_supply` | `Sim`, `SimAssemble`, `HeapCreate/Memop/Region/Neg/LK/Rules`, `Call`, `RulesS`, `CallS`, `Triple` | ≈38 |
| `SymFresh P y := ∀ m, P.supply ≤ m → symEq y (fresh_given_int P.digest m) = false`; `symFresh_of_digest_ne` unconditional | `SymFresh` | 1 def, 2 lemmas |
| `[MintDigestC …]` deleted from signatures | `CertP`, `WFprocDec`, `T11Guard`, `T11Adequacy`, `Spikes.T11S` | 12 |
| `MintDigest`, `MintDigestC`, the Spikes pin `mintDigest_pin_t11` | deleted | — |
| the mirror's `HeadStep.neg_rewrite` mints `fresh_given_int rs.sym_digest rs.sym_supply` | `Lang` (+ `arenaOK_negRewrite`/`stepRel_negRewrite` take the digest) | 3 |
| prose: `Lang.lean:69-79`, `SymFresh.lean:7-8`, `HeapNeg.lean:34,135` | docstrings | 4 |

**The re-pin carries more than the digest.** The note's "today" signature `initial_driver_state (sup) (top) (file)
(fs)` is mainline's: the address-space top (charter S3.R2's part two) is on mainline (47 commits past our pin) but not at
`e64819de7`, where the entry is `initial_driver_state (sup) (file) (fs)` (generated `Driver.lean:492`). With E-A's enum
reader (+1 leading argument on every reader-taking signature, `drive` included) the next re-pin changes three
signatures at once; the digest is the smallest of the three. Hence the ruling in §4 Q4.

## 4. Answers to the note's §7 questions

1. **§5 — accepted [AGENT, C3.34 delegation]:** `Program.digest` is a FIELD seeded from the entry (§2), `progOf F supply
   digest`. Field rather than a bare argument because `Program` is the structure every layer statement is over.
2. **No exported theorem needed [AGENT]:** we state `fresh_given_int d n = Symbol d n SD_None := rfl` and the
   `MintDigest`-shaped `rfl` ourselves, in the layer, against the generated definition. A named theorem in a hand-written
   module is welcome for stability but we do not depend on it; do not spend a module on it.
3. **No theorem of ours uses `Program.digest` for a PROGRAM symbol's digest [AGENT, verified by grep over
   `CerberusIris`/`CerberusSL`/`Spikes` at C3.54]:** every use is as the RUN digest (`MintDigest`, `symFresh_of_digest_ne`)
   or as the `≠ ""` hypothesis (`symFresh_of_digest`, `WFprocDec.symFresh_of_libDigestB`, `CertP.libProcCheck_sound`); the
   one computation from `main` (`T11Guard.t11_digest`/`t11_digest_ne`) is the single-unit instance and becomes `rfl`/`decide`
   on the field. Consistent with §5.
4. **Timing — [USER 2026-09-20] "agree, we should wait for the complete solution to land":** ONE re-pin, taken after the
   digest slice has landed alongside E-A (and the address-space top already on mainline), never two. [AGENT] our
   re-pin cost is the semantics rebuild plus re-verifying the 49 hand-written seams; no single signature change is
   the cost, so bundling is strictly cheaper for us.
5. **Item 7 (`SelectAgreesC`) — [USER 2026-09-20] "we can ask for this immediately":** we request that the item 7 work be
   STARTED NOW, not queued behind this arc. [AGENT] the reason is arithmetic: item 7 conditions six of our seven rungs
   (t5, t4, t3, t9r, t2r, t11), the digest conditions t11 alone; v1 needs both (INTERFACE disclosure 22). We do not ask
   that the digest slice be delayed for it — it is designed and small — only that item 7 not wait for the digest to
   land. If item 7 lands within the same window, the one re-pin of Q4 covers it too and every rung of the ladder
   becomes unconditional at once. The exact contract is in our note's item 7 (fail-closed arity mismatch as NO MATCH,
   `select_case` continuing to later arms, bindings and their order kept; acceptance criterion the selector equality
   `select_case subst_sym_expr v pats = selectCaseE v pats` and its pure twin); a structured-error semantics would not
   discharge it.

## 5. What we will verify at the re-pin (our acceptance)

- The definition shape: `fresh_given_int d n = Symbol d n SD_None := rfl` in the layer; the `MintDigest`-shaped `rfl`;
  the pin `mintDigest_pin_t11` DELETED, `MintDigestC` gone from the tree (the D13 tripwire may name it as a banned
  identifier afterwards, so a resurrection is loud).
- `Spikes.T11S.t11_adequacy_concrete_pin`'s cone: exactly `selectAgrees_pin` (or the trio alone, if item 7 has landed).
- `corpus-check` green on the eight quoted modules with their new `digest` field against the re-pinned frontend; the
  seven recorded outcomes unchanged.
- The run-state invariant's preservation theorem trio-only; `check.sh` ALL CHECKS GREEN; the pins re-counted.

## 6. One remark for the note's authors, no action asked

`initial_core_run_state dg xs` (the non-`_given` constructor, §3.2) still draws its supply from the ambient
`Symbol.fresh_int ()`; our adequacy runs only through the supply-threaded `initial_driver_state`, so this is not on our
path and we ask nothing — noted so the effect-erasure page's "frontend minting only" paragraph is not read as covering
that constructor.
