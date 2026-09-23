"""Compare code tokens after lexically removing nested comments; strings stay intact."""
import hashlib,json,re,subprocess
from pathlib import Path
BASE='24f19d6f5a63204afff1991e3fc1fcf5b28ad420'
TOKEN=re.compile(r'"(?:\\.|[^"\\])*"|\'(?:\\.|[^\'\\])\'|[\w][\w\'.!?]*|:=|=>|[^\s]', re.UNICODE)
def tokens(text,lean):
    start,end=('/-','-/') if lean else ('(*','*)')
    out=[];i=0
    while i<len(text):
        if text.startswith(start,i):
            depth=1;i+=2;out.append(' ')
            while depth:
                assert i<len(text),'unterminated comment'
                if text.startswith(start,i):depth+=1;i+=2
                elif text.startswith(end,i):depth-=1;i+=2
                else:i+=1
        elif lean and text.startswith('--',i):
            j=text.find('\n',i);i=len(text) if j<0 else j;out.append(' ')
        elif text[i]=='"':
            j=i;i+=1
            while i<len(text):
                if text[i]=='\\':i+=2
                elif text[i]=='"':i+=1;break
                else:i+=1
            else:raise ValueError('unterminated string')
            out.append(text[j:i])
        else:out.append(text[i]);i+=1
    return TOKEN.findall(''.join(out))
if __name__=='__main__':
    files=['frontend/model/implementation.lem','frontend/model/core_run_aux.lem','lean_frontend/CabsImport.lean']
    for p in files:
        old=subprocess.check_output(['git','show',BASE+':'+p],text=True);new=Path(p).read_text()
        assert old!=new,p
        assert tokens(old,p.endswith('.lean'))==tokens(new,p.endswith('.lean')),p
        print('SOURCE COMMENT-ONLY:',p)
    before=json.loads(Path('.tmp/run-digest-review/before-hashes.json').read_text())
    current={str(p) for d,ext in [('ocaml_frontend/generated','*.ml'),('lean_frontend/generated','*.lean')] for p in Path(d).glob(ext)}
    assert current==set(before),'generated file set changed'
    changed=[]
    for p,h in before.items():
        if hashlib.sha256(Path(p).read_bytes()).hexdigest()!=h:
            old=(Path('.tmp/run-digest-review/before')/p).read_text();new=Path(p).read_text()
            assert tokens(old,p.endswith('.lean'))==tokens(new,p.endswith('.lean')),p
            changed.append(p);print('GENERATED COMMENT-ONLY:',p)
    print('Derived generated comparison:',len(before),'files;',len(changed),'comment-only changes;',len(before)-len(changed),'byte-identical files.')
