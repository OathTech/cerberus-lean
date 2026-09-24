import CerbMem
import Sc_value
import Init.Data.SInt.Lemmas
/-! Proofs about lossless keys and the actual interner. These do not identify
    raw keys with the final Cmm value equivalence across typed memory views. -/
namespace CerbSCValues
open CerbMem

private def restoreProvenance : sc_provenance_key → Provenance
  | .SC_no_provenance => .Prov_none
  | .SC_storage_provenance n => .Prov_some n
  | .SC_symbolic_provenance n => .Prov_symbolic n
  | .SC_device_provenance => .Prov_device

private def restorePointer : sc_pointer_key → PointerValue
  | (provenance, base) => .PV (restoreProvenance provenance) (match base with
    | .SC_null_pointer ty => .PVnull ty
    | .SC_function_pointer sym => .PVfunction sym
    | .SC_concrete_pointer member address => .PVconcrete member address)

mutual
private def restoreValue : sc_value_key → MemValue
  | .SC_unspecified_value ty => .MVunspecified ty
  | .SC_integer_value ity provenance n => .MVinteger ity (.IV (restoreProvenance provenance) n)
  | .SC_floating_value fty bits => .MVfloating fty (.ofBits (Int64.ofInt bits).toUInt64)
  | .SC_pointer_value ty pointer => .MVpointer ty (restorePointer pointer)
  | .SC_array_value values => .MVarray (restoreValues values)
  | .SC_struct_value tag members => .MVstruct tag (restoreMembers members)
  | .SC_union_value tag member value => .MVunion tag member (restoreValue value)
private def restoreValues : List sc_value_key → List MemValue
  | [] => []
  | value :: rest => restoreValue value :: restoreValues rest
private def restoreMembers : List (identifier × ctype × sc_value_key) → List (identifier × ctype × MemValue)
  | [] => []
  | (id,ty,value) :: rest => (id,ty,restoreValue value) :: restoreMembers rest
end

private theorem provenance_roundtrip (provenance : Provenance) :
    restoreProvenance (scProvenanceKey provenance) = provenance := by
  cases provenance <;> rfl

private theorem pointer_roundtrip (pointer : PointerValue) :
    restorePointer (scPointerKey pointer) = pointer := by
  cases pointer with
  | PV provenance base =>
    cases base <;> simp [scPointerKey, restorePointer, provenance_roundtrip]

mutual
private theorem value_roundtrip (value : MemValue) :
    restoreValue (scValueKeyConcrete value) = value := by
  cases value with
  | MVunspecified ty => rfl
  | MVinteger ity number =>
    cases number with
    | IV provenance n => simp [scValueKeyConcrete, restoreValue, provenance_roundtrip]
  | MVfloating fty value =>
    simp [scValueKeyConcrete, restoreValue, CerbFloat.Value.ofBits_toBits]
  | MVpointer ty pointer =>
    simp [scValueKeyConcrete, restoreValue, pointer_roundtrip]
  | MVarray values =>
    simp only [scValueKeyConcrete, restoreValue, values_roundtrip]
  | MVstruct tag members =>
    simp only [scValueKeyConcrete, restoreValue, members_roundtrip]
  | MVunion tag member value =>
    simp only [scValueKeyConcrete, restoreValue, value_roundtrip]
private theorem values_roundtrip (values : List MemValue) :
    restoreValues (scValueKeys values) = values := by
  cases values with
  | nil => rfl
  | cons value rest =>
    simp only [scValueKeys, restoreValues, value_roundtrip, values_roundtrip]
private theorem members_roundtrip (members : List (identifier × ctype × MemValue)) :
    restoreMembers (scMemberKeys members) = members := by
  cases members with
  | nil => rfl
  | cons entry rest =>
    rcases entry with ⟨id,ty,value⟩
    simp only [scMemberKeys, restoreMembers, value_roundtrip, members_roundtrip]
end

/-- Every concrete field is recoverable, including every floating bit pattern.
    Equality here is structural Lean equality, not C numeric comparison. -/
theorem value_key_injective : Function.Injective scValueKeyConcrete := by
  intro a b same
  have := congrArg restoreValue same
  simpa only [value_roundtrip] using this

theorem value_key_eq_iff (a b : MemValue) :
    scValueKeyConcrete a = scValueKeyConcrete b ↔ a = b :=
  ⟨fun h => value_key_injective h, fun h => congrArg scValueKeyConcrete h⟩

/-- A previously found key retains its token and the entire table. -/
theorem intern_existing (key : sc_value_key) (table : sc_value_table) (token : Nat)
    (found : Lem_List.lookupBy (fun a b => a == b) key table = some token) :
    sc_intern_value key table = (token,table) := by
  simp [sc_intern_value, found]

/-- The absent branch grows the table by one and preserves every prior entry.
    No claim is made about malformed externally supplied token tables. -/
theorem intern_absent (key : sc_value_key) (table : sc_value_table)
    (absent : Lem_List.lookupBy (fun a b => a == b) key table = none) :
    sc_intern_value key table = (table.length,(key,table.length)::table) := by
  simp [sc_intern_value, absent]

def TokensBounded (table : sc_value_table) : Prop :=
  ∀ key token, (key,token) ∈ table → token < table.length

theorem empty_tokens_bounded : TokensBounded [] := by
  intro key token member
  cases member

theorem length_token_fresh (table : sc_value_table) (bounded : TokensBounded table)
    (key : sc_value_key) : (key,table.length) ∉ table := by
  intro member
  exact Nat.lt_irrefl _ (bounded key table.length member)

/-- Starting from empty, every call preserves the bound needed by freshness.
    This theorem does not assume a fabricated invariant on arbitrary tables. -/
theorem intern_preserves_bound (key : sc_value_key) (table : sc_value_table)
    (bounded : TokensBounded table) : TokensBounded (sc_intern_value key table).2 := by
  unfold sc_intern_value
  split
  · exact bounded
  · intro other token member
    simp only [List.mem_cons] at member
    rcases member with same | old
    · cases same
      simp
    · exact Nat.lt_trans (bounded other token old) (Nat.lt_succ_self _)

end CerbSCValues

-- Lossless physical byte keys; these do not establish logical reads-from.
namespace CerbSCByteKeys
open CerbMem

theorem provenanceKey_injective : Function.Injective scProvenanceKey := by
  intro a b h
  cases a <;> cases b <;> simp_all [scProvenanceKey]

theorem byteBits_injective :
    Function.Injective (fun value : Option UInt8 =>
      value.map (fun v => Int.ofNat v.toNat)) := by
  intro a b h
  cases a with
  | none => cases b <;> simp_all
  | some a =>
    cases b with
    | none => simp_all
    | some b =>
      apply congrArg some
      apply UInt8.toNat_inj.mp
      simpa using congrArg Int.toNat (Option.some.inj h)

theorem byteKey_injective : Function.Injective scByteKeyConcrete := by
  intro a b h
  have hp := provenanceKey_injective (congrArg sc_byte_key.sc_byte_provenance h)
  have ho := congrArg sc_byte_key.sc_byte_copy_offset h
  have hv := byteBits_injective (congrArg sc_byte_key.sc_byte_bits h)
  cases a; cases b
  simp_all [scByteKeyConcrete, representationBits]

theorem byteKey_bits (byte : AbsByte) :
    (scByteKeyConcrete byte).sc_byte_bits = representationBits byte := rfl

theorem byteKeys_injective : Function.Injective (List.map scByteKeyConcrete) := by
  intro xs ys h
  induction xs generalizing ys with
  | nil => cases ys <;> simp_all
  | cons x xs ih =>
    cases ys with
    | nil => simp_all
    | cons y ys =>
      have hpair := List.cons.inj h
      have hhead := byteKey_injective hpair.1
      have htail := ih hpair.2
      simp_all

end CerbSCByteKeys
