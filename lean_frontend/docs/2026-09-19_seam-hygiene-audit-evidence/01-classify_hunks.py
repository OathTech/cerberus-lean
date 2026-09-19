#!/usr/bin/env python3
"""Auditor's mechanical hunk classifier for the seam-hygiene range (item 1).
Reads the three code-commit diffs and classifies every removed/added line pair in SEAM files:
 (a) failure LEAF swap panic! -> failwithI with identical message text, or a self-locating
     `<Module>.<fn>: ` prefix inserted immediately after the opening quote (or s!");
 (a') Main.lean's `panic! e` -> `failwithI s!"Main.loadCoreImpl: {e}"` (the variable wrapped in a prefixed interpolation);
 (imp) a pure `import LemLib` addition;
 (b) switch GUARD wrapping: every removed code line reappears unchanged (modulo `else ` prefix / indentation /
     trailing `-- comment`) among the added lines of the same hunk; added lines are only comments, guard `if`,
     kill lines, `else`, or the re-appeared default;
 (c) oomKill naming: the exact kill literal replaced by `oomKill` / the def added / the theorem restated;
 (d) identity stubs (CerbUtils);
 (e) the structural BEq (CerbMem :224-260);
 (doc) comment/docstring-only changes;
 (f) ANYTHING ELSE -> printed loudly.
"""
import re, sys, subprocess
from collections import Counter, defaultdict

SEAM = re.compile(r'^lean_frontend/(CerbMem|CerbFS|CerbDecode|CerbUtils|CerberusImpl|CerbLocation|CerbFloat|CoreParser|Main|CerbGlobal|CerbMemAllocatorProofs)\.lean$')
PREFIX = re.compile(r'^[A-Z][A-Za-z0-9_]*\.[A-Za-z0-9_\']+: ')

def hunks(diff_text):
    """yield (file, hunk_header, [(sign, line)])"""
    f = None; cur = None
    for raw in diff_text.split('\n'):
        if raw.startswith('diff --git'):
            if cur: yield cur
            f = raw.split(' b/')[-1]; cur = None; continue
        if raw.startswith('@@'):
            if cur: yield cur
            cur = (f, raw, []); continue
        if cur is None: continue
        if raw.startswith('+++') or raw.startswith('---') or raw.startswith('index '): continue
        if raw == '': cur[2].append((' ', '')); continue
        if raw[:1] in '+- ':
            cur[2].append((raw[0], raw[1:]))
    if cur: yield cur

def strip_comment(s):
    # remove a trailing `-- comment` (not inside a string literal: seams' code lines here have none with `--` inside strings except messages; guard by quote parity)
    out = []; inq = False; i = 0
    while i < len(s):
        c = s[i]
        if c == '"' and (i == 0 or s[i-1] != '\\'): inq = not inq
        if not inq and s.startswith('--', i): break
        out.append(c); i += 1
    return ''.join(out).strip()

CODEISH = re.compile(r'panic!|failwithI|:=|=>|\bif\b.*\bthen\b|^\s*else\b|\bmatch\b|\bkill\b|NDkilled|memReturn|memFail|^\s*\||^\s*(def|theorem|instance|private|opaque|mutual|end)\b|^\s*import\b')
def is_comment(s):
    t = s.strip()
    return t == '' or t.startswith('--') or t.startswith('/-') or t.startswith('-/') or not CODEISH.search(re.sub(r'`[^`]*`', '', s))

def leaf_swap(r, a):
    """(a): r has one `panic!`, a has `failwithI` in its place; the rest identical or prefixed."""
    if r.count('panic!') != 1 or 'failwithI' not in a: return None
    i = r.index('panic!'); j = a.index('failwithI')
    if r[:i] != a[:j]: return None
    rr = r[i+len('panic!'):]; aa = a[j+len('failwithI'):]
    if rr == aa: return 'a:same-text'
    # prefix inserted after the opening quote: ` "X` -> ` "P: X`, ` s!"X` -> ` s!"P: X`
    m = re.match(r'^(\s*(?:s!)?")', rr)
    if m and aa.startswith(m.group(1)):
        rest_r = rr[len(m.group(1)):]; rest_a = aa[len(m.group(1)):]
        pm = PREFIX.match(rest_a)
        if pm and rest_a[pm.end():] == rest_r: return 'a:prefixed(' + pm.group(0).strip() + ')'
    # Main.lean: `panic! e` -> `failwithI s!"Main.loadCoreImpl: {e}"`
    if rr.strip() == 'e' and aa.strip() == 's!"Main.loadCoreImpl: {e}"': return "a':var-wrapped(Main.loadCoreImpl)"
    return None

def norm_code(s):
    s = strip_comment(s)
    s = re.sub(r'^else\s+', '', s)
    return re.sub(r'\s+', ' ', s).strip()

def classify_hunk(f, hdr, lines, commit):
    rem = [l for s, l in lines if s == '-']; add = [l for s, l in lines if s == '+']
    if not rem and not add: return ('ctx-only', [])
    notes = []
    # docs-only
    if all(is_comment(l) for l in rem + add):
        return ('doc', notes)
    # import
    if not rem and all(l.strip() == 'import LemLib' for l in add):
        return ('imp', notes)
    # leaf swaps: pair removed/added in order
    if len(rem) == len(add) and rem and all(leaf_swap(r, a) for r, a in zip(rem, add)):
        return ('a', [leaf_swap(r, a) for r, a in zip(rem, add)])
    # (b) guard wrapping — every removed code line re-appears among added lines (normalised)
    rem_code = [norm_code(l) for l in rem if not is_comment(l)]
    add_code = [norm_code(l) for l in add if not is_comment(l)]
    if rem_code and all(any(rc == ac or ac.endswith(rc) or ac == 'else ' + rc for ac in add_code) for rc in rem_code):
        others = []
        for ac in add_code:
            if ac in rem_code or any(ac.endswith(rc) for rc in rem_code): continue
            if ac == 'else' or ac.startswith('if ') or ac.startswith('(CerbGlobal.') or ac.startswith('(NDkilled (Other (MerrOther "') or ac.startswith('kill (Other (MerrOther "') or ac.startswith('else if CerbGlobal.has_switch') or ac.startswith('(CerbGlobal.is_PNVI') or ac.startswith('else match') or ac.startswith('CerbGlobal.'): continue
            others.append(ac)
        if not others: return ('b', [])
        notes.append('added non-guard lines: ' + repr(others))
    if not rem_code and add_code and all(
            ac == 'else' or ac.startswith('if ') or ac.startswith('else if ') or ac.startswith('(NDkilled (Other (MerrOther "') or ac.startswith('kill (Other (MerrOther "') or ac.startswith('(CerbGlobal.') for ac in add_code):
        return ("b'", ['pure insertion: ' + repr([a[:60] for a in add_code])])
    # (c) oomKill
    if commit.startswith('dde3'):
        joined_r = '\n'.join(rem); joined_a = '\n'.join(add)
        if all('Concrete.allocator: failed (out of memory)' in l for l in rem if not is_comment(l)) and all(('oomKill' in l) for l in add if not is_comment(l)):
            return ('c', [])
        if 'def oomKill' in joined_a and not rem_code: return ('c:def', [])
        if f.endswith('CerbMemAllocatorProofs.lean'): return ('c:theorem-restated', [f'REMOVED={rem_code}', f'ADDED={add_code}'])
        if f.endswith('CerbUtils.lean'): return ('d', [f'REMOVED={rem_code}', f'ADDED={add_code}'])
        if 'beqMemValue' in joined_r or 'beqMemValue' in joined_a: return ('e', [f'REMOVED={rem_code}', f'ADDED={add_code}'])
    if commit.startswith('ee1e') and f.endswith('CerbGlobal.lean'):
        return ('g:CerbGlobal(fence ext 2)', [f'REMOVED={rem_code}', f'ADDED={add_code}'])
    return ('f', [f'REMOVED={rem}', f'ADDED={add}'] + notes)

def main():
    tot = Counter()
    for c in ['fce1de9f8', 'ee1eaf94d', 'dde3b766b']:
        txt = open(f'.tmp/audit/diffs/{c}.diff').read()
        per = Counter()
        for f, hdr, lines in hunks(txt):
            if not SEAM.match(f): continue
            cls, notes = classify_hunk(f, hdr, lines, c)
            per[cls] += 1; tot[(c, cls)] += 1
            if cls in ('f',) or cls.startswith('c:theorem') or cls.startswith('d') or cls.startswith('e') or cls.startswith('g') or notes:
                print(f'[{c}] {f} {hdr.split("@@")[1].strip()} -> {cls}')
                for n in notes: print('      ' + str(n)[:600])
        print(f'== {c}: seam-file hunks by class: {dict(per)}')
    print('== leaf-swap detail (a) tally by kind:')
    kinds = Counter()
    for c in ['fce1de9f8']:
        txt = open(f'.tmp/audit/diffs/{c}.diff').read()
        for f, hdr, lines in hunks(txt):
            if not SEAM.match(f): continue
            rem = [l for s, l in lines if s == '-']; add = [l for s, l in lines if s == '+']
            if len(rem) == len(add):
                for r, a in zip(rem, add):
                    k = leaf_swap(r, a)
                    if k: kinds[k.split('(')[0]] += 1; kinds['TOTAL'] += 1
                    if k and k.startswith('a:prefixed'): print('   ', f.split('/')[-1], k)
    print('   ', dict(kinds))
main()
