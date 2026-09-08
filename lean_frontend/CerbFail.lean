import Nondeterminism

/- C-TF1, typed-failure design (2026-09-05), R1 and §2.1.
   A pure, value-carrying boundary atom, like CerbFuel.fuelExhaustedLoc.
   No native binding or new axiom. Proofs are uniform in this atom;
   runtime recognition below does not supply an inequality theorem. -/
namespace CerbFail
set_option autoImplicit true

opaque modelFailStopLoc : CerbLocation.Loc := CerbLocation.Loc.other "model fail-stop"

def failStopKill {err : Type} (msg : String) : kill_reason err :=
  Error0 modelFailStopLoc msg

def failStopND {a info err cs st : Type} (msg : String) : ndM a info err cs st :=
  kill (failStopKill msg)

/-- Diagnostic strings contain Unicode, unlike the model's byte-as-Char IO.
    Encode UTF-8 bytes with the batch protocol's String.escaped grammar. -/
def escapeMessage (msg : String) : String :=
  msg.toUTF8.foldl (fun acc byte =>
    let n := byte.toNat
    acc ++ match n with
    | 34 => "\\\""
    | 92 => "\\\\"
    | 10 => "\\n"
    | 9 => "\\t"
    | 13 => "\\r"
    | 8 => "\\b"
    | _ => if 32 ≤ n && n ≤ 126 then String.singleton (Char.ofNat n)
      else "\\" ++ toString (n / 100) ++ toString (n / 10 % 10) ++ toString (n % 10)) ""

def batchRecord (msg : String) : String :=
  "ModelFailure {msg: \"" ++ escapeMessage msg ++ "\"}"

end CerbFail
