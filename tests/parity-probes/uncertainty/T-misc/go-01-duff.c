int main(void){ int src[7]={1,2,3,4,5,6,7}; int dst[7]={0,0,0,0,0,0,0}; int *s=src,*d=dst; int n=7; int c=(n+3)/4;
  switch(n%4){ case 0: do{ *d++=*s++; case 3: *d++=*s++; case 2: *d++=*s++; case 1: *d++=*s++; } while(--c>0); }
  int sum=0; for(int i=0;i<7;i++) sum+=dst[i]; return sum; }
