import CerbMem
-- AFTER H1: the orchestrator's two identities must FAIL by rfl (no equation for an opaque leaf)
example : CerbMem.combineProv (.Prov_symbolic 0) .Prov_none = .Prov_none := rfl
example : CerbMem.bytesToInt [] false = none := rfl
-- tactic-mode forms (candidate #guard_msgs texts)
example : CerbMem.combineProv (.Prov_symbolic 0) .Prov_none = .Prov_none := by rfl
example : CerbMem.bytesToInt [] false = none := by rfl
-- positive controls: a default arm still reduces
example : CerbMem.combineProv .Prov_none .Prov_none = .Prov_none := rfl
example : CerbMem.combineProv .Prov_device .Prov_none = .Prov_device := rfl
