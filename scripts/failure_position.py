#!/usr/bin/env python3
"""Position class of a failure site — mechanical, token-level, with CLIMB.

The live half of the failure-reach register's position column
(scripts/check_failure_reach.py). Ported 2026-09-08 from the reachability
census's evidence script
(lean_frontend/docs/2026-09-07_pure-failure-reachability-census-evidence/
classify_position.py, Q1 of the census record) so that the classes the
register carries are recomputed on every run from the SAME rules that
produced them; the evidence copy stays as the record.

Reuses scripts/failure_census.py's comment stripper and tokenizer so offsets
agree with the census JSON. The 'unit' starts as the failure expression (the
innermost `( failwithI ... : T )` group when present, else the failure token).
The unit is then CLIMBED to the maximal expression whose value IS the failure
whenever the failure's branch is taken:
  - pure wrapper parentheses are peeled;
  - if the unit is a match arm body (`| pat => unit`) the unit becomes the whole
    `match ... with ...` expression (head = the `match` token found by walking
    back at the same bracket depth to the `with` and its `match`);
  - if the unit is an `if` branch (`then unit` / `else unit`) it becomes the `if`.
The token BEFORE the final unit's head decides the class:
  TAIL          `:=` of a def/instance/theorem/where-method body, or <BOF>/`in`
  LET-BOUND     `:=` of a `let`/`have` (the F1 shape: bound, maybe dead)
  LAMBDA-BODY   `=>` of a `fun` (evaluated iff the lambda is applied and used)
  ARGUMENT      identifier / `)` / `]` / `<|` / `$` (application argument)
  TUPLE-OR-LIST prev/next is `,` or prev is `[`
  STRUCT-FIELD  `:=` inside `{ ... }`
  SCRUTINEE     `match`/`if` (always evaluated)
  TAIL-LETBODY  `;` (generated `let x := e; unit`: the unit is the let BODY)
  STMT-NEWLINE  hand-written: the unit starts a new line after a token that is
                not an expression continuation (a `let` line / a match arm
                body on its own line) — the census read these by hand (TAIL)
  OTHER…        anything else (manual review)
`chain` records every climb step.

DISCARDABLE (the register's tripwire, added here): a LET-BOUND / LET-BOUND-FUN
unit whose bound names never occur again before the next declaration header,
or are all `_`-prefixed — the F1 shape with a DEAD binding, the one position
class where OCaml raises and a strict Lean evaluation would not have to
(design: docs/2026-09-07_pure-failure-correspondence-design.md; census Q1:
today 0 such sites).

CLI (for a hand look): failure_position.py ROOT census.json [out.json]
"""
import json, re, sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import failure_census as fc

OPEN = {'(': ')', '[': ']', '{': '}'}
CLOSE = {v: k for k, v in OPEN.items()}
IDENT = re.compile(r"^[A-Za-z_][\w'.!?]*$")
HEADER = re.compile(r'(?m)^[ \t]*(?:(?:private|protected|noncomputable|partial|unsafe)[ \t]+)*'
                    r'(?:def|abbrev|opaque|instance|theorem)\b')
CONTINUATION = (':=', '=>', 'then', 'else', '(', ',', '[', '<|', '$', 'do', '←', 'fun', 'λ', 'with', 'in',
                ';', '|', 'if', 'match', 'return', 'pure', '&&', '||', '+', '-', '*', '/', '++', '==', '!=',
                '<', '>', '≤', '≥', '::', '<$>', '>>=', '|>', '<;>')


class Classifier:
    def __init__(self, root):
        self.root = Path(root).resolve()
        self.cache = {}
        self.text_cache = {}

    def text(self, rel):
        if rel not in self.text_cache:
            self.text_cache[rel] = (self.root / rel).read_text()
        return self.text_cache[rel]

    def tokens_of(self, rel):
        if rel not in self.cache:
            clean = fc.strip_comments(self.text(rel))
            toks = [(m.start(), m[0]) for m in fc.TOKEN.finditer(clean)]
            stack, pairs = [], {}
            for i, (_, w) in enumerate(toks):
                if w in OPEN: stack.append(i)
                elif w in CLOSE and stack:
                    o = stack.pop(); pairs[o] = i; pairs[i] = o
            headers = sorted(h.start() for h in HEADER.finditer(clean))
            self.cache[rel] = (toks, pairs, headers)
        return self.cache[rel]

    def line_of(self, rel, off):
        return self.text(rel).count('\n', 0, off)

    @staticmethod
    def walk_back(toks, k, stop):
        """From index k backwards at bracket depth 0; return (index, word) of the
        first token in `stop`, or (None, reason)."""
        depth = 0
        j = k
        while j >= 0:
            w = toks[j][1]
            if w in CLOSE: depth += 1
            elif w in OPEN:
                if depth == 0: return None, '<open>'
                depth -= 1
            elif depth == 0 and w in stop:
                return j, w
            j -= 1
        return None, '<BOF>'

    @staticmethod
    def ctx(toks, start, end):
        return (' '.join(w for _, w in toks[max(0, start-12):start]) + '  ▶'
                + ' '.join(w for _, w in toks[start:min(end+1, start+14)])[:90] + '…◀  '
                + ' '.join(w for _, w in toks[end+1:end+5]))

    def classify(self, rel, offset):
        """-> dict(cls, prev, chain, ctx, start, end, tok) — the census's Q1 classes."""
        toks, pairs, _ = self.tokens_of(rel)
        generated = Path(rel).parent.name == 'generated'
        idx = {s: i for i, (s, _) in enumerate(toks)}
        i = idx.get(offset)
        wb = self.walk_back
        def result(cls, prev, chain, start, end):
            return {'cls': cls, 'prev': prev, 'chain': chain, 'ctx': self.ctx(toks, start, end),
                    'start': start, 'end': end, 'tok': i}
        if i is None: return {'cls': 'OFFSET-MISS', 'prev': '', 'chain': [], 'ctx': '', 'start': -1, 'end': -1, 'tok': -1}
        start, end = i, i
        if i > 0 and toks[i-1][1] == '(' and (i-1) in pairs:
            start, end = i-1, pairs[i-1]
        chain = []
        for _ in range(60):
            while start > 0 and toks[start-1][1] == '(' and pairs.get(start-1) == end + 1:
                start, end = start-1, end+1
            if start > 0 and toks[start-1][1] == '(' and (start-1) in pairs and pairs[start-1] > end:
                start, end = start-1, pairs[start-1]
                continue
            prev = toks[start-1][1] if start > 0 else '<BOF>'
            if not generated and start > 0 and self.line_of(rel, toks[start-1][0]) < self.line_of(rel, toks[start][0]) \
               and prev not in CONTINUATION:
                chain.append('newline-stmt'); return result('STMT-NEWLINE', prev, chain, start, end)
            if prev == ';':
                j, w = wb(toks, start-2, {'let', 'have'})
                if w in ('let', 'have'):
                    chain.append('let-body'); start = j; continue
                chain.append(';?'); return result('OTHER;', prev, chain, start, end)
            if prev == '=>':
                j, w = wb(toks, start-2, {'|', 'fun', 'λ', 'with', 'match', 'if', 'then', 'else', ':=', ';'})
                if w in ('fun', 'λ'):
                    fp = toks[j-1][1] if j > 0 else '<BOF>'
                    if fp == '(' and (j-1) in pairs:
                        chain.append('fun-body'); start, end = j-1, pairs[j-1]
                        prev2 = toks[start-1][1] if start > 0 else '<BOF>'
                        return result('LAMBDA-BODY', prev2, chain, start, end)
                    if fp == ':=':
                        k2, w2 = wb(toks, j-2, {'let', 'have', 'def', 'instance', 'theorem', 'abbrev', 'opaque', 'where', ':=', '=>', 'with', 'then', 'else', ';', 'in', 'do'})
                        if w2 in ('def', 'instance', 'theorem', 'abbrev', 'opaque', 'where', ':=', '<BOF>'):
                            chain.append('def-body-fun'); return result('TAIL', prev, chain, start, end)
                        if w2 in ('let', 'have'):
                            chain.append('let-bound-fun'); return result('LET-BOUND-FUN', prev, chain, start, end)
                    chain.append(f'fun-body({fp})'); return result('LAMBDA-BODY', fp, chain, start, end)
                if w == '|':
                    k, w2 = wb(toks, j-1, {'with'})
                    if w2 == 'with':
                        m, w3 = wb(toks, k-1, {'match'})
                        if w3 == 'match':
                            chain.append('match-arm'); start = m; end = max(end, k)
                            continue
                    if w2 in ('<BOF>', '<open>'):
                        chain.append('eqn-arm'); return result('TAIL', prev, chain, start, end)
                    chain.append(f'arm?{w2}'); return result('OTHER-ARM', prev, chain, start, end)
                chain.append(f'=>?{w}'); return result('OTHER=>', prev, chain, start, end)
            if prev in ('then', 'else'):
                j, w = wb(toks, start-2, {'if'})
                if w == 'if':
                    chain.append(f'{prev}-branch'); start = j; continue
                chain.append(f'{prev}?'); return result('OTHER-IF', prev, chain, start, end)
            break
        prev = toks[start-1][1] if start > 0 else '<BOF>'
        nxt = toks[end+1][1] if end+1 < len(toks) else '<EOF>'
        if prev == ':=':
            j, w = wb(toks, start-2, {'let', 'have', 'def', 'instance', 'theorem', 'abbrev', 'opaque', 'where', ':=', '=>', 'with', 'then', 'else', ';', 'in', 'do'})
            if w in ('let', 'have'): cls = 'LET-BOUND'
            elif w in ('def', 'instance', 'theorem', 'abbrev', 'opaque', 'where', ':=', '<BOF>'): cls = 'TAIL'
            elif w == '<open>':
                cls = 'STRUCT-FIELD' if start >= 2 and toks[start-2][1] not in OPEN else 'OTHER:=('
            elif w == 'with': cls = 'STRUCT-FIELD'
            else: cls = 'OTHER:=' + w
        elif prev in ('match', 'if'): cls = 'SCRUTINEE'
        elif prev == ';': cls = 'TAIL-LETBODY'
        elif prev in ('<BOF>', 'in'): cls = 'TAIL'
        elif prev == ',' or nxt == ',' or prev == '[': cls = 'TUPLE-OR-LIST'
        elif prev in ('<|', '$', ')', ']') or IDENT.match(prev): cls = 'ARGUMENT'
        elif prev in ('←', 'do'): cls = 'MONADIC-STMT'
        else: cls = 'OTHER'
        return result(cls, prev, chain, start, end)

    def dead_binding(self, rel, res):
        """For a LET-BOUND / LET-BOUND-FUN unit: the bound names, and whether NONE of
        them occurs again before the next declaration header (-> DISCARDABLE).
        Returns (names, dead)."""
        if res['cls'] not in ('LET-BOUND', 'LET-BOUND-FUN'): return [], False
        toks, pairs, headers = self.tokens_of(rel)
        start, end = res['start'], res['end']
        # LET-BOUND: prev is `:=`; LET-BOUND-FUN: the head is `fun` whose prev is `:=`
        k = start - 1
        while k >= 0 and toks[k][1] != ':=': k -= 1
        j, w = self.walk_back(toks, k-1, {'let', 'have'})
        if w not in ('let', 'have'): return [], False
        names = []
        depth = 0
        for t in range(j+1, k):
            word = toks[t][1]
            if word in OPEN: depth += 1; continue
            if word in CLOSE: depth -= 1; continue
            if word == ':' and depth == 0: break
            if IDENT.match(word) and word not in ('fun', 'λ'): names.append(word)
        if not names: return [], True
        if all(n == '_' or n.startswith('_') for n in names): return names, True
        # the body: tokens after the unit up to the next declaration header
        unit_off = toks[start][0]
        nxt_hdr = next((h for h in headers if h > unit_off), None)
        body = [w for off, w in toks[end+1:] if nxt_hdr is None or off < nxt_hdr]
        used = any(n in body for n in names)
        return names, not used


def main():
    root, census_path = sys.argv[1], sys.argv[2]
    out = sys.argv[3] if len(sys.argv) > 3 else None
    census = json.load(open(census_path))
    c = Classifier(root)
    rows = []
    from collections import Counter
    for s in census['sites']:
        r = c.classify(s['file'], s['offset'])
        names, dead = c.dead_binding(s['file'], r)
        rows.append(dict(s, position=r['cls'], prev_token=r['prev'], climb=r['chain'], context=r['ctx'],
                         let_names=names, discardable=dead))
    if out:
        json.dump({'schema': 3, 'method': __doc__, 'sites': rows}, open(out, 'w'), indent=1, ensure_ascii=False)
    print(Counter(r['position'] for r in rows).most_common())
    print('discardable:', sum(1 for r in rows if r['discardable']))


if __name__ == '__main__': main()
