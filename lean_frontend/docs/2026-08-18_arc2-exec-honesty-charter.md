# Arc 2: exec-honesty — charter (2026-08-18)

Status: blessed by user 2026-08-18 ("keep rolling on the branch and not
merge a broken state"). Continues on the UNMERGED `arc/effects-totality`
branch pair (both repos) — arcs 1+2 merge together, once, when the state
is non-broken. Plan of record: design note §13 (this directory,
`2026-08-18_effects-totality-design.md`); this charter adds slice
structure, gates, and the merge criterion.

## End state

The execution slice is honest end-to-end: no unsafe extern reachable
from the fuel-opsem TCB (fresh threaded through core_run_state per the
model's own supply idiom), theorems that certify (DAEMON no longer
False-implying on the theorem path), the known live divergence closed
(mini_pipeline), and the census failure-class mechanized out of
existence. Then ONE merge of the whole branch pair.

## Slices

1. **S0 — purity gate, reporting mode**: `scripts/check_exec_purity.sh` —
   whitespace-robust assertions over generated exec-slice modules
   (no runEffectful / bare `fresh ()` / unsafeBaseIO / CerbTags reads),
   with an explicit ALLOWLIST section (each entry justified). Wired into
   the unit-test gate. Reports the 3 known fresh sites; flips to
   ENFORCING in S2.
2. **S1 — the .lem patch** (§13, R2-micro): `sym_supply` as the fourth
   supply; `fresh_symbol'`/`E.fresh_symbol` mirroring `fresh_action_id'`;
   three call sites to the bind idiom; seeding via a target_rep'd
   `initial_sym_supply` val (OCaml: one `Cerb_fresh.int` read; Lean: the
   hand-written scaffold-counter seam) so `drive`'s public signature is
   unchanged. OCaml-first validation (full build + suites). One commit,
   git-revertible.
3. **S2 — Lean regen**: purity gate ENFORCING (seed val allowlisted);
   proof test gains fresh_symbol' distinctness/sequence lemmas (now
   provable). Gate green everywhere.
4. **S3 — seed wiring + invariant**: both targets seeded; uniqueness
   invariant (exec numbers ∉ translation numbers) documented + a
   monotonicity lemma over the threaded supply.
5. **S4 — id-canonicalizer**: first-occurrence renumbering utility
   (symbol + thread ids) with unit test; wired into trace/golden diffs
   when Phase 2 produces them (the id-insensitive differential ruling).
6. **S5 — DAEMON repair**: design + implement so the exemplar theorems'
   axiom environment is consistent (real Inhabited derivation where
   feasible; bounded axiom otherwise; measured by `#print axioms` on the
   proof test — added to the gate). USER CHECKPOINT on the design if the
   options trade off generated-code ergonomics.
7. **S6 — mini_pipeline restructure** (port-local, unprotected by obj 3):
   eliminate the `with_tagDefs` extent / split-read divergence; the
   §10 repro class (`int a[sizeof(struct S)]`) becomes a test.
8. **S7 — close**: full gates both repos; focused 1-agent audit of the
   cumulative .lem diff + DAEMON change (semantic preservation); THE
   merge ask (explicit, for the specific merge, arcs 1+2 together).

## Merge criterion (the "non-broken" bar, user-set)

Purity gate enforcing and green; proof-test theorems DAEMON-clean per
`#print axioms`; mini_pipeline divergence closed or explicitly re-ruled;
all suites at baseline; audit findings dispositioned. No merge before.

## Inherited discipline

Arc-1 charter's gates and rules bind unchanged (validation gate, pin
dance, fail-closed maximalism, decisions-in-files, toolchain pinned at
4.29.0, audit-ask unconditional). Deferral with an honest record remains
success.
