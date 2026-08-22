/-
  CerbStepInstances.lean — hand-written instances for
  Core_reduction.core_step2 (arc 4 / S1a, 2026-08-19).

  Why: core_step2 carries core_runM continuations (state-monad functions)
  and closure-carrying thread_states, so the Lem Lean backend emitted
  sorry-fallback BEq/Ord/SetType/Eq0/Ord0 instances. The sorry BEq fired at
  runtime from driver2's blocked-thread filter
  (`step_opt <> Just Step_blocked2`, driver.lem:1410, rendered as
  `maybeEqualBy (fun x y => x == y) step_opt (some Step_blocked2)`) — the
  first crash for 77/105 tests/minimal files (S0 frontier,
  docs/2026-08-19_arc4-s0-frontier.md). A SECOND equality site exists at
  driver.lem:1376 (`List.any (fun step -> step <> Step_blocked2)` in
  _non_blocked_th_sts): also inside Driver.lean's import closure, so it
  gets these instances too; like :1410 it only ever compares against the
  nullary Step_blocked2.

  Semantics: OCAML POLYMORPHIC-EQUALITY PARITY. OCaml's (=)/compare walk
  the representation, comparing constructor tags first, and raise
  Invalid_argument "compare: functional value" when they reach a closure.
  We mirror:
    - different constructors                       -> false
    - same nullary constructor                     -> true
    - same ctor, all payloads structurally
      comparable (no functions/closures anywhere)  -> structural equality
    - same ctor, any payload that is (or contains)
      a function/closure                           -> failwithI (honest-loud,
                                                     opaque; mirrors the raise)
  NOTE: thread_state counts as closure-carrying: besides arena/stack, its
  `env : list (map sym value)` is an OCaml Pmap, which stores its ordering
  closure, so OCaml (=) raises on it. core_runM values are functions.

  Constructor classification (12 constructors):
  | constructor          | payloads                                              | class      |
  |-----------------------|------------------------------------------------------|------------|
  | Step_ccall2           | thread_id (Nat), core_runM thread_state (FUNCTION)   | panic      |
  | Step_with_runstate2   | runstate_step_kind, core_runM thread_state (FUNCTION)| panic      |
  | Step_tau2             | String, core_tau_step_kind, thread_state (CLOSURES)  | panic      |
  | Step_action_request2  | String, Loc, thread_id, Bool,                        |            |
  |                       |   core_runM (action_request2 thread_state) (FUNCTION)| panic      |
  | Step_blocked2         | (nullary)                                            | true       |
  | Step_error2           | String                                               | structural |
  | Step_thread_done2     | thread_id (Nat), value                               | structural |
  | Step_done2            | value                                                | structural |
  | Step_memop_request2   | Loc, memop, List value, thread_id, Bool,             |            |
  |                       |   (value -> thread_state) (FUNCTION)                 | panic      |
  | Step_spawn_threads2   | (List thread_id -> thread_state) (FUNCTION),         |            |
  |                       |   List thread_state (CLOSURES)                       | panic      |
  | Step_fs2              | thread_id, thread_state (CLOSURES),                  |            |
  |                       |   core_runM fs_oper_or_done (FUNCTION)               | panic      |
  | Step_nd2              | List thread_state (CLOSURES)                         | panic      |

  Core.value is pure data all the way down in the concrete memory model
  (IntegerValue/PointerValue/MemValue are closure-free, mirroring OCaml
  impl_mem.ml), so the Step_thread_done2/Step_done2 arms are genuinely
  structural. The generated `deriving BEq` for `value` can NOT be used for
  them: it routes Vobject/Vloaded through the generated sorry
  `BEq object_value` (a mutual block the backend can't derive), so we
  recurse by hand via CerbMem's real BEq instances.

  The live call site only ever tests against nullary Step_blocked2, so the
  panic arms are dead in practice — they exist for parity honesty. Do NOT
  soften them to false/true.

  Mechanism note: `declare {lean} skip_instances type core_step2` can NOT be
  used (probed, arc-4 S1a): it also suppresses the real Inhabited instance,
  which Core_reduction.lean itself needs (failwithI sites) and which this
  file cannot provide (import cycle). Instead the generated sorry instances
  remain at (priority := low) and the default-priority instances below
  override them wherever this file is imported — currently Driver.lean (via
  `declare {lean} extra_import` in driver.lem), the ONLY module that uses
  equality on core_step2. Any NEW use site in another generated module must
  also extra_import this file, or it will silently get the sorry fallback.
-/
import Core_reduction
import CerbCtypeInstances

/- Structural equality for Core values, bypassing the generated
   (transitively sorry) `deriving BEq` on `value`. Leaf comparisons use
   real instances: CerbMem.IntegerValue/PointerValue/MemValue (hand-written
   in CerbMem.lean), Float (IEEE ==, matching OCaml (=) incl. nan, -0.0),
   sym/identifier/core_base_type (derived), ctype (CerbCtypeInstances).

   LEAF-PARITY: the CerbMem leaf instances (BEq PointerValueBase,
   beqMemValueImpl) were made OCaml-polymorphic-`(=)` PARITY in arc-14 S1
   F4 (sem:S1) — they now compare all payloads. The former coarseness
   caveat and its reachability argument have been RELOCATED to CerbMem.lean
   (see "THE MEMORY-MODEL INSTANCE CAVEAT" there). Both driver.lem sites
   (:1376, :1410) still only test against the nullary Step_blocked2, so
   these leaves never decide a live comparison regardless. -/
mutual

private def beqObjectValue : object_value → object_value → Bool
  | .OVinteger i1, .OVinteger i2 => i1 == i2
  | .OVfloating f1, .OVfloating f2 => f1 == f2
  | .OVpointer p1, .OVpointer p2 => p1 == p2
  | .OVarray lvs1, .OVarray lvs2 => beqLoadedValueList lvs1 lvs2
  | .OVstruct s1 ms1, .OVstruct s2 ms2 => s1 == s2 && ms1 == ms2
  | .OVunion s1 m1 v1, .OVunion s2 m2 v2 => s1 == s2 && m1 == m2 && v1 == v2
  | _, _ => false

private def beqLoadedValue : loaded_value → loaded_value → Bool
  | .LVspecified ov1, .LVspecified ov2 => beqObjectValue ov1 ov2
  | .LVunspecified ty1, .LVunspecified ty2 => ty1 == ty2
  | _, _ => false

private def beqLoadedValueList : List loaded_value → List loaded_value → Bool
  | [], [] => true
  | lv1 :: rest1, lv2 :: rest2 =>
      beqLoadedValue lv1 lv2 && beqLoadedValueList rest1 rest2
  | _, _ => false

end

mutual

private def beqCoreValue : value → value → Bool
  | .Vobject ov1, .Vobject ov2 => beqObjectValue ov1 ov2
  | .Vloaded lv1, .Vloaded lv2 => beqLoadedValue lv1 lv2
  | .Vunit, .Vunit => true
  | .Vtrue, .Vtrue => true
  | .Vfalse, .Vfalse => true
  | .Vctype ty1, .Vctype ty2 => ty1 == ty2
  | .Vlist bty1 vs1, .Vlist bty2 vs2 => bty1 == bty2 && beqCoreValueList vs1 vs2
  | .Vtuple vs1, .Vtuple vs2 => beqCoreValueList vs1 vs2
  | _, _ => false

private def beqCoreValueList : List value → List value → Bool
  | [], [] => true
  | v1 :: rest1, v2 :: rest2 => beqCoreValue v1 v2 && beqCoreValueList rest1 rest2
  | _, _ => false

end

private def beqCoreStep2 : core_step2 → core_step2 → Bool
  | .Step_blocked2, .Step_blocked2 => true
  | .Step_error2 str1, .Step_error2 str2 => str1 == str2
  | .Step_thread_done2 tid1 v1, .Step_thread_done2 tid2 v2 =>
      tid1 == tid2 && beqCoreValue v1 v2
  | .Step_done2 v1, .Step_done2 v2 => beqCoreValue v1 v2
  -- Panic arms: OCaml (=) raises Invalid_argument on the closures these carry.
  | .Step_ccall2 _ _, .Step_ccall2 _ _ =>
      (failwithI "BEq core_step2: functional value (Step_ccall2)" : Bool)
  | .Step_with_runstate2 _ _, .Step_with_runstate2 _ _ =>
      (failwithI "BEq core_step2: functional value (Step_with_runstate2)" : Bool)
  | .Step_tau2 _ _ _, .Step_tau2 _ _ _ =>
      (failwithI "BEq core_step2: functional value (Step_tau2)" : Bool)
  | .Step_action_request2 _ _ _ _ _, .Step_action_request2 _ _ _ _ _ =>
      (failwithI "BEq core_step2: functional value (Step_action_request2)" : Bool)
  | .Step_memop_request2 _ _ _ _ _ _, .Step_memop_request2 _ _ _ _ _ _ =>
      (failwithI "BEq core_step2: functional value (Step_memop_request2)" : Bool)
  | .Step_spawn_threads2 _ _, .Step_spawn_threads2 _ _ =>
      (failwithI "BEq core_step2: functional value (Step_spawn_threads2)" : Bool)
  | .Step_fs2 _ _ _, .Step_fs2 _ _ _ =>
      (failwithI "BEq core_step2: functional value (Step_fs2)" : Bool)
  | .Step_nd2 _, .Step_nd2 _ =>
      (failwithI "BEq core_step2: functional value (Step_nd2)" : Bool)
  | _, _ => false

/- OCaml polymorphic `compare` parity. OCaml orders the sole immediate
   (nullary) constructor Step_blocked2 below every block constructor; block
   constructors are ordered by tag = declaration order among the non-nullary
   constructors; equal tags compare fields (raising on closures). Only the
   Step_error2 / Step_thread_done2 / Step_done2 same-tag field comparisons
   would be closure-free in OCaml; a hand-written polymorphic-compare for
   Core values has no call site today, so those arms panic honestly instead
   (recorded deviation — unreachable from any current use). -/
private def blockTag : core_step2 → Nat
  | .Step_ccall2 _ _ => 0
  | .Step_with_runstate2 _ _ => 1
  | .Step_tau2 _ _ _ => 2
  | .Step_action_request2 _ _ _ _ _ => 3
  | .Step_error2 _ => 4
  | .Step_thread_done2 _ _ => 5
  | .Step_done2 _ => 6
  | .Step_memop_request2 _ _ _ _ _ _ => 7
  | .Step_spawn_threads2 _ _ => 8
  | .Step_fs2 _ _ _ => 9
  | .Step_nd2 _ => 10
  | .Step_blocked2 => 11  -- unreachable via compareCoreStep2 (handled first)

private def compareCoreStep2 (x y : core_step2) : Ordering :=
  match x, y with
  | .Step_blocked2, .Step_blocked2 => .eq
  | .Step_blocked2, _ => .lt  -- OCaml: immediate < block
  | _, .Step_blocked2 => .gt
  | .Step_error2 str1, .Step_error2 str2 => compare str1 str2
  | _, _ =>
    match compare (blockTag x) (blockTag y) with
    | .lt => .lt
    | .gt => .gt
    | .eq => (failwithI "Ord core_step2: same-constructor compare on non-comparable payloads" : Ordering)

instance : BEq core_step2 where
  beq := beqCoreStep2

instance : Ord core_step2 where
  compare := compareCoreStep2

-- No Inhabited here: the generated one (default := Step_blocked2) is real
-- and stays in Core_reduction.lean (see mechanism note above).

instance : Lem_Basic_classes.SetType core_step2 where
  setElemCompare x y :=
    match compareCoreStep2 x y with
    | .lt => LemOrdering.LT
    | .eq => LemOrdering.EQ
    | .gt => LemOrdering.GT

instance : Lem_Basic_classes.Eq0 core_step2 where
  isEqual := beqCoreStep2
  isInequal x y := !(beqCoreStep2 x y)

instance : Lem_Basic_classes.Ord0 core_step2 where
  compare := defaultCompare
  isLess := defaultLess
  isLessEqual := defaultLessEq
  isGreater := defaultGreater
  isGreaterEqual := defaultGreaterEq
