# Step-runner stack ceiling — re-characterization and design disposition (slice record)

Branch `fix/stack-ceiling` @ base mainline `07a7fca29`. Worker:
stack-ceiling. Charge: locate and characterize the registered
"step-runner stack ceiling" residual, write a design note naming the
mechanism in classic PL terms, then implement the smallest
structure-respecting fix (park if it balloons or leaves scope).
Quoted outputs are verbatim; tallies marked *derived* are computed
from the recorded runs; decisions carry [AGENT] provenance.

**Disposition up front: PARKED after characterization — the
registered premise is stale.** No process-stack overflow reproduces
at this mainline at any probed point (down to a 1 MB stack limit).
The binding ceiling on long executions is now the lem totalization
FUEL BUDGET (`lemDefaultFuel` = 10^6) of the driver's non-memory step
loop, failing loudly and fail-closed. Every correct raise of that
ceiling is a lem-lean change (two-repo pin dance), outside this
slice's authorized workspace. Details and evidence below; §8 has the
park reasoning and proposed follow-ups.

## 1. The registered residual, located

- `docs/2026-08-31_semantics-forward-assessment.md` F6.1 (price M),
  verbatim: "**F6.1 Fix the step-runner stack ceiling (M; pattern b
  or c)** — the real scalability bug: a few thousand loop iterations
  overflow the process stack in the step/ND recursion. The fix is
  making the run loop iterative/tail-recursive (or trampolined) at
  the *executable* face; the definitional fuel semantics is
  untouched." (Companion guard item F4.5, price S.)
- `TODO.md` small items, verbatim: "Step-runner stack-ceiling guard
  (known limitation: loops of a few thousand iterations can overflow
  the process stack in the step/ND recursion;
  `docs/2026-08-19_arc6-s0-survey.md`)."
- History: first observed arc-6 S0 (SIGABRT at ~2k-8k iterations,
  single-trace); re-probed arc-10, register row 20 of
  `docs/2026-08-21_arc10-results.md`, verbatim: "REFRESHED: onset
  16384 < N ≤ 24576 plain loop iterations, uniformly LOUD exit 134
  (S0 re-probe, 5/5) — the arc-6 '~1.4k, quiet-death' text is
  superseded."
- Distinct neighbor, out of scope here: the parity-detective's
  class-(b) OOM (`docs/2026-08-30_parity-detective-report.md` RC-3,
  boxed per-byte memory at CerbMem.lean:1530) is a HEAP
  representation defect, not this item.

## 2. Fresh binaries (and a lem-sync gate catch)

Both drivers were rebuilt before any measurement (2026-08-30; the
worktree's primed binaries dated Aug 22 predate the base commit).
The first oracle build attempt FAILED CLOSED on the dune lem-sync
gate: `CERB_LEM_SYNC_STALE: frontend .lem sources changed since
generation (stamp src e51f8852…, tree 2b3f663d…) — generated/ is
STALE`. Remediated per the gate's own recipe (`make clean-prelude-src
prelude-src` under the project switch), after which
`check_lem_sync: OK`; the Lean side was regenerated via
`make lean-prelude-src` (stamp re-recorded) and rebuilt via
`scripts/capped lake build cerberus-lean` (CERB_MEM_MAX=32G,
incremental, ~30 s). `git status` after full regeneration: clean —
the committed generated trees are byte-identical to what the pinned
lem re-derives. Binaries: `_build/default/backend/driver/main.exe`
19:09, `lean_frontend/.lake/build/bin/cerberus-lean` 19:11
(2026-08-30).

## 3. Reproduction — the failure is fuel, not stack

Probe programs (materialized per N; ephemeral `.tmp/sc/` harness, the
programs inline here):

```c
/* loop */ int main(void){ int s=0; for (int i=0;i<N;i++) s+=1; return (s==N)?42:1; }
/* rec  */ int f(int n) { return n == 0 ? 0 : 1 + f(n - 1); }
           int main(void) { return f(N) == N ? 42 : 1; }
/* vloop = loop with `volatile int s` at file scope */
```

Lean pipeline: `main.exe --cabs-json` → `cerberus-lean --batch
[--first]`; oracle: `main.exe --nolibc --exec --batch
--mode=exhaustive`. Stack limit via `ulimit -s` (default 8192 KB).
Verbatim probe-runner lines (`/usr/bin/time` fields appended):

```
[loop N=4096 lean-ex stack=8192KB] rc=0 :: Defined {value: "Specified(42)", ...} ELAPSED=1.09s MAXRSS=129924KB
[loop N=16384 lean-ex stack=8192KB] rc=0 :: Defined {value: "Specified(42)", ...} ELAPSED=4.04s MAXRSS=296576KB
[loop N=16384 lean-ex stack=1024KB] rc=0 :: Defined {value: "Specified(42)", ...} ELAPSED=4.22s MAXRSS=300140KB
[loop N=16384 lean-first stack=8192KB] rc=0 :: Defined {value: "Specified(42)", ...} ELAPSED=4.37s MAXRSS=299344KB
[vloop 16384 stack=1024KB rc=0] Defined {value: "Specified(42)", ...} ELAPSED=4.07s MAXRSS=296988KB
[loop N=18432 lean-ex stack=8192KB] rc=1 :: lem: fuel exhausted ...
[loop N=20480 lean-ex stack=8192KB] rc=1 :: lem: fuel exhausted ...
[loop N=24576 lean-ex stack=8192KB] rc=1 :: lem: fuel exhausted ...
[loop N=24576 lean-first stack=8192KB] rc=1 :: lem: fuel exhausted ...
[rec N=50000 lean-ex stack=8192KB] rc=0 :: Defined {value: "Specified(42)", ...} ELAPSED=23.54s MAXRSS=584484KB
[rec N=57344 lean-ex stack=8192KB] rc=0 :: Defined {value: "Specified(42)", ...} ELAPSED=29.47s MAXRSS=660348KB
[rec N=57344 lean-ex stack=1024KB] rc=0 :: Defined {value: "Specified(42)", ...} ELAPSED=30.31s MAXRSS=660836KB
[rec N=65536 lean-ex stack=8192KB] rc=1 :: lem: fuel exhausted ...
[rec N=100000 lean-ex stack=8192KB] rc=1 :: lem: fuel exhausted ...
```

Findings:

1. **No stack overflow, anywhere probed.** Every passing point also
   passes at `ulimit -s 1024` (1 MB — an 8× REDUCTION from the
   default under which arc-10 recorded exit 134): stack use is
   iteration-independent. The arc-10 exit-134 onset window
   (16384 < N ≤ 24576) now fails as fuel exhaustion instead, with rc=1.
2. **The failure is clean fuel exhaustion, loud twice over**: stderr
   `lem: fuel exhausted` panic + backtrace; the fuel-0 sentinel
   (`NDkilled (Undef0 …)`, driver.lem:1887) then surfaces as
   `Error {msg: "[empty UB, probably a cerberus BUG]"}` on stdout with
   exit 1. Fail-closed: never a silent wrong answer or a silent [].
3. **Onsets** (derived): plain loop first-fail ∈ (16384, 18432]
   iterations ⇒ ~55-61 fuel/iteration; C recursion first-fail ∈
   (57344, 65536] depth ⇒ ~15-17 fuel/frame. Both modes (exhaustive
   and `--first`) fail identically — the fuel is walked once either way.
4. Memory-action density does not change the picture (volatile probe).

## 4. The mechanism, symbolized (evidence, not guess)

`addr2line` on the panic backtrace (both shapes, loop and rec):

```
0xeaf904  lp_CerberusLean_drive__nonmemory__steps__aux2__lemFuel
0xeafa16  lp_CerberusLean_drive__nonmemory__steps__aux2__lemFuel___lam__4___boxed
0x4d9d107 lean_apply_1
0xbff275  lp_CerberusLean_nd__bind__lemFuel___redArg___lam__1
```

- The exhausting function is **`drive_nonmemory_steps_aux2`** — the
  driver's non-memory small-step loop, `frontend/model/driver.lem:1062-1090`
  (plain unbounded `let rec` in the model: one recursive call per
  advanced Core step / per thread-queue rotation).
- Its Lean totalization (arc-3): `declare {lean} fuel val
  drive_nonmemory_steps_aux2 = …` (driver.lem:1887), which the lem
  backend compiles to a fuel worker plus a wrapper applying
  **`lemDefaultFuel`, hardcoded** (lem-lean `src/lean_backend.ml:2504`
  — there is no per-declaration budget syntax).
- `lemDefaultFuel := 1000000` (lem-lean `lean-lib/LemLib.lean:73`),
  whose provenance note says the constant is "a per-consumer
  empirical margin, not a theorem — exhaustion is LOUD … Consumers
  needing more thread their own fuel via the worker."
- The budget family is COUPLED at 10^6: `nd_bind_lemFuel`
  (generated Nondeterminism.lean:188-192), `CerbND.ndDefaultFuel :=
  lemDefaultFuel` (CerbND.lean:71), and the driver.lem fuel quartet
  (`print_eval_conv_aux`, `drive_nonmemory_steps_aux2`, `driver2`,
  `hack`, driver.lem:1886-1889). CerbND's own header (BUDGET
  RATIONALE): "the trees this runner walks are themselves built by
  10^6-fuel'd binds, so a deeper budget could never be exercised past
  the substrate's own ceiling" — raising any ONE member is vacuous.
- That same header ANTICIPATED today's state, verbatim: "the
  marker's loudness means an eventual stack fix that exposes the fuel
  ceiling shows up as an explicit PANIC, not a silent []." That is
  exactly what §3 measures.

**What moved since arc-10** (honest gap): on 2026-08-21 the same
probe shape died uniformly with exit 134 (stack) at the same order of
onset; today the stack is flat at 1 MB and fuel binds. The mover was
not identified in this slice (candidates: the arc-14 lem-backend
emission slices — the current pin `861ed81` — changing the fuel
workers' code shape to something the Lean 4.32 code generator
compiles tail-recursively; or arcs 12-17 driver/step reorganization).
The near-coincidence of the old and new onsets is unsurprising: both
ceilings are linear in executed steps (bytes/step then, fuel/step
now). Identifying the mover is archaeology (old-binary bisection),
priced S-M, not attempted here.

## 5. The OCaml oracle at the same point (mirror-OCaml doctrine)

- Same recursive structure: the oracle's runner `Smt2.runND` aux
  (`ocaml_frontend/smt2.ml:36-141`) recurses non-tail under
  bind/`foldlM` continuations; `drive_nonmemory_steps_aux2` is
  UNBOUNDED `let rec` on the OCaml target (no fuel — the fuel is
  Lean-target-only totalization). There is no structural divergence
  to repair; the Lean-side budget is the deliberate, documented price
  of the totality discipline.
- Measured oracle ceilings on the same probes (verbatim):

```
[loop N=100000 oracle-ex stack=8192KB] rc=0 :: Defined {value: "Specified(42)", ...} Time spent: 7.499614 seconds
[loop N=1000000 oracle-ex stack=8192KB] rc=0 :: Defined {value: "Specified(42)", ...} Time spent: 78.857399 seconds
[rec N=100000 oracle-ex stack=8192KB] rc=0 :: Defined {value: "Specified(42)", ...} Time spent: 32.499367 seconds
[rec N=500000 oracle-ex stack=8192KB] rc=124 :: (timeout 180s, MAXRSS 2850880KB)
```

  In this range the oracle's practical bound is TIME (and RSS), not
  stack or any budget. Derived comparison at the shared points: Lean
  is ~3-9× the oracle's wall time on these shapes (loop 16384: 4.0s
  Lean; rec 50000: 23.5s Lean vs ~16s-extrapolated oracle) —
  consistent with the parity report's RC-4 constant; perf is
  registered separately and is not this item.

## 6. Fix design space (classic PL terms, priced)

| # | Mechanism | Scope | Price | Verdict |
|---|---|---|---|---|
| a | **Per-declaration fuel budgets** (`declare {lean} fuel … val f`, caller-chosen bound in the classic explicit-fuel/bounded-recursion discipline) + deliberate budgets on the driver quartet and the ND substrate | lem-lean backend + cerberus .lem declares; two-repo pin dance | M | RECOMMENDED follow-up |
| b | **Move `lemDefaultFuel` deliberately** (e.g. 10^6 → 10^8), per the CerbND header's anticipated "budget move" once stack no longer dominates | lem-lean LemLib + pin dance | S code / M process | Acceptable fallback; blunt (global). Derived edge: at measured fuel rates (~2.3×10^5 fuel/s loop-shape, ~3×10^4 fuel/s rec-shape) a 10^8 budget puts the loud edge at ~7-50 min of single-invocation stepping — below the grind horizon; 10^9+ would not be |
| c | Trampoline / defunctionalized-CPS / explicit continuation stack in the runner loops (the F6.1 text's transform) | cerberus-lean | M-L | NOT JUSTIFIED by evidence — there is no stack growth to remove; it would gratuitously diverge from smt2.ml's structure (mirror doctrine) and churn the RelSem/RunND.lean proof surface |
| d | Post-process generated Driver.lean to splice a bigger constant (Makefile sed) | cerberus-lean only | S | REJECTED — a doctored generated artifact; violates certification integrity (the generated tree must be what the pinned lem derives; the lem-sync gate exists to catch exactly this class) |
| e | Guard only (F4.5) | — | 0 | Already de facto satisfied: §3's edge is loud, classified, fail-closed. The ceiling itself still gates kernel-scale runs, so F6.1 stays open — retargeted at fuel |

Cerberus-side-only raises were checked and are impossible without
(d): the wrappers' `lemDefaultFuel` application is emitted by the
backend (lean_backend.ml:2504), the constant lives in LemLib, and the
binding call sites (driver.lem:1278 et al.) are generated code.
`CerbND.ndDefaultFuel` IS cerberus-side but is not the binding member
(§4: aux2 exhausts first, and the substrate ceiling argument).

## 7. Invariants any fix must preserve (unchanged from the charge)

- Exec-cone semantics bit-identical below budget: fuel moves only the
  loud edge (the `runNDFuel_mono` fuel-monotonicity pattern; RelSem
  soundness statements are fuel-quantified and survive any budget).
- No new `partial` on the exec path; totality gates untouched.
- No maxRecDepth/heartbeat (kernel-resource) bumps — defects by
  definition. A deliberate RUNTIME fuel-budget move is a different
  class but requires its own registered rationale (the LemLib
  provenance-note pattern) and the coupled-family analysis of §4.

## 8. Disposition [AGENT]: PARKED (characterization is the slice product)

1. The briefed premise — "the exec driver hitting process-stack
   limits on deep recursion" — does not reproduce at mainline
   `07a7fca29` (§3, measured to 1 MB stack). There is no in-scope
   stack transform to implement; option (c) would be a fix for a
   defect that no longer exists.
2. The ACTUAL ceiling (the fuel family) can only be raised correctly
   in lem-lean (§6 a/b) — a two-repo pin-dance arc, outside this
   slice's authorized workspace (this worktree only). Implementing it
   here would violate the slice boundary; faking it cerberus-side
   (§6 d) would violate the trust surface. Fail-closed: park.
3. No code changed ⇒ the phase-2 validation battery (which certifies
   a fix) has nothing to certify; the worktree's tracked tree is
   byte-clean after full regeneration (§2), and both probe drivers
   were freshly rebuilt before every measurement.

Proposed follow-ups (operator's call):

- Retarget the register: F6.1's text and TODO.md's residual line
  describe a superseded failure mode; the item is now "the 10^6 fuel
  family binds at ~1.7×10^4 loop iterations / ~6×10^4 C-recursion
  depth per non-memory run — loud, fail-closed" (TODO.md pointer
  updated in this slice; the dated assessment doc left untouched as
  a record).
- A lem-arc item for §6(a) per-declaration budgets, with §6(b) as
  fallback, riding the next functional lem arc (the pin is already
  due a re-pin per the container notes).
- Optional S-priced archaeology: identify the stack-ceiling mover
  (old-binary bisection over arcs 10-17) if the record is wanted.

## 9. Provenance

- [AGENT] all probe design, the park decision (grounds in §8), the
  TODO.md pointer refresh, and all pricing estimates. Derived tallies
  labeled; quoted outputs verbatim.
- [USER-chartered] the slice charge (via the orchestrator brief);
  the F6.1/F4.5 registrations quoted in §1 are the operator-reviewed
  forward assessment's.
- Ephemeral probe harness lived in `.tmp/sc/` (container scratch
  rule); the probe programs and every load-bearing verbatim line are
  preserved in this record.
