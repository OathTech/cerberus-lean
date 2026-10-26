#!/usr/bin/env python3
"""Matched-mode inner_arg_temps instrument, modelled on test_pnvi.sh.

The shared observation codec owns framing, exits and full verdict tokens.
AGREE is exhaustive; AGREE-FIRST is a single trace, outside CONTRACT §1.
BOTH_FAIL (one Error per engine, equal under failure-class, or two crashes)
and RESOURCE (oracle bound exceeded) are never agreement. Within a mode,
complete ordered engine sequences must match. The baseline pins distinct
complete tokens and failure/resource classes, not execution multiplicities.
Missing/extra/changed rows fail closed. DIFF and INVALID cannot be recorded.

The three main witnesses and every tests/libc_exec row run all four
engine/mode combinations. The oracle cross-mode sanity check compares SETS
of distinct complete observations, ignoring only order and multiplicity.
It is separate from the exact per-mode engine trust surface. Counts are
reported, never pinned. Fuzzing applies the same oracle cross-mode rule.

The mode probes inspect actual Core conventions, independently of verdicts
(which ought to agree across modes). The dump/mode plants test both directions.
Ordinary corpora are exhaustive/nolibc; libc mirrors test_libc_exec.sh:
single-trace top-level inputs and exhaustive/exhaustive inputs. Timeouts:
30 seconds ordinary, 300 libc; every subprocess is capped at 4G by default.
"""
from __future__ import annotations

import argparse
from collections import Counter
from dataclasses import dataclass
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys
import time

# Reuse the PNVI instrument's capture decoder, not its mode-specific refusal
# table or row classifier. Unexpected REFUSAL/CLI_REFUSAL are failures here.
from pnvi_lane import classify_side, is_single_error, side_hash


def same_failure(normal, inner):
    """Cross-mode equality of two FAILED side outcomes. Resource outcomes compare by
    CLASS only: whether the bound hit first is the memory cap (KILL) or the wall-clock
    limit (TIMEOUT) depends on box load, so the kind is informational (it stays in the
    per-row evidence). An Error pair compares by its failure-class token (only Symbol's
    numeric id may differ); everything else must be identical."""
    if normal[0] == 'RESOURCE' and inner[0] == 'RESOURCE':
        return True
    if is_single_error(normal) and is_single_error(inner):
        return normal[2] == inner[2]
    return normal == inner

ROOT = Path(__file__).resolve().parent.parent
SW = '--switches=inner_arg_temps'
RT = '--runtime=_build/install/default'
BASELINE = ROOT / 'tests/inner_arg_temps/baseline.json'


class Failure(RuntimeError):
    pass


def require(ok, message):
    if not ok:
        raise Failure(message)


@dataclass(frozen=True)
class Row:
    name: str
    source: Path
    mode: str = 'exhaustive'
    libc: bool = False
    args: tuple[str, ...] = ()
    expected: int | None = None


def population():
    rows = []
    for label, folder, pattern in [('minimal', 'tests/minimal', '*.c'),
                                   ('fixtures', 'tests/fixtures', '*/source.c'),
                                   ('corpus', 'lean_frontend/corpus', '*.c'),
                                   ('libc', 'tests/libc_exec', '*.c'),
                                   ('libc/exhaustive', 'tests/libc_exec/exhaustive', '*.c')]:
        paths = sorted((ROOT / folder).glob(pattern))
        require(paths, f'empty corpus: {folder}/{pattern}')
        for p in paths:
            name = p.parent.name if label == 'fixtures' else p.stem
            rows.append(Row(f'{label}/{name}', p.relative_to(ROOT),
                            'first' if label == 'libc' else 'exhaustive', label.startswith('libc')))
    for stem, args, value in [('main-args', ('--args', 'ab cd'), 0),
                              ('recursive-main', (), 7),
                              ('recursive-main-args', ('--args', 'ab cd'), 42)]:
        rows.append(Row('witness/' + stem, Path(f'tests/inner_arg_temps/{stem}.c'), args=args, expected=value))
    for stem in ['0343-subzero-floating-to-_Bool', '0344-ptr-to-_Bool-param']:
        rows.append(Row('upstream/' + stem, Path(f'tests/ci/{stem}.c'), 'first', True))
    require(len({r.name for r in rows}) == len(rows), 'duplicate population row')
    return rows


def classify(mode, oracle, lean):
    require(oracle[0] != 'INVALID' and lean[0] != 'INVALID', f'INVALID: oracle={oracle}; lean={lean}')
    if oracle[0] == 'RESOURCE':
        return 'RESOURCE oracle:' + oracle[1]
    require(lean[0] != 'RESOURCE', f'Lean {lean[1]} where oracle completed: {oracle[0]}')
    if is_single_error(oracle) and is_single_error(lean) and oracle[2] == lean[2]:
        return 'BOTH_FAIL'
    if oracle[0] == lean[0] == 'CRASH':
        return 'BOTH_FAIL'
    require(oracle[0] == lean[0] == 'OBS' and oracle[1] == lean[1],
            f'DIFF: oracle={oracle}; lean={lean}')
    return 'AGREE-FIRST' if mode == 'first' else 'AGREE'


def same_sequence(name, oracle, lean):
    require(oracle[0] == lean[0] == 'OBS' and oracle[1] == lean[1],
            f'{name}: matched-mode complete-sequence disagreement: {oracle} / {lean}')


def same_observation_set(name, normal, inner):
    require(normal[0] == inner[0] == 'OBS' and set(normal[1]) == set(inner[1]),
            f'{name}: oracle cross-mode observation-set disagreement or incomplete observation: {normal} / {inner}')


def baseline_hash(side):
    # Pin behaviours across revisions, not internal path enumeration. This
    # projection is NEVER used for the within-mode engine comparison.
    return side_hash(('OBS', tuple(sorted(set(side[1]))), ())) if side[0] == 'OBS' else side_hash(side)


def check_baseline(actual, path, selection=None):
    baseline = json.loads(path.read_text())
    require(isinstance(baseline, dict) and baseline, 'empty or malformed baseline')
    expected = {k: v for k, v in baseline.items() if selection is None or selection.search(k)}
    require(actual and expected, 'empty selection or baseline')
    require(actual.keys() == expected.keys(),
            f'baseline row set differs: missing={sorted(expected.keys()-actual.keys())}; new={sorted(actual.keys()-expected.keys())}')
    for name, value in actual.items():
        require(value == expected[name], f'{name}: baseline changed: {expected[name]} -> {value}')
    print(f'BASELINE OK (inner_arg_temps: {len(actual)} rows; classes and both distinct-observation/status hashes exact)', flush=True)


class Runner:
    def __init__(self, oracle, lean, out):
        self.oracle, self.lean, self.out = str(oracle), str(lean), Path(out)
        self.out.mkdir(parents=True, exist_ok=True)
        self.env = dict(os.environ, CERB_MEM_MAX=os.environ.get('CERB_TEST_MEM_MAX', '4G'),
                        LEAN_ABORT_ON_PANIC='1', NO_COLOR='1', TERM='dumb')
        self.metadata = None

    def capture(self, label, command, seconds=30, cwd=ROOT):
        prefix = self.out / label.replace('/', '__')
        require(not prefix.with_suffix(prefix.suffix + '.status').exists(), f'reused capture: {prefix}')
        cmd = [str(ROOT / 'scripts/capped'), 'timeout', f'{seconds}s', *map(str, command)]
        Path(str(prefix) + '.command').write_text(shlex.join(cmd) + '\n')
        Path(str(prefix) + '.capture-error').write_text('capture not completed\n')
        with Path(str(prefix) + '.stdout').open('wb') as stdout, Path(str(prefix) + '.stderr').open('wb') as stderr:
            p = subprocess.run(cmd, cwd=cwd, env=self.env, stdin=subprocess.DEVNULL, stdout=stdout, stderr=stderr)
        rc = p.returncode if p.returncode >= 0 else 128 - p.returncode
        Path(str(prefix) + '.status').write_text(str(rc) + '\n')
        Path(str(prefix) + '.capture-error').unlink()
        return str(prefix)

    def bridge(self, row):
        p = self.capture(row.name + '.bridge', [self.oracle, RT, '--nolibc', '--cabs-json', row.source])
        require(Path(p + '.status').read_text().strip() == '0', f'{row.name}: Cabs bridge failed')
        content = Path(p + '.stdout').read_bytes()
        json.loads(content)  # reject malformed/truncated output immediately
        target = self.out / (row.name.replace('/', '__') + '.json')
        target.write_bytes(content)
        return target

    def libc_args(self, switched):
        if self.metadata is None:
            p = self.capture('libc-metadata', [ROOT / 'scripts/libc_prep.sh', '--jsons', self.out / 'metadata'], 300)
            require(Path(p + '.status').read_text().strip() == '0', 'libc preparation failed')
            self.metadata = Path(p + '.stdout').read_text().splitlines()
            require(len(self.metadata) == 12 and all(Path(x).is_file() for x in self.metadata), 'expected twelve libc metadata TUs')
        dump = 'libc_inner_arg_temps.core' if switched else 'libc.core'
        args = ['--libc', str(ROOT / 'tests/libc' / dump)]
        for path in self.metadata:
            args += ['--libc-tu', path]
        return args

    def mode_probes(self):
        row = next(r for r in population() if r.name == 'witness/main-args')
        p = self.capture('mode.oracle', [self.oracle, RT, '--nolibc', SW, '--pp=core', row.source])
        core = Path(p + '.stdout').read_text()
        require(Path(p + '.status').read_text().strip() == '0' and
                re.search(r'proc main\s*\(argc_fav[0-9]+: loaded integer, argv_fav[0-9]+: loaded pointer\)', core),
                'oracle switch/convention probe failed (flag stripped or wrong calling convention)')
        js = self.bridge(Row('mode', row.source))
        quote = self.out / 'mode.lean'
        p = self.capture('mode.lean', [self.lean, RT, SW, '--quote-core', quote, js])
        require(Path(p + '.status').read_text().strip() == '0' and quote.is_file(), 'Lean mode quotation failed')
        text = quote.read_text()
        require('-- cerberus-lean switches: [inner_arg_temps]\n' in text and
                'calling_convention.Inner_arg_callconv' in text,
                'Lean switch/convention probe failed (flag stripped or wrong calling convention)')
        print('MODE OK (oracle loaded main parameters; Lean quoted Inner_arg_callconv and exact switch set)', flush=True)

    def dump_plants(self):
        row = Row('dump-plant', Path('tests/fixtures/001-return-literal/source.c'))
        js = self.bridge(row)
        for switched in [True, False]:
            p = self.capture('dump-plant.' + str(switched),
                             [self.lean, '--batch', RT, *([SW] if switched else []),
                              *self.libc_args(not switched), js], 300)
            require(Path(p + '.status').read_text().strip() == '2' and
                    b'cerberus-lean: refused' in Path(p + '.stderr').read_bytes() and
                    b'IncompatibleCallingConvention:' in Path(p + '.stderr').read_bytes() and
                    not Path(p + '.stdout').read_bytes(),
                    f'dump/mode mismatch did not refuse cleanly: switched={switched}')
        print('DUMP PLANTS OK (both incompatible dump/mode pairings refused, exit 2, no verdict)', flush=True)

    def transport_plants(self):
        """Exercise both fail-closed checks with real printer/loader inputs."""
        row = Row('binder-plant', Path('tests/fixtures/001-return-literal/source.c'))
        js = self.bridge(row)
        for switched in [False, True]:
            args = self.libc_args(switched)
            source = Path(args[1]).read_text()
            header = re.search(r'^proc exit \(([A-Za-z_][A-Za-z0-9_]*):[^\n]*\n', source, re.M)
            require(header is not None, 'binder plant: missing exit parameter')
            parameter = header[1]
            # Corrupt just the first typed body binder after exit's header.
            body = re.search(r'\b([A-Za-z_][A-Za-z0-9_]*):', source[header.end():])
            require(body is not None and body[1] != parameter, 'binder plant: missing distinct body binder')
            start, end = header.end() + body.start(1), header.end() + body.end(1)
            planted = self.out / f'binder-plant-{switched}.core'
            planted.write_text(source[:start] + parameter + source[end:])
            args[1] = str(planted)
            p = self.capture(f'binder-plant.{switched}',
                             [self.lean, '--batch', RT, *([SW] if switched else []), *args, js], 300)
            error = Path(p + '.stderr').read_text()
            require(Path(p + '.status').read_text().strip() == '2' and
                    f'R-IAT-LIBC-SYMBOL-LOSS: procedure exit binds parameter name {parameter} again' in error and
                    not Path(p + '.stdout').read_bytes(),
                    f'parameter-rebinding plant did not refuse cleanly: switched={switched}')
        print('PLANT OK (Normal and switched dump lines rebind a parameter -> named loader refusal)', flush=True)

        # Discover the actual fresh ID; a hard-coded suffix would silently stop
        # testing the collision when unrelated elaboration changes minting.
        source = self.out / 'printer-collision.c'
        control = 'int f(int x) { int x_fav0 = 1; return x + x_fav0; }\nint main(void) { return f(2); }\n'
        source.write_text(control)
        def pp(label, switched):
            return self.capture(label, [self.oracle, RT, '--nolibc', *([SW] if switched else []), '--pp=core', source])
        p = pp('printer-control', True)
        require(Path(p + '.status').read_text().strip() == '0', 'printer positive control failed')
        parameter = re.search(r'proc f\s*\((x_fav[0-9]+): loaded integer', Path(p + '.stdout').read_text())
        require(parameter is not None and parameter[1] != 'x_fav0', 'printer control: no distinct numbered parameter')
        source.write_text(control.replace('x_fav0', parameter[1]))
        p = pp('printer-collision', True)
        require(Path(p + '.status').read_text().strip() == '125' and
                f'Core printer symbol collision in procedure f: {parameter[1]}' in Path(p + '.stderr').read_text(),
                'printer collision plant did not stop with its named error')
        p = pp('printer-normal', False)
        require(Path(p + '.status').read_text().strip() == '0', 'Normal printer control failed')
        print('PLANT OK (measured argument spelling used as a bare local -> printer collision; Normal control passes)', flush=True)

    def row(self, row, cross=False):
        js = self.bridge(row)
        sides = {}
        libc_cross = row.name.startswith('libc/')
        four_way = row.expected is not None or libc_cross
        for switched in ([True, False] if four_way or cross else [True]):
            suffix = 'inner' if switched else 'normal'
            sw = [SW] if switched else []
            ocmd = [self.oracle, RT, *([] if row.libc else ['--nolibc']), '--exec', '--batch',
                    *(['--mode=exhaustive'] if row.mode == 'exhaustive' else []), *sw, *row.args, row.source]
            lcmd = [self.lean, '--batch', *(['--first'] if row.mode == 'first' else []), RT, *sw,
                    *(self.libc_args(switched) if row.libc else []), *row.args, js]
            for engine, cmd in [('oracle', ocmd), ('lean', lcmd)]:
                # Fuzz cross-mode leg needs only the Normal oracle; witnesses need all four.
                if cross and not switched and not four_way and engine == 'lean':
                    continue
                p = self.capture(f'{row.name}.{suffix}.{engine}', cmd, 300 if row.libc else 30)
                sides[suffix, engine] = classify_side(p, engine == 'lean')
                if engine == 'lean' and sides[suffix, engine][0] == 'OBS':
                    report = b'cerberus-lean switches: ' + (b'[inner_arg_temps]' if switched else b'[]')
                    require(Path(p + '.stderr').read_bytes().splitlines().count(report) == 1,
                            f'{row.name}: missing/duplicate Lean switch report')
        oracle, lean = sides['inner', 'oracle'], sides['inner', 'lean']
        cls = classify(row.mode, oracle, lean)
        normal_status = None
        if cls == 'BOTH_FAIL' or cls.startswith('RESOURCE'):
            # A new switched failure must not acquire a baseline merely because
            # both engines fail. Re-run both Normal controls at the same limits.
            # (The cross-mode comparison of two failures is `same_failure`.)
            for engine, cmd in [('oracle', [self.oracle, RT, *([] if row.libc else ['--nolibc']),
                                            '--exec', '--batch', *(['--mode=exhaustive'] if row.mode == 'exhaustive' else []),
                                            *row.args, row.source]),
                                ('lean', [self.lean, '--batch', *(['--first'] if row.mode == 'first' else []),
                                          RT, *(self.libc_args(False) if row.libc else []), *row.args, js])]:
                if ('normal', engine) not in sides:
                    p = self.capture(f'{row.name}.normal.{engine}', cmd, 300 if row.libc else 30)
                    sides['normal', engine] = classify_side(p, engine == 'lean')
                normal, inner = sides['normal', engine], sides['inner', engine]
                # The existing failure-class contract permits only Symbol's
                # numeric ID to differ in an Error. Both complete token streams
                # remain separately hash-pinned; no error text is rewritten.
                require(same_failure(normal, inner),
                        f'{row.name}: failure differs from Normal on {engine}: {normal} / {inner}')
            normal_status = {'class': classify(row.mode, sides['normal', 'oracle'], sides['normal', 'lean']),
                             'oracle': side_hash(sides['normal', 'oracle']), 'lean': side_hash(sides['normal', 'lean'])}
        if row.libc and row.mode == 'exhaustive':
            require(cls == 'AGREE' and len(oracle[1]) >= 2,
                    f'{row.name}: exhaustive libc control has fewer than two complete observations')
        if four_way:
            # This gate keeps order and multiplicity, independently in each mode.
            for mode in ['inner', 'normal']:
                same_sequence(f'{row.name} ({mode})', sides[mode, 'oracle'], sides[mode, 'lean'])
        if four_way or cross:
            normal = sides['normal', 'oracle']
            same_observation_set(row.name, normal, oracle)
            print(f'  CROSS-MODE SET OK {row.name}: distinct={len(set(oracle[1]))} '
                  f'Normal={len(normal[1])} inner_arg_temps={len(oracle[1])} observations (counts informational)', flush=True)
        if row.expected is not None:
            token = f'VAL:{{value: "Specified({row.expected})", stdout: "", stderr: "", blocked: "false"}}'
            require(set(oracle[1]) == {token}, f'{row.name}: expected witness observation differs: {oracle}')
        if row.name.startswith('upstream/'):
            expected_text = (ROOT / 'tests/ci/expected' / (row.source.name + '.expected')).read_bytes()
            import observations
            p = str(self.out / (row.name.replace('/', '__') + '.inner.oracle'))
            parsed = observations.parse(Path(p+'.stdout').read_bytes(), Path(p+'.stderr').read_bytes(),
                                        int(Path(p+'.status').read_text()), 'batch')
            expected = observations.parse(expected_text, b'', 0, 'batch')
            require(cls == 'AGREE-FIRST' and parsed.tokens('full') == expected.tokens('full'),
                    f'{row.name}: upstream expected verdict differs')
        print(f'  {cls:25} {row.name}' + (' cross-mode=SAME_SET' if four_way or cross else ''), flush=True)
        return {'class': cls, 'mode': row.mode, 'oracle': baseline_hash(oracle), 'lean': baseline_hash(lean),
                **({'normal_status': normal_status} if normal_status is not None else {}),
                **({'cross_mode': 'SAME_SET'} if four_way or cross else {}),
                **({'normal_baseline': 'tests/libc_exec/baseline.txt:38 (039-strerror-assert MATCH)'}
                   if row.name == 'libc/039-strerror-assert' else {})}

    def run(self, rows, cross=False):
        require(rows, 'empty selection')
        self.mode_probes()
        self.dump_plants()
        results, errors = {}, []
        for row in rows:
            try:
                results[row.name] = self.row(row, cross)
            except (Failure, OSError, ValueError) as exc:
                errors.append(row.name)
                print(f'  FAIL {row.name}: {exc}', flush=True)
        (self.out / 'results.json').write_text(json.dumps(results, indent=2, sort_keys=True) + '\n')
        print('SUMMARY: inner_arg_temps rows=' + str(len(rows)) + ' ' +
              ' '.join(f'{k}={v}' for k, v in sorted(Counter(r['class'] for r in results.values()).items())) +
              f' failures={len(errors)}', flush=True)
        require(not errors, f'failed rows: {errors}')
        require(any(r['class'].startswith('AGREE') for r in results.values()), 'zero semantic comparisons')
        return results


def selftest(args):
    selection = re.compile(r'^witness/|^libc/(002-puts|039-strerror-assert)$')
    rows = [r for r in population() if selection.search(r.name)]
    control = Runner(args.oracle, args.lean, args.out / 'control')
    actual = control.run(rows)
    check_baseline(actual, args.baseline, selection)
    print('SELFTEST CONTROL OK', flush=True)
    control.transport_plants()
    # Real engine wrappers like test_pnvi.sh: strip the actual command-line
    # switch, not the instrument's expected result. Each convention probe must fail.
    for engine in ['oracle', 'lean']:
        real = getattr(args, engine)
        stub = args.out / (engine + '-strip.py')
        stub.write_text('#!/usr/bin/env python3\nimport os,sys\nreal=' + repr(str(real)) +
                        '\nos.execv(real, [real] + [a for a in sys.argv[1:] if not a.startswith("--switches")])\n')
        stub.chmod(0o755)
        print(f'PLANT MODE: {engine} switch stripped; not semantic evidence', flush=True)
        runner = Runner(stub if engine == 'oracle' else args.oracle,
                        stub if engine == 'lean' else args.lean, args.out / (engine + '-strip'))
        try:
            runner.mode_probes()
        except Failure as exc:
            require(f'{engine if engine == "oracle" else "Lean"} switch/convention probe failed' in str(exc),
                    f'wrong switch-strip failure: {exc}')
            print(f'PLANT OK ({engine} switch stripped -> {exc})', flush=True)
        else:
            raise Failure(f'{engine} switch stripping was accepted')
    stub = args.out / 'normal-lean-change.py'
    stub.write_text('#!/usr/bin/env python3\nimport subprocess,sys\nreal=' + repr(str(args.lean)) +
                    '\np=subprocess.run([real]+sys.argv[1:],capture_output=True)\n'
                    'out=p.stdout\nif "--switches=inner_arg_temps" not in sys.argv:\n'
                    '    out=out.replace(b"Specified(42)",b"Specified(43)").replace(b"Specified(7)",b"Specified(8)")\n'
                    'sys.stdout.buffer.write(out)\nsys.stderr.buffer.write(p.stderr)\n'
                    'sys.exit(p.returncode if p.returncode>=0 else 128-p.returncode)\n')
    stub.chmod(0o755)
    runner = Runner(args.oracle, stub, args.out / 'normal-lean-change')
    for name, message in [('witness/recursive-main-args', 'matched-mode complete-sequence disagreement'),
                          ('libc/002-puts', 'matched-mode complete-sequence disagreement')]:
        try:
            runner.row(next(r for r in rows if r.name == name))
        except Failure as exc:
            require(message in str(exc), f'wrong cross-mode failure: {exc}')
            print(f'PLANT OK (Normal-only Lean result changed -> {message})', flush=True)
        else:
            raise Failure(f'Normal-only Lean change was accepted: {name}')
    # Different paths may repeat or reorder the same complete observations
    # across conventions. Neither change is allowed between engines in a mode.
    tokens = tuple('VAL:' + json.dumps({'value': 'Specified(1)', 'stdout': output,
                   'stderr': '', 'blocked': 'false'}) for output in ['a', 'b'])
    normal = ('OBS', tokens * 3, ())
    inner = ('OBS', tuple(reversed(tokens)), ())
    same_observation_set('multiplicity/order control', normal, inner)
    require(baseline_hash(normal) == baseline_hash(inner), 'baseline accidentally pins multiplicity/order')
    for changed in [('OBS', tuple(reversed(normal[1])), ()), ('OBS', tokens * 2, ())]:
        try:
            same_sequence('sequence plant', normal, changed)
        except Failure:
            pass
        else:
            raise Failure('matched-mode sequence mutation was accepted')
    for field, value in [('value', 'Specified(2)'), ('stdout', 'changed'),
                         ('stderr', 'changed'), ('blocked', 'true')]:
        payload = json.loads(tokens[0][4:]); payload[field] = value
        changed = ('OBS', ('VAL:' + json.dumps(payload), tokens[1]), ())
        try:
            same_observation_set('field plant ' + field, normal, changed)
        except Failure:
            pass
        else:
            raise Failure(f'cross-mode {field} mutation was accepted')
    print('PLANT OK (cross-mode duplication/order accepted; per-mode sequence changes and four observation-field changes rejected)', flush=True)
    # Exercise the real baseline comparator with captured controls, no reruns.
    for kind in ['deleted', 'phantom', 'hash', 'class', 'cross-mode']:
        mutated = json.loads(json.dumps(actual)); key = next(iter(mutated))
        if kind == 'deleted': del mutated[key]
        elif kind == 'phantom': mutated['witness/phantom'] = mutated[key]
        elif kind == 'hash': mutated[key]['oracle'] = '0' * 12
        elif kind == 'class': mutated[key]['class'] = 'BOTH_FAIL'
        else: mutated[key]['cross_mode'] = 'DIFF'
        path = args.out / (kind + '.json'); path.write_text(json.dumps(mutated))
        try:
            check_baseline(actual, path, selection)
        except Failure:
            print(f'PLANT OK (baseline {kind} rejected)', flush=True)
        else:
            raise Failure(f'baseline {kind} plant accepted')
    require(same_failure(('RESOURCE', 'KILL'), ('RESOURCE', 'TIMEOUT')),
            'cross-mode: two resource outcomes of different kinds must compare equal by class')
    require(not same_failure(('RESOURCE', 'KILL'), ('OBS', ('VAL:one',), ())),
            'cross-mode: a resource outcome must not equal an observation')
    for o, l in [(('OBS', ('VAL:one',), ()), ('OBS', ('VAL:two',), ())),
                 (('OBS', ('VAL:one',), ()), ('RESOURCE', 'TIMEOUT')),
                 (('INVALID', 'truncated'), ('INVALID', 'truncated')),
                 (('OBS', ('VAL:one',), ()), ('CLI_REFUSAL', 'refuse all'))]:
        try:
            classify('exhaustive', o, l)
        except Failure:
            pass
        else:
            raise Failure(f'bad outcome pair accepted: {o} / {l}')
    print('SELFTEST OK (control; both stripped-switch stubs; Normal-only main/libc mutations; both dump/mode plants; both binder plants; printer collision; sequence/set controls; five baseline plants; outcome failures)', flush=True)


def fuzz(args):
    """Reproducible Csmith measurement; no baseline and no silent skips."""
    require(args.fuzz > 0, '--fuzz count must be positive')
    csmith = shutil.which('csmith')
    require(csmith, 'csmith not found')
    runner = Runner(args.oracle, args.lean, args.out / 'fuzz')
    generated = runner.out / 'generated'
    generated.mkdir()
    # Csmith writes platform.info even for --version. Keep every invocation
    # in this owned scratch directory, never the source checkout's root.
    version = runner.capture('csmith-version', [csmith, '--version'], cwd=generated)
    require(Path(version + '.status').read_text().strip() == '0', 'csmith --version failed')
    print(Path(version + '.stdout').read_text().strip(), flush=True)
    for name in ['csmith_cerberus.h', 'safe_math.h']:
        shutil.copyfile(ROOT / 'tests/csmith' / name, generated / name)
    flags = ['--no-argc', '--no-bitfields', '--max-funcs', '3', '--max-block-depth', '3',
             '--max-block-size', '4', '--max-expr-complexity', '3']
    rows = []
    started = time.monotonic()
    for seed in range(args.seed_start + 1, args.seed_start + args.fuzz + 1):
        p = runner.capture(f'generate-{seed}', [csmith, '--seed', str(seed), *flags], cwd=generated)
        require(Path(p + '.status').read_text().strip() == '0', f'Csmith seed {seed} failed')
        source = Path(p + '.stdout').read_text()
        require(source.count('#include "csmith.h"') == 1, f'Csmith seed {seed}: missing/duplicate header')
        source = source.replace('#include "csmith.h"', '#define CSMITH_MINIMAL\n#include "csmith_cerberus.h"')
        path = generated / f'csmith_{seed}.c'
        path.write_text(source)
        rows.append(Row(f'csmith/{seed}', path, 'first'))
    print(f'FUZZ PLAN: count={args.fuzz} seeds={args.seed_start+1}..{args.seed_start+args.fuzz} '
          f'flags={shlex.join(flags)}; single-trace; switched engine pair and cross-mode oracle', flush=True)
    runner.run(rows, cross=True)
    print(f'FUZZ PASS: {args.fuzz} samples; every switched pair and cross-mode oracle agrees; '
          f'{time.monotonic()-started:.2f}s including generation', flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--oracle', type=Path, required=True)
    parser.add_argument('--lean', type=Path, required=True)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--baseline', type=Path, default=BASELINE)
    modes = parser.add_mutually_exclusive_group()
    modes.add_argument('--selftest', action='store_true')
    modes.add_argument('--gate', action='store_true')
    modes.add_argument('--observe', action='store_true')
    modes.add_argument('--record-baseline', action='store_true')
    modes.add_argument('--fuzz', type=int, metavar='COUNT', help='Csmith single-trace measurement, no baseline')
    parser.add_argument('--seed-start', type=int, default=2026102100)
    parser.add_argument('--rows')
    args = parser.parse_args()
    for engine in [args.oracle, args.lean]:
        require(engine.is_file() and os.access(engine, os.X_OK), f'missing engine: {engine}')
    require(not (args.rows and (args.gate or args.selftest or args.record_baseline or args.fuzz is not None)), 'selection cannot certify or record the whole gate')
    args.out.mkdir(parents=True, exist_ok=True)
    if args.fuzz is not None:
        fuzz(args)
        return
    if args.selftest or args.gate:
        selftest(args)
        if args.selftest: return
    selection = re.compile(args.rows) if args.rows else None
    rows = [r for r in population() if selection is None or selection.search(r.name)]
    started = time.monotonic()
    actual = Runner(args.oracle, args.lean, args.out / 'lane').run(rows)
    if args.record_baseline:
        args.baseline.write_text('{\n' + ',\n'.join(
            '  ' + json.dumps(k) + ': ' + json.dumps(v, sort_keys=True)
            for k, v in sorted(actual.items())) + '\n}\n')
        print(f'BASELINE RECORDED ({len(actual)} rows): {args.baseline}')
    elif not args.observe:
        check_baseline(actual, args.baseline, selection)
    print(f'inner_arg_temps elapsed: {time.monotonic()-started:.2f}s', flush=True)


if __name__ == '__main__':
    try:
        main()
    except (Failure, OSError, ValueError) as exc:
        print('inner_arg_temps: FAIL — ' + str(exc), file=sys.stderr)
        sys.exit(1)
