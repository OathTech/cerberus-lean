import CerbMem
/-! memscale-micro — isolate the CerbMem byte-path primitives and time
    them (arc/mem-scale, 2026-09-01). Usage: memscale-micro <case> <N>.
    Prints `case\tN\tms`. Peak RSS is measured externally (/usr/bin/time
    -v) — for the `alloc`/`read` cases the resident bytemap of N bytes
    dominates, giving the per-byte resident cost of the representation.
    Instrument only; nothing here is part of the semantics. -/
open CerbMem

def unspecByte : AbsByte := { prov := .Prov_none, copyOffset := none, value := none }
def zeroByte : AbsByte := { prov := .Prov_none, copyOffset := none, value := some (0 : UInt8) }
def charArrTy (n : Nat) : ctype := Ctype [] (.Array0 unsigned_char (some (n : Int)))
def intArrTy (n : Nat) : ctype := Ctype [] (.Array0 signed_int (some (n : Int)))
def tagDefs : CerbTags.TagDefsMap := fmapEmpty
/-- Address base. `lo` = 0x1000 (keys fit Lean's small-Int range);
    `hi` = the concrete allocator's real region (lastAddress =
    0xFFFFFFFFFFFF, CerbMem.MemState) — 48-bit keys exceed Lean's
    small-Int bound (LEAN_MAX_SMALL_INT = 2^31-1 on 64-bit), so every
    bytemap key becomes a heap-allocated big integer. -/
def baseOf (n : Nat) : String → Int
  | "hi" => 0xFFFFFFFFFFFF - (n : Int) - 0x10000
  | _ => 0x1000

/-- Time `act` on `n`. Two guards against the compiler moving the pure
    computation out of the window: `nn` depends on `t0` (so `act nn`
    cannot be hoisted above the first clock read), and the result is
    printed to stderr BEFORE the second clock read (so it cannot be
    sunk below it). Pre-built inputs are forced by `force` before t0. -/
def timeIt (label : String) (n : Nat) (act : Nat → Nat) : IO Unit := do
  let t0 ← IO.monoMsNow
  let nn := if t0 == 0 then n + 1 else n
  let r := act nn
  IO.eprint s!"result={r} "
  let t1 ← IO.monoMsNow
  IO.println s!"{label}\t{n}\t{t1 - t0}\tresult={r}"

/-- Force a pre-built value before the timed region (its size is printed). -/
def force (k : Nat) : IO Unit := IO.eprint s!"prebuilt={k} "

def elemsLen : MemValue → Nat
  | .MVarray es => es.length
  | _ => 0

/-- Entry. fuel-parameter arc (2026-09-04): `memValueToBytes`/`reconstructValue`
    read the ambient `[LemFuel]`; this instrument takes it from its command
    line (`--fuel N`, REQUIRED, leading) — a caller's choice, never a numeral
    in the Lean text (scripts/check_no_fuel_numerals.sh scans tests/). -/
def main (args : List String) : IO UInt32 := do
  match args with
  | "--fuel" :: fStr :: rest =>
    match fStr.toNat? with
    | some f =>
      if f == 0 then IO.eprintln "memscale-micro: refused — --fuel 0 (positive integer required)"; return 2
      else
        match rest with
        | [c, nStr] => @run ⟨f⟩ c nStr.toNat! (baseOf nStr.toNat! "lo")
        | [c, nStr, "hi"] => @run ⟨f⟩ c nStr.toNat! (baseOf nStr.toNat! "hi")
        | _ => IO.eprintln "usage: memscale-micro --fuel <N> <case> <N> [hi]"; return 2
    | none => IO.eprintln s!"memscale-micro: refused — --fuel {fStr}: not a decimal numeral"; return 2
  | _ => IO.eprintln "usage: memscale-micro --fuel <N> <case> <N> [hi]  (the fuel is the caller's parameter; scripts pass $CERB_TEST_FUEL)"; return 2
where
  run [LemFuel] (c : String) (n : Nat) (base : Int) : IO UInt32 := do
    match c with
    -- allocation-time list: List.replicate n unspecified (allocateObject initOpt=none)
    | "replicate" => timeIt c n fun n => (List.replicate n unspecByte).length
    -- allocation: replicate + per-byte TreeMap insert (writeBytesTo)
    | "alloc" => timeIt c n fun n =>
        (writeBytesTo initialMemState base (List.replicate n unspecByte)).bytemap.size
    -- load side: per-byte TreeMap lookup (readBytesFrom) over a resident map
    | "read" =>
        let st := writeBytesTo initialMemState base (List.replicate n zeroByte)
        force st.bytemap.size
        timeIt c n fun n => (readBytesFrom st base n).length
    -- repr of an N-element char array of zeros (a_zero_global / b_zero_local)
    | "serialize_chararray" =>
        let mv := MemValue.MVarray (List.replicate n (.MVinteger (.Unsigned .Ichar) (.IV .Prov_none 0)))
        force (elemsLen mv)
        timeIt c n fun n => (memValueToBytes tagDefs [] mv).2.length
    -- abst of an N-byte char array (the by-value struct / array load path)
    | "reconstruct_chararray" =>
        let bytes := List.replicate n zeroByte
        force bytes.length
        timeIt c n fun n => elemsLen (reconstructValue tagDefs [] [] base (charArrTy n) bytes)
    -- abst of an N-byte int array (N/4 elements of 4 bytes)
    | "reconstruct_intarray" =>
        let bytes := List.replicate n zeroByte
        force bytes.length
        timeIt c n fun n => elemsLen (reconstructValue tagDefs [] [] base (intArrTy (n / 4)) bytes)
    -- bytesToInt over N bytes (one big integer; linear expected)
    | "bytesToInt" =>
        let bytes := List.replicate n zeroByte
        force bytes.length
        timeIt c n fun n => match bytesToInt bytes false with | some v => v.toNat % 251 | none => 0
    -- N single-byte stores at consecutive addresses (d_loop's map-update cost)
    | "store_loop" => timeIt c n fun n =>
        (Nat.fold n (fun i _ st => writeBytesTo st (base + i) [zeroByte]) initialMemState).bytemap.size
    -- N single-byte loads (readBytesFrom size 1) over a resident map
    | "load_loop" =>
        let st := writeBytesTo initialMemState base (List.replicate n zeroByte)
        force st.bytemap.size
        timeIt c n fun n => Nat.fold n (fun i _ acc => acc + (readBytesFrom st (base + i) 1).length) 0
    -- the whole by-value copy path: read N bytes, abst as char[N], repr, write back
    | "copy_chararray" =>
        let st := writeBytesTo initialMemState base (List.replicate n zeroByte)
        force st.bytemap.size
        timeIt c n fun n =>
          let bytes := readBytesFrom st base n
          let mv := reconstructValue tagDefs [] [] base (charArrTy n) bytes
          let (_, bs) := memValueToBytes tagDefs [] mv
          (writeBytesTo st (base + n) bs).bytemap.size
    | _ => IO.eprintln s!"unknown case {c}"; return 2
    return 0
