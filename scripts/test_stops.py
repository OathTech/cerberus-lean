#!/usr/bin/env python3
"""Outcome codec/frame tests; --lean-bin adds real Lean parser/adapter captures.

No production lane policy is changed. Tests explicitly distinguish diagnostic
metadata retained from an invalid capture from an admitted, clean capture.
"""
import argparse
import ast
import copy
import json
import os
from pathlib import Path
import resource
import subprocess
import sys
import time
import unittest

import observations as obs


ROOT = Path(__file__).resolve().parent.parent
LEAN_BIN = None
REF = ['1', 'REFUSAL', 'fs', '', 'cannot open a\nb', 'a filesystem model', None, 'CONTRACT.md §3']
UP = ['cerberus', 'b9aeedcb4dd438763b0eef7f95ac19e93875d7de',
      'memory/concrete/impl_mem.ml', '2658', '2659', 'assert false']
CRASH = ['1', 'UPSTREAM_CRASH', 'CerbMem.memcmp', 'non-integer byte', UP, ['none'], None]
INV = ['1', 'INVARIANT', 'Main.judgeSwitches', 'refusal returned', 'Main.refuseSwitches must terminate']
OK = b'Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}\n'
ERR = b'Error {msg: "ordinary error"}\n'
FUEL = b'Error {msg: "lem: fuel exhausted"}\n'
PANIC = b'PANIC at _private.LemLib.0.failwithIImpl LemLib:226:2: '
TRACE = b'backtrace:\n/lib/runtime.so(lean_panic+0x2) [0xAa01]\n'
WRAPPER = b'scripts/capped: line 36: 123 Aborted                 "$@"\n'
CORE_WRAPPER = b'scripts/capped: line 36: 123 Aborted                 (core dumped) "$@"\n'
INSTALLED_WRAPPER = (
    b'/opt/tools/capped: line 147: 123 Aborted                 '
    b'( { echo "$BASHPID" > "$cg/cgroup.procs"; } 2> /dev/null || '
    b'{ echo "$prog: could not move into $cg: refusing to run uncapped" 1>&2; exit 4; }; '
    b'exec env CAPPED_STATE=1 CAPPED_MEM_MAX="$MEM" "$0" "$@" )\n')


def wire(value):
    return obs.STOP_PREFIX + json.dumps(value, ensure_ascii=False, separators=(',', ':')).encode()


def model(payload):
    return b'ModelFailure {msg: "' + obs.escape(payload).encode('ascii') + b'"}\n'


def multi(*records):
    return b''.join(b'EXECUTION %d:\n' % i + r for i, r in enumerate(records))


def assert_cli_refusals(stdout, stderr, status, boundary=None, items=None,
                        contains='', excludes=''):
    """Witness helper, not a machine CLI: check original, separate captures."""
    decoded = obs.decode_stop(stdout, stderr, status)
    assert status == 2 and not stdout, (status, stdout)
    assert not (decoded.problems or decoded.legacy_panics or decoded.fuel), decoded
    stops = [entry.stop for entry in decoded.stops]
    assert stops and all(isinstance(stop, obs.Refusal) for stop in stops), decoded
    if boundary is not None:
        assert all(stop.boundary == boundary for stop in stops), stops
    if items is not None:
        assert [stop.item for stop in stops] == items, stops
    assert any(contains in stop.detail for stop in stops), stops
    assert not excludes or all(excludes not in stop.detail for stop in stops), stops


def schema_cases():
    """Shared inputs, independent expected admission (not decoder-generated)."""
    good = [REF, CRASH, INV]
    for boundary in sorted(obs.STOP_BOUNDARIES):
        v = copy.deepcopy(REF)
        v[2], v[3], v[6], v[7] = boundary, None, UP, None
        good.append(v)
    for tray in (['pending'], ['draft', '12'], ['filed', 'https://example.org/issues/1']):
        v = copy.deepcopy(CRASH)
        v[5], v[6] = tray, 'source review'
        good.append(v)
    v = copy.deepcopy(INV)
    v[3] = ''.join(map(chr, range(32))) + '☃😀� / : " \\ud800\n' + wire(REF).decode()
    good.append(v)
    v = copy.deepcopy(CRASH)
    v[4][0], v[4][5] = 'lem', ''
    good.append(v)
    cases = [(wire(v), 'valid') for v in good]
    # Alternative admitted spellings preserve decoded fields, including an
    # escaped backslash followed by ud800 and a literal replacement character.
    cases.extend([
        (b'cerberus-lean stop [ "1" ,\t"INVARIANT", "s", "\\/\\b\\f\\n\\r\\t\\u001F", "r" ]', 'valid'),
        (wire(INV) + b'\t ', 'valid'),
        (b'ordinary panic', 'absent'),
        (b'', 'absent'),
        (b'x cerberus-lean stop []', 'absent'),
    ])
    bad = [None, {}, True, 1, [], ['1'], ['2', *INV[1:]], [1, *INV[1:]],
           ['1', 'RESOURCE', 'fuel'], ['1', 'INVARIANT', 'x', 'd', None]]
    for base in (REF, CRASH, INV):
        bad.extend([base[:-1], base + [None]])
    for at in (2, 3, 4):
        for value in ('', None, False, 1, {}, []):
            v = copy.deepcopy(INV); v[at] = value; bad.append(v)
    for at in (4, 5, 7):
        v = copy.deepcopy(REF); v[at] = ''; bad.append(v)
    for at, value in ((2, 'unknown'), (2, []), (3, 0), (3, False), (6, {})):
        v = copy.deepcopy(REF); v[at] = value; bad.append(v)
    for at, values in (
            (0, ('unknown',)), (1, ('a' * 39, 'A' * 40, 'g' * 40)),
            (2, ('', '/a', 'a/', 'a//b', 'a/./b', 'a/../b')),
            (3, ('0', '01', '-1', '1.0', '1e2', '١', 1, True)),
            (4, ('1', '0', '02659')), (5, (None, {}))):
        for value in values:
            v = copy.deepcopy(CRASH); v[4][at] = value; bad.append(v)
    for upstream in (None, UP[:-1], UP + ['extra']):
        v = copy.deepcopy(CRASH); v[4] = upstream; bad.append(v)
    for tray in ([], ['NONE'], ['none', None], ['pending', 'x'], ['draft'],
                 ['draft', '0'], ['draft', '01'], ['draft', 1], ['filed', ''],
                 ['filed', 'http://example.org/1'], ['filed', 'https://'],
                 ['filed', 'https:///x'], ['filed', 'https://a/has space'], {}):
        v = copy.deepcopy(CRASH); v[5] = tray; bad.append(v)
    cases.extend((wire(v), 'malformed') for v in bad)
    cases.extend((v, 'malformed') for v in (
        b'cerberus-lean stop', b'cerberus-lean stop[]', b'cerberus-lean stopp []',
        b'cerberus-lean stop {"class":"REFUSAL","class":"INVARIANT"}',
        b'cerberus-lean stop {"cl\\u0061ss":"REFUSAL","class":"INVARIANT"}',
        wire(INV).replace(b'"refusal returned"', b'"\\ud800"'),
        wire(INV).replace(b'"refusal returned"', b'"\\ud83d\\ude00"'),
        wire(INV).replace(b'"refusal returned"', b'"\\u0020"'),
        wire(INV).replace(b'"refusal returned"', b'"\\u0061"'),
        wire(INV).replace(b'"refusal returned"', b'"\\x00"'),
        wire(INV).replace(b'"refusal returned"', b'"\x00"'),
        wire(INV) + b'\n', wire(INV) + b'\r', wire(INV) + b' []',
        wire(INV)[:-1],
    ))
    return cases


class SchemaTests(unittest.TestCase):
    def test_frozen_schema(self):
        for payload, expected in schema_cases():
            with self.subTest(payload=payload):
                if expected == 'malformed':
                    with self.assertRaises(obs.ProtocolError):
                        obs.parse_stop(payload)
                else:
                    self.assertEqual(obs.parse_stop(payload) is None, expected == 'absent')

    def test_strict_utf8_and_surrogate(self):
        for encoded in (b'\xff', b'\xed\xa0\x80', b'\xc0\x80'):
            with self.subTest(encoded=encoded), self.assertRaises(obs.ProtocolError):
                obs.parse_stop(wire(INV).replace(b'refusal returned', encoded))

    def test_all_metadata_and_option_distinctions(self):
        r = obs.parse_stop(wire(REF))
        self.assertIsInstance(r, obs.Refusal)
        self.assertEqual((r.kind, r.boundary, r.item, r.detail, r.mover, r.upstream, r.see),
                         ('REFUSAL', *REF[2:]))
        c = obs.parse_stop(wire(CRASH))
        self.assertEqual(c.upstream, obs.Upstream(*UP))
        self.assertEqual(c.tray, obs.Tray('none'))
        r2 = copy.deepcopy(REF); r2[3] = None
        self.assertNotEqual(r, obs.parse_stop(wire(r2)))

    def test_unbounded_positive_text(self):
        v = copy.deepcopy(CRASH)
        v[4][3] = '1' * 5000
        v[4][4] = '2' * 5000
        v[5] = ['draft', '1' * 5000]
        self.assertEqual(obs.parse_stop(wire(v)).tray.number, '1' * 5000)


class SwitchReportTests(unittest.TestCase):
    """The driver's informational switch-set report on stderr (post-rebase adaptation of
    the inner_arg_temps slice, 2026-10-26): one well-formed line is admitted and retained,
    everything else stays a problem."""
    VERDICT = b'Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}\n'

    def test_well_formed_report_is_admitted_and_retained(self):
        for line in (b'cerberus-lean switches: []', b'cerberus-lean switches: [inner_arg_temps]',
                     b'cerberus-lean switches: [PNVI_ae_udi]'):
            result = obs.decode_stop(self.VERDICT, line + b'\n', 0)
            self.assertEqual(result.problems, [], (line, result.problems))
            self.assertFalse(result.stops or result.fuel or result.legacy_panics)
            self.assertEqual(result.switch_report, line)

    def test_malformed_report_is_a_problem(self):
        for line in (b'cerberus-lean switches: [inner arg]', b'cerberus-lean switches: [',
                     b'cerberus-lean switches:[]', b'cerberus-lean switches: [a,]'):
            result = obs.decode_stop(self.VERDICT, line + b'\n', 0)
            self.assertTrue(result.problems, line)
            self.assertIsNone(result.switch_report)

    def test_duplicate_report_is_a_problem(self):
        err = b'cerberus-lean switches: []\ncerberus-lean switches: []\n'
        result = obs.decode_stop(self.VERDICT, err, 0)
        self.assertTrue(result.problems)

    def test_other_stderr_text_is_still_a_problem(self):
        result = obs.decode_stop(self.VERDICT, b'cerberus-lean: something else\n', 0)
        self.assertTrue(result.problems)


class CaptureTests(unittest.TestCase):
    def clean(self, out, err, rc):
        result = obs.decode_stop(out, err, rc)
        self.assertEqual(result.problems, [], result.problems)
        return result

    def test_ordinary_absence_is_not_empty_capture(self):
        for out, rc in ((OK, 0), (ERR, 1), (multi(OK, ERR), 0)):
            result = self.clean(out, b'', rc)
            self.assertFalse(result.stops or result.fuel or result.legacy_panics)
        for rc in (0, 1, 2, 124, 134, 137):
            self.assertTrue(obs.decode_stop(b'', b'', rc).problems)

    def test_cli_collection_with_duplicates_and_positions(self):
        line = wire(REF) + b'\n'
        result = self.clean(b'', line * 3, 2)
        self.assertEqual([o.stop for o in result.stops], [obs.parse_stop(wire(REF))] * 3)
        self.assertEqual([o.position for o in result.stops],
                         [obs.SourcePosition(i + 1, i * len(line)) for i in range(3)])
        self.assertTrue(all(o.channel == 'cli' and o.execution is None for o in result.stops))
        self.assertEqual(self.clean(b'', wire(INV) + b'\n', 2).stops[0].stop.kind, 'INVARIANT')

    def test_model_collection_and_fuel_with_execution_indices(self):
        result = self.clean(multi(OK, model(wire(INV)), FUEL, model(wire(CRASH)),
                                 model(wire(INV))), b'', 0)
        self.assertEqual([o.execution for o in result.stops], [1, 3, 4])
        self.assertEqual([o.stop.kind for o in result.stops], ['INVARIANT', 'UPSTREAM_CRASH', 'INVARIANT'])
        self.assertEqual(result.fuel, [obs.FuelOccurrence('kill', 2,
            obs.SourcePosition(6, len(multi(OK, model(wire(INV)))) + len(b'EXECUTION 2:\n')))])
        self.assertEqual(self.clean(model(wire(CRASH)), b'', 1).stops[0].execution, 0)

    def test_envelope_less_model_failure_is_not_attributed(self):
        # The old observation-lane positive plant remains a decoder negative:
        # its sentinel is not evidence of which producer class stopped the run.
        result = obs.decode_stop(model(b'Concrete.memcmp: non-integer byte'), b'', 1)
        self.assertFalse(result.stops)
        self.assertTrue(result.problems)

    def test_program_data_and_ordinary_error_have_no_authority(self):
        injected = b'\n'.join((wire(INV), wire(REF), FUEL, PANIC + wire(INV),
                               b'capped: OOM-KILLED (oom_kill=1)', WRAPPER))
        escaped = obs.escape(injected).encode('ascii')
        out = OK.replace(b'stdout: ""', b'stdout: "' + escaped + b'"')
        out = out.replace(b'stderr: ""', b'stderr: "' + escaped + b'"')
        result = self.clean(out, b'', 0)
        self.assertFalse(result.stops or result.fuel or result.legacy_panics)
        for payload in (wire(INV), wire(REF), b'prefix lem: fuel exhausted',
                        b'cerberus-lean stop malformed'):
            result = self.clean(b'Error {msg: "' + payload + b'"}\n', b'', 1)
            self.assertFalse(result.stops or result.fuel)

    def test_embedded_stop_and_resource_markers_are_data(self):
        v = copy.deepcopy(INV)
        v[3] = '\n'.join([wire(REF).decode(), FUEL.decode(), (PANIC + wire(CRASH)).decode(),
                          'capped: OOM-KILLED (oom_kill=1)'])
        result = self.clean(model(wire(v)), b'', 1)
        self.assertEqual(len(result.stops), 1)
        self.assertEqual(result.stops[0].stop.detail, v[3])
        self.assertFalse(result.fuel or result.legacy_panics)

    def test_panic_trace_suffix_grammar(self):
        for value in (REF, CRASH, INV):
            for tail in (b'', TRACE, WRAPPER, b'/owned/' + WRAPPER, CORE_WRAPPER,
                         b'/owned/' + CORE_WRAPPER, INSTALLED_WRAPPER,
                         INSTALLED_WRAPPER.replace(b'Aborted ', b'Aborted (core dumped) '),
                         TRACE + obs.CORE_DUMP + b'\n' + INSTALLED_WRAPPER,
                         obs.CORE_DUMP + b'\n' + WRAPPER,
                         TRACE + obs.CORE_DUMP + b'\n' + WRAPPER):
                with self.subTest(value=value[1], tail=tail):
                    result = self.clean(b'', PANIC + wire(value) + b'\n' + tail, 134)
                    self.assertEqual(result.stops[0].stop, obs.parse_stop(wire(value)))
        for tail in (TRACE + WRAPPER * 2, TRACE + obs.CORE_DUMP + b'\n' + obs.CORE_DUMP + b'\n',
                     WRAPPER + obs.CORE_DUMP + b'\n', b'backtrace:\n', b'backtrace:\ngarbage\n',
                     TRACE + b'garbage\n', b'lookalike-capped: line 1: 2 Aborted "$@"\n',
                     CORE_WRAPPER.replace(b'Aborted                 ', b'Aborted\t'),
                     CORE_WRAPPER + CORE_WRAPPER, INSTALLED_WRAPPER * 2,
                     INSTALLED_WRAPPER + WRAPPER, WRAPPER + INSTALLED_WRAPPER,
                     INSTALLED_WRAPPER + obs.CORE_DUMP + b'\n',
                     INSTALLED_WRAPPER.replace(b'"$0"', b'"other"'),
                     INSTALLED_WRAPPER.replace(b'exit 4;', b'exit 0;'),
                     INSTALLED_WRAPPER.replace(b'Aborted ', b'Aborted\t'),
                     INSTALLED_WRAPPER.replace(b'capped:', b'other:'),
                     INSTALLED_WRAPPER.rstrip(b'\n') + b' extra\n'):
            result = obs.decode_stop(b'', PANIC + wire(INV) + b'\n' + tail, 134)
            self.assertTrue(result.problems, tail)
            self.assertEqual(len(result.stops), 1, tail)

    def test_exact_fuel_frames(self):
        self.assertEqual(self.clean(FUEL, b'', 1).fuel[0].form, 'kill')
        for header, form in ((b'', 'bare-panic'), (PANIC, 'translation-panic')):
            for tail in (b'', TRACE, TRACE + WRAPPER, TRACE + INSTALLED_WRAPPER):
                result = self.clean(b'', header + obs.FUEL_PAYLOAD + b'\n' + tail, 134)
                self.assertEqual(result.fuel[0].form, form)
                self.assertFalse(result.stops or result.legacy_panics)
            result = obs.decode_stop(b'', header + obs.FUEL_PAYLOAD + b'\ngarbage\n', 134)
            self.assertTrue(result.problems)
            self.assertFalse(result.fuel)

    def test_legacy_payload_is_bytes_and_never_shared(self):
        payload = b'legacy \xff\ncontinuation'
        result = self.clean(b'', PANIC + payload + b'\n' + TRACE + WRAPPER, 134)
        self.assertEqual(result.legacy_panics[0].payload, payload)
        self.assertFalse(result.stops or result.fuel)
        result = self.clean(b'', PANIC + payload + b'\n', 134)
        self.assertEqual(result.legacy_panics[0].payload, payload)
        for extra in (obs.FUEL_PAYLOAD, FUEL.rstrip(b'\n'), PANIC + b'second', wire(INV),
                      model(wire(INV)).rstrip(b'\n')):
            result = obs.decode_stop(b'', PANIC + payload + b'\n' + extra + b'\n' + TRACE, 134)
            self.assertTrue(result.problems)
            self.assertFalse(result.fuel or result.stops or result.legacy_panics)

    def test_unmigrated_refusal_text_is_unattributed(self):
        # Declared fork refusals are not wire attribution without an envelope.
        for payload in (b'Concrete.memcpy: refused - memcpy on overlapping objects',
                        b'Concrete.allocator: refused - allocation with an invalid alignment 3',
                        b'Desugaring_init.moveTo_aux: refused - union initializer designating a member other than the first'):
            self.assertIsNone(obs.parse_stop(payload))
            result = self.clean(b'', PANIC + payload + b'\n' + TRACE + WRAPPER, 134)
            self.assertFalse(result.stops or result.fuel)
            self.assertEqual([p.payload for p in result.legacy_panics], [payload])

    def test_absent_model_and_malformed_panic_never_become_legacy(self):
        self.assertTrue(obs.decode_stop(model(b'old message'), b'', 1).problems)
        for payload in (b'cerberus-lean stop', wire(['2', *INV[1:]])):
            result = obs.decode_stop(b'', PANIC + payload + b'\n' + TRACE, 134)
            self.assertTrue(result.problems)
            self.assertFalse(result.legacy_panics)

    def test_all_positions_checked_and_bad_tail_preserves_invariant(self):
        for out, err, rc in (
                (model(wire(INV)) + b'broken\n', b'', 1),
                (multi(model(wire(INV)), model(b'cerberus-lean stop [broken')), b'', 0),
                (multi(model(wire(INV)), OK) + b'EXECUTION 2:\nModelFailure {msg: "', b'', 0),
                (model(wire(INV)), b'unknown diagnostic\n', 1),
                (model(wire(INV)), b'capped: OOM-KILLED (oom_kill=1)\n', 137),
                (model(wire(INV)), b'', 124),
                (model(wire(INV)), b'\x1b[0m\n', 1),
                (b'', wire(INV) + b'\ntruncated', 2)):
            result = obs.decode_stop(out, err, rc)
            self.assertTrue(result.problems, (out, err, rc))
            self.assertEqual(result.stops[0].stop.kind, 'INVARIANT')
            self.assertFalse(result.fuel)
        # Check stderr even when stdout has a valid ordinary record.
        result = obs.decode_stop(OK, wire(INV) + b'\n', 0)
        self.assertTrue(result.problems)
        self.assertEqual(result.stops[0].stop.kind, 'INVARIANT')

    def test_wrong_channels_statuses_and_incomplete_records(self):
        for out, err, rc in (
                (model(wire(REF)), b'', 1), (b'', wire(CRASH) + b'\n', 2),
                (b'', wire(INV) + b'\n' + wire(REF) + b'\n', 2),
                (b'', wire(INV) + b'\n' + wire(INV) + b'\n', 2),
                (model(wire(INV)), b'', 0), (b'', PANIC + wire(INV) + b'\n', 1),
                (b'', wire(REF) + b'\n', 1), (wire(INV) + b'\n', b'', 1),
                (b'', PANIC.replace(b'226:2', b'0:2') + wire(INV) + b'\n', 134),
                (b'', PANIC.replace(b'failwithIImpl', b'other') + wire(INV) + b'\n', 134),
                (model(wire(INV)).rstrip(b'\n'), b'', 1),
                (b'', PANIC + wire(INV), 134), (b'', wire(REF), 2),
                (b'', PANIC + wire(INV) + b'\n' + TRACE.rstrip(b'\n'), 134)):
            self.assertTrue(obs.decode_stop(out, err, rc).problems, (out, err, rc))
        self.assertFalse(obs.decode_stop(model(wire(INV)).rstrip(b'\n'), b'', 1).stops)

    def test_batch_header_integrity_and_escape_errors(self):
        record = model(wire(INV))
        for out in (b'EXECUTION 0:\n' + record,
                    b'EXECUTION 1:\n' + record + b'EXECUTION 1:\n' + OK,
                    record + record,
                    multi(record, OK).replace(b'EXECUTION 1:', b'EXECUTION 0:'),
                    b'EXECUTION 0:\nEXECUTION 1:\n' + record,
                    multi(record, OK) + b'EXECUTION 2:\n',
                    record.replace(b'\\"', b'\\999', 1),
                    record + b'\n', b'\r\n' + record):
            self.assertTrue(obs.decode_stop(out, b'', 0).problems, out)
        annotated = multi(record, OK).replace(b'EXECUTION 0:', b'EXECUTION 0 (exit = 1):')
        self.assertEqual(len(self.clean(annotated, b'', 0).stops), 1)


class LeanConformanceTests(unittest.TestCase):
    def run_lean(self, mode, input=None):
        def no_core():
            resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
        return subprocess.run([str(ROOT / 'scripts/capped'), str(LEAN_BIN), mode],
                              input=input, capture_output=True, timeout=60,
                              env={**os.environ, 'LEAN_ABORT_ON_PANIC': '1',
                                   'NO_COLOR': '1', 'TERM': 'dumb'}, preexec_fn=no_core)

    def test_cross_language_schema_corpus(self):
        cases = schema_cases()
        transport = ''.join(json.dumps(payload.decode(), ensure_ascii=False) + '\n'
                            for payload, _ in cases).encode()
        result = self.run_lean('decode', transport)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, b'')
        lines = result.stdout.splitlines()
        self.assertEqual(len(lines), len(cases))
        for (payload, expected), line in zip(cases, lines):
            with self.subTest(payload=payload):
                if expected == 'valid':
                    self.assertEqual(obs.parse_stop(line), obs.parse_stop(payload))
                else:
                    self.assertEqual(line, expected.upper().encode())

    def test_lean_rendering(self):
        result = self.run_lean('render')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stderr, b'')
        lines = result.stdout.splitlines()
        self.assertEqual(lines[:3], [wire(REF), wire(CRASH), wire(INV)])
        self.assertEqual(len(lines), 7)
        for line in lines:
            self.assertIsNotNone(obs.parse_stop(line))
        self.assertIn(''.join(map(chr, range(32))), obs.parse_stop(lines[3]).detail)
        self.assertIn('\\ud800', obs.parse_stop(lines[3]).item)

    def test_actual_channel_adapters(self):
        for mode, rc, kinds in (
                ('refuse', 2, ['REFUSAL', 'REFUSAL']),
                ('invariant-cli', 2, ['INVARIANT']),
                ('typed', 1, ['UPSTREAM_CRASH']),
                ('pure', 134, ['UPSTREAM_CRASH']),
                ('refuse-m', 134, ['REFUSAL'])):
            with self.subTest(mode=mode):
                child = self.run_lean(mode)
                self.assertEqual(child.returncode, rc, (child.stdout, child.stderr))
                result = obs.decode_stop(child.stdout, child.stderr, child.returncode)
                self.assertFalse(result.problems, (result.problems, child.stdout, child.stderr))
                self.assertEqual([o.stop.kind for o in result.stops], kinds)


def consumer_demo(consumer, outdir):
    """Read-only demonstration of the raw-byte patch to Caesium's actual run().

    Native adapter/driver outputs and explicitly labelled fixtures travel through
    its cap/timeout capture shape. No consumer file is imported for side effects
    or modified, and no adoption is implied. Run under the provider's capped.
    """
    outdir.mkdir(parents=True, exist_ok=True)
    path = consumer / 'scripts/differential.py'
    tree = ast.parse(path.read_text())
    fn = copy.deepcopy(next(n for n in tree.body if isinstance(n, ast.FunctionDef) and n.name == 'run'))
    calls = [n for n in ast.walk(fn) if isinstance(n, ast.Call) and
             isinstance(n.func, ast.Attribute) and isinstance(n.func.value, ast.Name) and
             n.func.value.id == 'subprocess' and n.func.attr == 'run']
    assert len(calls) == 1, 'review the changed consumer runner'
    call = calls[0]
    keywords = {k.arg: k.value for k in call.keywords}
    assert ast.literal_eval(keywords['text']) is True
    assert ast.literal_eval(keywords['errors']) == 'replace'
    # The sole prototype patch: keep this driver's streams as raw bytes.
    call.keywords = [k for k in call.keywords if k.arg not in ('text', 'errors')]
    ns = dict(os=os, subprocess=subprocess, time=time, Path=Path)
    exec(compile(ast.Module(body=[fn], type_ignores=[]), str(path), 'exec'), ns)
    cap = next(line for line in (consumer/'scripts/env.sh').read_text().splitlines()
               if line.startswith('cap() {'))
    assert cap == 'cap() { if command -v capped >/dev/null 2>&1; then capped "$@"; else "$@"; fi; }', cap
    env = {'BASH_FUNC_cap%%': '() ' + cap.partition('() ')[2], 'NO_COLOR': '1', 'TERM': 'dumb'}
    resource.setrlimit(resource.RLIMIT_CORE, (0, 0))
    rows = []

    def capture(name, cmd, status, kinds=(), fuel=(), legacy=0, problems=False, expected=None, cwd=ROOT):
        rc, stdout, stderr, seconds = ns['run'](list(map(str, cmd)), cwd, 45, '48G', env)
        assert isinstance(stdout, bytes) and isinstance(stderr, bytes)
        for ext, data in (('stdout', stdout), ('stderr', stderr), ('status', str(rc).encode())):
            (outdir/f'{name}.{ext}').write_bytes(data)
        decoded = obs.decode_stop(stdout, stderr, rc)
        assert rc == status, (name, rc, stderr)
        assert [o.stop.kind for o in decoded.stops] == list(kinds), (name, decoded)
        assert [o.form for o in decoded.fuel] == list(fuel), (name, decoded)
        assert len(decoded.legacy_panics) == legacy and bool(decoded.problems) == problems, (name, decoded)
        if expected is not None:
            assert [o.stop for o in decoded.stops] == expected, (name, decoded)
        rows.append((name, rc, len(decoded.stops), len(decoded.fuel), len(decoded.legacy_panics), len(decoded.problems)))
        print(f'{name}: exit={rc} stops={len(decoded.stops)} fuel={len(decoded.fuel)} legacy={len(decoded.legacy_panics)} problems={len(decoded.problems)}', flush=True)
        return decoded, stdout, stderr

    driver = ROOT/'lean_frontend/.lake/build/bin/cerberus-lean'
    stop_test = ROOT/'lean_frontend/.lake/build/bin/stop-test'
    runtime = ROOT/'_build/install/default'
    for mode, status, values in [('refuse', 2, [REF, REF]), ('invariant-cli', 2, [INV]),
                                  ('typed', 1, [CRASH]), ('pure', 134, [CRASH]), ('refuse-m', 134, [REF])]:
        capture('adapter-' + mode, [stop_test, mode], status, [v[1] for v in values],
                expected=[obs.parse_stop(wire(v)) for v in values])
    decoded, _, _ = capture('driver-cli', [driver, '--fuel', '0'], 2, ['REFUSAL'])
    assert decoded.stops[0].stop.boundary == 'fuel-arg' and decoded.stops[0].stop.item == '0'
    decoded, _, _ = capture('driver-switches', [driver, '--switches=bogus,also-bogus'], 2, ['REFUSAL'] * 2)
    assert [(o.stop.boundary, o.stop.item) for o in decoded.stops] == [('switches', 'bogus'), ('switches', 'also-bogus')]

    # Incoming quotation admission paths retain their predicates, exit 2 and
    # no-output contract, now with the existing CLI refusal metadata.
    quoted = outdir/'Refused.lean'
    assert not quoted.exists(), 'use a fresh demonstration directory'
    libc_args = ['--libc', 'tests/libc/libc.core', '--libc-tu',
                 'tests/fixtures/001-return-literal/cabs.json']
    quote_cases = []
    for flag in ('--quote-core', '--quote-libc'):
        for name, args in [('repeated', [flag, quoted, flag, quoted]),
                           ('empty', [flag, '']), ('flag-path', [flag, '--invalid'])]:
            quote_cases.append((flag[2:] + '-' + name, args, flag))
    quote_cases.extend([
        ('quote-mode', ['--batch', '--first', '--quote-core', quoted], 'Core quotation'),
        ('quote-identical', ['--quote-core', quoted, '--quote-libc', quoted, *libc_args], '--quote-core/--quote-libc'),
        ('quote-no-user-tu', ['--quote-core', quoted, *libc_args], '--quote-core')])
    for name, args, item in quote_cases:
        d, stdout, _ = capture(name, [driver, *args], 2, ['REFUSAL'])
        assert stdout == b'' and not quoted.exists(), name
        assert (d.stops[0].stop.boundary, d.stops[0].stop.item) == ('cli', item), d
    for flag in ('--quote-core', '--quote-libc'):
        capture(flag[2:] + '-usage', [driver, flag], 1, problems=True)
        assert not quoted.exists()

    probe = outdir/'Panic.lean'
    probe.write_text('''import LemLib
def main (args : List String) : IO Unit := do
  match args with
  | ["fuel"] => IO.println (fuelExhaustedWith "lem: fuel exhausted" (0 : Nat))
  | [payload] => IO.println (failwithI payload : String)
  | _ => throw (IO.userError "one payload required")
''')
    lean_cmd = [ROOT/'scripts/capped', 'lake', 'env', 'lean', '--run', probe]
    capture('adapter-pure-invariant', [*lean_cmd, wire(INV).decode()], 134, ['INVARIANT'],
            expected=[obs.parse_stop(wire(INV))], cwd=ROOT/'lean_frontend')
    capture('adapter-bare-fuel', [*lean_cmd, 'fuel'], 134, fuel=['bare-panic'], cwd=ROOT/'lean_frontend')

    mixed = '''int memcmp(const void *, const void *, unsigned long);
int open(const char *, int, ...);
int a;
int f(void) { a = 1; return 0; }
int g(void) {
  int x, y;
  if (a) return memcmp(&x, &y, sizeof x);
  return open("x", 0);
}
int main(void) { return g() + f(); }
'''
    programs = {'mixed': mixed,
                'translation': 'int unused(void) { return ' + '1 + (' * 192 + '0' + ')' * 192 + '; }\nint main(void) { return 0; }\n',
                'fuel-kill': 'int main(void) { while (1) {} }\n',
                'legacy': (ROOT/'tests/immaculate/nolibc/zd-any-bounded-int-crash.c').read_text(),
                'union-refusal': 'union U { int i; unsigned char c[4]; }; int main(void) { union U u = { .c = {1,2,3,4} }; return u.c[0]; }\n',
                'alignment-refusal': 'void *aligned_alloc(unsigned long, unsigned long); int main(void) { return aligned_alloc(3, 9) == 0; }\n',
                'overlap-refusal': 'void *memcpy(void *, const void *, unsigned long); int main(void) { char a[4] = {1,2,3,4}; memcpy(a+1, a, 2); return a[1]; }\n'}
    for name, source in programs.items():
        cfile, jsonfile = outdir/f'{name}.c', outdir/f'{name}.json'
        cfile.write_text(source)
        bridge = subprocess.run([str(ROOT/'scripts/capped'), str(ROOT/'_build/default/backend/driver/main.exe'),
                                 '--runtime', str(runtime), '--cabs-json', str(cfile)], capture_output=True)
        assert bridge.returncode == 0, bridge.stderr
        jsonfile.write_bytes(bridge.stdout)
    def driver_cmd(name, *flags):
        return [driver, '--batch', *flags, '--runtime', runtime, outdir/f'{name}.json']
    d, out, _ = capture('mixed-first', driver_cmd('mixed', '--first'), 1, ['UPSTREAM_CRASH'])
    assert out.count(b'ModelFailure {') == 1
    stop = d.stops[0].stop
    assert stop.site == 'CerbMem.memcmpByte' and stop.upstream == obs.Upstream(
        'cerberus', UP[1], UP[2], '2658', '2659', '| _ ->\n                assert false in')
    assert stop.tray == obs.Tray('none') and stop.see is None
    d, out, _ = capture('mixed-exhaustive', driver_cmd('mixed'), 134, ['REFUSAL'])
    assert out == b'' and not out.count(b'ModelFailure {')
    stop = d.stops[0].stop
    assert (stop.boundary, stop.item, stop.mover, stop.upstream, stop.see) == (
        'fs', 'open', 'a SibylFS-faithful filesystem model', None,
        'CerbFS.lean; docs/2026-09-28_cerbfs-refuse-all-record.md')
    capture('driver-translation-fuel', driver_cmd('translation', '--first', '--fuel', '128'), 134, fuel=['translation-panic'])
    capture('driver-fuel-kill', driver_cmd('fuel-kill', '--first', '--fuel', '128'), 1, fuel=['kill'])
    capture('driver-legacy', driver_cmd('legacy', '--first'), 134, legacy=1)
    for name, prefix in [('union-refusal', b'Desugaring_init.moveTo_aux: refused - '),
                         ('alignment-refusal', b'Concrete.allocator: refused - '),
                         ('overlap-refusal', b'Concrete.memcpy: refused - ')]:
        d, _, _ = capture('driver-' + name, driver_cmd(name, '--first'), 134, legacy=1)
        assert d.legacy_panics[0].payload.startswith(prefix), d
        assert obs.parse_stop(d.legacy_panics[0].payload) is None

    # These are transport fixtures, not claims of C end-to-end executions.
    fixtures = [
        ('mixed-emitted', multi(model(wire(CRASH)), model(wire(INV)), model(wire(CRASH))), b'', 0, [CRASH, INV, CRASH], [], False),
        ('verdict-stop', multi(OK, model(wire(INV))), b'', 0, [INV], [], False),
        ('stop-fuel', multi(model(wire(CRASH)), FUEL), b'', 0, [CRASH], ['kill'], False),
        ('malformed-later', multi(model(wire(INV)), model(b'cerberus-lean stop ["2"]')), b'', 0, [INV], [], True),
        ('cross-channel-causes', model(wire(INV)), wire(REF) + b'\n', 1, [INV, REF], [], True),
    ]
    injected = copy.deepcopy(INV)
    injected[3] = '\n'.join([wire(REF).decode(), FUEL.decode(), (PANIC + wire(CRASH)).decode()])
    fixtures.append(('detail-injection', model(wire(injected)), b'', 1, [injected], [], False))
    escaped = obs.escape(wire(INV) + b'\n' + FUEL + PANIC + wire(REF)).encode('ascii')
    fixtures.append(('program-data', OK.replace(b'stdout: ""', b'stdout: "' + escaped + b'"'), b'', 0, [], [], False))
    fixtures.append(('ordinary-error', b'Error {msg: "' + wire(INV) + b'"}\n', b'', 1, [], [], False))
    for name, stdout, stderr, status, values, fuels, problems in fixtures:
        # Real separate-stream capture through exactly the same runner/cap shape.
        script = 'import sys; sys.stdout.buffer.write(' + repr(stdout) + '); sys.stderr.buffer.write(' + repr(stderr) + '); sys.exit(' + str(status) + ')'
        d, _, _ = capture('fixture-' + name, [sys.executable, '-c', script], status,
                          [v[1] for v in values], fuels, problems=problems,
                          expected=[obs.parse_stop(wire(v)) for v in values])
        if name == 'mixed-emitted':
            assert [o.execution for o in d.stops] == [0, 1, 2]
    print(f'CONSUMER DEMO: {len(rows)} captures passed; emitted records only; no external adoption', flush=True)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--lean-bin', type=Path)
    parser.add_argument('--consumer-demo', type=Path, help='read-only Caesium checkout; prototype raw-byte capture')
    parser.add_argument('--out', type=Path, help='consumer demo scratch directory (under .tmp)')
    args = parser.parse_args()
    if args.consumer_demo:
        if not args.out or not args.out.resolve().is_relative_to(ROOT/'.tmp'):
            parser.error('--consumer-demo requires --out under this worktree .tmp')
        consumer_demo(args.consumer_demo.resolve(), args.out.resolve())
        sys.exit(0)
    LEAN_BIN = args.lean_bin.resolve() if args.lean_bin else None
    if LEAN_BIN and not LEAN_BIN.is_file():
        parser.error('--lean-bin does not exist; build stop-test first')
    suite = unittest.TestSuite()
    for cls in (SchemaTests, CaptureTests, SwitchReportTests) + ((LeanConformanceTests,) if LEAN_BIN else ()):
        suite.addTests(unittest.defaultTestLoader.loadTestsFromTestCase(cls))
    result = unittest.TextTestRunner(verbosity=2).run(suite)
    sys.exit(not result.wasSuccessful())
