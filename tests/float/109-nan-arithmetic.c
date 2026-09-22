/* Both NaN operands have the same sign/payload. This tests payload
 * retention and quieting without depending on which NaN operand the
 * native compiler selects. The separate 784-row OCaml matrix tests
 * the pinned concrete model's operand-selection rule. */
union U { unsigned long long bits; double value; };
int main(void) {
 union U a={.bits=0xfff0000000000001ULL}, b={.bits=0xfff8000000000001ULL}, out;
 out.value=a.value+b.value; if(out.bits!=0xfff8000000000001ULL)return 1;
 out.value=b.value-a.value; if(out.bits!=0xfff8000000000001ULL)return 2;
 out.value=a.value*b.value; if(out.bits!=0xfff8000000000001ULL)return 3;
 out.value=b.value/a.value; if(out.bits!=0xfff8000000000001ULL)return 4;
 return 0;
}
