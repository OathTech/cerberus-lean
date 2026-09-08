#!/usr/bin/env python3
"""Byte-preserving Cerberus plain-batch observations (schema 1).

The normative protocol and lane projections are documented in
lean_frontend/docs/2026-09-05_observation-contract.md. No third-party packages.
"""

from __future__ import annotations

import argparse
import base64
from dataclasses import dataclass
import json
from pathlib import Path
import re
import sys


class ProtocolError(ValueError):
    pass


SHORT = {ord('n'): 10, ord('t'): 9, ord('r'): 13, ord('b'): 8,
         ord('"'): 34, ord('\\'): 92}
ESCAPED = rb'(?:[^"\\\r\n]|\\["\\ntrb]|\\[0-9]{3})*'
DEFINED = re.compile(rb'Defined \{value: "([^"\r\n]*)", stdout: "(' +
                     ESCAPED + rb')", stderr: "(' + ESCAPED +
                     rb')", blocked: "(true|false)"\}')
UNDEFINED = re.compile(rb'Undefined \{ub: "([^"\r\n]*)", stderr: "(' +
                       ESCAPED + rb')", loc: "([^"\r\n]*)"\}')
ERROR = re.compile(rb'Error \{msg: "([^\r\n]*)"\}')
MODEL_FAILURE = re.compile(rb'ModelFailure \{msg: "(' + ESCAPED + rb')"\}')
HEADER = re.compile(rb'EXECUTION ([0-9]+)(?: \(exit = [^\r\n]+\))?:')
ORACLE_INTERNAL = re.compile(rb'^internal error: (.+)$', re.M)
FATAL = re.compile(rb'^(?:PANIC at |internal error: |Fatal error: exception |'
                   rb'cerberus: internal error, uncaught exception:|capped: OOM-KILLED)', re.M)
FUEL_RECORD = re.compile(rb'^(?:Error \{msg: "lem: fuel exhausted"\}|'
                         rb'lem: fuel exhausted|internal error: lem: fuel exhausted|'
                         rb'PANIC at [^\r\n]*: lem: fuel exhausted)$', re.M)
CAP_OOM = re.compile(Path(__file__).with_name('cap_oom.regex').read_bytes().strip(), re.M)
LEAN_PANIC = re.compile(rb'PANIC at ([^ \r\n]+) [^\r\n]+:[0-9]+:[0-9]+: (.+)')
LEAN_FRAME = re.compile(rb'[^\r\n]+\([^()\r\n]*\) \[0x[0-9a-fA-F]+\]')
ABORT_WRAPPER = re.compile(rb'[^\r\n]*/scripts/capped: line [0-9]+: +[0-9]+ Aborted(?: \(core dumped\))? +"\$@"')
OCAML_FRAME = re.compile(rb'          (?:Raised at|Raised by primitive operation at|Called from|Re-raised at) '
                          rb'.+ in file "[^"\r\n]+"(?: \(inlined\))?, lines? [0-9]+(?:-[0-9]+)?, characters [0-9]+-[0-9]+')
OCAML_ENVELOPE = b'cerberus: internal error, uncaught exception:'
# These existing negative pins are coarse CRASH checks, never semantic or
# diagnostic agreement. New panic origins need explicit review here.
IMMACULATE_PANICS = {
    b'CerbMem.memcmpM.getBytes', b'CerbUtils.gcc_builtin_bswap64',
    b'_private.CerbDecode.0.CerbDecode.decode_character_constant_aux',
    b'CerbMem.sizeofCtype_lemFuel', b'CerbFS.fs_opendir',
    b'CerbFloat.truncToInt', b'CerbMem.allocator', b'CerbMem.casePtrval',
}


def unescape(data: bytes) -> bytes:
    out = bytearray()
    i = 0
    while i < len(data):
        c = data[i]
        if c != 92:
            if not 32 <= c <= 126 or c == 34:
                raise ProtocolError('unescaped byte in String.escaped field')
            out.append(c)
            i += 1
        else:
            i += 1
            if i == len(data):
                raise ProtocolError('truncated escape')
            if data[i] in SHORT:
                out.append(SHORT[data[i]])
                i += 1
            else:
                digits = data[i:i + 3]
                if len(digits) != 3 or not digits.isdigit() or int(digits) > 255:
                    raise ProtocolError('invalid decimal byte escape')
                out.append(int(digits))
                i += 3
    return bytes(out)


def escape(data: bytes) -> str:
    short = {v: '\\' + chr(k) for k, v in SHORT.items()}
    return ''.join(short[b] if b in short else chr(b) if 32 <= b <= 126
                   else f'\\{b:03d}' for b in data)


@dataclass(frozen=True)
class Verdict:
    kind: str
    fields: tuple[tuple[str, bytes], ...]

    def field(self, name: str) -> bytes:
        return dict(self.fields)[name]

    def token(self) -> str:
        prefix = {'Defined': 'VAL', 'Undefined': 'UB', 'Error': 'ERR',
                  'InternalError': 'INTERNAL_ERROR', 'ModelFailure': 'MODEL_FAILURE'}[self.kind]
        body = ', '.join(f'{k}: "{escape(v)}"' for k, v in self.fields)
        return f'{prefix}:{{{body}}}'

    def reference(self) -> str:
        if self.kind == 'ModelFailure':
            raise ProtocolError('model fail-stop has no semantic reference projection')
        if self.kind == 'Defined':
            return escape(self.field('value'))
        if self.kind == 'Undefined':
            return escape(self.field('ub'))
        if self.kind == 'Error':
            return 'ERROR'
        return 'INTERNAL_ERROR(' + escape(self.field('msg')).replace(' ', '_') + ')'


@dataclass(frozen=True)
class Observation:
    verdicts: tuple[Verdict, ...]
    expected_exit: int
    stdout: bytes
    stderr: bytes
    status: int | None
    internal: bool = False

    @property
    def model_failure(self) -> bool:
        return any(v.kind == 'ModelFailure' for v in self.verdicts)

    def tokens(self, projection: str = 'full') -> list[str]:
        if projection == 'full':
            return [v.token() for v in self.verdicts]
        if projection == 'values':
            return [('VAL:' + escape(v.field('value'))) if v.kind == 'Defined'
                    else v.token() for v in self.verdicts]
        if projection == 'pin':
            if len(self.verdicts) != 1:
                raise ProtocolError('call-point pin requires exactly one verdict')
            v = self.verdicts[0]
            if v.kind == 'Defined':
                return [escape(v.field('value'))]
            if v.kind == 'Undefined':
                return [v.token().removeprefix('UB:')]
            raise ProtocolError('call-point pin requires Defined or Undefined')
        raise ProtocolError(f'unknown projection {projection}')

    def evidence(self) -> dict:
        return {'schema': 1, 'status': self.status, 'expected_exit': self.expected_exit,
                'completion': ('model_failure' if self.model_failure else
                               'internal_failure' if self.internal else 'complete'),
                'verdicts': [{'kind': v.kind,
                              'fields_hex': {k: x.hex() for k, x in v.fields}}
                             for v in self.verdicts],
                'stdout_base64': base64.b64encode(self.stdout).decode('ascii'),
                'stderr_base64': base64.b64encode(self.stderr).decode('ascii')}

    def refusal(self, prefix: bytes) -> bytes:
        if len(self.verdicts) != 1 or self.verdicts[0].kind != 'Error':
            raise ProtocolError('refusal requires exactly one completed Error verdict')
        message = self.verdicts[0].field('msg')
        if not message.startswith(prefix):
            raise ProtocolError('Error is outside the required refusal domain')
        return message


def failure_message(stderr: bytes, status: int | None, policy: str) -> bytes | None:
    """Decode a failure and its known trace envelope, retaining all payload.

    Unknown continuation before a trace is message content, not discarded
    diagnostics. Extra fatal records and unrecognized trace lines reject.
    Exact single-line OCaml/Lean header-only captures remain supported.
    """
    lines = stderr.split(b'\n')
    if lines[-1] == b'':
        lines.pop()  # the printer's final newline; additional newlines are data
    if not lines:
        return None
    lean = LEAN_PANIC.fullmatch(lines[0])
    oracle = ORACLE_INTERNAL.fullmatch(lines[0])
    envelope_only = lines[0] == OCAML_ENVELOPE and policy == 'immaculate'
    if not lean and not oracle and not envelope_only:
        return None
    if status != (134 if lean else 125):
        raise ProtocolError('internal failure has the wrong exit status')
    if lean:
        if lean[1] != b'LemLib.failwithIImpl' and not (
                policy == 'immaculate' and lean[1] in IMMACULATE_PANICS):
            raise ProtocolError('unreviewed panic origin')
        payload = [lean[2]]
        remaining = lines[1:]
        if b'backtrace:' in remaining:
            at = remaining.index(b'backtrace:')
            payload += remaining[:at]
            trace = remaining[at + 1:]
            frames = 0
            while trace and LEAN_FRAME.fullmatch(trace[0]):
                frames += 1
                trace.pop(0)
            if not frames:
                raise ProtocolError('empty or malformed Lean backtrace')
            if trace and trace[0] == b'timeout: the monitored command dumped core':
                trace.pop(0)
            if trace and ABORT_WRAPPER.fullmatch(trace[0]):
                trace.pop(0)
            if trace:
                raise ProtocolError('unexpected diagnostic after Lean backtrace')
        else:
            payload += remaining
    else:
        payload = [oracle[1]] if oracle else []
        remaining = lines[1:] if oracle else lines
        if OCAML_ENVELOPE in remaining:
            at = remaining.index(OCAML_ENVELOPE)
            payload += remaining[:at]
            trace = remaining[at + 1:]
            if not trace or not trace[0].startswith(b'          '):
                raise ProtocolError('missing OCaml exception payload')
            exception = trace.pop(0)[10:]
            failure = re.fullmatch(rb'Failure\("(' + ESCAPED + rb')"\)', exception)
            if oracle:
                if not failure or unescape(failure[1]) != b'internal error: ' + b'\n'.join(payload):
                    raise ProtocolError('OCaml exception does not repeat its complete failure message')
            else:
                if not (failure or exception in (b'Z.Overflow', b'Division_by_zero', b'Not_found') or
                        re.fullmatch(rb'File "[^"\r\n]+", line [0-9]+, characters [0-9]+-[0-9]+: Assertion failed', exception)):
                    raise ProtocolError('unreviewed OCaml exception form')
                payload = [unescape(failure[1]) if failure else exception]
            if not trace or not all(OCAML_FRAME.fullmatch(line) for line in trace):
                raise ProtocolError('missing or unrecognized OCaml exception trace')
        else:
            payload += remaining
    message = b'\n'.join(payload)
    # The leading payload is the recognized failure itself. A second fatal
    # line inside its continuation is not an ignorable diagnostic envelope.
    if FATAL.search(b'\n'.join(payload[1:])) or FUEL_RECORD.search(message):
        raise ProtocolError('additional fatal/fuel record inside failure payload')
    return message


def parse(stdout: bytes, stderr: bytes = b'', status: int | None = None,
          policy: str = 'batch') -> Observation:
    if b'\x00' in stdout:
        raise ProtocolError('raw NUL in batch protocol (capture retained)')
    if CAP_OOM.search(stderr) or status == 137:
        raise ProtocolError('engine killed or exited 137; no completed observation')
    if status == 124:
        raise ProtocolError('engine timeout; exploration incomplete')
    if b'\x1b' in stderr:
        # Cmdliner 2.x styles the oracle's diagnostics (incl. the uncaught-
        # exception envelope) from NO_COLOR/TERM regardless of isatty; a
        # styled envelope would otherwise miss every exact match below and
        # fall through to "outside batch protocol" (2026-09-06 landing
        # finding, 13 immaculate rows). Never stripped: scripts/common.sh
        # pins NO_COLOR=1 / TERM=dumb for every engine invocation, and this
        # is the loud witness that an engine ran outside that pin.
        raise ProtocolError('styled (ANSI) diagnostics in engine stderr; '
                            'the harness must run engines with NO_COLOR=1 / TERM=dumb')
    all_output = stdout + b'\n' + stderr
    # Match complete failure/diagnostic records, never a substring of an
    # escaped semantic output field or of an unrelated Error message.
    if FUEL_RECORD.search(all_output):
        raise ProtocolError('fuel exhausted; exploration incomplete')
    if policy in ('litmus', 'immaculate'):
        message = failure_message(stderr, status, policy)
        if message is not None:
            if stdout:
                raise ProtocolError('unexpected stdout beside internal failure')
            v = Verdict('InternalError', (('msg', message),))
            return Observation((v,), status, stdout, stderr, status, True)
    if FATAL.search(all_output):
        raise ProtocolError('fatal engine diagnostic; no completed observation')
    if status is not None and status not in (0, 1):
        raise ProtocolError(f'engine exit {status} outside batch protocol')
    verdicts = []
    headers = 0
    pending = False
    for line in stdout.split(b'\n'):
        if not line:
            continue
        h = HEADER.fullmatch(line)
        if h:
            if pending or len(verdicts) != headers or int(h.group(1)) != headers:
                raise ProtocolError('invalid/missing execution framing')
            headers += 1
            pending = True
            continue
        d, u, e = DEFINED.fullmatch(line), UNDEFINED.fullmatch(line), ERROR.fullmatch(line)
        if d:
            v = Verdict('Defined', (('value', d[1]), ('stdout', unescape(d[2])),
                                    ('stderr', unescape(d[3])), ('blocked', d[4])))
        elif u:
            v = Verdict('Undefined', (('ub', u[1]), ('stderr', unescape(u[2])), ('loc', u[3])))
        elif e:
            v = Verdict('Error', (('msg', e[1]),))
        elif f := MODEL_FAILURE.fullmatch(line):
            v = Verdict('ModelFailure', (('msg', unescape(f[1])),))
        else:
            raise ProtocolError('unknown or malformed stdout record: ' + repr(line[:160]))
        if headers and not pending:
            raise ProtocolError('multiple verdicts under one execution header')
        verdicts.append(v)
        pending = False
    if not verdicts or pending:
        raise ProtocolError('empty or truncated observation')
    if (headers and (headers != len(verdicts) or headers < 2)) or (
            not headers and len(verdicts) != 1):
        raise ProtocolError('missing or spurious multi-execution framing')
    expected = int(len(verdicts) == 1 and verdicts[0].kind != 'Defined')
    if status is not None and status != expected:
        raise ProtocolError(f'exit {status} inconsistent with verdicts; expected {expected}')
    obs = Observation(tuple(verdicts), expected, stdout, stderr, status)
    if obs.model_failure and policy not in ('model-failure', 'immaculate'):
        raise ProtocolError('model fail-stop; no completed semantic observation')
    if obs.model_failure and status is None:
        raise ProtocolError('model fail-stop classification requires original exit status')
    return obs


def load_capture(prefix: str, policy: str = 'batch') -> Observation:
    path = Path(prefix)
    if Path(str(path) + '.capture-error').exists():
        raise ProtocolError(f'capture failed or reused its prefix: {prefix}')
    return parse(Path(str(path) + '.stdout').read_bytes(),
                 Path(str(path) + '.stderr').read_bytes(),
                 int(Path(str(path) + '.status').read_text()), policy)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['tokens', 'expected-exit', 'inspect',
                                           'reference-set', 'messages', 'compare', 'refusal', 'model-failure'])
    parser.add_argument('--stdout', default='-')
    parser.add_argument('--stderr')
    parser.add_argument('--status', type=int)
    parser.add_argument('--capture', help='prefix of .stdout/.stderr/.status files')
    parser.add_argument('--other', help='second capture prefix for compare')
    parser.add_argument('--policy', choices=['batch', 'litmus', 'immaculate', 'model-failure'], default='batch')
    parser.add_argument('--refusal-prefix', default='model refused: ')
    parser.add_argument('--projection', choices=['full', 'values', 'pin'], default='full')
    parser.add_argument('--comparison', choices=['sequence', 'set'], default='sequence')
    args = parser.parse_args()
    if args.action == 'model-failure':
        args.policy = 'model-failure'
    try:
        if args.capture:
            obs = load_capture(args.capture, args.policy)
            if args.status is not None and args.status != obs.status:
                raise ProtocolError('capture status differs from original runner status')
        else:
            stdout = sys.stdin.buffer.read() if args.stdout == '-' else Path(args.stdout).read_bytes()
            stderr = Path(args.stderr).read_bytes() if args.stderr else b''
            obs = parse(stdout, stderr, args.status, args.policy)
        if args.action == 'model-failure':
            if not obs.model_failure:
                return 1
            print('MODEL_FAILURE')
        elif args.action == 'tokens':
            print('\n'.join(obs.tokens(args.projection)))
        elif args.action == 'expected-exit':
            print(obs.expected_exit)
        elif args.action == 'inspect':
            print(json.dumps(obs.evidence(), sort_keys=True))
        elif args.action == 'reference-set':
            print('{' + ','.join(sorted({v.reference() for v in obs.verdicts})) + '}')
        elif args.action == 'messages':
            for v in obs.verdicts:
                if v.kind in ('Error', 'InternalError', 'ModelFailure'):
                    print(escape(v.field('msg')))
        elif args.action == 'refusal':
            print(escape(obs.refusal(args.refusal_prefix.encode('utf-8'))))
        elif args.action == 'compare':
            if not args.capture or not args.other:
                raise ProtocolError('compare requires two complete captures')
            other = load_capture(args.other, args.policy)
            if obs.model_failure or other.model_failure:
                raise ProtocolError('model fail-stops cannot certify semantic agreement')
            left, right = obs.verdicts, other.verdicts
            equal = set(left) == set(right) if args.comparison == 'set' else left == right
            if not equal:
                print('OBSERVATION DIFFERENCE', file=sys.stderr)
                print(json.dumps({'left': obs.evidence(), 'right': other.evidence()},
                                 sort_keys=True), file=sys.stderr)
                return 1
    except (ProtocolError, OSError, ValueError) as exc:
        print(f'OBSERVATION ERROR: {exc}', file=sys.stderr)
        return 2
    return 0


if __name__ == '__main__':
    sys.exit(main())
