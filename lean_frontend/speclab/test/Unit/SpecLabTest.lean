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

open SpecLab.ByteArr in
def byteArrChecks : List Check :=
  let ramp : List UInt8 := [1, 2, 3]
  [ { name := "bytearr: encodeInput = u16le prefix ++ verbatim bytes"
    , pass := encodeInput ramp == [3, 0, 1, 2, 3]
        && encodeInput [] == [0, 0] }
  , { name := "bytearr: expectedBytes = prefix ++ dst' ++ src'; n=0 nonempty"
    , pass := expectedBytes ramp == [3, 0, 1, 2, 3, 1, 2, 3]
        && expectedBytes [] == [0, 0] }
  , { name := "bytearr: canonicity (executable spot): decode-then-encode = id"
    , pass := [[], [7], ramp, List.replicate 16 255].all fun bs =>
        match decodeInput (encodeInput bs) with
        | some (bs', []) => encodeInput bs' == encodeInput bs
        | _ => false }
  , { name := "bytearr: validStreamb accepts encoded Wf, rejects malformed"
    , pass := validStreamb (encodeInput ramp)
        && validStreamb [0, 0]
        && !validStreamb [5, 0, 1]          -- short body
        && !validStreamb [17, 0]            -- over capacity
        && !validStreamb (encodeInput (List.replicate 17 1)) }
  , { name := "bytearr: plant verdict predicted 3 (dst byte 0) on ramp"
    , pass := plantVerdict ramp == 3
        && plantVerdict [] == 0             -- n=0: plant is invisible
        && plantVerdict [canary, 9] == 0 }  -- canary collision: blind spot, by design
  , { name := "bytearr: getarr expected = ret ++ arr; plant verdict 1"
    , pass :=
        let hello : List UInt8 :=
          [104, 101, 108, 108, 111, 104, 101, 108, 108, 111]
        getarrExpected hello == 111 :: hello
        && getarrPlantVerdict hello == 1
        && getarrPlantVerdict (List.replicate 10 7) == 0 }
  , { name := "bytearr: sweep sample sets sized and Wf (memcpy ≥ 100)"
    , pass := sweepSamples.length ≥ 100 && sweepSamples.all wfb
        && getarrSamples.length == 20 && getarrSamples.all gwfb }
  , { name := "bytearr: structured face flattens to byte face (executable)"
    , pass := bytesOfU16s [4660, 255] == [52, 18, 255, 0] }
  ]

open SpecLab.ListAppend in
def listAppendChecks : List Check :=
  let m21 : SpecLab.ListAppend.Input := ⟨[1, 2], [3]⟩
  let mBound : SpecLab.ListAppend.Input :=
    ⟨[-2147483648, -1], [2147483647]⟩
  [ { name := "list: encodeInput (xs=[1,2],ys=[3]) = the S3 probe stream"
    , pass := encodeInput m21
        == [2, 0, 1, 0, 0, 0, 2, 0, 0, 0, 1, 0, 3, 0, 0, 0] }
  , { name := "list: expectedBytes = count ++ appended heads; n=0 nonempty"
    , pass := expectedBytes m21 == [3, 0, 1, 0, 0, 0, 2, 0, 0, 0, 3, 0, 0, 0]
        && expectedBytes ⟨[], []⟩ == [0, 0] }
  , { name := "list: input codec round trip at edges (executable)"
    , pass := [m21, mBound, ⟨[], []⟩, ⟨[], [7]⟩,
        ⟨List.replicate 8 (-1), List.replicate 8 2147483647⟩].all fun m =>
        decodeInput (encodeInput m) == some (m, []) }
  , { name := "list: validStreamb accepts encoded Wf, rejects malformed"
    , pass := validStreamb (encodeInput m21)
        && validStreamb [0, 0, 0, 0]
        && !validStreamb [2, 0, 1]                 -- short body
        && !validStreamb [9, 0]                    -- over cap
        && !validStreamb (encodeInput m21 ++ [1]) }  -- trailing junk
  , { name := "list: link plant verdict 255 (len arm); blind at |xs| ≤ 1"
    , pass := linkPlantVerdict m21 == 255
        && linkPlantVerdict ⟨[], [3]⟩ == 0
        && linkPlantVerdict ⟨[5], [3]⟩ == 0
        && linkPlantLeaked m21 == 1 }
  , { name := "list: elem plant verdict 3 (element 0 low byte); blind at xs=[]"
    , pass := elemPlantVerdict m21 == 3
        && elemPlantVerdict ⟨[], [3]⟩ == 0
        && elemPlantVerdict mBound == 3 }
  , { name := "list: xorOne two's-complement mirror (evens up, odds down)"
    , pass := xorOne 0 == 1 && xorOne 1 == 0 && xorOne (-1) == -2
        && xorOne (-2) == -1 && xorOne 2147483647 == 2147483646
        && xorOne (-2147483648) == -2147483647 }
  , { name := "list: sweep sample set ≥ 100 and all Wf"
    , pass := sweepSamples.length ≥ 100 && sweepSamples.all wfb }
  , { name := "list: at-samples all AtWf; at model = drop k ++ ys"
    , pass := atSamples.all atWfb
        && atModelFn ⟨1, [1, 2, 3], [9]⟩ == [2, 3, 9]
        && encodeAtInput ⟨1, [5], []⟩ == 1 :: encodeInput ⟨[5], []⟩ }
  ]

/-! ## arc-15 S4: the tree-rotation (R4) test-side layer — the
    TREE|PATH text syntax (parser + printer, TEST-SIDE ONLY; the pure
    encoders remain the statement vocabulary) and the sanity checks. -/

/-- Recursive-descent tree parser over `L` / `( v LEFT RIGHT )`
tokens (fuel = token count; test-side). -/
def treeOfToks : Nat → List String → Option (SpecLab.TreeRot.Tree × List String)
  | 0, _ => none
  | _ + 1, "L" :: rest => some (.leaf, rest)
  | fuel + 1, "(" :: vtok :: rest => do
    let v ← vtok.toInt?
    let (l, r1) ← treeOfToks fuel rest
    let (r, r2) ← treeOfToks fuel r1
    match r2 with
    | ")" :: r3 => some (.node v l r, r3)
    | _ => none
  | _, _ => none

/-- `(7 (2 L L) L)` → Tree (whitespace-tolerant around parens). -/
def parseTreeText (s : String) : Option SpecLab.TreeRot.Tree :=
  let toks := ((s.replace "(" " ( ").replace ")" " ) ").splitOn " "
    |>.filter (· ≠ "")
  match treeOfToks (toks.length + 1) toks with
  | some (t, []) => some t
  | _ => none

/-- Path text: a string over {l, r} (empty = rotate at the root). -/
def parsePathText (s : String) : Option (List Bool) :=
  s.toList.foldr (fun c acc => do
    let p ← acc
    match c with
    | 'l' => some (false :: p)
    | 'r' => some (true :: p)
    | _ => none) (some [])

/-- The R4 model CLI argument: `TREE|PATH`. -/
def parseTreeArg (s : String) : Option SpecLab.TreeRot.Input :=
  match s.splitOn "|" with
  | [ts, ps] => do
    let t ← parseTreeText ts
    let p ← parsePathText ps
    some ⟨t, p⟩
  | _ => none

def treeTextOf : SpecLab.TreeRot.Tree → String
  | .leaf => "L"
  | .node v l r => s!"({v} {treeTextOf l} {treeTextOf r})"

def pathTextOf (p : List Bool) : String :=
  String.join (p.map fun b => if b then "r" else "l")

def treeArgOf (m : SpecLab.TreeRot.Input) : String :=
  treeTextOf m.tree ++ "|" ++ pathTextOf m.path

open SpecLab.TreeRot in
/-- The pinned worked-example instance (small vals): tree
`(1 (2 (3 L (4 L L)) (5 L L)) (6 L L))`, path `[l]` — the rotation
locus is b=2, the transferred middle subtree is `(4 L L)`. -/
def treeM0 : SpecLab.TreeRot.Input :=
  ⟨pinnedShape 1 2 3 4 5 6, [false]⟩

open SpecLab.TreeRot in
def treeRotChecks : List Check :=
  let m0 := treeM0
  let expect0 : List UInt8 :=  -- encodeTree (node 1 (node 3 L (node 2 (node 4 L L) (node 5 L L))) (node 6 L L))
    [1,1,0,0,0, 1,3,0,0,0, 0, 1,2,0,0,0, 1,4,0,0,0, 0,0, 1,5,0,0,0,
     0,0, 1,6,0,0,0, 0,0]
  [ { name := "tree: encodeInput m0 = pre-order presence code ++ path"
    , pass := encodeInput m0
        == [1,1,0,0,0, 1,2,0,0,0, 1,3,0,0,0, 0, 1,4,0,0,0, 0,0,
            1,5,0,0,0, 0,0, 1,6,0,0,0, 0,0] ++ [1, 0] }
  , { name := "tree: rotateAt m0 transfers the middle subtree (hand-checked)"
    , pass := modelFn m0
        == .node 1 (.node 3 .leaf (.node 2 (.node 4 .leaf .leaf)
             (.node 5 .leaf .leaf))) (.node 6 .leaf .leaf)
        && expectedBytes m0 == expect0 }
  , { name := "tree: rotateAt off-shape is identity (leaf walk, no-left locus)"
    , pass := rotateAt .leaf [false] == .leaf
        && rotateAt (.node 5 .leaf (.node 6 .leaf .leaf)) [] ==
             .node 5 .leaf (.node 6 .leaf .leaf)
        && rotateAt (.node 1 (.node 2 .leaf .leaf) .leaf) [true, true] ==
             .node 1 (.node 2 .leaf .leaf) .leaf }
  , { name := "tree: input codec round trip at edges (executable)"
    , pass := [m0, ⟨.leaf, []⟩, ⟨.leaf, [true]⟩,
        ⟨pinnedShape 0 (-1) (-2147483648) 2147483647 1 (-2147483647), [false]⟩,
        ⟨completeT 5 0 (fun i => Int.ofNat i + 1), [false, false, false, false]⟩].all
        fun m => decodeInput (encodeInput m) == some (m, []) }
  , { name := "tree: validStreamb accepts encoded Wf, rejects malformed"
    , pass := validStreamb (encodeInput m0)
        && validStreamb [0, 0]                    -- leaf tree, empty path
        && !validStreamb [1, 5, 0, 0, 0]          -- truncated children
        && !validStreamb [2, 0]                   -- bad presence byte
        && !validStreamb [0]                      -- missing path count
        && !validStreamb [0, 1, 2]                -- bad path bit
        && !validStreamb ([0, 0] ++ [7]) }        -- trailing junk
  , { name := "tree: swap plant verdict 7 on m0 (byte 6 = locus val); blind spots 0"
    , pass := swapPlantVerdict m0 == 7
        && swapPlantVerdict ⟨.node 7 (.node 7 .leaf .leaf) .leaf, []⟩ == 0
        && swapPlantVerdict ⟨.node 5 .leaf (.node 6 .leaf .leaf), []⟩ == 0 }
  , { name := "tree: drop plant verdict 255 (length arm) on m0; leak 1; blind spot 0"
    , pass := dropPlantVerdict m0 == 255
        && dropPlantLeaked m0 == 1
        && dropPlantVerdict ⟨.node 1 (.node 2 .leaf .leaf) .leaf, []⟩ == 0
        && dropPlantLeaked ⟨.node 1 (.node 2 .leaf .leaf) .leaf, []⟩ == 0 }
  , { name := "tree: sweep sample set ≥ 120 and all Wf"
    , pass := sweepSamples.length ≥ 120 && sweepSamples.all wfb }
  , { name := "tree: preorderVals of the pinned instance a = wire bytes 1..24"
    , pass := ((pinnedShape 67305985 134678021 202050057 269422093
          336794129 404166165).preorderVals.flatMap
          SpecLab.DivMod.encodeI32LE).map (fun b => b.toNat)
        == (List.range 24).map (· + 1) }
  , { name := "tree: text syntax round trip (parser ∘ printer = id)"
    , pass := [m0, ⟨.leaf, []⟩,
        ⟨lspineT 4 0 (fun i => Int.ofNat i - 2), [false, false]⟩].all
        fun m => parseTreeArg (treeArgOf m) == some m }
  ]

/-! ## arc-15 S5: the CN-seed rung (R5: swap_pair + lookup_size_shift)
    test-side layer. -/

open SpecLab.CnSeed in
/-- The pinned swap instance a (wire bytes 1..16). -/
def swapM0 : SpecLab.CnSeed.PairInput :=
  ⟨578437695752307201, 1157159078456920585⟩

open SpecLab.CnSeed in
def cnSeedChecks : List Check :=
  [ { name := "cnseed: encodePair swapM0 = wire bytes 1..16"
    , pass := (encodePair swapM0).map (·.toNat)
        == (List.range 16).map (· + 1) }
  , { name := "cnseed: expectedBytes = swapped halves (bytes 9..16 ++ 1..8)"
    , pass := (expectedBytes swapM0).map (·.toNat)
        == ((List.range 8).map (· + 9)) ++ ((List.range 8).map (· + 1)) }
  , { name := "cnseed: pair codec round trip at edges (executable)"
    , pass := swapSamples.all fun m =>
        decodePair (encodePair m) == some (m, []) }
  , { name := "cnseed: validStreamb accepts 16 bytes, rejects 15/17"
    , pass := validStreamb (encodePair swapM0)
        && !validStreamb (List.replicate 15 1)
        && !validStreamb (List.replicate 17 1) }
  , { name := "cnseed: swap plant verdict 9 at swapM0; blind exactly on diagonal"
    , pass := swapPlantVerdict swapM0 == 9
        && swapPlantVerdict ⟨5, 5⟩ == 0
        && swapPlantVerdict ⟨0, 18446744073709551615⟩ == 9 }
  , { name := "cnseed: swap sweep set = full 10x10 cross incl. diagonal"
    , pass := swapSamples.length == 100
        && swapSamples.any (fun m => m.a == m.b) }
  , { name := "cnseed: lookupSizeShift arms (12/8/2/0) + plant verdicts"
    , pass := lookupSizeShift 0 == 12 && lookupSizeShift 1 == 8
        && lookupSizeShift 2 == 2 && lookupSizeShift 3 == 0
        && lookupSizeShift 2000000000 == 0
        && lookupPlantVerdict 1 == 1 && lookupPlantVerdict 0 == 0
        && lookupPlantVerdict 2 == 0 && lookupPlantVerdict 77 == 0 }
  , { name := "cnseed: lookup wire (encodeSz/lookupExpected LE spot checks)"
    , pass := (encodeSz 1).map (·.toNat) == [1, 0, 0, 0]
        && (encodeSz 2000000000).map (·.toNat) == [0, 148, 53, 119]
        && (lookupExpected 1).map (·.toNat) == [8, 0, 0, 0]
        && (lookupExpected 77).map (·.toNat) == [0, 0, 0, 0] }
  , { name := "cnseed: lookup samples all LWf"
    , pass := lookupSamples.all lwfb && lookupSamples.length ≥ 12 }
  ]

/-- #eval-able one-shot: `#eval SpecLab.Test.allPass` (also the exe's
exit verdict). -/
def allChecks : List Check :=
  codecChecks ++ harnessChecks ++ divmodChecks ++ byteArrChecks
    ++ listAppendChecks ++ treeRotChecks ++ cnSeedChecks

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

/-- Model-bytes CSV: like `parseCsvBytes` but the empty string is the
empty model (n = 0 is a live memcpy instance; its STREAM `[0,0]` is
never empty — only the model list is). -/
def parseModelCsv (s : String) : Option (List UInt8) :=
  if s.isEmpty then some [] else parseCsvBytes s

def csvOfBytes (bs : List UInt8) : String :=
  String.intercalate "," (bs.map (fun b => toString b.toNat))

open SpecLab.ByteArr in
/-- The R2 byte-blaster emitter arms (memcpy + getarr). Returns
(harness text, predicted verdict) or an error. -/
def emitByteArr (mode : String) (csv : String) :
    Except String (String × String) := do
  match mode with
  | "memcpy" =>
    let some bs := parseModelCsv csv | throw s!"bad byte list: {csv}"
    if !wfb bs then throw s!"model not Wf (length {bs.length} > 16)"
    pure (mkMemcpy bs, "Specified(0)")
  | "memcpy-plant" =>
    let some bs := parseModelCsv csv | throw s!"bad byte list: {csv}"
    if !wfb bs then throw s!"model not Wf (length {bs.length} > 16)"
    pure (mkMemcpyPlant bs, s!"Specified({plantVerdict bs})")
  | "memcpy-stream" =>
    let some s := parseCsvBytes csv | throw s!"bad byte list: {csv}"
    if !validStreamb s then throw "INVALID stream (prefix/capacity)"
    pure (mkMemcpyOfStream s, "Specified(0)")
  | "memcpy-raw" =>
    -- NO validity check (the malformed lane); nonempty splice only
    -- (empty C initializers are invalid pre-C23)
    let some s := parseCsvBytes csv | throw s!"bad byte list: {csv}"
    if s.isEmpty then throw "raw stream must be nonempty"
    pure (mkMemcpyOfStream s,
      if validStreamb s then "Specified(0)" else "Specified(254)")
  | "getarr" =>
    let some bs := parseModelCsv csv | throw s!"bad byte list: {csv}"
    if !gwfb bs then throw s!"model not GWf (length {bs.length} ≠ 10)"
    pure (mkGetarr bs, "Specified(0)")
  | "getarr-plant" =>
    let some bs := parseModelCsv csv | throw s!"bad byte list: {csv}"
    if !gwfb bs then throw s!"model not GWf (length {bs.length} ≠ 10)"
    pure (mkGetarrPlant bs, s!"Specified({getarrPlantVerdict bs})")
  | "getarr-raw" =>
    let some s := parseCsvBytes csv | throw s!"bad byte list: {csv}"
    if s.isEmpty then throw "raw stream must be nonempty"
    pure (mkGetarrOfStream s,
      if gwfb s then "Specified(0)" else "Specified(254)")
  | _ => throw s!"unknown bytearr mode: {mode}"

/-- Parse a comma-separated Int list ("1,-2,3"; "" = empty). -/
def parseCsvInts (s : String) : Option (List Int) :=
  if s.isEmpty then some [] else
  (s.splitOn ",").foldr (fun tok acc => do
    let ns ← acc
    let n ← tok.trimAscii.toString.toInt?
    some (n :: ns)) (some [])

/-- Parse the R3 pair-model CSV: `xs|ys` (each side comma-separated
ints, empty side = empty list; "1,2|3"). -/
def parsePairCsv (s : String) : Option SpecLab.ListAppend.Input :=
  match s.splitOn "|" with
  | [xs, ys] => do
    let l1 ← parseCsvInts xs
    let l2 ← parseCsvInts ys
    some ⟨l1, l2⟩
  | _ => none

/-- Parse the pointer-selection CSV: `k|xs|ys`. -/
def parseAtCsv (s : String) : Option SpecLab.ListAppend.AtInput :=
  match s.splitOn "|" with
  | [ks, xs, ys] => do
    let k ← ks.trimAscii.toString.toNat?
    let l1 ← parseCsvInts xs
    let l2 ← parseCsvInts ys
    some ⟨k, l1, l2⟩
  | _ => none

def pairCsvOf (m : SpecLab.ListAppend.Input) : String :=
  String.intercalate "," (m.xs.map toString) ++ "|"
    ++ String.intercalate "," (m.ys.map toString)

def atCsvOf (m : SpecLab.ListAppend.AtInput) : String :=
  s!"{m.k}|" ++ String.intercalate "," (m.xs.map toString) ++ "|"
    ++ String.intercalate "," (m.ys.map toString)

open SpecLab.ListAppend in
/-- The R3 linked-list emitter arms. Returns (harness text, predicted
verdict) or an error. -/
def emitList (mode : String) (csv : String) :
    Except String (String × String) := do
  let getPair : Except String SpecLab.ListAppend.Input := do
    let some m := parsePairCsv csv | throw s!"bad pair csv: {csv}"
    if !wfb m then throw s!"model not Wf (caps 8/8, i32 heads)"
    pure m
  match mode with
  | "append" =>
    let m ← getPair
    pure (mkAppend m, "Specified(0)")
  | "append-link-plant" =>
    let m ← getPair
    pure (mkAppendLinkPlant m, s!"Specified({linkPlantVerdict m})")
  | "append-elem-plant" =>
    let m ← getPair
    pure (mkAppendElemPlant m, s!"Specified({elemPlantVerdict m})")
  | "append-form2" =>
    let m ← getPair
    pure (mkAppendForm2 m, "Specified(0)")
  | "build-only" =>
    let m ← getPair
    pure (mkBuildOnly m, "Specified(0)")
  | "append-stream" =>
    let some s := parseCsvBytes csv | throw s!"bad byte list: {csv}"
    if !validStreamb s then throw "INVALID stream (prefix/cap/range)"
    pure (mkAppendOfStream s, "Specified(0)")
  | "append-raw" =>
    -- NO validity check (the malformed lane); nonempty splice only
    let some s := parseCsvBytes csv | throw s!"bad byte list: {csv}"
    if s.isEmpty then throw "raw stream must be nonempty"
    pure (mkAppendOfStream s,
      if validStreamb s then "Specified(0)" else "Specified(254)")
  | "append-at" =>
    let some m := parseAtCsv csv | throw s!"bad at csv (k|xs|ys): {csv}"
    if !atWfb m then throw "model not AtWf (k < |xs|, caps 8/8)"
    pure (mkAppendAt m, "Specified(0)")
  | _ => throw s!"unknown list mode: {mode}"

open SpecLab.ListAppend in
/-- Predicted Form 2 stdout for the append harness (healthy target),
batch-escaped spelling. -/
def predictListForm2Stdout (m : SpecLab.ListAppend.Input) : String :=
  SpecLab.DivMod.render3 (expectedBytes m) ++ "\\n"

open SpecLab.TreeRot in
/-- The R4 tree-rotation emitter arms. Returns (harness text,
predicted verdict) or an error. -/
def emitTree (mode : String) (arg : String) :
    Except String (String × String) := do
  let getM : Except String SpecLab.TreeRot.Input := do
    let some m := parseTreeArg arg | throw s!"bad tree arg (TREE|PATH): {arg}"
    if !wfb m then throw "model not Wf (≤ 31 nodes, i32 vals, path ≤ 8)"
    pure m
  match mode with
  | "rotate" =>
    let m ← getM
    pure (mkRotate m, "Specified(0)")
  | "rotate-swap-plant" =>
    let m ← getM
    pure (mkRotateSwapPlant m, s!"Specified({swapPlantVerdict m})")
  | "rotate-drop-plant" =>
    let m ← getM
    pure (mkRotateDropPlant m, s!"Specified({dropPlantVerdict m})")
  | "rotate-form2" =>
    let m ← getM
    pure (mkRotateForm2 m, "Specified(0)")
  | "build-only" =>
    let m ← getM
    pure (mkBuildOnly m, "Specified(0)")
  | "rotate-stream" =>
    let some s := parseCsvBytes arg | throw s!"bad byte list: {arg}"
    if !validStreamb s then throw "INVALID stream (scan/path/cap)"
    pure (mkRotateOfStream s, "Specified(0)")
  | "rotate-raw" =>
    -- NO validity check (the malformed lane); nonempty splice only
    let some s := parseCsvBytes arg | throw s!"bad byte list: {arg}"
    if s.isEmpty then throw "raw stream must be nonempty"
    pure (mkRotateOfStream s,
      if validStreamb s then "Specified(0)" else "Specified(254)")
  | _ => throw s!"unknown tree mode: {mode}"

open SpecLab.TreeRot in
/-- Predicted Form 2 stdout for the rotate harness (healthy target),
batch-escaped spelling. -/
def predictTreeForm2Stdout (m : SpecLab.TreeRot.Input) : String :=
  SpecLab.DivMod.render3 (expectedBytes m) ++ "\\n"

/-- Parse a u64 decimal CLI argument. -/
def parseU64 (s : String) : Option UInt64 := do
  let n ← s.toNat?
  if n < 18446744073709551616 then some (UInt64.ofNat n) else none

open SpecLab.CnSeed in
/-- The R5 CN-seed emitter arms (swap_pair: arg = "A B" u64 decimals
via two CLI args folded into one csv "A,B"; lookup: arg = sz).
Returns (harness text, predicted verdict) or an error. -/
def emitSeed (mode : String) (arg : String) :
    Except String (String × String) := do
  let getPair : Except String SpecLab.CnSeed.PairInput := do
    match arg.splitOn "," with
    | [as, bs] =>
      let some a := parseU64 as.trimAscii.toString | throw s!"bad u64: {as}"
      let some b := parseU64 bs.trimAscii.toString | throw s!"bad u64: {bs}"
      pure ⟨a, b⟩
    | _ => throw s!"bad pair arg (A,B): {arg}"
  let getSz : Except String Int := do
    let some n := arg.toNat? | throw s!"bad sz: {arg}"
    if !lwfb (n : Int) then throw s!"sz {n} not LWf (< 2^31)" else
    pure (n : Int)
  match mode with
  | "swap" =>
    let m ← getPair
    pure (mkSwap m, "Specified(0)")
  | "swap-plant" =>
    let m ← getPair
    pure (mkSwapPlant m, s!"Specified({swapPlantVerdict m})")
  | "swap-stream" =>
    let some s := parseCsvBytes arg | throw s!"bad byte list: {arg}"
    if !validStreamb s then throw "INVALID stream (not 16 bytes)"
    pure (mkSwapOfStream s, "Specified(0)")
  | "swap-raw" =>
    -- NO validity check (the malformed lane); nonempty splice only
    let some s := parseCsvBytes arg | throw s!"bad byte list: {arg}"
    if s.isEmpty then throw "raw stream must be nonempty"
    pure (mkSwapOfStream s,
      if validStreamb s then "Specified(0)" else "Specified(254)")
  | "lookup" =>
    let sz ← getSz
    pure (mkLookup sz, "Specified(0)")
  | "lookup-plant" =>
    let sz ← getSz
    pure (mkLookupPlant sz, s!"Specified({lookupPlantVerdict sz})")
  | "lookup-raw" =>
    let some s := parseCsvBytes arg | throw s!"bad byte list: {arg}"
    if s.isEmpty then throw "raw stream must be nonempty"
    pure (mkLookupOfStream s,
      match Codec.decodeU32LE s with
      | some (u, []) =>
        if u.toNat < 2147483648 then "Specified(0)" else "Specified(254)"
      | _ => "Specified(254)")
  | _ => throw s!"unknown seed mode: {mode}"

def main (args : List String) : IO UInt32 := do
  match args with
  | ["--emit-seed", mode, arg] =>
    match emitSeed mode arg with
    | .ok (h, _) => IO.print h; return 0
    | .error e => IO.eprintln s!"SpecLabTest: {e}"; return 2
  | ["--seed-predict", mode, arg] =>
    match emitSeed mode arg with
    | .ok (_, v) => IO.println v; return 0
    | .error e => IO.eprintln s!"SpecLabTest: {e}"; return 2
  | ["--seed-swap-samples"] =>
    for m in SpecLab.CnSeed.swapSamples do
      IO.println s!"{m.a},{m.b}"
    return 0
  | ["--seed-lookup-samples"] =>
    for sz in SpecLab.CnSeed.lookupSamples do
      IO.println s!"{sz}"
    return 0
  | ["--emit-tree", mode, arg] =>
    match emitTree mode arg with
    | .ok (h, _) => IO.print h; return 0
    | .error e => IO.eprintln s!"SpecLabTest: {e}"; return 2
  | ["--tree-predict", mode, arg] =>
    match emitTree mode arg with
    | .ok (_, v) =>
      IO.println v
      if mode == "rotate-form2" then
        match parseTreeArg arg with
        | some m => IO.println (predictTreeForm2Stdout m)
        | none => pure ()
      return 0
    | .error e => IO.eprintln s!"SpecLabTest: {e}"; return 2
  | ["--tree-samples"] =>
    for m in SpecLab.TreeRot.sweepSamples do
      IO.println (treeArgOf m)
    return 0
  | ["--emit-list", mode, csv] =>
    match emitList mode csv with
    | .ok (h, _) => IO.print h; return 0
    | .error e => IO.eprintln s!"SpecLabTest: {e}"; return 2
  | ["--list-predict", mode, csv] =>
    match emitList mode csv with
    | .ok (_, v) =>
      IO.println v
      if mode == "append-form2" then
        match parsePairCsv csv with
        | some m => IO.println (predictListForm2Stdout m)
        | none => pure ()
      return 0
    | .error e => IO.eprintln s!"SpecLabTest: {e}"; return 2
  | ["--list-samples"] =>
    for m in SpecLab.ListAppend.sweepSamples do
      IO.println (pairCsvOf m)
    return 0
  | ["--list-at-samples"] =>
    for m in SpecLab.ListAppend.atSamples do
      IO.println (atCsvOf m)
    return 0
  | ["--emit-bytearr", mode, csv] =>
    match emitByteArr mode csv with
    | .ok (h, _) => IO.print h; return 0
    | .error e => IO.eprintln s!"SpecLabTest: {e}"; return 2
  | ["--bytearr-predict", mode, csv] =>
    match emitByteArr mode csv with
    | .ok (_, v) => IO.println v; return 0
    | .error e => IO.eprintln s!"SpecLabTest: {e}"; return 2
  | ["--bytearr-samples"] =>
    -- memcpy sweep sample STREAMS (2+n bytes each — never empty)
    for bs in SpecLab.ByteArr.sweepSamples do
      IO.println (csvOfBytes (SpecLab.ByteArr.encodeInput bs))
    return 0
  | ["--getarr-samples"] =>
    for bs in SpecLab.ByteArr.getarrSamples do
      IO.println (csvOfBytes bs)
    return 0
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
