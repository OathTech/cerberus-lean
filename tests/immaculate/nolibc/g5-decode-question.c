// G5: '\?' is a legal C escape (§6.4.4.4) decoding to '?' = 63. Upstream
// decode.ml validates the octal path and FAILs on '?' (not an octal
// digit) -> but '\?' is actually in no simple table, so upstream's
// catch-all failwiths. Lean's readDigit silent-0 default decodes it to 0.
int main(void) { char c = '\?'; return c; }
