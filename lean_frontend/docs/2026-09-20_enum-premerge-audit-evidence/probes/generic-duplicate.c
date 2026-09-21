enum E {A,B};int main(void){return _Generic(0,enum E:1,unsigned int:2,default:3);}
