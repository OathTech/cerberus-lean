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
HEADER = re.compile(rb'EXECUTION ([0-9]+)(?: \(exit = [^\r\n]+\))?:')
ORACLE_INTERNAL = re.compile(rb'^internal error: (.+)$', re.M)
LEAN_INTERNAL = re.compile(rb'^PANIC at [^\r\n]*failwithIImpl '
                           rb'[^\r\n]*:[0-9]+:[0-9]+: (.+)$', re.M)
FATAL = re.compile(rb'^(?:PANIC at |internal error: |Fatal error: exception |'
                   rb'cerberus: internal error, uncaught exception:|capped: OOM-KILLED)', re.M)


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
                  'InternalError': 'INTERNAL_ERROR'}[self.kind]
        body = ', '.join(f'{k}: "{escape(v)}"' for k, v in self.fields)
        return f'{prefix}:{{{body}}}'

    def reference(self) -> str:
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
                'completion': 'internal_failure' if self.internal else 'complete',
                'verdicts': [{'kind': v.kind,
                              'fields_hex': {k: x.hex() for k, x in v.fields}}
                             for v in self.verdicts],
                'stdout_base64': base64.b64encode(self.stdout).decode('ascii'),
                'stderr_base64': base64.b64encode(self.stderr).decode('ascii')}


def parse(stdout: bytes, stderr: bytes = b'', status: int | None = None,
          policy: str = 'batch') -> Observation:
    if b'\x00' in stdout:
        raise ProtocolError('raw NUL in batch protocol (capture retained)')
    if b'capped: OOM-KILLED' in stderr or status == 137:
        raise ProtocolError('engine killed or exited 137; no completed observation')
    if status == 124:
        raise ProtocolError('engine timeout; exploration incomplete')
    all_output = stdout + b'\n' + stderr
    if b'lem: fuel exhausted' in all_output:
        raise ProtocolError('fuel exhausted; exploration incomplete')
    if policy == 'litmus':
        oracle = list(ORACLE_INTERNAL.finditer(all_output))
        lean = list(LEAN_INTERNAL.finditer(all_output))
        matches = oracle + lean
        if matches:
            if len(matches) != 1 or re.search(rb'^(Defined|Undefined|Error|EXECUTION)\b',
                                              stdout, re.M):
                raise ProtocolError('mixed verdicts and internal failure')
            expected = 125 if oracle else 134
            if status != expected:
                raise ProtocolError(f'internal failure exit {status}; expected {expected}')
            # No extra stdout may be smuggled in with the recognized failure.
            remaining = ORACLE_INTERNAL.sub(b'', LEAN_INTERNAL.sub(b'', stdout)).strip()
            if remaining:
                raise ProtocolError('unexpected stdout beside internal failure')
            v = Verdict('InternalError', (('msg', matches[0].group(1)),))
            return Observation((v,), expected, stdout, stderr, status, True)
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
    return Observation(tuple(verdicts), expected, stdout, stderr, status)


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
                                           'reference-set', 'messages', 'compare'])
    parser.add_argument('--stdout', default='-')
    parser.add_argument('--stderr')
    parser.add_argument('--status', type=int)
    parser.add_argument('--capture', help='prefix of .stdout/.stderr/.status files')
    parser.add_argument('--other', help='second capture prefix for compare')
    parser.add_argument('--policy', choices=['batch', 'litmus'], default='batch')
    parser.add_argument('--projection', choices=['full', 'values', 'pin'], default='full')
    parser.add_argument('--comparison', choices=['sequence', 'set'], default='sequence')
    args = parser.parse_args()
    try:
        if args.capture:
            obs = load_capture(args.capture, args.policy)
            if args.status is not None and args.status != obs.status:
                raise ProtocolError('capture status differs from original runner status')
        else:
            stdout = sys.stdin.buffer.read() if args.stdout == '-' else Path(args.stdout).read_bytes()
            stderr = Path(args.stderr).read_bytes() if args.stderr else b''
            obs = parse(stdout, stderr, args.status, args.policy)
        if args.action == 'tokens':
            print('\n'.join(obs.tokens(args.projection)))
        elif args.action == 'expected-exit':
            print(obs.expected_exit)
        elif args.action == 'inspect':
            print(json.dumps(obs.evidence(), sort_keys=True))
        elif args.action == 'reference-set':
            print('{' + ','.join(sorted({v.reference() for v in obs.verdicts})) + '}')
        elif args.action == 'messages':
            for v in obs.verdicts:
                if v.kind in ('Error', 'InternalError'):
                    print(escape(v.field('msg')))
        elif args.action == 'compare':
            if not args.capture or not args.other:
                raise ProtocolError('compare requires two complete captures')
            other = load_capture(args.other, args.policy)
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
