from pathlib import Path

out = Path(__file__).resolve().parent / 'core-probes'
out.mkdir(exist_ok=True)
cases = {
    'tray45': '''proc main (): eff loaded integer :=
  case (1, 2, 3) of
    | (a: integer, b: integer) => pure (Specified (a + b))
    | _: (integer, integer, integer) => pure (Specified (0))
  end
''',
    'long-pattern': '''proc main (): eff loaded integer :=
  case (1, 2) of
    | (a: integer, b: integer, c: integer) => pure (Specified (a + b))
    | _: (integer, integer) => pure (Specified (0))
  end
''',
    'nested-mismatch': '''proc main (): eff loaded integer :=
  case ((1, 2, 3), 4) of
    | ((a: integer, b: integer), c: integer) => pure (Specified (a + b + c))
    | _: ((integer, integer, integer), integer) => pure (Specified (0))
  end
''',
    'fitting': '''proc main (): eff loaded integer :=
  case (1, 2) of
    | (a: integer, b: integer) => pure (Specified (a + b))
    | _: (integer, integer) => pure (Specified (0))
  end
''',
    'pure-case': '''proc main (): eff loaded integer :=
  pure (Specified (case (1, 2, 3) of
    | (a: integer, b: integer) => a + b
    | _: (integer, integer, integer) => 0
  end))
''',
    'no-match': '''proc main (): eff loaded integer :=
  case (1, 2, 3) of
    | (a: integer, b: integer) => pure (Specified (a + b))
  end
''',
    'let-mismatch': '''proc main (): eff loaded integer :=
  let (a: integer, b: integer) = (1, 2, 3) in
    pure (Specified (a + b))
''',
    'pure-let-mismatch': '''proc main (): eff loaded integer :=
  pure (Specified (let (a: integer, b: integer) = (1, 2, 3) in a + b))
''',
    'let-nested-mismatch': '''proc main (): eff loaded integer :=
  let ((a: integer, b: integer), c: integer) = ((1, 2, 3), 4) in
    pure (Specified (a + b + c))
''',
}
for kind in ['weak', 'strong']:
    cases['seq-' + kind + '-mismatch'] = 'proc main (): eff loaded integer :=\n  let ' + kind + ' (a: integer, b: integer) = pure (1, 2, 3) in\n    pure (Specified (a + b))\n'
    cases['unseq-' + kind + '-mismatch'] = 'proc main (): eff loaded integer :=\n  let ' + kind + ' (a: integer, b: integer) = unseq(pure (1), pure (2), pure (3)) in\n    pure (Specified (a + b))\n'
for name, source in cases.items():
    (out / (name + '.core')).write_text(source)
print('prepared', len(cases), 'Core inputs')
