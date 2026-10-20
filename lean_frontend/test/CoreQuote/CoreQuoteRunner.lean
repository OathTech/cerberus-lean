import Unit.CoreQuoteTest

/- Executable launcher, separate so the checker can also import Main. -/

def main (args : List String) : IO UInt32 := do
  match args with
  | ["--emit-control", name, path] => CoreQuoteTest.emitControl name path; return 0
  | ["--local-controls"] => CoreQuoteTest.localControls; return 0
  | _ =>
    let cwd ← IO.currentDir
    let root := if (← (cwd / "lean_frontend/lakefile.toml").pathExists) then cwd else cwd.parent.getD cwd
    let script := (root / "lean_frontend/test/CoreQuote/CoreQuoteRoundTrip.py").toString
    let child ← IO.Process.spawn { cmd := "python3", args := (#[script] ++ args.toArray), cwd := some root }
    child.wait
