#!/usr/bin/env python3
"""Hermetic process and artifact plants for the independent oracle instrument."""
import json
from pathlib import Path
import os
import sys
import tempfile
import unittest

from build_independent_oracle import CERBERUS_REV, LEM_REV, sha
from test_upstream_oracle import capture, compare, signature, validate_build

OK = b'Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}\n'


class UpstreamInstrumentTests(unittest.TestCase):
    def pair(self, root, left=(OK, b'', 0), right=(OK, b'', 0)):
        records = []
        for name, (stdout, stderr, status) in zip(('upstream', 'fork'), (left, right)):
            code = (f'import sys; sys.stdout.buffer.write({stdout!r}); '
                    f'sys.stderr.buffer.write({stderr!r}); sys.exit({status})')
            records.append(capture(root / name, [sys.executable, '-c', code], dict(os.environ), 2))
        return records

    def test_real_control_and_same_value_byte_mutation(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            self.assertEqual(compare(*self.pair(root), 'batch')[0], 'semantic_agreement')
            altered = OK.replace(b'stdout: ""', b'stdout: "\\000\\128\\255"')
            self.assertEqual(compare(*self.pair(root, right=(altered, b'', 0)), 'batch')[0], 'difference')

    def test_status_and_fatal_suffix_cannot_hide_behind_verdict(self):
        with tempfile.TemporaryDirectory() as tmp:
            for status in (2, 124, 137):
                pair = self.pair(Path(tmp), right=(OK, b'', status))
                self.assertIn(compare(*pair, 'batch')[0], ('difference', 'incomplete'))
            diagnostic = b'cerberus: internal error, uncaught exception:\n'
            pair = self.pair(Path(tmp), left=(OK, diagnostic, 0), right=(OK, diagnostic, 0))
            self.assertEqual(compare(*pair, 'batch')[0], 'difference')

    def test_only_elapsed_diagnostic_trailer_is_projected(self):
        with tempfile.TemporaryDirectory() as tmp:
            base = b'tests/input.c:7: type error\n'
            pair = self.pair(Path(tmp), (b'', base + b'Time spent: 0.123 seconds\n', 1),
                             (b'', base + b'Time spent: 0.456 seconds\n', 1))
            self.assertEqual(compare(*pair, 'batch')[0], 'matching_failure')
            self.assertNotEqual(pair[0]['stderr_sha256'], pair[1]['stderr_sha256'])
            pair = self.pair(Path(tmp), (b'', base, 1), (b'', base.replace(b':7:', b':8:'), 1))
            self.assertEqual(compare(*pair, 'batch')[0], 'difference')

    def test_reviewed_difference_moves_fail_closed(self):
        with tempfile.TemporaryDirectory() as tmp:
            pair = self.pair(Path(tmp), (b'', b'upstream backtrace\n', 125), (b'', b'fork backtrace\n', 125))
            pin = dict(upstream=signature(pair[0]), fork=signature(pair[1]), rationale='fixture review')
            self.assertEqual(compare(*pair, 'batch', pin)[0], 'reviewed_difference')
            changed = self.pair(Path(tmp))
            self.assertEqual(compare(*changed, 'batch', pin)[0], 'difference')

    def fixture(self, root):
        sources = {}
        for name, rev in [('lem', LEM_REV), ('cerberus', CERBERUS_REV)]:
            archive = root / (name + '.tar')
            archive.write_bytes(b'hermetic provenance fixture, not a real build')
            sources[name] = {'commit': rev, 'archive_sha256': sha(archive)}
        artifacts = {}
        for name in ('compiler', 'oracle'):
            path = root / name
            path.write_bytes(b'hermetic executable identity fixture')
            artifacts[name] = {'path': str(path), 'sha256': sha(path)}
        for name in ('lem_runtime', 'lem_library', 'generated', 'runtime'):
            directory = root / name
            directory.mkdir()
            (directory / 'resource').write_bytes(b'hermetic resource fixture')
            artifacts[name] = {'root': str(directory), 'files': {'resource': sha(directory / 'resource')}}
        manifest = {'status': 'built', 'sources': sources, 'artifacts': artifacts,
                    'environment': {'DUNE_CACHE': 'disabled', 'GIT_CEILING_DIRECTORIES': str(root)}}
        path = root / 'manifest.json'
        path.write_text(json.dumps(manifest))
        return path

    def test_missing_wrong_and_extra_artifacts_refuse(self):
        for kind in ('missing', 'changed', 'extra', 'source', 'inventory'):
            with self.subTest(kind=kind), tempfile.TemporaryDirectory() as tmp:
                root = Path(tmp)
                path = self.fixture(root)
                validate_build(path)
                if kind == 'missing':
                    (root / 'runtime/resource').unlink()
                elif kind == 'changed':
                    (root / 'compiler').write_bytes(b'foreign compiler')
                elif kind == 'extra':
                    (root / 'runtime/foreign').write_bytes(b'foreign runtime')
                elif kind == 'source':
                    (root / 'lem.tar').write_bytes(b'foreign source')
                else:
                    data = json.loads(path.read_text())
                    data['artifacts']['runtime']['files'] = {}
                    path.write_text(json.dumps(data))
                with self.assertRaises((ValueError, OSError)):
                    validate_build(path)


if __name__ == '__main__':
    unittest.main(verbosity=2)
