#!/usr/bin/env python3
"""Position class of each failure site — mechanical, token-level, with CLIMB.

Reuses scripts/failure_census.py's comment stripper and tokenizer so offsets agree
with the census JSON. The 'unit' starts as the failure expression (the innermost
`( failwithI ... : T )` group when present, else the failure token). The unit is
then CLIMBED to the maximal expression whose value IS the failure whenever the
failure's branch is taken:
  - pure wrapper parentheses are peeled;
  - if the unit is a match arm body (`| pat => unit`) the unit becomes the whole
    `match ... with ...` expression (head = the `match` token found by walking back
    at the same bracket depth to the `with` and its `match`);
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
  OTHER         anything else (manual review)
`chain` records every climb step for audit.
"""
import json, sys, re
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'scripts'))
import failure_census as fc

ROOT = Path(sys.argv[1]).resolve()
census = json.load(open(sys.argv[2]))
out = sys.argv[3]
OPEN = {'(': ')', '[': ']', '{': '}'}
CLOSE = {v: k for k, v in OPEN.items()}
IDENT = re.compile(r"^[A-Za-z_][\w'.!?]*$")
cache = {}

def tokens_of(rel):
    if rel not in cache:
        clean = fc.strip_comments((ROOT / rel).read_text())
        toks = [(m.start(), m[0]) for m in fc.TOKEN.finditer(clean)]
        stack, pairs = [], {}
        for i, (_, w) in enumerate(toks):
            if w in OPEN: stack.append(i)
            elif w in CLOSE and stack:
                o = stack.pop(); pairs[o] = i; pairs[i] = o
        cache[rel] = (toks, pairs)
    return cache[rel]

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

line_cache = {}
def line_of(rel, off):
    if rel not in line_cache:
        line_cache[rel] = (ROOT / rel).read_text()
    return line_cache[rel].count('\n', 0, off)

def classify(rel, offset):
    toks, pairs = tokens_of(rel)
    generated = Path(rel).parent.name == 'generated'
    idx = {s: i for i, (s, _) in enumerate(toks)}
    i = idx.get(offset)
    if i is None: return 'OFFSET-MISS', '', [], ''
    start, end = i, i
    if i > 0 and toks[i-1][1] == '(' and (i-1) in pairs:
        start, end = i-1, pairs[i-1]
    chain = []
    for _ in range(60):
        while start > 0 and toks[start-1][1] == '(' and pairs.get(start-1) == end + 1:
            start, end = start-1, end+1
        # the head sits first inside a paren group whose extent we do not know
        # (a climbed `match`/`if`/`let`): adopt the whole group as the unit
        if start > 0 and toks[start-1][1] == '(' and (start-1) in pairs and pairs[start-1] > end:
            start, end = start-1, pairs[start-1]
            continue
        prev = toks[start-1][1] if start > 0 else '<BOF>'
        # hand-written files: a statement boundary is a NEWLINE, not a token
        if not generated and start > 0 and line_of(rel, toks[start-1][0]) < line_of(rel, toks[start][0]) \
           and prev not in (':=', '=>', 'then', 'else', '(', ',', '[', '<|', '$', 'do', '←', 'fun', 'λ', 'with', 'in', ';', '|', 'if', 'match', 'return', 'pure', '&&', '||', '+', '-', '*', '/', '++', '==', '!=', '<', '>', '≤', '≥', '::', '<$>', '>>=', '|>', '<;>'):
            chain.append('newline-stmt'); return 'STMT-NEWLINE', prev, chain, ctx(toks, start, end)
        if prev == ';':
            j, w = walk_back(toks, start-2, {'let', 'have'})
            if w in ('let', 'have'):
                chain.append('let-body'); start = j; continue
            chain.append(';?'); return 'OTHER;', prev, chain, ctx(toks, start, end)
        if prev == '=>':
            # match arm or fun body? walk back over the pattern to `|`/`fun`/`with`
            j, w = walk_back(toks, start-2, {'|', 'fun', 'λ', 'with', 'match', 'if', 'then', 'else', ':=', ';'})
            if w in ('fun', 'λ'):
                # a lambda: def-body lambda (`def f : A → B := fun x => ...`) is TAIL;
                # let-bound / argument lambdas are callbacks
                fp = toks[j-1][1] if j > 0 else '<BOF>'
                if fp == '(' and (j-1) in pairs:
                    chain.append('fun-body'); start, end = j-1, pairs[j-1]
                    # the parenthesised lambda is an argument (or component)
                    prev2 = toks[start-1][1] if start > 0 else '<BOF>'
                    return 'LAMBDA-BODY', prev2, chain, ctx(toks, start, end)
                if fp == ':=':
                    k2, w2 = walk_back(toks, j-2, {'let', 'have', 'def', 'instance', 'theorem', 'abbrev', 'opaque', 'where', ':=', '=>', 'with', 'then', 'else', ';', 'in', 'do'})
                    if w2 in ('def', 'instance', 'theorem', 'abbrev', 'opaque', 'where', ':=', '<BOF>'):
                        chain.append('def-body-fun'); return 'TAIL', prev, chain, ctx(toks, start, end)
                    if w2 in ('let', 'have'):
                        chain.append('let-bound-fun'); return 'LET-BOUND-FUN', prev, chain, ctx(toks, start, end)
                chain.append(f'fun-body({fp})'); return 'LAMBDA-BODY', fp, chain, ctx(toks, start, end)
            if w == '|':
                # find the `with` of this match: walk back from the `|` to `with`
                k, w2 = walk_back(toks, j-1, {'with'})
                # NOTE: arms' bodies sit at the same depth; the nearest `with` at
                # depth 0 is this match's only if nested matches are parenthesised
                # (the generator parenthesises them). Recorded in the chain.
                if w2 == 'with':
                    m, w3 = walk_back(toks, k-1, {'match'})
                    if w3 == 'match':
                        chain.append('match-arm'); start = m; end = max(end, k)
                        continue
                if w2 in ('<BOF>', '<open>'):
                    chain.append('eqn-arm'); return 'TAIL', prev, chain, ctx(toks, start, end)
                chain.append(f'arm?{w2}'); return 'OTHER-ARM', prev, chain, ctx(toks, start, end)
            chain.append(f'=>?{w}'); return 'OTHER=>', prev, chain, ctx(toks, start, end)
        if prev in ('then', 'else'):
            j, w = walk_back(toks, start-2, {'if'})
            if w == 'if':
                chain.append(f'{prev}-branch'); start = j; continue
            chain.append(f'{prev}?'); return 'OTHER-IF', prev, chain, ctx(toks, start, end)
        break
    prev = toks[start-1][1] if start > 0 else '<BOF>'
    nxt = toks[end+1][1] if end+1 < len(toks) else '<EOF>'
    if prev == ':=':
        j, w = walk_back(toks, start-2, {'let', 'have', 'def', 'instance', 'theorem', 'abbrev', 'opaque', 'where', ':=', '=>', 'with', 'then', 'else', ';', 'in', 'do'})
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
    return cls, prev, chain, ctx(toks, start, end)

def ctx(toks, start, end):
    return ' '.join(w for _, w in toks[max(0, start-12):start]) + '  ▶' + ' '.join(w for _, w in toks[start:min(end+1, start+14)])[:90] + '…◀  ' + ' '.join(w for _, w in toks[end+1:end+5])

rows = []
for s in census['sites']:
    cls, prev, chain, c = classify(s['file'], s['offset'])
    rows.append(dict(s, position=cls, prev_token=prev, climb=chain, context=c))
json.dump({'schema': 2, 'method': __doc__, 'sites': rows}, open(out, 'w'), indent=1, ensure_ascii=False)
from collections import Counter
print(Counter(r['position'] for r in rows).most_common())
