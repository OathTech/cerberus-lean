import Nondeterminism
import CerbEscape

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
  CerbEscape.text msg

def batchRecord (msg : String) : String :=
  "ModelFailure {msg: \"" ++ escapeMessage msg ++ "\"}"

end CerbFail
