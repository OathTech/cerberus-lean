#!/usr/bin/env python3
"""Exercise the built driver's Unicode diagnostic producers through stdin.

Called by test_parse.sh after build_lean. No oracle or model execution is
needed: inputs deliberately fail at the bridge or libc parser boundary.
"""

import argparse
import json
import os
from pathlib import Path
import subprocess
import tempfile

from observations import escape, unescape


ROOT = Path(__file__).resolve().parent.parent


def run(binary, args, value):
    env = {**os.environ, 'LEAN_ABORT_ON_PANIC': '1'}
    result = subprocess.run(
        [str(ROOT / 'scripts/capped'), str(binary), *args, '--stdin'],
        input=json.dumps(value, ensure_ascii=False).encode('utf-8'),
        capture_output=True, timeout=30, cwd=ROOT, env=env)
    if result.returncode != 1:
        raise AssertionError(f'expected refusal exit 1, got {result.returncode}: {result.stderr!r}')
    return result


def check_record(output, message):
    expected = b'Error {msg: "' + escape(message).encode('ascii') + b'"}\n'
    if output != expected:
        raise AssertionError(f'wrong batch bytes: {output!r}, expected {expected!r}')
    # Exercise the strict byte grammar, including its <=255 escape bound.
    assert unescape(output[len(b'Error {msg: "'):-len(b'"}\n')]) == message


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--lean-bin', required=True, type=Path)
    args = parser.parse_args()
    binary = args.lean_bin.resolve()
    count = 0
    # The suffix of stderr is the same producer message, before batch escaping.
    # Checking that it still contains the input avoids a vacuous generic error.
    for value in ['plain', 'é', 'λ', '😀', 'ÿ', '\x00\x08\t\n\r"\\',
                  'Error {msg: "forged"}\nDefined {value: "Specified(0)"}']:
        result = run(binary, ['--batch'], value)
        prefix = b'cerberus-lean: parse error: '
        assert result.stderr.startswith(prefix) and result.stderr.endswith(b'\n'), result.stderr
        message = result.stderr[len(prefix):-1]
        assert value.encode('utf-8') in message, (value, message)
        check_record(result.stdout, b'cabs-json parse error: ' + message)
        count += 1
    # The second changed producer: Core-parser failures during libc loading.
    # A valid empty bridge TU reaches this path before user-program execution.
    with tempfile.TemporaryDirectory(prefix='batch-diagnostics-') as tmp:
        path = Path(tmp) / 'libc-éλ😀.core'
        path.write_text('this is not a Core file', encoding='utf-8')
        value = {'tag': 'TUnit', 'decls': [], 'digest': '0' * 32}
        options = ['--libc', str(path), '--libc-tu', str(Path(tmp) / 'unused.json')]
        human = run(binary, options, value)
        marker = b'  libc load failed: '
        lines = [line for line in human.stdout.splitlines() if line.startswith(marker)]
        assert len(lines) == 1, human.stdout
        message = lines[0][len(marker):]
        assert str(path).encode('utf-8') in message, message
        batch = run(binary, ['--batch', *options], value)
        assert not batch.stderr, batch.stderr
        check_record(batch.stdout, b'libc load failed: ' + message)
        count += 1
    print(f'batch diagnostic producers: {count}/{count} passed')


if __name__ == '__main__':
    main()
