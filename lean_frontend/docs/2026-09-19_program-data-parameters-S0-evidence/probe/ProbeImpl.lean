/- S0 probe: the hand-written reader_consumer stub. The reader parameters
   arrive as LEADING arguments in the backend's GLOBAL SORTED reader order
   (lean_backend.ml lean_reader_get_params: `_lemReader_<name>` sorted by
   String.compare) — for {tagDefs, digest, enum_defs} that is
   digest, enum_defs, tagDefs. -/
import LemLib

namespace ProbeImpl

def tagDefsUnreachable (_ : Unit) : Fmap Nat Nat := fmapEmpty
def digestUnreachable (_ : Unit) : String := ""
def enumDefsUnreachable (_ : Unit) : Fmap Nat Nat := fmapEmpty

/-- distinguishes the two same-typed maps: tagDefs by ENTRY COUNT, enum_defs by VALUE SUM -/
def consume (digest : String) (enum_defs : Fmap Nat Nat) (tagDefs : Fmap Nat Nat) (x : Nat) : Nat :=
  x + 100 * (fmapElements tagDefs).length
    + 10000 * ((fmapElements enum_defs).foldl (fun acc p => acc + p.2) 0)
    + 1000000 * digest.length

/-- the one-reader control's consumer -/
def consume1 (tagDefs : Fmap Nat Nat) (x : Nat) : Nat :=
  x + 100 * (fmapElements tagDefs).length

end ProbeImpl
