#!/usr/bin/env python3
"""Lexical failure-site census, with source offsets and explicit type evidence.

This is an inventory, not a reachability proof or a Lean type checker. Nested
comments and string contents cannot introduce failure tokens. Generated
copies of handwritten seams are counted only at their authoritative source.
"""
import argparse
from collections import Counter
import hashlib
import json
from pathlib import Path
import re

ROOT = Path(__file__).resolve().parent.parent


def strip_comments(text):
    chars = list(text)
    i, depth, string = 0, 0, False
    while i < len(chars):
        if depth:
            if text.startswith('/-', i):
                chars[i:i+2] = '  '; depth += 1; i += 2
            elif text.startswith('-/', i):
                chars[i:i+2] = '  '; depth -= 1; i += 2
            else:
                if chars[i] != '\n': chars[i] = ' '
                i += 1
        elif string:
            if chars[i] == '\\': i += 2
            elif chars[i] == '"': string = False; i += 1
            else: i += 1
        elif text.startswith('/-', i):
            chars[i:i+2] = '  '; depth = 1; i += 2
        elif text.startswith('--', i):
            end = text.find('\n', i)
            if end < 0: end = len(chars)
            chars[i:end] = ' '*(end-i); i = end
        elif chars[i] == "'" and (i == 0 or not (text[i-1].isalnum() or text[i-1] in "_'")) and (char := re.match(r"'(?:\\.|[^'\\])'", text[i:])):
            i += len(char[0])
        elif chars[i] == '"': string = True; i += 1
        else: i += 1
    if depth or string: raise ValueError('unterminated comment/string')
    return ''.join(chars)


TOKEN = re.compile(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])\'|[\w][\w\'.!?]*|:=|=>|[^\s]', re.UNICODE)
MONAD = re.compile(r'\b(?:ndM|memM|stExceptUndefM|stExceptM|exceptM|errorM)\b')


def census(path, root=ROOT):
    text = path.read_text()
    clean = strip_comments(text)
    tokens = list(TOKEN.finditer(clean))
    # Generated declarations mostly occupy one line, but some workers don't.
    headers = list(re.finditer(r'(?m)^[ \t]*(?:(?:private|protected|noncomputable|partial|unsafe)[ \t]+)*'
                              r'(?:def|abbrev|opaque|instance|theorem)\b(?:[ \t]+([^\s:(\[]+))?', clean))
    namespaces = []
    header_names = {}
    events = [(h.start(), 'header', h) for h in headers]
    events += [(m.start(), 'scope', m) for m in re.finditer(
        r'(?m)^\s*(namespace\s+[^\s]+|section(?:\s+[^\s]+)?|mutual|end(?:\s+[^\s]+)?)\s*$', clean)]
    for _, kind, event in sorted(events, key=lambda e: e[0]):
        if kind == 'header':
            prefix = '.'.join(n for n in namespaces if n)
            header_names[event.start()] = (prefix+'.' if prefix else '')+(event[1] or '<anonymous declaration>')
        elif event[1].startswith('namespace '): namespaces.append(event[1].split()[1])
        elif event[1].startswith('end'):
            if namespaces: namespaces.pop()
        else: namespaces.append('')
    rows = []
    stack = []
    containing = {}
    pairs = {}
    for i, token in enumerate(tokens):
        word = token[0]
        if word in ('(', '[', '{'): stack.append(i)
        elif word in (')', ']', '}') and stack:
            opening = stack.pop()
            pairs[opening] = i
        containing[i] = tuple(stack)
    for i, token in enumerate(tokens):
        if token[0] not in ('failwithI', 'panic!', 'panic', 'panicCore'):
            continue
        header = next((h for h in reversed(headers) if h.start() <= token.start()), None)
        definition = header_names[header.start()] if header else '<no declaration>'
        type_text = ''
        # An immediate ascription at the failure call's enclosing delimiter
        # supplies the generated type. Skip nested message applications.
        if containing[i]:
            opening = containing[i][-1]
            end = pairs.get(opening, i)
            for j in range(i+1, end):
                if tokens[j][0] == ':' and containing[j] == containing[i]:
                    type_text = clean[tokens[j].end():tokens[end].start()].strip()
                    break
        decl_type = ''
        if header:
            next_header = next((h.start() for h in headers if h.start() > header.start()), len(clean))
            end = clean.find(':=', header.end(), next_header)
            if end >= 0: decl_type = clean[header.start():end].strip()
        generated = path.parent.name == 'generated'
        evidence = type_text if generated else decl_type
        monadic = bool(MONAD.search(evidence))
        # A type containing a monad does not automatically have a usable
        # source-location/error vocabulary. Keep unresolved aliases explicit.
        channel = 'none_or_unresolved'
        if monadic:
            if re.search(r'\b(?:ndM|memM)\b', evidence): channel = 'NDkilled_Error0_loc'
            elif re.search(r'\bt0\b', evidence): channel = 'undefined_Error_loc'
            elif 'CerbLocation.Loc' in evidence and not re.search(r'\berrorM\b', evidence):
                channel = 'exception_payload_location_review_required'
            elif re.search(r'\bcore_run_cause\b', evidence): channel = 'core_run_cause_needs_failure_constructor'
            elif re.search(r'\berrorM\b', evidence): channel = 'typing_error_location_needs_failure_constructor'
            elif re.search(r'\berror\b', evidence): channel = 'Errors_error_location_needs_failure_constructor'
            else: channel = 'error_alias_review_required'
        following = text[token.end():min(len(text), token.end()+240)].strip()
        group = 'monadic_ascribed' if monadic else 'pure_or_unresolved'
        rows.append({'file': str(path.relative_to(root)), 'line': text.count('\n', 0, token.start())+1,
                     'column': token.start()-text.rfind('\n', 0, token.start()), 'offset': token.start(),
                     'definition': definition, 'token': token[0], 'ascribed_type': type_text,
                     'declaration_type': decl_type if not generated else '', 'group': group,
                     'generated': generated, 'channel': channel, 'following_source': following,
                     'comparison_residual': following.startswith('"Lean backend: comparison residual'),
                     'incomplete_pattern': bool(re.match(r'"[^"\n]*[Ii]ncomplete', following))})
    return rows


def assign_dependencies(rows, reach, ranges_by_module):
    """Only a compiler range containing this source position may own a site.

    Lexical names are retained as hints, never as evidence of containment.
    Multiple smallest ranges remain explicit rather than selecting one by
    name/order. Dependency bits are available only for identified owners.
    """
    for row in rows:
        position = (row['line'], row['column'] - 1)
        matches = [r for r in ranges_by_module.get(Path(row['file']).stem, [])
                   if r[2] <= position < r[3]]
        candidates = []
        if matches:
            span = min((r[3][0] - r[2][0], r[3][1] - r[2][1]) for r in matches)
            candidates = sorted({r[0] for r in matches
                                 if (r[3][0] - r[2][0], r[3][1] - r[2][1]) == span})
        row['lexical_definition'] = row['definition']
        row['kernel_names'] = candidates
        row['range_match'] = bool(candidates)
        identified = len(candidates) == 1 and candidates[0] in reach
        row['dependency_status'] = ('identified' if identified else 'range_multiple'
                                    if len(candidates) > 1 else 'unresolved_range_or_import')
        if identified:
            row['definition'] = candidates[0]
            row.update(reach[candidates[0]])
        else:
            row['definition'] = '<unresolved compiler declaration>'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=ROOT)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--reach-log', type=Path, help='complete FailureReach Lean build log')
    args = parser.parse_args()
    root = args.root.resolve()
    handwritten = sorted((root/'lean_frontend').glob('*.lean'))
    names = {p.name for p in handwritten}
    generated = sorted(p for p in (root/'lean_frontend/generated').glob('*.lean') if p.name not in names)
    if not generated: raise SystemExit('missing generated source; run the recorded generation recipe')
    paths = handwritten + generated
    rows = [row for p in paths for row in census(p, root)]
    if args.reach_log:
        reach_text = args.reach_log.read_text()
        if 'Build completed successfully' not in reach_text or 'error:' in reach_text:
            raise SystemExit('reachability instrument did not complete successfully')
        reach = {m[1]: {'exec_dependency': m[2] == 'true', 'frontend_dependency': m[3] == 'true'}
                 for m in re.finditer(r'FAILURE_REACH\t([^\t\n]+)\t(true|false)\t(true|false)', reach_text)}
        if len(reach) < 1000:
            raise SystemExit('reachability log has too few definitions')
        ranges_by_module = {}
        for m in re.finditer(r'FAILURE_RANGE\t([^\t\n]+)\t([^\t\n]+)\t([^\t\n]+)\t(\d+)\t(\d+)\t(\d+)\t(\d+)', reach_text):
            ranges_by_module.setdefault(m[2], []).append((m[1], m[3], (int(m[4]), int(m[5])), (int(m[6]), int(m[7]))))
        assign_dependencies(rows, reach, ranges_by_module)
    counts = Counter(('generated' if r['generated'] else 'handwritten')+':'+r['group'] for r in rows)
    report = {'schema': 2, 'method': __doc__, 'counts': dict(sorted(counts.items())),
              'source_sha256': {str(p.relative_to(root)): hashlib.sha256(p.read_bytes()).hexdigest() for p in paths},
              'sites': rows}
    if args.reach_log:
        report['reach_log_sha256'] = hashlib.sha256(args.reach_log.read_bytes()).hexdigest()
        report['reachability_limit'] = 'constant dependency closure, including types and mutual blocks; not a path reachability proof'
    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(report, indent=2, ensure_ascii=False)+'\n')
    print(json.dumps(report['counts'], indent=2))


if __name__ == '__main__': main()
