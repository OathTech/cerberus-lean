import CerbMem
-- the orchestrator's two probes (charter §1): BEFORE H1 both compile by rfl
example : CerbMem.combineProv (.Prov_symbolic 0) .Prov_none = .Prov_none := rfl
example : CerbMem.bytesToInt [] false = none := rfl
