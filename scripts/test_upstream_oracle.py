#!/usr/bin/env python3
"""Independent pristine OCaml versus fork OCaml over the fork-vs-Lean lanes' corpora.

Build the pristine side with scripts/ensure_independent_oracle.py first (the lane
itself never builds; a missing or invalid manifest fails closed). Every
unexpected difference fails; the reviewed register scripts/upstream_oracle_
differences.json (schema 2) is the ONLY permitted list of fork≠pristine
behaviours — each row classed, cited, and binding both full observation
signatures. Raw process failures are reported separately from completed
semantic verdicts. WP-O (2026-09-16, lean_frontend/docs/2026-09-16_charter-
pristine-oracle-instrument.md O1) widened the corpus to every corpus the
fork-vs-Lean lanes GATE on (Tier A/B baselines) plus the tests/ci and csmith
reporting corpora, mirroring each owning lane's flags, exclusions and per-case
timeout (cited at each block of corpus()). NOT walked: test_ci_sweep.sh's
fourteen other suites (LADDER Tier C row C4, a scoreboard with no baseline) —
named in the report's not_applicable list.

Scopes: the default selection (`--corpus tier-b`) is LADDER Tier B row 10;
libxml2 chvalid is its own Tier B row (`--corpus libxml2_chvalid`); tests/ci and
the csmith corpus are reporting rows (`--corpus ci`, `--corpus csmith [--shard
K/M]` — the shard arithmetic of scripts/test_csmith_corpus.sh). `--only`,
`--shard` and any selection short of `all` certify only what they ran.
"""
from __future__ import annotations

import argparse
from collections import Counter
from dataclasses import dataclass
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import time

from build_independent_oracle import CERBERUS_REV, LEM_REV, files, sha
from observations import ProtocolError, load_capture
from release import artifacts, source_identity

ROOT = Path(__file__).resolve().parent.parent
REGISTER = ROOT / 'scripts/upstream_oracle_differences.json'
REGISTER_SCHEMA = 2
# Register row classes (charter O1). A pristine-side timeout is admissible ONLY
# through a row of an INCOMPLETE_ADMITTING class whose citation explains the
# non-termination; never for the fork side, never for a signal kill (137).
CLASSES = ('diagnostic-text', 'resource', 'missing-feature', 'shared-model-fix')
INCOMPLETE_ADMITTING = ('resource', 'shared-model-fix')
INCOMPLETE_STATUSES = (124, 137)
# A signature binds the exit status, the raw stdout bytes and the stderr bytes
# under the lane's declared DIAGNOSTIC projection (only the run-varying
# `Time spent: <decimal> seconds` trailer removed; the raw stderr is retained
# in every capture). Schema 1 bound the raw stderr sha, which only a crash
# (no trailer) could ever reproduce — no completing case was pinnable.
SIGNATURE_KEYS = ('status', 'stdout_sha256', 'diagnostic_sha256')
ROW_KEYS = {'class', 'citation', 'rationale', 'upstream', 'fork'}
# Corpus labels -> the rows they belong to. Membership per the WP-O
# measurement table (record 2026-09-16 §O1): everything the fork-vs-Lean lanes
# walk except the csmith corpus, which is its own reporting row.
CORPORA = {
    'tier-b': ('minimal', 'coverage', 'debug', 'float', 'bytes', 'libc_exec', 'multi_tu',
               'multi_tu_tray', 'cn', 'libxml2_uri', 'cli', 'immaculate', 'verify', 'corpus'),
    'libxml2_chvalid': ('libxml2_chvalid',),   # its own Tier B row (~6 min: 4 slices x ~45 s x 2 engines)
    'ci': ('ci',),                             # reporting row: two both-sides timeouts at the mirrored 30 s
    'csmith': ('csmith',),                     # reporting row, sharded
}
CORPORA['all'] = tuple(label for key in ('tier-b', 'libxml2_chvalid', 'ci', 'csmith') for label in CORPORA[key])
# lean_frontend/corpus stems test_verify.sh runs MAIN-mode (test_verify.sh:269);
# the hashed arena programs are pin-provenance only there and are not executed.
CORPUS_MAIN_STEMS = ('p01_clamp', 'p02_sat_add', 'p03_swap_mayalias', 'p09_call_contract',
                     'p10_gcd_rec', 'p11_gcd_iter', 'p12_pt_midpoint')


@dataclass
class Case:
    id: str
    kind: str              # batch | core | typecheck
    flags: list            # oracle arguments after --runtime=<dir>
    corpus: str            # corpus label (CORPORA membership)
    timeout: float | None = None   # the mirrored lane's per-case bound; None = --timeout
    # O2 (--with-lean) recipe mirrored from the fork-vs-Lean lane, or None when the
    # case has no Lean side (the legacy CLI rows): {'tus': [(bridge_flags, source)],
    # 'args': [Lean arguments before the cabs-jsons], 'libc': bool, 'projection': str}
    lean: dict | None = None


LEAN_BIN = ROOT / 'lean_frontend/.lake/build/bin/cerberus-lean'
LEAN_STATUSES = ('lean_agreement', 'lean_difference', 'lean_both_undecodable', 'lean_incomplete',
                 'lean_bridge_failed', 'lean_not_applicable')


def lean_recipe(sources, args, bridge_flags=(), libc=False, projection='full', capped=False):
    # `capped`: the owning lane runs its bridge AND its Lean driver under CAPPED_TEST
    # (test_libc_exec.sh:95/:103, test_immaculate.sh:163/:171, test_libxml2.sh:143/:203/:213,
    # test_libxml2_uri.sh:185 + run_capped :105-108); test_exec.sh, test_bytes.sh,
    # test_multi_tu.sh, test_cn_coverage.sh and test_verify.sh do not (pre-merge audit M5).
    return {'tus': [(list(bridge_flags), str(src)) for src in sources], 'args': list(args),
            'libc': libc, 'projection': projection, 'capped': capped}


def validate_build(path):
    manifest = json.loads(path.read_text())
    if manifest['status'] != 'built' or manifest['sources']['lem']['commit'] != LEM_REV or \
            manifest['sources']['cerberus']['commit'] != CERBERUS_REV:
        raise ValueError('independent build is incomplete or has wrong source pins')
    required = {'compiler', 'lem_runtime', 'lem_library', 'generated', 'oracle', 'runtime'}
    if set(manifest['artifacts']) != required or any(not entry.get('files') for entry in
            manifest['artifacts'].values() if 'root' in entry):
        raise ValueError('independent artifact inventory missing or empty')
    if manifest.get('environment', {}).get('DUNE_CACHE') != 'disabled' or \
            not manifest.get('environment', {}).get('GIT_CEILING_DIRECTORIES'):
        raise ValueError('build recipe did not isolate cache/source-version provenance')
    for name, source in manifest['sources'].items():
        if sha(path.parent / (name + '.tar')) != source['archive_sha256']:
            raise ValueError(f'independent {name} source archive changed')
    for name, entry in manifest['artifacts'].items():
        if 'path' in entry:
            if sha(entry['path']) != entry['sha256']:
                raise ValueError(f'independent {name} artifact changed')
        else:
            if files(Path(entry['root'])) != entry['files']:
                raise ValueError(f'independent {name} resources changed or file set drifted')
    return manifest


def citation_exists(citation: str) -> bool:
    """A citation is a GIT-TRACKED repo-relative file (optionally `:N`/`:N-M` lines that exist in
    it, or `#anchor`) or an ISO-fix id R<n> present in VALIDATION.md §2's register table. A scratch,
    ignored or untracked file is not a record (pre-merge audit N1); `..` components are refused;
    if git is unavailable the check raises and the lane fails closed."""
    if re.fullmatch(r'R[0-9]+', citation):
        table = (ROOT / 'lean_frontend/VALIDATION.md').read_text()
        return re.search(r'^\| \*\*' + citation + r'\*\* \|', table, re.M) is not None
    match = re.fullmatch(r'([^:#]+?)(?::([0-9]+)(?:-([0-9]+))?)?(?:#[^#]*)?', citation)
    if not match:
        return False
    path, start, end = match[1], match[2], match[3]
    if not path or Path(path).is_absolute() or '..' in Path(path).parts or not (ROOT / path).is_file():
        return False
    tracked = subprocess.run(['git', '-C', str(ROOT), 'ls-files', '--error-unmatch', '--', path],
                             capture_output=True)
    if tracked.returncode != 0:
        return False
    if start:
        lines = len((ROOT / path).read_text(errors='replace').splitlines())
        first, last = int(start), int(end) if end else int(start)
        if not 1 <= first <= last <= lines:
            return False
    return True


def load_register(path):
    """Fail-closed schema-2 reader: every row classed, cited, rationalised, two full
    signatures that actually differ; incompleteness only where the charter admits it."""
    data = json.loads(Path(path).read_text())
    if not isinstance(data, dict) or data.get('schema') != REGISTER_SCHEMA:
        raise ValueError(f'register: schema must be {REGISTER_SCHEMA} (found '
                         f'{data.get("schema") if isinstance(data, dict) else type(data).__name__!r}); '
                         f'schema-1 rows carry no class/citation and are refused')
    if set(data) != {'schema', 'cases'} or not isinstance(data['cases'], dict):
        raise ValueError('register: top level must be exactly {"schema", "cases"} with cases an object')
    for case, row in data['cases'].items():
        where = f'register row {case!r}'
        if not isinstance(row, dict) or set(row) != ROW_KEYS:
            found = sorted(row) if isinstance(row, dict) else type(row).__name__
            raise ValueError(f'{where}: keys must be exactly {sorted(ROW_KEYS)} (found {found})')
        if row['class'] not in CLASSES:
            raise ValueError(f'{where}: unknown class {row["class"]!r}; permitted: {list(CLASSES)}')
        citations = row['citation'] if isinstance(row['citation'], list) else [row['citation']]
        if not citations or not all(isinstance(c, str) and c.strip() for c in citations):
            raise ValueError(f'{where}: citation must be a non-empty string or list of them')
        for citation in citations:
            if not citation_exists(citation):
                raise ValueError(f'{where}: citation {citation!r} is neither a git-tracked repo file (with the '
                                 f'cited lines present, no `..`) nor an ISO-fix register id present in VALIDATION.md §2')
        if not isinstance(row['rationale'], str) or not row['rationale'].strip():
            raise ValueError(f'{where}: rationale must be a non-empty string')
        for side in ('upstream', 'fork'):
            signature_ = row[side]
            if not isinstance(signature_, dict) or set(signature_) != set(SIGNATURE_KEYS):
                raise ValueError(f'{where}: {side} signature must have exactly {list(SIGNATURE_KEYS)}')
            status = signature_['status']
            if isinstance(status, bool) or not isinstance(status, int) or not 0 <= status <= 255:
                raise ValueError(f'{where}: {side}.status must be an integer exit status')
            for key in ('stdout_sha256', 'diagnostic_sha256'):
                if not isinstance(signature_[key], str) or not re.fullmatch(r'[0-9a-f]{64}', signature_[key]):
                    raise ValueError(f'{where}: {side}.{key} must be a lowercase sha256 hex digest')
        if row['upstream'] == row['fork']:
            raise ValueError(f'{where}: upstream and fork signatures are identical — the row records no difference')
        if row['fork']['status'] in INCOMPLETE_STATUSES:
            raise ValueError(f'{where}: a fork-side incomplete process (status {row["fork"]["status"]}) is never admissible')
        if row['upstream']['status'] == 137:
            raise ValueError(f'{where}: a pristine-side signal kill (137) is never admissible')
        if row['upstream']['status'] == 124 and row['class'] not in INCOMPLETE_ADMITTING:
            raise ValueError(f'{where}: a pristine-side timeout (124) is admissible only through a row of class '
                             f'{list(INCOMPLETE_ADMITTING)} whose citation explains the non-termination, not '
                             f'{row["class"]!r}')
    return data['cases']


# THE diagnostic projection — the one both `matching_failure` and the register's
# stderr signature use. (1) backend/driver/main.ml's elapsed-time trailer is
# instrumentation: its exact whole-line grammar is removed. (2) [USER 2026-09-17]
# ("(2) agree"): inside OCaml backtrace FRAMES only — `Raised at` / `Raised by
# primitive operation at` / `Called from` / `Re-raised at` … `in file "…"[ (inlined)],
# line N[-M], characters A-B` — the source positions are normalised to
# `line N, characters A-B`: generated-code line numbers shift with every .lem
# edit and the two Lem runtimes' lem_list.ml frames differ, so a both-crash pair
# whose frames differ ONLY in positions is the same failure. The exception text,
# the frame's function and file names, every non-frame line and every stdout byte
# are compared untouched; the raw stderr is retained in every capture.
TIME_SPENT = re.compile(rb'^Time spent: [0-9]+\.[0-9]+ seconds\n', re.M)
FRAME_POSITION = re.compile(
    rb'^( *(?:Raised at|Raised by primitive operation at|Called from|Re-raised at) [^\n]*? in file "[^"\n]*"'
    rb'(?: \(inlined\))?), lines? [0-9]+(?:-[0-9]+)?, characters [0-9]+-[0-9]+$', re.M)


def project_diagnostics(stderr: bytes) -> bytes:
    return FRAME_POSITION.sub(rb'\1, line N, characters A-B', TIME_SPENT.sub(b'', stderr))


def record_of(prefix, status, seconds=0.0, command=()):
    """The comparison record of a completed capture at `prefix` (.stdout/.stderr/.status written)."""
    return {'status': status, 'seconds': round(seconds, 3),
            'stdout_sha256': sha(prefix.with_suffix('.stdout')),
            'stderr_sha256': sha(prefix.with_suffix('.stderr')),
            'diagnostic_sha256': hashlib.sha256(project_diagnostics(prefix.with_suffix('.stderr').read_bytes())).hexdigest(),
            'capture': str(prefix), 'command': list(command)}


def synthetic_record(prefix, status, stdout: bytes, stderr: bytes):
    """A capture written from given bytes (plants only): the same files and record as capture()."""
    prefix.with_suffix('.stdout').write_bytes(stdout)
    prefix.with_suffix('.stderr').write_bytes(stderr)
    prefix.with_suffix('.status').write_text(str(status) + '\n')
    return record_of(prefix, status)


# The per-test memory cap of the capping lanes: scripts/common.sh:389 (`CERB_TEST_MEM_MAX`,
# default 4G) and :401 (`CAPPED_TEST=(env "CERB_MEM_MAX=$TEST_MEM_MAX" "$CAPPED_BIN")`), always
# placed OUTSIDE `timeout` (e.g. test_libc_exec.sh:85/:95/:103).
CAPPED_TEST = ['env', 'CERB_MEM_MAX=' + os.environ.get('CERB_TEST_MEM_MAX', '4G'), str(ROOT / 'scripts/capped')]


def capture(prefix, command, env, limit, wrapper=()):
    started = time.monotonic()
    command = [*map(str, wrapper), 'timeout', str(limit), *map(str, command)]
    prefix.with_suffix('.command.json').write_text(json.dumps(command) + '\n')
    with prefix.with_suffix('.stdout').open('wb') as stdout, prefix.with_suffix('.stderr').open('wb') as stderr:
        proc = subprocess.run(command, cwd=ROOT, env=env, stdout=stdout, stderr=stderr)
    status = proc.returncode if proc.returncode >= 0 else 128 - proc.returncode
    prefix.with_suffix('.status').write_text(str(status) + '\n')
    return record_of(prefix, status, time.monotonic() - started, command)


def signature(record):
    return {key: record[key] for key in SIGNATURE_KEYS}


def compare(left, right, kind, exception=None):
    """left = pristine upstream, right = fork. Returns (status, reason)."""
    # A signal kill (137) on either side is never admitted — registered or not.
    if left['status'] == 137 or right['status'] == 137:
        return 'incomplete', 'signal termination (137) on either side is never admitted'
    if exception is not None:
        # [AGENT, pre-merge audit M1 — the orchestrator's reading of ruling (1) with the standing
        # "pin moved → difference" rule]: a REGISTERED case is ALWAYS judged by its row. Both
        # signatures must reproduce the row exactly; anything else — a fork side that now times
        # out, a both-sides timeout, a moved sha — is `difference` ("reviewed pin moved"). The
        # `matching_incomplete` shortcut below is for UNREGISTERED cases only.
        if right['status'] == 124:
            return 'difference', 'reviewed difference pin moved: the registered fork side timed out (never admissible)'
        if exception.get('rationale') and exception['upstream'] == signature(left) and \
                exception['fork'] == signature(right):
            # A pristine-side timeout is admitted ONLY by a row of an incomplete-admitting class
            # (charter O1: the citation explains the non-termination — draft 37 for `node`); the
            # loader enforces this too, kept here so compare() is fail-closed on its own.
            if left['status'] == 124 and exception['class'] not in INCOMPLETE_ADMITTING:
                return 'incomplete', 'pristine timeout admissible only through a resource/shared-model-fix row'
            return 'reviewed_difference', exception['rationale']
        return 'difference', 'reviewed difference pin moved (stale or changed exception); review before changing it'
    # Unregistered cases from here on.
    # [USER 2026-09-17] ("(1) agree"): BOTH engines exceeded the lane's own bound —
    # the REPORTED class `matching_incomplete`: counted, never agreement, not a
    # failure; no register row is ever written for it. Any ONE-sided timeout
    # stays `incomplete` and fatal exactly as before.
    if left['status'] == 124 and right['status'] == 124:
        return 'matching_incomplete', 'both engines exceeded the lane bound; counted, not agreement'
    if right['status'] == 124:
        return 'incomplete', 'fork-side timeout is never admitted'
    if left['status'] == 124:
        return 'incomplete', 'pristine timeout without an admitting reviewed row (class resource/shared-model-fix)'
    if kind == 'batch':
        try:
            a, b = load_capture(left['capture']), load_capture(right['capture'])
            if a.verdicts == b.verdicts:
                return 'semantic_agreement', ''
            reason = 'completed semantic observations differ'
        except (ProtocolError, OSError, ValueError) as exc:
            reason = str(exc)
            # This is evidence about matching rejection/failure of the CLI,
            # explicitly not a successful semantic execution comparison.
            if all(left[key] == right[key] for key in ('status', 'stdout_sha256', 'diagnostic_sha256')) and \
                    left['status'] in (1, 125, 134):
                raw = Path(left['capture'] + '.stdout').read_bytes()
                err = Path(left['capture'] + '.stderr').read_bytes()
                if not raw and err:
                    return 'matching_failure', 'same failure under diagnostic projection; no semantic result'
    elif signature(left) == signature(right) and left['status'] == 0:
        if Path(left['capture'] + '.stdout').stat().st_size or kind == 'typecheck':
            return 'interface_agreement', ''
        reason = 'unexpected silent interface success'
    else:
        reason = 'legacy interface output/status differs'
    return 'difference', reason


def rel(path):
    return str(Path(path).relative_to(ROOT))


def corpus(cn_root, stage):
    """Every corpus the fork-vs-Lean lanes walk, with each lane's flags, exclusions
    and per-case timeout mirrored (cites are to the lane scripts at WP-O)."""
    cases = []

    def add(case_id, kind, flags, corpus_label, timeout=None, lean=None):
        cases.append(Case(case_id, kind, flags, corpus_label, timeout, lean))

    # Tier A single-file exec corpora: test_exec.sh's exclusions (:403-406
    # `! -name "*.syntax-only.c" ! -name "*.exhaust.c"`) and oracle flags
    # (:442-443 `--nolibc --exec --batch --mode=exhaustive`); test_libc_exec.sh
    # runs the oracle WITH libc (:87 `--exec --batch`, default mode). Per-case
    # bounds, each the owning lane's own: test_exec.sh:169 TIMEOUT_SECS=30
    # (minimal/coverage/debug/float), test_bytes.sh:47 TIMEOUT_SECS=30,
    # test_libc_exec.sh:37 TIMEOUT_SECS=300 (pre-merge audit M2).
    bounds = {'minimal': 30, 'coverage': 30, 'debug': 30, 'float': 30, 'bytes': 30, 'libc_exec': 300}
    for folder in ('minimal', 'coverage', 'debug', 'float', 'bytes', 'libc_exec'):
        paths = sorted((ROOT / 'tests' / folder).rglob('*.c'))
        if not paths:
            raise ValueError(f'missing/empty Tier A corpus: {folder}')
        for path in paths:
            if path.name.endswith(('.syntax-only.c', '.exhaust.c')):
                continue  # same explicit execution exclusions as test_exec.sh
            flags = ['--exec', '--batch']
            if folder != 'libc_exec':
                flags += ['--nolibc', '--mode=exhaustive']
            # Lean (O2): test_exec.sh:445-451 `--cabs-json <c>` -> `--batch <json>`;
            # test_bytes.sh:79-81/:88 bridges with `--nolibc --cabs-json`;
            # test_libc_exec.sh:97/:104-105 `--batch --first --libc … --libc-tu …`.
            if folder == 'libc_exec':
                lean = lean_recipe([rel(path)], ['--batch', '--first'], libc=True, capped=True)
            elif folder == 'bytes':
                lean = lean_recipe([rel(path)], ['--batch'], bridge_flags=['--nolibc'])
            else:
                lean = lean_recipe([rel(path)], ['--batch'])
            add(str(path.relative_to(ROOT / 'tests')), 'batch', flags + [rel(path)], folder, bounds[folder], lean=lean)
    # Multi-TU (test_multi_tu.sh:139 `.c` files in sorted name order; :149-150
    # `--nolibc --exec --batch --mode=exhaustive a.c b.c …`; :66 TIMEOUT_SECS=30).
    # tests/multi_tu_tray is LADDER Tier A row 6b, the SAME engine invocation:
    # the cross-TU struct-value cases pristine upstream loops or rejects on
    # (upstream-tray drafts 37/38/39) — walked here with their reviewed
    # shared-model-fix register rows.
    for folder, label in (('tests/multi_tu', 'multi_tu'), ('tests/multi_tu_tray', 'multi_tu_tray')):
        directories = sorted(p for p in (ROOT / folder).iterdir() if p.is_dir())
        if not directories:
            raise ValueError(f'empty multi-TU corpus: {folder}')
        for directory in directories:
            paths = sorted(directory.glob('*.c'))
            if len(paths) < 2:
                raise ValueError(f'multi-TU case has fewer than two inputs: {directory}')
            # Lean: test_multi_tu.sh:175 one `--cabs-json` per TU, :192 `--batch a.json b.json`;
            # the tray row compares under the codec's `failure-class` projection (LADDER row 6b).
            add(f'{label}/{directory.name}', 'batch',
                ['--exec', '--batch', '--nolibc', '--mode=exhaustive', *map(rel, paths)], label, 30,
                lean=lean_recipe(map(rel, paths), ['--batch'],
                                 projection='failure-class' if label == 'multi_tu_tray' else 'full'))
    if cn_root is None:
        cn_root = next((parent / 'deps/cn/tests/cn' for parent in ROOT.parents
                        if (parent / 'deps/cn/tests/cn').is_dir()), None)
    if cn_root is None:
        raise ValueError('CN corpus missing; provide --cn-root')
    rows = (ROOT / 'tests/cn_coverage/manifest.txt').read_text().splitlines()
    for row in rows:
        if not row or row.startswith('#'):
            continue
        name, classification, extras, note = row.split('|')
        path = cn_root / name
        tus = [path]
        for extra in filter(None, extras.split(',')):
            tus.append(cn_root / extra[3:] if extra.startswith('cn:') else ROOT / 'tests/cn_coverage' / extra)
        if not all(p.is_file() for p in tus):
            raise ValueError(f'CN input missing: {name}')
        # Lean: test_cn_coverage.sh:235 `-I <dir> --cabs-json <tu>` per TU, :239 `--batch <jsons>`;
        # bound :86 TIMEOUT_SECS=30.
        add(f'cn/{name}', 'batch', ['--exec', '--batch', '--nolibc', '--mode=exhaustive',
                                   '-I', str(path.parent), *map(str, tus)], 'cn', 30,
            lean=lean_recipe(map(str, tus), ['--batch'], bridge_flags=['-I', str(path.parent)]))
    prep = subprocess.check_output([str(ROOT / 'scripts/libxml2_prep.sh'), 'uri.c'], text=True).splitlines()
    if not prep:
        raise ValueError('libxml2 preparation emitted no arguments')
    uri = Path(prep[-1])
    tus = [ROOT / 'tests/libxml2/uri_harness.c', uri,
           *[uri.parent / name for name in ('xmlstring.c', 'xmlmemory.c', 'globals.c')]]
    if not all(p.is_file() for p in tus):
        raise ValueError('libxml2 URI harness/input missing')
    for mode in ('libc', 'nolibc'):
        # Lean: test_libxml2_uri.sh:186 `--cabs-json FLAGS <tu>` per TU; :221 `--batch --first
        # --libc … --libc-tu … <jsons>` (libc) / :193 `--batch --first <jsons>` (nolibc).
        # The nolibc row is that lane's MIRRORED-FAILURE PAIR (test_libxml2_uri.sh:198-204: both
        # --nolibc surfaces must fail with the unknown-procedure `memset` Error), whose text embeds a
        # symbol id the two engines number differently (VALIDATION.md §1(a), upstream-tray 17) —
        # compared here under the labelled `failure-class` projection; the libc row stays `full`.
        # Bound: test_libxml2_uri.sh:58 TIMEOUT_SECS=300 (pre-merge audit M2); that lane caps
        # oracle, bridge and Lean (run_capped :105-108, :185).
        add('libxml2/uri-' + mode, 'batch', ['--exec', '--batch',
            *(['--nolibc'] if mode == 'nolibc' else []), *prep[:-1], *map(str, tus)], 'libxml2_uri', 300,
            lean=lean_recipe(map(str, tus), ['--batch', '--first'], bridge_flags=prep[:-1], libc=(mode == 'libc'),
                             projection='failure-class' if mode == 'nolibc' else 'full', capped=True))
    # Same representative input through legacy parse/typecheck/pretty-print CLI. These
    # three rows have no owning lane; they run at the `--timeout` default.
    simple = 'tests/minimal/001-return-literal.c'
    add('cli/core-dump', 'core', ['--nolibc', '--pp=core', simple], 'cli')
    add('cli/typecheck-core', 'typecheck', ['--nolibc', '--typecheck-core', simple], 'cli')
    add('cli/args', 'batch', ['--nolibc', '--exec', '--batch', '--args', 'ab cd',
                              'tests/immaculate/argv/argv1.c'], 'cli',
        lean=lean_recipe(['tests/immaculate/argv/argv1.c'], ['--batch', '--first', '--args', 'ab cd']))
    # Immaculate (test_immaculate.sh: oracle flags :151-156 `--exec --batch`
    # [+ `--nolibc` unless libc] [+ `--args "ab cd"` for argv rows] — NO
    # --mode flag, i.e. the oracle's default single-trace mode, which that
    # lane pairs with Lean `--first`; :63 TIMEOUT_SECS=60; corpora :191-193
    # nolibc/*.c, :201-203 argv/*.c, :212-214 libc/*.c). The two in-Lean
    # probes (g6-hash-collision.lean, illtyped-store.lean) have no oracle
    # side and are not cases here.
    immaculate = ROOT / 'tests/immaculate'
    for sub, extra in (('nolibc', ['--nolibc']), ('argv', ['--nolibc', '--args', 'ab cd']), ('libc', [])):
        paths = sorted((immaculate / sub).glob('*.c'))
        if not paths:
            raise ValueError(f'empty immaculate corpus: {sub}')
        for path in paths:
            suffix = '-args' if sub == 'argv' else ''
            # Lean: test_immaculate.sh:163-165 `--cabs-json <c>`; :168-173 `--batch --first`
            # [+ `--args "ab cd"`] [+ the libc pin + 12 metadata TUs].
            largs = ['--batch', '--first'] + (['--args', 'ab cd'] if sub == 'argv' else [])
            add(f'immaculate/{sub}/{path.stem}{suffix}', 'batch', ['--exec', '--batch', *extra, rel(path)],
                'immaculate', 60, lean=lean_recipe([rel(path)], largs, libc=(sub == 'libc'), capped=True))
    # tests/ci (LADDER Tier C: `test_exec.sh --write-baseline=… tests/ci`;
    # test_exec.sh:403-406 recursive find minus .syntax-only.c/.exhaust.c,
    # :442-443 flags, :169 TIMEOUT_SECS=30).
    ci = sorted((ROOT / 'tests/ci').rglob('*.c'))
    if not ci:
        raise ValueError('empty tests/ci corpus')
    for path in ci:
        if path.name.endswith(('.syntax-only.c', '.exhaust.c')):
            continue
        add(f'ci/{path.relative_to(ROOT / "tests/ci")}', 'batch',
            ['--exec', '--batch', '--nolibc', '--mode=exhaustive', rel(path)], 'ci', 30,
            lean=lean_recipe([rel(path)], ['--batch']))
    # tests/verify MAIN mode (test_verify.sh:75-77 `--nolibc --exec --batch
    # --mode=exhaustive`, timeout 30 at :75). Excluded, fork-only: the
    # call-point rows (Lean `--call`, :160-163, and the oracle's rendered
    # wrapper TUs, :57-65, which exist only to mirror `--call`) and the
    # `--pp=core` pin derivations (:105, :209, :238 — Core text, not an
    # execution; pristine-vs-fork Core dumps are the tolerated renumbering
    # class, VALIDATION.md §5).
    verify = sorted((ROOT / 'tests/verify').glob('*.c'))
    if not verify:
        raise ValueError('empty tests/verify corpus')
    for path in verify:
        # Lean: test_verify.sh:128 `--cabs-json <c>`, :78-79 `--batch <json>`.
        add(f'verify/{path.stem}', 'batch', ['--nolibc', '--exec', '--batch', '--mode=exhaustive', rel(path)],
            'verify', 30, lean=lean_recipe([rel(path)], ['--batch']))
    # lean_frontend/corpus MAIN mode: exactly the stems test_verify.sh executes
    # main-mode (:269; same verify_pair flags); the call-point rows
    # (tests/corpus/expectations.txt) are fork-only as above.
    for stem in CORPUS_MAIN_STEMS:
        path = ROOT / 'lean_frontend/corpus' / (stem + '.c')
        if not path.is_file():
            raise ValueError(f'corpus fixture missing: {path}')
        add(f'corpus/{stem}', 'batch', ['--nolibc', '--exec', '--batch', '--mode=exhaustive', rel(path)],
            'corpus', 30, lean=lean_recipe([rel(path)], ['--batch']))
    # libxml2 chvalid (test_libxml2.sh: prep :110-116 `libxml2_prep.sh chvalid.c`
    # → FLAGS + TU; slices :136 sorted `battery/chvalid_battery_*.c`; oracle
    # :162-163 `--nolibc --exec --batch FLAGS… <slice> <chvalid.c>` in the
    # default single-trace mode; :65 TIMEOUT_SECS=300). The battery-drift check
    # (:121-124) is that lane's own; the committed slices are the inputs here.
    prep = subprocess.check_output([str(ROOT / 'scripts/libxml2_prep.sh'), 'chvalid.c'], text=True).splitlines()
    if len(prep) < 2:
        raise ValueError('libxml2 chvalid preparation emitted no arguments')
    chvalid, flags = prep[-1], prep[:-1]
    slices = sorted((ROOT / 'tests/libxml2/battery').glob('chvalid_battery_*.c'))
    if not slices:
        raise ValueError('empty chvalid battery')
    for path in slices:
        # Lean: test_libxml2.sh:144/:204 `--cabs-json FLAGS <tu>` for chvalid.c and the slice,
        # :214-215 `--batch --first <slice.json> <chvalid.json>`.
        add(f'libxml2/chvalid/{path.stem}', 'batch',
            ['--nolibc', '--exec', '--batch', *flags, rel(path), chvalid], 'libxml2_chvalid', 300,
            lean=lean_recipe([rel(path), chvalid], ['--batch', '--first'], bridge_flags=flags, capped=True))
    # csmith (test_csmith_corpus.sh: materialisation :53-68 — csmith_cerberus.h +
    # safe_math.h copied beside PREFIXED copies whose `#include "csmith.h"`
    # becomes `#define CSMITH_MINIMAL` + `#include "csmith_cerberus.h"`,
    # prefixes sia_/sa_/smx_; :51 TIMEOUT_SECS=15; test_exec.sh flags). The
    # deterministic list is the staged names in codepoint order — NOT the
    # lane's `find | sort`, whose order is locale-dependent (en_US.UTF-8 puts
    # sa_csmith_100.c before sa_csmith_10.c) — so `--shard K/M` here mirrors
    # the arithmetic (:88-95), not necessarily that lane's boundaries.
    header = ROOT / 'tests/csmith'
    staged = stage / 'csmith'
    staged.mkdir(parents=True, exist_ok=False)
    for name in ('csmith_cerberus.h', 'safe_math.h'):
        shutil.copy2(header / name, staged / name)
    count = 0
    for sub, prefix in (('small_int_arith', 'sia'), ('small_arrays', 'sa'), ('small_mix', 'smx')):
        sources = sorted((header / sub).glob('*.c'))
        if not sources:
            raise ValueError(f'empty csmith sub-corpus: {sub}')
        for path in sources:
            text = path.read_text()
            (staged / f'{prefix}_{path.name}').write_text(
                text.replace('#include "csmith.h"', '#define CSMITH_MINIMAL\n#include "csmith_cerberus.h"'))
            count += 1
    for path in sorted(staged.glob('*.c')):
        add(f'csmith/{path.name}', 'batch', ['--nolibc', '--exec', '--batch', '--mode=exhaustive', str(path)],
            'csmith', 15, lean=lean_recipe([str(path)], ['--batch']))
    if count != 1669:
        raise ValueError(f'csmith corpus has {count} programs; the lane is built for 1669 (corpus drift)')
    return cases


def shard(cases, spec):
    """K/M slice of an already-ordered list, test_csmith_corpus.sh:88-95's arithmetic."""
    match = re.fullmatch(r'([0-9]+)/([0-9]+)', spec or '')
    if not match:
        raise ValueError(f'bad --shard {spec!r}; expected K/M')
    k, m = int(match[1]), int(match[2])
    if not 1 <= k <= m:
        raise ValueError(f'bad --shard {spec}: need 1 <= K <= M')
    per = (len(cases) + m - 1) // m
    return cases[(k - 1) * per:(k - 1) * per + per]


def library_probe(out, sides, environments, limit):
    # A public generated helper exercises package
    # resolution/linking. Public pipeline signature drift is a separate reviewed
    # interface limitation, not concealed by pretending this is a full API test.
    source = 'let () = let n = Cerb_frontend.Utils.fromJust "provider-api" (Some 42) in Printf.printf "%d\\n" n\n'
    result = []
    for side in ('upstream', 'fork'):
        directory = out / ('library-' + side)
        directory.mkdir()
        src, exe = directory / 'client.ml', directory / 'client'
        src.write_text(source)
        env = dict(environments[side])
        env['OCAMLPATH'] = str(sides[side]['runtime'] / 'lib') + os.pathsep + env.get('OCAMLPATH', '')
        built = capture(directory / 'build', ['ocamlfind', 'ocamlopt', '-package',
                        'cerberus-lib.mem.concrete', '-linkpkg', src, '-o', exe], env, limit)
        if built['status'] != 0:
            result.append((built, None))
        else:
            result.append((built, capture(directory / 'run', [exe], env, limit)))
    return result


def verdict_summary(record):
    """One token per side for the three-engine line: the batch verdicts (codec tokens,
    joined with ' | ') or the failure shape."""
    if record is None:
        return '-'
    if record['status'] in INCOMPLETE_STATUSES:
        return f'INCOMPLETE({record["status"]})'
    try:
        return ' | '.join(load_capture(record['capture']).tokens('full'))
    except (ProtocolError, OSError, ValueError) as exc:
        return f'UNDECODABLE(status {record["status"]}: {exc})'


def run_lean(directory, case, fork_side, env, limit, libc_args):
    """The fork's --cabs-json bridge per TU (as the fork-vs-Lean lanes do), then the
    Lean driver on the JSONs; LEAN_ABORT_ON_PANIC=1 as scripts/common.sh:319."""
    bridges, jsons = [], []
    wrapper = CAPPED_TEST if case.lean.get('capped') else ()
    for i, (bridge_flags, source) in enumerate(case.lean['tus']):
        record = capture(directory / f'bridge{i}', [fork_side['binary'], '--runtime=' + str(fork_side['runtime']),
                                                     *bridge_flags, '--cabs-json', source], env, limit, wrapper)
        bridges.append(record)
        if record['status'] != 0 or Path(record['capture'] + '.stdout').stat().st_size == 0:
            return {'status': 'lean_bridge_failed', 'reason': f'cabs-json of {source}: exit {record["status"]}',
                    'bridges': bridges, 'lean': None}
        json_path = directory / f'tu{i}.json'
        shutil.copyfile(record['capture'] + '.stdout', json_path)
        jsons.append(str(json_path))
    args = [*case.lean['args'], *(libc_args if case.lean.get('libc') else []), *jsons]
    lean_env = {**env, 'LEAN_ABORT_ON_PANIC': '1'}
    record = capture(directory / 'lean', [LEAN_BIN, *args], lean_env, limit, wrapper)
    return {'status': None, 'reason': '', 'bridges': bridges, 'lean': record}


def lean_compare(fork_record, lean_record, projection):
    """Lean vs fork under the lane row's projection. Report-only: never gates."""
    if lean_record['status'] in INCOMPLETE_STATUSES:
        return 'lean_incomplete', f'Lean status {lean_record["status"]}'
    errors = {}
    sides = {}
    for name, record in (('fork', fork_record), ('lean', lean_record)):
        try:
            sides[name] = load_capture(record['capture'])
        except (ProtocolError, OSError, ValueError) as exc:
            errors[name] = f'{exc} (status {record["status"]})'
    if len(sides) == 2:
        if sides['fork'].tokens(projection) == sides['lean'].tokens(projection):
            return 'lean_agreement', f'projection {projection}'
        return 'lean_difference', f'verdict tokens differ under projection {projection}'
    if len(sides) == 0:
        return 'lean_both_undecodable', f'fork: {errors["fork"]}; lean: {errors["lean"]} — not agreement'
    return 'lean_difference', 'one side undecodable: ' + '; '.join(f'{k}: {v}' for k, v in errors.items())


def hermetic_plants(register_path):
    """No processes: the schema-2 loader must reject every doctored register, and
    compare() must classify the incomplete/stale matrix as chartered."""
    results = []
    good = json.loads(register_path.read_text())
    first = next(iter(good['cases']))

    def expect_reject(name, mutate):
        data = json.loads(json.dumps(good))
        mutate(data)
        with tempfile.NamedTemporaryFile('w', suffix='.json', delete=False) as handle:
            handle.write(json.dumps(data))
            temp = handle.name
        try:
            load_register(temp)
            results.append((f'register/{name}', False, 'ACCEPTED a doctored register (must reject)'))
        except ValueError as exc:
            results.append((f'register/{name}', True, str(exc)))
        finally:
            os.unlink(temp)

    def set_status(data, side, status):
        data['cases'][first][side]['status'] = status

    expect_reject('schema-1', lambda d: d.update(schema=1))
    expect_reject('missing-class', lambda d: d['cases'][first].pop('class'))
    expect_reject('unknown-class', lambda d: d['cases'][first].update({'class': 'failure-text'}))
    expect_reject('missing-citation', lambda d: d['cases'][first].pop('citation'))
    expect_reject('empty-citation', lambda d: d['cases'][first].update(citation=''))
    expect_reject('nonexistent-citation', lambda d: d['cases'][first].update(
        citation='lean_frontend/docs/upstream-tray/00-does-not-exist.md'))
    expect_reject('unknown-iso-fix-id', lambda d: d['cases'][first].update(citation='R99'))
    expect_reject('unknown-key', lambda d: d['cases'][first].update(note='x'))
    expect_reject('empty-rationale', lambda d: d['cases'][first].update(rationale=' '))
    expect_reject('identical-signatures', lambda d: d['cases'][first].update(fork=dict(d['cases'][first]['upstream'])))
    expect_reject('fork-timeout', lambda d: set_status(d, 'fork', 124))
    expect_reject('fork-kill', lambda d: set_status(d, 'fork', 137))
    expect_reject('pristine-kill', lambda d: set_status(d, 'upstream', 137))
    expect_reject('pristine-timeout-under-diagnostic-text', lambda d: (
        d['cases'][first].update({'class': 'diagnostic-text'}), set_status(d, 'upstream', 124)))
    expect_reject('malformed-sha', lambda d: d['cases'][first]['fork'].update(stdout_sha256='xyz'))
    # Pre-merge audit N1: a citation must be a git-TRACKED file whose cited lines exist.
    with tempfile.NamedTemporaryFile('w', suffix='.md', dir=ROOT / '.tmp', delete=False) as scratch:
        scratch.write('not a record\n')
        untracked = str(Path(scratch.name).relative_to(ROOT))
    try:
        expect_reject('untracked-citation', lambda d: d['cases'][first].update(citation=untracked))
    finally:
        os.unlink(ROOT / untracked)
    expect_reject('out-of-range-line-citation', lambda d: d['cases'][first].update(citation='tests/multi_tu_tray/README.md:99999'))
    expect_reject('inverted-line-range-citation', lambda d: d['cases'][first].update(citation='tests/multi_tu_tray/README.md:9-3'))
    expect_reject('parent-directory-citation', lambda d: d['cases'][first].update(citation='../lem-lean/README.md'))
    rows = None
    try:
        rows = load_register(register_path)
        results.append(('register/committed-loads', True, f'{len(rows)} rows, every class/citation valid'))
    except ValueError as exc:
        results.append(('register/committed-loads', False, str(exc)))
    # compare() matrix on synthetic records (statuses and signatures only).
    empty = hashlib.sha256(b'').hexdigest()
    done = {'status': 0, 'stdout_sha256': 'a' * 64, 'diagnostic_sha256': empty}
    other = {'status': 0, 'stdout_sha256': 'b' * 64, 'diagnostic_sha256': empty}
    timeout_ = {'status': 124, 'stdout_sha256': empty, 'diagnostic_sha256': empty}
    killed = {'status': 137, 'stdout_sha256': empty, 'diagnostic_sha256': empty}
    admitting = {'class': 'shared-model-fix', 'citation': 'x', 'rationale': 'r', 'upstream': timeout_, 'fork': done}
    diagnostic = dict(admitting, **{'class': 'diagnostic-text'})
    fork_side = dict(admitting, upstream=done, fork=timeout_)
    checks = [
        ('compare/pristine-timeout+admitting-row', compare(timeout_, done, 'batch', admitting)[0], 'reviewed_difference'),
        ('compare/pristine-timeout+diagnostic-row', compare(timeout_, done, 'batch', diagnostic)[0], 'incomplete'),
        ('compare/pristine-timeout+no-row', compare(timeout_, done, 'batch', None)[0], 'incomplete'),
        ('compare/pristine-timeout+moved-fork-signature', compare(timeout_, other, 'batch', admitting)[0], 'difference'),
        ('compare/fork-timeout+row', compare(done, timeout_, 'batch', fork_side)[0], 'difference'),
        ('compare/pristine-kill+row', compare(killed, done, 'batch', dict(admitting, upstream=killed))[0], 'incomplete'),
        ('compare/fork-kill', compare(done, killed, 'batch', None)[0], 'incomplete'),
        ('compare/stale-row-pair-now-agrees', compare(done, done, 'batch', dict(admitting, upstream=other))[0], 'difference'),
        ('compare/row-pin-moved', compare(other, done, 'batch', dict(admitting, upstream=done, fork=other))[0], 'difference'),
    ]
    checks += [
        # [USER 2026-09-17] (1): the timeout matrix — both-sides 124 is the counted, non-failing
        # class; every one-sided timeout and every 137 stays fatal; a row cannot change that.
        ('compare/one-sided-pristine-timeout-no-row', compare(timeout_, done, 'batch', None)[0], 'incomplete'),
        ('compare/one-sided-fork-timeout', compare(done, timeout_, 'batch', None)[0], 'incomplete'),
        ('compare/unregistered-both-sides-timeout', compare(timeout_, timeout_, 'batch', None)[0], 'matching_incomplete'),
        # Pre-merge audit M1: a REGISTERED case is always judged by its row — a both-sides
        # timeout on a registered case is a moved pin, RED; with the committed `node` row too.
        ('compare/registered-both-sides-timeout+row', compare(timeout_, timeout_, 'batch', admitting)[0], 'difference'),
        ('compare/registered-node-row-fork-also-times-out',
         compare(timeout_, timeout_, 'batch', rows['multi_tu_tray/node']) [0] if rows and 'multi_tu_tray/node' in rows else 'NO-NODE-ROW',
         'difference'),
        ('compare/both-sides-kill', compare(killed, killed, 'batch', None)[0], 'incomplete'),
        ('compare/timeout-vs-kill', compare(timeout_, killed, 'batch', None)[0], 'incomplete'),
    ]
    # [USER 2026-09-17] (2): the diagnostic projection — synthetic both-crash captures.
    envelope = (b'cerberus: internal error, uncaught exception:\n'
                b'          Failure("TODO(pure shift a null pointer should be undefined behaviour), offset:4")\n'
                b'          Raised at Stdlib.failwith in file "stdlib.ml", line 29, characters 17-33\n'
                b'          Called from Cerb_frontend__Translation.translate_expression.(fun) in file '
                b'"ocaml_frontend/generated/translation.ml", line 2987, characters 35-59\n'
                b'          Called from Lem_list.map in file "lem_list.ml" (inlined), line 178, characters 22-39\n'
                b'          Called from Dune__exe__Main.cerberus in file "backend/driver/main.ml", lines 261-287, characters 8-15\n')
    shifted = (envelope.replace(b'line 2987, characters 35-59', b'line 2990, characters 35-59')
               .replace(b'line 178, characters 22-39', b'line 171, characters 22-39')
               .replace(b'lines 261-287, characters 8-15', b'lines 309-335, characters 8-15'))
    text_changed = envelope.replace(b'offset:4', b'offset:0')
    frame_renamed = envelope.replace(b'Lem_list.map', b'Lem_list.count_map')
    lead_a = b'internal error: failed at line 5\n' + envelope
    lead_b = b'internal error: failed at line 6\n' + envelope
    with tempfile.TemporaryDirectory(prefix='projection-plants-', dir=ROOT / '.tmp') as tmp:
        tmp = Path(tmp)
        a = synthetic_record(tmp / 'a', 125, b'', envelope)
        b = synthetic_record(tmp / 'b', 125, b'', shifted)
        c = synthetic_record(tmp / 'c', 125, b'', text_changed)
        d = synthetic_record(tmp / 'd', 125, b'', frame_renamed)
        e = synthetic_record(tmp / 'e', 125, b'', lead_a)
        f = synthetic_record(tmp / 'f', 125, b'', lead_b)
        g = synthetic_record(tmp / 'g', 125, b'Defined {value: "Specified(0)", stdout: "", stderr: "", blocked: "false"}\n', envelope)
        checks += [
            ('projection/frame-positions-only', compare(a, b, 'batch', None)[0], 'matching_failure'),
            ('projection/exception-text-differs', compare(a, c, 'batch', None)[0], 'difference'),
            ('projection/frame-function-differs', compare(a, d, 'batch', None)[0], 'difference'),
            ('projection/non-frame-line-position-differs', compare(e, f, 'batch', None)[0], 'difference'),
            ('projection/stdout-beside-crash-not-matching', compare(a, g, 'batch', None)[0], 'difference'),
            ('projection/raw-stderr-retained', a['stderr_sha256'] != b['stderr_sha256'] and a['diagnostic_sha256'] == b['diagnostic_sha256'], True),
        ]
        for name, got, want in checks:
            results.append((name, got == want, f'got {got!r}, want {want!r}'))
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--build-manifest', type=Path, default=os.environ.get(
        'CERB_INDEPENDENT_MANIFEST', str(ROOT / '.validation-foundations/independent-oracle-v2/manifest.json')))
    parser.add_argument('--out', type=Path)
    parser.add_argument('--cn-root', type=Path)
    parser.add_argument('--corpus', choices=sorted(CORPORA), default='tier-b',
                        help='tier-b (LADDER Tier B row 10, default) | libxml2_chvalid (its own Tier B row) | '
                             'ci, csmith (reporting rows) | all')
    parser.add_argument('--shard', help='K/M slice of the selected, ordered cases (test_csmith_corpus.sh arithmetic); a subset')
    parser.add_argument('--only', help='explicit regex subset of case ids; never a full independent lane')
    parser.add_argument('--plant', action='store_true',
                        help='hermetic register/compare plants + real control + unexpected fork-verdict mutation '
                             '+ a real registered fork≠pristine difference with its row withheld (must be RED)')
    parser.add_argument('--timeout', type=float, default=30, help='per-side bound for cases whose lane sets none')
    parser.add_argument('--with-lean', action='store_true',
                        help='REPORT-ONLY third column: run the Lean engine on each batch case through the fork\'s '
                             '--cabs-json bridge exactly as the fork-vs-Lean lane does and report pristine | fork | '
                             'lean; Lean-vs-fork never gates here (its own lanes do) but every difference is printed')
    args = parser.parse_args()
    if args.plant and (args.only or args.shard or args.with_lean):
        parser.error('--plant and --only/--shard/--with-lean are separate scopes')
    out = args.out.resolve() if args.out else Path(tempfile.mkdtemp(prefix='upstream-oracle-', dir=ROOT / '.tmp'))
    out.mkdir(parents=True, exist_ok=True)
    scope = ('plant' if args.plant else 'subset (--only)' if args.only else
             f'{args.corpus} shard {args.shard}' if args.shard else args.corpus)
    report = {'schema': 2, 'status': 'incomplete', 'source': source_identity(), 'rows': [],
              'scope': scope, 'corpus_selection': args.corpus, 'corpora': list(CORPORA[args.corpus]),
              'register_schema': REGISTER_SCHEMA, 'with_lean': args.with_lean,
              'lean_gating': 'none — the Lean column is a report; Lean-vs-fork is gated by its own lanes',
              'diagnostic_projection': 'remove the whole-line ^Time spent: <decimal> seconds trailer; normalise '
                                       '`line N[-M], characters A-B` inside OCaml backtrace frames (Raised at / Raised by '
                                       'primitive operation at / Called from / Re-raised at … in file "…") to `line N, '
                                       'characters A-B` ([USER 2026-09-17]); raw stderr retained in every capture',
              'not_applicable': [
                  {'interface': '--cabs-json, --call, --batch-alloc-census',
                   'reason': 'fork extensions; absent from pristine upstream CLI'},
                  {'interface': 'test_verify.sh call-point rows (Lean --call + oracle wrapper TUs) and --pp=core pin derivations',
                   'reason': 'fork-only harness rows / Core text under the tolerated renumbering class; MAIN-mode rows are walked'},
                  {'interface': 'tests/immaculate/*.lean in-Lean probes',
                   'reason': 'no oracle side'},
                  {'interface': 'test_ci_sweep.sh suites other than tests/ci (test_ci_sweep.sh:90-104): '
                                'tests/gcc-torture/breakdown/{success,fail,limbus,undefined,invalid,not_std_compliant,'
                                'not_supported}, tests/tcc, tests/suite, tests/pnvi_testsuite, tests/hacl-star, '
                                'tests/freebsd, tests/examples, tests/cheri-ci',
                   'reason': 'LADDER Tier C row C4, a fork-vs-Lean scoreboard with no baseline — not a gated corpus; '
                             'not walked here (pre-merge audit M3)'},
                  {'interface': 'Lean unit/kernel gates and generated fixture pins',
                   'reason': 'provider-specific artifacts; not upstream OCaml interfaces'},
              ]}

    def save():
        temp = out / 'report.tmp'
        temp.write_text(json.dumps(report, indent=2, sort_keys=True) + '\n')
        temp.replace(out / 'report.json')
    save()
    started = time.monotonic()
    try:
        manifest = validate_build(args.build_manifest.resolve())
        report['upstream_build_manifest'] = {'path': str(args.build_manifest.resolve()),
                                             'sha256': sha(args.build_manifest)}
        subprocess.run([str(ROOT / 'tools/check_driver_fresh.sh'), '--check-oracle'], check=True)
        libc_args = []
        if args.with_lean:
            # The Lean binary is a PREREQUISITE here exactly like the oracles: never built by
            # this lane (the lanes' build_lean runs under scripts/capped), freshness-checked.
            if not LEAN_BIN.is_file():
                raise ValueError(f'--with-lean: Lean driver missing: {LEAN_BIN}')
            subprocess.run([str(ROOT / 'tools/check_driver_fresh.sh'), '--check-lean'], check=True)
            report['lean_binary'] = {'path': str(LEAN_BIN), 'sha256': sha(LEAN_BIN)}
        fork = ROOT / '_build/default/backend/driver/main.exe'
        report['fork_binary'] = {'path': str(fork), 'sha256': sha(fork)}
        report['fork_artifacts'] = artifacts()
        sides = {'upstream': {'binary': Path(manifest['artifacts']['oracle']['path']),
                               'runtime': Path(manifest['artifacts']['runtime']['root'])},
                 'fork': {'binary': fork, 'runtime': ROOT / '_build/install/default'}}
        # Diagnostic-styling pin (as scripts/common.sh): Cmdliner styles the
        # crash envelope from TERM/NO_COLOR, and both sides' stderr is decoded
        # by the exact-envelope codec (2026-09-06 landing finding).
        pin = {'NO_COLOR': '1', 'TERM': 'dumb'}
        envs = {'fork': {**os.environ, **pin}, 'upstream': {**os.environ, **manifest['environment'], **pin}}
        exceptions = load_register(REGISTER)
        stage = out / 'stage'
        stage.mkdir()
        everything = corpus(args.cn_root, stage)
        ids = [case.id for case in everything]
        if len(set(ids)) != len(ids):
            raise ValueError('duplicate case ids in the corpus')
        # Both directions: a register row must name a live case (of ANY corpus).
        if set(exceptions) - set(ids):
            raise ValueError('reviewed difference refers to a case absent from the corpus: '
                             + ', '.join(sorted(set(exceptions) - set(ids))))
        cases = [case for case in everything if case.corpus in CORPORA[args.corpus]]
        report['membership'] = [{'id': c.id, 'kind': c.kind, 'corpus': c.corpus, 'timeout': c.timeout or args.timeout,
                                 'arguments': c.flags} for c in cases]
        inputs = {arg for case in cases for arg in case.flags if Path(arg).is_file()}
        report['input_files'] = {arg: sha(arg) for arg in sorted(inputs)}
        report['manifest_files'] = {rel_: sha(ROOT / rel_) for rel_ in
                                  ['tests/cn_coverage/manifest.txt', 'scripts/upstream_oracle_differences.json',
                                   'tests/libxml2/config/config.h', 'tests/libxml2/config/libxml/xmlversion.h']}
        report['source_archives'] = 'upstream source archives and all binary/runtime hashes checked before dispatch'
        if args.shard:
            cases = shard(cases, args.shard)
        if args.only:
            cases = [case for case in cases if re.search(args.only, case.id)]
        plants = []
        if args.plant:
            print('PLANT MODE: hermetic register/compare plants; a real passing pair, then the fork verdict mutated; '
                  'a real registered fork≠pristine difference with its row withheld', flush=True)
            for name, ok, detail in hermetic_plants(REGISTER):
                plants.append({'id': f'plant/{name}', 'status': 'plant_ok' if ok else 'plant_failed', 'reason': detail})
                print(f'{"PLANT OK  " if ok else "PLANT FAIL"} {name}: {detail}', flush=True)
            registered = [case for case in everything if case.id in exceptions
                          and exceptions[case.id]['class'] == 'shared-model-fix'
                          and exceptions[case.id]['upstream']['status'] not in INCOMPLETE_STATUSES]
            if not registered:
                plants.append({'id': 'plant/withheld-row', 'status': 'plant_failed',
                               'reason': 'no shared-model-fix register row with a completing pristine side to plant (vacuity guard)'})
            cases = [cases[0], Case('plant/unexpected-verdict', cases[0].kind, cases[0].flags, 'plant', cases[0].timeout)]
            if registered:
                cases.append(Case('plant/withheld-row:' + registered[0].id, registered[0].kind, registered[0].flags,
                                  'plant', registered[0].timeout))
        if not cases:
            raise ValueError('empty independent oracle selection')
        if args.with_lean and any(case.lean and case.lean.get('libc') for case in cases):
            # The libc pin + the 12 metadata TU cabs-jsons (scripts/libc_prep.sh --jsons; drift-checked
            # there), linked before the user TUs as test_libc_exec.sh:75-76 / test_immaculate.sh:210-211.
            libc_dir = out / 'libcjson'
            emitted = subprocess.check_output([str(ROOT / 'scripts/libc_prep.sh'), '--jsons', str(libc_dir)],
                                              text=True).splitlines()
            if len(emitted) != 12 or not all(Path(p).is_file() for p in emitted):
                raise ValueError(f'libc_prep.sh --jsons emitted {len(emitted)} paths; expected 12 metadata TUs')
            libc_args = ['--libc', str(ROOT / 'tests/libc/libc.core')]
            for path in emitted:
                libc_args += ['--libc-tu', path]

        def run_pair(index, case, mutate_fork=False):
            directory = out / f'{index:04d}'
            directory.mkdir()
            pair = {}
            for side, info in sides.items():
                command = [info['binary'], '--runtime=' + str(info['runtime']), *case.flags]
                if mutate_fork and side == 'fork':
                    wrapper = ('import subprocess,sys; p=subprocess.run(sys.argv[1:],capture_output=True); '
                               'sys.stdout.buffer.write(p.stdout.replace(b"Specified(",b"Specified(999")); '
                               'sys.stderr.buffer.write(p.stderr); sys.exit(p.returncode)')
                    command = [sys.executable, '-c', wrapper, *command]
                pair[side] = capture(directory / side, command, envs[side], case.timeout or args.timeout)
            return pair

        for i, case in enumerate(cases, 1):
            if case.id.startswith('plant/withheld-row:'):
                real = case.id.split(':', 1)[1]
                pair = run_pair(i, case)
                with_row, _ = compare(pair['upstream'], pair['fork'], case.kind, exceptions[real])
                without_row, why = compare(pair['upstream'], pair['fork'], case.kind, None)
                ok = with_row == 'reviewed_difference' and without_row == 'difference'
                status = 'plant_ok' if ok else 'plant_failed'
                reason = (f'{real}: with its register row -> {with_row}; row withheld -> {without_row} ({why})')
                report['rows'].append({'id': case.id, 'kind': case.kind, 'corpus': case.corpus, 'status': status,
                                       'reason': reason, **pair})
                print(f'{i}/{len(cases)} {status}: {case.id} — {reason}', flush=True)
                save()
                continue
            mutate = args.plant and case.id == 'plant/unexpected-verdict'
            pair = run_pair(i, case, mutate_fork=mutate)
            status, reason = compare(pair['upstream'], pair['fork'], case.kind, exceptions.get(case.id))
            if mutate:
                status = 'plant_rejected' if status == 'difference' else 'plant_failed'
            row = {'id': case.id, 'kind': case.kind, 'corpus': case.corpus, 'status': status, 'reason': reason, **pair}
            line = (f'{i}/{len(cases)} {status}: {case.id} (pristine {pair["upstream"]["seconds"]:.1f}s, '
                    f'fork {pair["fork"]["seconds"]:.1f}s)')
            if args.with_lean:
                if case.lean is None:
                    lean = {'status': 'lean_not_applicable', 'reason': 'legacy CLI row; no Lean side'}
                else:
                    lean = run_lean(out / f'{i:04d}', case, sides['fork'], envs['fork'],
                                    case.timeout or args.timeout, libc_args)
                    if lean['status'] is None:
                        lean['status'], lean['reason'] = lean_compare(pair['fork'], lean['lean'], case.lean['projection'])
                    lean['projection'] = case.lean['projection']
                lean['three_engines'] = {'pristine': verdict_summary(pair['upstream']),
                                         'fork': verdict_summary(pair['fork']),
                                         'lean': verdict_summary(lean.get('lean'))}
                row['lean'] = lean
                line += f' | lean: {lean["status"]}'
                if lean['status'] not in ('lean_agreement', 'lean_not_applicable'):
                    line += (f'\n    LEAN≠FORK {case.id}: {lean["reason"]}\n      pristine: {lean["three_engines"]["pristine"][:200]}'
                             f'\n      fork:     {lean["three_engines"]["fork"][:200]}\n      lean:     {lean["three_engines"]["lean"][:200]}')
            report['rows'].append(row)
            print(line, flush=True)
            save()
        report['rows'].extend(plants)
        if not args.only and not args.plant and not args.shard and args.corpus in ('tier-b', 'all'):
            library = library_probe(out, sides, envs, args.timeout)
            report['library_probe'] = library
            if all(run and run['status'] == 0 and Path(run['capture'] + '.stdout').read_bytes() == b'42\n'
                   for build, run in library):
                report['library_status'] = 'passed'
            else:
                report['library_status'] = 'failed'
        report['counts'] = dict(Counter(row['status'] for row in report['rows']))
        if args.with_lean:
            report['lean_counts'] = dict(Counter(row['lean']['status'] for row in report['rows'] if 'lean' in row))
            report['lean_differences'] = [row['id'] for row in report['rows']
                                          if 'lean' in row and row['lean']['status'] not in ('lean_agreement', 'lean_not_applicable')]
        report['seconds'] = round(time.monotonic() - started, 1)
        report['source_after'] = source_identity()
        report['source_unchanged'] = report['source_after'] == report['source']
        # `matching_incomplete` (both-sides timeout, [USER 2026-09-17]) is counted, never fatal.
        failed = any(row['status'] in ('difference', 'incomplete', 'plant_failed') for row in report['rows']) \
            or report.get('library_status') == 'failed' or not report['source_unchanged']
        report['status'] = ('failed' if failed else 'plants_passed' if args.plant else
                            'subset_passed' if (args.only or args.shard) else 'passed')
        save()
        print(f'Independent oracle scope: {scope}; {len(report["rows"])} rows in {report["seconds"]}s; '
              f'source unchanged: {report["source_unchanged"]}', flush=True)
        if args.with_lean:
            print(f'Three-engine report (Lean column, NOT gating): {report["lean_counts"]}; '
                  f'Lean≠fork rows: {len(report["lean_differences"])}' +
                  (': ' + ', '.join(report['lean_differences']) if report['lean_differences'] else ''), flush=True)
        print(f'Independent oracle: {report["status"]}; {report["counts"]}; {out / "report.json"}', flush=True)
        return int(failed)
    except (ValueError, OSError, KeyError, subprocess.CalledProcessError) as exc:
        report.update(status='incomplete', error=str(exc))
        save()
        print(f'INDEPENDENT ORACLE INCOMPLETE: {exc}', file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.exit(main())
