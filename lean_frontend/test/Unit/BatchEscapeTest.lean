import CerbEscape
import CerbFail

/-! Byte/text boundary tests, imported and run by pp-test. The all-byte
expected string is OCaml 5.4.0 `String.escaped (String.init 256 Char.chr)`,
recorded 2026-09-09. No decoder implementation supplies that expected value. -/
namespace BatchEscapeTest

def allBytes : ByteArray := ⟨(List.range 256).toArray.map UInt8.ofNat⟩
def allByteChars : String := String.ofList ((List.range 256).map Char.ofNat)

def oracleAllBytes : String := "\\000\\001\\002\\003\\004\\005\\006\\007\\b\\t\\n\\011\\012\\r\\014\\015\\016\\017\\018\\019\\020\\021\\022\\023\\024\\025\\026\\027\\028\\029\\030\\031 !\\\"#$%&'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\\\]^_`abcdefghijklmnopqrstuvwxyz{|}~\\127\\128\\129\\130\\131\\132\\133\\134\\135\\136\\137\\138\\139\\140\\141\\142\\143\\144\\145\\146\\147\\148\\149\\150\\151\\152\\153\\154\\155\\156\\157\\158\\159\\160\\161\\162\\163\\164\\165\\166\\167\\168\\169\\170\\171\\172\\173\\174\\175\\176\\177\\178\\179\\180\\181\\182\\183\\184\\185\\186\\187\\188\\189\\190\\191\\192\\193\\194\\195\\196\\197\\198\\199\\200\\201\\202\\203\\204\\205\\206\\207\\208\\209\\210\\211\\212\\213\\214\\215\\216\\217\\218\\219\\220\\221\\222\\223\\224\\225\\226\\227\\228\\229\\230\\231\\232\\233\\234\\235\\236\\237\\238\\239\\240\\241\\242\\243\\244\\245\\246\\247\\248\\249\\250\\251\\252\\253\\254\\255"

-- Kernel witnesses distinguish a single FF byte from Unicode U+00FF.
example : CerbEscape.byteChars "ÿ" = "\\255" := by
  rw [CerbEscape.byteChars, String.foldl_eq_foldl_toList]
  decide
example : CerbEscape.text "ÿ" = "\\195\\191" := by decide
example : CerbEscape.text "éλ😀" = "\\195\\169\\206\\187\\240\\159\\152\\128" := by decide
example : CerbEscape.bytes ⟨#[0, 128, 195, 169, 255]⟩ = "\\000\\128\\195\\169\\255" := by decide

def checks : List (String × Bool) := [
  ("all 256 bytes match OCaml", CerbEscape.bytes allBytes == oracleAllBytes),
  ("all 256 byte carriers match OCaml", CerbEscape.byteChars allByteChars == oracleAllBytes),
  ("empty bytes", CerbEscape.bytes ⟨#[]⟩ == ""),
  ("empty byte carriers", CerbEscape.byteChars "" == ""),
  ("empty text", CerbEscape.text "" == ""),
  ("text controls and delimiters", CerbEscape.text "\x00\x08\t\n\r\"\\" == "\\000\\b\\t\\n\\r\\\"\\\\"),
  ("UTF-8 sequence carried as bytes", CerbEscape.byteChars "Ã©" == "\\195\\169"),
  ("UTF-8 text", CerbEscape.text "éλ😀" == "\\195\\169\\206\\187\\240\\159\\152\\128"),
  ("model-failure text uses the same adapter", CerbFail.escapeMessage "éλ😀" ==
    "\\195\\169\\206\\187\\240\\159\\152\\128"),
  ("embedded verdict remains escaped payload", CerbEscape.text "Error {msg: \"x\"}\n" ==
    "Error {msg: \\\"x\\\"}\\n")]

def run : IO Bool := do
  let mut ok := true
  for (name, passed) in checks do
    IO.println s!"{if passed then "PASS" else "FAIL"} batch escaping: {name}"
    ok := ok && passed
  return ok

end BatchEscapeTest
