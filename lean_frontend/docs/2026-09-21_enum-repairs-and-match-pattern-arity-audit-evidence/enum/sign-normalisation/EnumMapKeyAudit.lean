import Implementation
namespace EnumMapKeyAudit
def k : sym := sym.Symbol "abc" 42 SD_None
def q : sym := sym.Symbol "abc" 42 (SD_Id "different-description")
def ed : Fmap sym integerType := Lem_Map.fromList [(k, .Unsigned .Int_)]
example : typeof_enum ed fmapEmpty q = .Unsigned .Int_ := rfl
example : is_signed_ity ed fmapEmpty (.Enum0 q) = false := rfl
example : CerberusImpl.lookupEnum ed q = .Unsigned .Int_ := rfl
end EnumMapKeyAudit
