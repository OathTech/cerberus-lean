import LemLib

namespace CerbFloat

/-- The concrete Cerberus binary64 representation. Memory copies preserve all
bits, including signaling/quiet NaNs and their signs/payloads. Lean 4.32.2's
`Float.ofBits` and `Float.toBits` canonicalize NaNs, so a bare Lean `Float`
cannot implement `Int64.float_of_bits`/`Int64.bits_of_float` at this seam. -/
structure Value where
  bits : UInt64
  deriving Inhabited, Repr

namespace Value

def ofBits (bits : UInt64) : Value := ⟨bits⟩
def toBits (v : Value) : UInt64 := v.bits
/-- Numeric projection only; never use it to encode a value in memory. -/
def toFloat (v : Value) : Float := Float.ofBits v.bits
def ofFloat (v : Float) : Value := ⟨v.toBits⟩
def ofInt (n : Int) : Value := ofFloat (Float.ofInt n)
def isNaN (v : Value) : Bool :=
  v.bits &&& 0x7ff0000000000000 == 0x7ff0000000000000 &&
    v.bits &&& 0x000fffffffffffff != 0
def isInf (v : Value) : Bool := v.bits &&& 0x7fffffffffffffff == 0x7ff0000000000000
private def quiet (v : Value) : Value := ⟨v.bits ||| 0x0008000000000000⟩

/-- Mirror the concrete OCaml arithmetic on the pinned x86-64 reference:
NaN operands retain the first NaN's payload/sign and become quiet; an invalid
operation with non-NaN operands yields the negative quiet indefinite NaN.
Finite arithmetic continues to use Lean's existing binary64 primitives.
The retained 784-row native `Impl_mem.op_fval` matrix checks all four operators
on both NaN kinds/signs, distinct payloads, infinities, signed zeros and ±1. -/
private def binary (op : Float → Float → Float) (x y : Value) : Value :=
  if x.isNaN then quiet x
  else if y.isNaN then quiet y
  else
    let z := op x.toFloat y.toFloat
    if z.isNaN then ofBits 0xfff8000000000000 else ofFloat z

instance : BEq Value where beq x y := x.toFloat == y.toFloat
instance : LT Value where lt x y := x.toFloat < y.toFloat
instance : LE Value where le x y := x.toFloat ≤ y.toFloat
instance (x y : Value) : Decidable (x < y) := inferInstanceAs (Decidable (x.toFloat < y.toFloat))
instance (x y : Value) : Decidable (x ≤ y) := inferInstanceAs (Decidable (x.toFloat ≤ y.toFloat))
instance : Add Value where add := binary (· + ·)
instance : Sub Value where sub := binary (· - ·)
instance : Mul Value where mul := binary (· * ·)
instance : Div Value where div := binary (· / ·)
instance : Neg Value where neg v := ⟨v.bits ^^^ 0x8000000000000000⟩
instance (n : Nat) : OfNat Value n where ofNat := ofFloat (Float.ofNat n)
instance : OfScientific Value where ofScientific n s e := ofFloat (Float.ofScientific n s e)
instance : Coe Float Value where coe := ofFloat
instance : Ord Value where
  compare x y :=
    if x < y then .lt
    else if y < x then .gt
    else match x.isNaN, y.isNaN with
      | true, false => .lt
      | false, true => .gt
      | _, _ => .eq

/-- All representations round-trip, without a finiteness premise. -/
theorem toBits_ofBits (bits : UInt64) : (ofBits bits).toBits = bits := rfl
theorem ofBits_toBits (v : Value) : ofBits v.toBits = v := rfl

end Value
end CerbFloat
