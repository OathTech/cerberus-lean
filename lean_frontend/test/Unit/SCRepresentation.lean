import CerbSCRepresentation

private def cases : List (String × List (Option Int) × List (Option Int) × sc_representation_comparison) :=
  [ ("same integer representation", [some 7, some 0], [some 7, some 0], .SC_same_bits)
  , ("different integer representation", [some 7, some 0], [some 8, some 0], .SC_different_bits)
  , ("positive and negative zero", [some 0, some 0, some 0, some 0, some 0, some 0, some 0, some 0],
      [some 0, some 0, some 0, some 0, some 0, some 0, some 0, some 128], .SC_different_bits)
  , ("identical NaN representation", [some 1, some 0, some 0, some 0, some 0, some 0, some 248, some 127],
      [some 1, some 0, some 0, some 0, some 0, some 0, some 248, some 127], .SC_same_bits)
  , ("different NaN payload", [some 1, some 0, some 0, some 0, some 0, some 0, some 248, some 127],
      [some 2, some 0, some 0, some 0, some 0, some 0, some 248, some 127], .SC_different_bits)
  , ("unspecified left", [none], [some 0], .SC_unspecified_representation)
  , ("unspecified right", [some 0], [none], .SC_unspecified_representation)
  , ("two unspecified bytes", [none], [none], .SC_unspecified_representation)
  , ("difference before padding", [some 1, none], [some 2, none], .SC_unspecified_representation)
  , ("padding before difference", [none, some 1], [none, some 2], .SC_unspecified_representation)
  , ("size mismatch", [some 0], [some 0, some 0], .SC_representation_size_mismatch)
  ]

def main : IO UInt32 := do
  let mut ok := true
  for (label, left, right, expected) in cases do
    let pass := sc_compare_representation left right == expected
    IO.println s!"{label}: {pass}"
    ok := ok && pass
  return if ok then 0 else 1
