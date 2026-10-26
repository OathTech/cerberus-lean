#!/usr/bin/env python3
"""Byte-preserving Cerberus plain-batch observations (schema 1).

The normative protocol and lane projections are documented in
lean_frontend/docs/2026-09-05_observation-contract.md. No third-party packages.

Projections: `full` (every lane row; the complete verdict tokens), `values`,
`pin`, and the EXPLICIT OPT-IN `failure-class` — the `full` tokens with
`Symbol(<digits>, ` rewritten to `Symbol(_, ` inside Error/Undefined payloads
and nothing else (semantics-audit repairs 2026-09-11, charter D3(g) / §8 item
2). It exists for exactly one lane row, LADDER Tier A row 6b
(`test_multi_tu.sh --failure-class-projection tests/multi_tu_tray`): fork
OCaml and Lean number symbols differently, so an `Error` whose text quotes a
symbol is a `full` MISMATCH even when the two engines agree; the projection
elides the numbering and NOTHING else (Defined tokens untouched; any other
payload byte still differs). Applying it to an existing lane row is forbidden
(charter §3). ONE further consumer, which never grants agreement: the PNVI lane's
classifier (scripts/pnvi_lane.py, S4 review F1, 2026-10-07) consults it only to
decide whether two single-`Error` verdicts are the same failure for the non-
agreement class BOTH_FAIL (VALIDATION §1(a)); its AGREE comparison and every
hash stay on `full`.
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
# origin, then the `<module>:<line>:<col>` location (no spaces — pre-merge audit N8: a
# free-form location field absorbed a stray second space after the origin), then the message
LEAN_PANIC = re.compile(rb'PANIC at ([^ \r\n]+) ([^ \r\n]+:[0-9]+:[0-9]+): (.+)')
LEAN_FRAME = re.compile(rb'[^\r\n]+\([^()\r\n]*\) \[0x[0-9a-fA-F]+\]')
ABORT_WRAPPER = re.compile(rb'[^\r\n]*/scripts/capped: line [0-9]+: +[0-9]+ Aborted(?: \(core dumped\))? +"\$@"')
OCAML_FRAME = re.compile(rb'          (?:Raised at|Raised by primitive operation at|Called from|Re-raised at) '
                          rb'.+ in file "[^"\r\n]+"(?: \(inlined\))?, lines? [0-9]+(?:-[0-9]+)?, characters [0-9]+-[0-9]+')
OCAML_ENVELOPE = b'cerberus: internal error, uncaught exception:'
# `failure-class` projection: the one shape it rewrites — a symbol's NUMBER as
# `Symbol.show` prints it (`Symbol(<digits>, <description>)`, symbol.lem).
SYMBOL_NUMBER = re.compile(rb'Symbol\([0-9]+, ')
# The one panic origin every policy accepts: LemLib's failure leaf. Its impl is
# `private` (lem-lean lean-lib/LemLib.lean:167 `private unsafe def failwithIImpl`),
# so the runtime prints the PRIVATE-MANGLED name — the unmangled
# `LemLib.failwithIImpl` this constant replaced (seam-hygiene H1, 2026-09-19,
# lean_frontend/docs/2026-09-18_seam-hygiene-record.md §3) is NEVER printed and
# was a dead accept (real transcripts: that record's evidence `after-*.stderr`).
LEMLIB_FAILWITHI_ORIGIN = b'_private.LemLib.0.failwithIImpl'
# Seam panic origins the IMMACULATE policy additionally accepts — the coarse
# CRASH pins, never semantic or diagnostic agreement. Since seam-hygiene H1 every
# hand-written failure site of the exec closure is LemLib's `failwithI` (the
# register scripts/failure_reach_register.txt is the review); the ONE seam site
# that still panicked under its own name after H1 — CerberusImpl.lean
# typeof_enum_impl, the enum registry read — was DELETED by program-data
# parameters E-A (2026-09-20: the enum's compatible type is program data; the
# lookup miss is a `failwithI` leaf, so it arrives under the LemLib origin like
# every other seam failure). The set is EMPTY and the mechanism stays fail-closed:
# anything not the LemLib origin is ProtocolError('unreviewed panic origin'); a
# new origin needs explicit review here.
IMMACULATE_PANICS = set()


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
        if projection == 'failure-class':
            # LADDER Tier A row 6b ONLY (module docstring): Error/Undefined
            # payload fields with symbol numbers elided; every other verdict
            # kind is its `full` token byte for byte.
            return [Verdict(v.kind, tuple((k, SYMBOL_NUMBER.sub(b'Symbol(_, ', x))
                                          for k, x in v.fields)).token()
                    if v.kind in ('Error', 'Undefined') else v.token()
                    for v in self.verdicts]
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
        if lean[1] != LEMLIB_FAILWITHI_ORIGIN and not (
                policy == 'immaculate' and lean[1] in IMMACULATE_PANICS):
            raise ProtocolError('unreviewed panic origin')
        payload = [lean[3]]
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


# Outcome protocol v1 (design-v2 §2). This additive API does not change any
# legacy lane policy. Host resource evidence and ordinary comparison stay with
# the caller. Positions below are one-based lines and zero-based byte offsets.
STOP_PREFIX = b'cerberus-lean stop '
STOP_RESERVED = b'cerberus-lean stop'
# The driver's informational switch-set report (CerbDriverConfig.switchReport),
# printed on stderr after a COMPLETED run (never after a panic, never before a
# CLI stop): exactly one well-formed line is admitted and retained; a malformed
# or duplicate one is a problem (inner_arg_temps post-rebase adaptation, 2026-10-26).
SWITCH_REPORT_PREFIX = b'cerberus-lean switches:'
SWITCH_REPORT = re.compile(rb'cerberus-lean switches: \[(?:[A-Za-z_][A-Za-z0-9_]*(?:,[A-Za-z_][A-Za-z0-9_]*)*)?\]')
STOP_BOUNDARIES = frozenset((
    'fs', 'pnvi', 'switches', 'concurrency', 'float-format', 'cli', 'runtime',
    'library-location', 'cabs-json-utf8', 'batch-ub-payload', 'abort-flag',
    'fuel-arg', 'address-space-arg'))
STOP_PANIC = re.compile(rb'PANIC at _private\.LemLib\.0\.failwithIImpl '
                        rb'LemLib:[1-9][0-9]*:[1-9][0-9]*: (.*)')
STOP_ABORT_WRAPPER = re.compile(
    rb'(?:[^\r\n]*/)?scripts/capped: line [0-9]+: +[0-9]+ '
    rb'Aborted(?: +\(core dumped\))? +"\$@"')
# The installed cap wrapper used by Caesium runs this literal subshell.
# Source-checked terminal alternative, design-v2 §4.1 amendment (E.1).
# Match the command exactly; this is not a general Bash diagnostic parser.
STOP_CAPPED_SUBSHELL = (
    b'( { echo "$BASHPID" > "$cg/cgroup.procs"; } 2> /dev/null || '
    b'{ echo "$prog: could not move into $cg: refusing to run uncapped" 1>&2; exit 4; }; '
    b'exec env CAPPED_STATE=1 CAPPED_MEM_MAX="$MEM" "$0" "$@" )')
STOP_INSTALLED_ABORT_WRAPPER = re.compile(
    rb'(?:[^\r\n]*/)?capped: line [0-9]+: +[0-9]+ '
    rb'Aborted(?: +\(core dumped\))? +' + re.escape(STOP_CAPPED_SUBSHELL))
CORE_DUMP = b'timeout: the monitored command dumped core'
FUEL_PAYLOAD = b'lem: fuel exhausted'


@dataclass(frozen=True)
class Upstream:
    repository: str
    revision: str
    path: str
    # Canonical PosText, kept as text to avoid machine-size / digit-count limits.
    first: str
    last: str
    text: str


@dataclass(frozen=True)
class Tray:
    state: str
    number: str | None = None
    url: str | None = None


@dataclass(frozen=True)
class Refusal:
    boundary: str
    item: str | None
    detail: str
    mover: str
    upstream: Upstream | None
    see: str | None

    @property
    def kind(self) -> str:
        return 'REFUSAL'


@dataclass(frozen=True)
class UpstreamCrash:
    site: str
    detail: str
    upstream: Upstream
    tray: Tray
    see: str | None

    @property
    def kind(self) -> str:
        return 'UPSTREAM_CRASH'


@dataclass(frozen=True)
class Invariant:
    site: str
    detail: str
    see: str

    @property
    def kind(self) -> str:
        return 'INVARIANT'


Stop = Refusal | UpstreamCrash | Invariant


def _stop_text(value, nonempty=False) -> str:
    if not isinstance(value, str) or (nonempty and not value):
        raise ProtocolError('expected ' + ('nonempty ' if nonempty else '') + 'string')
    return value


def _stop_optional(value, parse):
    return None if value is None else parse(value)


def _stop_positive(value) -> str:
    value = _stop_text(value)
    if not re.fullmatch(r'[1-9][0-9]*', value):
        raise ProtocolError('expected canonical positive decimal string')
    return value


def _stop_upstream(value) -> Upstream:
    if not isinstance(value, list) or len(value) != 6:
        raise ProtocolError('expected six-field upstream tuple')
    repo, revision, path, first, last, text = map(_stop_text, value)
    if repo not in ('cerberus', 'lem'):
        raise ProtocolError('unknown upstream repository')
    if not re.fullmatch(r'[0-9a-f]{40}', revision):
        raise ProtocolError('invalid full revision')
    if any(part in ('', '.', '..') for part in path.split('/')):
        raise ProtocolError('invalid repository-relative path')
    _stop_positive(first)
    _stop_positive(last)
    if (len(first), first) > (len(last), last):
        raise ProtocolError('invalid source line range')
    return Upstream(repo, revision, path, first, last, text)


def _stop_https(url: str) -> bool:
    return (url.startswith('https://') and bool(re.split(r'[/\?#]', url[8:])[0])
            and all(ord(c) > 32 and ord(c) != 127 and c != '\\' for c in url))


def _stop_tray(value) -> Tray:
    if value == ['none'] or value == ['pending']:
        return Tray(value[0])
    if isinstance(value, list) and len(value) == 2:
        state, data = value
        if state == 'draft':
            return Tray(state, number=_stop_positive(data))
        if state == 'filed' and _stop_https(_stop_text(data)):
            return Tray(state, url=data)
    raise ProtocolError('unknown tray, invalid HTTPS URL or tuple shape')


def _stop_escapes(body: str) -> None:
    """Validate escape tokens before the stock parser can normalize them."""
    i = 0
    while i < len(body):
        c = body[i]
        if c in '\r\n':
            raise ProtocolError('raw line break in stop JSON')
        if c == '\\':
            i += 1
            if i == len(body):
                raise ProtocolError('truncated JSON escape')
            if body[i] == 'u':
                digits = body[i + 1:i + 5]
                if not re.fullmatch(r'00[01][0-9a-fA-F]', digits):
                    raise ProtocolError('wire Unicode escape must encode U+0000–U+001F')
                i += 4
            elif body[i] not in '"\\/bfnrt':
                raise ProtocolError('invalid JSON escape')
        i += 1


def parse_stop(payload: bytes) -> Stop | None:
    """None means absent; a malformed reserved envelope raises ProtocolError.

    Call only at a stop position, never on a program-data or ordinary Error field.
    The capture decoder below retains errors instead of raising away a collection.
    """
    if not payload.startswith(STOP_RESERVED):
        return None
    if not payload.startswith(STOP_PREFIX):
        raise ProtocolError('invalid reserved-prefix suffix')
    try:
        body = payload[len(STOP_PREFIX):].decode('utf-8', errors='strict')
        _stop_escapes(body)
        value = json.loads(body)
    except (UnicodeError, ValueError, RecursionError) as error:
        raise ProtocolError(f'malformed stop JSON: {error}') from error
    if not isinstance(value, list) or len(value) < 2 or value[0] != '1':
        raise ProtocolError('unknown version or non-array stop')
    required = lambda v: _stop_text(v, nonempty=True)
    if value[1] == 'REFUSAL' and len(value) == 8:
        _, _, boundary, item, detail, mover, upstream, see = value
        boundary = _stop_text(boundary)
        if boundary not in STOP_BOUNDARIES:
            raise ProtocolError('unknown boundary')
        return Refusal(boundary, _stop_optional(item, _stop_text), required(detail),
                       required(mover), _stop_optional(upstream, _stop_upstream),
                       _stop_optional(see, required))
    if value[1] == 'UPSTREAM_CRASH' and len(value) == 7:
        _, _, site, detail, upstream, tray, see = value
        return UpstreamCrash(required(site), required(detail), _stop_upstream(upstream),
                             _stop_tray(tray), _stop_optional(see, required))
    if value[1] == 'INVARIANT' and len(value) == 5:
        return Invariant(*map(required, value[2:]))
    raise ProtocolError('unknown constructor or tuple shape')


@dataclass(frozen=True)
class SourcePosition:
    line: int
    offset: int


@dataclass(frozen=True)
class StopOccurrence:
    channel: str
    execution: int | None
    position: SourcePosition
    stop: Stop


@dataclass(frozen=True)
class LegacyPanic:
    payload: bytes
    position: SourcePosition
    # Deliberately no upstream/shared classification.


@dataclass(frozen=True)
class FuelOccurrence:
    form: str
    execution: int | None
    position: SourcePosition


@dataclass(frozen=True)
class StopProblem:
    channel: str
    position: SourcePosition
    reason: str


@dataclass
class StopDecode:
    stops: list[StopOccurrence]
    legacy_panics: list[LegacyPanic]
    fuel: list[FuelOccurrence]
    problems: list[StopProblem]
    switch_report: bytes | None = None


def _stop_lines(data: bytes):
    offset = 0
    chunks = data.split(b'\n')
    for number, line in enumerate(chunks, 1):
        complete = number < len(chunks)
        if complete or line:
            yield line, SourcePosition(number, offset), complete
        offset += len(line) + 1


def decode_stop(stdout: bytes, stderr: bytes, status: int) -> StopDecode:
    """Decode every complete emitted stop, retaining metadata beside problems.

    This is not a completion or comparison predicate. Inspect every collection,
    then use the existing ordinary-observation checks. No host cause is inferred.
    Order is stdout record order, then stderr record order; no chronology between
    separate streams can be reconstructed. Original captures remain with callers.
    """
    result = StopDecode([], [], [], [])

    def problem(channel, position, reason):
        result.problems.append(StopProblem(channel, position, reason))

    def envelope(payload, channel, execution, position):
        try:
            stop = parse_stop(payload)
        except ProtocolError as error:
            problem(channel, position, str(error))
            return None
        if stop is None:
            problem(channel, position, 'missing stop envelope')
        else:
            result.stops.append(StopOccurrence(channel, execution, position, stop))
        return stop

    origin = SourcePosition(1, 0)
    headers = records = 0
    pending = False
    current = None
    first_kind = None
    for line, position, complete in _stop_lines(stdout):
        if not complete:
            problem('stdout', position, 'truncated record (missing LF)')
            continue
        if b'\x00' in line or b'\x1b' in line or b'\r' in line:
            problem('stdout', position, 'raw NUL, ANSI or CR in framing')
        if not line:
            problem('stdout', position, 'empty line outside batch framing')
            continue
        header = HEADER.fullmatch(line)
        if header:
            if pending or records != headers or header[1] != str(headers).encode('ascii'):
                problem('stdout', position, 'invalid/missing execution framing')
            # Preserve even a wrong explicit index; do not use int(text)'s
            # interpreter-specific digit-count limit as a protocol rule.
            current = 0
            for digit in header[1]:
                current = current * 10 + digit - ord('0')
            headers += 1
            pending = True
            continue
        if (headers and not pending) or (not headers and records):
            problem('stdout', position, 'record without its execution header')
        execution = current if headers else 0
        d, u, e = DEFINED.fullmatch(line), UNDEFINED.fullmatch(line), ERROR.fullmatch(line)
        f = MODEL_FAILURE.fullmatch(line)
        kind = None
        try:
            if d:
                unescape(d[2]); unescape(d[3])
                kind = 'Defined'
            elif u:
                unescape(u[2])
                kind = 'Undefined'
            elif e:
                kind = 'Error'
                if e[1] == FUEL_PAYLOAD:
                    result.fuel.append(FuelOccurrence('kill', execution, position))
            elif f:
                kind = 'ModelFailure'
                stop = envelope(unescape(f[1]), 'model-failure', execution, position)
                if isinstance(stop, Refusal):
                    problem('model-failure', position, 'REFUSAL is not a typed-kill class')
            else:
                problem('stdout', position, 'unknown or malformed batch record')
        except ProtocolError as error:
            problem('stdout', position, str(error))
        if kind:
            first_kind = first_kind or kind
            records += 1
        pending = False
    if stdout:
        if not records or pending or (headers and (headers != records or headers < 2)):
            problem('stdout', origin, 'empty/truncated or invalid batch framing')
        if not headers and records != 1:
            problem('stdout', origin, 'missing multi-execution framing')
        expected = int(records == 1 and first_kind != 'Defined')
        if type(status) is not int or status != expected:
            problem('stdout', origin, f'exit {status} inconsistent with batch; expected {expected}')

    lines = list(_stop_lines(stderr))
    if lines:
        for line, position, complete in lines:
            if not complete:
                problem('stderr', position, 'truncated diagnostic (missing LF)')
            if any(c in line for c in (b'\x00', b'\x1b', b'\r')):
                problem('stderr', position, 'raw NUL, ANSI or CR in framing')
        head = lines[0][0]
        panic = STOP_PANIC.fullmatch(head)
        bare_fuel = head == FUEL_PAYLOAD
        if panic or bare_fuel:
            initial_problems = len(result.problems)
            if stdout:
                problem('panic', origin, 'panic requires empty stdout')
            if type(status) is not int or status != 134:
                problem('panic', origin, 'panic requires exit 134')
            payload = panic[1] if panic else FUEL_PAYLOAD
            encoded = payload.startswith(STOP_RESERVED)
            is_fuel = payload == FUEL_PAYLOAD
            # Preserve a complete encoded first-line occurrence even with a bad
            # tail or status. A truncated first line never supplies an occurrence.
            if encoded and lines[0][2]:
                envelope(payload, 'panic', None, origin)
            remaining = lines[1:]
            continuation = []
            if not encoded and not is_fuel:
                while remaining and remaining[0][0] != b'backtrace:':
                    continuation.append(remaining.pop(0)[0])
                for line in continuation:
                    if (line.startswith(STOP_RESERVED) or FATAL.match(line) or
                            FUEL_RECORD.fullmatch(line) or MODEL_FAILURE.fullmatch(line)):
                        problem('panic', origin, 'additional fatal/stop/fuel frame inside legacy payload')
            if remaining and remaining[0][0] == b'backtrace:':
                remaining.pop(0)
                frames = 0
                while remaining and remaining[0][2] and LEAN_FRAME.fullmatch(remaining[0][0]):
                    remaining.pop(0)
                    frames += 1
                if not frames:
                    problem('panic', origin, 'empty or malformed backtrace')
            if remaining and remaining[0][0] == CORE_DUMP:
                remaining.pop(0)
            if remaining and (STOP_ABORT_WRAPPER.fullmatch(remaining[0][0]) or
                              STOP_INSTALLED_ABORT_WRAPPER.fullmatch(remaining[0][0])):
                remaining.pop(0)
            for _, position, _ in remaining:
                problem('panic', position, 'unexpected diagnostic after panic frame')
            valid_frame = (all(complete and not any(c in line for c in (b'\x00', b'\x1b', b'\r'))
                               for line, _, complete in lines)
                           and len(result.problems) == initial_problems)
            if valid_frame:
                if is_fuel:
                    result.fuel.append(FuelOccurrence('translation-panic' if panic else 'bare-panic',
                                                      None, origin))
                elif not encoded:
                    result.legacy_panics.append(LegacyPanic(b'\n'.join([payload] + continuation), origin))
        else:
            cli_stops = []
            for line, position, complete in lines:
                if not complete:
                    continue
                if line.startswith(SWITCH_REPORT_PREFIX):
                    if not SWITCH_REPORT.fullmatch(line):
                        problem('stderr', position, 'malformed switch report')
                    elif result.switch_report is not None:
                        problem('stderr', position, 'duplicate switch report')
                    else:
                        result.switch_report = line
                    continue
                if line.startswith(STOP_RESERVED):
                    stop = envelope(line, 'cli', None, position)
                    if stop:
                        cli_stops.append(stop)
                else:
                    problem('stderr', position, 'unrecognized diagnostic or unreviewed panic origin')
            if cli_stops:
                if stdout or type(status) is not int or status != 2:
                    problem('cli', origin, 'CLI stops require empty stdout and exit 2')
                if not (all(isinstance(s, Refusal) for s in cli_stops) or
                        (len(cli_stops) == 1 and isinstance(cli_stops[0], Invariant))):
                    problem('cli', origin, 'CLI requires refusals only or one invariant')
    if not stdout and not stderr:
        problem('capture', origin, 'unrecognized/truncated capture')
    return result


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
    parser.add_argument('--projection', choices=['full', 'values', 'pin', 'failure-class'], default='full',
                        help="'failure-class' is the opt-in symbol-number-eliding projection of LADDER row 6b only")
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
