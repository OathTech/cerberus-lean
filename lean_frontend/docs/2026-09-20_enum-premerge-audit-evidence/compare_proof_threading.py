from pathlib import Path
import subprocess,re,json,difflib
root=Path.cwd();out=root/'.tmp/enum-premerge'
files=subprocess.check_output(['git','diff','--name-only','5407597d9...HEAD'],text=True).splitlines()
names=['enumDefs','_lemReader_enum_definitions','eds','ed']
def normalise(s):
 # Strip comments for a code-only comparison; nested Lean block comments included.
 parts=[];i=0;depth=0
 while i<len(s):
  if s.startswith('/-',i):depth+=1;i+=2
  elif depth and s.startswith('-/',i):depth-=1;i+=2
  elif depth:i+=1
  elif s.startswith('--',i):
   j=s.find('\n',i);i=len(s) if j<0 else j
  else:parts.append(s[i]);i+=1
 s=''.join(parts)
 # Remove only named enum-map binders, balancing their type's parentheses.
 i=0;parts=[]
 while i<len(s):
  m=re.match(r'\((?:'+ '|'.join(names) +r')\s*:',s[i:])
  if m:
   j=i+1;depth=1
   while j<len(s) and depth:
    depth+=(s[j]=='(')-(s[j]==')');j+=1
   i=j
  else:parts.append(s[i]);i+=1
 s=''.join(parts)
 s=re.sub(r'\b(?:'+'|'.join(names)+r')\b','',s)
 return re.sub(r'\s+',' ',s).strip()
rows=[]
for name in files:
 if not name.endswith('_lemMeasureProofs.lean'):continue
 old=subprocess.check_output(['git','show','5407597d9:'+name],text=True);new=Path(name).read_text()
 saved=names[:]
 if name.endswith(('AilTypesAux_lemMeasureProofs.lean','Ctype_aux_lemMeasureProofs.lean')): names.append('tagDefs')
 a=normalise(old);b=normalise(new)
 names[:]=saved
 rows.append({'path':name,'equal_after_erasing_new_reader_binders_arguments_and_comments':a==b})
 print(name,'MECHANICAL' if a==b else 'RESIDUAL')
 if a!=b:
  # Short token-context around each residual for manual review, not a semantic verifier.
  aa=a.split();bb=b.split()
  for tag,i,j,k,l in difflib.SequenceMatcher(None,aa,bb,autojunk=False).get_opcodes():
   if tag!='equal':print('before:', ' '.join(aa[max(0,i-10):j+10]));print('after: ', ' '.join(bb[max(0,k-10):l+10]))
(out/'proof-threading.json').write_text(json.dumps(rows,indent=2)+'\n')
