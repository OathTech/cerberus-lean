import CerbMem

set_option autoImplicit true

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
