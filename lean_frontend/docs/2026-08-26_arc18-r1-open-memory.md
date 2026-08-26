# Arc-18 R1 — the open-memory minting mode (record)

Slice R1 of the segment-ladder charter
(`docs/2026-08-26_arc18-segment-ladder-charter.md` — the arc's
designated DERISK slice, unknown #1; priced M). Worker: [AGENT],
worktree `cerberus-lean-coherence`, branch `arc/segment-ladder`, base
`b8baec82f`. Gated at the landing commit: relsem + speclab capped
builds with all in-build gates, `test_unit.sh` 7/7 + gate scripts,
`test_verify.sh` 35/35, `test_speclab_divmod.sh --gate` +
`test_speclab_seed.sh --gate` PASS; driver paths untouched
(relsem/scripts/docs only). Quoted outputs verbatim.

## 1. What the mode is

The round evaluator can now MINT CHAIN EQUATIONS AT OPEN MEMORY: a
`derive_rounds` drive whose from-state carries the two heap maps as
FREE BINDERS (the `setMaps` decomposition the CerbMemInterp walk
rules quantify), with map reads discharged through the REGISTERED
memRW lane laws (read-over-write/frame/projection, Kit/Mem) against
footprint HYPOTHESES from an `assuming` pack — never by ground
evaluation of a closed map. Genuinely missing facts surface as
tagged frontiers (fail-closed, loud); there is no silent
ground-fall-back (the pre-R1 failure shape was the opposite and is
closed by §3's first mechanism).

**The lane configuration is compositional, not a fork**: the mode is
exactly `derive_rounds … assuming <footprint pack> fencing
CerbMem.writeBytesTo Std.TreeMap.insert Std.TreeMap.get?
Std.TreeMap.erase … chain builder` over a T5W-`mkRdy`-shaped builder
(LITERAL scalar fields — no hidden fenced ladders under the anchor;
the maps the only open memory slots). Everything it runs on is the
existing builder machinery (arc-17 S3 / C3b): the attribute fence,
substitute-first hypothesis rewriting, the memRW minter lane, the
piecewise terminal chain assembler.

## 2. The acceptance instance: T6 re-derived on the open-memory route

`RelSem/T6Probe.lean`:

* **The open drive**: `derive_rounds ro (bm am tr aid exc symc ctr)
  (halX hrdX) assuming … builder` from `mkRdy6` — the ENTIRE T6 run
  (51 rounds + terminal: create/store of the local t, the unseq load
  pair through the pack, the branch, kill, the Erun return jump)
  minted with the maps free. Pack = TWO footprint facts, exactly the
  walk rule's premises: `halX : am.get? 0 = some allocX` and
  `hrdX : readBytesFrom (memRdy bm am) xAddr 4 = argBytes6`.
  Verbatim: `derive_rounds RelSem.T6.ro: relative chain
  RelSem.T6.ro_chainrel emitted (51 rounds, terminal=true)`.
* **The theorem layer**: `driver2_o` — the whole `driver2` atom at
  open maps — is `ro_chainrel` (instantiated at the canonical
  supplies, fuel 999947) + `ndct_offer1` + `driver2_done` + one
  alignment rfl each way (`mkRdy6 = setMaps (rRdy seed) bm am`; the
  final state = `setMaps (rDone6 seed) (allocStoreBytes …)
  ((am.insert 2 allocT).erase 2)`, with `rDone6` PROJECTED from the
  minted final state `ro51` at zeroed maps — the `lh1Arena`
  never-transcribe discipline). This replaces what T1/T3 needed
  hand-derived open round lemmas for: ZERO hand rounds in T6's
  driver characterization.
* **The walk**: `t6_wpK_thr` re-derived on the heap route — the
  T1Threaded pattern verbatim (rest ladder, open k-stage equations
  k1_o–k9_o with `inject_ptr_arg1`/`callND_errno` + Kit blocks,
  `wp_argobj`/`wp_rest`/`wp_scratch1`/`wp_fin` macros). The driver
  atom is `wp_scratch1`: it reads the argument object's footprint,
  runs t's whole lifetime internally (dead bytes out as `HptT`), and
  the errno fragments ride the frame across it — the framing
  dividend now demonstrated on an evaluator-minted chain.
* **Statements byte-stable**: `T6ThreadedStatement` and both theorem
  statements are verbatim; only proof bodies moved
  (`kCallHarnessAdequateThrHeap_of_wp (GF := CerbHeapS)` replacing
  the OwnP bridge). Cone pins passed verbatim — T6Threaded /
  T6Threaded_ubFree / t6_wpK_thr remain EXACTLY
  {propext, Classical.choice, Quot.sound}.
* The GROUND drive (`derive_rounds r`) is retained as the
  evaluator's ground-lane acceptance instance; it re-elaborated
  byte-identically under the engine changes (as did the five T5
  walks and the T4 drives — all cone pins verbatim).

## 3. What the walls were (each fell law-shaped; engine +47 lines)

1. **Silent symbolic ride-through at drifted records** (the one real
   mode gap, and R1's justification): mid-run reads surface at
   `MemState.mk` records whose SCALAR fields have drifted
   (post-create supplies) while the bytemap is the same open binder —
   the pack fact, stated at the canonical ready state, could not
   match, and the x-load rode through with a SYMBOLIC value that
   exploded two rounds later. Fix: PACK-CANONICAL RESPELLING in the
   memRW lane (`mintMemRW`) — bridge through the registered
   `readBytesFrom_congr_bytemap` law (kind `memRW`, variant `congr`)
   to the pack fact's own state; base facts only. A registry-law
   consumer; no semantic knowledge in engine code (+34 lines,
   Lanes).
2. **Seven missing pass-through projection laws**: the Erun return
   jump rebuilds the memory record FIELD-BY-FIELD over the folded
   write ladder; only 6 of 13 non-bytemap `MemState` fields had
   registered `writeBytesTo` projection laws. Added
   nextIota/iotaMap/varargs/nextVarargsId/dynamicAddrs/lastUsed/
   requested (Kit/Mem, all rfl; census 69 → 76, memRW 13 → 20) —
   the charter's good case: insufficient in COUNT, not in kind.
3. **Proj-node blindness in the normalizer**: whnf leaves raw
   `.proj` nodes over fenced-head applications (the file tables'
   Fmap/TreeMap internals under the TreeMap fence — the T6 fence
   set, unlike T5's, must fence `TreeMap.insert/get?` for the
   allocation ladders while the FILE tables use the same constants);
   `groundNorm`'s args-first walk never entered a proj node, so the
   fenced-head ground escape could not fire. Fix: PROJ-NODE
   RECURSION in `groundNorm` (+13 lines, Core; pure elaborator
   handling).
4. **Builder-anchor hygiene** (no engine change): a first probe
   anchored on `setMaps (restOf (dRdy seed)) bm am`, whose scalar
   fields hide the FENCED memD3 ladder — the create's address
   arithmetic dug into WF internals to a maxRecDepth wall. The T5W
   `mkRdy` discipline (literal scalar fields) is confirmed as the
   mode's builder contract and is documented at the drive site.

## 4. Gate re-registrations (all in the landing commit)

* `scripts/check_one_route.sh`: the labeled T6 exemption line
  DELETED; `T6Probe.lean` added to LIVE_MODULES (35 modules);
  headers updated. PLANT-TESTED both directions (transcripts
  verbatim, clean-tree OK restored after each):
  plant 1 (reintroduced `import RelSem.PerStepOwnP` in T6Probe) —
  `check_one_route: FAIL — live-route module imports an OwnP/arc-7
  surface: relsem/RelSem/T6Probe.lean`; plant 2 (a `[CerbGS …]`
  binder in T6Probe) — token FAIL + coexistence FAIL +
  non-allowlisted OwnP-binder FAIL.
* `RelSem/Audit.lean`: step_law census pin 69 → 76 (provenance
  comment); sweep pin 6784 → 6959 (the ro drive's emissions + the
  T6 spine + the 7 laws; provenance comment). All other pins
  byte-stable, incl. the 112-name no-cone carrier.
* `scripts/engine_size_baseline.txt`: re-derived 5207 → 5727 with
  the FF-3 stale delta (+473, C3b/C4) separated from R1's growth
  (+47) per the in-file discipline; `check_engine_size` now clean
  (the 9 standing WARN lines retired into the annotated baseline).
* Contracts doc §3a/§6-R2: the exemption marked CLEARED (factual
  annotation of the executed mover, not a contract change).

## 5. Validation (verbatim; exit-checked, strictly serial)

```
Build completed successfully (402 jobs).          [relsem]
Build completed successfully (147 jobs).          [speclab]
Total: 7 passed, 0 failed                          [test_unit]
check_one_route: OK — one state interpretation on the live route (35 modules OwnP-free; coexistence hazard clear; OwnP binders confined to the retirement register)
test_verify: 35 passed, 0 failed (6 fixtures, 22 harness points)
test_speclab_divmod: PASS (--gate)
test_speclab_seed: PASS (--gate)
info: RelSem/T6Probe.lean:318:0: derive_rounds RelSem.T6.ro: relative chain RelSem.T6.ro_chainrel emitted (51 rounds, terminal=true)
```

(The census line: `step_law census: 76 laws [advance 5, construct 9,
envAlg 3, envMap 4, evalArith 2, evalPull 2, heapWP 4, heapWalk 8,
loop 2, memBlock 6, memRW 20, perform 6, roundGlue 3, wpSeq 2]` —
pinned in Audit.)

## 6. What the segment layer may now assume (the R1 contract)

Given a segment start term whose memory subterm is the `setMaps`
decomposition (or a builder aligning to it by rfl) and a hypothesis
pack containing the segment's footprint facts (allocation-table
`get?` facts + `readBytesFrom` range facts at the canonical state),
`derive_rounds … assuming … chain builder` mints the ∀-fuel relative
chain equation for the segment — reads through the registered memRW
laws + the pack, creates/kills through the ground scalar fields,
terminal segments in the `ndct_offer1`/`driver2_done`-composable
form. Missing facts are tagged frontiers naming the stuck term. R2's
judgment layer consumes exactly this.

Prices/parks: none open — R1 landed within price (M); no stop-event
fired. Probe logs at container `.r1-logs/` (scratch, not committed).
