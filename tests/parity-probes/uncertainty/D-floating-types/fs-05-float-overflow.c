int main(void){ float f = 3.0e38f; float g = f * 10.0f; return g == g / 10.0f * 10.0f && g > f; }
