/-
SpecLabTest — S0 executable sanity layer + harness emitter.

Modes:
  (no args)                 run all sanity checks; exit 0 iff all pass.
  --emit-identity CSV       print the identity harness for the given
                            choice stream (comma-separated bytes) to
                            stdout — consumed by scripts/test_speclab.sh.
  --emit-plant CSV IDX      print the identity harness with expected[]
                            CORRUPTED at position IDX (bit-flipped) —
                            the plant-mode instrument: the harness must
                            then return 1+IDX, differentially, on both
                            pipelines.

EPISTEMIC LABEL: everything in this file is a TEST (untrusted-evaluator
checking, golean Audit-doctrine vocabulary) — the kernel-checked layer
is the lemma set in SpecLab/Codec.lean, checked by `lake build`. The
renderer parse-back round trip here is executable evidence about
`renderByteArrayLiteral`'s faithfulness, never a proof.
-/
import SpecLab

open SpecLab SpecLab.Codec

set_option autoImplicit false

/-- Parse the inside of a rendered C byte initializer back to bytes:
the renderer's executable inverse ("3, 255" → some [3, 255]).
Test-side only. -/
def parseByteArrayLiteral (s : String) : Option (List UInt8) :=
  if s.isEmpty then some [] else
  (s.splitOn ", ").foldr (fun tok acc => do
    let ns ← acc
    let n ← tok.toNat?
    if n < 256 then some (UInt8.ofNat n :: ns) else none) (some [])

/-- Parse a plain comma-separated byte list CLI argument ("1,2,255"). -/
def parseCsvBytes (s : String) : Option (List UInt8) :=
  (s.splitOn ",").foldr (fun tok acc => do
    let ns ← acc
    let n ← tok.trimAscii.toString.toNat?
    if n < 256 then some (UInt8.ofNat n :: ns) else none) (some [])

structure Check where
  name : String
  pass : Bool

def rendererRoundTrip (bs : List UInt8) : Bool :=
  parseByteArrayLiteral (renderByteArrayLiteral bs) == some bs

/-- The splice sanity: rendering with sentinel-distinct parts, the
rendered text decomposes exactly as pre/choices/mid/expected/post. -/
def spliceSanity : Bool :=
  let t : HarnessTemplate := { pre := "<PRE>", mid := "<MID>", post := "<POST>" }
  mkHarness t [1, 2] [3] == "<PRE>1, 2<MID>3<POST>"

def codecChecks : List Check :=
  let u16s : List UInt16 := [0, 1, 255, 256, 4660, 65535]
  let u32s : List UInt32 := [0, 1, 65535, 65536, 305419896, 4294967295]
  let u64s : List UInt64 := [0, 1, 4294967295, 4294967296,
    1311768467463790320, 18446744073709551615]
  let arrs : List (List UInt8) := [[], [0], [1, 2, 3], List.replicate 300 7]
  [ { name := "codec: u8 round trip (executable spot checks)"
    , pass := (List.range 256).all fun n =>
        let v := UInt8.ofNat n
        decodeU8 (encodeU8 v ++ [9]) == some (v, [9]) }
  , { name := "codec: u16le round trip (executable spot checks)"
    , pass := u16s.all fun v =>
        decodeU16LE (encodeU16LE v ++ [9]) == some (v, [9]) }
  , { name := "codec: u32le round trip (executable spot checks)"
    , pass := u32s.all fun v =>
        decodeU32LE (encodeU32LE v ++ [9]) == some (v, [9]) }
  , { name := "codec: u64le round trip (executable spot checks)"
    , pass := u64s.all fun v =>
        decodeU64LE (encodeU64LE v ++ [9]) == some (v, [9]) }
  , { name := "codec: u16le is little-endian on the wire (0x1234 -> 52,18)"
    , pass := encodeU16LE 4660 == [52, 18] }
  , { name := "codec: arrayU16 round trip (executable spot checks)"
    , pass := arrs.all fun xs =>
        decodeArrayU16 decodeU8 (encodeArrayU16 encodeU8 xs ++ [9])
          == some (xs, [9]) }
  , { name := "codec: decode underrun is none, never junk"
    , pass := (decodeU16LE [1] == none) && (decodeU32LE [1, 2, 3] == none)
        && (decodeArrayU16 decodeU8 (encodeU16LE 3 ++ [1, 2]) == none) }
  ]

def harnessChecks : List Check :=
  [ { name := "mkHarness: splice decomposition exact", pass := spliceSanity }
  , { name := "mkHarness: renderer parse-back round trip"
    , pass := [[], [0], [255], [1, 2, 3], List.replicate 64 170].all
        rendererRoundTrip }
  , { name := "mkHarness: identity harness contains both spliced arrays"
    , pass :=
        let h := mkIdentityHarness [7, 8, 9]
        -- two occurrences of the literal (choices + expected)
        ((h.splitOn "7, 8, 9").length == 3)
        && (h.splitOn "\n").length > 20 }
  ]

open SpecLab.DivMod in
def divmodChecks : List Check :=
  let m72 : Input := ⟨7, 2⟩
  let mneg : Input := ⟨-7, 2⟩
  let i8s : List Int := [-128, -127, -1, 0, 1, 126, 127]
  [ { name := "divmod: expectedBytes (7,2) = [3,0,0,0,1,0,0,0]"
    , pass := expectedBytes m72 == [3, 0, 0, 0, 1, 0, 0, 0] }
  , { name := "divmod: expectedBytes (-7,2) = q=-3 r=-1 two's complement"
    , pass := expectedBytes mneg
        == [253, 255, 255, 255, 255, 255, 255, 255] }
  , { name := "divmod: C truncation semantics spot checks (tdiv/tmod)"
    , pass := modelFn ⟨-7, 2⟩ == (-3, -1) && modelFn ⟨7, -2⟩ == (-3, 1)
        && modelFn ⟨-7, -2⟩ == (3, -1) && modelFn ⟨7, 2⟩ == (3, 1) }
  , { name := "divmod: i8 byte codec round trip (executable spot checks)"
    , pass := i8s.all fun n => ofByteI8 (toByteI8 n) == n }
  , { name := "divmod: input codec round trip at edges (executable)"
    , pass := edgeSamples.all fun m =>
        decodeInput (encodeInput m) == some (m, []) }
  , { name := "divmod: edge sample set ≥ 100 and all Wf"
    , pass := edgeSamples.length ≥ 100 && edgeSamples.all wfb }
  , { name := "divmod: INT_MIN/-1 and y=0 rows filtered from edges"
    , pass := edgeSamples.all fun m =>
        m.y ≠ 0 && !(m.x == i32Min && m.y == -1) }
  , { name := "divmod: verdictOf mirror (agree/index/length)"
    , pass := verdictOf [1, 2] [1, 2] == 0
        && verdictOf [1, 9] [1, 2] == 2
        && verdictOf [1] [1, 2] == 255 }
  , { name := "divmod: plant verdict predicted at (7,2) is 1 (q byte 0)"
    , pass := plantVerdict m72 == 1 && plantVerdictI8 m72 == 1 }
  , { name := "divmod: render3 stdout mirror (0,255 -> 000,255,)"
    , pass := render3 [0, 255] == "000,255," }
  ]

/-- #eval-able one-shot: `#eval SpecLab.Test.allPass` (also the exe's
exit verdict). -/
def allChecks : List Check := codecChecks ++ harnessChecks ++ divmodChecks

def emitPlant (bs : List UInt8) (idx : Nat) : Option String :=
  if h : idx < bs.length then
    let corrupted := bs.set idx (bs[idx] ^^^ 1)
    some (mkHarness identityTemplateV1 bs corrupted)
  else none

open SpecLab.DivMod in
/-- Render a divmod harness for FORM at input (x, y). Returns
(harness text, predicted verdict line) or an error string. -/
def emitDivMod (form : String) (x y : Int) :
    Except String (String × String) := do
  let m : Input := ⟨x, y⟩
  let needI8 := form == "i8" || form == "i8-plant"
  if needI8 then
    if !wfI8b m then throw s!"input ({x}, {y}) not WfI8"
  else
    if !wfb m then throw s!"input ({x}, {y}) not Wf"
  match form with
  | "form1" => pure (mkDivModForm1 m, "Specified(0)")
  | "form1b" => pure (mkDivModForm1b m, "Specified(0)")
  | "form2" => pure (mkDivModForm2 m, "Specified(0)")
  | "i8" => pure (mkDivModI8 m, "Specified(0)")
  | "form1-plant" =>
    pure (mkDivModForm1Plant m, s!"Specified({plantVerdict m})")
  | "form1b-plant" =>
    pure (mkDivModForm1bPlant m,
      if plantVerdict m == 0 then "Specified(0)" else "Specified(1)")
  | "form2-plant" => pure (mkDivModForm2Plant m, "Specified(0)")
  | "i8-plant" =>
    pure (mkDivModI8Plant m, s!"Specified({plantVerdictI8 m})")
  | _ => throw s!"unknown divmod form: {form}"

open SpecLab.DivMod in
/-- Predicted Form 2 stdout for input (x, y) (healthy targets), in
the batch-output ESCAPED spelling (the trailing flush newline prints
as literal `\n` in the batch line). -/
def predictForm2Stdout (x y : Int) : String :=
  render3 (expectedBytes ⟨x, y⟩) ++ "\\n"

def main (args : List String) : IO UInt32 := do
  match args with
  | ["--emit-divmod", form, xs, ys] =>
    match xs.toInt?, ys.toInt? with
    | some x, some y =>
      match emitDivMod form x y with
      | .ok (h, _) => IO.print h; return 0
      | .error e => IO.eprintln s!"SpecLabTest: {e}"; return 2
    | _, _ => IO.eprintln "SpecLabTest: bad --emit-divmod ints"; return 2
  | ["--divmod-predict", form, xs, ys] =>
    match xs.toInt?, ys.toInt? with
    | some x, some y =>
      match emitDivMod form x y with
      | .ok (_, v) =>
        IO.println v
        if form == "form2" || form == "form2-plant" then
          -- Form 2's observable: the healthy-model stdout prediction
          -- (the plant's stdout DIVERGES from this — that is the red)
          IO.println (predictForm2Stdout x y)
        return 0
      | .error e => IO.eprintln s!"SpecLabTest: {e}"; return 2
    | _, _ => IO.eprintln "SpecLabTest: bad --divmod-predict ints"; return 2
  | ["--emit-divmod-stream", csv] =>
    match parseCsvBytes csv with
    | some bs =>
      if SpecLab.DivMod.validStreamb bs then
        IO.print (SpecLab.DivMod.mkDivModForm1OfStream bs)
        return 0
      else
        IO.eprintln "SpecLabTest: INVALID stream (not 8 bytes / not Wf)"
        return 3
    | none => IO.eprintln s!"SpecLabTest: bad byte list: {csv}"; return 2
  | ["--divmod-samples"] =>
    for m in SpecLab.DivMod.edgeSamples do
      IO.println s!"{m.x} {m.y}"
    return 0
  | ["--emit-identity", csv] =>
    match parseCsvBytes csv with
    | some bs =>
      if bs.isEmpty then
        IO.eprintln "SpecLabTest: --emit-identity needs a nonempty byte list \
          (empty C initializers are invalid pre-C23)"
        return 2
      IO.print (mkIdentityHarness bs)
      return 0
    | none => IO.eprintln s!"SpecLabTest: bad byte list: {csv}"; return 2
  | ["--emit-plant", csv, idxs] =>
    match parseCsvBytes csv, idxs.toNat? with
    | some bs, some idx =>
      match emitPlant bs idx with
      | some h => IO.print h; return 0
      | none =>
        IO.eprintln s!"SpecLabTest: plant index {idx} out of range"; return 2
    | _, _ => IO.eprintln "SpecLabTest: bad --emit-plant args"; return 2
  | [] =>
    let mut failed := 0
    for c in allChecks do
      if c.pass then
        IO.println s!"  PASS  {c.name}"
      else
        IO.println s!"  FAIL  {c.name}"
        failed := failed + 1
    if failed == 0 then
      IO.println s!"SpecLabTest: ALL PASSED ({allChecks.length} checks)"
      return 0
    else
      IO.println s!"SpecLabTest: {failed} FAILED"
      return 1
  | _ =>
    IO.eprintln "usage: speclab-test [--emit-identity CSV | --emit-plant CSV IDX]"
    return 2
