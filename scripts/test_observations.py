#!/usr/bin/env python3
"""Adversarial protocol and actual subprocess-capture tests; no engine build."""

import base64
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

from observations import ProtocolError, escape, load_capture, parse, unescape


OK = b'Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}\n'
UB = b'Undefined {ub: "UB005_data_race", stderr: "x\\000\\255", loc: "<t.c:4:2>"}\n'
ERR = b'Error {msg: "model refused: thread spawn"}\n'


def multi(*rows):
    return b''.join(b'EXECUTION %d:\n' % i + row for i, row in enumerate(rows))


class ObservationTests(unittest.TestCase):
    def test_all_bytes_are_decimal_not_octal_or_unicode(self):
        data = bytes(range(256))
        self.assertEqual(unescape(escape(data).encode('ascii')), data)
        self.assertEqual(unescape(b'\\000\\128\\195\\169\\255'), b'\0\x80\xc3\xa9\xff')
        self.assertEqual(unescape(b'\\010'), b'\n')
        for bad in (b'\\', b'\\12', b'\\xFF', b'\\256', b'\\999', b'\xff', b'\0'):
            with self.subTest(bad=bad), self.assertRaises(ProtocolError):
                unescape(bad)

    def test_each_semantic_field_changes_comparison(self):
        original = parse(OK, status=0).verdicts
        for old, new in [(b'Specified(0)', b'Specified(137)'),
                         (b'stdout: ""', b'stdout: "\\000\\255"'),
                         (b'stderr: ""', b'stderr: "\\195\\169"'),
                         (b'false', b'true')]:
            with self.subTest(field=old):
                self.assertNotEqual(parse(OK.replace(old, new), status=0).verdicts, original)
        for old, new in [(b'UB005', b'UB999'), (b'x\\000', b'y\\000'), (b':4:2', b':4:3')]:
            self.assertNotEqual(parse(UB, status=1).verdicts,
                                parse(UB.replace(old, new), status=1).verdicts)

    def test_equivalent_escape_spelling_preserves_bytes(self):
        a = OK.replace(b'stdout: ""', b'stdout: "\\n"')
        b = OK.replace(b'stdout: ""', b'stdout: "\\010"')
        self.assertEqual(parse(a).verdicts, parse(b).verdicts)
        self.assertNotEqual(parse(a).stdout, parse(b).stdout)

    def test_escaped_verdict_is_payload(self):
        payload = b'Defined {value: "Specified(9)"}\n\xff\0'
        data = OK.replace(b'stdout: ""', b'stdout: "' + escape(payload).encode() + b'"')
        obs = parse(data, status=0)
        self.assertEqual(len(obs.verdicts), 1)
        self.assertEqual(obs.verdicts[0].field('stdout'), payload)

    def test_order_and_multiplicity_are_preserved(self):
        a = parse(multi(OK, UB, OK), status=0)
        b = parse(multi(UB, OK), status=0)
        self.assertNotEqual(a.verdicts, b.verdicts)
        self.assertEqual(set(a.verdicts), set(b.verdicts))
        self.assertEqual(a.tokens('values')[0], 'VAL:Specified(0)')
        with self.assertRaises(ProtocolError):
            a.tokens('pin')

    def test_completion_protocol(self):
        for output, status in [(OK, 0), (UB, 1), (ERR, 1), (multi(UB, ERR), 0),
                               (OK.replace(b'Specified(0)', b'Specified(137)'), 0)]:
            self.assertEqual(parse(output, status=status).expected_exit, status)
        for output, status in [(OK, 1), (UB, 0), (ERR, 0), (OK, 124), (OK, 137),
                               (UB, 125), (multi(OK, UB), 1), (OK, -9)]:
            with self.subTest(output=output, status=status), self.assertRaises(ProtocolError):
                parse(output, status=status)

    def test_malformed_suffix_does_not_leave_a_valid_prefix(self):
        cases = [b'', b'\n', OK + b'Defined {value: "Specified(9)"',
                 OK.replace(b', blocked: "false"', b''),
                 OK.replace(b'stdout: ""', b'stdout: "", unexpected: "x"'),
                 OK.replace(b'stdout: ""', b'stdout: "", stdout: ""'),
                 OK.replace(b'false', b'unknown'), OK + ERR, b'EXECUTION 0:\n' + OK,
                 multi(OK, UB) + b'EXECUTION 2:\n', multi(OK, UB).replace(b'EXECUTION 1', b'EXECUTION 3'),
                 OK + b'unknown diagnostic\n', OK + b'\0', b'Unknown {msg: "x"}\n']
        for data in cases:
            with self.subTest(data=data), self.assertRaises(ProtocolError):
                parse(data, status=0)

    def test_diagnostics_are_separate_and_fatal_suffixes_reject(self):
        note = b'Time spent: 0.04 seconds\nwarning: model annotation\xff\n'
        obs = parse(OK, note, status=0)
        self.assertEqual(obs.verdicts, parse(OK, status=0).verdicts)
        evidence = obs.evidence()
        self.assertEqual(base64.b64decode(evidence['stderr_base64']), note)
        for diagnostic in (b'PANIC at source\n', b'internal error: failed\n',
                           b'Fatal error: exception Failure("x")\n', b'capped: OOM-KILLED\n',
                           b'cerberus: internal error, uncaught exception:\n',
                           b'lem: fuel exhausted\n'):
            with self.subTest(diagnostic=diagnostic), self.assertRaises(ProtocolError):
                parse(OK, diagnostic, status=0)

    def test_error_message_is_unescaped_bytes(self):
        raw = b'Error {msg: "failed on "x" at \\tmp\\new"}\n'
        self.assertEqual(parse(raw, status=1).verdicts[0].field('msg'),
                         b'failed on "x" at \\tmp\\new')

    def test_fuel_words_inside_semantic_output_are_data(self):
        payload = b'lem: fuel exhausted\nPANIC at fake\ncapped: OOM-KILLED\n\0\xff'
        for field in ('stdout', 'stderr'):
            original = (field + ': ""').encode()
            replacement = (field + ': "' + escape(payload) + '"').encode()
            obs = parse(OK.replace(original, replacement), status=0)
            self.assertEqual(obs.verdicts[0].field(field), payload)
        explanatory = b'Error {msg: "explaining lem: fuel exhausted"}\n'
        self.assertEqual(parse(explanatory, status=1).verdicts[0].kind, 'Error')

    def test_fuel_records_reject_including_litmus_failure_policy(self):
        fuel = b'Error {msg: "lem: fuel exhausted"}\n'
        for out, err, rc, policy in [
                (fuel, b'', 1, 'batch'), (multi(OK, fuel), b'', 0, 'batch'),
                (OK, b'lem: fuel exhausted\n', 0, 'batch'),
                (b'', b'internal error: lem: fuel exhausted\n', 125, 'litmus'),
                (b'', b'PANIC at LemLib.failwithIImpl LemLib.lean:10:3: lem: fuel exhausted\n', 134, 'litmus')]:
            with self.subTest(policy=policy, rc=rc), self.assertRaisesRegex(ProtocolError, 'fuel exhausted'):
                parse(out, err, rc, policy)

    def test_internal_failure_policy_is_narrow(self):
        ocaml = b'internal error: intentional failure\n'
        lean = b'PANIC at LemLib.failwithIImpl LemLib.lean:10:3: intentional failure\n'
        a = parse(b'', ocaml, 125, 'litmus')
        b = parse(b'', lean, 134, 'litmus')
        self.assertEqual(a.verdicts, b.verdicts)
        for out, err, rc in [(OK, ocaml, 125), (OK, lean, 134), (b'', ocaml, 0),
                              (b'', lean, 137), (b'something else\n', ocaml, 125)]:
            with self.subTest(rc=rc), self.assertRaises(ProtocolError):
                parse(out, err, rc, 'litmus')
        with self.assertRaises(ProtocolError):
            parse(b'', ocaml, 125)

    def test_all_positive_cap_witnesses_reject_regardless_of_parent_status(self):
        banners = [b'capped: OOM-KILLED (memory.events oom_kill=1; command exit 0)\n',
                   b'capped: OOM event recorded in cgroup (memory.events oom_kill=1) though command exited rc=0\n']
        for banner in banners:
            for out, rc in [(OK, 0), (ERR, 1)]:
                for policy in ['batch', 'litmus', 'immaculate']:
                    with self.subTest(rc=rc, policy=policy), self.assertRaises(ProtocolError):
                        parse(out, banner, rc, policy)
        self.assertEqual(parse(OK, b'warning: capped: OOM-KILLED is a banner name\n', 0).verdicts,
                         parse(OK, status=0).verdicts)

    def test_failure_continuation_is_preserved_and_extra_fatal_rejects(self):
        oracle = b'internal error: reason\n'
        lean = b'PANIC at LemLib.failwithIImpl LemLib.lean:10:3: reason\n'
        a = parse(b'', oracle + b'left payload\n', 125, 'litmus')
        b = parse(b'', lean + b'right payload\n', 134, 'litmus')
        self.assertNotEqual(a.verdicts, b.verdicts)
        self.assertEqual(a.verdicts[0].field('msg'), b'reason\nleft payload')
        self.assertEqual(a.verdicts, parse(b'', lean+b'left payload\n', 134, 'litmus').verdicts)
        for extra in [b'Fatal error: exception Failure("second fault")\n',
                      b'PANIC at other\n', b'internal error: second fault\n']:
            with self.subTest(extra=extra), self.assertRaises(ProtocolError):
                parse(b'', lean + extra, 134, 'litmus')

    def test_known_trace_envelopes_only_are_normalized(self):
        lean = b'PANIC at LemLib.failwithIImpl LemLib.lean:10:3: reason\n'
        trace = (b'backtrace:\n/tmp/lean(+0x12) [0x1234]\n'
                 b'timeout: the monitored command dumped core\n'
                 b'/tmp/scripts/capped: line 55: 123 Aborted                 "$@"\n')
        self.assertEqual(parse(b'', lean+trace, 134, 'litmus').verdicts,
                         parse(b'', lean, 134, 'litmus').verdicts)
        for bad in [trace+b'Fatal error: exception Stack_overflow\n',
                    trace.replace(b'/tmp/lean(+0x12) [0x1234]', b'unknown diagnostic')]:
            with self.assertRaises(ProtocolError): parse(b'', lean+bad, 134, 'litmus')
        oracle = (b'internal error: reason\ncerberus: internal error, uncaught exception:\n'
                  b'          Failure("internal error: reason")\n'
                  b'          Called from Lem_list.map in file "lem_list.ml" (inlined), line 171, characters 22-39\n')
        self.assertEqual(parse(b'', oracle, 125, 'litmus').verdicts,
                         parse(b'', lean, 134, 'litmus').verdicts)
        with self.assertRaises(ProtocolError):
            parse(b'', oracle.replace(b'Failure("internal error: reason")', b'Failure("different")'), 125, 'litmus')

    def test_immaculate_validates_before_coarse_crash_projection(self):
        good = b'PANIC at CerbMem.memcmpM.getBytes CerbMem:2774:10: assertion\n'
        self.assertTrue(parse(b'', good, 134, 'immaculate').internal)
        for out, err, rc in [(b'corrupted bytes\n', good, 134),
                             (OK, good, 134), (b'', good, 125),
                             (b'', good.replace(b'assertion', b'lem: fuel exhausted'), 134),
                             (b'', good.replace(b'CerbMem.memcmpM.getBytes', b'Other.unreviewed'), 134)]:
            with self.subTest(out=out, err=err, rc=rc), self.assertRaises(ProtocolError):
                parse(out, err, rc, 'immaculate')

    def test_refusal_validates_the_entire_collection(self):
        self.assertEqual(parse(ERR, status=1).refusal(b'model refused: thread spawn'), b'model refused: thread spawn')
        other = b'Error {msg: "unrelated evaluator failure"}\n'
        for data in [multi(ERR, other), multi(other, ERR), multi(ERR, ERR), multi(ERR, OK)]:
            with self.assertRaises(ProtocolError): parse(data, status=0).refusal(b'model refused: ')
        with self.assertRaises(ProtocolError): parse(other, status=1).refusal(b'model refused: ')

    def test_actual_shell_capture_retains_bytes_and_status(self):
        helper = Path(__file__).with_name('observations.sh')
        with tempfile.TemporaryDirectory() as directory:
            for rc in (0, 1, 124, 137):
                prefix = str(Path(directory) / str(rc))
                script = ('source "$1"; observation_capture "$2" "$3" -c '
                          '\'import sys; sys.stdout.buffer.write(bytes.fromhex(sys.argv[1])); '
                          'sys.stderr.buffer.write(b"diagnostic\\xff\\n"); sys.exit(int(sys.argv[2]))\' '
                          '"$4" "$5"')
                proc = subprocess.run(['bash', '-c', script, 'capture-test', str(helper),
                                       prefix, sys.executable, OK.hex(), str(rc)], capture_output=True)
                self.assertEqual(proc.returncode, rc)
                self.assertEqual(Path(prefix + '.stdout').read_bytes(), OK)
                self.assertEqual(Path(prefix + '.stderr').read_bytes(), b'diagnostic\xff\n')
                self.assertEqual(Path(prefix + '.status').read_text(), f'{rc}\n')
                if rc == 0:
                    self.assertEqual(load_capture(prefix).status, 0)
                else:
                    with self.assertRaises(ProtocolError):
                        load_capture(prefix)


if __name__ == '__main__':
    unittest.main(verbosity=2)
