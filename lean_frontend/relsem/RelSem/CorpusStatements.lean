/-
  RelSem.CorpusStatements — V0 (2026-08-27): THE BATCH-A CORPUS
  STATEMENT SLATE — the FROZEN target corpus's scalar call-boundary
  rows (P01/P02/P03/P09/P10/P11/P12), registered HONEST-UNPROVED in
  the consistency-freshness house shape (relsemcore
  RelSem/Threaded.lean §CONSISTENCY; record
  docs/2026-08-27_v0-statements-and-ban.md).

  Statement texts implement docs/2026-08-27_target-corpus.md §2
  verbatim-in-substance: canonical property (∀ init/args; pre;
  outcome-set; post), the anti-brute-force §0 bounds, the call-
  boundary route (args at the call, prologue stores — the T4/T5
  mechanism). EVERY statement is a V-plan TARGET: zero are provable
  today (corpus §4 — that is the corpus doing its job); the ban gate
  (Audit.lean) checks the quantified-input obligation on each.

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.Threaded
import RelSem.T1File
import RelSem.CorpusFiles

set_option autoImplicit false

namespace RelSem.Corpus

open RelSem RelSem.Cerb
open RelSem.T1 (intRange)

/-- The shared corpus environment hypothesis (the corpus doc §2 house
    shape's EnvHyp; T5EnvHypThr lineage): the TU-digest extern at the
    harness state — the exec paths draw fresh symbols (the R6
    every-assignment finding) and drawn symbols carry the ambient
    digest. -/
def CorpusEnvHyp : Prop := CerberusFresh.digest () = ""

/-- P12's environment hypothesis (T4EnvHypThr lineage): the struct-pt
    layout reads the ambient tag table. -/
def P12EnvHyp : Prop :=
  CerbTags.tagDefs () = p12File.tagDefs ∧
  CerberusFresh.digest () = ""

/-! ## P01 clamp — THE EMBLEM (F1 branch at symbolic data, F13) -/

/-- P01's pure model: clamp0(x) = max x 0. -/
def p01Spec (x : Int) (r : driver_result) : Prop :=
  r.dres_core_value = intValue (max x 0)

/-- **P01 (clamp)** — ∀ x ∈ intRange: outcomes = {Specified (max x 0)}.
    HONESTY LABEL: UNPROVED (first provable after V2 — the first
    symbolic data-dependent branch; the plan's defining checkpoint). -/
def P01Statement : Prop :=
  CorpusEnvHyp →
  ∀ (x : Int), intRange x →
    CallHarnessAdequateCns p01Prior p01File.tagDefs p01File "clamp0"
      [intValue x] corpusFs (p01Spec x)

/-- P01 UB-freedom. HONESTY LABEL: UNPROVED. -/
def P01UBFreeStatement : Prop :=
  CorpusEnvHyp →
  ∀ (x : Int), intRange x →
    CallHarnessUBFreeCns p01Prior p01File.tagDefs p01File "clamp0"
      [intValue x] corpusFs

/-! ## P02 sat_add (F1, F12 overflow side conditions, F13, F15
    sequenced-&&) -/

/-- P02's pure model: 3-case saturating add (corpus §2). -/
def satAdd (a b : Int) : Int :=
  if a + b > 2147483647 then 2147483647
  else if a + b < -2147483648 then -2147483648
  else a + b

/-- P02's spec: sat_add(a,b) = satAdd a b, Specified. -/
def p02Spec (a b : Int) (r : driver_result) : Prop :=
  r.dres_core_value = intValue (satAdd a b)

/-- **P02 (sat_add)** — ∀ a b ∈ intRange: outcomes =
    {Specified (satAdd a b)}, no UB (the guards' overflow-safety is
    proved, not assumed — incl. the sequenced-&& F15 forcing).
    HONESTY LABEL: PROVED (PERF-1 2026-08-28 —
    RelSem.P02.p02_proved, RelSem/P02Proof.lean; cones exactly the
    classical trio, pinned in-build). -/
def P02Statement : Prop :=
  CorpusEnvHyp →
  ∀ (a b : Int), intRange a → intRange b →
    CallHarnessAdequateCns p02Prior p02File.tagDefs p02File "sat_add"
      [intValue a, intValue b] corpusFs (p02Spec a b)

/-- P02 UB-freedom. HONESTY LABEL: PROVED (PERF-1 2026-08-28 —
    RelSem.P02.p02_ubfree_proved; trio cone, pinned in-build). -/
def P02UBFreeStatement : Prop :=
  CorpusEnvHyp →
  ∀ (a b : Int), intRange a → intRange b →
    CallHarnessUBFreeCns p02Prior p02File.tagDefs p02File "sat_add"
      [intValue a, intValue b] corpusFs

/-! ## P03 swap — both alias arms in ONE theorem (F7, F9-relabeled,
    F14). `alias ∈ {0,1}` is STRUCTURAL case vocabulary (corpus §0:
    not a data domain — a, b are full-range; the two-point
    disjunction is the case structure, not a sample set). -/

/-- P03's spec: the harness verdict is 0 (swap correct + frame,
    per-arm expected computed by the harness itself). -/
def p03Spec (r : driver_result) : Prop :=
  r.dres_core_value = intValue 0

/-- **P03 (swap, both alias arms)** — ∀ a b ∈ intRange,
    ∀ alias ∈ {0,1} (structural): outcomes = {Specified 0}.
    HONESTY LABEL: UNPROVED (V2 — assertion layer + alias
    case-split). -/
def P03Statement : Prop :=
  CorpusEnvHyp →
  ∀ (a b alias : Int), intRange a → intRange b →
    (alias = 0 ∨ alias = 1) →
    CallHarnessAdequateCns p03Prior p03File.tagDefs p03File "harness"
      [intValue a, intValue b, intValue alias] corpusFs p03Spec

/-- P03 UB-freedom. HONESTY LABEL: UNPROVED. -/
def P03UBFreeStatement : Prop :=
  CorpusEnvHyp →
  ∀ (a b alias : Int), intRange a → intRange b →
    (alias = 0 ∨ alias = 1) →
    CallHarnessUBFreeCns p03Prior p03File.tagDefs p03File "harness"
      [intValue a, intValue b, intValue alias] corpusFs

/-! ## P09 call_contract (F5 contract consumption, F9 frame, F7) -/

/-- P09's precondition (corpus §0, the H4-closed derived bound):
    0 ≤ a, 0 ≤ b, a + b ≤ INT_MAX − 2. -/
def p09Pre (a b : Int) : Prop :=
  0 ≤ a ∧ 0 ≤ b ∧ a + b ≤ 2147483645

/-- P09's spec: harness(a,b) = (a+1)+(b+1), Specified. -/
def p09Spec (a b : Int) (r : driver_result) : Prop :=
  r.dres_core_value = intValue ((a + 1) + (b + 1))

/-- **P09 (call_contract)** — ∀ a b with the derived pre: outcomes =
    {Specified ((a+1)+(b+1))}; bump's contract consumed at both call
    sites with the sibling cell framed (inlining is not a legitimate
    technique — corpus Q3, operator-settled; P10 is the structural
    backstop). HONESTY LABEL: UNPROVED (V4). -/
def P09Statement : Prop :=
  CorpusEnvHyp →
  ∀ (a b : Int), p09Pre a b →
    CallHarnessAdequateCns p09Prior p09File.tagDefs p09File "harness"
      [intValue a, intValue b] corpusFs (p09Spec a b)

/-- P09 UB-freedom. HONESTY LABEL: UNPROVED. -/
def P09UBFreeStatement : Prop :=
  CorpusEnvHyp →
  ∀ (a b : Int), p09Pre a b →
    CallHarnessUBFreeCns p09Prior p09File.tagDefs p09File "harness"
      [intValue a, intValue b] corpusFs

/-! ## P10 gcd_rec / P11 gcd_iter (recursion by measure / loop
    variant; the shared Euclid model) -/

/-- The shared gcd domain (corpus §0: FULL type range —
    0 < a ≤ INT_MAX, 0 ≤ b ≤ INT_MAX). -/
def gcdPre (a b : Int) : Prop :=
  0 < a ∧ a ≤ 2147483647 ∧ 0 ≤ b ∧ b ≤ 2147483647

/-- The shared pure model: mathematical gcd (on the nonneg domain
    `Int.gcd` is Euclid's function; gcd(a,0) = a). -/
def gcdSpec (a b : Int) (r : driver_result) : Prop :=
  r.dres_core_value = intValue (Int.gcd a b : Int)

/-- **P10 (gcd_rec)** — ∀ a b in the full-range domain: outcomes =
    {Specified (gcd a b)}; the recursive call consumed via its own
    contract at the data-dependent measure (b' = a mod b < b).
    HONESTY LABEL: UNPROVED (V4). -/
def P10Statement : Prop :=
  CorpusEnvHyp →
  ∀ (a b : Int), gcdPre a b →
    CallHarnessAdequateCns p10Prior p10File.tagDefs p10File "gcd_rec"
      [intValue a, intValue b] corpusFs (gcdSpec a b)

/-- P10 UB-freedom. HONESTY LABEL: UNPROVED. -/
def P10UBFreeStatement : Prop :=
  CorpusEnvHyp →
  ∀ (a b : Int), gcdPre a b →
    CallHarnessUBFreeCns p10Prior p10File.tagDefs p10File "gcd_rec"
      [intValue a, intValue b] corpusFs

/-- **P11 (gcd_iter)** — ∀ a b in the full-range domain: outcomes =
    {Specified (gcd a b)}; termination by well-founded VARIANT (b
    strictly decreases — no closed-form trip count), %-UB from the
    guard. HONESTY LABEL: UNPROVED (V3a). -/
def P11Statement : Prop :=
  CorpusEnvHyp →
  ∀ (a b : Int), gcdPre a b →
    CallHarnessAdequateCns p11Prior p11File.tagDefs p11File "gcd"
      [intValue a, intValue b] corpusFs (gcdSpec a b)

/-- P11 UB-freedom. HONESTY LABEL: UNPROVED. -/
def P11UBFreeStatement : Prop :=
  CorpusEnvHyp →
  ∀ (a b : Int), gcdPre a b →
    CallHarnessUBFreeCns p11Prior p11File.tagDefs p11File "gcd"
      [intValue a, intValue b] corpusFs

/-! ## P12 pt_midpoint (F10 struct fields, F9 frame-as-observable,
    F7, F12) -/

/-- P12's per-coordinate bound (corpus §0, derived: the a->x + b->x
    hazard — |coord| ≤ INT_MAX/2). -/
def p12Range (v : Int) : Prop := -1073741823 ≤ v ∧ v ≤ 1073741823

/-- P12's spec: verdict 0 (midpoint correct AND the input structs
    unchanged — the frame is IN the postcondition, observably: 9 on
    a frame break, 1 on a wrong midpoint). -/
def p12Spec (r : driver_result) : Prop :=
  r.dres_core_value = intValue 0

/-- **P12 (pt_midpoint)** — ∀ ax ay bx by in the derived range:
    outcomes = {Specified 0}. HONESTY LABEL: UNPROVED (V3b). -/
def P12Statement : Prop :=
  P12EnvHyp →
  ∀ (ax ay bx by_ : Int),
    p12Range ax → p12Range ay → p12Range bx → p12Range by_ →
    CallHarnessAdequateCns p12Prior p12File.tagDefs p12File "harness"
      [intValue ax, intValue ay, intValue bx, intValue by_] corpusFs
      p12Spec

/-- P12 UB-freedom. HONESTY LABEL: UNPROVED. -/
def P12UBFreeStatement : Prop :=
  P12EnvHyp →
  ∀ (ax ay bx by_ : Int),
    p12Range ax → p12Range ay → p12Range bx → p12Range by_ →
    CallHarnessUBFreeCns p12Prior p12File.tagDefs p12File "harness"
      [intValue ax, intValue ay, intValue bx, intValue by_] corpusFs

end RelSem.Corpus
