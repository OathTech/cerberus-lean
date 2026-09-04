# Concurrency support — scoping and deconfliction note (2026-09-04)

Author: the orchestrator [AGENT], at the operator's request ("could we
reasonably start building the concurrency support while closing out the
various sequential issues? … we need this for wireguard and other things
… It's a major design lift … for now I think it makes sense for you to
do the planning / deconflicting / scoping whether it's possible to run in
parallel" [USER 2026-09-04]). Facts below were measured in this tree
(`mdd/cerberus-lean` @ `1b57bcf26`) and upstream `deps/cerberus-upstream`
@ `b9aeedcb4`; recommendations are [AGENT].

## 0. Answer in one paragraph

Yes, a concurrency feature branch can run in parallel with the sequential
close-out, provided it starts from the right premise: at our merge base
upstream Cerberus has NO working executable concurrency — the model
(`frontend/concurrency/cmm_op.lem`, the Nienhuis operational C11 model,
and `cmm_csem.lem`, the cppmem axiomatic model) is present and already
GENERATES to Lean, but the driver's concurrency branch is a stub
(`driver.lem:754-755` `if with_concurrency then error "TODO:
perform_action_request2 ==> concurrency"`; the flag is hard-wired `false`
at `:980`). So Phase 0 is not "port the concurrency", it is "resurrect the
executable operational C11 path in the fork's driver, on both targets at
once, with an external litmus oracle". The deconfliction with the
sequential arcs is narrow and listed in §4. The strategic design question
— which memory model refined-cerberus should build on for Linux-class
code — is real and is NOT answered by C11's model; §3 scopes it as a
phased program with the parametricity principle as the guide.

## 1. What exists (measured)

| Artefact | Where | Size | State |
|---|---|---|---|
| Operational C11 model (Nienhuis, OOPSLA 2016 "An operational semantics for C/C++11 concurrency") | `frontend/concurrency/cmm_op.lem` | 813 lines | generated to Lean today: `lean_frontend/generated/Cmm_op.lean` (612 lines); untouched upstream since 2019 |
| Axiomatic C11 model ("cppmem model exploration tool") | `frontend/concurrency/cmm_csem.lem` | 3,420 lines | generated: `Cmm_csem.lean` (2,493 lines); 23 `declare lean target_rep … = \`sorry\`` declares UNREFERENCED (TODO.md:105) — a live landmine for any consumer of the model |
| Equivalence proofs, Isabelle | `Cmm_op_proofs.thy`, `Cmm_master_lemmas.thy` | 5,145 + 2,476 lines | the operational model is proved against the axiomatic one — the trust asset of the whole package; not ported |
| Driver integration | `frontend/model/driver.lem` | `concurrency_state: Cmm_op.symState` in the driver state (:67), `with_concurrency` threaded through `driver2`/`process_core_step2` (:1321-1427), the action branch is `error "TODO…"` (:754-755), the call site passes `false` (:980) | NON-FUNCTIONAL on OCaml and Lean alike — matched behaviour, both refuse (charter Z-25; `--concurrency` refused by Lean, Z-24; oracle prints `CONCURRENCY IS BROKEN`) |
| Linux kernel model | `frontend/concurrency/linux.lem` | 11 lines | a stub; LKMM is NOT in Cerberus |
| Lean stub | `lean_frontend/CerbConcurrency.lean` | 33 lines | `statically_satisfied := true`; declared temporal boundary, "mover: the concurrency arc"; the forward-design constraint recorded there: "Layer-2/3 shapes must not bake in single-thread/SC assumptions" |
| OCaml SMT runner | `ocaml_frontend/smt2.ml` | 143 lines | `runND` over a `Constraints` module — the vestige of the old constraint-based exploration; the Concrete memory model's constraints are trivially SAT (charter Z-59) |
| Consumer today | refined-cerberus `cerberus-heaplang` | — | `drive fmapEmpty false …`: concurrency OFF by construction; `auxAddToRfLoad` (Cmm_op) is in their cone only as a dead arm (ARCHITECTURE.md:278) |
| Prior notes | roadmap archive (`2026-08-31_container-roadmap-archive.md:113-118`) | — | **Model parametricity principle** [USER 2026-08-19]: "the memory/concurrency model is an aspect to keep AS PARAMETRIC AS FEASIBLE — the research community legitimately disagrees (legacy C11 vs RC11 vs promising vs ...) … (a) fix the INTERFACE at the candidate-execution/event …" |
| Prior notes | manual archive (`2026-08-31_container-manual-archive.md:346-355`) | — | cmm/concurrency arc **RESCOPED 2026-08-26 [USER]-ratified per the pKVM spike**: "lock-invariants M + schedule-streams face M + lem-generated C11 model from upstream cmm_csem.lem M-L; weak-memory logic deferred as its own future program — [USER] 'PhD level work in itself'"; WireGuard demoted behind pKVM ("RCU in allowedips is the harder concurrency") |
| Reading | `deps/papers-weak-memory/` | 31 PDFs | Nienhuis 2016; iGPS 2017; Cosmo 2020; RustBelt-relaxed 2020; Compass 2022; AxSL 2024; relaxed RCU 2025; the iris litreview set |

## 2. The oracle problem (the rule meets the feature)

The standing rule is zero execution discrepancies against the OCaml
oracle. For concurrency the oracle does not exist at `b9aeedcb4`. Three
ways to get one, not exclusive:

- **(O1) Resurrect the fork's OCaml path.** The driver integration is
  `.lem` (`driver.lem`), so writing it ONCE gives both targets the same
  behaviour by generation — this is the one place where editing shared
  `.lem` is the right move: it is a FEATURE the OCaml side lacks, not a
  restructuring for Lean, and it is upstream-facing (tray: "restore
  `--concurrency`"). Upstream's git history (pre-2019) likely holds the
  original implementation of `perform_action_request2`'s concurrency arm;
  recovering it is the first task (mirror upstream-old, cite the commit).
  Cost: M. Risk: the old path depended on SMT constraint solving
  (`smt2.ml`, cvc5 is available offline) — the symbolic operational model
  generates constraints on values; the Lean side would need the same
  (a constraint layer or an enumerative substitute) — this is where the
  Lean port could diverge in MECHANISM while agreeing in RESULT.
- **(O2) External litmus oracle.** `herd7` with the C11 `.cat` model (and
  later `linux-kernel.cat`) on a litmus corpus (the classic C11 tests
  Nienhuis validated against; RC11 paper tests) — an oracle INDEPENDENT of
  the Cerberus lineage, exactly the role gcc plays for the sequential
  lanes. Programs are tiny; exhaustive enumeration is feasible on both
  engines. Cost: S–M for the lane; herd7 needs installing (network window).
- **(O3) The Isabelle equivalence** (`Cmm_op_proofs.thy`) as the argument
  that the operational model IS the axiomatic model — trust for the
  MODEL, not a test for the PORT. Porting the proof to Lean is a research
  project (L+), out of scope; citing it is free.

Recommendation [AGENT]: O1 + O2 together in Phase 0; O3 cited.

## 3. Phasing (each phase a chartered arc; scope decided with the operator before any brief)

**Phase 0 — executable C11 operational concurrency, both targets, litmus-validated (M–L).**
`driver.lem` concurrency arm restored (from upstream history where
possible); `Cmm_op` state threaded (already in the driver state);
`CerbGlobal.using_concurrency` becomes a PARAMETER (the reasoning-
artifact audit's instance A, step 2 — do it here rather than as a
constant flip); `CerbConcurrency.lean` stub DELETED (the model is
generated); the 23 unreferenced `sorry` target_reps in `cmm_csem.lem`
resolved (real reps or removed — they become reachable); `--concurrency`
un-refused in `Main.lean` (Z-24's refusal was "not supported", which
stops being true); a litmus lane (`tests/litmus/`, herd7 second oracle;
the OCaml and Lean engines must agree with each other AND with herd on
the allowed-outcome SETS); the totality gate's slice grows to the cmm
modules (fuel'd or measured per the fuel-parameter rules — the
scheduler's nondeterminism is ND branches, which the runner already
enumerates). Exit: the C11 litmus corpus agrees three ways; the
sequential battery unchanged (concurrency off = today's behaviour,
byte-identical).

**Phase 1 — the model interface (M).** Per the parametricity principle:
fix the interface at events/candidate executions so the memory model is
a parameter of the driver (C11-op today; RC11 / LKMM later), and state
the contract a consumer logic needs (what refined-cerberus's Iris
instantiation reads: the event structure, the per-thread step relation,
the consistency predicate). This is the design lift the operator named;
it needs a written design and a consumer review BEFORE code (the
fuel-arc practice). Inputs: the 2026-08-19 principle, Nienhuis §2, the
Cosmo/iGPS/AxSL papers for what a logic consumes.

**Phase 2 — a Linux-relevant model (L, research-adjacent).** WireGuard
and pKVM code is LKMM territory (`linux.lem` is 11 lines); options are an
LKMM instance behind the Phase-1 interface (herd's `linux-kernel.cat` as
the oracle), or RC11 as the sound over-approximation the logic literature
supports (Cosmo, iGPS). This is where "PhD level work" lives; Phase 0–1
make it possible without deciding it.

## 4. Deconfliction with the sequential close-out (concrete)

| Surface | Sequential owner (in flight / queued) | Concurrency branch touches | Conflict class | Rule |
|---|---|---|---|---|
| `frontend/model/driver.lem` | C1 (deletes 5 numeric declares at :1915-1918; C2 adds `fuel_measure` declares) | the `perform_action_request2` arm (:747-760), the `false` at :980, `driver2` family | different hunks, same file; C1's fuelled `driver2` gains a real `with_concurrency` branch (scheduler nondeterminism = ND, already fuelled) | rebase the feature branch after each sequential merge; the fuel declares and the arm never share a line |
| `lean_frontend/Main.lean` | C1 (`--fuel`), Z3 (link order), Z4 (docs) | `--concurrency` un-refusal | same arg loop | land Z-24's un-refusal LAST in the feature branch; one-line conflict |
| `CerbGlobal.lean` | reasoning-artifact A step 1 (queued: constants as `def`s) | `using_concurrency` as a parameter (A step 2) | overlapping intent | the feature branch OWNS A-step-2 for `using_concurrency` only; A step 1 for the rest stays sequential |
| `CerbND.lean` / runners | C1 (`[LemFuel]`) | none expected (ND branching already exhaustive) | — | — |
| `CerbConcurrency.lean`, `cmm_*.lem` reps, `Cmm_*.lean` generated | nobody | deletion / real reps | none | — |
| Gates: totality slice, opaque census, ratchet | C1/C2 re-pin populations | the cmm modules join the slice | the census counts move on both sides | the feature branch re-pins only its own rows, with reasons; merge order sequential-first |
| Lanes/baselines | Z4 (re-record), C1 (zero movement) | a NEW litmus lane; the existing lanes must not move (concurrency off) | none if the default stays off | any movement in a sequential lane from the feature branch is a finding |
| Box | one heavy sequential worker at a time | a second heavy worker | oracle `CERB_SKIP` under concurrent lanes (known) | the concurrency worker's differential is herd7 + both engines on litmus programs — small; run the sequential battery only at its own boundaries, never concurrently with a sequential worker's battery |
| lem-lean | C1/C2 pin bump; declare consolidation (TODO 18) | none (the model is plain `.lem`) | — | — |

Merge discipline: the feature branch merges ff-only after the sequential
arcs it rebased over; its pre-merge audit is unconditional; its
differential evidence is the litmus lane + zero movement elsewhere.

## 5. What "strong and useful for refined-cerberus" needs settled first (Phase 1 inputs)

1. Which side of the operational/axiomatic pair the LOGIC consumes: Iris
   instantiations (iGPS, Cosmo) are built over operational presentations
   with a view/promise-style state; adequacy against an axiomatic model
   goes through an equivalence (which Cerberus HAS in Isabelle for C11).
2. Whether C11's known defects (out-of-thin-air, the SC-fence issues RC11
   repairs) matter for the target programs (kernel code uses LKMM idioms:
   `smp_load_acquire`, RCU, `READ_ONCE`); if yes, Phase 2 is not optional.
3. The interface shape (§3 Phase 1): the consumer writes what they need;
   we write what the models provide; the intersection is the contract.

## 6. Provenance

[USER 2026-09-04]: the request; [USER 2026-08-19] the parametricity
principle and [USER 2026-08-26] the rescoping, quoted from the archives.
[AGENT]: the measurements (§1), the oracle analysis (§2), the phasing
(§3), the deconfliction table (§4), §5. Docs-only; nothing merged or
pushed; no code touched.
