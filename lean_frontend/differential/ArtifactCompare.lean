import PipelineA
import PipelineB
import CerbQuote
import ArtifactQuoteB

/- Whole pre-execution artifacts, compared without rendering or serializing.
   ArtifactQuoteB emits the original constructor/type label strings on purpose:
   this is the sole namespace-forgetting map. Literal values, symbol identities,
   locations, all AST fields and map/set tree shapes remain exact. Fmap comparator
   closures use CerbQuote's existing audited producer-provenance contract; this
   does not claim extensional equality of arbitrary supplied functions. -/

namespace CoreBDiff.ArtifactCompare

mutual
partial def sameTerm : CerbQuote.Term → CoreB.CerbQuote.Term → Bool
  | .atom a, .atom b => a == b
  | .app a xs, .app b ys => a == b && sameTerms xs ys
  | .list xs, .list ys => sameTerms xs ys
  | .consList a xs x, .consList b ys y => a == b && sameTerms xs ys && sameTerm x y
  | .typed a x, .typed b y => a == b && sameTerm x y
  | _, _ => false

partial def sameTerms : List CerbQuote.Term → List CoreB.CerbQuote.Term → Bool
  | [], [] => true
  | x :: xs, y :: ys => sameTerm x y && sameTerms xs ys
  | _, _ => false
end

/-- Check the complete linked/converted file from the same prepared input.
    The retained translation artifacts supply comparator provenance at the
    audited producer site; one-TU linking and conversion preserve it. -/
def compare (a : ExecutionA) (b : ExecutionB) : Except String Unit := do
  unless a.translatedSupply == b.translatedSupply do
    throw "translation fresh supplies differ"
  unless a.initialSupply == b.initialSupply do
    throw "initial-driver fresh supplies differ"
  let pa ← (CerbQuote.linkedProvenance
    [CerbQuote.translatedProvenance a.translated] a.file).mapError (·.message)
  let pb ← (CoreB.CerbQuote.linkedProvenance
    [CoreB.CerbQuote.translatedProvenance b.translated] b.file).mapError (·.message)
  let qa ← (CerbQuote.quoteFile pa a.file).mapError (·.message)
  let qb ← (CoreB.CerbQuote.quoteFile pb b.file).mapError (·.message)
  unless sameTerm qa qb do throw "complete Core/CoreB artifact differs under namespace erasure"

end CoreBDiff.ArtifactCompare
