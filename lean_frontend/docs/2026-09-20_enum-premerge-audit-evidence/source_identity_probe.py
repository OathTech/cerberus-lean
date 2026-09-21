"""Reproduce E3 using the checked-out release runner; run from repository root.

This recipe was written after the original fixture run. It creates a fresh
ignored scratch repository and changes no machine or repository Git config.
"""
from pathlib import Path
import json
import subprocess
import sys
import tempfile

root = Path.cwd()
sys.path.insert(0, str(root / 'scripts'))
from release import source_identity

scratch = root / '.tmp' / 'enum-premerge'
scratch.mkdir(parents=True, exist_ok=True)
with tempfile.TemporaryDirectory(prefix='source-identity-replay-', dir=scratch) as d:
    fixture = Path(d)
    def git(*args):
        return subprocess.run(['git', *args], cwd=fixture, check=True,
                              capture_output=True, text=True)
    git('init', '-b', 'audit')
    probe = fixture / 'probe'
    probe.write_text('base\n')
    git('add', 'probe')
    git('-c', 'user.name=Audit fixture', '-c', 'user.email=audit@example.invalid',
        '-c', 'commit.gpgsign=false', 'commit', '-m', 'source identity fixture')
    probe.write_text('uncommitted\n')
    before = source_identity(fixture)
    after = source_identity(fixture)
    probe.write_text('changed again\n')
    changed = source_identity(fixture)
    result = {
        'stable_uncommitted_before': before,
        'stable_uncommitted_after': after,
        'changed_after': changed,
        'stable_dirty_unchanged': before == after,
        'changed_dirty_unchanged': before == changed,
    }
    print(json.dumps(result, indent=2))
    assert before == after and before != changed
