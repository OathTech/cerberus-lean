/-
  RelSem.CorpusBStatements — V0 (2026-08-27): THE BATCH-B CORPUS
  STATEMENT SLATE — the FROZEN target corpus's memory-input rows
  (P04/P05/P06/P14/P15), registered HONEST-UNPROVED in the
  consistency-freshness house shape (record
  docs/2026-08-27_v0-statements-and-ban.md).

  Statement texts implement docs/2026-08-27_target-corpus.md §2's
  memory-input template at the file level (the arc-15 mkHarness
  shape): `∀ m, wf m → HarnessRunsToCns prior (fileOf m) 0` — the
  harness family is quantified through the parametric splice
  (RelSem/CorpusBFiles.lean), expected[] computed by the pure model,
  verdict 0 = agreement (mismatch-index / flag verdicts otherwise —
  the readback is IN the program).

  ENCODING FINDING (recorded for the operator, per the frozen-corpus
  stop-and-report rule): P06's wf carries `1 ≤ |xs|` — the corpus §2
  text states only `|xs| ≤ 2^20`, but the empty family instance has
  an empty `expected[]` array, which neither C (pre-C23) nor the
  splice can express (the mkHarness nonempty-array note); the same
  bound is EXPLICIT in the corpus's own P04 row. Flagged in the V0
  record §findings; everything else is the frozen text verbatim.

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.Threaded
import RelSem.T1File
import RelSem.CorpusStatements
import RelSem.CorpusBFiles

set_option autoImplicit false

namespace RelSem.Corpus

open RelSem RelSem.Cerb
open RelSem.T1 (intRange)

/-! ## P04 arr_sum (F2a quantified-n invariant, F8 symbolic index,
    F7, F12 overflow pre, F14) -/

/-- P04's wf (corpus §0/§2): 1 ≤ |xs| ≤ 2^20, elements int-range,
    every prefix sum in int range (the SEMANTIC no-overflow pre the
    invariant carries). -/
def p04Wf (xs : List Int) : Prop :=
  1 ≤ xs.length ∧ xs.length ≤ 1048576 ∧
  (∀ v ∈ xs, intRange v) ∧
  (∀ i ≤ xs.length, intRange ((xs.take i).foldl (· + ·) 0))

/-- **P04 (arr_sum)** — ∀ xs, wf xs → outcomes = {Specified 0} (the
    harness compares against the spliced Σ xs). HONESTY LABEL:
    UNPROVED (V3b). -/
def P04Statement : Prop :=
  CorpusEnvHyp →
  ∀ (xs : List Int), p04Wf xs →
    HarnessRunsToCns p04Prior (p04FileOf xs) 0

/-! ## P05 find_first (F2b contents-dependent trip count, F4 early
    exit, F8, F1, F13) -/

/-- P05's wf: |xs| ≤ 2^20, elements + target int-range. -/
def p05Wf (xs : List Int) (x : Int) : Prop :=
  xs.length ≤ 1048576 ∧ (∀ v ∈ xs, intRange v) ∧ intRange x

/-- **P05 (find_first)** — ∀ xs x, wf → outcomes = {Specified 0}
    (expected_idx = the LEAST hit index else |xs|, spliced from the
    pure model). HONESTY LABEL: UNPROVED (V3b — the sharpest loop
    rung: minimization invariant). -/
def P05Statement : Prop :=
  CorpusEnvHyp →
  ∀ (xs : List Int) (x : Int), p05Wf xs x →
    HarnessRunsToCns p05Prior (p05FileOf xs x) 0

/-! ## P06 arr_reverse (F2a partially-transformed-array invariant,
    F8 symbolic writes, F7, F14) -/

/-- P06's wf (the `1 ≤ |xs|` encoding bound is the header-note
    finding). -/
def p06Wf (xs : List Int) : Prop :=
  1 ≤ xs.length ∧ xs.length ≤ 1048576 ∧ (∀ v ∈ xs, intRange v)

/-- **P06 (arr_reverse)** — ∀ xs, wf xs → outcomes = {Specified 0}
    (expected[] = reverse xs; mismatch-index readback). HONESTY
    LABEL: UNPROVED (V3b). -/
def P06Statement : Prop :=
  CorpusEnvHyp →
  ∀ (xs : List Int), p06Wf xs →
    HarnessRunsToCns p06Prior (p06FileOf xs) 0

/-! ## P14 count_pairs (F3 nested invariants, F8 two symbolic
    indices, F2a quadratic count, F12) -/

/-- P14's wf (corpus §0: n ≤ 65536 — the largest bound making the
    count fit int, derived; elements int-range). -/
def p14Wf (xs : List Int) : Prop :=
  xs.length ≤ 65536 ∧ (∀ v ∈ xs, intRange v)

/-- **P14 (count_pairs)** — ∀ xs, wf xs → outcomes = {Specified 0}
    (expected_cnt = #{(i,j) | i<j, xs[i]=xs[j]}, spliced from the
    pure model). HONESTY LABEL: UNPROVED (V3b). -/
def P14Statement : Prop :=
  CorpusEnvHyp →
  ∀ (xs : List Int), p14Wf xs →
    HarnessRunsToCns p14Prior (p14FileOf xs) 0

/-! ## P15 scan_classify (NUL discipline from an ∃-witness, uchar
    widening, the switch shape — corpus review §6's one-row triple) -/

/-- P15's wf (corpus §2): bytes in uchar range, a NUL PRESENT within
    bounds (the ∃-NUL deref-safety witness — position < 2^20 since
    |s| ≤ 2^20), nonempty by containing it. -/
def p15Wf (s : List Int) : Prop :=
  s.length ≤ 1048576 ∧ (∀ v ∈ s, 0 ≤ v ∧ v ≤ 255) ∧ (0 : Int) ∈ s

/-- **P15 (scan_classify)** — ∀ s, wf s → outcomes = {Specified 0}
    (expected_cnt = digit-class bytes strictly before the first NUL,
    spliced from the pure model). HONESTY LABEL: UNPROVED (V3b). -/
def P15Statement : Prop :=
  CorpusEnvHyp →
  ∀ (s : List Int), p15Wf s →
    HarnessRunsToCns p15Prior (p15FileOf s) 0

/-! ## P07 list_sum / P08 list_reverse (F11 rep predicates FORCED by
    the H2 quantified link-order permutation, F10, F7, F2a — the
    summit rows) -/

/-- P07's wf (corpus §0/§2 + H2): |l| ≤ 2^20 heads, int-range, every
    prefix sum in range (traversal order = head order — the prologue
    links π-permuted SLOTS, list order stays index order), and π a
    PERMUTATION of 0..n−1 (the quantified skeleton — ~n! shapes). -/
def p07Wf (heads : List Int) (pi_ : List Nat) : Prop :=
  heads.length ≤ 1048576 ∧
  (∀ v ∈ heads, intRange v) ∧
  (∀ i ≤ heads.length, intRange ((heads.take i).foldl (· + ·) 0)) ∧
  List.Perm pi_ (List.range heads.length)

/-- **P07 (list_sum)** — ∀ l π, wf → outcomes = {Specified 0}
    (expected_sum = Σ l; the heap SKELETON is quantified through π).
    HONESTY LABEL: UNPROVED (V5 — the summit; rep predicate
    `IntList p l` forced). -/
def P07Statement : Prop :=
  CorpusEnvHyp →
  ∀ (heads : List Int) (pi_ : List Nat), p07Wf heads pi_ →
    HarnessRunsToCns p07Prior (p07FileOf heads pi_) 0

/-- P08's wf (as P07 minus the sum pre; `1 ≤ |l|` is the same
    encoding bound as P06's — expected[] must be nonempty). -/
def p08Wf (heads : List Int) (pi_ : List Nat) : Prop :=
  1 ≤ heads.length ∧ heads.length ≤ 1048576 ∧
  (∀ v ∈ heads, intRange v) ∧
  List.Perm pi_ (List.range heads.length)

/-- **P08 (list_reverse)** — ∀ l π, wf → outcomes = {Specified 0}
    (the readback walks the reversed heap list against expected[] =
    reverse l). HONESTY LABEL: UNPROVED (V5 — the Reynolds/O'Hearn
    classic at a quantified skeleton). -/
def P08Statement : Prop :=
  CorpusEnvHyp →
  ∀ (heads : List Int) (pi_ : List Nat), p08Wf heads pi_ →
    HarnessRunsToCns p08Prior (p08FileOf heads pi_) 0

end RelSem.Corpus
