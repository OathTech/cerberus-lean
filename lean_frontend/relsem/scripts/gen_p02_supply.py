#!/usr/bin/env python3
# gen_p02_supply.py — PERF-1 (2026-08-28): THE P02 SUPPLY GENERATOR,
# committed/versioned (review amendment A11: the generator precedes
# the fused supply becoming the default path).
#
# Input: the V2Probe transcript (5 representative runs, one per data
# path of sat_add). GROUND TRUTH provenance: RelSem/V2Probe.lean
# (resurrectable from git 055a1834b — see the V2b pause record
# lean_frontend/docs/2026-08-28_v2b-pause-record.md §1/§6) run at
# hi (1000000007, 1200000033) / midA (1000000007, 33) /
# midB (-1000000007, 33) / lo (-1000000007, -1200000033) /
# midC (0, 424242433). The transcript is an INSTRUMENT ARTIFACT
# (container scratch, not committed): every emitted lemma is
# ordinary checked Lean — the generator carries NO trust.
#
# Emission (PERF-1 mechanisms A+B):
#  * COMMITTED-CHOICE DISPATCH keyed down to ARM FORM (the r127
#    lesson; Lithium interpreter.v syntax-directed selection): class
#    (TAU/LOAD/Erun/guard/arith) x op x verdict x arm OPERAND FORM
#    (primitive PEconv_int / literal-first-operand unary minus /
#    conv-call); VALUES are read off the transcript and fed as
#    tactic arguments. An unkeyed form is a LOUD generation error.
#  * BLOCK-FUSED SUPPLY (the operator-ratified default unit):
#    maximal straight-line pure-control runs between cut points
#    become ONE @[seg_block] SegStep lemma each, proved by the
#    once-proved sequence composition (SegStep.trans over link_ctl
#    — Floyd 1967 cut points + the Hoare 1969 sequence rule at
#    generation time). Anchors (first round, births, loads, cell
#    reads, guards/ariths, Erun, terminals, singleton runs) remain
#    per-round @[seg_round] facts — the escalation ladder.
#  * NO heartbeat budgets: every emitted lemma runs at the DEFAULT
#    budget (the pinned-discovery seg_discover regime); a slow round
#    is a loud build failure, never a budget raise.
#
# Usage: python3 gen_p02_supply.py <transcript> <OUT.lean>
#   (OUT = RelSem/P02Rounds.lean; chunks A-D written alongside.)
import re, sys, hashlib, collections

SRC = sys.argv[1]
OUT = sys.argv[2]

runs_meta = {
  "hi":  dict(a=1000000007, b=1200000033),
  "mA":  dict(a=1000000007, b=33),
  "mB":  dict(a=-1000000007, b=33),
  "lo":  dict(a=-1000000007, b=-1200000033),
  "mC":  dict(a=0, b=424242433),
}
tag_by_header = {
  "hi (1000000007, 1200000033)": "hi",
  "midA (1000000007, 33)": "mA",
  "midB (-1000000007, 33)": "mB",
  "lo (-1000000007, -1200000033)": "lo",
  "midC (0, 424242433)": "mC",
}

text = open(SRC).read()
# split runs
runs = []
for m in re.finditer(r"@@@@@ P02 ([^@]+) @@@@@\n", text):
    runs.append((m.group(1).strip(), m.end()))
run_bodies = []
for i,(hdr,start) in enumerate(runs):
    end = runs[i+1][1]-len("@@@@@ P02 "+runs[i+1][0]+" @@@@@\n") if i+1 < len(runs) else len(text)
    run_bodies.append((tag_by_header[hdr], text[start:end]))

# ---------- abstraction ----------
def abstract(body, tag):
    a = runs_meta[tag]["a"]; b = runs_meta[tag]["b"]
    subs = []
    def lit(n): return f"({n})"
    # derived first (longest / most specific)
    cand = []
    if tag != "mC":
        cand.append((2147483647-a, "(2147483647 - a)"))
        cand.append((-2147483648-a, "(-2147483648 - a)"))
        cand.append((a+b, "(a + b)"))
        cand.append((a, "a"))
    # midC: the add result EQUALS b — prefer the plain var (the
    # `0 + b` spelling is not defeq to `b` at symbolic b and would
    # break the cell/trace match against the caller's `xBytes b`;
    # the exit rewrite handles satAdd 0 b = b by omega)
    cand.append((b, "b"))
    for v, repl in cand:
        if tag == "mC" and v == 0: continue
        subs.append((f"(.IV .Prov_none ({v}))", f"(.IV .Prov_none {repl})"))
        subs.append((f"(.IV .Prov_none ({v} : Int))", f"(.IV .Prov_none {repl})"))
    out = body
    for old, new in subs:
        out = out.replace(old, new)
    return out

# ---------- symbol renaming ----------
sym_re = re.compile(r'\(Symbol "" (\d+) \(SD_Id "([A-Za-z_0-9]+)"\)\)')
def sym_const(name):
    return "p02s_" + name
all_syms = {}

def rename_syms(s):
    def f(m):
        num, name = m.group(1), m.group(2)
        all_syms[name] = num
        return sym_const(name)
    return sym_re.sub(f, s)

# ---------- parse rounds ----------
Round = collections.namedtuple("Round", "idx cls sup arena env trace")
def parse_run(body, tag):
    rounds = []
    parts = re.split(r"===== ROUND \[(\d+)\] ", body)
    # parts[0] header junk; then idx, rest pairs
    for i in range(1, len(parts), 2):
        idx = int(parts[i]); rest = parts[i+1]
        header, _, rest2 = rest.partition("\n")
        clsm = re.match(r"([A-Z_]+(?:\[[^\]]*\])?) \| sym=(\d+) aid=(\d+) exc=(\d+) ctr=(\d+)", header)
        if clsm is None: raise RuntimeError("hdr: "+header[:120])
        cls = clsm.group(1)
        sup = dict(sym=int(clsm.group(2)), aid=int(clsm.group(3)),
                   exc=int(clsm.group(4)), ctr=int(clsm.group(5)))
        am = re.match(r"ARENA := (.*)\nENV:\n((?:    .*\n)*)TRACE\(\d+\) := \[(.*?)\]\n", rest2, re.S)
        arena = am.group(1)
        envtxt = am.group(2)
        trace = am.group(3)
        env = []
        for lm in re.finditer(r"    (\(Symbol[^↦]*\)) ↦ (.*)", envtxt):
            env.append((lm.group(1).strip(), lm.group(2).strip()))
        arena = rename_syms(abstract(arena, tag))
        env = [(rename_syms(k), rename_syms(abstract(v, tag))) for k,v in env]
        trace = rename_syms(abstract(trace, tag))
        rounds.append(Round(idx, cls, sup, arena, env, trace))
    return rounds

parsed = {tag: parse_run(body, tag) for tag, body in run_bodies}

# ---------- arena dedupe ----------
arena_ids = {}
arena_list = []
def arena_id(a):
    if a not in arena_ids:
        arena_ids[a] = len(arena_list)
        arena_list.append(a)
    return arena_ids[a]

for tag, rs in parsed.items():
    for r in rs:
        arena_id(r.arena)

# ---------- trace conversion ----------
# ME_load entries: (ME_load L0 none (Ctype ...) (.PV (.Prov_some N) (.PVconcrete none ADDR)) «MV:MVinteger (Signed Int_) (.IV .Prov_none V)»)
tr_re = re.compile(r"\(ME_load L0 none \(Ctype \[\] \(Basic \(Integer \(Signed Int_\)\)\)\) \(.PV \(.Prov_some (\d+)\) \(.PVconcrete none (\d+)\)\) «MV:MVinteger \(Signed Int_\) \(.IV .Prov_none ([^»]*)\)»\)")
def conv_trace(tr):
    items = []
    if tr.strip():
        for m in tr_re.finditer(tr):
            aid, addr, val = m.groups()
            fn = {"0": "p02meLoadA", "1": "p02meLoadB"}.get(aid)
            if fn is None: raise RuntimeError("trace aid "+aid)
            items.append(f"{fn} {val.strip()}" if not val.strip().lstrip("-").isdigit() or True else f"{fn} ({val})")
        # count check
        n_paren = tr.count("ME_load")
        if n_paren != len(items): raise RuntimeError("trace parse miss: "+tr[:80])
    return "[" + ", ".join(items) + "]"

# ---------- per-round instances (dedup across runs) ----------
insts = {}
order = []
hards = []
run_keys = {}   # tag -> the run's ordered instance-key sequence
for tag, rs in parsed.items():
    run_keys[tag] = []
    for j in range(len(rs)-1):
        cur, nxt = rs[j], rs[j+1]
        key_env_cur = dict(cur.env); key_env_nxt = dict(nxt.env)
        births = [k for k,_ in nxt.env if k not in key_env_cur]
        # order births by first occurrence in cur.arena (pattern order)
        births.sort(key=lambda k: cur.arena.find(k) if cur.arena.find(k)>=0 else 1<<30)
        aidbump = nxt.sup["aid"] - cur.sup["aid"]
        key = (arena_id(cur.arena), arena_id(nxt.arena), cur.cls,
               tuple((bk, key_env_nxt[bk]) for bk in births), aidbump,
               conv_trace(cur.trace), conv_trace(nxt.trace),
               cur.sup["ctr"], nxt.sup["ctr"], j == 0)
        run_keys[tag].append(key)
        if key in insts:
            insts[key]["tags"].add(tag)
            continue
        insts[key] = dict(tags={tag}, cur=cur, nxt=nxt, births=births,
                          aidbump=aidbump, first=(j == 0))
        order.append(key)
    # terminal round
    last = rs[-1]
    key = ("TERM", arena_id(last.arena), conv_trace(last.trace),
           last.sup["ctr"])
    run_keys[tag].append(key)
    if key not in insts:
        insts[key] = dict(tags={tag}, cur=last, nxt=None, births=[],
                          aidbump=0, term=True)
        order.append(key)
    else:
        insts[key]["tags"].add(tag)

# ---------- read detection (tree diff) ----------
def tokenize(s):
    return re.findall(r"\(|\)|\[|\]|[^\s()\[\]]+", s)
def parse_sexp(toks, i=0):
    # returns (node, next)
    t = toks[i]
    if t in "([":
        close = ")" if t == "(" else "]"
        items = []
        i += 1
        while toks[i] != close:
            node, i = parse_sexp(toks, i)
            items.append(node)
        return (tuple(items) if t=="(" else ("LIST",)+tuple(items)), i+1
    else:
        return t, i+1

def diff_subtrees(x, y, acc):
    if x == y: return
    if isinstance(x, tuple) and isinstance(y, tuple) and len(x)==len(y):
        diffs = [k for k in range(len(x)) if x[k]!=y[k]]
        if len(diffs) == 1:
            diff_subtrees(x[diffs[0]], y[diffs[0]], acc)
            return
    acc.append((x, y))

def syms_in(node, out):
    if isinstance(node, tuple):
        if len(node)>=2 and node[0]=="PEsym":
            out.append(node[1])
        for c in node:
            syms_in(c, out)

def detect_reads(inst):
    cur, nxt = inst["cur"], inst["nxt"]
    if inst.get("term") or cur.cls.startswith("TAU["):
        return []
    try:
        tx,_ = parse_sexp(tokenize(cur.arena))
        ty,_ = parse_sexp(tokenize(nxt.arena))
    except Exception:
        return ["PARSE_FAIL"]
    acc=[]
    diff_subtrees(tx, ty, acc)
    envd = dict(cur.env)
    reads=[]
    for old,new in acc:
        so=[]; sn=[]
        syms_in(old, so); syms_in(new, sn)
        for s in so:
            if s in envd and s not in sn and s not in reads:
                reads.append(s)
    return reads

for k in order:
    insts[k]["reads"] = detect_reads(insts[k])

# ---------- classification for stats ----------
stats = collections.Counter()
for k in order:
    i = insts[k]
    if i.get("term"): stats["TERM"] += 1
    else: stats[i["cur"].cls] += 1
print("distinct round instances:", len(order))
for c,n in stats.most_common(): print(" ", c, n)
print("arenas:", len(arena_list), "total chars:", sum(len(a) for a in arena_list))
n_reads = collections.Counter(tuple(insts[k]["reads"]) and len(insts[k]["reads"]) for k in order)
print("read counts:", dict(n_reads))

# ================= EMISSION =================
def render(node):
    if isinstance(node, str): return node
    if isinstance(node, tuple):
        if len(node)>0 and node[0]=="LIST":
            return "[" + ", ".join(render(c) for c in node[1:]) + "]"
        return "(" + " ".join(render(c) for c in node) + ")"
    raise RuntimeError(str(node))

# ---- terminal value extraction ----
def term_value(arena):
    t,_ = parse_sexp(tokenize(arena))
    # (Expr annots (Epure (Pexpr annots () (PEval V))))
    def find(n):
        if isinstance(n, tuple):
            if len(n)>=2 and n[0]=="PEval":
                return n[1] if len(n)==2 else tuple(["PEval-ERR"])
            for c in n:
                r=find(c)
                if r is not None: return r
        return None
    v = find(t)
    return render(v)

# ---- arena factoring (greedy shared-substring on rendered subtrees) ----
corpus = list(arena_list)  # mutable strings
def tok_spans(s):
    return [(m.group(0), m.start(), m.end())
            for m in re.finditer(r"\(|\)|\[|\]|[^\s()\[\]]+", s)]
def parse_spans(toks, i=0):
    t, st, en = toks[i]
    if t in "([":
        close = ")" if t == "(" else "]"
        items=[]; i+=1
        while toks[i][0] != close:
            node, i = parse_spans(toks, i)
            items.append(node)
        return ((st, toks[i][2], tuple(x for x in items)), i+1)
    else:
        return ((st, en, t), i+1)
subcount = collections.Counter()
FRAG_HEADS={"Expr":"RExpr","Pattern":"generic_pattern sym",
            "Pexpr":"generic_pexpr Unit sym"}
def head_of(src_sub):
    m=re.match(r"\(\s*([A-Za-z_0-9]+)", src_sub)
    return m.group(1) if m else ""
def walk_spans(node, src):
    st, en, payload = node
    if isinstance(payload, tuple):
        if en-st >= 300 and src[st]=="(" and head_of(src[st:en]) in FRAG_HEADS:
            subcount[src[st:en]] += 1
        for c in payload: walk_spans(c, src)
for a in arena_list:
    root,_ = parse_spans(tok_spans(a))
    walk_spans(root, a)

cands = sorted([s for s,c in subcount.items() if c>=2],
               key=len, reverse=True)
selected = []  # (name, body)
def var_params(s):
    ps=[]
    if re.search(r"(?<![A-Za-z0-9_])a(?![A-Za-z0-9_])", s): ps.append("a")
    if re.search(r"(?<![A-Za-z0-9_])b(?![A-Za-z0-9_])", s): ps.append("b")
    return ps
kctr=0
for s in cands:
    total = sum(t.count(s) for t in corpus) + sum(b.count(s) for _,b in selected)
    if total < 2: continue
    name=f"p02n{kctr}"; kctr+=1
    ps=var_params(s)
    call = f"({name}{''.join(' '+p for p in ps)})" if ps else name
    corpus=[t.replace(s, call) for t in corpus]
    selected=[(n, b.replace(s, call)) for n,b in selected]
    selected.append((name, s))

out=[]
out.append("""/-
  RelSem.P02Rounds — V2b (2026-08-28): THE P02 (sat_add) ROUND SUPPLY,
  GENERATED (gen_p02.py at the container .v2b-logs; ground truth: the
  V2Probe transcripts at five representative inputs — one per path:
  hi (1000000007, 1200000033), midA (1000000007, 33),
  midB (-1000000007, 33), lo (-1000000007, -1200000033),
  midC (0, 424242433) — symbolic positions a/b/(a+b)/(2147483647 - a)/
  (-2147483648 - a) re-abstracted from the concrete values; the midC
  path is stated at the literal a = 0, the a = 0 case being reached by
  subst in the proof). Round statements carry `:= by seg_round_tac`;
  the HARD rounds (guard compare/verdict chains, the checked
  subtract/add, the ret jump) are hand-written below on the same laws.
  Families/protocol mirror T2Rounds (the two-argument program).

  House rules: no sorry, no axioms. Under the in-build audit.
-/

import RelSem.P01Rounds
import RelSem.T1Proof
import RelSem.T2Rounds
import RelSem.SegRoundTac
import RelSem.CorpusFiles
import RelSem.CorpusStatements

set_option autoImplicit false
set_option maxHeartbeats 2000000

namespace RelSem.P02

open RelSem RelSem.Cerb RelSem.Kit RelSem.CerbSt RelSem.Corpus
open Lem_Basic_classes (ordCompare)
open RelSem.T1 (T1P RExpr aU intCty xAddr xPtr xPtrV loadedV xBytes
  mkByte roundtrip_arith allocX allocXS mr0 mr1
  memValueToBytes_int memValueFromValue_int
  birth_new birth_pres birth_rev birth_wfp)
open RelSem.P01 (L0 clsNone dbl_new₁ dbl_new₂ dbl_pres dbl_rev
  dbl_wfp)

/-! ## Program symbols (transcript-pinned) -/
""")
for name in sorted(all_syms):
    out.append(f'def {sym_const(name)} : sym := Symbol "" {all_syms[name]} (SD_Id "{name}")')
out.append("")

# ---- the T2 template block, renamed ----
import os
t2src=open(os.path.join(os.path.dirname(os.path.abspath(__file__)),
    "..", "RelSem", "T2Rounds.lean")).read()
blk_start=t2src.index("def bAddr : Int")
blk_end=t2src.index("/-! ## The R10 add chain")
blk=t2src[blk_start:blk_end]
# strip T2's own arena defs (only the stage-0 reference survives, via P02AR0)
a_start=blk.index("/-! ## Arena terms")
a_end=blk.index("/-! ## The T2 families")
blk=blk[:a_start]+blk[a_end:]
ar0call = None  # fill later; leave placeholder P02AR0
renames=[
 ("t2errAddr","p02errAddr"),("t2errPtr","p02errPtr"),
 ("t2allocErrS","p02allocErrS"),("t2mr2","p02mr2"),("t2mr3","p02mr3"),
 ("t2Th0","p02Th0"),("t2σ0","p02σ0"),("t2CtlAt","p02CtlAt"),
 ("t2fam0_frame","p02fam0_frame"),("t2fam_frame","p02fam_frame"),
 ("t2fam0","p02fam0"),("t2fam","p02fam"),("t2Ctl0","p02Ctl0"),
 ("t2_inv0","p02_inv0"),("t2_inv","p02_inv"),
 ("t2Init_inv","p02Init_inv"),("t2Init","p02Init"),
 ("t2thGf","p02thGf"),("t2dGσ","p02dGσ"),("t2dGCtl","p02dGCtl"),
 ("t2dGfam","p02dGfam"),("t2dG_inv","p02dG_inv"),
 ("t2k1_fam","p02k1_fam"),("t2k3_any","p02k3_any"),
 ("t2k4_any","p02k4_any"),("t2k5_any","p02k5_any"),
 ("t2_init_ctl_eq","p02_init_ctl_eq"),
 ("t2_init_sup_eq","p02_init_sup_eq"),
 ("t2_init_mrest_eq","p02_init_mrest_eq"),
 ("t2memA","p02memA"),("t2k6_fam","p02k6_fam"),("t2k8_fam","p02k8_fam"),
 ("t2σ","p02σ"),("t2Th","p02Th"),
 ("t2File","p02File"),("t2Fs","corpusFs"),
 ("addT2Sym","satAddP02Sym"),
 ('resolveFunSym p02File "add"','resolveFunSym p02File "sat_add"'),
 ("t2symA536","P02_UNUSED_A536"),  # avoid catching t2symA prefix issues
 ("t2symA","p02s_a"),("t2symB","p02s_b"),
 ("loadB_eq_facts","p02loadB_eq_facts"),
 ("t2ar0","P02AR0"),
]
for o,n in renames: blk=blk.replace(o,n)
blk=blk.replace("theorem p02_inv ","@[seg_inv]\ntheorem p02_inv ")
blk=blk.replace("theorem p02_inv0 ","@[seg_inv]\ntheorem p02_inv0 ")
T2BLOCK_MARK="@@T2BLOCK@@"
out.append(T2BLOCK_MARK)

# ---- meLoad defs ----
out.append("""
/-! ## Trace events -/

def p02meLoadA (v : Int) : trace_event :=
  ME_load CerbLocation.Loc.unknown none intCty
    (.PV (.Prov_some 0) (.PVconcrete none 281474976710648))
    (CerbMem.MemValue.MVinteger (Signed Int_)
      (CerbMem.IntegerValue.IV .Prov_none v))

def p02meLoadB (v : Int) : trace_event :=
  ME_load CerbLocation.Loc.unknown none intCty
    (.PV (.Prov_some 1) (.PVconcrete none 281474976710644))
    (CerbMem.MemValue.MVinteger (Signed Int_)
      (CerbMem.IntegerValue.IV .Prov_none v))

/-! ## Shared arena fragments (hash-consed) -/
""")
for name, body in reversed(selected):
    ps=var_params(body)
    sig = "".join(f" ({p} : Int)" for p in ps)
    fty = FRAG_HEADS[head_of(body)]
    out.append(f"private def {name}{sig} : {fty} :=\n  {body}\n")

out.append("/-! ## Arenas -/\n")
for i, a in enumerate(corpus):
    ps = var_params(a)
    sig = "".join(f" ({p} : Int)" for p in ps)
    out.append(f"def p02ar{i}{sig} : RExpr :=\n  {a}\n")

def ar_ref(aid_):
    ps = var_params(corpus[aid_])
    return f"(p02ar{aid_}{''.join(' '+p for p in ps)})" if ps else f"p02ar{aid_}"

# splice the T2 block AFTER arenas (it references the stage-0 arena)
blk_final = "/-! ## Families/protocol (T2Rounds mirrored at p02File; renames only) -/\n" + blk
out=[o.replace(T2BLOCK_MARK, "") for o in out]
out.append(blk_final)
out.append('''
/-- The walker's canonical control-image anchor equals the named
    ctl spelling (ONE generic shallow rfl — the ctl projection drops
    the pack fields; PERF-1: seg_done's hinv routes through this so
    no consumer ever defeq-bridges the two spellings). -/
theorem p02ctl_anchor (ar : RExpr) (tr : List trace_event) (n : Nat) :
    ctlOf (p02fam ar tr n
      (RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState))
      = p02CtlAt ar tr n := rfl

/-- The ctl projection at ANY pack (shallow — the projection drops
    the pack fields; seg_done's control obligations route through
    this instead of per-instance deep rfl). -/
theorem p02ctl_any (ar : RExpr) (tr : List trace_event) (n : Nat)
    (p : T1P) :
    ctlOf (p02fam ar tr n p) = p02CtlAt ar tr n := rfl
''')
out=[o.replace("P02AR0", ar_ref(arena_id(parsed["hi"][0].arena))) for o in out]

# ---- classification (committed-choice keys, computed per instance) ----
def needs_ab(txts):
    s=" ".join(txts)
    return var_params(s)

PATHCONDS = {
    "hi": ["0 < a", "2147483647 - a < b"],
    "mA": ["0 < a", "¬ 2147483647 - a < b"],
    "mB": ["¬ 0 < a", "a < 0", "¬ b < -2147483648 - a"],
    "lo": ["¬ 0 < a", "a < 0", "b < -2147483648 - a"],
    "mC": [],
}

def cell_val(vtext):
    """Extract the integer value term from an env cell's
    `(Vloaded (LVspecified (OVinteger (.IV .Prov_none V))))` text."""
    m = re.match(r"\(Vloaded \(LVspecified \(OVinteger \(\.IV "
                 r"\.Prov_none (.*)\)\)\)\)$", vtext)
    if m is None:
        raise RuntimeError("cell_val: unexpected cell shape: " + vtext)
    v = m.group(1)
    return v if v.startswith("(") else f"({v})"

def classify(key):
    """Compute the instance's emission data (cached)."""
    i = insts[key]
    if "cls_done" in i:
        return i
    cur=i["cur"]; nxt=i["nxt"]
    i["tags_s"]="_".join(sorted(i["tags"]))
    if i.get("term"):
        i["cls_done"]=True
        return i
    eIn=arena_id(cur.arena); eOut=arena_id(nxt.arena)
    trIn=conv_trace(cur.trace); trOut=conv_trace(nxt.trace)
    births=i["births"]; envN=dict(nxt.env)
    if births:
        ins_expr="p.f₁"
        for bk in reversed(births):
            ins_expr=f"(@fmapAddBy sym value Lem_Map.instBEqOfMapKeyType (@Lem_Map.mapKeyCompare sym _) {bk} {envN[bk]} {ins_expr})"
        pack="{ p with f₁ := " + ins_expr + " }"
    elif i["aidbump"]:
        pack="{ p with aS := p.aS + 1 }"
    else:
        pack="p"
    hyps=[]
    rangehyps=set()
    envC=dict(cur.env)
    reads=i["reads"]
    if reads==["PARSE_FAIL"]:
        raise RuntimeError(f"arena parse fail at instance {key!r}")
    # deterministic read order: first occurrence in the OLD arena
    reads = sorted(reads, key=lambda s:
        cur.arena.find(s) if cur.arena.find(s)>=0 else 1<<30)
    for ri,rs in enumerate(reads):
        hyps.append(f"(hrd{ri} : lookup_env {rs} [p.f₁] = some {envC[rs]})")
    if i["aidbump"]:
        # the NEW event is CONSED AT THE FRONT of the trace
        firstent = trOut.split("[",1)[1].split(",")[0].strip().rstrip("]").strip()
        fn = "A" if firstent.startswith("p02meLoadA") else "B"
        addr, alloc = ("xAddr","allocXS") if fn=="A" else ("bAddr","allocBS")
        aidn = "0" if fn=="A" else "1"
        lastv = firstent.split(None,1)[1].strip()
        hyps.append(f"(hget : p.ls.allocations.get? {aidn} = some {alloc})")
        hyps.append(f"(hb : ∀ i : Nat, (hi : i < (xBytes {lastv}).length) → p.ls.bytemap.get? ({addr} + (i : Int)) = some (xBytes {lastv})[i])")
        hyps.append("(hlum : p.ls.lastUsedUnionMembers = [])")
        hyps.append("(hfpm : p.ls.funptrmap = [])")
        hyps.append("(hinv : MemInv p.ls)")
        if lastv=="a": rangehyps.add("a")
        if lastv=="b": rangehyps.add("b")
    cls = cur.cls
    def diff_txts():
        try:
            tx,_=parse_sexp(tokenize(cur.arena)); ty,_=parse_sexp(tokenize(nxt.arena))
            acc=[]; diff_subtrees(tx,ty,acc)
            if not acc: return ("","")
            def rnd(node):
                if isinstance(node,str): return node
                if node and node[0]=="LIST": return "["+", ".join(rnd(c) for c in node[1:])+"]"
                return "("+" ".join(rnd(c) for c in node)+")"
            return (rnd(acc[0][0]), rnd(acc[0][1]))
        except Exception:
            return ("","")
    cond_hyps=[]
    dtxt=""; ntxt=""
    if cls.startswith("RS_EVAL[Epure]"):
        dtxt,ntxt=diff_txts()
    is_guard = (dtxt.find("(PEif (Pexpr [(Aloc L0)] () (PEop OpGt")>=0 or
                dtxt.find("(PEif (Pexpr [(Aloc L0)] () (PEop OpLt")>=0) and \
               "conv_int" in dtxt and "PEcatch" not in dtxt
    is_arith = "PEcatch_exceptional_condition" in dtxt
    is_erun = cls.startswith("RS_EVAL[Erun")
    if is_guard or is_arith or is_erun:
        # path-condition intersection over this round's tags
        tglists=[PATHCONDS[t] for t in sorted(i["tags"])]
        conds=[c for c in tglists[0] if all(c in tl for tl in tglists[1:])]
        for k,c in enumerate(conds):
            cond_hyps.append(f"(hp{k} : {c})")
        scan = dtxt + " " + " ".join(hyps) + " " + " ".join(conds)
        for v in ("a","b"):
            if re.search(r"\b%s\b"%v, scan): rangehyps.add(v)
    # COMMITTED-CHOICE DISPATCH (class x op x verdict x ARM FORM;
    # any unkeyed shape is a loud generation error)
    if cls.startswith("TAU[") or cls.startswith("RS_TAU["):
        tac = "seg_round_tau"
    elif cls.startswith("ACTION[LoadRequest"):
        tac = "seg_round_load"
    elif is_erun:
        # the ret-conv jump: the conv CELL is the FIRING return
        # site's argument sym = the unique detected read that is a
        # conv_loaded_int argument (the arena may still carry the
        # other return sites' conv calls; the diff-based reads list
        # also carries jump-discard noise); loud on ambiguity
        argsyms = re.findall(
            r"p02s_conv_loaded_int\).{0,200}?PEsym (p02s_a_\d+)",
            cur.arena, re.S)
        cands = [s for s in reads if s in argsyms]
        if len(cands) != 1:
            raise RuntimeError(
                f"Erun round: firing conv cell ambiguous: {cands}")
        convsym = cands[0]
        if convsym not in envC:
            raise RuntimeError(f"Erun conv cell {convsym} not in env")
        v = cell_val(envC[convsym])
        # THE VALUE-FORM KEY (PERF-0 bisect finding): a LITERAL ret
        # value closes through the eval skeleton (the whole rest is
        # ground once the cell read plugs — measured <2 s on r60);
        # a SYMBOLIC value needs the proved conv-loop face (its
        # range checks are hypotheses) — seg_round_conv_ret.
        # the ONE real read hypothesis in BOTH cases (the noisy
        # detection's other entries are jump-discard artifacts; a
        # pointer-cell read would push the round outside the link
        # shapes — birth + 1 read is link_birth1_env1)
        hyps = [f"(hrd0 : lookup_env {convsym} [p.f₁] = some {envC[convsym]})"]
        if re.match(r"^\(-?\d+\)$", v):
            tac = "seg_round_eval"
            cond_hyps = []   # no side conditions needed at literals
        else:
            for var in ("a","b"):
                if re.search(r"\b%s\b"%var, v): rangehyps.add(var)
            tac = f"seg_round_conv_ret {v}"
    elif is_guard:
        gop = "gt" if "PEop OpGt" in dtxt else "lt"
        gv = "T" if ".Prov_none (1)" in ntxt else "F"
        tac = f"seg_round_guard_{gop}{gv}"
    elif is_arith:
        iop = "sub" if "IOpSub" in dtxt else "add"
        # THE ARM-FORM KEY (one level below op/verdict — the r127
        # lesson: primitive vs call conversion forms never unify
        # against each other's lemmas)
        if "PEconv_int" in dtxt:
            form = "prim"
        elif re.search(r"IOp(?:Add|Sub) \(Pexpr \[\(Aloc L0\)\] \(\) \(PEval", dtxt):
            form = "neglit"
        else:
            form = "call"
        if iop == "add" and form == "prim":
            if len(reads) != 2:
                raise RuntimeError("prim-add round without 2 reads")
            v1 = cell_val(envC[reads[0]]); v2 = cell_val(envC[reads[1]])
            if v1 == "(0)":
                # ZERO-LEFT key: the successor spells the plain
                # variable (0 + b not defeq to b) — the normalizing
                # face p02add_evalR0
                tac = f"seg_round_arith_add_prim_z {v2}"
            else:
                tac = f"seg_round_arith_add_prim {v1} {v2}"
        elif form == "neglit":
            tac = "seg_round_neg_lit"
        elif form == "call":
            tac = f"seg_round_arith_{iop}"
        else:
            raise RuntimeError(
                f"UNKEYED arith arm form: iop={iop} form={form} "
                f"(committed choice demands a key; add the form key "
                f"and its content lemma before regenerating)")
    else:
        tac = "seg_round_eval"
    hyps = hyps + cond_hyps
    rh=""
    if "a" in rangehyps: rh += " (ha1 : -2147483648 ≤ a) (ha2 : a ≤ 2147483647)"
    if "b" in rangehyps: rh += " (hb1 : -2147483648 ≤ b) (hb2 : b ≤ 2147483647)"
    i.update(eIn=eIn, eOut=eOut, trIn=trIn, trOut=trOut, pack=pack,
             hyps=hyps, rh=rh, tac=tac,
             fusible=(not i.get("first") and pack=="p" and not hyps
                      and tac in ("seg_round_tau","seg_round_eval")))
    i["cls_done"]=True
    return i

for key in order:
    classify(key)

# ---- block partition (mechanism B: maximal pure-control runs) ----
blocks = {}          # identity(tuple of keys) -> block index
block_list = []      # [ [keys...] ]
fused_keys = set()   # instances consumed by some block
for tag in sorted(run_keys):
    seq = run_keys[tag]
    grp = []
    def flush(grp):
        if len(grp) >= 2:
            ident = tuple(grp)
            if ident not in blocks:
                blocks[ident] = len(block_list)
                block_list.append(list(grp))
            for k in grp:
                fused_keys.add(k)
    for k in seq:
        if classify(k).get("fusible"):
            grp.append(k)
        else:
            flush(grp); grp = []
    flush(grp)

# an instance fused in one run may still sit in a SINGLETON position
# in another run (block starts elsewhere): emit it per-round too
needed_per_round = set()
for tag in sorted(run_keys):
    seq = run_keys[tag]
    grp = []
    for k in seq:
        if classify(k).get("fusible"):
            grp.append(k)
        else:
            if len(grp) == 1: needed_per_round.add(grp[0])
            grp = []
    if len(grp) == 1: needed_per_round.add(grp[0])

# ---- emission units ----
rounds_out=[]
blocks_out=[]
nround=0
n_anchor=0
for key in order:
    i=classify(key)
    cur=i["cur"]; nxt=i["nxt"]
    tags=i["tags_s"]
    if i.get("term"):
        rv=term_value(cur.arena)
        name=f"p02term_{tags}"
        arE=ar_ref(arena_id(cur.arena)); trE=conv_trace(cur.trace)
        binders="".join(f" ({p} : Int)" for p in needs_ab([corpus[arena_id(cur.arena)],trE,rv]))
        rounds_out.append(f"""@[seg_round]
theorem {name}{binders} (p : T1P) :
    app (dnmsRoundM p02File.tagDefs 0)
        (p02fam {arE} {trE} {cur.sup['ctr']} p)
      = (NDactive (Sum.inr [Step_done2 ({rv})]),
         p02fam {arE} {trE} {cur.sup['ctr']} p) := by
  seg_round_term
""")
        nround+=1
        continue
    if key in fused_keys and key not in needed_per_round:
        nround+=1
        continue   # block-granular default: no per-round emission
    name=f"p02r{nround}_{tags}"
    entry = "p02fam0 p" if i.get("first") else (
        f"p02fam {ar_ref(i['eIn'])} {i['trIn']} {cur.sup['ctr']} p")
    stmt_txts=[corpus[i["eIn"]],corpus[i["eOut"]],i["trIn"],i["trOut"],
               i["pack"]," ".join(i["hyps"]),i["rh"],i["tac"]]
    binders="".join(f" ({p} : Int)" for p in needs_ab(stmt_txts))
    hyptxt=("\n    "+"\n    ".join(i["hyps"])) if i["hyps"] else ""
    rounds_out.append(f"""@[seg_round]
theorem {name}{binders}{i["rh"]} (p : T1P){hyptxt} :
    app (dnmsRoundM p02File.tagDefs 0)
        ({entry})
      = (NDactive (Sum.inl NOWAKEUP),
         p02fam {ar_ref(i['eOut'])} {i['trOut']} {nxt.sup['ctr']} {i['pack']}) := by
  {i["tac"]}
""")
    nround+=1
    n_anchor+=1

def fam_of(i, side):
    if side=="I":
        return f"(p02fam {ar_ref(i['eIn'])} {i['trIn']} {i['cur'].sup['ctr']})"
    return f"(p02fam {ar_ref(i['eOut'])} {i['trOut']} {i['nxt'].sup['ctr']})"

for bi, keys in enumerate(block_list):
    ii = [classify(k) for k in keys]
    first, last = ii[0], ii[-1]
    K = len(keys)
    # ONE canonical ctl spelling — the walker's own anchor form
    # (`ctlOf (fam … pack0)`): mixed spellings sent every consumer
    # (block match, round filter, seg_done/p02_inv) through
    # deep-projection defeq (PERF-1 measured grinds)
    PK0 = "(RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)"
    cI = f"ctlOf (p02fam {ar_ref(first['eIn'])} {first['trIn']} {first['cur'].sup['ctr']} {PK0})"
    cO = f"ctlOf (p02fam {ar_ref(last['eOut'])} {last['trOut']} {last['nxt'].sup['ctr']} {PK0})"
    txts=[]
    for i in ii:
        txts += [corpus[i["eIn"]], corpus[i["eOut"]], i["trIn"], i["trOut"]]
    binders="".join(f" ({p} : Int)" for p in needs_ab(txts))
    links=[]
    for i in ii:
        PK0 = "(RelSem.Seg.Pack.mk fmapEmpty 0 0 0 0 CerbMem.initialMemState)"
        cOr = f"ctlOf (p02fam {ar_ref(i['eOut'])} {i['trOut']} {i['nxt'].sup['ctr']} {PK0})"
        links.append(
            f"(Seg.link_ctl (famI := {fam_of(i,'I')}) "
            f"(famO := {fam_of(i,'O')}) (cO := {cOr})\n"
            f"      (p02ShapeC _ _ _) (p02ShapeC _ _ _)\n"
            f"      (fun _ h _ => p02_inv h)\n"
            f"      (fun p _ => by {i['tac']})\n"
            f"      (fun p => rfl))")
    chain = links[-1]
    for l in reversed(links[:-1]):
        chain = f"(Seg.SegStep.trans {l}\n    {chain})"
    blocks_out.append(f"""@[seg_block]
theorem p02blk{bi}{binders} {{GF : Iris.BundledGFunctors}}
    [CerbStGS GF] {{S : Supplies}} {{env : List (sym × value)}}
    {{mr : CerbMem.MemState}} {{al : List (Int × CerbMem.Allocation)}}
    {{bs : List (Int × List CerbMem.AbsByte)}} :
    Seg.SegStep (GF := GF) p02File.tagDefs 0 {K}
      ⟨{cI}, S, env, mr, al, bs⟩
      ⟨{cO}, S, env, mr, al, bs⟩ :=
  {chain}
""")

print(f"blocks: {len(block_list)} covering "
      f"{len(fused_keys)} instances; per-round anchors: {n_anchor}; "
      f"double-emitted (singleton positions): "
      f"{len(needed_per_round & fused_keys)}")
out.append("end RelSem.P02")
open(OUT,"w").write("\n".join(out))
# split emission units (anchor rounds + block facts) across 4
# sibling modules
import math
NCH=4
units = rounds_out + blocks_out
per=math.ceil(len(units)/NCH)
base=OUT[:-5]  # strip .lean
for ci in range(NCH):
    chunk=units[ci*per:(ci+1)*per]
    hdr=f"""/-
  RelSem.P02Rounds{chr(65+ci)} — PERF-1 generated supply (chunk
  {ci+1}/{NCH}; see P02Rounds.lean header and
  scripts/gen_p02_supply.py). BLOCK-GRANULAR DEFAULT: @[seg_block]
  SegStep facts for the straight-line pure-control runs (Floyd cut
  points + the Hoare sequence rule via link_ctl/SegStep.trans),
  @[seg_round] anchors at the cut points. NO per-round heartbeat
  budgets (the pinned-discovery regime; a slow lemma is a loud
  build failure, never a budget).
-/

import RelSem.P02Rounds
import RelSem.P02Guard
import RelSem.SegRun

set_option autoImplicit false
set_option maxHeartbeats 2000000
set_option maxErrors 400

namespace RelSem.P02

open RelSem RelSem.Cerb RelSem.Kit RelSem.CerbSt RelSem.Corpus
open Lem_Basic_classes (ordCompare)
open RelSem.T1 (T1P RExpr aU intCty xAddr xPtr xPtrV loadedV xBytes
  mkByte allocX allocXS mr0 mr1)
open RelSem.P01 (L0)

/-- FamShape at any P02-family instance (all rfl; chunk-local copy —
    consumed by this chunk's block facts). -/
private def p02ShapeC (ar : RExpr) (tr : List trace_event) (n : Nat) :
    Seg.FamShape (p02fam ar tr n) :=
  ⟨fun _ => rfl, fun _ => rfl, fun _ => rfl, fun _ => rfl⟩

"""
    open(base+chr(65+ci)+".lean","w").write(hdr+"\n".join(chunk)+"\nend RelSem.P02\n")
print("emitted", OUT, "+4 chunks; instances:", nround,
      "fragments:", len(selected))
print("base size:", sum(len(o) for o in out),
      "units size:", sum(len(o) for o in units))
