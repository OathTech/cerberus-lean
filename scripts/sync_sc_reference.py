#!/usr/bin/env python3
"""Check/derive an independent Cmm carrier instance; predicate bodies are unchanged."""
from pathlib import Path
import argparse,re,sys
ROOT=Path(__file__).resolve().parents[1]
def code_only(source):
    chars=list(source);i=0;depth=0;quoted=None
    while i<len(source):
        if depth:
            if source.startswith('(*',i):depth+=1;chars[i:i+2]='  ';i+=2;continue
            if source.startswith('*)',i):depth-=1;chars[i:i+2]='  ';i+=2;continue
            if chars[i]!='\n':chars[i]=' '
            i+=1;continue
        if quoted:
            if source[i]=='\\' and quoted=='"':
                chars[i]=' ';i+=1
                if i<len(source) and chars[i]!='\n':chars[i]=' '
                i+=1;continue
            if source[i]==quoted:quoted=None
            if chars[i]!='\n':chars[i]=' '
            i+=1;continue
        if source.startswith('(*',i):depth=1;chars[i:i+2]='  ';i+=2;continue
        if source[i] in ('"','`'):quoted=source[i];chars[i]=' '
        i+=1
    assert depth==0 and quoted is None
    return ''.join(chars)

def inventory(source):
    code=code_only(source)
    names={'type':set(),'function':set(),'field':set()}
    starts=list(re.finditer(r'(?m)^(?:type|let|val|instance|declare)\b',code))
    for i,start in enumerate(starts):
        block=code[start.start():starts[i+1].start() if i+1<len(starts) else len(code)]
        if block.startswith('type '):
            match=re.match(r'type\s+(\w+)\s*=\s*(.*)',block,re.S);assert match,block[:80]
            name,body=match.groups();names['type'].add(name)
            if body.startswith('<|'):
                fields=re.findall(r'(?:<\||;)\s*([A-Za-z]\w*)\s*:',body)
                assert fields,body[:80];names['field'].update(fields)
            else:
                variant=('|' in body or re.match(r'[A-Z][A-Za-z_0-9]*\b',body))
                constructors=re.findall(r'(?:^|\|)\s*([A-Za-z][A-Za-z_0-9]*)\b',body) if variant else []
                names['function'].update(constructors)
        elif block.startswith('val '):
            match=re.match(r'val\s+([A-Za-z]\w*)\s*:',block);assert match,block[:80]
            names['function'].add(match.group(1))
        elif block.startswith('let '):
            match=re.match(r'let\s+(?:(?:rec|inline)\s+|~?\{[^}]*\}\s*)*([A-Za-z]\w*)\b',block)
            assert match,block[:100]
            names['function'].add(match.group(1))
    return {kind:sorted(values) for kind,values in names.items()}

def expected_sources():
    result={}
    for name,source_name in [('sc_reference_aux','cmm_aux'),('sc_reference','cmm_csem')]:
        source=(ROOT/'frontend/concurrency'/(source_name+'.lem')).read_text()
        names=inventory(source)
        if name.endswith('_aux'):
            if source.count('type aid_impl = string')!=1:
                raise ValueError('upstream action-ID carrier anchor changed')
            body=source.replace('type aid_impl = string','type aid_impl = nat')
        else:
            if source.count('open import Cmm_aux')!=1:
                raise ValueError('upstream carrier-import anchor changed')
            body=source.replace('open import Cmm_aux','open import Sc_reference_aux')
        directives=[]
        for kind,values in names.items():
            for value in values:
                prefix='SCRef_' if value[0].isupper() else 'sc_ref_'
                for target in ['ocaml','lean']:
                    directives.append(f'declare {{{target}}} rename {kind} {value} = {prefix}{value}')
        result[name]=('(* Derived logical-carrier instance; predicate bodies unchanged. *)\n'+body+
          '\n(* Target-specific names keep this instance distinct from the live Core adapter. *)\n'+
          '\n'.join(directives)+'\n')
    return result

def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--write',action='store_true',help='rewrite after reviewing reference changes')
    args=parser.parse_args()
    for name,expected in expected_sources().items():
        path=ROOT/'frontend/model'/(name+'.lem')
        if args.write:
            if not path.is_file() or path.read_text()!=expected:path.write_text(expected)
        elif not path.is_file() or path.read_text()!=expected:
            sys.exit('SC reference derivation mismatch: '+str(path))
    print('SC reference: unchanged predicate bodies; explicit carriers; distinct target names')

if __name__=='__main__':main()
